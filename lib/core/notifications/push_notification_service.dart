import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '/backend/schema/notifications_record.dart';

/// Top-level background FCM handler required by `firebase_messaging`.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('FCM background init skipped: $e');
  }
}

/// Manages real OS-level notifications (Android/iOS system tray, lock screen,
/// sound & vibration) via:
/// 1. Firebase Cloud Messaging (FCM) for background / terminated push delivery.
/// 2. Live Firestore `notifications` bridge for instant system-tray alerts
///    while the app is running (works even before Cloud Functions are deployed),
///    strictly deduplicated by notification ID so users never get duplicates.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const String channelId = 'oneway_alerts';
  static const String channelName = 'إشعارات ONEWAY';
  static const String channelDescription =
      'تنبيهات حالة البلاغات، ردود الإدارة، وتحديثات الأماكن المهيأة';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _enabled = true;
  String? _currentUid;
  VoidCallback? _onOpenNotifications;

  StreamSubscription<RemoteMessage>? _fcmForegroundSub;
  StreamSubscription<RemoteMessage>? _fcmOpenedSub;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _firestoreSub;

  /// Bounded deduplication set so a notification delivered by both FCM and the
  /// live Firestore bridge is only shown once in the OS tray.
  final Set<String> _deliveredIds = <String>{};
  final Set<String> _initialSnapshotIds = <String>{};
  bool _initialSnapshotLoaded = false;

  @visibleForTesting
  bool shouldDeliverOnce(String id) {
    if (id.isEmpty) return true;
    if (_deliveredIds.contains(id)) return false;
    if (_deliveredIds.length > 200) {
      _deliveredIds.remove(_deliveredIds.first);
    }
    _deliveredIds.add(id);
    return true;
  }

  @visibleForTesting
  void resetDeduplicationForTest() {
    _deliveredIds.clear();
    _initialSnapshotIds.clear();
    _initialSnapshotLoaded = false;
  }

  bool get isEnabled => _enabled;

  Future<void> initialize({
    required VoidCallback onOpenNotifications,
    bool initialEnabled = true,
  }) async {
    _onOpenNotifications = onOpenNotifications;
    _enabled = initialEnabled;
    if (_initialized || kIsWeb) return;

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (_) {
          _onOpenNotifications?.call();
        },
      );

      // Create high-importance Android notification channel
      const androidChannel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // Configure FCM presentation & listeners if Firebase is initialized
      if (Firebase.apps.isNotEmpty) {
        final messaging = FirebaseMessaging.instance;
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        _fcmForegroundSub = FirebaseMessaging.onMessage.listen(_onFcmMessage);
        _fcmOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((_) {
          _onOpenNotifications?.call();
        });
        _tokenRefreshSub = messaging.onTokenRefresh.listen((token) {
          if (_currentUid != null && _enabled) {
            _persistToken(_currentUid!, token);
          }
        });

        final initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
          Future.microtask(() => _onOpenNotifications?.call());
        }
      }

      _initialized = true;
    } catch (e) {
      debugPrint('PushNotificationService init skipped: $e');
    }
  }

  Future<void> _onFcmMessage(RemoteMessage message) async {
    if (!_enabled) return;
    final docId = (message.data['notificationId'] as String?) ??
        message.messageId ??
        '';
    if (!shouldDeliverOnce(docId)) return;

    final title = message.notification?.title ??
        (message.data['title'] as String?) ??
        'ONEWAY';
    final body = message.notification?.body ??
        (message.data['body'] as String?) ??
        '';
    if (body.isEmpty && title == 'ONEWAY') return;

    await showSystemNotification(
      id: docId.isNotEmpty ? docId.hashCode : DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: docId,
    );
  }

  /// Requests OS notification permissions (Android 13+ POST_NOTIFICATIONS & iOS).
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    try {
      bool granted = true;
      final androidImpl = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        granted = (await androidImpl.requestNotificationsPermission()) ?? true;
      }

      if (Firebase.apps.isNotEmpty) {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
        granted = granted &&
            (settings.authorizationStatus == AuthorizationStatus.authorized ||
                settings.authorizationStatus ==
                    AuthorizationStatus.provisional);
      }
      return granted;
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
      return false;
    }
  }

  /// Attaches push token registration + live system-tray notification listener
  /// for the signed-in user.
  Future<void> attachUser(String uid, {required bool enabled}) async {
    _enabled = enabled;
    if (uid.isEmpty) {
      await detachUser();
      return;
    }
    if (_currentUid == uid && _firestoreSub != null && enabled) return;

    _currentUid = uid;
    if (!enabled) {
      await _stopFirestoreBridge();
      return;
    }

    if (!kIsWeb) {
      await requestPermissions();
      await _syncCurrentFcmToken(uid);
      _startFirestoreBridge(uid);
    }
  }

  Future<void> detachUser() async {
    _currentUid = null;
    await _stopFirestoreBridge();
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (!enabled) {
      await _stopFirestoreBridge();
      return;
    }
    if (_currentUid != null && _currentUid!.isNotEmpty && !kIsWeb) {
      await requestPermissions();
      await _syncCurrentFcmToken(_currentUid!);
      _startFirestoreBridge(_currentUid!);
    }
  }

  Future<void> _syncCurrentFcmToken(String uid) async {
    if (Firebase.apps.isEmpty) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.trim().isNotEmpty) {
        await _persistToken(uid, token.trim());
      }
    } catch (e) {
      debugPrint('FCM getToken skipped: $e');
    }
  }

  Future<void> _persistToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcm_tokens': FieldValue.arrayUnion([token]),
        'updated_time': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Never block app flow if offline or rules not yet published
      debugPrint('FCM token save skipped: $e');
    }
  }

  void _startFirestoreBridge(String uid) {
    if (Firebase.apps.isEmpty) return;
    _firestoreSub?.cancel();
    _initialSnapshotLoaded = false;
    _initialSnapshotIds.clear();

    _firestoreSub = NotificationsRecord.collection
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen(
      (snapshot) {
        if (!_enabled) return;
        if (!_initialSnapshotLoaded) {
          for (final doc in snapshot.docs) {
            _initialSnapshotIds.add(doc.id);
          }
          _initialSnapshotLoaded = true;
          return;
        }

        for (final change in snapshot.docChanges) {
          if (change.type != DocumentChangeType.added) continue;
          final doc = change.doc;
          if (_initialSnapshotIds.contains(doc.id)) continue;
          final data = doc.data();
          if (data == null || data['is_read'] == true) continue;
          if (!shouldDeliverOnce(doc.id)) continue;

          final title = (data['title'] as String?)?.trim();
          final body = (data['body'] as String?)?.trim();
          if ((title == null || title.isEmpty) &&
              (body == null || body.isEmpty)) {
            continue;
          }

          showSystemNotification(
            id: doc.id.hashCode & 0x7FFFFFFF,
            title: (title != null && title.isNotEmpty) ? title : 'ONEWAY',
            body: body ?? '',
            payload: doc.id,
          );
        }
      },
      onError: (Object e) {
        debugPrint('Firestore notification bridge error: $e');
      },
    );
  }

  Future<void> _stopFirestoreBridge() async {
    await _firestoreSub?.cancel();
    _firestoreSub = null;
    _initialSnapshotLoaded = false;
    _initialSnapshotIds.clear();
  }

  Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb || !_initialized) return;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      await _localNotifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Local system notification error: $e');
    }
  }

  Future<void> dispose() async {
    await _fcmForegroundSub?.cancel();
    await _fcmOpenedSub?.cancel();
    await _tokenRefreshSub?.cancel();
    await _stopFirestoreBridge();
  }
}

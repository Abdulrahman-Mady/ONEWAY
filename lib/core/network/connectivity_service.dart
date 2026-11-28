import 'dart:async';
import 'dart:io' show InternetAddress;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Centralized, test-friendly network connectivity monitor for ONEWAY.
///
/// Tracks real-time network changes via `connectivity_plus` and performs a
/// fast, bounded reachability check before critical upload actions (such as
/// submitting a place, uploading photos, or sending a barrier report) so the
/// user never gets stuck on an infinite loading spinner when offline.
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  /// Live reactive online state listened to by [OfflineStatusBanner] and
  /// offline-aware repositories.
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);

  /// Fires `true` briefly when connectivity recovers after an offline period.
  final ValueNotifier<bool> justReconnectedNotifier = ValueNotifier<bool>(false);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _reconnectedBannerTimer;
  bool _initialized = false;

  /// Injectable seam for deterministic unit/widget tests without platform channels.
  @visibleForTesting
  Future<bool> Function()? testConnectivityOverride;

  bool get isOnline => isOnlineNotifier.value;
  bool get isOffline => !isOnlineNotifier.value;

  /// Starts listening to OS connectivity events once at app startup.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (testConnectivityOverride != null) {
      final online = await testConnectivityOverride!();
      _setOnlineState(online, announceReconnect: false);
      return;
    }

    try {
      final initial = await Connectivity().checkConnectivity();
      _setOnlineState(
        _hasNetworkInterface(initial),
        announceReconnect: false,
      );
    } catch (e) {
      debugPrint('Connectivity initial check skipped: $e');
    }

    try {
      _subscription = Connectivity().onConnectivityChanged.listen(
        (results) {
          _setOnlineState(_hasNetworkInterface(results));
        },
        onError: (Object e) {
          debugPrint('Connectivity stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('Connectivity listener skipped: $e');
    }
  }

  /// Actively verifies whether the device currently has usable internet access
  /// (catches both airplane mode / Wi-Fi off AND dead Wi-Fi routers with no
  /// external internet). Bounded to ~3 seconds so UI never hangs.
  Future<bool> checkHasInternet({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (testConnectivityOverride != null) {
      final ok = await testConnectivityOverride!();
      _setOnlineState(ok);
      return ok;
    }

    try {
      final results = await Connectivity().checkConnectivity().timeout(timeout);
      if (!_hasNetworkInterface(results)) {
        _setOnlineState(false);
        return false;
      }
    } catch (_) {
      // If plugin fails on an unsupported platform, continue to DNS check on IO.
    }

    if (kIsWeb) {
      _setOnlineState(true);
      return true;
    }

    try {
      final lookup = await InternetAddress.lookup('clients3.google.com')
          .timeout(timeout);
      final reachable =
          lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
      _setOnlineState(reachable);
      return reachable;
    } catch (_) {
      _setOnlineState(false);
      return false;
    }
  }

  /// Manually updates connectivity state (used in tests or error handlers).
  @visibleForTesting
  void setOnlineForTest(bool online, {bool announceReconnect = true}) {
    _setOnlineState(online, announceReconnect: announceReconnect);
  }

  /// Resets test overrides cleanly between test cases.
  @visibleForTesting
  void resetForTesting() {
    testConnectivityOverride = null;
    _reconnectedBannerTimer?.cancel();
    isOnlineNotifier.value = true;
    justReconnectedNotifier.value = false;
  }

  bool _hasNetworkInterface(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  void _setOnlineState(bool online, {bool announceReconnect = true}) {
    final wasOffline = !isOnlineNotifier.value;
    if (isOnlineNotifier.value != online) {
      isOnlineNotifier.value = online;
    }

    if (online && wasOffline && announceReconnect) {
      justReconnectedNotifier.value = true;
      _reconnectedBannerTimer?.cancel();
      _reconnectedBannerTimer = Timer(const Duration(seconds: 3), () {
        justReconnectedNotifier.value = false;
      });
    } else if (!online) {
      _reconnectedBannerTimer?.cancel();
      justReconnectedNotifier.value = false;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _reconnectedBannerTimer?.cancel();
    _initialized = false;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '/auth/auth_service.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/favorites_record.dart';
import '/core/analytics/analytics_service.dart';
import '/core/constants/app_constants.dart';
import '/core/notifications/push_notification_service.dart';
import '/features/discovery/discovery_pages.dart' show PlaceDetailPage;
import '/features/emergency/emergency_service.dart';
import '/features/onboarding/onboarding_flow.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/main.dart';
import '/pages/submit_accessibility_report/submit_accessibility_report_widget.dart';
import 'voice_assistant_models.dart';

/// Result returned after executing an [AssistantAction].
class ActionExecutionResult {
  const ActionExecutionResult({
    required this.success,
    this.feedbackMessage,
    this.navigatedAway = false,
  });

  final bool success;
  final String? feedbackMessage;
  final bool navigatedAway;
}

/// Executes structured [AssistantAction]s cleanly against app state, GoRouter,
/// Firestore favorites/profile, and external phone/maps/web intents.
class VoiceActionExecutor {
  VoiceActionExecutor._();

  static Future<ActionExecutionResult> execute(
    BuildContext context,
    AssistantAction action, {
    VoidCallback? onClearConversation,
    ValueChanged<double>? onTtsRateChanged,
    ValueChanged<bool>? onConversationModeChanged,
    ValueChanged<bool>? onVoiceFeedbackChanged,
    ValueChanged<String>? onLocaleChanged,
  }) async {
    final isEn = FFAppState().isEnglish;

    switch (action.type) {
      case AssistantActionType.none:
        return const ActionExecutionResult(success: true);

      case AssistantActionType.clearConversation:
        onClearConversation?.call();
        return const ActionExecutionResult(success: true);

      case AssistantActionType.goBack:
        if (context.mounted) {
          context.safePop();
        }
        return const ActionExecutionResult(success: true, navigatedAway: true);

      case AssistantActionType.navigate:
        final route = action.route;
        if (route == null || route.isEmpty || !context.mounted) {
          return const ActionExecutionResult(success: false);
        }
        try {
          context.pushNamed(
            route,
            queryParameters: action.routeParams,
          );
          return const ActionExecutionResult(
            success: true,
            navigatedAway: true,
          );
        } catch (_) {
          return ActionExecutionResult(
            success: false,
            feedbackMessage: isEn
                ? 'Could not open that screen right now.'
                : 'تعذر فتح هذه الصفحة حالياً.',
          );
        }

      case AssistantActionType.openPlace:
        final place = action.place;
        if (place == null || !context.mounted) {
          return const ActionExecutionResult(success: false);
        }
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlaceDetailPage(place: place)),
        );
        return const ActionExecutionResult(success: true, navigatedAway: true);

      case AssistantActionType.openReport:
        if (!context.mounted) {
          return const ActionExecutionResult(success: false);
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                SubmitAccessibilityReportWidget(place: action.place),
          ),
        );
        return const ActionExecutionResult(success: true, navigatedAway: true);

      case AssistantActionType.directions:
        final place = action.place;
        if (place == null || !place.hasLocation()) {
          return ActionExecutionResult(
            success: false,
            feedbackMessage: isEn
                ? 'Coordinates for this place are unavailable.'
                : 'إحداثيات هذا المكان غير متوفرة بعد.',
          );
        }
        final loc = place.location!;
        final uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${loc.latitude},${loc.longitude}&travelmode=walking',
        );
        try {
          AnalyticsService.instance.logNavigationStarted(
            placeId: place.reference.id,
            navigationMode: 'voice_maps',
          );
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return const ActionExecutionResult(success: true);
        } catch (_) {
          return ActionExecutionResult(
            success: false,
            feedbackMessage: isEn
                ? 'Could not open Google Maps.'
                : 'تعذر فتح تطبيق الخرائط.',
          );
        }

      case AssistantActionType.callPhone:
        final number = (action.phoneNumber ?? action.place?.phoneNumber ?? '')
            .replaceAll(RegExp(r'\s+'), '');
        if (number.isEmpty) {
          return ActionExecutionResult(
            success: false,
            feedbackMessage: isEn
                ? 'No phone number available.'
                : 'لا يوجد رقم هاتف متاح.',
          );
        }
        try {
          await launchUrl(Uri(scheme: 'tel', path: number));
          return const ActionExecutionResult(success: true);
        } catch (_) {
          return ActionExecutionResult(
            success: false,
            feedbackMessage: isEn
                ? 'Could not dial $number on this device.'
                : 'تعذر فتح الاتصال بالرقم $number على هذا الجهاز.',
          );
        }

      case AssistantActionType.openUrl:
        final url = action.url ?? '';
        if (!url.startsWith('https://') && !url.startsWith('mailto:')) {
          return const ActionExecutionResult(success: false);
        }
        try {
          await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          );
          return const ActionExecutionResult(success: true);
        } catch (_) {
          return ActionExecutionResult(
            success: false,
            feedbackMessage: isEn
                ? 'Could not open external link.'
                : 'تعذر فتح الرابط حالياً.',
          );
        }

      case AssistantActionType.toggleFavorite:
        return _executeToggleFavorite(action, isEn: isEn);

      case AssistantActionType.changeSetting:
        return _executeChangeSetting(
          context,
          action,
          isEn: isEn,
          onTtsRateChanged: onTtsRateChanged,
          onConversationModeChanged: onConversationModeChanged,
          onVoiceFeedbackChanged: onVoiceFeedbackChanged,
          onLocaleChanged: onLocaleChanged,
        );

      case AssistantActionType.triggerSos:
        final sosRes = await EmergencyService.triggerSOS();
        return ActionExecutionResult(
          success: sosRes.success,
          feedbackMessage: sosRes.message,
        );
    }
  }

  static Future<ActionExecutionResult> _executeToggleFavorite(
    AssistantAction action, {
    required bool isEn,
  }) async {
    final place = action.place;
    final uid = currentUserUid;
    if (place == null) {
      return const ActionExecutionResult(success: false);
    }
    if (uid.isEmpty) {
      return ActionExecutionResult(
        success: false,
        feedbackMessage: isEn
            ? 'Please sign in first to save favorites.'
            : 'يرجى تسجيل الدخول أولاً لحفظ الأماكن في المفضلة.',
      );
    }

    try {
      final docRef =
          FavoritesRecord.collection.doc('${uid}_${place.reference.id}');
      if (action.addFavorite) {
        await docRef.set({
          'userId': uid,
          'placeId': place.reference.id,
          'placeName': place.name,
          'placePhoto': place.photoUrl,
          'placeCategory': place.category,
          'created_at': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.delete();
      }
      AnalyticsService.instance.logFavoriteToggled(
        placeId: place.reference.id,
        added: action.addFavorite,
      );
      return ActionExecutionResult(
        success: true,
        feedbackMessage: action.addFavorite
            ? (isEn ? 'Added to Favorites' : 'تمت الإضافة إلى المفضلة')
            : (isEn ? 'Removed from Favorites' : 'تمت الإزالة من المفضلة'),
      );
    } catch (_) {
      return ActionExecutionResult(
        success: false,
        feedbackMessage: isEn
            ? 'Could not update Favorites right now.'
            : 'تعذر تحديث المفضلة حالياً.',
      );
    }
  }

  static Future<ActionExecutionResult> _executeChangeSetting(
    BuildContext context,
    AssistantAction action, {
    required bool isEn,
    ValueChanged<double>? onTtsRateChanged,
    ValueChanged<bool>? onConversationModeChanged,
    ValueChanged<bool>? onVoiceFeedbackChanged,
    ValueChanged<String>? onLocaleChanged,
  }) async {
    final appState = FFAppState();
    final key = action.settingKey;
    final val = action.settingValue;

    try {
      switch (key) {
        case 'font_scale':
          double target = appState.fontScale;
          if (val == 'increase') {
            target = (appState.fontScale + 0.15)
                .clamp(AppConstants.minFontScale, AppConstants.maxFontScale);
          } else if (val == 'decrease') {
            target = (appState.fontScale - 0.15)
                .clamp(AppConstants.minFontScale, AppConstants.maxFontScale);
          } else if (val is num) {
            target = val
                .toDouble()
                .clamp(AppConstants.minFontScale, AppConstants.maxFontScale);
          }
          await appState.setFontScale(target);
          await AnalyticsService.instance.setFontScale(target);
          return const ActionExecutionResult(success: true);

        case 'high_contrast':
          if (val is bool) {
            await appState.setHighContrast(val);
            await AnalyticsService.instance.setHighContrastEnabled(val);
          }
          return const ActionExecutionResult(success: true);

        case 'theme_mode':
          final mode = val == 'dark' ? ThemeMode.dark : ThemeMode.light;
          if (context.mounted) {
            final app = context.findAncestorStateOfType<MyAppState>();
            app?.setThemeMode(mode);
          }
          return const ActionExecutionResult(success: true);

        case 'language':
          final code = val == 'en' ? 'en' : 'ar';
          await appState.setLocaleCode(code);
          await AnalyticsService.instance.setPreferredLanguage(code);
          onLocaleChanged?.call(code);
          return const ActionExecutionResult(success: true);

        case 'voice_feedback':
          if (val is bool) {
            await appState.setVoiceFeedbackEnabled(val);
            onVoiceFeedbackChanged?.call(val);
          }
          return const ActionExecutionResult(success: true);

        case 'tts_rate':
          if (val is num) {
            onTtsRateChanged?.call(val.toDouble().clamp(0.3, 0.75));
          }
          return const ActionExecutionResult(success: true);

        case 'conversation_mode':
          if (val is bool) {
            onConversationModeChanged?.call(val);
          }
          return const ActionExecutionResult(success: true);

        case 'notifications':
          if (val is bool) {
            await appState.setNotificationsEnabled(val);
            await PushNotificationService.instance.setEnabled(val);
          }
          return const ActionExecutionResult(success: true);

        case 'mobility_type':
          if (val is String) {
            final option = MobilityProfileOption.resolveOption(val);
            await appState.setMobilityType(option.firestoreValue);
            await AnalyticsService.instance.setMobilityType(option.firestoreValue);
            final userDoc = currentUserDocument;
            if (userDoc != null) {
              await userDoc.reference.update({
                'mobility_type': option.firestoreValue,
                'updated_time': FieldValue.serverTimestamp(),
              });
            } else {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(
                AppConstants.kPendingMobilityTypeKey,
                option.firestoreValue,
              );
            }
          }
          return const ActionExecutionResult(success: true);

        case 'access_needs':
          if (val is List) {
            final needs = val
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .take(10)
                .toList();
            await appState.setAccessNeeds(needs);
            final userDoc = currentUserDocument;
            if (userDoc != null) {
              try {
                await userDoc.reference.update({
                  'access_needs': needs,
                  'updated_time': FieldValue.serverTimestamp(),
                });
              } catch (_) {}
            } else {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setStringList(AppConstants.kPendingAccessNeedsKey, needs);
            }
          }
          return const ActionExecutionResult(success: true);

        case 'open_personalization':
          if (context.mounted) {
            await showAccessibilityPreferencesSheet(context);
          }
          return const ActionExecutionResult(success: true);

        case 'sign_out':
          await AuthService.instance.signOut();
          if (context.mounted) {
            context.go('/login');
          }
          return const ActionExecutionResult(success: true, navigatedAway: true);
      }
    } catch (_) {
      return ActionExecutionResult(
        success: false,
        feedbackMessage: isEn
            ? 'Could not apply setting.'
            : 'تعذر تطبيق الإعداد حالياً.',
      );
    }

    return const ActionExecutionResult(success: true);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/components/button/button_widget.dart';
import '/core/analytics/analytics_service.dart';
import '/core/notifications/push_notification_service.dart';
import '/features/legal/legal_pages.dart';
import '/features/onboarding/home_spotlight_tour.dart';
import '/features/onboarding/onboarding_flow.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/l10n/app_strings.dart';
import '/main.dart';
import 'settings_page_model.dart';
export 'settings_page_model.dart';

/// Production Settings page: real persisted accessibility preferences
/// (font size, high contrast, voice feedback, notifications), legal links
/// (Privacy Policy, Terms, About), and Google Play-compliant Account Deletion.
class SettingsPageWidget extends StatefulWidget {
  const SettingsPageWidget({super.key});

  static String routeName = 'SettingsPage';
  static String routePath = '/settings';

  @override
  State<SettingsPageWidget> createState() => _SettingsPageWidgetState();
}

class _SettingsPageWidgetState extends State<SettingsPageWidget> {
  late SettingsPageModel _model;
  bool _deletingAccount = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SettingsPageModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _showQuickUsageGuide(BuildContext context, FlutterFlowTheme theme) {
    final items = [
      (
        icon: Icons.map_outlined,
        title: S.t(
          context,
          'استكشاف الأماكن المهيأة وتخصيص الوصول',
          'Explore Accessible Places & Personalization',
        ),
        content: S.t(
          context,
          'استخدم الخريطة أو البحث للوصول إلى الأماكن المجهزة حسب طريقة تنقلك واحتياجات الوصول الفعلية (مدخل بدون درجات، منحدر، مصعد، حمام مجهز، ممرات واسعة، ومواقف).',
          'Use the map or search to find accessible venues tailored to your mobility way and concrete access needs (step-free entry, ramp, elevator, restroom, wide corridors, and parking).',
        ),
      ),
      (
        icon: Icons.mic_rounded,
        title: S.t(
          context,
          'المساعد الصوتي الكامل بدون كتابة',
          'Full Hands-Free Voice Assistant',
        ),
        content: S.t(
          context,
          'إذا كنت تفضل عدم الكتابة، افتح المساعد الصوتي وتحدث باللهجة المصرية للبحث، فتح الصفحات، تقديم بلاغ عائق، اقتراح مكان جديد، إضافة مرافق طوارئ، أو مراسلة الدعم بالصوت فقط.',
          'Open the Voice Assistant to search places, navigate screens, report barriers, suggest places, manage settings, or reach support completely hands-free.',
        ),
      ),
      (
        icon: Icons.report_problem_outlined,
        title: S.t(
          context,
          'الإبلاغ عن عائق أو اقتراح مكان',
          'Report a Barrier or Suggest a Place',
        ),
        content: S.t(
          context,
          'إذا واجهت مدخلاً معطلاً أو مصعداً لا يعمل يمكنك إرسال بلاغ فوري ليراجعه فريق ONEWAY، كما يمكنك اقتراح أماكن جديدة بكامل بياناتها وصورها.',
          'Report broken ramps or elevators immediately for review by the ONEWAY team, or suggest new accessible venues with full details and photos.',
        ),
      ),
      (
        icon: Icons.emergency_outlined,
        title: S.t(
          context,
          'أرقام الطوارئ الرسمية في مصر',
          'Official Emergency Numbers in Egypt',
        ),
        content: S.t(
          context,
          'يوفر قسم الطوارئ اتصالاً مباشراً بأرقام الطوارئ الرسمية (الإسعاف 123، الشرطة 122، الحماية المدنية 180، المجلس القومي 15044) ومشاركة موقعك الجغرافي الحقيقي مع مرافقك.',
          'Quick-dial official Egyptian hotlines (Ambulance 123, Police 122, Civil Defense 180, NCDA 15044) and share your live GPS location with trusted companions.',
        ),
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.divider,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                child: Row(
                  children: [
                    _IconTile(
                      icon: Icons.menu_book_rounded,
                      color: theme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        S.t(context, 'دليل الاستخدام السريع', 'Quick Usage Guide'),
                        style: theme.titleLarge.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: theme.primaryText,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: S.t(context, 'إغلاق', 'Close'),
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.divider),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.background,
                        borderRadius: BorderRadius.circular(
                          theme.designToken.radius.xl,
                        ),
                        border: Border.all(color: theme.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _IconTile(icon: item.icon, color: theme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: theme.titleMedium.copyWith(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: theme.primaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.content,
                            style: theme.bodyMedium.copyWith(
                              fontSize: 14,
                              color: theme.secondaryText,
                              height: 1.65,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: FilledButton.icon(
                  key: const Key('replay_home_tour_btn'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(sheetCtx).pop();
                    HomeTourController.instance.requestReplay();
                    context.goNamed(HomeDashboardWidget.routeName);
                  },
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 22),
                  label: Text(
                    S.t(
                      context,
                      'إعادة الجولة التعليمية التفاعلية على الشاشة الرئيسية',
                      'Replay Interactive Home Tour',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndDeleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الحساب والبيانات'),
        content: const Text(
          'هل أنت متأكد من رغبتك في حذف حسابك نهائياً؟\n\n'
          'سيتم حذف مفضلاتك، إشعاراتك، جهات اتصال الطوارئ، ومسح بياناتك الشخصية وحذف حسابك من ONEWAY. لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FlutterFlowTheme.of(context).error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('تأكيد الحذف النهائي'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _deletingAccount = true);

    try {
      // 1. Prefer atomic server-side account deletion via Cloud Functions
      //    so Firestore data is never scrubbed if Auth deletion fails.
      bool deletedOnServer = false;
      try {
        final callable = FirebaseFunctions.instance.httpsCallable(
          'deleteMyAccount',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
        );
        final res = await callable.call(<String, dynamic>{});
        if (res.data is Map && (res.data as Map)['deleted'] == true) {
          deletedOnServer = true;
        }
      } catch (_) {
        deletedOnServer = false;
      }

      if (!deletedOnServer) {
        // Verify recent sign-in freshness before scrubbing Firestore data
        final lastSignIn = user.metadata.lastSignInTime;
        if (lastSignIn != null &&
            DateTime.now().difference(lastSignIn) >
                const Duration(minutes: 5)) {
          throw FirebaseAuthException(code: 'requires-recent-login');
        }

        final uid = user.uid;
        final db = FirebaseFirestore.instance;

        for (final col in ['favorites', 'notifications', 'emergencyContacts']) {
          final snap = await db
              .collection(col)
              .where('userId', isEqualTo: uid)
              .limit(100)
              .get();
          for (final doc in snap.docs) {
            await doc.reference.delete();
          }
        }

        final userRef = db.collection('users').doc(uid);
        final userSnap = await userRef.get();
        if (userSnap.exists) {
          await userRef.update({
            'display_name': 'حساب محذوف',
            'email': '',
            'phone_number': '',
            'photo_url': '',
            'address': '',
            'governorate': '',
            'gender': '',
            'mobility_type': '',
            'updated_time': FieldValue.serverTimestamp(),
          });
        }

        await user.delete();
      } else {
        await authManager.signOut();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف حسابك وبياناتك بنجاح.')),
      );
      context.goNamedAuth(AuthenticationWidget.routeName, context.mounted);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'requires-recent-login'
          ? 'لأمان حسابك، يرجى تسجيل الخروج ثم إعادة تسجيل الدخول والمحاولة مرة أخرى لحذف الحساب.'
          : 'تعذر حذف الحساب حالياً (${e.code}).';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: FlutterFlowTheme.of(context).error,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('حدث خطأ أثناء حذف الحساب. حاول مرة أخرى.'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final appState = context.watch<FFAppState>();
    final fbUser = FirebaseAuth.instance.currentUser;
    final isRegisteredUser = loggedIn && fbUser != null && !fbUser.isAnonymous;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.background,
        appBar: AppBar(
          backgroundColor: theme.navy,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: S.t(context, 'رجوع', 'Back'),
            onPressed: () => context.safePop(),
          ),
          title: Text(S.t(context, 'الإعدادات', 'Settings')),
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionHeader(
                  title: S.t(
                      context, 'تخصيص سهولة الوصول', 'Accessibility Profile'),
                  theme: theme,
                ),
                const SizedBox(height: 10),
                _SettingsCard(
                  theme: theme,
                  children: [
                    _SettingsNavRow(
                      label: S.t(
                        context,
                        'طريقة التنقل واحتياجات الوصول (3 خطوات)',
                        'Mobility & Venue Access Needs',
                      ),
                      icon: Icons.accessible_forward_rounded,
                      iconColor: theme.primary,
                      onTap: () => showAccessibilityPreferencesSheet(context),
                      theme: theme,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _SectionHeader(
                  title: S.t(context, 'اللغة والعرض', 'Language & Display'),
                  theme: theme,
                ),
                const SizedBox(height: 10),
                _SettingsCard(
                  theme: theme,
                  children: [
                    // Language selector (Arabic / English)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _IconTile(
                                icon: Icons.language_rounded,
                                color: theme.navy,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  S.t(context, 'لغة التطبيق', 'App Language'),
                                  style: theme.bodyMedium.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: theme.primaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<String>(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment(
                                  value: 'ar',
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('العربية', maxLines: 1),
                                  ),
                                ),
                                ButtonSegment(
                                  value: 'en',
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('English', maxLines: 1),
                                  ),
                                ),
                              ],
                              selected: {appState.localeCode},
                              onSelectionChanged: (set) {
                                if (set.isNotEmpty) {
                                  appState.setLocaleCode(set.first);
                                  AnalyticsService.instance
                                      .setPreferredLanguage(set.first);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: theme.divider, indent: 16, endIndent: 16),
                    // Font size selector
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _IconTile(
                                icon: Icons.text_fields_rounded,
                                color: theme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  S.t(context, 'حجم الخط', 'Font Size'),
                                  style: theme.bodyMedium.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: theme.primaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<double>(
                              showSelectedIcon: false,
                              segments: [
                                ButtonSegment(
                                  value: 1.0,
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      S.t(context, 'عادي', 'Normal'),
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                ButtonSegment(
                                  value: 1.15,
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      S.t(context, 'كبير', 'Large'),
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                ButtonSegment(
                                  value: 1.3,
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      S.t(context, 'كبير جداً', 'XL'),
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ],
                              selected: {
                                appState.fontScale >= 1.25
                                    ? 1.3
                                    : appState.fontScale >= 1.1
                                        ? 1.15
                                        : 1.0,
                              },
                              onSelectionChanged: (set) {
                                if (set.isNotEmpty) {
                                  appState.setFontScale(set.first);
                                  AnalyticsService.instance
                                      .setFontScale(set.first);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: theme.divider, indent: 16, endIndent: 16),
                    // Theme Mode selector (System / Light / Dark)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _IconTile(
                                icon: Icons.dark_mode_outlined,
                                color: theme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  S.t(context, 'مظهر التطبيق', 'Theme Mode'),
                                  style: theme.bodyMedium.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: theme.primaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<ThemeMode>(
                              showSelectedIcon: false,
                              segments: [
                                ButtonSegment(
                                  value: ThemeMode.system,
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      S.t(context, 'تلقائي', 'Auto'),
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                ButtonSegment(
                                  value: ThemeMode.light,
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      S.t(context, 'نهاري', 'Light'),
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                ButtonSegment(
                                  value: ThemeMode.dark,
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      S.t(context, 'ليلي', 'Dark'),
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ],
                              selected: {FlutterFlowTheme.themeMode},
                              onSelectionChanged: (set) {
                                if (set.isNotEmpty) {
                                  final app = context
                                      .findAncestorStateOfType<MyAppState>();
                                  if (app != null) {
                                    app.setThemeMode(set.first);
                                  } else {
                                    FlutterFlowTheme.saveThemeMode(set.first);
                                  }
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: theme.divider, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _SettingsToggle(
                        label: S.t(context, 'تباين مرتفع', 'High Contrast'),
                        icon: Icons.contrast_rounded,
                        iconColor: theme.tertiaryDark,
                        value: appState.highContrast,
                        onChanged: (v) {
                          appState.setHighContrast(v);
                          AnalyticsService.instance.setHighContrastEnabled(v);
                        },
                        theme: theme,
                      ),
                    ),
                    Divider(height: 1, color: theme.divider, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _SettingsToggle(
                        label: S.t(context, 'تفعيل الصوت (المساعد الصوتي)',
                            'Voice Feedback'),
                        icon: Icons.volume_up_rounded,
                        iconColor: theme.primary,
                        value: appState.voiceFeedbackEnabled,
                        onChanged: (v) => appState.setVoiceFeedbackEnabled(v),
                        theme: theme,
                      ),
                    ),
                    Divider(height: 1, color: theme.divider, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _SettingsToggle(
                        label: S.t(context, 'الإشعارات', 'Notifications'),
                        icon: Icons.notifications_active_outlined,
                        iconColor: theme.secondary,
                        value: appState.notificationsEnabled,
                        onChanged: (v) {
                          appState.setNotificationsEnabled(v);
                          PushNotificationService.instance.setEnabled(v);
                        },
                        theme: theme,
                      ),
                    ),
                    Divider(height: 1, color: theme.divider, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _SettingsToggle(
                        label: S.t(
                          context,
                          'تحليلات تحسين التطبيق وتقارير الأعطال',
                          'Analytics & Crash Diagnostics',
                        ),
                        icon: Icons.analytics_outlined,
                        iconColor: theme.primary,
                        value: AnalyticsService.instance.isEnabled,
                        onChanged: (v) async {
                          await AnalyticsService.instance.setEnabled(v);
                          if (mounted) setState(() {});
                        },
                        theme: theme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _SectionHeader(
                  title: S.t(context, 'الخصوصية والمعلومات', 'Privacy & Info'),
                  theme: theme,
                ),
                const SizedBox(height: 10),
                _SettingsCard(
                  theme: theme,
                  children: [
                    _SettingsNavRow(
                      label: S.t(context, 'سياسة الخصوصية', 'Privacy Policy'),
                      icon: Icons.privacy_tip_outlined,
                      iconColor: theme.primary,
                      onTap: () => context.pushNamed(PrivacyPolicyPage.routeName),
                      theme: theme,
                    ),
                    Divider(height: 1, color: theme.divider, indent: 16, endIndent: 16),
                    _SettingsNavRow(
                      label: S.t(context, 'شروط الاستخدام', 'Terms of Use'),
                      icon: Icons.description_outlined,
                      iconColor: theme.navy,
                      onTap: () => context.pushNamed(TermsOfUsePage.routeName),
                      theme: theme,
                    ),
                    Divider(height: 1, color: theme.divider, indent: 16, endIndent: 16),
                    _SettingsNavRow(
                      label: S.t(context, 'حول التطبيق', 'About ONEWAY'),
                      icon: Icons.info_outline_rounded,
                      iconColor: theme.secondary,
                      onTap: () => context.pushNamed(AboutAppPage.routeName),
                      theme: theme,
                    ),
                    Divider(height: 1, color: theme.divider, indent: 16, endIndent: 16),
                    _SettingsNavRow(
                      label: S.t(context, 'المساعدة والدعم', 'Help & Support'),
                      icon: Icons.help_outline_rounded,
                      iconColor: theme.gold,
                      onTap: () => context.pushNamed(HelpSupportPageWidget.routeName),
                      theme: theme,
                    ),
                    Divider(height: 1, color: theme.divider, indent: 16, endIndent: 16),
                    _SettingsNavRow(
                      label: S.t(
                        context,
                        'دليل الاستخدام السريع',
                        'Quick Usage Guide',
                      ),
                      icon: Icons.menu_book_rounded,
                      iconColor: theme.primary,
                      onTap: () => _showQuickUsageGuide(context, theme),
                      theme: theme,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                if (currentUserIsAdmin) ...[
                  _SettingsButton(
                    label: S.t(context, 'لوحة تحكم الإدارة (Admin Portal)',
                        'Admin Portal'),
                    icon: Icons.admin_panel_settings_rounded,
                    variant: 'secondary',
                    onPressed: () => context.pushNamed('AdminDashboard'),
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                ],
                _SettingsButton(
                  label: S.t(context, 'الملف الشخصي ونوع الحساب',
                      'Profile & Account'),
                  icon: Icons.person_rounded,
                  variant: 'outline',
                  onPressed: () => context.pushNamed(UserProfileWidget.routeName),
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _SettingsButton(
                  label: loggedIn
                      ? S.t(context, 'تسجيل الخروج', 'Sign Out')
                      : S.t(context, 'تسجيل الدخول', 'Sign In'),
                  icon: loggedIn ? Icons.logout_rounded : Icons.login_rounded,
                  variant: loggedIn ? 'ghost' : 'primary',
                  onPressed: () async {
                    if (loggedIn) {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(S.t(context, 'تسجيل الخروج', 'Sign Out')),
                          content: Text(S.t(
                            context,
                            'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟',
                            'Are you sure you want to sign out?',
                          )),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: Text(S.t(context, 'إلغاء', 'Cancel')),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: Text(
                                  S.t(context, 'تسجيل الخروج', 'Sign Out')),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true || !context.mounted) return;
                      GoRouter.of(context).prepareAuthEvent();
                      await AnalyticsService.instance.clearUserId();
                      await authManager.signOut();
                      if (context.mounted) {
                        context.goNamedAuth(
                          AuthenticationWidget.routeName,
                          context.mounted,
                        );
                      }
                    } else {
                      context.pushNamed(AuthenticationWidget.routeName);
                    }
                  },
                  theme: theme,
                ),
                if (isRegisteredUser) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _deletingAccount ? null : _confirmAndDeleteAccount,
                    icon: _deletingAccount
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.delete_forever_rounded, color: theme.error),
                    label: Text(
                      _deletingAccount
                          ? 'جاري حذف الحساب...'
                          : 'حذف الحساب والبيانات نهائياً',
                      style: theme.bodyMedium.copyWith(
                        color: theme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.theme});
  final String title;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: theme.titleMedium.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: theme.secondaryText,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.theme, required this.children});
  final FlutterFlowTheme theme;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        border: Border.all(color: theme.divider),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            color: theme.shadow.withValues(alpha: 0.06),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _SettingsNavRow extends StatelessWidget {
  const _SettingsNavRow({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _IconTile(icon: icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.bodyMedium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText,
                ),
              ),
            ),
            Icon(
              Icons.chevron_left_rounded,
              color: theme.secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final bool value;
  final ValueChanged<bool> onChanged;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: label,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                _IconTile(icon: icon, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.bodyMedium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: theme.primary,
            inactiveTrackColor: theme.outlineVariant,
            inactiveThumbColor: theme.surface,
          ),
        ],
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({
    required this.label,
    required this.icon,
    required this.variant,
    required this.onPressed,
    required this.theme,
  });

  final String label;
  final IconData icon;
  final String variant;
  final VoidCallback onPressed;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return ButtonWidget(
      content: label,
      variant: variant,
      size: 'medium',
      fullWidth: true,
      icon: Icon(icon, size: 22),
      iconPresent: true,
      onPressed: onPressed,
    );
  }
}

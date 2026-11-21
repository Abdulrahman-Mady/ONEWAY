import '/auth/firebase_auth/auth_util.dart';
import '/components/button/button_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'user_profile_model.dart';
import 'edit_profile_widget.dart';
export 'user_profile_model.dart';
export 'edit_profile_widget.dart';

/// Profile page: shows the signed-in user's own data (from the Firestore
/// users document) and lets them edit it.
class UserProfileWidget extends StatefulWidget {
  const UserProfileWidget({super.key});

  static String routeName = 'UserProfile';
  static String routePath = '/profile';

  @override
  State<UserProfileWidget> createState() => _UserProfileWidgetState();
}

class _UserProfileWidgetState extends State<UserProfileWidget> {
  late UserProfileModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => UserProfileModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.background,
        appBar: AppBar(
          backgroundColor: theme.background,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: true,
          title: Text(
            'حسابي',
            style: theme.titleLarge.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          actions: const [],
          centerTitle: true,
          elevation: 0,
        ),
        body: AuthUserStreamWidget(
          builder: (context) {
            final isUserLoggedIn = loggedIn;
            final data = currentUserDocument?.snapshotData ??
                const <String, dynamic>{};
            final role = currentUserDocument?.role ?? 'user';

            final displayName = (data['display_name'] as String?) ?? '';
            final userTitle = !isUserLoggedIn
                ? 'ضيف ONEWAY'
                : (displayName.isNotEmpty
                    ? displayName
                    : (currentUserEmail.isNotEmpty
                        ? currentUserEmail
                        : 'مستخدم ONEWAY'));
            final userSubTitle = isUserLoggedIn
                ? (currentUserEmail.isNotEmpty
                    ? currentUserEmail
                    : 'حساب مفعل على Firebase')
                : 'وضع العرض التجريبي كزائر';

            return SafeArea(
              top: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius:
                            BorderRadius.circular(theme.designToken.radius.xl),
                        border:
                            Border.all(color: theme.outlineVariant, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor:
                                theme.primary.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.person_rounded,
                              color: theme.primary,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            userTitle,
                            textAlign: TextAlign.center,
                            style: theme.titleLarge.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: theme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userSubTitle,
                            textAlign: TextAlign.center,
                            style: theme.bodyMedium.copyWith(
                              fontSize: 14,
                              color: theme.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (!isUserLoggedIn)
                            ButtonWidget(
                              content: 'تسجيل الدخول / إنشاء حساب',
                              variant: 'primary',
                              size: 'large',
                              fullWidth: true,
                              onPressed: () => context
                                  .pushNamed(AuthenticationWidget.routeName),
                            )
                          else ...[
                            ButtonWidget(
                              content: 'تعديل البيانات الشخصية',
                              variant: 'primary',
                              size: 'large',
                              fullWidth: true,
                              icon: Icon(Icons.edit_outlined,
                                  color: theme.onPrimary, size: 20),
                              iconPresent: true,
                              onPressed: () => context
                                  .pushNamed(EditProfileWidget.routeName),
                            ),
                            const SizedBox(height: 12),
                            ButtonWidget(
                              content: 'تسجيل الخروج',
                              variant: 'destructive',
                              size: 'large',
                              fullWidth: true,
                              onPressed: () async {
                                GoRouter.of(context).prepareAuthEvent();
                                await authManager.signOut();
                                if (context.mounted) {
                                  context.goNamedAuth(
                                      AuthenticationWidget.routeName,
                                      context.mounted);
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Personal data card
                    if (isUserLoggedIn) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.surface,
                          borderRadius: BorderRadius.circular(
                              theme.designToken.radius.xl),
                          border: Border.all(
                              color: theme.outlineVariant, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'البيانات الشخصية',
                              style: theme.titleMedium.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: theme.primaryText,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.phone_outlined,
                              label: 'رقم الهاتف',
                              value: (data['phone_number'] as String?) ?? '',
                              theme: theme,
                            ),
                            _InfoRow(
                              icon: Icons.wc_outlined,
                              label: 'النوع',
                              value: (data['gender'] as String?) ?? '',
                              theme: theme,
                            ),
                            _InfoRow(
                              icon: Icons.cake_outlined,
                              label: 'تاريخ الميلاد',
                              value: _formatBirthDate(data['birth_date']),
                              theme: theme,
                            ),
                            _InfoRow(
                              icon: Icons.location_on_outlined,
                              label: 'العنوان',
                              value: (data['address'] as String?) ?? '',
                              theme: theme,
                            ),
                            _InfoRow(
                              icon: Icons.map_outlined,
                              label: 'المحافظة',
                              value: (data['governorate'] as String?) ?? '',
                              theme: theme,
                            ),
                            _InfoRow(
                              icon: Icons.accessible_forward_rounded,
                              label: 'نوع الحركة',
                              value: (data['mobility_type'] as String?) ?? '',
                              theme: theme,
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    // Action Buttons
                    _ProfileActionButton(
                      label: 'المفضلة',
                      icon: Icons.favorite_outline_rounded,
                      onPressed: () =>
                          context.pushNamed(FavoritesPageWidget.routeName),
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    _ProfileActionButton(
                      label: 'الإشعارات',
                      icon: Icons.notifications_outlined,
                      onPressed: () =>
                          context.pushNamed(NotificationsPageWidget.routeName),
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    _ProfileActionButton(
                      label: 'الإعدادات',
                      icon: Icons.settings_outlined,
                      onPressed: () =>
                          context.pushNamed(SettingsPageWidget.routeName),
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    _ProfileActionButton(
                      label: 'المساعدة والدعم',
                      icon: Icons.help_outline_rounded,
                      onPressed: () =>
                          context.pushNamed(HelpSupportPageWidget.routeName),
                      theme: theme,
                    ),
                    if (role == 'businessOwner') ...[
                      const SizedBox(height: 12),
                      _ProfileActionButton(
                        label: 'لوحة الأعمال',
                        icon: Icons.business_outlined,
                        onPressed: () => context.pushNamed(
                            BusinessAdminDashboardWidget.routeName),
                        theme: theme,
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Status Text
                    Text(
                      isUserLoggedIn
                          ? 'بيانات الحساب مسجلة ومتزامنة مع Firebase.'
                          : 'سجل الدخول لحفظ تفضيلاتك وأماكنك المفضلة.',
                      textAlign: TextAlign.center,
                      style: theme.bodySmall.copyWith(
                        fontSize: 12,
                        color: theme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static String _formatBirthDate(dynamic raw) {
    if (raw is DateTime) {
      return '${raw.day}/${raw.month}/${raw.year}';
    }
    return '';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final FlutterFlowTheme theme;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final shown = value.trim().isEmpty ? 'غير محدد' : value.trim();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: theme.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.bodyMedium.copyWith(
                  fontSize: 14,
                  color: theme.secondaryText,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  shown,
                  textAlign: TextAlign.end,
                  style: theme.bodyMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: value.trim().isEmpty
                        ? theme.hintText
                        : theme.primaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(color: theme.divider, height: 1),
      ],
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.theme,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return ButtonWidget(
      content: label,
      variant: 'outline',
      size: 'medium',
      fullWidth: true,
      icon: Icon(icon, size: 22),
      iconPresent: true,
      onPressed: onPressed,
    );
  }
}

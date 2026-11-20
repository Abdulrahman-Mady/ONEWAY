import '/auth/firebase_auth/auth_util.dart';
import '/components/button/button_widget.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_profile_model.dart';
export 'user_profile_model.dart';

/// DSL page UserProfile
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
            final userTitle = isUserLoggedIn
                ? (currentUserDisplayName.isNotEmpty
                    ? currentUserDisplayName
                    : (currentUserEmail.isNotEmpty
                        ? currentUserEmail
                        : 'مستخدم ONEWAY'))
                : 'ضيف ONEWAY';
            final userSubTitle = isUserLoggedIn
                ? (currentUserEmail.isNotEmpty
                    ? currentUserEmail
                    : 'حساب مفعل على Firebase')
                : 'وضع العرض التجريبي كزائر';

            return SafeArea(
              top: true,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Header
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.surface,
                          borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
                          border: Border.all(color: theme.outlineVariant, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: theme.primary.withValues(alpha: 0.1),
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
                                onPressed: () =>
                                    context.pushNamed(AuthenticationWidget.routeName),
                              )
                            else
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
                        ),
                      ),
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
                      const SizedBox(height: 12),
                      _ProfileActionButton(
                        label: 'لوحة الأعمال',
                        icon: Icons.business_outlined,
                        onPressed: () =>
                            context.pushNamed(BusinessAdminDashboardWidget.routeName),
                        theme: theme,
                      ),
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
              ),
            );
          },
        ),
      ),
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

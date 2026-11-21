import '/auth/firebase_auth/auth_util.dart';
import '/components/button/button_widget.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_page_model.dart';
export 'settings_page_model.dart';

/// DSL page SettingsPage
class SettingsPageWidget extends StatefulWidget {
  const SettingsPageWidget({super.key});

  static String routeName = 'SettingsPage';
  static String routePath = '/settings';

  @override
  State<SettingsPageWidget> createState() => _SettingsPageWidgetState();
}

class _SettingsPageWidgetState extends State<SettingsPageWidget> {
  late SettingsPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SettingsPageModel());

    _model.toggleValue1 = _model.largeText!;
    _model.toggleValue2 = _model.highContrast!;
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
            'الإعدادات',
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
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إعدادات العرض على هذا الجهاز',
                    style: theme.titleMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
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
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _SettingsToggle(
                            label: 'نص كبير',
                            icon: Icons.text_fields_rounded,
                            iconColor: theme.primary,
                            value: _model.toggleValue1!,
                            onChanged: (value) => safeSetState(() => _model.toggleValue1 = value),
                            theme: theme,
                          ),
                        ),
                        Divider(height: 1, color: theme.divider, indent: 16, endIndent: 16),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _SettingsToggle(
                            label: 'تباين مرتفع',
                            icon: Icons.contrast_rounded,
                            iconColor: theme.gold,
                            value: _model.toggleValue2!,
                            onChanged: (value) => safeSetState(() => _model.toggleValue2 = value),
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
                      border: Border.all(color: theme.outlineVariant, width: 1.5),
                    ),
                    child: Text(
                      'هذه الخيارات تجريبية ولا تغيّر إعدادات النظام أو حجم النص في كامل التطبيق بعد.',
                      style: theme.bodySmall.copyWith(
                        fontSize: 12,
                        color: theme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (currentUserIsAdmin)
                    _SettingsButton(
                      label: 'لوحة تحكم الإدارة (Admin Portal) 🛡️',
                      icon: Icons.admin_panel_settings,
                      variant: 'secondary',
                      onPressed: () => context.pushNamed('AdminDashboard'),
                      theme: theme,
                    ),
                  const SizedBox(height: 12),
                  _SettingsButton(
                    label: 'الملف الشخصي ونوع الحساب',
                    icon: Icons.person_rounded,
                    variant: 'outline',
                    onPressed: () => context.pushNamed(UserProfileWidget.routeName),
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _SettingsButton(
                    label: 'المساعدة والدعم',
                    icon: Icons.help_outline_rounded,
                    variant: 'primary',
                    onPressed: () => context.pushNamed(HelpSupportPageWidget.routeName),
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _SettingsButton(
                    label: loggedIn ? 'تسجيل الخروج' : 'تسجيل الدخول',
                    icon: Icons.logout_rounded,
                    variant: loggedIn ? 'ghost' : 'primary',
                    onPressed: () async {
                      if (loggedIn) {
                        GoRouter.of(context).prepareAuthEvent();
                        await authManager.signOut();
                        context.goNamedAuth(AuthenticationWidget.routeName, context.mounted);
                      } else {
                        context.pushNamed(AuthenticationWidget.routeName);
                      }
                    },
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.bodyMedium.copyWith(
                fontSize: 15,
                color: theme.primaryText,
              ),
            ),
          ],
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: theme.primary,
          inactiveTrackColor: theme.outlineVariant,
          inactiveThumbColor: theme.surface,
        ),
      ],
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
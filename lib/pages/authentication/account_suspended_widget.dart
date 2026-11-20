import '/components/button/button_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart'
    show FlutterFlowTheme;
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AccountSuspendedWidget extends StatefulWidget {
  const AccountSuspendedWidget({super.key});

  static String routeName = 'AccountSuspended';
  static String routePath = '/account-suspended';

  @override
  State<AccountSuspendedWidget> createState() => _AccountSuspendedWidgetState();
}

class _AccountSuspendedWidgetState extends State<AccountSuspendedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _suspensionReason = '';
  String _suspendedAt = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouter.of(context).routerDelegate.currentConfiguration.uri.queryParameters;
      _suspensionReason = extra['suspensionReason'] ?? '';
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Suspension icon
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: theme.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: theme.error,
                        size: 70,
                      ),
                    ).animate().scale(duration: Duration(milliseconds: 600), curve: Curves.elasticOut),
                    const SizedBox(height: 32),
                    // Title
                    Text(
                      'الحساب معلق',
                      style: theme.headlineSmall.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: theme.error,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Message
                    Text(
                      'تم تعليق حسابك مؤقتاً ولا يمكنك الوصول للتطبيق في الوقت الحالي.',
                      style: theme.bodyLarge.copyWith(
                        fontSize: 16,
                        color: theme.secondaryText,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // Reason
                    if (_suspensionReason.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Card(
                        color: theme.error.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
                          side: BorderSide(color: theme.error.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, color: theme.error, size: 24),
                                  const SizedBox(width: 12),
                                  Text(
                                    'سبب التعليق:',
                                    style: theme.labelMedium.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.error,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _suspensionReason,
                                style: theme.bodyMedium.copyWith(
                                  fontSize: 14,
                                  color: theme.primaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    // Actions
                    Column(
                      children: [
                        ButtonWidget(
                          content: 'التواصل مع الدعم',
                          variant: 'primary',
                          size: 'large',
                          fullWidth: true,
                          iconEnd: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 24),
                          iconEndPresent: true,
                          onPressed: _contactSupport,
                        ),
                        const SizedBox(height: 16),
                        ButtonWidget(
                          content: 'محاولة تسجيل الدخول مرة أخرى',
                          variant: 'outline',
                          size: 'medium',
                          fullWidth: true,
                          onPressed: () => context.pushNamed(AuthenticationWidget.routeName),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _logout,
                          child: Text(
                            'تسجيل الخروج',
                            style: theme.labelLarge.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.tertiaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _contactSupport() async {
    // Navigate to help/support page
    context.pushNamed(HelpSupportPageWidget.routeName);
  }

  Future<void> _logout() async {
    await AuthService.instance.signOut();
    if (mounted) {
      context.pushNamed(AuthenticationWidget.routeName);
    }
  }
}
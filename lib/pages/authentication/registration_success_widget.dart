import '/components/button/button_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart'
    show FlutterFlowTheme;
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class RegistrationSuccessWidget extends StatefulWidget {
  const RegistrationSuccessWidget({super.key});

  static String routeName = 'RegistrationSuccess';
  static String routePath = '/register/success';

  @override
  State<RegistrationSuccessWidget> createState() => _RegistrationSuccessWidgetState();
}

class _RegistrationSuccessWidgetState extends State<RegistrationSuccessWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _email = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouter.of(context).routerDelegate.currentConfiguration.uri.queryParameters;
      _email = extra['email'] ?? '';
      _phone = extra['phone'] ?? '';
    });

    _animationController.forward();

    // Auto-navigate after delay
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        AuthRouter.instance.navigateAfterRegistration(context);
      }
    });
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: theme.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: theme.success,
                      size: 80,
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                ),
              ),
              const SizedBox(height: 32),
              // Title
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Text(
                    'تم إنشاء حسابك بنجاح!',
                    style: theme.headlineSmall.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: theme.primaryText,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 500.ms, delay: 400.ms).slideY(begin: 0.2),
                ),
              ),
              const SizedBox(height: 16),
              // Subtitle
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Text(
                    'مرحباً بك في OneWay\nيمكنك الآن استكشاف الأماكن المجهزة في مصر',
                    style: theme.bodyLarge.copyWith(
                      fontSize: 16,
                      color: theme.secondaryText,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 500.ms, delay: 500.ms).slideY(begin: 0.2),
                ),
              ),
              const SizedBox(height: 32),
              // Info cards
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      _buildInfoCard(
                        theme,
                        icon: Icons.email_outlined,
                        label: 'البريد الإلكتروني',
                        value: _maskEmail(_email),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        theme,
                        icon: Icons.phone_outlined,
                        label: 'رقم الهاتف',
                        value: _maskPhone(_phone),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms, delay: 600.ms).slideY(begin: 0.2),
                ),
              ),
              const SizedBox(height: 40),
              // Continue button
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ButtonWidget(
                    content: 'ابدأ الاستكشاف',
                    variant: 'primary',
                    size: 'large',
                    fullWidth: true,
                    iconEnd: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
                    iconEndPresent: true,
                    onPressed: () => AuthRouter.instance.navigateAfterRegistration(context),
                  ).animate().fadeIn(duration: 500.ms, delay: 800.ms).slideY(begin: 0.2),
                ),
              ),
              const SizedBox(height: 16),
              // Auto redirect text
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'سيتم تحويلك تلقائياً خلال لحظات...',
                  style: theme.labelSmall.copyWith(
                    fontSize: 12,
                    color: theme.tertiaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(FlutterFlowTheme theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        border: Border.all(color: theme.outlineVariant, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
            ),
            child: Icon(icon, color: theme.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.labelSmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.tertiaryText,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: theme.bodyMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _maskEmail(String email) {
    if (email.isEmpty) return 'غير محدد';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return email;
    return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}@$domain';
  }

  String _maskPhone(String phone) {
    if (phone.isEmpty) return 'غير محدد';
    if (phone.length <= 4) return phone;
    return '${phone.substring(0, 3)}${'*' * (phone.length - 7)}${phone.substring(phone.length - 4)}';
  }
}
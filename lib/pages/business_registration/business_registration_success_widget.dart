import '/components/button/button_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart'
    show FlutterFlowTheme;
import '/flutter_flow/flutter_flow_util.dart'
    show
        FlutterFlowTheme;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class BusinessRegistrationSuccessWidget extends StatefulWidget {
  const BusinessRegistrationSuccessWidget({super.key});

  static String routeName = 'BusinessRegistrationSuccess';
  static String routePath = '/business/register/success';

  @override
  State<BusinessRegistrationSuccessWidget> createState() => _BusinessRegistrationSuccessWidgetState();
}

class _BusinessRegistrationSuccessWidgetState extends State<BusinessRegistrationSuccessWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _businessId = '';
  String _businessName = '';

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
      if (!mounted) return;
      final state = GoRouterState.of(context);
      final extraMap = state.extra is Map ? state.extra as Map : const {};
      final queryParams = state.uri.queryParameters;
      setState(() {
        _businessId = (extraMap['businessId'] as String?) ??
            queryParams['businessId'] ??
            '';
        _businessName = (extraMap['businessName'] as String?) ??
            queryParams['businessName'] ??
            '';
      });
    });

    _animationController.forward();

    // Auto-navigate after delay
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        context.pushNamed(BusinessApplicationStatusWidget.routeName);
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
                    'تم تقديم طلبك بنجاح!',
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
                    'طلب تسجيل "${_businessName.isEmpty ? 'منشأتك' : _businessName}" قيد المراجعة الآن.\nسيتواصل معك فريق OneWay خلال 2-3 أيام عمل.',
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
              // Info card
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Card(
                    color: theme.primary.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
                      side: BorderSide(color: theme.primary.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
                                ),
                                child: Icon(
                                  Icons.pending_actions_rounded,
                                  color: theme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'رقم الطلب',
                                      style: theme.labelSmall.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: theme.tertiaryText,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      _businessId.isEmpty
                                          ? 'جاري الإنشاء...'
                                          : (_businessId.length > 8
                                                  ? _businessId.substring(0, 8)
                                                  : _businessId)
                                              .toUpperCase(),
                                      style: theme.bodyMedium.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: theme.primaryText,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 18,
                                color: theme.tertiaryText,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'وقت المراجعة المتوقع: 2-3 أيام عمل',
                                style: theme.bodySmall.copyWith(
                                  fontSize: 13,
                                  color: theme.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 600.ms).slideY(begin: 0.2),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Buttons
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      ButtonWidget(
                        content: 'متابعة حالة الطلب',
                        variant: 'primary',
                        size: 'large',
                        fullWidth: true,
                        iconEnd: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
                        iconEndPresent: true,
                        onPressed: () => context.pushNamed(BusinessApplicationStatusWidget.routeName),
                      ).animate().fadeIn(duration: 500.ms, delay: 800.ms).slideY(begin: 0.2),
                      const SizedBox(height: 12),
                      ButtonWidget(
                        content: 'العودة للرئيسية',
                        variant: 'outline',
                        size: 'medium',
                        fullWidth: true,
                        onPressed: () => context.goNamed(HomeDashboardWidget.routeName),
                      ).animate().fadeIn(duration: 500.ms, delay: 900.ms).slideY(begin: 0.2),
                    ],
                  ).animate().fadeIn(duration: 500.ms, delay: 700.ms).slideY(begin: 0.2),
                ),
              ),
              const SizedBox(height: 16),
              // Auto redirect text
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'سيتم تحويلك تلقائياً إلى حالة الطلب...',
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
}
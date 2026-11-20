import '/components/button/button_widget.dart';
import '/components/dot/dot_widget.dart';
import '/components/onboarding_slide/onboarding_slide_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'splash_onboarding_model.dart';
export 'splash_onboarding_model.dart';

class SplashOnboardingWidget extends StatefulWidget {
  const SplashOnboardingWidget({super.key});

  static String routeName = 'SplashOnboarding';
  static String routePath = '/splashOnboarding';

  @override
  State<SplashOnboardingWidget> createState() => _SplashOnboardingWidgetState();
}

class _SplashOnboardingWidgetState extends State<SplashOnboardingWidget>
    with SingleTickerProviderStateMixin {
  late SplashOnboardingModel _model;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SplashOnboardingModel());
    _pageController = PageController();

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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _model.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.goNamed(AuthenticationWidget.routeName);
    }
  }

  void _skipOnboarding() {
    context.goNamed(AuthenticationWidget.routeName);
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
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Stack(
              children: [
                // Decorative background element
                Positioned(
                  top: -150,
                  right: -150,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.05),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(300),
                      ),
                    ),
                  ),
                ),
                // Main content
                SafeArea(
                  child: Column(
                    children: [
                      // Skip button
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _skipOnboarding,
                              child: Text(
                                'تخطي',
                                style: theme.labelLarge.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: theme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Page view
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (index) {
                            safeSetState(() => _currentPage = index);
                          },
                          children: const [
                            OnboardingSlideWidget(
                              title: 'اعرف المكان قبل ما تروح',
                              desc:
                                  'استكشف المطاعم، المستشفيات، والمراكز التجارية المجهزة لاستقبالك بكل سهولة.',
                              lottieDesc:
                                  'https://dimg.dreamflow.cloud/v1/lottie/wheelchair+user+exploring+city+map',
                            ),
                            OnboardingSlideWidget(
                              title: 'فلاتر ذكية للإتاحة',
                              desc:
                                  'اختر ما يناسبك: منحدر، مصعد مجهز، حمام مناسب، موقف سيارات، والمزيد.',
                              lottieDesc:
                                  'https://dimg.dreamflow.cloud/v1/lottie/accessibility+filters+mobile+app',
                            ),
                            OnboardingSlideWidget(
                              title: 'مجتمع يشارك الخبرات',
                              desc:
                                  'أضف تقييمك، أبلغ عن عائق، وساعد الآخرين في اتخاذ قرارات أفضل.',
                              lottieDesc:
                                  'https://dimg.dreamflow.cloud/v1/lottie/community+sharing+accessibility+reviews',
                            ),
                          ],
                        ),
                      ),
                      // Bottom section
                      Container(
                        decoration: BoxDecoration(
                          color: theme.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 20,
                              color: theme.shadow.withValues(alpha: 0.1),
                              offset: const Offset(0, -4),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Page indicators
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (index) {
                                return DotWidget(
                                  currentIndex: _currentPage,
                                  index: index,
                                );
                              }),
                            ),
                            const SizedBox(height: 32),
                            // Next/Get Started button
                            Row(
                              children: [
                                Expanded(
                                  child: ButtonWidget(
                                    content: _currentPage == 2
                                        ? 'ابدأ الآن'
                                        : 'التالي',
                                    variant: 'primary',
                                    size: 'large',
                                    fullWidth: true,
                                    iconEnd: Icon(
                                      _currentPage == 2
                                          ? Icons.arrow_forward_rounded
                                          : Icons.arrow_forward_rounded,
                                      color: theme.onPrimary,
                                      size: 24,
                                    ),
                                    iconEndPresent: true,
                                    onPressed: _nextPage,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
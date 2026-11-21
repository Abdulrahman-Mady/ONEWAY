import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> _markSeenAndContinue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kOnboardingSeenKey, true);
    } catch (_) {}
    if (mounted) context.goNamed(AuthenticationWidget.routeName);
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _markSeenAndContinue();
    }
  }

  void _skipOnboarding() {
    _markSeenAndContinue();
  }

  static const _slides = <(String, String)>[
    (
      'اعرف المكان قبل ما تروح',
      'استكشف المطاعم، المستشفيات، والمراكز التجارية المجهزة لاستقبالك بكل سهولة.',
    ),
    (
      'فلاتر ذكية للإتاحة',
      'اختر ما يناسبك: منحدر، مصعد مجهز، حمام مناسب، موقف سيارات، والمزيد.',
    ),
    (
      'مجتمع يشارك الخبرات',
      'أضف تقييمك، أبلغ عن عائق، وساعد الآخرين في اتخاذ قرارات أفضل.',
    ),
  ];

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
        backgroundColor: theme.navy,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Top: full-bleed Cairo hero with the wheelchair traveler.
                Expanded(
                  flex: 52,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/onboarding_hero.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                      // Fade into the sheet color at the bottom.
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 70,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                theme.navy.withValues(alpha: 0),
                                theme.navy,
                              ],
                            ),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Align(
                          alignment: AlignmentDirectional.topEnd,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: TextButton(
                              onPressed: _skipOnboarding,
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.3),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                'تخطي',
                                style: theme.labelLarge.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom: navy sheet with slide copy, dots and action.
                Expanded(
                  flex: 48,
                  child: Container(
                    color: theme.navy,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                    child: Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _slides.length,
                            onPageChanged: (index) {
                              safeSetState(() => _currentPage = index);
                            },
                            itemBuilder: (context, index) {
                              final (title, desc) = _slides[index];
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: theme.headlineSmall.copyWith(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    desc,
                                    textAlign: TextAlign.center,
                                    style: theme.bodyLarge.copyWith(
                                      fontSize: 15,
                                      color: Colors.white
                                          .withValues(alpha: 0.78),
                                      height: 1.7,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_slides.length, (index) {
                            final active = _currentPage == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              width: active ? 26 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: active
                                    ? theme.gold
                                    : Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _currentPage == 2 ? 'ابدأ الآن' : 'التالي',
                              style: theme.titleMedium.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
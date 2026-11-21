import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    if (_currentPage < _slides.length - 1) {
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
      'مصر بدون عوائق',
      'دليلك الذكي للوصول إلى الأماكن المهيأة لذوي الإعاقة وكبار السن',
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
        backgroundColor: theme.background,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Brand row on the light canvas.
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'assets/images/oneway_logo_mark.jpg',
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'ONE',
                                style: GoogleFonts.cairo(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: theme.navy,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              TextSpan(
                                text: 'WAY',
                                style: GoogleFonts.cairo(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: theme.primary,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Illustrated hero: wheelchair traveler facing Cairo.
                Expanded(
                  flex: 46,
                  child: Image.asset(
                    'assets/images/onboarding_hero.jpg',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
                // Teal wave separating the art from the white sheet.
                ClipPath(
                  clipper: _OnboardingWaveClipper(),
                  child: Container(height: 24, color: theme.primary),
                ),
                // White sheet: slide copy, dots, teal CTA, skip.
                Expanded(
                  flex: 54,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: Colors.white),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
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
                                          color: theme.navy,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        desc,
                                        textAlign: TextAlign.center,
                                        style: theme.bodyLarge.copyWith(
                                          fontSize: 15,
                                          color: theme.secondaryText,
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
                              children:
                                  List.generate(_slides.length, (index) {
                                final active = _currentPage == index;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  width: active ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? theme.primary
                                        : theme.secondaryText
                                            .withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _nextPage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _currentPage == _slides.length - 1
                                          ? 'ابدأ الآن'
                                          : 'التالي',
                                      style: theme.titleMedium.copyWith(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (_currentPage < _slides.length - 1) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_back,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: _skipOnboarding,
                              child: Text(
                                'تخطي',
                                style: theme.labelLarge.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.secondaryText,
                                ),
                              ),
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

/// Wavy top edge for the teal strip above the onboarding sheet.
class _OnboardingWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(0, 0);
    path.lineTo(0, size.height * 0.6);
    path.quadraticBezierTo(
        size.width * 0.25, size.height, size.width * 0.5, size.height * 0.55);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.1, size.width, size.height * 0.5);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

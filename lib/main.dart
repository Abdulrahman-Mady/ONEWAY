import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';

import 'backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';

/// Builds the single Material theme for the whole app from the brand
/// palette in FlutterFlowTheme, so every screen (including admin and
/// account pages that use plain Material widgets) shares one look.
ThemeData _buildBrandedTheme(FlutterFlowTheme brand, Brightness brightness) {
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  final cairoText = GoogleFonts.cairoTextTheme(base.textTheme);
  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    primaryColor: brand.primary,
    scaffoldBackgroundColor: brand.background,
    fontFamily: GoogleFonts.cairo().fontFamily,
    textTheme: cairoText,
    colorScheme: ColorScheme.fromSeed(
      seedColor: brand.primary,
      brightness: brightness,
      primary: brand.primary,
      secondary: brand.secondary,
      tertiary: brand.tertiary,
      error: brand.error,
      surface: brand.surface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: brand.primary,
      foregroundColor: brand.onPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.cairo(
        color: brand.onPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: brand.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: brand.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brand.primary,
        foregroundColor: brand.onPrimary,
        minimumSize: const Size(48, 52),
        elevation: 0,
        textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: brand.primary,
        minimumSize: const Size(48, 52),
        side: BorderSide(color: brand.primary, width: 1.5),
        textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: brand.primary,
        textStyle: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: brand.surfaceVariant,
      hintStyle: GoogleFonts.cairo(color: brand.hintText, fontSize: 14),
      labelStyle: GoogleFonts.cairo(color: brand.secondaryText, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: brand.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: brand.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: brand.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: brand.error, width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: brand.onBackground,
      contentTextStyle: GoogleFonts.cairo(color: brand.background, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: brand.surface,
      titleTextStyle: GoogleFonts.cairo(
        color: brand.primaryText,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: brand.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: brand.primary,
      unselectedLabelColor: brand.secondaryText,
      indicatorColor: brand.primary,
      labelStyle: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700),
      unselectedLabelStyle:
          GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    dividerTheme: DividerThemeData(color: brand.divider, thickness: 1),
    iconTheme: IconThemeData(color: brand.onSurfaceVariant),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: brand.tertiary,
      foregroundColor: brand.onPrimary,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: brand.primary,
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  // Initialize Firebase
  await initFirebase();

  // Initialize theme
  await FlutterFlowTheme.initialize();

  // Initialize app state
  final appState = FFAppState();
  await appState.initializePersistedState();

  // Set up error handling
  if (!kIsWeb) {
    FlutterError.onError = (details) {
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    };
  }

  runApp(ChangeNotifierProvider(
    create: (context) => appState,
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  State<MyApp> createState() => MyAppState();

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatchBase? routeMatch]) {
    final RouteMatchBase lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.path;
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();
  late Stream<BaseAuthUser> userStream;

  final authUserSub = authenticatedUserStream.listen((_) {});

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    userStream = oneWayEgyptFirebaseUserStream()
      ..listen((user) {
        _appStateNotifier.update(user);
      });
    jwtTokenStream.listen((_) {});
    Future.delayed(
      const Duration(milliseconds: 1000),
      () => _appStateNotifier.stopShowingSplashImage(),
    );
  }

  @override
  void dispose() {
    authUserSub.cancel();

    super.dispose();
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ONEWAY - مصر بدون عوائق',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''),
        Locale('en', ''),
      ],
      locale: const Locale('ar', ''),
      theme: _buildBrandedTheme(LightModeTheme(), Brightness.light),
      darkTheme: _buildBrandedTheme(DarkModeTheme(), Brightness.dark),
      themeMode: _themeMode,
      routerConfig: _router,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                  MediaQuery.of(context).textScaler.scale(1.0).clamp(0.85, 1.3)),
            ),
            child: child!,
          ),
        );
      },
    );
  }
}

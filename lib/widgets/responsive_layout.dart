import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// Breakpoints & responsive sizing helpers so every screen adapts cleanly
/// across small phones (320px), standard phones (360-430px), foldables,
/// tablets (600px+), and landscape orientations without RenderFlex overflows.
class OnewayResponsive {
  OnewayResponsive._();

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 360) return 14;
    if (w < 600) return 20;
    return 28;
  }

  /// Max readable content width for phone-first layouts on tablets/desktop.
  static double maxContentWidth(BuildContext context) =>
      isTablet(context) ? 620 : double.infinity;

  /// Number of columns for quick-action or card grids.
  static int gridColumns(BuildContext context, {int phone = 2, int tablet = 4}) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 720) return tablet;
    if (w >= 520) return 3;
    return phone;
  }

  /// Responsive hero image height bounded safely by screen height.
  static double boundedHeight(
    BuildContext context, {
    required double fraction,
    required double min,
    required double max,
  }) {
    final h = MediaQuery.sizeOf(context).height;
    return (h * fraction).clamp(min, max);
  }
}

/// Constrains page content cleanly on wide screens while filling phones edge-to-edge.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 600,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    return Align(
      alignment: Alignment.topCenter,
      child: content,
    );
  }
}

/// Crisp, artifact-free ONEWAY brand emblem + wordmark using the studio app icon.
class OnewayBrandLockup extends StatelessWidget {
  const OnewayBrandLockup({
    super.key,
    this.iconSize = 44,
    this.fontSize = 22,
    this.lightText = true,
    this.vertical = false,
  });

  final double iconSize;
  final double fontSize;
  final bool lightText;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final iconWidget = Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(iconSize * 0.26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/app_icon_1024.png',
        width: iconSize,
        height: iconSize,
        fit: BoxFit.cover,
      ),
    );

    final wordmark = RichText(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        children: [
          TextSpan(
            text: 'ONE',
            style: GoogleFonts.cairo(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: lightText ? Colors.white : theme.navy,
              letterSpacing: 1.5,
              height: 1.1,
            ),
          ),
          TextSpan(
            text: 'WAY',
            style: GoogleFonts.cairo(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: lightText ? const Color(0xFF2DD4BF) : theme.primary,
              letterSpacing: 1.5,
              height: 1.1,
            ),
          ),
        ],
      ),
    );

    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(height: 10),
          wordmark,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        const SizedBox(width: 10),
        wordmark,
      ],
    );
  }
}

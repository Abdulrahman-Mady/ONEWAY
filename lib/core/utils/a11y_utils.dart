import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility (WCAG 2.2 AA) and reduced-motion utilities for ONEWAY.
class A11yUtils {
  A11yUtils._();

  /// Announces a dynamic status update to TalkBack / VoiceOver live regions.
  static void announce(BuildContext context, String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;
    try {
      final dir = Directionality.maybeOf(context) ?? TextDirection.rtl;
      SemanticsService.announce(trimmed, dir);
    } catch (_) {
      // Safe no-op in headless widget test environments.
    }
  }

  /// Returns true when the OS or user prefers reduced motion.
  static bool prefersReducedMotion(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    if (mq == null) return false;
    return mq.disableAnimations || mq.accessibleNavigation;
  }

  /// Returns [Duration.zero] when reduced motion is enabled, otherwise [normal].
  static Duration effectiveDuration(
    BuildContext context,
    Duration normal,
  ) {
    return prefersReducedMotion(context) ? Duration.zero : normal;
  }

  /// Computes relative luminance according to WCAG 2.1 specification.
  static double relativeLuminance(Color color) {
    double linearize(double channel) {
      return channel <= 0.03928
          ? channel / 12.92
          : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = linearize(color.r);
    final g = linearize(color.g);
    final b = linearize(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Computes WCAG 2.1 contrast ratio between [foreground] and [background].
  /// Returns a value in `[1.0, 21.0]`.
  static double contrastRatio(Color foreground, Color background) {
    final l1 = relativeLuminance(foreground);
    final l2 = relativeLuminance(background);
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Returns true if [foreground] on [background] passes WCAG 2.1 AA
  /// (>= 4.5:1 for normal text, >= 3.0:1 for large text).
  static bool meetsWcagAA(
    Color foreground,
    Color background, {
    bool largeText = false,
  }) {
    final threshold = largeText ? 3.0 : 4.5;
    return contrastRatio(foreground, background) >= threshold;
  }
}

/// Ensures any interactive icon/chip satisfies the 48x48dp minimum touch target
/// and provides a clear screen-reader [Semantics] label.
class AccessibleTouchTarget extends StatelessWidget {
  const AccessibleTouchTarget({
    super.key,
    required this.child,
    this.semanticLabel,
    this.semanticHint,
    this.isButton = true,
    this.minSize = 48.0,
  });

  final Widget child;
  final String? semanticLabel;
  final String? semanticHint;
  final bool isButton;
  final double minSize;

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: Center(widthFactor: 1.0, heightFactor: 1.0, child: child),
    );

    if (semanticLabel != null) {
      content = Semantics(
        button: isButton,
        label: semanticLabel,
        hint: semanticHint,
        child: content,
      );
    }

    return content;
  }
}

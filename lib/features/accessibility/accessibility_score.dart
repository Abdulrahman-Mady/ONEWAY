import 'package:flutter/material.dart';

import '/app_state.dart';
import '/backend/schema/places_record.dart';
import '/backend/schema/structs/accessibility_features_struct.dart';
import '/core/theme/oneway_theme.dart';
import '/l10n/app_strings.dart';

/// Wheelmap-style 3-tier traffic-light accessibility classification.
enum AccessibilityLevel {
  full, // Green — strongly accessible
  partial, // Amber — partially accessible
  limited, // Red — limited or unknown accessibility
}

/// Result of scoring a place against a specific user's mobility profile.
class CompatibilityResult {
  const CompatibilityResult({
    required this.scorePercent,
    required this.level,
    required this.availableCount,
    required this.totalFeatures,
    required this.isPersonalized,
  });

  final int scorePercent;
  final AccessibilityLevel level;
  final int availableCount;
  final int totalFeatures;
  final bool isPersonalized;

  Color get color {
    switch (level) {
      case AccessibilityLevel.full:
        return OnewayPalette.accessFull;
      case AccessibilityLevel.partial:
        return OnewayPalette.accessPartial;
      case AccessibilityLevel.limited:
        return OnewayPalette.accessLimited;
    }
  }

  Color get softBackground {
    switch (level) {
      case AccessibilityLevel.full:
        return const Color(0xFFDCFCE7);
      case AccessibilityLevel.partial:
        return const Color(0xFFFEF3C7);
      case AccessibilityLevel.limited:
        return const Color(0xFFFEE2E2);
    }
  }

  String levelLabel(BuildContext context) {
    switch (level) {
      case AccessibilityLevel.full:
        return S.t(context, 'مهيأ بالكامل', 'Fully Accessible');
      case AccessibilityLevel.partial:
        return S.t(context, 'مهيأ جزئياً', 'Partially Accessible');
      case AccessibilityLevel.limited:
        return S.t(context, 'إتاحة محدودة', 'Limited Access');
    }
  }

  String matchLabel(BuildContext context) {
    if (isPersonalized) {
      return S.t(context, 'مناسب لك $scorePercent%', '$scorePercent% Match');
    }
    return S.t(context, 'تقييم الإتاحة $scorePercent%', '$scorePercent% Access');
  }
}

/// Computes both the traffic-light accessibility tier and a personalized
/// compatibility score (%) based on the user's `mobility_type`.
class AccessibilityScorer {
  AccessibilityScorer._();

  static CompatibilityResult evaluatePlace(
    PlacesRecord place, {
    String? mobilityType,
    List<String>? accessNeeds,
  }) {
    final resolvedNeeds = accessNeeds ??
        (FFAppState().accessNeeds.isNotEmpty ? FFAppState().accessNeeds : null);
    return evaluateFeatures(
      place.accessibilityFeatures,
      mobilityType: mobilityType,
      accessNeeds: resolvedNeeds,
    );
  }

  static CompatibilityResult evaluateFeatures(
    AccessibilityFeaturesStruct features, {
    String? mobilityType,
    List<String>? accessNeeds,
  }) {
    final normalizedMobility = (mobilityType ?? '').trim().toLowerCase();
    final cleanNeeds = (accessNeeds ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    final isGeneralOnly = normalizedMobility.contains('بشكل عام') ||
        normalizedMobility.contains('general');
    final isPersonalized =
        (normalizedMobility.isNotEmpty && !isGeneralOnly) ||
            cleanNeeds.isNotEmpty;

    // Internal evidence-based weight profile (never shown as raw % in UI):
    // [entrance, ramp, elevator, restroom, parking] (sum = 100)
    List<int> weights;
    if (normalizedMobility.contains('كهرب') ||
        normalizedMobility.contains('electric')) {
      weights = [25, 30, 20, 15, 10];
    } else if (normalizedMobility.contains('يدوي') ||
        normalizedMobility.contains('كرسي') ||
        normalizedMobility.contains('wheelchair')) {
      weights = [25, 25, 20, 20, 10];
    } else if (normalizedMobility.contains('كبار') ||
        normalizedMobility.contains('عكاز') ||
        normalizedMobility.contains('مشاي') ||
        normalizedMobility.contains('بمساعدة') ||
        normalizedMobility.contains('صعوبة') ||
        normalizedMobility.contains('senior') ||
        normalizedMobility.contains('walker') ||
        normalizedMobility.contains('assisted')) {
      weights = [25, 15, 30, 20, 10];
    } else if (normalizedMobility.contains('طفل') ||
        normalizedMobility.contains('عربة') ||
        normalizedMobility.contains('stroller')) {
      weights = [30, 30, 25, 5, 10];
    } else {
      weights = [25, 25, 20, 20, 10];
    }

    final hasWideCorridor = (features.corridorWidth.trim().isNotEmpty &&
            !features.corridorWidth.contains('ضيق')) ||
        (features.hasWheelchairEntrance() && features.wheelchairEntrance);

    final flags = <bool>[
      features.hasWheelchairEntrance() && features.wheelchairEntrance,
      features.hasRamp() && features.ramp,
      features.hasSuitableElevator() && features.suitableElevator,
      features.hasAccessibleRestroom() && features.accessibleRestroom,
      features.hasAccessibleParking() && features.accessibleParking,
    ];

    // If the user explicitly selected concrete access needs, prioritize
    // matching those exact architectural requirements while keeping a 0..100 scale.
    if (cleanNeeds.isNotEmpty) {
      final needChecks = <String, bool>{
        'step_free_entrance': flags[0],
        'suitable_ramp': flags[1],
        'accessible_elevator': flags[2],
        'accessible_restroom': flags[3],
        'wide_passages': hasWideCorridor,
        'accessible_parking': flags[4],
      };
      var matchedNeeds = 0;
      var totalSelectedNeeds = 0;
      for (final need in cleanNeeds) {
        if (needChecks.containsKey(need)) {
          totalSelectedNeeds++;
          if (needChecks[need] == true) matchedNeeds++;
        }
      }
      if (totalSelectedNeeds > 0) {
        var baseScore = 0;
        for (var i = 0; i < flags.length; i++) {
          if (flags[i]) baseScore += weights[i];
        }
        final needsRatioScore =
            ((matchedNeeds / totalSelectedNeeds) * 100).round();
        // Blend 70% explicit access-needs match + 30% mobility profile baseline
        final blended = ((needsRatioScore * 0.7) + (baseScore * 0.3)).round();
        final count = flags.where((f) => f).length;
        final level = blended >= 70
            ? AccessibilityLevel.full
            : blended >= 35
                ? AccessibilityLevel.partial
                : AccessibilityLevel.limited;
        return CompatibilityResult(
          scorePercent: blended.clamp(0, 100),
          level: level,
          availableCount: count,
          totalFeatures: flags.length,
          isPersonalized: true,
        );
      }
    }

    var score = 0;
    var count = 0;
    for (var i = 0; i < flags.length; i++) {
      if (flags[i]) {
        score += weights[i];
        count++;
      }
    }

    final AccessibilityLevel level;
    if (score >= 70) {
      level = AccessibilityLevel.full;
    } else if (score >= 35) {
      level = AccessibilityLevel.partial;
    } else {
      level = AccessibilityLevel.limited;
    }

    return CompatibilityResult(
      scorePercent: score.clamp(0, 100),
      level: level,
      availableCount: count,
      totalFeatures: flags.length,
      isPersonalized: isPersonalized,
    );
  }
}

/// Compact pill badge showing personalized compatibility percentage.
class CompatibilityBadge extends StatelessWidget {
  const CompatibilityBadge({
    super.key,
    required this.result,
    this.compact = false,
  });

  final CompatibilityResult result;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: result.softBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: result.color.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            result.level == AccessibilityLevel.full
                ? Icons.verified_rounded
                : result.level == AccessibilityLevel.partial
                    ? Icons.adjust_rounded
                    : Icons.info_outline_rounded,
            size: compact ? 13 : 15,
            color: result.color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              compact ? '${result.scorePercent}%' : result.matchLabel(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w800,
                color: result.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

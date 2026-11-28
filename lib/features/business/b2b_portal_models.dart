import '/backend/schema/structs/accessibility_features_struct.dart';
import '/features/accessibility/accessibility_score.dart';

/// Four-stage B2B verification lifecycle enforced by ONEWAY.
enum B2bVerificationStage {
  unregistered,
  registeredPending,
  auditRequested,
  verifiedWithEvidence,
}

extension B2bVerificationStageX on B2bVerificationStage {
  int get stepIndex {
    switch (this) {
      case B2bVerificationStage.unregistered:
        return 0;
      case B2bVerificationStage.registeredPending:
        return 1;
      case B2bVerificationStage.auditRequested:
        return 2;
      case B2bVerificationStage.verifiedWithEvidence:
        return 3;
    }
  }

  String labelAr() {
    switch (this) {
      case B2bVerificationStage.unregistered:
        return 'غير مسجل';
      case B2bVerificationStage.registeredPending:
        return 'مسجل — بانتظار التوثيق';
      case B2bVerificationStage.auditRequested:
        return 'طلب التقييم الميداني قيد التنسيق';
      case B2bVerificationStage.verifiedWithEvidence:
        return 'موثّق بدليل ميداني';
    }
  }

  String labelEn() {
    switch (this) {
      case B2bVerificationStage.unregistered:
        return 'Unregistered';
      case B2bVerificationStage.registeredPending:
        return 'Registered — Unverified';
      case B2bVerificationStage.auditRequested:
        return 'Field Audit Pending';
      case B2bVerificationStage.verifiedWithEvidence:
        return 'Field-Verified';
    }
  }
}

/// Interactive accessibility self-assessment checklist completed by a business
/// before requesting an independent field verification audit.
class B2bSelfAssessment {
  const B2bSelfAssessment({
    this.wheelchairEntrance = false,
    this.ramp = false,
    this.suitableElevator = false,
    this.accessibleRestroom = false,
    this.accessibleParking = false,
    this.hasFacilityPhotos = false,
    this.corridorWidthNote = '',
  });

  final bool wheelchairEntrance;
  final bool ramp;
  final bool suitableElevator;
  final bool accessibleRestroom;
  final bool accessibleParking;
  final bool hasFacilityPhotos;
  final String corridorWidthNote;

  B2bSelfAssessment copyWith({
    bool? wheelchairEntrance,
    bool? ramp,
    bool? suitableElevator,
    bool? accessibleRestroom,
    bool? accessibleParking,
    bool? hasFacilityPhotos,
    String? corridorWidthNote,
  }) {
    return B2bSelfAssessment(
      wheelchairEntrance: wheelchairEntrance ?? this.wheelchairEntrance,
      ramp: ramp ?? this.ramp,
      suitableElevator: suitableElevator ?? this.suitableElevator,
      accessibleRestroom: accessibleRestroom ?? this.accessibleRestroom,
      accessibleParking: accessibleParking ?? this.accessibleParking,
      hasFacilityPhotos: hasFacilityPhotos ?? this.hasFacilityPhotos,
      corridorWidthNote: corridorWidthNote ?? this.corridorWidthNote,
    );
  }

  AccessibilityFeaturesStruct toFeaturesStruct() => AccessibilityFeaturesStruct(
        wheelchairEntrance: wheelchairEntrance,
        ramp: ramp,
        suitableElevator: suitableElevator,
        accessibleRestroom: accessibleRestroom,
        accessibleParking: accessibleParking,
        corridorWidth: corridorWidthNote,
      );

  /// Computes audit readiness score (0..100): 85% from the 5 architectural
  /// criteria + 15% from attaching photographic facility evidence.
  int get readinessPercent {
    final base = AccessibilityScorer.evaluateFeatures(toFeaturesStruct())
        .scorePercent;
    final weightedBase = (base * 0.85).round();
    final photoBonus = hasFacilityPhotos ? 15 : 0;
    return (weightedBase + photoBonus).clamp(0, 100);
  }

  /// Evaluates how well this facility matches each of the 4 core mobility groups.
  Map<String, CompatibilityResult> mobilityBreakdown() {
    final features = toFeaturesStruct();
    return {
      'electric': AccessibilityScorer.evaluateFeatures(
        features,
        mobilityType: 'كرسي متحرك كهربائي',
      ),
      'manual': AccessibilityScorer.evaluateFeatures(
        features,
        mobilityType: 'كرسي متحرك يدوي',
      ),
      'senior': AccessibilityScorer.evaluateFeatures(
        features,
        mobilityType: 'كبار السن',
      ),
      'stroller': AccessibilityScorer.evaluateFeatures(
        features,
        mobilityType: 'عربة أطفال',
      ),
    };
  }

  Map<String, dynamic> toFirestoreMap() => {
        'wheelchair_entrance': wheelchairEntrance,
        'ramp': ramp,
        'suitable_elevator': suitableElevator,
        'accessible_restroom': accessibleRestroom,
        'accessible_parking': accessibleParking,
        'has_facility_photos': hasFacilityPhotos,
        'corridor_width_note': corridorWidthNote,
        'readiness_percent': readinessPercent,
      };
}

/// Summary model of a linked branch place shown inside the B2B portal.
class B2bBranchSummary {
  const B2bBranchSummary({
    required this.placeId,
    required this.name,
    required this.category,
    required this.address,
    required this.features,
    required this.isGenuinelyVerified,
    required this.effectiveVerificationStatus,
    this.verificationEvidence = '',
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  final String placeId;
  final String name;
  final String category;
  final String address;
  final AccessibilityFeaturesStruct features;
  final bool isGenuinelyVerified;
  final String effectiveVerificationStatus;
  final String verificationEvidence;
  final double rating;
  final int reviewCount;
}

/// Immutable data snapshot rendered by [B2bVerificationDashboardView].
/// Allows clean separation from Firestore for unit/widget testing.
class B2bPortalSnapshot {
  const B2bPortalSnapshot({
    this.businessId,
    this.businessName = '',
    this.category = '',
    this.businessStatus = 'none',
    this.subscriptionTier = 'free',
    this.subscriptionStatus = 'inactive',
    this.pendingAuditStatus,
    this.branches = const [],
    this.reportsCount,
    this.reportsAccessDenied = false,
  });

  final String? businessId;
  final String businessName;
  final String category;
  final String businessStatus;
  final String subscriptionTier;
  final String subscriptionStatus;
  final String? pendingAuditStatus;
  final List<B2bBranchSummary> branches;
  final int? reportsCount;
  final bool reportsAccessDenied;

  bool get hasBusiness => businessId != null && businessId!.isNotEmpty;

  /// Enforces ONEWAY's ethical charter: a business is ONLY considered verified
  /// if at least one branch carries genuine `verification_evidence` (or the
  /// backend explicitly approved & verified the facility), NEVER because of
  /// a paid subscription tier.
  B2bVerificationStage get verificationStage {
    if (!hasBusiness) return B2bVerificationStage.unregistered;
    final anyEvidenceVerified = branches.any((b) => b.isGenuinelyVerified);
    if (anyEvidenceVerified) {
      return B2bVerificationStage.verifiedWithEvidence;
    }
    if (pendingAuditStatus == 'pending' || pendingAuditStatus == 'scheduled') {
      return B2bVerificationStage.auditRequested;
    }
    return B2bVerificationStage.registeredPending;
  }

  /// Average rating across linked branches that have ratings.
  double get averageBranchRating {
    final rated = branches.where((b) => b.rating > 0).toList();
    if (rated.isEmpty) return 0.0;
    final sum = rated.fold<double>(0.0, (acc, b) => acc + b.rating);
    return sum / rated.length;
  }

  /// Average mobility compatibility scores across all linked branches.
  /// Returns null when no branches exist yet (so UI falls back transparently
  /// to the self-assessment preview).
  Map<String, int>? averageMobilityScores() {
    if (branches.isEmpty) return null;
    const profiles = <String, String>{
      'electric': 'كرسي متحرك كهربائي',
      'manual': 'كرسي متحرك يدوي',
      'senior': 'كبار السن',
      'stroller': 'عربة أطفال',
    };
    final result = <String, int>{};
    for (final entry in profiles.entries) {
      final total = branches.fold<int>(
        0,
        (acc, b) =>
            acc +
            AccessibilityScorer.evaluateFeatures(
              b.features,
              mobilityType: entry.value,
            ).scorePercent,
      );
      result[entry.key] = (total / branches.length).round();
    }
    return result;
  }
}

/// Transparent B2B plan specification.
class B2bPlanSpec {
  const B2bPlanSpec({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.priceAr,
    required this.priceEn,
    required this.badgeAr,
    required this.badgeEn,
    required this.featuresAr,
    required this.featuresEn,
    required this.grantsBadgeOnPayment,
    this.highlighted = false,
  });

  final String id;
  final String titleAr;
  final String titleEn;
  final String priceAr;
  final String priceEn;
  final String badgeAr;
  final String badgeEn;
  final List<String> featuresAr;
  final List<String> featuresEn;

  /// Ethical invariant: MUST always be `false`. Paying never buys a badge;
  /// only passing an independent field audit with evidence earns verification.
  final bool grantsBadgeOnPayment;
  final bool highlighted;

  static const List<B2bPlanSpec> catalog = [
    B2bPlanSpec(
      id: 'free',
      titleAr: 'الباقة الأساسية (Free)',
      titleEn: 'Starter Listing (Free)',
      priceAr: '0 جنيهاً',
      priceEn: '0 EGP / Free',
      badgeAr: 'للانضمام السريع',
      badgeEn: 'Starter',
      featuresAr: [
        'إدراج فرع واحد على خريطة ONEWAY',
        'استعراض تقييم الإتاحة والتوافق الحركي',
        'تقييم ذاتي تفاعلي لمعايير الكود الهندسي',
      ],
      featuresEn: [
        'List 1 branch on the ONEWAY map',
        'View baseline accessibility & mobility scores',
        'Interactive architectural self-assessment',
      ],
      grantsBadgeOnPayment: false,
    ),
    B2bPlanSpec(
      id: 'field_audit',
      titleAr: 'التقييم الميداني المستقل (One-Time)',
      titleEn: 'Independent Field Audit (One-Time)',
      priceAr: '5,000 جنيهاً / للفرع',
      priceEn: '5,000 EGP / branch',
      badgeAr: 'الأكثر طلباً',
      badgeEn: 'Most Popular',
      highlighted: true,
      featuresAr: [
        'زيارة ميدانية شاملة من مهندس إتاحة معتمد',
        'قياس ميل المنحدرات وعرض الأبواب والمصاعد والحمامات',
        'تقرير هندسي معتمد بتوصيات التحسين وتوافق قانون 10/2018',
        'توثيق الأدلة الميدانية (verification_evidence) ومنح الشارة عند الاجتياز',
      ],
      featuresEn: [
        'On-site inspection by certified accessibility engineers',
        'Measured ramp slopes, door widths, elevators & restrooms',
        'Law 10/2018 architectural compliance & upgrade report',
        'Verified badge & published field evidence upon passing',
      ],
      grantsBadgeOnPayment: false,
    ),
    B2bPlanSpec(
      id: 'pro',
      titleAr: 'الاشتراك المؤسسي (Business Pro)',
      titleEn: 'Business Pro Subscription',
      priceAr: '1,000 جنيهاً / شهرياً',
      priceEn: '1,000 EGP / month',
      badgeAr: 'للمنشآت النشطة',
      badgeEn: 'Active Venues',
      featuresAr: [
        'لوحة تحليلات متقدمة للزيارات والتوافق حسب نوع الحركة',
        'إدارة حتى 10 فروع مع تنبيهات فورية لبلاغات العوائق',
        'أولوية مراجعة تحديثات الإتاحة والرد الرسمي على التقييمات',
        'تصدير تقارير الإتاحة الشهرية (CSV / PDF)',
      ],
      featuresEn: [
        'Advanced analytics by mobility profile & visitor intent',
        'Manage up to 10 branches with instant barrier report alerts',
        'Priority moderation & official review responses',
        'Monthly accessibility compliance exports',
      ],
      grantsBadgeOnPayment: false,
    ),
    B2bPlanSpec(
      id: 'enterprise',
      titleAr: 'باقة السلاسل والهيئات (Enterprise / B2G)',
      titleEn: 'Enterprise & Government (B2G)',
      priceAr: 'تسعير مخصص',
      priceEn: 'Custom Pricing',
      badgeAr: 'للسلاسل والجهات',
      badgeEn: 'Multi-Branch',
      featuresAr: [
        'فروع غير محدودة وفريق توثيق ميداني مخصص',
        'إعادة توثيق ربع سنوية وشهادات امتثال رسمية',
        'تكامل API مع أنظمة الحجز ومواقع المنشآت',
      ],
      featuresEn: [
        'Unlimited branches & dedicated field audit team',
        'Quarterly re-certification & official compliance reports',
        'API integration for booking & facility portals',
      ],
      grantsBadgeOnPayment: false,
    ),
  ];
}

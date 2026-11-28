import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '/core/analytics/analytics_service.dart';
import '/core/constants/app_constants.dart';
import '/core/theme/oneway_theme.dart';
import '/features/accessibility/accessibility_score.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/l10n/app_strings.dart';
import '/widgets/responsive_layout.dart';
import 'b2b_portal_models.dart';

/// Full B2B Verification & Business Analytics Dashboard view for ONEWAY.
///
/// Organizes business management into 4 clear tabs:
///   1. Overview & Analytics (KPIs + fl_chart compatibility breakdown)
///   2. Verification & Evidence (4-stage pipeline + self-assessment + audit request)
///   3. Branches & Reports (linked places with real CompatibilityBadge & evidence)
///   4. Plans & Subscriptions (transparent pricing + Ethical Integrity Charter)
class B2bVerificationDashboardView extends StatefulWidget {
  const B2bVerificationDashboardView({
    super.key,
    required this.snapshot,
    required this.onRegisterBusiness,
    required this.onRequestFieldAudit,
    required this.onContactSales,
    required this.onClose,
    this.onOpenBranch,
    this.onEditPlace,
    this.venueAddress = '',
    this.venuePhone = '',
    this.venueHours = '',
    this.venueDescription = '',
    this.venuePhotoUrl = '',
    this.adminFeedback = '',
    this.hasPendingEdits = false,
    this.displayName = '',
    this.analytics,
  });

  final B2bPortalSnapshot snapshot;
  final VoidCallback onRegisterBusiness;
  final Future<void> Function(B2bSelfAssessment assessment) onRequestFieldAudit;
  final void Function(B2bPlanSpec plan) onContactSales;
  final VoidCallback onClose;
  final void Function(B2bBranchSummary branch)? onOpenBranch;
  final VoidCallback? onEditPlace;
  final String venueAddress;
  final String venuePhone;
  final String venueHours;
  final String venueDescription;
  final String venuePhotoUrl;
  final String adminFeedback;
  final bool hasPendingEdits;
  final String displayName;
  final AnalyticsService? analytics;

  @override
  State<B2bVerificationDashboardView> createState() =>
      _B2bVerificationDashboardViewState();
}

class _B2bVerificationDashboardViewState
    extends State<B2bVerificationDashboardView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  B2bSelfAssessment _assessment = const B2bSelfAssessment(
    wheelchairEntrance: true,
    ramp: true,
  );
  bool _submittingAudit = false;

  AnalyticsService get _analytics =>
      widget.analytics ?? AnalyticsService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _submitAuditRequest() async {
    if (_submittingAudit) return;
    setState(() => _submittingAudit = true);
    try {
      await widget.onRequestFieldAudit(_assessment);
      await _analytics.logFieldAssessmentRequested(
        businessId: widget.snapshot.businessId ?? 'unregistered',
        readinessScore: _assessment.readinessPercent,
      );
    } finally {
      if (mounted) setState(() => _submittingAudit = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final snap = widget.snapshot;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.navy,
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: S.t(context, 'رجوع', 'Back'),
          onPressed: widget.onClose,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 4,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: OnewayPalette.primaryAccentOnDark,
              child: Icon(
                Icons.business_center_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    snap.hasBusiness
                        ? snap.businessName
                        : (widget.displayName.isNotEmpty
                            ? widget.displayName
                            : S.t(context, 'بوابة أعمال ONEWAY',
                                'ONEWAY Business Portal')),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    snap.hasBusiness
                        ? '${snap.category} • ${snap.subscriptionTier.toUpperCase()}'
                        : S.t(context, 'التوثيق الميداني وتحليلات الإتاحة',
                            'Verification & Accessibility Analytics'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: S.t(context, 'رجوع للرئيسية', 'Back to Home'),
            onPressed: widget.onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.72),
          indicatorColor: theme.gold,
          indicatorWeight: 3,
          tabs: [
            Tab(
              key: const Key('b2b_tab_overview'),
              text: S.t(context, 'نظرة عامة', 'Overview'),
              icon: const Icon(Icons.insights_rounded, size: 18),
            ),
            Tab(
              key: const Key('b2b_tab_verification'),
              text: S.t(context, 'التوثيق', 'Verification'),
              icon: const Icon(Icons.verified_user_rounded, size: 18),
            ),
            Tab(
              key: const Key('b2b_tab_branches'),
              text: S.t(context, 'الفروع', 'Branches'),
              icon: const Icon(Icons.storefront_rounded, size: 18),
            ),
            Tab(
              key: const Key('b2b_tab_plans'),
              text: S.t(context, 'الباقات', 'Plans'),
              icon: const Icon(Icons.workspace_premium_rounded, size: 18),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(context, theme, snap),
          _buildVerificationTab(context, theme, snap),
          _buildBranchesTab(context, theme, snap),
          _buildPlansTab(context, theme, snap),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: OVERVIEW & ANALYTICS
  // =========================================================================
  Widget _buildOverviewTab(
    BuildContext context,
    FlutterFlowTheme theme,
    B2bPortalSnapshot snap,
  ) {
    final hPad = OnewayResponsive.horizontalPadding(context);
    final branchScores = snap.averageMobilityScores();
    final isPreview = branchScores == null;
    final breakdownScores = branchScores ??
        _assessment.mobilityBreakdown().map((k, v) => MapEntry(k, v.scorePercent));
    final stage = snap.verificationStage;

    return ListView(
      key: const Key('b2b_overview_list'),
      padding: EdgeInsets.all(hPad),
      children: [
        if (!snap.hasBusiness) ...[
          _RegisterBusinessBanner(
            theme: theme,
            onRegister: widget.onRegisterBusiness,
          ),
          const SizedBox(height: 16),
        ] else ...[
          // Place Owner's Uploaded Place Summary & Direct Edit Card
          Card(
            key: const Key('owner_uploaded_place_card'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: widget.venuePhotoUrl.trim().isNotEmpty
                              ? Image.network(
                                  widget.venuePhotoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: theme.primary.withValues(alpha: 0.12),
                                    child: Icon(Icons.storefront_rounded,
                                        color: theme.primary, size: 30),
                                  ),
                                )
                              : Container(
                                  color: theme.primary.withValues(alpha: 0.12),
                                  child: Icon(Icons.storefront_rounded,
                                      color: theme.primary, size: 30),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              snap.businessName,
                              style: theme.titleMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.primaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (snap.category.isNotEmpty) snap.category,
                                if (widget.venuePhone.isNotEmpty)
                                  widget.venuePhone,
                              ].join(' • '),
                              style: theme.bodySmall.copyWith(
                                color: theme.secondaryText,
                              ),
                            ),
                            if (widget.venueAddress.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.venueAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.bodySmall.copyWith(
                                  color: theme.secondaryText,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.hasPendingEdits) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.infoContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sync_rounded,
                              size: 18, color: theme.info),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'لديك تعديلات محفوظة قيد مراجعة الإدارة لتحديثها على الخريطة.',
                              style: theme.bodySmall.copyWith(
                                color: theme.primaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (widget.adminFeedback.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.warningContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'ملاحظة الإدارة: ${widget.adminFeedback}',
                        style: theme.bodySmall.copyWith(
                          color: theme.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (widget.onEditPlace != null) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('owner_edit_place_btn'),
                      onPressed: widget.onEditPlace,
                      icon: const Icon(Icons.edit_location_alt_rounded, size: 19),
                      label: Text(
                        S.t(
                          context,
                          'تعديل بيانات المكان والصور وتجهيزات الإتاحة',
                          'Edit Venue Info, Photos & Accessibility',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Verification Status Strip
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (stage == B2bVerificationStage.verifiedWithEvidence
                            ? theme.success
                            : theme.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    stage == B2bVerificationStage.verifiedWithEvidence
                        ? Icons.verified_rounded
                        : Icons.fact_check_rounded,
                    color: stage == B2bVerificationStage.verifiedWithEvidence
                        ? theme.success
                        : theme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.t(context, 'حالة توثيق المنشأة',
                            'Verification Status'),
                        style: theme.labelMedium.copyWith(
                          color: theme.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        S.t(context, stage.labelAr(), stage.labelEn()),
                        style: theme.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: Text(S.t(context, 'التفاصيل', 'Details')),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // KPI Grid (2x2)
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                icon: Icons.store_rounded,
                color: theme.primary,
                label: S.t(context, 'الفروع المرتبطة', 'Linked Branches'),
                value: '${snap.branches.length}',
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiTile(
                icon: Icons.star_rounded,
                color: theme.tertiaryDark,
                label: S.t(context, 'متوسط التقييم', 'Avg Rating'),
                value: snap.averageBranchRating > 0
                    ? '${snap.averageBranchRating.toStringAsFixed(1)} / 5'
                    : S.t(context, 'لا يوجد بعد', 'No ratings'),
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                icon: Icons.workspace_premium_rounded,
                color: theme.navy,
                label: S.t(context, 'الباقة الحالية', 'Active Plan'),
                value: snap.subscriptionTier.toUpperCase(),
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiTile(
                icon: Icons.report_problem_outlined,
                color: theme.warning,
                label: S.t(context, 'بلاغات الإتاحة', 'Barrier Reports'),
                value: snap.reportsAccessDenied
                    ? '0'
                    : '${snap.reportsCount ?? 0}',
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Compatibility Breakdown BarChart (fl_chart)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        S.t(
                          context,
                          'توافق منشأتك حسب نوع الحركة (%)',
                          'Compatibility by Mobility Profile (%)',
                        ),
                        style: theme.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.primaryText,
                        ),
                      ),
                    ),
                    if (isPreview)
                      Chip(
                        label: Text(
                          S.t(context, 'تقييم ذاتي', 'Self-Check'),
                          style: theme.labelSmall,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isPreview
                      ? S.t(
                          context,
                          'محسوب من قائمة التقييم الذاتي الحالية حتى يتم ربط وتوثيق فروعك.',
                          'Preview computed from your self-assessment checklist until branches are linked.',
                        )
                      : S.t(
                          context,
                          'متوسط التوافق الفعلي عبر ${snap.branches.length} فروع مرتبطة.',
                          'Average score across ${snap.branches.length} linked branch(es).',
                        ),
                  style: theme.bodySmall.copyWith(color: theme.secondaryText),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 190,
                  child: _MobilityCompatibilityChart(
                    scores: breakdownScores,
                    theme: theme,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Ethical Charter Callout
        _EthicalCharterCard(theme: theme),
        const SizedBox(height: 24),
      ],
    );
  }

  // =========================================================================
  // TAB 2: VERIFICATION PIPELINE & SELF-ASSESSMENT
  // =========================================================================
  Widget _buildVerificationTab(
    BuildContext context,
    FlutterFlowTheme theme,
    B2bPortalSnapshot snap,
  ) {
    final hPad = OnewayResponsive.horizontalPadding(context);
    final stage = snap.verificationStage;
    final readiness = _assessment.readinessPercent;

    final steps = [
      (
        S.t(context, '1. تسجيل المنشأة', '1. Register Business'),
        S.t(context, 'إدخال بيانات النشاط والفروع', 'Submit venue & branch info'),
      ),
      (
        S.t(context, '2. التقييم الذاتي والصور', '2. Self-Assessment & Photos'),
        S.t(context, 'تحديد المرافق المهيأة وإرفاق صور',
            'Verify facilities & prepare photos'),
      ),
      (
        S.t(context, '3. الزيارة الميدانية المستقلة',
            '3. Independent Field Audit'),
        S.t(context, 'قياس المنحدرات والأبواب والمصاعد بواسطة مهندس إتاحة',
            'On-site measurement by accessibility engineers'),
      ),
      (
        S.t(context, '4. شارة "موثق" مع دليل ميداني',
            '4. Verified Badge + Evidence'),
        S.t(context, 'تظهر للعملاء مرتبطة بحقل verification_evidence',
            'Published with verification_evidence for full trust'),
      ),
    ];

    return ListView(
      key: const Key('b2b_verification_list'),
      padding: EdgeInsets.all(hPad),
      children: [
        // 4-Stage Progress Pipeline
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.t(context, 'مراحل الحصول على شارة التوثيق',
                      'Verification Pipeline'),
                  style: theme.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < steps.length; i++) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: i <= stage.stepIndex
                            ? theme.primary
                            : theme.outlineVariant,
                        child: Icon(
                          i < stage.stepIndex
                              ? Icons.check_rounded
                              : Icons.circle,
                          size: i < stage.stepIndex ? 16 : 8,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              steps[i].$1,
                              style: theme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: i <= stage.stepIndex
                                    ? theme.primaryText
                                    : theme.secondaryText,
                              ),
                            ),
                            Text(
                              steps[i].$2,
                              style: theme.bodySmall.copyWith(
                                color: theme.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (i < steps.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Interactive Readiness Checklist
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        S.t(context, 'قائمة الجاهزية للتقييم الميداني',
                            'Field Audit Readiness Checklist'),
                        style: theme.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.primaryText,
                        ),
                      ),
                    ),
                    Text(
                      '$readiness%',
                      key: const Key('b2b_readiness_percent'),
                      style: theme.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: readiness >= 70
                            ? theme.success
                            : theme.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: readiness / 100.0,
                    minHeight: 8,
                    backgroundColor: theme.surfaceVariant,
                    color: readiness >= 70 ? theme.success : theme.warning,
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(S.t(context, 'مدخل مستوٍ مناسب للكراسي المتحركة',
                      'Step-free wheelchair entrance')),
                  value: _assessment.wheelchairEntrance,
                  onChanged: (v) => setState(
                    () => _assessment =
                        _assessment.copyWith(wheelchairEntrance: v),
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(S.t(context, 'منحدر بميل آمن (Ramp ≤ 1:12)',
                      'Safe-slope ramp (≤ 1:12)')),
                  value: _assessment.ramp,
                  onChanged: (v) => setState(
                    () => _assessment = _assessment.copyWith(ramp: v),
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(S.t(context, 'مصعد مجهز بباب ≥ 90 سم',
                      'Accessible elevator (door ≥ 90 cm)')),
                  value: _assessment.suitableElevator,
                  onChanged: (v) => setState(
                    () =>
                        _assessment = _assessment.copyWith(suitableElevator: v),
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(S.t(context, 'دورة مياه مجهزة ومقابض أمان',
                      'Accessible restroom with grab bars')),
                  value: _assessment.accessibleRestroom,
                  onChanged: (v) => setState(
                    () => _assessment =
                        _assessment.copyWith(accessibleRestroom: v),
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(S.t(context, 'موقف سيارات مخصص قريب من المدخل',
                      'Dedicated accessible parking')),
                  value: _assessment.accessibleParking,
                  onChanged: (v) => setState(
                    () => _assessment =
                        _assessment.copyWith(accessibleParking: v),
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(S.t(context, 'جهّزت صور المدخل والمصعد والحمام',
                      'Entrance, elevator & restroom photos ready')),
                  value: _assessment.hasFacilityPhotos,
                  onChanged: (v) => setState(
                    () => _assessment =
                        _assessment.copyWith(hasFacilityPhotos: v),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  key: const Key('b2b_request_audit_btn'),
                  onPressed: _submittingAudit ? null : _submitAuditRequest,
                  icon: _submittingAudit
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.assignment_turned_in_rounded),
                  label: Text(
                    snap.pendingAuditStatus == 'pending'
                        ? S.t(context, 'إرسال تحديث لطلب التقييم الميداني',
                            'Submit Updated Field Audit Request')
                        : S.t(context, 'طلب تقييم ميداني مستقل الآن',
                            'Request Official Field Audit'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // =========================================================================
  // TAB 3: BRANCHES & EVIDENCE
  // =========================================================================
  Widget _buildBranchesTab(
    BuildContext context,
    FlutterFlowTheme theme,
    B2bPortalSnapshot snap,
  ) {
    final hPad = OnewayResponsive.horizontalPadding(context);

    if (snap.branches.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(hPad + 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storefront_outlined,
                    size: 56, color: theme.secondaryText),
                const SizedBox(height: 12),
                Text(
                  S.t(context, 'لا توجد فروع مرتبطة بعد',
                      'No Linked Branches Yet'),
                  textAlign: TextAlign.center,
                  style: theme.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  S.t(
                    context,
                    'بعد تسجيل منشأتك وطلب التقييم الميداني، سيقوم فريق ONEWAY بربط فروعك وعرض دليل التوثيق (verification_evidence) وتقييمات العملاء هنا.',
                    'Once registered and audited, your linked venues, field evidence, and visitor ratings appear here.',
                  ),
                  textAlign: TextAlign.center,
                  style: theme.bodyMedium.copyWith(
                    color: theme.secondaryText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: snap.hasBusiness
                      ? () => _tabController.animateTo(1)
                      : widget.onRegisterBusiness,
                  icon: Icon(snap.hasBusiness
                      ? Icons.verified_user_rounded
                      : Icons.add_business_rounded),
                  label: Text(
                    snap.hasBusiness
                        ? S.t(context, 'ابدأ التقييم الميداني',
                            'Start Field Audit')
                        : S.t(context, 'تسجيل منشأة الآن',
                            'Register Business'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      key: const Key('b2b_branches_list'),
      padding: EdgeInsets.all(hPad),
      itemCount: snap.branches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final branch = snap.branches[index];
        final compat = AccessibilityScorer.evaluateFeatures(branch.features);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        branch.name,
                        style: theme.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.primaryText,
                        ),
                      ),
                    ),
                    CompatibilityBadge(result: compat, compact: true),
                  ],
                ),
                if (branch.address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    branch.address,
                    style: theme.bodySmall.copyWith(color: theme.secondaryText),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Chip(
                      avatar: Icon(
                        branch.isGenuinelyVerified
                            ? Icons.verified_rounded
                            : Icons.pending_outlined,
                        size: 16,
                        color: branch.isGenuinelyVerified
                            ? theme.success
                            : theme.warning,
                      ),
                      label: Text(
                        branch.isGenuinelyVerified
                            ? S.t(context, 'موثّق بدليل ميداني',
                                'Evidence-Verified')
                            : S.t(context, 'بانتظار دليل ميداني',
                                'Awaiting Field Evidence'),
                      ),
                    ),
                    if (branch.rating > 0)
                      Chip(
                        avatar: Icon(Icons.star_rounded,
                            size: 16, color: theme.tertiaryDark),
                        label: Text(
                          '${branch.rating.toStringAsFixed(1)} (${branch.reviewCount})',
                        ),
                      ),
                  ],
                ),
                if (branch.verificationEvidence.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.successContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.fact_check_rounded,
                            size: 18, color: theme.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            branch.verificationEvidence,
                            style: theme.bodySmall.copyWith(
                              color: theme.primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.onOpenBranch != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: () => widget.onOpenBranch!(branch),
                      child: Text(S.t(context, 'عرض صفحة المكان', 'View Place')),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================================
  // TAB 4: PLANS & SUBSCRIPTIONS + ETHICAL CHARTER
  // =========================================================================
  Widget _buildPlansTab(
    BuildContext context,
    FlutterFlowTheme theme,
    B2bPortalSnapshot snap,
  ) {
    final hPad = OnewayResponsive.horizontalPadding(context);

    return ListView(
      key: const Key('b2b_plans_list'),
      padding: EdgeInsets.all(hPad),
      children: [
        _EthicalCharterCard(theme: theme),
        const SizedBox(height: 16),
        for (final plan in B2bPlanSpec.catalog) ...[
          _B2bPlanCard(
            plan: plan,
            isCurrent: snap.subscriptionTier.toLowerCase() == plan.id,
            theme: theme,
            onAction: () {
              _analytics.logB2bPlanViewed(planId: plan.id);
              if (plan.id == 'field_audit') {
                _tabController.animateTo(1);
              } else {
                widget.onContactSales(plan);
              }
            },
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _RegisterBusinessBanner extends StatelessWidget {
  const _RegisterBusinessBanner({
    required this.theme,
    required this.onRegister,
  });

  final FlutterFlowTheme theme;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.navy, theme.primary],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_rounded,
                  color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  S.t(context, 'سجّل منشأتك على ONEWAY',
                      'Register Your Venue on ONEWAY'),
                  style: theme.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            S.t(
              context,
              'أضف مطعمك، مستشفاك، فندقك، أو مركزك التجاري لتوثيق سهولة الوصول وجذب عملاء جدد من ذوي الإعاقة الحركية وكبار السن وأسرهم.',
              'List your venue to get field-verified accessibility credentials and welcome mobility-impaired visitors & families across Egypt.',
            ),
            style: theme.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.navy,
            ),
            onPressed: onRegister,
            icon: const Icon(Icons.add_business_rounded),
            label: Text(S.t(context, 'تسجيل منشأة الآن', 'Register Now')),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.theme,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.bodySmall.copyWith(color: theme.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobilityCompatibilityChart extends StatelessWidget {
  const _MobilityCompatibilityChart({
    required this.scores,
    required this.theme,
  });

  final Map<String, int> scores;
  final FlutterFlowTheme theme;

  Color _barColor(int score) {
    if (score >= 70) return OnewayPalette.accessFull;
    if (score >= 35) return OnewayPalette.accessPartial;
    return OnewayPalette.accessLimited;
  }

  @override
  Widget build(BuildContext context) {
    const keys = ['electric', 'manual', 'senior', 'stroller'];
    final labels = [
      S.t(context, 'كهربائي', 'Electric'),
      S.t(context, 'يدوي', 'Manual'),
      S.t(context, 'كبار سن', 'Senior'),
      S.t(context, 'عربة', 'Stroller'),
    ];

    return BarChart(
      BarChartData(
        maxY: 100,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.divider,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: 25,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}%',
                style: theme.labelSmall.copyWith(color: theme.secondaryText),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    labels[idx],
                    style: theme.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(keys.length, (i) {
          final score = (scores[keys[i]] ?? 0).clamp(0, 100);
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: score.toDouble(),
                width: 24,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
                color: _barColor(score),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 100,
                  color: theme.surfaceVariant,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _EthicalCharterCard extends StatelessWidget {
  const _EthicalCharterCard({required this.theme});

  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('b2b_ethical_charter'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.warningContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.warning, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_rounded, color: theme.warning, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.t(context, 'ميثاق النزاهة والشفافية',
                      'Ethical Integrity Charter'),
                  style: theme.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  S.t(
                    context,
                    'الاشتراك المؤسسي يمنحك أدوات الإدارة والتحليلات فقط. شارة "موثّق" لا تُباع أبداً وتُمنح حصرياً بعد تقييم ميداني مستقل وتوثيق الأدلة (verification_evidence).',
                    'Subscriptions unlock management & analytics tools ONLY. The Verified badge is NEVER for sale and requires an independent field audit with evidence.',
                  ),
                  style: theme.bodySmall.copyWith(
                    color: theme.primaryText,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _B2bPlanCard extends StatelessWidget {
  const _B2bPlanCard({
    required this.plan,
    required this.isCurrent,
    required this.theme,
    required this.onAction,
  });

  final B2bPlanSpec plan;
  final bool isCurrent;
  final FlutterFlowTheme theme;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final features = S.isEn(context) ? plan.featuresEn : plan.featuresAr;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: plan.highlighted ? theme.primary : theme.outlineVariant,
          width: plan.highlighted ? 2.0 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    S.t(context, plan.titleAr, plan.titleEn),
                    style: theme.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.primaryText,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    isCurrent
                        ? S.t(context, 'باقتك الحالية', 'Current')
                        : S.t(context, plan.badgeAr, plan.badgeEn),
                    style: theme.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.primary,
                    ),
                  ),
                  backgroundColor: theme.primary.withValues(alpha: 0.1),
                  side: BorderSide(color: theme.primary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              S.t(context, plan.priceAr, plan.priceEn),
              style: theme.titleMedium.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.primary,
              ),
            ),
            const SizedBox(height: 10),
            for (final feature in features)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 18, color: theme.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: theme.bodySmall.copyWith(
                          color: theme.primaryText,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            if (!isCurrent)
              plan.highlighted
                  ? ElevatedButton(
                      onPressed: onAction,
                      child: Text(
                        plan.id == 'field_audit'
                            ? S.t(context, 'طلب تقييم ميداني',
                                'Request Field Audit')
                            : S.t(context, 'تواصل مع فريق الأعمال',
                                'Contact Business Sales'),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: onAction,
                      child: Text(
                        S.t(
                          context,
                          'التفاصيل والتفعيل (${AppConstants.businessEmail})',
                          'Contact (${AppConstants.businessEmail})',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}

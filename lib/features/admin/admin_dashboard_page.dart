import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/constants/app_constants.dart';
import '/features/discovery/places_repository.dart';
import '/features/emergency/emergency_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/nav/nav.dart';
import '/pages/home_dashboard/home_dashboard_widget.dart';
import '/widgets/main_photo_picker_card.dart';

bool _isReportUnreplied({
  required String status,
  required String adminNotes,
}) {
  if (adminNotes.trim().isNotEmpty) return false;
  return status == 'new' ||
      status == 'underReview' ||
      status == 'needsMoreInformation';
}

bool _isDocUnreplied(QueryDocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>?;
  final status = (data?['status'] as String?) ?? 'new';
  final notes = (data?['admin_notes'] as String?) ?? '';
  return _isReportUnreplied(status: status, adminNotes: notes);
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  static const String routeName = 'AdminDashboard';
  static const String routePath = '/admin-dashboard';

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _placesSegment = 0; // 0: Published, 1: Place Owners, 2: Community Suggestions
  String _reportsFilter = 'all';

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

  void _navigateToTab(
    int index, {
    int placesSegment = 0,
    String? reportsFilter,
  }) {
    if (index == 2) {
      setState(() => _placesSegment = placesSegment);
    } else if (index == 1 && reportsFilter != null) {
      setState(() => _reportsFilter = reportsFilter);
    }
    _tabController.animateTo(index);
  }

  void _handleBackNavigation() {
    if (_tabController.index != 0) {
      _tabController.animateTo(0);
      return;
    }
    if (GoRouter.maybeOf(context) != null) {
      context.safePop();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.navy,
            foregroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              key: const Key('admin_back_btn'),
              tooltip: 'رجوع للصفحة السابقة',
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              onPressed: () {
                if (GoRouter.maybeOf(context) != null) {
                  context.safePop();
                } else {
                  Navigator.of(context).maybePop();
                }
              },
            ),
            actions: [
              if (GoRouter.maybeOf(context) != null)
                TextButton.icon(
                  onPressed: () =>
                      context.goNamed(HomeDashboardWidget.routeName),
                  icon: const Icon(Icons.home_outlined,
                      color: Colors.white, size: 18),
                  label: const Text(
                    'الرئيسية',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
            ],
            title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: theme.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.gold.withValues(alpha: 0.45),
                  ),
                ),
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: theme.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'لوحة إدارة ONEWAY',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 14),
            indicatorColor: theme.gold,
            indicatorWeight: 3,
            labelColor: theme.gold,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
            unselectedLabelColor: Colors.white.withValues(alpha: 0.72),
            tabs: [
              const Tab(
                icon: Icon(Icons.dashboard_outlined, size: 20),
                text: 'المؤشرات',
              ),
              Tab(
                icon: StreamBuilder<QuerySnapshot>(
                  stream: AccessibilityReportsRecord.collection.limit(100).snapshots(),
                  builder: (context, snapshot) {
                    final unreplied = snapshot.hasData
                        ? snapshot.data!.docs.where(_isDocUnreplied).length
                        : 0;
                    if (unreplied <= 0) {
                      return const Icon(Icons.assignment_late_outlined,
                          size: 20);
                    }
                    return Badge(
                      backgroundColor: const Color(0xFFEF4444),
                      textColor: Colors.white,
                      label: Text(
                        unreplied > 99 ? '99+' : '$unreplied',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Icon(Icons.assignment_late_outlined,
                          size: 20),
                    );
                  },
                ),
                text: 'البلاغات',
              ),
              const Tab(
                icon: Icon(Icons.place_outlined, size: 20),
                text: 'الأماكن',
              ),
              const Tab(
                icon: Icon(Icons.people_outline, size: 20),
                text: 'المستخدمين',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(onNavigateToTab: _navigateToTab),
            _ReportsModerationTab(
              filterStatus: _reportsFilter,
              onFilterChanged: (f) => setState(() => _reportsFilter = f),
            ),
            _PlacesManagementTab(
              selectedSegment: _placesSegment,
              onSelectSegment: (v) => setState(() => _placesSegment = v),
            ),
            const _UsersManagementTab(),
          ],
        ),
        ),
      ),
    );
  }
}

// ==============================================================================
// TAB 1: EXECUTIVE OVERVIEW & ACTIONABLE KPIs
// ==============================================================================
class _OverviewTab extends StatefulWidget {
  const _OverviewTab({required this.onNavigateToTab});
  final void Function(
    int index, {
    int placesSegment,
    String? reportsFilter,
  }) onNavigateToTab;

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  String _currentRoleTitle() {
    final role = currentUserDocument?.role ?? '';
    return switch (role) {
      'superAdmin' => 'أدمن رئيسي (Super Admin) — كامل الصلاحيات',
      'admin' => 'أدمن المنصة (Admin) — إدارة كاملة',
      _ => 'إدارة ONEWAY',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        // First-run setup hint (disappears once places exist and rules allow reads)
        const _SetupHintCard(),

        // Executive Admin Identity Card
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                theme.navy,
                Color.lerp(theme.navy, theme.primary, 0.28) ?? theme.navyLight,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.navy.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.gold.withValues(alpha: 0.5),
                    width: 1.4,
                  ),
                ),
                child: Icon(Icons.shield_rounded, color: theme.gold, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUserDisplayName.isNotEmpty
                          ? currentUserDisplayName
                          : 'مدير النظام',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (currentUserEmail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        currentUserEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.gold.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.gold.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Text(
                        _currentRoleTitle(),
                        style: TextStyle(
                          color: theme.gold,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Prominent Alert Banner whenever there are unreplied reports
        _UnrepliedReportsBanner(
          onOpenUnreplied: () =>
              widget.onNavigateToTab(1, reportsFilter: 'unreplied'),
        ),

        // Actionable Live KPI Grid
        Text(
          'مؤشرات التشغيل الحية',
          style: theme.titleMedium.copyWith(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StatCard(
                title: 'بلاغات بدون رد',
                icon: Icons.mark_chat_unread_rounded,
                color: const Color(0xFFDC2626),
                stream: AccessibilityReportsRecord.collection.limit(100).snapshots(),
                valueBuilder: (docs) => docs.where(_isDocUnreplied).length,
                subtitleBuilder: (docs, _) => 'من آخر ${docs.length} بلاغ',
                onTap: () =>
                    widget.onNavigateToTab(1, reportsFilter: 'unreplied'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'الأماكن الموثّقة',
                icon: Icons.verified_rounded,
                color: theme.primary,
                stream: PlacesRecord.collection.limit(100).snapshots(),
                valueBuilder: (docs) => docs.where((d) {
                  final s = (d.data() as Map<String, dynamic>?)?[
                          'verification_status'] as String? ??
                      '';
                  return s == 'verified';
                }).length,
                subtitleBuilder: (docs, _) => 'من إجمالي ${docs.length} مكان',
                onTap: () => widget.onNavigateToTab(2, placesSegment: 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StatCard(
                title: 'طلبات أصحاب الأماكن',
                icon: Icons.storefront_rounded,
                color: const Color(0xFF7C3AED),
                stream: BusinessesRecord.collection.limit(100).snapshots(),
                valueBuilder: (docs) => docs.where((d) {
                  final map = d.data() as Map<String, dynamic>?;
                  final status = map?['status'] as String? ?? 'pending';
                  final pendingEdits = map?['has_pending_edits'] == true;
                  return status == 'pending' || pendingEdits;
                }).length,
                subtitleBuilder: (docs, _) =>
                    'من إجمالي ${docs.length} منشأة مسجلة',
                onTap: () =>
                    widget.onNavigateToTab(2, placesSegment: 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'المستخدمين',
                icon: Icons.people_rounded,
                color: const Color(0xFF0284C7),
                stream: UsersRecord.collection.limit(100).snapshots(),
                valueBuilder: (docs) => docs.length,
                subtitleBuilder: (docs, _) {
                  final ownersCount = docs.where((d) {
                    final r = (d.data() as Map<String, dynamic>?)?['role']
                            as String? ??
                        'user';
                    return r == 'businessOwner';
                  }).length;
                  return '$ownersCount صاحب مكان مسجّل';
                },
                onTap: () => widget.onNavigateToTab(3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Quick Administrative Actions
        Text(
          'إجراءات الإدارة السريعة',
          style: theme.titleMedium.copyWith(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _QuickAdminTile(
                icon: Icons.mark_chat_unread_rounded,
                color: const Color(0xFFDC2626),
                title: 'مراجعة بلاغات الأماكن والرد عليها',
                subtitle: 'عرض البلاغات الواردة على الأماكن المسجّلة وتحديث حالتها.',
                onTap: () =>
                    widget.onNavigateToTab(1, reportsFilter: 'unreplied'),
              ),
              Divider(height: 1, color: theme.divider),
              _QuickAdminTile(
                icon: Icons.storefront_rounded,
                color: const Color(0xFF7C3AED),
                title: 'مراجعة طلبات وتعديلات أصحاب الأماكن',
                subtitle: 'اعتماد الأماكن المرفوعة من أصحابها ومراجعة تعديلاتهم.',
                onTap: () => widget.onNavigateToTab(2, placesSegment: 1),
              ),
              Divider(height: 1, color: theme.divider),
              _QuickAdminTile(
                icon: Icons.add_location_alt_rounded,
                color: theme.primary,
                title: 'إدارة الأماكن واقتراحات المجتمع',
                subtitle: 'إضافة وتوثيق الأماكن المهيأة ومراجعة اقتراحات المستخدمين.',
                onTap: () => widget.onNavigateToTab(2, placesSegment: 2),
              ),
              Divider(height: 1, color: theme.divider),
              _QuickAdminTile(
                icon: Icons.manage_accounts_rounded,
                color: const Color(0xFF0284C7),
                title: 'إدارة المستخدمين والأدوار (مستخدم عادي / صاحب مكان / أدمن)',
                subtitle: 'تنظيم صلاحيات الحسابات الثلاثة المعتمدة في المنصة.',
                onTap: () => widget.onNavigateToTab(3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UnrepliedReportsBanner extends StatelessWidget {
  const _UnrepliedReportsBanner({required this.onOpenUnreplied});

  final VoidCallback onOpenUnreplied;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: AccessibilityReportsRecord.collection.limit(100).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final unrepliedCount =
            snapshot.data!.docs.where(_isDocUnreplied).length;
        if (unrepliedCount <= 0) return const SizedBox.shrink();

        final label = unrepliedCount == 1
            ? 'يوجد بلاغ واحد لم يتم الرد عليه بعد'
            : unrepliedCount == 2
                ? 'يوجد بلاغان لم يتم الرد عليهما بعد'
                : 'يوجد $unrepliedCount بلاغات لم يتم الرد عليها بعد';

        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Material(
            color: const Color(0xFFDC2626).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onOpenUnreplied,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.45),
                    width: 1.4,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: theme.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFB91C1C),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'اضغط هنا لمراجعتها والرد على أصحابها فوراً',
                            style: theme.bodySmall.copyWith(
                              color: theme.primaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFFDC2626),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickAdminTile extends StatelessWidget {
  const _QuickAdminTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: theme.titleSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.primaryText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.bodySmall.copyWith(
          color: theme.secondaryText,
          height: 1.4,
        ),
      ),
      trailing:
          trailing ?? Icon(Icons.chevron_left_rounded, color: theme.secondaryText),
      onTap: onTap,
    );
  }
}

/// Shows a contextual setup hint at the top of the overview tab:
/// old Firestore rules still live in the console, or the places collection
/// is still empty. Renders nothing when everything is fine.
class _SetupHintCard extends StatelessWidget {
  const _SetupHintCard();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: PlacesRecord.collection.limit(1).snapshots(),
      builder: (context, snapshot) {
        String? message;
        IconData icon = Icons.rule_folder_outlined;
        Color color = theme.warning;
        if (snapshot.hasError) {
          message =
              'قواعد Firestore القديمة ما زالت مطبقة في الكونسول، لذلك تظهر الصفحة فارغة. '
              'الصق محتوى ملف firestore.rules من المشروع في تبويب Firestore > Rules ثم اضغط Publish.';
        } else if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
          icon = Icons.add_location_alt_rounded;
          color = theme.info;
          message =
              'لا توجد أماكن منشورة بعد. تُسجّل الأماكن حصراً بالطرق التقليدية: عبر تسجيل صاحب المكان واعتماده، أو اقتراحات المجتمع بعد المراجعة، أو الإضافة المباشرة من تبويب «الأماكن».';
        }
        if (message == null) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.stream,
    required this.valueBuilder,
    required this.subtitleBuilder,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Stream<QuerySnapshot> stream;
  final int Function(List<QueryDocumentSnapshot> docs) valueBuilder;
  final String Function(List<QueryDocumentSnapshot> docs, int value)
      subtitleBuilder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final hasError = snapshot.hasError;
        final isLoading = !snapshot.hasData && !hasError;
        final docs = snapshot.data?.docs ?? const <QueryDocumentSnapshot>[];
        final value = hasError || isLoading ? 0 : valueBuilder(docs);
        return Material(
          color: theme.surface,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadow.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleSmall.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: theme.primaryText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (hasError)
                    Icon(Icons.sync_problem_rounded,
                        color: theme.error, size: 26)
                  else if (isLoading)
                    SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: color),
                    )
                  else
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1.1,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    hasError
                        ? 'تحقق من قواعد Firestore'
                        : isLoading
                            ? 'جاري التحميل...'
                            : subtitleBuilder(docs, value),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: theme.secondaryText),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==============================================================================
// TAB 2: EXECUTIVE REPORTS MODERATION (Reply & Status Update + Unreplied Alerts)
// ==============================================================================
class _ReportsModerationTab extends StatefulWidget {
  const _ReportsModerationTab({
    required this.filterStatus,
    required this.onFilterChanged,
  });

  final String filterStatus;
  final ValueChanged<String> onFilterChanged;

  @override
  State<_ReportsModerationTab> createState() => _ReportsModerationTabState();
}

class _ReportsModerationTabState extends State<_ReportsModerationTab> {
  String get _filterStatus => widget.filterStatus;

  static const _statuses = <String>[
    'new',
    'underReview',
    'needsMoreInformation',
    'verified',
    'resolved',
    'rejected',
  ];

  String _statusLabel(String s) => switch (s) {
        'new' => 'جديد',
        'underReview' => 'قيد المراجعة',
        'needsMoreInformation' => 'يحتاج توضيح',
        'verified' => 'تم الاعتماد ✓',
        'resolved' => 'تم الحل',
        'rejected' => 'مرفوض',
        _ => s,
      };

  Color _statusColor(String s) => switch (s) {
        'new' => const Color(0xFFD97706),
        'underReview' => const Color(0xFF0284C7),
        'needsMoreInformation' => const Color(0xFF7C3AED),
        'verified' => const Color(0xFF16A34A),
        'resolved' => const Color(0xFF0D9488),
        'rejected' => const Color(0xFFDC2626),
        _ => Colors.grey,
      };

  IconData _statusIcon(String s) => switch (s) {
        'new' => Icons.fiber_new_rounded,
        'underReview' => Icons.hourglass_top_rounded,
        'needsMoreInformation' => Icons.help_outline_rounded,
        'verified' => Icons.verified_rounded,
        'resolved' => Icons.task_alt_rounded,
        'rejected' => Icons.cancel_outlined,
        _ => Icons.info_outline_rounded,
      };

  String _quickTemplateFor(String status) => switch (status) {
        'verified' =>
          'شكراً لمساهمتك! تم التحقق من البلاغ واعتماده، وسيتم تحديث بيانات المكان.',
        'resolved' =>
          'تمت معالجة العائق وتحديث حالة المكان بنجاح. نشكرك على تعاونك مع ONEWAY.',
        'rejected' =>
          'نعتذر، لم نتمكن من اعتماد البلاغ حالياً لعدم كفاية التفاصيل أو عدم تطابق الموقع.',
        'needsMoreInformation' =>
          'نحتاج صورة أوضح أو تفاصيل إضافية عن موقع العائق لنتمكن من مراجعته واعتماده.',
        'underReview' =>
          'بلاغك قيد المراجعة الميدانية من فريق ONEWAY وسنوافيك بالقرار قريباً.',
        _ => '',
      };

  String _notificationTitleFor(String status) => switch (status) {
        'verified' => 'تم اعتماد بلاغك ✓',
        'resolved' => 'تم حل البلاغ بنجاح ✓',
        'rejected' => 'تحديث بخصوص بلاغك',
        'needsMoreInformation' => 'مطلوب تفاصيل إضافية لبلاغك',
        'underReview' => 'بلاغك قيد المراجعة الآن',
        _ => 'تحديث بخصوص بلاغك',
      };

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final d = dt.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$day/$month/${d.year} • $hour:$min';
  }

  Future<bool> _submitDecision(
    AccessibilityReportsRecord report, {
    required String newStatus,
    required String replyText,
  }) async {
    try {
      final trimmedReply = replyText.trim();
      // Uses only ['status', 'admin_notes', 'updated_at'] so BOTH admin AND
      // moderator pass firestore.rules cleanly.
      await report.reference.update({
        'status': newStatus,
        'admin_notes': trimmedReply,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Notify the reporting user with the decision AND the admin's reply
      if (report.createdBy.isNotEmpty) {
        final placeTitle = report.placeName.isEmpty
            ? 'عائق في الطريق'
            : report.placeName;
        final bodyBuffer = StringBuffer(
          'بلاغك عن ($placeTitle) أصبحت حالته: ${_statusLabel(newStatus)}.',
        );
        if (trimmedReply.isNotEmpty) {
          bodyBuffer.write('\nرد الإدارة: $trimmedReply');
        }
        if (newStatus == 'needsMoreInformation') {
          bodyBuffer.write(
            '\nاضغط هنا لتعديل البلاغ وإضافة الملاحظات المطلوبة وإعادة إرساله.',
          );
        }
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': report.createdBy,
          'title': _notificationTitleFor(newStatus),
          'body': bodyBuffer.toString(),
          'type': 'report_status',
          'report_id': report.reference.id,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              trimmedReply.isNotEmpty
                  ? 'تم تحديث البلاغ (${_statusLabel(newStatus)}) وإرسال ردك للمستخدم ✓'
                  : 'تم تحديث حالة البلاغ إلى: ${_statusLabel(newStatus)} ✓',
            ),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر حفظ القرار: $e'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
      return false;
    }
  }

  void _showDecisionSheet(
    AccessibilityReportsRecord report, {
    required String initialStatus,
  }) {
    final theme = FlutterFlowTheme.of(context);
    String selectedStatus =
        _statuses.contains(initialStatus) ? initialStatus : 'verified';
    final initialReply = report.adminNotes.trim().isNotEmpty
        ? report.adminNotes.trim()
        : _quickTemplateFor(selectedStatus);
    final replyCtrl = TextEditingController(text: initialReply);
    bool saving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final statusColor = _statusColor(selectedStatus);
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مراجعة البلاغ والرد على المستخدم',
                                style: theme.titleMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.primaryText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${report.placeName.isEmpty ? "عائق في الطريق" : report.placeName} • ${report.userName.isEmpty ? "مستخدم" : report.userName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.bodySmall.copyWith(
                                  color: theme.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'اختر القرار / الحالة:',
                      style: theme.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in const [
                          'verified',
                          'resolved',
                          'underReview',
                          'needsMoreInformation',
                          'rejected',
                        ])
                          ChoiceChip(
                            selected: selectedStatus == s,
                            showCheckmark: false,
                            avatar: Icon(
                              _statusIcon(s),
                              size: 16,
                              color: selectedStatus == s
                                  ? Colors.white
                                  : _statusColor(s),
                            ),
                            selectedColor: _statusColor(s),
                            label: Text(
                              _statusLabel(s),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: selectedStatus == s
                                    ? Colors.white
                                    : theme.primaryText,
                              ),
                            ),
                            onSelected: (_) {
                              setSheetState(() {
                                final prevTemplate =
                                    _quickTemplateFor(selectedStatus);
                                selectedStatus = s;
                                if (replyCtrl.text.trim().isEmpty ||
                                    replyCtrl.text.trim() == prevTemplate) {
                                  replyCtrl.text = _quickTemplateFor(s);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: replyCtrl,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'رد الإدارة للمستخدم',
                        hintText:
                            'اكتب ردك أو سبب القرار ليظهر لصاحب البلاغ في «بلاغاتي» والإشعارات...',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => setSheetState(
                          () => replyCtrl.text =
                              _quickTemplateFor(selectedStatus),
                        ),
                        icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                        label: const Text('استخدام رد جاهز مناسب للحالة'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: statusColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: saving
                            ? null
                            : () async {
                                setSheetState(() => saving = true);
                                final ok = await _submitDecision(
                                  report,
                                  newStatus: selectedStatus,
                                  replyText: replyCtrl.text,
                                );
                                if (sheetCtx.mounted) {
                                  if (ok) {
                                    Navigator.pop(sheetCtx);
                                  } else {
                                    setSheetState(() => saving = false);
                                  }
                                }
                              },
                        icon: saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(_statusIcon(selectedStatus), size: 20),
                        label: Text(
                          saving
                              ? 'جاري الحفظ والإرسال...'
                              : 'حفظ القرار وإرسال الرد للمستخدم',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showImageDialog(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Padding(
              padding: EdgeInsets.all(20),
              child: Text('تعذر تحميل الصورة'),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return StreamBuilder<QuerySnapshot>(
      // Fetch all reports directly without server-side orderBy so documents
      // with pending serverTimestamps are never silently dropped; sort in Dart.
      stream: AccessibilityReportsRecord.collection.limit(100).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'تعذر تحميل البلاغات: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allReports = snapshot.data!.docs
            .map(AccessibilityReportsRecord.fromSnapshot)
            .toList();

        bool isUnreplied(AccessibilityReportsRecord r) => _isReportUnreplied(
              status: r.status,
              adminNotes: r.adminNotes,
            );

        // Pin ALL unreplied reports at the very top (newest first), then replied.
        allReports.sort((a, b) {
          final ua = isUnreplied(a);
          final ub = isUnreplied(b);
          if (ua != ub) return ua ? -1 : 1;
          final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return tb.compareTo(ta);
        });

        final unrepliedCount = allReports.where(isUnreplied).length;

        int countFor(String statusKey) {
          if (statusKey == 'all') return allReports.length;
          if (statusKey == 'unreplied') return unrepliedCount;
          return allReports.where((r) => r.status == statusKey).length;
        }

        final filteredReports = _filterStatus == 'all'
            ? allReports
            : _filterStatus == 'unreplied'
                ? allReports.where(isUnreplied).toList()
                : allReports.where((r) => r.status == _filterStatus).toList();

        final filterOptions = <(String key, String label)>[
          ('unreplied', 'لم يُرد عليها'),
          ('all', 'الكل'),
          ('new', 'جديد'),
          ('underReview', 'قيد المراجعة'),
          ('verified', 'معتمد'),
          ('resolved', 'تم الحل'),
          ('needsMoreInformation', 'توضيح'),
          ('rejected', 'مرفوض'),
        ];

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Column(
          children: [
            // High-visibility alert strip when unreplied reports exist
            if (unrepliedCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                child: Material(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => widget.onFilterChanged(
                      _filterStatus == 'unreplied' ? 'all' : 'unreplied',
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.mark_chat_unread_rounded,
                            color: Color(0xFFDC2626),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              unrepliedCount == 1
                                  ? 'يوجد بلاغ واحد بانتظار الرد — لا تنسَ الرد عليه'
                                  : 'يوجد $unrepliedCount بلاغات بانتظار الرد — مثبّتة في الأعلى',
                              style: const TextStyle(
                                color: Color(0xFFB91C1C),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _filterStatus == 'unreplied' ? 'عرض الكل' : 'عرضها',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Live Filter Strip with Counts
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  for (final (key, label) in filterOptions) ...[
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        showCheckmark: false,
                        selected: _filterStatus == key,
                        avatar: key == 'unreplied' && unrepliedCount > 0
                            ? Icon(
                                Icons.circle,
                                size: 9,
                                color: _filterStatus == key
                                    ? Colors.white
                                    : const Color(0xFFDC2626),
                              )
                            : null,
                        selectedColor: key == 'unreplied'
                            ? const Color(0xFFDC2626)
                            : key == 'all'
                                ? theme.navy
                                : _statusColor(key),
                        side: key == 'unreplied' &&
                                unrepliedCount > 0 &&
                                _filterStatus != key
                            ? const BorderSide(
                                color: Color(0xFFDC2626),
                                width: 1.3,
                              )
                            : null,
                        label: Text(
                          '$label (${countFor(key)})',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: _filterStatus == key
                                ? Colors.white
                                : (key == 'unreplied' && unrepliedCount > 0)
                                    ? const Color(0xFFB91C1C)
                                    : theme.primaryText,
                          ),
                        ),
                        onSelected: (_) => widget.onFilterChanged(key),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Reports List
            Expanded(
              child: filteredReports.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _filterStatus == 'unreplied'
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.assignment_turned_in_outlined,
                              size: 48,
                              color: _filterStatus == 'unreplied'
                                  ? const Color(0xFF16A34A)
                                  : theme.secondaryText.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _filterStatus == 'unreplied'
                                  ? 'ممتاز! تم الرد على جميع البلاغات الواردة ✓'
                                  : allReports.isEmpty
                                      ? 'لا توجد بلاغات واردة حتى الآن.'
                                      : 'لا توجد بلاغات مطابقة لهذا الفلتر.',
                              textAlign: TextAlign.center,
                              style: theme.bodyMedium.copyWith(
                                color: theme.secondaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      itemCount: filteredReports.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final report = filteredReports[index];
                        final status = _statuses.contains(report.status)
                            ? report.status
                            : 'new';
                        final color = _statusColor(status);
                        final dateStr = _formatDate(report.createdAt);
                        final needsReply = isUnreplied(report);

                        return Container(
                          decoration: BoxDecoration(
                            color: needsReply
                                ? (isDark
                                    ? const Color(0xFF2B1C19)
                                    : const Color(0xFFFFF8F6))
                                : theme.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: needsReply
                                  ? const Color(0xFFDC2626)
                                      .withValues(alpha: 0.55)
                                  : color.withValues(alpha: 0.25),
                              width: needsReply ? 1.8 : 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (needsReply
                                        ? const Color(0xFFDC2626)
                                        : theme.shadow)
                                    .withValues(alpha: needsReply ? 0.08 : 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Top attention ribbon for unreplied reports
                              if (needsReply)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  color: const Color(0xFFDC2626)
                                      .withValues(alpha: 0.12),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.mark_chat_unread_rounded,
                                        size: 16,
                                        color: Color(0xFFDC2626),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          report.userNotes.trim().isNotEmpty
                                              ? 'تم تعديل البلاغ وإرسال توضيح المستخدم • لم يتم الرد بعد'
                                              : 'لم يتم الرد بعد • بانتظار مراجعة الإدارة',
                                          style: const TextStyle(
                                            color: Color(0xFFB91C1C),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Header: Place Name + Status Badge
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            report.placeName.isEmpty
                                                ? 'عائق عام في الطريق'
                                                : report.placeName,
                                            style: theme.titleMedium.copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: theme.primaryText,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.13),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color:
                                                  color.withValues(alpha: 0.35),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(_statusIcon(status),
                                                  size: 14, color: color),
                                              const SizedBox(width: 4),
                                              Text(
                                                _statusLabel(status),
                                                style: TextStyle(
                                                  color: color,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Meta: Category + Reporter + Date
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 6,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: theme.primary
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            report.problemCategory.isEmpty
                                                ? 'عائق إتاحة'
                                                : report.problemCategory,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: theme.primary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'بواسطة: ${report.userName.isEmpty ? "مستخدم" : report.userName}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.secondaryText,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (dateStr.isNotEmpty)
                                          Text(
                                            dateStr,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: theme.secondaryText,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Description Box
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.surfaceVariant
                                            .withValues(alpha: 0.65),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        report.description,
                                        style: theme.bodyMedium.copyWith(
                                          height: 1.5,
                                          color: theme.primaryText,
                                        ),
                                      ),
                                    ),

                                    // Reporter Clarification Notes (when user edited & resubmitted)
                                    if (report.userNotes.trim().isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.all(11),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF16A34A)
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFF16A34A)
                                                .withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(
                                                  Icons.speaker_notes_rounded,
                                                  size: 16,
                                                  color: Color(0xFF15803D),
                                                ),
                                                SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'توضيح وملاحظات مقدم البلاغ:',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Color(0xFF15803D),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              report.userNotes,
                                              style: theme.bodySmall.copyWith(
                                                color: theme.primaryText,
                                                height: 1.45,
                                                fontSize: 13,
                                              ),
                                            ),
                                            if (report.previousAdminNotes
                                                .trim()
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                'طلب التوضيح السابق: ${report.previousAdminNotes}',
                                                style: theme.bodySmall.copyWith(
                                                  color: theme.secondaryText,
                                                  fontSize: 11.5,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],

                                    // Attached Photos Gallery
                                    if (report.photoUrls.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        height: 82,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: report.photoUrls.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(width: 8),
                                          itemBuilder: (context, pIndex) {
                                            final pUrl =
                                                report.photoUrls[pIndex];
                                            return InkWell(
                                              onTap: () =>
                                                  _showImageDialog(pUrl),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Image.network(
                                                  pUrl,
                                                  width: 82,
                                                  height: 82,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(
                                                    width: 82,
                                                    height: 82,
                                                    color: theme.outlineVariant,
                                                    child: const Icon(
                                                        Icons.broken_image),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],

                                    // Existing Admin Reply Display
                                    if (report.adminNotes
                                        .trim()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.all(11),
                                        decoration: BoxDecoration(
                                          color: theme.primary
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: theme.primary
                                                .withValues(alpha: 0.25),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.check_circle_rounded,
                                                size: 18, color: theme.primary),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'تم الرد على المستخدم:',
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: theme.primary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    report.adminNotes,
                                                    style: theme.bodySmall
                                                        .copyWith(
                                                      color: theme.primaryText,
                                                      height: 1.45,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 14),

                                    // Single Unified Action Row: Reply & Update Status (+ Delete for Admins)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: needsReply
                                              ? FilledButton.icon(
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor:
                                                        theme.primary,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 14,
                                                      vertical: 11,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      _showDecisionSheet(
                                                    report,
                                                    initialStatus:
                                                        status == 'new'
                                                            ? 'verified'
                                                            : status,
                                                  ),
                                                  icon: const Icon(
                                                      Icons.reply_rounded,
                                                      size: 19),
                                                  label: const Text(
                                                    'رد وتحديث الحالة',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                )
                                              : OutlinedButton.icon(
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        theme.primary,
                                                    side: BorderSide(
                                                      color: theme.primary
                                                          .withValues(
                                                              alpha: 0.45),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 14,
                                                      vertical: 11,
                                                    ),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                  ),
                                                  onPressed: () =>
                                                      _showDecisionSheet(
                                                    report,
                                                    initialStatus: status,
                                                  ),
                                                  icon: const Icon(
                                                      Icons.edit_note_rounded,
                                                      size: 19),
                                                  label: const Text(
                                                    'تعديل الرد وتحديث الحالة',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                        if (currentUserIsAdmin) ...[
                                          const SizedBox(width: 8),
                                          IconButton(
                                            tooltip: 'حذف البلاغ',
                                            icon: Icon(
                                                Icons.delete_outline_rounded,
                                                color: theme.error),
                                            onPressed: () async {
                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (c) => AlertDialog(
                                                  title: const Text(
                                                      'تأكيد الحذف'),
                                                  content: const Text(
                                                      'هل أنت متأكد من حذف هذا البلاغ نهائياً؟'),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                c, false),
                                                        child: const Text(
                                                            'إلغاء')),
                                                    FilledButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                c, true),
                                                        child:
                                                            const Text('حذف')),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                await report.reference.delete();
                                              }
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ==============================================================================
// TAB 3: PLACES MANAGEMENT (Published + Place Owners + Community Suggestions)
// ==============================================================================
class _PlacesManagementTab extends StatefulWidget {
  const _PlacesManagementTab({
    required this.selectedSegment,
    required this.onSelectSegment,
  });

  final int selectedSegment;
  final ValueChanged<int> onSelectSegment;

  @override
  State<_PlacesManagementTab> createState() => _PlacesManagementTabState();
}

class _PlacesManagementTabState extends State<_PlacesManagementTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int get _segment => widget.selectedSegment;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static const _adminCategories = <String>[
    'طبي ومستشفيات',
    'صيدليات',
    'تسوق ومراكز تجارية',
    'مطاعم وكافيهات',
    'مساحات عمل',
    'تعليم وجامعات',
    'مواصلات ونقل',
    'سياحة وثقافة',
    'فنادق وسياحة',
    'مرافق عامة',
  ];

  static const _availableAmenities = <String>[
    'رامب',
    'أسانسير',
    'حمام مجهز',
    'باركنج',
    'مدخل كرسي متحرك',
    'واي فاي',
    'توصيل',
    'تيك أواي',
    'جلسات خارجية',
    'تكييف',
    'خدمة 24 ساعة',
  ];

  void _showAddPlaceDialog() => _showPlaceFormSheet();

  void _showPlaceFormSheet({
    PlacesRecord? existing,
    Map<String, dynamic>? prefillSubmission,
    DocumentReference? submissionRef,
  }) {
    final isEditing = existing != null;
    final features = existing?.accessibilityFeatures;
    final sub = prefillSubmission ?? const <String, dynamic>{};
    final subName = (sub['place_name'] as String?) ?? '';
    final subCat = (sub['category'] as String?) ?? '';
    final subCity = (sub['city'] as String?) ?? '';
    final subGov = (sub['governorate'] as String?) ?? '';
    final subAddr = (sub['address'] as String?) ?? '';
    final subPhone = (sub['phone_number'] as String?) ?? '';
    final subHours = (sub['opening_hours'] as String?) ?? '';
    final subWebsite = (sub['website'] as String?) ?? '';
    final subDesc = (sub['description'] as String?) ?? '';
    final subMainPhoto = (sub['photo_url'] as String?) ?? '';
    final subEntrancePhoto = (sub['entrance_photo_url'] as String?) ??
        (sub['entrancePhotoUrl'] as String?) ??
        '';
    final subElevatorPhoto = (sub['elevator_photo_url'] as String?) ??
        (sub['elevatorPhotoUrl'] as String?) ??
        '';
    final subRestroomPhoto = (sub['restroom_photo_url'] as String?) ??
        (sub['restroomPhotoUrl'] as String?) ??
        '';
    final subFeatures = sub['accessibility_features'] is Map
        ? Map<String, dynamic>.from(sub['accessibility_features'] as Map)
        : const <String, dynamic>{};
    final subAmenities = (sub['amenities'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    final subLocation = sub['location'] is GeoPoint
        ? sub['location'] as GeoPoint
        : null;

    final nameCtrl = TextEditingController(
        text: existing?.name ?? subName);
    final rawInitialCat = existing?.category.isNotEmpty == true
        ? existing!.category
        : (subCat.isNotEmpty ? subCat : 'طبي ومستشفيات');
    final dropdownCategories = <String>{
      ..._adminCategories,
      rawInitialCat,
    }.toList();
    String selectedCat = rawInitialCat;
    final cityCtrl = TextEditingController(
      text: existing?.city.isNotEmpty == true
          ? existing!.city
          : (subCity.isNotEmpty ? subCity : 'القاهرة'),
    );
    final govCtrl = TextEditingController(
      text: existing?.governorate.isNotEmpty == true
          ? existing!.governorate
          : (subGov.isNotEmpty ? subGov : 'القاهرة'),
    );
    final addrCtrl = TextEditingController(
        text: existing?.address ?? subAddr);
    final phoneCtrl = TextEditingController(
        text: existing?.phoneNumber ?? subPhone);
    final hoursCtrl = TextEditingController(
        text: existing?.openingHours ?? subHours);
    final ratingCtrl = TextEditingController(
      text: (existing != null && existing.hasRating() && existing.rating > 0)
          ? existing.rating.toString()
          : '',
    );
    final webCtrl = TextEditingController(
        text: existing?.website ?? subWebsite);
    final descCtrl = TextEditingController(
        text: existing?.description ?? subDesc);
    final evidenceCtrl = TextEditingController(
      text: existing?.verificationEvidence ?? '',
    );
    final selectedAmenities = <String>{
      ...(existing?.amenities ?? subAmenities),
    };
    String mainPhotoUrl = existing?.photoUrl.isNotEmpty == true
        ? existing!.photoUrl
        : subMainPhoto;
    Uint8List? mainPhotoBytes;
    String entrancePhotoUrl = existing?.entrancePhotoUrl.isNotEmpty == true
        ? existing!.entrancePhotoUrl
        : subEntrancePhoto;
    Uint8List? entrancePhotoBytes;
    String elevatorPhotoUrl = existing?.elevatorPhotoUrl.isNotEmpty == true
        ? existing!.elevatorPhotoUrl
        : subElevatorPhoto;
    Uint8List? elevatorPhotoBytes;
    String restroomPhotoUrl = existing?.restroomPhotoUrl.isNotEmpty == true
        ? existing!.restroomPhotoUrl
        : subRestroomPhoto;
    Uint8List? restroomPhotoBytes;
    final miniMapCtrl = MapController();
    String? uploadingSlot;
    bool fetchingGps = false;

    ll.LatLng pickedLocation = existing?.location != null
        ? ll.LatLng(existing!.location!.latitude, existing.location!.longitude)
        : (subLocation != null
            ? ll.LatLng(subLocation.latitude, subLocation.longitude)
            : const ll.LatLng(30.0444, 31.2357));

    bool wheelchair = features?.wheelchairEntrance ??
        (subFeatures['wheelchairEntrance'] as bool?) ??
        true;
    bool ramp = features?.ramp ?? (subFeatures['ramp'] as bool?) ?? true;
    bool elevator = features?.suitableElevator ??
        (subFeatures['suitableElevator'] as bool?) ??
        false;
    bool restroom = features?.accessibleRestroom ??
        (subFeatures['accessibleRestroom'] as bool?) ??
        false;
    bool parking = features?.accessibleParking ??
        (subFeatures['accessibleParking'] as bool?) ??
        false;
    bool verified = isEditing
        ? existing.verificationStatus == 'verified'
        : true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isEditing ? 'تعديل بيانات المكان' : 'إضافة مكان متاح جديد',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'اسم المكان *',
                      hintText: 'مثال: مستشفى القصر العيني الجديد',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCat,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'التصنيف',
                      border: OutlineInputBorder(),
                    ),
                    items: dropdownCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedCat = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cityCtrl,
                          decoration: const InputDecoration(
                            labelText: 'المدينة',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: govCtrl,
                          decoration: const InputDecoration(
                            labelText: 'المحافظة',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addrCtrl,
                    decoration: const InputDecoration(
                      labelText: 'العنوان التفصيلي',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم التواصل / الهاتف',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: hoursCtrl,
                          decoration: const InputDecoration(
                            labelText: 'مواعيد العمل',
                            hintText: 'مثال: 09:00 ص - 11:00 م',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: ratingCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'التقييم (0-5)',
                            hintText: '4.8',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MainPhotoPickerCard(
                    title: 'الصورة الرئيسية للمكان (اختياري)',
                    subtitle: 'اختر صورة واضحة للمكان من المعرض أو الكاميرا',
                    imageBytes: mainPhotoBytes,
                    imageUrl: mainPhotoUrl,
                    isUploading: uploadingSlot == 'main',
                    onRemove: () => setModalState(() {
                      mainPhotoBytes = null;
                      mainPhotoUrl = '';
                    }),
                    onPickGallery: () async {
                      final bytes = await PlacePhotoUploadHelper.pickImageBytes(
                        source: ImageSource.gallery,
                      );
                      if (bytes == null) return;
                      setModalState(() {
                        mainPhotoBytes = bytes;
                        uploadingSlot = 'main';
                      });
                      try {
                        final url =
                            await PlacePhotoUploadHelper.uploadImageBytes(
                          bytes: bytes,
                          uid: currentUserUid,
                          folder: 'places',
                          prefix: 'main',
                        );
                        setModalState(() => mainPhotoUrl = url);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تعذر رفع الصورة: $e')),
                          );
                        }
                      } finally {
                        setModalState(() => uploadingSlot = null);
                      }
                    },
                    onPickCamera: () async {
                      final bytes = await PlacePhotoUploadHelper.pickImageBytes(
                        source: ImageSource.camera,
                      );
                      if (bytes == null) return;
                      setModalState(() {
                        mainPhotoBytes = bytes;
                        uploadingSlot = 'main';
                      });
                      try {
                        final url =
                            await PlacePhotoUploadHelper.uploadImageBytes(
                          bytes: bytes,
                          uid: currentUserUid,
                          folder: 'places',
                          prefix: 'main',
                        );
                        setModalState(() => mainPhotoUrl = url);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تعذر رفع الصورة: $e')),
                          );
                        }
                      } finally {
                        setModalState(() => uploadingSlot = null);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'صور تفصيلية للمدخل والمصعد والحمام (اختياري):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  for (final slot in <({
                    String key,
                    String label,
                    IconData icon,
                    String url,
                    Uint8List? bytes,
                    void Function(Uint8List?, String) onUpdate,
                  })>[
                    (
                      key: 'entrance',
                      label: 'صورة المدخل / المنحدر',
                      icon: Icons.accessible_rounded,
                      url: entrancePhotoUrl,
                      bytes: entrancePhotoBytes,
                      onUpdate: (b, u) {
                        entrancePhotoBytes = b;
                        entrancePhotoUrl = u;
                      },
                    ),
                    (
                      key: 'elevator',
                      label: 'صورة المصعد',
                      icon: Icons.elevator_rounded,
                      url: elevatorPhotoUrl,
                      bytes: elevatorPhotoBytes,
                      onUpdate: (b, u) {
                        elevatorPhotoBytes = b;
                        elevatorPhotoUrl = u;
                      },
                    ),
                    (
                      key: 'restroom',
                      label: 'صورة دورة المياه المهيأة',
                      icon: Icons.wc_rounded,
                      url: restroomPhotoUrl,
                      bytes: restroomPhotoBytes,
                      onUpdate: (b, u) {
                        restroomPhotoBytes = b;
                        restroomPhotoUrl = u;
                      },
                    ),
                  ]) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (slot.bytes != null || slot.url.isNotEmpty)
                              ? FlutterFlowTheme.of(context)
                                  .primary
                                  .withValues(alpha: 0.45)
                              : FlutterFlowTheme.of(context).divider,
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: slot.bytes != null
                                  ? Image.memory(slot.bytes!, fit: BoxFit.cover)
                                  : slot.url.isNotEmpty
                                      ? Image.network(
                                          slot.url,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            slot.icon,
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                          ),
                                        )
                                      : Container(
                                          color: FlutterFlowTheme.of(context)
                                              .surfaceVariant,
                                          child: Icon(
                                            slot.icon,
                                            size: 22,
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                          ),
                                        ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slot.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                                Text(
                                  slot.bytes != null || slot.url.isNotEmpty
                                      ? 'تم اختيار الصورة'
                                      : 'لم يتم اختيار صورة بعد',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (slot.bytes != null || slot.url.isNotEmpty)
                            IconButton(
                              tooltip: 'حذف الصورة',
                              onPressed: uploadingSlot != null
                                  ? null
                                  : () => setModalState(
                                      () => slot.onUpdate(null, '')),
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: FlutterFlowTheme.of(context).error,
                              ),
                            ),
                          FilledButton.tonalIcon(
                            onPressed: uploadingSlot != null
                                ? null
                                : () async {
                                    final bytes = await PlacePhotoUploadHelper
                                        .pickImageBytes(
                                      source: ImageSource.gallery,
                                      maxWidth: 1280,
                                      imageQuality: 82,
                                    );
                                    if (bytes == null) return;
                                    setModalState(() {
                                      slot.onUpdate(bytes, slot.url);
                                      uploadingSlot = slot.key;
                                    });
                                    try {
                                      final url = await PlacePhotoUploadHelper
                                          .uploadImageBytes(
                                        bytes: bytes,
                                        uid: currentUserUid,
                                        folder: 'places',
                                        prefix: slot.key,
                                      );
                                      setModalState(
                                        () => slot.onUpdate(bytes, url),
                                      );
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text('تعذر رفع الصورة: $e'),
                                          ),
                                        );
                                      }
                                    } finally {
                                      setModalState(() => uploadingSlot = null);
                                    }
                                  },
                            icon: uploadingSlot == slot.key
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.photo_library_outlined,
                                    size: 17),
                            label: Text(
                              slot.bytes != null || slot.url.isNotEmpty
                                  ? 'تغيير'
                                  : 'اختيار',
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'وصف المكان وتفاصيل الوصول',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ميزات الإتاحة المتوفرة:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SwitchListTile(
                    title: const Text('مدخل مناسب للكرسي المتحرك'),
                    value: wheelchair,
                    onChanged: (v) => setModalState(() => wheelchair = v),
                  ),
                  SwitchListTile(
                    title: const Text('منحدر مجهز (Ramp)'),
                    value: ramp,
                    onChanged: (v) => setModalState(() => ramp = v),
                  ),
                  SwitchListTile(
                    title: const Text('مصعد مجهز'),
                    value: elevator,
                    onChanged: (v) => setModalState(() => elevator = v),
                  ),
                  SwitchListTile(
                    title: const Text('حمام مخصص لذوي الإعاقة'),
                    value: restroom,
                    onChanged: (v) => setModalState(() => restroom = v),
                  ),
                  SwitchListTile(
                    title: const Text('موقف سيارات مخصص'),
                    value: parking,
                    onChanged: (v) => setModalState(() => parking = v),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'التجهيزات والخدمات الإضافية (Amenities):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final am in _availableAmenities)
                        FilterChip(
                          label: Text(am, style: const TextStyle(fontSize: 12)),
                          selected: selectedAmenities.contains(am),
                          onSelected: (sel) {
                            setModalState(() {
                              if (sel) {
                                selectedAmenities.add(am);
                              } else {
                                selectedAmenities.remove(am);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('اعتماد المكان كـ (Verified)'),
                    value: verified,
                    activeTrackColor: Colors.green,
                    onChanged: (v) => setModalState(() => verified = v),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: evidenceCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'إثبات التوثيق الميداني (لإظهار شارة تم التحقق ✓)',
                      hintText:
                          'مثال: فحص ميداني بواسطة فريق ONEWAY — المنحدر والمصعد يعملان بكفاءة',
                      prefixIcon: Icon(Icons.verified_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'موقع المكان على الخريطة (اضغط لتحديد الدبوس):',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: fetchingGps
                            ? null
                            : () async {
                                setModalState(() => fetchingGps = true);
                                try {
                                  final pos = await EmergencyService
                                      .determineCurrentPosition();
                                  if (pos != null) {
                                    final next = ll.LatLng(
                                        pos.latitude, pos.longitude);
                                    setModalState(() => pickedLocation = next);
                                    miniMapCtrl.move(next, 15);
                                  }
                                } finally {
                                  setModalState(() => fetchingGps = false);
                                }
                              },
                        icon: fetchingGps
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location_rounded, size: 16),
                        label: const Text('موقعي'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 185,
                      child: FlutterMap(
                        mapController: miniMapCtrl,
                        options: MapOptions(
                          initialCenter: pickedLocation,
                          initialZoom: 13.5,
                          onTap: (_, point) {
                            setModalState(() => pickedLocation = point);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: AppConstants.mapTileUrlTemplate,
                            userAgentPackageName:
                                AppConstants.mapUserAgentPackage,
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: pickedLocation,
                                width: 42,
                                height: 42,
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: Color(0xFFE5484D),
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الإحداثيات: ${pickedLocation.latitude.toStringAsFixed(5)}, ${pickedLocation.longitude.toStringAsFixed(5)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: uploadingSlot != null
                        ? null
                        : () async {
                      if (nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('أدخل اسم المكان أولاً')),
                        );
                        return;
                      }

                      Navigator.pop(ctx);
                      final parsedRating =
                          double.tryParse(ratingCtrl.text.trim());
                      final validRating = (parsedRating != null &&
                              parsedRating >= 0 &&
                              parsedRating <= 5)
                          ? parsedRating
                          : null;
                      final evidenceText = evidenceCtrl.text.trim();
                      final payload = <String, dynamic>{
                        'name': nameCtrl.text.trim(),
                        'category': selectedCat,
                        'city': cityCtrl.text.trim(),
                        'governorate': govCtrl.text.trim(),
                        'address': addrCtrl.text.trim(),
                        'phone_number': phoneCtrl.text.trim(),
                        'opening_hours': hoursCtrl.text.trim(),
                        'website': webCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'photo_url': mainPhotoUrl.trim(),
                        'entrance_photo_url': entrancePhotoUrl.trim(),
                        'elevator_photo_url': elevatorPhotoUrl.trim(),
                        'restroom_photo_url': restroomPhotoUrl.trim(),
                        'location': GeoPoint(
                          pickedLocation.latitude,
                          pickedLocation.longitude,
                        ),
                        'geo': PlacesRepository.buildGeoField(
                          pickedLocation.latitude,
                          pickedLocation.longitude,
                        ),
                        'accessibility_features': {
                          'wheelchairEntrance': wheelchair,
                          'ramp': ramp,
                          'suitableElevator': elevator,
                          'accessibleRestroom': restroom,
                          'accessibleParking': parking,
                          'corridorWidth': features?.corridorWidth.isNotEmpty == true
                              ? features!.corridorWidth
                              : 'أكثر من 120 سم',
                          'entranceObstacles':
                              features?.entranceObstacles.isNotEmpty == true
                                  ? features!.entranceObstacles
                                  : 'لا يوجد',
                        },
                        'amenities': selectedAmenities.take(20).toList(),
                        'data_source': existing?.dataSource.isNotEmpty == true
                            ? existing!.dataSource
                            : 'admin',
                        if (validRating != null) 'rating': validRating,
                        'verification_status':
                            verified ? 'verified' : 'needsUpdate',
                        'verification_evidence': evidenceText,
                        'verified_by': currentUserEmail,
                        'last_verified_at': FieldValue.serverTimestamp(),
                      };

                      try {
                        if (isEditing) {
                          await existing.reference.update(payload);
                        } else {
                          payload['photos'] = <String>[
                            if (mainPhotoUrl.trim().isNotEmpty)
                              mainPhotoUrl.trim(),
                            if (entrancePhotoUrl.trim().isNotEmpty)
                              entrancePhotoUrl.trim(),
                            if (elevatorPhotoUrl.trim().isNotEmpty)
                              elevatorPhotoUrl.trim(),
                            if (restroomPhotoUrl.trim().isNotEmpty)
                              restroomPhotoUrl.trim(),
                          ];
                          payload['created_at'] = FieldValue.serverTimestamp();
                          final createdDoc =
                              await PlacesRecord.collection.add(payload);
                          if (submissionRef != null) {
                            await submissionRef.update({
                              'status': 'approved',
                              'published_place_id': createdDoc.id,
                              'reviewed_by': currentUserEmail,
                              'reviewed_at': FieldValue.serverTimestamp(),
                            });
                            final submitterUid =
                                (prefillSubmission?['submittedBy'] as String?) ??
                                    '';
                            if (submitterUid.isNotEmpty) {
                              await FirebaseFirestore.instance
                                  .collection('notifications')
                                  .add({
                                'userId': submitterUid,
                                'title': 'تم اعتماد ونشر المكان الذي اقترحته ✓',
                                'body':
                                    'شكراً لمساهمتك في مجتمع ONEWAY! تمت مراجعة ونشر «${nameCtrl.text.trim()}» على الخريطة ليظهر للجميع.',
                                'type': 'place_submission_approved',
                                'is_read': false,
                                'created_at': FieldValue.serverTimestamp(),
                              });
                            }
                          }
                        }
                        PlacesRepository.instance.invalidateCache();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEditing
                                  ? 'تم تحديث بيانات المكان بنجاح!'
                                  : 'تمت إضافة المكان بنجاح إلى التطبيق!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(isEditing
                                    ? 'تعذر تعديل المكان: $e'
                                    : 'تعذر إضافة المكان: $e')),
                          );
                        }
                      }
                    },
                    child: Text(isEditing ? 'حفظ التعديلات' : 'حفظ ونشر المكان'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      children: [
        // Search and Add Button (stacks cleanly at large font sizes / narrow screens)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1.0);
              final stackControls =
                  constraints.maxWidth < 380 || textScale >= 1.25;
              final searchField = TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                decoration: InputDecoration(
                  hintText: 'بحث في الأماكن بالاسم أو المدينة...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              final addButton = FilledButton.icon(
                onPressed: _showAddPlaceDialog,
                icon: const Icon(Icons.add),
                label: const Text(
                  'إضافة مكان جديد',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
              if (stackControls) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchField,
                    const SizedBox(height: 8),
                    addButton,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 8),
                  addButton,
                ],
              );
            },
          ),
        ),

        // 3-Segment Switcher: Published Places | Place Owners | Community Suggestions
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.location_on_outlined, size: 17),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('الأماكن المنشورة', maxLines: 1),
                  ),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.storefront_outlined, size: 17),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('أصحاب الأماكن', maxLines: 1),
                  ),
                ),
                ButtonSegment(
                  value: 2,
                  icon: Icon(Icons.inbox_outlined, size: 17),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('اقتراحات المجتمع', maxLines: 1),
                  ),
                ),
              ],
              selected: {_segment},
              onSelectionChanged: (s) {
                if (s.isNotEmpty) widget.onSelectSegment(s.first);
              },
            ),
          ),
        ),

        if (_segment == 1)
          Expanded(child: _buildBusinessApplicationsList(theme))
        else if (_segment == 2)
          Expanded(child: _buildSubmissionsList(theme))
        else
          Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: PlacesRecord.collection.limit(100).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('خطأ في التحميل: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var places =
                  snapshot.data!.docs.map(PlacesRecord.fromSnapshot).toList();

              if (_searchQuery.isNotEmpty) {
                places = places.where((p) {
                  return p.name.contains(_searchQuery) ||
                      p.city.contains(_searchQuery) ||
                      p.category.contains(_searchQuery);
                }).toList();
              }

              if (places.isEmpty) {
                return const Center(
                  child: Text('لا توجد أماكن مطابقة للبحث.'),
                );
              }

              return ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: places.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final place = places[index];
                  final isVerified = place.verificationStatus == 'verified';

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: isVerified
                                    ? theme.successContainer
                                    : theme.warningContainer,
                                child: Icon(
                                  isVerified
                                      ? Icons.verified
                                      : Icons.help_outline,
                                  color:
                                      isVerified ? theme.success : theme.warning,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      place.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${place.category} • ${place.city}',
                                      style: theme.bodySmall.copyWith(
                                        color: theme.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (!isVerified)
                                OutlinedButton.icon(
                                  icon: Icon(Icons.check_circle_outline,
                                      size: 18, color: theme.success),
                                  label: Text('اعتماد',
                                      style: TextStyle(color: theme.success)),
                                  onPressed: () {
                                    place.reference.update({
                                      'verification_status': 'verified',
                                      'verified_by': currentUserEmail,
                                      'last_verified_at':
                                          FieldValue.serverTimestamp(),
                                    });
                                    PlacesRepository.instance.invalidateCache();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'تم اعتماد مكان (${place.name}) بنجاح!')),
                                    );
                                  },
                                ),
                              OutlinedButton.icon(
                                icon: Icon(Icons.edit_outlined,
                                    size: 18, color: theme.primary),
                                label: Text('تعديل',
                                    style: TextStyle(color: theme.primary)),
                                onPressed: () =>
                                    _showPlaceFormSheet(existing: place),
                              ),
                              OutlinedButton.icon(
                                icon: Icon(Icons.delete_outline,
                                    size: 18, color: theme.error),
                                label: Text('حذف',
                                    style: TextStyle(color: theme.error)),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('تأكيد حذف المكان'),
                                      content: Text(
                                          'هل أنت متأكد من رغبتك في حذف مكان (${place.name}) نهائياً؟'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(c, false),
                                            child: const Text('إلغاء')),
                                        FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(c, true),
                                            child: const Text('حذف')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    place.reference.delete();
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _approveAndSyncBusinessOwnerPlace(
    BusinessesRecord biz,
  ) async {
    try {
      final raw = biz.snapshotData;
      final claimedPlaceId =
          ((raw['claimed_existing_place_id'] as String?) ?? '').trim();
      final existingBranchIds = List<String>.from(biz.branchPlaceIds);

      // Build canonical place payload from the Place Owner's submitted data
      final loc = biz.location;
      final placePayload = <String, dynamic>{
        'name': biz.businessName,
        'category': biz.category.isNotEmpty ? biz.category : 'مرافق عامة',
        'description': biz.description,
        'address': biz.address,
        'governorate': biz.governorate.isNotEmpty ? biz.governorate : 'القاهرة',
        'city': biz.city.isNotEmpty ? biz.city : 'القاهرة',
        'phone_number': biz.phoneNumber,
        'opening_hours': biz.openingHours,
        'website': (raw['website'] as String?) ?? '',
        if (biz.photoUrl.isNotEmpty) 'photo_url': biz.photoUrl,
        if (((raw['entrance_photo_url'] as String?) ?? '').isNotEmpty)
          'entrance_photo_url': raw['entrance_photo_url'],
        if (((raw['elevator_photo_url'] as String?) ?? '').isNotEmpty)
          'elevator_photo_url': raw['elevator_photo_url'],
        if (((raw['restroom_photo_url'] as String?) ?? '').isNotEmpty)
          'restroom_photo_url': raw['restroom_photo_url'],
        if (loc != null) ...{
          'location': GeoPoint(loc.latitude, loc.longitude),
          'geo': PlacesRepository.buildGeoField(loc.latitude, loc.longitude),
        },
        if (raw['accessibility_features'] is Map)
          'accessibility_features': raw['accessibility_features']
        else
          'accessibility_features': {
            'wheelchairEntrance': true,
            'ramp': true,
            'suitableElevator': false,
            'accessibleRestroom': false,
            'accessibleParking': false,
          },
        if (raw['amenities'] is List)
          'amenities': List<String>.from(raw['amenities'] as List),
        'business_id': biz.reference.id,
        'data_source': 'business_owner',
        'verification_status': 'verified',
        'verified_by': currentUserEmail,
        'last_verified_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      String linkedPlaceId = '';
      if (existingBranchIds.isNotEmpty) {
        linkedPlaceId = existingBranchIds.first;
        await PlacesRecord.collection.doc(linkedPlaceId).set(
              placePayload,
              SetOptions(merge: true),
            );
      } else if (claimedPlaceId.isNotEmpty) {
        // Owner claimed an existing community-suggested place -> merge & link without duplicating!
        linkedPlaceId = claimedPlaceId;
        await PlacesRecord.collection.doc(linkedPlaceId).set(
              placePayload,
              SetOptions(merge: true),
            );
      } else {
        placePayload['photos'] = <String>[];
        placePayload['created_at'] = FieldValue.serverTimestamp();
        final created = await PlacesRecord.collection.add(placePayload);
        linkedPlaceId = created.id;
      }

      await biz.reference.update({
        'status': 'active',
        'has_pending_edits': false,
        'branch_place_ids': <String>{
          ...existingBranchIds,
          if (linkedPlaceId.isNotEmpty) linkedPlaceId,
        }.toList(),
        'approved_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (biz.ownerId.isNotEmpty) {
        try {
          await UsersRecord.collection.doc(biz.ownerId).update({
            'role': 'businessOwner',
            'business_application_status': 'active',
            'has_uploaded_place': true,
            'updated_time': FieldValue.serverTimestamp(),
          });
        } catch (_) {}

        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': biz.ownerId,
          'title': 'تم اعتماد مكانك على ONEWAY ✓',
          'body':
              'تم اعتماد ونشر بيانات «${biz.businessName}» على الخريطة! يمكنك متابعة الإحصائيات وتعديل بيانات المكان في أي وقت من لوحة صاحب المكان.',
          'type': 'business_approved',
          'business_id': biz.reference.id,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      PlacesRepository.instance.invalidateCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'تم اعتماد ونشر «${biz.businessName}» وتفعيل حساب صاحب المكان ✓'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر اعتماد المكان: $e'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }

  Future<void> _showRejectBusinessDialog(BusinessesRecord biz) async {
    final reasonCtrl = TextEditingController(
      text: biz.rejectionReason.isNotEmpty
          ? biz.rejectionReason
          : 'يرجى استكمال تفاصيل العنوان وصور الإتاحة ثم إعادة الإرسال.',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('رفض الطلب / طلب استكمال بيانات'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'المنشأة: ${biz.businessName}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'سبب الرفض أو الملاحظات المطلوبة لصاحب المكان',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: FlutterFlowTheme.of(context).error,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('تأكيد الرفض وإشعار المالك'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final reason = reasonCtrl.text.trim().isNotEmpty
        ? reasonCtrl.text.trim()
        : 'يرجى استكمال تفاصيل العنوان وصور الإتاحة ثم إعادة الإرسال.';
    try {
      await biz.reference.update({
        'status': 'rejected',
        'has_pending_edits': false,
        'rejection_reason': reason,
        'rejected_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      if (biz.ownerId.isNotEmpty) {
        try {
          await UsersRecord.collection.doc(biz.ownerId).update({
            'business_application_status': 'rejected',
            'updated_time': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': biz.ownerId,
          'title': 'ملاحظات على طلب تسجيل مكانك',
          'body': 'بخصوص «${biz.businessName}»: $reason',
          'type': 'business_rejected',
          'business_id': biz.reference.id,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إرسال الملاحظات ورفض طلب «${biz.businessName}».'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تحديث حالة الطلب: $e'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteBusiness(BusinessesRecord biz) async {
    final hasLinked = biz.branchPlaceIds.isNotEmpty;
    bool alsoDeleteLinkedPlaces = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد حذف طلب صاحب المكان'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'هل أنت متأكد من حذف طلب «${biz.businessName}» نهائياً؟ لا يمكن التراجع عن هذا الإجراء.',
                ),
                if (hasLinked) ...[
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: alsoDeleteLinkedPlaces,
                    onChanged: (v) =>
                        setDialogState(() => alsoDeleteLinkedPlaces = v ?? false),
                    title: const Text(
                      'حذف المكان المنشور المرتبط بهذا الطلب من الخريطة أيضاً',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: FlutterFlowTheme.of(context).error,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('حذف نهائي'),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      if (alsoDeleteLinkedPlaces) {
        for (final pid in biz.branchPlaceIds) {
          try {
            await PlacesRecord.collection.doc(pid).delete();
          } catch (_) {}
        }
        PlacesRepository.instance.invalidateCache();
      }
      await biz.reference.delete();
      if (biz.ownerId.isNotEmpty) {
        try {
          await UsersRecord.collection.doc(biz.ownerId).update({
            'business_application_status': 'none',
            'updated_time': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف طلب «${biz.businessName}» بنجاح ✓'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر حذف الطلب: $e'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }

  void _showBusinessDetailsSheet(BusinessesRecord biz) {
    final theme = FlutterFlowTheme.of(context);
    final raw = biz.snapshotData;
    final ownerName = (raw['ownerName'] as String?) ??
        (raw['owner_name'] as String?) ??
        '';
    final ownerPhone = (raw['ownerPhone'] as String?) ??
        (raw['owner_phone'] as String?) ??
        '';
    final ownerEmail = (raw['ownerEmail'] as String?) ??
        (raw['owner_email'] as String?) ??
        '';
    final claimedId =
        ((raw['claimed_existing_place_id'] as String?) ?? '').trim();
    final photos = <({String label, String url})>[
      if (biz.photoUrl.trim().isNotEmpty)
        (label: 'الصورة الرئيسية', url: biz.photoUrl.trim()),
      if (biz.entrancePhotoUrl.trim().isNotEmpty)
        (label: 'المدخل / المنحدر', url: biz.entrancePhotoUrl.trim()),
      if (biz.elevatorPhotoUrl.trim().isNotEmpty)
        (label: 'المصعد', url: biz.elevatorPhotoUrl.trim()),
      if (biz.restroomPhotoUrl.trim().isNotEmpty)
        (label: 'الحمام المجهز', url: biz.restroomPhotoUrl.trim()),
    ];
    final feat = biz.accessibilityFeatures;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) => ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      biz.businessName.isNotEmpty
                          ? biz.businessName
                          : 'تفاصيل طلب صاحب المكان',
                      style: theme.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.primaryText,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              if (photos.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          child: Image.network(photos[i].url, fit: BoxFit.contain),
                        ),
                      ),
                      child: SizedBox(
                        width: 150,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  photos[i].url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: theme.surfaceVariant,
                                    child: const Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              photos[i].label,
                              textAlign: TextAlign.center,
                              style: theme.bodySmall.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _buildAdminDetailRow(theme, 'الحالة', biz.status),
              _buildAdminDetailRow(theme, 'التصنيف', biz.category),
              _buildAdminDetailRow(theme, 'هاتف المكان', biz.phoneNumber),
              if (biz.email.isNotEmpty)
                _buildAdminDetailRow(theme, 'بريد المكان', biz.email),
              if (biz.governorate.isNotEmpty || biz.city.isNotEmpty)
                _buildAdminDetailRow(
                  theme,
                  'المحافظة / المدينة',
                  [
                    if (biz.governorate.isNotEmpty) biz.governorate,
                    if (biz.city.isNotEmpty) biz.city,
                  ].join(' — '),
                ),
              if (biz.address.isNotEmpty)
                _buildAdminDetailRow(theme, 'العنوان التفصيلي', biz.address),
              if (biz.openingHours.isNotEmpty)
                _buildAdminDetailRow(theme, 'ساعات العمل', biz.openingHours),
              if (biz.website.isNotEmpty)
                _buildAdminDetailRow(theme, 'الموقع الإلكتروني', biz.website),
              if (biz.location != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 6),
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${biz.location!.latitude},${biz.location!.longitude}',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: Text(
                      'فتح الموقع على الخريطة (${biz.location!.latitude.toStringAsFixed(4)}, ${biz.location!.longitude.toStringAsFixed(4)})',
                    ),
                  ),
                ),
              const Divider(height: 22),
              Text(
                'بيانات صاحب المكان:',
                style: theme.titleSmall.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              if (ownerName.isNotEmpty)
                _buildAdminDetailRow(theme, 'اسم المالك', ownerName),
              if (ownerPhone.isNotEmpty)
                _buildAdminDetailRow(theme, 'هاتف المالك', ownerPhone),
              if (ownerEmail.isNotEmpty)
                _buildAdminDetailRow(theme, 'بريد المالك', ownerEmail),
              if (claimedId.isNotEmpty)
                _buildAdminDetailRow(
                  theme,
                  'نوع الطلب',
                  'إثبات ملكية وربط بمكان موجود ($claimedId)',
                ),
              if (biz.description.isNotEmpty) ...[
                const Divider(height: 22),
                Text(
                  'الوصف وتفاصيل الوصول:',
                  style: theme.titleSmall.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(biz.description, style: theme.bodyMedium),
              ],
              const Divider(height: 22),
              Text(
                'تجهيزات الإتاحة المُعلنة:',
                style: theme.titleSmall.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _buildAccessibilityFeatureChips(theme, {
                  'wheelchairEntrance': feat.wheelchairEntrance,
                  'ramp': feat.ramp,
                  'suitableElevator': feat.suitableElevator,
                  'accessibleRestroom': feat.accessibleRestroom,
                  'accessibleParking': feat.accessibleParking,
                }),
              ),
              if (biz.amenities.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'خدمات ومرافق إضافية:',
                  style: theme.titleSmall.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: biz.amenities
                      .map((a) => Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(a, style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  _approveAndSyncBusinessOwnerPlace(biz);
                },
                icon: const Icon(Icons.verified_rounded),
                label: Text(
                  biz.status == 'active' && !biz.hasPendingEdits
                      ? 'إعادة مزامنة واعتماد البيانات على الخريطة'
                      : 'قبول واعتماد ونشر المكان',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        _showRejectBusinessDialog(biz);
                      },
                      icon: Icon(Icons.close_rounded, color: theme.error),
                      label: Text('رفض / استكمال',
                          style: TextStyle(color: theme.error)),
                    ),
                  ),
                  if (currentUserIsAdmin) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.error),
                        ),
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _confirmDeleteBusiness(biz);
                        },
                        icon: Icon(Icons.delete_outline_rounded,
                            color: theme.error),
                        label: Text('حذف الطلب',
                            style: TextStyle(color: theme.error)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminDetailRow(
    FlutterFlowTheme theme,
    String label,
    String value,
  ) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: theme.bodySmall.copyWith(
                color: theme.secondaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim(),
              style: theme.bodyMedium.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAccessibilityFeatureChips(
    FlutterFlowTheme theme,
    Map<String, dynamic> featuresMap,
  ) {
    final entries = <(String, String)>[
      ('wheelchairEntrance', 'مدخل بدون درجات'),
      ('ramp', 'منحدر مناسب'),
      ('suitableElevator', 'مصعد متاح'),
      ('accessibleRestroom', 'حمام مجهز'),
      ('accessibleParking', 'موقف سيارات'),
    ];
    return entries.map((e) {
      final hasIt = featuresMap[e.$1] == true;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: (hasIt ? theme.success : theme.outlineVariant)
              .withValues(alpha: hasIt ? 0.14 : 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasIt
                ? theme.success.withValues(alpha: 0.45)
                : theme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasIt ? Icons.check_circle_rounded : Icons.cancel_outlined,
              size: 14,
              color: hasIt ? theme.success : theme.secondaryText,
            ),
            const SizedBox(width: 5),
            Text(
              e.$2,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: hasIt ? theme.success : theme.secondaryText,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _showSubmissionDetailsSheet(
    DocumentReference docRef,
    Map<String, dynamic> data,
  ) {
    final theme = FlutterFlowTheme.of(context);
    final name = (data['place_name'] as String?) ?? 'مكان مقترح';
    final cat = (data['category'] as String?) ?? '';
    final gov = (data['governorate'] as String?) ?? '';
    final city = (data['city'] as String?) ?? '';
    final addr = (data['address'] as String?) ?? '';
    final phone = (data['phone_number'] as String?) ?? '';
    final hours = (data['opening_hours'] as String?) ?? '';
    final website = (data['website'] as String?) ?? '';
    final desc = (data['description'] as String?) ?? '';
    final submitterName = (data['submitter_name'] as String?) ?? '';
    final submitterEmail = (data['submitter_email'] as String?) ?? '';
    final submitterPhone = (data['submitter_phone'] as String?) ?? '';
    final loc = data['location'] is GeoPoint ? data['location'] as GeoPoint : null;
    final featuresMap = data['accessibility_features'] is Map
        ? Map<String, dynamic>.from(data['accessibility_features'] as Map)
        : const <String, dynamic>{};
    final amenities = (data['amenities'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    final photos = <({String label, String url})>[
      if (((data['photo_url'] as String?) ?? '').trim().isNotEmpty)
        (label: 'الصورة الرئيسية', url: (data['photo_url'] as String).trim()),
      if (((data['entrance_photo_url'] as String?) ?? '').trim().isNotEmpty)
        (
          label: 'المدخل / المنحدر',
          url: (data['entrance_photo_url'] as String).trim(),
        ),
      if (((data['elevator_photo_url'] as String?) ?? '').trim().isNotEmpty)
        (label: 'المصعد', url: (data['elevator_photo_url'] as String).trim()),
      if (((data['restroom_photo_url'] as String?) ?? '').trim().isNotEmpty)
        (
          label: 'الحمام المجهز',
          url: (data['restroom_photo_url'] as String).trim(),
        ),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) => ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: theme.titleLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.primaryText,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              if (photos.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          child: Image.network(photos[i].url, fit: BoxFit.contain),
                        ),
                      ),
                      child: SizedBox(
                        width: 150,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  photos[i].url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: theme.surfaceVariant,
                                    child: const Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              photos[i].label,
                              textAlign: TextAlign.center,
                              style: theme.bodySmall.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _buildAdminDetailRow(theme, 'التصنيف', cat),
              if (gov.isNotEmpty || city.isNotEmpty)
                _buildAdminDetailRow(
                  theme,
                  'المحافظة / المدينة',
                  [if (gov.isNotEmpty) gov, if (city.isNotEmpty) city]
                      .join(' — '),
                ),
              _buildAdminDetailRow(theme, 'العنوان التفصيلي', addr),
              _buildAdminDetailRow(theme, 'هاتف المكان', phone),
              _buildAdminDetailRow(theme, 'ساعات العمل', hours),
              _buildAdminDetailRow(theme, 'الموقع الإلكتروني', website),
              if (loc != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${loc.latitude},${loc.longitude}',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: Text(
                      'فتح الموقع على الخريطة (${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)})',
                    ),
                  ),
                ),
              if (submitterName.isNotEmpty ||
                  submitterEmail.isNotEmpty ||
                  submitterPhone.isNotEmpty) ...[
                const Divider(height: 22),
                Text(
                  'بيانات مقدم الاقتراح:',
                  style: theme.titleSmall.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                _buildAdminDetailRow(theme, 'الاسم', submitterName),
                _buildAdminDetailRow(theme, 'البريد الإلكتروني', submitterEmail),
                _buildAdminDetailRow(theme, 'الهاتف', submitterPhone),
              ],
              if (desc.isNotEmpty) ...[
                const Divider(height: 22),
                Text(
                  'الوصف وملاحظات الوصول:',
                  style: theme.titleSmall.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(desc, style: theme.bodyMedium),
              ],
              if (featuresMap.isNotEmpty) ...[
                const Divider(height: 22),
                Text(
                  'تجهيزات الإتاحة:',
                  style: theme.titleSmall.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildAccessibilityFeatureChips(theme, featuresMap),
                ),
              ],
              if (amenities.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: amenities
                      .map((a) => Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(a, style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  _showPlaceFormSheet(
                    prefillSubmission: data,
                    submissionRef: docRef,
                  );
                },
                icon: const Icon(Icons.publish_rounded),
                label: const Text('مراجعة واعتماد ونشر على الخريطة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessApplicationsList(FlutterFlowTheme theme) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: BusinessesRecord.collection.limit(80).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'تعذر تحميل طلبات أصحاب الأماكن: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!.docs
            .map(BusinessesRecord.fromSnapshot)
            .toList()
          ..sort((a, b) {
            final aAction = a.status == 'pending' || a.hasPendingEdits;
            final bAction = b.status == 'pending' || b.hasPendingEdits;
            if (aAction != bAction) return aAction ? -1 : 1;
            final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return tb.compareTo(ta);
          });

        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'لا توجد طلبات مسجلة من أصحاب أماكن حتى الآن.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final biz = items[index];
            final raw = biz.snapshotData;
            final claimedId =
                ((raw['claimed_existing_place_id'] as String?) ?? '').trim();
            final ownerName = (raw['ownerName'] as String?) ??
                (raw['owner_name'] as String?) ??
                '';
            final ownerPhone = (raw['ownerPhone'] as String?) ??
                (raw['owner_phone'] as String?) ??
                '';
            final needsAction =
                biz.status == 'pending' || biz.hasPendingEdits;
            final feat = biz.accessibilityFeatures;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (biz.photoUrl.trim().isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              biz.photoUrl.trim(),
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 54,
                                height: 54,
                                color: theme.surfaceVariant,
                                child: const Icon(Icons.storefront_rounded),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                biz.businessName.isNotEmpty
                                    ? biz.businessName
                                    : 'منشأة بدون اسم',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                [
                                  if (biz.category.isNotEmpty) biz.category,
                                  if (biz.governorate.isNotEmpty)
                                    biz.governorate,
                                  if (biz.city.isNotEmpty) biz.city,
                                ].join(' • '),
                                style: theme.bodySmall.copyWith(
                                  color: theme.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: biz.hasPendingEdits
                                ? theme.infoContainer
                                : biz.status == 'active'
                                    ? theme.successContainer
                                    : biz.status == 'rejected'
                                        ? theme.errorContainer
                                        : theme.warningContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            biz.hasPendingEdits
                                ? 'تعديل جديد من المالك'
                                : biz.status == 'active'
                                    ? 'معتمد ومنشور'
                                    : biz.status == 'rejected'
                                        ? 'مرفوض'
                                        : 'طلب جديد قيد المراجعة',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: biz.hasPendingEdits
                                  ? theme.info
                                  : biz.status == 'active'
                                      ? theme.success
                                      : biz.status == 'rejected'
                                          ? theme.error
                                          : theme.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (biz.phoneNumber.isNotEmpty ||
                        biz.address.isNotEmpty ||
                        ownerName.isNotEmpty)
                      Text(
                        [
                          if (ownerName.isNotEmpty) 'المالك: $ownerName',
                          if (ownerPhone.isNotEmpty) ownerPhone,
                          if (biz.phoneNumber.isNotEmpty &&
                              biz.phoneNumber != ownerPhone)
                            'هاتف المكان: ${biz.phoneNumber}',
                          if (biz.address.isNotEmpty) biz.address,
                        ].join(' • '),
                        style: theme.bodySmall.copyWith(
                          color: theme.secondaryText,
                        ),
                      ),
                    if (claimedId.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '🔗 طلب إثبات ملكية لمكان موجود مسبقاً على الخريطة (سيتم دمجه وربطه بصاحبه دون تكرار).',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryDark,
                          ),
                        ),
                      ),
                    ],
                    if (biz.hasPendingEdits &&
                        biz.lastEditSummary.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'ملخص التعديل: ${biz.lastEditSummary}',
                        style: theme.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.primaryText,
                        ),
                      ),
                    ],
                    if (biz.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        biz.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _buildAccessibilityFeatureChips(theme, {
                        'wheelchairEntrance': feat.wheelchairEntrance,
                        'ramp': feat.ramp,
                        'suitableElevator': feat.suitableElevator,
                        'accessibleRestroom': feat.accessibleRestroom,
                        'accessibleParking': feat.accessibleParking,
                      }),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showBusinessDetailsSheet(biz),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('عرض كل البيانات'),
                        ),
                        if (needsAction || biz.status == 'rejected')
                          FilledButton.icon(
                            onPressed: () =>
                                _approveAndSyncBusinessOwnerPlace(biz),
                            icon: const Icon(Icons.verified_rounded, size: 18),
                            label: Text(
                              biz.hasPendingEdits
                                  ? 'اعتماد التعديلات وتحديث الخريطة'
                                  : claimedId.isNotEmpty
                                      ? 'اعتماد الملكية وربط المكان'
                                      : 'قبول واعتماد ونشر',
                            ),
                          ),
                        if (needsAction || biz.status == 'active')
                          OutlinedButton.icon(
                            onPressed: () => _showRejectBusinessDialog(biz),
                            icon: Icon(Icons.close_rounded,
                                size: 18, color: theme.error),
                            label: Text('رفض / استكمال',
                                style: TextStyle(color: theme.error)),
                          ),
                        if (currentUserIsAdmin)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: theme.error.withValues(alpha: 0.55),
                              ),
                            ),
                            onPressed: () => _confirmDeleteBusiness(biz),
                            icon: Icon(Icons.delete_outline_rounded,
                                size: 18, color: theme.error),
                            label: Text('حذف',
                                style: TextStyle(color: theme.error)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubmissionsList(FlutterFlowTheme theme) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('placeSubmissions')
          .limit(80)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'تعذر تحميل الاقتراحات: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final ta = (a.data()['created_at'] as Timestamp?)?.toDate() ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final tb = (b.data()['created_at'] as Timestamp?)?.toDate() ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return tb.compareTo(ta);
          });
        if (docs.isEmpty) {
          return const Center(
            child: Text('لا توجد أماكن مقترحة من المستخدمين حتى الآن.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final name = (data['place_name'] as String?) ?? 'مكان مقترح';
            final cat = (data['category'] as String?) ?? '';
            final gov = (data['governorate'] as String?) ?? '';
            final city = (data['city'] as String?) ?? '';
            final addr = (data['address'] as String?) ?? '';
            final phone = (data['phone_number'] as String?) ?? '';
            final hours = (data['opening_hours'] as String?) ?? '';
            final desc = (data['description'] as String?) ?? '';
            final photoUrl = (data['photo_url'] as String?) ?? '';
            final submitterName = (data['submitter_name'] as String?) ?? '';
            final featuresMap = data['accessibility_features'] is Map
                ? Map<String, dynamic>.from(
                    data['accessibility_features'] as Map)
                : const <String, dynamic>{};
            final status = (data['status'] as String?) ?? 'pending';
            final isPending = status == 'new' ||
                status == 'pending' ||
                status == 'underReview';

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (photoUrl.trim().isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              photoUrl.trim(),
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 54,
                                height: 54,
                                color: theme.surfaceVariant,
                                child: const Icon(Icons.place_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                [
                                  if (cat.isNotEmpty) cat,
                                  if (gov.isNotEmpty) gov,
                                  if (city.isNotEmpty) city,
                                ].join(' • '),
                                style: theme.bodySmall.copyWith(
                                  color: theme.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'approved'
                                ? theme.successContainer
                                : status == 'rejected'
                                    ? theme.errorContainer
                                    : theme.warningContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status == 'approved'
                                ? 'تم النشر'
                                : status == 'rejected'
                                    ? 'مرفوض'
                                    : 'قيد المراجعة',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: status == 'approved'
                                  ? theme.success
                                  : status == 'rejected'
                                      ? theme.error
                                      : theme.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (addr.isNotEmpty ||
                        phone.isNotEmpty ||
                        hours.isNotEmpty ||
                        submitterName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (addr.isNotEmpty) addr,
                          if (phone.isNotEmpty) 'هاتف: $phone',
                          if (hours.isNotEmpty) 'المواعيد: $hours',
                          if (submitterName.isNotEmpty)
                            'مقترح من: $submitterName',
                        ].join(' • '),
                        style: theme.bodySmall.copyWith(
                          color: theme.secondaryText,
                        ),
                      ),
                    ],
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        desc,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodySmall.copyWith(height: 1.5),
                      ),
                    ],
                    if (featuresMap.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children:
                            _buildAccessibilityFeatureChips(theme, featuresMap),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showSubmissionDetailsSheet(doc.reference, data),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('عرض كل البيانات'),
                        ),
                        if (isPending || status == 'rejected')
                          FilledButton.icon(
                            onPressed: () => _showPlaceFormSheet(
                              prefillSubmission: data,
                              submissionRef: doc.reference,
                            ),
                            icon: const Icon(Icons.publish_rounded, size: 18),
                            label: const Text('مراجعة واعتماد ونشر'),
                          ),
                        if (isPending)
                          OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                await doc.reference.update({
                                  'status': 'rejected',
                                  'reviewed_by': currentUserEmail,
                                  'reviewed_at': FieldValue.serverTimestamp(),
                                });
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('تعذر الرفض: $e')),
                                  );
                                }
                              }
                            },
                            icon: Icon(Icons.close_rounded,
                                size: 18, color: theme.error),
                            label: Text('رفض',
                                style: TextStyle(color: theme.error)),
                          ),
                        if (currentUserIsAdmin)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: theme.error.withValues(alpha: 0.55),
                              ),
                            ),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (c) => Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: AlertDialog(
                                    title: const Text('تأكيد حذف الاقتراح'),
                                    content: Text(
                                      'هل أنت متأكد من حذف اقتراح «$name» نهائياً؟',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(c, false),
                                        child: const Text('إلغاء'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: theme.error,
                                        ),
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('حذف'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                              if (ok == true) {
                                await doc.reference.delete();
                              }
                            },
                            icon: Icon(Icons.delete_outline_rounded,
                                size: 18, color: theme.error),
                            label: Text('حذف',
                                style: TextStyle(color: theme.error)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ==============================================================================
// TAB 4: USERS & ROLES MANAGEMENT (Overflow-safe + Full Role Editor)
// ==============================================================================
class _UsersManagementTab extends StatefulWidget {
  const _UsersManagementTab();

  @override
  State<_UsersManagementTab> createState() => _UsersManagementTabState();
}

class _UsersManagementTabState extends State<_UsersManagementTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  static const _roleOptions = <({
    String value,
    String label,
    String subtitle,
    IconData icon,
  })>[
    (
      value: 'user',
      label: 'مستخدم عادي',
      subtitle: 'تصفح الأماكن، التقييم، اقتراح أماكن، والإبلاغ عن عوائق',
      icon: Icons.person_outline_rounded,
    ),
    (
      value: 'businessOwner',
      label: 'صاحب مكان',
      subtitle: 'عرض وتعديل بيانات وتجهيزات المكان الخاص به ومتابعة حالة التوثيق',
      icon: Icons.store_outlined,
    ),
    (
      value: 'admin',
      label: 'أدمن (Admin)',
      subtitle: 'إدارة الأماكن والبلاغات وأصحاب الأماكن والمستخدمين',
      icon: Icons.shield_outlined,
    ),
    (
      value: 'superAdmin',
      label: 'أدمن رئيسي (Super Admin)',
      subtitle: 'صلاحيات كاملة بما فيها إدارة حسابات الأدمن',
      icon: Icons.admin_panel_settings_rounded,
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _roleLabel(String role) {
    if (role == 'moderator') return 'أدمن (Admin)';
    for (final r in _roleOptions) {
      if (r.value == role) return r.label;
    }
    return 'مستخدم عادي';
  }

  Future<void> _updateUserRole(UsersRecord user, String newRole) async {
    if (!currentUserIsAdmin) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تعديل الصلاحيات متاح لمدير النظام فقط.'),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
      return;
    }
    final isCurrentSuperAdmin = currentUserDocument?.role == 'superAdmin';
    if (!isCurrentSuperAdmin &&
        (user.role == 'superAdmin' || newRole == 'superAdmin')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'تعديل أو تعيين صلاحية المدير العام (Super Admin) متاح للمدير العام فقط.',
          ),
          backgroundColor: FlutterFlowTheme.of(context).error,
        ),
      );
      return;
    }
    try {
      await user.reference.update({
        'role': newRole,
        'updated_time': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم حفظ صلاحية (${user.displayName.isNotEmpty ? user.displayName : user.email}) كـ: ${_roleLabel(newRole)}',
          ),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final isPermDenied = e.code == 'permission-denied';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPermDenied
                ? 'مطلوب نشر ملف firestore.rules المحدّث في Firebase Console > Firestore > Rules > Publish لتفعيل تعديل الصلاحيات من التطبيق.'
                : 'تعذر تعديل الصلاحية: ${e.message ?? e.code}',
          ),
          backgroundColor: FlutterFlowTheme.of(context).error,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تعديل الصلاحية: $e'),
          backgroundColor: FlutterFlowTheme.of(context).error,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showRoleEditorSheet(UsersRecord user) {
    final theme = FlutterFlowTheme.of(context);
    final isCurrentSuperAdmin = currentUserDocument?.role == 'superAdmin';
    String selectedRole = user.role.isNotEmpty ? user.role : 'user';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'تحديد صلاحيات المستخدم',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.displayName.isNotEmpty
                                    ? '${user.displayName} (${user.email})'
                                    : user.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.bodySmall.copyWith(
                                  color: theme.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final opt in _roleOptions)
                      if (opt.value != 'superAdmin' || isCurrentSuperAdmin)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () =>
                                setSheetState(() => selectedRole = opt.value),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedRole == opt.value
                                    ? theme.primary.withValues(alpha: 0.1)
                                    : theme.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selectedRole == opt.value
                                      ? theme.primary
                                      : theme.divider,
                                  width: selectedRole == opt.value ? 1.8 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    opt.icon,
                                    color: selectedRole == opt.value
                                        ? theme.primary
                                        : theme.secondaryText,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          opt.label,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: theme.primaryText,
                                          ),
                                        ),
                                        Text(
                                          opt.subtitle,
                                          style: theme.bodySmall.copyWith(
                                            fontSize: 12,
                                            color: theme.secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selectedRole == opt.value)
                                    Icon(Icons.check_circle_rounded,
                                        color: theme.primary),
                                ],
                              ),
                            ),
                          ),
                        ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _updateUserRole(user, selectedRole);
                      },
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('حفظ الصلاحية'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPromoteByEmailDialog(List<UsersRecord> allUsers) {
    final emailCtrl = TextEditingController();
    String targetRole = 'admin';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة / ترقية مدير نظام'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'أدخل البريد الإلكتروني لحساب مسجّل في التطبيق لتعيين صلاحيته:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      hintText: 'admin@example.com',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: targetRole,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'الصلاحية المطلوبة',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'admin', child: Text('أدمن (Admin)')),
                      DropdownMenuItem(
                          value: 'businessOwner',
                          child: Text('صاحب مكان')),
                      DropdownMenuItem(
                          value: 'user', child: Text('مستخدم عادي')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => targetRole = v);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () async {
                  final email = emailCtrl.text.trim().toLowerCase();
                  if (email.isEmpty) return;
                  final match = allUsers
                      .where((u) => u.email.trim().toLowerCase() == email)
                      .firstOrNull;
                  if (match == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'لا يوجد حساب مسجّل بهذا البريد بعد. اطلب منه إنشاء حساب أولاً.',
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  await _updateUserRole(match, targetRole);
                },
                child: const Text('حفظ الصلاحية'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: UsersRecord.collection
          .orderBy('created_time', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('خطأ في التحميل: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allUsers =
            snapshot.data!.docs.map(UsersRecord.fromSnapshot).toList();
        final q = _searchQuery.trim().toLowerCase();
        final users = q.isEmpty
            ? allUsers
            : allUsers.where((u) {
                return u.displayName.toLowerCase().contains(q) ||
                    u.email.toLowerCase().contains(q) ||
                    u.role.toLowerCase().contains(q);
              }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                  final stackControls =
                      constraints.maxWidth < 380 || textScale >= 1.25;
                  final searchField = TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم أو البريد...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  );
                  final addAdminBtn = currentUserIsAdmin
                      ? FilledButton.icon(
                          onPressed: () => _showPromoteByEmailDialog(allUsers),
                          icon: const Icon(Icons.person_add_alt_1_rounded,
                              size: 18),
                          label: const Text(
                            'إضافة مدير',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        )
                      : null;
                  if (addAdminBtn == null) return searchField;
                  if (stackControls) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        searchField,
                        const SizedBox(height: 8),
                        addAdminBtn,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: searchField),
                      const SizedBox(width: 8),
                      addAdminBtn,
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: users.isEmpty
                  ? const Center(
                      child: Text('لا يوجد مستخدمين مطابقين للبحث.'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final isAdmin =
                            user.role == 'admin' || user.role == 'superAdmin';
                        final isSelf = user.uid == currentUserUid;
                        final isCurrentSuperAdmin =
                            currentUserDocument?.role == 'superAdmin';
                        final canEditThisUser = currentUserIsAdmin &&
                            (user.role != 'superAdmin' || isCurrentSuperAdmin);

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isAdmin
                                          ? theme.tertiaryLight
                                          : theme.infoContainer,
                                      child: Icon(
                                        isAdmin
                                            ? Icons.shield_rounded
                                            : Icons.person_rounded,
                                        color: isAdmin
                                            ? theme.tertiaryDark
                                            : theme.info,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  user.displayName.isNotEmpty
                                                      ? user.displayName
                                                      : 'مستخدم بدون اسم',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                              if (isSelf) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        theme.successContainer,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    'أنت',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: theme.success,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (user.email.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              user.email,
                                              maxLines: 1,
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
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isAdmin
                                            ? theme.tertiaryLight
                                            : theme.surfaceVariant,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'الدور: ${_roleLabel(user.role)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isAdmin
                                              ? theme.tertiaryDark
                                              : theme.primaryText,
                                        ),
                                      ),
                                    ),
                                    if (canEditThisUser)
                                      OutlinedButton.icon(
                                        onPressed: () =>
                                            _showRoleEditorSheet(user),
                                        icon: const Icon(
                                            Icons.manage_accounts_rounded,
                                            size: 18),
                                        label: const Text('تعديل الصلاحية'),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(0, 38),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                        ),
                                      )
                                    else if (user.role == 'superAdmin')
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: theme.surfaceVariant,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'محمي • Super Admin',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: theme.secondaryText,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

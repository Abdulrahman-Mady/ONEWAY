import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/accessibility_reports_record.dart';
import '/backend/schema/places_record.dart';
import '/backend/schema/reviews_record.dart';
import '/backend/schema/users_record.dart';
import '/backend/seed_data.dart';
import '/flutter_flow/flutter_flow_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'لوحة تحكم الإدارة - ONEWAY',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.analytics_outlined), text: 'المؤشرات'),
              Tab(icon: Icon(Icons.assignment_late_outlined), text: 'البلاغات'),
              Tab(icon: Icon(Icons.place_outlined), text: 'الأماكن'),
              Tab(icon: Icon(Icons.people_outline), text: 'المستخدمين'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(
                onNavigateToTab: (index) => _tabController.animateTo(index)),
            const _ReportsModerationTab(),
            const _PlacesManagementTab(),
            const _UsersManagementTab(),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// TAB 1: OVERVIEW & STATS
// ==============================================================================
class _OverviewTab extends StatefulWidget {
  const _OverviewTab({required this.onNavigateToTab});
  final void Function(int) onNavigateToTab;

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  bool _seeding = false;
  String? _seedingMessage;

  Future<void> _seedInitialPlaces() async {
    setState(() {
      _seeding = true;
      _seedingMessage = null;
    });
    try {
      final count = await OnewayDataSeeder.seedPlaces();
      if (mounted) {
        setState(() =>
            _seedingMessage = 'تم بنجاح إضافة $count أماكن أولية معتمدة!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _seedingMessage = 'خطأ أثناء الاستيراد: $e');
      }
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Admin Greeting & Role Badge
        Card(
          color: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.amber,
                  child: Icon(Icons.shield, color: Colors.black87, size: 30),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUserEmail,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber, width: 1),
                        ),
                        child: const Text(
                          'حساب مصرح بكامل الصلاحيات (Admin)',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Live Stats Grid
        const Text(
          'إحصائيات المنصة الحية',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'الأماكن المسجلة',
                icon: Icons.place,
                color: Colors.teal,
                stream: PlacesRecord.collection.snapshots(),
                subtitle: (count) => '$count مكان متاح',
                onTap: () => widget.onNavigateToTab(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'بلاغات العوائق',
                icon: Icons.assignment_late,
                color: Colors.orange,
                stream: AccessibilityReportsRecord.collection.snapshots(),
                subtitle: (count) => '$count بلاغ وارد',
                onTap: () => widget.onNavigateToTab(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'المستخدمين',
                icon: Icons.people,
                color: Colors.indigo,
                stream: UsersRecord.collection.snapshots(),
                subtitle: (count) => '$count حساب مسجل',
                onTap: () => widget.onNavigateToTab(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'تقييمات الإتاحة',
                icon: Icons.star,
                color: Colors.amber.shade800,
                stream: ReviewsRecord.collection.snapshots(),
                subtitle: (count) => '$count تقييم معتمد',
                onTap: () => widget.onNavigateToTab(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Quick Administrative Actions
        const Text(
          'إجراءات الإدارة السريعة',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(Icons.add_location_alt, color: Colors.blue),
                ),
                title: const Text('إضافة مكان مجهز جديد'),
                subtitle: const Text(
                    'إدراج مستشفى، مول، أو منشأة وتحديد ميزات الإتاحة.'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => widget.onNavigateToTab(2),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFEF3C7),
                  child: Icon(Icons.cloud_upload_outlined, color: Colors.amber),
                ),
                title: const Text('استيراد الأماكن المعتمدة الأولية'),
                subtitle:
                    const Text('تغذية قاعدة البيانات بـ 8 أماكن مصرية معتمدة.'),
                trailing: _seeding
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                onTap: _seeding ? null : _seedInitialPlaces,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFEE2E2),
                  child: Icon(Icons.assignment_late, color: Colors.red),
                ),
                title: const Text('مراجعة بلاغات العوائق المعلقة'),
                subtitle:
                    const Text('فحص بلاغات المستخدمين وتغيير حالتها فورياً.'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => widget.onNavigateToTab(1),
              ),
            ],
          ),
        ),
        if (_seedingMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _seedingMessage!.contains('بنجاح')
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _seedingMessage!,
              style: TextStyle(
                color: _seedingMessage!.contains('بنجاح')
                    ? Colors.green.shade800
                    : Colors.red.shade800,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.stream,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Stream<QuerySnapshot> stream;
  final String Function(int) subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Icon(icon, color: color, size: 24),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle(count),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==============================================================================
// TAB 2: REPORTS MODERATION
// ==============================================================================
class _ReportsModerationTab extends StatefulWidget {
  const _ReportsModerationTab();

  @override
  State<_ReportsModerationTab> createState() => _ReportsModerationTabState();
}

class _ReportsModerationTabState extends State<_ReportsModerationTab> {
  String _filterStatus = 'all';

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
        'needsMoreInformation' => 'معلومات إضافية',
        'verified' => 'تم التحقق',
        'resolved' => 'تم الحل',
        'rejected' => 'مرفوض',
        _ => s,
      };

  Color _statusColor(String s) => switch (s) {
        'new' => Colors.orange,
        'underReview' => Colors.blue,
        'needsMoreInformation' => Colors.purple,
        'verified' => Colors.green,
        'resolved' => Colors.teal,
        'rejected' => Colors.red,
        _ => Colors.grey,
      };

  Future<void> _updateStatus(
    AccessibilityReportsRecord report,
    String newStatus,
  ) async {
    try {
      await report.reference.update({'status': newStatus});

      // Send user notification about status update
      if (report.createdBy.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': report.createdBy,
          'title': 'تحديث بخصوص بلاغك',
          'body':
              'بلاغك عن (${report.placeName}) أصبحت حالته: ${_statusLabel(newStatus)}.',
          'type': 'report_status',
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('تم تحديث حالة البلاغ إلى: ${_statusLabel(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر التحديث: $e')),
        );
      }
    }
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
    return Column(
      children: [
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('الكل'),
                selected: _filterStatus == 'all',
                onSelected: (_) => setState(() => _filterStatus = 'all'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('جديد'),
                selected: _filterStatus == 'new',
                onSelected: (_) => setState(() => _filterStatus = 'new'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('قيد المراجعة'),
                selected: _filterStatus == 'underReview',
                onSelected: (_) =>
                    setState(() => _filterStatus = 'underReview'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('تم التحقق'),
                selected: _filterStatus == 'verified',
                onSelected: (_) => setState(() => _filterStatus = 'verified'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('مرفوض'),
                selected: _filterStatus == 'rejected',
                onSelected: (_) => setState(() => _filterStatus = 'rejected'),
              ),
            ],
          ),
        ),

        // Reports Stream
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: AccessibilityReportsRecord.collection
                .orderBy('created_at', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('خطأ في التحميل: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var reports = snapshot.data!.docs
                  .map(AccessibilityReportsRecord.fromSnapshot)
                  .toList();

              if (_filterStatus != 'all') {
                reports =
                    reports.where((r) => r.status == _filterStatus).toList();
              }

              if (reports.isEmpty) {
                return const Center(
                  child: Text('لا توجد بلاغات مطابقة لهذا الفلتر.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final report = reports[index];
                  final status =
                      _statuses.contains(report.status) ? report.status : 'new';

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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
                                  report.placeName.isEmpty
                                      ? 'عائق عام في الطريق'
                                      : report.placeName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(status)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _statusLabel(status),
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.category,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                report.problemCategory,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal),
                              ),
                              const Spacer(),
                              Text(
                                'بواسطة: ${report.userName.isEmpty ? "مستخدم" : report.userName}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              report.description,
                              style: const TextStyle(height: 1.4),
                            ),
                          ),

                          // Photos preview if any
                          if (report.photoUrls.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 80,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: report.photoUrls.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, pIndex) {
                                  final pUrl = report.photoUrls[pIndex];
                                  return InkWell(
                                    onTap: () => _showImageDialog(pUrl),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        pUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.broken_image),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),

                          // Status Dropdown and Delete Action
                          Row(
                            children: [
                              const Text('تغيير الحالة: ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: status,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  items: _statuses
                                      .map((s) => DropdownMenuItem(
                                            value: s,
                                            child: Text(_statusLabel(s)),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null && val != report.status) {
                                      _updateStatus(report, val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'حذف البلاغ',
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('تأكيد الحذف'),
                                      content: const Text(
                                          'هل أنت متأكد من حذف هذا البلاغ؟'),
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
                                    report.reference.delete();
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
}

// ==============================================================================
// TAB 3: PLACES MANAGEMENT
// ==============================================================================
class _PlacesManagementTab extends StatefulWidget {
  const _PlacesManagementTab();

  @override
  State<_PlacesManagementTab> createState() => _PlacesManagementTabState();
}

class _PlacesManagementTabState extends State<_PlacesManagementTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddPlaceDialog() {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'طبي ومستشفيات');
    final cityCtrl = TextEditingController(text: 'القاهرة');
    final govCtrl = TextEditingController(text: 'محافظة القاهرة');
    final addrCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final webCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final photoCtrl = TextEditingController();

    bool wheelchair = true;
    bool ramp = true;
    bool elevator = true;
    bool restroom = true;
    bool parking = false;
    bool verified = true;

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
                      const Text(
                        'إضافة مكان متاح جديد',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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
                    value: catCtrl.text,
                    decoration: const InputDecoration(
                      labelText: 'التصنيف',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'طبي ومستشفيات', child: Text('طبي ومستشفيات')),
                      DropdownMenuItem(
                          value: 'تسوق ومراكز تجارية',
                          child: Text('تسوق ومراكز تجارية')),
                      DropdownMenuItem(
                          value: 'ثقافة وسياحة', child: Text('ثقافة وسياحة')),
                      DropdownMenuItem(
                          value: 'تعليم وجامعات', child: Text('تعليم وجامعات')),
                      DropdownMenuItem(
                          value: 'مواصلات ومحطات',
                          child: Text('مواصلات ومحطات')),
                    ],
                    onChanged: (v) => setModalState(() => catCtrl.text = v!),
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
                      labelText: 'رقم هاتف المكان',
                      border: OutlineInputBorder(),
                    ),
                  ),
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
                  SwitchListTile(
                    title: const Text('اعتماد المكان فورياً كـ (Verified)'),
                    value: verified,
                    activeColor: Colors.green,
                    onChanged: (v) => setModalState(() => verified = v),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('أدخل اسم المكان أولاً')),
                        );
                        return;
                      }

                      Navigator.pop(ctx);
                      try {
                        await PlacesRecord.collection.add({
                          'name': nameCtrl.text.trim(),
                          'category': catCtrl.text,
                          'city': cityCtrl.text.trim(),
                          'governorate': govCtrl.text.trim(),
                          'address': addrCtrl.text.trim(),
                          'phone_number': phoneCtrl.text.trim(),
                          'website': webCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'photo_url': photoCtrl.text.trim().isNotEmpty
                              ? photoCtrl.text.trim()
                              : 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800',
                          'photos': <String>[],
                          'location': const GeoPoint(30.0444, 31.2357),
                          'accessibility_features': {
                            'wheelchairEntrance': wheelchair,
                            'ramp': ramp,
                            'suitableElevator': elevator,
                            'accessibleRestroom': restroom,
                            'accessibleParking': parking,
                            'corridorWidth': 'أكثر من 120 سم',
                            'entranceObstacles': 'لا يوجد',
                          },
                          'verification_status':
                              verified ? 'verified' : 'needsUpdate',
                          'verified_by': currentUserEmail,
                          'last_verified_at': FieldValue.serverTimestamp(),
                          'created_at': FieldValue.serverTimestamp(),
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('تمت إضافة المكان بنجاح إلى التطبيق!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تعذر إضافة المكان: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('حفظ ونشر المكان'),
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
    return Column(
      children: [
        // Search and Add Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'بحث في الأماكن بالاسم أو المدينة...',
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _showAddPlaceDialog,
                icon: const Icon(Icons.add),
                label: const Text('إضافة مكان'),
              ),
            ],
          ),
        ),

        // Places List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: PlacesRecord.collection.snapshots(),
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
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isVerified
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        child: Icon(
                          isVerified ? Icons.verified : Icons.help_outline,
                          color: isVerified ? Colors.green : Colors.orange,
                        ),
                      ),
                      title: Text(
                        place.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${place.category} • ${place.city}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isVerified)
                            IconButton(
                              tooltip: 'اعتماد المكان وتوثيقه',
                              icon: const Icon(Icons.check_circle_outline,
                                  color: Colors.green),
                              onPressed: () {
                                place.reference.update({
                                  'verification_status': 'verified',
                                  'verified_by': currentUserEmail,
                                  'last_verified_at':
                                      FieldValue.serverTimestamp(),
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'تم اعتماد مكان (${place.name}) بنجاح!')),
                                );
                              },
                            ),
                          IconButton(
                            tooltip: 'حذف المكان',
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
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
                                        onPressed: () => Navigator.pop(c, true),
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
}

// ==============================================================================
// TAB 4: USERS & ROLES MANAGEMENT
// ==============================================================================
class _UsersManagementTab extends StatelessWidget {
  const _UsersManagementTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: UsersRecord.collection
          .orderBy('created_time', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('خطأ في التحميل: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users =
            snapshot.data!.docs.map(UsersRecord.fromSnapshot).toList();

        if (users.isEmpty) {
          return const Center(child: Text('لا يوجد مستخدمين مسجلين بعد.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final user = users[index];
            final isAdmin = user.role == 'admin' || user.role == 'superAdmin';
            final isSelf = user.uid == currentUserUid;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      isAdmin ? Colors.amber.shade100 : Colors.blue.shade50,
                  child: Icon(
                    isAdmin ? Icons.shield : Icons.person,
                    color: isAdmin ? Colors.amber.shade900 : Colors.blue,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      user.displayName.isNotEmpty
                          ? user.displayName
                          : 'مستخدم بدون اسم',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'أنت',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  '${user.email}\nالدور الحالي: ${isAdmin ? "مدير نظام (Admin)" : "مستخدم عادي (User)"}',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  tooltip: 'تغيير الدور',
                  onSelected: (newRole) async {
                    try {
                      await user.reference.update({'role': newRole});
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم تعديل دور ${user.displayName} إلى: ${newRole == "admin" ? "مدير نظام" : "مستخدم عادي"}',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تعذر تعديل الدور: $e')),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'admin',
                      child: Row(
                        children: [
                          Icon(Icons.shield, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Text('ترقية إلى مدير نظام (Admin)'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'user',
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.grey, size: 20),
                          SizedBox(width: 8),
                          Text('تعيين كمستخدم عادي (User)'),
                        ],
                      ),
                    ),
                  ],
                  child: Chip(
                    backgroundColor:
                        isAdmin ? Colors.amber.shade100 : Colors.grey.shade100,
                    label: Text(
                      isAdmin ? 'مدير نظام 🛡️' : 'مستخدم عادي 👤',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isAdmin ? Colors.amber.shade900 : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

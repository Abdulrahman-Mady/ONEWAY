import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/businesses_record.dart';
import '/backend/schema/accessibility_reports_record.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'business_admin_dashboard_model.dart';
export 'business_admin_dashboard_model.dart';

class BusinessAdminDashboardWidget extends StatefulWidget {
  const BusinessAdminDashboardWidget({super.key});

  static String routeName = 'BusinessAdminDashboard';
  static String routePath = '/business-admin';

  @override
  State<BusinessAdminDashboardWidget> createState() =>
      _BusinessAdminDashboardWidgetState();
}

class _BusinessAdminDashboardWidgetState
    extends State<BusinessAdminDashboardWidget> {
  late BusinessAdminDashboardModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BusinessAdminDashboardModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _showRegisterBusinessDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController(text: currentUserEmail);
    String selectedCategory = 'مطاعم وكافيهات';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تسجيل منشأة جديدة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'سجّل منشأتك (مطعم، مستشفى، مول، فندق) في Accessible Egypt لتوثيق الإتاحة والوصول لعملاء جدد.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المنشأة أو الشركة *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'تصنيف المنشأة',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'مطاعم وكافيهات',
                          child: Text('مطاعم وكافيهات')),
                      DropdownMenuItem(
                          value: 'طبي ومستشفيات',
                          child: Text('طبي ومستشفيات')),
                      DropdownMenuItem(
                          value: 'تسوق ومراكز تجارية',
                          child: Text('تسوق ومراكز تجارية')),
                      DropdownMenuItem(
                          value: 'فنادق وسياحة', child: Text('فنادق وسياحة')),
                      DropdownMenuItem(
                          value: 'تعليم وجامعات', child: Text('تعليم وجامعات')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم هاتف التواصل *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () async {
                  final bName = nameController.text.trim();
                  final bPhone = phoneController.text.trim();
                  if (bName.isEmpty || bPhone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('يرجى ملء جميع الحقول المطلوبة.')),
                    );
                    return;
                  }

                  Navigator.pop(dialogCtx);
                  try {
                    await BusinessesRecord.collection.add({
                      'ownerId': currentUserUid,
                      'business_name': bName,
                      'category': selectedCategory,
                      'phone_number': bPhone,
                      'email': emailController.text.trim(),
                      'status': 'pending',
                      'subscription_tier': 'free',
                      'branch_place_ids': <String>[],
                      'created_at': FieldValue.serverTimestamp(),
                      'updated_at': FieldValue.serverTimestamp(),
                    });

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'تم تقديم طلب تسجيل المنشأة بنجاح وهو قيد المراجعة.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } on FirebaseException catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(e.message ?? 'تعذر تسجيل المنشأة.')),
                      );
                    }
                  }
                },
                child: const Text('تسجيل المنشأة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFieldAssessmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.verified_rounded, color: Colors.blue),
              SizedBox(width: 8),
              Text('طلب تقييم ميداني رسمي'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'خدمة التقييم الميداني لمنشأتك تشمل:\n'
                '• زيارة ميدانية من متخصصي الإتاحة الحركية.\n'
                '• قياس دقيق للمنحدرات وعرض الأبواب والمصاعد والحمامات.\n'
                '• تقرير هندسي معتمد بتوصيات تحسين سهولة الوصول.\n'
                '• منح شارة المكان الموثق (Verified) داخل التطبيق.\n\n'
                'التكلفة الإرشادية: 5,000 ج للمنشأة.',
                style: TextStyle(height: 1.5, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .add({
                    'userId': currentUserUid,
                    'title': 'تم استلام طلب التقييم الميداني',
                    'body':
                        'سيتواصل معك فريق Accessible Egypt لتنسيق موعد الزيارة الميدانية.',
                    'type': 'business_assessment',
                    'is_read': false,
                    'created_at': FieldValue.serverTimestamp(),
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'تم إرسال طلب التقييم بنجاح. سيتواصل معك فريق العمل قريباً.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (_) {}
              },
              child: const Text('تأكيد إرسال الطلب'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.background,
        body: StreamBuilder<QuerySnapshot>(
          stream: BusinessesRecord.collection
              .where('ownerId', isEqualTo: currentUserUid)
              .snapshots(),
          builder: (context, snapshot) {
            BusinessesRecord? business;
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              business =
                  BusinessesRecord.fromSnapshot(snapshot.data!.docs.first);
            }

            return SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Bar
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: theme.outlineVariant,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: theme.primary,
                              child:
                                  const Icon(Icons.business_center, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  business != null
                                      ? business.businessName
                                      : (currentUserDisplayName.isNotEmpty
                                          ? currentUserDisplayName
                                          : 'بوابة المنشآت والأعمال'),
                                  style: theme.titleMedium.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: theme.primaryText,
                                  ),
                                ),
                                Text(
                                  business != null
                                      ? '${business.category} • باقة ${business.subscriptionTier}'
                                      : 'Accessible Business Portal',
                                  style: theme.bodySmall.copyWith(
                                    fontSize: 12,
                                    color: theme.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          tooltip: 'رجوع للرئيسية',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => context.safePop(),
                        ),
                      ],
                    ),
                  ),

                  // Main Body Content
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Unregistered Banner if no business found
                        if (business == null) ...[
                          _BannerCard(
                            icon: Icons.storefront,
                            iconColor: theme.secondary,
                            title: 'سجّل منشأتك على ONEWAY',
                            subtitle:
                                'أضف بيانات مطعمك أو مستشفاك أو مركزك التجاري لإظهار خدمات الإتاحة، وجذب عملاء جدد من ذوي الإعاقة الحركية وأسرهم.',
                            actionLabel: 'تسجيل منشأة الآن',
                            onAction: () => _showRegisterBusinessDialog(context),
                            theme: theme,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Metrics Cards
                        Text(
                          'مؤشرات الأداء والإتاحة',
                          style: theme.titleMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: theme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                icon: Icons.store,
                                color: theme.secondary,
                                label: 'الفروع التابعة',
                                value: business != null
                                    ? '${business.branchPlaceIds.length} فروع'
                                    : '0',
                                theme: theme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                icon: Icons.verified_user,
                                color: theme.success,
                                label: 'حالة التوثيق',
                                value: business != null
                                    ? (business.status == 'active'
                                        ? 'موثق ✅'
                                        : 'قيد المراجعة ⏳')
                                    : 'غير مسجل',
                                theme: theme,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                icon: Icons.workspace_premium,
                                color: theme.tertiary,
                                label: 'الباقة الحالية',
                                value: business != null
                                    ? business.subscriptionTier
                                    : 'أساسية',
                                theme: theme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: AccessibilityReportsRecord.collection
                                    .limit(50)
                                    .snapshots(),
                                builder: (ctx, repSnap) {
                                  final count =
                                      repSnap.hasData ? repSnap.data!.size : 0;
                                  return _MetricCard(
                                    icon: Icons.report_problem_outlined,
                                    color: theme.tertiary,
                                    label: 'بلاغات الإتاحة',
                                    value: '$count بلاغات',
                                    theme: theme,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Management Actions
                        Text(
                          'إدارة المنشأة والخدمات',
                          style: theme.titleMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: theme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          color: theme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(theme.designToken.radius.xl),
                            side: BorderSide(color: theme.outlineVariant, width: 1.5),
                          ),
                          child: Column(
                            children: [
                              _ActionListTile(
                                icon: Icons.assignment_turned_in,
                                iconColor: theme.secondary,
                                title: 'طلب تقييم ميداني رسمي',
                                subtitle:
                                    'زيارة ميدانية وتقييم هندسي للمداخل والمرافق مع شهادة إتاحة',
                                onTap: () => _showFieldAssessmentDialog(context),
                                theme: theme,
                              ),
                              Divider(
                                height: 1,
                                color: theme.outlineVariant,
                                indent: 16,
                                endIndent: 16,
                              ),
                              _ActionListTile(
                                icon: Icons.edit_note,
                                iconColor: theme.tertiary,
                                title: 'تحديث بيانات الإتاحة للفروع',
                                subtitle:
                                    'تحديث تفاصيل المنحدرات والمصاعد والحمامات المجهزة',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'يمكنك تحديث بيانات فروعك مباشرة من صفحة تفاصيل المكان أو بطلب مراجعة رسمية.'),
                                    ),
                                  );
                                },
                                theme: theme,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Monetization & Subscription Plans
                        Text(
                          'باقات وخطط الأعمال (B2B Plans)',
                          style: theme.titleMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: theme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SubscriptionTierCard(
                          title: '1. باقة التقييم الميداني (One-Time)',
                          price: '5,000 جنيهاً / للمنشأة',
                          badge: 'الأكثر طلباً',
                          features: const [
                            'زيارة ميدانية شاملة من مهندسي الإتاحة',
                            'تقرير فني تفصيلي بالمداخل والمنحدرات والمصاعد',
                            'توصيات هندسية لتحسين إمكانية الوصول',
                            'منح شارة المكان الموثوق (Verified Place) في التطبيق',
                          ],
                          onAction: () => _showFieldAssessmentDialog(context),
                          actionLabel: 'طلب تقييم الآن',
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        _SubscriptionTierCard(
                          title: '2. الاشتراك المؤسسي الشهري (Pro)',
                          price: '1,000 جنيهاً / شهرياً',
                          badge: 'للمنشآت النشطة',
                          features: const [
                            'لوحة تحكم وتحليلات متقدمة لزيارات العملاء',
                            'إدارة متعددة للفروع وساعات العمل',
                            'أولوية مراجعة تحديثات الإتاحة من الإدارة',
                            'الرد على ملاحظات وتقييمات العملاء',
                          ],
                          onAction: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'تواصل مع فريق المبيعات لتفعيل الاشتراك المؤسسي: business@accessible-egypt.com'),
                              ),
                            );
                          },
                          actionLabel: 'تواصل مع المبيعات',
                          theme: theme,
                        ),
                        const SizedBox(height: 16),

                        // Ethical Transparency Notice
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.tertiary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
                            border: Border.all(color: theme.tertiary, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.shield_outlined,
                                  color: theme.tertiary, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'ميثاق النزاهة: الاشتراك المؤسسي يمنحك ميزات الإدارة والتحليلات فقط. شارة التحقق لا تُباع، ويتم منحها حصرياً بناءً على تقييم ميداني مستقل وصحيح.',
                                  style: theme.bodySmall.copyWith(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: theme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    required this.theme,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: theme.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        side: BorderSide(color: theme.primary, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.titleMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.bodyMedium.copyWith(
                fontSize: 13,
                height: 1.5,
                color: theme.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_business),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
      color: theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        side: BorderSide(color: theme.outlineVariant, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.titleMedium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.bodySmall.copyWith(
                fontSize: 12,
                color: theme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionListTile extends StatelessWidget {
  const _ActionListTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.theme,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.1),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: theme.bodyMedium.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: theme.primaryText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.bodySmall.copyWith(
          fontSize: 12,
          color: theme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(Icons.chevron_left, color: theme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}

class _SubscriptionTierCard extends StatelessWidget {
  const _SubscriptionTierCard({
    required this.title,
    required this.price,
    required this.badge,
    required this.features,
    required this.onAction,
    required this.actionLabel,
    required this.theme,
  });

  final String title;
  final String price;
  final String badge;
  final List<String> features;
  final VoidCallback onAction;
  final String actionLabel;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        side: BorderSide(color: theme.outlineVariant, width: 1.5),
      ),
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
                    title,
                    style: theme.bodyMedium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                ),
                Chip(
                  label: Text(badge, style: theme.labelSmall.copyWith(fontSize: 11)),
                  backgroundColor: theme.primary.withValues(alpha: 0.1),
                  side: BorderSide(color: theme.primary, width: 1),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: theme.titleMedium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: theme.secondary,
              ),
            ),
            const SizedBox(height: 12),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 16, color: theme.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(f,
                            style: theme.bodySmall.copyWith(
                              fontSize: 12,
                              color: theme.onSurfaceVariant,
                            )),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 14),
            FilledButton.tonal(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
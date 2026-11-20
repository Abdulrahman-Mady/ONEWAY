import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/backend/schema/accessibility_reports_record.dart';
import '/backend/schema/emergency_contacts_record.dart';
import '/backend/schema/notifications_record.dart';
import '/backend/schema/users_record.dart';
import '/backend/seed_data.dart';
import '/features/emergency/emergency_service.dart';
import 'package:go_router/go_router.dart';

class MyReportsPage extends StatelessWidget {
  const MyReportsPage({super.key});

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('بلاغاتي')),
          body: StreamBuilder<QuerySnapshot>(
            stream: AccessibilityReportsRecord.collection
                .where('createdBy', isEqualTo: currentUserUid)
                .orderBy('created_at', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const _MessageState(
                    'تعذر تحميل البلاغات. تأكد من الاتصال ثم أعد المحاولة.');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final reports = snapshot.data!.docs
                  .map(AccessibilityReportsRecord.fromSnapshot)
                  .toList();
              if (reports.isEmpty) {
                return const _MessageState('لم ترسل أي بلاغات بعد.');
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final report = reports[index];
                  return Card(
                    child: ListTile(
                      title: Text(report.placeName.isEmpty
                          ? 'مكان غير محدد'
                          : report.placeName),
                      subtitle: Text(
                          '${report.problemCategory}\n${report.description}'),
                      isThreeLine: true,
                      trailing: _ReportStatus(status: report.status),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
}

class NotificationsCenterPage extends StatelessWidget {
  const NotificationsCenterPage({super.key});

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('الإشعارات')),
          body: StreamBuilder<QuerySnapshot>(
            stream: NotificationsRecord.collection
                .where('userId', isEqualTo: currentUserUid)
                .orderBy('created_at', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const _MessageState('تعذر تحميل الإشعارات.');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final notifications = snapshot.data!.docs
                  .map(NotificationsRecord.fromSnapshot)
                  .toList();
              if (notifications.isEmpty) {
                return const _MessageState('لا توجد إشعارات جديدة.');
              }
              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (_, index) {
                  final notification = notifications[index];
                  return ListTile(
                    leading: Icon(notification.isRead
                        ? Icons.notifications_none
                        : Icons.notifications),
                    title: Text(notification.title),
                    subtitle: Text(notification.body),
                    tileColor: notification.isRead
                        ? null
                        : Theme.of(context).colorScheme.secondaryContainer,
                    onTap: notification.isRead
                        ? null
                        : () =>
                            notification.reference.update({'is_read': true}),
                  );
                },
              );
            },
          ),
        ),
      );
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  bool _triggeringSOS = false;

  Future<void> _handleTriggerSOS() async {
    setState(() => _triggeringSOS = true);
    try {
      final result = await EmergencyService.triggerSOS();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor:
              result.success ? FlutterFlowTheme.of(context).error : FlutterFlowTheme.of(context).onWarningContainer,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إطلاق الاستغاثة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _triggeringSOS = false);
    }
  }

  Future<void> _setAsPrimary(EmergencyContactsRecord target) async {
    try {
      final snapshot = await EmergencyContactsRecord.collection
          .where('userId', isEqualTo: currentUserUid)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(
            doc.reference, {'is_primary': doc.id == target.reference.id});
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('تم تعيين ${target.name} كمرافق رئيسي للطوارئ.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر التعيين: $e')),
        );
      }
    }
  }

  Future<void> _addContact(BuildContext context, bool isFirst) async {
    final name = TextEditingController();
    final relation = TextEditingController();
    final phone = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة جهة اتصال للطوارئ'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: name,
              decoration:
                  const InputDecoration(labelText: 'اسم المرافق / الشخص'),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'أدخل الاسم' : null,
            ),
            TextFormField(
              controller: relation,
              decoration: const InputDecoration(
                  labelText: 'صلة القرابة (مثال: أخ، صديق، والد)'),
            ),
            TextFormField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف (يدعم واتساب)',
                hintText: '010XXXXXXXX',
              ),
              validator: (value) =>
                  (value ?? '').trim().length < 8 ? 'أدخل رقماً صحيحاً' : null,
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (result != true) {
      return;
    }
    try {
      await EmergencyContactsRecord.collection.add({
        'userId': currentUserUid,
        'name': name.text.trim(),
        'relationship': relation.text.trim(),
        'phone_number': phone.text.trim(),
        'is_primary': isFirst,
        'created_at': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة جهة الاتصال بنجاح.')),
        );
      }
    } on FirebaseException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'تعذر حفظ جهة الاتصال.')),
        );
      }
    } finally {
      name.dispose();
      relation.dispose();
      phone.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('مساعدة الطوارئ ونداء الاستغاثة')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addContact(context, false),
            label: const Text('إضافة مرافق'),
            icon: const Icon(Icons.person_add_alt_1),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: EmergencyContactsRecord.collection
                .where('userId', isEqualTo: currentUserUid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const _MessageState('تعذر تحميل جهات الاتصال.');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final contacts = snapshot.data!.docs
                  .map(EmergencyContactsRecord.fromSnapshot)
                  .toList();

              final primaryContact = contacts.firstWhere(
                (c) => c.isPrimary,
                orElse: () => contacts.isNotEmpty
                    ? contacts.first
                    : EmergencyContactsRecord.fromSnapshot(
                        snapshot.data!.docs.firstOrNull ??
                            snapshot.data!.docs.first),
              );

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Prominent SOS Alert Card
                  Card(
                    color: FlutterFlowTheme.of(context).errorContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side:
                          BorderSide(color: FlutterFlowTheme.of(context).error, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: FlutterFlowTheme.of(context).error, size: 28),
                              SizedBox(width: 8),
                              Text(
                                'نداء الاستغاثة السريع (SOS)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: FlutterFlowTheme.of(context).error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            contacts.isNotEmpty
                                ? 'سيتم إرسال إحداثيات موقعك الجغرافي الحي مباشرة عبر رسالة واتساب وSMS إلى مرافقك: ${primaryContact.name} (${primaryContact.phoneNumber}).'
                                : 'يرجى إضافة جهة اتصال واحدة على الأقل بالأسفل لتفعيل نداء الاستغاثة وإرسال موقعك عند الطوارئ.',
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: FlutterFlowTheme.of(context).error,
                              foregroundColor: FlutterFlowTheme.of(context).onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: contacts.isEmpty || _triggeringSOS
                                ? null
                                : _handleTriggerSOS,
                            icon: _triggeringSOS
                                ? SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: FlutterFlowTheme.of(context).onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.emergency_share, size: 24),
                            label: Text(
                              _triggeringSOS
                                  ? 'جارٍ تحديد الموقع وإرسال الاستغاثة...'
                                  : '🚨 إرسال نداء استغاثة فوري الآن',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'قائمة المرافقين المسجلين (${contacts.length})',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (contacts.isEmpty)
                        TextButton.icon(
                          onPressed: () => _addContact(context, true),
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة مرافق أول'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (contacts.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.people_outline,
                                size: 48, color: FlutterFlowTheme.of(context).secondaryText),
                            const SizedBox(height: 12),
                            const Text(
                              'لا توجد جهات اتصال مضافة حتى الآن.\nأضف مرافِقك أو أحد أفراد عائلتك ليكون جهة اتصالك المعتمدة عند الطوارئ.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => _addContact(context, true),
                              icon: const Icon(Icons.add),
                              label: const Text('إضافة جهة اتصال الآن'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...contacts.map((contact) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: IconButton(
                              tooltip: contact.isPrimary
                                  ? 'المرافق الرئيسي'
                                  : 'تعيين كمرافق رئيسي',
                              icon: Icon(
                                contact.isPrimary
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: contact.isPrimary
                                    ? FlutterFlowTheme.of(context).tertiary
                                    : FlutterFlowTheme.of(context).secondaryText,
                                size: 30,
                              ),
                              onPressed: contact.isPrimary
                                  ? null
                                  : () => _setAsPrimary(contact),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  contact.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                if (contact.isPrimary) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context).tertiaryLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'الأساسي',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: FlutterFlowTheme.of(context).secondaryDark),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                                '${contact.relationship.isNotEmpty ? contact.relationship + " • " : ""}${contact.phoneNumber}'),
                            trailing: IconButton(
                              tooltip: 'حذف',
                              onPressed: () => contact.reference.delete(),
                              icon: Icon(Icons.delete_outline,
                                  color: FlutterFlowTheme.of(context).error),
                            ),
                          ),
                        )),
                  const SizedBox(height: 80),
                ],
              );
            },
          ),
        ),
      );
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: currentUserDisplayName);
    _phone = TextEditingController(text: currentPhoneNumber);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await UsersRecord.collection.doc(currentUserUid).update({
        'display_name': _name.text.trim(),
        'phone_number': _phone.text.trim(),
        'updated_time': FieldValue.serverTimestamp(),
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم حفظ الملف الشخصي.')));
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message ?? 'تعذر حفظ التعديلات.')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('الملف الشخصي')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // User Role Card
              Card(
                color: currentUserIsAdmin
                    ? FlutterFlowTheme.of(context).primaryDark
                    : FlutterFlowTheme.of(context).surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: currentUserIsAdmin
                        ? FlutterFlowTheme.of(context).tertiary
                        : FlutterFlowTheme.of(context).outlineVariant,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            currentUserIsAdmin
                                ? Icons.admin_panel_settings
                                : Icons.person_pin,
                            color: currentUserIsAdmin
                                ? FlutterFlowTheme.of(context).tertiary
                                : FlutterFlowTheme.of(context).secondaryText,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentUserIsAdmin
                                    ? 'نوع الحساب: مدير النظام (Admin) 🛡️'
                                    : 'نوع الحساب: مستخدم عادي (User) 👤',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: currentUserIsAdmin
                                      ? FlutterFlowTheme.of(context).onPrimary
                                      : FlutterFlowTheme.of(context).primaryText,
                                ),
                              ),
                              Text(
                                currentUserEmail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: currentUserIsAdmin
                                      ? FlutterFlowTheme.of(context).onPrimary.withValues(alpha: 0.75)
                                      : FlutterFlowTheme.of(context).secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (currentUserIsAdmin) ...[
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: FlutterFlowTheme.of(context).tertiary,
                            foregroundColor: FlutterFlowTheme.of(context).primaryText,
                          ),
                          onPressed: () => context.pushNamed('AdminDashboard'),
                          icon: const Icon(Icons.dashboard_customize),
                          label: const Text(
                            'فتح لوحة تحكم الإدارة',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'يتم تعيين صلاحيات الإدارة من خلال لوحة تحكم Firebase Functions فقط.',
                          style: TextStyle(
                            fontSize: 12,
                            color: FlutterFlowTheme.of(context).onPrimary.withValues(alpha: 0.75),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        OutlinedButton.icon(
                          onPressed: null,
                          icon: Icon(Icons.shield_outlined, color: FlutterFlowTheme.of(context).secondaryText),
                          label: Text(
                            'صلاحيات الإدارة متاحة للحسابات المعتمدة فقط',
                            style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
          'للحصول على صلاحيات الإدارة، تواصل مع فريق ONEWAY عبر الإعدادات > الدعم.',
                          style: TextStyle(
                            fontSize: 12,
                            color: FlutterFlowTheme.of(context).secondaryText,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'تعديل البيانات الشخصية',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                    labelText: 'الاسم', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'رقم الهاتف', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'جارٍ الحفظ…' : 'حفظ التعديلات')),
            ],
          ),
        ),
      );
}

class ReportModerationPage extends StatelessWidget {
  const ReportModerationPage({super.key});

  static const _statuses = <String>[
    'new',
    'underReview',
    'needsMoreInformation',
    'verified',
    'resolved',
    'rejected',
  ];

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('مراجعة البلاغات')),
          body: StreamBuilder<QuerySnapshot>(
            stream: AccessibilityReportsRecord.collection
                .orderBy('created_at', descending: true)
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const _MessageState('تعذر تحميل قائمة المراجعة.');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final reports = snapshot.data!.docs
                  .map(AccessibilityReportsRecord.fromSnapshot)
                  .toList();
              if (reports.isEmpty) {
                return const _MessageState('لا توجد بلاغات للمراجعة.');
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (_, index) {
                  final report = reports[index];
                  final status =
                      _statuses.contains(report.status) ? report.status : 'new';
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(report.placeName,
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(report.problemCategory),
                          const SizedBox(height: 4),
                          Text(report.description),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: status,
                            decoration: const InputDecoration(
                                labelText: 'حالة المراجعة',
                                border: OutlineInputBorder()),
                            items: _statuses
                                .map((value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(_reportStatusLabel(value))))
                                .toList(),
                            onChanged: (value) {
                              if (value != null && value != report.status) {
                                report.reference.update({'status': value});
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
      );
}

class InitialAdminSetupPage extends StatefulWidget {
  const InitialAdminSetupPage({super.key});

  @override
  State<InitialAdminSetupPage> createState() => _InitialAdminSetupPageState();
}

class _InitialAdminSetupPageState extends State<InitialAdminSetupPage> {
  bool _running = false;
  bool _seeding = false;
  String? _message;
  String? _seedMessage;

  Future<void> _seedPlaces() async {
    setState(() {
      _seeding = true;
      _seedMessage = null;
    });
    try {
      final count = await OnewayDataSeeder.seedPlaces();
      if (mounted) {
        setState(() => _seedMessage =
            'تم بنجاح إضافة $count أماكن مصرية معتمدة إلى قاعدة البيانات!');
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() => _seedMessage =
            error.message ?? 'تعذر إضافة الأماكن. تأكد من الصلاحيات والاتصال.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _seedMessage = 'خطأ: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _seeding = false);
      }
    }
  }

  Future<void> _activate() async {
    setState(() {
      _running = true;
      _message = null;
    });
    try {
      await FirebaseFunctions.instance
          .httpsCallable('bootstrapInitialSuperAdmin')
          .call();
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      if (mounted) {
        setState(() => _message =
            'تمت الترقية بنجاح. أغلق التطبيق وافتحه أو سجّل الخروج ثم الدخول لتحديث الصلاحيات.');
      }
    } on FirebaseFunctionsException catch (error) {
      if (mounted) {
        setState(
            () => _message = error.message ?? 'تعذر تفعيل صلاحيات الإدارة.');
      }
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('تفعيل الإدارة')),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                      'هذه الخطوة تتحقق من البريد المهيأ في Firebase Functions. لا يمكنها ترقية أي بريد آخر أو تغيير دور مستخدم من الهاتف.'),
                  const SizedBox(height: 12),
                  Text(currentUserEmail,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _running ? null : _activate,
                    child:
                        Text(_running ? 'جارٍ التحقق…' : 'تفعيل حساب المدير'),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 20),
                    Text(_message!, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('تغذية البيانات الأولية (Seed Places)',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                      'استيراد 8 أماكن حقيقية معتمدة في القاهرة والجيزة (مستشفيات، مولات، جامعات، محطات) لاختبار وظائف البحث والفلاتر وتفاصيل الإتاحة.'),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _seeding ? null : _seedPlaces,
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: Text(_seeding
                        ? 'جارٍ الاستيراد…'
                        : 'استيراد الأماكن المعتمدة'),
                  ),
                  if (_seedMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_seedMessage!,
                        style: TextStyle(
                            color: _seedMessage!.contains('تم')
                                ? FlutterFlowTheme.of(context).success
                                : FlutterFlowTheme.of(context).error),
                        textAlign: TextAlign.center),
                  ],
                ]),
          ),
        ),
      );
}

class _ReportStatus extends StatelessWidget {
  const _ReportStatus({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) =>
      Chip(label: Text(_reportStatusLabel(status)));
}

String _reportStatusLabel(String status) => switch (status) {
      'new' => 'جديد',
      'underReview' => 'قيد المراجعة',
      'needsMoreInformation' => 'يحتاج معلومات إضافية',
      'verified' => 'تم التحقق',
      'resolved' => 'تم الحل',
      'rejected' => 'مرفوض',
      _ => 'قيد المراجعة',
    };

class _MessageState extends StatelessWidget {
  const _MessageState(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      );
}

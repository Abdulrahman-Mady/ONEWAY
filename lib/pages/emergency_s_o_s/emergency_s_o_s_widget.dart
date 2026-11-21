import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/emergency_contacts_record.dart';
import '/features/emergency/emergency_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'emergency_s_o_s_model.dart';
export 'emergency_s_o_s_model.dart';

/// Fully functional emergency page: SOS alert, official Egyptian emergency
/// numbers, the user's real emergency contacts (Firestore-backed CRUD),
/// nearby-hospitals search, first-aid tips and location sharing.
class EmergencySOSWidget extends StatefulWidget {
  const EmergencySOSWidget({super.key});

  static String routeName = 'EmergencySOS';
  static String routePath = '/emergency';

  @override
  State<EmergencySOSWidget> createState() => _EmergencySOSWidgetState();
}

class _EmergencySOSWidgetState extends State<EmergencySOSWidget> {
  late EmergencySOSModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _sosInFlight = false;

  static const _officialNumbers = [
    (name: 'الإسعاف', number: '123', icon: Icons.local_hospital_rounded),
    (name: 'شرطة النجدة', number: '122', icon: Icons.local_police_rounded),
    (name: 'المطافي', number: '180', icon: Icons.fire_truck_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EmergencySOSModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = FlutterFlowTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? theme.error : theme.success,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    try {
      if (!await launchUrl(uri)) {
        _showMessage('تعذر فتح الاتصال بالرقم $number', isError: true);
      }
    } catch (_) {
      _showMessage('تعذر فتح الاتصال بالرقم $number', isError: true);
    }
  }

  Future<void> _triggerSOS() async {
    if (_sosInFlight) return;
    setState(() => _sosInFlight = true);
    try {
      final result = await EmergencyService.triggerSOS();
      _showMessage(result.message, isError: !result.success);
    } finally {
      if (mounted) setState(() => _sosInFlight = false);
    }
  }

  Future<void> _shareLocation() async {
    final pos = await EmergencyService.determineCurrentPosition();
    final lat = pos?.latitude ?? EmergencyService.defaultLat;
    final lng = pos?.longitude ?? EmergencyService.defaultLng;
    final mapsUrl = 'https://maps.google.com/?q=$lat,$lng';
    final text = '📍 موقعي الحالي: $mapsUrl';
    final uri = Uri.parse(
        'whatsapp://send?text=${Uri.encodeComponent(text)}');
    final smsUri = Uri(
      scheme: 'sms',
      queryParameters: {'body': text},
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        _showMessage('رابط موقعك: $mapsUrl', isError: false);
      }
    } catch (_) {
      _showMessage('تعذر مشاركة الموقع حالياً.', isError: true);
    }
  }

  Future<void> _openNearbyHospitals() async {
    final pos = await EmergencyService.determineCurrentPosition();
    final Uri uri;
    if (pos != null) {
      uri = Uri.parse(
          'https://www.google.com/maps/search/%D9%85%D8%B3%D8%AA%D8%B4%D9%81%D9%89/@${pos.latitude},${pos.longitude},14z');
    } else {
      uri = Uri.parse(
          'https://www.google.com/maps/search/%D9%85%D8%B3%D8%AA%D8%B4%D9%81%D9%89');
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _showMessage('تعذر فتح خرائط جوجل.', isError: true);
    }
  }

  void _showFirstAid() {
    final theme = FlutterFlowTheme.of(context);
    const tips = [
      'حافظ على هدوءك وثبّت الكرسي المتحرك بفرامله قبل أي حركة.',
      'عند السقوط من الكرسي: لا تنهض بسرعة، افحص نفسك أولاً واطلب المساعدة.',
      'عند نزيف: اضغط مباشرة على الجرح بقماش نظيف وارفع العضو المصاب.',
      'عند الإغماء: استلقِ على سطح مستوٍ وارفع القدمين قليلاً.',
      'لقرح الفراش: غيّر وضعية الجلوس كل 15-30 دقيقة وافحص الجلد يومياً.',
      'في الحريق: ابتعد عن الدخان منخفضاً واطلب المطافي على 180 فوراً.',
      'احتفظ بأدويتك الأساسية وبطاقة بياناتك الطبية معك دائماً.',
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.medical_services_rounded,
                        color: theme.error, size: 26),
                    const SizedBox(width: 10),
                    Text(
                      'الإسعافات الأولية',
                      style: theme.titleLarge.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.primaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...tips.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: theme.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tip,
                            style: theme.bodyMedium.copyWith(
                              fontSize: 14,
                              color: theme.primaryText,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteContact(EmergencyContactsRecord contact) async {
    try {
      await contact.reference.delete();
      _showMessage('تم حذف جهة الاتصال.');
    } catch (_) {
      _showMessage('تعذر حذف جهة الاتصال.', isError: true);
    }
  }

  void _showAddContactSheet() {
    final theme = FlutterFlowTheme.of(context);
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();
    var isPrimary = true;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'إضافة جهة اتصال طوارئ',
                      style: theme.titleLarge.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم *',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'الاسم مطلوب'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: relationController,
                      decoration: const InputDecoration(
                        labelText: 'صلة القرابة (اختياري)',
                        hintText: 'أب، أخ، صديق...',
                        prefixIcon: Icon(Icons.family_restroom_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهاتف *',
                        hintText: '01xxxxxxxxx',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) {
                        final raw = (value ?? '')
                            .trim()
                            .replaceAll(RegExp(r'[\s-]'), '')
                            .replaceFirst(RegExp(r'^0020'), '0')
                            .replaceFirst(RegExp(r'^\+?20'), '0');
                        if (!RegExp(r'^(010|011|012|015)\d{8}$')
                            .hasMatch(raw)) {
                          return 'رقم غير صحيح - اكتب رقماً مصرياً مثل 010xxxxxxxx';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: isPrimary,
                      onChanged: (v) =>
                          setSheetState(() => isPrimary = v ?? false),
                      title: const Text('جهة الاتصال الأساسية للاستغاثة'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (!(formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        final uid = currentUserUid;
                        if (uid.isEmpty) return;
                        final phone = phoneController.text
                            .trim()
                            .replaceAll(RegExp(r'[\s-]'), '')
                            .replaceFirst(RegExp(r'^0020'), '0')
                            .replaceFirst(RegExp(r'^\+?20'), '0');
                        try {
                          await EmergencyContactsRecord.collection.add(
                            createEmergencyContactsRecordData(
                              userId: uid,
                              name: nameController.text.trim(),
                              relationship: relationController.text.trim(),
                              phoneNumber: phone,
                              isPrimary: isPrimary,
                              createdAt: DateTime.now(),
                            ),
                          );
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                          _showMessage('تمت إضافة جهة الاتصال.');
                        } catch (_) {
                          _showMessage('تعذر حفظ جهة الاتصال.',
                              isError: true);
                        }
                      },
                      child: const Text('حفظ جهة الاتصال'),
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

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.background,
        body: Column(
          children: [
            // Hero Header with SOS Button
            Container(
              decoration: BoxDecoration(
                color: theme.error,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    children: [
                      // Top row: Back + Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SOSActionButton(
                            icon: Icons.arrow_forward_rounded,
                            onPressed: () =>
                                context.goNamed(HomeDashboardWidget.routeName),
                          ),
                          Text(
                            'مساعدة الطوارئ',
                            style: theme.titleLarge.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: theme.onError,
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // SOS Button
                      InkWell(
                        onTap: _triggerSOS,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: theme.onError,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 32,
                                color: Colors.black.withValues(alpha: 0.25),
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _sosInFlight
                              ? CircularProgressIndicator(color: theme.error)
                              : Text(
                                  'SOS',
                                  style: theme.displayMedium.copyWith(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    color: theme.error,
                                    letterSpacing: 2,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'اضغط لإرسال استغاثة وموقعك لجهة اتصال الطوارئ',
                        textAlign: TextAlign.center,
                        style: theme.bodyMedium.copyWith(
                          fontSize: 14,
                          color: theme.onError.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Official emergency numbers
                    _SectionHeader(title: 'أرقام الطوارئ الرسمية', theme: theme),
                    const SizedBox(height: 12),
                    Row(
                      children: _officialNumbers
                          .map(
                            (n) => Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: _OfficialNumberCard(
                                  name: n.name,
                                  number: n.number,
                                  icon: n.icon,
                                  onTap: () => _callNumber(n.number),
                                  theme: theme,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 28),

                    // Emergency Contacts (real, Firestore-backed)
                    _SectionHeader(
                      title: 'جهات اتصال الطوارئ',
                      actionLabel: 'إضافة',
                      actionIcon: Icons.add_rounded,
                      onAction: _showAddContactSheet,
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: EmergencyContactsRecord.collection
                          .where('userId', isEqualTo: currentUserUid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _HintCard(
                            text:
                                'تعذر تحميل جهات الاتصال - تأكد من تحديث قواعد Firestore في لوحة التحكم.',
                            theme: theme,
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final contacts = snapshot.data!.docs
                            .map(EmergencyContactsRecord.fromSnapshot)
                            .toList();
                        if (contacts.isEmpty) {
                          return _HintCard(
                            text:
                                'لا توجد جهات اتصال بعد. أضف شخصاً موثوقاً ليصله موقعك عند الاستغاثة.',
                            theme: theme,
                          );
                        }
                        contacts.sort((a, b) => (b.isPrimary ? 1 : 0)
                            .compareTo(a.isPrimary ? 1 : 0));
                        return Column(
                          children: contacts
                              .map(
                                (c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ContactCard(
                                    contact: c,
                                    onCall: () => _callNumber(c.phoneNumber),
                                    onDelete: () => _deleteContact(c),
                                    theme: theme,
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nearby hospitals
                    _ActionTile(
                      icon: Icons.local_hospital_rounded,
                      color: theme.primary,
                      title: 'أقرب المستشفيات والمراكز الطبية',
                      subtitle:
                          'يفتح خرائط جوجل لعرض المستشفيات القريبة من موقعك.',
                      onTap: _openNearbyHospitals,
                      theme: theme,
                    ),
                    const SizedBox(height: 12),

                    // First Aid Info
                    _ActionTile(
                      icon: Icons.medical_services_rounded,
                      color: theme.error,
                      title: 'تعليمات الإسعافات الأولية',
                      subtitle:
                          'دليل سريع للتعامل مع حالات الطوارئ الشائعة لمستخدمي الكراسي المتحركة.',
                      onTap: _showFirstAid,
                      theme: theme,
                    ),
                    const SizedBox(height: 24),

                    // Share Location
                    OutlinedButton.icon(
                      onPressed: _shareLocation,
                      icon: const Icon(Icons.my_location_rounded),
                      label: const Text('مشاركة موقعي الحالي'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SOSActionButton extends StatelessWidget {
  const _SOSActionButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.onError.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: theme.onError, size: 22),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    required this.theme,
  });

  final String title;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.titleMedium.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: Icon(actionIcon, size: 18),
            label: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _OfficialNumberCard extends StatelessWidget {
  const _OfficialNumberCard({
    required this.name,
    required this.number,
    required this.icon,
    required this.onTap,
    required this.theme,
  });

  final String name;
  final String number;
  final IconData icon;
  final VoidCallback onTap;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.error.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.error.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: theme.error, size: 26),
              const SizedBox(height: 8),
              Text(
                number,
                style: theme.titleMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.error,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                textAlign: TextAlign.center,
                style: theme.bodySmall.copyWith(
                  fontSize: 12,
                  color: theme.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    required this.onCall,
    required this.onDelete,
    required this.theme,
  });

  final EmergencyContactsRecord contact;
  final VoidCallback onCall;
  final VoidCallback onDelete;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: contact.isPrimary
              ? theme.primary.withValues(alpha: 0.5)
              : theme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.primary.withValues(alpha: 0.1),
            child: Icon(Icons.person_rounded, color: theme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        contact.name,
                        style: theme.titleSmall.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.primaryText,
                        ),
                      ),
                    ),
                    if (contact.isPrimary) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.star_rounded, color: theme.tertiary, size: 18),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (contact.relationship.isNotEmpty) contact.relationship,
                    contact.phoneNumber,
                  ].join(' · '),
                  style: theme.bodySmall.copyWith(
                    fontSize: 13,
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCall,
            icon: Icon(Icons.call_rounded, color: theme.primary),
            tooltip: 'اتصال',
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline_rounded, color: theme.error),
            tooltip: 'حذف',
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.theme,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.titleMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.bodySmall.copyWith(
                        fontSize: 12,
                        color: theme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: color, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.text, required this.theme});

  final String text;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.bodyMedium.copyWith(
          fontSize: 14,
          color: theme.secondaryText,
          height: 1.6,
        ),
      ),
    );
  }
}

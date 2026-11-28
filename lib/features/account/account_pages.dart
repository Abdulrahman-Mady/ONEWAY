import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/utils/image_compression_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/backend/schema/accessibility_reports_record.dart';
import '/backend/schema/emergency_contacts_record.dart';
import '/backend/schema/notifications_record.dart';
import '/backend/schema/users_record.dart';
import '/features/emergency/emergency_service.dart';
import 'package:go_router/go_router.dart';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({
    super.key,
    this.initialReportId,
    this.autoOpenEdit = false,
  });

  final String? initialReportId;
  final bool autoOpenEdit;

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  bool _didAutoOpenSheet = false;

  static Color _statusColor(String status, FlutterFlowTheme theme) =>
      switch (status) {
        'new' => const Color(0xFFD97706),
        'underReview' => const Color(0xFF0284C7),
        'needsMoreInformation' => const Color(0xFF7C3AED),
        'verified' => const Color(0xFF16A34A),
        'resolved' => const Color(0xFF0D9488),
        'rejected' => theme.error,
        _ => theme.secondaryText,
      };

  static IconData _statusIcon(String status) => switch (status) {
        'new' => Icons.fiber_new_rounded,
        'underReview' => Icons.hourglass_top_rounded,
        'needsMoreInformation' => Icons.help_outline_rounded,
        'verified' => Icons.verified_rounded,
        'resolved' => Icons.task_alt_rounded,
        'rejected' => Icons.cancel_outlined,
        _ => Icons.info_outline_rounded,
      };

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final d = dt.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$day/$month/${d.year} • $hour:$min';
  }

  void _maybeAutoOpenClarification(List<AccessibilityReportsRecord> reports) {
    if (_didAutoOpenSheet || !widget.autoOpenEdit || reports.isEmpty) return;
    AccessibilityReportsRecord? target;
    final targetId = widget.initialReportId?.trim() ?? '';
    if (targetId.isNotEmpty) {
      for (final r in reports) {
        if (r.reference.id == targetId) {
          target = r;
          break;
        }
      }
    }
    target ??= reports
        .where((r) => r.status == 'needsMoreInformation')
        .firstOrNull;

    if (target != null &&
        (target.status == 'needsMoreInformation' || target.status == 'new')) {
      _didAutoOpenSheet = true;
      final reportToOpen = target;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ReportClarificationSheet.show(context, reportToOpen);
        }
      });
    } else {
      _didAutoOpenSheet = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          backgroundColor: theme.navy,
          foregroundColor: Colors.white,
          title: const Text(
            'بلاغاتي',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: currentUserUid.isEmpty
            ? const _MessageState('سجّل الدخول لعرض بلاغاتك ومتابعة حالتها.')
            : StreamBuilder<QuerySnapshot>(
                // Filter without server-side orderBy to avoid requiring a
                // composite Firestore index; sort newest-first in memory.
                stream: AccessibilityReportsRecord.collection
                    .where('createdBy', isEqualTo: currentUserUid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _MessageState(
                      'تعذر تحميل البلاغات حالياً (${snapshot.error}).',
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final targetId = widget.initialReportId?.trim() ?? '';
                  final reports = snapshot.data!.docs
                      .map(AccessibilityReportsRecord.fromSnapshot)
                      .toList()
                    ..sort((a, b) {
                      // Pin target report or needsMoreInformation reports at top
                      if (targetId.isNotEmpty) {
                        final aMatch = a.reference.id == targetId;
                        final bMatch = b.reference.id == targetId;
                        if (aMatch != bMatch) return aMatch ? -1 : 1;
                      }
                      final aNeeds = a.status == 'needsMoreInformation';
                      final bNeeds = b.status == 'needsMoreInformation';
                      if (aNeeds != bNeeds) return aNeeds ? -1 : 1;
                      final ta = a.updatedAt ??
                          a.createdAt ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      final tb = b.updatedAt ??
                          b.createdAt ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      return tb.compareTo(ta);
                    });

                  _maybeAutoOpenClarification(reports);

                  if (reports.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: theme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.assignment_outlined,
                                size: 42,
                                color: theme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لم ترسل أي بلاغات بعد',
                              style: theme.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.primaryText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'عند إرسال بلاغ عن أي عائق ستتمكن من متابعة حالته وقراءة رد فريق الإدارة هنا مباشرة.',
                              textAlign: TextAlign.center,
                              style: theme.bodySmall.copyWith(
                                color: theme.secondaryText,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final report = reports[index];
                      final color = _statusColor(report.status, theme);
                      final isRejected = report.status == 'rejected';
                      final needsClarification =
                          report.status == 'needsMoreInformation';
                      final canEdit =
                          needsClarification || report.status == 'new';
                      final isHighlighted = targetId.isNotEmpty &&
                          report.reference.id == targetId;
                      final dateLabel = _formatDate(report.createdAt);

                      return Container(
                        decoration: BoxDecoration(
                          color: needsClarification
                              ? const Color(0xFF7C3AED).withValues(alpha: 0.04)
                              : theme.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isHighlighted || needsClarification
                                ? color.withValues(alpha: 0.65)
                                : color.withValues(alpha: 0.28),
                            width:
                                isHighlighted || needsClarification ? 1.8 : 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadow.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (needsClarification) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.edit_notifications_rounded,
                                      size: 18,
                                      color: Color(0xFF7C3AED),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'الإدارة تطلب توضيحاً إضافياً — يمكنك تعديل البلاغ وإعادة إرساله الآن',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF6D28D9),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    report.placeName.isEmpty
                                        ? 'عائق في الطريق العام'
                                        : report.placeName,
                                    style: theme.titleSmall.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: theme.primaryText,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: color.withValues(alpha: 0.35)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_statusIcon(report.status),
                                          size: 14, color: color),
                                      const SizedBox(width: 4),
                                      Text(
                                        _reportStatusLabel(report.status),
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
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: theme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    report.problemCategory.isEmpty
                                        ? 'بلاغ إتاحة'
                                        : report.problemCategory,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.primary,
                                    ),
                                  ),
                                ),
                                if (dateLabel.isNotEmpty)
                                  Text(
                                    dateLabel,
                                    style: theme.bodySmall.copyWith(
                                      fontSize: 11.5,
                                      color: theme.secondaryText,
                                    ),
                                  ),
                                if (report.photoUrls.isNotEmpty)
                                  Text(
                                    '• ${report.photoUrls.length} صورة مرفقة',
                                    style: theme.bodySmall.copyWith(
                                      fontSize: 11.5,
                                      color: theme.secondaryText,
                                    ),
                                  ),
                              ],
                            ),
                            if (report.description.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                report.description,
                                style: theme.bodyMedium.copyWith(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: theme.primaryText,
                                ),
                              ),
                            ],
                            if (report.userNotes.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  color: theme.success.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.success.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person_pin_circle_rounded,
                                          size: 16,
                                          color: theme.success,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            report.status == 'new' &&
                                                    report.adminNotes
                                                        .trim()
                                                        .isEmpty
                                                ? 'ملاحظاتك المضافة (تمت إعادة الإرسال وبانتظار رد الإدارة)'
                                                : 'ملاحظاتك الإضافية المرفقة',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: theme.success,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      report.userNotes,
                                      style: theme.bodyMedium.copyWith(
                                        fontSize: 13.5,
                                        height: 1.45,
                                        color: theme.primaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (report.adminNotes.trim().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (isRejected
                                          ? theme.error
                                          : needsClarification
                                              ? const Color(0xFF7C3AED)
                                              : theme.primary)
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (isRejected
                                            ? theme.error
                                            : needsClarification
                                                ? const Color(0xFF7C3AED)
                                                : theme.primary)
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          needsClarification
                                              ? Icons.help_center_rounded
                                              : Icons
                                                  .admin_panel_settings_rounded,
                                          size: 16,
                                          color: isRejected
                                              ? theme.error
                                              : needsClarification
                                                  ? const Color(0xFF7C3AED)
                                                  : theme.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            needsClarification
                                                ? 'طلب توضيح من إدارة ONEWAY'
                                                : 'رد فريق إدارة ONEWAY',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: isRejected
                                                  ? theme.error
                                                  : needsClarification
                                                      ? const Color(0xFF7C3AED)
                                                      : theme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      report.adminNotes,
                                      style: theme.bodyMedium.copyWith(
                                        fontSize: 13.5,
                                        height: 1.5,
                                        color: theme.primaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (canEdit) ...[
                              const SizedBox(height: 14),
                              needsClarification
                                  ? FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF7C3AED),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () =>
                                          ReportClarificationSheet.show(
                                              context, report),
                                      icon: const Icon(Icons.edit_note_rounded,
                                          size: 20),
                                      label: const Text(
                                        'تعديل البلاغ وإضافة الملاحظات وإعادة الإرسال',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                    )
                                  : OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: theme.primary,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () =>
                                          ReportClarificationSheet.show(
                                              context, report),
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 18),
                                      label: const Text(
                                        'تعديل البلاغ أو إضافة ملاحظات',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

/// Interactive bottom sheet allowing the reporter to edit their report,
/// attach/remove photos, add clarification notes, and resubmit it to Admin
/// (transitioning status from 'needsMoreInformation' back to unreplied 'new').
class ReportClarificationSheet extends StatefulWidget {
  const ReportClarificationSheet({super.key, required this.report});

  final AccessibilityReportsRecord report;

  static Future<bool?> show(
    BuildContext context,
    AccessibilityReportsRecord report,
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ReportClarificationSheet(report: report),
    );
  }

  @override
  State<ReportClarificationSheet> createState() =>
      _ReportClarificationSheetState();
}

class _ReportClarificationSheetState extends State<ReportClarificationSheet> {
  static const List<String> _categories = [
    'عدم وجود منحدر',
    'منحدر مفقود',
    'مدخل غير مناسب',
    'مصعد غير مناسب',
    'حمام غير مجهز',
    'ممر ضيق',
    'رصيف مسدود',
    'موقف مخصص مفقود',
    'معلومة غير دقيقة',
    'أخرى',
  ];

  late final TextEditingController _placeNameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _notesCtrl;
  late String _selectedCategory;
  late List<String> _existingPhotoUrls;
  final List<XFile> _newPickedPhotos = [];
  final ImagePicker _picker = ImagePicker();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.report;
    _placeNameCtrl = TextEditingController(text: r.placeName);
    _descCtrl = TextEditingController(text: r.description);
    _notesCtrl = TextEditingController(text: r.userNotes);
    _selectedCategory = r.problemCategory.isNotEmpty
        ? r.problemCategory
        : _categories.first;
    _existingPhotoUrls = List<String>.from(r.photoUrls);
  }

  @override
  void dispose() {
    _placeNameCtrl.dispose();
    _descCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  int get _totalPhotosCount =>
      _existingPhotoUrls.length + _newPickedPhotos.length;

  Future<void> _pickNewPhoto(ImageSource source) async {
    if (_totalPhotosCount >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الحد الأقصى 3 صور لكل بلاغ.')),
      );
      return;
    }
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 82,
      );
      if (picked != null && mounted) {
        setState(() => _newPickedPhotos.add(picked));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر اختيار الصورة. تحقق من الأذونات.')),
        );
      }
    }
  }

  Future<void> _submitClarification() async {
    if (_saving) return;
    final desc = _descCtrl.text.trim();
    final notes = _notesCtrl.text.trim();
    final isClarification = widget.report.status == 'needsMoreInformation';

    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة وصف البلاغ قبل الإرسال.')),
      );
      return;
    }
    if (isClarification &&
        notes.isEmpty &&
        desc == widget.report.description.trim() &&
        _newPickedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى إضافة الملاحظات التوضيحية أو تعديل الوصف أو إرفاق صورة قبل إعادة الإرسال.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final finalUrls = List<String>.from(_existingPhotoUrls);
      if (_newPickedPhotos.isNotEmpty && currentUserUid.isNotEmpty) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        for (var i = 0; i < _newPickedPhotos.length; i++) {
          try {
            final Uint8List rawBytes = await _newPickedPhotos[i].readAsBytes();
            final compressed =
                await ImageCompressionService.compressForUpload(rawBytes);
            final ref = FirebaseStorage.instance.ref(
              'reports/$currentUserUid/${widget.report.reference.id}/clarify_${ts}_$i.jpg',
            );
            await ref.putData(
              compressed,
              SettableMetadata(contentType: 'image/jpeg'),
            );
            finalUrls.add(await ref.getDownloadURL());
          } catch (_) {
            // Keep submission resilient if Storage upload fails.
          }
        }
      }

      final payload = <String, dynamic>{
        'problemCategory': _selectedCategory,
        'place_name': _placeNameCtrl.text.trim().isEmpty
            ? widget.report.placeName
            : _placeNameCtrl.text.trim(),
        'description': desc,
        'user_notes': notes,
        'photo_urls': finalUrls,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (isClarification) {
        // Transition from 'needsMoreInformation' back to unreplied 'new' for Admin!
        payload['status'] = 'new';
        payload['previous_admin_notes'] = widget.report.adminNotes;
        payload['admin_notes'] = '';
      }

      await widget.report.reference.update(payload);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isClarification
                ? 'تم إرسال تعديلاتك وملاحظاتك بنجاح! عاد البلاغ لقائمة المراجعة لدى الإدارة ✓'
                : 'تم حفظ تعديلات البلاغ بنجاح ✓',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'تعذر تحديث البلاغ حالياً.'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الإرسال: $e'),
            backgroundColor: FlutterFlowTheme.of(context).error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isClarification = widget.report.status == 'needsMoreInformation';
    final categoryItems = <String>{
      ..._categories,
      _selectedCategory,
    }.toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
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
                    child: Text(
                      isClarification
                          ? 'تعديل البلاغ وإضافة التوضيح المطلوب'
                          : 'تعديل بيانات البلاغ',
                      style: theme.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.primaryText,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _saving ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              if (widget.report.adminNotes.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.help_outline_rounded,
                            size: 17,
                            color: Color(0xFF7C3AED),
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'المطلوب توضيحه من الإدارة:',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6D28D9),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.report.adminNotes,
                        style: theme.bodyMedium.copyWith(
                          fontSize: 13.5,
                          height: 1.5,
                          color: theme.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (widget.report.placeId.isEmpty) ...[
                TextField(
                  controller: _placeNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'اسم المكان / الشارع / المحطة',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'نوع المشكلة / العائق',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                items: categoryItems
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'وصف المشكلة (يمكنك التعديل عليه)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: isClarification
                      ? 'إضافة ملاحظات / توضيح للإدارة *'
                      : 'ملاحظات إضافية (اختياري)',
                  hintText:
                      'اكتب التوضيح المطلوب، مثل مكان العائق بالتحديد أو رقم البوابة أو أي تفاصيل إضافية...',
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 42),
                    child: Icon(Icons.rate_review_outlined),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Text(
                    'الصور المرفقة ($_totalPhotosCount/3)',
                    style: theme.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                  if (_totalPhotosCount < 3)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        TextButton.icon(
                          onPressed: _saving
                              ? null
                              : () => _pickNewPhoto(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined, size: 17),
                          label: const Text('كاميرا'),
                        ),
                        TextButton.icon(
                          onPressed: _saving
                              ? null
                              : () => _pickNewPhoto(ImageSource.gallery),
                          icon:
                              const Icon(Icons.photo_library_outlined, size: 17),
                          label: const Text('معرض الصور'),
                        ),
                      ],
                    ),
                ],
              ),
              if (_totalPhotosCount > 0) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < _existingPhotoUrls.length; i++)
                      _PhotoThumbTile(
                        child: Image.network(
                          _existingPhotoUrls[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image_outlined),
                        ),
                        onRemove: _saving
                            ? null
                            : () => setState(
                                () => _existingPhotoUrls.removeAt(i)),
                      ),
                    for (var i = 0; i < _newPickedPhotos.length; i++)
                      _PhotoThumbTile(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded,
                                color: theme.primary),
                            const SizedBox(height: 2),
                            Text(
                              'جديدة ${i + 1}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                        onRemove: _saving
                            ? null
                            : () =>
                                setState(() => _newPickedPhotos.removeAt(i)),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isClarification ? const Color(0xFF7C3AED) : theme.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _saving ? null : _submitClarification,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
                label: Text(
                  _saving
                      ? 'جارٍ الحفظ والإرسال...'
                      : isClarification
                          ? 'إعادة إرسال البلاغ للإدارة بعد التعديل'
                          : 'حفظ تعديلات البلاغ',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoThumbTile extends StatelessWidget {
  const _PhotoThumbTile({required this.child, required this.onRemove});

  final Widget child;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return SizedBox(
      width: 82,
      height: 82,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: theme.surfaceVariant,
                child: child,
              ),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 3,
              left: 3,
              child: InkWell(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: theme.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NotificationsCenterPage extends StatelessWidget {
  const NotificationsCenterPage({super.key});

  bool _isReportNotification(NotificationsRecord n) {
    return n.type == 'report_status' ||
        n.hasReportId() ||
        n.title.contains('بلاغك') ||
        n.body.contains('بلاغك');
  }

  bool _isClarificationNotification(NotificationsRecord n) {
    return n.title.contains('تفاصيل إضافية') ||
        n.body.contains('يحتاج توضيح') ||
        n.body.contains('تفاصيل إضافية');
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    NotificationsRecord notification,
  ) async {
    if (!notification.isRead) {
      try {
        await notification.reference.update({'is_read': true});
      } catch (_) {}
    }
    if (!context.mounted) return;

    if (_isReportNotification(notification)) {
      final isClarification = _isClarificationNotification(notification);
      final queryParams = <String, String>{
        if (notification.hasReportId()) 'reportId': notification.reportId,
        if (isClarification) 'edit': '1',
      };
      context.pushNamed('MyReports', queryParameters: queryParams);
      return;
    }

    if (notification.type.startsWith('business_')) {
      context.pushNamed('BusinessApplicationStatus');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          backgroundColor: theme.navy,
          foregroundColor: Colors.white,
          title: const Text(
            'الإشعارات',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: currentUserUid.isEmpty
            ? const _MessageState('سجّل الدخول لعرض إشعاراتك.')
            : StreamBuilder<QuerySnapshot>(
                // Filter without server-side orderBy to avoid composite-index
                // failures; sort newest-first in memory.
                stream: NotificationsRecord.collection
                    .where('userId', isEqualTo: currentUserUid)
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
                      .toList()
                    ..sort((a, b) {
                      final ta = a.createdAt ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      final tb = b.createdAt ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      return tb.compareTo(ta);
                    });
                  if (notifications.isEmpty) {
                    return const _MessageState('لا توجد إشعارات جديدة.');
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final notification = notifications[index];
                      final unread = !notification.isRead;
                      final isReport = _isReportNotification(notification);
                      final isClarification =
                          _isClarificationNotification(notification);
                      final accentColor = isClarification
                          ? const Color(0xFF7C3AED)
                          : theme.primary;

                      return Material(
                        color: unread
                            ? accentColor.withValues(alpha: 0.08)
                            : theme.surface,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () =>
                              _handleNotificationTap(context, notification),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: unread || isClarification
                                    ? accentColor.withValues(alpha: 0.4)
                                    : theme.outlineVariant,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: (unread || isClarification
                                            ? accentColor
                                            : theme.secondaryText)
                                        .withValues(alpha: 0.14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isClarification
                                        ? Icons.edit_notifications_rounded
                                        : (unread
                                            ? Icons.notifications_active_rounded
                                            : Icons.notifications_none_rounded),
                                    color: unread || isClarification
                                        ? accentColor
                                        : theme.secondaryText,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notification.title,
                                        style: theme.titleSmall.copyWith(
                                          fontWeight: unread
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: theme.primaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notification.body,
                                        style: theme.bodySmall.copyWith(
                                          color: theme.secondaryText,
                                          height: 1.5,
                                        ),
                                      ),
                                      if (isReport) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: accentColor
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isClarification
                                                    ? Icons.edit_note_rounded
                                                    : Icons
                                                        .open_in_new_rounded,
                                                size: 14,
                                                color: accentColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  isClarification
                                                      ? 'فتح البلاغ وتعديله وإضافة الملاحظات'
                                                      : 'فتح البلاغ ومتابعة حالته',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: accentColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (unread)
                                  Container(
                                    width: 9,
                                    height: 9,
                                    margin: const EdgeInsets.only(top: 6),
                                    decoration: BoxDecoration(
                                      color: accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
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

              final primaryContact = contacts.isEmpty
                  ? null
                  : contacts.firstWhere(
                      (c) => c.isPrimary,
                      orElse: () => contacts.first,
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
                                ? 'سيتم إرسال إحداثيات موقعك الجغرافي الحي مباشرة عبر رسالة واتساب وSMS إلى مرافقك: ${primaryContact!.name} (${primaryContact.phoneNumber}).'
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
                      Expanded(
                        child: Text(
                          'قائمة المرافقين المسجلين (${contacts.length})',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (contacts.isEmpty) ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _addContact(context, true),
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة مرافق أول'),
                        ),
                      ],
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
  String? _message;

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
                  Text('إدارة واستيراد الأماكن الحقيقية',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text(
                      'يمكنك استيراد الأماكن الحقيقية المجهزة مباشرة من OpenStreetMap (Overpass API) أو Google Places API من داخل لوحة تحكم الإدارة.'),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => context.pushNamed('AdminDashboard'),
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('فتح لوحة تحكم الإدارة'),
                  ),
                ]),
          ),
        ),
      );
}

String _reportStatusLabel(String status) => switch (status) {
      'new' => 'جديد',
      'underReview' => 'قيد المراجعة',
      'needsMoreInformation' => 'يحتاج توضيح',
      'verified' => 'تم الاعتماد ✓',
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

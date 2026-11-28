import '/auth/business_registration_service.dart';
import '/components/button/button_widget.dart';
import '/core/constants/app_constants.dart';
import '/flutter_flow/flutter_flow_theme.dart'
    show FlutterFlowTheme;
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BusinessApplicationStatusWidget extends StatefulWidget {
  const BusinessApplicationStatusWidget({super.key});

  static String routeName = 'BusinessApplicationStatus';
  static String routePath = '/business/application-status';

  @override
  State<BusinessApplicationStatusWidget> createState() => _BusinessApplicationStatusWidgetState();
}

class _BusinessApplicationStatusWidgetState extends State<BusinessApplicationStatusWidget> {
  BusinessApplicationStatus _status = BusinessApplicationStatus.none;
  String _businessName = '';
  String _businessId = '';
  String? _rejectionReason;
  String? _adminNotes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplicationStatus();
  }

  Future<void> _loadApplicationStatus() async {
    safeSetState(() => _isLoading = true);

    final business = await BusinessRegistrationService.instance.getCurrentUserBusiness();

    if (!mounted) return;

    if (business != null) {
      _businessName = business.businessName;
      _businessId = business.reference.id;

      switch (business.status) {
        case 'pending':
          _status = BusinessApplicationStatus.pending;
          break;
        case 'active':
          _status = BusinessApplicationStatus.approved;
          break;
        case 'rejected':
          _status = BusinessApplicationStatus.rejected;
          _rejectionReason = business.snapshotData['rejection_reason'];
          break;
        case 'suspended':
          _status = BusinessApplicationStatus.suspended;
          _rejectionReason = business.snapshotData['suspension_reason'];
          break;
        default:
          _status = BusinessApplicationStatus.none;
      }
    } else {
      _status = BusinessApplicationStatus.none;
    }

    safeSetState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.background,
        body: Center(
          child: CircularProgressIndicator(color: theme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('حالة طلب التسجيل'),
        backgroundColor: theme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward_rounded, color: theme.primaryText),
          onPressed: () => context.safePop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            _buildStatusCard(theme),
            const SizedBox(height: 24),
            // Business Info
            _buildBusinessInfoCard(theme),
            const SizedBox(height: 24),
            // Status Details
            _buildStatusDetailsCard(theme),
            const SizedBox(height: 24),
            // Actions
            _buildActions(theme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(FlutterFlowTheme theme) {
    final statusColor = _getStatusColor(theme);

    return Card(
      color: theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xxl),
        side: BorderSide(color: statusColor, width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(theme.designToken.radius.xxl),
          gradient: LinearGradient(
            colors: [
              statusColor.withValues(alpha: 0.1),
              statusColor.withValues(alpha: 0.02),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(),
                color: statusColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _status.label,
              style: theme.headlineSmall.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: statusColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _status.description,
              style: theme.bodyMedium.copyWith(
                fontSize: 14,
                color: theme.secondaryText,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoCard(FlutterFlowTheme theme) {
    return Card(
      color: theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        side: BorderSide(color: theme.outlineVariant, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business_rounded, color: theme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'معلومات المنشأة',
                  style: theme.titleMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(theme, 'اسم المنشأة', _businessName.isEmpty ? 'غير محدد' : _businessName),
            const SizedBox(height: 12),
            _buildInfoRow(
              theme,
              'رقم الطلب',
              _businessId.isEmpty
                  ? 'غير محدد'
                  : (_businessId.length > 8
                          ? _businessId.substring(0, 8)
                          : _businessId)
                      .toUpperCase(),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(theme, 'الحالة الحالية', _status.label),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(FlutterFlowTheme theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.bodySmall.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.tertiaryText,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.primaryText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDetailsCard(FlutterFlowTheme theme) {
    if (_status == BusinessApplicationStatus.pending) {
      return Card(
        color: theme.primary.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
          side: BorderSide(color: theme.primary.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule_rounded, color: theme.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'قيد المراجعة',
                    style: theme.titleMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'فريق OneWay يراجع طلبك حالياً. ستتلقى إشعاراً عند اتخاذ قرار.',
                style: theme.bodyMedium.copyWith(
                  fontSize: 14,
                  color: theme.secondaryText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 18, color: theme.tertiaryText),
                  const SizedBox(width: 8),
                  Text(
                    'المدة المتوقعة: 2-3 أيام عمل',
                    style: theme.bodySmall.copyWith(
                      fontSize: 13,
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else if (_status == BusinessApplicationStatus.rejected) {
      return Card(
        color: theme.error.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
          side: BorderSide(color: theme.error.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cancel_rounded, color: theme.error, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'تم رفض الطلب',
                    style: theme.titleMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'للأسف، تم رفض طلب تسجيل منشأتك.',
                style: theme.bodyMedium.copyWith(
                  fontSize: 14,
                  color: theme.secondaryText,
                  height: 1.5,
                ),
              ),
              if (_rejectionReason != null && _rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سبب الرفض:',
                        style: theme.labelMedium.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _rejectionReason!,
                        style: theme.bodyMedium.copyWith(
                          fontSize: 13,
                          color: theme.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    } else if (_status == BusinessApplicationStatus.approved) {
      return Card(
        color: theme.success.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
          side: BorderSide(color: theme.success.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_rounded, color: theme.success, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'تهانينا! طلبك مقبول',
                    style: theme.titleMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'منشأتك الآن موثقة وستظهر للعملاء على OneWay.',
                style: theme.bodyMedium.copyWith(
                  fontSize: 14,
                  color: theme.secondaryText,
                  height: 1.5,
                ),
              ),
              if (_adminNotes != null && _adminNotes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ملاحظات من فريق المراجعة:',
                        style: theme.labelMedium.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.success,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _adminNotes!,
                        style: theme.bodyMedium.copyWith(
                          fontSize: 13,
                          color: theme.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    } else if (_status == BusinessApplicationStatus.suspended) {
      return Card(
        color: theme.warning.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
          side: BorderSide(color: theme.warning.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.pause_circle_rounded, color: theme.warning, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'الحساب معلق',
                    style: theme.titleMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'تم تعليق حساب منشأتك مؤقتاً.',
                style: theme.bodyMedium.copyWith(
                  fontSize: 14,
                  color: theme.secondaryText,
                  height: 1.5,
                ),
              ),
              if (_rejectionReason != null && _rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'السبب:',
                        style: theme.labelMedium.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.warning,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _rejectionReason!,
                        style: theme.bodyMedium.copyWith(
                          fontSize: 13,
                          color: theme.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    } else {
      // No application
      return Card(
        color: theme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
          side: BorderSide(color: theme.outlineVariant, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 48,
                color: theme.tertiaryText,
              ),
              const SizedBox(height: 12),
              Text(
                'لا يوجد طلب تسجيل',
                style: theme.titleMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'لم تقم بتقديم طلب تسجيل منشأة بعد.',
                style: theme.bodyMedium.copyWith(
                  fontSize: 14,
                  color: theme.secondaryText,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ButtonWidget(
                content: 'سجّل منشأتك الآن',
                variant: 'primary',
                size: 'medium',
                fullWidth: true,
                icon: const Icon(Icons.add_business, color: Colors.white, size: 20),
                iconPresent: true,
                onPressed: () => context.pushNamed(BusinessRegistrationWidget.routeName),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildActions(FlutterFlowTheme theme) {
    if (_status == BusinessApplicationStatus.pending) {
      return Column(
        children: [
          ButtonWidget(
            content: 'طلب تقييم ميداني',
            variant: 'outline',
            size: 'medium',
            fullWidth: true,
            icon: const Icon(Icons.assignment_turned_in, size: 20),
            iconPresent: true,
            onPressed: _requestFieldAssessment,
          ),
          const SizedBox(height: 12),
          ButtonWidget(
            content: 'العودة للرئيسية',
            variant: 'ghost',
            size: 'medium',
            fullWidth: true,
            onPressed: () => context.goNamed(HomeDashboardWidget.routeName),
          ),
        ],
      );
    } else if (_status == BusinessApplicationStatus.approved) {
      return Column(
        children: [
          ButtonWidget(
            content: 'الذهاب للوحة تحكم المنشأة',
            variant: 'primary',
            size: 'large',
            fullWidth: true,
            iconEnd: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
            iconEndPresent: true,
            onPressed: () => context.pushNamed(BusinessAdminDashboardWidget.routeName),
          ),
          const SizedBox(height: 12),
          ButtonWidget(
            content: 'العودة للرئيسية',
            variant: 'ghost',
            size: 'medium',
            fullWidth: true,
            onPressed: () => context.goNamed(HomeDashboardWidget.routeName),
          ),
        ],
      );
    } else if (_status == BusinessApplicationStatus.rejected) {
      return Column(
        children: [
          ButtonWidget(
            content: 'تقديم طلب جديد',
            variant: 'primary',
            size: 'medium',
            fullWidth: true,
            onPressed: () => context.pushNamed(BusinessRegistrationWidget.routeName),
          ),
          const SizedBox(height: 12),
          ButtonWidget(
            content: 'التواصل مع الدعم',
            variant: 'outline',
            size: 'medium',
            fullWidth: true,
            onPressed: _contactSupport,
          ),
        ],
      );
    } else if (_status == BusinessApplicationStatus.suspended) {
      return Column(
        children: [
          ButtonWidget(
            content: 'التواصل مع الدعم لمراجعة التعليق',
            variant: 'primary',
            size: 'medium',
            fullWidth: true,
            onPressed: _contactSupport,
          ),
          const SizedBox(height: 12),
          ButtonWidget(
            content: 'العودة للرئيسية',
            variant: 'ghost',
            size: 'medium',
            fullWidth: true,
            onPressed: () => context.goNamed(HomeDashboardWidget.routeName),
          ),
        ],
      );
    } else {
      return ButtonWidget(
        content: 'سجّل منشأتك الآن',
        variant: 'primary',
        size: 'large',
        fullWidth: true,
        icon: const Icon(Icons.add_business, color: Colors.white, size: 24),
        iconPresent: true,
        onPressed: () => context.pushNamed(BusinessRegistrationWidget.routeName),
      );
    }
  }

  Color _getStatusColor(FlutterFlowTheme theme) {
    switch (_status) {
      case BusinessApplicationStatus.pending:
        return theme.primary;
      case BusinessApplicationStatus.approved:
        return theme.success;
      case BusinessApplicationStatus.rejected:
        return theme.error;
      case BusinessApplicationStatus.suspended:
        return theme.warning;
      case BusinessApplicationStatus.none:
        return theme.tertiaryText;
    }
  }

  IconData _getStatusIcon() {
    switch (_status) {
      case BusinessApplicationStatus.pending:
        return Icons.pending_actions_rounded;
      case BusinessApplicationStatus.approved:
        return Icons.verified_rounded;
      case BusinessApplicationStatus.rejected:
        return Icons.cancel_rounded;
      case BusinessApplicationStatus.suspended:
        return Icons.pause_circle_rounded;
      case BusinessApplicationStatus.none:
        return Icons.storefront_outlined;
    }
  }

  Future<void> _requestFieldAssessment() async {
    if (_businessId.isEmpty) return;

    final success = await BusinessRegistrationService.instance.requestFieldAssessment(
      businessId: _businessId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'تم إرسال طلب التقييم الميداني بنجاح'
                : 'فشل إرسال الطلب، يرجى المحاولة لاحقاً',
          ),
          backgroundColor: success ? FlutterFlowTheme.of(context).success : FlutterFlowTheme.of(context).error,
        ),
      );
    }
  }

  void _contactSupport() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final theme = FlutterFlowTheme.of(ctx);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'التواصل المباشر مع دعم ONEWAY',
                    style: theme.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      AppConstants.launchSupportWhatsApp(
                        message:
                            'مرحباً دعم ONEWAY، أستفسر بخصوص طلب تسجيل منشأة: $_businessName',
                      );
                    },
                    icon: const Icon(Icons.chat_rounded),
                    label: const Text(
                      'تواصل عبر واتساب (${AppConstants.supportWhatsAppNumber})',
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      AppConstants.launchSupportEmail(
                        subject: 'استفسار بخصوص طلب منشأة: $_businessName',
                      );
                    },
                    icon: const Icon(Icons.email_outlined),
                    label: const Text(
                      'إرسال بريد إلكتروني (${AppConstants.supportEmail})',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.pushNamed(HelpSupportPageWidget.routeName);
                    },
                    child: const Text('فتح صفحة المساعدة والدعم'),
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
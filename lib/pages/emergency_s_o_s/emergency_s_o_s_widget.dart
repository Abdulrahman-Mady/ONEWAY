import '/components/button/button_widget.dart';
import '/components/contact_card/contact_card_widget.dart';
import '/components/facility_item/facility_item_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/features/emergency/emergency_service.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'emergency_s_o_s_model.dart';
export 'emergency_s_o_s_model.dart';

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
                gradient: LinearGradient(
                  colors: [theme.error, theme.error],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                      // Top row: Help + Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SOSActionButton(
                            icon: Icons.help_outline_rounded,
                            onPressed: () => context.goNamed(HomeDashboardWidget.routeName),
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
                        onTap: () async {
                          final result = await EmergencyService.triggerSOS();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result.message,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: result.success
                                    ? theme.success
                                    : theme.error,
                                duration: const Duration(milliseconds: 5000),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(theme.designToken.radius.full),
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: theme.error,
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 32,
                                color: theme.error.withValues(alpha: 0.5),
                                offset: const Offset(0, 12),
                                spreadRadius: 0,
                              ),
                            ],
                            borderRadius: BorderRadius.circular(theme.designToken.radius.full),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.gpp_maybe_rounded,
                                size: 44,
                                color: Colors.white,
                              ),
                              Text(
                                'SOS',
                                style: theme.headlineMedium.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'اضغط لإرسال استغاثة وتحديد موقعك',
                        textAlign: TextAlign.center,
                        style: theme.bodyMedium.copyWith(
                          fontSize: 14,
                          color: theme.onError.withValues(alpha: 0.8),
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
                    // Emergency Contacts
                    _SectionHeader(
                      title: 'جهات اتصال الطوارئ',
                      actionLabel: 'إضافة',
                      actionIcon: Icons.add_rounded,
                      onAction: () {
                        // TODO: Add contact
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _ContactCard(
                      name: 'أحمد محمد',
                      phone: '01012345678',
                      relation: 'الأب',
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    _ContactCard(
                      name: 'سارة محمود',
                      phone: '01198765432',
                      relation: 'الزوجة',
                      theme: theme,
                    ),
                    const SizedBox(height: 24),

                    // Nearby Hospitals
                    _SectionHeader(
                      title: 'أقرب مستشفيات مجهزة',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _FacilityCard(
                      title: 'مستشفى السلام الدولي',
                      distance: '1.2 كم',
                      status: 'متاح',
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    _FacilityCard(
                      title: 'مركز النيل الطبي',
                      distance: '2.5 كم',
                      status: 'متاح',
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    _FacilityCard(
                      title: 'مستشفى كليوباترا',
                      distance: '3.8 كم',
                      status: 'متاح',
                      theme: theme,
                    ),
                    const SizedBox(height: 24),

                    // First Aid Info
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
                        border: Border.all(color: theme.error.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: theme.error,
                              borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.medical_services_rounded,
                              color: theme.onError,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تعليمات الإسعافات الأولية',
                                  style: theme.titleMedium.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: theme.error,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'دليل سريع للتعامل مع حالات الطوارئ الشائعة لمستخدمي الكراسي المتحركة.',
                                  style: theme.bodySmall.copyWith(
                                    fontSize: 12,
                                    color: theme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_left_rounded,
                            color: theme.error,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Share Location
                    ButtonWidget(
                      content: 'مشاركة الموقع الحالي مع الطوارئ',
                      variant: 'outline',
                      size: 'medium',
                      fullWidth: true,
                      icon: Icon(
                        Icons.my_location_rounded,
                        color: theme.primaryText,
                        size: 24,
                      ),
                      iconPresent: true,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'لم تتم مشاركة الموقع. يتطلب ذلك إذن الموقع وخدمة خلفية مهيأة.',
                            ),
                            duration: Duration(milliseconds: 4000),
                          ),
                        );
                      },
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
        borderRadius: BorderRadius.circular(theme.designToken.radius.full),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.onError.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(theme.designToken.radius.full),
          ),
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
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: Icon(actionIcon, size: 20, color: theme.primary),
            label: Text(
              actionLabel!,
              style: theme.labelLarge.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.name,
    required this.phone,
    required this.relation,
    required this.theme,
  });

  final String name;
  final String phone;
  final String relation;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return ContactCardWidget(
      name: name,
      phone: phone,
      relation: relation,
      icon: Icon(
        Icons.star,
        color: theme.secondary,
        size: 24,
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  const _FacilityCard({
    required this.title,
    required this.distance,
    required this.status,
    required this.theme,
  });

  final String title;
  final String distance;
  final String status;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return FacilityItemWidget(
      title: title,
      distance: distance,
      status: status,
    );
  }
}
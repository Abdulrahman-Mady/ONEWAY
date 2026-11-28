import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '/core/analytics/analytics_service.dart';
import '/core/constants/app_constants.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/nav/nav.dart';
import '/l10n/app_strings.dart';
import '/widgets/responsive_layout.dart';

/// Practical Egypt Accessibility & Rights Guide (offline-ready, AR/EN):
/// Integrated Services Card, specialized vehicles, transit discounts,
/// Law No. 10 of 2018 rights, and one-tap Egyptian official hotlines.
class EgyptGuidePage extends StatelessWidget {
  const EgyptGuidePage({super.key});

  static const String routeName = 'EgyptGuide';
  static const String routePath = '/egypt-guide';

  Future<void> _callHotline(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    try {
      await launchUrl(uri);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.t(context, 'تعذر فتح الاتصال بالرقم $number',
                  'Could not dial $number'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S.t(context, 'تعذر فتح الرابط حالياً.', 'Could not open link.'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final hPad = OnewayResponsive.horizontalPadding(context);

    final hotlines = <({String nameAr, String nameEn, String number, IconData icon})>[
      (
        nameAr: 'المجلس القومي لذوي الإعاقة',
        nameEn: 'National Council for Disabilities',
        number: '16736',
        icon: Icons.accessible_forward_rounded,
      ),
      (
        nameAr: 'وزارة التضامن الاجتماعي',
        nameEn: 'Ministry of Social Solidarity',
        number: '16439',
        icon: Icons.badge_outlined,
      ),
      (
        nameAr: 'شكاوى مجلس الوزراء',
        nameEn: 'Cabinet Complaints Hotline',
        number: '16528',
        icon: Icons.support_agent_rounded,
      ),
      (
        nameAr: 'الإسعاف',
        nameEn: 'Ambulance',
        number: '123',
        icon: Icons.local_hospital_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.navy,
        foregroundColor: Colors.white,
        leading: GoRouter.maybeOf(context) != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: S.t(context, 'رجوع', 'Back'),
                onPressed: () => context.safePop(),
              )
            : null,
        title: Text(S.t(context, 'دليلك في مصر', 'Egypt Access Guide')),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(hPad),
          child: ResponsiveContainer(
            maxWidth: 640,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Intro Hero Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.navy, theme.primary],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              S.t(
                                context,
                                'دليل الحقوق والخدمات في مصر',
                                'Disability Rights & Services in Egypt',
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        S.t(
                          context,
                          'معلومات عملية محدثة لمساعدتك في استخراج بطاقة الخدمات المتكاملة، التسهيلات القانونية، المواصلات، وأرقام الجهات الرسمية — تعمل حتى بدون إنترنت.',
                          'Practical offline-ready guide covering the Integrated Services Card, legal rights, transit discounts, and official Egyptian hotlines.',
                        ),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13.5,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Guide Sections
                _GuideExpansionCard(
                  theme: theme,
                  sectionId: 'integrated_services_card',
                  icon: Icons.credit_card_rounded,
                  iconColor: theme.primary,
                  title: S.t(context, 'بطاقة الخدمات المتكاملة (خطوات الاستخراج)',
                      'Integrated Services Card (How to Apply)'),
                  subtitle: S.t(context, 'التقديم، الأوراق المطلوبة، والمزايا',
                      'Application steps, documents & benefits'),
                  initiallyExpanded: true,
                  body: S.t(
                    context,
                    '1. حجز موعد الكشف الطبي المميكن عبر موقع المجالس الطبية المتخصصة.\n'
                    '2. التوجه بالبطاقة الشخصية والتقارير الطبية الحديثة لإجراء الكشف.\n'
                    '3. بعد القبول الطبي، احجز موعد التقييم الوظيفي في مكتب التأهيل الاجتماعي التابع لوزارة التضامن.\n\n'
                    'أهم المزايا:\n'
                    '• الجمع بين معاشين والتأمين الصحي الشامل.\n'
                    '• خصومات على مترو الأنفاق والسكك الحديدية والمواصلات العامة.\n'
                    '• التعيين ضمن نسبة الـ 5% وتسهيلات الإسكان والجامعات.\n'
                    '• الدخول المجاني أو المخفض للمتاحف والمناطق الأثرية الحكومية.',
                    '1. Book a medical committee appointment via the Specialized Medical Councils portal.\n'
                    '2. Bring your National ID and recent medical reports for assessment.\n'
                    '3. Once approved, complete the functional assessment at your local Ministry of Social Solidarity office.\n\n'
                    'Key Benefits:\n'
                    '• Discounted Cairo Metro, railway, and public transit fares.\n'
                    '• Health insurance & pension benefits.\n'
                    '• 5% employment quota, university & housing facilitation.\n'
                    '• Free or discounted access to public museums & heritage sites.',
                  ),
                  actionLabel: S.t(context, 'فتح بوابة وزارة التضامن',
                      'Open Ministry Portal'),
                  onAction: () =>
                      _openUrl(context, 'https://rdis.moss.gov.eg/'),
                ),
                const SizedBox(height: 12),

                _GuideExpansionCard(
                  theme: theme,
                  sectionId: 'adapted_vehicles',
                  icon: Icons.directions_car_filled_rounded,
                  iconColor: theme.navy,
                  title: S.t(context, 'السيارات المجهزة ورخصة القيادة',
                      'Adapted Vehicles & Special License'),
                  subtitle: S.t(context, 'الإعفاء الجمركي والكشف الطبي للقيادة',
                      'Customs facilitation & medical clearance'),
                  body: S.t(
                    context,
                    '• يشترط وجود بطاقة الخدمات المتكاملة سارية.\n'
                    '• حجز كشف طبي خاص بالسيارات المجهزة لدى المجالس الطبية المتخصصة لتحديد نوع التجهيز المطلوب (يدوي/أوتوماتيك/مرافق).\n'
                    '• التقديم بالقرار الطبي والبطاقة في المرور والجمارك وفق الضوابط السارية.',
                    '• Requires a valid Integrated Services Card.\n'
                    '• Book a dedicated adapted-vehicle medical exam via the Specialized Medical Councils to determine required modifications.\n'
                    '• Submit the approved medical decision to Traffic & Customs authorities per current regulations.',
                  ),
                ),
                const SizedBox(height: 12),

                _GuideExpansionCard(
                  theme: theme,
                  sectionId: 'public_transit',
                  icon: Icons.directions_subway_rounded,
                  iconColor: theme.secondary,
                  title: S.t(context, 'المواصلات العامة والمترو في مصر',
                      'Cairo Metro & Public Transit Tips'),
                  subtitle: S.t(context, 'الخطوط الجديدة، المصاعد، وتذاكر التخفيض',
                      'Accessible lines, elevators & reduced fares'),
                  body: S.t(
                    context,
                    '• الخط الثالث لمترو الأنفاق (الخط الأخضر) ومحطات القطار الكهربائي الخفيف (LRT) ومحطة قطارات بشتيل مجهزة بمصاعد ومنحدرات ومسارات مخصصة.\n'
                    '• يُتاح لحاملي بطاقة الخدمات المتكاملة تذاكر واشتراكات مخفضة في المترو والقطارات.\n'
                    '• قبل النزول لأي محطة قديمة (الخط الأول/الثاني)، راجع حالتها على خريطة ONEWAY للتأكد من عمل المصعد.',
                    '• Cairo Metro Line 3 (Green Line), LRT stations, and Bashtil Station feature elevators, ramps, and accessible paths.\n'
                    '• Integrated Services Card holders receive reduced-fare tickets and passes on Metro and Railways.\n'
                    '• Always check recent community reports on ONEWAY before using older Line 1/2 stations.',
                  ),
                ),
                const SizedBox(height: 12),

                _GuideExpansionCard(
                  theme: theme,
                  sectionId: 'law_10_2018',
                  icon: Icons.gavel_rounded,
                  iconColor: theme.gold,
                  title: S.t(context, 'حقوقك في قانون رقم 10 لسنة 2018',
                      'Your Rights Under Law No. 10 of 2018'),
                  subtitle: S.t(context, 'التوظيف، الإتاحة المكانية، والدمج',
                      'Employment, spatial accessibility & inclusion'),
                  body: S.t(
                    context,
                    'يكفل قانون حقوق الأشخاص ذوي الإعاقة رقم 10 لسنة 2018:\n'
                    '• التزام الجهات الحكومية والمنشآت العامة بتوفير الكود الهندسي للإتاحة (منحدرات، مصاعد، دورات مياه مهيأة).\n'
                    '• الحق في التعليم الدامج وتوفير التيسيرات في الامتحانات.\n'
                    '• تخصيص نسبة 5% من الوظائف في الجهات التي يعمل بها 20 عاملاً فأكثر، وتخفيض ساعات العمل ساعة يومياً مدفوعة الأجر.\n'
                    '• يمكنك الإبلاغ عن أي مخالفة عبر الخط الساخن للمجلس القومي للأشخاص ذوي الإعاقة (16736).',
                    'Egypt Law No. 10 of 2018 guarantees:\n'
                    '• Mandatory architectural accessibility standards in public and government buildings.\n'
                    '• Inclusive education and exam accommodations.\n'
                    '• 5% employment quota in workplaces with 20+ employees, plus one paid reduced working hour daily.\n'
                    '• Report violations via the National Council hotline (16736).',
                  ),
                ),

                const SizedBox(height: 22),
                Text(
                  S.t(context, 'أرقام رسمية وخطوط ساخنة (اتصال مباشر)',
                      'Official Hotlines (One-Tap Call)'),
                  style: theme.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 10),
                for (final h in hotlines) ...[
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.primary.withValues(alpha: 0.12),
                        child: Icon(h.icon, color: theme.primary, size: 22),
                      ),
                      title: Text(
                        S.t(context, h.nameAr, h.nameEn),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      subtitle: Text(
                        h.number,
                        style: TextStyle(
                          color: theme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      trailing: IconButton.filledTonal(
                        tooltip: S.t(context, 'اتصال', 'Call'),
                        onPressed: () => _callHotline(context, h.number),
                        icon: const Icon(Icons.phone_rounded),
                      ),
                      onTap: () => _callHotline(context, h.number),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          S.t(context, 'التواصل المباشر مع دعم ONEWAY',
                              'Direct ONEWAY Support'),
                          style: theme.titleSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () =>
                                  AppConstants.launchSupportWhatsApp(),
                              icon: const Icon(Icons.chat_rounded, size: 18),
                              label: Text(
                                S.t(
                                  context,
                                  'واتساب (${AppConstants.supportWhatsAppNumber})',
                                  'WhatsApp (${AppConstants.supportWhatsAppNumber})',
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  AppConstants.launchSupportEmail(),
                              icon: const Icon(Icons.email_outlined, size: 18),
                              label: const Text(AppConstants.supportEmail),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideExpansionCard extends StatelessWidget {
  const _GuideExpansionCard({
    required this.theme,
    required this.sectionId,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.body,
    this.initiallyExpanded = false,
    this.actionLabel,
    this.onAction,
  });

  final FlutterFlowTheme theme;
  final String sectionId;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String body;
  final bool initiallyExpanded;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          onExpansionChanged: (expanded) {
            if (expanded) {
              AnalyticsService.instance.logGuideViewed(section: sectionId);
            }
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
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
              fontSize: 12,
              color: theme.secondaryText,
            ),
          ),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                body,
                style: theme.bodyMedium.copyWith(
                  color: theme.primaryText,
                  height: 1.7,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

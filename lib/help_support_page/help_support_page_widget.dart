import '/components/button/button_widget.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'help_support_page_model.dart';
export 'help_support_page_model.dart';

/// DSL page HelpSupportPage
class HelpSupportPageWidget extends StatefulWidget {
  const HelpSupportPageWidget({super.key});

  static String routeName = 'HelpSupportPage';
  static String routePath = '/help';

  @override
  State<HelpSupportPageWidget> createState() => _HelpSupportPageWidgetState();
}

class _HelpSupportPageWidgetState extends State<HelpSupportPageWidget> {
  late HelpSupportPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HelpSupportPageModel());
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
        appBar: AppBar(
          backgroundColor: theme.background,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: true,
          title: Text(
            'المساعدة والدعم',
            style: theme.titleLarge.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          actions: const [],
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'كيف نساعدك؟',
                    style: theme.titleLarge.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _HelpCard(
                    title: 'استخدام ONEWAY',
                    content:
                        'ابحث عن مكان، وافتح تفاصيله لمراجعة المعلومات المتاحة. بيانات الأماكن الحالية تجريبية وغير مؤكدة.',
                    icon: Icons.info_outline_rounded,
                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  _HelpCard(
                    title: 'الإبلاغ عن عائق',
                    content:
                        'يمكنك حفظ بلاغ تجريبي على الجهاز من صفحة البلاغ. لا يصل البلاغ إلى فريق مراجعة قبل ربط قاعدة البيانات.',
                    icon: Icons.report_problem_outlined,
                    theme: theme,
                  ),
                  const SizedBox(height: 24),
                  ButtonWidget(
                    content: 'إرسال بلاغ تجريبي',
                    variant: 'primary',
                    size: 'large',
                    fullWidth: true,
                    onPressed: () =>
                        context.pushNamed(SubmitAccessibilityReportWidget.routeName),
                  ),
                  const SizedBox(height: 12),
                  ButtonWidget(
                    content: 'العودة للرئيسية',
                    variant: 'outline',
                    size: 'large',
                    fullWidth: true,
                    onPressed: () => context.goNamed(HomeDashboardWidget.routeName),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.theme,
  });

  final String title;
  final String content;
  final IconData icon;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        border: Border.all(color: theme.outlineVariant, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: theme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
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
            content,
            style: theme.bodyMedium.copyWith(
              fontSize: 14,
              color: theme.secondaryText,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
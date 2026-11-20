import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notifications_page_model.dart';
export 'notifications_page_model.dart';

/// DSL page NotificationsPage
class NotificationsPageWidget extends StatefulWidget {
  const NotificationsPageWidget({super.key});

  static String routeName = 'NotificationsPage';
  static String routePath = '/notifications';

  @override
  State<NotificationsPageWidget> createState() => _NotificationsPageWidgetState();
}

class _NotificationsPageWidgetState extends State<NotificationsPageWidget> {
  late NotificationsPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NotificationsPageModel());
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
            'الإشعارات',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoBanner(
                  icon: Icons.info_outline_rounded,
                  message:
                      'الإشعارات الفعلية تحتاج إلى ربط Firebase وإعداد خدمة الإشعارات.',
                  theme: theme,
                ),
                const SizedBox(height: 24),
                Text(
                  'لا توجد إشعارات حالياً.',
                  style: theme.bodyMedium.copyWith(
                    fontSize: 14,
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.message,
    required this.theme,
  });

  final IconData icon;
  final String message;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        border: Border.all(color: theme.outlineVariant, width: 1.5),
      ),
      child: Row(
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
          Expanded(
            child: Text(
              message,
              style: theme.bodyMedium.copyWith(
                fontSize: 14,
                color: theme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
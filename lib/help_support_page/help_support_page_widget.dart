import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/core/constants/app_constants.dart';
import '/features/legal/legal_pages.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'help_support_page_model.dart';
export 'help_support_page_model.dart';

/// Production Help & Support page with direct 1-tap Email, WhatsApp & Phone
/// support plus legal links.
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
          backgroundColor: theme.navy,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'رجوع',
            onPressed: () => context.safePop(),
          ),
          title: const Text('المساعدة والدعم المباشر'),
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Direct Contact Hero Card (Email + WhatsApp + Call)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.navy, theme.primary],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: theme.navy.withValues(alpha: 0.16),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.support_agent_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تواصل معنا مباشرة في أي وقت',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'اضغط لإرسال رسالة واتساب أو بريد إلكتروني مباشرة لفريق الدعم',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => AppConstants.launchSupportWhatsApp(
                          message:
                              'مرحباً دعم ONEWAY، أحتاج المساعدة بخصوص حسابي (${currentUserEmail.isNotEmpty ? currentUserEmail : "مستخدم ONEWAY"}):',
                        ),
                        icon: const Icon(Icons.chat_rounded, size: 20),
                        label: const Text(
                          'تواصل عبر واتساب: ${AppConstants.supportWhatsAppNumber}',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: theme.navy,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => AppConstants.launchSupportEmail(),
                        icon: const Icon(Icons.email_rounded, size: 20),
                        label: const Text(
                          'إرسال بريد: ${AppConstants.supportEmail}',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => AppConstants.launchSupportPhoneCall(),
                        icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                        label: const Text(
                          'اتصال هاتفي مباشر (${AppConstants.supportWhatsAppNumber})',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    TextButton(
                      onPressed: () =>
                          context.pushNamed(PrivacyPolicyPage.routeName),
                      child: const Text('سياسة الخصوصية'),
                    ),
                    const Text('•'),
                    TextButton(
                      onPressed: () =>
                          context.pushNamed(TermsOfUsePage.routeName),
                      child: const Text('شروط الاستخدام'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

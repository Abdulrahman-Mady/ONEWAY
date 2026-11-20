import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '/components/assistant_suggestion/assistant_suggestion_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/features/ai/oneway_ai_engine.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import 'voice_assistant_interface_model.dart';
export 'voice_assistant_interface_model.dart';

class VoiceAssistantInterfaceWidget extends StatefulWidget {
  const VoiceAssistantInterfaceWidget({super.key});

  static String routeName = 'VoiceAssistantInterface';
  static String routePath = '/assistant';

  @override
  State<VoiceAssistantInterfaceWidget> createState() =>
      _VoiceAssistantInterfaceWidgetState();
}

class _VoiceAssistantInterfaceWidgetState
    extends State<VoiceAssistantInterfaceWidget> {
  late VoiceAssistantInterfaceModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _textController = TextEditingController();
  bool _isProcessing = false;
  bool _isListening = false;
  String _currentQuery = '';
  AIResponse? _lastResponse;
  bool _showTextInput = false;

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _speechAvailable = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VoiceAssistantInterfaceModel());
    _initSpeech();
    _initTts();

    // Check for initial query from navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = GoRouter.of(context);
      final currentRoute = router.routerDelegate.currentConfiguration;
      // Get extra from the current route's path parameters
      final extra = currentRoute.uri.queryParameters['initialQuery'];
      if (extra != null && extra.isNotEmpty) {
        _handleQuery(extra);
      }
    });
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (val) {
          debugPrint('Speech error: $val');
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted && _isListening) {
              setState(() => _isListening = false);
              if (_currentQuery.trim().isNotEmpty &&
                  _currentQuery != 'أنا أستمع إليك الآن...') {
                _handleQuery(_currentQuery.trim());
              }
            }
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Speech init exception: $e');
    }
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('ar');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _flutterTts.setErrorHandler((msg) {
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (e) {
      debugPrint('TTS init exception: $e');
    }
  }

  Future<void> _speak(String text) async {
    final clean = text
        .replaceAll('*', '')
        .replaceAll('#', '')
        .replaceAll('🚨', 'تنبيه: ')
        .replaceAll('📍', 'المكان: ')
        .replaceAll('•', '،');
    try {
      setState(() => _isSpeaking = true);
      await _flutterTts.stop();
      await _flutterTts.speak(clean);
    } catch (e) {
      debugPrint('TTS speak exception: $e');
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  Future<void> _stopSpeaking() async {
    try {
      await _flutterTts.stop();
      if (mounted) setState(() => _isSpeaking = false);
    } catch (_) {}
  }

  @override
  void dispose() {
    _model.dispose();
    _textController.dispose();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _handleQuery(String query) async {
    if (query.trim().isEmpty) return;

    if (_isSpeaking) {
      await _stopSpeaking();
    }

    setState(() {
      _currentQuery = query;
      _isProcessing = true;
      _isListening = false;
      _lastResponse = null;
    });

    try {
      final response = await OnewayAIEngine.processQuery(context, query);
      if (!mounted) return;

      setState(() {
        _lastResponse = response;
        _isProcessing = false;
      });

      // Speak response automatically
      _speak(response.replyText);

      // If navigation requested, execute after brief feedback
      if (response.intent == AIIntentType.navigation &&
          response.navigationRoute != null) {
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) {
            context.pushNamed(response.navigationRoute!);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _lastResponse = AIResponse(
          intent: AIIntentType.generalInfo,
          replyText: 'حدث خطأ أثناء معالجة الطلب: $e',
        );
      });
    }
  }

  Future<void> _toggleMic() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      if (_currentQuery.trim().isNotEmpty &&
          _currentQuery != 'أنا أستمع إليك الآن...') {
        _handleQuery(_currentQuery.trim());
      }
    } else {
      if (_isSpeaking) {
        await _stopSpeaking();
      }
      if (_speechAvailable) {
        setState(() {
          _isListening = true;
          _currentQuery = 'أنا أستمع إليك الآن...';
        });
        await _speech.listen(
          localeId: 'ar_EG',
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 3),
          onResult: (result) {
            setState(() {
              _currentQuery = result.recognizedWords;
              _textController.text = result.recognizedWords;
            });
            if (result.finalResult &&
                result.recognizedWords.trim().isNotEmpty) {
              _speech.stop();
              setState(() => _isListening = false);
              _handleQuery(result.recognizedWords.trim());
            }
          },
        );
      } else {
        _showQuickCommandsSheet();
      }
    }
  }

  void _showQuickCommandsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'أوامر صوتية سريعة',
                    style: FlutterFlowTheme.of(context).titleMedium,
                  ),
                  const Icon(Icons.mic, color: Colors.red),
                ],
              ),
              const SizedBox(height: 16),
              _QuickCommandTile(
                icon: Icons.emergency,
                iconColor: Colors.red,
                title: '🚨 اطلب استغاثة وابعث موقعي للمرافق',
                onTap: () {
                  Navigator.pop(ctx);
                  _handleQuery('اطلب استغاثة من مرافقي وابعث موقعي');
                },
              ),
              _QuickCommandTile(
                icon: Icons.local_hospital,
                iconColor: Colors.blue,
                title: '🏥 أقرب مستشفى فيها مدخل مناسب ومنحدر',
                onTap: () {
                  Navigator.pop(ctx);
                  _handleQuery('أقرب مستشفى فيها مدخل مناسب ومنحدر');
                },
              ),
              _QuickCommandTile(
                icon: Icons.shopping_bag,
                iconColor: Colors.teal,
                title: '🛍️ مول تجاري مجهز للكراسي في الجيزة',
                onTap: () {
                  Navigator.pop(ctx);
                  _handleQuery('مول تجاري مجهز في الجيزة');
                },
              ),
              _QuickCommandTile(
                icon: Icons.map,
                iconColor: Colors.orange,
                title: '🗺️ افتح الخريطة التفاعلية',
                onTap: () {
                  Navigator.pop(ctx);
                  _handleQuery('افتح الخريطة');
                },
              ),
            ],
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
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Stack(
            children: [
              // Background pattern
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.primary, theme.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: theme.background,
                    ),
                  ),
                ],
              ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top App Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _AppBarButton(
                            icon: Icons.arrow_forward_rounded,
                            onPressed: () => context.safePop(),
                            theme: theme,
                          ),
                          Row(
                            children: [
                              Icon(Icons.auto_awesome,
                                  color: theme.tertiary, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'ONEWAY AI Assistant',
                                style: theme.titleMedium.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          _AppBarButton(
                            icon: Icons.emergency,
                            iconColor: theme.error,
                            onPressed: () =>
                                context.pushNamed(EmergencySOSWidget.routeName),
                            theme: theme,
                          ),
                        ],
                      ),
                    ),

                    // Main Scrollable Area
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 10),

                            // Active Query display
                            if (_currentQuery.isNotEmpty)
                              _QueryCard(query: _currentQuery, theme: theme),

                            // Loading state
                            if (_isProcessing) ...[
                              const SizedBox(height: 24),
                              Center(
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(
                                      color: theme.primary,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'المساعد الذكي يبحث في بيانات الإتاحة...',
                                      style: theme.bodyMedium.copyWith(
                                        color: theme.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // AI Response Card
                            if (_lastResponse != null) ...[
                              const SizedBox(height: 16),
                              _ResponseCard(
                                response: _lastResponse!,
                                isSpeaking: _isSpeaking,
                                onSpeak: () => _speak(_lastResponse!.replyText),
                                onStop: _stopSpeaking,
                                theme: theme,
                              ),
                            ],

                            // Render Place Cards if any
                            if (_lastResponse?.places.isNotEmpty == true) ...[
                              const SizedBox(height: 16),
                              Text(
                                'الأماكن المقترحة لك:',
                                style: theme.titleMedium.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: theme.primaryText,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._lastResponse!.places.map((place) {
                                final f = place.accessibilityFeatures;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: theme.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(theme.designToken.radius.xl),
                                    side: BorderSide(
                                        color: theme.outlineVariant, width: 1.5),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: theme.secondary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                            theme.designToken.radius.lg),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.accessible_forward,
                                        color: theme.secondary,
                                        size: 24,
                                      ),
                                    ),
                                    title: Text(
                                      place.name,
                                      style: theme.titleMedium.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: theme.primaryText,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${place.category} • ${place.city}',
                                          style: theme.bodySmall.copyWith(
                                            fontSize: 12,
                                            color: theme.secondaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            if (f.hasRamp() && f.ramp)
                                              _FeatureChip(
                                                  icon: Icons.check,
                                                  label: 'منحدر',
                                                  color: theme.success,
                                                  theme: theme),
                                            if (f.hasSuitableElevator() &&
                                                f.suitableElevator)
                                              _FeatureChip(
                                                  icon: Icons.check,
                                                  label: 'مصعد',
                                                  color: theme.info,
                                                  theme: theme),
                                            if (f.hasAccessibleRestroom() &&
                                                f.accessibleRestroom)
                                              _FeatureChip(
                                                  icon: Icons.check,
                                                  label: 'حمام',
                                                  color: theme.primary,
                                                  theme: theme),
                                            if (f.hasWheelchairEntrance() &&
                                                f.wheelchairEntrance)
                                              _FeatureChip(
                                                  icon: Icons.check,
                                                  label: 'مدخل',
                                                  color: theme.tertiary,
                                                  theme: theme),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.arrow_back_ios),
                                    onTap: () {
                                      context.pushNamed(
                                        PlaceDetailsWidget.routeName,
                                        extra: <String, dynamic>{
                                          'placeRecord': place,
                                        },
                                      );
                                    },
                                  ),
                                );
                              }),
                            ],

                            // Suggestions when idle
                            if (_lastResponse == null && !_isProcessing) ...[
                              const SizedBox(height: 30),
                              Center(
                                child: Text(
                                  'جرّب أن تطلب مني بالصوت أو النص:',
                                  style: theme.labelMedium.copyWith(
                                    color: theme.tertiaryText,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              AssistantSuggestionWidget(
                                query: '🚨 اطلب استغاثة من مرافقي وابعث موقعي',
                                onTap: () => _handleQuery(
                                    'اطلب استغاثة من مرافقي وابعث موقعي'),
                              ),
                              const SizedBox(height: 10),
                              AssistantSuggestionWidget(
                                query: '🏥 أقرب مستشفى فيها مدخل مناسب ومنحدر',
                                onTap: () => _handleQuery(
                                    'أقرب مستشفى فيها مدخل مناسب ومنحدر'),
                              ),
                              const SizedBox(height: 10),
                              AssistantSuggestionWidget(
                                query: '🛍️ مول تجاري مجهز للكراسي في 6 أكتوبر',
                                onTap: () => _handleQuery(
                                    'عايز مول مجهز للكراسي في 6 اكتوبر'),
                              ),
                              const SizedBox(height: 10),
                              AssistantSuggestionWidget(
                                query: '🗺️ افتح الخريطة التفاعلية',
                                onTap: () => _handleQuery('افتح الخريطة'),
                              ),
                            ],
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Control Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 20,
                            color: theme.shadow.withValues(alpha: 0.1),
                            offset: const Offset(0, -4),
                            spreadRadius: 0,
                          ),
                        ],
                        border: Border(
                          top: BorderSide(
                            color: theme.outlineVariant.withValues(alpha: 0.5),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_showTextInput) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _textController,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (text) {
                                      _handleQuery(text);
                                      _textController.clear();
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'اكتب سؤالك هنا...',
                                      hintStyle: theme.bodyMedium.copyWith(
                                        color: theme.hintText,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(theme.designToken.radius.xl),
                                        borderSide:
                                            BorderSide(color: theme.outlineVariant, width: 1.5),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(theme.designToken.radius.xl),
                                        borderSide:
                                            BorderSide(color: theme.outlineVariant, width: 1.5),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(theme.designToken.radius.xl),
                                        borderSide:
                                            BorderSide(color: theme.primary, width: 2),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _BottomActionButton(
                                  icon: Icons.send,
                                  onPressed: () {
                                    _handleQuery(_textController.text);
                                    _textController.clear();
                                  },
                                  theme: theme,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Mic and toggle buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _BottomActionButton(
                                  icon: _showTextInput
                                      ? Icons.keyboard_hide
                                      : Icons.keyboard,
                                  onPressed: () {
                                    setState(
                                        () => _showTextInput = !_showTextInput);
                                  },
                                  theme: theme,
                                ),
                                GestureDetector(
                                  onTap: _toggleMic,
                                  child: AnimatedContainer(
                                    duration: theme.designToken.animation.normal,
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isListening
                                          ? theme.error
                                          : theme.primary,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_isListening
                                                  ? theme.error
                                                  : theme.primary)
                                              .withValues(alpha: 0.4),
                                          blurRadius: 16,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _isListening ? Icons.mic : Icons.mic_none,
                                      color: theme.onPrimary,
                                      size: 36,
                                    ),
                                  ),
                                ),
                                _BottomActionButton(
                                  icon: Icons.emergency_outlined,
                                  iconColor: theme.error,
                                  onPressed: () => _handleQuery(
                                      'اطلب استغاثة من مرافقي وابعث موقعي'),
                                  theme: theme,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isListening
                                  ? 'جارٍ الاستماع... اضغط للإيقاف'
                                  : 'اضغط على الميكروفون للتحدث',
                              style: theme.labelSmall.copyWith(
                                color: theme.tertiaryText,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBarButton extends StatelessWidget {
  const _AppBarButton({
    required this.icon,
    this.iconColor,
    required this.onPressed,
    required this.theme,
  });

  final IconData icon;
  final Color? iconColor;
  final VoidCallback onPressed;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(theme.designToken.radius.full),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(theme.designToken.radius.full),
          ),
          child: Icon(icon, color: iconColor ?? Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  const _BottomActionButton({
    required this.icon,
    this.iconColor,
    required this.onPressed,
    required this.theme,
  });

  final IconData icon;
  final Color? iconColor;
  final VoidCallback onPressed;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(theme.designToken.radius.full),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(theme.designToken.radius.full),
          ),
          child: Icon(icon, color: iconColor ?? theme.primary, size: 26),
        ),
      ),
    );
  }
}

class _QuickCommandTile extends StatelessWidget {
  const _QuickCommandTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.1),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: theme.bodyMedium.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: theme.primaryText,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _QueryCard extends StatelessWidget {
  const _QueryCard({
    required this.query,
    required this.theme,
  });

  final String query;
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
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.secondary.withValues(alpha: 0.1),
              child: Icon(Icons.person, color: theme.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                query,
                style: theme.bodyMedium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  const _ResponseCard({
    required this.response,
    required this.isSpeaking,
    required this.onSpeak,
    required this.onStop,
    required this.theme,
  });

  final AIResponse response;
  final bool isSpeaking;
  final VoidCallback onSpeak;
  final VoidCallback onStop;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    final isEmergency = response.intent == AIIntentType.emergency;

    return Card(
      color: isEmergency
          ? theme.error.withValues(alpha: 0.08)
          : theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        side: BorderSide(
          color: isEmergency ? theme.error : theme.outlineVariant,
          width: isEmergency ? 1.5 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          isEmergency ? theme.error : theme.primary,
                      child: Icon(
                        isEmergency
                            ? Icons.warning_rounded
                            : Icons.auto_awesome,
                        color: theme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEmergency ? 'تنبيه طوارئ' : 'رد المساعد الذكي',
                      style: theme.titleSmall.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isEmergency ? theme.error : theme.primaryText,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: isSpeaking ? 'إيقاف الصوت' : 'استماع للرد صوتياً',
                  icon: Icon(
                    isSpeaking ? Icons.volume_up_rounded : Icons.volume_mute_rounded,
                    color: isSpeaking ? theme.success : theme.onSurfaceVariant,
                  ),
                  onPressed: isSpeaking ? onStop : onSpeak,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              response.replyText,
              style: theme.bodyMedium.copyWith(
                fontSize: 14,
                height: 1.6,
                color: theme.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final Color color;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(theme.designToken.radius.full),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.labelSmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
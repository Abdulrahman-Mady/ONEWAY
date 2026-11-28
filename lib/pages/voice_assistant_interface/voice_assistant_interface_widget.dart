import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '/core/analytics/analytics_service.dart';
import '/core/theme/oneway_theme.dart';
import '/core/utils/a11y_utils.dart';
import '/features/accessibility/accessibility_score.dart';
import '/features/ai/oneway_ai_engine.dart';
import '/features/ai/voice_action_executor.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/widgets/responsive_layout.dart';
import 'voice_assistant_interface_model.dart';
export 'voice_assistant_interface_model.dart';

/// Clean, minimalist, executive-grade Voice & AI Assistant screen for ONEWAY.
///
/// Features:
/// - Serene ambient voice visualizer (no visual clutter or duplicate mic buttons)
/// - Minimalist header with mute toggle and secondary options menu
/// - Multi-turn conversation stream with sleek dark-glass response & place cards
/// - Streamlined 3-control bottom bar (Capabilities, Primary Mic, Keyboard)
/// - Full bilingual support (Arabic RTL & English LTR) and 1.45x font-scale safety
class VoiceAssistantInterfaceWidget extends StatefulWidget {
  const VoiceAssistantInterfaceWidget({
    super.key,
    this.enableAutoGreeting = true,
    this.enableSpeechInit = true,
  });

  /// Allows widget tests to render cleanly without firing platform TTS/STT channels.
  final bool enableAutoGreeting;
  final bool enableSpeechInit;

  static String routeName = 'VoiceAssistantInterface';
  static String routePath = '/assistant';

  @override
  State<VoiceAssistantInterfaceWidget> createState() =>
      _VoiceAssistantInterfaceWidgetState();
}

class _VoiceAssistantInterfaceWidgetState
    extends State<VoiceAssistantInterfaceWidget>
    with SingleTickerProviderStateMixin {
  late VoiceAssistantInterfaceModel _model;
  late AnimationController _pulseController;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  final AssistantSession _session = AssistantSession();
  final List<ConversationTurn> _turns = [];

  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  bool _showTextInput = false;
  bool _conversationMode = true;
  bool _micManuallyDisabled = false;
  bool _voiceMuted = false;
  double _soundLevel = 0.0;
  String _liveTranscript = '';
  int _turnCounter = 0;
  Timer? _resumeListenTimer;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => VoiceAssistantInterfaceModel());
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    final appState = FFAppState();
    _session.localeCode = appState.localeCode;
    _voiceMuted = !appState.voiceFeedbackEnabled;

    if (widget.enableSpeechInit) {
      _initSpeech();
      _initTts();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = GoRouter.maybeOf(context);
      final initialQuery = router
          ?.routerDelegate.currentConfiguration.uri.queryParameters['initialQuery'];
      if (initialQuery != null && initialQuery.trim().isNotEmpty) {
        _handleQuery(initialQuery.trim());
      } else if (widget.enableAutoGreeting && !_voiceMuted) {
        final isEn = _isEn;
        _speak(
          isEn
              ? 'Welcome to ONEWAY Smart Assistant. How can I help you?'
              : 'أهلاً بيك في مساعد وان واي الذكي! قولّي أساعدك إزاي النهاردة؟',
          isEnglish: isEn,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (A11yUtils.prefersReducedMotion(context)) {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
      }
    } else if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  bool get _isEn => _session.localeCode == 'en';

  void _cancelPendingResume() {
    _resumeListenTimer?.cancel();
    _resumeListenTimer = null;
  }

  /// Opens the mic ONCE after TTS finishes speaking, strictly respecting the
  /// user's manual mic lock. Never loops on silence/timeout.
  void _scheduleSingleListenAfterSpeech() {
    _cancelPendingResume();
    if (!mounted ||
        _micManuallyDisabled ||
        !_conversationMode ||
        !_speechAvailable ||
        _isListening ||
        _isProcessing ||
        _showTextInput) {
      return;
    }
    _resumeListenTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted ||
          _micManuallyDisabled ||
          !_conversationMode ||
          _isListening ||
          _isProcessing ||
          _isSpeaking ||
          _showTextInput) {
        return;
      }
      _startListening(userInitiated: false);
    });
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (val) {
          debugPrint('Speech error: $val');
          // Never auto-restart on timeout/no-match — wait calmly for user tap.
          _cancelPendingResume();
          if (mounted) {
            setState(() {
              _isListening = false;
              _soundLevel = 0.0;
            });
          }
        },
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted && _isListening) {
              final captured = _liveTranscript.trim();
              setState(() {
                _isListening = false;
                _soundLevel = 0.0;
              });
              if (captured.isNotEmpty) {
                _handleQuery(captured);
              }
              // When silence/timeout occurs with no speech, settle calmly into
              // idle ready state — NEVER bounce/re-open the mic in a loop.
            }
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Speech init exception: $e');
    }
  }

  Future<void> _configureTtsLocale({required bool useEnglish}) async {
    if (useEnglish) {
      await _flutterTts.setLanguage('en-US');
      return;
    }
    // Prefer an authentic Egyptian Arabic voice (ar-EG) when available on device.
    try {
      final voices = await _flutterTts.getVoices;
      if (voices is List) {
        Map<String, String>? bestEgVoice;
        for (final raw in voices) {
          if (raw is Map) {
            final locale = (raw['locale'] ?? '').toString();
            final name = (raw['name'] ?? '').toString();
            final normLocale = locale.toLowerCase().replaceAll('_', '-');
            if (normLocale.startsWith('ar-eg') && name.isNotEmpty) {
              bestEgVoice = {'name': name, 'locale': locale};
              if (name.toLowerCase().contains('network') ||
                  name.toLowerCase().contains('salma') ||
                  name.toLowerCase().contains('shakir')) {
                break;
              }
            }
          }
        }
        if (bestEgVoice != null) {
          await _flutterTts.setVoice(bestEgVoice);
          return;
        }
      }
    } catch (_) {}

    try {
      final hasArEgDash = await _flutterTts.isLanguageAvailable('ar-EG');
      if (hasArEgDash == true) {
        await _flutterTts.setLanguage('ar-EG');
        return;
      }
      final hasArEgUnderscore = await _flutterTts.isLanguageAvailable('ar_EG');
      if (hasArEgUnderscore == true) {
        await _flutterTts.setLanguage('ar_EG');
        return;
      }
    } catch (_) {}

    await _flutterTts.setLanguage('ar');
  }

  String _prepareSpokenText(String text, {required bool useEnglish}) {
    var clean = text
        .replaceAll(RegExp(r'https?://\S+'), '')
        .replaceAll('*', '')
        .replaceAll('#', '')
        .replaceAll('🚨', '')
        .replaceAll('📍', '')
        .replaceAll('✅', '')
        .replaceAll('❌', '')
        .replaceAll('⚠️', '')
        .replaceAll('1️⃣', 'أولاً: ')
        .replaceAll('2️⃣', 'ثانياً: ')
        .replaceAll('•', '،')
        .trim();

    if (!useEnglish) {
      clean = clean
          .replaceAll(RegExp(r'\bONEWAY\b', caseSensitive: false), 'وان واي')
          .replaceAll(RegExp(r'\bGPS\b', caseSensitive: false), 'جي بي إس')
          .replaceAll(RegExp(r'\bSOS\b', caseSensitive: false), 'استغاثة طوارئ')
          .replaceAll(RegExp(r'\bRamp\b', caseSensitive: false), 'رامب')
          .replaceAll(RegExp(r'\bLRT\b', caseSensitive: false), 'القطار الكهربائي')
          .replaceAll('%', ' في المية ');
    }

    return clean.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<void> _initTts() async {
    try {
      await _configureTtsLocale(useEnglish: _session.isEnglish);
      await _flutterTts.setSpeechRate(_session.ttsRate);
      await _flutterTts.setPitch(1.0);
      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
        _scheduleSingleListenAfterSpeech();
      });
      _flutterTts.setErrorHandler((msg) {
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (e) {
      debugPrint('TTS init exception: $e');
    }
  }

  Future<void> _speak(String text, {bool? isEnglish}) async {
    if (_voiceMuted || text.trim().isEmpty) return;
    final useEn = isEnglish ?? _isEn;
    final clean = _prepareSpokenText(text, useEnglish: useEn);
    if (clean.isEmpty) return;

    try {
      await _configureTtsLocale(useEnglish: useEn);
      await _flutterTts.setSpeechRate(_session.ttsRate);
      if (mounted) setState(() => _isSpeaking = true);
      await _flutterTts.stop();
      await _flutterTts.speak(clean);
    } catch (e) {
      debugPrint('TTS speak exception: $e');
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  Future<void> _stopSpeaking() async {
    _cancelPendingResume();
    try {
      await _flutterTts.stop();
      if (mounted) setState(() => _isSpeaking = false);
    } catch (_) {}
  }

  @override
  void dispose() {
    _cancelPendingResume();
    _conversationMode = false;
    _micManuallyDisabled = true;
    _pulseController.dispose();
    _model.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    _scrollController.dispose();
    try {
      _speech.stop();
    } catch (_) {}
    try {
      _flutterTts.stop();
    } catch (_) {}
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: A11yUtils.effectiveDuration(
          context,
          const Duration(milliseconds: 300),
        ),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _handleQuery(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return;

    if (_isSpeaking) {
      await _stopSpeaking();
    }
    if (_isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
    }

    setState(() {
      _liveTranscript = '';
      _isListening = false;
      _soundLevel = 0.0;
      _isProcessing = true;
      _turns.add(
        ConversationTurn(
          id: 'u_${++_turnCounter}',
          isUser: true,
          text: query,
        ),
      );
    });
    _scrollToBottom();

    try {
      final response = await OnewayAIEngine.processQuery(
        null,
        query,
        session: _session,
      );
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _turns.add(
          ConversationTurn(
            id: 'a_${++_turnCounter}',
            isUser: false,
            text: response.replyText,
            response: response,
          ),
        );
      });
      _scrollToBottom();

      AnalyticsService.instance.logVoiceAssistantUsed(
        intent: response.intent.name,
        success: true,
        placeId: response.places.isNotEmpty
            ? response.places.first.reference.id
            : null,
      );

      // Execute auto-action if present
      final action = response.primaryAction;
      if (action != null && action.autoExecute) {
        if (action.type == AssistantActionType.navigate ||
            action.type == AssistantActionType.goBack ||
            action.type == AssistantActionType.openPlace ||
            action.type == AssistantActionType.openReport) {
          // Speak first, then navigate cleanly without permanently disabling hands-free mode.
          final wasHandsFree = _conversationMode;
          _conversationMode = false;
          _cancelPendingResume();
          _speak(response.spokenText, isEnglish: response.isEnglish);
          Future.delayed(const Duration(milliseconds: 1100), () async {
            if (!mounted) return;
            await _runAction(action);
            if (mounted && wasHandsFree) {
              _conversationMode = _session.conversationMode;
            }
          });
          return;
        } else {
          await _runAction(action);
        }
      }

      // Speak concise spoken summary (unless action muted voice)
      if (!_voiceMuted && response.spokenText.isNotEmpty) {
        _speak(response.spokenText, isEnglish: response.isEnglish);
      } else if (_voiceMuted && response.replyText.isNotEmpty && mounted) {
        SemanticsService.announce(
          response.replyText,
          response.isEnglish ? TextDirection.ltr : TextDirection.rtl,
        );
      }
    } catch (e) {
      AnalyticsService.instance.logVoiceAssistantUsed(
        intent: 'error',
        success: false,
      );
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _turns.add(
          ConversationTurn(
            id: 'e_${++_turnCounter}',
            isUser: false,
            text: _isEn
                ? 'Something went wrong while processing your request. Please try again.'
                : 'حدث خطأ أثناء معالجة طلبك. يرجى المحاولة مرة أخرى.',
            response: AIResponse(
              intent: AIIntentType.generalInfo,
              replyText: _isEn
                  ? 'Something went wrong while processing your request.'
                  : 'حدث خطأ أثناء معالجة طلبك.',
              isEnglish: _isEn,
            ),
          ),
        );
      });
      _scrollToBottom();
    }
  }

  Future<void> _runAction(AssistantAction action) async {
    final result = await VoiceActionExecutor.execute(
      context,
      action,
      onClearConversation: _clearConversation,
      onTtsRateChanged: (rate) {
        _session.ttsRate = rate;
        _flutterTts.setSpeechRate(rate);
      },
      onConversationModeChanged: (enabled) {
        if (mounted) setState(() => _conversationMode = enabled);
      },
      onVoiceFeedbackChanged: (enabled) {
        if (mounted) setState(() => _voiceMuted = !enabled);
        if (!enabled) _stopSpeaking();
      },
      onLocaleChanged: (code) {
        if (mounted) {
          setState(() => _session.localeCode = code);
        }
      },
    );

    if (!mounted) return;
    if (result.feedbackMessage != null &&
        result.feedbackMessage!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.feedbackMessage!),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _clearConversation() {
    _stopSpeaking();
    setState(() {
      _session.clear();
      _turns.clear();
      _liveTranscript = '';
      _isProcessing = false;
    });
  }

  Future<void> _toggleLanguage() async {
    final nextCode = _isEn ? 'ar' : 'en';
    _session.localeCode = nextCode;
    await FFAppState().setLocaleCode(nextCode);
    await AnalyticsService.instance.setPreferredLanguage(nextCode);
    if (mounted) setState(() {});
  }

  Future<void> _toggleMute() async {
    final nextMuted = !_voiceMuted;
    setState(() => _voiceMuted = nextMuted);
    await FFAppState().setVoiceFeedbackEnabled(!nextMuted);
    if (nextMuted) {
      await _stopSpeaking();
    }
  }

  Future<void> _startListening({bool userInitiated = true}) async {
    _cancelPendingResume();
    if (!_speechAvailable) {
      if (userInitiated && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEn
                  ? 'Microphone is unavailable. You can type your request below.'
                  : 'الميكروفون غير متاح حالياً. يمكنك الكتابة من زر لوحة المفاتيح بالأسفل.',
            ),
          ),
        );
      }
      return;
    }
    if (_isSpeaking) {
      await _stopSpeaking();
    }
    setState(() {
      _micManuallyDisabled = false;
      _isListening = true;
      _liveTranscript = '';
      _soundLevel = 0.2;
    });
    try {
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: _isEn ? 'en_US' : 'ar_EG',
          // Wait patiently for the user to start and finish speaking
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 10),
          partialResults: true,
          enableHapticFeedback: true,
          contextualPhrases: const [
            'ONEWAY',
            'وان واي',
            'منحدر',
            'رامب',
            'مصعد',
            'أسانسير',
            'حمام مجهز',
            'استغاثة',
            'صاحب مكان',
            'بطاقة الخدمات المتكاملة',
            'التباين العالي',
          ],
        ),
        onSoundLevelChange: (level) {
          if (!mounted) return;
          // Normalize typical dB range (-2..10) into 0.0..1.0 smoothly.
          final normalized = ((level + 2.0) / 12.0).clamp(0.05, 1.0);
          setState(() => _soundLevel = normalized);
        },
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _liveTranscript = result.recognizedWords;
            if (_showTextInput) {
              _textController.text = result.recognizedWords;
            }
          });
          if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
            _speech.stop();
            setState(() {
              _isListening = false;
              _soundLevel = 0.0;
            });
            _handleQuery(result.recognizedWords.trim());
          }
        },
      );
    } catch (e) {
      debugPrint('Speech listen exception: $e');
      if (mounted) {
        setState(() {
          _isListening = false;
          _soundLevel = 0.0;
        });
      }
    }
  }

  Future<void> _disableMicAndPauseAssistant() async {
    _cancelPendingResume();
    try {
      await _speech.cancel();
    } catch (_) {}
    await _stopSpeaking();
    if (mounted) {
      setState(() {
        _micManuallyDisabled = true;
        _conversationMode = false;
        _isListening = false;
        _soundLevel = 0.0;
        _liveTranscript = '';
      });
    }
    _session.conversationMode = false;
  }

  Future<void> _toggleMic() async {
    if (_isListening) {
      final captured = _liveTranscript.trim();
      if (captured.isNotEmpty) {
        // User finished speaking and tapped stop: process what they said.
        _cancelPendingResume();
        try {
          await _speech.stop();
        } catch (_) {}
        if (mounted) {
          setState(() {
            _isListening = false;
            _soundLevel = 0.0;
          });
        }
        _handleQuery(captured);
      } else {
        // User explicitly closed the mic: stay silent & off until tapped again.
        await _disableMicAndPauseAssistant();
      }
    } else if (_isSpeaking) {
      // Tapping mic while assistant is speaking pauses/stops it completely
      // until the user taps the mic again to re-enable.
      await _disableMicAndPauseAssistant();
    } else {
      // User explicitly tapped mic to activate it again.
      setState(() {
        _micManuallyDisabled = false;
        _conversationMode = true;
      });
      _session.conversationMode = true;
      await _startListening(userInitiated: true);
    }
  }

  void _navigateBack() {
    _cancelPendingResume();
    _conversationMode = false;
    _micManuallyDisabled = true;
    _stopSpeaking();
    try {
      _speech.cancel();
    } catch (_) {}
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      context.safePop();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _showCapabilitiesSheet() {
    final theme = FlutterFlowTheme.of(context);
    final isEn = _isEn;

    final groups = <({
      String title,
      IconData icon,
      Color color,
      List<({String label, String query})> items,
    })>[
      (
        title: isEn ? 'Smart Place Discovery' : 'البحث الذكي عن الأماكن',
        icon: Icons.location_on_rounded,
        color: OnewayPalette.primaryAccentOnDark,
        items: [
          (
            label: isEn
                ? 'Nearest hospital with ramp'
                : 'أقرب مستشفى فيها منحدر ومدخل مناسب',
            query: isEn
                ? 'Nearest hospital with ramp'
                : 'أقرب مستشفى فيها منحدر ومدخل مناسب',
          ),
          (
            label: isEn
                ? 'Wheelchair-accessible mall in 6th of October'
                : 'مول تجاري مجهز للكراسي في 6 أكتوبر',
            query: isEn
                ? 'Accessible mall in 6 October'
                : 'مول تجاري مجهز للكراسي في 6 أكتوبر',
          ),
          (
            label: isEn
                ? 'Accessible museums & cultural sites'
                : 'متاحف وأماكن ثقافية مجهزة في القاهرة',
            query: isEn
                ? 'Accessible museums in Cairo'
                : 'متاحف وأماكن ثقافية مجهزة في القاهرة',
          ),
          (
            label: isEn
                ? 'Does Mall of Egypt have an accessible restroom?'
                : 'هل مول مصر فيه حمام مجهز ومصعد؟',
            query: isEn
                ? 'Does Mall of Egypt have an accessible restroom?'
                : 'هل مول مصر فيه حمام مجهز ومصعد؟',
          ),
        ],
      ),
      (
        title: isEn ? 'Live App & Accessibility Controls' : 'التحكم بالتطبيق والإتاحة بالصوت',
        icon: Icons.tune_rounded,
        color: const Color(0xFF8B5CF6),
        items: [
          (
            label: isEn ? 'Increase font size' : 'كبّر حجم الخط في التطبيق',
            query: isEn ? 'Increase font size' : 'كبّر الخط',
          ),
          (
            label: isEn ? 'Enable high contrast mode' : 'شغّل وضع التباين العالي',
            query: isEn ? 'Enable high contrast' : 'شغّل التباين العالي',
          ),
          (
            label: isEn ? 'Switch to Dark Mode' : 'شغّل الوضع الليلي (دارك مود)',
            query: isEn ? 'Dark mode' : 'شغّل الوضع الليلي',
          ),
          (
            label: isEn
                ? 'Set mobility: Wheelchair'
                : 'تخصيص طريقة التنقل: كرسي متحرك',
            query: isEn
                ? 'I use a wheelchair'
                : 'أنا بستخدم كرسي متحرك',
          ),
          (
            label: isEn
                ? 'Personalize my access needs'
                : 'خصص احتياجات الوصول الخاصة بي',
            query: isEn
                ? 'Personalize accessibility'
                : 'خصص احتياجاتي',
          ),
        ],
      ),
      (
        title: isEn ? 'Egypt Rights & Official Hotlines' : 'دليلك وحقوقك والأرقام الرسمية في مصر',
        icon: Icons.gavel_rounded,
        color: OnewayPalette.gold,
        items: [
          (
            label: isEn
                ? 'How to get the Integrated Services Card'
                : 'خطوات استخراج بطاقة الخدمات المتكاملة',
            query: isEn
                ? 'How to get Integrated Services Card?'
                : 'خطوات استخراج بطاقة الخدمات المتكاملة',
          ),
          (
            label: isEn
                ? 'Your rights under Law No. 10 of 2018'
                : 'حقوقي في قانون رقم 10 لسنة 2018',
            query: isEn
                ? 'What are my rights in Law 10 of 2018?'
                : 'إيه حقوقي في قانون 10 لسنة 2018؟',
          ),
          (
            label: isEn
                ? 'Cairo Metro & accessible transit tips'
                : 'خطوط المترو المجهزة وتخفيضات المواصلات',
            query: isEn
                ? 'Which Cairo Metro lines are accessible?'
                : 'إيه خطوط المترو المجهزة في مصر؟',
          ),
          (
            label: isEn
                ? 'Show all official Egyptian hotlines'
                : 'اعرض كل الأرقام الرسمية والخطوط الساخنة',
            query: isEn
                ? 'Show all official hotlines'
                : 'اعرض كل الأرقام الرسمية والخطوط الساخنة',
          ),
        ],
      ),
      (
        title: isEn ? 'Account, Navigation & Emergency' : 'حسابك، التنقل، والطوارئ',
        icon: Icons.explore_rounded,
        color: const Color(0xFFEF4444),
        items: [
          (
            label: isEn ? 'Trigger SOS & share my location' : '🚨 اطلب استغاثة من مرافقي وابعث موقعي',
            query: isEn
                ? 'Trigger SOS and send my location'
                : 'اطلب استغاثة من مرافقي وابعث موقعي',
          ),
          (
            label: isEn ? 'What is in my favorites?' : 'إيه الأماكن المحفوظة في مفضلتي؟',
            query: isEn ? 'What are my favorites?' : 'إيه في مفضلتي؟',
          ),
          (
            label: isEn ? 'Check my barrier reports' : 'إيه أخبار بلاغاتي؟',
            query: isEn ? 'Check my reports' : 'أخبار بلاغاتي',
          ),
          (
            label: isEn ? 'Open interactive map' : 'افتح الخريطة التفاعلية',
            query: isEn ? 'Open map' : 'افتح الخريطة',
          ),
          (
            label: isEn
                ? 'Report a barrier at a registered place'
                : 'أبلغ عن عائق في مكان مسجّل',
            query: isEn ? 'Report a barrier' : 'أبلغ عن عائق',
          ),
          (
            label: isEn
                ? 'Manage my venue (Place Owner)'
                : 'إدارة وتعديل مكاني (لصاحب المكان)',
            query: isEn ? 'Open business portal' : 'افتح لوحة صاحب المكان',
          ),
          (
            label: isEn ? 'Read my profile aloud' : 'اقرأ بيانات حسابي بالصوت',
            query: isEn ? 'Read my profile' : 'اقرأ بياناتي',
          ),
          (
            label: isEn ? 'Suggest an accessible place' : 'اقترح مكان مهيأ جديد',
            query: isEn ? 'Suggest a place' : 'اقترح مكان',
          ),
          (
            label: isEn ? 'Message support on WhatsApp' : 'كلم الدعم الفني على واتساب',
            query: isEn ? 'WhatsApp support' : 'واتساب الدعم',
          ),
          (
            label: isEn ? 'Where am I right now?' : 'أنا فين دلوقتي؟ (فحص GPS)',
            query: isEn ? 'Where am I?' : 'أنا فين دلوقتي؟',
          ),
        ],
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Directionality(
        textDirection: isEn ? TextDirection.ltr : TextDirection.rtl,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.9,
          builder: (_, controller) => Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: theme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isEn
                            ? 'Everything I Can Do For You'
                            : 'كل ما أقدر أعمله لك بالصوت',
                        style: theme.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.primaryText,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: isEn ? 'Close' : 'إغلاق',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: groups.length,
                  itemBuilder: (_, idx) {
                    final g = groups[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: g.color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(g.icon, color: g.color, size: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  g.title,
                                  style: theme.titleSmall.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: theme.primaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          for (final item in g.items)
                            Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              color: theme.surfaceVariant.withValues(alpha: 0.45),
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  item.label,
                                  style: theme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.primaryText,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.mic_none_rounded,
                                  size: 20,
                                  color: g.color,
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _handleQuery(item.query);
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(bool isEn) {
    if (_isListening) {
      return isEn ? 'Listening...' : 'يستمع الآن...';
    }
    if (_isProcessing) {
      return isEn ? 'Thinking...' : 'يفكّر...';
    }
    if (_isSpeaking) {
      return isEn ? 'Speaking' : 'يتحدث';
    }
    if (_micManuallyDisabled) {
      return isEn ? 'Mic paused' : 'المايك متوقف';
    }
    if (_voiceMuted) {
      return isEn ? 'Muted' : 'الصوت مكتوم';
    }
    return isEn ? 'Ready' : 'جاهز';
  }

  List<({String label, String query})> _quickPrompts(bool isEn) {
    return [
      (
        label: isEn ? 'Nearest hospital' : 'أقرب مستشفى',
        query: isEn
            ? 'Nearest hospital with ramp'
            : 'أقرب مستشفى فيها مدخل مناسب ومنحدر',
      ),
      (
        label: isEn ? 'Accessible malls' : 'مولات مهيأة',
        query: isEn
            ? 'Accessible mall in 6 October'
            : 'عايز مول مجهز للكراسي في 6 اكتوبر',
      ),
      (
        label: isEn ? 'Open map' : 'افتح الخريطة',
        query: isEn ? 'Open map' : 'افتح الخريطة',
      ),
      (
        label: isEn ? 'Rights & guide' : 'دليلك وحقوقك',
        query: isEn
            ? 'What are my rights in Law 10 of 2018?'
            : 'إيه حقوقي في قانون 10 لسنة 2018؟',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isEn = _isEn;
    final reducedMotion = A11yUtils.prefersReducedMotion(context);
    final hPad = OnewayResponsive.horizontalPadding(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFF0A1524),
        body: Directionality(
          textDirection: isEn ? TextDirection.ltr : TextDirection.rtl,
          child: Stack(
            children: [
              // Clean refined deep slate-navy backdrop with subtle ambient glow
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0A1524),
                        Color(0xFF0F2035),
                        Color(0xFF0B1829),
                      ],
                    ),
                  ),
                ),
              ),
              if (_turns.isEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.18),
                          radius: 0.78,
                          colors: [
                            (_isListening
                                    ? const Color(0xFFEF4444)
                                    : OnewayPalette.primaryAccentOnDark)
                                .withValues(alpha: 0.14),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopBar(theme, isEn),
                    Expanded(
                      child: ResponsiveContainer(
                        maxWidth: 680,
                        child: _turns.isEmpty && !_isProcessing
                            ? _buildIdleHero(theme, isEn, reducedMotion, hPad)
                            : _buildConversationStream(theme, isEn, hPad),
                      ),
                    ),
                    if (_isListening && _turns.isNotEmpty)
                      _buildLiveListeningBanner(theme, isEn),
                    _buildBottomDock(theme, isEn, reducedMotion),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(FlutterFlowTheme theme, bool isEn) {
    final isCompact = OnewayResponsive.isCompact(context);
    final statusColor = _isListening
        ? const Color(0xFFEF4444)
        : _isSpeaking
            ? const Color(0xFF38BDF8)
            : _voiceMuted
                ? Colors.white38
                : const Color(0xFF2DD4BF);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 12 : 18,
        10,
        isCompact ? 12 : 18,
        6,
      ),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: isEn ? 'Back' : 'رجوع',
            onPressed: _navigateBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEn ? 'ONEWAY AI' : 'مساعد ONEWAY',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _statusLabel(isEn),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.labelSmall.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.68),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          _HeaderIconButton(
            icon: _voiceMuted
                ? Icons.volume_off_rounded
                : Icons.volume_up_rounded,
            iconColor: _voiceMuted
                ? Colors.white54
                : OnewayPalette.primaryDarkMode,
            tooltip: _voiceMuted
                ? (isEn ? 'Unmute voice' : 'تشغيل الصوت')
                : (isEn ? 'Mute voice' : 'كتم الصوت'),
            onPressed: _toggleMute,
          ),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            tooltip: isEn ? 'More options' : 'خيارات إضافية',
            color: const Color(0xFF152942),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
            onSelected: (value) {
              switch (value) {
                case 'lang':
                  _toggleLanguage();
                  break;
                case 'auto_listen':
                  setState(() => _conversationMode = !_conversationMode);
                  _session.conversationMode = _conversationMode;
                  break;
                case 'new_chat':
                  _clearConversation();
                  break;
                case 'sos':
                  _handleQuery(
                    isEn
                        ? 'Trigger SOS and send my location'
                        : 'اطلب استغاثة من مرافقي وابعث موقعي',
                  );
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'lang',
                child: Row(
                  children: [
                    const Icon(Icons.translate_rounded,
                        size: 18, color: Colors.white70),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isEn ? 'التحويل للعربية' : 'Switch to English',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'auto_listen',
                child: Row(
                  children: [
                    Icon(
                      _conversationMode
                          ? Icons.hearing_rounded
                          : Icons.hearing_disabled_rounded,
                      size: 18,
                      color: _conversationMode
                          ? OnewayPalette.primaryDarkMode
                          : Colors.white54,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _conversationMode
                            ? (isEn ? 'Auto-listen: ON' : 'الاستماع التلقائي: مفعّل')
                            : (isEn ? 'Auto-listen: OFF' : 'الاستماع التلقائي: متوقف'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              if (_turns.isNotEmpty)
                PopupMenuItem<String>(
                  value: 'new_chat',
                  child: Row(
                    children: [
                      const Icon(Icons.refresh_rounded,
                          size: 18, color: Colors.white70),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isEn ? 'New conversation' : 'محادثة جديدة',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              PopupMenuItem<String>(
                value: 'sos',
                child: Row(
                  children: [
                    const Icon(Icons.emergency_rounded,
                        size: 18, color: Color(0xFFFCA5A5)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isEn ? 'Emergency SOS' : 'استغاثة طوارئ',
                        style: const TextStyle(color: Color(0xFFFCA5A5)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.more_vert_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleHero(
    FlutterFlowTheme theme,
    bool isEn,
    bool reducedMotion,
    double hPad,
  ) {
    final prompts = _quickPrompts(isEn);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 36).clamp(0.0, double.infinity),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Single refined ambient voice presence (never duplicates the mic button)
                _AmbientVoicePresence(
                  controller: _pulseController,
                  isListening: _isListening,
                  isSpeaking: _isSpeaking,
                  isProcessing: _isProcessing,
                  soundLevel: _soundLevel,
                  reducedMotion: reducedMotion,
                  onTap: _toggleMic,
                  semanticLabel: _isListening
                      ? (isEn ? 'Stop listening' : 'إيقاف الاستماع')
                      : (isEn ? 'Tap to speak' : 'اضغط للتحدث'),
                ),
                const SizedBox(height: 28),

                // Live transcript OR calm executive greeting
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _isListening && _liveTranscript.isNotEmpty
                        ? _liveTranscript
                        : _isListening
                            ? (isEn ? 'Listening...' : 'أنا أستمع إليك...')
                            : _isSpeaking
                                ? (isEn ? 'Speaking...' : 'جاري التحدث...')
                                : _micManuallyDisabled
                                    ? (isEn
                                        ? 'Mic is paused'
                                        : 'تم إيقاف المايك')
                                    : (isEn
                                        ? 'Welcome to ONEWAY Smart Assistant'
                                        : 'أهلاً بك في مساعد وان واي الذكي'),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.headlineSmall.copyWith(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isListening
                      ? (isEn
                          ? 'Speak naturally — tap stop anytime'
                          : 'تحدّث براحتك — واضغط المايك لإيقافه في أي وقت')
                      : _micManuallyDisabled
                          ? (isEn
                              ? 'Tap the mic button when you want to speak again'
                              : 'اضغط على زر المايك عندما تريد التحدث مجدداً')
                          : (isEn
                              ? 'How can I help you?'
                              : 'أقدر أساعدك إزاي؟'),
                  textAlign: TextAlign.center,
                  style: theme.bodyMedium.copyWith(
                    fontSize: 14.5,
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),

                // 4 clean, emoji-free minimal quick-start chips
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in prompts)
                      _MinimalSuggestionChip(
                        label: p.label,
                        onTap: () => _handleQuery(p.query),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversationStream(
    FlutterFlowTheme theme,
    bool isEn,
    double hPad,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 20),
      itemCount: _turns.length + (_isProcessing ? 1 : 0),
      itemBuilder: (ctx, index) {
        if (_isProcessing && index == _turns.length) {
          return _ThinkingBubble(isEn: isEn, theme: theme);
        }

        final turn = _turns[index];
        final isLastTurn = index == _turns.length - 1;

        if (turn.isUser) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _UserBubble(text: turn.text, theme: theme),
          );
        }

        final response = turn.response;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AssistantResponseCard(
                response: response ??
                    AIResponse(
                      intent: AIIntentType.generalInfo,
                      replyText: turn.text,
                      isEnglish: isEn,
                    ),
                isSpeaking: _isSpeaking && isLastTurn,
                isEn: isEn,
                theme: theme,
                onSpeak: () => _speak(
                  response?.spokenText ?? turn.text,
                  isEnglish: response?.isEnglish ?? isEn,
                ),
                onStop: _stopSpeaking,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: turn.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEn ? 'Copied to clipboard' : 'تم النسخ'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                onActionTap: _runAction,
              ),

              // Enriched Place Cards
              if (response != null && response.places.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...List.generate(response.places.length, (pIdx) {
                  final place = response.places[pIdx];
                  final match = pIdx < response.placeMatches.length
                      ? response.placeMatches[pIdx]
                      : PlaceMatch(
                          place: place,
                          compatibility: AccessibilityScorer.evaluatePlace(
                            place,
                            mobilityType: _session.mobilityType,
                          ),
                        );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _EnrichedPlaceCard(
                      match: match,
                      indexNumber: pIdx + 1,
                      isEn: isEn,
                      theme: theme,
                      onOpenDetails: () => _runAction(
                        AssistantAction(
                          type: AssistantActionType.openPlace,
                          labelAr: 'التفاصيل',
                          labelEn: 'Details',
                          place: place,
                        ),
                      ),
                      onDirections: () => _runAction(
                        AssistantAction(
                          type: AssistantActionType.directions,
                          labelAr: 'الاتجاهات',
                          labelEn: 'Route',
                          place: place,
                        ),
                      ),
                      onCall: place.phoneNumber.isNotEmpty
                          ? () => _runAction(
                                AssistantAction(
                                  type: AssistantActionType.callPhone,
                                  labelAr: 'اتصال',
                                  labelEn: 'Call',
                                  place: place,
                                  phoneNumber: place.phoneNumber,
                                ),
                              )
                          : null,
                      onSaveFavorite: () => _runAction(
                        AssistantAction(
                          type: AssistantActionType.toggleFavorite,
                          labelAr: 'حفظ',
                          labelEn: 'Save',
                          place: place,
                          addFavorite: true,
                        ),
                      ),
                    ),
                  );
                }),
              ],

              // Concise Follow-Up Suggestions (only under latest AI response)
              if (isLastTurn &&
                  !_isProcessing &&
                  response != null &&
                  response.followUpSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: response.followUpSuggestions
                      .map(
                        (suggestion) => _MinimalSuggestionChip(
                          label: suggestion,
                          onTap: () => _handleQuery(suggestion),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveListeningBanner(
    FlutterFlowTheme theme,
    bool isEn,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.graphic_eq_rounded, color: Color(0xFFFCA5A5), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _liveTranscript.isNotEmpty
                  ? _liveTranscript
                  : (isEn ? 'Listening...' : 'جاري الاستماع...'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDock(
    FlutterFlowTheme theme,
    bool isEn,
    bool reducedMotion,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1A2B),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
      ),
      child: ResponsiveContainer(
        maxWidth: 680,
        child: _showTextInput
            ? _buildComposerRow(theme, isEn)
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DockIconButton(
                    key: const Key('voice_assistant_capabilities_btn'),
                    icon: Icons.grid_view_rounded,
                    tooltip: isEn ? 'Commands & help' : 'الأوامر والقدرات',
                    onPressed: _showCapabilitiesSheet,
                  ),
                  _PrimaryMicButton(
                    key: const Key('voice_assistant_mic_btn'),
                    controller: _pulseController,
                    isListening: _isListening,
                    isSpeaking: _isSpeaking,
                    isProcessing: _isProcessing,
                    isPaused: _micManuallyDisabled,
                    soundLevel: _soundLevel,
                    reducedMotion: reducedMotion,
                    onTap: _toggleMic,
                    semanticLabel: _isListening
                        ? (isEn ? 'Stop listening' : 'إيقاف الاستماع')
                        : _micManuallyDisabled
                            ? (isEn ? 'Enable mic' : 'تفعيل المايك')
                            : (isEn ? 'Tap to speak' : 'اضغط للتحدث'),
                  ),
                  _DockIconButton(
                    key: const Key('voice_assistant_keyboard_btn'),
                    icon: Icons.keyboard_rounded,
                    tooltip: isEn ? 'Type instead' : 'الكتابة بالنص',
                    onPressed: () {
                      _cancelPendingResume();
                      if (_isListening) {
                        try {
                          _speech.cancel();
                        } catch (_) {}
                      }
                      setState(() {
                        _isListening = false;
                        _soundLevel = 0.0;
                        _showTextInput = true;
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _textFocusNode.requestFocus();
                      });
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildComposerRow(FlutterFlowTheme theme, bool isEn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          _CompactCircleButton(
            key: const Key('voice_assistant_keyboard_btn'),
            icon: Icons.keyboard_hide_rounded,
            tooltip: isEn ? 'Voice mode' : 'العودة للصوت',
            onPressed: () {
              FocusScope.of(context).unfocus();
              setState(() => _showTextInput = false);
            },
          ),
          Expanded(
            child: TextField(
              key: const Key('voice_assistant_text_input'),
              controller: _textController,
              focusNode: _textFocusNode,
              textInputAction: TextInputAction.send,
              onSubmitted: (text) {
                if (text.trim().isEmpty) return;
                _handleQuery(text);
                _textController.clear();
              },
              style: theme.bodyMedium.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: isEn ? 'Ask anything...' : 'اكتب سؤالك هنا...',
                hintStyle: theme.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.48),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
              ),
            ),
          ),
          _CompactCircleButton(
            key: const Key('voice_assistant_mic_btn'),
            icon: _isListening ? Icons.stop_rounded : Icons.mic_none_rounded,
            tooltip: _isListening
                ? (isEn ? 'Stop listening' : 'إيقاف الاستماع')
                : (isEn ? 'Speak' : 'تحدث'),
            color: _isListening ? const Color(0xFFEF4444) : null,
            iconColor: Colors.white,
            onPressed: _toggleMic,
          ),
          const SizedBox(width: 4),
          _CompactCircleButton(
            key: const Key('voice_assistant_send_btn'),
            icon: Icons.arrow_upward_rounded,
            tooltip: isEn ? 'Send' : 'إرسال',
            color: OnewayPalette.primaryAccentOnDark,
            iconColor: Colors.white,
            onPressed: () {
              final text = _textController.text.trim();
              if (text.isEmpty) return;
              _handleQuery(text);
              _textController.clear();
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// SUB-COMPONENTS
// =============================================================================

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _DockIconButton extends StatelessWidget {
  const _DockIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(26),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.9),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactCircleButton extends StatelessWidget {
  const _CompactCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.iconColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color ?? Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              color: iconColor ?? Colors.white70,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Serene, executive-grade ambient voice presence with concentric soft halos
/// and a minimal 5-bar monochromatic equalizer (no cartoon rainbow bars,
/// no duplicate mic icon).
class _AmbientVoicePresence extends StatelessWidget {
  const _AmbientVoicePresence({
    required this.controller,
    required this.isListening,
    required this.isSpeaking,
    required this.isProcessing,
    required this.soundLevel,
    required this.reducedMotion,
    required this.onTap,
    required this.semanticLabel,
  });

  final AnimationController controller;
  final bool isListening;
  final bool isSpeaking;
  final bool isProcessing;
  final double soundLevel;
  final bool reducedMotion;
  final VoidCallback onTap;
  final String semanticLabel;

  static const _barFactors = <double>[0.45, 0.78, 1.0, 0.78, 0.45];

  @override
  Widget build(BuildContext context) {
    final accent = isListening
        ? const Color(0xFFEF4444)
        : isSpeaking
            ? const Color(0xFF38BDF8)
            : const Color(0xFF16A6A0);
    final highlight = isListening
        ? const Color(0xFFFCA5A5)
        : isSpeaking
            ? const Color(0xFF7DD3FC)
            : const Color(0xFF2DD4BF);

    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            final pulse = reducedMotion ? 0.35 : controller.value;
            final energy = isListening
                ? (0.45 + soundLevel * 0.55)
                : isSpeaking
                    ? (0.4 + pulse * 0.4)
                    : (0.15 + pulse * 0.2);
            final phase = pulse * math.pi * 2;

            return SizedBox(
              width: 152,
              height: 152,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Soft outer ambient halo
                  Container(
                    width: 136 + 14 * energy,
                    height: 136 + 14 * energy,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.08 + 0.07 * energy),
                      border: Border.all(
                        color: highlight.withValues(alpha: 0.16),
                        width: 1,
                      ),
                    ),
                  ),
                  // Core luminous orb
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.25, -0.3),
                        radius: 0.9,
                        colors: [
                          highlight.withValues(alpha: 0.95),
                          accent,
                          Color.lerp(accent, const Color(0xFF0A1524), 0.52)!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.38 * energy + 0.15),
                          blurRadius: 28 + 16 * energy,
                          spreadRadius: 2 + 4 * energy,
                        ),
                      ],
                    ),
                    child: Center(
                      child: isProcessing
                          ? const SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                for (var i = 0; i < _barFactors.length; i++)
                                  Container(
                                    width: 4,
                                    height: _eqHeight(i, phase, energy),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 2.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  double _eqHeight(int index, double phase, double energy) {
    final base = _barFactors[index];
    if (reducedMotion || (!isListening && !isSpeaking)) {
      return (10.0 + 18.0 * base).clamp(8.0, 32.0);
    }
    final wave = 0.5 + 0.5 * math.sin(phase + index * 0.9);
    return (10.0 + 28.0 * base * (0.4 + 0.6 * wave) * (0.65 + 0.35 * energy))
        .clamp(8.0, 40.0);
  }
}

/// Primary microphone trigger button in the streamlined bottom bar.
class _PrimaryMicButton extends StatelessWidget {
  const _PrimaryMicButton({
    super.key,
    required this.controller,
    required this.isListening,
    required this.isSpeaking,
    required this.isProcessing,
    required this.isPaused,
    required this.soundLevel,
    required this.reducedMotion,
    required this.onTap,
    required this.semanticLabel,
  });

  final AnimationController controller;
  final bool isListening;
  final bool isSpeaking;
  final bool isProcessing;
  final bool isPaused;
  final double soundLevel;
  final bool reducedMotion;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final activeColor = isListening
        ? const Color(0xFFEF4444)
        : isSpeaking
            ? const Color(0xFF38BDF8)
            : isPaused
                ? const Color(0xFF334155)
                : OnewayPalette.primaryAccentOnDark;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            final pulse = reducedMotion ? 0.25 : controller.value;
            final amp = isListening
                ? (0.45 + soundLevel * 0.55)
                : isSpeaking
                    ? (0.3 + pulse * 0.35)
                    : isPaused
                        ? 0.0
                        : 0.15;

            return Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor,
                border: isPaused
                    ? Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                        width: 1.5,
                      )
                    : null,
                boxShadow: isPaused
                    ? null
                    : [
                        BoxShadow(
                          color:
                              activeColor.withValues(alpha: 0.45 * amp + 0.18),
                          blurRadius: 16 + 14 * amp,
                          spreadRadius: 1 + 4 * amp,
                        ),
                      ],
              ),
              child: isProcessing
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Icon(
                      isListening || isSpeaking
                          ? Icons.stop_rounded
                          : isPaused
                              ? Icons.mic_off_rounded
                              : Icons.mic_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _MinimalSuggestionChip extends StatelessWidget {
  const _MinimalSuggestionChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({
    required this.text,
    required this.theme,
  });

  final String text;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              OnewayPalette.primaryAccentOnDark,
              OnewayPalette.primaryLightMode,
            ],
          ),
          borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(18),
            topEnd: Radius.circular(18),
            bottomStart: Radius.circular(18),
            bottomEnd: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: theme.bodyMedium.copyWith(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble({
    required this.isEn,
    required this.theme,
  });

  final bool isEn;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: OnewayPalette.primaryDarkMode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isEn
                    ? 'Analyzing your request & accessibility data...'
                    : 'المساعد الذكي يحلل طلبك ويبحث في بيانات الإتاحة...',
                style: theme.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantResponseCard extends StatelessWidget {
  const _AssistantResponseCard({
    required this.response,
    required this.isSpeaking,
    required this.isEn,
    required this.theme,
    required this.onSpeak,
    required this.onStop,
    required this.onCopy,
    required this.onActionTap,
  });

  final AIResponse response;
  final bool isSpeaking;
  final bool isEn;
  final FlutterFlowTheme theme;
  final VoidCallback onSpeak;
  final VoidCallback onStop;
  final VoidCallback onCopy;
  final ValueChanged<AssistantAction> onActionTap;

  ({IconData icon, Color color, String title}) _meta() {
    switch (response.intent) {
      case AIIntentType.emergency:
        return (
          icon: Icons.warning_rounded,
          color: theme.error,
          title: isEn ? 'Emergency Alert' : 'تنبيه طوارئ',
        );
      case AIIntentType.appControl:
        return (
          icon: Icons.tune_rounded,
          color: const Color(0xFF7C3AED),
          title: isEn ? 'App Control Applied' : 'تحكم فوري بالتطبيق',
        );
      case AIIntentType.egyptGuide:
        return (
          icon: Icons.gavel_rounded,
          color: const Color(0xFFD97706),
          title: isEn ? 'Egypt Rights & Guide' : 'دليلك وحقوقك في مصر',
        );
      case AIIntentType.userData:
        return (
          icon: Icons.account_circle_rounded,
          color: const Color(0xFF0284C7),
          title: isEn ? 'Your Account & Location' : 'بياناتك وموقعك',
        );
      case AIIntentType.navigation:
        return (
          icon: Icons.explore_rounded,
          color: theme.primary,
          title: isEn ? 'Navigation' : 'تنقل داخل التطبيق',
        );
      case AIIntentType.placeAction:
      case AIIntentType.placeDetails:
      case AIIntentType.placeSearch:
        return (
          icon: Icons.accessible_forward_rounded,
          color: theme.primary,
          title: isEn ? 'Accessibility Assistant' : 'مساعد الإتاحة الذكي',
        );
      case AIIntentType.generalInfo:
        return (
          icon: Icons.auto_awesome_rounded,
          color: theme.primary,
          title: isEn ? 'ONEWAY Assistant' : 'مساعد ONEWAY',
        );
    }
  }

  IconData _actionIcon(String? hint) {
    switch (hint) {
      case 'phone':
        return Icons.phone_rounded;
      case 'directions':
        return Icons.directions_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'map':
        return Icons.map_rounded;
      case 'sos':
        return Icons.emergency_rounded;
      case 'guide':
        return Icons.menu_book_rounded;
      case 'settings':
        return Icons.tune_rounded;
      case 'report':
        return Icons.report_problem_rounded;
      case 'link':
        return Icons.open_in_new_rounded;
      case 'place':
        return Icons.place_rounded;
      default:
        return Icons.bolt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = _meta();
    final isEmergency = response.intent == AIIntentType.emergency;

    return Container(
      decoration: BoxDecoration(
        color: isEmergency
            ? const Color(0xFF2B1722)
            : const Color(0xFF14263C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEmergency
              ? theme.error.withValues(alpha: 0.75)
              : Colors.white.withValues(alpha: 0.1),
          width: isEmergency ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  meta.icon,
                  color: isEmergency
                      ? const Color(0xFFFCA5A5)
                      : OnewayPalette.primaryDarkMode,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  meta.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelLarge.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isEmergency
                        ? const Color(0xFFFCA5A5)
                        : Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
              IconButton(
                tooltip: isEn ? 'Copy' : 'نسخ',
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.copy_rounded,
                  size: 17,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
                onPressed: onCopy,
              ),
              IconButton(
                tooltip: isSpeaking
                    ? (isEn ? 'Stop audio' : 'إيقاف الصوت')
                    : (isEn ? 'Read aloud' : 'استماع للرد'),
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                icon: Icon(
                  isSpeaking
                      ? Icons.stop_circle_rounded
                      : Icons.volume_up_rounded,
                  size: 20,
                  color: isSpeaking
                      ? const Color(0xFFFCA5A5)
                      : OnewayPalette.primaryDarkMode,
                ),
                onPressed: isSpeaking ? onStop : onSpeak,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            response.replyText,
            style: theme.bodyMedium.copyWith(
              fontSize: 14.5,
              height: 1.65,
              color: Colors.white.withValues(alpha: 0.94),
            ),
          ),
          if (response.quickActions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: response.quickActions.map((act) {
                final isCallOrSos = act.type == AssistantActionType.callPhone ||
                    act.type == AssistantActionType.triggerSos;
                final tint = isCallOrSos
                    ? const Color(0xFFFCA5A5)
                    : OnewayPalette.primaryDarkMode;
                return OutlinedButton.icon(
                  onPressed: () => onActionTap(act),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(44, 38),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    foregroundColor: tint,
                    backgroundColor: tint.withValues(alpha: 0.1),
                    side: BorderSide(color: tint.withValues(alpha: 0.35)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(_actionIcon(act.iconName), size: 16),
                  label: Text(
                    act.label(isEnglish: isEn),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _EnrichedPlaceCard extends StatelessWidget {
  const _EnrichedPlaceCard({
    required this.match,
    required this.indexNumber,
    required this.isEn,
    required this.theme,
    required this.onOpenDetails,
    required this.onDirections,
    required this.onSaveFavorite,
    this.onCall,
  });

  final PlaceMatch match;
  final int indexNumber;
  final bool isEn;
  final FlutterFlowTheme theme;
  final VoidCallback onOpenDetails;
  final VoidCallback onDirections;
  final VoidCallback onSaveFavorite;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final place = match.place;
    final f = place.accessibilityFeatures;
    final distanceLabel = match.formattedDistance(isEnglish: isEn);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF172C45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpenDetails,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: OnewayPalette.primaryAccentOnDark
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '$indexNumber',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: OnewayPalette.primaryDarkMode,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: theme.titleMedium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (place.category.isNotEmpty) place.category,
                              if (place.city.isNotEmpty) place.city,
                              if (distanceLabel != null) distanceLabel,
                            ].join(' • '),
                            style: theme.bodySmall.copyWith(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    CompatibilityBadge(
                        result: match.compatibility, compact: true),
                  ],
                ),
                const SizedBox(height: 10),

                // Feature Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (f.hasRamp() && f.ramp)
                      _MiniChip(
                        label: isEn ? 'Ramp' : 'منحدر',
                        color: const Color(0xFF4ADE80),
                      ),
                    if (f.hasSuitableElevator() && f.suitableElevator)
                      _MiniChip(
                        label: isEn ? 'Elevator' : 'مصعد',
                        color: const Color(0xFF38BDF8),
                      ),
                    if (f.hasAccessibleRestroom() && f.accessibleRestroom)
                      _MiniChip(
                        label: isEn ? 'Restroom' : 'حمام مجهز',
                        color: OnewayPalette.primaryDarkMode,
                      ),
                    if (f.hasWheelchairEntrance() && f.wheelchairEntrance)
                      _MiniChip(
                        label: isEn ? 'Entrance' : 'مدخل',
                        color: const Color(0xFFC4B5FD),
                      ),
                    if (f.hasAccessibleParking() && f.accessibleParking)
                      _MiniChip(
                        label: isEn ? 'Parking' : 'موقف',
                        color: const Color(0xFFFCD34D),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Compact One-Tap Place Actions
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _CardActionButton(
                      icon: Icons.info_outline_rounded,
                      label: isEn ? 'Details' : 'التفاصيل',
                      color: OnewayPalette.primaryAccentOnDark,
                      filled: true,
                      onTap: onOpenDetails,
                    ),
                    if (place.hasLocation())
                      _CardActionButton(
                        icon: Icons.directions_rounded,
                        label: isEn ? 'Route' : 'الاتجاهات',
                        color: const Color(0xFF38BDF8),
                        onTap: onDirections,
                      ),
                    if (onCall != null)
                      _CardActionButton(
                        icon: Icons.phone_rounded,
                        label: isEn ? 'Call' : 'اتصال',
                        color: const Color(0xFF4ADE80),
                        onTap: onCall!,
                      ),
                    _CardActionButton(
                      icon: Icons.favorite_border_rounded,
                      label: isEn ? 'Save' : 'مفضلة',
                      color: const Color(0xFFFDA4AF),
                      onTap: onSaveFavorite,
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

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: filled ? Colors.white : color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// A single step inside the interactive Home Dashboard Spotlight Tour.
class SpotlightTourStep {
  const SpotlightTourStep({
    required this.id,
    required this.targetKey,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.icon,
    this.highlightRadius = 20,
    this.highlightPadding = 6,
  });

  final String id;
  final GlobalKey targetKey;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final IconData icon;
  final double highlightRadius;
  final double highlightPadding;
}

/// Persists per-account tour completion and coordinates on-demand replay
/// triggered from Settings -> Quick Usage Guide.
class HomeTourController {
  HomeTourController._();

  static final HomeTourController instance = HomeTourController._();

  static const String _prefPrefix = 'oneway_home_spotlight_tour_seen_v1_';

  /// Incremented whenever the user taps "Replay Interactive Tour" in Settings.
  final ValueNotifier<int> replayNonce = ValueNotifier<int>(0);

  /// Pending replay flag so if HomeDashboard is mounted freshly after
  /// `context.goNamed('HomeDashboard')`, it starts the tour immediately.
  bool _pendingReplay = false;

  bool consumePendingReplay() {
    if (!_pendingReplay) return false;
    _pendingReplay = false;
    return true;
  }

  /// Requests an immediate replay of the Spotlight Tour on HomeDashboard.
  void requestReplay() {
    _pendingReplay = true;
    replayNonce.value++;
  }

  String _keyForUid(String uid) =>
      '$_prefPrefix${uid.trim().isEmpty ? 'default' : uid.trim()}';

  Future<bool> hasSeenTour(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyForUid(uid)) == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> markTourSeen(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyForUid(uid), true);
    } catch (_) {}
  }

  @visibleForTesting
  void resetForTesting() {
    _pendingReplay = false;
    replayNonce.value = 0;
  }
}

/// Interactive Spotlight Coach-Marks Overlay with optional Arabic/English TTS
/// narration so both sighted and non-reading users learn ONEWAY's core buttons.
class HomeSpotlightTourOverlay extends StatefulWidget {
  const HomeSpotlightTourOverlay({
    super.key,
    required this.steps,
    required this.onFinished,
    this.isEnglish = false,
    this.initialVoiceEnabled = true,
    this.enableTts = true,
  });

  final List<SpotlightTourStep> steps;
  final VoidCallback onFinished;
  final bool isEnglish;
  final bool initialVoiceEnabled;
  final bool enableTts;

  @override
  State<HomeSpotlightTourOverlay> createState() =>
      _HomeSpotlightTourOverlayState();
}

class _HomeSpotlightTourOverlayState extends State<HomeSpotlightTourOverlay>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Rect? _targetRect;
  late bool _voiceEnabled;
  FlutterTts? _tts;
  bool _isSpeaking = false;
  late AnimationController _pulseController;

  SpotlightTourStep get _step => widget.steps[_currentIndex];

  @override
  void initState() {
    super.initState();
    _voiceEnabled = widget.initialVoiceEnabled;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    if (widget.enableTts) {
      _initTts();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusCurrentStep();
    });
  }

  Future<void> _initTts() async {
    try {
      final tts = FlutterTts();
      await tts.setSpeechRate(0.48);
      await tts.setPitch(1.0);
      await tts.setLanguage(widget.isEnglish ? 'en-US' : 'ar-EG');
      tts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      tts.setErrorHandler((_) {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _tts = tts;
      if (_voiceEnabled && mounted) {
        unawaited(_speakStep(_step));
      }
    } catch (_) {
      // Gracefully skip TTS on platforms/tests without native TTS channel.
      _tts = null;
    }
  }

  Future<void> _speakStep(SpotlightTourStep step) async {
    if (!_voiceEnabled || !widget.enableTts || _tts == null) return;
    final title = widget.isEnglish ? step.titleEn : step.titleAr;
    final desc = widget.isEnglish ? step.descriptionEn : step.descriptionAr;
    final spoken = '$title. $desc';
    try {
      await _tts!.stop();
      if (mounted) setState(() => _isSpeaking = true);
      await _tts!.speak(spoken);
    } catch (_) {
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  Future<void> _stopTts() async {
    try {
      await _tts?.stop();
    } catch (_) {}
    if (mounted && _isSpeaking) {
      setState(() => _isSpeaking = false);
    }
  }

  Future<void> _focusCurrentStep() async {
    if (!mounted) return;
    final step = _step;
    final targetCtx = step.targetKey.currentContext;

    if (targetCtx != null) {
      try {
        await Scrollable.ensureVisible(
          targetCtx,
          alignment: 0.28,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }

    if (!mounted) return;
    final measured = _measureTarget(step);
    setState(() => _targetRect = measured);

    final title = widget.isEnglish ? step.titleEn : step.titleAr;
    final desc = widget.isEnglish ? step.descriptionEn : step.descriptionAr;
    try {
      final view = View.of(context);
      SemanticsService.sendAnnouncement(
        view,
        '$title. $desc',
        widget.isEnglish ? TextDirection.ltr : TextDirection.rtl,
      );
    } catch (_) {}

    if (_voiceEnabled) {
      unawaited(_speakStep(step));
    }
  }

  Rect? _measureTarget(SpotlightTourStep step) {
    final targetCtx = step.targetKey.currentContext;
    if (targetCtx == null) return null;
    final renderObj = targetCtx.findRenderObject();
    if (renderObj is! RenderBox || !renderObj.hasSize) return null;
    final topLeft = renderObj.localToGlobal(Offset.zero);
    final raw = topLeft & renderObj.size;
    return raw.inflate(step.highlightPadding);
  }

  void _next() {
    if (_currentIndex + 1 < widget.steps.length) {
      unawaited(_stopTts());
      setState(() => _currentIndex++);
      unawaited(_focusCurrentStep());
    } else {
      _finish();
    }
  }

  void _previous() {
    if (_currentIndex > 0) {
      unawaited(_stopTts());
      setState(() => _currentIndex--);
      unawaited(_focusCurrentStep());
    }
  }

  void _toggleVoice() {
    setState(() => _voiceEnabled = !_voiceEnabled);
    if (_voiceEnabled) {
      unawaited(_speakStep(_step));
    } else {
      unawaited(_stopTts());
    }
  }

  void _finish() {
    unawaited(_stopTts());
    widget.onFinished();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tts?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final step = _step;
    final isEn = widget.isEnglish;
    final isLast = _currentIndex == widget.steps.length - 1;
    final rect = _targetRect;

    // Decide whether the explanation card goes below or above the spotlighted widget
    final bool placeCardAbove =
        rect != null && rect.center.dy > size.height * 0.52;

    final double topSafe = mq.padding.top + 16;
    final double bottomSafe = mq.padding.bottom + 16;

    double? cardTop;
    double? cardBottom;
    if (rect == null) {
      cardBottom = bottomSafe + 24;
    } else if (placeCardAbove) {
      final spaceAbove = rect.top - topSafe - 16;
      if (spaceAbove >= 210) {
        cardBottom = (size.height - rect.top) + 14;
      } else {
        cardTop = topSafe;
      }
    } else {
      final spaceBelow = size.height - rect.bottom - bottomSafe - 16;
      if (spaceBelow >= 210) {
        cardTop = rect.bottom + 14;
      } else {
        cardBottom = bottomSafe;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Dimmed backdrop with luminous cutout around target widget
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _next,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => CustomPaint(
                    painter: _SpotlightHolePainter(
                      holeRect: rect,
                      radius: step.highlightRadius,
                      borderColor: theme.primary,
                      pulse: _pulseController.value,
                    ),
                  ),
                ),
              ),
            ),

            // Floating explanation card
            Positioned(
              left: 16,
              right: 16,
              top: cardTop,
              bottom: cardBottom,
              child: SafeArea(
                top: cardTop == null,
                bottom: cardBottom == null,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 440,
                    maxHeight: size.height * 0.56,
                  ),
                  child: SingleChildScrollView(
                    child: Container(
                      key: const Key('spotlight_tour_card'),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: theme.primary.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header row: step counter, voice toggle, skip
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  isEn
                                      ? 'Step ${_currentIndex + 1} of ${widget.steps.length}'
                                      : 'خطوة ${_currentIndex + 1} من ${widget.steps.length}',
                                  style: TextStyle(
                                    color: theme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                key: const Key('spotlight_voice_toggle_btn'),
                                onPressed: _toggleVoice,
                                tooltip: _voiceEnabled
                                    ? (isEn ? 'Mute voice guide' : 'كتم القراءة الصوتية')
                                    : (isEn ? 'Listen to step' : 'سماع الشرح بالصوت'),
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  _voiceEnabled
                                      ? Icons.volume_up_rounded
                                      : Icons.volume_off_rounded,
                                  color: _voiceEnabled
                                      ? theme.primary
                                      : theme.secondaryText,
                                  size: 22,
                                ),
                              ),
                              TextButton(
                                key: const Key('spotlight_skip_btn'),
                                onPressed: _finish,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  minimumSize: const Size(0, 36),
                                ),
                                child: Text(
                                  isEn ? 'Skip' : 'تخطي',
                                  style: TextStyle(
                                    color: theme.secondaryText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Icon + Title
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: theme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  step.icon,
                                  color: theme.primary,
                                  size: 23,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isEn ? step.titleEn : step.titleAr,
                                  style: theme.titleMedium.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: theme.primaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Description
                          Text(
                            isEn ? step.descriptionEn : step.descriptionAr,
                            style: theme.bodyMedium.copyWith(
                              fontSize: 14,
                              color: theme.secondaryText,
                              height: 1.55,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Progress dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(widget.steps.length, (i) {
                              final active = i == _currentIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                width: active ? 22 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: active
                                      ? theme.primary
                                      : theme.outlineVariant,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 14),

                          // Navigation buttons
                          Row(
                            children: [
                              if (_currentIndex > 0) ...[
                                OutlinedButton(
                                  key: const Key('spotlight_prev_btn'),
                                  onPressed: _previous,
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(84, 44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(isEn ? 'Back' : 'السابق'),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: FilledButton.icon(
                                  key: const Key('spotlight_next_btn'),
                                  onPressed: _next,
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: Icon(
                                    isLast
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    isLast
                                        ? (isEn ? 'Start Exploring' : 'ابدأ الاستخدام')
                                        : (isEn ? 'Next' : 'التالي'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightHolePainter extends CustomPainter {
  const _SpotlightHolePainter({
    required this.holeRect,
    required this.radius,
    required this.borderColor,
    required this.pulse,
  });

  final Rect? holeRect;
  final double radius;
  final Color borderColor;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.72);

    if (holeRect == null) {
      canvas.drawRect(fullRect, overlayPaint);
      return;
    }

    final rrect = RRect.fromRectAndRadius(holeRect!, Radius.circular(radius));
    final cutoutPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(fullRect)
      ..addRRect(rrect);

    canvas.drawPath(cutoutPath, overlayPaint);

    // Glowing ring around the highlighted real widget
    final glowPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.45 + 0.35 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 + (pulse * 2.5);
    canvas.drawRRect(rrect.inflate(1.5), glowPaint);

    final crispBorder = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, crispBorder);
  }

  @override
  bool shouldRepaint(covariant _SpotlightHolePainter oldDelegate) {
    return oldDelegate.holeRect != holeRect ||
        oldDelegate.radius != radius ||
        oldDelegate.pulse != pulse ||
        oldDelegate.borderColor != borderColor;
  }
}

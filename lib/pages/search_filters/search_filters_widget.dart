import '/components/accessibility_toggle/accessibility_toggle_widget.dart';
import '/components/button/button_widget.dart';
import '/components/checkbox/checkbox_widget.dart';
import '/components/filter_chip/filter_chip_widget.dart';
import '/components/slider/slider_widget.dart';
import '/components/text_field/text_field_widget.dart';
import '/features/ai/oneway_ai_engine.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'search_filters_model.dart';
export 'search_filters_model.dart';

class SearchFiltersWidget extends StatefulWidget {
  const SearchFiltersWidget({super.key});

  static String routeName = 'SearchFilters';
  static String routePath = '/search';

  @override
  State<SearchFiltersWidget> createState() => _SearchFiltersWidgetState();
}

class _SearchFiltersWidgetState extends State<SearchFiltersWidget>
    with SingleTickerProviderStateMixin {
  late SearchFiltersModel _model;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SearchFiltersModel());
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _animationController.forward();
    _initSpeechToText();
  }

  Future<void> _initSpeechToText() async {
    _model.speechToText = stt.SpeechToText();
    await _model.speechToText!.initialize(
      onError: (error) => debugPrint('Speech recognition error: $error'),
      onStatus: (status) => debugPrint('Speech recognition status: $status'),
    );
  }

  Future<void> _startVoiceSearch() async {
    if (_model.isListening) {
      await _stopVoiceSearch();
      return;
    }

    final available = await _model.speechToText!.initialize();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('التعرف على الصوت غير متاح على هذا الجهاز')),
        );
      }
      return;
    }

    safeSetState(() {
      _model.isListening = true;
      _model.voiceSearchQuery = '';
    });

    _model.speechToText!.listen(
      onResult: (result) {
        safeSetState(() {
          _model.voiceSearchQuery = result.recognizedWords;
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'ar_EG',
      cancelOnError: true,
      partialResults: true,
    );
  }

  Future<void> _stopVoiceSearch() async {
    await _model.speechToText!.stop();
    safeSetState(() {
      _model.isListening = false;
    });

    if (_model.voiceSearchQuery.isNotEmpty) {
      _processVoiceQuery(_model.voiceSearchQuery);
    }
  }

  void _processVoiceQuery(String query) {
    // Navigate to voice assistant interface with the query
    context.pushNamed(
      VoiceAssistantInterfaceWidget.routeName,
      extra: {'initialQuery': query},
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
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
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Header
                Container(
                  decoration: BoxDecoration(
                    color: theme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: theme.outlineVariant,
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _MapActionButton(
                            icon: Icons.arrow_forward_rounded,
                            onPressed: () => context.goNamed(HomeDashboardWidget.routeName),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'بحث عن أماكن',
                            style: theme.titleLarge.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: theme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Search bar
                      Row(
                        children: [
                          Expanded(
                            child: _SearchField(
                              hint: 'ابحث عن مطعم، مستشفى، أو مول...',
                              onTap: () => context.goNamed(VoiceAssistantInterfaceWidget.routeName),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _MapActionButton(
                            icon: _model.isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                            backgroundColor: _model.isListening ? Colors.red : theme.primary,
                            onPressed: _startVoiceSearch,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Filters
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                          theme,
                          'التصنيف',
                          _buildCategoryChips(theme),
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          theme,
                          'متطلبات الإتاحة',
                          _buildAccessibilityToggles(theme),
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          theme,
                          'الموقع',
                          _buildLocationDropdown(theme),
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          theme,
                          'المسافة القصوى',
                          _buildDistanceSlider(theme),
                        ),
                        const SizedBox(height: 24),
                        _buildSection(
                          theme,
                          'حالة التحقق',
                          _buildVerificationFilter(theme),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom Actions
                Container(
                  decoration: BoxDecoration(
                    color: theme.surface,
                    border: Border(
                      top: BorderSide(
                        color: theme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 20,
                        color: theme.shadow.withValues(alpha: 0.1),
                        offset: const Offset(0, -4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: ButtonWidget(
                          content: 'إعادة ضبط',
                          variant: 'outline',
                          size: 'medium',
                          fullWidth: true,
                          onPressed: _resetFilters,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ButtonWidget(
                          content: 'عرض النتائج',
                          variant: 'primary',
                          size: 'medium',
                          fullWidth: true,
                          onPressed: () => context.goNamed(ExploreMapWidget.routeName),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(FlutterFlowTheme theme, String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.titleMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildCategoryChips(FlutterFlowTheme theme) {
    final categories = [
      {'label': 'الكل', 'active': true},
      {'label': 'مطاعم', 'active': true},
      {'label': 'مستشفيات', 'active': true},
      {'label': 'فنادق', 'active': true},
      {'label': 'مراكز تسوق', 'active': true},
      {'label': 'بنوك', 'active': true},
      {'label': 'حدائق', 'active': true},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        return FilterChipWidget(
          label: cat['label'] as String,
          active: cat['active'] as bool,
          onTap: () {},
        );
      }).toList(),
    );
  }

  Widget _buildAccessibilityToggles(FlutterFlowTheme theme) {
    return Column(
      children: [
        AccessibilityToggleWidget(
          icon: Icon(
            Icons.wheelchair_pickup_rounded,
            color: theme.secondary,
            size: 22,
          ),
          label: 'مدخل كراسي متحركة',
          active: true,
        ),
        const SizedBox(height: 12),
        AccessibilityToggleWidget(
          icon: Icon(
            Icons.elevator_rounded,
            color: theme.secondary,
            size: 22,
          ),
          label: 'وجود مصعد',
          active: true,
        ),
        const SizedBox(height: 12),
        AccessibilityToggleWidget(
          icon: Icon(
            Icons.accessible_rounded,
            color: theme.secondary,
            size: 22,
          ),
          label: 'دورة مياه مجهزة',
          active: true,
        ),
        const SizedBox(height: 12),
        AccessibilityToggleWidget(
          icon: Icon(
            Icons.ramp_left_rounded,
            color: theme.secondary,
            size: 22,
          ),
          label: 'رصيف مائل (Ramp)',
          active: true,
        ),
        const SizedBox(height: 12),
        AccessibilityToggleWidget(
          icon: Icon(
            Icons.local_parking_rounded,
            color: theme.secondary,
            size: 22,
          ),
          label: 'موقف سيارات مخصص',
          active: true,
        ),
      ],
    );
  }

  Widget _buildLocationDropdown(FlutterFlowTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FlutterFlowDropDown<String>(
        controller: _model.dropdownValueController ??=
            FormFieldController<String>(_model.dropdownValue ??= 'القاهرة'),
        options: const [
          'القاهرة',
          'الجيزة',
          'الإسكندرية',
          'القليوبية'
        ],
        onChanged: (val) => safeSetState(() => _model.dropdownValue = val),
        width: double.infinity,
        height: 52,
        textStyle: theme.bodyMedium.copyWith(
          fontSize: 15,
          color: theme.primaryText,
        ),
        hintText: 'القاهرة',
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: theme.secondaryText,
          size: 24,
        ),
        fillColor: theme.surface,
        elevation: 2,
        borderColor: theme.outlineVariant,
        borderWidth: 1.5,
        borderRadius: theme.designToken.radius.xl,
        margin: EdgeInsets.zero,
        hidesUnderline: true,
        isOverButton: false,
        isSearchable: false,
        isMultiSelect: false,
      ),
    );
  }

  Widget _buildDistanceSlider(FlutterFlowTheme theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'المسافة القصوى',
              style: theme.titleMedium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
              ),
            ),
            Text(
              '15 كم',
              style: theme.labelLarge.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderWidget(
          label: '',
          labelPresent: false,
          description: '',
          descriptionPresent: false,
          valueLabel: '',
          valueLabelPresent: false,
          step: 0.0,
          divisions: 0,
          valuePercentage: 60.0,
          color: theme.secondary,
          variant: 'Material',
          disabled: false,
          showTicks: true,
        ),
      ],
    );
  }

  Widget _buildVerificationFilter(FlutterFlowTheme theme) {
    return Row(
      children: [
        Expanded(
          child: wrapWithModel(
            model: _model.checkboxModel,
            updateCallback: () => safeSetState(() {}),
            child: CheckboxWidget(
              label: 'تم التحقق فقط',
              subtitle: 'أماكن راجعها فريقنا',
              color: theme.primary,
              isChecked: true,
              hasSubtitle: true,
              disabled: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _SearchField({required String hint, required VoidCallback onTap}) {
    final theme = FlutterFlowTheme.of(context);
    final isListening = _model.isListening;
    final voiceQuery = _model.voiceSearchQuery;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isListening ? null : onTap,
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        splashColor: theme.primary.withValues(alpha: 0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isListening ? theme.primary.withValues(alpha: 0.1) : theme.surface,
            borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
            border: Border.all(
              color: isListening ? theme.primary : theme.outlineVariant,
              width: isListening ? 2 : 1.5,
            ),
            boxShadow: isListening
                ? [
                    BoxShadow(
                      color: theme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : [theme.designToken.shadow.xs],
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isListening
                    ? Icon(
                        Icons.mic_rounded,
                        key: const ValueKey('mic'),
                        color: theme.primary,
                        size: 24,
                      )
                    : Icon(
                        Icons.search_rounded,
                        key: const ValueKey('search'),
                        color: theme.secondaryText,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isListening
                      ? (voiceQuery.isEmpty ? 'جاري الاستماع... تكلم الآن' : voiceQuery)
                      : hint,
                  style: theme.bodyMedium.copyWith(
                    fontSize: 15,
                    color: isListening ? theme.primary : theme.hintText,
                    fontWeight: isListening ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isListening)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetFilters() {
    // Reset all filter states
    safeSetState(() {
      _model.dropdownValue = 'القاهرة';
      // Reset other filters
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إعادة ضبط الفلاتر'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    this.backgroundColor,
    required this.onPressed,
  });

  final IconData icon;
  final Color? backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bgColor = backgroundColor ?? theme.surfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(theme.designToken.radius.full),
        splashColor: theme.primary.withValues(alpha: 0.1),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(theme.designToken.radius.full),
            boxShadow: bgColor == theme.primary ? [theme.designToken.shadow.sm] : null,
          ),
          child: Icon(
            icon,
            color: backgroundColor != null ? theme.onPrimary : theme.primaryText,
            size: 24,
          ),
        ),
      ),
    );
  }
}
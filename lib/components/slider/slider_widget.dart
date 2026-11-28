import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'slider_model.dart';
export 'slider_model.dart';

class SliderWidget extends StatefulWidget {
  const SliderWidget({
    super.key,
    String? label,
    bool? labelPresent,
    String? description,
    bool? descriptionPresent,
    String? valueLabel,
    bool? valueLabelPresent,
    double? step,
    int? divisions,
    double? valuePercentage,
    Color? color,
    String? variant,
    bool? disabled,
    bool? showTicks,
    this.onChanged,
  })  : label = label ?? '',
        labelPresent = labelPresent ?? false,
        description = description ?? '',
        descriptionPresent = descriptionPresent ?? false,
        valueLabel = valueLabel ?? '',
        valueLabelPresent = valueLabelPresent ?? false,
        step = step ?? 0.0,
        divisions = divisions ?? 0,
        valuePercentage = valuePercentage ?? 60.0,
        color = color ?? const Color(0x00000000),
        variant = variant ?? 'Material',
        disabled = disabled ?? false,
        showTicks = showTicks ?? true;

  final String label;
  final bool labelPresent;
  final String description;
  final bool descriptionPresent;
  final String valueLabel;
  final bool valueLabelPresent;
  final double step;
  final int divisions;
  final double valuePercentage;
  final Color color;
  final String variant;
  final bool disabled;
  final bool showTicks;
  final ValueChanged<double>? onChanged;

  @override
  State<SliderWidget> createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget> {
  late SliderModel _model;
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SliderModel());
    _currentValue = widget.valuePercentage;

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final activeColor = widget.color.value == 0x00000000 ? theme.secondary : widget.color;
    final isDisabled = widget.disabled;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Label and Value
          if (widget.labelPresent || widget.valueLabelPresent)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.labelPresent)
                  Expanded(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.labelLarge.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryText,
                      ),
                    ),
                  ),
                if (widget.valueLabelPresent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(theme.designToken.radius.full),
                    ),
                    child: Text(
                      widget.valueLabel.isEmpty
                          ? '${_currentValue.toInt()}%'
                          : widget.valueLabel,
                      style: theme.labelMedium.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: activeColor,
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: activeColor,
              inactiveTrackColor: theme.outlineVariant,
              thumbColor: activeColor,
              overlayColor: activeColor.withValues(alpha: 0.15),
              valueIndicatorColor: activeColor,
              valueIndicatorTextStyle: theme.labelSmall.copyWith(
                fontSize: 11,
                color: theme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              tickMarkShape: widget.showTicks
                  ? const RoundSliderTickMarkShape(tickMarkRadius: 3)
                  : null,
              activeTickMarkColor: activeColor,
              inactiveTickMarkColor: theme.outlineVariant,
            ),
            child: Slider(
              min: 0.0,
              max: 100.0,
              value: _currentValue.clamp(0.0, 100.0),
              divisions: widget.divisions > 0 ? widget.divisions : null,
              onChanged: isDisabled
                  ? null
                  : (newValue) {
                      newValue = double.parse(newValue.toStringAsFixed(2));
                      safeSetState(() => _currentValue = newValue);
                      widget.onChanged?.call(newValue);
                    },
            ),
          ),
          // Description
          if (widget.descriptionPresent && widget.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.bodySmall.copyWith(
                  fontSize: 12,
                  color: theme.tertiaryText,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
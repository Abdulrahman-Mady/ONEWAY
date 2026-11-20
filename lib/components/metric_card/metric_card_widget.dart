import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'metric_card_model.dart';
export 'metric_card_model.dart';

class MetricCardWidget extends StatefulWidget {
  const MetricCardWidget({
    super.key,
    this.icon,
    String? label,
    Color? tone,
    String? value,
  })  : label = label ?? 'المشاهدات',
        tone = tone ?? const Color(0x00000000),
        value = value ?? '1,240';

  final Widget? icon;
  final String label;
  final Color tone;
  final String value;

  @override
  State<MetricCardWidget> createState() => _MetricCardWidgetState();
}

class _MetricCardWidgetState extends State<MetricCardWidget> {
  late MetricCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MetricCardModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final toneColor = widget.tone.value == 0x00000000 ? theme.primary : widget.tone;

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        border: Border.all(color: theme.outlineVariant, width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconTheme(
                data: IconThemeData(
                  color: toneColor,
                  size: 24,
                ),
                child: widget.icon ?? const Icon(Icons.visibility_rounded),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: toneColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(theme.designToken.radius.full),
                ),
                child: Text(
                  widget.label,
                  style: theme.labelSmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: toneColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.value,
            style: theme.headlineMedium.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}
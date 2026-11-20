import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'accessibility_chip_model.dart';
export 'accessibility_chip_model.dart';

class AccessibilityChipWidget extends StatefulWidget {
  const AccessibilityChipWidget({
    super.key,
    this.icon,
    String? label,
    Color? tone,
  })  : label = label ?? 'مدخل مجهز',
        tone = tone ?? const Color(0x00000000);

  final Widget? icon;
  final String label;
  final Color tone;

  @override
  State<AccessibilityChipWidget> createState() =>
      _AccessibilityChipWidgetState();
}

class _AccessibilityChipWidgetState extends State<AccessibilityChipWidget> {
  late AccessibilityChipModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AccessibilityChipModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: valueOrDefault<Color>(
          widget.tone,
          const Color(0x00000000),
        ),
        shape: BoxShape.rectangle,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          widget.icon!,
          Text(
            valueOrDefault<String>(
              widget.label,
              'مدخل مجهز',
            ),
            style: FlutterFlowTheme.of(context).labelSmall.override(
                  font: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelSmall.fontStyle,
                  ),
                  color: valueOrDefault<Color>(
                    widget.tone,
                    const Color(0x00000000),
                  ),
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                  fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                  lineHeight: 1.2,
                ),
          ),
        ].divide(const SizedBox(width: 4.0)),
      ),
    );
  }
}

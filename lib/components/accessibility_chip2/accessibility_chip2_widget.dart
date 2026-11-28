import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'accessibility_chip2_model.dart';
export 'accessibility_chip2_model.dart';

class AccessibilityChip2Widget extends StatefulWidget {
  const AccessibilityChip2Widget({
    super.key,
    this.icon,
    String? label,
    bool? available,
  })  : label = label ?? 'مدخل مجهز',
        available = available ?? true;

  final Widget? icon;
  final String label;
  final bool available;

  @override
  State<AccessibilityChip2Widget> createState() => _AccessibilityChip2WidgetState();
}

class _AccessibilityChip2WidgetState extends State<AccessibilityChip2Widget> {
  late AccessibilityChip2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AccessibilityChip2Model());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isAvailable = widget.available;

    return Container(
      decoration: BoxDecoration(
        color: isAvailable ? theme.successContainer : theme.surfaceVariant,
        borderRadius: BorderRadius.circular(theme.designToken.radius.md),
        border: Border.all(
          color: isAvailable ? theme.success : theme.outlineVariant,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconTheme(
            data: IconThemeData(
              size: 18,
              color: isAvailable ? theme.success : theme.onSurfaceVariant,
            ),
            child: widget.icon ?? const Icon(Icons.check_circle_rounded),
          ),
          const SizedBox(width: 8),
          Text(
            widget.label,
            style: theme.labelMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isAvailable ? theme.success : theme.onSurfaceVariant,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
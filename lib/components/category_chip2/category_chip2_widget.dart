import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'category_chip2_model.dart';
export 'category_chip2_model.dart';

class CategoryChip2Widget extends StatefulWidget {
  const CategoryChip2Widget({
    super.key,
    this.icon,
    String? label,
    bool? selected,
  })  : label = label ?? 'مدخل غير مناسب',
        selected = selected ?? true;

  final Widget? icon;
  final String label;
  final bool selected;

  @override
  State<CategoryChip2Widget> createState() => _CategoryChip2WidgetState();
}

class _CategoryChip2WidgetState extends State<CategoryChip2Widget> {
  late CategoryChip2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CategoryChip2Model());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isSelected = widget.selected;

    return AnimatedContainer(
      duration: theme.designToken.animation.normal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? theme.secondary : theme.surface,
        borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
        border: Border.all(
          color: isSelected ? theme.secondary : theme.outlineVariant,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme(
            data: IconThemeData(
              size: 18,
              color: isSelected ? theme.onSecondary : theme.onSurfaceVariant,
            ),
            child: widget.icon ?? const Icon(Icons.category_rounded),
          ),
          const SizedBox(width: 8),
          Text(
            widget.label,
            style: theme.labelMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? theme.onSecondary : theme.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}
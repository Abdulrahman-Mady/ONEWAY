import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'category_chip_model.dart';
export 'category_chip_model.dart';

class CategoryChipWidget extends StatefulWidget {
  const CategoryChipWidget({
    super.key,
    this.icon,
    String? label,
    String? target,
    this.onTap,
    this.isSelected = false,
  })  : label = label ?? 'مرافق عامة',
        target = target ?? 'ExploreMap';

  final Widget? icon;
  final String label;
  final String target;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  State<CategoryChipWidget> createState() => _CategoryChipWidgetState();
}

class _CategoryChipWidgetState extends State<CategoryChipWidget>
    with SingleTickerProviderStateMixin {
  late CategoryChipModel _model;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CategoryChipModel());
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(CategoryChipWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      _animationController.forward().then((_) => _animationController.reverse());
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isSelected = widget.isSelected;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap ?? () {
            context.pushNamed(ExploreMapWidget.routeName);
          },
          borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
          splashColor: theme.primary.withValues(alpha: 0.1),
          highlightColor: theme.primary.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: theme.designToken.animation.normal,
            curve: theme.designToken.animation.standard,
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
              color: isSelected ? theme.primary : theme.surface,
              border: Border.all(
                color: isSelected ? theme.primary : theme.outlineVariant,
                width: isSelected ? 0 : 1.5,
              ),
              boxShadow: isSelected
                  ? [theme.designToken.shadow.primaryMd]
                  : [theme.designToken.shadow.xs],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: theme.designToken.animation.normal,
                  curve: theme.designToken.animation.standard,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.onPrimary.withValues(alpha: 0.2)
                        : theme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(theme.designToken.radius.full),
                  ),
                  child: IconTheme(
                    data: IconThemeData(
                      size: 28,
                      color: isSelected ? theme.onPrimary : theme.primary,
                    ),
                    child: widget.icon ??
                        const Icon(Icons.category_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedDefaultTextStyle(
                  duration: theme.designToken.animation.normal,
                  style: theme.labelMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? theme.onPrimary : theme.primaryText,
                    height: 1.2,
                  ),
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
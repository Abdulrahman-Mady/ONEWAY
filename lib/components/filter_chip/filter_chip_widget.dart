import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'filter_chip_model.dart';
export 'filter_chip_model.dart';

class FilterChipWidget extends StatefulWidget {
  const FilterChipWidget({
    super.key,
    required this.label,
    this.icon,
    this.active = false,
    this.onTap,
    this.showCheck = true,
  });

  final String label;
  final Widget? icon;
  final bool active;
  final VoidCallback? onTap;
  final bool showCheck;

  @override
  State<FilterChipWidget> createState() => _FilterChipWidgetState();
}

class _FilterChipWidgetState extends State<FilterChipWidget>
    with SingleTickerProviderStateMixin {
  late FilterChipModel _model;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _borderAnimation;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FilterChipModel());
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _borderAnimation = Tween<double>(begin: 0, end: 2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(FilterChipWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
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
    final isActive = widget.active;

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
          onTap: widget.onTap ?? () {},
          borderRadius: BorderRadius.circular(theme.designToken.radius.full),
          splashColor: theme.primary.withValues(alpha: 0.1),
          highlightColor: theme.primary.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: theme.designToken.animation.normal,
            curve: theme.designToken.animation.standard,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(theme.designToken.radius.full),
              color: isActive ? theme.primary : theme.surface,
              border: Border.all(
                color: isActive ? theme.primary : theme.outlineVariant,
                width: 1.5,
              ),
              boxShadow: isActive
                  ? [theme.designToken.shadow.primarySm]
                  : [theme.designToken.shadow.xs],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  IconTheme(
                    data: IconThemeData(
                      size: 18,
                      color: isActive ? theme.onPrimary : theme.secondaryText,
                    ),
                    child: widget.icon!,
                  ),
                  const SizedBox(width: 8),
                ],
                AnimatedDefaultTextStyle(
                  duration: theme.designToken.animation.normal,
                  style: theme.labelMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? theme.onPrimary : theme.primaryText,
                    height: 1.2,
                  ),
                  child: Text(widget.label),
                ),
                if (isActive && widget.showCheck) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: theme.onPrimary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
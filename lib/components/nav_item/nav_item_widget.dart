import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'nav_item_model.dart';
export 'nav_item_model.dart';

class NavItemWidget extends StatefulWidget {
  const NavItemWidget({
    super.key,
    String? label,
    this.icon,
    String? target,
    bool? selected,
    this.onTap,
  })  : label = label ?? 'الرئيسية',
        target = target ?? 'HomeDashboard',
        selected = selected ?? true;

  final String label;
  final Widget? icon;
  final String target;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends State<NavItemWidget>
    with SingleTickerProviderStateMixin {
  late NavItemModel _model;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => NavItemModel());
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
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
    final isSelected = widget.selected;

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: widget.onTap ?? () async {
        await _model.onTap(context);
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconTheme(
                data: IconThemeData(
                  size: 24,
                  color: isSelected
                      ? theme.primary
                      : theme.onSurfaceVariant,
                ),
                child: widget.icon ??
                    const Icon(Icons.home_rounded),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: theme.designToken.animation.normal,
                style: theme.labelMedium.copyWith(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? theme.primary
                      : theme.onSurfaceVariant,
                  height: 1.3,
                ),
                child: Text(
                  widget.label,
                ),
              ),
              const SizedBox(height: 4),
              // Active indicator
              AnimatedContainer(
                duration: theme.designToken.animation.normal,
                curve: theme.designToken.animation.standard,
                height: 3,
                width: isSelected ? 20 : 0,
                decoration: BoxDecoration(
                  color: isSelected ? theme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'accessibility_toggle_model.dart';
export 'accessibility_toggle_model.dart';

class AccessibilityToggleWidget extends StatefulWidget {
  const AccessibilityToggleWidget({
    super.key,
    this.icon,
    String? label,
    bool? active,
    this.onChanged,
  })  : label = label ?? 'مدخل كراسي متحركة',
        active = active ?? true;

  final Widget? icon;
  final String label;
  final bool active;
  final ValueChanged<bool>? onChanged;

  @override
  State<AccessibilityToggleWidget> createState() => _AccessibilityToggleWidgetState();
}

class _AccessibilityToggleWidgetState extends State<AccessibilityToggleWidget>
    with SingleTickerProviderStateMixin {
  late AccessibilityToggleModel _model;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AccessibilityToggleModel());
    _isActive = widget.active;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _model.maybeDispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isActive = !_isActive;
    });
    _animationController.forward().then((_) => _animationController.reverse());
    widget.onChanged?.call(_isActive);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: theme.designToken.animation.normal,
          curve: theme.designToken.animation.standard,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isActive
                ? theme.primary.withValues(alpha: 0.08)
                : theme.surface,
            borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
            border: Border.all(
              color: _isActive ? theme.primary : theme.outlineVariant,
              width: _isActive ? 2 : 1.5,
            ),
            boxShadow: _isActive
                ? [theme.designToken.shadow.primarySm]
                : [theme.designToken.shadow.xs],
          ),
          child: Row(
            children: [
              // Icon container
              AnimatedContainer(
                duration: theme.designToken.animation.normal,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isActive
                      ? theme.primary.withValues(alpha: 0.15)
                      : theme.surfaceVariant,
                  borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
                ),
                child: Center(
                  child: IconTheme(
                    data: IconThemeData(
                      size: 22,
                      color: _isActive ? theme.primary : theme.secondaryText,
                    ),
                    child: widget.icon ??
                        const Icon(Icons.accessible_forward_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Label
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: theme.designToken.animation.normal,
                  style: theme.bodyLarge.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _isActive ? theme.primary : theme.primaryText,
                    height: 1.5,
                  ),
                  child: Text(widget.label),
                ),
              ),
              // Custom Switch
              AnimatedContainer(
                duration: theme.designToken.animation.normal,
                width: 52,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _isActive ? theme.primary : theme.onSurface.withValues(alpha: 0.2),
                  boxShadow: _isActive
                      ? [
                          BoxShadow(
                            blurRadius: 4,
                            color: theme.primary.withValues(alpha: 0.3),
                            offset: const Offset(0, 2),
                            spreadRadius: 0,
                          ),
                        ]
                      : [],
                ),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: theme.designToken.animation.normal,
                      curve: theme.designToken.animation.standard,
                      left: _isActive ? 26 : 2,
                      top: 2,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: theme.onPrimary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 4,
                              color: theme.shadow.withValues(alpha: 0.2),
                              offset: const Offset(0, 2),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
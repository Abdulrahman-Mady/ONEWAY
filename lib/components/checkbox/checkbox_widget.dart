import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'checkbox_model.dart';
export 'checkbox_model.dart';

class CheckboxWidget extends StatefulWidget {
  const CheckboxWidget({
    super.key,
    String? label,
    String? subtitle,
    Color? color,
    bool? isChecked,
    bool? hasSubtitle,
    bool? disabled,
    this.onChanged,
  })  : label = label ?? 'تم التحقق فقط',
        subtitle = subtitle ?? 'أماكن راجعها فريقنا',
        color = color ?? const Color(0x00000000),
        isChecked = isChecked ?? true,
        hasSubtitle = hasSubtitle ?? true,
        disabled = disabled ?? false;

  final String label;
  final String subtitle;
  final Color color;
  final bool isChecked;
  final bool hasSubtitle;
  final bool disabled;
  final ValueChanged<bool>? onChanged;

  @override
  State<CheckboxWidget> createState() => _CheckboxWidgetState();
}

class _CheckboxWidgetState extends State<CheckboxWidget>
    with SingleTickerProviderStateMixin {
  late CheckboxModel _model;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CheckboxModel());
    _isChecked = widget.isChecked;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
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
    if (widget.disabled) return;
    setState(() {
      _isChecked = !_isChecked;
    });
    _animationController.forward().then((_) => _animationController.reverse());
    widget.onChanged?.call(_isChecked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final activeColor = widget.color.value == 0x00000000 ? theme.primary : widget.color;

    return Opacity(
      opacity: widget.disabled ? 0.5 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(theme.designToken.radius.md),
          splashColor: activeColor.withValues(alpha: 0.1),
          child: AnimatedContainer(
            duration: theme.designToken.animation.fast,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                AnimatedBuilder(
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
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: _isChecked ? activeColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(theme.designToken.radius.sm),
                      border: Border.all(
                        color: _isChecked ? activeColor : theme.outlineVariant,
                        width: 2,
                      ),
                      boxShadow: _isChecked
                          ? [
                              BoxShadow(
                                blurRadius: 4,
                                color: activeColor.withValues(alpha: 0.3),
                                offset: const Offset(0, 2),
                                spreadRadius: 0,
                              ),
                            ]
                          : [],
                    ),
                    child: _isChecked
                        ? Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: theme.onPrimary,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                // Label and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: theme.primaryText,
                          height: 1.5,
                        ),
                      ),
                      if (widget.hasSubtitle && widget.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.bodySmall.copyWith(
                            fontSize: 12,
                            color: theme.secondaryText,
                            height: 1.4,
                          ),
                        ),
                      ],
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
}
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'button_model.dart';
export 'button_model.dart';

class ButtonWidget extends StatefulWidget {
  const ButtonWidget({
    super.key,
    this.icon,
    bool? iconPresent,
    this.iconEnd,
    bool? iconEndPresent,
    String? content,
    String? variant,
    String? size,
    bool? fullWidth,
    bool? loading,
    bool? disabled,
    this.onPressed,
    this.borderRadius,
  })  : iconPresent = iconPresent ?? false,
        iconEndPresent = iconEndPresent ?? false,
        content = content ?? 'تخطي',
        variant = variant ?? 'primary',
        size = size ?? 'medium',
        fullWidth = fullWidth ?? false,
        loading = loading ?? false,
        disabled = disabled ?? false;

  final Widget? icon;
  final bool iconPresent;
  final Widget? iconEnd;
  final bool iconEndPresent;
  final String content;
  final String variant; // primary, secondary, outline, ghost, destructive
  final String size; // small, medium, large
  final bool fullWidth;
  final bool loading;
  final bool disabled;
  final VoidCallback? onPressed;
  final double? borderRadius;

  @override
  State<ButtonWidget> createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends State<ButtonWidget>
    with SingleTickerProviderStateMixin {
  late ButtonModel _model;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ButtonModel());
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _elevationAnimation = Tween<double>(begin: 0, end: 4).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _model.maybeDispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.disabled && !widget.loading) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.disabled && !widget.loading) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (!widget.disabled && !widget.loading) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final disabled = widget.disabled || widget.loading;
    final fullWidth = widget.fullWidth;

    // Resolve colors based on variant
    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;
    List<BoxShadow> shadows = [];

    switch (widget.variant) {
      case 'secondary':
        backgroundColor = theme.secondary;
        foregroundColor = theme.onSecondary;
        borderColor = Colors.transparent;
        shadows = widget.disabled ? [] : [theme.designToken.shadow.primarySm];
        break;
      case 'outline':
        backgroundColor = Colors.transparent;
        foregroundColor = theme.primary;
        borderColor = theme.outlineVariant;
        break;
      case 'ghost':
        backgroundColor = Colors.transparent;
        foregroundColor = theme.primary;
        borderColor = Colors.transparent;
        break;
      case 'destructive':
        backgroundColor = theme.error;
        foregroundColor = theme.onError;
        borderColor = Colors.transparent;
        shadows = widget.disabled ? [] : [
          BoxShadow(
            blurRadius: 8,
            color: theme.error.withValues(alpha: 0.3),
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ];
        break;
      case 'primary':
      default:
        backgroundColor = theme.primary;
        foregroundColor = theme.onPrimary;
        borderColor = Colors.transparent;
        shadows = widget.disabled ? [] : [theme.designToken.shadow.primarySm];
        break;
    }

    // Adjust for disabled state
    if (disabled) {
      backgroundColor = isDark
          ? theme.onSurface.withValues(alpha: 0.12)
          : theme.onSurface.withValues(alpha: 0.12);
      foregroundColor = isDark
          ? theme.onSurface.withValues(alpha: 0.38)
          : theme.onSurface.withValues(alpha: 0.38);
      borderColor = Colors.transparent;
      shadows = [];
    }

    // Adjust for pressed state
    if (_isPressed && !disabled) {
      backgroundColor = Color.alphaBlend(
        Colors.black.withValues(alpha: 0.1),
        backgroundColor,
      );
    }

    // Resolve padding based on size
    EdgeInsetsGeometry padding;
    double fontSize;
    double iconSize;
    double radius = widget.borderRadius ??
        (widget.size == 'small' ? theme.designToken.radius.sm :
         widget.size == 'large' ? theme.designToken.radius.xl :
         theme.designToken.radius.lg);

    switch (widget.size) {
      case 'small':
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
        fontSize = 13;
        iconSize = 18;
        break;
      case 'large':
        padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
        fontSize = 16;
        iconSize = 24;
        break;
      case 'medium':
      default:
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
        fontSize = 14;
        iconSize = 20;
        break;
    }

    Widget buttonChild = AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: shadows.map((s) => BoxShadow(
                blurRadius: s.blurRadius + _elevationAnimation.value,
                color: s.color,
                offset: Offset(s.offset.dx, s.offset.dy + _elevationAnimation.value / 2),
                spreadRadius: s.spreadRadius,
              )).toList(),
            ),
            child: child,
          ),
        );
      },
      child: Container(
        width: fullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: borderColor,
            width: widget.variant == 'outline' ? 1.5 : 0,
          ),
        ),
        padding: padding,
        child: widget.loading
            ? _buildLoadingIndicator(foregroundColor, iconSize)
            : _buildButtonContent(foregroundColor, iconSize, fontSize),
      ),
    );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: disabled ? null : widget.onPressed,
      child: AnimatedOpacity(
        opacity: disabled ? 0.6 : 1.0,
        duration: theme.designToken.animation.fast,
        child: buttonChild,
      ),
    );
  }

  Widget _buildLoadingIndicator(Color color, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  Widget _buildButtonContent(Color color, double iconSize, double fontSize) {
    final theme = FlutterFlowTheme.of(context);
    final children = <Widget>[];

    if (widget.iconPresent && widget.icon != null) {
      children.add(IconTheme(
        data: IconThemeData(size: iconSize, color: color),
        child: widget.icon!,
      ));
      children.add(SizedBox(width: widget.size == 'small' ? 6 : 8));
    }

    children.add(Flexible(
      child: Text(
        widget.content,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.labelLarge.copyWith(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          height: 1.2,
        ),
      ),
    ));

    if (widget.iconEndPresent && widget.iconEnd != null) {
      children.add(SizedBox(width: widget.size == 'small' ? 6 : 8));
      children.add(IconTheme(
        data: IconThemeData(size: iconSize, color: color),
        child: widget.iconEnd!,
      ));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'bottom_nav_model.dart';
export 'bottom_nav_model.dart';

class BottomNavWidget extends StatefulWidget {
  const BottomNavWidget({
    super.key,
    this.child,
    this.currentIndex = 0,
    this.onTap,
  });

  final Widget Function()? child;
  final int currentIndex;
  final ValueChanged<int>? onTap;

  @override
  State<BottomNavWidget> createState() => _BottomNavWidgetState();
}

class _BottomNavWidgetState extends State<BottomNavWidget>
    with SingleTickerProviderStateMixin {
  late BottomNavModel _model;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BottomNavModel());
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: theme.shadow.withValues(alpha: isDark ? 0.3 : 0.1),
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
          BoxShadow(
            blurRadius: 4,
            color: theme.shadow.withValues(alpha: isDark ? 0.2 : 0.05),
            offset: const Offset(0, -1),
            spreadRadius: 0,
          ),
        ],
        border: Border(
          top: BorderSide(
            color: theme.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: widget.child != null
              ? widget.child!()
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dot_model.dart';
export 'dot_model.dart';

class DotWidget extends StatefulWidget {
  const DotWidget({
    super.key,
    bool? active,
    this.onTap,
    this.index = 0,
    this.currentIndex = 0,
  })  : active = active ?? false;

  final bool active;
  final VoidCallback? onTap;
  final int index;
  final int currentIndex;

  @override
  State<DotWidget> createState() => _DotWidgetState();
}

class _DotWidgetState extends State<DotWidget>
    with SingleTickerProviderStateMixin {
  late DotModel _model;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DotModel());
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _widthAnimation = Tween<double>(begin: 8.0, end: 24.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(DotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (widget.active) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
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
    final isActive = widget.active || widget.index == widget.currentIndex;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            width: isActive ? _widthAnimation.value : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isActive ? theme.primary : theme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        },
      ),
    );
  }
}
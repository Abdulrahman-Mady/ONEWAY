import '/components/nav_item/nav_item_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'bottom_nav_child_model.dart';
export 'bottom_nav_child_model.dart';

class BottomNavChildWidget extends StatefulWidget {
  const BottomNavChildWidget({
    super.key,
    this.currentIndex = 0,
    this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int>? onTap;

  @override
  State<BottomNavChildWidget> createState() => _BottomNavChildWidgetState();
}

class _BottomNavChildWidgetState extends State<BottomNavChildWidget> {
  late BottomNavChildModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BottomNavChildModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final currentIndex = widget.currentIndex;
    final onTap = widget.onTap;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNavItem(
          index: 0,
          label: 'الرئيسية',
          icon: Icons.home_rounded,
          activeIcon: Icons.home_rounded,
          currentIndex: currentIndex,
          onTap: onTap,
        ),
        _buildNavItem(
          index: 1,
          label: 'الخريطة',
          icon: Icons.map_outlined,
          activeIcon: Icons.map_rounded,
          currentIndex: currentIndex,
          onTap: onTap,
        ),
        _buildNavItem(
          index: 2,
          label: 'بلاغ',
          icon: Icons.report_problem_outlined,
          activeIcon: Icons.report_problem_rounded,
          currentIndex: currentIndex,
          onTap: onTap,
        ),
        _buildNavItem(
          index: 3,
          label: 'حسابي',
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          currentIndex: currentIndex,
          onTap: onTap,
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required int currentIndex,
    required ValueChanged<int>? onTap,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final isSelected = currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap?.call(index),
          borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
          splashColor: theme.primary.withValues(alpha: 0.1),
          highlightColor: theme.primary.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: theme.designToken.animation.normal,
            curve: theme.designToken.animation.standard,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
              color: isSelected
                  ? theme.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: theme.designToken.animation.normal,
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    key: ValueKey(isSelected),
                    size: 24,
                    color: isSelected
                        ? theme.primary
                        : theme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: theme.designToken.animation.normal,
                  style: theme.labelSmall.copyWith(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? theme.primary
                        : theme.onSurfaceVariant,
                    height: 1.2,
                    letterSpacing: 0.2,
                  ),
                  child: Text(label),
                ),
                const SizedBox(height: 4),
                // Active indicator
                AnimatedContainer(
                  duration: theme.designToken.animation.normal,
                  curve: theme.designToken.animation.standard,
                  height: 3,
                  width: isSelected ? 24 : 0,
                  decoration: BoxDecoration(
                    color: isSelected ? theme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
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
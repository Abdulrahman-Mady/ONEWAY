import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'switch_component_model.dart';
export 'switch_component_model.dart';

class SwitchComponentWidget extends StatefulWidget {
  const SwitchComponentWidget({
    super.key,
    String? label,
    bool? labelPresent,
    String? variant,
    bool? active,
  })  : label = label ?? '',
        labelPresent = labelPresent ?? false,
        variant = variant ?? 'iOS',
        active = active ?? false;

  final String label;
  final bool labelPresent;
  final String variant;
  final bool active;

  @override
  State<SwitchComponentWidget> createState() => _SwitchComponentWidgetState();
}

class _SwitchComponentWidgetState extends State<SwitchComponentWidget> {
  late SwitchComponentModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SwitchComponentModel());

    _model.switchValue = valueOrDefault<bool>(
      valueOrDefault<bool>(
        widget.active,
        false,
      )
          ? true
          : false,
      false,
    );
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isIOS = widget.variant == 'iOS';
    final isIOS26 = widget.variant == 'iOS 26+';
    final isActive = widget.active;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isIOS || isIOS26)
            Switch.adaptive(
              value: _model.switchValue!,
              onChanged: (newValue) async {
                safeSetState(() => _model.switchValue = newValue);
              },
              activeTrackColor: theme.primary,
              inactiveTrackColor: theme.outlineVariant,
              inactiveThumbColor: theme.surface,
            ),
          if (!isIOS && !isIOS26)
            _CustomSwitch(
              active: isActive,
              onChanged: (value) => safeSetState(() => _model.switchValue = value),
              theme: theme,
            ),
          if (widget.labelPresent)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                widget.label,
                style: theme.bodyMedium.copyWith(
                  fontSize: 14,
                  color: theme.primaryText,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomSwitch extends StatelessWidget {
  const _CustomSwitch({
    required this.active,
    required this.onChanged,
    required this.theme,
  });

  final bool active;
  final ValueChanged<bool> onChanged;
  final FlutterFlowTheme theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!active),
      child: AnimatedContainer(
        duration: theme.designToken.animation.normal,
        width: 56,
        height: 32,
        decoration: BoxDecoration(
          color: active ? theme.primary : theme.outlineVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: AnimatedAlign(
            duration: theme.designToken.animation.normal,
            alignment: active ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 4,
                    color: theme.shadow.withValues(alpha: 0.2),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
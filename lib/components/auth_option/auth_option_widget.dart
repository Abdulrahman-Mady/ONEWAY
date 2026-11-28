import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_option_model.dart';
export 'auth_option_model.dart';

class AuthOptionWidget extends StatefulWidget {
  const AuthOptionWidget({
    super.key,
    this.icon,
    String? label,
    bool? isPrimary,
  })  : label = label ?? 'تسجيل الدخول بواسطة Google',
        isPrimary = isPrimary ?? false;

  final Widget? icon;
  final String label;
  final bool isPrimary;

  @override
  State<AuthOptionWidget> createState() => _AuthOptionWidgetState();
}

class _AuthOptionWidgetState extends State<AuthOptionWidget> {
  late AuthOptionModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AuthOptionModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isPrimary = widget.isPrimary;

    return Container(
      decoration: BoxDecoration(
        color: isPrimary ? theme.primary : theme.surface,
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        border: Border.all(
          color: isPrimary ? theme.primary : theme.outlineVariant,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconTheme(
            data: IconThemeData(
              size: 22,
              color: isPrimary ? theme.onPrimary : theme.primaryText,
            ),
            child: widget.icon ?? const Icon(Icons.g_mobiledata_rounded),
          ),
          const SizedBox(width: 12),
          Text(
            widget.label,
            style: theme.labelLarge.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isPrimary ? theme.onPrimary : theme.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'info_row_model.dart';
export 'info_row_model.dart';

class InfoRowWidget extends StatefulWidget {
  const InfoRowWidget({
    super.key,
    this.icon,
    String? label,
    String? value,
  })  : label = label ?? 'العنوان',
        value = value ?? 'شارع التسعين الشمالي، التجمع الخامس، القاهرة';

  final Widget? icon;
  final String label;
  final String value;

  @override
  State<InfoRowWidget> createState() => _InfoRowWidgetState();
}

class _InfoRowWidgetState extends State<InfoRowWidget> {
  late InfoRowModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => InfoRowModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
          ),
          alignment: Alignment.center,
          child: IconTheme(
            data: IconThemeData(
              color: theme.primary,
              size: 20,
            ),
            child: widget.icon ?? const Icon(Icons.info_outline_rounded),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: theme.labelSmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: theme.tertiaryText,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.value,
                style: theme.bodyMedium.copyWith(
                  fontSize: 14,
                  color: theme.primaryText,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
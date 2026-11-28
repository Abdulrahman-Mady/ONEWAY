import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'photo_slot_model.dart';
export 'photo_slot_model.dart';

class PhotoSlotWidget extends StatefulWidget {
  const PhotoSlotWidget({
    super.key,
    String? label,
  }) : label = label ?? 'صورة العائق';

  final String label;

  @override
  State<PhotoSlotWidget> createState() => _PhotoSlotWidgetState();
}

class _PhotoSlotWidgetState extends State<PhotoSlotWidget> {
  late PhotoSlotModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PhotoSlotModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        border: Border.all(color: theme.outlineVariant, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_a_photo_rounded,
            color: theme.onSurfaceVariant,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            widget.label,
            style: theme.labelSmall.copyWith(
              fontSize: 11,
              color: theme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
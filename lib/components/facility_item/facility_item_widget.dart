import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'facility_item_model.dart';
export 'facility_item_model.dart';

class FacilityItemWidget extends StatefulWidget {
  const FacilityItemWidget({
    super.key,
    String? distance,
    String? status,
    String? title,
  })  : distance = distance ?? '1.2 كم',
        status = status ?? 'متاح',
        title = title ?? 'مستشفى السلام الدولي';

  final String distance;
  final String status;
  final String title;

  @override
  State<FacilityItemWidget> createState() => _FacilityItemWidgetState();
}

class _FacilityItemWidgetState extends State<FacilityItemWidget> {
  late FacilityItemModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FacilityItemModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isAvailable = widget.status == 'متاح' || widget.status == 'empty';

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        border: Border.all(color: theme.outlineVariant, width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.surfaceVariant,
                borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
              ),
              child: CachedNetworkImage(
                fadeInDuration: const Duration(milliseconds: 200),
                imageUrl:
                    'https://dimg.dreamflow.cloud/v1/image/facility%20building%20exterior',
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.primary,
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.local_hospital_rounded,
                  color: theme.onSurfaceVariant,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: theme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.distance,
                      style: theme.bodySmall.copyWith(
                        fontSize: 12,
                        color: theme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? theme.successContainer
                        : theme.warningContainer,
                    borderRadius: BorderRadius.circular(theme.designToken.radius.sm),
                  ),
                  child: Text(
                    widget.status,
                    style: theme.labelSmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isAvailable ? theme.success : theme.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _FacilityActionButton(
            onPressed: () {
              // Handle directions
            },
          ),
        ],
      ),
    );
  }
}

class _FacilityActionButton extends StatelessWidget {
  const _FacilityActionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
          ),
          child: Icon(
            Icons.directions_rounded,
            color: theme.secondary,
            size: 24,
          ),
        ),
      ),
    );
  }
}
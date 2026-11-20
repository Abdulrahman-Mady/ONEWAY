import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'branch_item_model.dart';
export 'branch_item_model.dart';

class BranchItemWidget extends StatefulWidget {
  const BranchItemWidget({
    super.key,
    bool? isVerified,
    String? name,
    String? score,
    String? status,
  })  : isVerified = isVerified ?? true,
        name = name ?? 'فرع روكسي',
        score = score ?? '92%',
        status = status ?? 'تم التحقق';

  final bool isVerified;
  final String name;
  final String score;
  final String status;

  @override
  State<BranchItemWidget> createState() => _BranchItemWidgetState();
}

class _BranchItemWidgetState extends State<BranchItemWidget> {
  late BranchItemModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BranchItemModel());
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
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
        border: Border.all(color: theme.outlineVariant, width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.surfaceVariant,
              borderRadius: BorderRadius.circular(theme.designToken.radius.lg),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.store_rounded,
              color: theme.onSurfaceVariant,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.name,
                      style: theme.titleSmall.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.primaryText,
                      ),
                    ),
                    if (widget.isVerified) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.check_circle_rounded,
                        color: theme.success,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.status,
                  style: theme.bodySmall.copyWith(
                    fontSize: 12,
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.score,
                style: theme.titleMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'تقييم الإتاحة',
                style: theme.labelSmall.copyWith(
                  fontSize: 11,
                  color: theme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
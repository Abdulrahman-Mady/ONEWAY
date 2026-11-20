import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'assistant_suggestion_model.dart';
export 'assistant_suggestion_model.dart';

class AssistantSuggestionWidget extends StatefulWidget {
  const AssistantSuggestionWidget({
    super.key,
    String? query,
    this.onTap,
  }) : query = query ?? 'أقرب مستشفى فيها مدخل مناسب';

  final String query;
  final VoidCallback? onTap;

  @override
  State<AssistantSuggestionWidget> createState() => _AssistantSuggestionWidgetState();
}

class _AssistantSuggestionWidgetState extends State<AssistantSuggestionWidget> {
  late AssistantSuggestionModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AssistantSuggestionModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(theme.designToken.radius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(theme.designToken.radius.full),
          border: Border.all(color: theme.outlineVariant, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              color: theme.secondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              widget.query,
              style: theme.labelLarge.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
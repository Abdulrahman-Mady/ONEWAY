import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'contact_card_model.dart';
export 'contact_card_model.dart';

class ContactCardWidget extends StatefulWidget {
  const ContactCardWidget({
    super.key,
    this.icon,
    String? name,
    String? phone,
    String? relation,
  })  : name = name ?? 'أحمد محمد',
        phone = phone ?? '01012345678',
        relation = relation ?? 'الأب';

  final Widget? icon;
  final String name;
  final String phone;
  final String relation;

  @override
  State<ContactCardWidget> createState() => _ContactCardWidgetState();
}

class _ContactCardWidgetState extends State<ContactCardWidget> {
  late ContactCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ContactCardModel());
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
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(theme.designToken.radius.full),
            ),
            alignment: Alignment.center,
            child: IconTheme(
              data: IconThemeData(
                size: 24,
                color: theme.primary,
              ),
              child: widget.icon ?? const Icon(Icons.person_rounded),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: theme.titleMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.relation,
                  style: theme.bodySmall.copyWith(
                    fontSize: 12,
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          _ContactActionButton(
            icon: Icons.call_rounded,
            onPressed: () {
              // Handle call
            },
          ),
        ],
      ),
    );
  }
}

class _ContactActionButton extends StatelessWidget {
  const _ContactActionButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(theme.designToken.radius.full),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.secondary,
            borderRadius: BorderRadius.circular(theme.designToken.radius.full),
          ),
          child: Icon(
            icon,
            color: theme.onSecondary,
            size: 22,
          ),
        ),
      ),
    );
  }
}
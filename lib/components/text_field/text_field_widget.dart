import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'text_field_model.dart';
export 'text_field_model.dart';

class TextFieldWidget extends StatefulWidget {
  const TextFieldWidget({
    super.key,
    String? label,
    bool? labelPresent,
    String? helper,
    bool? helperPresent,
    this.leadingIcon,
    bool? leadingIconPresent,
    this.trailingIcon,
    bool? trailingIconPresent,
    String? hint,
    String? value,
    String? onChange,
    String? onSubmit,
    String? variant,
    bool? error,
    this.controller,
    this.focusNode,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.maxLength,
  })  : label = label ?? 'البريد الإلكتروني',
        labelPresent = labelPresent ?? true,
        helper = helper ?? '',
        helperPresent = helperPresent ?? false,
        leadingIconPresent = leadingIconPresent ?? true,
        trailingIconPresent = trailingIconPresent ?? false,
        hint = hint ?? 'example@mail.com',
        value = value ?? '',
        onChange = onChange ?? '',
        onSubmit = onSubmit ?? '',
        variant = variant ?? 'outlined',
        error = error ?? false;

  final String label;
  final bool labelPresent;
  final String helper;
  final bool helperPresent;
  final Widget? leadingIcon;
  final bool leadingIconPresent;
  final Widget? trailingIcon;
  final bool trailingIconPresent;
  final String hint;
  final String value;
  final String onChange;
  final String onSubmit;
  final String variant; // 'outlined', 'filled', 'ghost'
  final bool error;

  // New properties for better integration
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final int? maxLength;

  @override
  State<TextFieldWidget> createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<TextFieldWidget> {
  late TextFieldModel _model;
  late TextEditingController _internalController;
  late FocusNode _internalFocusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TextFieldModel());

    _internalController = widget.controller ?? TextEditingController(text: widget.value);
    _internalFocusNode = widget.focusNode ?? FocusNode();

    _internalFocusNode.addListener(() {
      if (mounted) {
        setState(() => _hasFocus = _internalFocusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    }
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isError = widget.error;
    final isDark = theme.brightness == Brightness.dark;

    // Resolve colors
    Color fillColor;
    Color borderColor;
    double borderWidth;

    switch (widget.variant) {
      case 'filled':
        fillColor = theme.surfaceContainer;
        borderColor = isError ? theme.error : (_hasFocus ? theme.primary : Colors.transparent);
        borderWidth = isError || _hasFocus ? 2 : 0;
        break;
      case 'ghost':
        fillColor = Colors.transparent;
        borderColor = isError ? theme.error : (_hasFocus ? theme.primary : Colors.transparent);
        borderWidth = isError || _hasFocus ? 2 : 0;
        break;
      case 'outlined':
      default:
        fillColor = theme.surface;
        borderColor = isError ? theme.error : (_hasFocus ? theme.primary : theme.outlineVariant);
        borderWidth = isError || _hasFocus ? 2 : 1.5;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.labelPresent)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label,
              style: theme.labelMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isError ? theme.error : theme.primaryText,
              ),
            ),
          ),
        // Text Field
        AnimatedContainer(
          duration: theme.designToken.animation.fast,
          curve: theme.designToken.animation.standard,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(theme.designToken.radius.xl),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: _hasFocus && widget.variant != 'ghost'
                ? [
                    BoxShadow(
                      blurRadius: 8,
                      color: theme.primary.withValues(alpha: 0.1),
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: _internalController,
            focusNode: _internalFocusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            style: theme.bodyLarge.copyWith(
              fontSize: 16,
              color: theme.primaryText,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hint,
              hintStyle: theme.bodyLarge.copyWith(
                fontSize: 16,
                color: theme.hintText,
              ),
              prefixIcon: widget.leadingIconPresent && widget.leadingIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 16, right: 12),
                      child: IconTheme(
                        data: IconThemeData(
                          color: _hasFocus ? theme.primary : theme.onSurfaceVariant,
                          size: 22,
                        ),
                        child: widget.leadingIcon!,
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              suffixIcon: widget.trailingIconPresent && widget.trailingIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: widget.trailingIcon!,
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: widget.leadingIconPresent ? 8 : 16,
                vertical: 16,
              ),
              counterText: '',
            ),
            validator: widget.validator ?? _model.inputTextControllerValidator.asValidator(context),
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
          ),
        ),
        // Helper/Error Text
        if (widget.helperPresent && widget.helper.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              widget.helper,
              style: theme.bodySmall.copyWith(
                fontSize: 12,
                color: theme.tertiaryText,
              ),
            ),
          )
        else if (isError && _internalController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'يرجى التحقق من المدخلات',
              style: theme.bodySmall.copyWith(
                fontSize: 12,
                color: theme.error,
              ),
            ),
          ),
      ],
    );
  }
}
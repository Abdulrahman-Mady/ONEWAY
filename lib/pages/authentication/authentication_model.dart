import '/components/button/button_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'authentication_widget.dart' show AuthenticationWidget;
import 'package:flutter/material.dart';

class AuthenticationModel extends FlutterFlowModel<AuthenticationWidget> {
  ///  Local state fields for this page.

  bool? createAccountMode = false;

  ///  State fields for stateful widgets in this page.

  // State field(s) for emailInput widget.
  FocusNode? emailInputFocusNode;
  TextEditingController? emailInputTextController;
  String? Function(BuildContext, String?)? emailInputTextControllerValidator;
  // State field(s) for passwordInput widget.
  late FocusNode passwordInputPasswordVisibilityFocusNode;
  FocusNode? passwordInputFocusNode;
  TextEditingController? passwordInputTextController;
  late bool passwordInputVisibility;
  String? Function(BuildContext, String?)? passwordInputTextControllerValidator;
  // Model for Button.
  late ButtonModel buttonModel1;
  // Model for Button.
  late ButtonModel buttonModel2;
  // Model for Button.
  late ButtonModel buttonModel3;
  // Model for Button.
  late ButtonModel buttonModel4;
  // Model for Button.
  late ButtonModel buttonModel5;
  // Model for Button.
  late ButtonModel buttonModel6;
  // Model for Button.
  late ButtonModel buttonModel7;

  @override
  void initState(BuildContext context) {
    passwordInputPasswordVisibilityFocusNode = FocusNode();
    passwordInputVisibility = false;
    buttonModel1 = createModel(context, () => ButtonModel());
    buttonModel2 = createModel(context, () => ButtonModel());
    buttonModel3 = createModel(context, () => ButtonModel());
    buttonModel4 = createModel(context, () => ButtonModel());
    buttonModel5 = createModel(context, () => ButtonModel());
    buttonModel6 = createModel(context, () => ButtonModel());
    buttonModel7 = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    emailInputFocusNode?.dispose();
    emailInputTextController?.dispose();

    passwordInputFocusNode?.dispose();
    passwordInputTextController?.dispose();
    passwordInputPasswordVisibilityFocusNode.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
    buttonModel3.dispose();
    buttonModel4.dispose();
    buttonModel5.dispose();
    buttonModel6.dispose();
    buttonModel7.dispose();
  }
}

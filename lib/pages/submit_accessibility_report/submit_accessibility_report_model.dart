import '/components/button/button_widget.dart';
import '/components/checkbox/checkbox_widget.dart';
import '/components/photo_slot/photo_slot_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'submit_accessibility_report_widget.dart'
    show SubmitAccessibilityReportWidget;
import 'package:flutter/material.dart';

class SubmitAccessibilityReportModel
    extends FlutterFlowModel<SubmitAccessibilityReportWidget> {
  ///  Local state fields for this page.

  String? reportDescription = '';

  String? reportCategory = 'مدخل غير مناسب';

  ///  State fields for stateful widgets in this page.

  // State field(s) for ChoiceChips widget.
  FormFieldController<List<String>>? choiceChipsValueController;
  String? get choiceChipsValue =>
      choiceChipsValueController?.value?.firstOrNull;
  set choiceChipsValue(String? val) =>
      choiceChipsValueController?.value = val != null ? [val] : [];
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textFieldTextController;
  String? Function(BuildContext, String?)? textFieldTextControllerValidator;
  // Model for PhotoSlot.
  late PhotoSlotModel photoSlotModel1;
  // Model for PhotoSlot.
  late PhotoSlotModel photoSlotModel2;
  // Model for Checkbox.
  late CheckboxModel checkboxModel;
  // Model for Button.
  late ButtonModel buttonModel1;
  // Model for Button.
  late ButtonModel buttonModel2;

  @override
  void initState(BuildContext context) {
    photoSlotModel1 = createModel(context, () => PhotoSlotModel());
    photoSlotModel2 = createModel(context, () => PhotoSlotModel());
    checkboxModel = createModel(context, () => CheckboxModel());
    buttonModel1 = createModel(context, () => ButtonModel());
    buttonModel2 = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textFieldTextController?.dispose();

    photoSlotModel1.dispose();
    photoSlotModel2.dispose();
    checkboxModel.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
  }
}

import '/components/accessibility_toggle/accessibility_toggle_widget.dart';
import '/components/button/button_widget.dart';
import '/components/checkbox/checkbox_widget.dart';
import '/components/filter_chip/filter_chip_widget.dart';
import '/components/slider/slider_widget.dart';
import '/components/text_field/text_field_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'search_filters_widget.dart' show SearchFiltersWidget;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SearchFiltersModel extends FlutterFlowModel<SearchFiltersWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for TextField.
  late TextFieldModel textFieldModel;
  // Model for FilterChip.
  late FilterChipModel filterChipModel1;
  // Model for FilterChip.
  late FilterChipModel filterChipModel2;
  // Model for FilterChip.
  late FilterChipModel filterChipModel3;
  // Model for FilterChip.
  late FilterChipModel filterChipModel4;
  // Model for FilterChip.
  late FilterChipModel filterChipModel5;
  // Model for FilterChip.
  late FilterChipModel filterChipModel6;
  // Model for FilterChip.
  late FilterChipModel filterChipModel7;
  // Model for AccessibilityToggle.
  late AccessibilityToggleModel accessibilityToggleModel1;
  // Model for AccessibilityToggle.
  late AccessibilityToggleModel accessibilityToggleModel2;
  // Model for AccessibilityToggle.
  late AccessibilityToggleModel accessibilityToggleModel3;
  // Model for AccessibilityToggle.
  late AccessibilityToggleModel accessibilityToggleModel4;
  // Model for AccessibilityToggle.
  late AccessibilityToggleModel accessibilityToggleModel5;
  // State field(s) for Dropdown widget.
  String? dropdownValue;
  FormFieldController<String>? dropdownValueController;
  // Model for Slider.
  late SliderModel sliderModel;
  // Model for Checkbox.
  late CheckboxModel checkboxModel;
  // Model for Button.
  late ButtonModel buttonModel1;
  // Model for Button.
  late ButtonModel buttonModel2;

  // Voice search
  stt.SpeechToText? speechToText;
  bool isListening = false;
  String voiceSearchQuery = '';

  @override
  void initState(BuildContext context) {
    textFieldModel = createModel(context, () => TextFieldModel());
    filterChipModel1 = createModel(context, () => FilterChipModel());
    filterChipModel2 = createModel(context, () => FilterChipModel());
    filterChipModel3 = createModel(context, () => FilterChipModel());
    filterChipModel4 = createModel(context, () => FilterChipModel());
    filterChipModel5 = createModel(context, () => FilterChipModel());
    filterChipModel6 = createModel(context, () => FilterChipModel());
    filterChipModel7 = createModel(context, () => FilterChipModel());
    accessibilityToggleModel1 =
        createModel(context, () => AccessibilityToggleModel());
    accessibilityToggleModel2 =
        createModel(context, () => AccessibilityToggleModel());
    accessibilityToggleModel3 =
        createModel(context, () => AccessibilityToggleModel());
    accessibilityToggleModel4 =
        createModel(context, () => AccessibilityToggleModel());
    accessibilityToggleModel5 =
        createModel(context, () => AccessibilityToggleModel());
    sliderModel = createModel(context, () => SliderModel());
    checkboxModel = createModel(context, () => CheckboxModel());
    buttonModel1 = createModel(context, () => ButtonModel());
    buttonModel2 = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    textFieldModel.dispose();
    filterChipModel1.dispose();
    filterChipModel2.dispose();
    filterChipModel3.dispose();
    filterChipModel4.dispose();
    filterChipModel5.dispose();
    filterChipModel6.dispose();
    filterChipModel7.dispose();
    accessibilityToggleModel1.dispose();
    accessibilityToggleModel2.dispose();
    accessibilityToggleModel3.dispose();
    accessibilityToggleModel4.dispose();
    accessibilityToggleModel5.dispose();
    sliderModel.dispose();
    checkboxModel.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
    speechToText?.stop();
    speechToText = null;
  }
}

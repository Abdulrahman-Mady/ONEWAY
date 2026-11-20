import '/components/switch_component/switch_component_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'accessibility_toggle_widget.dart' show AccessibilityToggleWidget;
import 'package:flutter/material.dart';

class AccessibilityToggleModel
    extends FlutterFlowModel<AccessibilityToggleWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for Switch.
  late SwitchComponentModel switchModel;

  @override
  void initState(BuildContext context) {
    switchModel = createModel(context, () => SwitchComponentModel());
  }

  @override
  void dispose() {
    switchModel.dispose();
  }
}

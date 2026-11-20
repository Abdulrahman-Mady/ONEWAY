import '/components/accessibility_chip/accessibility_chip_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'place_preview_card_widget.dart' show PlacePreviewCardWidget;
import 'package:flutter/material.dart';

class PlacePreviewCardModel extends FlutterFlowModel<PlacePreviewCardWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for AccessibilityChip.
  late AccessibilityChipModel accessibilityChipModel1;
  // Model for AccessibilityChip.
  late AccessibilityChipModel accessibilityChipModel2;

  @override
  void initState(BuildContext context) {
    accessibilityChipModel1 =
        createModel(context, () => AccessibilityChipModel());
    accessibilityChipModel2 =
        createModel(context, () => AccessibilityChipModel());
  }

  @override
  void dispose() {
    accessibilityChipModel1.dispose();
    accessibilityChipModel2.dispose();
  }
}

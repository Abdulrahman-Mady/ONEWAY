import '/components/accessibility_chip2/accessibility_chip2_widget.dart';
import '/components/button/button_widget.dart';
import '/components/info_row/info_row_widget.dart';
import '/components/slider/slider_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'place_details_widget.dart' show PlaceDetailsWidget;
import 'package:flutter/material.dart';

class PlaceDetailsModel extends FlutterFlowModel<PlaceDetailsWidget> {
  ///  Local state fields for this page.

  bool? isFavorite = false;

  ///  State fields for stateful widgets in this page.

  // Model for Slider.
  late SliderModel sliderModel;
  // Model for AccessibilityChip.
  late AccessibilityChip2Model accessibilityChipModel1;
  // Model for AccessibilityChip.
  late AccessibilityChip2Model accessibilityChipModel2;
  // Model for AccessibilityChip.
  late AccessibilityChip2Model accessibilityChipModel3;
  // Model for AccessibilityChip.
  late AccessibilityChip2Model accessibilityChipModel4;
  // Model for AccessibilityChip.
  late AccessibilityChip2Model accessibilityChipModel5;
  // Model for InfoRow.
  late InfoRowModel infoRowModel1;
  // Model for InfoRow.
  late InfoRowModel infoRowModel2;
  // Model for InfoRow.
  late InfoRowModel infoRowModel3;
  // State field(s) for Map widget.
  LatLng? mapGoogleMapsCenter;
  // Model for Button.
  late ButtonModel buttonModel1;
  // Model for Button.
  late ButtonModel buttonModel2;
  // Model for Button.
  late ButtonModel buttonModel3;

  @override
  void initState(BuildContext context) {
    sliderModel = createModel(context, () => SliderModel());
    accessibilityChipModel1 =
        createModel(context, () => AccessibilityChip2Model());
    accessibilityChipModel2 =
        createModel(context, () => AccessibilityChip2Model());
    accessibilityChipModel3 =
        createModel(context, () => AccessibilityChip2Model());
    accessibilityChipModel4 =
        createModel(context, () => AccessibilityChip2Model());
    accessibilityChipModel5 =
        createModel(context, () => AccessibilityChip2Model());
    infoRowModel1 = createModel(context, () => InfoRowModel());
    infoRowModel2 = createModel(context, () => InfoRowModel());
    infoRowModel3 = createModel(context, () => InfoRowModel());
    buttonModel1 = createModel(context, () => ButtonModel());
    buttonModel2 = createModel(context, () => ButtonModel());
    buttonModel3 = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    sliderModel.dispose();
    accessibilityChipModel1.dispose();
    accessibilityChipModel2.dispose();
    accessibilityChipModel3.dispose();
    accessibilityChipModel4.dispose();
    accessibilityChipModel5.dispose();
    infoRowModel1.dispose();
    infoRowModel2.dispose();
    infoRowModel3.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
    buttonModel3.dispose();
  }
}

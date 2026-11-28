import '/components/bottom_nav/bottom_nav_widget.dart';
import '/components/place_preview_card/place_preview_card_widget.dart';
import '/components/text_field/text_field_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'explore_map_widget.dart' show ExploreMapWidget;
import 'package:flutter/material.dart';

class ExploreMapModel extends FlutterFlowModel<ExploreMapWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for Map widget.
  LatLng? mapGoogleMapsCenter;
  // Model for TextField.
  late TextFieldModel textFieldModel;
  // Model for PlacePreviewCard.
  late PlacePreviewCardModel placePreviewCardModel1;
  // Model for PlacePreviewCard.
  late PlacePreviewCardModel placePreviewCardModel2;
  // Model for PlacePreviewCard.
  late PlacePreviewCardModel placePreviewCardModel3;
  // Model for BottomNav.
  late BottomNavModel bottomNavModel;

  @override
  void initState(BuildContext context) {
    textFieldModel = createModel(context, () => TextFieldModel());
    placePreviewCardModel1 =
        createModel(context, () => PlacePreviewCardModel());
    placePreviewCardModel2 =
        createModel(context, () => PlacePreviewCardModel());
    placePreviewCardModel3 =
        createModel(context, () => PlacePreviewCardModel());
    bottomNavModel = createModel(context, () => BottomNavModel());
  }

  @override
  void dispose() {
    textFieldModel.dispose();
    placePreviewCardModel1.dispose();
    placePreviewCardModel2.dispose();
    placePreviewCardModel3.dispose();
    bottomNavModel.dispose();
  }
}

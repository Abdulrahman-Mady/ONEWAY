import '/components/bottom_nav/bottom_nav_widget.dart';
import '/components/button/button_widget.dart';
import '/components/category_chip/category_chip_widget.dart';
import '/components/place_card/place_card_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'home_dashboard_widget.dart' show HomeDashboardWidget;
import 'package:flutter/material.dart';

class HomeDashboardModel extends FlutterFlowModel<HomeDashboardWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for CategoryChip.
  late CategoryChipModel categoryChipModel1;
  // Model for CategoryChip.
  late CategoryChipModel categoryChipModel2;
  // Model for CategoryChip.
  late CategoryChipModel categoryChipModel3;
  // Model for CategoryChip.
  late CategoryChipModel categoryChipModel4;
  // Model for CategoryChip.
  late CategoryChipModel categoryChipModel5;
  // Model for PlaceCard.
  late PlaceCardModel placeCardModel1;
  // Model for PlaceCard.
  late PlaceCardModel placeCardModel2;
  // Model for PlaceCard.
  late PlaceCardModel placeCardModel3;
  // Model for Button.
  late ButtonModel buttonModel;
  // Model for BottomNav.
  late BottomNavModel bottomNavModel;

  @override
  void initState(BuildContext context) {
    categoryChipModel1 = createModel(context, () => CategoryChipModel());
    categoryChipModel2 = createModel(context, () => CategoryChipModel());
    categoryChipModel3 = createModel(context, () => CategoryChipModel());
    categoryChipModel4 = createModel(context, () => CategoryChipModel());
    categoryChipModel5 = createModel(context, () => CategoryChipModel());
    placeCardModel1 = createModel(context, () => PlaceCardModel());
    placeCardModel2 = createModel(context, () => PlaceCardModel());
    placeCardModel3 = createModel(context, () => PlaceCardModel());
    buttonModel = createModel(context, () => ButtonModel());
    bottomNavModel = createModel(context, () => BottomNavModel());
  }

  @override
  void dispose() {
    categoryChipModel1.dispose();
    categoryChipModel2.dispose();
    categoryChipModel3.dispose();
    categoryChipModel4.dispose();
    categoryChipModel5.dispose();
    placeCardModel1.dispose();
    placeCardModel2.dispose();
    placeCardModel3.dispose();
    buttonModel.dispose();
    bottomNavModel.dispose();
  }
}

import '/components/button/button_widget.dart';
import '/components/contact_card/contact_card_widget.dart';
import '/components/facility_item/facility_item_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'emergency_s_o_s_widget.dart' show EmergencySOSWidget;
import 'package:flutter/material.dart';

class EmergencySOSModel extends FlutterFlowModel<EmergencySOSWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Button.
  late ButtonModel buttonModel1;
  // Model for ContactCard.
  late ContactCardModel contactCardModel1;
  // Model for ContactCard.
  late ContactCardModel contactCardModel2;
  // Model for FacilityItem.
  late FacilityItemModel facilityItemModel1;
  // Model for FacilityItem.
  late FacilityItemModel facilityItemModel2;
  // Model for FacilityItem.
  late FacilityItemModel facilityItemModel3;
  // Model for Button.
  late ButtonModel buttonModel2;

  @override
  void initState(BuildContext context) {
    buttonModel1 = createModel(context, () => ButtonModel());
    contactCardModel1 = createModel(context, () => ContactCardModel());
    contactCardModel2 = createModel(context, () => ContactCardModel());
    facilityItemModel1 = createModel(context, () => FacilityItemModel());
    facilityItemModel2 = createModel(context, () => FacilityItemModel());
    facilityItemModel3 = createModel(context, () => FacilityItemModel());
    buttonModel2 = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    buttonModel1.dispose();
    contactCardModel1.dispose();
    contactCardModel2.dispose();
    facilityItemModel1.dispose();
    facilityItemModel2.dispose();
    facilityItemModel3.dispose();
    buttonModel2.dispose();
  }
}

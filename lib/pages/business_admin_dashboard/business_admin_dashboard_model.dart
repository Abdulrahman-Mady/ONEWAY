import '/components/branch_item/branch_item_widget.dart';
import '/components/button/button_widget.dart';
import '/components/metric_card/metric_card_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'business_admin_dashboard_widget.dart' show BusinessAdminDashboardWidget;
import 'package:flutter/material.dart';

class BusinessAdminDashboardModel
    extends FlutterFlowModel<BusinessAdminDashboardWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for MetricCard.
  late MetricCardModel metricCardModel1;
  // Model for MetricCard.
  late MetricCardModel metricCardModel2;
  // Model for MetricCard.
  late MetricCardModel metricCardModel3;
  // Model for MetricCard.
  late MetricCardModel metricCardModel4;
  // Model for Button.
  late ButtonModel buttonModel1;
  // Model for Button.
  late ButtonModel buttonModel2;
  // Model for BranchItem.
  late BranchItemModel branchItemModel;
  // Model for Button.
  late ButtonModel buttonModel3;
  // Model for Button.
  late ButtonModel buttonModel4;

  @override
  void initState(BuildContext context) {
    metricCardModel1 = createModel(context, () => MetricCardModel());
    metricCardModel2 = createModel(context, () => MetricCardModel());
    metricCardModel3 = createModel(context, () => MetricCardModel());
    metricCardModel4 = createModel(context, () => MetricCardModel());
    buttonModel1 = createModel(context, () => ButtonModel());
    buttonModel2 = createModel(context, () => ButtonModel());
    branchItemModel = createModel(context, () => BranchItemModel());
    buttonModel3 = createModel(context, () => ButtonModel());
    buttonModel4 = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    metricCardModel1.dispose();
    metricCardModel2.dispose();
    metricCardModel3.dispose();
    metricCardModel4.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
    branchItemModel.dispose();
    buttonModel3.dispose();
    buttonModel4.dispose();
  }
}

import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'nav_item_widget.dart' show NavItemWidget;
import 'package:flutter/material.dart';

class NavItemModel extends FlutterFlowModel<NavItemWidget> {
  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}

  /// Action blocks.
  Future onTap(BuildContext context) async {
    if (valueOrDefault<String>(
          widget!.target,
          'HomeDashboard',
        ) ==
        'HomeDashboard') {
      context.goNamed(HomeDashboardWidget.routeName);
    } else if (widget!.target == 'ExploreMap') {
      context.goNamed(ExploreMapWidget.routeName);
    } else if (widget!.target == 'SubmitAccessibilityReport') {
      context.pushNamed(SubmitAccessibilityReportWidget.routeName);
    } else if (widget!.target == 'UserProfile') {
      context.pushNamed(UserProfileWidget.routeName);
    } else if (widget!.target == 'FavoritesPage') {
      context.pushNamed(FavoritesPageWidget.routeName);
    } else if (widget!.target == 'NotificationsPage') {
      context.pushNamed(NotificationsPageWidget.routeName);
    } else {
      context.pushNamed(HelpSupportPageWidget.routeName);
    }
  }
}

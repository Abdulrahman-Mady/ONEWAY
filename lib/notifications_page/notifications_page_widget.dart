import '/features/account/account_pages.dart' show NotificationsCenterPage;
import 'package:flutter/material.dart';
import 'notifications_page_model.dart';
export 'notifications_page_model.dart';

/// Delegates directly to the live Firestore-backed NotificationsCenterPage.
class NotificationsPageWidget extends StatelessWidget {
  const NotificationsPageWidget({super.key});

  static String routeName = 'NotificationsPage';
  static String routePath = '/notifications';

  @override
  Widget build(BuildContext context) {
    return const NotificationsCenterPage();
  }
}
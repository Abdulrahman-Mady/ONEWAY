import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_way_egypt/core/network/connectivity_service.dart';
import 'package:one_way_egypt/widgets/offline_status_banner.dart';

void main() {
  tearDown(() {
    ConnectivityService.instance.resetForTesting();
  });

  group('ConnectivityService & OfflineStatusOverlay', () {
    testWidgets(
      'displays offline banner when disconnected, recovers with green banner, then hides',
      (tester) async {
        var onlineNow = false;
        ConnectivityService.instance.testConnectivityOverride =
            () async => onlineNow;
        ConnectivityService.instance.setOnlineForTest(
          false,
          announceReconnect: false,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: OfflineStatusOverlay(
              child: Scaffold(body: Center(child: Text('Main App'))),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('لا يوجد اتصال بالإنترنت'), findsOneWidget);
        expect(find.byKey(const Key('offline_retry_btn')), findsOneWidget);

        // Simulate internet returning and tapping Retry
        onlineNow = true;
        await tester.tap(find.byKey(const Key('offline_retry_btn')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.textContaining('تم استعادة الاتصال بالإنترنت'),
          findsOneWidget,
        );

        // Reconnected banner auto-dismisses cleanly after 3 seconds
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('تم استعادة الاتصال بالإنترنت'),
          findsNothing,
        );
        expect(find.text('Main App'), findsOneWidget);
      },
    );

    testWidgets(
      'showOfflineUploadRetryDialog preserves page state and returns retry choice',
      (tester) async {
        bool? retryResult;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    retryResult = await showOfflineUploadRetryDialog(context);
                  },
                  child: const Text('Trigger'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Trigger'));
        await tester.pumpAndSettle();

        expect(find.text('انقطع الاتصال بالإنترنت'), findsOneWidget);
        expect(find.text('إعادة المحاولة'), findsOneWidget);

        await tester.tap(find.text('إعادة المحاولة'));
        await tester.pumpAndSettle();

        expect(retryResult, isTrue);
      },
    );
  });
}

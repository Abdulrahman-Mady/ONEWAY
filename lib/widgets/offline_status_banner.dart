import 'package:flutter/material.dart';

import '/core/network/connectivity_service.dart';
import '/features/discovery/places_repository.dart';

/// Global non-intrusive connectivity status wrapper placed in `MaterialApp.builder`.
///
/// - When offline: displays a clear top status bar explaining that cached data
///   is still accessible and offering a 1-tap retry button.
/// - When connection returns: shows a brief green "Back online" confirmation
///   bar and refreshes cached place data automatically.
class OfflineStatusOverlay extends StatefulWidget {
  const OfflineStatusOverlay({
    super.key,
    required this.child,
    this.isEnglish = false,
  });

  final Widget child;
  final bool isEnglish;

  @override
  State<OfflineStatusOverlay> createState() => _OfflineStatusOverlayState();
}

class _OfflineStatusOverlayState extends State<OfflineStatusOverlay> {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    ConnectivityService.instance.justReconnectedNotifier.addListener(
      _onReconnectedChanged,
    );
  }

  @override
  void dispose() {
    ConnectivityService.instance.justReconnectedNotifier.removeListener(
      _onReconnectedChanged,
    );
    super.dispose();
  }

  void _onReconnectedChanged() {
    if (ConnectivityService.instance.justReconnectedNotifier.value) {
      // Clear stale empty/cached place lists so screens fetch fresh server data.
      PlacesRepository.instance.invalidateCache();
    }
  }

  Future<void> _retryConnection() async {
    if (_checking) return;
    setState(() => _checking = true);
    await ConnectivityService.instance.checkHasInternet();
    if (mounted) {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isOnlineNotifier,
      builder: (context, isOnline, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: ConnectivityService.instance.justReconnectedNotifier,
          builder: (context, justReconnected, __) {
            final showBanner = !isOnline || justReconnected;
            return Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: showBanner
                      ? Material(
                          key: ValueKey<String>(
                            isOnline ? 'online_banner' : 'offline_banner',
                          ),
                          color: isOnline
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB45309),
                          elevation: 2,
                          child: SafeArea(
                            bottom: false,
                            child: Semantics(
                              liveRegion: true,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isOnline
                                          ? Icons.wifi_rounded
                                          : Icons.wifi_off_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isOnline
                                            ? (widget.isEnglish
                                                ? 'Back online — syncing latest data'
                                                : 'تم استعادة الاتصال بالإنترنت — جاري التحديث')
                                            : (widget.isEnglish
                                                ? 'No internet connection — showing saved data. Uploads require internet.'
                                                : 'لا يوجد اتصال بالإنترنت — يتم عرض البيانات المحفوظة، والرفع يتطلب اتصالاً'),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                    if (!isOnline) ...[
                                      const SizedBox(width: 8),
                                      TextButton(
                                        key: const Key('offline_retry_btn'),
                                        onPressed:
                                            _checking ? null : _retryConnection,
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.18),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          minimumSize: const Size(0, 32),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: _checking
                                            ? const SizedBox.square(
                                                dimension: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text(
                                                widget.isEnglish
                                                    ? 'Retry'
                                                    : 'فحص الاتصال',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(child: widget.child),
              ],
            );
          },
        );
      },
    );
  }
}

/// Reusable, user-friendly dialog shown when an upload/write action fails due
/// to missing or dropped internet connection. Guarantees the user that none of
/// their form inputs or selected photos were lost and provides 1-tap Retry.
Future<bool> showOfflineUploadRetryDialog(
  BuildContext context, {
  String title = 'انقطع الاتصال بالإنترنت',
  String message =
      'لا يوجد اتصال بالإنترنت حالياً. جميع بياناتك وصورك محفوظة كما هي في الصفحة ولن تضيع — تأكد من الشبكة ثم اضغط «إعادة المحاولة».',
}) async {
  final retry = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogCtx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Color(0xFFB45309),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.55),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('إغلاق والبقاء في الصفحة'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    ),
  );
  return retry == true;
}

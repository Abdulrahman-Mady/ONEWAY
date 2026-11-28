import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/nav/nav.dart';
import '/pages/splash_onboarding/splash_onboarding_widget.dart';

/// A widget that catches errors in its subtree and displays a friendly error UI.
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
    this.fallback,
  });

  final Widget child;
  final void Function(FlutterErrorDetails)? onError;
  final Widget Function(BuildContext, Object, StackTrace?)? fallback;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();

  static void _defaultOnError(FlutterErrorDetails details) {
    debugPrint('ErrorBoundary caught error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  }
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    // Register error handler
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      widget.onError?.call(details);
      ErrorBoundary._defaultOnError(details);
      if (mounted) {
        setState(() {
          _error = details.exception;
          _stackTrace = details.stack;
        });
      }
    };
  }

  @override
  void dispose() {
    // Reset error handler
    FlutterError.onError = ErrorBoundary._defaultOnError;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallback?.call(context, _error!, _stackTrace) ??
          _DefaultErrorFallback(
            error: _error!,
            stackTrace: _stackTrace,
            onRetry: () => setState(() {
              _error = null;
              _stackTrace = null;
            }),
          );
    }
    return widget.child;
  }
}

class _DefaultErrorFallback extends StatelessWidget {
  const _DefaultErrorFallback({
    required this.error,
    this.stackTrace,
    required this.onRetry,
  });

  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;
    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: theme.error,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'حدث خطأ غير متوقع',
                  style: theme.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'نعتذر، واجه التطبيق مشكلة. يرجى المحاولة مرة أخرى.',
                  style: theme.bodyMedium.copyWith(
                    color: theme.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (isDebug) ...[
                  const Divider(),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        '$error${stackTrace != null ? '\n\n$stackTrace' : ''}',
                        style: theme.labelSmall.copyWith(
                          fontFamily: 'monospace',
                          color: theme.error,
                        ),
                      ),
                    ),
                  ),
                  const Divider(),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    // Navigate to home or login
                    context.goNamed(SplashOnboardingWidget.routeName);
                  },
                  child: Text(
                    'العودة للرئيسية',
                    style: theme.labelLarge.copyWith(
                      color: theme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A wrapper for async operations with loading and error states.
class AsyncValueWidget<T> extends StatefulWidget {
  const AsyncValueWidget({
    super.key,
    required this.future,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.initialData,
  });

  final Future<T> future;
  final Widget Function(BuildContext, T) builder;
  final Widget Function(BuildContext)? loadingBuilder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final T? initialData;

  @override
  State<AsyncValueWidget<T>> createState() => _AsyncValueWidgetState<T>();
}

class _AsyncValueWidgetState<T> extends State<AsyncValueWidget<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.future;
  }

  @override
  void didUpdateWidget(covariant AsyncValueWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.future != widget.future) {
      _future = widget.future;
    }
  }

  void _retry() {
    setState(() {
      _future = widget.future;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      initialData: widget.initialData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingBuilder?.call(context) ??
              Center(
                child: CircularProgressIndicator(
                  color: FlutterFlowTheme.of(context).primary,
                ),
              );
        }
        if (snapshot.hasError) {
          return widget.errorBuilder?.call(context, snapshot.error!, snapshot.stackTrace) ??
              _DefaultErrorFallback(
                error: snapshot.error!,
                stackTrace: snapshot.stackTrace,
                onRetry: _retry,
              );
        }
        return widget.builder(context, snapshot.data!);
      },
    );
  }
}

/// Mixin for widgets that need to show loading states.
mixin LoadingMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    if (mounted) {
      setState(() => _isLoading = value);
    }
  }

  Future<void> runWithLoading(Future<void> Function() action) async {
    setLoading(true);
    try {
      await action();
    } finally {
      if (mounted) setLoading(false);
    }
  }
}

/// A button that shows loading state while async operation is running.
class AsyncButton extends StatefulWidget {
  const AsyncButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.loadingChild,
    this.variant = 'primary',
    this.size = 'medium',
    this.fullWidth = false,
    this.enabled = true,
  });

  final Future<void> Function() onPressed;
  final Widget child;
  final Widget? loadingChild;
  final String variant;
  final String size;
  final bool fullWidth;
  final bool enabled;

  @override
  State<AsyncButton> createState() => _AsyncButtonState();
}

class _AsyncButtonState extends State<AsyncButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading || !widget.enabled) return;

    setState(() => _isLoading = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.6,
      child: AbsorbPointer(
        absorbing: _isLoading || !widget.enabled,
        child: FilledButton(
          onPressed: _handlePress,
          style: FilledButton.styleFrom(
            minimumSize: widget.fullWidth ? const Size(double.infinity, 48) : null,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          child: _isLoading
              ? widget.loadingChild ??
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.onPrimary),
                    ),
                  )
              : widget.child,
        ),
      ),
    );
  }
}

/// Network connectivity status widget.
class ConnectivityStatus extends StatefulWidget {
  const ConnectivityStatus({
    super.key,
    this.child,
    this.showWhenOffline = true,
  });

  final Widget? child;
  final bool showWhenOffline;

  @override
  State<ConnectivityStatus> createState() => _ConnectivityStatusState();
}

class _ConnectivityStatusState extends State<ConnectivityStatus> {
  bool _isOnline = true;
  late Stream<List<ConnectivityResult>> _connectivityStream;

  @override
  void initState() {
    super.initState();
    _connectivityStream = Connectivity().onConnectivityChanged;
    _connectivityStream.listen((results) {
      if (mounted) {
        setState(() => _isOnline = results.any((r) => r != ConnectivityResult.none));
      }
    });
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() => _isOnline = results.any((r) => r != ConnectivityResult.none));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOnline && widget.showWhenOffline) {
      return Container(
        width: double.infinity,
        color: FlutterFlowTheme.of(context).warning,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'أنت غير متصل بالإنترنت',
              style: FlutterFlowTheme.of(context).labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return widget.child ?? const SizedBox.shrink();
  }
}
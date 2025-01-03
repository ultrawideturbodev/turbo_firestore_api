import 'dart:async';
import 'dart:ui';
import 'package:turbo_firestore_api/extensions/completer_extension.dart';

/// A utility class that provides debouncing functionality for callbacks.
///
/// TurboDebouncer helps manage the rate at which callbacks are executed by
/// delaying their execution until a specified duration has passed without
/// any new calls.
///
/// Example:
/// ```dart
/// final debouncer = TurboDebouncer(duration: Duration(milliseconds: 300));
///
/// // Call the debounced function
/// debouncer.run(() {
///   print('This will only execute after 300ms of inactivity');
/// });
///
/// // Cancel if needed
/// debouncer.tryCancel();
/// ```
class TurboDebouncer {
  /// Creates a new [TurboDebouncer] instance.
  ///
  /// Parameters:
  /// - [duration] - The duration to wait before executing the callback
  TurboDebouncer({
    required Duration duration,
  }) : _duration = duration;

  final Duration _duration;
  Timer? _timer;
  VoidCallback? _voidCallback;
  Completer? _isRunningCompleter;

  /// Runs the provided callback after the debounce duration.
  ///
  /// If called multiple times within the duration, only the last callback
  /// will be executed after the duration has elapsed.
  ///
  /// Parameters:
  /// - [voidCallback] - The callback to execute after the debounce duration
  void run(VoidCallback voidCallback) {
    _isRunningCompleter ??= Completer();
    _voidCallback = voidCallback;
    tryCancel();
    _timer = Timer(
      _duration,
      () {
        voidCallback();
        _voidCallback = null;
        _isRunningCompleter?.completeIfNotComplete();
        _isRunningCompleter = null;
      },
    );
  }

  /// Cancels any pending callback execution.
  void tryCancel() => _timer?.cancel();

  /// Cancels any pending callback and executes it immediately.
  void tryCancelAndRunNow() {
    tryCancel();
    _voidCallback?.call();
    _voidCallback = null;
  }

  /// Future that completes when the current debounced operation is done.
  Future get isDone => _isRunningCompleter?.future ?? Future.value();
}

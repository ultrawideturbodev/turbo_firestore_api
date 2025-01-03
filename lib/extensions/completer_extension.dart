import 'dart:async';

/// Extension on [Completer] that provides additional utility methods for handling completion states.
extension CompleterExtension<T> on Completer<T> {
  /// Completes the [Completer] with the given [value] only if it hasn't been completed yet.
  ///
  /// This method is useful when you want to safely complete a [Completer] without throwing
  /// a [StateError] if it's already been completed. This is particularly helpful in cleanup
  /// scenarios or when dealing with multiple potential completion points.
  ///
  /// Example:
  /// ```dart
  /// final completer = Completer<String>();
  /// // This will complete the completer
  /// completer.completeIfNotComplete('first');
  /// // This will be ignored since the completer is already complete
  /// completer.completeIfNotComplete('second');
  /// ```
  ///
  /// Parameters:
  /// - [value]: Optional value to complete the [Completer] with. If not provided,
  ///   completes with null for nullable types.
  void completeIfNotComplete([FutureOr<T>? value]) {
    if (!isCompleted) {
      complete(value);
    }
  }
}

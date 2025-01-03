import 'dart:async';
import 'dart:collection';
import 'dart:ui';

/// A utility class that provides mutual exclusion functionality.
///
/// TurboMutex helps manage concurrent access to resources by ensuring
/// that only one operation can execute at a time. Operations are queued
/// and executed in order.
///
/// Example:
/// ```dart
/// final mutex = TurboMutex();
///
/// // Run operations with mutual exclusion
/// await mutex.lockAndRun(
///   run: (unlock) async {
///     // Do something that needs exclusive access
///     await someOperation();
///     unlock(); // Release the lock
///   },
/// );
///
/// // Clean up
/// mutex.dispose();
/// ```
class TurboMutex {
  /// Queue of completers for managing locks.
  final _completerQueue = Queue<Completer>();

  /// Locks the mutex, runs the provided function, and releases the lock.
  ///
  /// The provided [run] function receives an [unlock] callback that must be called
  /// when the operation is complete to release the lock.
  ///
  /// Parameters:
  /// - [run] - Function to execute with the lock
  ///
  /// Returns the result of the [run] function
  FutureOr<T> lockAndRun<T>({
    required FutureOr<T> Function(VoidCallback unlock) run,
  }) async {
    final completer = Completer();
    _completerQueue.add(completer);
    if (_completerQueue.first != completer) {
      await _completerQueue.removeFirst().future;
    }
    final value = await run(() => completer.complete());
    _completerQueue.remove(completer);
    return value;
  }

  /// Disposes of the mutex by clearing all pending operations.
  void dispose() => _completerQueue.clear();
}

import 'package:loglytics/loglytics.dart';
import 'package:turbo_firestore_api/models/sensitive_data.dart';

/// A logger for the TurboFirestoreApi that handles different log levels and sensitive data.
///
/// This class provides logging functionality with different severity levels:
/// - Info: General information messages
/// - Success: Successful operation messages
/// - Warning: Warning messages that don't prevent operation
/// - Error: Error messages with optional stack traces
///
/// Example:
/// ```dart
/// class MyLogger extends TurboFirestoreLogger {
///   const MyLogger() : super(
///     turboLogLevel: TurboLogLevel.info,
///     hideInProduction: true
///   );
/// }
/// ```
class TurboFirestoreLogger {
  /// Creates a logger with customizable settings.
  ///
  /// The [turboLogLevel] determines which log messages are shown, defaulting to [TurboLogLevel.debug].
  /// If [hideInProduction] is true, logging is disabled in release mode.
  /// Set [showSensitiveData] to false to hide sensitive data in logs.
  /// The prefix parameters customize the prefix text for each log type.
  TurboFirestoreLogger({
    Log? log,
    bool hideInProduction = true,
    this.showSensitiveData = true,
  }) : _log = log ?? Log(location: 'TurboFirestoreApi');

  final Log _log;

  /// Whether to include sensitive data in log messages
  final bool showSensitiveData;

  /// Logs an informational message.
  ///
  /// The [message] is the main log text. Optional [sensitiveData] will be logged
  /// if [showSensitiveData] is true.
  void debug({
    required String message,
    SensitiveData? sensitiveData,
  }) {
    _log.debug(message);
    if (showSensitiveData && sensitiveData != null) {
      _log.debug(sensitiveData.toString());
    }
  }

  /// Logs a success message.
  ///
  /// The [message] is the main log text. Optional [sensitiveData] will be logged
  /// if [showSensitiveData] is true.
  void info({
    required String message,
    SensitiveData? sensitiveData,
  }) {
    _log.info(message);
    if (showSensitiveData && sensitiveData != null) {
      _log.info(sensitiveData.toString());
    }
  }

  /// Logs a warning message.
  ///
  /// The [message] is the main log text. Optional [sensitiveData] will be logged
  /// if [showSensitiveData] is true.
  void warning({
    required String message,
    SensitiveData? sensitiveData,
  }) {
    _log.warning(message);
    if (showSensitiveData && sensitiveData != null) {
      _log.warning(sensitiveData.toString());
    }
  }

  /// Logs an error message with optional stack trace information.
  ///
  /// The [message] is the main error description.
  /// [error] is the error object that was caught.
  /// [stackTrace] is the stack trace associated with the error.
  /// [label] and [maxFrames] customize the stack trace output.
  /// [sensitiveData] provides additional context that will be logged if [showSensitiveData] is true.
  void error({
    Object? error,
    StackTrace? stackTrace,
    required SensitiveData? sensitiveData,
    required String message,
  }) {
    _log.error(
      message,
      error: error,
      stackTrace: stackTrace,
    );
    if (showSensitiveData && sensitiveData != null) {
      _log.error(sensitiveData.toString());
    }
  }
}

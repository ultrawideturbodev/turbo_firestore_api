import 'package:turbo_response/turbo_response.dart';

/// A base class for objects that can be written to Firestore.
///
/// This abstract class provides the foundation for objects that need to be
/// stored in Firestore. It enforces validation and serialization requirements
/// through two key methods:
/// - [validate] for ensuring data integrity before writing
/// - [toJson] for converting the object to a Firestore-compatible format
///
/// Example:
/// ```dart
/// class User extends TurboWriteable {
///   User({required this.name, required this.age});
///
///   final String name;
///   final int age;
///
///   @override
///   TurboResponse<void>? validate<void>() {
///     if (name.isEmpty) {
///       return TurboResponse.fail(message: 'Name cannot be empty');
///     }
///     if (age < 0) {
///       return TurboResponse.fail(message: 'Age cannot be negative');
///     }
///     return null;
///   }
///
///   @override
///   Map<String, dynamic> toJson() => {
///     'name': name,
///     'age': age,
///   };
/// }
/// ```
abstract class TurboWriteable {
  /// Validates the object's data before writing to Firestore.
  ///
  /// Returns a [TurboResponse] with error details if the validation fails,
  /// or `null` if the object is valid and can be written to Firestore.
  ///
  /// The type parameter [T] allows for returning specific error data types
  /// when validation fails.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// TurboResponse<String>? validate<String>() {
  ///   if (!isValid) {
  ///     return TurboResponse.fail(
  ///       message: 'Validation failed',
  ///       data: 'Custom error data'
  ///     );
  ///   }
  ///   return null;
  /// }
  /// ```
  TurboResponse<T>? validate<T>();

  /// Converts the object to a Firestore-compatible map.
  ///
  /// Returns a [Map] with string keys and dynamic values that can be
  /// directly written to Firestore. All complex objects should be
  /// converted to basic Firestore-supported types.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Map<String, dynamic> toJson() => {
  ///   'field1': value1,
  ///   'field2': value2,
  /// };
  /// ```
  Map<String, dynamic> toJson();
}

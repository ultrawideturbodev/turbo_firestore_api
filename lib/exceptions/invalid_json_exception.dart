/// Exception thrown when JSON data from Firestore is invalid or cannot be parsed
///
/// This exception provides detailed context about the invalid JSON data,
/// including where it came from and what went wrong. It's useful for:
/// - Debugging data conversion issues
/// - Tracking down malformed documents
/// - Validating data integrity
/// - Error reporting and logging
///
/// Example:
/// ```dart
/// try {
///   final user = User.fromJson(json);
/// } catch (e) {
///   throw InvalidJsonException(
///     id: documentId,
///     path: 'users',
///     api: 'UserApi',
///     data: json,
///   );
/// }
/// ```
class InvalidJsonException implements Exception {
  /// Creates a new invalid JSON exception with context
  ///
  /// Parameters:
  /// [id] unique identifier of the document with invalid JSON
  /// [path] Firestore path where the document was found
  /// [api] name of the API that encountered the error
  /// [data] the actual invalid JSON data
  const InvalidJsonException({
    required this.id,
    required this.path,
    required this.api,
    required this.data,
  });

  /// The document ID where the invalid JSON was found
  final String id;

  /// The Firestore path where the document exists
  final String path;

  /// The name of the API that encountered the invalid JSON
  final String api;

  /// The actual invalid JSON data that caused the error
  final Map<String, dynamic> data;

  @override
  String toString() {
    return 'InvalidJsonException{id: $id, path: $path, api: $api, data: $data}';
  }
}

/// A function type for building document instances with metadata.
///
/// Parameters:
/// - [id] - Document identifier
/// - [timestamp] - Creation or modification time
/// - [userId] - Associated user identifier
///
/// Example:
/// ```dart
/// TurboDocBuilder<User> userBuilder = (id, timestamp, userId) {
///   return User(id: id, createdAt: timestamp, createdBy: userId);
/// };
/// ```
typedef TurboDocBuilder<T> = T Function(
  String id,
  DateTime timestamp,
  String? userId,
);

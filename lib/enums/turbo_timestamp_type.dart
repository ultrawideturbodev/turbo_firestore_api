import 'package:turbo_firestore_api/extensions/turbo_map_extension.dart';

/// Defines how timestamps should be managed in Firestore documents
///
/// This enum controls the automatic addition of createdAt and updatedAt timestamps
/// to documents. It supports tracking document creation time, last update time,
/// or both. These timestamps are useful for:
/// - Sorting documents by age
/// - Tracking modification history
/// - Implementing caching strategies
/// - Auditing document changes
///
/// Example:
/// ```dart
/// // Track both creation and update times
/// api.createDoc(
///   writeable: user,
///   timestampType: TurboTimestampType.createdAndUpdated,
/// );
///
/// // Track only updates
/// api.updateDoc(
///   writeable: user,
///   timestampType: TurboTimestampType.updated,
/// );
/// ```
enum TurboTimestampType {
  /// Adds only a creation timestamp to the document
  ///
  /// Use this when you need to track when a document was first created,
  /// Adds only an update timestamp to the document
  ///
  /// Use this when you need to track the last modification time,
  /// but don't need to preserve the original creation time
  createdAt,

  /// Adds both creation and update timestamps to the document
  ///
  /// Use this for full timestamp tracking, preserving both the original
  /// creation time and the last modification time
  updatedAt,

  /// creation time and the last modification time
  createdAtAndUpdatedAt,

  /// Does not add any timestamps to the document
  ///
  /// Use this when timestamp tracking is not needed or when you want
  /// to manage timestamps manually
  none;

  /// Adds the appropriate timestamps to a map based on the timestamp type
  ///
  /// Parameters:
  /// [map] the map to add timestamps to
  /// [createdAtFieldName] name of the created timestamp field
  /// [updatedAtFieldName] name of the updated timestamp field
  ///
  /// Returns a new map containing the specified timestamps
  ///
  /// Example:
  /// ```dart
  /// final data = {'name': 'John'};
  /// final withTimestamps = TurboTimestampType.createdAndUpdated.add(
  ///   data,
  ///   createdAtFieldName: 'createdAt',
  ///   updatedAtFieldName: 'updatedAt',
  /// );
  /// ```
  Map<E, T> add<E, T>(
    Map<E, T> map, {
    String? createdAtFieldName,
    String? updatedAtFieldName,
  }) {
    switch (this) {
      case TurboTimestampType.createdAt:
        return map.withCreatedAt(
          createdAtFieldName: createdAtFieldName!,
        );
      case TurboTimestampType.updatedAt:
        return map.withUpdatedAt(
          updatedAtFieldName: updatedAtFieldName!,
        );
      case TurboTimestampType.createdAtAndUpdatedAt:
        return map.withCreatedAtAndUpdatedAt(
          createdAtFieldName: createdAtFieldName!,
          updatedAtFieldName: updatedAtFieldName!,
        );
      case TurboTimestampType.none:
        return map;
    }
  }
}

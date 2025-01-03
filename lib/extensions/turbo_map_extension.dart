import 'package:cloud_firestore/cloud_firestore.dart';

/// Extension on [Map] that provides utility methods for working with Firestore documents.
///
/// This extension adds functionality to handle common Firestore document operations such as:
/// - Managing document references
/// - Handling document IDs
/// - Managing timestamp fields (createdAt/updatedAt)
extension TurboMapExtension on Map {
  /// Adds a local document reference field to the map if specified conditions are met.
  ///
  /// This method is used to maintain a local reference to the Firestore document without storing it in the database.
  /// It's particularly useful for maintaining document references in DTOs and models.
  ///
  /// This method is used to maintain a local reference to the Firestore document without storing it in the database.
  /// It's particularly useful for maintaining document references in DTOs and models.
  ///
  /// Example:
  /// ```dart
  /// final data = {'name': 'John'};
  /// final docRef = FirebaseFirestore.instance.collection('users').doc('123');
  /// final result = data.tryAddLocalDocumentReference(
  ///   docRef,
  ///   referenceFieldName: '_ref',
  ///
  /// Parameters:
  /// - [documentReference]: The Firestore document reference to add
  /// - [referenceFieldName]: The field name under which to store the reference
  /// - [tryAddLocalDocumentReference]: Whether to attempt adding the reference
  ///
  /// Returns:
  /// A new [Map] with the document reference added if conditions are met
  ///   tryAddLocalDocumentReference: true,
  /// );
  /// ```
  Map<T, E> tryAddLocalDocumentReference<T, E>(
    DocumentReference documentReference, {
    required String referenceFieldName,
    required bool tryAddLocalDocumentReference,
  }) =>
      tryAddLocalDocumentReference && containsKey(referenceFieldName)
          ? this as Map<T, E>
          : (this..[referenceFieldName] = documentReference) as Map<T, E>;

  /// This method is used to clean up local document references that were added for internal use.
  ///

  /// Removes a local document reference field from the map if specified conditions are met.
  ///
  /// Example:
  /// ```dart
  /// final data = {'name': 'John', '_ref': docRef};
  /// final result = data.tryRemoveLocalDocumentReference(
  ///   referenceFieldName: '_ref',
  ///
  /// Parameters:
  /// - [referenceFieldName]: The field name of the reference to remove
  /// - [tryRemoveLocalDocumentReference]: Whether to attempt removing the reference
  ///
  /// Returns:
  /// A new [Map] with the document reference removed if conditions are met
  ///   tryRemoveLocalDocumentReference: true,
  /// );
  /// ```
  Map<T, E> tryRemoveLocalDocumentReference<T, E>({
    required String referenceFieldName,
    required bool tryRemoveLocalDocumentReference,
  }) =>
      tryRemoveLocalDocumentReference && containsKey(referenceFieldName)
          ? (this..remove(referenceFieldName)) as Map<T, E>
          : this as Map<T, E>;

  /// This method is used to maintain a local ID field without storing it in the database.
  /// It's particularly useful for maintaining document IDs in DTOs and models.
  ///

  /// Adds a local ID field to the map if specified conditions are met.
  ///
  /// Example:
  /// ```dart
  /// final data = {'name': 'John'};
  /// final result = data.tryAddLocalId(
  ///   '123',
  ///   idFieldName: '_id',
  ///
  /// Parameters:
  /// - [id]: The ID to add
  /// - [idFieldName]: The field name under which to store the ID
  /// - [tryAddLocalId]: Whether to attempt adding the ID
  ///
  /// Returns:
  /// A new [Map] with the ID added if conditions are met
  ///   tryAddLocalId: true,
  /// );
  /// ```
  Map<T, E> tryAddLocalId<T, E>(
    String id, {
    required String idFieldName,
    required bool tryAddLocalId,
  }) =>
      tryAddLocalId && containsKey(idFieldName)
          ? this as Map<T, E>
          : (this..[idFieldName] = id) as Map<T, E>;

  /// This method is used to clean up local ID fields that were added for internal use.
  ///

  /// Removes a local ID field from the map if specified conditions are met.
  ///
  /// Example:
  /// ```dart
  /// final data = {'name': 'John', '_id': '123'};
  /// final result = data.tryRemoveLocalId(
  ///   idFieldName: '_id',
  ///
  /// Parameters:
  /// - [idFieldName]: The field name of the ID to remove
  /// - [tryRemoveLocalId]: Whether to attempt removing the ID
  ///
  /// Returns:
  /// A new [Map] with the ID removed if conditions are met
  ///   tryRemoveLocalId: true,
  /// );
  /// ```
  Map<T, E> tryRemoveLocalId<T, E>({
    required String idFieldName,
    required bool tryRemoveLocalId,
  }) =>
      tryRemoveLocalId && containsKey(idFieldName)
          ? (this..remove(idFieldName)) as Map<T, E>
          : this as Map<T, E>;

  /// This method is used to automatically track when a document was last updated.
  /// The field name is configurable through the Firestore API setup.
  ///

  /// Adds an 'updatedAt' timestamp field to the map.
  ///
  /// Example:
  /// ```dart
  ///
  /// Parameters:
  /// - [updatedAtFieldName]: The field name under which to store the timestamp
  ///
  /// Returns:
  /// A new [Map] with the updated timestamp added
  /// final data = {'name': 'John'};
  /// final result = data.withUpdated(updatedAtFieldName: 'updatedAt');
  /// ```
  Map<T, E> withUpdatedAt<T, E>({required String updatedAtFieldName}) =>
      (this..[updatedAtFieldName] = Timestamp.now()) as Map<T, E>;

  /// This method is used to automatically track when a document was created.
  /// The field name is configurable through the Firestore API setup.
  ///

  /// Adds a 'createdAt' timestamp field to the map.
  ///
  /// Example:
  /// ```dart
  ///
  /// Parameters:
  /// - [createdAtFieldName]: The field name under which to store the timestamp
  ///
  /// Returns:
  /// A new [Map] with the created timestamp added
  /// final data = {'name': 'John'};
  /// final result = data.withCreated(createdAtFieldName: 'createdAt');
  /// ```
  Map<T, E> withCreatedAt<T, E>({required String createdAtFieldName}) =>
      (this..[createdAtFieldName] = Timestamp.now()) as Map<T, E>;

  /// This method is used to automatically track both creation and last update times.
  /// The field names are configurable through the Firestore API setup.
  ///

  /// Adds both 'created' and 'updatedAt' timestamp fields to the map.
  ///
  /// Example:
  /// ```dart
  /// final data = {'name': 'John'};
  /// final result = data.withCreatedAndUpdated(
  ///   createdAtFieldName: 'createdAt',
  ///
  /// Parameters:
  /// - [createdAtFieldName]: The field name under which to store the creation timestamp
  /// - [updatedAtFieldName]: The field name under which to store the update timestamp
  ///
  /// Returns:
  /// A new [Map] with both created and updated timestamps added
  ///   updatedAtFieldName: 'updatedAt',
  /// );
  /// ```
  Map<T, E> withCreatedAtAndUpdatedAt<T, E>({
    required String createdAtFieldName,
    required String updatedAtFieldName,
  }) {
    final now = Timestamp.now();
    return (this
      ..[createdAtFieldName] = now
      ..[updatedAtFieldName] = now) as Map<T, E>;
  }
}

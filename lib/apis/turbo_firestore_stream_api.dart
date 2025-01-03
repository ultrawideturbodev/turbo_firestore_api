part of 'turbo_firestore_api.dart';

/// Extension that adds stream operations to [TurboFirestoreApi]
///
/// Provides methods for real-time document updates from Firestore
///
/// Features:
/// - Collection streaming
/// - Single document streaming
/// - Query-based streaming
/// - Type-safe streaming
/// - Automatic conversion
/// - Collection group support
///
/// Example:
/// ```dart
/// final api = TurboFirestoreApi<User>();
/// final stream = api.streamAll();
/// stream.listen((snapshot) {
///   print('Got ${snapshot.docs.length} users');
/// });
/// ```
///
/// See also:
/// [TurboFirestoreListApi] one-time list operations
/// [TurboFirestoreSearchApi] search operations
extension TurboFirestoreStreamApi<T> on TurboFirestoreApi<T> {
  /// Streams all documents from a collection
  ///
  /// Returns real-time updates for all documents
  /// Provides raw Firestore data without conversion
  ///
  /// Returns [Stream] of [QuerySnapshot] containing:
  /// - Document data
  /// - Document metadata
  /// - Document changes
  ///
  /// Features:
  /// - Real-time updates
  /// - Raw data access
  /// - Local ID field management
  /// - Document reference handling
  ///
  /// Example:
  /// ```dart
  /// final stream = api.streamAll();
  /// stream.listen((snapshot) {
  ///   for (var doc in snapshot.docs) {
  ///     print('User data: ${doc.data()}');
  ///   }
  /// });
  /// ```
  ///
  /// See also:
  /// [streamAllWithConverter] type-safe streaming
  /// [streamByQuery] filtered streaming
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAll() {
    _log.debug(
      message: 'Finding stream..',
      sensitiveData: SensitiveData(
        path: _collectionPath(),
      ),
    );
    return listCollectionReference().snapshots();
  }

  /// Streams and converts all documents from a collection
  ///
  /// Returns real-time updates with automatic conversion to [T]
  /// Requires [_fromJson] configuration
  ///
  /// Returns [Stream] of [List<T>] containing:
  /// - Converted document data
  /// - Real-time updates
  ///
  /// Features:
  /// - Automatic type conversion
  /// - Real-time updates
  /// - Local ID field management
  /// - Document reference handling
  ///
  /// Example:
  /// ```dart
  /// final stream = api.streamAllWithConverter();
  /// stream.listen((users) {
  ///   for (var user in users) {
  ///     print('User name: ${user.name}');
  ///   }
  /// });
  /// ```
  ///
  /// See also:
  /// [streamAll] raw data streaming
  /// [streamByQueryWithConverter] filtered type-safe streaming
  Stream<List<T>> streamAllWithConverter() {
    _log.debug(
      message: 'Finding stream with converter..',
      sensitiveData: SensitiveData(
        path: _collectionPath(),
      ),
    );
    return listCollectionReferenceWithConverter().snapshots().map(
          (event) => event.docs.map((e) => e.data()).toList(),
        );
  }

  /// Streams documents matching a query
  ///
  /// Returns real-time updates for filtered documents
  /// Provides raw Firestore data without conversion
  ///
  /// Parameters:
  /// [collectionReferenceQuery] custom query to filter documents
  /// [whereDescription] description of the query for logging
  ///
  /// Returns [Stream] of [List] containing:
  /// - Document data
  /// - Real-time updates
  ///
  /// Features:
  /// - Custom query support
  /// - Real-time updates
  /// - Raw data access
  /// - Error logging
  ///
  /// Example:
  /// ```dart
  /// final stream = api.streamByQuery(
  ///   collectionReferenceQuery: (ref) => ref.where('age', isGreaterThan: 18),
  ///   whereDescription: 'Adult users',
  /// );
  /// stream.listen((users) {
  ///   print('Got ${users.length} adult users');
  /// });
  /// ```
  ///
  /// See also:
  /// [streamByQueryWithConverter] type-safe query streaming
  /// [streamAll] unfiltered streaming
  Stream<List<Map<String, dynamic>>> streamByQuery({
    required CollectionReferenceDef<Map<String, dynamic>>?
        collectionReferenceQuery,
    required String whereDescription,
  }) {
    _log.debug(
      message: 'Finding stream by query..',
      sensitiveData: SensitiveData(
        path: _collectionPath(),
        whereDescription: whereDescription,
      ),
    );
    final query = collectionReferenceQuery?.call(listCollectionReference()) ??
        listCollectionReference();
    return query.snapshots().map(
          (event) => event.docs.map((e) => e.data()).toList(),
        );
  }

  /// Streams and converts documents matching a query
  ///
  /// Returns real-time updates with automatic conversion to [T]
  /// Requires [_fromJson] configuration
  ///
  /// Parameters:
  /// [collectionReferenceQuery] custom query to filter documents
  /// [whereDescription] description of the query for logging
  ///
  /// Returns [Stream] of [List<T>] containing:
  /// - Converted document data
  /// - Real-time updates
  ///
  /// Features:
  /// - Custom query support
  /// - Automatic type conversion
  /// - Real-time updates
  /// - Error logging
  ///
  /// Example:
  /// ```dart
  /// final stream = api.streamByQueryWithConverter(
  ///   collectionReferenceQuery: (ref) => ref.where('age', isGreaterThan: 18),
  ///   whereDescription: 'Adult users',
  /// );
  /// stream.listen((users) {
  ///   for (var user in users) {
  ///     print('Adult user: ${user.name}');
  ///   }
  /// });
  /// ```
  ///
  /// See also:
  /// [streamByQuery] raw data query streaming
  /// [streamAllWithConverter] unfiltered type-safe streaming
  Stream<List<T>> streamByQueryWithConverter({
    CollectionReferenceDef<T>? collectionReferenceQuery,
    required String whereDescription,
  }) {
    _log.debug(
      message: 'Finding stream by query with converter..',
      sensitiveData: SensitiveData(
        path: _collectionPath(),
        whereDescription: whereDescription,
      ),
    );
    final query = collectionReferenceQuery
            ?.call(listCollectionReferenceWithConverter()) ??
        listCollectionReferenceWithConverter();
    return query.snapshots().map(
          (event) => event.docs.map((e) => e.data()).toList(),
        );
  }

  /// Streams a single document
  ///
  /// Returns real-time updates for a specific document
  /// Provides raw Firestore data without conversion
  ///
  /// Parameters:
  /// [id] unique identifier of the document
  /// [collectionPathOverride] override path for collection groups
  ///
  /// Returns [Stream] of [DocumentSnapshot] containing:
  /// - Document data
  /// - Document metadata
  /// - Real-time updates
  ///
  /// Features:
  /// - Real-time updates
  /// - Raw data access
  /// - Local ID field management
  /// - Document reference handling
  ///
  /// Example:
  /// ```dart
  /// final stream = api.streamByDocId(id: 'user-123');
  /// stream.listen((snapshot) {
  ///   if (snapshot.exists) {
  ///     print('User data: ${snapshot.data()}');
  ///   }
  /// });
  /// ```
  ///
  /// See also:
  /// [streamDocByIdWithConverter] type-safe document streaming
  /// [streamAll] collection streaming
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamByDocId({
    required String id,
    String? collectionPathOverride,
  }) {
    final docRef =
        getDocRefById(id: id, collectionPathOverride: collectionPathOverride);
    _log.debug(
      message: 'Finding doc stream..',
      sensitiveData: SensitiveData(
        path: collectionPathOverride ?? _collectionPath(),
        id: id,
      ),
    );
    return docRef.snapshots();
  }

  /// Streams and converts a single document
  ///
  /// Returns real-time updates with automatic conversion to [T]
  /// Requires [_fromJson] configuration
  ///
  /// Parameters:
  /// [id] unique identifier of the document
  /// [collectionPathOverride] override path for collection groups
  ///
  /// Returns [Stream] of [T?] containing:
  /// - Converted document data
  /// - Real-time updates
  ///
  /// Features:
  /// - Automatic type conversion
  /// - Real-time updates
  /// - Local ID field management
  /// - Document reference handling
  ///
  /// Example:
  /// ```dart
  /// final stream = api.streamDocByIdWithConverter(id: 'user-123');
  /// stream.listen((user) {
  ///   if (user != null) {
  ///     print('User name: ${user.name}');
  ///   }
  /// });
  /// ```
  ///
  /// See also:
  /// [streamByDocId] raw data document streaming
  /// [streamAllWithConverter] collection type-safe streaming
  Stream<T?> streamDocByIdWithConverter({
    required String id,
    String? collectionPathOverride,
  }) {
    assert(
      _isCollectionGroup == (collectionPathOverride != null),
      'Firestore does not support finding a document by id when communicating with a collection group, '
      'therefore, you must specify the collectionPathOverride containing all parent collection and document ids '
      'in order to make this method work.',
    );
    final docRefWithConverter = getDocRefByIdWithConverter(
      id: id,
      collectionPathOverride: collectionPathOverride,
    );
    _log.debug(
      message: 'Finding doc stream with converter..',
      sensitiveData: SensitiveData(
        path: collectionPathOverride ?? _collectionPath(),
        id: id,
      ),
    );
    return docRefWithConverter.snapshots().map((e) => e.data());
  }
}

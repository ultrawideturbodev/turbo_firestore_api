part of 'turbo_firestore_api.dart';

/// Extension that adds list operations to [TurboFirestoreApi]
///
/// Provides methods for retrieving multiple documents from Firestore
///
/// Features:
/// - Query-based document retrieval
/// - Type-safe document conversion
/// - Collection reference access
/// - Local ID and reference field management
/// - Collection group queries
/// - Custom query support
///
/// Example:
/// ```dart
/// final api = TurboFirestoreApi<User>();
/// final response = await api.listAll();
/// ```
///
/// See also:
/// [TurboFirestoreGetApi] single document retrieval
/// [TurboFirestoreSearchApi] search operations
extension TurboFirestoreListApi<T> on TurboFirestoreApi<T> {
  /// Lists documents matching a custom query
  ///
  /// Returns raw Firestore data without type conversion
  /// Useful for complex queries with raw data access
  ///
  /// Parameters:
  /// [collectionReferenceQuery] custom query to filter documents
  /// [whereDescription] description of the query for logging
  ///
  /// Returns [TurboResponse] containing:
  /// - Success with list of document data
  /// - Fail with error details on operation failure
  ///
  /// Features:
  /// - Custom query support
  /// - Raw data access
  /// - Local ID field management
  /// - Error logging
  ///
  /// Example:
  /// ```dart
  /// final response = await api.listByQuery(
  ///   collectionReferenceQuery: (ref) => ref.where('age', isGreaterThan: 18),
  ///   whereDescription: 'Finding adult users',
  /// );
  /// response.when(
  ///   success: (users) => print('Found ${users.length} adults'),
  ///   fail: (error) => print('Error $error'),
  /// );
  /// ```
  ///
  /// See also:
  /// [listByQueryWithConverter] type-safe queries
  /// [listAll] retrieve all documents
  Future<TurboResponse<List<Map<String, dynamic>>>> listByQuery({
    required CollectionReferenceDef<Map<String, dynamic>>
        collectionReferenceQuery,
    required String whereDescription,
  }) async {
    try {
      _log.debug(
        message: 'Finding without converter, with custom query..',
        sensitiveData: SensitiveData(
          path: _collectionPath(),
          whereDescription: whereDescription,
        ),
      );
      final result = (await collectionReferenceQuery(
        listCollectionReference(),
      ).get(_getOptions))
          .docs
          .map(
            (e) => e.data(),
          )
          .toList();
      _logResultLength(result);
      return TurboResponse.success(result: result);
    } catch (error, stackTrace) {
      _log.error(
        message: 'Unable to find documents with custom query',
        sensitiveData: SensitiveData(
          path: _collectionPath(),
          whereDescription: whereDescription,
        ),
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.fail(error: error);
    }
  }

  /// Lists and converts documents matching a custom query
  ///
  /// Returns documents converted to type [T] using [_fromJson]
  /// Provides type-safe access to filtered Firestore data
  ///
  /// Parameters:
  /// [collectionReferenceQuery] custom query to filter documents
  /// [whereDescription] description of the query for logging
  ///
  /// Returns [TurboResponse] containing:
  /// - Success with list of typed documents
  /// - Fail with error details on operation failure
  ///
  /// Features:
  /// - Custom query support
  /// - Automatic type conversion
  /// - Local ID field management
  /// - Document reference handling
  /// - Error logging
  ///
  /// Example:
  /// ```dart
  /// final response = await api.listByQueryWithConverter(
  ///   collectionReferenceQuery: (ref) => ref.where('age', isGreaterThan: 18),
  ///   whereDescription: 'Finding adult users',
  /// );
  /// response.when(
  ///   success: (users) => print('Found ${users.length} adults'),
  ///   fail: (error) => print('Error $error'),
  /// );
  /// ```
  ///
  /// See also:
  /// [listByQuery] raw data queries
  /// [listAllWithConverter] retrieve all typed documents
  Future<TurboResponse<List<T>>> listByQueryWithConverter({
    required CollectionReferenceDef<T> collectionReferenceQuery,
    required String whereDescription,
  }) async {
    try {
      _log.debug(
        message: 'Finding with converter, with custom query..',
        sensitiveData: SensitiveData(
          path: _collectionPath(),
          whereDescription: whereDescription,
        ),
      );
      final result = (await collectionReferenceQuery(
                  listCollectionReferenceWithConverter())
              .get(_getOptions))
          .docs
          .map((e) => e.data())
          .toList();
      _logResultLength(result);
      return TurboResponse.success(result: result);
    } catch (error, stackTrace) {
      _log.error(
        message: 'Unable to find documents with custom query',
        sensitiveData: SensitiveData(
          path: _collectionPath(),
          whereDescription: whereDescription,
        ),
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.fail(error: error);
    }
  }

  /// Lists all documents in the collection
  ///
  /// Returns raw Firestore data without type conversion
  /// Useful for bulk data access or when type conversion is not needed
  ///
  /// Returns [TurboResponse] containing:
  /// - Success with list of document data
  /// - Fail with error details on operation failure
  ///
  /// Features:
  /// - Raw data access
  /// - Local ID field management
  /// - Document reference handling
  /// - Error logging
  ///
  /// Example:
  /// ```dart
  /// final response = await api.listAll();
  /// response.when(
  ///   success: (users) => print('Found ${users.length} users'),
  ///   fail: (error) => print('Error $error'),
  /// );
  /// ```
  ///
  /// See also:
  /// [listAllWithConverter] type-safe retrieval
  /// [listByQuery] filtered queries
  Future<TurboResponse<List<Map<String, dynamic>>>> listAll() async {
    try {
      _log.debug(
        message: 'Finding all documents without converter..',
        sensitiveData: SensitiveData(
          path: _collectionPath(),
        ),
      );
      final result = (await listCollectionReference().get(_getOptions))
          .docs
          .map(
            (e) => e.data(),
          )
          .toList();
      _logResultLength(result);
      return TurboResponse.success(result: result);
    } catch (error, stackTrace) {
      _log.error(
          message: 'Unable to find all documents',
          sensitiveData: SensitiveData(
            path: _collectionPath(),
          ),
          error: error,
          stackTrace: stackTrace);
      return TurboResponse.fail(error: error);
    }
  }

  /// Lists and converts all documents in the collection
  ///
  /// Returns documents converted to type [T] using [_fromJson]
  /// Provides type-safe access to all collection data
  ///
  /// Returns [TurboResponse] containing:
  /// - Success with list of typed documents
  /// - Fail with error details on operation failure
  ///
  /// Features:
  /// - Automatic type conversion
  /// - Local ID field management
  /// - Document reference handling
  /// - Error logging
  ///
  /// Example:
  /// ```dart
  /// final response = await api.listAllWithConverter();
  /// response.when(
  ///   success: (users) => print('Found ${users.length} users'),
  ///   fail: (error) => print('Error $error'),
  /// );
  /// ```
  ///
  /// See also:
  /// [listAll] raw data access
  /// [listByQueryWithConverter] filtered type-safe queries
  Future<TurboResponse<List<T>>> listAllWithConverter() async {
    try {
      _log.debug(
        message: 'Finding all documents with converter..',
        sensitiveData: SensitiveData(
          path: _collectionPath(),
        ),
      );
      final result =
          (await listCollectionReferenceWithConverter().get(_getOptions))
              .docs
              .map((e) => e.data())
              .toList();
      _logResultLength(result);
      return TurboResponse.success(result: result);
    } catch (error, stackTrace) {
      _log.error(
        message: 'Unable to find all documents',
        sensitiveData: SensitiveData(
          path: _collectionPath(),
        ),
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.fail(error: error);
    }
  }

  /// Gets a collection reference for raw data access
  ///
  /// Returns [Query] for raw Firestore operations
  /// Includes converters for field management
  ///
  /// Features:
  /// - Raw data access
  /// - Local ID field management
  /// - Document reference handling
  /// - Collection group support
  ///
  /// Example:
  /// ```dart
  /// final ref = api.listCollectionReference();
  /// final snapshot = await ref.where('age', isGreaterThan: 18).get();
  /// print('Found ${snapshot.docs.length} adults');
  /// ```
  ///
  /// See also:
  /// [listCollectionReferenceWithConverter] type-safe references
  /// [listByQuery] direct query access
  Query<Map<String, dynamic>> listCollectionReference() {
    _log.debug(
      message: 'Finding collection..',
      sensitiveData: SensitiveData(
        path: _collectionPath(),
      ),
    );
    return (_isCollectionGroup
            ? _firebaseFirestore.collectionGroup(_collectionPath())
            : _firebaseFirestore.collection(_collectionPath()))
        .withConverter<Map<String, dynamic>>(
      fromFirestore: (snapshot, _) {
        final data = snapshot.data() ?? {};
        try {
          return data
              .tryAddLocalId(
                snapshot.id,
                idFieldName: _idFieldName,
                tryAddLocalId: _tryAddLocalId,
              )
              .tryAddLocalDocumentReference(
                snapshot.reference,
                referenceFieldName: _documentReferenceFieldName,
                tryAddLocalDocumentReference: _tryAddLocalDocumentReference,
              );
        } catch (error) {
          _log.error(
            message:
                'Unexpected error caught while adding local id and document reference',
            sensitiveData: SensitiveData(
              path: _collectionPath(),
              id: snapshot.id,
              data: data,
            ),
          );
          rethrow;
        }
      },
      toFirestore: (data, _) {
        try {
          return data
              .tryRemoveLocalId(
                idFieldName: _idFieldName,
                tryRemoveLocalId: _tryAddLocalId,
              )
              .tryRemoveLocalDocumentReference(
                referenceFieldName: _documentReferenceFieldName,
                tryRemoveLocalDocumentReference: _tryAddLocalDocumentReference,
              );
        } catch (error) {
          _log.error(
            message: 'Could not find collection',
            sensitiveData: SensitiveData(
              path: _collectionPath(),
            ),
          );
          rethrow;
        }
      },
    );
  }

  /// Gets a collection reference with type conversion
  ///
  /// Returns [Query] with automatic conversion between Firestore and [T]
  /// Requires [_fromJson] and [_toJson] configuration
  ///
  /// Features:
  /// - Automatic type conversion
  /// - Local ID field management
  /// - Document reference handling
  /// - Collection group support
  /// - Error handling with [_fromJsonError]
  ///
  /// Example:
  /// ```dart
  /// final ref = api.listCollectionReferenceWithConverter<User>();
  /// final snapshot = await ref.where('age', isGreaterThan: 18).get();
  /// final users = snapshot.docs.map((doc) => doc.data()).toList();
  /// print('Found ${users.length} adult users');
  /// ```
  ///
  /// See also:
  /// [listCollectionReference] raw data references
  /// [listByQueryWithConverter] direct type-safe queries
  Query<T> listCollectionReferenceWithConverter() {
    _log.debug(
      message: 'Finding collection with converter..',
      sensitiveData: SensitiveData(
        path: _collectionPath(),
      ),
    );
    return (_isCollectionGroup
            ? _firebaseFirestore.collectionGroup(_collectionPath())
            : _firebaseFirestore.collection(_collectionPath()))
        .withConverter<T>(
      fromFirestore: (snapshot, _) {
        final data = snapshot.data() ?? {};
        try {
          return _fromJson!(
            data
                .tryAddLocalId(
                  snapshot.id,
                  idFieldName: _idFieldName,
                  tryAddLocalId: _tryAddLocalId,
                )
                .tryAddLocalDocumentReference(
                  snapshot.reference,
                  referenceFieldName: _documentReferenceFieldName,
                  tryAddLocalDocumentReference: _tryAddLocalDocumentReference,
                ),
          );
        } catch (error, stackTrace) {
          _log.error(
            message:
                'Unexpected error caught while adding local id and document reference',
            sensitiveData: SensitiveData(
              path: _collectionPath(),
              id: snapshot.id,
              data: data,
            ),
            stackTrace: stackTrace,
            error: InvalidJsonException(
              id: snapshot.id,
              path: snapshot.reference.path,
              api: runtimeType.toString(),
              data: data,
            ),
          );
          _log.debug(
              message: 'Returning error response..', sensitiveData: null);
          try {
            return _fromJsonError!(
              data
                  .tryAddLocalId(
                    snapshot.id,
                    idFieldName: _idFieldName,
                    tryAddLocalId: _tryAddLocalId,
                  )
                  .tryAddLocalDocumentReference(
                    snapshot.reference,
                    referenceFieldName: _documentReferenceFieldName,
                    tryAddLocalDocumentReference: _tryAddLocalDocumentReference,
                  ),
            );
          } catch (error, stackTrace) {
            _log.error(
              message:
                  'Unexpected error caught while adding local id and document reference',
              sensitiveData: SensitiveData(
                path: _collectionPath(),
                id: snapshot.id,
                data: data,
              ),
              error: error,
              stackTrace: stackTrace,
            );
          }
          rethrow;
        }
      },
      toFirestore: (data, _) {
        try {
          return _toJson!(data)
              .tryRemoveLocalId(
                idFieldName: _idFieldName,
                tryRemoveLocalId: _tryAddLocalId,
              )
              .tryRemoveLocalDocumentReference(
                referenceFieldName: _documentReferenceFieldName,
                tryRemoveLocalDocumentReference: _tryAddLocalDocumentReference,
              );
        } catch (error) {
          _log.error(
            message:
                'Unexpected error caught while removing local id and document reference',
            sensitiveData: SensitiveData(
              path: _collectionPath(),
              data: data,
            ),
          );
          rethrow;
        }
      },
    );
  }
}

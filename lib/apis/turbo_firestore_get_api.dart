part of 'turbo_firestore_api.dart';

/// Extension that adds read/get operations to [TurboFirestoreApi]
///
/// This extension provides methods for retrieving documents from Firestore
///
/// Features:
/// - Single document retrieval
/// - Type-safe document conversion
/// - Document reference access
/// - Local ID and reference field management
/// - Collection group queries
/// - Custom collection path overrides
///
/// Example:
/// ```dart
/// final api = TurboFirestoreApi<User>();
/// final response = await api.getById(id: 'user-123');
/// ```
///
/// See also:
/// - [TurboFirestoreCreateApi] document creation and updates
/// - [TurboFirestoreDeleteApi] document deletion
extension TurboFirestoreGetApi<T> on TurboFirestoreApi<T> {
  /// Retrieves a document by its unique identifier
  ///
  /// Returns raw Firestore data without type conversion. Useful for direct data access
  /// or when type conversion is not needed
  ///
  /// Parameters:
  /// [id] unique identifier of the document
  /// [collectionPathOverride] override path for collection groups
  ///
  /// Returns [TurboResponse] containing:
  /// - Success with document data
  /// - Empty fail when document not found
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
  /// final response = await api.getById(id: 'user-123');
  /// response.when(
  ///   success: (data) => print('Found user ${data['name']}'),
  ///   fail: (error) => print('Error $error'),
  /// );
  /// ```
  ///
  /// See also:
  /// - [getByIdWithConverter] type-safe document retrieval
  /// - [getDocRefById] document reference access
  Future<TurboResponse<Map<String, dynamic>>> getById({
    required String id,
    String? collectionPathOverride,
  }) async {
    assert(
      _isCollectionGroup == (collectionPathOverride != null),
      'Firestore does not support finding a document by id when communicating with a collection group, '
      'therefore, you must specify the collectionPathOverride containing all parent collection and document ids '
      'in order to make this method work.',
    );
    try {
      _log.debug(
        message: 'Finding without converter..',
        sensitiveData: SensitiveData(
          path: collectionPathOverride ?? _collectionPath(),
          id: id,
        ),
      );
      final result = (await getDocRefById(
        id: id,
        collectionPathOverride: collectionPathOverride,
      ).get(_getOptions))
          .data();
      if (result != null) {
        _log.info(
          message: 'Found item!',
          sensitiveData: null,
        );
        return TurboResponse.success(result: result);
      } else {
        _log.warning(
          message: 'Found nothing!',
          sensitiveData: null,
        );
        return TurboResponse.emptyFail();
      }
    } catch (error, stackTrace) {
      _log.error(
        message: 'Unable to find document',
        sensitiveData: SensitiveData(
          path: collectionPathOverride ?? _collectionPath(),
          id: id,
        ),
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.fail(error: error);
    }
  }

  /// Retrieves and converts a document by its unique identifier
  ///
  /// Returns document data converted to type [T] using [_fromJson]
  /// Provides type-safe access to Firestore data
  ///
  /// Parameters:
  /// [id] unique identifier of the document
  /// [collectionPathOverride] override path for collection groups
  ///
  /// Returns [TurboResponse] containing:
  /// - Success with typed document data
  /// - Empty fail when document not found
  /// - Fail with error details on operation failure
  ///
  /// Features:
  /// - Automatic type conversion
  /// - Local ID field management
  /// - Document reference handling
  /// - Type-safe error handling
  /// - Error logging
  ///
  /// Example:
  /// ```dart
  /// final response = await api.getByIdWithConverter(id: 'user-123');
  /// response.when(
  ///   success: (user) => print('Found user ${user.name}'),
  ///   fail: (error) => print('Error $error'),
  /// );
  /// ```
  ///
  /// See also:
  /// - [getById] raw data access
  /// - [getDocRefByIdWithConverter] typed document reference
  Future<TurboResponse<T>> getByIdWithConverter({
    required String id,
    String? collectionPathOverride,
  }) async {
    assert(
      _isCollectionGroup == (collectionPathOverride != null),
      'Firestore does not support finding a document by id when communicating with a collection group, '
      'therefore, you must specify the collectionPathOverride containing all parent collection and document ids '
      'in order to make this method work.',
    );
    try {
      _log.debug(
        message: 'Finding with converter..',
        sensitiveData: SensitiveData(
          path: collectionPathOverride ?? _collectionPath(),
          id: id,
        ),
      );
      final result = (await getDocRefByIdWithConverter(
        id: id,
        collectionPathOverride: collectionPathOverride,
      ).get(_getOptions))
          .data();
      if (result != null) {
        _log.info(
          message: 'Found item!',
          sensitiveData: null,
        );
        return TurboResponse.success(result: result);
      } else {
        _log.warning(
          message: 'Found nothing!',
          sensitiveData: null,
        );
        return TurboResponse.emptyFail();
      }
    } catch (error, stackTrace) {
      _log.error(
        message: 'Unable to find document',
        error: error,
        stackTrace: stackTrace,
        sensitiveData: SensitiveData(
          path: collectionPathOverride ?? _collectionPath(),
          id: id,
        ),
      );
      return TurboResponse.fail(error: error);
    }
  }

  /// Gets a document reference by ID for raw data access
  ///
  /// Returns [DocumentReference] for Firestore operations
  /// Includes converters for field management
  ///
  /// Parameters:
  /// [id] unique identifier of the document
  /// [collectionPathOverride] override path for collection groups
  ///
  /// Features:
  /// - Raw data access
  /// - Local ID field management
  /// - Document reference handling
  /// - Automatic field cleanup
  ///
  /// Example:
  /// ```dart
  /// final docRef = api.getDocRefById(id: 'user-123');
  /// final snapshot = await docRef.get();
  /// if (snapshot.exists) {
  ///   print('User data ${snapshot.data()}');
  /// }
  /// ```
  ///
  /// See also:
  /// - [getDocRefByIdWithConverter] type-safe references
  /// - [getById] direct data access
  DocumentReference<Map<String, dynamic>> getDocRefById({
    required String id,
    String? collectionPathOverride,
  }) {
    assert(
      _isCollectionGroup == (collectionPathOverride != null),
      'Firestore does not support finding a document by id when communicating with a collection group, '
      'therefore, you must specify the collectionPathOverride containing all parent collection and document ids '
      'in order to make this method work.',
    );
    _log.debug(
      message: 'Finding document..',
      sensitiveData: SensitiveData(
        path: collectionPathOverride ?? _collectionPath(),
        id: id,
      ),
    );
    return _firebaseFirestore
        .doc('${collectionPathOverride ?? _collectionPath()}/$id')
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
              path: collectionPathOverride ?? _collectionPath(),
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
            message:
                'Unexpected error caught while removing local id and document reference',
            sensitiveData: SensitiveData(
              path: collectionPathOverride ?? _collectionPath(),
              id: id,
              data: data,
            ),
          );
          rethrow;
        }
      },
    );
  }

  /// Gets a document reference with type conversion
  ///
  /// Returns [DocumentReference] with automatic conversion between Firestore and [T]
  /// Requires [_fromJson] and [_toJson] configuration
  ///
  /// Parameters:
  /// [id] unique identifier of the document
  /// [collectionPathOverride] override path for collection groups
  ///
  /// Features:
  /// - Automatic type conversion
  /// - Local ID field management
  /// - Document reference handling
  /// - Type-safe operations
  ///
  /// Example:
  /// ```dart
  /// final docRef = api.getDocRefByIdWithConverter<User>(id: 'user-123');
  /// final snapshot = await docRef.get();
  /// if (snapshot.exists) {
  ///   final user = snapshot.data();
  ///   print('User name ${user.name}');
  /// }
  /// ```
  ///
  /// See also:
  /// - [getDocRefById] raw data references
  /// - [getByIdWithConverter] direct typed access
  DocumentReference<T> getDocRefByIdWithConverter({
    required String id,
    String? collectionPathOverride,
  }) {
    assert(
      _isCollectionGroup == (collectionPathOverride != null),
      'Firestore does not support finding a document by id when communicating with a collection group, '
      'therefore, you must specify the collectionPathOverride containing all parent collection and document ids '
      'in order to make this method work.',
    );
    _log.debug(
      message: 'Finding document with converter..',
      sensitiveData: SensitiveData(
        path: collectionPathOverride ?? _collectionPath(),
        id: id,
      ),
    );
    return _firebaseFirestore
        .doc('${collectionPathOverride ?? _collectionPath()}/$id')
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
              path: collectionPathOverride ?? _collectionPath(),
              id: snapshot.id,
              data: data,
            ),
            error: InvalidJsonException(
              id: snapshot.id,
              path: snapshot.reference.path,
              api: runtimeType.toString(),
              data: data,
            ),
            stackTrace: stackTrace,
          );
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
                path: collectionPathOverride ?? _collectionPath(),
                id: snapshot.id,
                data: data,
              ),
              error: error,
              stackTrace: stackTrace,
            );
            rethrow;
          }
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
              path: collectionPathOverride ?? _collectionPath(),
              id: id,
              data: data,
            ),
          );
          rethrow;
        }
      },
    );
  }

  /// Gets a document snapshot for raw data access
  ///
  /// Returns [DocumentSnapshot] containing raw document data and metadata
  /// Useful for accessing document metadata with data
  ///
  /// Parameters:
  /// [id] unique identifier of the document
  /// [collectionPathOverride] override path for collection groups
  ///
  /// Features:
  /// - Metadata access
  /// - Raw data access
  /// - Local ID field management
  /// - Document reference handling
  ///
  /// Example:
  /// ```dart
  /// final snapshot = await api.getDocSnapshotById(id: 'user-123');
  /// if (snapshot.exists) {
  ///   print('Created at ${snapshot.metadata.creationTime}');
  ///   print('Data ${snapshot.data()}');
  /// }
  /// ```
  ///
  /// See also:
  /// - [getDocSnapshotByIdWithConverter] typed snapshots
  /// - [getDocRefById] reference access
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocSnapshotById({
    required String id,
    String? collectionPathOverride,
  }) async {
    assert(
      _isCollectionGroup == (collectionPathOverride != null),
      'Firestore does not support finding a document by id when communicating with a collection group, '
      'therefore, you must specify the collectionPathOverride containing all parent collection and document ids '
      'in order to make this method work.',
    );
    final docRef =
        getDocRefById(id: id, collectionPathOverride: collectionPathOverride);
    _log.debug(
      message: 'Finding document snapshot..',
      sensitiveData: SensitiveData(
        path: collectionPathOverride ?? _collectionPath(),
        id: id,
      ),
    );
    return docRef.get(_getOptions);
  }

  /// Gets a document snapshot with type conversion
  ///
  /// Returns [DocumentSnapshot] with automatic conversion to type [T]
  /// Useful for accessing metadata with typed data
  ///
  /// Parameters:
  /// [id] unique identifier of the document
  /// [collectionPathOverride] override path for collection groups
  ///
  /// Features:
  /// - Automatic type conversion
  /// - Metadata access
  /// - Local ID field management
  /// - Document reference handling
  ///
  /// Example:
  /// ```dart
  /// final snapshot = await api.getDocSnapshotByIdWithConverter<User>(id: 'user-123');
  /// if (snapshot.exists) {
  ///   final user = snapshot.data();
  ///   print('Created at ${snapshot.metadata.creationTime}');
  ///   print('User name ${user.name}');
  /// }
  /// ```
  ///
  /// See also:
  /// - [getDocSnapshotById] raw data snapshots
  /// - [getDocRefByIdWithConverter] reference access
  Future<DocumentSnapshot<T>> getDocSnapshotByIdWithConverter({
    required String id,
    String? collectionPathOverride,
  }) async {
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
      message: 'Finding doc snapshot with converter..',
      sensitiveData: SensitiveData(
        path: collectionPathOverride ?? _collectionPath(),
        id: id,
      ),
    );
    return docRefWithConverter.get(_getOptions);
  }
}

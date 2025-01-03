part of 'turbo_firestore_api.dart';

/// Extension that adds update operations to [TurboFirestoreApi]
///
/// Provides methods for updating existing documents in Firestore
///
/// Features:
/// - Single document updates
/// - Batch operations
/// - Transaction support
/// - Automatic timestamp management
/// - Validation through [TurboWriteable]
///
/// Example:
/// ```dart
/// final api = TurboFirestoreApi<User>();
/// final user = User(name: 'John Updated');
/// final response = await api.updateDoc(
///   writeable: user,
///   id: 'user-123',
/// );
/// ```
///
/// See also:
/// [TurboFirestoreCreateApi] document creation
/// [TurboFirestoreDeleteApi] document deletion
extension TurboFirestoreUpdateApi<T> on TurboFirestoreApi<T> {
  /// Updates an existing document in Firestore
  ///
  /// Modifies document data while preserving fields not included in [writeable]
  /// Automatically manages timestamps based on [timestampType]
  ///
  /// Parameters:
  /// [writeable] data to update, must implement [TurboWriteable]
  /// [id] unique identifier of the document
  /// [writeBatch] optional batch to include this operation in
  /// [timestampType] type of timestamp to add when updating
  /// [collectionPathOverride] override path for collection groups
  /// [transaction] optional transaction to include this operation in
  ///
  /// Returns [TurboResponse] containing:
  /// - Success with document reference
  /// - Fail with validation or operation errors
  ///
  /// Features:
  /// - Automatic validation
  /// - Timestamp management
  /// - Batch operation support
  /// - Transaction support
  /// - Error logging
  ///
  /// Example:
  /// ```dart
  /// final user = User(name: 'John Updated');
  /// final response = await api.updateDoc(
  ///   writeable: user,
  ///   id: 'user-123',
  /// );
  /// response.when(
  ///   success: (ref) => print('Updated user ${ref.id}'),
  ///   fail: (error) => print('Error $error'),
  /// );
  /// ```
  ///
  /// See also:
  /// [updateDocs] batch updates
  /// [createDoc] document creation
  Future<TurboResponse<DocumentReference>> updateDoc({
    required TurboWriteable writeable,
    required String id,
    WriteBatch? writeBatch,
    TurboTimestampType timestampType = TurboTimestampType.updatedAt,
    String? collectionPathOverride,
    Transaction? transaction,
  }) async {
    assert(
      _isCollectionGroup == (collectionPathOverride != null),
      'Firestore does not support finding a document by id when communicating with a collection group, '
      'therefore, you must specify the collectionPathOverride containing all parent collection and document ids '
      'in order to make this method work.',
    );
    try {
      _log.debug(
        message: 'Checking if writeable is valid..',
        sensitiveData: null,
      );
      final TurboResponse<DocumentReference>? invalidResponse =
          writeable.validate();
      if (invalidResponse != null) {
        _log.warning(
          message: 'TurboWriteable was invalid!',
          sensitiveData: null,
        );
        return invalidResponse;
      }
      _log.info(message: 'TurboWriteable is valid!', sensitiveData: null);
      _log.debug(
        message: 'Updating document..',
        sensitiveData: SensitiveData(
          path: collectionPathOverride ?? _collectionPath(),
          id: id,
          isBatch: writeBatch != null,
          isTransaction: transaction != null,
          updateTimeStampType: timestampType,
        ),
      );
      if (writeBatch != null) {
        _log.debug(
          message: 'WriteBatch was not null! Updating with batch..',
          sensitiveData: null,
        );
        final lastBatchResponse = await updateDocs(
          writeable: writeable,
          id: id,
          writeBatch: writeBatch,
          timestampType: timestampType,
          collectionPathOverride: collectionPathOverride,
        );
        _log.debug(
          message: 'Checking if batchUpdate was successful..',
          sensitiveData: null,
        );
        return _handleBatchOperation(lastBatchResponse);
      } else {
        _log.debug(
          message: 'WriteBatch was null! Updating without batch..',
          sensitiveData: null,
        );
        final documentReference = getDocRefById(
            id: id, collectionPathOverride: collectionPathOverride);
        _log.debug(
          message: 'Creating JSON..',
          sensitiveData: null,
        );
        final writeableAsJson = timestampType.add(
          writeable.toJson(),
          createdAtFieldName: _createdAtFieldName,
          updatedAtFieldName: _updatedAtFieldName,
        );
        if (transaction == null) {
          _log.debug(
            message: 'Updating data with documentReference.update..',
            sensitiveData: SensitiveData(
              path: collectionPathOverride ?? _collectionPath(),
              id: documentReference.id,
              data: writeableAsJson,
            ),
          );
          await documentReference.update(writeableAsJson);
        } else {
          _log.debug(
            message: 'Updating data with transaction.update..',
            sensitiveData: SensitiveData(
              path: collectionPathOverride ?? _collectionPath(),
              id: documentReference.id,
              data: writeableAsJson,
            ),
          );
          transaction.update(
              getDocRefById(id: documentReference.id), writeableAsJson);
        }
        _log.info(
          message: 'Updating data done!',
          sensitiveData: null,
        );
        return TurboResponse.success(result: documentReference);
      }
    } catch (error, stackTrace) {
      _log.error(
        message: 'Unable to update document',
        sensitiveData: SensitiveData(
          path: collectionPathOverride ?? _collectionPath(),
          id: id,
          isBatch: writeBatch != null,
          updateTimeStampType: timestampType,
        ),
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.fail(error: error);
    }
  }

  /// Updates documents using a batch operation
  ///
  /// Modifies multiple documents atomically while preserving unchanged fields
  /// Automatically manages timestamps based on [timestampType]
  ///
  /// Parameters:
  /// [writeable] data to update, must implement [TurboWriteable]
  /// [id] unique identifier of the document
  /// [writeBatch] optional existing batch to add to
  /// [timestampType] type of timestamp to add when updating
  /// [collectionPathOverride] override path for collection groups
  ///
  /// Returns [TurboResponse] containing:
  /// - Success with batch and document reference
  /// - Fail with validation or operation errors
  ///
  /// Features:
  /// - Atomic updates
  /// - Automatic validation
  /// - Timestamp management
  /// - Creates new batch if none provided
  /// - Error logging
  ///
  /// Example:
  /// ```dart
  /// final batch = firestore.batch();
  /// final user = User(name: 'John Updated');
  /// final response = await api.updateDocs(
  ///   writeable: user,
  ///   id: 'user-123',
  ///   writeBatch: batch,
  /// );
  /// response.when(
  ///   success: (result) async {
  ///     await result.writeBatch.commit();
  ///     print('Updated user ${result.documentReference.id}');
  ///   },
  ///   fail: (error) => print('Error $error'),
  /// );
  /// ```
  ///
  /// See also:
  /// [updateDoc] single document updates
  /// [createDocs] batch creation
  Future<TurboResponse<WriteBatchWithReference<Map<String, dynamic>>>>
      updateDocs({
    required TurboWriteable writeable,
    required String id,
    WriteBatch? writeBatch,
    TurboTimestampType timestampType = TurboTimestampType.updatedAt,
    String? collectionPathOverride,
  }) async {
    assert(
      _isCollectionGroup == (collectionPathOverride != null),
      'Firestore does not support finding a document by id when communicating with a collection group, '
      'therefore, you must specify the collectionPathOverride containing all parent collection and document ids '
      'in order to make this method work.',
    );
    final TurboResponse<WriteBatchWithReference<Map<String, dynamic>>>?
        invalidResponse = writeable.validate();
    if (invalidResponse != null) {
      _log.warning(
        message: 'TurboWriteable was invalid!',
        sensitiveData: null,
      );
      return invalidResponse;
    }
    try {
      _log.info(message: 'TurboWriteable is valid!', sensitiveData: null);
      _log.debug(
        message: 'Creating document with batch..',
        sensitiveData: SensitiveData(
          path: collectionPathOverride ?? _collectionPath(),
          id: id,
          isBatch: writeBatch != null,
          updateTimeStampType: timestampType,
        ),
      );
      final nullSafeWriteBatch = writeBatch ?? this.writeBatch;
      final documentReference = getDocRefById(id: id);
      _log.debug(message: 'Creating JSON..', sensitiveData: null);
      final writeableAsJson = timestampType.add(
        writeable.toJson(),
        createdAtFieldName: _createdAtFieldName,
        updatedAtFieldName: _updatedAtFieldName,
      );
      _log.debug(
        message: 'Updating data with writeBatch.update..',
        sensitiveData: SensitiveData(
          path: collectionPathOverride ?? _collectionPath(),
          id: documentReference.id,
          data: writeableAsJson,
        ),
      );
      nullSafeWriteBatch.update(
        documentReference,
        writeableAsJson,
      );
      _log.info(
        message:
            'Adding update to batch done! Returning WriteBatchWithReference..',
        sensitiveData: null,
      );
      return TurboResponse.success(
        result: WriteBatchWithReference(
          writeBatch: nullSafeWriteBatch,
          documentReference: documentReference,
        ),
      );
    } catch (error, stackTrace) {
      _log.error(
        message: 'Unable to update document with batch',
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
}

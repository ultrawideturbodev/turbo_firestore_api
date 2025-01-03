part of 'turbo_firestore_api.dart';

/// Extension that adds delete operations to [TurboFirestoreApi]
///
/// Provides methods for removing documents from Firestore
///
/// Features:
/// - Single document deletion
/// - Batch operations
/// - Transaction support
/// - Collection group support
/// - Error handling
///
/// Example:
/// ```dart
/// final api = TurboFirestoreApi<User>();
/// final response = await api.deleteDoc(id: 'user-123');
/// ```
///
/// See also:
/// [TurboFirestoreUpdateApi] document updates
/// [TurboFirestoreCreateApi] document creation
extension TurboFirestoreDeleteApi<T> on TurboFirestoreApi<T> {
  /// Deletes a document from Firestore
  ///
  /// Permanently removes document and all its data
  /// Supports batch and transaction operations
  ///
  /// Parameters:
  /// [id] unique identifier of the document
  /// [writeBatch] optional batch to include this operation in
  /// [collectionPathOverride] override path for collection groups
  /// [transaction] optional transaction to include this operation in
  ///
  /// Returns [TurboResponse] containing:
  /// - Empty success when document is deleted
  /// - Empty fail on operation failure
  ///
  /// Features:
  /// - Batch operation support
  /// - Transaction support
  /// - Collection group support
  /// - Error logging
  ///
  /// Example:
  /// ```dart
  /// final response = await api.deleteDoc(id: 'user-123');
  /// response.when(
  ///   success: (_) => print('Deleted user'),
  ///   fail: (error) => print('Error $error'),
  /// );
  /// ```
  ///
  /// See also:
  /// [deleteDocs] batch deletion
  /// [updateDoc] document updates
  Future<TurboResponse<void>> deleteDoc({
    required String id,
    WriteBatch? writeBatch,
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
        message: 'Deleting document..',
        sensitiveData: SensitiveData(
          path: collectionPathOverride ?? _collectionPath(),
          id: id,
          isBatch: writeBatch != null,
        ),
      );
      if (writeBatch != null) {
        _log.debug(
          message: 'WriteBatch was not null! Deleting with batch..',
          sensitiveData: null,
        );
        final lastBatchResponse = await deleteDocs(
          id: id,
          writeBatch: writeBatch,
          collectionPathOverride: collectionPathOverride,
        );
        _log.debug(
          message: 'Checking if batchDelete was successful..',
          sensitiveData: null,
        );
        final batchResult = _handleBatchResponse(lastBatchResponse);
        if (batchResult != null) {
          _log.debug(
            message: 'Last batch was added with success! Committing..',
            sensitiveData: null,
          );
          await batchResult.writeBatch.commit();
          _log.info(
            message: 'Committing writeBatch done!',
            sensitiveData: null,
          );
          return TurboResponse.emptySuccess();
        } else {
          _log.error(
            message: 'Last batch failed!',
            sensitiveData: null,
          );
          return TurboResponse.emptyFail();
        }
      } else {
        _log.debug(
          message: 'WriteBatch was null! Deleting without batch..',
          sensitiveData: null,
        );
        final documentReference = getDocRefById(
            id: id, collectionPathOverride: collectionPathOverride);
        if (transaction == null) {
          _log.debug(
            message: 'Deleting data with documentReference.delete..',
            sensitiveData: null,
          );
          await documentReference.delete();
        } else {
          transaction.delete(getDocRefById(id: documentReference.id));
        }
        _log.info(
          message: 'Deleting data done!',
          sensitiveData: null,
        );
        return TurboResponse.emptySuccess();
      }
    } catch (error, stackTrace) {
      _log.error(
          message: 'Unable to delete document',
          sensitiveData: SensitiveData(
            path: collectionPathOverride ?? _collectionPath(),
            id: id,
          ),
          error: error,
          stackTrace: stackTrace);
      return TurboResponse.emptyFail();
    }
  }

  /// Deletes documents using a batch operation
  ///
  /// Removes multiple documents atomically
  /// Creates new batch if none provided
  ///
  /// Parameters:
  /// [id] unique identifier of the document
  /// [writeBatch] optional existing batch to add to
  /// [collectionPathOverride] override path for collection groups
  ///
  /// Returns [TurboResponse] containing:
  /// - Success with batch and document reference
  /// - Fail with operation errors
  ///
  /// Features:
  /// - Atomic deletion
  /// - Creates new batch if none provided
  /// - Collection group support
  /// - Error logging
  ///
  /// Example:
  /// ```dart
  /// final batch = firestore.batch();
  /// final response = await api.deleteDocs(
  ///   id: 'user-123',
  ///   writeBatch: batch,
  /// );
  /// response.when(
  ///   success: (result) async {
  ///     await result.writeBatch.commit();
  ///     print('Deleted user ${result.documentReference.id}');
  ///   },
  ///   fail: (error) => print('Error $error'),
  /// );
  /// ```
  ///
  /// See also:
  /// [deleteDoc] single document deletion
  /// [updateDocs] batch updates
  Future<TurboResponse<WriteBatchWithReference<Map<String, dynamic>>>>
      deleteDocs({
    required String id,
    WriteBatch? writeBatch,
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
        message: 'Deleting document with batch..',
        sensitiveData: SensitiveData(
          path: collectionPathOverride ?? _collectionPath(),
          id: id,
          isBatch: writeBatch != null,
        ),
      );
      final nullSafeWriteBatch = writeBatch ?? this.writeBatch;
      final documentReference =
          getDocRefById(id: id, collectionPathOverride: collectionPathOverride);
      _log.debug(
        message: 'Deleting data with writeBatch.delete..',
        sensitiveData: null,
      );
      nullSafeWriteBatch.delete(documentReference);
      _log.info(
        message:
            'Adding delete to batch done! Returning WriteBatchWithReference..',
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
        message: 'Unable to delete document with batch',
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

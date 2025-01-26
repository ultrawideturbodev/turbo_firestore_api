part of 'turbo_document_service.dart';

/// A document service that allows notification both before and after synchronizing data.
///
/// Extends [TurboDocumentService] to provide hooks for notifying both before and after
/// the local state is updated with new data from Firestore.
///
/// Type Parameters:
/// - [T] - The document type, must extend [TurboWriteableId<String>]
/// - [API] - The Firestore API type, must extend [TurboFirestoreApi<T>]
abstract class BeAfSyncTurboDocumentService<T extends TurboWriteableId<String>,
    API extends TurboFirestoreApi<T>> extends TurboDocumentService<T, API> {
  /// Creates a new [BeAfSyncTurboDocumentService] instance.
  BeAfSyncTurboDocumentService({required super.api});

  /// Called before the local state is updated with new data.
  ///
  /// Use this method to perform any necessary operations before
  /// the document is synchronized with local state.
  ///
  /// Parameters:
  /// - [doc] - The new document from Firestore
  void beforeSyncNotifyUpdate(T? doc);

  /// Called after the local state has been updated with new data.
  ///
  /// Use this method to perform any necessary operations after
  /// the document has been synchronized with local state.
  ///
  /// Parameters:
  /// - [doc] - The new document from Firestore
  void afterSyncNotifyUpdate(T? doc);

  /// Handles incoming data updates from Firestore with pre and post-sync notifications.
  ///
  /// This callback is triggered when:
  /// - New document data is received from Firestore
  /// - The user's authentication state changes
  ///
  /// The method:
  /// - Notifies before sync via [beforeSyncNotifyUpdate] if user is authenticated
  /// - Updates local state with new document data
  /// - Marks the service as ready after first update
  /// - Notifies after sync via [afterSyncNotifyUpdate]
  /// - Clears local state if user is not authenticated
  ///
  /// Parameters:
  /// - [value] - The new document value from Firestore
  /// - [user] - The current Firebase user
  @override
  void Function(T? value, User? user) get onData {
    return (value, user) {
      final doc = value;
      if (user != null) {
        log.debug('Updating doc for user ${user.uid}');
        beforeSyncNotifyUpdate(doc);
        final pDoc = updateLocalDoc(
          id: value?.id,
          doc: (_, __) => value,
          doNotifyListeners: canNotifyListeners,
        );
        _isReady.completeIfNotComplete();
        afterSyncNotifyUpdate(pDoc);
        log.debug('Updated doc');
      } else {
        log.debug('User is null, clearing doc');
        beforeSyncNotifyUpdate(null);
        updateLocalDoc(
          id: null,
          doc: (_, __) => null,
          doNotifyListeners: canNotifyListeners,
        );
        afterSyncNotifyUpdate(null);
      }
    };
  }
}

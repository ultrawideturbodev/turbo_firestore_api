part of 'turbo_collection_service.dart';

/// A collection service that allows notification after synchronizing data.
///
/// Extends [TurboCollectionService] to provide a hook for notifying after
/// the local state has been updated with new data from Firestore.
///
/// Type Parameters:
/// - [T] - The document type, must extend [TurboWriteableId<String>]
/// - [API] - The Firestore API type, must extend [TurboFirestoreApi<T>]
abstract class AfSyncTurboCollectionService<T extends TurboWriteableId<String>,
    API extends TurboFirestoreApi<T>> extends TurboCollectionService<T, API> {
  /// Creates a new [AfSyncTurboCollectionService] instance.
  AfSyncTurboCollectionService({required super.api});

  /// Called after the local state has been updated with new data.
  ///
  /// Use this method to perform any necessary operations after
  /// the documents have been synchronized with local state.
  ///
  /// Parameters:
  /// - [docs] - The new documents from Firestore
  void afterSyncNotifyUpdate(List<T> docs);

  /// Handles incoming data updates from Firestore with post-sync notification.
  ///
  /// This callback is triggered when:
  /// - New document data is received from Firestore
  /// - The user's authentication state changes
  ///
  /// The method:
  /// - Updates local state with new document data if user is authenticated
  /// - Marks the service as ready after first update
  /// - Notifies after sync via [afterSyncNotifyUpdate]
  /// - Clears local state if user is not authenticated
  ///
  /// Parameters:
  /// - [value] - The new document values from Firestore
  /// - [user] - The current Firebase user
  @override
  void Function(List<T>? value, User? user) get onData {
    return (value, user) {
      final docs = value ?? [];
      if (user != null) {
        log.debug('Updating docs for user ${user.uid}');
        _docsPerId.update(docs.toIdMap((element) => element.id));
        _isReady.completeIfNotComplete();
        afterSyncNotifyUpdate(docs);
        log.debug('Updated ${docs.length} docs');
      } else {
        log.debug('User is null, clearing docs');
        _docsPerId.update({});
      }
    };
  }
}

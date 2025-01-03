part of 'turbo_collection_service.dart';

/// A collection service that allows notification before synchronizing data.
///
/// Extends [TurboCollectionService] to provide a hook for notifying before
/// the local state is updated with new data from Firestore.
///
/// Type Parameters:
/// - [T] - The document type, must extend [TurboWriteableId<String>]
/// - [API] - The Firestore API type, must extend [TurboFirestoreApi<T>]
abstract class BeTurboCollectionService<T extends TurboWriteableId<String>,
    API extends TurboFirestoreApi<T>> extends TurboCollectionService<T, API> {
  /// Creates a new [BeTurboCollectionService] instance.
  BeTurboCollectionService({required super.api});

  /// Called before the local state is updated with new data.
  ///
  /// Use this method to perform any necessary operations before
  /// the documents are synchronized with local state.
  ///
  /// Parameters:
  /// - [docs] - The new documents from Firestore
  void beforeSyncNotifyUpdate(List<T> docs);

  /// Handles incoming data updates from Firestore with pre-sync notification.
  ///
  /// This callback is triggered when:
  /// - New document data is received from Firestore
  /// - The user's authentication state changes
  ///
  /// The method:
  /// - Notifies before sync via [beforeSyncNotifyUpdate] if user is authenticated
  /// - Updates local state with new document data
  /// - Marks the service as ready after first update
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
        beforeSyncNotifyUpdate(docs);
        _docsPerId.update(docs.toIdMap((element) => element.id));
        _isReady.completeIfNotComplete();
        log.debug('Updated ${docs.length} docs');
      } else {
        log.debug('User is null, clearing docs');
        _docsPerId.update({});
      }
    };
  }
}

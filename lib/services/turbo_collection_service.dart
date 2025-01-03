import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:informers/informer.dart';
import 'package:loglytics/loglytics.dart';
import 'package:turbo_firestore_api/abstracts/turbo_writeable.dart';
import 'package:turbo_firestore_api/abstracts/turbo_writeable_id.dart';
import 'package:turbo_firestore_api/apis/turbo_firestore_api.dart';
import 'package:turbo_firestore_api/extensions/completer_extension.dart';
import 'package:turbo_firestore_api/typedefs/turbo_doc_builder.dart';
import 'package:turbo_response/turbo_response.dart';
import 'package:turbo_firestore_api/extensions/turbo_list_extension.dart';
import 'package:turbo_firestore_api/services/turbo_auth_sync_service.dart';

part 'before_turbo_collection_service.dart';
part 'after_sync_turbo_collection_service.dart';
part 'before_after_sync_turbo_collection_service.dart';

/// A service for managing a collection of Firestore documents with synchronized local state.
///
/// The [TurboCollectionService] provides a robust foundation for managing collections of documents
/// that need to be synchronized between Firestore and local state. It handles:
/// - Local state management with optimistic updates
/// - Remote state synchronization
/// - Batch operations
/// - Transaction support
/// - Error handling
/// - Automatic user authentication state sync
///
/// Type Parameters:
/// - [T] - The document type, must extend [TurboWriteableId<String>]
/// - [API] - The Firestore API type, must extend [TurboFirestoreApi<T>]
///
/// Example:
/// ```dart
/// class UserService extends TurboCollectionService<User, UserApi> {
///   UserService({required super.api});
///
///   Future<void> updateUserName(String userId, String newName) async {
///     final user = findById(userId);
///     final updated = user.copyWith(name: newName);
///     await updateDoc(doc: updated);
///   }
/// }
/// ```
///
/// Features:
/// - Automatic local state updates before remote operations
/// - Optimistic UI updates with rollback on failure
/// - Batch operations for multiple documents
/// - Transaction support for atomic operations
/// - Automatic stream update blocking during mutations
/// - Error handling and logging
/// - User authentication state synchronization
abstract class TurboCollectionService<T extends TurboWriteableId<String>,
        API extends TurboFirestoreApi<T>> extends TurboAuthSyncService<List<T>>
    with Loglytics {
  /// Creates a new [TurboCollectionService] instance.
  ///
  /// Parameters:
  /// - [api] - The Firestore API instance for remote operations
  TurboCollectionService({
    required this.api,
  });

  // 📍 LOCATOR ------------------------------------------------------------------------------- \\
  // 🧩 DEPENDENCIES -------------------------------------------------------------------------- \\

  /// The Firestore API instance used for remote operations.
  final API api;

  // 🎬 INIT & DISPOSE ------------------------------------------------------------------------ \\

  /// Disposes of the service by cleaning up resources.
  ///
  /// Disposes the [_docsPerId] informer and completes the [_isReady] completer
  /// if not already completed. Then calls the parent dispose method.
  @override
  Future<void> dispose() {
    _docsPerId.dispose();
    _isReady.completeIfNotComplete();
    return super.dispose();
  }

  // 👂 LISTENERS ----------------------------------------------------------------------------- \\
  // ⚡️ OVERRIDES ----------------------------------------------------------------------------- \\

  /// Stream of all documents for a given user.
  @override
  Stream<List<T>> Function(User user) get stream =>
      (_) => api.streamAllWithConverter();

  /// Handles data updates from the Firestore stream.
  ///
  /// Updates the local state when new data arrives from Firestore.
  /// If [user] is null, clears the local state.
  @override
  void Function(List<T>? value, User? user) get onData {
    return (value, user) {
      final docs = value ?? [];
      if (user != null) {
        log.debug('Updating docs for user ${user.uid}');
        _docsPerId.update(docs.toIdMap((element) => element.id));
        _isReady.completeIfNotComplete();
        log.debug('Updated ${docs.length} docs');
      } else {
        log.debug('User is null, clearing docs');
        _docsPerId.update({});
      }
    };
  }

  // 🎩 STATE --------------------------------------------------------------------------------- \\

  /// Local state for documents, indexed by their IDs.
  final _docsPerId = Informer<Map<String, T>>({}, forceUpdate: true);

  /// Completer that resolves when the service is ready.
  final _isReady = Completer();

  // 🛠 UTIL ---------------------------------------------------------------------------------- \\
  // 🧲 FETCHERS ------------------------------------------------------------------------------ \\

  /// Value listenable for the document collection state.
  ValueListenable<Map<String, T>> get docsPerId => _docsPerId;

  /// Whether the collection has any documents.
  bool get hasDocs => _docsPerId.value.isNotEmpty;

  /// Whether a document with the given ID exists.
  bool exists(String id) => _docsPerId.value.containsKey(id);

  /// Finds a document by its ID. Throws if not found.
  T findById(String id) => _docsPerId.value[id]!;

  /// Finds a document by its ID. Returns null if not found.
  T? tryFindById(String? id) => _docsPerId.value[id];

  /// Future that completes when the service is ready to use.
  Future get isReady => _isReady.future;

  /// Listenable for the document collection state.
  Listenable get listenable => _docsPerId;

  // 🏗️ HELPERS ------------------------------------------------------------------------------- \\
  // ⚙️ LOCAL MUTATORS ------------------------------------------------------------------------ \\

  /// Deletes a document from local state.
  ///
  /// Parameters:
  /// - [doc] - The document to delete
  /// - [doNotifyListeners] - Whether to notify listeners of the change
  @protected
  void deleteLocalDoc({
    required T doc,
    bool doNotifyListeners = true,
  }) {
    log.debug('Deleting local doc with id: ${doc.id}');
    _docsPerId.updateCurrent(
      (value) => value..remove(doc.id),
      doNotifyListeners: doNotifyListeners,
    );
  }

  /// Deletes multiple documents from local state.
  ///
  /// Parameters:
  /// - [docs] - The documents to delete
  /// - [doNotifyListeners] - Whether to notify listeners of the changes
  @protected
  void deleteLocalDocs({
    required List<T> docs,
    bool doNotifyListeners = true,
  }) {
    log.debug('Deleting ${docs.length} local docs');
    for (final doc in docs) {
      deleteLocalDoc(doc: doc, doNotifyListeners: false);
    }
    if (doNotifyListeners) _docsPerId.rebuild();
  }

  /// Creates or updates a document in local state.
  ///
  /// Parameters:
  /// - [doc] - The document to upsert
  /// - [doNotifyListeners] - Whether to notify listeners of the change
  @protected
  void upsertLocalDoc({
    required T doc,
    bool doNotifyListeners = true,
  }) {
    log.debug('Upserting local doc with id: ${doc.id}');
    _docsPerId.updateCurrent(
      (value) => value
        ..update(
          doc.id,
          (_) => doc,
          ifAbsent: () => doc,
        ),
      doNotifyListeners: doNotifyListeners,
    );
  }

  /// Updates an existing document in local state.
  ///
  /// Parameters:
  /// - [doc] - The document to update
  /// - [doNotifyListeners] - Whether to notify listeners of the change
  @protected
  void updateLocalDoc({
    required T doc,
    bool doNotifyListeners = true,
  }) {
    log.debug('Updating local doc with id: ${doc.id}');
    _docsPerId.updateCurrent(
      (value) => value..update(doc.id, (_) => doc),
      doNotifyListeners: doNotifyListeners,
    );
  }

  /// Creates a new document in local state.
  ///
  /// Parameters:
  /// - [doc] - The document to create
  /// - [doNotifyListeners] - Whether to notify listeners of the change
  @protected
  void createLocalDoc({
    required T doc,
    bool doNotifyListeners = true,
  }) {
    log.debug('Creating local doc with id: ${doc.id}');
    _docsPerId.updateCurrent(
      (value) => value..[doc.id] = doc,
      doNotifyListeners: doNotifyListeners,
    );
  }

  /// Creates or updates multiple documents in local state.
  ///
  /// Parameters:
  /// - [docs] - The documents to upsert
  /// - [doNotifyListeners] - Whether to notify listeners of the changes
  @protected
  void upsertLocalDocs({
    required List<T> docs,
    bool doNotifyListeners = true,
  }) {
    log.debug('Upserting ${docs.length} local docs');
    for (final doc in docs) {
      upsertLocalDoc(doc: doc, doNotifyListeners: false);
    }
    if (doNotifyListeners) _docsPerId.rebuild();
  }

  /// Updates multiple existing documents in local state.
  ///
  /// Parameters:
  /// - [docs] - The documents to update
  /// - [doNotifyListeners] - Whether to notify listeners of the changes
  @protected
  void updateLocalDocs({
    required List<T> docs,
    bool doNotifyListeners = true,
  }) {
    log.debug('Updating ${docs.length} local docs');
    for (final doc in docs) {
      updateLocalDoc(doc: doc, doNotifyListeners: false);
    }
    if (doNotifyListeners) _docsPerId.rebuild();
  }

  /// Creates multiple new documents in local state.
  ///
  /// Parameters:
  /// - [docs] - The documents to create
  /// - [doNotifyListeners] - Whether to notify listeners of the changes
  @protected
  void createLocalDocs({
    required List<T> docs,
    bool doNotifyListeners = true,
  }) {
    log.debug('Creating ${docs.length} local docs');
    for (final doc in docs) {
      createLocalDoc(doc: doc, doNotifyListeners: false);
    }
    if (doNotifyListeners) _docsPerId.rebuild();
  }

  // 🕹️ LOCAL & REMOTE MUTATORS --------------------------------------------------------------- \\

  /// Updates a document both locally and in Firestore.
  ///
  /// Performs an optimistic update by updating the local state first,
  /// then syncing with Firestore. If the remote update fails, the local
  /// state remains updated.
  ///
  /// Parameters:
  /// - [doc] - The document to update
  /// - [transaction] - Optional transaction for atomic operations
  /// - [remoteUpdateRequestBuilder] - Optional builder for remote update data
  /// - [doNotifyListeners] - Whether to notify listeners of the change
  ///
  /// Returns a [TurboResponse] with the updated document reference
  @protected
  Future<TurboResponse<DocumentReference>> updateDoc({
    Transaction? transaction,
    TurboWriteable Function(T doc)? remoteUpdateRequestBuilder,
    bool doNotifyListeners = true,
    required T doc,
  }) async {
    try {
      log.debug('Updating doc with id: ${doc.id}');
      updateLocalDoc(
        doc: doc,
        doNotifyListeners: doNotifyListeners,
      );
      final future = api.updateDoc(
        writeable: remoteUpdateRequestBuilder?.call(doc) ?? doc,
        id: doc.id,
        transaction: transaction,
      );
      tempBlockStreamUpdates(future);
      return await future;
    } catch (error, stackTrace) {
      log.error(
        '$error caught while updating doc',
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.emptyFail();
    }
  }

  /// Creates a new document both locally and in Firestore.
  ///
  /// Performs an optimistic create by updating the local state first,
  /// then syncing with Firestore. If the remote create fails, the local
  /// state remains updated.
  ///
  /// Parameters:
  /// - [doc] - The document to create
  /// - [transaction] - Optional transaction for atomic operations
  /// - [doNotifyListeners] - Whether to notify listeners of the change
  ///
  /// Returns a [TurboResponse] with the created document reference
  @protected
  Future<TurboResponse<DocumentReference>> createDoc({
    Transaction? transaction,
    bool doNotifyListeners = true,
    required T doc,
  }) async {
    try {
      log.debug('Creating doc with id: ${doc.id}');
      createLocalDoc(
        doc: doc,
        doNotifyListeners: doNotifyListeners,
      );
      final future = api.createDoc(
        writeable: doc,
        id: doc.id,
        transaction: transaction,
      );
      tempBlockStreamUpdates(future);
      return await future;
    } catch (error, stackTrace) {
      log.error(
        '$error caught while creating doc',
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.emptyFail();
    }
  }

  /// Updates multiple documents both locally and in Firestore.
  ///
  /// Performs optimistic updates by updating the local state first,
  /// then syncing with Firestore. Uses a batch operation for multiple
  /// documents unless a transaction is provided.
  ///
  /// Parameters:
  /// - [docs] - The documents to update
  /// - [transaction] - Optional transaction for atomic operations
  /// - [remoteUpdateRequestBuilder] - Optional builder for remote update data
  /// - [doNotifyListeners] - Whether to notify listeners of the changes
  ///
  /// Returns a [TurboResponse] indicating success or failure
  @protected
  Future<TurboResponse> updateDocs({
    TurboWriteable Function(T doc)? remoteUpdateRequestBuilder,
    bool doNotifyListeners = true,
    required List<T> docs,
    Transaction? transaction,
  }) async {
    try {
      log.debug('Updating ${docs.length} docs');
      updateLocalDocs(docs: docs, doNotifyListeners: doNotifyListeners);
      if (transaction != null) {
        for (final doc in docs) {
          await api.updateDoc(
            id: doc.id,
            transaction: transaction,
            writeable: remoteUpdateRequestBuilder?.call(doc) ?? doc,
          );
        }
        return TurboResponse.emptySuccess();
      } else {
        final batch = api.writeBatch;
        for (final doc in docs) {
          await api.updateDocs(
            id: doc.id,
            writeBatch: batch,
            writeable: remoteUpdateRequestBuilder?.call(doc) ?? doc,
          );
        }
        final future = batch.commit();
        tempBlockStreamUpdates(future);
        await future;
        return TurboResponse.emptySuccess();
      }
    } catch (error, stackTrace) {
      log.error(
        '${error.runtimeType} caught while updating docs',
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.emptyFail();
    }
  }

  /// Creates multiple documents both locally and in Firestore.
  ///
  /// Performs optimistic creates by updating the local state first,
  /// then syncing with Firestore. Uses a batch operation for multiple
  /// documents unless a transaction is provided.
  ///
  /// Parameters:
  /// - [docs] - The documents to create
  /// - [transaction] - Optional transaction for atomic operations
  /// - [doNotifyListeners] - Whether to notify listeners of the changes
  ///
  /// Returns a [TurboResponse] indicating success or failure
  @protected
  Future<TurboResponse> createDocs({
    bool doNotifyListeners = true,
    required List<T> docs,
    Transaction? transaction,
  }) async {
    try {
      log.debug('Creating ${docs.length} docs');
      createLocalDocs(docs: docs, doNotifyListeners: doNotifyListeners);
      if (transaction != null) {
        for (final doc in docs) {
          await api.createDoc(
            id: doc.id,
            transaction: transaction,
            writeable: doc,
          );
        }
        return TurboResponse.emptySuccess();
      } else {
        final batch = api.writeBatch;
        for (final doc in docs) {
          await api.createDocs(
            id: doc.id,
            writeBatch: batch,
            writeable: doc,
          );
        }
        final future = batch.commit();
        tempBlockStreamUpdates(future);
        await future;
        return TurboResponse.emptySuccess();
      }
    } catch (error, stackTrace) {
      log.error(
        '${error.runtimeType} caught while creating docs',
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.emptyFail();
    }
  }

  /// Deletes a document both locally and from Firestore.
  ///
  /// Performs an optimistic delete by updating the local state first,
  /// then syncing with Firestore. If the remote delete fails, the local
  /// state remains updated.
  ///
  /// Parameters:
  /// - [doc] - The document to delete
  /// - [transaction] - Optional transaction for atomic operations
  /// - [doNotifyListeners] - Whether to notify listeners of the change
  ///
  /// Returns a [TurboResponse] indicating success or failure
  @protected
  Future<TurboResponse<void>> deleteDoc({
    required T doc,
    bool doNotifyListeners = true,
    Transaction? transaction,
  }) async {
    try {
      log.debug('Deleting doc with id: ${doc.id}');
      deleteLocalDoc(doc: doc, doNotifyListeners: doNotifyListeners);
      final future = api.deleteDoc(
        id: doc.id,
        transaction: transaction,
      );
      tempBlockStreamUpdates(future);
      return await future;
    } catch (error, stackTrace) {
      log.error(
        '$error caught while deleting doc',
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.emptyFail();
    }
  }

  /// Deletes multiple documents both locally and from Firestore.
  ///
  /// Performs optimistic deletes by updating the local state first,
  /// then syncing with Firestore. Uses a batch operation for multiple
  /// documents unless a transaction is provided.
  ///
  /// Parameters:
  /// - [docs] - The documents to delete
  /// - [transaction] - Optional transaction for atomic operations
  /// - [doNotifyListeners] - Whether to notify listeners of the changes
  ///
  /// Returns a [TurboResponse] indicating success or failure
  @protected
  Future<TurboResponse> deleteDocs({
    required List<T> docs,
    bool doNotifyListeners = true,
    Transaction? transaction,
  }) async {
    try {
      log.debug('Deleting ${docs.length} docs');
      deleteLocalDocs(docs: docs, doNotifyListeners: doNotifyListeners);
      if (transaction != null) {
        for (final doc in docs) {
          await api.deleteDoc(
            id: doc.id,
            transaction: transaction,
          );
        }
        return TurboResponse.emptySuccess();
      } else {
        final batch = api.writeBatch;
        for (final doc in docs) {
          await api.deleteDocs(
            id: doc.id,
            writeBatch: batch,
          );
        }
        final future = batch.commit();
        tempBlockStreamUpdates(future);
        await future;
        return TurboResponse.emptySuccess();
      }
    } catch (error, stackTrace) {
      log.error(
        '${error.runtimeType} caught while deleting docs',
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.emptyFail();
    }
  }

  /// Creates or updates a document both locally and in Firestore.
  ///
  /// Performs an optimistic upsert by updating the local state first,
  /// then syncing with Firestore. If the remote upsert fails, the local
  /// state remains updated.
  ///
  /// Parameters:
  /// - [doc] - The document to upsert
  /// - [transaction] - Optional transaction for atomic operations
  /// - [remoteUpdateRequestBuilder] - Optional builder for remote update data
  /// - [doNotifyListeners] - Whether to notify listeners of the change
  ///
  /// Returns a [TurboResponse] with the upserted document reference
  @protected
  Future<TurboResponse<DocumentReference>> upsertDoc({
    Transaction? transaction,
    TurboWriteable Function(T doc)? remoteUpdateRequestBuilder,
    bool doNotifyListeners = true,
    required T doc,
  }) async {
    try {
      log.debug('Upserting doc with id: ${doc.id}');
      upsertLocalDoc(
        doc: doc,
        doNotifyListeners: doNotifyListeners,
      );
      final future = api.createDoc(
        merge: true,
        writeable: doc.isLocalDefault
            ? doc
            : remoteUpdateRequestBuilder?.call(doc) ?? doc,
        id: doc.id,
        transaction: transaction,
      );
      tempBlockStreamUpdates(future);
      return await future;
    } catch (error, stackTrace) {
      log.error(
        '$error caught while upserting doc',
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.emptyFail();
    }
  }

  /// Creates or updates multiple documents both locally and in Firestore.
  ///
  /// Performs optimistic upserts by updating the local state first,
  /// then syncing with Firestore. Uses a batch operation for multiple
  /// documents unless a transaction is provided.
  ///
  /// Parameters:
  /// - [docs] - The documents to upsert
  /// - [transaction] - Optional transaction for atomic operations
  /// - [remoteUpdateRequestBuilder] - Optional builder for remote update data
  /// - [doNotifyListeners] - Whether to notify listeners of the changes
  ///
  /// Returns a [TurboResponse] indicating success or failure
  @protected
  Future<TurboResponse> upsertDocs({
    TurboWriteable Function(T doc)? remoteUpdateRequestBuilder,
    bool doNotifyListeners = true,
    required List<T> docs,
    Transaction? transaction,
  }) async {
    try {
      log.debug('Upserting ${docs.length} docs');
      upsertLocalDocs(docs: docs, doNotifyListeners: doNotifyListeners);
      if (transaction != null) {
        for (final doc in docs) {
          await api.createDoc(
            id: doc.id,
            transaction: transaction,
            writeable: doc.isLocalDefault
                ? doc
                : remoteUpdateRequestBuilder?.call(doc) ?? doc,
            merge: true,
          );
        }
        return TurboResponse.emptySuccess();
      } else {
        final batch = api.writeBatch;
        for (final doc in docs) {
          await api.createDocs(
            id: doc.id,
            writeBatch: batch,
            writeable: doc.isLocalDefault
                ? doc
                : remoteUpdateRequestBuilder?.call(doc) ?? doc,
            merge: true,
          );
        }
        final future = batch.commit();
        tempBlockStreamUpdates(future);
        await future;
        return TurboResponse.emptySuccess();
      }
    } catch (error, stackTrace) {
      log.error(
        '${error.runtimeType} caught while upserting docs',
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.emptyFail();
    }
  }

  // 🪄 MUTATORS ------------------------------------------------------------------------------ \\

  /// Builds a new document with generated ID and current timestamp.
  ///
  /// Parameters:
  /// - [builder] - Function to build the document
  T buildDoc(
    TurboDocBuilder<T> builder,
  ) =>
      builder(
        api.genId,
        DateTime.now(),
        cachedUserId,
      );

  /// Forces a rebuild of the local state.
  void rebuild() => _docsPerId.rebuild();
}

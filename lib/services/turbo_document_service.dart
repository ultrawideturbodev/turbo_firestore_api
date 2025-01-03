import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:informers/informer.dart';
import 'package:loglytics/loglytics.dart';
import 'package:turbo_firestore_api/abstracts/turbo_writeable.dart';
import 'package:turbo_firestore_api/abstracts/turbo_writeable_id.dart';
import 'package:turbo_firestore_api/apis/turbo_firestore_api.dart';
import 'package:turbo_firestore_api/services/turbo_auth_sync_service.dart';
import 'package:turbo_firestore_api/typedefs/turbo_doc_builder.dart';
import 'package:turbo_firestore_api/typedefs/turbo_locator_def.dart';
import 'package:turbo_response/turbo_response.dart';

import '../extensions/completer_extension.dart';

/// A service for managing a single Firestore document with synchronized local state.
///
/// Extends [TurboAuthSyncService] to provide functionality for managing a single document
/// that needs to be synchronized between Firestore and local state. It handles:
/// - Local state management with optimistic updates
/// - Remote state synchronization
/// - Transaction support
/// - Error handling
/// - Automatic user authentication state sync
/// - Before/after update notifications
///
/// Type Parameters:
/// - [T] - The document type, must extend [TurboWriteableId<String>]
/// - [API] - The Firestore API type, must extend [TurboFirestoreApi<T>]
abstract class TurboDocumentService<T extends TurboWriteableId<String>,
        API extends TurboFirestoreApi<T>> extends TurboAuthSyncService<T?>
    with Loglytics {
  /// Creates a new [TurboDocumentService] instance.
  ///
  /// Parameters:
  /// - [api] - The Firestore API instance for remote operations
  TurboDocumentService({
    required this.api,
  });

  // 📍 LOCATOR ------------------------------------------------------------------------------- \\
  // 🧩 DEPENDENCIES -------------------------------------------------------------------------- \\

  /// The Firestore API instance used for remote operations.
  final API api;

  // 🎬 INIT & DISPOSE ------------------------------------------------------------------------ \\

  /// Disposes of the document service and releases resources.
  ///
  /// This method:
  /// - Disposes of the local document state
  /// - Completes the ready state if not already completed
  /// - Calls the parent class dispose method
  ///
  /// This method must be called when the service is no longer needed
  /// to prevent memory leaks.
  @override
  @mustCallSuper
  Future<void> dispose() {
    _doc.dispose();
    _isReady.completeIfNotComplete();
    return super.dispose();
  }

  // 👂 LISTENERS ----------------------------------------------------------------------------- \\
  // ⚡️ OVERRIDES ----------------------------------------------------------------------------- \\

  /// Handles incoming data updates from Firestore.
  ///
  /// This callback is triggered when:
  /// - New document data is received from Firestore
  /// - The user's authentication state changes
  ///
  /// The method:
  /// - Updates local state with new document data if user is authenticated
  /// - Clears local state if user is not authenticated
  /// - Marks the service as ready after first update
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
        upsertLocalDoc(doc: doc);
        _isReady.completeIfNotComplete();
        log.debug('Updated doc');
      } else {
        log.debug('User is null, clearing doc');
        upsertLocalDoc(doc: doc);
      }
    };
  }

  // 🎩 STATE --------------------------------------------------------------------------------- \\

  /// Local state for the document.
  late final _doc = Informer<T?>(
      initialValueLocator?.call() ?? defaultValueLocator?.call(),
      forceUpdate: true);

  /// Completer that resolves when the service is ready.
  final _isReady = Completer();

  // 🛠 UTIL ---------------------------------------------------------------------------------- \\
  // 🧲 FETCHERS ------------------------------------------------------------------------------ \\

  /// Function to provide initial document value.
  TurboLocatorDef<T>? initialValueLocator;

  /// Function to provide default document value.
  TurboLocatorDef<T>? defaultValueLocator;

  /// Called before local state is updated.
  ValueChanged<T?>? beforeLocalNotifyUpdate;

  /// Called after local state is updated.
  ValueChanged<T?>? afterLocalNotifyUpdate;

  /// Future that completes when the service is ready.
  Future get isReady => _isReady.future;

  /// Listenable for the document state.
  Listenable get listenable => _doc;

  /// Value listenable for the document state.
  ValueListenable<T?> get doc => _doc;

  /// Whether a document exists in local state.
  bool get hasDoc => _doc.value != null;

  // 🏗️ HELPERS ------------------------------------------------------------------------------- \\

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

  // ⚙️ LOCAL MUTATORS ------------------------------------------------------------------------ \\

  /// Forces a rebuild of the local state.
  void rebuild() => _doc.rebuild();

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
    if (doNotifyListeners) {
      beforeLocalNotifyUpdate?.call(doc);
    }
    _doc.update(null, doNotifyListeners: doNotifyListeners);
    if (doNotifyListeners) {
      afterLocalNotifyUpdate?.call(doc);
    }
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
    if (doNotifyListeners) {
      beforeLocalNotifyUpdate?.call(doc);
    }
    _doc.update(doc, doNotifyListeners: doNotifyListeners);
    if (doNotifyListeners) {
      afterLocalNotifyUpdate?.call(doc);
    }
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
    if (doNotifyListeners) {
      beforeLocalNotifyUpdate?.call(doc);
    }
    _doc.update(doc, doNotifyListeners: doNotifyListeners);
    if (doNotifyListeners) {
      afterLocalNotifyUpdate?.call(doc);
    }
  }

  /// Creates or updates a document in local state.
  ///
  /// Parameters:
  /// - [doc] - The document to upsert
  /// - [doNotifyListeners] - Whether to notify listeners of the change
  @protected
  void upsertLocalDoc({
    required T? doc,
    bool doNotifyListeners = true,
  }) {
    final pDoc = doc ?? defaultValueLocator?.call();
    log.debug('Updating local doc with id: ${pDoc?.id}');
    if (doNotifyListeners) {
      beforeLocalNotifyUpdate?.call(pDoc);
    }
    _doc.update(pDoc, doNotifyListeners: doNotifyListeners);
    if (doNotifyListeners) {
      afterLocalNotifyUpdate?.call(pDoc);
    }
  }

  // 🕹️ LOCAL & REMOTE MUTATORS --------------------------------------------------------------- \\

  /// Creates or updates a document both locally and in Firestore.
  ///
  /// Performs an optimistic upsert by updating the local state first,
  /// then syncing with Firestore. If the remote upsert fails, the local
  /// state remains updated.
  ///
  /// Parameters:
  /// - [doc] - The document to upsert
  /// - [remoteUpdateRequestBuilder] - Optional builder for remote update data
  /// - [doNotifyListeners] - Whether to notify listeners of the change
  /// - [transaction] - Optional transaction for atomic operations
  ///
  /// Returns a [TurboResponse] with the upserted document reference
  @protected
  Future<TurboResponse<DocumentReference>> upsertDoc({
    required T doc,
    TurboWriteable Function(T doc)? remoteUpdateRequestBuilder,
    bool doNotifyListeners = true,
    Transaction? transaction,
  }) async {
    try {
      log.debug('Upserting doc with id: ${doc.id}');
      upsertLocalDoc(doc: doc, doNotifyListeners: doNotifyListeners);
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

  /// Deletes a document both locally and from Firestore.
  ///
  /// Performs an optimistic delete by updating the local state first,
  /// then syncing with Firestore. If the remote delete fails, the local
  /// state remains updated.
  ///
  /// Parameters:
  /// - [doc] - The document to delete
  /// - [doNotifyListeners] - Whether to notify listeners of the change
  ///
  /// Returns a [TurboResponse] indicating success or failure
  @protected
  Future<TurboResponse<void>> deleteDoc({
    required T doc,
    bool doNotifyListeners = true,
  }) async {
    try {
      log.debug('Deleting doc with id: ${doc.id}');
      deleteLocalDoc(doc: doc, doNotifyListeners: doNotifyListeners);
      final future = api.deleteDoc(
        id: doc.id,
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

  /// Updates a document both locally and in Firestore.
  ///
  /// Performs an optimistic update by updating the local state first,
  /// then syncing with Firestore. If the remote update fails, the local
  /// state remains updated.
  ///
  /// Parameters:
  /// - [doc] - The document to update
  /// - [remoteUpdateRequestBuilder] - Optional builder for remote update data
  /// - [doNotifyListeners] - Whether to notify listeners of the change
  /// - [transaction] - Optional transaction for atomic operations
  ///
  /// Returns a [TurboResponse] with the updated document reference
  @protected
  Future<TurboResponse<DocumentReference>> updateDoc({
    required T doc,
    TurboWriteable Function(T doc)? remoteUpdateRequestBuilder,
    bool doNotifyListeners = true,
    Transaction? transaction,
  }) async {
    try {
      log.debug('Updating doc with id: ${doc.id}');
      upsertLocalDoc(doc: doc, doNotifyListeners: doNotifyListeners);
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
  /// - [doNotifyListeners] - Whether to notify listeners of the change
  /// - [transaction] - Optional transaction for atomic operations
  ///
  /// Returns a [TurboResponse] with the created document reference
  @protected
  Future<TurboResponse<DocumentReference>> createDoc({
    required T doc,
    bool doNotifyListeners = true,
    Transaction? transaction,
  }) async {
    try {
      log.debug('Creating doc with id: ${doc.id}');
      upsertLocalDoc(doc: doc, doNotifyListeners: doNotifyListeners);
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
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turbo_firestore_api/abstracts/turbo_writeable.dart';
import 'package:turbo_firestore_api/enums/turbo_search_term_type.dart';
import 'package:turbo_firestore_api/enums/turbo_timestamp_type.dart';
import 'package:turbo_firestore_api/exceptions/invalid_json_exception.dart';
import 'package:turbo_firestore_api/extensions/turbo_map_extension.dart';
import 'package:turbo_firestore_api/models/sensitive_data.dart';
import 'package:turbo_firestore_api/models/write_batch_with_reference.dart';
import 'package:turbo_firestore_api/typedefs/collection_reference_def.dart';
import 'package:turbo_firestore_api/util/turbo_firestore_logger.dart';
import 'package:turbo_response/turbo_response.dart';

part 'turbo_firestore_create_api.dart';
part 'turbo_firestore_get_api.dart';
part 'turbo_firestore_list_api.dart';
part 'turbo_firestore_stream_api.dart';
part 'turbo_firestore_search_api.dart';
part 'turbo_firestore_update_api.dart';
part 'turbo_firestore_delete_api.dart';

/// A powerful, type-safe wrapper around Cloud Firestore operations.
///
/// The [TurboFirestoreApi] provides a high-level interface for interacting with Firestore,
/// offering automatic type conversion, validation, and enhanced error handling.
///
/// Type parameter [T] represents the model type this API instance will work with.
///
/// Features:
/// - Automatic type conversion between Firestore documents and Dart objects
/// - Built-in validation through [TurboWriteable]
/// - Automatic timestamp management for createdAt/updatedAt fields
/// - Local ID management for easier document tracking
/// - Sensitive data handling
/// - Comprehensive logging
/// - Collection group support
/// - Batch operation capabilities
///
/// Example usage with a custom model:
/// ```dart
/// class User {
///   User({required this.name, this.age});
///
///   final String name;
///   final int? age;
///
///   factory User.fromJson(Map<String, dynamic> json) => User(
///     name: json['name'] as String,
///     age: json['age'] as int?,
///   );
///
///   Map<String, dynamic> toJson() => {
///     'name': name,
///     'age': age,
///   };
/// }
///
/// final api = TurboFirestoreApi<User>(
///   firebaseFirestore: FirebaseFirestore.instance,
///   collectionPath: () => 'users',
///   fromJson: User.fromJson,
///   toJson: (user) => user.toJson(),
/// );
///
/// // Create a new user
/// final user = User(name: 'John', age: 30);
/// await api.set(data: user);
///
/// // Query users
/// final adults = await api.query(
///   where: (ref) => ref.where('age', isGreaterThanOrEqualTo: 18),
/// );
/// ```
class TurboFirestoreApi<T> {
  /// Creates a new instance of [TurboFirestoreApi].
  ///
  /// Required parameters:
  /// - [firebaseFirestore]: The Firestore instance to use for operations
  /// - [collectionPath]: Function that returns the path to the Firestore collection
  ///
  /// Optional parameters for type conversion:
  /// - [toJson]: Converts instances of [T] to Firestore-compatible maps
  /// - [fromJson]: Creates instances of [T] from Firestore documents
  /// - [fromJsonError]: Alternative conversion for error cases
  ///
  /// Document ID management:
  /// - [tryAddLocalId]: When true, adds document ID to local objects
  /// - [idFieldName]: Field name for document ID (default: 'id')
  ///
  /// Timestamp fields:
  /// - [createdAtFieldName]: Field for creation timestamp (default: 'createdAt')
  /// - [updatedAtFieldName]: Field for update timestamp (default: 'updatedAt')
  ///
  /// Advanced features:
  /// - [logger]: Custom logger for operation tracking
  /// - [isCollectionGroup]: Enable collection group queries
  /// - [tryAddLocalDocumentReference]: Add document reference to local objects
  /// - [documentReferenceFieldName]: Field for document reference
  /// - [getOptions]: Custom options for get operations
  /// - [hideSensitiveData]: Automatically hide sensitive data in logs
  ///
  /// Example:
  /// ```dart
  /// final api = TurboFirestoreApi<User>(
  ///   firebaseFirestore: FirebaseFirestore.instance,
  ///   collectionPath: () => 'users',
  ///   fromJson: User.fromJson,
  ///   toJson: (user) => user.toJson(),
  ///   tryAddLocalId: true,
  ///   logger: CustomLogger(),
  /// );
  /// ```
  TurboFirestoreApi({
    required FirebaseFirestore firebaseFirestore,
    required String Function() collectionPath,
    Map<String, dynamic> Function(T value)? toJson,
    T Function(Map<String, dynamic> json)? fromJson,
    T Function(Map<String, dynamic> json)? fromJsonError,
    bool tryAddLocalId = false,
    TurboFirestoreLogger? logger,
    String createdAtFieldName = 'createdAt',
    String updatedAtFieldName = 'updatedAt',
    String idFieldName = 'id',
    String documentReferenceFieldName = 'documentReference',
    bool isCollectionGroup = false,
    bool tryAddLocalDocumentReference = false,
    GetOptions? getOptions,
    bool hideSensitiveData = true,
  })  : _firebaseFirestore = firebaseFirestore,
        _collectionPath = collectionPath,
        _toJson = toJson,
        _fromJson = fromJson,
        _fromJsonError = fromJsonError,
        _tryAddLocalId = tryAddLocalId,
        _log = logger ?? TurboFirestoreLogger(),
        _createdAtFieldName = createdAtFieldName,
        _updatedAtFieldName = updatedAtFieldName,
        _idFieldName = idFieldName,
        _documentReferenceFieldName = documentReferenceFieldName,
        _isCollectionGroup = isCollectionGroup,
        _tryAddLocalDocumentReference = tryAddLocalDocumentReference,
        _getOptions = getOptions;

  // 📍 LOCATOR ------------------------------------------------------------------------------- \\
  // 🧩 DEPENDENCIES -------------------------------------------------------------------------- \\

  /// Used to performs Firestore operations.
  final FirebaseFirestore _firebaseFirestore;

  /// Used to find the Firestore collection.
  final String Function() _collectionPath;

  /// Used to serialize your data to JSON when using 'WithConverter' methods.
  final Map<String, dynamic> Function(T value)? _toJson;

  /// Used to deserialize your data to JSON when using 'WithConverter' methods.
  final T Function(Map<String, dynamic> json)? _fromJson;

  /// Used to deserialize your data to JSON when using 'WithConverter' methods and a data error occurs.
  ///
  /// Use this to create a default object to show to the user in case parsing your data goes wrong.
  /// This is especially useful when you are working with iterables of the same type.
  /// Because now when an error occurs it will use a default object and parsing of the other objects
  /// that have no errors can continue. Whereas before it would just throw an error and stop parsing.
  final T Function(Map<String, dynamic> json)? _fromJsonError;

  /// Used to add an id field to any of your local Firestore data (so not actually in Firestore).
  ///
  /// If this is true then your data will have an id field added based on the [_idFieldName]
  /// specified in the constructor. Add this id field to the model you're serializing to and you
  /// will have easy access to the document id at any time. Any create or update method will by
  /// default try te remove the field again before writing to Firestore (unless specified otherwise).
  ///
  /// Setting this to true will also try to remove the field when deserializing.
  final bool _tryAddLocalId;

  /// Used to add a [DocumentReference] field to any of your local Firestore data (so not actually in Firestore).
  ///
  /// If this is true then your data will have an id field added based on the [_idFieldName]
  /// specified in the constructor. Add this id field to the model you're serializing to and you
  /// will have easy access to the document id at any time. Any create or update method will by
  /// default try te remove the field again before writing to Firestore (unless specified otherwise).
  ///
  /// Setting this to true will also try to remove the field when deserializing.
  final bool _tryAddLocalDocumentReference;

  /// Used to provide proper logging when performing any operation inside the [TurboFirestoreApi].
  final TurboFirestoreLogger _log;

  /// Used to provide a default 'createdAt' field based on the provided [TurboTimestampType] of create methods.
  final String _createdAtFieldName;

  /// Used to provide a default 'updatedAt' field based on the provided [TurboTimestampType] of update methods.
  final String _updatedAtFieldName;

  /// Used to provide an id field to your create/update methods if necessary.
  ///
  /// May also be used to provide an id field to your data from Firestore when fetching data.
  final String _idFieldName;

  /// Used to provide a reference field to your create/update methods if necessary.
  ///
  /// May also be used to provide an id field to your data from Firestore when fetching data.
  final String _documentReferenceFieldName;

  /// Whether the [_collectionPath] refers to a collection group.
  final bool _isCollectionGroup;

  /// An options class that configures the behavior of get() calls on [DocumentReference] and [Query].
  final GetOptions? _getOptions;

  // 🎬 INIT & DISPOSE ------------------------------------------------------------------------ \\
  // 👂 LISTENERS ----------------------------------------------------------------------------- \\
  // ⚡️ OVERRIDES ----------------------------------------------------------------------------- \\
  // 🎩 STATE --------------------------------------------------------------------------------- \\
  // 🛠 UTIL ---------------------------------------------------------------------------------- \\
  // 🧲 FETCHERS ------------------------------------------------------------------------------ \\

  /// Helper method to fetch a [WriteBatch] from [_firebaseFirestore]..
  WriteBatch get writeBatch => _firebaseFirestore.batch();

  /// The current collection
  CollectionReference get collection =>
      _firebaseFirestore.collection(_collectionPath());

  /// A new document
  DocumentReference get doc => collection.doc();

  /// Generates a new document ID without creating the document
  String get genId => doc.id;

  /// Used to determined if a document exists based on given [id].
  Future<bool> docExists({
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
      message: 'Checking if document exists..',
      sensitiveData: SensitiveData(
        path: collectionPathOverride ?? _collectionPath(),
        id: id,
      ),
    );
    return (await docRef.get(_getOptions)).exists;
  }

  // 🏗️ HELPERS ------------------------------------------------------------------------------- \\

  /// Helper method for logging the length of a List result.
  void _logResultLength(List<dynamic> result) {
    if (result.isNotEmpty) {
      _log.info(
        message: 'Found ${result.length} item(s)!',
        sensitiveData: SensitiveData(
          path: _collectionPath(),
        ),
      );
    } else {
      _log.warning(
        message: 'Found 0 items!',
        sensitiveData: SensitiveData(
          path: _collectionPath(),
        ),
      );
    }
  }

  /// Helper method to handle batch responses and extract the result.
  ///
  /// This method properly unwraps the TurboResponse and handles error cases.
  WriteBatchWithReference<Map<String, dynamic>>? _handleBatchResponse(
    TurboResponse<WriteBatchWithReference<Map<String, dynamic>>> response,
  ) {
    return response.when<WriteBatchWithReference<Map<String, dynamic>>?>(
      success: (success) => success.result,
      fail: (_) => null,
    );
  }

  /// Helper method to handle batch operations.
  ///
  /// This method properly handles the batch response and executes the commit operation.
  Future<TurboResponse<DocumentReference>> _handleBatchOperation(
    TurboResponse<WriteBatchWithReference<Map<String, dynamic>>> batchResponse,
  ) async {
    final batchResult = _handleBatchResponse(batchResponse);
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
      return TurboResponse.success(result: batchResult.documentReference);
    } else {
      _log.error(
        message: 'Last batch failed!',
        sensitiveData: null,
      );
      return TurboResponse.emptyFail();
    }
  }

// 🪄 MUTATORS ------------------------------------------------------------------------------ \\

  /// Helper method to run a [Transaction] from [_firebaseFirestore]..
  Future<E> runTransaction<E>(
    TransactionHandler<E> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) =>
      _firebaseFirestore.runTransaction(
        transactionHandler,
        timeout: timeout,
        maxAttempts: maxAttempts,
      );
}

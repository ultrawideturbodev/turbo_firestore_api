import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turbo_firestore_api/turbo_firestore_api.dart';

/// A model for encapsulating sensitive operation data for logging purposes
///
/// This class collects context about Firestore operations, making it easier to:
/// - Debug issues with specific documents or queries
/// - Track operation parameters
/// - Monitor performance
/// - Audit data access
///
/// Example:
/// ```dart
/// final sensitiveData = SensitiveData(
///   path: 'users',
///   id: 'user-123',
///   searchTerm: 'John',
///   searchField: 'name',
///   searchTermType: TurboSearchTermType.startsWith,
/// );
/// log.debug(
///   message: 'Searching for user',
///   sensitiveData: sensitiveData,
/// );
/// ```
class SensitiveData {
  /// Creates a new sensitive data container
  ///
  /// Parameters:
  /// [path] Firestore collection or document path
  /// [id] optional document ID
  /// [whereDescription] description of query conditions
  /// [createTimeStampType] timestamp type for document creation
  /// [field] field name being operated on
  /// [isBatch] whether operation is part of a batch
  /// [isMerge] whether operation is a merge
  /// [isTransaction] whether operation is part of a transaction
  /// [limit] query result limit
  /// [mergeFields] specific fields to merge
  /// [searchField] field to search in
  /// [searchTerm] term to search for
  /// [searchTermType] type of search operation
  /// [type] operation type identifier
  /// [updateTimeStampType] timestamp type for document updates
  /// [data] additional operation data
  const SensitiveData({
    required this.path,
    this.id,
    this.whereDescription,
    this.createTimeStampType,
    this.field,
    this.isBatch,
    this.isMerge,
    this.isTransaction,
    this.limit,
    this.mergeFields,
    this.searchField,
    this.searchTerm,
    this.searchTermType,
    this.type,
    this.updateTimeStampType,
    this.data,
  });

  /// The Firestore path being accessed
  final String path;

  /// The document ID being operated on
  final String? id;

  /// Description of query conditions
  final String? whereDescription;

  /// Fields to merge in update operations
  final List<FieldPath>? mergeFields;

  /// Field name being operated on
  final String? field;

  /// Field to search in for search operations
  final String? searchField;

  /// Term to search for in search operations
  final String? searchTerm;

  /// Type of search being performed
  final TurboSearchTermType? searchTermType;

  /// Operation type identifier
  final String? type;

  /// Timestamp type for document creation
  final TurboTimestampType? createTimeStampType;

  /// Timestamp type for document updates
  final TurboTimestampType? updateTimeStampType;

  /// Whether operation is part of a batch
  final bool? isBatch;

  /// Whether operation is a merge
  final bool? isMerge;

  /// Whether operation is part of a transaction
  final bool? isTransaction;

  /// Query result limit
  final int? limit;

  /// Additional operation data
  final Object? data;

  @override
  String toString() {
    return 'SensitiveData:'
        'path: $path'
        '${id != null ? ', id: $id' : ''}'
        '${whereDescription != null ? ', whereDescription: $whereDescription' : ''}'
        '${createTimeStampType != null ? ', createTimeStampType: $createTimeStampType' : ''}'
        '${field != null ? ', field: $field' : ''}'
        '${isBatch != null ? ', isBatch: $isBatch' : ''}'
        '${isMerge != null ? ', isMerge: $isMerge' : ''}'
        '${isTransaction != null ? ', isTransaction: $isTransaction' : ''}'
        '${limit != null ? ', limit: $limit' : ''}'
        '${mergeFields != null ? ', mergeFields: $mergeFields' : ''}'
        '${searchField != null ? ', searchField: $searchField' : ''}'
        '${searchTerm != null ? ', searchTerm: $searchTerm' : ''}'
        '${searchTermType != null ? ', searchTermType: $searchTermType' : ''}'
        '${type != null ? ', type: $type' : ''}'
        '${updateTimeStampType != null ? ', updateTimeStampType: $updateTimeStampType' : ''}'
        '${data != null ? ', data: $data' : ''}';
  }
}

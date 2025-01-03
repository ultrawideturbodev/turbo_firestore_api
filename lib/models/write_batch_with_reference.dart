import 'package:cloud_firestore/cloud_firestore.dart';

/// A container for a Firestore write batch and its most recently used document reference
///
/// This class helps track batch operations by keeping both the batch and the last
/// document reference together. This is useful for:
/// - Chaining batch operations
/// - Accessing the last modified document
/// - Maintaining type safety in batch operations
/// - Building complex atomic updates
///
/// Example:
/// ```dart
/// // Create a new user in a batch
/// final response = await api.createDocs(
///   writeable: user,
///   writeBatch: batch,
/// );
///
/// response.when(
///   success: (result) async {
///     // Access the batch and reference
///     final batch = result.writeBatch;
///     final userRef = result.documentReference;
///
///     // Add more operations to the batch
///     batch.update(userRef, {'status': 'active'});
///
///     // Commit all changes atomically
///     await batch.commit();
///   },
///   fail: (error) => print('Error: $error'),
/// );
/// ```
class WriteBatchWithReference<T> {
  /// Creates a new write batch with reference container
  ///
  /// Parameters:
  /// [writeBatch] the Firestore batch operation
  /// [documentReference] reference to the last document operated on
  const WriteBatchWithReference({
    required this.writeBatch,
    required this.documentReference,
  });

  /// The Firestore write batch for atomic operations
  ///
  /// This batch can be:
  /// - Used for additional operations
  /// - Committed to apply all changes
  /// - Passed to other batch operations
  final WriteBatch writeBatch;

  /// Reference to the last document in the batch
  ///
  /// This reference:
  /// - Points to the most recently modified document
  /// - Is typed with [T] for type safety
  /// - Can be used for further operations
  final DocumentReference<T> documentReference;
}

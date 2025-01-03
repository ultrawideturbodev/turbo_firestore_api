import 'package:cloud_firestore/cloud_firestore.dart';

/// A function type for modifying Firestore collection queries.
///
/// Example:
/// ```dart
/// CollectionReferenceDef<User> activeUsers = (query) => query
///   .where('status', isEqualTo: 'active')
///   .orderBy('name');
/// ```
typedef CollectionReferenceDef<T> = Query<T> Function(
    Query<T> collectionReference);

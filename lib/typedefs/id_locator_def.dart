/// A function type for locating instances by their ID.
///
/// Example:
/// ```dart
/// IdLocatorDef<DocumentReference<User>> locateUserRef = (id) =>
///   firestore.collection('users').doc(id).withConverter(...);
/// ```
typedef IdLocatorDef<T> = T Function(String id);

/// Extension on [List] that provides utility methods for working with lists in the context of Turbo Firestore.
extension TurboListExtensionExtension<T> on List<T> {
  /// Converts a list of elements into a map where the keys are derived from the elements using the provided [id] function.
  ///
  /// This is particularly useful when you need to create a lookup map from a list of objects,
  /// where each object has a unique identifier that can be extracted.
  ///
  /// Example:
  /// ```dart
  /// final users = [User(id: '1'), User(id: '2')];
  /// final userMap = users.toIdMap((user) => user.id);
  /// // Result: {'1': User(id: '1'), '2': User(id: '2')}
  /// ```
  ///
  /// Parameters:
  /// - [id]: A function that extracts a unique identifier of type [E] from each element of type [T].
  ///
  /// Returns:
  /// A [Map] where the keys are of type [E] (the extracted IDs) and the values are the original elements of type [T].
  Map<E, T> toIdMap<E extends Object>(E Function(T element) id) {
    final map = <E, T>{};
    for (final element in this) {
      map[id(element)] = element;
    }
    return map;
  }
}

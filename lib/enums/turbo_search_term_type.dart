/// Defines the type of search operation to perform in Firestore queries
///
/// This enum is used to specify how search terms should be matched against
/// document fields. It supports both prefix matching for string fields and
/// array containment for array fields.
///
/// Example:
/// ```dart
/// // Prefix matching
/// api.listBySearchTerm(
///   searchTerm: 'Jo',
///   searchField: 'name',
///   searchTermType: TurboSearchTermType.startsWith,
/// );
///
/// // Array containment
/// api.listBySearchTerm(
///   searchTerm: 'tag1',
///   searchField: 'tags',
///   searchTermType: TurboSearchTermType.arrayContains,
/// );
/// ```
enum TurboSearchTermType {
  /// Matches documents where the specified field starts with the search term
  ///
  /// Use this for prefix-based string searches. For example, searching for 'Jo'
  /// in a name field would match 'John', 'Joseph', etc.
  startsWith,

  /// Matches documents where the specified array field contains the search term
  ///
  /// Use this for searching within array fields. For example, searching for 'tag1'
  /// in a tags field would match documents with ['tag1', 'tag2'] or ['tag1'].
  arrayContains,
}

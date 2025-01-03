part of 'turbo_firestore_api.dart';

/// Extension that adds search operations to [TurboFirestoreApi]
///
/// Provides methods for searching documents in Firestore
///
/// Features:
/// - Text-based search
/// - Numeric search
/// - Array containment search
/// - Prefix matching
/// - Type-safe results
/// - Result limiting
///
/// Example:
/// ```dart
/// final api = TurboFirestoreApi<User>();
/// final response = await api.listBySearchTerm(
///   searchTerm: 'John',
///   searchField: 'name',
///   searchTermType: TurboSearchTermType.startsWith,
/// );
/// ```
///
/// See also:
/// [TurboFirestoreListApi] list operations
/// [TurboFirestoreGetApi] single document retrieval
extension TurboFirestoreSearchApi<T> on TurboFirestoreApi<T> {
  /// Searches for documents matching a search term
  ///
  /// Returns raw Firestore data without type conversion
  /// Supports both text and numeric search terms
  ///
  /// Parameters:
  /// [searchTerm] term to search for
  /// [searchField] field to search in
  /// [searchTermType] type of search to perform
  /// [doSearchNumberEquivalent] whether to also search for numeric value
  /// [limit] maximum number of results to return
  ///
  /// Returns [TurboResponse] containing:
  /// - Success with list of matching documents
  /// - Fail with operation errors
  ///
  /// Features:
  /// - Raw data access
  /// - Text and numeric search
  /// - Array containment search
  /// - Prefix matching
  /// - Result limiting
  /// - Error logging
  ///
  /// Example:
  /// ```dart
  /// final response = await api.listBySearchTerm(
  ///   searchTerm: 'John',
  ///   searchField: 'name',
  ///   searchTermType: TurboSearchTermType.startsWith,
  ///   limit: 10,
  /// );
  /// response.when(
  ///   success: (users) => print('Found ${users.length} users'),
  ///   fail: (error) => print('Error $error'),
  /// );
  /// ```
  ///
  /// See also:
  /// [listBySearchTermWithConverter] type-safe search
  /// [listByQuery] custom queries
  Future<TurboResponse<List<Map<String, dynamic>>>> listBySearchTerm({
    required String searchTerm,
    required String searchField,
    required TurboSearchTermType searchTermType,
    bool doSearchNumberEquivalent = false,
    int? limit,
  }) async {
    try {
      _log.debug(
        message: 'Searching without converter..',
        sensitiveData: SensitiveData(
          path: _collectionPath(),
          searchTerm: searchTerm,
          searchField: searchField,
          searchTermType: searchTermType,
          limit: limit,
        ),
      );
      collectionReferenceQuery(
              Query<Map<String, dynamic>> collectionReference) =>
          switch (searchTermType) {
            TurboSearchTermType.arrayContains => limit == null
                ? collectionReference.where(
                    searchField,
                    arrayContainsAny: [searchTerm, ...searchTerm.split(' ')],
                  )
                : collectionReference.where(
                    searchField,
                    arrayContainsAny: [searchTerm, ...searchTerm.split(' ')],
                  ).limit(limit),
            TurboSearchTermType.startsWith => limit == null
                ? collectionReference.where(
                    searchField,
                    isGreaterThanOrEqualTo: searchTerm,
                    isLessThan: '$searchTerm\uf8ff',
                  )
                : collectionReference
                    .where(
                      searchField,
                      isGreaterThanOrEqualTo: searchTerm,
                      isLessThan: '$searchTerm\uf8ff',
                    )
                    .limit(limit),
          };
      final result = (await collectionReferenceQuery(
        listCollectionReference(),
      ).get(_getOptions))
          .docs
          .map(
            (e) => e.data(),
          )
          .toList();
      if (doSearchNumberEquivalent) {
        try {
          final numberSearchTerm = double.tryParse(searchTerm);
          if (numberSearchTerm != null) {
            collectionReferenceQuery(
                    Query<Map<String, dynamic>> collectionReference) =>
                switch (searchTermType) {
                  TurboSearchTermType.arrayContains => limit == null
                      ? collectionReference.where(
                          searchField,
                          arrayContainsAny: [numberSearchTerm],
                        )
                      : collectionReference.where(
                          searchField,
                          arrayContainsAny: [numberSearchTerm],
                        ).limit(limit),
                  TurboSearchTermType.startsWith => limit == null
                      ? collectionReference.where(
                          searchField,
                          isGreaterThanOrEqualTo: numberSearchTerm,
                          isLessThan: numberSearchTerm + 1,
                        )
                      : collectionReference
                          .where(
                            searchField,
                            isGreaterThanOrEqualTo: numberSearchTerm,
                            isLessThan: numberSearchTerm + 1,
                          )
                          .limit(limit),
                };
            final numberResult = (await collectionReferenceQuery(
              listCollectionReference(),
            ).get(_getOptions))
                .docs
                .map(
                  (e) => e.data(),
                )
                .toList();
            result.addAll(numberResult);
          }
        } catch (error, stackTrace) {
          _log.error(
            message:
                '${error.runtimeType} caught while trying to search for number equivalent',
            sensitiveData: SensitiveData(
              path: _collectionPath(),
              searchTerm: searchTerm,
              searchTermType: searchTermType,
              searchField: searchField,
            ),
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
      _logResultLength(result);
      return TurboResponse.success(result: result);
    } catch (error, stackTrace) {
      _log.error(
        message: 'Unable to find documents',
        sensitiveData: SensitiveData(
          path: _collectionPath(),
          searchTerm: searchTerm,
          searchField: searchField,
          searchTermType: searchTermType,
        ),
        error: error,
        stackTrace: stackTrace,
      );
      return TurboResponse.fail(error: error);
    }
  }

  /// Searches for documents with type conversion
  ///
  /// Returns documents converted to type [T] using [_fromJson]
  /// Supports both text and numeric search terms
  ///
  /// Parameters:
  /// [searchTerm] term to search for
  /// [searchField] field to search in
  /// [searchTermType] type of search to perform
  /// [doSearchNumberEquivalent] whether to also search for numeric value
  /// [limit] maximum number of results to return
  ///
  /// Returns [TurboResponse] containing:
  /// - Success with list of typed documents
  /// - Fail with operation errors
  ///
  /// Features:
  /// - Automatic type conversion
  /// - Text and numeric search
  /// - Array containment search
  /// - Prefix matching
  /// - Result limiting
  /// - Error logging
  ///
  /// Example:
  /// ```dart
  /// final response = await api.listBySearchTermWithConverter(
  ///   searchTerm: 'John',
  ///   searchField: 'name',
  ///   searchTermType: TurboSearchTermType.startsWith,
  ///   limit: 10,
  /// );
  /// response.when(
  ///   success: (users) => users.forEach((user) => print(user.name)),
  ///   fail: (error) => print('Error $error'),
  /// );
  /// ```
  ///
  /// See also:
  /// [listBySearchTerm] raw data search
  /// [listByQueryWithConverter] custom type-safe queries
  Future<TurboResponse<List<T>>> listBySearchTermWithConverter({
    required String searchTerm,
    required String searchField,
    required TurboSearchTermType searchTermType,
    bool doSearchNumberEquivalent = false,
    int? limit,
  }) async {
    try {
      _log.debug(
        message: 'Searching with converter..',
        sensitiveData: SensitiveData(
          path: _collectionPath(),
          searchTerm: searchTerm,
          searchField: searchField,
          searchTermType: searchTermType,
          limit: limit,
        ),
      );
      collectionReferenceQuery(Query<T> collectionReference) =>
          switch (searchTermType) {
            TurboSearchTermType.arrayContains => limit == null
                ? collectionReference.where(
                    searchField,
                    arrayContainsAny: [searchTerm, ...searchTerm.split(' ')],
                  )
                : collectionReference.where(
                    searchField,
                    arrayContainsAny: [searchTerm, ...searchTerm.split(' ')],
                  ).limit(limit),
            TurboSearchTermType.startsWith => limit == null
                ? collectionReference.where(
                    searchField,
                    isGreaterThanOrEqualTo: searchTerm,
                    isLessThan: '$searchTerm\uf8ff',
                  )
                : collectionReference
                    .where(
                      searchField,
                      isGreaterThanOrEqualTo: searchTerm,
                      isLessThan: '$searchTerm\uf8ff',
                    )
                    .limit(limit),
          };
      final result = (await collectionReferenceQuery(
        listCollectionReferenceWithConverter(),
      ).get(_getOptions))
          .docs
          .map((e) => e.data())
          .toList();
      if (doSearchNumberEquivalent) {
        try {
          final numberSearchTerm = double.tryParse(searchTerm);
          if (numberSearchTerm != null) {
            collectionReferenceQuery(Query<T> collectionReference) =>
                switch (searchTermType) {
                  TurboSearchTermType.startsWith => limit == null
                      ? collectionReference.where(
                          searchField,
                          arrayContainsAny: [numberSearchTerm],
                        )
                      : collectionReference.where(
                          searchField,
                          arrayContainsAny: [numberSearchTerm],
                        ).limit(limit),
                  TurboSearchTermType.arrayContains => limit == null
                      ? collectionReference.where(
                          searchField,
                          isGreaterThanOrEqualTo: numberSearchTerm,
                          isLessThan: numberSearchTerm + 1,
                        )
                      : collectionReference
                          .where(
                            searchField,
                            isGreaterThanOrEqualTo: numberSearchTerm,
                            isLessThan: numberSearchTerm + 1,
                          )
                          .limit(limit),
                };
            final numberResult = (await collectionReferenceQuery(
              listCollectionReferenceWithConverter(),
            ).get(_getOptions))
                .docs
                .map(
                  (e) => e.data(),
                )
                .toList();
            result.addAll(numberResult);
          }
        } catch (error, stackTrace) {
          _log.error(
            message: 'Unable to search for number equivalent',
            sensitiveData: SensitiveData(
              path: _collectionPath(),
              searchTerm: searchTerm,
              searchField: searchField,
              searchTermType: searchTermType,
            ),
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
      _logResultLength(result);
      return TurboResponse.success(result: result);
    } catch (error, stackTrace) {
      _log.error(
          message: 'Unable to find documents',
          sensitiveData: SensitiveData(
            path: _collectionPath(),
            searchTerm: searchTerm,
            searchField: searchField,
            searchTermType: searchTermType,
          ),
          error: error,
          stackTrace: stackTrace);
      return TurboResponse.fail(error: error);
    }
  }
}

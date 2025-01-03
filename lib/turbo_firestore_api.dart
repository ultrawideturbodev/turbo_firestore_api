/// A powerful and flexible Firestore API wrapper for Flutter applications
///
/// This package provides a type-safe, feature-rich interface for interacting with Cloud Firestore
/// It includes support for CRUD operations, real-time updates, batch operations, and more
///
/// Features:
/// - Type-safe document operations
/// - Real-time data streaming
/// - Batch and transaction support
/// - Automatic timestamp management
/// - Search capabilities
/// - Collection group queries
/// - Error handling and logging
/// - Optimistic updates
/// - Debouncing and mutex support
/// - Authentication state synchronization
///
/// Example:
/// ```dart
/// // Create a typed API instance
/// final api = TurboFirestoreApi<User>(
///   collectionPath: 'users',
///   fromJson: User.fromJson,
///   toJson: (user) => user.toJson(),
/// );
///
/// // Create a document
/// final response = await api.createDoc(
///   writeable: user,
///   timestampType: TurboTimestampType.createdAndUpdated,
/// );
///
/// // Stream real-time updates
/// api.streamAllWithConverter().listen((users) {
///   print('Got ${users.length} users');
/// });
/// ```
///
/// See the individual components for detailed documentation:
library;

/// Core utilities for logging, debugging and
export 'util/turbo_firestore_logger.dart';
export 'util/turbo_debouncer.dart';
export 'util/turbo_mutex.dart';
export 'util/turbo_block_debouncer.dart';

/// Abstract interfaces for API functionality
export 'abstracts/turbo_writeable.dart';
export 'abstracts/turbo_writeable_id.dart';

/// Main API class and extensions
export 'apis/turbo_firestore_api.dart';

/// Enums for configuring API behavior
export 'enums/turbo_search_term_type.dart';
export 'enums/turbo_timestamp_type.dart';
export 'enums/turbo_parse_type.dart';

/// Exception types for error handling
export 'exceptions/invalid_json_exception.dart';

/// Data models and utilities
export 'models/sensitive_data.dart';
export 'models/write_batch_with_reference.dart';

/// Services for state management
export 'services/turbo_auth_sync_service.dart';
export 'services/turbo_collection_service.dart';
export 'services/turbo_document_service.dart';

/// Extensions for enhanced functionality
export 'extensions/completer_extension.dart';
export 'extensions/turbo_list_extension.dart';
export 'extensions/turbo_map_extension.dart';

/// Mixins for shared behavior
export 'mixins/turbo_exception_handler.dart';

/// Type definitions
export 'typedefs/collection_reference_def.dart';
export 'typedefs/id_locator_def.dart';
export 'typedefs/turbo_doc_builder.dart';
export 'typedefs/turbo_locator_def.dart';

/// Constants
export 'constants/k_errors.dart';

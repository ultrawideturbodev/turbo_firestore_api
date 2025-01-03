/// A function type for locating or creating instances of type [T].
///
/// Example:
/// ```dart
/// TurboLocatorDef<UserService> locateUserService = () => UserService();
/// final userService = locateUserService();
/// ```
typedef TurboLocatorDef<T> = T Function();

import 'package:firebase_auth/firebase_auth.dart';
import 'package:loglytics/loglytics.dart';
import 'package:turbo_firestore_api/constants/k_errors.dart';
import 'package:turbo_response/turbo_response.dart';

/// A mixin that provides Firebase Authentication exception handling.
///
/// Provides a standardized way to handle Firebase Authentication exceptions
/// by converting them into user-friendly [TurboResponse] objects with:
/// - Appropriate error titles
/// - Descriptive error messages
/// - Original error details for debugging
///
/// Usage:
/// ```dart
/// class AuthService with TurboExceptionHandler {
///   Future<TurboResponse<UserCredential>> signIn() async {
///     try {
///       // Sign in code...
///     } on FirebaseAuthException catch (e) {
///       return tryHandleFirebaseAuthException(
///         firebaseAuthException: e,
///         log: log,
///       );
///     }
///   }
/// }
/// ```
mixin TurboExceptionHandler {
  /// Handles Firebase Authentication exceptions and converts them to [TurboResponse].
  ///
  /// Takes a [FirebaseAuthException] and returns a [TurboResponse] with appropriate
  /// error messages based on the exception code. Logs the error details using
  /// the provided [log] instance.
  ///
  /// Parameters:
  /// - [firebaseAuthException] - The Firebase Authentication exception to handle
  /// - [log] - Logger instance for error logging
  ///
  /// Returns a [TurboResponse] with appropriate error details
  TurboResponse<T> tryHandleFirebaseAuthException<T>({
    required FirebaseAuthException firebaseAuthException,
    required Log log,
  }) {
    log.error('Handling FirebaseAuthException: ${firebaseAuthException.code}');
    log.error(
        'Handling FirebaseAuthException: ${firebaseAuthException.message}  ');
    switch (firebaseAuthException.code) {
      case kErrorsInvalidLoginCredentials:
        return TurboResponse.fail(
          error: firebaseAuthException,
          title: 'Invalid credentials',
          message: 'The credentials provided are invalid, please try again.',
        );
      case kErrorsAccountExistsWithDifferentCredentials:
        return TurboResponse.fail(
          error: firebaseAuthException,
          title: 'Account already in use',
          message: 'The account is already in use, please try again.',
        );
      case kErrorsInvalidCredential:
        return TurboResponse.fail(
          error: firebaseAuthException,
          title: 'Invalid credential',
          message:
              'Something went wrong verifying the credential, please try again.',
        );
      case kErrorsOperationNotAllowed:
        return TurboResponse.fail(
          error: firebaseAuthException,
          title: 'Operation not allowed',
          message:
              'The type of account corresponding to the credential is not enabled, please try again.',
        );
      case kErrorsUserDisabled:
        return TurboResponse.fail(
          error: firebaseAuthException,
          title: 'Account disabled',
          message:
              'The account corresponding to the credential is disabled, please try again.',
        );
      case kErrorsUserNotFound:
        return TurboResponse.fail(
          error: firebaseAuthException,
          title: 'Account not found',
          message:
              'The account corresponding to the credential was not found, please try again.',
        );
      case kErrorsWrongPassword:
        return TurboResponse.fail(
          error: firebaseAuthException,
          title: 'Wrong password',
          message: 'The password is invalid, please try again.',
        );
      case kErrorsInvalidVerificationCode:
        return TurboResponse.fail(
          error: firebaseAuthException,
          title: 'Invalid verification code',
          message:
              'The verification code of the credential is invalid, please try again.',
        );
      case kErrorsInvalidVerificationId:
        return TurboResponse.fail(
          error: firebaseAuthException,
          title: 'Invalid verification id',
          message:
              'The verification id of the credential is invalid, please try again.',
        );
      case kErrorsInvalidEmail:
        return TurboResponse.fail(
          error: firebaseAuthException,
          title: 'Invalid email',
          message: 'The email address provided is invalid, please try again.',
        );
      case kErrorsEmailAlreadyInUse:
        return TurboResponse.fail(
          error: firebaseAuthException,
          title: 'Email already in use',
          message:
              'The email used already exists, please use a different email or try to log in.',
        );
      case kErrorsWeakPassword:
        return TurboResponse.fail(
          error: firebaseAuthException,
          title: 'Weak password',
          message: 'The password provided is too weak, please try again.',
        );
      case kErrorsInvalidPhoneNumber:
        return TurboResponse.fail(
          error: firebaseAuthException,
          title: 'Invalid Phone Number',
          message:
              'The phone number has an invalid format. Please input a valid phone number.',
        );
      case kErrorsCaptchaCheckFailed:
        return TurboResponse.fail(
          error: firebaseAuthException,
          title: 'Captcha Check Failed',
          message:
              'The reCAPTCHA response token was invalid or expired, or the request contained an invalid API key. Please try again.',
        );
      case kErrorsQuotaExceeded:
        return TurboResponse.fail(
          error: firebaseAuthException,
          title: 'Quota Exceeded',
          message:
              'The quota of SMS verification messages has been exceeded. This is done to prevent abuse. Please try again later.',
        );
      case kErrorsProviderAlreadyLinked:
        return TurboResponse.fail(
          error: firebaseAuthException,
          title: 'Provider Already Linked',
          message:
              'The provider account is already linked to another user account. Please use a different account or unlink the existing one.',
        );
      case kErrorsCredentialAlreadyInUse:
        return TurboResponse.fail(
          error: firebaseAuthException,
          title: 'Credential Already In Use',
          message:
              'The account corresponding to the credential already exists among your users, or is already linked to a Firebase User. Please use a different credential.',
        );
    }
    return TurboResponse.fail(
      error: firebaseAuthException,
      title: 'Unknown error',
      message: 'An unknown error has occurred, please try again.',
    );
  }
}

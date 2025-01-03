/// Error code when an account already exists with different credentials.
const kErrorsAccountExistsWithDifferentCredentials =
    'account-exists-with-different-credential';

/// Error code when the captcha verification fails.
const kErrorsCaptchaCheckFailed = 'captcha-check-failed';

/// Error code when the credential is already associated with a different user account.
const kErrorsCredentialAlreadyInUse = 'credential-already-in-use';

/// Error code when attempting to create an account with an email that is already in use.
const kErrorsEmailAlreadyInUse = 'email-already-in-use';

/// Error code when the provided credential is malformed or has expired.
const kErrorsInvalidCredential = 'invalid-credential';

/// Error code when the email address is not valid.
const kErrorsInvalidEmail = 'invalid-email';

/// Error code when the phone number is not valid.
const kErrorsInvalidPhoneNumber = 'invalid-phone-number';

/// Error code when the SMS verification code is not valid.
const kErrorsInvalidVerificationCode = 'invalid-verification-code';

/// Error code when the verification ID for phone auth is not valid.
const kErrorsInvalidVerificationId = 'invalid-verification-id';

/// Error code when the requested authentication operation is not allowed.
const kErrorsOperationNotAllowed = 'operation-not-allowed';

/// Error code when attempting to link a provider that is already linked to the account.
const kErrorsProviderAlreadyLinked = 'provider-already-linked';

/// Error code when the project's quota for the specified operation has been exceeded.
const kErrorsQuotaExceeded = 'quota-exceeded';

/// Error code when the user account has been disabled by an administrator.
const kErrorsUserDisabled = 'user-disabled';

/// Error code when the specified user account cannot be found.
const kErrorsUserNotFound = 'user-not-found';

/// Error code when the password does not meet the minimum requirements.
const kErrorsWeakPassword = 'weak-password';

/// Error code when the password is invalid for the specified email.
const kErrorsWrongPassword = 'wrong-password';

/// Error code when the login credentials are invalid.
const kErrorsInvalidLoginCredentials = 'INVALID_LOGIN_CREDENTIALS';

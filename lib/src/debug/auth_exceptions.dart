import '../ember_core.dart';

abstract class AuthFailure extends EmberException {
  AuthFailure({required super.devMessage, String? userMessage, super.metadata})
    : super(
        module: Module.fire,
        logType: LogType.failure,
        userMessage: userMessage ?? 'Authentication failed. Please check your details',
      );
}

abstract class AuthError extends EmberException {
  AuthError({required super.devMessage, String? userMessage, super.metadata, super.logType = LogType.error})
    : super(
        module: Module.fire,
        userMessage: userMessage ?? 'An authentication service error occurred. Please try again later or contact support',
      );
}

// Failures (LogType.failure)

class AuthCredentialsFailure extends AuthFailure {
  AuthCredentialsFailure({String? reason})
    : super(
        devMessage: 'Invalid Credentials: ${reason ?? 'General failure'}',
        userMessage: 'Invalid login details. Please check your email and password',
        metadata: reason != null ? {'reason': reason} : {},
      );
}

class AuthRegistrationConflictFailure extends AuthFailure {
  AuthRegistrationConflictFailure({required String field, required String value})
    : super(
        devMessage: 'Registration Conflict: $field \'$value\' already exists',
        userMessage: 'This $field is already registered. Please use a different $field or try logging in',
        metadata: {'field': field, 'value': value},
      );
}

class AuthInvalidInputFailure extends AuthFailure {
  AuthInvalidInputFailure({required String field, String? reason})
    : super(
        devMessage: 'Invalid Input: Field \'$field\' is invalid${reason != null ? ' ($reason)' : ''}.',
        userMessage:
            reason == 'weak'
                ? 'The password provided is too weak. Please choose a stronger one'
                : 'The $field provided is invalid. Please enter a valid $field',
        metadata: {'field': field, if (reason != null) 'reason': reason},
      );
}

class AuthVerificationFailure extends AuthFailure {
  AuthVerificationFailure({required String reason})
    : super(
        devMessage: 'Verification Failed: $reason',
        userMessage: 'Verification failed. Please check the code or link, or request a new one',
        metadata: {'reason': reason},
      );
}

class AuthRequiresRecentLoginFailure extends AuthFailure {
  AuthRequiresRecentLoginFailure()
    : super(
        devMessage: 'Operation requires recent authentication',
        userMessage: 'This action is sensitive and requires you to log in again for security',
      );
}

class AuthAccountLinkingFailure extends AuthFailure {
  AuthAccountLinkingFailure({required String reason})
    : super(
        devMessage: 'Account Linking Failed: $reason',
        userMessage: 'Could not link account. It might already be associated with another user or sign-in method',
        metadata: {'reason': reason},
      );
}

class AuthSessionFailure extends AuthFailure {
  AuthSessionFailure({required String reason})
    : super(
        devMessage: 'Session Invalid: $reason',
        userMessage: 'Your session is no longer valid. Please log in again',
        metadata: {'reason': reason},
      );
}

// Errors (LogType.error / LogType.critical)

class AuthAccountStateError extends AuthError {
  AuthAccountStateError({required String reason})
    : super(
        devMessage: 'Account State Error: $reason',
        userMessage: 'Your account access has been restricted ($reason). Please contact support',
        metadata: {'reason': reason},
        logType: LogType.error, // User needs specific info, but it's a configured state
      );
}

class AuthServiceError extends AuthError {
  AuthServiceError({required String reason})
    : super(
        devMessage: 'Firebase Auth Service Error: $reason',
        userMessage: 'An authentication service error occurred ($reason). Please try again later',
        metadata: {'reason': reason},
        logType: LogType.error, // Service-side issue
      );
}

class AuthConfigurationError extends AuthError {
  AuthConfigurationError({required String reason, bool critical = true})
    : super(
        devMessage: 'Firebase Auth Configuration Error: $reason',
        userMessage: 'A configuration error occurred. Please contact support',
        metadata: {'reason': reason},
        logType: critical ? LogType.critical : LogType.error, // Usually critical config issues
      );
}

class AuthEnvironmentError extends AuthError {
  AuthEnvironmentError({required String reason})
    : super(
        devMessage: 'Authentication Environment Error: $reason',
        userMessage: 'Cannot perform authentication due to a device or browser issue ($reason)',
        metadata: {'reason': reason},
        logType: LogType.error, // Environment issue
      );
}

class AuthUnknownError extends AuthError {
  AuthUnknownError({String? code})
    : super(
        devMessage: 'Unknown Firebase Auth error${code != null ? ' (Code: $code)' : ''}',
        userMessage: 'An unexpected authentication error occurred. Please try again',
        metadata: code != null ? {'firebase_code': code} : {},
        logType: LogType.unknownError,
      );
}

// --- Factory Constructor for Mapping ---

/// Provides a convenient way to create specific Auth exceptions from Firebase error codes.
class BessFirebaseAuthExceptionFactory {
  static EmberException fromCode(String code) {
    // Normalize case for reliable matching
    final String lowerCaseCode = code.toLowerCase();

    switch (lowerCaseCode) {
      // --- Failures ---
      case 'invalid-credential': // Often generic for login issues
      case 'invalid-login-credentials': // Explicit generic login failure
      case 'user-not-found':
      case 'wrong-password':
      case 'user-mismatch':
        return AuthCredentialsFailure(reason: lowerCaseCode);

      case 'email-already-in-use':
      case 'email-already-exists':
        return AuthRegistrationConflictFailure(field: 'email', value: 'provided');
      case 'uid-already-exists':
        return AuthRegistrationConflictFailure(field: 'user ID', value: 'provided');

      case 'invalid-email':
        return AuthInvalidInputFailure(field: 'email');
      case 'weak-password':
        return AuthInvalidInputFailure(field: 'password', reason: 'weak');

      case 'invalid-verification-code':
        return AuthVerificationFailure(reason: 'invalid_code');
      case 'invalid-verification-id':
        return AuthVerificationFailure(reason: 'invalid_id');
      case 'expired-action-code':
        return AuthVerificationFailure(reason: 'expired_code');
      case 'invalid-action-code':
        return AuthVerificationFailure(reason: 'invalid_action_code');
      case 'missing-action-code':
        return AuthVerificationFailure(reason: 'missing_code');

      case 'requires-recent-login':
        return AuthRequiresRecentLoginFailure();

      case 'credential-already-in-use':
        return AuthAccountLinkingFailure(reason: 'credential_in_use');
      case 'account-exists-with-different-credential':
        return AuthAccountLinkingFailure(reason: 'different_credential');
      case 'provider-already-linked': // Similar to linking issues
        return AuthAccountLinkingFailure(reason: 'provider_already_linked');

      case 'user-token-expired':
        return AuthSessionFailure(reason: 'token_expired');
      case 'user-token-revoked':
        return AuthSessionFailure(reason: 'token_revoked');
      case 'session-cookie-expired':
        return AuthSessionFailure(reason: 'session_cookie_expired');
      case 'user-token-mismatch':
        return AuthSessionFailure(reason: 'token_mismatch');

      // --- Errors / Critical ---
      case 'user-disabled':
        return AuthAccountStateError(reason: 'disabled');

      case 'quota-exceeded':
        return AuthServiceError(reason: 'quota_exceeded');
      case 'internal-error':
        return AuthServiceError(reason: 'internal_firebase_error');
      case 'invalid-recipient-email': // Likely service-side if format was already validated client-side
        return AuthServiceError(reason: 'invalid_recipient_email_server_side');

      case 'operation-not-allowed':
        return AuthConfigurationError(reason: 'operation_not_allowed', critical: false); // Config, but maybe not critical failure
      case 'invalid-message-payload':
        return AuthConfigurationError(reason: 'template_payload_invalid');
      case 'invalid-sender':
        return AuthConfigurationError(reason: 'template_sender_invalid');
      case 'missing-iframe-start':
      case 'missing-iframe-end':
      case 'missing-iframe-src':
        return AuthConfigurationError(reason: 'template_iframe_issue');
      case 'auth-domain-config-required':
        return AuthConfigurationError(reason: 'auth_domain_missing');
      case 'missing-app-credential':
      case 'invalid-app-credential':
        return AuthConfigurationError(reason: 'platform_app_credential_issue');
      case 'invalid-cordova-configuration':
        return AuthConfigurationError(reason: 'cordova_config_invalid');
      case 'app-deleted':
        return AuthConfigurationError(reason: 'firebase_app_deleted', critical: true); // Definitely critical
      case 'app-not-authorized':
        return AuthConfigurationError(reason: 'app_not_authorized_api_key', critical: true); // Critical config

      case 'web-storage-unsupported':
        return AuthEnvironmentError(reason: 'web_storage_unsupported');
      case 'keychain-error':
        return AuthEnvironmentError(reason: 'ios_keychain_error');

      // Default: Unknown Error
      default:
        return AuthUnknownError(code: code);
    }
  }
}

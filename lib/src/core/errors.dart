import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// An error that carries a message that is safe and useful to show a user.
class AppException implements Exception {
  AppException(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'AppException: $message${cause == null ? '' : ' (caused by $cause)'}';

  /// Turns anything thrown by the data layer into an [AppException].
  static AppException from(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;

    if (error is PostgrestException) {
      return AppException(_postgrestMessage(error), cause: error, stackTrace: stackTrace);
    }
    if (error is AuthException) {
      return AppException(_authMessage(error), cause: error, stackTrace: stackTrace);
    }
    if (error is SocketException || error is TimeoutException || error is HttpException) {
      return AppException('Can\'t reach the server. Check your connection and try again.', cause: error, stackTrace: stackTrace);
    }
    return AppException('Something went wrong.', cause: error, stackTrace: stackTrace);
  }

  static String _postgrestMessage(PostgrestException e) {
    switch (e.code) {
      // Raised deliberately by the database's RPCs; the message is meant for people.
      case 'BS001':
      case 'BS002':
      case 'BS003':
      case 'BS004':
        return e.message;
      case '42501':
        return 'You don\'t have permission to do that.';
      case '23505':
        return 'That already exists.';
      case '23503':
        return 'That refers to something that no longer exists.';
      case '23P01':
        return 'That overlaps with something that is already scheduled.';
      case 'P0002':
        return 'That could not be found.';
      case 'PGRST301':
      case 'PGRST303':
        return 'Your session has expired. Please sign in again.';
    }
    final message = e.message.toLowerCase();
    if (message.contains('failed host lookup') || message.contains('connection refused') || message.contains('socketexception')) {
      return 'Can\'t reach the server. Check your connection and try again.';
    }
    return 'The server rejected that request.';
  }

  static String _authMessage(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return 'Incorrect email or password.';
      case 'email_not_confirmed':
        return 'Please confirm your email address first.';
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'user_banned':
        return 'This account has been deactivated.';
      case 'weak_password':
        return 'That password is too weak. Use at least 8 characters.';
      case 'same_password':
        return 'Choose a password different from your current one.';
      case 'session_expired':
      case 'session_not_found':
      case 'refresh_token_not_found':
        return 'Your session has expired. Please sign in again.';
    }
    return e.message.isEmpty ? 'Authentication failed.' : e.message;
  }
}

/// Runs [action] and rethrows anything it throws as an [AppException],
/// preserving the original stack trace.
Future<T> guarded<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on AppException {
    rethrow;
  } catch (e, st) {
    Error.throwWithStackTrace(AppException.from(e, st), st);
  }
}

/// Row level security silently filters rows out of updates and deletes. When
/// a write that should have touched [expected] rows touched none, tell the
/// user instead of pretending it worked.
void ensureAffected(List<dynamic> rows, int expected) {
  if (expected > 0 && rows.isEmpty) {
    throw AppException('Nothing was changed. You may not have permission to do that.');
  }
}

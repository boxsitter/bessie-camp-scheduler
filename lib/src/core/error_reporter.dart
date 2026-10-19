import 'package:sentry_flutter/sentry_flutter.dart';

import '../shared/services/toast.dart';
import 'app_config.dart';
import 'errors.dart';
import 'logging.dart';

/// Where errors nobody caught end up: logged, shown to the user, and
/// (when configured) sent to Sentry.
class ErrorReporter {
  const ErrorReporter._();

  /// An error from an async gap or a platform callback.
  static void handleUncaught(Object error, StackTrace stackTrace) {
    if (error is AppException) {
      // Already phrased for people; the cause was logged where it was thrown.
      Toast.error(error.message);
      if (error.cause != null) log.w('Unhandled AppException', error: error.cause, stackTrace: error.stackTrace ?? stackTrace);
      return;
    }
    log.e('Uncaught error', error: error, stackTrace: stackTrace);
    Toast.error('Something went wrong. If this keeps happening, let your director know.');
    if (AppConfig.sentryEnabled) Sentry.captureException(error, stackTrace: stackTrace);
  }

  /// An error from the Flutter framework (build/layout/paint).
  static void handleFlutterError(FlutterErrorDetails details) {
    log.e('Flutter error', error: details.exception, stackTrace: details.stack);
    if (AppConfig.sentryEnabled) Sentry.captureException(details.exception, stackTrace: details.stack);
  }
}

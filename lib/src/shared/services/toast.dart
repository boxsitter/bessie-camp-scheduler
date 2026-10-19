import 'package:get/get.dart';

import '../../core/errors.dart';
import '../../core/logging.dart';
import 'popup_service.dart';

enum ToastType { info, success, warning, error }

/// Short messages shown to the user. Use this (not `log`) for anything a
/// person should see; use `log` for developer diagnostics.
class Toast {
  const Toast._();

  static void info(String message, {String? title}) => _show(ToastType.info, message, title: title);
  static void success(String message, {String? title}) => _show(ToastType.success, message, title: title ?? 'Success');
  static void warning(String message, {String? title}) => _show(ToastType.warning, message, title: title ?? 'Heads up');
  static void error(String message, {String? title}) => _show(ToastType.error, message, title: title ?? 'Something went wrong');

  /// Logs [error] and tells the user what went wrong in plain language.
  static void failure(Object error, [StackTrace? stackTrace]) {
    final exception = AppException.from(error, stackTrace);
    log.e('Operation failed', error: exception.cause ?? exception, stackTrace: stackTrace ?? exception.stackTrace);
    _show(ToastType.error, exception.message, title: 'Something went wrong');
  }

  static void _show(ToastType type, String message, {String? title}) {
    if (!Get.isRegistered<PopupService>() || Get.context == null) {
      log.i('${type.name}: ${title == null ? '' : '$title - '}$message');
      return;
    }
    Get.find<PopupService>().showToast(type: type, title: title, message: message);
  }
}

/// Runs [action], reporting any failure as a toast instead of throwing.
/// Returns null when it failed.
Future<T?> attempt<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (e, st) {
    Toast.failure(e, st);
    return null;
  }
}

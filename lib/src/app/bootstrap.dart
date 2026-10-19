import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

import '../core/app_config.dart';
import '../core/error_reporter.dart';
import '../core/logging.dart';
import '../services/auth_service.dart';
import 'bessie_app.dart';
import 'bindings.dart';

/// Starts the app, wrapping it in Sentry when a DSN was configured.
Future<void> bootstrap() async {
  if (AppConfig.sentryEnabled) {
    await SentryFlutter.init((options) {
      options.dsn = AppConfig.sentryDsn;
      options.environment = AppConfig.sentryEnvironment;
      options.release = AppConfig.releaseVersion;
      // This app handles children's names and birthdates: never attach
      // user details to error reports.
      options.sendDefaultPii = false;
      options.tracesSampleRate = 0.1;
    }, appRunner: _run);
  } else {
    await _run();
  }
}

Future<void> _run() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  FlutterError.onError = ErrorReporter.handleFlutterError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    ErrorReporter.handleUncaught(error, stackTrace);
    return true;
  };

  log.i('Connecting to ${AppConfig.supabaseUrl}');
  await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
  AppBindings.registerCore(Supabase.instance.client);
  await Get.find<AuthService>().init();

  await _initDesktopWindow();

  if (Get.find<AuthService>().isSignedIn) {
    try {
      await AppBindings.onSignedIn();
    } catch (e, st) {
      // The saved session is valid but the camp can't be loaded (no season
      // yet, offline, ...): fall back to the login screen rather than a blank app.
      log.e('Could not load the camp after restoring the session', error: e, stackTrace: st);
      await Get.find<AuthService>().signOut();
    }
  }

  FlutterNativeSplash.remove();
  runApp(const BessieFlutterApp());
}

Future<void> _initDesktopWindow() async {
  if (kIsWeb || !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(const WindowOptions(title: 'Bessie', minimumSize: Size(770, 500)));
  await windowManager.show();
  await windowManager.focus();
}

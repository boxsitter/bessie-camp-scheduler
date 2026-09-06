import 'dart:async';
import 'dart:io';

import 'package:bessie/src/ember_core.dart';
import 'package:bessie/src/bess_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:window_manager/window_manager.dart';

const recoveryMode = false;

/// Entry point of Flutter App
Future<void> main() async {
  Debug.init(kReleaseMode);
  Debug.handleInfo(Debug.getDebugStateInfo());

  if (!Debug.enableSentry) {
    await runZonedGuarded(() async {
      await initializeApp();
    }, (Object error, StackTrace stack) {
      if (error is! EmberException || !error.isHandled) {
        Debug.parseException(error, stack);
        Future<void>.microtask(() {
          Zone.current.parent?.handleUncaughtError(error, stack);
        });
      }
    });
  } else {
    await SentryFlutter.init(
      (options) {
        options.dsn = 'https://81a155539d2eb46d3a99b6fd0779bf30@o4508969385656320.ingest.us.sentry.io/4508969397190657';
        options.sendDefaultPii = true;
        options.tracesSampleRate = 1.0;
        options.release = String.fromEnvironment(
          'SENTRY_RELEASE_VERSION',
          defaultValue: 'bessie-web-LOCAL-DEV-FALLBACK', // Fallback for local development if not defined
        );
        options.environment = 'production';
      },
      appRunner: initializeApp,
    );
  }
}

Future<void> initializeApp() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception is! EmberException || !(details.exception as EmberException).isHandled) {
      Debug.parseException(details.exception, details.stack);
    }
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (error is! EmberException || !error.isHandled) {
      Debug.parseException(error, stack);
      return true;
    }
    return false;
  };

  try {
    await FireStarter.initialize();
  } catch (e) {
    throw Exception('Firebase not initialized!');
  }


  EmberCore.init(BessUi());

  // Initialize window manager if on desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      title: 'Bessie',
      minimumSize: Size(770, 500),

    );
    await windowManager.waitUntilReadyToShow(windowOptions);
    await windowManager.show();
    await windowManager.focus();
  }

  if (Get.find<UserService>().isAuthenticated) {
    await EmberCore.onLogin();
    FrontendManager.instance.onLogin();
  }

  FlutterNativeSplash.remove();
  BessUi.launchFlutterApp();
}

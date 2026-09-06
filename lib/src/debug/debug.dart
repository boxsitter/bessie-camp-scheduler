import 'dart:async';

import '../ember_core.dart';

class Debug {
  Debug._internal();
  static final Debug _singleton = Debug._internal();
  static Debug get instance => _singleton;

  int maxEntries = 400;
  final List<Logable> _events = <Logable>[];
  List<Logable> get events => List.unmodifiable(_events);
  final StreamController<Logable> _controller = StreamController<Logable>.broadcast();
  Stream<Logable> get onEvent => _controller.stream;

  // State
  late final String? _configCode;
  late final bool _enableSentry;
  late final bool _useFirestoreEmulator;
  late final Verbosity _maxVerbosityToPrint;
  late final bool _simplifyStackTraces;
  late final bool _colorfulLogs;

  static String? get configCode => instance._configCode;
  static bool get useFirestoreEmulator => instance._useFirestoreEmulator;
  static bool get enableSentry => instance._enableSentry;
  static Verbosity get maxVerbosityToPrint => instance._maxVerbosityToPrint;
  static bool get simplifyStackTraces => instance._simplifyStackTraces;
  static bool get colorfulLogs => instance._colorfulLogs;

  // helper method
  static List<dynamic>? parseDebugConfigCode(String code) {
    if (configPresets.containsKey(code)) {
      return configPresets[code];
    }
    if (code.length != 5) return null;
    if (int.tryParse(code) == null) return null;
    List<dynamic> output = [];
    output.add(int.parse(code[0]) == 1);
    output.add(int.parse(code[1]) == 1);
    switch (int.parse(code[2])) {
      case 0:
        output.add(Verbosity.none);
      case 1:
        output.add(Verbosity.essential);
        break;
      case 2:
        output.add(Verbosity.verbose);
        break;
      case 3:
        output.add(Verbosity.excessive);
        break;
      default:
        return null; // invalid value
    }
    output.add(int.parse(code[3]) == 1);
    output.add(int.parse(code[4]) == 1);
    return output;
  }

  static const Map<String, List<dynamic>> configPresets = {
    'debug': [false, false, Verbosity.excessive, true, false],
    'release': [true, false, Verbosity.none, false, false],
  };

  // ?DEBUG=#### in url
  // --dart-define=DEBUG=#####
  // enableSentry (0 or 1)
  // useFirestoreEmulator (0 or 1)
  // maxVerbosityToPrint (0: no console output, 1: essential, 2: verbose, 3: excessive)
  // simplifyStackTraces (0 or 1)
  // colorfulLogs (0 or 1)
  // Priority: urlArgs, commandArgs, defaults
  static void init(bool isReleaseMode) {
    final String? urlArgs = Uri.base.queryParameters['DEBUG'];
    const String? commandArgs = bool.hasEnvironment("DEBUG") ? String.fromEnvironment("DEBUG") : null;

    if (urlArgs != null) {
      final List<dynamic>? parsedDebugConfigCode = parseDebugConfigCode(urlArgs);
      if (parsedDebugConfigCode != null) {
        instance._configCode = urlArgs;
        instance._enableSentry = parsedDebugConfigCode[0];
        instance._useFirestoreEmulator = parsedDebugConfigCode[1];
        instance._maxVerbosityToPrint = parsedDebugConfigCode[2];
        instance._simplifyStackTraces = parsedDebugConfigCode[3];
        instance._colorfulLogs = parsedDebugConfigCode[4];
        return;
      }
    }

    if (commandArgs != null) {
      final List<dynamic>? parsedDebugConfigCode = parseDebugConfigCode(commandArgs);
      if (parsedDebugConfigCode != null) {
        instance._configCode = commandArgs;
        instance._enableSentry = parsedDebugConfigCode[0];
        instance._useFirestoreEmulator = parsedDebugConfigCode[1];
        instance._maxVerbosityToPrint = parsedDebugConfigCode[2];
        instance._simplifyStackTraces = parsedDebugConfigCode[3];
        instance._colorfulLogs = parsedDebugConfigCode[4];
        return;
      }
    }

    instance._configCode = null;
    instance._enableSentry = isReleaseMode;
    instance._maxVerbosityToPrint = isReleaseMode ? Verbosity.none : Verbosity.verbose;
    instance._useFirestoreEmulator = !isReleaseMode;
    instance._simplifyStackTraces = !isReleaseMode;
    instance._colorfulLogs = !isReleaseMode;
  }

  static EmberInfo getDebugStateInfo()  {
    Map<String, String>? meta = {};
    meta['Config Code'] = configCode != null ? configCode.toString() : 'not set';
    meta['Enable Sentry'] = enableSentry.toString();
    meta['Use Firestore Emulator'] = useFirestoreEmulator.toString();
    meta['Max Verbosity To Print'] = maxVerbosityToPrint.name;
    meta['Simplify Stack Traces'] = simplifyStackTraces.toString();
    meta['Colorful Logs'] = colorfulLogs.toString();

    return Info('Debug State', metadata: meta, verbosity: Verbosity.verbose);
  }

  static EmberException parseException(Object e, [StackTrace? stackTrace]) {
    return instance._parseException(e, stackTrace);
  }

  EmberException _parseException(Object e, [StackTrace? stackTrace]) {
    if (e is EmberException && e.isHandled) {
      return e;
    }

    final EmberException exception = e.toEmberException(stackTrace);
    _push(exception);
    if (_maxVerbosityToPrint != Verbosity.none) {
      _devPrint(exception, stackTrace);
    }
    if (exception.userMessage != null) {
      FrontendManager.instance.showToast(title: exception.logType.userString, message: exception.userMessage, logType: exception.logType);
    }

    exception.isHandled = true;
    return exception;
  }

  static void handleInfo(EmberInfo info) {
    instance._handleInfo(info);
  }

  void _handleInfo(EmberInfo info) {
    _push(info);

    if (info.verbosity.level <= _maxVerbosityToPrint.level &&
        _maxVerbosityToPrint != Verbosity.none &&
        info.verbosity != Verbosity.none) {
      _devPrint(info);
    }

    if (info.userMessage != null) {
      FrontendManager.instance.showToast(title: info.logType.userString, message: info.userMessage, logType: info.logType);
    }
  }

  static void logInfo(String devMessage, {Verbosity? verbosity, String? userMessage, Map<String, String>? metadata}) {
    handleInfo(Info(devMessage, verbosity: verbosity, userMessage: userMessage, metadata: metadata));
  }

  static void logSuccess(String devMessage, {Verbosity? verbosity, String? userMessage, Map<String, String>? metadata}) {
    handleInfo(Success(devMessage, verbosity: verbosity, userMessage: userMessage, metadata: metadata));
  }

  static void logWarning(String devMessage, {Verbosity? verbosity, String? userMessage, Map<String, String>? metadata}) {
    handleInfo(Warning(devMessage, verbosity: verbosity, userMessage: userMessage, metadata: metadata));
  }

  Future<T?> guard<T>(FutureOr<T> Function() action) async {
    try {
      return await Future.sync(action);
    } catch (e, st) {
      _parseException(e.toEmberException(st), st);
      return null;
    }
  }

  void _push(Logable entry) {
    if (_events.length >= maxEntries) _events.removeAt(0);
    _events.add(entry);
    _controller.add(entry);
  }

  void _devPrint(Logable entry, [StackTrace? stackTrace]) {
    print((entry.toStringFormatted(stackTrace)).trim());
  }

  void dispose() => _controller.close();
}

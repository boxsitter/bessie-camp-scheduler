import '../../ember_core.dart';

abstract class EmberInfo extends Logable{

  final String? userTitle;
  final String? userMessage;
  final Verbosity verbosity;

  EmberInfo({
    this.userTitle,
    this.userMessage,
    Verbosity? verbosity,
    required super.module,
    required super.devMessage,
    super.metadata,
    required super.logType,
  }) : verbosity = verbosity ?? Verbosity.verbose;

}

class Info extends EmberInfo {
  Info( String devMessage, {
    super.verbosity,
    super.userMessage,
    Map<String, String>? metadata,
  }) : super(
    devMessage: devMessage,
    module: Module.core,
    logType: LogType.info,
    metadata: metadata ?? {},
  );
}

class Success extends EmberInfo {
  Success( String devMessage, {
    super.verbosity,
    super.userMessage,
    Map<String, String>? metadata,
  }) : super(
    devMessage: devMessage,
    module: Module.core,
    logType: LogType.success,
    metadata: metadata ?? {},
  );
}

class Warning extends EmberInfo {
  Warning( String devMessage, {
    super.verbosity,
    super.userMessage,
    Map<String, String>? metadata,
  }) : super(
    devMessage: devMessage,
    module: Module.core,
    logType: LogType.warning,
    metadata: metadata ?? {},
  );
}

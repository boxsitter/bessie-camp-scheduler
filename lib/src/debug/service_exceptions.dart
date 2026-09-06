import '../ember_core.dart';

class CsvError extends EmberException {
  CsvError(String devMessage, String userMessage) : super(
    module: Module.core,
    logType: LogType.error,
    devMessage: devMessage,
    userMessage: userMessage,
  );
}
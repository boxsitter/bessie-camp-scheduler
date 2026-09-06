

import '../ember_core.dart';

class ExceptionTest extends EmberException {
  ExceptionTest() : super(
    module: Module.core,
    devMessage: 'Minor failure exception',
    logType: LogType.error,
    userMessage: 'Operation failed',
    metadata: {
      'string1': 'hello world',
      'string2': 'hello world',
      'string3': 'hello world',
      'string4': 'hello world',
      'string5': 'hello world',
      'string6': 'hello world',
      'string7': 'hello world',
    }
  );
}

class CoreUninitializedError extends EmberException {
  CoreUninitializedError(String devMessage) : super(
      module: Module.core,
    logType: LogType.error,
      devMessage: devMessage,

  );
}

class CoreUnsupportedError extends EmberException {
  CoreUnsupportedError(String devMessage) : super(
    module: Module.core,
    logType: LogType.error,
    devMessage: devMessage,
  );
}

class CoreMembershipClassError extends EmberException {
  CoreMembershipClassError(String devMessage, Type attemptedType, Type expectedType) : super(
    module: Module.core,
    logType: LogType.error,
    devMessage: devMessage,
    metadata: {
      'Attempted type: ' : attemptedType.toString(),
      'Expected type ' : expectedType.toString(),
    }
  );
}

class CoreInvalidCollectionError extends EmberException {
  CoreInvalidCollectionError(String devMessage) : super(
    module: Module.core,
    logType: LogType.error,
    devMessage: devMessage,
  );
}

class CamperRegistrationError extends EmberException {
  CamperRegistrationError(String devMessage, String userMessage) : super(
    module: Module.core,
    logType: LogType.error,
    devMessage: devMessage,
    userMessage: userMessage,
  );
}
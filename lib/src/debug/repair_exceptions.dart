
import '../ember_core.dart';

abstract class RepairException extends EmberException {
  RepairException({
    required super.devMessage,
    String? userMessage,
    super.metadata,
    super.logType = LogType.warning, // Default to warning, can be overridden
  }) : super(
    module: Module.fire, // Assuming Module.fire can be added to your enum
    userMessage: userMessage ?? 'A database integrity issue was detected.',
  );
}

// Specific Repair Exception Classes

class RepairArgumentError extends RepairException {
  RepairArgumentError({required String reason})
      : super(
    devMessage: 'Repair Check Argument Error: $reason',
    userMessage: 'Invalid arguments provided for document integrity check.',
    metadata: {'reason': reason},
    logType: LogType.error,
  );
}

class RepairDocNotFoundError extends RepairException {
  RepairDocNotFoundError({String? path, String? id, String? keyInfo})
      : super(
    devMessage:
    'Document not found. Path: $path, ID: $id, KeyInfo: $keyInfo',
    userMessage: 'The document required for the integrity check could not be found.',
    metadata: {
      if (path != null) 'path': path,
      if (id != null) 'id': id,
      if (keyInfo != null) 'key_info': keyInfo,
    },
    logType: LogType.error,
  );
}

class RepairDocDataEmptyError extends RepairException {
  RepairDocDataEmptyError({String? keyInfo, String? path, String? id})
      : super(
    devMessage: 'Document data is empty or null. KeyInfo: $keyInfo, Path: $path, ID: $id',
    userMessage: 'The document exists but contains no data or its data is null.',
    metadata: {
      if (keyInfo != null) 'key_info': keyInfo,
      if (path != null) 'path': path,
      if (id != null) 'id': id,
    },
    logType: LogType.error,
  );
}

class RepairIdIssue extends RepairException {
  RepairIdIssue({
    required String reason,
    String? internalId,
    String? documentKey,
  }) : super(
    devMessage:
    'ID Issue: $reason. InternalID: $internalId, DocumentKey: $documentKey',
    userMessage: 'The document has an issue with its identifier.',
  );
}

class RepairFieldIssue extends RepairException {
  RepairFieldIssue({
    required String reason,
    String? documentKey,
    Set<String>? docKeys,
    Set<String>? templateKeys,
    Set<String>? missingInDoc,
    Set<String>? extraInDoc,
  }) : super(
    devMessage:
    'Field Issue: $reason. DocKey: $documentKey. DocKeys: $docKeys, TemplateKeys: $templateKeys, Missing: $missingInDoc, Extra: $extraInDoc',
    userMessage: 'The document\'s structure or fields do not match the expected template.',
    metadata: {
      'reason': reason,
      if (documentKey != null) 'document_key': documentKey,
      if (docKeys != null) 'doc_keys': docKeys.join(', '),
      if (templateKeys != null) 'template_keys': templateKeys.join(', '),
      if (missingInDoc != null && missingInDoc.isNotEmpty)
        'missing_in_doc': missingInDoc.join(', '),
      if (extraInDoc != null && extraInDoc.isNotEmpty)
        'extra_in_doc': extraInDoc.join(', '),
    },
  );
}

class RepairSerializationIssue extends RepairException {
  RepairSerializationIssue({
    required String stage, // e.g., "deserialization", "serialization"
    String? errorMessage,
    String? documentKey,
  }) : super(
    devMessage:
    '$stage failure: $errorMessage. DocumentKey: $documentKey',
    userMessage: 'The document data could not be correctly processed (serialized/deserialized).',
    metadata: {
      'stage': stage,
      if (errorMessage != null) 'error_message': errorMessage,
      if (documentKey != null) 'document_key': documentKey,
    },
  );
}

class RepairTypeIssue extends RepairException {
  RepairTypeIssue({
    String? expectedType,
    String? actualType,
    String? documentKey,
  }) : super(
    devMessage:
    'Type Issue. Expected: $expectedType, Actual: $actualType. DocumentKey: $documentKey',
    userMessage: 'The document\'s type does not match the expected type.',
    metadata: {
      if (expectedType != null) 'expected_type': expectedType,
      if (actualType != null) 'actual_type': actualType,
      if (documentKey != null) 'document_key': documentKey,
    },
  );
}

class RepairUnexpectedError extends RepairException {
  RepairUnexpectedError({
    String? errorMessage,
    String? stackTraceString,
    String? keyInfo,
  }) : super(
    devMessage:
    'Unexpected error during repair check for $keyInfo: $errorMessage',
    userMessage:
    'An unexpected error occurred while checking document integrity.',
    metadata: {
      if (errorMessage != null) 'error_message': errorMessage,
      if (stackTraceString != null) 'stack_trace': stackTraceString,
      if (keyInfo != null) 'key_info': keyInfo,
    },
    logType: LogType.critical,
  );
}
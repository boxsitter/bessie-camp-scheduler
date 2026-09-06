

import '../../ember_core.dart';

abstract class Logable {
  final DateTime timestamp;
  final Module module;
  final String devMessage;
  final Map<String, String> metadata;
  final LogType logType;

  Logable({
    required this.module,
    required this.devMessage,
    this.metadata = const{},
    required this.logType,
  }) : timestamp = DateTime.now();

  String toStringFormatted(StackTrace? stackTrace) {
    String output = '';

    // [Module Name]
    final String moduleName = '[${module.name}]';
    if (Debug.colorfulLogs) {
      output += CoreFormatter.formatAnsi(
        text: moduleName,
        color: logType == LogType.info || logType == LogType.success ? AnsiColor.cyan : AnsiColor.red,
      );
    } else {
      output += moduleName;
    }

    // [Module Name] Main Content
    final String mainContent = logType != LogType.info ? ' ${logType.devString}: $devMessage' : ' $devMessage';
    if (Debug.colorfulLogs) {
      output += CoreFormatter.formatAnsi(
        text: mainContent,
        color: logType.ansiColor,
      );
    } else {
      output += mainContent;
    }

    // [Module Name] Main Content
    // - Meta

    if (metadata.isNotEmpty) {
      String meta = '';
      meta += '\n';
      for (var entry in metadata.entries) {
        meta += '- ${entry.key}: ${entry.value}\n';
      }

      if (Debug.colorfulLogs) {
        output += CoreFormatter.formatAnsi(
          text: meta,
          color: logType.ansiColor,
        );
      } else {
        output += meta;
      }
    }

    // [Module Name] Main Content
    // - Meta
    // Stack Trace
    if (stackTrace != null) {
      String formattedStackTrace;
      if (Debug.simplifyStackTraces) {
        formattedStackTrace = CoreFormatter.simplifyStackTrace(stackTrace);
      } else {
        formattedStackTrace = stackTrace.toString();
      }

      if (Debug.colorfulLogs) {
        output += CoreFormatter.formatAnsi(
          text: formattedStackTrace,
          color: logType.ansiColor,
        );
      } else {
        output += formattedStackTrace;
      }
    }

    return  output;
  }

  @override
  String toString() {
    return toStringFormatted(null);
  }
}
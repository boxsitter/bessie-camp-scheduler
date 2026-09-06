
import '../ember_core.dart';

/// Defines ANSI escape codes for text styles.
enum AnsiStyle {
  bold('\x1B[1m'),
  italic('\x1B[3m'),
  underline('\x1B[4m'),
  strikethrough('\x1B[9m'),
  reset('\x1B[0m'); // Reset code

  final String code;
  const AnsiStyle(this.code);
}

class CoreFormatter {
  /// Formats a string with specified ANSI color and style.
  ///
  /// [text]: The string to format.
  /// [color]: The desired text color (optional).
  /// [style]: The desired text style (optional).
  ///
  /// Returns the formatted string with ANSI escape codes.
  static String formatAnsi({required String text, AnsiColor? color, AnsiStyle? style}) {
    final buffer = StringBuffer();

    final hasFormatting = (color != null && color != AnsiColor.reset) || (style != null && style != AnsiStyle.reset);

    if (style != null && style != AnsiStyle.reset) {
      buffer.write(style.code);
    }
    if (color != null && color != AnsiColor.reset) {
      buffer.write(color.code);
    }

    if (hasFormatting) {
      if (text.endsWith('\n')) {
        // Insert reset *before* the newline
        final withoutNewline = text.substring(0, text.length - 1);
        buffer.write(withoutNewline);
        buffer.write('\x1B[0m\n');
      } else {
        buffer.write(text);
        buffer.write('\x1B[0m');
      }
    } else {
      // No formatting applied, just write the text directly
      buffer.write(text);
    }

    return buffer.toString();
  }

  static Module extractModuleFromStackTrace(StackTrace stackTrace) {
    final traceString = stackTrace.toString();
    final linesBackwards = traceString.split('\n');
    final lines = linesBackwards.reversed.toList();

    String moduleDirName = '';
    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.startsWith('packages/')) {
        final afterPackages = trimmed.substring('packages/'.length);
        final parts = afterPackages.split('/');

        if (parts.isNotEmpty) {
          moduleDirName = parts.first;
        }
      }
    }

    switch (moduleDirName) {
      case 'bessie_app':
        return Module.bessie;
      case 'ember_core':
        return Module.core;
      case 'ember_fire':
        return Module.fire;
      default:
        return Module.unknown;
    }
  }

  /// Masks an email address for logging or display purposes, showing only the
  /// first character of the local part and the full domain.
  ///
  /// Examples:
  /// - 'john.doe@example.com' -> 'j*******@example.com'
  /// - 'a@domain.net' -> '*@domain.net'
  /// - 'invalid-email' -> '***'
  /// - null -> '***'
  static String maskEmail(String? email) {
    const String defaultMask = '***';

    if (email == null || email.isEmpty || !email.contains('@')) {
      return defaultMask;
    }

    final parts = email.split('@');
    // Ensure there's exactly one '@' symbol
    if (parts.length != 2) {
      return defaultMask;
    }

    final String localPart = parts[0];
    final String domain = parts[1];

    if (localPart.isEmpty) {
      // Handle emails starting with '@' (though unusual)
      return '$defaultMask@$domain';
    }

    if (localPart.length <= 3) {
      final String maskedLocalPart = ('*' * (localPart.length));
      return '$maskedLocalPart@$domain';
    }

    // Keep the first 3 characters, replace the rest with '*'
    final String maskedLocalPart = localPart[0] + localPart[1] + localPart[2] +('*' * (localPart.length - 3));

    return '$maskedLocalPart@$domain';
  }

  static String simplifyStackTrace(StackTrace? stackTrace) {
    List<String> userPackagePrefixes = const [
      'package:bessie/',
    ];

    const String placeholder = '[No stack trace available]';
    if (stackTrace == null) {
      return placeholder;
    }

    final String fullTrace = stackTrace.toString();
    if (fullTrace.trim().isEmpty) {
      return placeholder;
    }

    final List<String> lines = fullTrace.split('\n');
    final List<String> formattedLines = [];
    int externalLinesCount = 0;

    bool isUserCodeLine(String line) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) return false;

      // Check 1: Standard format with parentheses
      final contentStartIndex = trimmedLine.indexOf('(');
      if (contentStartIndex != -1) {
        final relevantPart = trimmedLine.substring(contentStartIndex);
        for (final prefix in userPackagePrefixes) {
          if (relevantPart.contains(prefix)) {
            // print("DEBUG: Matched (parentheses) line: '$trimmedLine' with prefix '$prefix'");
            return true;
          }
        }
      }

      // Check 2: Line starts with a package indication (for lines without parentheses)
      for (final prefix in userPackagePrefixes) {
        // If userPackagePrefixes = ['package'], this will catch lines starting with "package:" or "packages/"
        if (prefix == 'package' && (trimmedLine.startsWith('package:') || trimmedLine.startsWith('packages/'))) {
          // print("DEBUG: Matched (direct start - general 'package') line: '$trimmedLine'");
          return true;
        }
        // If userPackagePrefixes is specific, e.g., ['package:bessie/', 'package:ember_core/']
        else if (trimmedLine.startsWith(prefix)) {
          // print("DEBUG: Matched (direct start - specific prefix) line: '$trimmedLine' with prefix '$prefix'");
          return true;
        }
      }

      // print("DEBUG: No match for line: '$trimmedLine'");
      return false;
    }

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      if (isUserCodeLine(trimmedLine)) {
        if (externalLinesCount > 0) {
          formattedLines.add('[... $externalLinesCount external lines collapsed ...]');
          externalLinesCount = 0;
        }
        formattedLines.add(trimmedLine);
      } else {
        externalLinesCount++;
      }
    }

    if (externalLinesCount > 0) {
      formattedLines.add('[... $externalLinesCount external lines collapsed ...]');
    }

    return '\n${formattedLines.join('\n')}';
  }
}

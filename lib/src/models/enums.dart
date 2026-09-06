
import 'interfaces/titled.dart';

enum AnsiColor {
  // Standard colors
  black('\x1B[30m'),
  red('\x1B[31m'),
  green('\x1B[32m'),
  yellow('\x1B[33m'),
  blue('\x1B[34m'),
  magenta('\x1B[35m'),
  cyan('\x1B[36m'),
  white('\x1B[37m'),

  // Bright colors (often includes gray for bright black)
  gray('\x1B[90m'), // Often displayed as Gray
  brightRed('\x1B[91m'),
  brightGreen('\x1B[92m'),
  brightYellow('\x1B[93m'),
  brightBlue('\x1B[94m'),
  brightMagenta('\x1B[95m'),
  brightCyan('\x1B[96m'),
  brightWhite('\x1B[97m'),

  reset('\x1B[0m'), // Reset code
  none('');

  final String code;
  const AnsiColor(this.code);
}

enum LogType {
  failure('Failure', 'Oops', AnsiColor.yellow, Duration(milliseconds: 3500)),

  unknownError('Undefined Error', 'Something went wrong', AnsiColor.brightRed, Duration(milliseconds: 4000)),

  error('Error', 'Error', AnsiColor.brightRed, Duration(milliseconds: 4000)),

  critical('Critical Error', 'Critical error', AnsiColor.red, Duration(milliseconds: 5000)),

  info('Info', 'Info', AnsiColor.none, Duration(milliseconds: 2000)),

  success('Success', 'Success!', AnsiColor.brightGreen, Duration(milliseconds: 2000)),

  warning('Warning', 'Warning', AnsiColor.brightYellow, Duration(milliseconds: 3000));

  final String devString;
  final String userString;
  final AnsiColor ansiColor;
  final Duration toastDuration;
  const LogType(this.devString, this.userString, this.ansiColor, this.toastDuration);
}

enum Module {
  bessie('BESSIE'),
  core('CORE'),
  fire('FIRE'),
  quickLog('LOG'),
  unknown('UNKNOWN');

  final String name;
  const Module(this.name);
}

enum Role { root, director, admin, counselor, nullRole }

enum Verbosity {
  none(0, 'None'),
  essential(1, 'Essential'),
  verbose(2, 'Verbose'),
  excessive(3, 'Excessive');

  final int level;
  final String name;
  const Verbosity(this.level, this.name);
}

enum SortDirection { asc, desc }

enum ActivityCategory implements Titled{
  creative('Creative'),
  sportsAndAthletics('Sports & Athletics'),
  waterfront('Waterfront'),
  campClassics('Camp Classics'),
  silly('Silly & Unconventional'),
  skills('Skills Recs'),
  hidden('Hidden');

  @override
  final String title;
  const ActivityCategory(this.title);

  @override
  String get displayTitle => title;
}

/// ANSI styling for text written to the console's terminal.
///
/// Plain escape codes rather than a color package: the terminal widget always
/// understands them, whatever the host platform's own console supports.
class ConsoleStyle {
  const ConsoleStyle._();

  static String _wrap(String code, String text) => '\x1B[${code}m$text\x1B[0m';

  static String error(String text) => _wrap('1;31', text);
  static String warning(String text) => _wrap('33', text);
  static String success(String text) => _wrap('32', text);
  static String info(String text) => _wrap('94', text);
  static String emphasis(String text) => _wrap('1;36', text);
  static String dim(String text) => _wrap('90', text);
}

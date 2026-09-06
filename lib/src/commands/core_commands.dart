import 'package:bessie/src/cli/cli.dart';
import 'package:bessie/src/commands/dev_commands.dart';
import 'package:bessie/src/commands/user_commands.dart';

import 'setup_commands.dart';

class CoreCommands{
  static Map<String, EmberCommand> list = {...SetupCommands.list, ...UserCommands.list, ... DevCommands.list};
}
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// The app-wide developer log. User-facing messages go through `Toast`
/// (see shared/services/toast.dart), not through here.
final Logger log = Logger(
  level: kReleaseMode ? Level.warning : Level.debug,
  printer: PrettyPrinter(methodCount: 0, errorMethodCount: 8, lineLength: 100, colors: !kIsWeb, printEmojis: false),
);

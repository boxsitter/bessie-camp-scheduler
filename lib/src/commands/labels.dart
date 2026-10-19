import '../models/schedule.dart';

/// `10:15` for a time given as a duration since midnight.
String clockLabel(Duration time) => '${time.inHours.toString().padLeft(2, '0')}:${(time.inMinutes % 60).toString().padLeft(2, '0')}';

/// `Monday - Choice Activity 1 (10:15-11:15)`.
String blockLabel(Block block) => '${block.displayTitle} (${clockLabel(block.startTime)}-${clockLabel(block.endTime)})';

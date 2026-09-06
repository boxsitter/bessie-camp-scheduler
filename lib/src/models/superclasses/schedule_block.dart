import '../../ember_core.dart';
import '../interfaces/time_interval.dart';

typedef BlockId = String;

abstract class ScheduleBlock extends CoreObject implements TimeInterval{
  ScheduleBlock({required super.domain, required super.type, required super.idTag});

  String get title;
  bool get isTemplate;
}
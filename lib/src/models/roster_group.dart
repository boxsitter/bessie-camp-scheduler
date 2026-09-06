import 'package:bessie/src/ember_core.dart';

class RosterGroup {
  final String title;
  final RosterField? groupByField;
  List<Rosterable> items;
  bool isSelected;

  RosterGroup({
    required this.title,
    this.groupByField,
    required this.items,
    this.isSelected = false,
  });
}
import 'package:get/get.dart';

import '../../shared/constants/sizes.dart';

class SchedulePageController extends GetxController{
  static const int scale = 200;
  static const double outputAspectHorizontal = 11.0;
  static const double outputAspectVertical = 8.5;
  static const double outputAspectRatio = outputAspectHorizontal / outputAspectVertical;
  static const double columnSpacing = BessSizes.sm;
  static const int maxColumns = 5;
  static const double columnWidth = ((outputAspectHorizontal * scale) - columnSpacing * (maxColumns - 1)) / maxColumns;
  static const double totalWidth = outputAspectHorizontal * scale;
  static const double totalHeight = outputAspectVertical * scale;
  static const double miniHeight = totalHeight / 5;


}

import 'package:bessie/src/shared/widgets/containers/rounded_container.dart';
import 'package:bessie/src/features/schedule/schedule_page_controller.dart';
import 'package:flutter/material.dart';

import '../../shared/constants/colors.dart';
import '../../shared/constants/sizes.dart';
import '../../shared/widgets/header/menu_bar.dart';
import '../../shared/widgets/layouts/templates/site_layout.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BessSiteTemplate(desktop: SchedulePageDesktop(), desktopPadding: false, menuBar: BessMenuBar(),);
  }
}

class SchedulePageDesktop extends StatelessWidget {
  SchedulePageDesktop({super.key});

  final List<String> columns = ["Name", "Preferred Name", "Gender", "Age", "Cabin"];

  @override
  Widget build(BuildContext context) {
    List<Widget> rowChildren = [];
    rowChildren.add(
      SizedBox(
        width: SchedulePageController.columnWidth,
        height: SchedulePageController.totalHeight,
        child: Column(
          children: [
            BessRoundedContainer(
              width: SchedulePageController.columnWidth,
              height: SchedulePageController.miniHeight,
              showShadow: false,
              showBorder: true,
              radius: BessSizes.cardRadiusSm,
              borderThickness: BessSizes.borderThicknessMd,
              backgroundColor: BessColors.core,
              padding: EdgeInsets.zero,
              clipContent: true,
            ),

            SizedBox(
              height: SchedulePageController.columnSpacing,
            ),

            Expanded(
              child: BessRoundedContainer(
                width: SchedulePageController.columnWidth,
                showShadow: false,
                showBorder: true,
                radius: BessSizes.cardRadiusSm,
                borderThickness: BessSizes.borderThicknessMd,
                backgroundColor: BessColors.core,
                padding: EdgeInsets.zero,
                clipContent: true,
              ),
            ),
          ]
        ),
      )
    );

    rowChildren.add(SizedBox(width: SchedulePageController.columnSpacing));


    for (int i = 0; i < 3; i++) {
      rowChildren.add(
        BessRoundedContainer(
          width: SchedulePageController.columnWidth,
          height: SchedulePageController.totalHeight,
          showShadow: false,
          showBorder: true,
          radius: BessSizes.cardRadiusSm,
          borderThickness: BessSizes.borderThicknessMd,
          backgroundColor: BessColors.core,
          padding: EdgeInsets.zero,
          clipContent: true,
        ),
      );

      if (i < 3) {
        rowChildren.add(SizedBox(width: SchedulePageController.columnSpacing));
      }
    }

    rowChildren.add(
      SizedBox(
        width: SchedulePageController.columnWidth,
        height: SchedulePageController.totalHeight,
        child: Column(
            children: [

              Expanded(
                child: BessRoundedContainer(
                  width: SchedulePageController.columnWidth,
                  showShadow: false,
                  showBorder: true,
                  radius: BessSizes.cardRadiusSm,
                  borderThickness: BessSizes.borderThicknessMd,
                  backgroundColor: BessColors.core,
                  padding: EdgeInsets.zero,
                  clipContent: true,
                ),
              ),

              SizedBox(
                height: SchedulePageController.columnSpacing,
              ),

              BessRoundedContainer(
                width: SchedulePageController.columnWidth,
                height: SchedulePageController.miniHeight,
                showShadow: false,
                showBorder: true,
                radius: BessSizes.cardRadiusSm,
                borderThickness: BessSizes.borderThicknessMd,
                backgroundColor: BessColors.core,
                padding: EdgeInsets.zero,
                clipContent: true,
              ),
            ]
        ),
      )
    );

    return InteractiveViewer(
      constrained: false,
      scaleEnabled: true,
      panEnabled: true,
      boundaryMargin: const EdgeInsets.all(300),
      scaleFactor: 800,
      minScale: 0.50,
      maxScale: 2,
      alignment: Alignment.topLeft,
      child: Padding(
        padding: EdgeInsets.all(BessSizes.lg),
        child: Row(
          children: rowChildren,
        ),
      ),
    );
  }
}
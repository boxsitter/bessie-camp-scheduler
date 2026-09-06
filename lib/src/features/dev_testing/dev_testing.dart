import 'package:bessie/src/shared/styles/text_styles.dart';
import 'package:bessie/src/shared/widgets/buttons/card_button.dart';
import 'package:bessie/src/shared/widgets/wrappers/local_pointer_data.dart';
import 'package:flutter/material.dart';

import '../../shared/constants/colors.dart';
import '../../shared/constants/sizes.dart';
import '../../shared/widgets/header/menu_bar.dart';
import '../../shared/widgets/layouts/templates/site_layout.dart';

class DevTesting extends StatelessWidget {
  const DevTesting({super.key = const ValueKey('DevTesting')});

  @override
  Widget build(BuildContext context) {
    return const BessSiteTemplate(
      desktop: DevTestingDesktop(),
      menuBar: BessMenuBar(),
    );
  }
}

class DevTestingDesktop extends StatelessWidget {
  const DevTestingDesktop({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardButton(
              child: Center(child: Text('BIG BUTTON')),
              width: 600,
              height: 400,
              baseTint: BessColors.green,
              onPressed: () => {},
            ),
            SizedBox(
              width: BessSizes.spaceBtwItems,
            ),
            CardButton(
              child: Center(child: Text('Small Button')),
              width: 150,
              height: 60,
              baseTint: BessColors.green,
              onPressed: () => {},
            ),
            SizedBox(
              width: BessSizes.spaceBtwItems,
            ),
            CardButton(
              child: Center(child: Text('Wide Button')),
              width: 300,
              height: 70,
              baseTint: BessColors.green,
              onPressed: () => {},
            ),
            SizedBox(
              width: BessSizes.spaceBtwItems,
            ),
            CardButton(
              child: Center(
                  child: Text(
                'Tiny Button',
                style: BessTextStyles.standard.copyWith(fontSize: 8),
              )),
              width: 150,
              height: 30,
              baseTint: BessColors.green,
              onPressed: () => {},
              padding: EdgeInsets.all(0),
            ),
          ],
        ),
        SizedBox(height: 32),
        SizedBox(
          height: 200,
          width: 500,
          child: LocalPointerData(
            builder: (context, isHovering, isDown, localPosition, lastKnownClickState, lastKnownPosition) {
              // Correctly format the localPosition.
              final positionText = localPosition == null
                  ? 'null'
                  : 'dx: ${localPosition.dx.toStringAsFixed(2)}, dy: ${localPosition.dy.toStringAsFixed(2)}';

              final lastKnownPositionText = lastKnownPosition == null
                  ? 'null'
                  : 'dx: ${lastKnownPosition.dx.toStringAsFixed(2)}, dy: ${lastKnownPosition.dy.toStringAsFixed(2)}';

              return Container(
                color: isHovering ? Colors.blue.shade100 : Colors.grey.shade300,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Hovering: $isHovering'),
                    Text('Mouse Down: $isDown'),
                    Text('Local Position: $positionText'),
                    Text('Last Known Click State: $lastKnownClickState'),
                    Text('Last Known lastKnownPosition: $lastKnownPositionText'),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

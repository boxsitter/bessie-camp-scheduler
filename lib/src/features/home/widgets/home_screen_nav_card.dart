import 'package:bessie/src/shared/constants/sizes.dart';
import 'package:bessie/src/shared/widgets/containers/rounded_container.dart';
import 'package:flutter/material.dart';

import '../../../shared/styles/text_styles.dart';

class HomeScreenNavCard extends StatelessWidget {
  const HomeScreenNavCard({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
  });

  final String title;
  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context) {
    return BessRoundedContainer(
      height: 200,
      showBorder: true,
      borderThickness: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                size: BessSizes.iconMd,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    title,
                    style: BessTextStyles.lightHeader,
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
      
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

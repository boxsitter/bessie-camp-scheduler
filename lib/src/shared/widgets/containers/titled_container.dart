import 'package:bessie/src/shared/widgets/containers/rounded_container.dart';
import 'package:flutter/material.dart';
import '../../styles/text_styles.dart';

class TitledContainer extends StatelessWidget {
  const TitledContainer({
    super.key,
    required this.title,
    this.width,
    this.height,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(8),
    this.baseTint,
  });

  final String title;
  final double? width;
  final double? height;
  final Widget child;
  final Widget? trailing;
  final EdgeInsets? padding;
  final Color? baseTint;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            child: Row(
              children: [
                Expanded(child: Text(title, style: BessTextStyles.tableHeaderSecondary, overflow: TextOverflow.ellipsis, maxLines: 1,)),
                if (trailing != null)
                  trailing!,
              ],
            ),
            height: 40,
          ),
          Expanded(
            child: BessRoundedContainer(
              width: width,
              height: height,
              padding: padding,
              clipContent: true,
              showBorder: true,
              child: child,
              tintConditions: [(baseTint != null, baseTint)],
            ),
          ),
        ],
      ),
    );
  }
}

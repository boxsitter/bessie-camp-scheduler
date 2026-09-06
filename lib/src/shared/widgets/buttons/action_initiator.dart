import 'package:bessie/src/shared/constants/colors.dart';
import 'package:bessie/src/shared/widgets/buttons/card_button.dart';
import 'package:bessie/src/shared/widgets/shimmers/shimmer.dart';
import 'package:flutter/material.dart';

import '../../styles/text_styles.dart';
import '../wrappers/tint.dart';

class ActionInitiator extends StatelessWidget {
  const ActionInitiator(
      {super.key,
      required this.onPressed,
      this.awaiting = false,
      this.enabledText = '',
      this.awaitingText,
      this.width,
      this.disabled,
      this.disabledText,
      this.height});

  final void Function()? onPressed;
  final bool? awaiting;
  final bool? disabled;
  final String enabledText;
  final String? awaitingText;
  final String? disabledText;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (awaiting != true && disabled != true) {
      return CardButton(
        onPressed: onPressed,
        backgroundColor: BessColors.primary,
        child: Center(child: Text(enabledText, style: BessTextStyles.standardInverted)),
        width: width,
        height: height,
      );
    } else if (awaiting == true) {
      return Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned.fill(
            child: BessShimmerWrapper(
              period: Duration(milliseconds: 800),
              child: CardButton(
                child: Center(
                  child: Builder(
                    builder: (BuildContext context) {
                      return Text(
                        awaitingText ?? 'One moment...',
                        style: BessTextStyles.standard.copyWith(
                          color: Tint.of(context)?.foregroundColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      );
                    },
                  ),
                ),
                width: width,
                height: height,
              ),
            ),
          ),
          SizedBox(
            height: height,
            width: width ?? double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  awaitingText ?? enabledText,
                  style: BessTextStyles.standardInverted.copyWith(
                    color: BessColors.textInverted.withAlpha(150),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return CardButton(
        backgroundColor: BessColors.core,
        child: Center(
          child: Builder(
            builder: (BuildContext context) {
              return Text(
                disabledText ?? enabledText,
                style: BessTextStyles.standard.copyWith(
                  color: Tint.of(context)?.foregroundColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.clip,
              );
            },
          ),
        ),
        width: width,
        height: height,
      );
    }
  }
}

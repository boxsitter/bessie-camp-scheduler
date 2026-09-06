import 'package:bessie/src/shared/styles/text_styles.dart';
import 'package:flutter/material.dart';


class UnknownRoute extends StatelessWidget {
  const UnknownRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Woah there partner, the page you tried to access doesn\'t exist!', style: BessTextStyles.lightHeader, textAlign: TextAlign.center,)),
    );
  }
}
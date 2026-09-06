import 'package:flutter/animation.dart';

class BessAnimationCurves {
  // Padding and margin sizes
  static const Cubic linear = Cubic(0.0, 0.0, 1.0, 1.0);
  static const Cubic ease = Cubic(0.25, 0.1, 0.25, 1.0);
  static const Cubic easeIn = Cubic(0.5, 0.0, 1.0, 1.0);
  static const Cubic easeOut = Cubic(0.2, 0.8, 0.4, 1.0);
  static const Cubic easeInOut = Cubic(0.42, 0.0, 0.58, 1.0);
  static const Cubic fastOutSlowIn = Cubic(0.4, 0.0, 0.2, 1.0);
}
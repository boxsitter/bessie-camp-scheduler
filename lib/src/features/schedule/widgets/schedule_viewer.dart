import 'package:flutter/material.dart';

import '../../../shared/constants/sizes.dart';
import '../schedule_grid.dart';
import 'schedule_paper.dart';

/// Shows the [SchedulePaper] in a pan-and-zoom viewport, fitted to the window
/// width to start with. Double-tap to fit it again.
class ScheduleViewer extends StatefulWidget {
  const ScheduleViewer({super.key, required this.grid, this.title});

  final ScheduleGrid grid;
  final String? title;

  @override
  State<ScheduleViewer> createState() => _ScheduleViewerState();
}

class _ScheduleViewerState extends State<ScheduleViewer> {
  static const _margin = BessSizes.lg;

  TransformationController? _transform;
  double _fitScale = 1;

  double _fitFor(double viewportWidth) {
    final scale = viewportWidth / (SchedulePaperLayout.width + 2 * _margin);
    return scale.clamp(0.1, 1.0);
  }

  void _fit() {
    _transform?.value = Matrix4.diagonal3Values(_fitScale, _fitScale, 1);
  }

  @override
  void dispose() {
    _transform?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _fitScale = _fitFor(constraints.maxWidth);
        _transform ??= TransformationController(Matrix4.diagonal3Values(_fitScale, _fitScale, 1));

        return GestureDetector(
          onDoubleTap: _fit,
          child: InteractiveViewer(
            transformationController: _transform,
            constrained: false,
            alignment: Alignment.topLeft,
            boundaryMargin: const EdgeInsets.all(300),
            scaleFactor: 800,
            minScale: 0.1,
            maxScale: 2,
            child: Padding(
              padding: const EdgeInsets.all(_margin),
              child: SchedulePaper(grid: widget.grid, title: widget.title),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A widget that provides detailed pointer (mouse) state information to its child.
///
/// This widget tracks hover status, button-down state, and the pointer's local
/// position. It has special handling for situations where the pointer is dragged
/// outside the widget's bounds and then released, which is useful for complex
/// interactions like drag-and-drop.
class LocalPointerData extends StatefulWidget {
  const LocalPointerData({
    super.key,
    required this.builder,
  });

  /// A builder function that provides the gesture state to the child widget.
  ///
  /// - `isHovering`: True if the pointer is inside the widget's bounds.
  /// - `isDown`: True if the primary mouse button is pressed.
  /// - `localPosition`: The pointer's position within the widget.
  /// - `lastKnownClickState`: The value of `isDown` just before the pointer left the widget.
  /// - `lastKnownPosition`: The value of `localPosition` just before the pointer left the widget.
  final Widget Function(
      BuildContext context,
      bool isHovering,
      bool? isDown,
      Offset? localPosition,
      bool? lastKnownClickState,
      Offset? lastKnownPosition,
      ) builder;

  @override
  State<LocalPointerData> createState() => _LocalPointerDataState();
}

class _LocalPointerDataState extends State<LocalPointerData> {
  // Current state
  bool _isHovering = false;
  bool? _isDown;
  Offset? _localPosition;

  // Last known state (for when the mouse leaves)
  bool? _lastKnownClickState;
  Offset? _lastKnownPosition;

  /// Tracks whether a global pointer route is active.
  ///
  /// This is used to continue receiving pointer events even when the pointer
  /// has left the widget's bounds, but only if a drag was initiated inside it.
  bool _isDragEntered = false;

  @override
  void dispose() {
    // Clean up the global route when the widget is removed from the tree.
    _removeGlobalRoute();
    super.dispose();
  }

  /// Registers a global route to capture pointer events anywhere in the app.
  ///
  /// This is necessary for tracking drags that originate inside this widget
  /// but move outside of its bounds.
  void _addGlobalRoute() {
    if (!_isDragEntered) {
      _isDragEntered = true;
      GestureBinding.instance.pointerRouter.addGlobalRoute(_handleGlobalEvent);
    }
  }

  /// Removes the global pointer event route.
  void _removeGlobalRoute() {
    if (_isDragEntered) {
      _isDragEntered = false;
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_handleGlobalEvent);
    }
  }

  /// The global event handler for pointer events.
  ///
  /// This is only active when a drag has started within this widget.
  void _handleGlobalEvent(PointerEvent event) {
    if (!mounted) {
      // If the widget is no longer in the tree, we should not be handling events.
      _removeGlobalRoute();
      return;
    }

    if (event is PointerMoveEvent) {
      // Check if the pointer is still within our bounds.
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final localPosition = renderBox.globalToLocal(event.position);
        if (renderBox.size.contains(localPosition)) {
          // If the pointer re-enters, update the position.
          setState(() {
            _localPosition = localPosition;
          });
        } else {
          // If the pointer moves outside, we can stop listening globally.
          _exitWidget();
        }
      }
    } else if (event is PointerUpEvent) {
      // If the pointer is released anywhere, the drag is over.
      _handlePointerUp(event);
      _removeGlobalRoute();
    }
  }

  /// Centralized logic for handling pointer up events.
  void _handlePointerUp(PointerUpEvent event) {
    if (_isHovering) {
      setState(() {
        _isDown = false;
        _localPosition = event.localPosition;
      });
    }
  }

  /// Centralized logic for exiting the widget area.
  void _exitWidget() {
    _removeGlobalRoute();
    setState(() {
      // Preserve the state from just before we exited.
      _lastKnownClickState = _isDown;
      _lastKnownPosition = _localPosition;

      // Reset the current state.
      _isHovering = false;
      _isDown = null;
      _localPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {
        setState(() {
          _isHovering = true;
          _localPosition = event.localPosition;
          _isDown = event.down;
          // Reset last known state, as the pointer is now inside.
          _lastKnownClickState = null;
          _lastKnownPosition = null;
        });

        if (event.down) {
          // If the pointer enters while already down, start global tracking.
          _addGlobalRoute();
        }
      },
      onExit: (event) {
        // If not in a drag, exit normally.
        if (!_isDragEntered) {
          _exitWidget();
        }
      },
      onHover: (event) {
        setState(() {
          _localPosition = event.localPosition;
        });
      },
      child: Listener(
        onPointerDown: (event) {
          _addGlobalRoute();
          setState(() {
            _isDown = true;
            _localPosition = event.localPosition;
          });
        },
        onPointerUp: (event) {
          _removeGlobalRoute();
          _handlePointerUp(event);
        },
        onPointerMove: (event) {
          // Only update position on move if the button is down (i.e., dragging).
          if (_isHovering && (_isDown ?? false)) {
            setState(() {
              _localPosition = event.localPosition;
            });
          }
        },
        child: widget.builder(
          context,
          _isHovering,
          _isDown,
          _localPosition,
          _lastKnownClickState,
          _lastKnownPosition,
        ),
      ),
    );
  }
}
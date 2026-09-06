import '../ember_core.dart';

class FrontendManager {
  static CoreFrontend? _frontend;

  /// Sets the frontend implementation (called during initialization).
  static void setFrontend(CoreFrontend frontend) {
    _frontend = frontend;
    Debug.logInfo("Frontend set to: ${frontend.frontendName}");
  }

  /// Gets the current frontend instance.
  static CoreFrontend get instance {
    if (_frontend == null) {
      throw CoreUninitializedError('Frontend not initialized. Call setFrontend() first');
    }
    return _frontend!;
  }
}
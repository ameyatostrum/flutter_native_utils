import 'flutter_native_utils_platform_interface.dart';

class FlutterNativeUtils {
  /// Utility class providing native methods for Flutter applications.
  ///
  FlutterNativeUtils();

  /// Requests the app to restart.
  ///
  /// This method attempts to restart the app by invoking a platform-specific method. It handles various exceptions to ensure smooth interaction with  platform channels and plugins.
  ///
  /// Throws:
  ///- [Exception]: If the platform interaction fails [PlatformException], the plugin is missing [MissingPluginException], or any unexpected error occurs.
  ///
  ///Example:
  ///```dart
  /// await requestAppRestart();
  ///```
  ///
  Future<void> requestAppRestart() {
    return FlutterNativeUtilsPlatform.instance.requestAppRestart();
  }
}

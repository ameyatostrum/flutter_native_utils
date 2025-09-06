import 'package:flutter_native_utils/models/hardware_info.dart';

import 'flutter_native_utils_platform_interface.dart';

/// Utility class providing access to native platform methods for Flutter applications.
///
/// The [FlutterNativeUtils] class exposes methods that bridge between
/// Flutter (Dart) and the underlying operating system using platform channels.
/// These methods allow you to perform native operations such as restarting
/// the application or retrieving hardware identifiers.
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

  /// Requests hardware identifiers from the underlying platform.
  ///
  /// This method invokes a platform-specific implementation to retrieve
  /// system-level identifiers and returns them as a [HardwareInfo] object.
  ///
  /// The returned [HardwareInfo] typically provides:
  /// - [HardwareInfo.systemCpuId] → The CPU identifier (e.g., `ProcessorId` on Windows).
  /// - [HardwareInfo.systemBoardId] → The motherboard or baseboard identifier
  ///   (e.g., `SerialNumber` on Windows).
  ///
  /// Throws:
  /// - [PlatformException] if the underlying platform call fails.
  /// - [MissingPluginException] if no platform implementation is registered.
  ///
  /// Example:
  /// ```dart
  /// final info = await FlutterNativeUtils().requestHardwareInfo();
  /// print('CPU ID: ${info.systemCpuId}');
  /// print('Board ID: ${info.systemBoardId}');
  /// ```
  Future<HardwareInfo> requestHardwareInfo() {
    return FlutterNativeUtilsPlatform.instance.requestHardwareInfo();
  }

  // Future<TpmStatus> checkTpmStatus() {
  //   return FlutterNativeUtilsPlatform.instance.checkTpmStatus();
  // }

  // Future<Uint8List> createTpmKeyPair(String keyName) {
  //   return FlutterNativeUtilsPlatform.instance.createTpmKeyPair(keyName);
  // }

  // Future<Uint8List> signNonce(Uint8List nonce) {
  //   return FlutterNativeUtilsPlatform.instance.signNonce(nonce);
  // }
}

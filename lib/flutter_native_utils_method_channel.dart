import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_native_utils_platform_interface.dart';

/// An implementation of [FlutterNativeUtilsPlatform] that uses method channels.
class MethodChannelFlutterNativeUtils extends FlutterNativeUtilsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_native_utils');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> requestAppRestart() async {
    try {
      await methodChannel.invokeMethod<void>('RequestAppRestart');
    } on PlatformException catch (error) {
      // Handles platform-specific exceptions.
      // Throws an exception indicating the failure reason.
      throw Exception(
          "Unable to restart the app, platform interaction failed with error: $error");
    } on MissingPluginException catch (_) {
      // Handles the case where the plugin is not created for the platform.
      // Throws an exception indicating the missing plugin.
      throw Exception("Plugin is not created for this platform.");
    } catch (error) {
      // Handles any other exceptions.
      // Throws an exception indicating an unexpected error.
      throw Exception("Unexpected error occured, error: $error");
    }
  }
}

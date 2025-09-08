import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_native_utils_platform_interface.dart';
import 'models/models.dart';

/// An implementation of [FlutterNativeUtilsPlatform] that uses method channels.
class MethodChannelFlutterNativeUtils extends FlutterNativeUtilsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_native_utils');

  @override
  Future<void> requestAppRestart() async {
    try {
      await methodChannel.invokeMethod<void>('RequestAppRestart');
    } on PlatformException catch (error) {
      // Handles platform-specific exceptions.
      // Throws an exception indicating the failure reason.
      throw Exception("Unable to restart the app, platform interaction failed with error: $error");
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

  @override
  Future<HardwareInfo> requestHardwareInfo() async {
    try {
      final nativeResponse = await methodChannel.invokeMethod('RequestHardwareInfo');

      if (nativeResponse == null) {
        throw Exception("Unable to get hardwareInfo, platform interaction failed with error: platform did not provide info.");
      } else {
        return HardwareInfo.fromMap(nativeResponse);
      }
    } on PlatformException catch (error) {
      // Handles platform-specific exceptions.
      // Throws an exception indicating the failure reason.
      throw PlatformException(message: "Unable to get hardwareInfo, platform interaction failed with error: ${error.message}", code: error.code);
    } on MissingPluginException catch (_) {
      // Handles the case where the plugin is not created for the platform.
      // Throws an exception indicating the missing plugin.
      throw MissingPluginException("Plugin is not created for this platform.");
    } catch (error) {
      // Handles any other exceptions.
      // Throws an exception indicating an unexpected error.
      throw Exception("Unexpected error occured, error: $error");
    }
  }

  @override
  Future<Uint8List> createKeyPair(String keyName) async {
    try {
      final publicKey = await methodChannel.invokeMethod<Uint8List>(
        'CreateKeyPair',
        {'keyName': keyName},
      );
      if (publicKey == null) {
        throw Exception("Platform did not return a public key.");
      }
      return publicKey;
    } on PlatformException catch (error) {
      // Handles platform-specific exceptions.
      // Throws an exception indicating the failure reason.
      throw PlatformException(
        message: "Unable to get createKeyPair, platform interaction failed with error: ${error.message}",
        code: error.code,
      );
    } on MissingPluginException catch (_) {
      // Handles the case where the plugin is not created for the platform.
      // Throws an exception indicating the missing plugin.
      throw MissingPluginException("Plugin is not created for this platform.");
    } catch (error) {
      // Handles any other exceptions.
      // Throws an exception indicating an unexpected error.
      throw Exception("Unexpected error occured, error: $error");
    }
  }

  // @override
  // Future<Uint8List> signNonce(Uint8List nonce) async {
  //   try {
  //     final signature = await methodChannel.invokeMethod<Uint8List>('SignNonce', {'nonce': nonce});
  //     if (signature == null) {
  //       throw Exception("TPM returned no signature.");
  //     }
  //     return signature;
  //   } on PlatformException catch (error) {
  //     // Handles platform-specific exceptions.
  //     // Throws an exception indicating the failure reason.
  //     throw Exception("Unable to get signNonce, platform interaction failed with error: $error");
  //   } on MissingPluginException catch (_) {
  //     // Handles the case where the plugin is not created for the platform.
  //     // Throws an exception indicating the missing plugin.
  //     throw Exception("Plugin is not created for this platform.");
  //   } catch (error) {
  //     // Handles any other exceptions.
  //     // Throws an exception indicating an unexpected error.
  //     throw Exception("Unexpected error occured, error: $error");
  //   }
  // }
}

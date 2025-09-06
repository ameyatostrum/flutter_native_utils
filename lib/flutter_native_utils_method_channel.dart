import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_utils/models/hardware_info.dart';

import 'flutter_native_utils_platform_interface.dart';

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
      throw Exception("Unable to get hardwareInfo, platform interaction failed with error: $error");
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

  // @override
  // Future<TpmStatus> checkTpmStatus() async {
  //   try {
  //     final status = await methodChannel.invokeMethod<String>('CheckTPMStatus');
  //     switch (status) {
  //       case 'enabled':
  //         return TpmStatus.enabled;
  //       case 'disabled':
  //         return TpmStatus.disabled;
  //       default:
  //         return TpmStatus.unavailable;
  //     }
  //   } on PlatformException catch (error) {
  //     // Handles platform-specific exceptions.
  //     // Throws an exception indicating the failure reason.
  //     throw Exception("Unable to get checkTpmStatus, platform interaction failed with error: $error");
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

  // @override
  // Future<Uint8List> createTpmKeyPair(String keyName) async {
  //   try {
  //     final publicKey = await methodChannel.invokeMethod<Uint8List>(
  //       'CreateTpmKeyPair',
  //       {'keyName': keyName},
  //     );
  //     if (publicKey == null) {
  //       throw Exception("TPM did not return a public key.");
  //     }
  //     return publicKey;
  //   } on PlatformException catch (error) {
  //     // Handles platform-specific exceptions.
  //     // Throws an exception indicating the failure reason.
  //     throw Exception("Unable to get createTpmKeyPair, platform interaction failed with error: $error");
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

import 'dart:typed_data';

import 'package:flutter_native_utils/models/hardware_info.dart';
import 'package:flutter_native_utils/models/tpm_status.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_native_utils_method_channel.dart';

abstract class FlutterNativeUtilsPlatform extends PlatformInterface {
  /// Constructs a FlutterNativeUtilsPlatform.
  FlutterNativeUtilsPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterNativeUtilsPlatform _instance = MethodChannelFlutterNativeUtils();

  /// The default instance of [FlutterNativeUtilsPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterNativeUtils].
  static FlutterNativeUtilsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterNativeUtilsPlatform] when
  /// they register themselves.
  static set instance(FlutterNativeUtilsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> requestAppRestart() async {
    throw UnimplementedError('requestAppRestart() has not been implemented.');
  }

  /* Both methods should check if current platform in Windows 11
      Maybe call the method to check the TPM status within the sign challenge method*/
  //TODO: method to check TPM status
  /// Checks if a Trusted Platform Module (TPM) is available and enabled.
  ///
  /// This method invokes a platform-specific implementation to determine
  /// the presence and state of the Trusted Platform Module (TPM).
  ///
  /// Returns a [TpmStatus] indicating the current state:
  /// - [TpmStatus.enabled] → TPM is present and enabled (for example, TPM 2.0 is active).
  /// - [TpmStatus.disabled] → TPM is present but disabled or inactive.
  /// - [TpmStatus.unavailable] → TPM is not available on the system or could not be detected.
  ///
  /// Throws:
  /// - [PlatformException] if the underlying platform call fails.
  /// - [MissingPluginException] if no platform implementation is registered.
  Future<TpmStatus> checkTpmStatus() {
    throw UnimplementedError('checkTpmStatus() has not been implemented.');
  }

  /// Creates a new TPM-backed key pair if none exists.
  ///
  /// [keyName] → a unique identifier for the key (persisted in TPM storage).
  ///
  /// Returns the public key in DER-encoded format (or PEM as a string)
  /// so it can be sent to the server for registration.
  ///
  /// Throws:
  /// - [PlatformException] if key creation fails.
  /// - [MissingPluginException] if no platform implementation is registered.
  Future<Uint8List> createTpmKeyPair(String keyName) {
    throw UnimplementedError('createTpmKeyPair() has not been implemented.');
  }

  //TODO: method to sign challenge
  /// Signs a [nonce] using the TPM-protected private key.
  ///
  /// The TPM performs the signing operation internally, ensuring the private
  /// key never leaves the hardware.
  ///
  /// [nonce] → A random byte array (typically 16–32 bytes) provided by the server.
  ///
  /// Returns the raw signature as a [Uint8List]. You can encode this as Base64
  /// before sending to the server.
  ///
  /// Throws:
  /// - [PlatformException] if TPM signing fails.
  /// - [MissingPluginException] if no platform implementation is registered.
  Future<Uint8List> signNonce(Uint8List nonce) {
    throw UnimplementedError('signNonce() has not been implemented.');
  }

  /// Requests hardware identifiers from the underlying platform implementation.
  ///
  /// This method should be overridden by the platform-specific plugin code to
  /// return a [HardwareInfo] object containing system-level identifiers.
  ///
  /// The returned [HardwareInfo] typically provides:
  /// - [HardwareInfo.systemCpuId] → The CPU identifier (e.g., `ProcessorId` on Windows).
  /// - [HardwareInfo.systemBoardId] → The motherboard / baseboard identifier
  ///   (e.g., `SerialNumber` on Windows).
  ///
  /// By default, this method throws an [UnimplementedError] until a concrete
  /// platform-specific implementation is provided.
  ///
  /// Example:
  /// ```dart
  /// final info = await HardwareInfoPlatform.instance.requestHardwareInfo();
  /// print('CPU ID: ${info.systemCpuId}');
  /// print('Board ID: ${info.systemBoardId}');
  /// ```
  ///
  /// Throws:
  /// - [UnimplementedError] if the method has not been implemented on the
  ///   current platform.
  Future<HardwareInfo> requestHardwareInfo() async {
    throw UnimplementedError('requestHardwareInfo() has not been implemented.');
  }
}

import 'dart:typed_data';

import 'package:flutter_native_utils/models/hardware_info.dart';
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

  /// Creates a new secure key pair if none exists.
  ///
  /// Keys are stored in a platform-protected storage provider
  /// (for example, Windows CNG, macOS Secure Enclave, or Android Keystore).
  ///
  /// [keyName] → a unique identifier for the key (persisted in secure storage).
  ///
  /// Returns:
  /// - The public key in DER-encoded format (or PEM as a string),
  ///   which can be sent to the server for registration.
  ///
  /// Throws:
  /// - [PlatformException] if key creation fails.
  /// - [MissingPluginException] if no platform implementation is registered.
  Future<Uint8List> createKeyPair(String keyName) {
    throw UnimplementedError('createKeyPair() has not been implemented.');
  }

  /// Signs a [nonce] using the platform-protected private key.
  ///
  /// The private key never leaves the secure storage provider.
  /// Only the signature is returned.
  ///
  /// [nonce] → A random byte array (typically 16–32 bytes) provided by the server.
  ///
  /// Returns:
  /// - The raw signature as a [Uint8List]. You can Base64-encode it before
  ///   sending to the server.
  ///
  /// Throws:
  /// - [PlatformException] if signing fails.
  /// - [MissingPluginException] if no platform implementation is registered.
  Future<Uint8List> signNonce(Uint8List nonce, String keyName) {
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

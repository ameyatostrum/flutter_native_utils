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
  /// @Deprecated('This method is not implemented for any platform.')
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
  @Deprecated('This method is not implemented for any platform.')
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
  @Deprecated('This method is not implemented for any platform.')
  Future<HardwareInfo> requestHardwareInfo() async {
    throw UnimplementedError('requestHardwareInfo() has not been implemented.');
  }

  /// Retrieves a certificate from the Windows certificate store by its thumbprint.
  ///
  /// This method should be overridden by the platform-specific plugin code to
  /// return certificate data from the operating system's certificate store.
  ///
  /// **Parameters:**
  /// - [thumbprint] → The SHA-1 thumbprint (hash) of the certificate in hexadecimal
  ///   format without spaces or colons (e.g., "A1B2C3D4E5F6789012345678901234567890ABCD").
  ///
  /// **Returns:**
  /// A [Map<String, dynamic>] containing the certificate data, or `null` if the
  /// certificate is not found or an error occurs. The map typically contains:
  /// - `certificate` (List<int>) → The raw certificate bytes in DER/X.509 format.
  ///
  /// **Platform-specific behavior:**
  /// - **Windows**: Searches the current user's personal certificate store
  ///   (`CERT_SYSTEM_STORE_CURRENT_USER` / "MY" store).
  /// - **Other platforms**: Not yet implemented, will throw [UnimplementedError].
  ///
  /// **Note:** To find a certificate's thumbprint on Windows:
  /// 1. Open Certificate Manager (`certmgr.msc`)
  /// 2. Navigate to Personal → Certificates
  /// 3. Double-click the certificate
  /// 4. Go to Details tab → Thumbprint field
  ///
  /// Example:
  /// ```dart
  /// final certData = await FlutterNativeUtilsPlatform.instance
  ///     .getCertificate('A1B2C3D4E5F6789012345678901234567890ABCD');
  ///
  /// if (certData != null) {
  ///   final certBytes = certData['certificate'] as List<int>;
  ///   print('Certificate retrieved: ${certBytes.length} bytes');
  ///
  ///   // Use with SecurityContext for HTTPS client authentication
  ///   final context = SecurityContext.defaultContext;
  ///   context.useCertificateChainBytes(certBytes);
  /// } else {
  ///   print('Certificate not found');
  /// }
  /// ```
  ///
  /// Throws:
  /// - [UnimplementedError] if the method has not been implemented on the
  ///   current platform.
  /// - [PlatformException] with code:
  ///   - `BAD_ARGS` if the thumbprint parameter is missing or invalid.
  ///   - `FAILURE` if the certificate store cannot be opened or certificate not found.
  Future<Map<String, dynamic>?> getCertificate(String thumbprint) {
    throw UnimplementedError('getCertificate() has not been implemented.');
  }
}

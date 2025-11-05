import 'dart:typed_data';

import 'package:flutter_native_utils/models/models.dart';

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
  @Deprecated('This method is not implemented for any platform.')
  Future<HardwareInfo> requestHardwareInfo() {
    return FlutterNativeUtilsPlatform.instance.requestHardwareInfo();
  }

  @Deprecated('This method is not implemented for any platform.')
  Future<Uint8List> createKeyPair(String keyName) {
    return FlutterNativeUtilsPlatform.instance.createKeyPair(keyName);
  }

  @Deprecated('This method is not implemented for any platform.')
  Future<Uint8List> signNonce(Uint8List nonce, String keyName) {
    return FlutterNativeUtilsPlatform.instance.signNonce(nonce, keyName);
  }

  /// Retrieves a certificate from the Windows certificate store by its thumbprint.
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
  Future<Map<String, dynamic>?> getCertificate({required String thumbprint}) {
    return FlutterNativeUtilsPlatform.instance.getCertificate(thumbprint);
  }
}

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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

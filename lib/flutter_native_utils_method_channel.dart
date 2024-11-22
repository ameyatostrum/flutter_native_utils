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
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}

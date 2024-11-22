
import 'flutter_native_utils_platform_interface.dart';

class FlutterNativeUtils {
  Future<String?> getPlatformVersion() {
    return FlutterNativeUtilsPlatform.instance.getPlatformVersion();
  }
}

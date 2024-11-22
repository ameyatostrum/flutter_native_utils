import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_native_utils/flutter_native_utils.dart';
import 'package:flutter_native_utils/flutter_native_utils_platform_interface.dart';
import 'package:flutter_native_utils/flutter_native_utils_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterNativeUtilsPlatform
    with MockPlatformInterfaceMixin
    implements FlutterNativeUtilsPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterNativeUtilsPlatform initialPlatform = FlutterNativeUtilsPlatform.instance;

  test('$MethodChannelFlutterNativeUtils is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterNativeUtils>());
  });

  test('getPlatformVersion', () async {
    FlutterNativeUtils flutterNativeUtilsPlugin = FlutterNativeUtils();
    MockFlutterNativeUtilsPlatform fakePlatform = MockFlutterNativeUtilsPlatform();
    FlutterNativeUtilsPlatform.instance = fakePlatform;

    expect(await flutterNativeUtilsPlugin.getPlatformVersion(), '42');
  });
}

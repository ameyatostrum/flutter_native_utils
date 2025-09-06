import 'package:flutter/services.dart';
import 'package:flutter_native_utils/flutter_native_utils_method_channel.dart';
import 'package:flutter_native_utils/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channelName = 'flutter_native_utils';
  late MethodChannel methodChannel;
  late MethodChannelFlutterNativeUtils sut;

  setUp(() {
    methodChannel = const MethodChannel(channelName);
    sut = MethodChannelFlutterNativeUtils();
  });

  tearDown(() {
    // teardown
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel, null);
  });

  group(
    'requestAppRestart',
    () {
      test('should throw Exception when PlatformException is thrown', () async {
        // Arrange
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          throw PlatformException(code: 'ERROR', message: 'Failed');
        });

        // Act & Assert
        expect(
          () => sut.requestAppRestart(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('platform interaction failed'),
          )),
        );
      });
    },
  );

  group(
    'requestHardwareInfo',
    () {
      test('should return HardwareInfo when native call succeeds', () async {
        // Arrange
        const mockCpuId = 'CPU1234';
        const mockBoardId = 'BOARD5678';

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          expect(methodCall.method, 'RequestHardwareInfo');
          return {"systemCpuId": mockCpuId, "systemBoardId": mockBoardId};
        });

        // Act
        final info = await sut.requestHardwareInfo();

        // Assert
        expect(info, isA<HardwareInfo>());
        expect(info.systemCpuId, mockCpuId);
        expect(info.systemBoardId, mockBoardId);
      });

      test('should throw Exception when PlatformException is thrown', () async {
        // Arrange
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          throw PlatformException(code: 'ERROR', message: 'Failed');
        });

        // Act & Assert
        expect(
          () => sut.requestHardwareInfo(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('platform interaction failed'),
          )),
        );
      });

      test('should throw Exception when MissingPluginException is thrown', () async {
        // Arrange
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          throw MissingPluginException();
        });

        // Act & Assert
        expect(
          () => sut.requestHardwareInfo(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Plugin is not created'),
          )),
        );
      });

      test('should throw Exception when unexpected error occurs', () async {
        // Arrange
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          throw StateError('boom');
        });

        // Act & Assert
        expect(
          () => sut.requestHardwareInfo(),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('boom'),
          )),
        );
      });

      // group('checkTpmStatus', () {
      //   test('returns TpmStatus.enabled when platform returns "enabled"', () async {
      //     // channel.setMockMethodCallHandler((methodCall) async {
      //     //   if (methodCall.method == 'checkTpmStatus') {
      //     //     return 'enabled';
      //     //   }
      //     //   return null;
      //     // });
      //     TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
      //       expect(methodCall.method, 'checkTpmStatus');
      //       return 'enabled';
      //     });
      //     final status = await sut.checkTpmStatus();
      //     expect(status, equals(TpmStatus.enabled));
      //   });

      //   //   test('returns TpmStatus.disabled when platform returns "disabled"', () async {
      //   //     channel.setMockMethodCallHandler((methodCall) async {
      //   //       return 'disabled';
      //   //     });

      //   //     final status = await checkTpmStatus();
      //   //     expect(status, equals(TpmStatus.disabled));
      //   //   });

      //   //   test('returns TpmStatus.unavailable when platform returns "unavailable"', () async {
      //   //     channel.setMockMethodCallHandler((methodCall) async {
      //   //       return 'unavailable';
      //   //     });

      //   //     final status = await checkTpmStatus();
      //   //     expect(status, equals(TpmStatus.unavailable));
      //   //   });

      //   //   test('throws PlatformException when platform throws', () async {
      //   //     channel.setMockMethodCallHandler((_) async {
      //   //       throw PlatformException(code: 'ERROR', message: 'TPM check failed');
      //   //     });

      //   //     expect(() => checkTpmStatus(), throwsA(isA<PlatformException>()));
      //   //   });

      //   //   test('throws MissingPluginException when plugin not registered', () async {
      //   //     channel.setMockMethodCallHandler(null); // simulate no handler

      //   //     expect(() => checkTpmStatus(), throwsA(isA<MissingPluginException>()));
      //   //   });

      //   //   test('throws StateError for unexpected return values', () async {
      //   //     channel.setMockMethodCallHandler((_) async {
      //   //       return 'unknown_status';
      //   //     });

      //   //     expect(() => checkTpmStatus(), throwsA(isA<StateError>()));
      //   //   });

      //   //   test('throws StateError when platform returns null', () async {
      //   //     channel.setMockMethodCallHandler((_) async {
      //   //       return null;
      //   //     });

      //   //     expect(() => checkTpmStatus(), throwsA(isA<StateError>()));
      //   //   });
      // });
    },
  );
}

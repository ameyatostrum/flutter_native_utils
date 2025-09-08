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
    },
  );

  group(
    'createKeyPair',
    () {
      test('should return Uint8List when native call succeeds', () async {
        // Arrange
        const keyName = 'valid_key';
        final mockPublicKey = Uint8List.fromList([1, 2, 3, 4, 5]);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          methodChannel,
          (MethodCall methodCall) async {
            expect(methodCall.method, 'CreateKeyPair');
            expect(methodCall.arguments, {'keyName': keyName});
            return mockPublicKey;
          },
        );

        // Act
        final result = await sut.createKeyPair(keyName);

        // Assert
        expect(result, isA<Uint8List>());
        expect(result, mockPublicKey);
      });

      test('should throw PlatformException when native call fails', () async {
        // Arrange
        const keyName = 'fail_key';

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          methodChannel,
          (MethodCall methodCall) async {
            expect(methodCall.method, 'CreateKeyPair');
            expect(methodCall.arguments, {'keyName': keyName});
            throw PlatformException(code: 'KEY_CREATION_FAILED', message: 'Could not create key');
          },
        );

        // Act & Assert
        expect(() async => await sut.createKeyPair(keyName), throwsA(isA<Exception>()));
      });

      test('should throw Exception when native call returns null', () async {
        // Arrange
        const keyName = 'unexpected_key';

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          methodChannel,
          (MethodCall methodCall) async {
            expect(methodCall.method, 'CreateKeyPair');
            expect(methodCall.arguments, {'keyName': keyName});
            return null; // simulate unexpected null
          },
        );

        // Act & Assert
        expect(() => sut.createKeyPair(keyName), throwsA(isA<Exception>()));
      });

      test('should throw MissingPluginException when no handler is set', () async {
        // Arrange
        const keyName = 'any_key';
        // no handler set → simulates unimplemented method

        // Act & Assert
        expect(() => sut.createKeyPair(keyName), throwsA(isA<MissingPluginException>()));
      });
    },
  );
}

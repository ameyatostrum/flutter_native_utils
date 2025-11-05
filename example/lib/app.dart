import 'dart:developer' as developer;
import 'dart:math';
import 'dart:typed_data';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_native_utils/flutter_native_utils.dart';
import 'package:flutter_native_utils_example/domain/rsa_key_parser.dart';
import 'package:flutter_native_utils_example/widgets/widgets.dart';
import 'package:pointycastle/pointycastle.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _flutterNativeUtilsPlugin = FlutterNativeUtils();

  int topIndex = 0;
  PaneDisplayMode displayMode = PaneDisplayMode.auto;

  final _keyName = 'flutter_native_example_key_new';
  String _systemInfo = "System info will be displayed here";
  String _publicCryptoKey = "Public key will be displayed here.";
  String _signatureResult = "Signature result will be displayed here";
  String _validCertificate = "Valid certificate does not exist";
  RSAPublicKey? _pubKey;

  @override
  void initState() {
    super.initState();
  }

  /// Simulates fetching a random nonce from an API
  Future<Uint8List> getNonce() async {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256)); // 32-byte nonce
    return Uint8List.fromList(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      home: NavigationView(
        appBar: const NavigationAppBar(title: Text('Flutter Native Utils')),
        pane: NavigationPane(
            selected: topIndex,
            onItemPressed: (index) {
              setState(() {
                topIndex = index;
              });
              if (index == topIndex) {
                if (displayMode == PaneDisplayMode.open) {
                  setState(() => displayMode = PaneDisplayMode.compact);
                } else if (displayMode == PaneDisplayMode.compact) {
                  setState(() => displayMode = PaneDisplayMode.open);
                }
              }
            },
            displayMode: displayMode,
            items: [
              PaneItem(
                icon: const Icon(FluentIcons.home),
                title: const Text('Reboot'),
                body: TitleButtonWidget(
                  title: "Following button will reboot the application.",
                  buttonLabel: "Reboot app",
                  onPressed: () async {
                    await _flutterNativeUtilsPlugin.requestAppRestart();
                  },
                ),
              ),
              PaneItem(
                icon: const Icon(FluentIcons.info),
                title: const Text('System Info'),
                body: SingleChildScrollView(
                  child: Column(
                    spacing: 20.0,
                    children: [
                      TitleButtonWidget(
                        title: _systemInfo,
                        buttonLabel: "Fetch hardware info",
                        onPressed: () async {
                          final hardwareInfo = await _flutterNativeUtilsPlugin.requestHardwareInfo();
                          setState(() {
                            _systemInfo = "Current hardware CPU ID is ${hardwareInfo.systemCpuId} and board ID is ${hardwareInfo.systemBoardId}";
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              PaneItem(
                icon: const Icon(FluentIcons.lock),
                title: const Text('Key Signing'),
                body: SingleChildScrollView(
                  child: Column(
                    spacing: 20.0,
                    children: [
                      TitleButtonWidget(
                        title: _publicCryptoKey,
                        buttonLabel: "Create key",
                        onPressed: () async {
                          final pubKeyBlob = await _flutterNativeUtilsPlugin.createKeyPair(_keyName);
                          _pubKey = parseBcryptRsaPublicKey(Uint8List.fromList(pubKeyBlob));
                          setState(() {
                            if (_pubKey != null) {
                              _publicCryptoKey = 'Public key has been generated.';
                            }
                          });
                        },
                      ),
                      TitleButtonWidget(
                        title: _signatureResult,
                        buttonLabel: "Sign Nonce with Generated Key",
                        onPressed: () async {
                          try {
                            // TODO: implement verification of the public key. Right now these are just random 32 bytes.
                            final nonce = await getNonce();
                            final signature = await _flutterNativeUtilsPlugin.signNonce(nonce, _keyName);

                            final isSignatureVerified = verifySignature(Uint8List.fromList(signature), nonce, _pubKey!);

                            setState(() {
                              _signatureResult = "is signature verified -> $isSignatureVerified";
                            });
                          } catch (e) {
                            setState(() {
                              _signatureResult = "Error: $e";
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              PaneItem(
                icon: const Icon(FluentIcons.certificate),
                title: const Text('Get certificate'),
                body: SingleChildScrollView(
                  child: Column(
                    spacing: 20.0,
                    children: [
                      TitleButtonWidget(
                        title: _validCertificate,
                        buttonLabel: "Get Certificate",
                        onPressed: () async {
                          try {
                            final certificate = await _flutterNativeUtilsPlugin.getCertificate(
                              thumbprint: '<CERTIFICATE THUMBPRINT HEX VALUE HERE>',
                            );
                            setState(() {
                              if (certificate != null) {
                                developer.log('certificate key: ${certificate.keys}, certificate value: ${certificate.values}');
                                _validCertificate = "Certificate exists!";
                              } else {
                                _validCertificate = "Valid certificate does not exist";
                              }
                            });
                          } catch (e) {
                            setState(() {
                              _validCertificate = "An error occured while fetching the certificate: ${e.toString()}";
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ]),
      ),
    );
  }
}

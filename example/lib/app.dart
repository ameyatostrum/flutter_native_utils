import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_native_utils/flutter_native_utils.dart';
import 'package:flutter_native_utils_example/widgets/widgets.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _flutterNativeUtilsPlugin = FlutterNativeUtils();

  int topIndex = 0;
  PaneDisplayMode displayMode = PaneDisplayMode.auto;

  String _systemInfo = "System info will be displayed here";
  String _publicCryptoKey = "Public key will be displayed here.";

  @override
  void initState() {
    super.initState();
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
                  onPressed: () async => await showDialog(
                    context: context,
                    builder: (context) => ContentDialog(
                      title: const Text("Reboot the app"),
                      content: const Text("Are you sure you want to reboot the application?"),
                      actions: [
                        FilledButton(onPressed: () async => await _flutterNativeUtilsPlugin.requestAppRestart(), child: const Text("Reboot")),
                        Button(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
                      ],
                    ),
                  ),
                ),
              ),
              PaneItem(
                icon: const Icon(FluentIcons.home),
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
                      TitleButtonWidget(
                        title: _publicCryptoKey,
                        buttonLabel: "Create key",
                        onPressed: () async {
                          final publicKey = await _flutterNativeUtilsPlugin.createKeyPair('flutter_native_example_key');
                          final stringKey = publicKey.toString();
                          setState(() {
                            _publicCryptoKey = stringKey;
                          });
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

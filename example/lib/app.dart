import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_native_utils/flutter_native_utils.dart';
import 'package:flutter_native_utils_example/widgets/widgets.dart';
import 'package:flutter_native_utils_example/widgets/win_info_widget.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _flutterNativeUtilsPlugin = FlutterNativeUtils();

  int topIndex = 0;
  String systemInfo = "System info will be displayed here";
  PaneDisplayMode displayMode = PaneDisplayMode.auto;

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
                body: TestRebootWidget(
                  onPressed: () async => await _flutterNativeUtilsPlugin.requestAppRestart(),
                ),
              ),
              PaneItem(
                icon: const Icon(FluentIcons.home),
                title: const Text('System Info'),
                body: WinInfoWidget(
                  info: systemInfo,
                  onPressed: () async {
                    final hardwareInfo = await _flutterNativeUtilsPlugin.requestHardwareInfo();
                    systemInfo = "Current hardware CPU ID is ${hardwareInfo.systemCpuId} and board ID is ${hardwareInfo.systemBoardId}";
                    setState(() {});
                  },
                ),
              ),
            ]),
        // body: Center(
        //   child: Column(
        //     children: [
        //       TestRebootWidget(
        //         onPressed: () async =>
        //             await _flutterNativeUtilsPlugin.requestAppRestart(),
        //       ),
        //     ],
        //   ),
        // ),
      ),
    );
  }
}

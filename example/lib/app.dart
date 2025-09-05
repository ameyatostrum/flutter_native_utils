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

  int topIndex = 1;
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
                title: const Text('Home'),
                body: TestRebootWidget(
                  onPressed: () async =>
                      await _flutterNativeUtilsPlugin.requestAppRestart(),
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

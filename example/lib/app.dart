import 'package:flutter/material.dart';
import 'package:flutter_native_utils/flutter_native_utils.dart';
import 'package:flutter_native_utils_example/widgets/widgets.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _flutterNativeUtilsPlugin = FlutterNativeUtils();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Native Utils'),
        ),
        body: Center(
          child: Column(
            children: [
              TestRebootWidget(
                onPressed: () async =>
                    await _flutterNativeUtilsPlugin.requestAppRestart(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

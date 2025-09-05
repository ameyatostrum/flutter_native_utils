import 'package:fluent_ui/fluent_ui.dart';
// import 'package:flutter/material.dart';

// ignore: must_be_immutable
class TestRebootWidget extends StatelessWidget {
  void Function()? onPressed;

  TestRebootWidget({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Following button will reboot the application.",
            style: FluentTheme.of(context).typography.title,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: FilledButton(
            onPressed: onPressed == null
                ? null
                : () async => await showConfirmationDialog(
                      onPressed: onPressed,
                      context: context,
                    ),
            child: const Text("Reboot app"),
          ),
        ),
      ],
    );
  }

  Future<void> showConfirmationDialog({
    required void Function()? onPressed,
    required BuildContext context,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text("Reboot the app"),
        content: const Text("Are you sure you want to reboot the application?"),
        actions: [
          FilledButton(onPressed: onPressed, child: const Text("Reboot")),
          Button(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel")),
        ],
      ),
    );
  }
}

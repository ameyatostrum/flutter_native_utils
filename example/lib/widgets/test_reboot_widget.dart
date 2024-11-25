import 'package:flutter/material.dart';

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
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ElevatedButton(
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
      builder: (context) => AlertDialog(
        title: const Text("Reboot the app"),
        content: const Text("Are you sure you want to reboot the application?"),
        actions: [
          TextButton(onPressed: onPressed, child: const Text("Reboot")),
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel")),
        ],
      ),
    );
  }
}

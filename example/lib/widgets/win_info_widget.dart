import 'package:fluent_ui/fluent_ui.dart';

class WinInfoWidget extends StatelessWidget {
  final VoidCallback? onPressed;
  final String info;

  const WinInfoWidget({
    super.key,
    required this.info,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Following button will fetch system info.",
            style: FluentTheme.of(context).typography.title,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: FilledButton(
            onPressed: onPressed,
            child: const Text("Fetch info"),
          ),
        ),
        if (info.isNotEmpty) Text(info),
      ],
    );
  }
}

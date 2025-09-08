import 'package:fluent_ui/fluent_ui.dart';
// import 'package:flutter/material.dart';

// ignore: must_be_immutable
class TitleButtonWidget extends StatelessWidget {
  final String title;
  final String buttonLabel;
  void Function()? onPressed;

  TitleButtonWidget({
    super.key,
    required this.title,
    required this.buttonLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8.0,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: FluentTheme.of(context).typography.title,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: FilledButton(
            onPressed: onPressed,
            child: Text(buttonLabel),
          ),
        ),
      ],
    );
  }
}

# Flutter native utils

A plug-in to expose utilites which employ native platfrom libraries.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/to/develop-plugins),
a specialized package that includes platform-specific implementation code for
Android/iOS/Windows.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Add platforms

To add platforms, run `flutter create -t plugin --platforms <platforms> .` in this directory.
You can also find a detailed instruction on how to add platforms in the `pubspec.yaml` at https://flutter.dev/to/pubspec-plugin-platforms.

## Creating a branch
A branch is created for each platform. 
1. When creating a new branch, create a branch from the platform for which you are want to develop the plug-in, and suffix it with `-dev-{your name}`.
For example, if you would to develop or fix a bug for iOS platform, the branch name would be `ios-dev-ameyatostrum`.

2. Once you are satisfied with the development, merge your code with platform branch and mark it for review.


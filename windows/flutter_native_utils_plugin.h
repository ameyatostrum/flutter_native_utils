#ifndef FLUTTER_PLUGIN_FLUTTER_NATIVE_UTILS_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_NATIVE_UTILS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flutter_native_utils {

class FlutterNativeUtilsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterNativeUtilsPlugin();

  virtual ~FlutterNativeUtilsPlugin();

  // Disallow copy and assign.
  FlutterNativeUtilsPlugin(const FlutterNativeUtilsPlugin&) = delete;
  FlutterNativeUtilsPlugin& operator=(const FlutterNativeUtilsPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flutter_native_utils

#endif  // FLUTTER_PLUGIN_FLUTTER_NATIVE_UTILS_PLUGIN_H_

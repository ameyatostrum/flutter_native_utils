#include "include/flutter_native_utils/flutter_native_utils_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_native_utils_plugin.h"

void FlutterNativeUtilsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_native_utils::FlutterNativeUtilsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

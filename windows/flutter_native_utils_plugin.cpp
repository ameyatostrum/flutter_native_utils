#include "flutter_native_utils_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>

#include <winrt/Windows.ApplicationModel.Core.h> 
#include <winrt/Windows.Foundation.h> 
#include <iostream> 
using namespace winrt;
using namespace Windows::ApplicationModel::Core;
using namespace Windows::Foundation;

namespace flutter_native_utils {

// static
void FlutterNativeUtilsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "flutter_native_utils",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FlutterNativeUtilsPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FlutterNativeUtilsPlugin::FlutterNativeUtilsPlugin() {}

FlutterNativeUtilsPlugin::~FlutterNativeUtilsPlugin() {}

static std::wstring RequestAppRestart(const std::wstring& restartArgs) {
    // Get the current module file name 
    wchar_t moduleFileName[MAX_PATH];
    if (GetModuleFileName(NULL, moduleFileName, MAX_PATH) == 0)
    {
        return L"Failed to get module file name.";
    }

    // Prepare the command line arguments 
    std::wstring commandLine = L"\"";
    commandLine += moduleFileName;
    commandLine += L"\" ";
    commandLine += restartArgs;

    // Create the process with the same executable 
    STARTUPINFO startupInfo = { 0 };
    startupInfo.cb = sizeof(startupInfo);
    PROCESS_INFORMATION processInfo = { 0 };

    if (!CreateProcess(moduleFileName, // Application name 
        &commandLine[0], // Command line arguments 
        NULL, // Process attributes
        NULL, // Thread attributes 
        FALSE, // Inherit handles 
        0, // Creation flags 
        NULL, // Environment 
        NULL, // Current directory 
        &startupInfo, // Startup information 
        &processInfo // Process information 
    )) {
        return L"Failed to create process.";
    }

    // Close handles to the new process and primary thread 
    CloseHandle(processInfo.hProcess);
    CloseHandle(processInfo.hThread);

    // Exit the current process 
    ExitProcess(0);
}


void FlutterNativeUtilsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("RequestAppRestart") == 0) {
    // Example arguments for app restart 
      std::wstring restartArgs = L"";
      std::wstring requestMessage = RequestAppRestart(restartArgs);
      if (requestMessage == L"Success") {
          result->Success("Restart requested successfully.");
      }
      else {
          result->Error("FAILURE", "Failed to request to restart the application.");
      }
  } else {
    result->NotImplemented();
  }
}

}  // namespace flutter_native_utils

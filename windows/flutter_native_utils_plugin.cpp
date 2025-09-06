#include "flutter_native_utils_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <comdef.h>   // for _bstr_t, COM helpers
#include <Wbemidl.h>  // for IWbemLocator, IWbemServices, etc.

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>

#include <winrt/Windows.ApplicationModel.Core.h> 
#include <winrt/Windows.Foundation.h> 
#include <iostream> 
#pragma comment(lib, "wbemuuid.lib")
using namespace winrt;
using namespace Windows::ApplicationModel::Core;
using namespace Windows::Foundation;

namespace flutter_native_utils {
// ========== Utility Implementations ==========
// static void DebugLog(const std::wstring& msg) {
//     OutputDebugString((msg + L"\n").c_str());
// }

// Handles RequestAppRestart call
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

// Wrapper to handle RequestAppRestart channel call
void HandleRequestAppRestart(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  std::wstring restartArgs = L"";
  std::wstring requestMessage = RequestAppRestart(restartArgs);

  if (requestMessage == L"Success") {
    result->Success("Restart requested successfully.");
  } else {
    result->Error("FAILURE", "Failed to request to restart the application.");
  }
}

// -------- RequestHardwareInfo --------

static std::string QueryWmiProperty(const std::wstring& wmi_class,
                                    const std::wstring& property) {
    HRESULT hres = CoInitializeEx(0, COINIT_MULTITHREADED);
    if (hres == RPC_E_CHANGED_MODE) {
        // COM already initialized in STA mode; safe to continue
        hres = S_OK;
    }
    if (FAILED(hres)) {
        return "";
    }

    hres = CoInitializeSecurity(
        NULL, -1, NULL, NULL,
        RPC_C_AUTHN_LEVEL_DEFAULT, RPC_C_IMP_LEVEL_IMPERSONATE,
        NULL, EOAC_NONE, NULL);

    if (FAILED(hres) && hres != RPC_E_TOO_LATE) {
        if (hres != RPC_E_TOO_LATE) {
            CoUninitialize();
        }
        return "";
    }

    IWbemLocator* pLoc = NULL;
    hres = CoCreateInstance(
        CLSID_WbemLocator, 0, CLSCTX_INPROC_SERVER,
        IID_IWbemLocator, reinterpret_cast<LPVOID*>(&pLoc));
    if (FAILED(hres)) {
        CoUninitialize();
        return "";
    }

    IWbemServices* pSvc = NULL;
    hres = pLoc->ConnectServer(
        _bstr_t(L"ROOT\\CIMV2"), NULL, NULL, 0, NULL, 0, 0, &pSvc);
    if (FAILED(hres)) {
        pLoc->Release();
        CoUninitialize();
        return "";
    }

    hres = CoSetProxyBlanket(
        pSvc, RPC_C_AUTHN_WINNT, RPC_C_AUTHZ_NONE, NULL,
        RPC_C_AUTHN_LEVEL_CALL, RPC_C_IMP_LEVEL_IMPERSONATE,
        NULL, EOAC_NONE);
    if (FAILED(hres)) {
        pSvc->Release();
        pLoc->Release();
        CoUninitialize();
        return "";
    }

    IEnumWbemClassObject* pEnumerator = NULL;
    std::wstring query = L"SELECT " + property + L" FROM " + wmi_class;
    hres = pSvc->ExecQuery(
        bstr_t("WQL"), bstr_t(query.c_str()),
        WBEM_FLAG_FORWARD_ONLY | WBEM_FLAG_RETURN_IMMEDIATELY,
        NULL, &pEnumerator);
    if (FAILED(hres)) {
        pSvc->Release();
        pLoc->Release();
        CoUninitialize();
        return "";
    }

    IWbemClassObject* pclsObj = NULL;
    ULONG uReturn = 0;
    std::string resultStr;

    if (pEnumerator) {
        HRESULT hr = pEnumerator->Next(WBEM_INFINITE, 1, &pclsObj, &uReturn);
        if (uReturn != 0) {
            VARIANT vtProp;
            hr = pclsObj->Get(property.c_str(), 0, &vtProp, 0, 0);
            if (SUCCEEDED(hr) && vtProp.vt == VT_BSTR) {
                int len = WideCharToMultiByte(CP_UTF8, 0, vtProp.bstrVal, -1,
                                              NULL, 0, NULL, NULL);
                if (len > 0) {
                    std::string temp(len - 1, 0);
                    WideCharToMultiByte(CP_UTF8, 0, vtProp.bstrVal, -1,
                                        temp.data(), len, NULL, NULL);
                    resultStr = temp;
                }
            }
            VariantClear(&vtProp);
            pclsObj->Release();
        }
        pEnumerator->Release();
    }

    pSvc->Release();
    pLoc->Release();
    CoUninitialize();

    return resultStr;
}

static void HandleRequestHardwareInfo(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  std::string cpuId = QueryWmiProperty(L"Win32_Processor", L"ProcessorId");
  std::string boardId = QueryWmiProperty(L"Win32_BaseBoard", L"SerialNumber");

  flutter::EncodableMap response = {
      {flutter::EncodableValue("systemCpuId"), flutter::EncodableValue(cpuId)},
      {flutter::EncodableValue("systemBoardId"), flutter::EncodableValue(boardId)}};

  result->Success(response);
}



// ========== Plugin Boilerplate ==========

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

void FlutterNativeUtilsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  using Handler = std::function<void(
      const flutter::MethodCall<flutter::EncodableValue>&,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>)>;

  static const std::unordered_map<std::string, Handler> handlers = {
      {"RequestAppRestart", HandleRequestAppRestart},
      {"RequestHardwareInfo", HandleRequestHardwareInfo},
  };

  const std::string& method = method_call.method_name();
  auto it = handlers.find(method);

  if (it != handlers.end()) {
    it->second(method_call, std::move(result));
  } else {
    result->NotImplemented();
  }
}



}  // namespace flutter_native_utils

#include "flutter_native_utils_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <comdef.h>   // for _bstr_t, COM helpers
#include <Wbemidl.h>  // for IWbemLocator, IWbemServices, etc.

#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/encodable_value.h>

#include <memory>
#include <string>
#include <vector>

#include <winrt/Windows.ApplicationModel.Core.h>
#include <winrt/Windows.Foundation.h>

#include <ncrypt.h>   // CNG (Key Storage Provider API)
#include <iostream>

// Link required libraries
#pragma comment(lib, "wbemuuid.lib")  // WMI
#pragma comment(lib, "ncrypt.lib")    // CNG KSP

using namespace winrt;
using namespace Windows::ApplicationModel::Core;
using namespace Windows::Foundation;

namespace flutter_native_utils {
// ========== Utility Implementations ==========
static void DebugLog(const std::wstring& msg) {
    OutputDebugString((msg + L"\n").c_str());
}

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



// -------- CreateKeyPair --------
// ---- Utility ----
static std::wstring Utf8ToWide(const std::string& utf8) {
  if (utf8.empty()) return L"";
  int len = MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, nullptr, 0);
  std::wstring wide(len - 1, 0);
  MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, wide.data(), len);
  return wide;
}

// ---- Key creation / export ----
static std::vector<uint8_t> CreateOrOpenKeyPair(const std::wstring& keyName) {
  DebugLog(L">>> CreateOrOpenKeyPair called for key: " + keyName);

  NCRYPT_PROV_HANDLE hProv = NULL;
  NCRYPT_KEY_HANDLE hKey = NULL;
  SECURITY_STATUS status;

  // Open the default software KSP
  status = NCryptOpenStorageProvider(&hProv, MS_KEY_STORAGE_PROVIDER, 0);
  if (status != ERROR_SUCCESS) {
    DebugLog(L"NCryptOpenStorageProvider failed, status: " + std::to_wstring(status));
    throw std::runtime_error("NCryptOpenStorageProvider failed");
  }

  // Try opening the key
  status = NCryptOpenKey(hProv, &hKey, keyName.c_str(), 0, 0);
  if (status == NTE_BAD_KEYSET) {
    DebugLog(L"Key not found, generating new key pair...");

    status = NCryptCreatePersistedKey(
        hProv, &hKey,
        NCRYPT_RSA_ALGORITHM,   // or NCRYPT_ECDSA_P256_ALGORITHM
        keyName.c_str(),
        0,
        NCRYPT_OVERWRITE_KEY_FLAG);

    if (status != ERROR_SUCCESS) {
      DebugLog(L"NCryptCreatePersistedKey failed, status: " + std::to_wstring(status));
      NCryptFreeObject(hProv);
      throw std::runtime_error("NCryptCreatePersistedKey failed");
    }

    // Set key length property (for RSA)
    DWORD keyLength = 2048;
    status = NCryptSetProperty(hKey,
                               NCRYPT_LENGTH_PROPERTY,
                               (PBYTE)&keyLength,
                               sizeof(keyLength),
                               0);
    if (status != ERROR_SUCCESS) {
      DebugLog(L"NCryptSetProperty failed, status: " + std::to_wstring(status));
      NCryptFreeObject(hKey);
      NCryptFreeObject(hProv);
      throw std::runtime_error("NCryptSetProperty failed");
    }

    // Finalize key
    status = NCryptFinalizeKey(hKey, 0);
    if (status != ERROR_SUCCESS) {
      DebugLog(L"NCryptFinalizeKey failed, status: " + std::to_wstring(status));
      NCryptFreeObject(hKey);
      NCryptFreeObject(hProv);
      throw std::runtime_error("NCryptFinalizeKey failed");
    }

    DebugLog(L"Key pair generated successfully");
  } else if (status != ERROR_SUCCESS) {
    DebugLog(L"NCryptOpenKey failed, status: " + std::to_wstring(status));
    NCryptFreeObject(hProv);
    throw std::runtime_error("NCryptOpenKey failed");
  } else {
    DebugLog(L"Opened existing key successfully");
  }

  // Export public key
  DWORD keySize = 0;
  status = NCryptExportKey(
      hKey,
      NULL,
      BCRYPT_RSAPUBLIC_BLOB,  // export format
      NULL,
      NULL,
      0,
      &keySize,
      0);

  if (status != ERROR_SUCCESS) {
    DebugLog(L"NCryptExportKey (size query) failed, status: " + std::to_wstring(status));
    NCryptFreeObject(hKey);
    NCryptFreeObject(hProv);
    throw std::runtime_error("NCryptExportKey size query failed");
  }

  std::vector<uint8_t> pubKey(keySize);
  status = NCryptExportKey(
      hKey,
      NULL,
      BCRYPT_RSAPUBLIC_BLOB,
      NULL,
      pubKey.data(),
      keySize,
      &keySize,
      0);

  if (status != ERROR_SUCCESS) {
    DebugLog(L"NCryptExportKey failed, status: " + std::to_wstring(status));
    NCryptFreeObject(hKey);
    NCryptFreeObject(hProv);
    throw std::runtime_error("NCryptExportKey failed");
  }

  DebugLog(L"Public key exported successfully, size: " + std::to_wstring(keySize));

  // Cleanup
  NCryptFreeObject(hKey);
  NCryptFreeObject(hProv);

  return pubKey;
}

// Wrapper to handle CreateKeyPair channel call
void HandleCreateKeyPair(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  try {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (!args) throw std::runtime_error("Invalid arguments");

    auto keyNameIt = args->find(flutter::EncodableValue("keyName"));
    if (keyNameIt == args->end()) throw std::runtime_error("Missing keyName");

    std::string keyNameUtf8 = std::get<std::string>(keyNameIt->second);
    std::wstring keyName = Utf8ToWide(keyNameUtf8);

    DebugLog(L"[HandleCreateKeyPair] Creating/Opening key pair");
    auto pubKey = CreateOrOpenKeyPair(keyName);

    result->Success(flutter::EncodableValue(pubKey));
  } catch (const std::exception& ex) {
    DebugLog(L"[HandleCreateKeyPair] Exception: " + Utf8ToWide(ex.what()));
    result->Error("CNG_ERROR", ex.what());
  }
}

// void HandleCreateKeyPair(
//     const flutter::MethodCall<flutter::EncodableValue>& call,
//     std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
//   try {
//     const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
//     if (!args) throw std::runtime_error("Invalid arguments");

//     auto keyNameIt = args->find(flutter::EncodableValue("keyName"));
//     if (keyNameIt == args->end()) throw std::runtime_error("Missing keyName");

//     std::string keyNameUtf8 = std::get<std::string>(keyNameIt->second);
//     std::wstring keyName = Utf8ToWide(keyNameUtf8);

//     DebugLog(L"[HandleCreateKeyPair] Creating/Opening key pair for: " + keyName);

//     auto pubKey = CreateOrOpenKeyPair(keyName);
//     DebugLog(L"[HandleCreateKeyPair] Public key size: " + std::to_wstring(pubKey.size()));

//     result->Success(flutter::EncodableValue(
//         flutter::EncodableValue::ByteArray(pubKey.begin(), pubKey.end())));
//   } catch (const std::exception& ex) {
//     DebugLog(L"[HandleCreateKeyPair] Exception: " + Utf8ToWide(ex.what()));
//     result->Error("CNG_ERROR", ex.what());
//   }
// }


// ---- Signing ----
// static std::vector<uint8_t> SignWithKey(const std::wstring& keyName,
//                                         const std::vector<uint8_t>& data) {
//   DebugLog(L">>> SignWithKey called for key: " + keyName);

//   BCRYPT_ALG_HANDLE hAlgRsa = nullptr, hAlgSha = nullptr;
//   BCRYPT_KEY_HANDLE hKey = nullptr;
//   NTSTATUS status;

//   status = BCryptOpenAlgorithmProvider(&hAlgRsa, BCRYPT_RSA_ALGORITHM, NULL, 0);
//   if (status != 0) {
//     DebugLog(L"BCryptOpenAlgorithmProvider (RSA) failed");
//     throw std::runtime_error("BCryptOpenAlgorithmProvider (RSA) failed");
//   }

//   status = BCryptOpenKey(hAlgRsa, &hKey, keyName.c_str(), 0, 0);
//   if (status != 0) {
//     DebugLog(L"BCryptOpenKey failed");
//     BCryptCloseAlgorithmProvider(hAlgRsa, 0);
//     throw std::runtime_error("BCryptOpenKey failed");
//   }

//   // Hash with SHA256
//   status = BCryptOpenAlgorithmProvider(&hAlgSha, BCRYPT_SHA256_ALGORITHM, NULL, 0);
//   if (status != 0) {
//     DebugLog(L"BCryptOpenAlgorithmProvider (SHA256) failed");
//     BCryptDestroyKey(hKey);
//     BCryptCloseAlgorithmProvider(hAlgRsa, 0);
//     throw std::runtime_error("BCryptOpenAlgorithmProvider (SHA256) failed");
//   }

//   DWORD hashObjLen = 0, hashLen = 0, cbData = 0;
//   status = BCryptGetProperty(hAlgSha, BCRYPT_OBJECT_LENGTH,
//                              (PUCHAR)&hashObjLen, sizeof(DWORD), &cbData, 0);
//   status = BCryptGetProperty(hAlgSha, BCRYPT_HASH_LENGTH,
//                              (PUCHAR)&hashLen, sizeof(DWORD), &cbData, 0);

//   std::vector<uint8_t> hash(hashLen);
//   std::vector<uint8_t> hashObj(hashObjLen);

//   BCRYPT_HASH_HANDLE hHash = nullptr;
//   status = BCryptCreateHash(hAlgSha, &hHash, hashObj.data(), hashObjLen, NULL, 0, 0);
//   status = BCryptHashData(hHash, (PUCHAR)data.data(), (ULONG)data.size(), 0);
//   status = BCryptFinishHash(hHash, hash.data(), hashLen, 0);

//   DebugLog(L"SHA256 hash computed");

//   // Sign the hash
//   DWORD sigLen = 0;
//   status = BCryptSignHash(hKey, NULL, hash.data(), hashLen,
//                           NULL, 0, &sigLen, BCRYPT_PAD_PKCS1);
//   if (status != 0) {
//     DebugLog(L"BCryptSignHash (size) failed");
//     throw std::runtime_error("BCryptSignHash (size) failed");
//   }

//   std::vector<uint8_t> signature(sigLen);
//   status = BCryptSignHash(hKey, NULL, hash.data(), hashLen,
//                           signature.data(), sigLen, &sigLen, BCRYPT_PAD_PKCS1);
//   if (status != 0) {
//     DebugLog(L"BCryptSignHash failed");
//     throw std::runtime_error("BCryptSignHash failed");
//   }

//   DebugLog(L"Data signed successfully");

//   BCryptDestroyHash(hHash);
//   BCryptDestroyKey(hKey);
//   BCryptCloseAlgorithmProvider(hAlgSha, 0);
//   BCryptCloseAlgorithmProvider(hAlgRsa, 0);

//   return signature;
// }

// Wrapper to handle SignNonce channel call
// void HandleSignNonce(
//     const flutter::MethodCall<flutter::EncodableValue>& call,
//     std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
//   try {
//     const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
//     if (!args) throw std::runtime_error("Invalid arguments");

//     auto keyNameIt = args->find(flutter::EncodableValue("keyName"));
//     auto nonceIt   = args->find(flutter::EncodableValue("nonce"));
//     if (keyNameIt == args->end() || nonceIt == args->end())
//       throw std::runtime_error("Missing arguments");

//     std::string keyNameUtf8 = std::get<std::string>(keyNameIt->second);
//     std::wstring keyName = Utf8ToWide(keyNameUtf8);

//     std::vector<uint8_t> nonce = std::get<std::vector<uint8_t>>(nonceIt->second);

//     DebugLog(L"[HandleSignNonce] Signing nonce");
//     auto signature = SignWithKey(keyName, nonce);

//     result->Success(flutter::EncodableValue(signature));
//   } catch (const std::exception& ex) {
//     DebugLog(L"[HandleSignNonce] Exception: " + Utf8ToWide(ex.what()));
//     result->Error("CNG_ERROR", ex.what());
//   }
// }


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
      {"CreateKeyPair", HandleCreateKeyPair},
      // {"SignNonce", HandleSignNonce},
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

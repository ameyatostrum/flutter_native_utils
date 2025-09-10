#include "flutter_native_utils_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <comdef.h>
#include <Wbemidl.h>

#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/encodable_value.h>

#include <memory>
#include <string>
#include <vector>
#include <unordered_map>
#include <functional>

#include <winrt/Windows.ApplicationModel.Core.h>
#include <winrt/Windows.Foundation.h>

#include <ncrypt.h>
#include <iostream>

// Link required libraries
#pragma comment(lib, "wbemuuid.lib")
#pragma comment(lib, "ncrypt.lib")

using namespace winrt;
using namespace Windows::ApplicationModel::Core;
using namespace Windows::Foundation;

namespace flutter_native_utils {

// ---------- Debug helper ----------
static void DebugLog(const std::wstring& msg) {
  OutputDebugString((msg + L"\n").c_str());
}

// ---------- RAII wrapper for NCrypt handles ----------
struct NCryptHandle {
  NCRYPT_HANDLE handle{0};
  ~NCryptHandle() { reset(); }

  void reset() {
    if (handle) {
      NCryptFreeObject(handle);
      handle = 0;
    }
  }
  operator NCRYPT_HANDLE() const { return handle; }
  NCRYPT_HANDLE* put() { reset(); return &handle; }
};

// ---------- UTF8 <-> Wide ----------
static std::wstring Utf8ToWide(const std::string& str) {
  if (str.empty()) return L"";
  int len = MultiByteToWideChar(CP_UTF8, 0, str.c_str(), (int)str.size(), nullptr, 0);
  std::wstring result(len, 0);
  MultiByteToWideChar(CP_UTF8, 0, str.c_str(), (int)str.size(), result.data(), len);
  return result;
}

static std::string WideToUtf8(const std::wstring& wstr) {
  if (wstr.empty()) return "";
  int len = WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), (int)wstr.size(),
                                nullptr, 0, nullptr, nullptr);
  std::string result(len, 0);
  WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), (int)wstr.size(),
                      result.data(), len, nullptr, nullptr);
  return result;
}

// ---------- RequestAppRestart ----------
static std::wstring RequestAppRestart(const std::wstring& restartArgs) {
  wchar_t moduleFileName[MAX_PATH];
  if (GetModuleFileName(NULL, moduleFileName, MAX_PATH) == 0) {
    return L"Failed to get module file name.";
  }

  std::wstring commandLine = L"\"";
  commandLine += moduleFileName;
  commandLine += L"\" ";
  commandLine += restartArgs;

  STARTUPINFO startupInfo = { sizeof(startupInfo) };
  PROCESS_INFORMATION processInfo = { 0 };

  if (!CreateProcess(moduleFileName, &commandLine[0], NULL, NULL, FALSE,
                     0, NULL, NULL, &startupInfo, &processInfo)) {
    return L"Failed to create process.";
  }

  CloseHandle(processInfo.hProcess);
  CloseHandle(processInfo.hThread);

  ExitProcess(0);
}

void HandleRequestAppRestart(
    const flutter::MethodCall<flutter::EncodableValue>&,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  std::wstring msg = RequestAppRestart(L"");
  if (msg == L"Success") {
    result->Success("Restart requested successfully.");
  } else {
    result->Error("FAILURE", WideToUtf8(msg));
  }
}

// ---------- Hardware Info (WMI) ----------
static std::string QueryWmiProperty(const std::wstring& wmi_class,
                                    const std::wstring& property) {
  HRESULT hres = CoInitializeEx(0, COINIT_MULTITHREADED);
  if (hres == RPC_E_CHANGED_MODE) hres = S_OK;
  if (FAILED(hres)) return "";

  hres = CoInitializeSecurity(NULL, -1, NULL, NULL,
                              RPC_C_AUTHN_LEVEL_DEFAULT,
                              RPC_C_IMP_LEVEL_IMPERSONATE,
                              NULL, EOAC_NONE, NULL);
  if (FAILED(hres) && hres != RPC_E_TOO_LATE) {
    CoUninitialize();
    return "";
  }

  IWbemLocator* pLoc = NULL;
  hres = CoCreateInstance(CLSID_WbemLocator, 0, CLSCTX_INPROC_SERVER,
                          IID_IWbemLocator, reinterpret_cast<LPVOID*>(&pLoc));
  if (FAILED(hres)) {
    CoUninitialize();
    return "";
  }

  IWbemServices* pSvc = NULL;
  hres = pLoc->ConnectServer(_bstr_t(L"ROOT\\CIMV2"),
                             NULL, NULL, 0, NULL, 0, 0, &pSvc);
  if (FAILED(hres)) {
    pLoc->Release();
    CoUninitialize();
    return "";
  }

  CoSetProxyBlanket(pSvc, RPC_C_AUTHN_WINNT, RPC_C_AUTHZ_NONE, NULL,
                    RPC_C_AUTHN_LEVEL_CALL, RPC_C_IMP_LEVEL_IMPERSONATE,
                    NULL, EOAC_NONE);

  IEnumWbemClassObject* pEnumerator = NULL;
  std::wstring query = L"SELECT " + property + L" FROM " + wmi_class;
  hres = pSvc->ExecQuery(bstr_t("WQL"), bstr_t(query.c_str()),
                         WBEM_FLAG_FORWARD_ONLY | WBEM_FLAG_RETURN_IMMEDIATELY,
                         NULL, &pEnumerator);

  std::string resultStr;
  if (SUCCEEDED(hres) && pEnumerator) {
    IWbemClassObject* pclsObj = NULL;
    ULONG uReturn = 0;
    HRESULT hr = pEnumerator->Next(WBEM_INFINITE, 1, &pclsObj, &uReturn);
    if (uReturn != 0) {
      VARIANT vtProp;
      hr = pclsObj->Get(property.c_str(), 0, &vtProp, 0, 0);
      if (SUCCEEDED(hr) && vtProp.vt == VT_BSTR) {
        resultStr = WideToUtf8(vtProp.bstrVal);
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
    const flutter::MethodCall<flutter::EncodableValue>&,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  std::string cpuId = QueryWmiProperty(L"Win32_Processor", L"ProcessorId");
  std::string boardId = QueryWmiProperty(L"Win32_BaseBoard", L"SerialNumber");

  flutter::EncodableMap response = {
      {flutter::EncodableValue("systemCpuId"), flutter::EncodableValue(cpuId)},
      {flutter::EncodableValue("systemBoardId"), flutter::EncodableValue(boardId)}};
  result->Success(response);
}

// ---------- CNG Key Management ----------
static std::vector<uint8_t> CreateOrOpenKeyPair(const std::wstring& keyName) {
  NCryptHandle hProv, hKey;
  SECURITY_STATUS status = NCryptOpenStorageProvider(hProv.put(),
                                                     MS_KEY_STORAGE_PROVIDER, 0);
  if (status != ERROR_SUCCESS) throw std::runtime_error("OpenStorageProvider failed");

  status = NCryptOpenKey(hProv, hKey.put(), keyName.c_str(), 0, 0);
  if (status == NTE_BAD_KEYSET) {
    status = NCryptCreatePersistedKey(hProv, hKey.put(),
                                      NCRYPT_RSA_ALGORITHM,
                                      keyName.c_str(), 0,
                                      NCRYPT_OVERWRITE_KEY_FLAG);
    if (status != ERROR_SUCCESS) throw std::runtime_error("CreatePersistedKey failed");

    DWORD keyLength = 2048;
    status = NCryptSetProperty(hKey, NCRYPT_LENGTH_PROPERTY,
                               (PBYTE)&keyLength, sizeof(keyLength), 0);
    if (status != ERROR_SUCCESS) throw std::runtime_error("SetProperty failed");

    status = NCryptFinalizeKey(hKey, 0);
    if (status != ERROR_SUCCESS) throw std::runtime_error("FinalizeKey failed");
  } else if (status != ERROR_SUCCESS) {
    throw std::runtime_error("OpenKey failed");
  }

  DWORD keySize = 0;
  status = NCryptExportKey(hKey, 0, BCRYPT_RSAPUBLIC_BLOB,
                           nullptr, nullptr, 0, &keySize, 0);
  if (status != ERROR_SUCCESS) throw std::runtime_error("ExportKey size failed");

  std::vector<uint8_t> pubKey(keySize);
  status = NCryptExportKey(hKey, 0, BCRYPT_RSAPUBLIC_BLOB,
                           nullptr, pubKey.data(), keySize, &keySize, 0);
  if (status != ERROR_SUCCESS) throw std::runtime_error("ExportKey failed");

  return pubKey;
}

void HandleCreateKeyPair(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  try {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (!args) throw std::runtime_error("Invalid arguments");
    auto it = args->find(flutter::EncodableValue("keyName"));
    if (it == args->end()) throw std::runtime_error("Missing keyName");

    std::wstring keyName = Utf8ToWide(std::get<std::string>(it->second));
    auto pubKey = CreateOrOpenKeyPair(keyName);
    result->Success(flutter::EncodableValue(pubKey));
  } catch (const std::exception& ex) {
    result->Error("CNG_ERROR", ex.what());
  }
}

// ---------- Signing ----------
static std::vector<uint8_t> SignWithKey(const std::wstring& keyName,
                                        const std::vector<uint8_t>& data) {
  NCRYPT_PROV_HANDLE hProvider = 0;
  NCRYPT_KEY_HANDLE hKey = 0;
  BCRYPT_ALG_HANDLE hAlgSha = nullptr;
  BCRYPT_HASH_HANDLE hHash = nullptr;

  try {
    SECURITY_STATUS status = NCryptOpenStorageProvider(&hProvider, MS_KEY_STORAGE_PROVIDER, 0);
    if (status != ERROR_SUCCESS) {
      throw std::runtime_error("NCryptOpenStorageProvider failed");
    }

    status = NCryptOpenKey(hProvider, &hKey, keyName.c_str(), 0, 0);
    if (status != ERROR_SUCCESS) {
      throw std::runtime_error("NCryptOpenKey failed - key not found");
    }

    status = BCryptOpenAlgorithmProvider(&hAlgSha, BCRYPT_SHA256_ALGORITHM, nullptr, 0);
    if (status != ERROR_SUCCESS) {
      throw std::runtime_error("BCryptOpenAlgorithmProvider (SHA256) failed");
    }

    // Query hash object/length
    DWORD hashObjLen = 0, hashLen = 0, cbData = 0;
    status = BCryptGetProperty(hAlgSha, BCRYPT_OBJECT_LENGTH,
                               reinterpret_cast<PUCHAR>(&hashObjLen), sizeof(DWORD), &cbData, 0);
    status = BCryptGetProperty(hAlgSha, BCRYPT_HASH_LENGTH,
                               reinterpret_cast<PUCHAR>(&hashLen), sizeof(DWORD), &cbData, 0);

    std::vector<uint8_t> hash(hashLen);
    std::vector<uint8_t> hashObj(hashObjLen);

    status = BCryptCreateHash(hAlgSha, &hHash, hashObj.data(), hashObjLen, nullptr, 0, 0);
    if (status != ERROR_SUCCESS) {
      throw std::runtime_error("BCryptCreateHash failed");
    }

    status = BCryptHashData(hHash, const_cast<PUCHAR>(data.data()),
                            static_cast<ULONG>(data.size()), 0);
    if (status != ERROR_SUCCESS) {
      throw std::runtime_error("BCryptHashData failed");
    }

    status = BCryptFinishHash(hHash, hash.data(), hashLen, 0);
    if (status != ERROR_SUCCESS) {
      throw std::runtime_error("BCryptFinishHash failed");
    }

    BCRYPT_PKCS1_PADDING_INFO paddingInfo;
    paddingInfo.pszAlgId = BCRYPT_SHA256_ALGORITHM; // correct value

    // Query signature size
    DWORD sigLen = 0;
    status = NCryptSignHash(hKey, &paddingInfo, hash.data(), hashLen,
                            nullptr, 0, &sigLen, BCRYPT_PAD_PKCS1);
    if (status != ERROR_SUCCESS) {
      throw std::runtime_error("NCryptSignHash (size query) failed");
    }

    std::vector<uint8_t> signature(sigLen);

    // Perform signature
    status = NCryptSignHash(hKey, &paddingInfo, hash.data(), hashLen,
                            signature.data(), sigLen, &sigLen, BCRYPT_PAD_PKCS1);
    if (status != ERROR_SUCCESS) {
      throw std::runtime_error("NCryptSignHash failed");
    }

    signature.resize(sigLen);

    if (hHash) BCryptDestroyHash(hHash);
    if (hAlgSha) BCryptCloseAlgorithmProvider(hAlgSha, 0);
    if (hKey) NCryptFreeObject(hKey);
    if (hProvider) NCryptFreeObject(hProvider);

    return signature;
  } catch (...) {
    if (hHash) BCryptDestroyHash(hHash);
    if (hAlgSha) BCryptCloseAlgorithmProvider(hAlgSha, 0);
    if (hKey) NCryptFreeObject(hKey);
    if (hProvider) NCryptFreeObject(hProvider);
    throw;
  }
}

void HandleSignNonce(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  try {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (!args) throw std::runtime_error("Invalid arguments");

    auto keyIt = args->find(flutter::EncodableValue("keyName"));
    auto nonceIt = args->find(flutter::EncodableValue("nonce"));
    if (keyIt == args->end() || nonceIt == args->end())
      throw std::runtime_error("Missing arguments");

    std::wstring keyName = Utf8ToWide(std::get<std::string>(keyIt->second));
    std::vector<uint8_t> nonce = std::get<std::vector<uint8_t>>(nonceIt->second);

    auto signature = SignWithKey(keyName, nonce);
    result->Success(flutter::EncodableValue(signature));
  } catch (const std::exception& ex) {
    result->Error("CNG_ERROR", ex.what());
  }
}


// ---------- Plugin Boilerplate ----------
void FlutterNativeUtilsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "flutter_native_utils",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FlutterNativeUtilsPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FlutterNativeUtilsPlugin::FlutterNativeUtilsPlugin() {}
FlutterNativeUtilsPlugin::~FlutterNativeUtilsPlugin() {}

void FlutterNativeUtilsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  using Handler = std::function<void(
      const flutter::MethodCall<flutter::EncodableValue>&,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>)>;

  static const std::unordered_map<std::string, Handler> handlers = {
      {"RequestAppRestart", HandleRequestAppRestart},
      {"RequestHardwareInfo", HandleRequestHardwareInfo},
      {"CreateKeyPair", HandleCreateKeyPair},
      {"SignNonce", HandleSignNonce},
  };

  auto it = handlers.find(call.method_name());
  if (it != handlers.end()) {
    it->second(call, std::move(result));
  } else {
    result->NotImplemented();
  }
}

}  // namespace flutter_native_utils

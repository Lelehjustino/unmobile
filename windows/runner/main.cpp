#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <cstdlib>
#include <string>
#include <vector>

#include "flutter_window.h"
#include "utils.h"

static const wchar_t kSingleInstanceMutexName[] =
    L"UnRecepcao_SingleInstance_Mutex_v1";

static const wchar_t kWindowTitle[] =
    L"un_recepcao";

static bool BringExistingInstanceToFront() {
  HWND existingWindow = ::FindWindow(nullptr, kWindowTitle);

  if (existingWindow == nullptr) {
    return false;
  }

  // Se estiver minimizada, restaura.
  if (::IsIconic(existingWindow)) {
    ::ShowWindow(existingWindow, SW_RESTORE);
  }

  // Coloca na frente.
  ::ShowWindow(existingWindow, SW_SHOW);
  ::BringWindowToTop(existingWindow);
  ::SetForegroundWindow(existingWindow);

  return true;
}

int APIENTRY wWinMain(
    _In_ HINSTANCE instance,
    _In_opt_ HINSTANCE prev,
    _In_ wchar_t* command_line,
    _In_ int show_command) {

  // ============================================================
  // SINGLE INSTANCE
  // ============================================================

  HANDLE singleInstanceMutex = ::CreateMutexW(
      nullptr,
      TRUE,
      kSingleInstanceMutexName);

  if (singleInstanceMutex == nullptr) {
    return EXIT_FAILURE;
  }

  DWORD mutexError = ::GetLastError();

  // Já existe outra instância.
  if (mutexError == ERROR_ALREADY_EXISTS) {

    BringExistingInstanceToFront();

    ::CloseHandle(singleInstanceMutex);

    return EXIT_SUCCESS;
  }

  // ============================================================
  // PRIMEIRA INSTÂNCIA
  // ============================================================

  if (!::AttachConsole(ATTACH_PARENT_PROCESS) &&
      ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Inicializa COM.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(
      std::move(command_line_arguments));

  FlutterWindow window(project);

  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);

  if (!window.Create(
          kWindowTitle,
          origin,
          size)) {

    ::CloseHandle(singleInstanceMutex);
    ::CoUninitialize();

    return EXIT_FAILURE;
  }

  window.SetQuitOnClose(true);

  // ============================================================
  // LOOP PRINCIPAL
  // ============================================================

  ::MSG msg;

  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  // ============================================================
  // FINALIZAÇÃO
  // ============================================================

  ::CloseHandle(singleInstanceMutex);

  ::CoUninitialize();

  return EXIT_SUCCESS;
}
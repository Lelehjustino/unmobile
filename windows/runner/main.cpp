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

  // SINGLE INSTANCE

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

  // PRIMEIRA INSTÂNCIA

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

  // LOOP PRINCIPAL

  ::MSG msg;

  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  // FINALIZAÇÃO

  ::CloseHandle(singleInstanceMutex);

  ::CoUninitialize();

  return EXIT_SUCCESS;
}

/* #include <windows.h>

#include <string>
#include <vector>

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

#include "flutter_window.h"
#include "utils.h"

// Nome único do mutex — identifica a instância do aplicativo no SO.
static const wchar_t kSingleInstanceMutexName[] =
    L"UnRecepcao_SingleInstance_Mutex_v1";

// Título da janela — deve coincidir exatamente com o passado em window.Create().
static const wchar_t kWindowTitle[] = L"un_recepcao";

// Busca a janela existente e a traz para o foco/frente.
static bool BringExistingInstanceToFront() {
  HWND existingWindow = ::FindWindow(nullptr, kWindowTitle);
  if (existingWindow == nullptr) {
    return false;
  }

  // Se estiver minimizada, restaura para o estado normal.
  if (::IsIconic(existingWindow)) {
    ::ShowWindow(existingWindow, SW_RESTORE);
  }

  // Garante que a janela esteja visível e no topo.
  ::ShowWindow(existingWindow, SW_SHOW);
  ::BringWindowToTop(existingWindow);
  ::SetForegroundWindow(existingWindow);

  return true;
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t* command_line, _In_ int show_command) {
  // ── SINGLE INSTANCE CHECK ─────────────────────────────────────────────────
  // CreateMutexW cria (ou abre) um mutex nomeado global.
  // Se já existir (ERROR_ALREADY_EXISTS) → outra instância está rodando.
  HANDLE singleInstanceMutex = ::CreateMutexW(
      nullptr,                   // atributos de segurança padrão
      TRUE,                      // esta instância reivindica a posse inicial
      kSingleInstanceMutexName); // nome único do mutex

  if (singleInstanceMutex == nullptr) {
    // Falha total ao criar/abrir o mutex; não podemos prosseguir.
    return EXIT_FAILURE;
  }

  if (::GetLastError() == ERROR_ALREADY_EXISTS) {
    // Já existe outra instância rodando — traz para o foco e sai.
    BringExistingInstanceToFront();
    ::CloseHandle(singleInstanceMutex);
    return EXIT_SUCCESS;
  }

  // ── PRIMEIRA INSTÂNCIA ────────────────────────────────────────────────────
  // Anexa ao console do processo pai (ex: flutter run) ou cria um novo
  // console quando rodando sob o depurador.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Inicializa COM (necessário para plugins e bibliotecas que dependem dele).
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments = GetCommandLineArguments();
  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);

  if (!window.Create(kWindowTitle, origin, size)) {
    ::ReleaseMutex(singleInstanceMutex);
    ::CloseHandle(singleInstanceMutex);
    ::CoUninitialize();
    return EXIT_FAILURE;
  }

  window.SetQuitOnClose(true);

  // ── LOOP DE MENSAGENS ─────────────────────────────────────────────────────
  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  // ── FINALIZAÇÃO ───────────────────────────────────────────────────────────
  // Libera a posse do mutex antes de fechar o handle.
  // Isso permite que o app seja reaberto normalmente após fechar.
  ::ReleaseMutex(singleInstanceMutex);
  ::CloseHandle(singleInstanceMutex);

  ::CoUninitialize();
  return EXIT_SUCCESS;
} */
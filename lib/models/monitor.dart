import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Representação simples de um monitor físico.
class MonitorInfo {
  /// Handle do monitor (HMONITOR), retornado por [MonitorFromWindow] / [MonitorFromPoint].
  final int handle;

  /// Coordenada X da borda esquerda do monitor na área de trabalho virtual.
  final int left;

  /// Coordenada Y da borda superior do monitor na área de trabalho virtual.
  final int top;

  /// Largura em pixels do monitor.
  final int width;

  /// Altura em pixels do monitor.
  final int height;

  const MonitorInfo({
    required this.handle,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  @override
  String toString() =>
      'MonitorInfo(handle=$handle, left=$left, top=$top, ${width}x$height)';
}

// ─── Constantes Win32 que o pacote win32 pode não expor diretamente ────────

/// GetSystemMetrics(SM_CMONITORS): número de monitores de exibição.
const int SM_CMONITORS = 80;

/// GetSystemMetrics(SM_XVIRTUALSCREEN): coordenada X da tela virtual.
const int SM_XVIRTUALSCREEN = 76;

/// GetSystemMetrics(SM_YVIRTUALSCREEN): coordenada Y da tela virtual.
const int SM_YVIRTUALSCREEN = 77;

/// GetSystemMetrics(SM_CXVIRTUALSCREEN): largura total da tela virtual.
const int SM_CXVIRTUALSCREEN = 78;

/// GetSystemMetrics(SM_CYVIRTUALSCREEN): altura total da tela virtual.
const int SM_CYVIRTUALSCREEN = 79;

// ─── Enumeração de monitores sem callbacks ──────────────────────────────────

/// Retorna a lista de todos os monitores atualmente conectados.
///
/// Em vez de usar [EnumDisplayMonitors] (que requer um callback MONITORENUMPROC
/// e [Pointer.fromFunction]), esta função percorre a área de trabalho virtual
/// pixel a pixel (em passos de 1 px) usando [MonitorFromPoint] + [GetMonitorInfo]
/// e acumula handles únicos.
///
/// Complexidade: O(largura_virtual) no pior caso, mas na prática para
/// configurações com 2-4 monitores o laço termina muito rapidamente pois
/// cada novo handle é encontrado na borda esquerda de cada monitor.
List<MonitorInfo> enumerarMonitores() {
  // Quantos monitores o Windows reporta
  final totalMonitores = GetSystemMetrics(SM_CMONITORS);
  if (totalMonitores <= 0) return [];

  // Dimensões e origem da área de trabalho virtual
  final virtualLeft = GetSystemMetrics(SM_XVIRTUALSCREEN);
  final virtualTop = GetSystemMetrics(SM_YVIRTUALSCREEN);
  final virtualWidth = GetSystemMetrics(SM_CXVIRTUALSCREEN);
  final virtualHeight = GetSystemMetrics(SM_CYVIRTUALSCREEN);

  // Y central da área virtual — garante que o ponto está dentro de algum monitor
  final midY = virtualTop + virtualHeight ~/ 2;

  final Set<int> handlesSeen = {};
  final List<MonitorInfo> resultado = [];

  // Varre da esquerda para a direita com passo de 1 px.
  // Quando encontramos um handle novo, extraímos as informações desse monitor.
  // Paramos assim que tivermos encontrado todos os monitores esperados.
  for (int x = virtualLeft; x < virtualLeft + virtualWidth; x++) {
    if (resultado.length == totalMonitores) break;

    // MonitorFromPoint recebe uma struct POINT (win32 ^5)
    // MONITOR_DEFAULTTONULL = 0 → retorna 0 se o ponto não estiver em monitor
    final pPt = calloc<POINT>();
    pPt.ref.x = x;
    pPt.ref.y = midY;
    final hMon = MonitorFromPoint(pPt.ref, MONITOR_DEFAULTTONULL);
    calloc.free(pPt);

    if (hMon == 0) continue;
    if (handlesSeen.contains(hMon)) continue;

    handlesSeen.add(hMon);

    // Obtém as informações desse monitor
    final pInfo = calloc<MONITORINFO>();
    try {
      pInfo.ref.cbSize = sizeOf<MONITORINFO>();
      if (GetMonitorInfo(hMon, pInfo.cast()) != FALSE) {
        final rect = pInfo.ref.rcMonitor;
        resultado.add(MonitorInfo(
          handle: hMon,
          left: rect.left,
          top: rect.top,
          width: rect.right - rect.left,
          height: rect.bottom - rect.top,
        ));
        // Pula para a borda direita deste monitor para acelerar o laço
        x = rect.right - 1;
      }
    } finally {
      calloc.free(pInfo);
    }
  }

  return resultado;
}
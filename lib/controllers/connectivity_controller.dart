import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http; // Certifique-se de adicionar 'http' no seu pubspec.yaml
import 'package:shared_preferences/shared_preferences.dart';

/// ConnectivityController (Híbrido: Descoberta UDP + Watchdog HTTP)
class ConnectivityController extends GetxController with WidgetsBindingObserver {
  static ConnectivityController get to => Get.find<ConnectivityController>();

  // Constantes
  static const Duration _watchdogInterval = Duration(seconds: 15); // O cachorro vai checar o dono a cada 35 segundos.
  static const Duration _gracePeriod = Duration(seconds: 15); // Período de graça: 15 segundos de folga para não dar alarme falso.
  static const Duration _httpTimeout = Duration(seconds: 5); // Tempo limite para o C++ responder // Se o servidor demorar mais de 5 segundos para responder, o cachorro acha que ele morreu.
  static const String   _chaveEsperada = 'UnderControl Engine';
  static const int      _portaUDP = 30078;
  // Porta para assitir o c++
  static const int      _portaHTTP = 9035; // Ajuste se a porta HTTP do C++ for diferente

  // Estado reativo
  final RxBool connectionStatus = false.obs;
  final RxBool appEmBackground = false.obs;

  // Estado interno 
  Timer?  _watchdogTimer;
  Timer?  _graceTimer;
  bool    _rodandoWatchdog    = false; // Debounce do ciclo
  bool    _loadingPermitido   = true;  // false durante período de graça

  // Lifecycle do GetX 
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this); // O cachorro começa a espiar se o app vai ser minimizado.
    _iniciarWatchdog();
    // debugPrint('[Connectivity] Watchdog Híbrido (UDP + HTTP) iniciado.');
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _pararWatchdog();
    _graceTimer?.cancel();
    super.onClose();
  }

  // Lifecycle do app 
  @override
  // vendo se o usuario minimizou o app
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[Connectivity] Lifecycle: $state');
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        appEmBackground.value = true;
        _pararWatchdog();
        _cancelarGrace();
        break;
      case AppLifecycleState.resumed:
        appEmBackground.value = false;
        _iniciarPeriodoGrace();
        _iniciarWatchdog();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  // Controlando o Cronômetro Principal
  void _iniciarPeriodoGrace() {
    _loadingPermitido = false;
    _cancelarGrace();

    _graceTimer = Timer(_gracePeriod, () {
      _loadingPermitido = true;
      debugPrint('[Connectivity] Período de graça encerrado — monitoramento liberado.');
    });
  }

  void _cancelarGrace() {
    _graceTimer?.cancel(); // // Desliga o relógio de 35 segundos.
    _graceTimer = null;
    _loadingPermitido = true;
  }

  // Watchdog Loop
  void _iniciarWatchdog() {
    _pararWatchdog();
    _executarCicloWatchdog(); // Primeira execução imediata

    _watchdogTimer = Timer.periodic(_watchdogInterval, (_) {
      if (!_rodandoWatchdog && !appEmBackground.value) {
        _executarCicloWatchdog();
      }
    });
  }

  void _pararWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
  }

  /// O Coração do Watchdog: Descobre por UDP (se necessário) e valida por HTTP GET
  Future<void> _executarCicloWatchdog() async {
    if (_rodandoWatchdog) return;
    _rodandoWatchdog = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      String? ip = prefs.getString('servidor');

      // Nao usa UPD para controlar variavel
      // 1) Se não temos IP salvo ou se estávamos offline, tentamos redescobrir via UDP
      /* if (ip == null || ip.isEmpty || !connectionStatus.value) {
        debugPrint('[Watchdog] Buscando IP via UDP Broadcast...');
        final String? ipDescoberto = await discoverServer();
        
        if (ipDescoberto != null && ipDescoberto.isNotEmpty) {
          ip = ipDescoberto;
          if (prefs.getString('servidor') != ip) {
            await prefs.setString('servidor', ip);
            debugPrint('[Watchdog] Novo IP descoberto e salvo: $ip');
          }
        }
      }

      // Se mesmo após o UDP não encontramos nenhum IP, assumimos offline
      if (ip == null || ip.isEmpty) {
        _atualizarStatus(false);
        return;
      } */

      // 2) Validação via HTTP GET /health no servidor C++
      final url = Uri.parse('http://$ip:$_portaHTTP/health');
      debugPrint('[Watchdog][DIAG] ── Ciclo HTTP ─────────────────────────────────────');
      debugPrint('[Watchdog][DIAG] URL         : $url');
      debugPrint('[Watchdog][DIAG] Plataforma  : ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');

      final Stopwatch sw = Stopwatch()..start();
      final response = await http.get(url).timeout(_httpTimeout);
      sw.stop();

      // C++ precisa responder HTTP 200 OK
      final bool online = response.statusCode == 200;
      debugPrint('[Watchdog][DIAG] StatusCode  : ${response.statusCode} — ${sw.elapsedMilliseconds}ms — online=$online');
      _atualizarStatus(online);

    } on TimeoutException catch (e, st) {
      debugPrint('[Watchdog][DIAG] ⏱ TimeoutException: $e\n$st');
      _atualizarStatus(false);
    } on SocketException catch (e, st) {
      debugPrint('[Watchdog][DIAG] 🔌 SocketException: ${e.message} | osError=${e.osError} | code=${e.osError?.errorCode}');
      debugPrint('[Watchdog][DIAG] Stack: $st');
      _atualizarStatus(false);
    } catch (e, st) {
      // Qualquer outro erro de rede joga o status para offline
      debugPrint('[Watchdog][DIAG] ❌ Exceção inesperada (${e.runtimeType}): $e\n$st');
      _atualizarStatus(false);
    } finally {
      _rodandoWatchdog = false;
    }
  }

  void _atualizarStatus(bool novoStatus) {
    if (connectionStatus.value != novoStatus) {
      connectionStatus.value = novoStatus;
      debugPrint('[Watchdog] Status alterado → ${novoStatus ? "ONLINE" : "OFFLINE"}');
    }
  }

  // Descoberta de servidor via UDP (Mantido Original)
  static Future<String?> discoverServer() async {
    for (final bindAddr in [InternetAddress.anyIPv4, InternetAddress.anyIPv6]) {
      RawDatagramSocket? socket;
      try {
        socket = await RawDatagramSocket.bind(
          bindAddr,
          _portaUDP,
          reuseAddress: true,
          reusePort: true,
        ).timeout(const Duration(seconds: 3));

        socket.broadcastEnabled = true;

        await for (final event in socket.timeout(const Duration(seconds: 12))) {
          if (event != RawSocketEvent.read) continue;

          final datagram = socket.receive();
          if (datagram == null) continue;

          final msg = utf8.decode(datagram.data, allowMalformed: true).trim();

          if (!msg.contains(_chaveEsperada)) continue;

          String ip = '';
          final partes = msg.split('|');
          if (partes.length >= 2) ip = partes[1].trim();

          if (ip.isEmpty || ip.split('.').length < 3) {
            ip = datagram.address.address;
          }

          if (ip.isNotEmpty) {
            // Fechamos o rádio imediatamente para liberar a porta do sistema
            socket.close();

            // --- AQUI ESTÁ O SALVAMENTO CORRIGIDO ---
            final prefs = await SharedPreferences.getInstance();
            final String? ipAntigo = prefs.getString('servidor');

            // Se o IP que descobrimos agora for diferente do que estava guardado antes
            if (ipAntigo != ip) {
              await prefs.setString('servidor', ip); // Salva o novo IP direto
              debugPrint(' Novo IP descoberto e salvo no SharedPreferences: $ip');
            }
            // ----------------------------------------

            return ip; // Devolve o IP para quem chamou a função
          }
        }
      } on SocketException {
        // Ignora falhas de bind para tentar o próximo protocolo
      } on TimeoutException {
        // Sem resposta neste protocolo dentro do timeout
      } catch (e) {
        debugPrint('[discoverServer] Erro: $e');
      } finally {
        socket?.close();
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
    return null;
  }
  /* static Future<String?> discoverServer() async {
    for (final bindAddr in [InternetAddress.anyIPv4, InternetAddress.anyIPv6]) {
      RawDatagramSocket? socket;
      try {
        socket = await RawDatagramSocket.bind(
          bindAddr,
          _portaUDP,
          reuseAddress: true,
          reusePort: true,
        ).timeout(const Duration(seconds: 3));

        socket.broadcastEnabled = true;

        await for (final event in socket.timeout(const Duration(seconds: 12))) {
          if (event != RawSocketEvent.read) continue;

          final datagram = socket.receive();
          if (datagram == null) continue;

          final msg = utf8.decode(datagram.data, allowMalformed: true).trim();

          if (!msg.contains(_chaveEsperada)) continue;

          String ip = '';
          final partes = msg.split('|');
          if (partes.length >= 2) ip = partes[1].trim();

          if (ip.isEmpty || ip.split('.').length < 3) {
            ip = datagram.address.address;
          }

          if (ip.isNotEmpty) {
            socket.close();

            final prefs = await SharedPreferences.getInstance();
            String? ipVar = prefs.getString('servidor');
            ipVar = ip;
            if (prefs.getString('servidor') != ipVar) {
              await prefs.setString('servidor', ipVar);
              debugPrint(' Novo IP descoberto e salvo: $ipVar');
            }
            return ip;
          }
        }
      } on SocketException {
        // Ignora falhas de bind para tentar o próximo protocolo
      } on TimeoutException {
        // Sem resposta neste protocolo dentro do timeout
      } catch (e) {
        debugPrint('[discoverServer] Erro: $e');
      } finally {
        socket?.close();
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
    return null;
  } */

  // Conexao pública
  bool get isOnline => connectionStatus.value;

  Future<void> verificarAgora() async {
    await _executarCicloWatchdog();
  }
}

/* import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ConnectivityController
///
/// Responsabilidades:
/// - Monitorar disponibilidade do servidor EXCLUSIVAMENTE via UDP broadcast
/// - Atualizar [connectionStatus] com o resultado do UDP
/// - Implementar período de graça de 15s após o app voltar do background
/// - Controlar exibição do loading de reconexão
/// - Gerenciar lifecycle (paused/resumed) sem memory leaks
///
/// NÃO abre, NÃO mantém e NÃO monitora conexão MySQL.
/// A conexão MySQL é aberta sob demanda em [Connection] apenas para queries.
class ConnectivityController extends GetxController with WidgetsBindingObserver {
  // Singleton helper 
  static ConnectivityController get to => Get.find<ConnectivityController>();

  // Constantes

  static const Duration _udpInterval     = Duration(seconds: 35);
  static const Duration _gracePeriod     = Duration(seconds: 15);
  static const String   _chaveEsperada   = 'UnderControl Engine';
  static const int      _portaUDP        = 30078;
  static const String   _loadingRoute    = 'loading_reconnect_dialog';

  // Estado reativo

  /// true = servidor alcançável via UDP, false = offline.
  /// Controlado EXCLUSIVAMENTE pelo resultado do UDP.
  final RxBool connectionStatus = false.obs;

  /// true = app está em background (paused/inactive/hidden)
  final RxBool appEmBackground = false.obs;

  // Estado interno 

  Timer?  _udpTimer;
  Timer?  _graciaTimer;
  bool    _rodandoUDP         = false;    // debounce: um ciclo UDP por vez
  bool    _exibindoLoading    = false;
  bool    _loadingPermitido   = true;     // false durante período de graça

  // Lifecycle do GetX 

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _iniciarMonitoramentoUDP();
    debugPrint('[Connectivity] Controller iniciado — monitoramento UDP ativo.');
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _pararMonitoramentoUDP();
    _graciaTimer?.cancel();
    super.onClose();
  }

  // Lifecycle do app ─

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[Connectivity] Lifecycle: $state');
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _appFoiParaBackground();
        break;
      case AppLifecycleState.resumed:
        _appVoltouDoBackground();
        break;
      case AppLifecycleState.detached:
        debugPrint('[Connectivity] Detached — ignorado.');
        break;
    }
  }

  void _appFoiParaBackground() {
    appEmBackground.value = true;
    // Pausa o UDP enquanto em background para economizar bateria/recursos
    _pararMonitoramentoUDP();
    // Cancela graça ativa para não vazar timers entre sessões
    _cancelarGracia();
    debugPrint('[Connectivity] Background → UDP pausado.');
  }

  void _appVoltouDoBackground() {
    appEmBackground.value = false;
    // 1) Ativa período de graça: loading PROIBIDO por 15s
    _iniciarPeriodoGracia();
    // 2) Retoma UDP imediatamente para verificar disponibilidade
    _iniciarMonitoramentoUDP();
    debugPrint('[Connectivity] Resumed → graça 15s + UDP retomado.');
  }

  // Período de graça 

  void _iniciarPeriodoGracia() {
    _loadingPermitido = false;   // bloqueia loading durante graça
    _cancelarGracia();           // garante timer único

    _graciaTimer = Timer(_gracePeriod, () {
      _loadingPermitido = true;
      debugPrint('[Connectivity] Período de graça 15s encerrado — loading liberado.');
    });

    debugPrint('[Connectivity] Período de graça iniciado (15s).');
  }

  void _cancelarGracia() {
    _graciaTimer?.cancel();
    _graciaTimer      = null;
    _loadingPermitido = true;
  }

  // Monitoramento UDP 

  /// Inicia o timer periódico de descoberta UDP.
  /// Garante que não existam múltiplos timers ativos.
  void _iniciarMonitoramentoUDP() {
    _pararMonitoramentoUDP(); // cancela timer anterior antes de criar novo
    _executarCicloUDP();      // primeira execução imediata

    _udpTimer = Timer.periodic(_udpInterval, (_) {
      if (!_rodandoUDP && !appEmBackground.value) {
        _executarCicloUDP();
      }
    });
  }

  void _pararMonitoramentoUDP() {
    _udpTimer?.cancel();
    _udpTimer = null;
  }

  /// Executa um ciclo de descoberta UDP e atualiza [connectionStatus].
  Future<void> _executarCicloUDP() async {
    if (_rodandoUDP) return;
    _rodandoUDP = true;

    try {
      final String? ip = await discoverServer();
      final bool online = ip != null;

      // Persiste o IP descoberto para uso na conexão MySQL
      if (online && ip.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final ipSalvo = prefs.getString('servidor');
        if (ipSalvo != ip) {
          await prefs.setString('servidor', ip);
          debugPrint('[Connectivity] Servidor atualizado via UDP: $ip');
        }
      }

      // Atualiza status APENAS com base no UDP
      final bool mudou = connectionStatus.value != online;
      connectionStatus.value = online;

      if (mudou) {
        debugPrint('[Connectivity] Status alterado → ${online ? "ONLINE" : "OFFLINE"}');
        if (online) {
          // Voltou online → fecha loading se estava aberto
          _fecharLoading();
        }
      }
    } finally {
      _rodandoUDP = false;
    }
  }

  // Descoberta de servidor via UDP

  /// Escuta broadcasts UDP por até 12s, tentando IPv4 primeiro (compatível iOS).
  /// Retorna o IP do servidor ou null se não encontrado.
  ///
  /// Correções iOS:
  /// - reusePort: true evita EADDRINUSE em ciclos consecutivos no iOS
  /// - broadcastEnabled definido ANTES do await for
  /// - Tenta IPv4 → IPv6 em sequência, fechando sempre antes de tentar próximo
  /// - Timeout aumentado para 12s (iOS tem latência extra no mDNSResponder)
  static Future<String?> discoverServer() async {
    // debugPrint('[discoverServer] Iniciando busca UDP...');

    // iOS: tentamos apenas IPv4 primeiro; IPv6 como fallback.
    // Fazer bind duplo simultâneo na mesma porta causa conflito silencioso no iOS.
    for (final bindAddr in [InternetAddress.anyIPv4, InternetAddress.anyIPv6]) {
      RawDatagramSocket? socket;
      try {
        socket = await RawDatagramSocket.bind(
          bindAddr,
          _portaUDP,
          reuseAddress: true,
          // iOS: sem reusePort, o segundo bind falha com EADDRINUSE
          // após o primeiro ciclo fechar o socket (o kernel ainda tem a porta
          // em TIME_WAIT por alguns ms).
          reusePort: true,
        ).timeout(const Duration(seconds: 3));

        // broadcastEnabled deve ser definido ANTES de iniciar a escuta
        socket.broadcastEnabled = true;
        // debugPrint('[discoverServer] Escutando UDP em ${bindAddr.address}...');

        // iOS usa 12s: mDNSResponder pode demorar mais após retorno do background
        await for (final event in socket.timeout(const Duration(seconds: 12))) {
          if (event != RawSocketEvent.read) continue;

          final datagram = socket.receive();
          if (datagram == null) continue;

          final msg = utf8.decode(datagram.data, allowMalformed: true).trim();
          //debugPrint('[discoverServer] Recebido de ${datagram.address.address}: "$msg"');

          if (!msg.contains(_chaveEsperada)) continue;

          String ip = '';
          final partes = msg.split('|');
          if (partes.length >= 2) ip = partes[1].trim();

          // Fallback: usa IP de origem se payload estiver vazio/inválido
          if (ip.isEmpty || ip.split('.').length < 3) {
            ip = datagram.address.address;
            // debugPrint('[discoverServer] Usando IP de origem como fallback: $ip');
          }

          if (ip.isNotEmpty) {
            debugPrint('[discoverServer] Servidor localizado: $ip');
            socket.close();
            return ip;
          }
        }
      } on SocketException catch (e) {
        // debugPrint('[discoverServer] SocketException (${bindAddr.address}): ${e.message}');
        // Se IPv4 falhar com EADDRINUSE, vale tentar IPv6 no próximo loop
      } on TimeoutException {
        // debugPrint('[discoverServer] Timeout (${bindAddr.address}) — sem resposta em 12s.');
      } catch (e) {
        // debugPrint('[discoverServer] Erro (${bindAddr.address}): $e');
      } finally {
        // Garante fechamento antes de tentar próximo endereço
        socket?.close();
        socket = null;
        // Pequena pausa para o kernel liberar a porta no iOS
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    // debugPrint('[discoverServer] Servidor não encontrado.');
    return null;
  }

  // Loading de reconexão─

  static const Set<String> _rotasBloqueadas = {'/inicial', '/configuracoes', '/splash'};

  bool get _rotaBloqueada => _rotasBloqueadas.contains(Get.currentRoute);

  /// Exibe o loading de reconexão.
  ///
  /// USO EXTERNO OPCIONAL: pode ser chamado por views que queiram exibir
  /// um loading quando o UDP indicar offline (ex.: ação manual do usuário).
  ///
  /// NÃO é chamado automaticamente por queries — queries são independentes do UDP.
  /// NÃO aparece durante o período de graça de 15s após o app voltar.
  /// NÃO aparece em rotas de configuração/splash.
  /* void mostrarLoading() {
    if (!_loadingPermitido)  return; // dentro da graça: proibido
    if (_exibindoLoading && (Get.isDialogOpen ?? false)) return; // já visível
    if (_rotaBloqueada)      return; // rota proibida
    if (connectionStatus.value) return; // voltou online antes do frame

    _exibindoLoading = true;

    void show() {
      if (!_exibindoLoading)           return;
      if (Get.isDialogOpen ?? false)   return;
      if (_rotaBloqueada)              { _exibindoLoading = false; return; }
      if (connectionStatus.value)      { _exibindoLoading = false; return; }

      Get.dialog(
        PopScope(
          canPop: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 15),
                const Material(
                  color: Colors.transparent,
                  child: Text(
                    'Reconectando ao servidor...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                IconButton(
                  onPressed: () async {
                    // Força um ciclo UDP imediato ao clicar em retry
                    await ConnectivityController.to._executarCicloUDP();
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
        routeSettings: const RouteSettings(name: _loadingRoute),
      );
    }

    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      show();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) => show());
    }
  } */

  void _fecharLoading() {
    if (!_exibindoLoading) return;
    if (Get.isDialogOpen ?? false) Get.back();
    _exibindoLoading = false;
  }

  // API pública

  /// Retorna true se o servidor está online (baseado no último ciclo UDP).
  bool get isOnline => connectionStatus.value;

  /// Força um ciclo UDP imediato (ex.: ao salvar configurações).
  Future<void> verificarAgora() async {
    await _executarCicloUDP();
  }
}
 */
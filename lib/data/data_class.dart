import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:un_recepcao/controllers/connectivity_controller.dart';
class _DbReconexao {
  _DbReconexao._(); // Não instanciável — API 100% estática.

  // Rotas onde o dialog NÃO deve aparecer
  static const Set<String> _rotasBloqueadas = {'/inicial', '/configuracoes', '/splash', '/expedicao_motoboy', '/painel_cliente', '/painel_cozinha'};

  // Nome de rota do dialog (para identificação interna do GetX) 
  static const String _nomeRota = 'db_reconnect_dialog';

  // Estado interno — completamente isolado do UDP 
  static bool _exibindo = false;
  static bool _retentativaImediata = false;

  // Helpers 

  static bool get _rotaBloqueada =>
      _rotasBloqueadas.contains(Get.currentRoute);

  // API pública 

  /// Exibe o dialog de reconexão de banco.
  /// Seguro chamar múltiplas vezes — ignora se já estiver visível.
  /// Respeita as [_rotasBloqueadas] internamente, sem consultar UDP.
  static void mostrar() {
    if (_exibindo && (Get.isDialogOpen ?? false)) return;
    if (_rotaBloqueada) return;

    _exibindo = true;
    _retentativaImediata = false;

    // Garante exibição fora de qualquer frame em construção
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      _exibir();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) => _exibir());
    }
  }

  /// Fecha o dialog de reconexão de banco.
  ///
  /// Seguro chamar mesmo se o dialog não estiver visível.
  /// Usa o nome da rota para fechar APENAS o seu próprio dialog,
  /// sem afetar outros dialogs na pilha do GetX.
  static void fechar() {
    if (!_exibindo) return;
    _exibindo = false;
    _retentativaImediata = false;
    if (Get.isDialogOpen ?? false) {
      // Fecha somente se o dialog ativo for o nosso (pelo nome da rota)
      if (Get.rawRoute?.settings.name == _nomeRota) {
        Get.back();
      }
    }
  }

  /// Retorna true se o usuário pressionou "tentar novamente",
  /// consumindo o flag para que seja processado apenas uma vez.
  static bool consumirRetentativa() {
    if (!_retentativaImediata) return false;
    _retentativaImediata = false;
    return true;
  }

  // ─── Construção do dialog ─────────────────────────────────────────────────

  static void _exibir() {
    if (!_exibindo) return;
    if (Get.isDialogOpen ?? false) return;
    if (_rotaBloqueada) {
      _exibindo = false;
      return;
    }

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
              // Botão de retentativa imediata — seta flag sem fechar o dialog.
              // O loop de polling em _executarQuery detecta o flag e retenta.
              IconButton(
                onPressed: () => _retentativaImediata = true,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
      routeSettings: const RouteSettings(name: _nomeRota),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Connection — Data Class principal
// ══════════════════════════════════════════════════════════════════════════════
class Connection {
  // ─── IPs de ambiente de teste ─────────────────────────────────────────────
  static const String _ipTeste  = '192.192.192.192';
  static const String _ipTeste2 = '192192192192';

  // ─── API de compatibilidade com código legado ─────────────────────────────
  //
  // Toda a API pública original é mantida para não quebrar views existentes.
  // O connectionStatus delega ao ConnectivityController (UDP) — apenas visual.

  /// Status UDP observável — APENAS para uso visual na UI (AppBar, ícone, etc).
  /// NÃO use para condicionar queries ou abertura de conexão.
  static RxBool get connectionStatus {
    try {
      return ConnectivityController.to.connectionStatus;
    } catch (_) {
      return false.obs;
    }
  }

  /// ValueNotifier legado para widgets sem GetX.
  static ValueNotifier<bool> isConnected      = ValueNotifier(false);
  static ValueNotifier<bool> voltouAoApp      = ValueNotifier(false);
  static ValueNotifier<bool> zerarAtendimento = ValueNotifier(false);
  static ValueNotifier<bool> navigationLocked = ValueNotifier(false);
  static bool get bloquearNavegacao => navigationLocked.value;

  static void initLifecycleObserver() {
  }

  static Future<bool> conectarBanco() async {
    final prefs = await SharedPreferences.getInstance();
    final servidor = prefs.getString('servidor');
    if (servidor == null || servidor.isEmpty) return false;
    return await _testarConexaoMySQL(servidor);
  }

  /// Verifica disponibilidade real do servidor, resetando estado de "voltou ao app".
  /// Abre MySQL real — independente do UDP.
  static Future<bool> conectarBanconoSalvar() async {
    voltouAoApp.value = false;
    final prefs = await SharedPreferences.getInstance();
    final servidor = prefs.getString('servidor');
    if (servidor == null || servidor.isEmpty) return false;
    return await _testarConexaoMySQL(servidor);
  }

  static Future<bool> conexaoRealmenteCaiu() async {
    final prefs = await SharedPreferences.getInstance();
    final servidor = prefs.getString('servidor');
    if (servidor == null || servidor.isEmpty) return true;
    final ok = await _testarConexaoMySQL(servidor);
    return !ok;
  }

  static Future<bool> _testarConexaoMySQL(String host) async {
    MySQLConnection? conn;
    try {
      conn = await _abrirConexao(host);
      if (conn == null) return false;
      await conn.execute('SELECT 1').timeout(const Duration(seconds: 3));
      return true;
    } catch (_) {
      return false;
    } finally {
      await _fecharConexao(conn);
    }
  }

  /// SELECT: abre conexão → executa → fecha.
  Future<String> select(String sql) async {
    return await _executarQuery<String>(
      executor: (conn) async {
        final result = await conn.execute(sql);
        return jsonEncode(result.rows.map((r) => r.assoc()).toList());
      },
      fallback: '[]',
    );
  }

  /// INSERT / UPDATE / DELETE: abre conexão → executa → fecha.
  Future<String> ipd(String sql) async {
    return await _executarQuery<String>(
      executor: (conn) async {
        await conn.execute(sql);
        return 'sucesso';
      },
      fallback: 'erro',
    );
  }

  // Insert que retorna o id gerado
  Future<String> insertId(String sql) async {
    return await _executarQuery<String>(
      executor: (conn) async {
        final result = await conn.execute(sql);
        return result.lastInsertID.toString();
      },
      fallback: "0",
    );
  }

  /// Múltiplas queries em transação atômica: abre → executa → fecha.
  Future<String> transaction(List<String> queries) async {
    return await _executarQuery<String>(
      executor: (conn) async {
        await conn.transactional((ctx) async {
          for (final sql in queries) {
            if (sql.trim().isNotEmpty) await ctx.execute(sql);
          }
        });
        return 'sucesso';
      },
      fallback: 'erro',
    );
  }

  /// Alias mantido para compatibilidade.
  Future<String> safeQuery(List<String> queries) => transaction(queries);

  Future<T> _executarQuery<T>({
    required Future<T> Function(MySQLConnection conn) executor,
    required T fallback,
  }) async {
    // Intervalo padrão entre tentativas de reconexão (polling MySQL real)
    const maxTentativas = 60; // 60 × 5s ≈ 5 minutos

    MySQLConnection? conn;

    // ── 1. Obtém o IP do servidor ────────────────────────────────────────────
    final prefs    = await SharedPreferences.getInstance();
    final servidor = prefs.getString('servidor');

    if (servidor == null || servidor.isEmpty) {
      // debugPrint('[MySQL] Sem IP configurado — retornando fallback.');
      return fallback;
    }

    // ── 2. Primeira tentativa de conexão MySQL ───────────────────────────────
    // debugPrint('[MySQL] Tentando conectar em $servidor...');
    conn = await _abrirConexao(servidor);

    if (conn != null) {
      // Conexão ok → executa normalmente.
      try {
        final result = await executor(conn);
        // debugPrint('[MySQL] Query executada com sucesso.');
        return result;
      } catch (e) {
        // debugPrint('[MySQL] Erro ao executar query: $e');
        return fallback;
      } finally {
        await _fecharConexao(conn);
      }
    }

    // ── 3. Falha → aciona reconexão independente ─────────────────────────────
    // _DbReconexao não conhece UDP/HTTP; Watchdog não conhece _DbReconexao.
    // debugPrint('[MySQL] Conexão falhou — iniciando loop de reconexão...');
    _DbReconexao.mostrar();

    // ── 4. Loop de polling MySQL ─────────────────────────────────────────────
    for (int tentativa = 1; tentativa <= maxTentativas; tentativa++) {
      // debugPrint('[MySQL] Tentativa de reconexão $tentativa/$maxTentativas...');
      // Aguarda o intervalo padrão, mas permite retentativa imediata pelo botão.
      // Divide em fatias de 100ms para checar o flag sem bloquear agendamentos.
      for (int ms = 0; ms < 50; ms++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_DbReconexao.consumirRetentativa()) break; // botão pressionado
      }

      // Usa sempre o IP mais recente (pode ter sido atualizado por outros meios).
      final prefsNow     = await SharedPreferences.getInstance();
      final servidorNow  = prefsNow.getString('servidor') ?? servidor;

      conn = await _abrirConexao(servidorNow);

      if (conn != null) {
        // ── 5. Reconexão bem-sucedida ─────────────────────────────────────────
        // debugPrint('[MySQL] Reconexão bem-sucedida na tentativa $tentativa.');
        _DbReconexao.fechar();
        try {
          final result = await executor(conn);
          // debugPrint('[MySQL] Query executada com sucesso após reconexão.');
          return result;
        } catch (e) {
          // debugPrint('[MySQL] Erro ao executar query após reconexão: $e');
          return fallback;
        } finally {
          await _fecharConexao(conn);
        }
      }
    }

    // ── 6. Esgotou tentativas — retorna fallback silenciosamente ─────────────
    // debugPrint('[MySQL] Esgotou $maxTentativas tentativas — retornando fallback.');
    // O dialog permanece aberto para o usuário agir manualmente.
    return fallback;
  }

  // ─── Abertura/fechamento de conexão MySQL ─────────────────────────────────

  static Future<MySQLConnection?> _abrirConexao(String host) async {
    try {
      if (host == _ipTeste || host == _ipTeste2) {
        return await _abrirConexaoTeste();
      } else {
        return await _abrirConexaoProducao(host);
      }
    } catch (e, st) {
      // debugPrint('[MySQL][_abrirConexao] Exceção inesperada para $host: $e\n$st');
      return null;
    }
  }

  static Future<MySQLConnection?> _abrirConexaoProducao(String host) async {
    final int porta = int.parse(dotenv.get('DB_PORT', fallback: '3306'));
    final Stopwatch sw = Stopwatch()..start();

    // debugPrint('[MySQL][DIAG] ── Iniciando conexão ──────────────────────────');
    // debugPrint('[MySQL][DIAG] Host configurado : $host:$porta');
    // debugPrint('[MySQL][DIAG] Plataforma       : ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');

    // ── Resolução de DNS / IPv4 forçado ─────────────────────────────────────
    // iOS 17+ (iPhone 15 Pro Max / A17) prefere IPv6 (Happy Eyeballs).
    // O servidor MySQL responde apenas em IPv4 → forçamos a resolução aqui
    // para garantir que o socket abra em IPv4, evitando timeout silencioso.
    String ipResolvido = host;
    try {
      final List<InternetAddress> enderecos = await InternetAddress.lookup(
        host,
        type: InternetAddressType.IPv4, // força IPv4
      ).timeout(const Duration(seconds: 5));

      if (enderecos.isNotEmpty) {
        ipResolvido = enderecos.first.address;
        // debugPrint('[MySQL][DIAG] IP resolvido (IPv4): $ipResolvido');
      } else {
        // debugPrint('[MySQL][DIAG] Lookup IPv4 retornou lista vazia — usando host original.');
      }
    } on SocketException catch (e) {
      // debugPrint('[MySQL][DIAG] Falha no lookup IPv4 (${e.osError?.errorCode}): ${e.message}');
      // Se o lookup falhar (ex.: host já é IP puro), segue com o host original
    } on TimeoutException {
      // debugPrint('[MySQL][DIAG] Timeout no lookup DNS — usando host original.');
    } catch (e) {
      // debugPrint('[MySQL][DIAG] Erro no lookup: $e — usando host original.');
    }

    // debugPrint('[MySQL][DIAG] Abrindo socket TCP para $ipResolvido:$porta ...');

    try {
      final conn = await MySQLConnection.createConnection(
        host: ipResolvido,
        port: porta,
        userName: dotenv.get('DB_USER', fallback: 'root'),
        password: dotenv.get('DB_PASSWORD', fallback: ''),
        databaseName: dotenv.get('DB_NAME', fallback: 'undercontrol'),
        secure: false,
      ).timeout(
        // iOS: primeiro acesso TCP após suspensão passa por validação ATS +
        // NetworkExtension handshake. 8s era insuficiente — 16s dá margem segura.
        const Duration(seconds: 16),
        onTimeout: () => throw TimeoutException('createConnection timeout (16s)'),
      );

      // debugPrint('[MySQL][DIAG] createConnection OK — ${sw.elapsedMilliseconds}ms — autenticando...');

      await conn.connect().timeout(
        // iOS pode demorar até 12s no MySQL auth após retorno do background
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('connect() timeout (15s)'),
      );

      sw.stop();
      // debugPrint('[MySQL][DIAG] Conexão estabelecida com sucesso em ${sw.elapsedMilliseconds}ms.');
      return conn;
    } on TimeoutException catch (e, st) {
      sw.stop();
      // debugPrint('[MySQL][DIAG] ⏱ TimeoutException em ${sw.elapsedMilliseconds}ms: $e');
      // debugPrint('[MySQL][DIAG] Stack: $st');
      return null;
    } on SocketException catch (e, st) {
      sw.stop();
      // debugPrint('[MySQL][DIAG] 🔌 SocketException em ${sw.elapsedMilliseconds}ms');
      // debugPrint('[MySQL][DIAG]    mensagem  : ${e.message}');
      // debugPrint('[MySQL][DIAG]    osError   : ${e.osError}');
      // debugPrint('[MySQL][DIAG]    errorCode : ${e.osError?.errorCode}');
      // debugPrint('[MySQL][DIAG]    address   : ${e.address}');
      // debugPrint('[MySQL][DIAG]    port      : ${e.port}');
      // debugPrint('[MySQL][DIAG] Stack: $st');
      return null;
    } catch (e, st) {
      sw.stop();
      // debugPrint('[MySQL][DIAG] ❌ Exceção desconhecida em ${sw.elapsedMilliseconds}ms');
      // debugPrint('[MySQL][DIAG]    tipo : ${e.runtimeType}');
      // debugPrint('[MySQL][DIAG]    erro : $e');
      // debugPrint('[MySQL][DIAG] Stack: $st');
      return null;
    }
  }

  static Future<MySQLConnection?> _abrirConexaoTeste() async {
    try {
      final conn = await MySQLConnection.createConnection(
        host: 'mysql.focusnetwork.com.br',
        port: int.parse(dotenv.get('DB_PORT_TESTE')),
        userName: dotenv.get('DB_USER_TESTE'),
        password: dotenv.get('DB_PASSWORD_TESTE'),
        databaseName: dotenv.get('DB_NAME_TESTE'),
        secure: false,
      );

      await conn.connect().timeout(const Duration(seconds: 20));
      return conn;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _fecharConexao(MySQLConnection? conn) async {
    if (conn == null) return;
    try {
      await conn.close();
    } catch (_) {
      // Seguro ignorar — conexão já pode estar encerrada.
    }
  }
}

/* import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:un_recepcao/controllers/connectivity_controller.dart';
class _DbReconexao {
  _DbReconexao._(); // Não instanciável — API 100% estática.

  // Rotas onde o dialog NÃO deve aparecer
  static const Set<String> _rotasBloqueadas = {'/inicial', '/configuracoes', '/splash', '/expedicao_motoboy', '/painel_cliente', '/painel_cozinha'};

  // Nome de rota do dialog (para identificação interna do GetX) 
  static const String _nomeRota = 'db_reconnect_dialog';

  // Estado interno — completamente isolado do UDP 
  static bool _exibindo = false;
  static bool _retentativaImediata = false;

  // Helpers 

  static bool get _rotaBloqueada =>
      _rotasBloqueadas.contains(Get.currentRoute);

  // API pública 

  /// Exibe o dialog de reconexão de banco.
  /// Seguro chamar múltiplas vezes — ignora se já estiver visível.
  /// Respeita as [_rotasBloqueadas] internamente, sem consultar UDP.
  static void mostrar() {
    if (_exibindo && (Get.isDialogOpen ?? false)) return;
    if (_rotaBloqueada) return;

    _exibindo = true;
    _retentativaImediata = false;

    // Garante exibição fora de qualquer frame em construção
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      _exibir();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) => _exibir());
    }
  }

  /// Fecha o dialog de reconexão de banco.
  ///
  /// Seguro chamar mesmo se o dialog não estiver visível.
  /// Usa o nome da rota para fechar APENAS o seu próprio dialog,
  /// sem afetar outros dialogs na pilha do GetX.
  static void fechar() {
    if (!_exibindo) return;
    _exibindo = false;
    _retentativaImediata = false;
    if (Get.isDialogOpen ?? false) {
      // Fecha somente se o dialog ativo for o nosso (pelo nome da rota)
      if (Get.rawRoute?.settings.name == _nomeRota) {
        Get.back();
      }
    }
  }

  /// Retorna true se o usuário pressionou "tentar novamente",
  /// consumindo o flag para que seja processado apenas uma vez.
  static bool consumirRetentativa() {
    if (!_retentativaImediata) return false;
    _retentativaImediata = false;
    return true;
  }

  // ─── Construção do dialog ─────────────────────────────────────────────────

  static void _exibir() {
    if (!_exibindo) return;
    if (Get.isDialogOpen ?? false) return;
    if (_rotaBloqueada) {
      _exibindo = false;
      return;
    }

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
              // Botão de retentativa imediata — seta flag sem fechar o dialog.
              // O loop de polling em _executarQuery detecta o flag e retenta.
              IconButton(
                onPressed: () => _retentativaImediata = true,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
      routeSettings: const RouteSettings(name: _nomeRota),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Connection — Data Class principal
// ══════════════════════════════════════════════════════════════════════════════
class Connection {
  // ─── IPs de ambiente de teste ─────────────────────────────────────────────
  static const String _ipTeste  = '192.192.192.192';
  static const String _ipTeste2 = '192192192192';

  // ─── API de compatibilidade com código legado ─────────────────────────────
  //
  // Toda a API pública original é mantida para não quebrar views existentes.
  // O connectionStatus delega ao ConnectivityController (UDP) — apenas visual.

  /// Status UDP observável — APENAS para uso visual na UI (AppBar, ícone, etc).
  /// NÃO use para condicionar queries ou abertura de conexão.
  static RxBool get connectionStatus {
    try {
      return ConnectivityController.to.connectionStatus;
    } catch (_) {
      return false.obs;
    }
  }

  /// ValueNotifier legado para widgets sem GetX.
  static ValueNotifier<bool> isConnected      = ValueNotifier(false);
  static ValueNotifier<bool> voltouAoApp      = ValueNotifier(false);
  static ValueNotifier<bool> zerarAtendimento = ValueNotifier(false);
  static ValueNotifier<bool> navigationLocked = ValueNotifier(false);
  static bool get bloquearNavegacao => navigationLocked.value;

  static void initLifecycleObserver() {
  }

  static Future<bool> conectarBanco() async {
    final prefs = await SharedPreferences.getInstance();
    final servidor = prefs.getString('servidor');
    if (servidor == null || servidor.isEmpty) return false;
    return await _testarConexaoMySQL(servidor);
  }

  /// Verifica disponibilidade real do servidor, resetando estado de "voltou ao app".
  /// Abre MySQL real — independente do UDP.
  static Future<bool> conectarBanconoSalvar() async {
    voltouAoApp.value = false;
    final prefs = await SharedPreferences.getInstance();
    final servidor = prefs.getString('servidor');
    if (servidor == null || servidor.isEmpty) return false;
    return await _testarConexaoMySQL(servidor);
  }

  static Future<bool> conexaoRealmenteCaiu() async {
    final prefs = await SharedPreferences.getInstance();
    final servidor = prefs.getString('servidor');
    if (servidor == null || servidor.isEmpty) return true;
    final ok = await _testarConexaoMySQL(servidor);
    return !ok;
  }

  static Future<bool> _testarConexaoMySQL(String host) async {
    MySQLConnection? conn;
    try {
      conn = await _abrirConexao(host);
      if (conn == null) return false;
      await conn.execute('SELECT 1').timeout(const Duration(seconds: 3));
      return true;
    } catch (_) {
      return false;
    } finally {
      await _fecharConexao(conn);
    }
  }

  /// SELECT: abre conexão → executa → fecha.
  Future<String> select(String sql) async {
    return await _executarQuery<String>(
      executor: (conn) async {
        final result = await conn.execute(sql);
        return jsonEncode(result.rows.map((r) => r.assoc()).toList());
      },
      fallback: '[]',
    );
  }

  /// INSERT / UPDATE / DELETE: abre conexão → executa → fecha.
  Future<String> ipd(String sql) async {
    return await _executarQuery<String>(
      executor: (conn) async {
        await conn.execute(sql);
        return 'sucesso';
      },
      fallback: 'erro',
    );
  }

  // Insert que retorna o id gerado
  Future<String> insertId(String sql) async {
    return await _executarQuery<String>(
      executor: (conn) async {
        final result = await conn.execute(sql);
        return result.lastInsertID.toString();
      },
      fallback: "0",
    );
  }

  /// Múltiplas queries em transação atômica: abre → executa → fecha.
  Future<String> transaction(List<String> queries) async {
    return await _executarQuery<String>(
      executor: (conn) async {
        await conn.transactional((ctx) async {
          for (final sql in queries) {
            if (sql.trim().isNotEmpty) await ctx.execute(sql);
          }
        });
        return 'sucesso';
      },
      fallback: 'erro',
    );
  }

  /// Alias mantido para compatibilidade.
  Future<String> safeQuery(List<String> queries) => transaction(queries);

  Future<T> _executarQuery<T>({
    required Future<T> Function(MySQLConnection conn) executor,
    required T fallback,
  }) async {
    // Intervalo padrão entre tentativas de reconexão (polling MySQL real)
    const maxTentativas = 60; // 60 × 5s ≈ 5 minutos

    MySQLConnection? conn;

    // ── 1. Obtém o IP do servidor ────────────────────────────────────────────
    final prefs    = await SharedPreferences.getInstance();
    final servidor = prefs.getString('servidor');

    if (servidor == null || servidor.isEmpty) {
      // debugPrint('[MySQL] Sem IP configurado — retornando fallback.');
      return fallback;
    }

    // ── 2. Primeira tentativa de conexão MySQL ───────────────────────────────
    // debugPrint('[MySQL] Tentando conectar em $servidor...');
    conn = await _abrirConexao(servidor);

    if (conn != null) {
      // Conexão ok → executa normalmente.
      try {
        final result = await executor(conn);
        // debugPrint('[MySQL] Query executada com sucesso.');
        return result;
      } catch (e) {
        // debugPrint('[MySQL] Erro ao executar query: $e');
        return fallback;
      } finally {
        await _fecharConexao(conn);
      }
    }

    // ── 3. Falha → aciona reconexão independente ─────────────────────────────
    // _DbReconexao não conhece UDP/HTTP; Watchdog não conhece _DbReconexao.
    // debugPrint('[MySQL] Conexão falhou — iniciando loop de reconexão...');
    _DbReconexao.mostrar();

    // ── 4. Loop de polling MySQL ─────────────────────────────────────────────
    for (int tentativa = 1; tentativa <= maxTentativas; tentativa++) {
      // debugPrint('[MySQL] Tentativa de reconexão $tentativa/$maxTentativas...');
      // Aguarda o intervalo padrão, mas permite retentativa imediata pelo botão.
      // Divide em fatias de 100ms para checar o flag sem bloquear agendamentos.
      for (int ms = 0; ms < 50; ms++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_DbReconexao.consumirRetentativa()) break; // botão pressionado
      }

      // Usa sempre o IP mais recente (pode ter sido atualizado por outros meios).
      final prefsNow     = await SharedPreferences.getInstance();
      final servidorNow  = prefsNow.getString('servidor') ?? servidor;

      conn = await _abrirConexao(servidorNow);

      if (conn != null) {
        // ── 5. Reconexão bem-sucedida ─────────────────────────────────────────
        // debugPrint('[MySQL] Reconexão bem-sucedida na tentativa $tentativa.');
        _DbReconexao.fechar();
        try {
          final result = await executor(conn);
          // debugPrint('[MySQL] Query executada com sucesso após reconexão.');
          return result;
        } catch (e) {
          // debugPrint('[MySQL] Erro ao executar query após reconexão: $e');
          return fallback;
        } finally {
          await _fecharConexao(conn);
        }
      }
    }

    // ── 6. Esgotou tentativas — retorna fallback silenciosamente ─────────────
    // debugPrint('[MySQL] Esgotou $maxTentativas tentativas — retornando fallback.');
    // O dialog permanece aberto para o usuário agir manualmente.
    return fallback;
  }

  // ─── Abertura/fechamento de conexão MySQL ─────────────────────────────────

  static Future<MySQLConnection?> _abrirConexao(String host) async {
    try {
      if (host == _ipTeste || host == _ipTeste2) {
        return await _abrirConexaoTeste();
      } else {
        return await _abrirConexaoProducao(host);
      }
    } catch (e, st) {
      debugPrint('[MySQL][_abrirConexao] Exceção inesperada para $host: $e\n$st');
      return null;
    }
  }

  static Future<MySQLConnection?> _abrirConexaoProducao(String host) async {
    final int porta = int.parse(dotenv.get('DB_PORT', fallback: '3306'));
    final Stopwatch sw = Stopwatch()..start();

    // debugPrint('[MySQL][DIAG] ── Iniciando conexão ──────────────────────────');
    // debugPrint('[MySQL][DIAG] Host configurado : $host:$porta');
    // debugPrint('[MySQL][DIAG] Plataforma       : ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');

    // ── Resolução de DNS / IPv4 forçado ─────────────────────────────────────
    // iOS 17+ (iPhone 15 Pro Max / A17) prefere IPv6 (Happy Eyeballs).
    // O servidor MySQL responde apenas em IPv4 → forçamos a resolução aqui
    // para garantir que o socket abra em IPv4, evitando timeout silencioso.
    String ipResolvido = host;
    try {
      final List<InternetAddress> enderecos = await InternetAddress.lookup(
        host,
        type: InternetAddressType.IPv4, // força IPv4
      ).timeout(const Duration(seconds: 5));

      if (enderecos.isNotEmpty) {
        ipResolvido = enderecos.first.address;
        // debugPrint('[MySQL][DIAG] IP resolvido (IPv4): $ipResolvido');
      } else {
        // debugPrint('[MySQL][DIAG] Lookup IPv4 retornou lista vazia — usando host original.');
      }
    } on SocketException catch (e) {
      // debugPrint('[MySQL][DIAG] Falha no lookup IPv4 (${e.osError?.errorCode}): ${e.message}');
      // Se o lookup falhar (ex.: host já é IP puro), segue com o host original
    } on TimeoutException {
      // debugPrint('[MySQL][DIAG] Timeout no lookup DNS — usando host original.');
    } catch (e) {
      // debugPrint('[MySQL][DIAG] Erro no lookup: $e — usando host original.');
    }

    // debugPrint('[MySQL][DIAG] Abrindo socket TCP para $ipResolvido:$porta ...');

    try {
      final conn = await MySQLConnection.createConnection(
        host: ipResolvido,
        port: porta,
        userName: dotenv.get('DB_USER', fallback: 'root'),
        password: dotenv.get('DB_PASSWORD', fallback: ''),
        databaseName: dotenv.get('DB_NAME', fallback: 'undercontrol'),
        secure: false,
      ).timeout(
        // iOS: primeiro acesso TCP após suspensão passa por validação ATS +
        // NetworkExtension handshake. 8s era insuficiente — 16s dá margem segura.
        const Duration(seconds: 16),
        onTimeout: () => throw TimeoutException('createConnection timeout (16s)'),
      );

      // debugPrint('[MySQL][DIAG] createConnection OK — ${sw.elapsedMilliseconds}ms — autenticando...');

      await conn.connect().timeout(
        // iOS pode demorar até 12s no MySQL auth após retorno do background
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('connect() timeout (15s)'),
      );

      sw.stop();
      // debugPrint('[MySQL][DIAG] Conexão estabelecida com sucesso em ${sw.elapsedMilliseconds}ms.');
      return conn;
    } on TimeoutException catch (e, st) {
      sw.stop();
      debugPrint('[MySQL][DIAG] ⏱ TimeoutException em ${sw.elapsedMilliseconds}ms: $e');
      debugPrint('[MySQL][DIAG] Stack: $st');
      return null;
    } on SocketException catch (e, st) {
      sw.stop();
      debugPrint('[MySQL][DIAG] 🔌 SocketException em ${sw.elapsedMilliseconds}ms');
      debugPrint('[MySQL][DIAG]    mensagem  : ${e.message}');
      debugPrint('[MySQL][DIAG]    osError   : ${e.osError}');
      debugPrint('[MySQL][DIAG]    errorCode : ${e.osError?.errorCode}');
      debugPrint('[MySQL][DIAG]    address   : ${e.address}');
      debugPrint('[MySQL][DIAG]    port      : ${e.port}');
      debugPrint('[MySQL][DIAG] Stack: $st');
      return null;
    } catch (e, st) {
      sw.stop();
      debugPrint('[MySQL][DIAG] ❌ Exceção desconhecida em ${sw.elapsedMilliseconds}ms');
      debugPrint('[MySQL][DIAG]    tipo : ${e.runtimeType}');
      debugPrint('[MySQL][DIAG]    erro : $e');
      debugPrint('[MySQL][DIAG] Stack: $st');
      return null;
    }
  }

  static Future<MySQLConnection?> _abrirConexaoTeste() async {
    try {
      final conn = await MySQLConnection.createConnection(
        host: 'mysql.focusnetwork.com.br',
        port: int.parse(dotenv.get('DB_PORT_TESTE')),
        userName: dotenv.get('DB_USER_TESTE'),
        password: dotenv.get('DB_PASSWORD_TESTE'),
        databaseName: dotenv.get('DB_NAME_TESTE'),
        secure: false,
      );

      await conn.connect().timeout(const Duration(seconds: 20));
      return conn;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _fecharConexao(MySQLConnection? conn) async {
    if (conn == null) return;
    try {
      await conn.close();
    } catch (_) {
      // Seguro ignorar — conexão já pode estar encerrada.
    }
  }
}
 */
import 'package:get/get.dart';

/// Status possíveis durante o fluxo de entrarAutomaticamente()
enum StatusConexao {
  idle,
  conectandoSalvo,
  descobrindoServidor,
  falhaConexao,
  carregandoDados,
  verificandoLicenca,
  pronto,
}

class InicialController extends GetxController {
  // ─── Estado reativo ───────────────────────────────────────────────────────

  /// Status atual do fluxo de conexão
  final Rx<StatusConexao> status = StatusConexao.idle.obs;

  /// Mensagem descritiva exibida na UI em tempo real
  final RxString mensagem = ''.obs;

  /// Se o fluxo está em execução (evita múltiplas chamadas simultâneas)
  final RxBool emExecucao = false.obs;

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Atualiza status e mensagem de uma vez
  void atualizar(StatusConexao novoStatus, String novaMensagem) {
    status.value = novoStatus;
    mensagem.value = novaMensagem;
  }

  /// Reseta o estado para idle
  void resetar() {
    status.value = StatusConexao.idle;
    mensagem.value = '';
    emExecucao.value = false;
  }
}

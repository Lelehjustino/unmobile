import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:un_recepcao/controllers/views/painel_controller.dart';

/// Serviço singleton responsável pela notificação sonora de pedidos novos.
///
/// Regras de negócio:
/// - O som toca **exatamente 1 vez** para cada pedido novo.
/// - O som toca **somente** quando `painelController.estaNoPainelCozinha.value == true`.
/// - IDs já notificados ficam em um [Set] estático que **nunca é limpo**
///   (exceto ao trocar de terminal, via [resetarIdsNotificados]).
/// - Múltiplas chamadas simultâneas são protegidas por um lock ([Completer]).
/// - Rebuilds, timers sobrepostos e navegação **não** disparam som repetido.
class ServicoNotificacao {
  // ─── Player singleton (nunca recriado) ───
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _configurado = false;

  // ─── Lock para evitar execuções simultâneas de tocar som ───
  static Completer<void>? _lockSom;

  // ─── IDs de pedidos que já tiveram notificação sonora ───
  // Persiste em memória durante toda a vida do app.
  static final Set<String> _idsJaNotificados = {};

  // ─── PainelController (lazy) ───
  static PainelController get _painelController => Get.find<PainelController>();

  /// Configura o contexto de áudio (chamado uma vez na vida do app).
  static Future<void> configurarAudio() async {
    if (_configurado) return;
    try {
      // Pré-carrega o asset para garantir que está acessível
      await rootBundle.load('assets/audio/plim.mp3');

      await _audioPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.notificationEvent,
          ),
        ),
      );
      _configurado = true;
    } catch (e) {
      print('[ServicoNotificacao] Erro ao configurar áudio: $e');
    }
  }

  /// Verifica se existem pedidos novos na lista e toca o som **uma única vez**
  /// se houver pelo menos 1 ID inédito.
  ///
  /// Deve ser chamado **toda vez** que a lista de pedidos em preparo for atualizada.
  /// Toda a lógica de comparação de IDs acontece **aqui**, antes de chamar play().
  static Future<void> verificarENotificar(List<dynamic> listaPedidosEmPreparo) async {
    // 1) Só notifica se estiver no painel da cozinha
    if (!_painelController.estaNoPainelCozinha.value) {
      return;
    }

    // 2) Extrai IDs únicos dos pedidos atuais
    final Set<String> idsAtuais = listaPedidosEmPreparo
        .map((p) => p['numeropedido']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    // 3) Identifica apenas IDs inéditos (nunca notificados antes)
    final Set<String> idsIneditos = idsAtuais.difference(_idsJaNotificados);

    // 4) Se não há IDs inéditos, não faz nada
    if (idsIneditos.isEmpty) {
      return;
    }

    // 5) Adiciona os IDs inéditos ao conjunto de já notificados
    //    ANTES de tocar o som, para que chamadas concorrentes não
    //    encontrem os mesmos IDs como "novos".
    _idsJaNotificados.addAll(idsIneditos);

    // 6) Toca o som uma única vez
    await _tocarSom();
  }

  /// Toca o som de notificação com proteção contra chamadas simultâneas.
  /// Método privado — nunca deve ser chamado diretamente de fora.
  static Future<void> _tocarSom() async {
    // Se já está tocando, espera terminar (não toca de novo)
    if (_lockSom != null && !_lockSom!.isCompleted) {
      return;
    }

    _lockSom = Completer<void>();

    try {
      if (!_configurado) {
        await configurarAudio();
        if (!_configurado) return;
      }

      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('audio/plim.mp3'));
    } catch (e) {
      print('[ServicoNotificacao] Erro ao tocar som: $e');
    } finally {
      _lockSom?.complete();
      _lockSom = null;
    }
  }

  /// Toca o som de notificação diretamente, sem verificar `estaNoPainelCozinha`.
  /// Usar quando a lógica de disparo já foi tratada externamente (ex.: PainelCliente).
  static Future<void> tocarSom() => _tocarSom();

  /// Reseta os IDs notificados (usar ao trocar de terminal de produção).
  /// Ao resetar, a **próxima** consulta preencherá o Set sem tocar som —
  /// isso é feito automaticamente pelo [verificarENotificar] porque
  /// o chamador deve chamar [preencherIdsIniciais] logo em seguida.
  static void resetarIdsNotificados() {
    _idsJaNotificados.clear();
  }

  /// Preenche o conjunto de IDs já notificados **sem tocar som**.
  /// Usado na carga inicial ou ao trocar de terminal, para que os pedidos
  /// já existentes não disparem notificação sonora.
  static void preencherIdsIniciais(List<dynamic> listaPedidosEmPreparo) {
    final Set<String> idsAtuais = listaPedidosEmPreparo
        .map((p) => p['numeropedido']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    _idsJaNotificados.addAll(idsAtuais);
  }

  /// Libera o player e reseta a configuração de áudio.
  static Future<void> liberar() async {
    _configurado = false;
    await _audioPlayer.stop();
  }
}
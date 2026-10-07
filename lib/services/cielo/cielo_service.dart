import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class CieloService {
  static const _channel = MethodChannel('unmobile/cielo');

  // Listener registrado pelo chamador para receber o retorno da Cielo.
  static void Function(String jsonRetorno)? _listener;

  /// Registra o handler de retorno da Cielo.
  /// Deve ser chamado uma vez durante a inicialização do app.
  static void escutarRetorno(void Function(String jsonRetorno) onRetorno) {
    _listener = onRetorno;
    _channel.setMethodCallHandler(_onRetornoCieloHandler);
  }

  static Future<dynamic> _onRetornoCieloHandler(MethodCall call) async {
    if (call.method == 'onRetornoCielo') {
      final json = call.arguments as String? ?? '';
      _listener?.call(json);
    }
  }

  /// Dispara o deep link `lio://` para a Cielo Smart.
  /// [uri] — URI completa com scheme lio://, parâmetros request (Base64) e urlCallback.
  static Future<void> iniciarDeepLink(String uri) async {
    await _channel.invokeMethod<void>('iniciarDeepLink', {'uri': uri});
  }

  // Teste de comunicação com a Cielo
  Future<void> testarComunicacaoCielo(context) async {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔵 Abrindo Cielo Emulator...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      await CieloService.iniciarDeepLink(
        'lio://terminalinfo?urlCallback=unmobile://cielo',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🟢 Cielo Emulator acionada! Aguardando retorno...'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao chamar Cielo: $e'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

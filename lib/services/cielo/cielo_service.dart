import 'package:flutter/services.dart';

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
}

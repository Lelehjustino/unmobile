import 'package:flutter/services.dart';

class StoneService {
  static const MethodChannel _channel = MethodChannel('unmobile/stone');

  /// Inicia uma transação de pagamento.
  /// O Flutter envia o valor para o Android nativo.
  Future<Map<String, dynamic>> pagar({
    required int valor,
    String? referencia,
  }) async {
    try {
      final resultado = await _channel.invokeMethod(
        'pagar',
        {
          'valor': valor,
          'referencia': referencia,
        },
      );

      if (resultado == null) {
        return {
          'sucesso': false,
          'mensagem': 'Nenhum resultado retornado pelo Android.',
        };
      }

      return Map<String, dynamic>.from(resultado);
    } on PlatformException catch (e) {
      return {
        'sucesso': false,
        'codigo': e.code,
        'mensagem': e.message ?? 'Erro na comunicação com o Android.',
      };
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': e.toString(),
      };
    }
  }

  /// Cancela uma transação.
  static Future<Map<String, dynamic>> cancelar({
    required String transacaoId,
  }) async {
    try {
      final resultado = await _channel.invokeMethod(
        'cancelar',
        {
          'transacaoId': transacaoId,
        },
      );

      if (resultado == null) {
        return {
          'sucesso': false,
          'mensagem': 'Nenhum resultado retornado pelo Android.',
        };
      }

      return Map<String, dynamic>.from(resultado);
    } on PlatformException catch (e) {
      return {
        'sucesso': false,
        'codigo': e.code,
        'mensagem': e.message ?? 'Erro na comunicação com o Android.',
      };
    }
  }

  /// Verifica se o ambiente Android possui suporte à Stone.
  static Future<bool> verificarStone() async {
    try {
      final resultado = await _channel.invokeMethod<bool>('verificarStone');

      return resultado ?? false;
    } catch (_) {
      return false;
    }
  }
}
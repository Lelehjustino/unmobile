import 'dart:async';
import 'package:flutter/services.dart';

/// Serviço Flutter para comunicação com o PlugPagServiceWrapper via MethodChannel + EventChannel.
///
/// Arquitetura: Flutter/Dart → MethodChannel('unmobile/pagbank') → Kotlin → PlugPag → SmartPOS
///              SmartPOS → PlugPag → EventChannel('unmobile/pagbank/eventos') → Flutter/Dart
class PagBankSmartPOS {
  static const MethodChannel _channel = MethodChannel('unmobile/pagbank');
  static const EventChannel _eventosChannel = EventChannel('unmobile/pagbank/eventos');

  /// Controle de concorrência no lado Flutter.
  static bool _processando = false;

  /// Stream singleton do EventChannel.
  ///
  /// O EventChannel.receiveBroadcastStream() deve ser chamado UMA ÚNICA VEZ
  /// para evitar MissingPluginException ao cancelar o stream.
  /// O Flutter SDK internamente envia 'cancel' pelo canal quando o stream fecha —
  /// se o handler não estiver mais registrado nesse momento, lança o erro.
  static Stream<Map<String, dynamic>>? _eventosStream;

  static Stream<Map<String, dynamic>> get eventos {
    _eventosStream ??= _eventosChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event as Map));
    return _eventosStream!;
  }

  /// Realiza um pagamento na SmartPOS.
  ///
  /// [valorCentavos] — valor em centavos (ex: 3590 = R$ 35,90). Mínimo: 100 (R$1,00).
  /// [tipo] — 'credito', 'debito', 'voucher' ou 'pix'.
  /// [referencia] — identificador da venda.
  static Future<Map<String, dynamic>> pagar({
    required int valorCentavos,
    required String tipo,
    required String referencia,
  }) async {
    if (_processando) {
      return {
        'status': 'ERRO',
        'aprovado': false,
        'codigo': 'BUSY',
        'codigoErro': 'BUSY',
        'mensagem': 'Já existe uma transação em andamento',
      };
    }

    _processando = true;

    try {
      final resultado = await _channel.invokeMethod(
        'realizarPagamento',
        {
          'tipo': tipo,
          'valorCentavos': valorCentavos,
          'referencia': referencia,
        },
      );

      return Map<String, dynamic>.from(resultado as Map);
    } on PlatformException catch (e) {
      return {
        'status': 'ERRO',
        'aprovado': false,
        'codigo': 'PLATFORM_ERROR',
        'codigoErro': e.code,
        'mensagem': e.message ?? 'Erro de plataforma',
      };
    } catch (e) {
      return {
        'status': 'ERRO',
        'aprovado': false,
        'codigo': 'EXCEPTION',
        'codigoErro': 'EXCEPTION',
        'mensagem': 'Erro inesperado: $e',
      };
    } finally {
      _processando = false;
    }
  }

  /// Verifica se a SmartPOS está disponível e pronta.
  static Future<bool> estaDisponivel() async {
    try {
      final resultado = await _channel.invokeMethod<bool>('verificarSmartPOS');
      return resultado ?? false;
    } on PlatformException catch (e) {
      print('PAGBANK: estaDisponivel erro: ${e.message}');
      return false;
    } catch (e) {
      print('PAGBANK: estaDisponivel erro inesperado: $e');
      return false;
    }
  }

  /// Cancela uma transação em andamento (abort).
  static Future<Map<String, dynamic>> cancelarPagamento() async {
    try {
      final resultado = await _channel.invokeMethod('cancelarPagamento');
      return Map<String, dynamic>.from(resultado as Map);
    } on PlatformException catch (e) {
      return {
        'status': 'ERRO',
        'aprovado': false,
        'codigo': 'CANCEL_ERROR',
        'codigoErro': e.code,
        'mensagem': 'Erro ao cancelar: ${e.message}',
      };
    } catch (e) {
      return {
        'status': 'ERRO',
        'aprovado': false,
        'codigo': 'CANCEL_ERROR',
        'codigoErro': 'CANCEL_ERROR',
        'mensagem': 'Erro ao cancelar: $e',
      };
    }
  }
}
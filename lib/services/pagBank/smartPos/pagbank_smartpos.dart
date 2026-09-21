import 'dart:async';
import 'package:flutter/services.dart';

/// Serviço Flutter para comunicação com o PlugPagServiceWrapper via MethodChannel + EventChannel.
///
/// Arquitetura: Flutter/Dart → MethodChannel('unmobile/pagbank') → Kotlin → PlugPag → SmartPOS
///              SmartPOS → PlugPag → EventChannel('unmobile/pagbank/eventos') → Flutter/Dart
///
/// Baseado no SmartCoffee oficial (versão 1.35.0 do Wrapper).
class PagBankSmartPOS {
  static const MethodChannel _channel = MethodChannel('unmobile/pagbank');
  static const EventChannel _eventosChannel =
      EventChannel('unmobile/pagbank/eventos');

  /// Controle de concorrência no lado Flutter.
  static bool _processando = false;
  static bool get processando => _processando;

  /// Stream singleton do EventChannel.
  ///
  /// O EventChannel.receiveBroadcastStream() deve ser chamado UMA ÚNICA VEZ
  /// para evitar MissingPluginException ao cancelar o stream.
  static Stream<Map<String, dynamic>>? _eventosStream;

  static Stream<Map<String, dynamic>> get eventos {
    _eventosStream ??= _eventosChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event as Map));
    return _eventosStream!;
  }

  // ═══════════════════════════════════════════════════════════════
  // PAGAMENTO
  // SmartCoffee: doPay() → doPayment(PlugPagPaymentData) bloqueante
  // ═══════════════════════════════════════════════════════════════

  /// Realiza um pagamento na SmartPOS.
  ///
  /// [valorCentavos] — valor em centavos (ex: 3590 = R$ 35,90). Mínimo: 100 (R$1,00).
  /// [tipo] — 'credito', 'debito', 'voucher' ou 'pix'.
  /// [referencia] — identificador da venda (ex: 'PED123').
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

  // ═══════════════════════════════════════════════════════════════
  // VERIFICAÇÃO
  // SmartCoffee: hasRequirements + isServiceBusy
  // ═══════════════════════════════════════════════════════════════

  /// Verifica se a SmartPOS está disponível e pronta.
  /// Checa: PlugPagService instalado + isAuthenticated + !isServiceBusy
  static Future<bool> estaDisponivel() async {
    try {
      final resultado =
          await _channel.invokeMethod<bool>('verificarSmartPOS');
      return resultado ?? false;
    } on PlatformException catch (e) {
      print('PAGBANK: estaDisponivel erro: ${e.message}');
      return false;
    } catch (e) {
      print('PAGBANK: estaDisponivel erro inesperado: $e');
      return false;
    }
  }

  /// Verifica se o terminal está autenticado.
  /// SmartCoffee: isAuthenticated()
  static Future<bool> estaAutenticado() async {
    try {
      final resultado =
          await _channel.invokeMethod<bool>('verificarAutenticacao');
      return resultado ?? false;
    } catch (e) {
      print('PAGBANK: estaAutenticado erro: $e');
      return false;
    }
  }

  /// Verifica se o serviço está ocupado.
  /// SmartCoffee: isServiceBusy
  static Future<bool> servicoOcupado() async {
    try {
      final resultado =
          await _channel.invokeMethod<bool>('verificarServicoBusy');
      return resultado ?? false;
    } catch (e) {
      print('PAGBANK: servicoOcupado erro: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ATIVAÇÃO
  // SmartCoffee: startOnBoarding()
  // ═══════════════════════════════════════════════════════════════

  /// Inicia o processo de ativação/onboarding do terminal.
  /// Só deve ser chamado se isAuthenticated() retornar false.
  static Future<Map<String, dynamic>> iniciarAtivacao() async {
    try {
      final resultado = await _channel.invokeMethod('iniciarAtivacao');
      return Map<String, dynamic>.from(resultado as Map);
    } catch (e) {
      return {
        'status': 'ERRO',
        'mensagem': 'Erro ao iniciar ativação: $e',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CANCELAMENTO
  // SmartCoffee: abort()
  // ═══════════════════════════════════════════════════════════════

  /// Cancela uma transação em andamento.
  /// SmartCoffee: "Após executar o abort aguardar o retorno da função que você quer executar"
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

  // ═══════════════════════════════════════════════════════════════
  // ÚLTIMA TRANSAÇÃO
  // SmartCoffee OtherViewModel: getLastApprovedTransaction()
  // ═══════════════════════════════════════════════════════════════

  /// Recupera os dados da última transação aprovada.
  /// Útil quando a comunicação Flutter-Kotlin é perdida após aprovação.
  static Future<Map<String, dynamic>> ultimaTransacao() async {
    try {
      final resultado = await _channel.invokeMethod('ultimaTransacao');
      return Map<String, dynamic>.from(resultado as Map);
    } catch (e) {
      return {
        'status': 'ERRO',
        'aprovado': false,
        'codigo': 'EXCEPTION',
        'codigoErro': 'EXCEPTION',
        'mensagem': 'Erro ao buscar última transação: $e',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ESTORNO
  // SmartCoffee OtherViewModel: voidPayment(PlugPagVoidData)
  // ═══════════════════════════════════════════════════════════════

  /// Realiza estorno de uma transação aprovada.
  ///
  /// [transactionCode] e [transactionId] devem ser os valores retornados
  /// pelo pagamento original. [paymentType] é o tipo original (TYPE_CREDITO, etc.)
  static Future<Map<String, dynamic>> estornarPagamento({
    required String transactionCode,
    required String transactionId,
    int paymentType = 0,
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
        'estornarPagamento',
        {
          'transactionCode': transactionCode,
          'transactionId': transactionId,
          'paymentType': paymentType,
        },
      );

      return Map<String, dynamic>.from(resultado as Map);
    } catch (e) {
      return {
        'status': 'ERRO',
        'aprovado': false,
        'codigo': 'EXCEPTION',
        'codigoErro': 'EXCEPTION',
        'mensagem': 'Erro no estorno: $e',
      };
    } finally {
      _processando = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // IMPRESSÃO
  // SmartCoffee OtherViewModel: reprintStablishmentReceipt / reprintCustomerReceipt
  // ═══════════════════════════════════════════════════════════════

  /// Reimprime a via do estabelecimento da última transação.
  static Future<Map<String, dynamic>> reimprimirViaEstabelecimento() async {
    try {
      final resultado =
          await _channel.invokeMethod('reimprimirViaEstabelecimento');
      return Map<String, dynamic>.from(resultado as Map);
    } catch (e) {
      return {
        'status': 'ERRO',
        'mensagem': 'Erro ao reimprimir: $e',
      };
    }
  }

  /// Reimprime a via do cliente da última transação.
  static Future<Map<String, dynamic>> reimprimirViaCliente() async {
    try {
      final resultado =
          await _channel.invokeMethod('reimprimirViaCliente');
      return Map<String, dynamic>.from(resultado as Map);
    } catch (e) {
      return {
        'status': 'ERRO',
        'mensagem': 'Erro ao reimprimir: $e',
      };
    }
  }
}
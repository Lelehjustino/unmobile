import 'dart:async';
import 'dart:convert';

import 'package:un_recepcao/models/cielo/cieloCredentials.dart';

import 'cielo_service.dart';

// ---------------------------------------------------------------------------
// Tipos de resultado
// ---------------------------------------------------------------------------

enum CieloPaymentStatus { aprovado, cancelado, erro, timeout }

class CieloPaymentResult {
  final CieloPaymentStatus status;
  final String? mensagem;
  final Map<String, dynamic>? dadosBrutos;

  const CieloPaymentResult({
    required this.status,
    this.mensagem,
    this.dadosBrutos,
  });

  bool get aprovado => status == CieloPaymentStatus.aprovado;
}

// ---------------------------------------------------------------------------
// Serviço de pagamento
// ---------------------------------------------------------------------------

class CieloPaymentService {
  // Tempo máximo aguardando resposta da Cielo (3 minutos)
  static const Duration _timeout = Duration(minutes: 3);

  // Transação pendente única
  static Completer<CieloPaymentResult>? _pendente;
  static String? _referenciaPendente;
  static int? _valorPendenteCentavos;
  static bool _callbackProcessado = false;
  // Garante que o handler só é registrado uma vez por ciclo de vida do app
  static bool _handlerRegistrado = false;

  // ---------------------------------------------------------------------------
  // Público: iniciar pagamento e aguardar resultado
  // ---------------------------------------------------------------------------

  static Future<CieloPaymentResult> pagar({
    required int valorCentavos,
    required String referencia,
    required String paymentCode,
  }) async {
    // Proteção: não permite duas transações simultâneas
    if (_pendente != null && !_pendente!.isCompleted) {
      return const CieloPaymentResult(
        status: CieloPaymentStatus.erro,
        mensagem: 'Já existe um pagamento Cielo em andamento.',
      );
    }

    // Registra estado pendente
    _pendente = Completer<CieloPaymentResult>();
    _referenciaPendente = referencia;
    _valorPendenteCentavos = valorCentavos;
    _callbackProcessado = false;

    // Garante que o listener está registrado uma única vez
    if (!_handlerRegistrado) {
      _handlerRegistrado = true;
      CieloService.escutarRetorno(_onRetorno);
    }

    // Monta payload
    // Nota: `value` e `unitPrice` são int (centavos). `installments` = 1 (à vista).
    final pagamento = {
      'accessToken': CieloCredentials().accessToken,
      'clientID': CieloCredentials().clientId,
      'reference': referencia,
      'installments': 1,
      'items': [
        {
          'name': 'Venda unMobile',
          'quantity': 1,
          'sku': referencia,
          'unitOfMeasure': 'unidade',
          'unitPrice': valorCentavos,
        }
      ],
      'paymentCode': paymentCode,
      'value': valorCentavos,
    };

    final json = jsonEncode(pagamento);
    final request = base64Encode(utf8.encode(json));

    final uri = Uri(
      scheme: 'lio',
      host: 'payment',
      queryParameters: {
        'request': request,
        'urlCallback': 'unmobile://cielo',
      },
    );

    print('==============================');
    print('JSON CIELO: $json');
    print('DEEP LINK CIELO: ${uri.toString()}');
    print('==============================');

    try {
      await CieloService.iniciarDeepLink(uri.toString());
    } catch (e) {
      _limpar();
      return CieloPaymentResult(
        status: CieloPaymentStatus.erro,
        mensagem: 'Erro ao iniciar deep link Cielo: $e',
      );
    }

    // Aguarda o Future com timeout
    try {
      final resultado = await _pendente!.future.timeout(_timeout);
      return resultado;
    } on TimeoutException {
      _limpar();
      return const CieloPaymentResult(
        status: CieloPaymentStatus.timeout,
        mensagem: 'Tempo limite esgotado. Verifique o pagamento na maquininha.',
      );
    } catch (e) {
      _limpar();
      return CieloPaymentResult(
        status: CieloPaymentStatus.erro,
        mensagem: 'Erro inesperado: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Chamado pelo CieloService quando o callback chega
  // ---------------------------------------------------------------------------

  static void _onRetorno(String jsonRetorno) {
    print('==============================');
    print('CALLBACK CIELO RECEBIDO: $jsonRetorno');
    print('==============================');

    // Proteção: sem transação pendente
    if (_pendente == null || _pendente!.isCompleted) {
      print('CIELO: callback ignorado — nenhuma transação pendente.');
      return;
    }

    // Proteção: callback duplicado
    if (_callbackProcessado) {
      print('CIELO: callback duplicado ignorado.');
      return;
    }

    _callbackProcessado = true;

    Map<String, dynamic> dados;
    try {
      dados = jsonDecode(jsonRetorno) as Map<String, dynamic>;
    } catch (e) {
      print('CIELO: erro ao decodificar JSON do retorno: $e');
      _resolverELimpar(CieloPaymentResult(
        status: CieloPaymentStatus.erro,
        mensagem: 'Retorno inválido da Cielo.',
        dadosBrutos: {'raw': jsonRetorno},
      ));
      return;
    }

    final resultado = _avaliarRetorno(dados);
    _resolverELimpar(resultado);
  }

  // ---------------------------------------------------------------------------
  // Avalia o retorno e valida status / reference / valor
  // ---------------------------------------------------------------------------

  static CieloPaymentResult _avaliarRetorno(Map<String, dynamic> dados) {
    final String status = (dados['status'] ?? '').toString().toUpperCase();
    final String referencia = (dados['reference'] ?? '').toString();
    final dynamic responsecodeDyn = dados['responsecode'];
    final int? responsecode = responsecodeDyn != null
        ? int.tryParse(responsecodeDyn.toString())
        : null;

    // Valor retornado (pode vir como int em centavos)
    final dynamic valorDyn = dados['price'] ?? dados['value'];
    final int? valorRetornado = valorDyn != null
        ? int.tryParse(valorDyn.toString())
        : null;

    print('CIELO→ status=$status | ref=$referencia | responsecode=$responsecodeDyn | valor=$valorRetornado');

    // --- Cancelamento explícito pelo usuário ---
    if (status == 'CANCELLED' || status == 'CANCELED' || status == 'CANCEL') {
      return CieloPaymentResult(
        status: CieloPaymentStatus.cancelado,
        mensagem: 'Pagamento cancelado.',
        dadosBrutos: dados,
      );
    }

    // --- Erro técnico reportado pela Cielo ---
    if (status == 'ERROR') {
      return CieloPaymentResult(
        status: CieloPaymentStatus.erro,
        mensagem: 'Erro técnico retornado pela Cielo.',
        dadosBrutos: dados,
      );
    }

    // --- Recusado pelo banco / bandeira ---
    if (status == 'DECLINED' || status == 'REFUSED' || status == 'DENIED') {
      return CieloPaymentResult(
        status: CieloPaymentStatus.cancelado,
        mensagem: 'Pagamento recusado pela operadora.',
        dadosBrutos: dados,
      );
    }

    // --- Aprovado: PAID com responsecode == 0 ---
    if (status == 'PAID') {
      // Valida responsecode
      if (responsecode != null && responsecode != 0) {
        return CieloPaymentResult(
          status: CieloPaymentStatus.erro,
          mensagem: 'Pagamento PAID mas responsecode=$responsecode.',
          dadosBrutos: dados,
        );
      }

      // Valida reference
      if (_referenciaPendente != null &&
          referencia.isNotEmpty &&
          referencia != _referenciaPendente) {
        return CieloPaymentResult(
          status: CieloPaymentStatus.erro,
          mensagem:
              'Referência inválida. Esperado: $_referenciaPendente, recebido: $referencia',
          dadosBrutos: dados,
        );
      }

      // Valida valor (somente se veio no retorno)
      if (_valorPendenteCentavos != null &&
          valorRetornado != null &&
          valorRetornado != _valorPendenteCentavos) {
        return CieloPaymentResult(
          status: CieloPaymentStatus.erro,
          mensagem:
              'Valor divergente. Enviado: $_valorPendenteCentavos centavos, recebido: $valorRetornado centavos.',
          dadosBrutos: dados,
        );
      }

      return CieloPaymentResult(
        status: CieloPaymentStatus.aprovado,
        mensagem: 'Pagamento aprovado.',
        dadosBrutos: dados,
      );
    }

    // --- Qualquer outro status → erro ---
    return CieloPaymentResult(
      status: CieloPaymentStatus.erro,
      mensagem: 'Status desconhecido ou recusado: $status',
      dadosBrutos: dados,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static void _resolverELimpar(CieloPaymentResult resultado) {
    final comp = _pendente;
    _limpar();
    if (comp != null && !comp.isCompleted) {
      comp.complete(resultado);
    }
  }

  static void _limpar() {
    _pendente = null;
    _referenciaPendente = null;
    _valorPendenteCentavos = null;
    _callbackProcessado = false;
    // _handlerRegistrado permanece true — o handler não deve ser removido entre transações
  }

  // Consultar formas de pagamento habilitadas (sem alteração)
  static Future<void> consultarProdutosHabilitados() async {
    final json = jsonEncode({
      'clientID': CieloCredentials().clientId,
      'accessToken': CieloCredentials().accessToken,
    });

    final base64 = base64Encode(utf8.encode(json));

    final uri =
        'lio://enabledproducts'
        '?request=$base64'
        '&urlCallback=unmobile://cielo';

    await CieloService.iniciarDeepLink(uri);
  }
}
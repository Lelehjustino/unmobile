import 'dart:convert';

import 'cielo_service.dart';

class CieloPaymentService {
  static const String clientId = 'SEU_CLIENT_ID';
  static const String accessToken = 'SEU_ACCESS_TOKEN';

  static Future<void> pagar({
    required int valorCentavos,
    required String referencia,
  }) async {
    final pagamento = {
      'accessToken': accessToken,
      'clientID': clientId,
      'reference': referencia,
      'installments': 0,
      'items': [
        {
          'name': 'Teste unMobile',
          'quantity': 1,
          'sku': 'TESTE001',
          'unitOfMeasure': 'unidade',
          'unitPrice': valorCentavos,
        }
      ],
      'paymentCode': 'DEBITO_AVISTA',
      'value': valorCentavos.toString(),
    };

    final json = jsonEncode(pagamento);

    final base64 = base64Encode(
      utf8.encode(json),
    );

    final uri =
        'lio://payment'
        '?request=$base64'
        '&urlCallback=unmobile://cielo';

    await CieloService.iniciarDeepLink(uri);
  }
}
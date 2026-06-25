import 'package:flutter/services.dart';

class PaymentService {
  static const MethodChannel _channel = MethodChannel('stone_payment');

  static Future<Map<String, dynamic>> pagar({
    required double valor,
  }) async {
    try {
      final result = await _channel.invokeMethod('pagar', {
        "valor": valor,
      });

      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {
        "status": "erro",
        "mensagem": e.toString(),
      };
    }
  }
}
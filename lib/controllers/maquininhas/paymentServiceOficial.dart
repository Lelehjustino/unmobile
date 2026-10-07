import 'package:flutter/services.dart';
import 'package:un_recepcao/services/maquininhas/paymentProvider.dart';

class PaymentServiceOficial {
  static const MethodChannel _channel =
      MethodChannel('unmobile/payment_detector');

  static PaymentProvider provedorAtual = PaymentProvider.desconhecido;

  /// Identifica qual provedor de pagamento está disponível
  /// neste terminal.
  static Future<PaymentProvider> identificarProvedor() async {
    try {
      final resultado =
          await _channel.invokeMethod<String>('identificarProvedor');

      switch (resultado) {
        case 'pagbank':
          provedorAtual = PaymentProvider.pagBank;
          break;

        case 'cielo':
          provedorAtual = PaymentProvider.cielo;
          break;

        default:
          provedorAtual = PaymentProvider.desconhecido;
      }
    } on PlatformException catch (e) {
      print(
        'PAYMENT: erro ao identificar provedor: '
        '${e.code} - ${e.message}',
      );

      provedorAtual = PaymentProvider.desconhecido;
    } catch (e) {
      print('PAYMENT: erro inesperado: $e');

      provedorAtual = PaymentProvider.desconhecido;
    }

    print(
      'PAYMENT: provedor identificado = '
      '${provedorAtual.name}',
    );

    return provedorAtual;
  }
}
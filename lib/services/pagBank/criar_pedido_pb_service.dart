import 'dart:convert';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:http/http.dart' as http;
import 'package:un_recepcao/models/pagBank/order_class_pb.dart';

class PagBankService {
  static const String baseUrl = 'https://sandbox.api.pagseguro.com';

  final OrderClassPb orderClassPbController = Get.find<OrderClassPb>();

  Future<Map<String, dynamic>> criarPedido({
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/orders');

    final body = {
      "reference_id": orderClassPbController.reference_id,
      "customer": {
        "name":  orderClassPbController.customer?.name,
        "email": orderClassPbController.customer?.email,
        "tax_id": orderClassPbController.customer?.tax_id,
        "phones": [
          {
            "country": orderClassPbController.customer?.phone?.first.country,
            "area": orderClassPbController.customer?.phone?.first.area,
            "number": orderClassPbController.customer?.phone?.first.number,
            "type": orderClassPbController.customer?.phone?.first.type,
          }
        ]
      },
      "items": [
        {
          "reference_id": orderClassPbController.items?.reference_id,
          "name": orderClassPbController.items?.name,
          "quantity": orderClassPbController.items?.quantity,
          "unit_amount": orderClassPbController.items?.unit_amount,
        }
      ],
      "shipping": {
        "address": {
          "street": orderClassPbController.shipping?.first.address?.street,
          "number": orderClassPbController.shipping?.first.address?.number,
          "complement": orderClassPbController.shipping?.first.address?.complement,
          "locality": orderClassPbController.shipping?.first.address?.locality,
          "city": orderClassPbController.shipping?.first.address?.city,
          "region_code": orderClassPbController.shipping?.first.address?.region_code,
          "country": orderClassPbController.shipping?.first.address?.country,
          "postal_code": orderClassPbController.shipping?.first.address?.postal_code,
        }
      },
      "notification_urls": [
        orderClassPbController.notification_urls,
      ]
    };

    /* final body = {
      "reference_id": "ex-00001",
      "customer": {
        "name": "Jose da Silva",
        "email": "email@test.com",
        "tax_id": "12345678909",
        "phones": [
          {
            "country": "55",
            "area": "11",
            "number": "999999999",
            "type": "MOBILE"
          }
        ]
      },
      "items": [
        {
          "reference_id": "referencia do item",
          "name": "nome do item",
          "quantity": 1,
          "unit_amount": 500
        }
      ],
      "shipping": {
        "address": {
          "street": "Avenida Brigadeiro Faria Lima",
          "number": "1384",
          "complement": "apto 12",
          "locality": "Pinheiros",
          "city": "São Paulo",
          "region_code": "SP",
          "country": "BRA",
          "postal_code": "01452002"
        }
      },
      "notification_urls": [
        "https://meusite.com/notificacoes"
      ]
    }; */

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'accept': 'application/json',
        'content-type': 'application/json',
      },
      body: jsonEncode(body),
    );

    print('STATUS: ${response.statusCode}');
    print('RESPOSTA: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Erro PagBank: ${response.statusCode} - ${response.body}',
    );
  }
}
import 'dart:convert';

import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:http/http.dart' as http;
import 'package:un_recepcao/models/pagBank/order_class_pb.dart';

class CriarPedidoCartaoService {
  final OrderClassPb orderClassPbController = Get.find<OrderClassPb>();
  static const String _baseUrl = 'https://sandbox.api.pagseguro.com';

  Future<Map<String, dynamic>> criarPedido({
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/orders');

    final body = {
      "reference_id": orderClassPbController.reference_id,

      "customer": {
        "name": orderClassPbController.customer?.name,
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
      ],

      "charges": [
        {
          "reference_id": orderClassPbController.charges?.first.reference_id,
          "description": orderClassPbController.charges?.first.description,

          "amount": {
            "value": orderClassPbController.charges?.first.amount?.value,
            "currency": orderClassPbController.charges?.first.amount?.currency
          },

          "payment_method": {
            "type": orderClassPbController.charges?.first.payment_method?.type,
            "installments": orderClassPbController.charges?.first.payment_method?.installments,
            "capture": orderClassPbController.charges?.first.payment_method?.capture,
            "soft_descriptor": orderClassPbController.charges?.first.payment_method?.soft_descriptor,

            "card": {
              "number": orderClassPbController.charges?.first.payment_method?.card?.number,
              "exp_month": orderClassPbController.charges?.first.payment_method?.card?.exp_month,
              "exp_year": orderClassPbController.charges?.first.payment_method?.card?.exp_year,
              "security_code": orderClassPbController.charges?.first.payment_method?.card?.security_code,

              "holder": {
                "name": orderClassPbController.charges?.first.payment_method?.card?.holder?.name,
                "tax_id": orderClassPbController.charges?.first.payment_method?.card?.holder?.tax_id,
              }
            }
          },

          "notification_urls": [
            orderClassPbController.notification_urls,
          ]
        }
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
            "type": "MOBILE",
          }
        ]
      },

      "items": [
        {
          "reference_id": "referencia do item",
          "name": "nome do item",
          "quantity": 1,
          "unit_amount": 500,
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
          "postal_code": "01452002",
        }
      },

      "notification_urls": [
        "https://meusite.com/notificacoes"
      ],

      "charges": [
        {
          "reference_id": "MY-ID-123",
          "description": "Motivo de pagamento",

          "amount": {
            "value": 1000,
            "currency": "BRL",
          },

          "payment_method": {
            "type": "CREDIT_CARD",
            "installments": 1,
            "capture": true,
            "soft_descriptor": "Loja do meu teste",

            "card": {
              "number": "4111111111111111",
              "exp_month": "03",
              "exp_year": "2026",
              "security_code": "123",

              "holder": {
                "name": "Jose da Silva",
                "tax_id": "65544332211",
              }
            }
          },

          "notification_urls": [
            "https://yourserver.com/nas_ecommerce/277be731-3b7c-4dac-8c4e-4c3f4a1fdc46/"
          ]
        }
      ]
    }; */

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode(body),
    );

    print("STATUS: ${response.statusCode}");
    print("RESPOSTA: ${response.body}");

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    throw Exception(
      "Erro ao criar pedido com cartão: "
      "${response.statusCode} - ${response.body}",
    );
  }
}
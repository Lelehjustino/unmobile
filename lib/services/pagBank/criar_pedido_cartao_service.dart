import 'dart:convert';

import 'package:http/http.dart' as http;

class CriarPedidoCartaoService {
  static const String _baseUrl = 'https://sandbox.api.pagseguro.com';

  static Future<Map<String, dynamic>> criarPedido({
    required String token,
  }) async {
    final url = Uri.parse('$_baseUrl/orders');

    final body = {
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
    };

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
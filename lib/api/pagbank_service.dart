import 'dart:convert';
import 'package:http/http.dart' as http;

class PagBankOrdersService {
  // Substitua pela URL do seu ambiente (Sandbox ou Produção)
  static const String _baseUrl = "https://sandbox.pagbank.uol.com.br/api/v2"; 
  
  // ⚠️ SUBSTITUA PELAS SUAS CREDENCIAIS REAIS
  static const String _apiToken = "SEU_TOKEN_AQUI"; 
  static const String _clientEmail = "SEU_EMAIL_AQUI";

  // Função para criar um novo pedido (Order)
  Future<Map<String, dynamic>> createOrder({
    required String referenceId,
    required double totalAmount, // Valor total do pedido
    required String itemDescription, // Descrição do item
  }) async {
    // Converte o valor de Reais (double) para Centavos (int), que a API exige
    int amountInCents = (totalAmount * 100).toInt();

    // 1. Monta o corpo da requisição (JSON Payload)
    final Map<String, dynamic> requestBody = {
      // Identificador único do seu sistema
      "reference_id": referenceId, 

      // Dados do cliente (simplificado)
      "customer": {
        "email": _clientEmail, // Usamos o mesmo email da conta PagBank para simplificar o exemplo
        "name": "Cliente de Teste",
      },

      // Itens do pedido
      "items": [
        {
          "reference_id": "ITEM001",
          "name": itemDescription,
          "quantity": 1,
          "unit_amount": amountInCents,
        }
      ],

      // Detalhes da cobrança (simplificado para um valor total)
      "charges": [
        {
          "reference_id": "CHG001",
          "description": "Pagamento da Venda $referenceId",
          "amount": {
            "value": amountInCents
          },
          // ⚠️ Esta parte é crucial. Se for maquininha, PIX ou Cartão,
          // o objeto 'payment_method' seria diferente. 
          // Aqui, estamos apenas criando o pedido.
        }
      ]
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          // O PagBank geralmente usa o 'Authorization' com o token de Portador (Bearer)
          // Mas algumas APIs antigas usam email e token no body ou headers, verifique sua documentação.
          'Authorization': 'Bearer $_apiToken',
          // Dependendo da sua integração, você pode precisar de um 'x-api-version'
        },
        body: jsonEncode(requestBody),
      );

      // Verifica se a requisição foi bem sucedida (código 201 Created ou 200 OK)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        print("✅ Pedido Criado com Sucesso! Status Code: ${response.statusCode}");
        print("ID do Pedido: ${responseData['id']}");
        return responseData;
      } else {
        // Trata erros da API
        final errorData = jsonDecode(response.body);
        print("❌ Erro ao criar pedido. Status Code: ${response.statusCode}");
        print("Detalhes do Erro: ${errorData['error']}");
        throw Exception("Falha na API PagBank: ${response.statusCode} - ${errorData['error']}");
      }
    } catch (e) {
      print("❌ Erro de conexão ou processamento: $e");
      throw Exception("Erro de requisição: $e");
    }
  }
}
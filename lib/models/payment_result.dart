enum PaymentStatus { sucesso, falha, cancelado }

class PaymentResult {
  final PaymentStatus status;
  final String mensagem;
  final String? codigo;
  final double valor;

  PaymentResult({
    required this.status,
    required this.mensagem,
    required this.valor,
    this.codigo,
  });
}
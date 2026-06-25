enum PedidoStatus {
  espera,
  preparo,
  pronto
}

class Pedido {
  final String numero;
  final String nome;
  final PedidoStatus status;

  Pedido({
    required this.numero,
    required this.nome,
    required this.status,
  });

  Pedido copyWith({
    String? numero,
    String? nome,
    PedidoStatus? status,
  }) {
    return Pedido(
      numero: numero ?? this.numero,
      nome: nome ?? this.nome,
      status: status ?? this.status,
    );
  }
}
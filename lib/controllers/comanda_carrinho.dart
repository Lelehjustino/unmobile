import 'package:get/get.dart';
import 'package:un_recepcao/views/garcom_page.dart'; // Import necessário para Produto

/* // 
onTap: () {
  // Salva o carrinho que está na tela no repositório geral
  comandaCarrinhoController.salvarCarrinho(
    mesaController.text,      // Número da mesa
    comandaController.text,   // Número da comanda
    carrinhoController.carrinho, // Lista de produtos atual
  );
  
  // Limpa a tela para o próximo atendimento
  setState(() {
    carrinhoController.carrinho.clear();
    comandaController.clear();
    mesaController.clear();
  });
  
  chamarFoco(); // Volta para o campo inicial
}, */

/* // Na sua lógica de carregar mesa/comanda:
List<Produto> itensSalvos = comandaCarrinhoController.buscarProdutos(novaMesa, novaComanda);
if (itensSalvos.isNotEmpty) {
  setState(() {
    carrinhoController.carrinho.addAll(itensSalvos);
  });
} */

// Esta classe armazena os dados de um atendimento isolado
class CarrinhoArmazenado {
  final String mesa;
  final String comanda;
  final List<Produto> produtos;

  CarrinhoArmazenado({
    required this.mesa,
    required this.comanda,
    required this.produtos,
  });

  // Getter para calcular o total líquido do carrinho
  String get totalLiquido {
    double total = 0.0;
    for (var produto in produtos) {
      total += _calcularTotalProduto(produto);
    }
    return total.toStringAsFixed(2);
  }

  double _calcularTotalProduto(Produto produto) {
    double preco = double.tryParse(produto.preco.replaceAll(',', '.')) ?? 0.0;
    double totalItem = preco * produto.quantidade;
    
    for (var adicional in produto.adicionais) {
      totalItem += _calcularTotalProduto(adicional);
    }
    return totalItem;
  }
}

// Controller que funciona como um repositório para múltiplos carrinhos
class ComandaCarrinhoController extends GetxController {
  
  // Lista que guarda todos os carrinhos de mesas e comandas ativas no dispositivo
  final RxList<CarrinhoArmazenado> _repositorioDeCarrinhos = <CarrinhoArmazenado>[].obs;

  // Função para salvar um carrinho de uma mesa/comanda na lista (vindo do CarrinhoController)
  void salvarCarrinho(String mesa, String comanda, List<Produto> produtosDocarrinho) {
    
    // Antes de salvar, removemos se já existir um registro para esta mesa/comanda
    _repositorioDeCarrinhos.removeWhere((c) => c.mesa == mesa && c.comanda == comanda);

    // Adiciona o novo registro (salvando uma cópia imutável dos produtos)
    _repositorioDeCarrinhos.add(
      CarrinhoArmazenado(
        mesa: mesa,
        comanda: comanda,
        produtos: List<Produto>.from(produtosDocarrinho),
      ),
    );
    
    _repositorioDeCarrinhos.refresh();
    print("Carrinho salvo no repositório: Mesa $mesa, Comanda $comanda. Total de itens: ${produtosDocarrinho.length}");
  }

  // Função para recuperar a lista de produtos de uma mesa/comanda específica
  List<Produto> buscarProdutos(String mesa, String comanda) {
    final registro = _repositorioDeCarrinhos.firstWhere(
      (c) => c.mesa == mesa && c.comanda == comanda,
      orElse: () => CarrinhoArmazenado(mesa: mesa, comanda: comanda, produtos: []),
    );
    
    // Retorna uma cópia para que a tela possa manipular à vontade
    return List<Produto>.from(registro.produtos);
  }

  // Verifica se uma mesa/comanda específica tem itens salvos
  bool temItensSalvos(String mesa, String comanda) {
    return _repositorioDeCarrinhos.any((c) => c.mesa == mesa && c.comanda == comanda && c.produtos.isNotEmpty);
  }

  // Limpa o registro de uma mesa/comanda específica após o envio
  void removerCarrinho(String mesa, String comanda) {
    _repositorioDeCarrinhos.removeWhere((c) => c.mesa == mesa && c.comanda == comanda);
    _repositorioDeCarrinhos.refresh();
  }

  // Limpa todos os carrinhos salvos
  void limparTudo() {
    _repositorioDeCarrinhos.clear();
    _repositorioDeCarrinhos.refresh();
  }

  // Getters para verificar se há carrinhos armazenados
  bool get isEmpty => _repositorioDeCarrinhos.isEmpty;
  bool get isNotEmpty => _repositorioDeCarrinhos.isNotEmpty;

  // Getter para ver a lista completa de carrinhos armazenados (útil para debug ou listas)
  List<CarrinhoArmazenado> get listaCompleta => _repositorioDeCarrinhos.toList();
}
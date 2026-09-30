import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:un_recepcao/controllers/comanda_carrinho.dart';
import 'package:un_recepcao/views/garcom_page.dart';

// IMPORTAR: final CarrinhoController carrinhoController = Get.find<CarrinhoController>();
// CHAMAR: carrinhoController.adicionarProdutoAoCarrinho();
// APRESENTAR: carrinhoController.carrinho;

class CarrinhoController extends GetxController {
  final List<Produto> carrinho = <Produto>[];
  /* final comandaCarrinhoController = Get.put(ComandaCarrinhoController()); */
  RxString numeroComanda = "".obs;
  RxString numeroMesa = "".obs;
  RxString numeroPedido = "".obs;
  RxString clienteId = "".obs;
  RxString clienteNome = "".obs;
  RxString clienteCpf = "".obs;
  RxString clienteTelefone = "".obs;
  RxString clienteDataNascimento = "".obs;
  RxString nomeClienteBalcao = "".obs;
  RxString numeroClienteBalcao = "".obs;

  void adicionarProdutoAoCarrinho(
    String produtoNome,
    String produtoValor,
    String produtoNumero,
    double produtoQuantidade,
    String observacaoEscrita,
    String id, {
    bool temMeiaPorcao = false,
    List<Produto> adicionais = const [],
    List<String> observacoesTexto = const [],
  }) {

    // -------- Funções auxiliares --------
    bool listasTextoIguais(List<String> a, List<String> b) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }

    bool adicionaisIguais(List<Produto> a, List<Produto> b) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (a[i].numero != b[i].numero) return false;
        if (a[i].preco != b[i].preco) return false;
        if (a[i].quantidade != b[i].quantidade) return false;
      }
      return true;
    }

    // -------- Verificação de produto existente --------
    final int indexExistente = (produtoNome.contains('Kg') || temMeiaPorcao)
        ? -1
        : carrinho.indexWhere((produto) {
            return produto.numero == produtoNumero &&
                produto.preco == produtoValor &&
                produto.observacaoEscrita == observacaoEscrita &&
                listasTextoIguais(produto.observacoesTexto, observacoesTexto) &&
                adicionaisIguais(produto.adicionais, adicionais);
          });

    if (indexExistente != -1) {

      carrinho[indexExistente].quantidade += produtoQuantidade;
    } else {
      carrinho.add(
        Produto(
          nome: produtoNome,
          preco: produtoValor,
          numero: produtoNumero,
          quantidade: produtoQuantidade,
          observacaoEscrita: observacaoEscrita,
          id: id,
          temMeiaPorcao: temMeiaPorcao,
          adicionais: List<Produto>.from(adicionais),
          observacoesTexto: List<String>.from(observacoesTexto),
        ),
      );
    }

    for (int i = 0; i < carrinho.length; i++) {
      final p = carrinho[i];
     /*  print(
        '[$i] ${p.nome} | qtd: ${p.quantidade} | adicionais: ${p.adicionais.length}',
      ); */
    }
  }

  void editarProdutoAoCarrinho(
    int index,
    String produtoNome,
    String produtoValor,
    String produtoNumero,
    double produtoQuantidade,
    String observacaoEscrita,
    String id, {
    bool temMeiaPorcao = false,
    List<Produto> adicionais = const [],
    List<String> observacoesTexto = const [],
  }) {
    if (index >= 0 && index < carrinho.length) {
      carrinho[index] = Produto(
        nome: produtoNome,
        preco: produtoValor,
        numero: produtoNumero,
        quantidade: produtoQuantidade,
        observacaoEscrita: observacaoEscrita,
        id: id,
        temMeiaPorcao: temMeiaPorcao,
        adicionais: List<Produto>.from(adicionais),
        observacoesTexto: List<String>.from(observacoesTexto),
      );
    }
  }

  void limparCarrinho() {
    carrinho.clear();
    update(); // Notifica ouvintes se houver GetBuilder
  }

  void zerarAtendimentoCarrinho() {
    carrinho.clear();
    numeroComanda.value = "";
    numeroMesa.value = "";
    numeroPedido.value = "";
    clienteId.value = "";
    clienteNome.value = "";
    clienteCpf.value = "";
    clienteTelefone.value = "";
    clienteDataNascimento.value = "";
  }
}
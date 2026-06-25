import 'dart:convert';

import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:un_recepcao/data/data_class.dart';

class PedidosController extends GetxController {

  // PRIMEIRO funcao para configuracao de servico comanda - "se vier 0 não cobra, "1" cobra
  Future<String> configuracaoServicoComanda() async {
    String valor = "0";

    try {
      String dadosJson = await Connection().select(
        "SELECT resultado FROM configuracoes WHERE numero='2';",
      );

      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        valor = lista[0]['resultado'].toString();
        valor = lista[0]['resultado'].toString();
      } else {
        valor = "0";
      }
    } catch (e) {
        valor = "0";
    }

    return valor;
  }

  // PRIMEIRO funcao para configuracao de servico mesa - "se vier 0 não cobra, "1" cobra
  Future<String> configuracaoServicoMesa() async {
    String valor = "0";

    try {
      String dadosJson = await Connection().select(
        "SELECT resultado FROM configuracoes WHERE numero='3';",
      );

      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        valor = lista[0]['resultado'].toString();
      } else {
        valor = "0";
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
      valor = "0";
    }

    return valor;
  }

  // SEGUNDO update para abrir pedido e retorna o numero do pedido
  Future<String> abrirPedido(String numeroComanda, String valor) async {
    // Valores fixos
    String numeroCaixaAtual = '0';
    String numeroUsuarioAtual = '1';
    String numeroTradepointAtual = '1';
    String cobrarTaxa = valor;
    String NumeroComanda = numeroComanda;
    int numeroPedido = 0;

    // Montando o SQL
    String sql = "INSERT INTO pedidos (numerocartao_FK,numerocaixa_FK,numerousuarioabertura_FK,status,pessoas,observacao,numerotradepointabertura_FK,taxaservico,descricaopedido,abertura,numerocliente_FK) VALUES ('$NumeroComanda','$numeroCaixaAtual','$numeroUsuarioAtual','1','1','','$numeroTradepointAtual','$cobrarTaxa','Comanda - $NumeroComanda', CURRENT_TIMESTAMP,'$numeroPedido')";
    try {
      String numeroPedido = await Connection().insertId(sql);

      if (numeroPedido != "") {
        return numeroPedido;
      } else {
        return "";
      }
    } catch (e) {
      return "";
    }
  }

  // TERCEIRO - Função para inserir uma venda e dedolve o numero da venda
  Future<String> inserirVenda({
    required String numeroPedidoFk,
    required String numeroProdutoFk,
    required double valorUnitario,
    required double quantidade,
    required String observacao,
    required String numeroVendedorFk,
    required String numeroTradepointFk,
    required String numeroEstoqueFk,
    required int taxaServico,
    required String numeroAtendenteFk,
    required double comissao,
    required double valorComissao,
    required String idIntegracao,
    required int temCashback,
    required double percentualCashback,
    required double valorCashback,
    required double valorLiquido,
    required double valorServico,
    required String numeroPromocaoFk,
  }) async {
    try {
      String sql = '''
        INSERT INTO vendas (
          numeropromocao_fk,
          numeropedido_fk,
          numeroproduto_fk,
          valorunitario,
          quantidade,
          observacao,
          valorliquido,
          numerovendedor_fk,
          numerotradepoint_fk,
          numeroestoque_fk,
          taxaservico,
          valorservico,
          numeroatendente_fk,
          comissao,
          valorcomissao,
          id_integracao,
          temcashback,
          percentualcashback,
          valorcashback,
          datahora
        ) VALUES (
          '$numeroPromocaoFk',
          '$numeroPedidoFk',
          '$numeroProdutoFk',
          '$valorUnitario',
          '$quantidade',
          '$observacao',
          '$valorLiquido',
          '$numeroVendedorFk',
          '$numeroTradepointFk',
          '$numeroEstoqueFk',
          '$taxaServico',
          ROUND('$valorServico', 8),
          '$numeroAtendenteFk',
          '$comissao',
          '$valorComissao',
          '$idIntegracao',
          '$temCashback',
          '$percentualCashback',
          '$valorCashback',
          CURRENT_TIMESTAMP
        )
      ''';

      String numeroVenda = await Connection().insertId(sql);
      print('Venda inserida com sucesso. ID: $numeroVenda');
      return numeroVenda;
    } catch (e) {
      print('Erro ao inserir venda: $e');
      return "0";
    }
  }
}
import 'dart:convert';

import 'package:get/get.dart';
import 'package:un_recepcao/data/data_class.dart';

class PainelController extends GetxController {

  RxList<dynamic> listaPedidosEmPreparo = <dynamic>[].obs;
  RxList<dynamic> listaPedidosProntos = <dynamic>[].obs;
  RxList<dynamic> listaTerminais = <dynamic>[].obs;
  RxList<dynamic> listaPedidosDelivery = <dynamic>[].obs;
  RxList<dynamic> listaMotoboys = <dynamic>[].obs;

  RxString nomeTerminalSelecionado = "".obs;
  RxString numeroTerminalSelecionado = "".obs;

  RxString nomeMotoboySelecionado = "".obs;
  RxString numeroMotoboySelecionado = "".obs;

  RxBool estaNoPainelCozinha = false.obs;

  @override
  void onInit() {
    super.onInit();
    carregarTudo();
  }

  Future<void> carregarTudo() async {
    await buscarPedidosEmPreparo();
    await buscarPedidosProntos();
    await buscarTerminais();
    await buscarPedidosDelivery();
    await buscarMotoboys();
  }

  Future<void> buscarMotoboys() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, nome FROM motoboys WHERE ativo='1' ORDER BY nome;",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        listaMotoboys.assignAll(lista);
      } else {
        listaMotoboys.assignAll([]);
      }
    } catch (e) {
      print("Erro ao buscar motoboys: $e");
      listaMotoboys.assignAll([]);
    }
  }

  Future<void> buscarPedidosDelivery() async {
    // 1 -> em preparo
    // 2 -> pronto
    // 3 -> finalizado
    try {
      String dadosJson = await Connection().select(
        """
        SELECT
            d.numerodelivery,
            d.nomecliente,
            d.statuspainel,
            p.numero AS numeropedido
        FROM delivery d
        INNER JOIN pedidos p
            ON p.numero = d.numeropedido_FK
        WHERE
            d.datahorachegada >= DATE_SUB(NOW(), INTERVAL 6 HOUR) 
            AND d.balcao = 1;
        """,
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        listaPedidosDelivery.assignAll(lista);
      } else {
        listaPedidosDelivery.assignAll([]);
      }
    } catch (e) {
      print("Erro ao buscar pedidos prontos delivery: $e");
      listaPedidosDelivery.assignAll([]);
    }
  }

  Future<void> buscarPedidosEmPreparo() async {
    try{
      /* String dadosJson = await Connection().select(
        """
          SELECT
            pr.nome AS nome_produto,

            pr.id   AS tipo_produto,

            u.nome AS nome_garcom,

            v.observacao AS observacaovenda,

            v.numeroproduto_FK,
          
            min(v.datahora),
            
            p.observacao AS nomecliente,
            
            p.numero AS numeropedido,
            
            p.descricaopedido,
            
            GROUP_CONCAT(

              CONCAT(sp.nome, '::', vp.fracao)

              SEPARATOR '||'

            ) AS sabores

          FROM vendas v

          INNER JOIN pedidos p
            ON p.numero = v.numeropedido_FK        

          INNER JOIN produtos pr
            ON pr.numero = v.numeroproduto_FK AND (pr.numeroterminal1_FK = '${numeroTerminalSelecionado.value}'  OR pr.numeroterminal2_FK= '${numeroTerminalSelecionado.value}')
            
          INNER JOIN servidorproducao ser
            ON v.numero = ser.numerovenda_FK AND ser.status='1'

          LEFT JOIN vendaspizzas vp
            ON vp.numerovenda_FK = v.numero

          LEFT JOIN sabores sp
            ON sp.numero = vp.numerosabor_FK

          LEFT JOIN usuarios u
            ON u.numero = v.numerovendedor_FK

          GROUP BY
            v.numero,
            v.numeroproduto_FK,
            v.valorunitario,
            v.datahora;
        """,
      ); */

      String dadosJson = await Connection().select(
        """
          SELECT
            pr.nome AS nome_produto,

            pr.id   AS tipo_produto,

            u.nome AS nome_garcom,

            v.observacao AS observacaovenda,

            v.numeroproduto_FK,
          
            min(v.datahora),
            
            p.observacao AS nomecliente,
            
            p.numero AS numeropedido,
            
            p.descricaopedido,
            
            p.entrega AS entregapedido,
            
            GROUP_CONCAT(

              CONCAT(sp.nome, '::', vp.fracao)

              SEPARATOR '||'

            ) AS sabores

          FROM vendas v

          INNER JOIN pedidos p
            ON p.numero = v.numeropedido_FK        

          INNER JOIN produtos pr
            ON pr.numero = v.numeroproduto_FK AND (pr.numeroterminal1_FK = '${numeroTerminalSelecionado.value}'  OR pr.numeroterminal2_FK= '${numeroTerminalSelecionado.value}')
            
          INNER JOIN servidorproducao ser
            ON v.numero = ser.numerovenda_FK AND ser.status='1'

          LEFT JOIN vendaspizzas vp
            ON vp.numerovenda_FK = v.numero

          LEFT JOIN sabores sp
            ON sp.numero = vp.numerosabor_FK

          LEFT JOIN usuarios u
            ON u.numero = v.numerovendedor_FK

          GROUP BY
            v.numero,
            v.numeroproduto_FK,
            v.valorunitario,
            v.datahora;
        """,
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        listaPedidosEmPreparo.assignAll(lista);
      } else {
        listaPedidosEmPreparo.assignAll([]);
      }
    } catch (e) {
      print("Erro ao buscar pedidos em preparo: $e");
      listaPedidosEmPreparo.assignAll([]);
    }
  }

  Future<void> buscarTerminais() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, nome FROM terminaisproducao ORDER BY nome;",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        listaTerminais.assignAll(lista);
        String nomeTerminal = listaTerminais[0]['nome'].toString();
        String numeroTerminal = listaTerminais[0]['numero'].toString();
        setTerminal(nomeTerminal, numeroTerminal);
      } else {
        listaTerminais.assignAll([]);
      }
    } catch (e) {
      print("Erro ao buscar terminais: $e");
      listaTerminais.assignAll([]);
    }
  }

  Future<void> buscarPedidosProntos() async {
    try {
      String dadosJson = await Connection().select(
        """
        SELECT
          pr.nome AS nome_produto,
          pr.id   AS tipo_produto,
          u.nome AS nome_garcom,
          v.observacao AS observacaovenda,
          v.numeroproduto_FK,
          min(v.datahora),
          p.observacao AS nomecliente,
          p.descricaopedido,
          p.numero AS numeropedido,
          GROUP_CONCAT(
            CONCAT(sp.nome, '::', vp.fracao)
            SEPARATOR '||'
          ) AS sabores
        FROM vendas v
        INNER JOIN pedidos p
          ON p.numero = v.numeropedido_FK        
        INNER JOIN produtos pr
          ON pr.numero = v.numeroproduto_FK
        INNER JOIN servidorproducao ser
          ON v.numero = ser.numerovenda_FK AND ser.status='2'
        LEFT JOIN vendaspizzas vp
          ON vp.numerovenda_FK = v.numero
        LEFT JOIN sabores sp
          ON sp.numero = vp.numerosabor_FK
        LEFT JOIN usuarios u
          ON u.numero = v.numerovendedor_FK
        GROUP BY
          v.numero,
          v.numeroproduto_FK,
          v.valorunitario,
          v.datahora;
        """,
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        listaPedidosProntos.assignAll(lista);
      } else {
        listaPedidosProntos.assignAll([]);
      }
    } catch (e) {
      print("Erro ao buscar pedidos prontos: $e");
      listaPedidosProntos.assignAll([]);
    }
  }

  void confirmarPedido(String numeroPedido, String nomeUsuario) {
    // colocar pedido para pronto
    listaPedidosProntos.add({
      "numeroPedido": numeroPedido,
      "nomeUsuario": nomeUsuario
    });

    // remover pedido da lista de em preparo
    listaPedidosEmPreparo.removeWhere((item) => item['numeroPedido'] == numeroPedido);
  }

  void setTerminal(String nomeTerminal, String numeroTerminal) {
    nomeTerminalSelecionado.value = nomeTerminal;
    numeroTerminalSelecionado.value = numeroTerminal;
  }

  void setMotoboy(String nomeMotoboy, String numeroMotoboy) {
    nomeMotoboySelecionado.value = nomeMotoboy;
    numeroMotoboySelecionado.value = numeroMotoboy;
  }
}
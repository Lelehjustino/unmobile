import 'dart:convert';

import 'package:get/get.dart';
import 'package:un_recepcao/data/data_class.dart';

class PainelClienteController extends GetxController {

  RxList<dynamic> semImpressora = [].obs;
  RxList<dynamic> impressoras = [].obs;
  RxList<dynamic> comImpressora = [].obs;

  @override
  void onInit() {
    super.onInit();
    carregarTudo();
  }

  void carregarTudo(){
    buscarImpressoras();
  }

  // Buscar impressoras
  Future<void> buscarImpressoras() async {
    try {
      String dadosJson = await Connection().select(
        """
        SELECT numero,nome FROM impressoras WHERE tipo='Producao' AND ativo='1'
        """,
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        impressoras.assignAll(lista);
      } else {
        impressoras.assignAll([]);
      }
    } catch (e) {
      print("Erro ao buscar pedidos prontos delivery: $e");
      impressoras.assignAll([]);
    }
  }

  // Buscar pedidos que não tem impressora
  Future<List<dynamic>> buscarPedidosSemImpressora() async {
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
        INNER JOIN vendas v
            ON p.numero = v.numeropedido_FK
      INNER JOIN produtos pr
          ON pr.numero = v.numeroproduto_FK	    
        WHERE
            d.datahorachegada >= DATE_SUB(NOW(), INTERVAL 6 HOUR) 
            AND d.balcao = 1;
        """,
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        semImpressora.assignAll(lista);
        return lista;
      } else {
        semImpressora.assignAll([]);
        return [];
      }
    } catch (e) {
      print("Erro ao buscar pedidos prontos delivery: $e");
      semImpressora.assignAll([]);
      return [];
    }
  }

  // Buscar pedidos que não tem impressora
  Future<List<dynamic>> buscarPedidosComImpressora(String numeroImpressora) async {
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
        INNER JOIN vendas v
            ON p.numero = v.numeropedido_FK
		  INNER JOIN produtos pr
		      ON pr.numero = v.numeroproduto_FK	    
        WHERE
            d.datahorachegada >= DATE_SUB(NOW(), INTERVAL 6 HOUR) 
            AND d.balcao = 1 AND (pr.numeroimpressora1_FK='${numeroImpressora}' OR pr.numeroimpressora2_FK='${numeroImpressora}');
        """,
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        comImpressora.assignAll(lista);
        return lista;
      } else {
        comImpressora.assignAll([]);
        return [];
      }
    } catch (e) {
      print("Erro ao buscar pedidos prontos delivery: $e");
      comImpressora.assignAll([]);
      return [];
    }
  }
  
}
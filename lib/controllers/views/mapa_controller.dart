import 'dart:convert';

import 'package:get/get.dart';
import 'package:un_recepcao/data/data_class.dart';

class MapaController extends GetxController {

  RxList<dynamic> todasComandas = <dynamic>[].obs;
  RxList<dynamic> todasMesas = <dynamic>[].obs;
  RxList<dynamic> abertasComandas = <dynamic>[].obs;
  RxList<dynamic> abertasMesas = <dynamic>[].obs;
  RxList<dynamic> fechadasComandas = <dynamic>[].obs;
  RxList<dynamic> fechadasMesas = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    carregarTudo();
  }

  Future<void> carregarTudo() async {
    await carregarTodasAsComandas();
    await carregarTodasAsMesas();
    await carregarAsComandasAbertas();
    await carregarAsMesasAbertas();
    await carregarAsComandasFechadas();
    await carregarAsMesasFechadas();
  }

  // Função carregar TODAS as comandas
  Future<void> carregarTodasAsComandas() async {
    try {
      await Future.delayed(Duration.zero);

      String dadosJson = await Connection().select(
        "SELECT nomecliente, numero, statuspedido, numeropedido_FK, numeromesa FROM cartoes WHERE ativo='1' ORDER BY numero",
      );

      final List<dynamic> lista = jsonDecode(dadosJson);
      todasComandas.assignAll(lista);
    } catch (e) {
      todasComandas.assignAll([]);
    }
  }

  // Função carregar TODAS as mesas
  Future<void> carregarTodasAsMesas() async {
    try {
      await Future.delayed(Duration.zero);

      String dadosJson = await Connection().select(
        "SELECT numero, statuspedido, numeropedido_FK, comandavinculada, balcaovinculado FROM mesas WHERE ativo='1' ORDER BY numero",
      );


      final List<dynamic> lista = jsonDecode(dadosJson);
      todasMesas.assignAll(lista);
    } catch (e) {
      todasMesas.assignAll([]);
    }
  }

  // Função carregar as comandas ABERTAS
  Future<void> carregarAsComandasAbertas() async {
    try {
      await Future.delayed(Duration.zero);

      String dadosJson = await Connection().select(
        "SELECT numero, statuspedido, numeropedido_FK, numeromesa, nomecliente, valorliquidopedido FROM cartoes WHERE ativo='1' AND (numeropedido_FK!='0') ORDER BY numero",
      );


      final List<dynamic> lista = jsonDecode(dadosJson);
      abertasComandas.assignAll(lista);
    } catch (e) {
      abertasComandas.assignAll([]);
    }
  }

  // Função carregar as mesas ABERTAS
  Future<void> carregarAsMesasAbertas() async {
    try {
      await Future.delayed(Duration.zero);

      String dadosJson = await Connection().select(
        "SELECT numero, statuspedido, numeropedido_FK, comandavinculada, balcaovinculado, valorliquidopedido FROM mesas WHERE ativo='1' AND (numeropedido_FK!='0' OR balcaovinculado = '1' OR comandavinculada = '1') ORDER BY numero",
      );


      final List<dynamic> lista = jsonDecode(dadosJson);
      abertasMesas.assignAll(lista);
    } catch (e) {
      abertasMesas.assignAll([]);
    }
  }

  // Função carregar as comandas FECHADAS
  Future<void> carregarAsComandasFechadas() async {
    try {
      await Future.delayed(Duration.zero);

      String dadosJson = await Connection().select(
        "SELECT numero, statuspedido, numeropedido_FK, numeromesa FROM cartoes WHERE ativo='1' AND numeropedido_FK='0' ORDER BY numero",
      );


      final List<dynamic> lista = jsonDecode(dadosJson);
      fechadasComandas.assignAll(lista);
    } catch (e) {
      fechadasComandas.assignAll([]);
    }
  }

  // Função carregar as mesas FECHADAS
  Future<void> carregarAsMesasFechadas() async {
    try {
      await Future.delayed(Duration.zero);

      String dadosJson = await Connection().select(
        "SELECT numero, statuspedido, numeropedido_FK, comandavinculada, balcaovinculado FROM mesas WHERE ativo='1' AND numeropedido_FK='0' AND comandavinculada='0' AND balcaovinculado = '0' ORDER BY numero",
      );


      final List<dynamic> lista = jsonDecode(dadosJson);
      fechadasMesas.assignAll(lista);
    } catch (e) {
      fechadasMesas.assignAll([]);
    }
  }
}
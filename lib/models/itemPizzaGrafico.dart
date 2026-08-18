import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:path/path.dart';

class ItemPizzaGrafico {
  final String? nome;
  final double? quantidade;
  final String? id;

  ItemPizzaGrafico({
    this.nome,
    this.quantidade,
    this.id,
  });


  RxList<ItemPizzaGrafico> listaSabores = <ItemPizzaGrafico>[].obs;
  RxList<ItemPizzaGrafico> listaBordas = <ItemPizzaGrafico>[].obs;


  List<PieChartSectionData> criarSecoes(
    List<ItemPizzaGrafico> itens,
    double radius, {
    required bool mostrarTexto,
  }) {
    if (itens.isEmpty) {
      return [];
    }

    final total = itens.fold<double>(
      0,
      (soma, item) => soma + item.quantidade!,
    );

    if (total <= 0) {
      return [];
    }

    return itens.map((item) {
      final index = itens.indexOf(item);
      final percentual = (item.quantidade! / total) * 100;
      final nome = item.nome;
      final cor = item.id == 'P' ? _obterCorPizza(index): _obterCorBorda(index);

      return PieChartSectionData(
        value: item.quantidade!,
        color: cor,
        radius: radius,
        title: mostrarTexto
            ? '${nome}'
            : '',
        titleStyle: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  Color _obterCorPizza(int index) {
    return _coresPizzas[index % _coresPizzas.length];
  }

  Color _obterCorBorda(int index) {
    return _coresBordas[index % _coresBordas.length];
  }

  final List<Color> _coresPizzas = [
    const Color.fromRGBO(87, 154, 146, 1),
    const Color.fromRGBO(173, 216, 208, 1.0),
    const Color.fromRGBO(255, 216, 99, 1),
    const Color.fromRGBO(1, 132, 152, 1),
    const Color.fromRGBO(243, 153, 48, 1),
    const Color.fromARGB(255, 185, 93, 114),
  ];  

  final List<Color> _coresBordas = [
    const Color.fromARGB(255, 185, 93, 114),
    const Color.fromRGBO(243, 153, 48, 1),
    const Color.fromRGBO(1, 132, 152, 1),
    const Color.fromRGBO(255, 216, 99, 1),
    const Color.fromRGBO(173, 216, 208, 1.0),
    const Color.fromRGBO(87, 154, 146, 1),
  ];
}
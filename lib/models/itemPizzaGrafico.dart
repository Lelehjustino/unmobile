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
    bool textoForaDoGrafico = false,
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
      final cor = item.id == 'P' ? obterCorPizza(index): obterCorBorda(index);
      final corTexto = textoForaDoGrafico ? cor : (item.id == 'P' ? Colors.white : Colors.black);

      return PieChartSectionData(
        value: item.quantidade!,
        color: cor,
        radius: radius,
        title: mostrarTexto
            ? quebrarTexto(nome!, 5)
            : '',
        titleStyle: TextStyle(
          color: corTexto,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        titlePositionPercentageOffset: textoForaDoGrafico ? (itens.length % 2 == 0 ? 1.7 : 1.7) : 0.5,
      );
    }).toList();
  }

  Color obterCorPizza(int index) {
    return _coresPizzas[index % _coresPizzas.length];
  }

  Color obterCorBorda(int index) {
    return _coresBordas[index % _coresBordas.length];
  }

  final List<Color> _coresPizzas = [
    const Color.fromRGBO(87, 154, 146, 1),
    const Color.fromRGBO(173, 216, 208, 1.0),
    const Color.fromRGBO(255, 216, 99, 1),
    const Color.fromRGBO(1, 132, 152, 1),
    const Color.fromRGBO(243, 153, 48, 1),
  ];  

  final List<Color> _coresBordas = [
    const Color.fromRGBO(243, 153, 48, 1),
    const Color.fromRGBO(1, 132, 152, 1),
    const Color.fromRGBO(255, 216, 99, 1),
    const Color.fromRGBO(173, 216, 208, 1.0),
    const Color.fromRGBO(87, 154, 146, 1),
  ];

  String quebrarTexto(String texto, int maxCaracteres) {
    final palavras = texto.split(' ');
    final linhas = <String>[];
    String linhaAtual = '';

    for (final palavra in palavras) {
      final teste = linhaAtual.isEmpty
          ? palavra
          : '$linhaAtual $palavra';

      if (teste.length <= maxCaracteres) {
        linhaAtual = teste;
      } else {
        if (linhaAtual.isNotEmpty) {
          linhas.add(linhaAtual);
        }
        linhaAtual = palavra;
      }
    }

    if (linhaAtual.isNotEmpty) {
      linhas.add(linhaAtual);
    }

    return linhas.join('\n');
  }
}
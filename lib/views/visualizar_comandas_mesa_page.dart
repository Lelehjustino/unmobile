import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:un_recepcao/controllers/views/funcoes_controller.dart';
import 'package:un_recepcao/data/data_class.dart';
import 'package:un_recepcao/widgets/side_nav.dart';

class VisualizarComandasMesaPage extends StatefulWidget {
  VisualizarComandasMesaPage({super.key});

  @override
  State<VisualizarComandasMesaPage> createState() => _VisualizarComandasMesaPageState();
}

class _VisualizarComandasMesaPageState extends State<VisualizarComandasMesaPage> {

  final List<dynamic>? listaComandas = Get.arguments['listaComandas'];
  final String? mesaSelecionada = Get.arguments['mesa'];
  final int? indexMesa = Get.arguments['indexMesa'];

  final FuncoesController funcoesController = Get.put(FuncoesController());
  String versaoAplicacao = FuncoesController().versaoDoApp;

  bool aparecerNote = false;
  bool aparecerCupomAvulso = false;
  bool aparecerRecepcao = false;
  bool aparecerGarcom = false;
  bool naoAparecerMapa = false;
  bool aparecerCheckInOut = false;
  bool aparecerCheckIn = false;
  bool aparecerCheckOut = false;

  String nomeEmpresa = "";

  late Timer _timer;
  String _horaAtual = "";

  RxString nomeImpressoraSelecionada = ''.obs;
  RxString numeroImpressoraSelecionada = ''.obs;
  RxList<dynamic> impressorasSelecionadas = <dynamic>[].obs;

  /// Mapa: numeropedido_FK -> lista de produtos daquele pedido
  Map<String, List<dynamic>> produtosPorComanda = {};

  /// Mapa: numeropedido_FK -> valores totais daquele pedido
  Map<String, Map<String, String>> valoresPorComanda = {};

  bool carregando = true;

  final formatoReal = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _atualizarHora();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _atualizarHora();
    });
    carregarConfiguracoes();
    _carregarTodosDados();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void carregarConfiguracoes() async {
    await _carregarNote();
    await _carregarCupomAvulso();
    await _carregarRecepcao();
    await _carregargarcom();
    await _carregarModos();
    await _carregarchecks();
    await _loadNomeEmpresa();
  }

  /// Carrega produtos e valores para TODAS as comandas de forma paralela
  Future<void> _carregarTodosDados() async {
    if (listaComandas == null || listaComandas!.isEmpty) {
      setState(() { carregando = false; });
      return;
    }

    // Filtra apenas comandas com numeropedido_FK válido
    final comandasValidas = listaComandas!
        .where((c) => c['numeropedido_FK'] != null && c['numeropedido_FK'].toString() != '0')
        .toList();

    if (comandasValidas.isEmpty) {
      setState(() { carregando = false; });
      return;
    }

    // Busca em paralelo para todas as comandas
    await Future.wait(
      comandasValidas.map((comanda) async {
        final numeroPedido = comanda['numeropedido_FK'].toString();
        await Future.wait([
          _buscarProdutosComanda(numeroPedido),
          _buscarValoresPedido(numeroPedido),
        ]);
      }),
    );

    if (mounted) {
      setState(() { carregando = false; });
    }
  }

  /// Busca lista de produtos de um pedido específico
  Future<void> _buscarProdutosComanda(String numeropedido) async {
    try {
      String dadosJson = await Connection().select(
        """
        SELECT
            p.nome AS nome_produto,
            p.id   AS tipo_produto,
            un.simbolo AS produto_un,

            u.nome AS nome_garcom,

            v.observacao,
            v.numeroproduto_FK,
            v.valorunitario,
            SUM(v.quantidade) AS total_quantidade,
            SUM(v.valorliquido) AS total_valor,
            v.datahora,

            GROUP_CONCAT(
              CONCAT(sp.nome, '::', vp.fracao)
              SEPARATOR '||'
            ) AS sabores

          FROM vendas v

          INNER JOIN produtos p
            ON p.numero = v.numeroproduto_FK

          INNER JOIN unidades un
            ON un.numero = p.numerounidade_FK

          LEFT JOIN vendaspizzas vp
            ON vp.numerovenda_FK = v.numero

          LEFT JOIN sabores sp
            ON sp.numero = vp.numerosabor_FK

          LEFT JOIN usuarios u
            ON u.numero = v.numerovendedor_FK

          WHERE v.numeropedido_FK = '$numeropedido'
            AND v.cancelado = '0'

          GROUP BY
            v.numero,
            v.numeroproduto_FK,
            v.valorunitario,
            v.datahora;
        """,
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      // Agrupar produtos (mesma lógica da ContaPage)
      Map<String, dynamic> agrupados = {};
      for (var item in lista) {
        bool isKg = item['produto_un']?.toString().toUpperCase() == 'KG';
        String key =
            "${item['nome_produto']}_${item['valorunitario']}_${item['sabores']}_${item['observacao']}_${item['tipo_produto']}";

        if (isKg) {
          agrupados["${key}_${item['datahora']}_${item.hashCode}"] =
              Map<String, dynamic>.from(item);
        } else if (agrupados.containsKey(key)) {
          double qtdAtual = double.tryParse(agrupados[key]['total_quantidade'].toString()) ?? 0;
          double qtdNova = double.tryParse(item['total_quantidade'].toString()) ?? 0;
          agrupados[key]['total_quantidade'] = (qtdAtual + qtdNova).toString();

          double valorAtual = double.tryParse(agrupados[key]['total_valor'].toString()) ?? 0;
          double valorNovo = double.tryParse(item['total_valor'].toString()) ?? 0;
          agrupados[key]['total_valor'] = (valorAtual + valorNovo).toStringAsFixed(2);
        } else {
          agrupados[key] = Map<String, dynamic>.from(item);
        }
      }

      produtosPorComanda[numeropedido] = agrupados.values.toList();
    } catch (e) {
      produtosPorComanda[numeropedido] = [];
    }
  }

  /// Busca valores totais de um pedido específico
  Future<void> _buscarValoresPedido(String numeropedido) async {
    try {
      String dadosJson = await Connection().select(
        """
        SELECT valorprodutos, valoradicionais, valorservico, valordesconto, valortotalliquido
        FROM pedidos
        WHERE numero = '$numeropedido';
        """,
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        valoresPorComanda[numeropedido] = {
          'valorprodutos': lista[0]['valorprodutos']?.toString() ?? '0.00',
          'valoradicionais': lista[0]['valoradicionais']?.toString() ?? '0.00',
          'valorservico': lista[0]['valorservico']?.toString() ?? '0.00',
          'valordesconto': lista[0]['valordesconto']?.toString() ?? '0.00',
          'valortotalliquido': lista[0]['valortotalliquido']?.toString() ?? '0.00',
        };
      } else {
        valoresPorComanda[numeropedido] = {
          'valorprodutos': '0.00',
          'valoradicionais': '0.00',
          'valorservico': '0.00',
          'valordesconto': '0.00',
          'valortotalliquido': '0.00',
        };
      }
    } catch (e) {
      valoresPorComanda[numeropedido] = {
        'valorprodutos': '0.00',
        'valoradicionais': '0.00',
        'valorservico': '0.00',
        'valordesconto': '0.00',
        'valortotalliquido': '0.00',
      };
    }
  }

  // Carregar check
  Future<void> _carregarchecks() async {
    final prefs = await SharedPreferences.getInstance();
    final checkJson = prefs.getString('check_padrao');

    if (checkJson != null) {
      final checksSalvos = Set<String>.from(jsonDecode(checkJson));

      if (checksSalvos.contains("Check-in") && !checksSalvos.contains("Check-out")) {
        setState(() { aparecerCheckIn = true; aparecerCheckOut = false; });
      } else if (checksSalvos.contains("Check-out") && !checksSalvos.contains("Check-in")) {
        setState(() { aparecerCheckIn = false; aparecerCheckOut = true; });
      } else if (!checksSalvos.contains("Check-in") && !checksSalvos.contains("Check-out")) {
        setState(() { aparecerCheckIn = false; aparecerCheckOut = false; });
      } else if (checksSalvos.contains("Check-in") && checksSalvos.contains("Check-out")) {
        setState(() { aparecerCheckIn = true; aparecerCheckOut = true; });
      } else {
        setState(() { aparecerCheckIn = false; aparecerCheckOut = false; });
      }
    } else {
      setState(() { aparecerCheckIn = false; aparecerCheckOut = false; });
    }
  }

  // Carregar modo
  Future<void> _carregarModos() async {
    final prefs = await SharedPreferences.getInstance();
    final modoJson = prefs.getString('modo_padrao');

    if (modoJson != null) {
      final modosSalvos = Set<String>.from(jsonDecode(modoJson));
      setState(() {
        naoAparecerMapa = !(modosSalvos.contains("Mesa") || modosSalvos.contains("Comanda"));
        if (modosSalvos.contains("Mesa") && !modosSalvos.contains("Comanda")) {
          aparecerCheckInOut = false;
        } else if (modosSalvos.contains("Comanda")) {
          aparecerCheckInOut = true;
        } else {
          aparecerCheckInOut = false;
        }
      });
    } else {
      setState(() { naoAparecerMapa = true; aparecerCheckInOut = true; });
    }
  }

  // Carregar garçom
  Future<void> _carregargarcom() async {
    final prefs = await SharedPreferences.getInstance();
    final garcomJson = prefs.getString('garcom_padrao');

    if (garcomJson != null) {
      final garcomSalvos = Set<String>.from(jsonDecode(garcomJson));
      if (garcomSalvos.contains("Modo Garçom")) {
        setState(() { aparecerGarcom = true; });
      } else {
        setState(() { aparecerGarcom = false; });
      }
    } else {
      setState(() { aparecerGarcom = true; });
    }
  }

  // Carregar recepcao
  Future<void> _carregarRecepcao() async {
    final prefs = await SharedPreferences.getInstance();
    final recepcaoJson = prefs.getString('recepcao_padrao');

    if (recepcaoJson != null) {
      final recepcaosSalvos = Set<String>.from(jsonDecode(recepcaoJson));
      if (recepcaosSalvos.contains('Recepção')) {
        setState(() { aparecerRecepcao = true; });
      } else {
        setState(() { aparecerRecepcao = false; });
      }
    } else {
      setState(() { aparecerRecepcao = false; });
    }
  }

  // Carregar cupom avulso
  Future<void> _carregarCupomAvulso() async {
    final prefs = await SharedPreferences.getInstance();
    final noteJson = prefs.getString('cupom_avulso');

    if (noteJson != null) {
      final notesSalvos = Set<String>.from(jsonDecode(noteJson));
      if (notesSalvos.contains('Cupom Avulso')) {
        setState(() { aparecerCupomAvulso = true; });
      } else {
        setState(() { aparecerCupomAvulso = false; });
      }
    } else {
      setState(() { aparecerCupomAvulso = false; });
    }
  }

  // Carregar note
  Future<void> _carregarNote() async {
    final prefs = await SharedPreferences.getInstance();
    final noteJson = prefs.getString('note_padrao');

    if (noteJson != null) {
      final notesSalvos = Set<String>.from(jsonDecode(noteJson));
      if (notesSalvos.contains('Notes')) {
        setState(() { aparecerNote = true; });
      } else {
        setState(() { aparecerNote = false; });
      }
    } else {
      setState(() { aparecerNote = false; });
    }
  }

  // Load nomeEmpresa
  Future<void> _loadNomeEmpresa() async {
    final prefs = await SharedPreferences.getInstance();
    final nomeEmpresaSalvo = prefs.getString('nomeEmpresa');
    if (nomeEmpresaSalvo != null) {
      setState(() { nomeEmpresa = nomeEmpresaSalvo; });
    }
  }

  // Função para atualizar hora
  void _atualizarHora() {
    if (!mounted) return;
    final agora = DateTime.now();
    final horaFormatada = DateFormat.Hm().format(agora);
    setState(() { _horaAtual = horaFormatada; });
  }

  // BUILD 

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Comandas válidas (com pedido vinculado)
    final comandasValidas = (listaComandas ?? []).where((c) => c['numeropedido_FK'] != null && c['numeropedido_FK'].toString() != '0').toList();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: SideNav(),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: Obx(() {
          final conectado = Connection.connectionStatus.value;
          return AppBar(
            backgroundColor: conectado ? colorScheme.primary : colorScheme.error,
            automaticallyImplyLeading: false,
            title: Stack(
              alignment: Alignment.center,
              children: [
                // VOLTAR
                Align(
                  alignment: Alignment.centerLeft,
                  child: Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
                      onPressed: () => Get.back(),
                    ),
                  ),
                ),

                // CENTRO
                Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        nomeEmpresa,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      Text(
                        _horaAtual,
                        style: TextStyle(color: colorScheme.onPrimary, fontSize: 15),
                      ),
                    ],
                  ),
                ),

                // STATUS
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() => Text(
                        Connection.connectionStatus.value ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                      Text(
                        versaoAplicacao,
                        style: TextStyle(color: colorScheme.onPrimary, fontSize: 12),
                      ),
                      Text(
                        "${funcoesController.nomeTraidpoint}",
                        style: TextStyle(color: colorScheme.onPrimary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
      body: Column(
        children: [
          // Barra de identificação da mesa
          Container(
            height: MediaQuery.of(context).size.height * 0.05,
            color: colorScheme.outline,
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.arrow_back, color: Colors.transparent),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'COMANDAS DA MESA',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'MESA: ${mesaSelecionada ?? '-'}',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.arrow_back, color: Colors.transparent),
                ),
              ],
            ),
          ),

          // Corpo
          Expanded(
            child: carregando
                ? Center(child: CircularProgressIndicator())
                : comandasValidas.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhuma comanda com pedido vinculado.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                        itemCount: comandasValidas.length,
                        itemBuilder: (context, idx) {
                          final comanda = comandasValidas[idx];
                          final numeroPedido = comanda['numeropedido_FK'].toString();
                          final numeroComanda = comanda['numero']?.toString() ?? '-';
                          final nomeCliente = comanda['nomecliente']?.toString() ?? '';

                          final produtos = produtosPorComanda[numeroPedido] ?? [];
                          final valores = valoresPorComanda[numeroPedido] ?? {
                            'valorprodutos': '0.00',
                            'valoradicionais': '0.00',
                            'valorservico': '0.00',
                            'valordesconto': '0.00',
                            'valortotalliquido': '0.00',
                          };

                          return _buildBlocoComanda(
                            context: context,
                            colorScheme: colorScheme,
                            numeroComanda: numeroComanda,
                            numeroPedido: numeroPedido,
                            nomeCliente: nomeCliente,
                            produtos: produtos,
                            valores: valores,
                            indice: idx + 1,
                            total: comandasValidas.length,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // BLOCO DE UMA COMANDA
  Widget _buildBlocoComanda({
    required BuildContext context,
    required ColorScheme colorScheme,
    required String numeroComanda,
    required String numeroPedido,
    required String nomeCliente,
    required List<dynamic> produtos,
    required Map<String, String> valores,
    required int indice,
    required int total,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho da comanda
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Icon(Icons.description_outlined, color: colorScheme.onSurface, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comanda Nº $numeroComanda',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: MediaQuery.textScalerOf(context).scale(14),
                        ),
                      ),
                      Text(
                        'Pedido: $numeroPedido${nomeCliente.isNotEmpty ? ' · $nomeCliente' : ''}',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.8),
                          fontSize: MediaQuery.textScalerOf(context).scale(11),
                        ),
                      ),
                    ],
                  ),
                ),
                /* Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$indice / $total',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: MediaQuery.textScalerOf(context).scale(11),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ), */
              ],
            ),
          ),

          // Cabeçalho colunas
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'Produto',
                    style: TextStyle(fontSize: MediaQuery.textScalerOf(context).scale(13)),
                  ),
                ),
                Expanded(flex: 1, child: Container()),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Total',
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: MediaQuery.textScalerOf(context).scale(13)),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1),

          // Lista de produtos
          if (produtos.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Nenhum item nesta comanda',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: produtos.length,
              itemBuilder: (context, index) {
                final produto = produtos[index];
                final nomeDoProduto = produto['nome_produto'].toString();
                final quantidadeDoProduto = produto['total_quantidade'].toString();
                final precoDoProduto = produto['valorunitario'].toString();
                final totalDoProduto = produto['total_valor'].toString();
                final id = produto['tipo_produto'].toString();
                final saboresRaw = produto['sabores'] ?? '';
                final observacao = (produto['observacao'] ?? '').replaceFirst(RegExp(r'\|$'), '');
                final double qtdDouble = double.tryParse(quantidadeDoProduto) ?? 0;
                final nomeDoGarcom = produto['nome_garcom'] ?? '';

                final DateTime dataHora = DateTime.parse(produto['datahora'].toString());
                final String data = '${dataHora.day.toString().padLeft(2, '0')}/${dataHora.month.toString().padLeft(2, '0')}/${dataHora.year}';
                final String hora = '${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}:${dataHora.second.toString().padLeft(2, '0')}';

                final List<Map<String, String>> sabores = saboresRaw
                    .toString()
                    .split('||')
                    .where((s) => s.isNotEmpty)
                    .map<Map<String, String>>((item) {
                      final partes = item.split('::');
                      return {
                        'nome': partes[0],
                        'fracao': partes.length > 1 ? partes[1] : '',
                      };
                    })
                    .toList();

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  elevation: 0,
                  color: colorScheme.surface,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Informações do produto
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nomeDoProduto,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: MediaQuery.textScalerOf(context).scale(12),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Aten: ',
                                        style: TextStyle(
                                          fontSize: MediaQuery.textScalerOf(context).scale(11),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        nomeDoGarcom,
                                        style: TextStyle(
                                          fontSize: MediaQuery.textScalerOf(context).scale(11),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Sabores (pizza)
                                  if (id == 'PZ')
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: sabores.map((sabor) {
                                        final fracao = sabor['fracao'] == '1/1' ? '1' : sabor['fracao'] ?? '';
                                        return Row(
                                          children: [
                                            Text(
                                              '$fracao',
                                              style: TextStyle(
                                                fontSize: MediaQuery.textScalerOf(context).scale(10),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(width: 5),
                                            Flexible(
                                              child: Text(
                                                '${sabor['nome']}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: MediaQuery.textScalerOf(context).scale(10),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                            ),

                            // Qtde x Unitário
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$data $hora',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontSize: MediaQuery.textScalerOf(context).scale(10),
                                      color: Colors.transparent,
                                    ),
                                  ),
                                  Text(
                                    qtdDouble % 1 == 0
                                        ? '${qtdDouble.toInt()} x R\$ $precoDoProduto'
                                        : '${qtdDouble} x R\$ $precoDoProduto',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: MediaQuery.textScalerOf(context).scale(11),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Total do item
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$data $hora',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontSize: MediaQuery.textScalerOf(context).scale(10),
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    'R\$ $totalDoProduto',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontSize: MediaQuery.textScalerOf(context).scale(12),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Observação
                        if (observacao.isNotEmpty)
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  observacao,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: MediaQuery.textScalerOf(context).scale(11),
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

          /* Divider(height: 1),

          // Resumo financeiro da comanda
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildValorChip(context, 'Prod.', 'R\$ ${valores['valorprodutos']}'),
                _buildValorChip(context, 'Adic.', 'R\$ ${valores['valoradicionais']}'),
                _buildValorChip(context, 'Serv.', 'R\$ ${valores['valorservico']}'),
                _buildValorChip(context, 'Desc.', 'R\$ ${valores['valordesconto']}'),
              ],
            ),
          ), */

          /* // Total da comanda
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'TOTAL DA COMANDA:',
                  style: TextStyle(
                    fontSize: MediaQuery.textScalerOf(context).scale(12),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'R\$ ${valores['valortotalliquido']}',
                    style: TextStyle(
                      fontSize: MediaQuery.textScalerOf(context).scale(14),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ), */

          SizedBox(height: 8),
        ],
      ),
    );
  }
}
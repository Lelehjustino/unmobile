import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:un_recepcao/controllers/carrinho_controller.dart';
import 'package:un_recepcao/controllers/comanda_carrinho.dart';
import 'package:un_recepcao/controllers/views/funcoes_controller.dart';
import 'package:un_recepcao/controllers/views/painel_controller.dart';
import 'package:un_recepcao/data/data_class.dart';
import 'package:un_recepcao/views/informacoes_pedido.dart';
import 'package:un_recepcao/widgets/side_nav.dart';

class ExpedicaoMotoboyPage extends StatefulWidget {
  const ExpedicaoMotoboyPage({super.key});

  @override
  State<ExpedicaoMotoboyPage> createState() => ExpedicaoMotoboyPageState();
}

class ExpedicaoMotoboyPageState extends State<ExpedicaoMotoboyPage> {

  final CarrinhoController carrinhoController = Get.find<CarrinhoController>();
  final ComandaCarrinhoController comandaCarrinhoController = Get.find<ComandaCarrinhoController>();
  String versaoAplicacao = FuncoesController().versaoDoApp;
  final FuncoesController funcoesController = Get.find<FuncoesController>();
  final PainelController painelController = Get.find<PainelController>();

  List<dynamic> listaPedidos = [];
  List<dynamic> listaPedidosSelecionados = [];
  List<int> listaIndexPedidosSelecionados = [];

  String numeroMotoboySelecionado = "";
  String nomeMotoboySelecionado = "";

  String numeroTradepointSelecionada = "";
  String nomeEmpresa = "";

  bool isLoadingConfirmar = false;

  late Timer _timer;
  String _horaAtual = '';

  double totalDePedidos = 0;
  double totalDeTroco = 0;

  String totalDePedidosString = "0,00";
  String totalDeTrocoString = "0,00";

/*   String nomeClienteSelecionado = "";
  String telefoneClienteSelecionado = "";
  String enderecoClienteSelecionado = ""; */

  int motoboySelecionadoIndex = -1;

  @override
  void initState() {
    super.initState();

    painelController.estaNoPainelCozinha.value = false;

    _loadNomeEmpresa();
    _atualizarHora();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _atualizarHora();
      if (timer.tick % 5 == 0) {
        buscarPedidos();
      }
    });
    buscarPedidos();
    _loadNumeroLicenca();
  }

  void limparPage(){
    // confirmar 
    listaPedidosSelecionados.clear();
    listaIndexPedidosSelecionados.clear();
    totalDePedidos = 0;
    totalDeTroco = 0;
    painelController.nomeMotoboySelecionado.value = "";
    painelController.numeroMotoboySelecionado.value = "";
    painelController.setMotoboy("", "");
    setState(() {
      isLoadingConfirmar = false;
      totalDePedidosString = "0,00";
      totalDeTrocoString = "0,00";
      nomeMotoboySelecionado = "";
      numeroMotoboySelecionado = "";
      motoboySelecionadoIndex = -1;
    });
  }

  // Carregar / Salvar licença || NUMERO TRADEPOINT
  Future<void> _loadNumeroLicenca() async {
    final prefs = await SharedPreferences.getInstance();
    final licencaSalvoNumero = prefs.getString('licencaNumero');
    if (licencaSalvoNumero != null && mounted) {
      setState(() {
        numeroTradepointSelecionada = licencaSalvoNumero;
      });
    }
  }

  void calcularValores(String valorLiquidoPedido, String trocoPara) {
    setState(() {
      double valorLiquido = double.tryParse(valorLiquidoPedido.replaceAll(',', '.')) ?? 0.0;
      double troco = double.tryParse(trocoPara.replaceAll(',', '.')) ?? 0.0;
    totalDePedidos += valorLiquido;
    totalDeTroco += troco;
      totalDePedidosString = totalDePedidos.toStringAsFixed(2).replaceAll('.', ',');
      totalDeTrocoString = totalDeTroco.toStringAsFixed(2).replaceAll('.', ',');
    });
  }

  void subtrairValores(String valorLiquidoPedido, String trocoPara) {
    setState(() {
      double valorLiquido = double.tryParse(valorLiquidoPedido.replaceAll(',', '.')) ?? 0.0;
      double troco = double.tryParse(trocoPara.replaceAll(',', '.')) ?? 0.0;
      totalDePedidos -= valorLiquido;
      totalDeTroco -= troco;
      totalDePedidosString = totalDePedidos.toStringAsFixed(2).replaceAll('.', ',');
      totalDeTrocoString = totalDeTroco.toStringAsFixed(2).replaceAll('.', ',');
    });
  }

  Future<void> atualizarStatusEntrega({
    required String numeroDelivery,
    required String numeroMotoboy,
  }) async {

    String sql = """
      UPDATE delivery
      SET
        statusentrega = '2',
        numeromotoboy_FK = '$numeroMotoboy',
        datahorachegada = CURRENT_TIMESTAMP
      WHERE numerodelivery = '$numeroDelivery';
    """;

    try {
      String resultado = await Connection().ipd(sql);

      if (resultado == 'sucesso') {
        print("Status da entrega atualizado com sucesso");
      } else {
        print(">>>>>Erro ao atualizar status da entrega: $resultado <<<<<<<<");
      }
    } catch (e) {
      print(">>>>>>Erro inesperado ao atualizar status da entrega: $e <<<<<<<<");
    }
  }

  Future<void> inserirLogEntrega({
    required String numeroPedido,
    required String numeroUsuario, // numero do motoboy 
    required String numeroTradepoint,
    required String nomeMotoboy,
  }) async {

    String sql = """
      INSERT INTO pedidoslog (
        numeropedido_FK,
        numerousuario_FK,
        numerotradepoint_FK,
        numerocaixa_FK,
        datahora,
        log
      )
      VALUES (
        '$numeroPedido',
        '$numeroUsuario',
        '$numeroTradepoint',
        '0',
        CURRENT_TIMESTAMP,
        'Confirmado a entrega do pedido para o motoboy: $nomeMotoboy'
      );
    """;

    try {
      String resultado = await Connection().ipd(sql);

      if (resultado == 'sucesso') {
        print("Log inserido com sucesso");
      } else {
        print(">>>>>Erro ao inserir log: $resultado <<<<<<<<");
      }
    } catch (e) {
      print(">>>>>Erro inesperado ao inserir log: $e <<<<<<<<");
    }
  }

  /* // Função para buscar valores do pedido
  Future<void> buscarInformacoesCliente(String numeropedido) async {
    // $numeropedido
    try {

      String dadosJson = await Connection().select(
        """
         SELECT
              p.abertura,
              p.fechamento,
              p.valorprodutos,
              p.valoradicionais,
              p.valorservico,
              p.valordesconto,
              p.valortotalliquido,
              p.pessoas,
              p.valortotalliquido / p.pessoas AS totalPorPessoa,
              c.numero AS numeroCliente,
              c.nome AS nomeCliente,
              c.telefone AS telefoneCliente,
              c.endereco AS enderecoCliente,
              c.numeroendereco AS numeroEnderecoCliente, 
              c.complemento AS complementoEnderecoCliente,
              c.bairro AS bairroEnderecoCliente
          FROM pedidos p
          LEFT JOIN clientes c
              ON c.numero = p.numerocliente_FK
          WHERE p.numero = '$numeropedido';
        """,
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        final valor = lista[0]['valorprodutos'].toString();
        final valor2 = lista[0]['valoradicionais'].toString();
        final valor3 = lista[0]['valorservico'].toString();
        final valor4 = lista[0]['valordesconto'].toString();
        final valor5 = lista[0]['valortotalliquido'].toString();
        final valor6 = lista[0]['pessoas'].toString();
        final valor7 = lista[0]['totalPorPessoa'].toString();
        final valor8 = lista[0]['abertura'].toString();
        final valor9 = lista[0]['fechamento'].toString();
        final valor10 = lista[0]['nomeCliente'].toString();
        final valor11 = lista[0]['telefoneCliente'].toString();
        final valor12 = lista[0]['enderecoCliente'].toString();
        final valor13 = lista[0]['numeroEnderecoCliente'].toString();
        final valor14 = lista[0]['complementoEnderecoCliente'].toString();
        final valor15 = lista[0]['bairroEnderecoCliente'].toString();

        final enderecoCompleto = "$valor12, $valor13, $valor14, $valor15";

        final aberturaFormatado = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.parse(valor8));
        final fechamentoFormatado = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.parse(valor9));

        setState(() {
          nomeClienteSelecionado = valor10;
          telefoneClienteSelecionado = valor11;
          enderecoClienteSelecionado = enderecoCompleto;
        });
      } else {
        setState(() {
          nomeClienteSelecionado = "";
          telefoneClienteSelecionado = "";
          enderecoClienteSelecionado = "";
        });
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
      setState(() {
        nomeClienteSelecionado = "";
        telefoneClienteSelecionado = "";
        enderecoClienteSelecionado = "";
      });
    }
  } */

  Future<void> buscarPedidos() async {
    try {

      /* String dadosJson = await Connection().select(
        """
        SELECT
            d.numero AS id_delivery,
            d.trocopara,
            d.valorliquidopedido,
            d.numerodelivery,

            p.status,
            p.entrega,
            p.numerocliente_FK,
            p.numero,

            d.numeromotoboy_FK,
            TIMEDIFF(NOW(), p.abertura) AS tempoAberto,
            d.statusentrega,
            d.atendimento,

            c.nome,
            c.telefone,
            c.endereco,
            c.numeroendereco,
            c.complemento,
            c.bairro

        FROM delivery d

        INNER JOIN pedidos p
            ON d.numero = p.numerodelivery_FK

        LEFT JOIN clientes c
            ON c.numero = p.numerocliente_FK

        WHERE d.numerodelivery != '0'
            AND (p.status = '1' OR p.status = '2')
            AND d.statusentrega != '2'
            AND p.entrega = '1'

        ORDER BY d.numerodelivery
        """,
      ); */

      String dadosJson = await Connection().select(
        """
         SELECT
            d.numero AS id_delivery,
            d.trocopara,
            d.valorliquidopedido,
            d.numerodelivery,
            d.integrador,

            p.status,
            p.entrega,
            p.numerocliente_FK,
            p.numero,

            d.numeromotoboy_FK,
            TIMEDIFF(NOW(), p.abertura) AS tempoAberto,
            d.statusentrega,
            d.atendimento,

            c.nome,
            c.telefone,
            c.endereco,
            c.numeroendereco,
            c.complemento,
            c.bairro

        FROM delivery d

        INNER JOIN pedidos p
            ON d.numero = p.numerodelivery_FK

        LEFT JOIN clientes c
            ON c.numero = p.numerocliente_FK

        WHERE d.numerodelivery != '0'
            AND (p.status = '1' OR p.status = '2')
            AND d.statusentrega != '2'
            AND p.entrega = '1'

        ORDER BY d.numerodelivery
        """,
      );
      

      List<dynamic> lista = jsonDecode(dadosJson);

      if (mounted) {
        setState(() {
          if (lista.isNotEmpty) {
            listaPedidos = lista;
          } else {
            listaPedidos = [];
          }
        });
      }
    } catch (e) {
      print("Erro ao buscar pedidos: $e");
      if (mounted) {
        setState(() {
          listaPedidos = [];
        });
      }
    }
  }

  // Load nomeEmpresa
  Future<void> _loadNomeEmpresa() async {
    final prefs = await SharedPreferences.getInstance();
    final nomeEmpresaSalvo = prefs.getString('nomeEmpresa');
    if (nomeEmpresaSalvo != null) {
      setState(() {
        nomeEmpresa = nomeEmpresaSalvo;
      });
    }
  }

  // Função para atualizar hora
  void _atualizarHora() {
    final agora = DateTime.now();
    final horaFormatada = DateFormat.Hm().format(agora);
    setState(() {
      _horaAtual = horaFormatada;
    });
  }

  Future<void> shownDialogaAlertTwoBottom({
    required BuildContext context,
    String title = 'Confirmação',
    IconData icon = Icons.home,
    String cancelText = 'Cancelar',
    String confirmText = 'Sim',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    dynamic message, // Alterado para dynamic para aceitar String ou Function
    dynamic message2, // Alterado para dynamic para aceitar String ou Function
    TextEditingController? textController,
    FocusNode? focusNode,
    ValueChanged<String>? onSubmitted, // Callback ao submeter o texto
  }) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return showDialog(
      context: context,
      barrierDismissible: false, // Não pode fechar tocando fora
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: isTablet ? size.width * 0.2 : 20,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: size.height * 0.9,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 18.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ícone central
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(
                              ctx,
                            ).colorScheme.scrim.withOpacity(0.08),
                          ),
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            icon,
                            size: 40,
                            color: Theme.of(ctx).colorScheme.scrim,
                          ),
                        ),

                        SizedBox(height: 10),

                        // Título opcional
                        if (title.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              title,
                              style: Theme.of(ctx).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // Texto centralizado (atualizado para ser reativo)
                        if (message != null)
                          Padding(
                            padding: EdgeInsets.only(bottom: 0.0),
                            child: Text(
                              message is Function
                                  ? (message as Function)()
                                  : message.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 15,
                                color: Theme.of(ctx).colorScheme.onSurface,
                              ),
                            ),
                          ),

                        SizedBox(height: 10),

                        // Botões centralizados e responsivos
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Botão Cancelar
                            Flexible(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  if (onCancel != null) onCancel();
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  backgroundColor: Theme.of(
                                    ctx,
                                  ).colorScheme.scrim,
                                  minimumSize: Size(100, 48),
                                ),
                                child: Text(
                                  cancelText.toUpperCase(),
                                  style: TextStyle(
                                    color: Theme.of(ctx).colorScheme.onPrimary,
                                    fontSize: 20,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            // Botão Confirmar
                            Flexible(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  if (onConfirm != null) onConfirm();
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  backgroundColor: Theme.of(
                                    ctx,
                                  ).colorScheme.primary,
                                  minimumSize: Size(100, 48),
                                ),
                                child: Text(
                                  confirmText.toUpperCase(),
                                  style: TextStyle(
                                    color: Theme.of(ctx).colorScheme.onPrimary,
                                    fontSize: 20,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMotoboysRowMaior() {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double fontPadrao = (screenWidth.clamp(600, 1920) * 0.012);
    final double fontTitulo = (screenWidth.clamp(600, 1920) * 0.014);
    final double paddingPadrao = screenWidth * 0.008;
    final double spacingPadrao = screenWidth * 0.005;
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Container(
        color: colorScheme.primary.withOpacity(0.1),
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    final itemWidth = maxWidth / painelController.listaMotoboys.length;
                    final double tamanhoQuadrado = (constraints.maxHeight * 0.9).clamp(60.0, 100.0);
                    return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: painelController.listaMotoboys.length,
                    itemBuilder: (context, index) {
                      final motoboy = painelController.listaMotoboys[index];
                      final nomeMotoboy = motoboy['nome'];
                      final numeroMotoboy = motoboy['numero'];
                      final bool selecionado = motoboySelecionadoIndex == index;
                      return GestureDetector(
                        onTap: () {
                          if(!selecionado){
                            painelController.setMotoboy(nomeMotoboy, numeroMotoboy);
                            setState(() {
                              numeroMotoboySelecionado = numeroMotoboy;
                              nomeMotoboySelecionado = nomeMotoboy;
                              motoboySelecionadoIndex = index;
                            });
                          } else {
                            painelController.setMotoboy("", "");
                            setState(() {
                              numeroMotoboySelecionado = "";
                              nomeMotoboySelecionado = "";
                              motoboySelecionadoIndex = -1;
                            });
                          }
                        },
                        child: Container(
                          height: tamanhoQuadrado,
                          width: tamanhoQuadrado,
                          margin: EdgeInsets.only(
                            top: 6,
                            left: 6,
                            right: 6,
                            bottom: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selecionado
                                ? colorScheme.primary
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '$numeroMotoboy $nomeMotoboy',
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: selecionado
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: fontPadrao,
                                    ),
                                  ),
                                  Icon(
                                    Icons.person,
                                    color: selecionado ? colorScheme.onPrimary : colorScheme.onSurface,
                                    size: fontPadrao,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        /* Card(
                          color: selecionado ? colorScheme.scrim : colorScheme.surface,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Center(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: selecionado ? colorScheme.onPrimary : colorScheme.onSurface,
                                  ),
                                  Text(
                                    '$numeroMotoboy - $nomeMotoboy',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: selecionado ? colorScheme.onPrimary : colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ), */
                      );
                    },
                  );
                },
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMotoboysRowMenor() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        color: colorScheme.primary.withOpacity(0.1),
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    final itemWidth = maxWidth / painelController.listaMotoboys.length;
                    final double tamanhoQuadrado = (constraints.maxHeight * 0.9).clamp(60.0, 100.0);
                    return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: painelController.listaMotoboys.length,
                    itemBuilder: (context, index) {
                      final motoboy = painelController.listaMotoboys[index];
                      final nomeMotoboy = motoboy['nome'];
                      final numeroMotoboy = motoboy['numero'];
                      final bool selecionado = motoboySelecionadoIndex == index;
                      return GestureDetector(
                        onTap: () {
                          if(!selecionado){
                            painelController.setMotoboy(nomeMotoboy, numeroMotoboy);
                            setState(() {
                              numeroMotoboySelecionado = numeroMotoboy;
                              nomeMotoboySelecionado = nomeMotoboy;
                              motoboySelecionadoIndex = index;
                            });
                          } else {
                            painelController.setMotoboy("", "");
                            setState(() {
                              numeroMotoboySelecionado = "";
                              nomeMotoboySelecionado = "";
                              motoboySelecionadoIndex = -1;
                            });
                          }
                        },
                        child: 
                        /* Container(
                          margin: EdgeInsets.only(
                            top: 6,
                            left: 6,
                            right: 6,
                            bottom: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selecionado
                                ? colorScheme.primary
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '$numeroMotoboy - $nomeMotoboy',
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: selecionado
                                          ? colorScheme.onPrimary
                                          : colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      fontSize: tamanhoQuadrado * 0.15,
                                    ),
                                  ),
                                  /* Icon(
                                    Icons.person,
                                    color: selecionado ? colorScheme.onPrimary : colorScheme.onSurface,
                                    size: tamanhoQuadrado * 0.10,
                                  ), */
                                ],
                              ),
                            ),
                          ),
                        ), */
                        Card(
                          color: selecionado ? colorScheme.scrim : colorScheme.surface,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            child: Center(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: selecionado ? colorScheme.onPrimary : colorScheme.onSurface,
                                    size: tamanhoQuadrado * 0.15,
                                  ),
                                  Text(
                                    '$numeroMotoboy - $nomeMotoboy',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: selecionado ? colorScheme.onPrimary : colorScheme.onSurface,
                                      fontSize: tamanhoQuadrado * 0.15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPedidosExpedicaoRow() {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    
    // Proporções para manter a responsividade
    final double fontPadrao = (screenWidth.clamp(600, 1920) * 0.012);
    final double fontTitulo = (screenWidth.clamp(600, 1920) * 0.014);
    final double paddingPadrao = screenWidth * 0.008;
    final double spacingPadrao = screenWidth * 0.005;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: paddingPadrao, vertical: paddingPadrao),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // build de pedidos 
          Expanded(
            flex: 3,
              child: Container(
              // color: colorScheme.secondary.withOpacity(0.1),
              child: Padding(
                padding: EdgeInsets.all(paddingPadrao),
                child: 
                // PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS 
                GridView.builder(
                  padding: EdgeInsets.all(paddingPadrao),
                  itemCount: listaPedidos.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: paddingPadrao,
                    childAspectRatio: 3,
                    // crossAxisSpacing: paddingPadrao,
                  ),
                  itemBuilder: (context, index) {
                    final pedido = listaPedidos[index];
                    final numeroDelivery = pedido['numerodelivery'].toString();
                    final trocoPara = pedido['trocopara'].toString();
                    final numeroPedido = pedido['numero'].toString();
                    final valorLiquidoPedido = pedido['valorliquidopedido'].toString();
                    final status = pedido['status'].toString();
                    final entrega = pedido['entrega'].toString();
                    final numerocliente_FK = pedido['numerocliente_FK'].toString();
                    final numero = pedido['numero'].toString();
                    final numeromotoboy_FK = pedido['numeromotoboy_FK'].toString();
                    final nomeClienteSelecionado = pedido['nome'].toString();
                    final telefoneClienteSelecionado = pedido['telefone'].toString();
                    final enderecoClienteSelecionado = pedido['endereco'].toString();
                    final numeroEnderecoClienteSelecionado = pedido['numeroendereco'].toString();
                    final complementoClienteSelecionado = pedido['complemento'].toString();
                    final bairroClienteSelecionado = pedido['bairro'].toString();

                    final timediff = pedido['tempoAberto'].toString();
                    final statusentrega = pedido['statusentrega'].toString();
                    final atendimento = pedido['atendimento'].toString(); 

                    // buscarInformacoesCliente(numeroPedido);

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        final novoPedido = {
                          'indexOriginal': index,
                          'numerodelivery': numeroDelivery,
                          'valorliquidopedido': valorLiquidoPedido,
                          'numeroPedido': numeroPedido,
                          'status': status,
                          'entrega': entrega,
                          'numerocliente_FK': numerocliente_FK,
                          'numero': numero,
                          'numeromotoboy_FK': numeromotoboy_FK,
                          'timediff': timediff,
                          'statusentrega': statusentrega,
                          'atendimento': atendimento,
                          'trocopara': trocoPara,
                          'nomeClienteSelecionado': nomeClienteSelecionado,
                          'enderecoClienteSelecionado': enderecoClienteSelecionado,
                          'numeroEnderecoClienteSelecionado': numeroEnderecoClienteSelecionado,
                          'bairroClienteSelecionado': bairroClienteSelecionado,
                        };

                        try {
                          // Verificar se o pedido já está selecionado
                          int indexExistente = listaPedidosSelecionados.indexWhere(
                            (p) => p['numerodelivery'] == novoPedido['numerodelivery']
                          );

                          if (indexExistente != -1) {
                            // Já está selecionado, remover (Toggle off)
                            subtrairValores(valorLiquidoPedido, trocoPara);
                            setState(() {
                              listaPedidosSelecionados.removeAt(indexExistente);
                              listaIndexPedidosSelecionados.remove(index);
                            });
                          } else {
                            // Não está selecionado, adicionar (Toggle on)
                            setState(() {
                              listaPedidosSelecionados.add(novoPedido);
                              listaIndexPedidosSelecionados.add(index);

                              // Ordenar lista por número de delivery
                              listaPedidosSelecionados.sort((a, b) {
                                int numA = int.tryParse(a['numerodelivery'].toString()) ?? 0;
                                int numB = int.tryParse(b['numerodelivery'].toString()) ?? 0;
                                return numA.compareTo(numB);
                              });

                              calcularValores(valorLiquidoPedido, trocoPara);
                            });
                          }
                        } catch (e) {
                          print('erro ao alternar seleção do pedido: $e');
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          // color: colorScheme.secondary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(screenWidth * 0.008),
                        ),
                        padding: EdgeInsets.all(spacingPadrao / 2),
                        child: 
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(paddingPadrao),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // CABEÇALHO: Número e Nome do Cliente
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(spacingPadrao / 2),
                                      decoration: BoxDecoration(
                                        color: listaIndexPedidosSelecionados.contains(index) ? colorScheme.scrim.withOpacity(0.1) : colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.motorcycle,
                                        size: fontPadrao * 2,
                                        color: listaIndexPedidosSelecionados.contains(index) ? colorScheme.scrim : colorScheme.primary,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        '#$numeroDelivery',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: fontPadrao * 1.8,
                                          fontWeight: FontWeight.bold,
                                          color: listaIndexPedidosSelecionados.contains(index) ? colorScheme.scrim : colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 15),
                                    Expanded(
                                      child: Text(
                                        nomeClienteSelecionado,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: fontPadrao * 1.2,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface.withOpacity(0.8),
                                        ),
                                      ),
                                    ),
                                    // VALOR EM DESTAQUE
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: listaIndexPedidosSelecionados.contains(index) ? colorScheme.scrim.withValues(alpha: 0.15) : colorScheme.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'R\$ $valorLiquidoPedido',
                                        style: TextStyle(
                                          fontSize: fontPadrao * 1.1,
                                          fontWeight: FontWeight.bold,
                                          color: listaIndexPedidosSelecionados.contains(index) ? colorScheme.scrim : colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                Divider(height: paddingPadrao * 2, thickness: 0.5),

                                // CONTEÚDO: Endereço e Troco
                                Flexible(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: fontPadrao * 1.3,
                                        color: listaIndexPedidosSelecionados.contains(index)
                                            ? colorScheme.scrim
                                            : colorScheme.primary,
                                      ),

                                      SizedBox(width: spacingPadrao),

                                      Expanded(
                                        child: RichText(
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontSize: fontPadrao,
                                              color: colorScheme.onSurface,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: '$enderecoClienteSelecionado, ',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              TextSpan(
                                                text: numeroEnderecoClienteSelecionado,
                                              ),
                                              TextSpan(
                                                text: '\n$bairroClienteSelecionado',
                                                style: TextStyle(
                                                  fontSize: fontPadrao * 0.9,
                                                  color: colorScheme.onSurface.withOpacity(0.6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                /* Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: fontPadrao * 1.4,
                                      color: listaIndexPedidosSelecionados.contains(index) ? colorScheme.scrim : colorScheme.primary,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$enderecoClienteSelecionado, $numeroEnderecoClienteSelecionado',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: fontPadrao,
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.onSurface.withOpacity(0.9),
                                            ),
                                          ),
                                          Text(
                                            bairroClienteSelecionado,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: fontPadrao * 0.9,
                                              color: colorScheme.onSurface.withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // ),
                                    /* if (trocoPara != '0' && trocoPara != '0.00' && trocoPara != 'null')
                                      Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Troco para',
                                              style: TextStyle(
                                                fontSize: fontPadrao * 0.7,
                                                color: colorScheme.onSurface.withOpacity(0.5),
                                              ),
                                            ),
                                            Text(
                                              'R\$ $trocoPara',
                                              style: TextStyle(
                                                fontSize: fontPadrao * 0.9,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface.withOpacity(0.8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ), */
                                  ],
                                ), */
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // FINAL PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS 
          SizedBox(width: spacingPadrao),
          // build de expedicao 
          Expanded(
            flex: 1,
            child: Container(
              color: colorScheme.secondary.withOpacity(0.1),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(paddingPadrao),
                              child: Text(
                                'Expedição',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: fontTitulo,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSecondary,
                                ),
                              ),
                            ),

                            // Lista com os pedidos - list view pedidos
                            if (listaPedidosSelecionados.isNotEmpty)
                              Column(
                                children: listaPedidosSelecionados.asMap().entries.map<Widget>((entry) {
                                  final indexNoPainel = entry.key;
                                  final pedido = entry.value;
                                  final numeroDelivery = pedido['numerodelivery'].toString();
                                  final valorLiquidoPedido = pedido['valorliquidopedido'].toString();
                                  final status = pedido['status'].toString();
                                  final entrega = pedido['entrega'].toString();
                                  final numerocliente_FK = pedido['numerocliente_FK'].toString();
                                  final numero = pedido['numero'].toString();
                                  final numeromotoboy_FK = pedido['numeromotoboy_FK'].toString();
                                  final timediff = pedido['timediff(now(),p.abertura)'].toString(); // hora abertura
                                  final statusentrega = pedido['statusentrega'].toString();
                                  final atendimento = pedido['atendimento'].toString();
                                  final numeroPedido = pedido['numeroPedido'].toString();
                                  final nomeClienteSelecionado = pedido['nomeClienteSelecionado'].toString();
                                  final enderecoClienteSelecionado = pedido['enderecoClienteSelecionado'].toString();
                                  final numeroEnderecoClienteSelecionado = pedido['numeroEnderecoClienteSelecionado'].toString();
                                  final bairroClienteSelecionado = pedido['bairroClienteSelecionado'].toString();
                                  final trocoPara = pedido['trocopara'].toString();
                                  return Card(
                                    child: ListTile(
                                      title: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            onPressed: (){
                                              // olhar pedido - select 
                                              Get.to(
                                                () => InformacoesPedidoPage(),
                                                arguments: {
                                                  'numeropedido': numeroPedido,
                                                  'numeroDelivery': numeroDelivery,
                                                  'page': "expedicao_motoboy",
                                                },
                                              );
                                            }, 
                                            icon: Icon(
                                              Icons.search,
                                              size: fontPadrao * 2,
                                            ),
                                          ),

                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text.rich(
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text: '#$numeroDelivery',
                                                        style: TextStyle(
                                                          fontSize: fontPadrao * 1.25,
                                                          fontWeight: FontWeight.bold,
                                                          color: colorScheme.scrim,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text: ' - R\$ $valorLiquidoPedido',
                                                        style: TextStyle(
                                                          fontSize: fontPadrao,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  nomeClienteSelecionado,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: fontPadrao,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              IconButton(
                                                onPressed: (){
                                                  if(listaPedidosSelecionados.isEmpty){
                                                    if (!mounted) return;
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Não há pedidos selecionados.',
                                                        ),
                                                        backgroundColor: colorScheme.error,
                                                      ),
                                                    );
                                                  } else {
                                                    int index = listaPedidosSelecionados.length;
                                                    subtrairValores(valorLiquidoPedido, trocoPara);
                                                    setState(() {
                                                      listaPedidosSelecionados.removeAt(indexNoPainel);
                                                      listaIndexPedidosSelecionados.remove(pedido['indexOriginal']);
                                                    });
                                                    /* shownDialogaAlertTwoBottom(
                                                      context: context,
                                                      title: 'Deseja excluir este pedido da lista?',
                                                      message2: () => '',
                                                      icon: Icons.error,
                                                      cancelText: 'Não',
                                                      confirmText: 'Sim',
                                                      onConfirm: () async {
                                                        subtrairValores(valorLiquidoPedido, trocoPara);
                                                        setState(() {
                                                          listaPedidosSelecionados.removeAt(indexNoPainel);
                                                          listaIndexPedidosSelecionados.remove(pedido['indexOriginal']);
                                                        });
                                                      },
                                                      onCancel: () {},
                                                    ); */
                                                  }
                                                }, 
                                                icon: Icon(
                                                  Icons.delete,
                                                  size: fontPadrao * 2,
                                                )
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            
                            Expanded(child: SizedBox()),
                           
                            // Tres botoes - Total de pedidos e total troco
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: spacingPadrao, vertical: spacingPadrao),
                              padding: EdgeInsets.all(paddingPadrao),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(screenWidth * 0.007),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Motoboy
                                  Container(
                                    decoration: BoxDecoration(
                                      color: nomeMotoboySelecionado == ""
                                          ? Colors.transparent
                                          : colorScheme.scrim.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: spacingPadrao, vertical: 0),
                                      child: Text(
                                        // Motoboy: 
                                        '${numeroMotoboySelecionado} - ${nomeMotoboySelecionado}',
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: fontTitulo * 1.1,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: spacingPadrao),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Total de Pedidos: ',
                                              textAlign: TextAlign.left,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: fontPadrao,
                                                color: colorScheme.onSecondary,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${totalDePedidosString}',
                                            textAlign: TextAlign.right,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: fontPadrao,
                                              color: colorScheme.onSecondary,
                                            ),
                                          ),
                                          /* Text(
                                            '${listaPedidosSelecionados.length}',
                                            textAlign: TextAlign.right,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: fontPadrao,
                                              color: colorScheme.onSecondary,
                                            ),
                                          ), */
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Total Troco: R\$ ',
                                              textAlign: TextAlign.left,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: fontPadrao,
                                                color: colorScheme.onSecondary,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${totalDeTrocoString}',
                                            textAlign: TextAlign.right,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: fontPadrao,
                                              color: colorScheme.onSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Botao de confirmar
                            isLoadingConfirmar ? CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.scrim,
                            ) : Padding(
                              padding: EdgeInsets.all(paddingPadrao),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  minimumSize: Size(double.infinity, screenWidth * 0.04),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.008),
                                  ),
                                ),
                                onPressed: () async {
                                  setState(() {
                                    isLoadingConfirmar = true;
                                  });
                                  if(listaPedidosSelecionados.isNotEmpty && painelController.numeroMotoboySelecionado.value != "" && painelController.nomeMotoboySelecionado.value != "" ){
                                    try{
                                      bool conectado = await Connection.conectarBanconoSalvar();
                                      await _loadNumeroLicenca();
                                      if(conectado){
                                        // update
                                        for(var pedido in listaPedidosSelecionados){
                                          await atualizarStatusEntrega(
                                            numeroDelivery: pedido['numerodelivery'].toString(),
                                            numeroMotoboy: painelController.numeroMotoboySelecionado.value,
                                          );

                                          await inserirLogEntrega(
                                            numeroPedido: pedido['numero'],
                                            numeroUsuario: painelController.numeroMotoboySelecionado.value,
                                            numeroTradepoint: numeroTradepointSelecionada,
                                            nomeMotoboy: painelController.nomeMotoboySelecionado.value,
                                          );
                                        }
                                        await buscarPedidos();
                                        limparPage();
                                      } else {
                                        isLoadingConfirmar = false;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Sem conexão com a internet'),
                                            backgroundColor: colorScheme.error,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Erro ao confirmar expedição'),
                                          backgroundColor: Theme.of(context).colorScheme.error,
                                        ),
                                      );
                                    } finally {
                                      /* // confirmar 
                                      listaPedidosSelecionados.clear();
                                      totalDePedidos = 0;
                                      totalDeTroco = 0;
                                      painelController.nomeMotoboySelecionado.value = "";
                                      painelController.numeroMotoboySelecionado.value = "";
                                      painelController.setMotoboy("", "");
                                      setState(() {
                                        isLoadingConfirmar = false;
                                        totalDePedidosString = "0,00";
                                        totalDeTrocoString = "0,00";
                                      }); */
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Selecione os pedidos e o motoboy'),
                                        backgroundColor: colorScheme.error,
                                      ),
                                    );
                                    setState(() {
                                      isLoadingConfirmar = false;
                                    });
                                  }
                                },
                                child: Text(
                                  'Confirmar',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontSize: fontPadrao,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidosExpedicaoColumn() {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    
    // Proporções para manter a responsividade
    final double fontPadrao = (screenWidth.clamp(600, 1920) * 0.015);
    final double fontTitulo = (screenWidth.clamp(600, 1920) * 0.022);
    final double paddingPadrao = screenWidth * 0.008;
    final double spacingPadrao = screenWidth * 0.005;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: paddingPadrao, vertical: paddingPadrao),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // build de pedidos 
          Expanded(
            flex: 1,
              child: Container(
              // color: colorScheme.secondary.withOpacity(0.1),
              child: Padding(
                padding: EdgeInsets.all(paddingPadrao),
                child: 
                // PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS 
                GridView.builder(
                  padding: EdgeInsets.all(paddingPadrao),
                  itemCount: listaPedidos.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    // crossAxisCount: 2,
                    crossAxisCount: 1,
                    mainAxisSpacing: paddingPadrao,
                    childAspectRatio: 4,
                    // crossAxisSpacing: paddingPadrao,
                  ),
                  itemBuilder: (context, index) {
                    final pedido = listaPedidos[index];
                    final numeroDelivery = pedido['numerodelivery'].toString();
                    final trocoPara = pedido['trocopara'].toString();
                    final numeroPedido = pedido['numero'].toString();
                    final valorLiquidoPedido = pedido['valorliquidopedido'].toString();
                    final status = pedido['status'].toString();
                    final entrega = pedido['entrega'].toString();
                    final numerocliente_FK = pedido['numerocliente_FK'].toString();
                    final numero = pedido['numero'].toString();
                    final numeromotoboy_FK = pedido['numeromotoboy_FK'].toString();
                    final nomeClienteSelecionado = pedido['nome'].toString();
                    final telefoneClienteSelecionado = pedido['telefone'].toString();
                    final enderecoClienteSelecionado = pedido['endereco'].toString();
                    final numeroEnderecoClienteSelecionado = pedido['numeroendereco'].toString();
                    final complementoClienteSelecionado = pedido['complemento'].toString();
                    final bairroClienteSelecionado = pedido['bairro'].toString();

                    final timediff = pedido['tempoAberto'].toString();
                    final statusentrega = pedido['statusentrega'].toString();
                    final atendimento = pedido['atendimento'].toString(); 

                    // buscarInformacoesCliente(numeroPedido);

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        final novoPedido = {
                          'indexOriginal': index,
                          'numerodelivery': numeroDelivery,
                          'valorliquidopedido': valorLiquidoPedido,
                          'numeroPedido': numeroPedido,
                          'status': status,
                          'entrega': entrega,
                          'numerocliente_FK': numerocliente_FK,
                          'numero': numero,
                          'numeromotoboy_FK': numeromotoboy_FK,
                          'timediff': timediff,
                          'statusentrega': statusentrega,
                          'atendimento': atendimento,
                          'trocopara': trocoPara,
                          'nomeClienteSelecionado': nomeClienteSelecionado,
                          'enderecoClienteSelecionado': enderecoClienteSelecionado,
                          'numeroEnderecoClienteSelecionado': numeroEnderecoClienteSelecionado,
                          'bairroClienteSelecionado': bairroClienteSelecionado,
                        };

                        try {
                          // Verificar se o pedido já está selecionado
                          int indexExistente = listaPedidosSelecionados.indexWhere(
                            (p) => p['numerodelivery'] == novoPedido['numerodelivery']
                          );

                          if (indexExistente != -1) {
                            // Já está selecionado, remover (Toggle off)
                            subtrairValores(valorLiquidoPedido, trocoPara);
                            setState(() {
                              listaPedidosSelecionados.removeAt(indexExistente);
                              listaIndexPedidosSelecionados.remove(index);
                            });
                          } else {
                            // Não está selecionado, adicionar (Toggle on)
                            setState(() {
                              listaPedidosSelecionados.add(novoPedido);
                              listaIndexPedidosSelecionados.add(index);

                              // Ordenar lista por número de delivery
                              listaPedidosSelecionados.sort((a, b) {
                                int numA = int.tryParse(a['numerodelivery'].toString()) ?? 0;
                                int numB = int.tryParse(b['numerodelivery'].toString()) ?? 0;
                                return numA.compareTo(numB);
                              });

                              calcularValores(valorLiquidoPedido, trocoPara);
                            });
                          }
                        } catch (e) {
                          print('erro ao alternar seleção do pedido: $e');
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          // color: colorScheme.secondary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(screenWidth * 0.008),
                        ),
                        padding: EdgeInsets.all(spacingPadrao / 2),
                        child: 
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(paddingPadrao),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // CABEÇALHO: Número e Nome do Cliente
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(spacingPadrao / 2),
                                      decoration: BoxDecoration(
                                        color: listaIndexPedidosSelecionados.contains(index) ? colorScheme.scrim.withOpacity(0.1) : colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.motorcycle,
                                        size: fontPadrao * 2,
                                        color: listaIndexPedidosSelecionados.contains(index) ? colorScheme.scrim : colorScheme.primary,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        '#$numeroDelivery',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: fontPadrao * 1.8,
                                          fontWeight: FontWeight.bold,
                                          color: listaIndexPedidosSelecionados.contains(index) ? colorScheme.scrim : colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 15),
                                    Expanded(
                                      child: Text(
                                        nomeClienteSelecionado,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: fontPadrao * 1.2,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface.withOpacity(0.8),
                                        ),
                                      ),
                                    ),
                                    // VALOR EM DESTAQUE
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: listaIndexPedidosSelecionados.contains(index) ? colorScheme.scrim.withValues(alpha: 0.15) : colorScheme.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'R\$ $valorLiquidoPedido',
                                        style: TextStyle(
                                          fontSize: fontPadrao * 1.1,
                                          fontWeight: FontWeight.bold,
                                          color: listaIndexPedidosSelecionados.contains(index) ? colorScheme.scrim : colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                Divider(height: paddingPadrao * 2, thickness: 0.5),

                                // CONTEÚDO: Endereço e Troco
                                Flexible(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: fontPadrao * 1.3,
                                        color: listaIndexPedidosSelecionados.contains(index)
                                            ? colorScheme.scrim
                                            : colorScheme.primary,
                                      ),

                                      SizedBox(width: spacingPadrao),

                                      Expanded(
                                        child: RichText(
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontSize: fontPadrao,
                                              color: colorScheme.onSurface,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: '$enderecoClienteSelecionado, ',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              TextSpan(
                                                text: numeroEnderecoClienteSelecionado,
                                              ),
                                              TextSpan(
                                                text: '\n$bairroClienteSelecionado',
                                                style: TextStyle(
                                                  fontSize: fontPadrao * 0.9,
                                                  color: colorScheme.onSurface.withOpacity(0.6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                /* Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: fontPadrao * 1.4,
                                      color: listaIndexPedidosSelecionados.contains(index) ? colorScheme.scrim : colorScheme.primary,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$enderecoClienteSelecionado, $numeroEnderecoClienteSelecionado',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: fontPadrao,
                                              fontWeight: FontWeight.w500,
                                              color: colorScheme.onSurface.withOpacity(0.9),
                                            ),
                                          ),
                                          Text(
                                            bairroClienteSelecionado,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: fontPadrao * 0.9,
                                              color: colorScheme.onSurface.withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // ),
                                    /* if (trocoPara != '0' && trocoPara != '0.00' && trocoPara != 'null')
                                      Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Troco para',
                                              style: TextStyle(
                                                fontSize: fontPadrao * 0.7,
                                                color: colorScheme.onSurface.withOpacity(0.5),
                                              ),
                                            ),
                                            Text(
                                              'R\$ $trocoPara',
                                              style: TextStyle(
                                                fontSize: fontPadrao * 0.9,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface.withOpacity(0.8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ), */
                                  ],
                                ), */
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // FINAL PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS PEDIDOS 
          SizedBox(width: spacingPadrao),
          // build de expedicao 
          Expanded(
            flex: 1,
            child: Container(
              color: colorScheme.secondary.withOpacity(0.1),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(paddingPadrao),
                              child: Text(
                                'Expedição',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: fontTitulo,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSecondary,
                                ),
                              ),
                            ),

                            // Lista com os pedidos - list view pedidos
                            if (listaPedidosSelecionados.isNotEmpty)
                              Column(
                                children: listaPedidosSelecionados.asMap().entries.map<Widget>((entry) {
                                  final indexNoPainel = entry.key;
                                  final pedido = entry.value;
                                  final numeroDelivery = pedido['numerodelivery'].toString();
                                  final valorLiquidoPedido = pedido['valorliquidopedido'].toString();
                                  final status = pedido['status'].toString();
                                  final entrega = pedido['entrega'].toString();
                                  final numerocliente_FK = pedido['numerocliente_FK'].toString();
                                  final numero = pedido['numero'].toString();
                                  final numeromotoboy_FK = pedido['numeromotoboy_FK'].toString();
                                  final timediff = pedido['timediff(now(),p.abertura)'].toString(); // hora abertura
                                  final statusentrega = pedido['statusentrega'].toString();
                                  final atendimento = pedido['atendimento'].toString();
                                  final numeroPedido = pedido['numeroPedido'].toString();
                                  final nomeClienteSelecionado = pedido['nomeClienteSelecionado'].toString();
                                  final enderecoClienteSelecionado = pedido['enderecoClienteSelecionado'].toString();
                                  final numeroEnderecoClienteSelecionado = pedido['numeroEnderecoClienteSelecionado'].toString();
                                  final bairroClienteSelecionado = pedido['bairroClienteSelecionado'].toString();
                                  final trocoPara = pedido['trocopara'].toString();
                                  return Card(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: ListTile(
                                      dense: true,
                                      minVerticalPadding: 0,
                                      title: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            onPressed: (){
                                              // olhar pedido - select 
                                              Get.to(
                                                () => InformacoesPedidoPage(),
                                                arguments: {
                                                  'numeropedido': numeroPedido,
                                                  'numeroDelivery': numeroDelivery,
                                                  'page': "expedicao_motoboy",
                                                },
                                              );
                                            }, 
                                            icon: Icon(
                                              Icons.search,
                                              size: fontPadrao * 2,
                                            ),
                                          ),

                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text.rich(
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text: '#$numeroDelivery',
                                                        style: TextStyle(
                                                          fontSize: fontPadrao * 1.25,
                                                          fontWeight: FontWeight.bold,
                                                          color: colorScheme.scrim,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text: ' - R\$ $valorLiquidoPedido - $nomeClienteSelecionado',
                                                        style: TextStyle(
                                                          fontSize: fontPadrao,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                /* Text(
                                                  nomeClienteSelecionado,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: fontPadrao,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ), */
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              IconButton(
                                                onPressed: (){
                                                  if(listaPedidosSelecionados.isEmpty){
                                                    if (!mounted) return;
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Não há pedidos selecionados.',
                                                        ),
                                                        backgroundColor: colorScheme.error,
                                                      ),
                                                    );
                                                  } else {
                                                    int index = listaPedidosSelecionados.length;
                                                    subtrairValores(valorLiquidoPedido, trocoPara);
                                                    setState(() {
                                                      listaPedidosSelecionados.removeAt(indexNoPainel);
                                                      listaIndexPedidosSelecionados.remove(pedido['indexOriginal']);
                                                    });
                                                    /* shownDialogaAlertTwoBottom(
                                                      context: context,
                                                      title: 'Deseja excluir este pedido da lista?',
                                                      message2: () => '',
                                                      icon: Icons.error,
                                                      cancelText: 'Não',
                                                      confirmText: 'Sim',
                                                      onConfirm: () async {
                                                        subtrairValores(valorLiquidoPedido, trocoPara);
                                                        setState(() {
                                                          listaPedidosSelecionados.removeAt(indexNoPainel);
                                                          listaIndexPedidosSelecionados.remove(pedido['indexOriginal']);
                                                        });
                                                      },
                                                      onCancel: () {},
                                                    ); */
                                                  }
                                                }, 
                                                icon: Icon(
                                                  Icons.delete,
                                                  size: fontPadrao * 2,
                                                )
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            
                            Expanded(child: SizedBox()),
                           
                            // Tres botoes - Total de pedidos e total troco
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: spacingPadrao, vertical: spacingPadrao),
                              padding: EdgeInsets.all(paddingPadrao),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(screenWidth * 0.007),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Motoboy
                                  Container(
                                    decoration: BoxDecoration(
                                      color: nomeMotoboySelecionado == ""
                                          ? Colors.transparent
                                          : colorScheme.scrim.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: spacingPadrao, vertical: 0),
                                      child: Text(
                                        // Motoboy: 
                                        '${numeroMotoboySelecionado} - ${nomeMotoboySelecionado}',
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: fontTitulo * 1.1,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: spacingPadrao),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Total de Pedidos: ',
                                              textAlign: TextAlign.left,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: fontPadrao * 1.2,
                                                color: colorScheme.onSecondary,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${totalDePedidosString}',
                                            textAlign: TextAlign.right,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: fontPadrao * 1.2,
                                              color: colorScheme.onSecondary,
                                            ),
                                          ),
                                          /* Text(
                                            '${listaPedidosSelecionados.length}',
                                            textAlign: TextAlign.right,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: fontPadrao,
                                              color: colorScheme.onSecondary,
                                            ),
                                          ), */
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Total Troco: R\$ ',
                                              textAlign: TextAlign.left,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: fontPadrao * 1.2,
                                                color: colorScheme.onSecondary,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${totalDeTrocoString}',
                                            textAlign: TextAlign.right,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: fontPadrao * 1.2,
                                              color: colorScheme.onSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Botao de confirmar
                            isLoadingConfirmar ? CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.scrim,
                            ) : Padding(
                              padding: EdgeInsets.all(paddingPadrao),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  minimumSize: const Size(double.infinity, 40),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.008),
                                  ),
                                ),
                                onPressed: () async {
                                  setState(() {
                                    isLoadingConfirmar = true;
                                  });
                                  if(listaPedidosSelecionados.isNotEmpty && painelController.numeroMotoboySelecionado.value != "" && painelController.nomeMotoboySelecionado.value != "" ){
                                    try{
                                      bool conectado = await Connection.conectarBanconoSalvar();
                                      await _loadNumeroLicenca();
                                      if(conectado){
                                        // update
                                        for(var pedido in listaPedidosSelecionados){
                                          await atualizarStatusEntrega(
                                            numeroDelivery: pedido['numerodelivery'].toString(),
                                            numeroMotoboy: painelController.numeroMotoboySelecionado.value,
                                          );

                                          await inserirLogEntrega(
                                            numeroPedido: pedido['numero'],
                                            numeroUsuario: painelController.numeroMotoboySelecionado.value,
                                            numeroTradepoint: numeroTradepointSelecionada,
                                            nomeMotoboy: painelController.nomeMotoboySelecionado.value,
                                          );
                                        }
                                        await buscarPedidos();
                                        limparPage();
                                      } else {
                                        isLoadingConfirmar = false;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Sem conexão com a internet'),
                                            backgroundColor: colorScheme.error,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Erro ao confirmar expedição'),
                                          backgroundColor: Theme.of(context).colorScheme.error,
                                        ),
                                      );
                                    } finally {
                                      /* // confirmar 
                                      listaPedidosSelecionados.clear();
                                      totalDePedidos = 0;
                                      totalDeTroco = 0;
                                      painelController.nomeMotoboySelecionado.value = "";
                                      painelController.numeroMotoboySelecionado.value = "";
                                      painelController.setMotoboy("", "");
                                      setState(() {
                                        isLoadingConfirmar = false;
                                        totalDePedidosString = "0,00";
                                        totalDeTrocoString = "0,00";
                                      }); */
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Selecione os pedidos e o motoboy'),
                                        backgroundColor: colorScheme.error,
                                      ),
                                    );
                                    setState(() {
                                      isLoadingConfirmar = false;
                                    });
                                  }
                                },
                                child: Text(
                                  'Confirmar',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontSize: fontPadrao * 1.3,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridMotoboysColumn() {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double paddingPadrao = availableWidth * 0.01;
        final double spacingPadrao = availableWidth * 0.008;
        final double fontPadraoLetras = (availableWidth * 0.030) * 1.5;
        final double fontPadraoNumeros = (availableWidth * 0.050) * 1.5;

        // Tamanho mínimo de cada card de pedido: ajusta dynamicamente as colunas
        const double cardMinWidth = 140.0;
        final int cols = (availableWidth / cardMinWidth).floor().clamp(2, 8);

        if (listaPedidos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.motorcycle, size: 64, color: colorScheme.primary.withOpacity(0.4)),
                SizedBox(height: 16),
                Text(
                  'Nenhum pedido para expedição',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(paddingPadrao),
          itemCount: listaPedidos.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: spacingPadrao * 2,
            crossAxisSpacing: spacingPadrao * 2,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final pedido = listaPedidos[index];
            final numeroDelivery = pedido['numerodelivery'].toString();
            final trocoPara = pedido['trocopara'].toString();
            final numeroPedido = pedido['numero'].toString();
            final valorLiquidoPedido = pedido['valorliquidopedido'].toString();
            final status = pedido['status'].toString();
            final entrega = pedido['entrega'].toString();
            final numerocliente_FK = pedido['numerocliente_FK'].toString();
            final numero = pedido['numero'].toString();
            final numeromotoboy_FK = pedido['numeromotoboy_FK'].toString();
            final nomeClienteSelecionado = pedido['nome'].toString();
            final enderecoClienteSelecionado = pedido['endereco'].toString();
            final numeroEnderecoClienteSelecionado = pedido['numeroendereco'].toString();
            final bairroClienteSelecionado = pedido['bairro'].toString();
            final timediff = pedido['tempoAberto'].toString();
            final statusentrega = pedido['statusentrega'].toString();
            final atendimento = pedido['atendimento'].toString();
            final integrador = pedido['integrador'].toString();

            final corGrid = integrador.contains("PEDEAQUI") 
                ? const Color.fromARGB(255, 177, 167, 179)
                : integrador.contains("IFOOD")
                ? const Color.fromARGB(255, 240, 147, 140)
                : colorScheme.secondary;

            final corTexto = integrador.contains("PEDEAQUI")
                ? const Color.fromARGB(255, 73, 21, 82)
                : integrador.contains("IFOOD") || integrador.contains("P10") || integrador.contains("P 10")
                ? const Color.fromARGB(255, 154, 33, 24)
                : integrador.contains("NEEMO")
                ? colorScheme.scrim
                : integrador.contains("99FOOD")
                ? const Color.fromARGB(255, 236, 162, 2)
                : integrador.contains("ANOTA AI")
                ? const Color.fromARGB(255, 27, 88, 220)
                : colorScheme.primary;

            // se tiver vazio n escreve gourmet 
            String nomeIntegrador = integrador.contains("PEDEAQUI")
                ? "PEDEAQUI"
                : integrador.contains("IFOOD")
                ? "IFOOD"
                : integrador.contains("P10") || integrador.contains("P 10")
                ? "P10"
                : integrador.contains("NEEMO")
                ? "NEEMO"
                : integrador.contains("99FOOD")
                ? "99FOOD"
                : integrador.contains("ANOTA AI")
                ? "ANOTA AI"
                : "";

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // Limpa seleções anteriores e abre popup com este pedido
                listaPedidosSelecionados.clear();
                listaIndexPedidosSelecionados.clear();

                final novoPedido = {
                  'indexOriginal': index,
                  'numerodelivery': numeroDelivery,
                  'valorliquidopedido': valorLiquidoPedido,
                  'numeroPedido': numeroPedido,
                  'status': status,
                  'entrega': entrega,
                  'numerocliente_FK': numerocliente_FK,
                  'numero': numero,
                  'numeromotoboy_FK': numeromotoboy_FK,
                  'timediff': timediff,
                  'statusentrega': statusentrega,
                  'atendimento': atendimento,
                  'trocopara': trocoPara,
                  'nomeClienteSelecionado': nomeClienteSelecionado,
                  'enderecoClienteSelecionado': enderecoClienteSelecionado,
                  'numeroEnderecoClienteSelecionado': numeroEnderecoClienteSelecionado,
                  'bairroClienteSelecionado': bairroClienteSelecionado,
                  'integrador': integrador,
                };

                listaPedidosSelecionados.add(novoPedido);
                listaIndexPedidosSelecionados.add(index);

                popupSelecionarMotoboy(
                  listaPedidosSelecionados,
                  enderecoClienteSelecionado,
                  numeroEnderecoClienteSelecionado,
                  bairroClienteSelecionado,
                  integrador,
                  numeroDelivery,
                  nomeClienteSelecionado,
                  valorLiquidoPedido
                );
              },
              child: Card(
                elevation: 3,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                // color: corGrid,
                child: Padding(
                  padding: EdgeInsets.all(paddingPadrao.clamp(8.0, 16.0)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Número do delivery
                      Text(
                        '#$numeroDelivery#',
                        style: TextStyle(
                          fontSize: fontPadraoNumeros,
                          fontWeight: FontWeight.bold,
                          color: corTexto,
                        ),
                      ),

                      // Ícone da moto
                      Icon(
                        Icons.motorcycle,
                        size: fontPadraoLetras * 4,
                        color: corTexto,
                      ),

                      // Cliente
                      Text(
                        nomeClienteSelecionado,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontPadraoLetras * 0.9,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),

                      // Intergrador
                      if(nomeIntegrador != "")
                      Padding(
                        padding: EdgeInsets.only(bottom: 2.0),
                        child: Text(
                          nomeIntegrador,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: fontPadraoLetras * 0.6,
                            fontWeight: FontWeight.w600,
                            color: corTexto,
                          ),
                        ),
                      ),

                      // Valor
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: corTexto.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'R\$ $valorLiquidoPedido',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: fontPadraoLetras,
                            fontWeight: FontWeight.w600,
                            color: corTexto,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGridMotoboysRow() {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;

        // Limita o tamanho máximo para evitar componentes gigantes em monitores ou TVs
        final double minDimension = availableWidth < availableHeight ? availableWidth : availableHeight;
        
        final double paddingPadrao = (minDimension * 0.02).clamp(8.0, 16.0);
        final double spacingPadrao = (minDimension * 0.02).clamp(8.0, 16.0);
        
        // Fontes dinâmicas com limites (clamp) para evitar textos minúsculos ou enormes
        final double fontPadraoLetras = (availableWidth * 0.015).clamp(11.0, 16.0);
        final double fontPadraoNumeros = (availableWidth * 0.025).clamp(16.0, 24.0);

        // Tamanho mínimo de cada card de pedido para ajustar as colunas
        const double cardMinWidth = 160.0;
        final int cols = (availableWidth / cardMinWidth).floor().clamp(2, 8);

        // Calcula a relação de aspecto com base na proporção de colunas e espaço em tela
        final double cardWidth = (availableWidth - (paddingPadrao * 2) - (spacingPadrao * (cols - 1))) / cols;
        final double desiredCardHeight = (availableHeight * 0.35).clamp(150.0, 220.0);
        final double calculatedAspectRatio = cardWidth / desiredCardHeight;

        if (listaPedidos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.motorcycle, size: 64, color: colorScheme.primary.withOpacity(0.4)),
                SizedBox(height: 16),
                Text(
                  'Nenhum pedido para expedição',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(paddingPadrao),
          itemCount: listaPedidos.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: spacingPadrao,
            crossAxisSpacing: spacingPadrao,
            childAspectRatio: calculatedAspectRatio,
          ),
          itemBuilder: (context, index) {
            final pedido = listaPedidos[index];
            final numeroDelivery = pedido['numerodelivery'].toString();
            final trocoPara = pedido['trocopara'].toString();
            final numeroPedido = pedido['numero'].toString();
            final valorLiquidoPedido = pedido['valorliquidopedido'].toString();
            final status = pedido['status'].toString();
            final entrega = pedido['entrega'].toString();
            final numerocliente_FK = pedido['numerocliente_FK'].toString();
            final numero = pedido['numero'].toString();
            final numeromotoboy_FK = pedido['numeromotoboy_FK'].toString();
            final nomeClienteSelecionado = pedido['nome'].toString();
            final enderecoClienteSelecionado = pedido['endereco'].toString();
            final numeroEnderecoClienteSelecionado = pedido['numeroendereco'].toString();
            final bairroClienteSelecionado = pedido['bairro'].toString();
            final timediff = pedido['tempoAberto'].toString();
            final statusentrega = pedido['statusentrega'].toString();
            final atendimento = pedido['atendimento'].toString();
            final integrador = pedido['integrador'].toString();

            final corGrid = integrador.contains("PEDEAQUI") 
                ? const Color.fromARGB(255, 177, 167, 179)
                : integrador.contains("IFOOD")
                ? const Color.fromARGB(255, 240, 147, 140)
                : colorScheme.secondary;

            final corTexto = integrador.contains("PEDEAQUI")
                ? const Color.fromARGB(255, 73, 21, 82)
                : integrador.contains("IFOOD") || integrador.contains("P10") || integrador.contains("P 10")
                ? const Color.fromARGB(255, 154, 33, 24)
                : integrador.contains("NEEMO")
                ? colorScheme.scrim
                : integrador.contains("99FOOD")
                ? const Color.fromARGB(255, 178, 122, 3)
                : integrador.contains("ANOTA AI")
                ? const Color.fromARGB(255, 27, 88, 220)
                : colorScheme.primary;

            // se tiver vazio n escreve gourmet 
            String nomeIntegrador = integrador.contains("PEDEAQUI")
                ? "PEDEAQUI"
                : integrador.contains("IFOOD")
                ? "IFOOD"
                : integrador.contains("P10") || integrador.contains("P 10")
                ? "P10"
                : integrador.contains("NEEMO")
                ? "NEEMO"
                : integrador.contains("99FOOD")
                ? "99FOOD"
                : integrador.contains("ANOTA AI")
                ? "ANOTA AI"
                : "";

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // Limpa seleções anteriores e abre popup com este pedido
                listaPedidosSelecionados.clear();
                listaIndexPedidosSelecionados.clear();

                final novoPedido = {
                  'indexOriginal': index,
                  'numerodelivery': numeroDelivery,
                  'valorliquidopedido': valorLiquidoPedido,
                  'numeroPedido': numeroPedido,
                  'status': status,
                  'entrega': entrega,
                  'numerocliente_FK': numerocliente_FK,
                  'numero': numero,
                  'numeromotoboy_FK': numeromotoboy_FK,
                  'timediff': timediff,
                  'statusentrega': statusentrega,
                  'atendimento': atendimento,
                  'trocopara': trocoPara,
                  'nomeClienteSelecionado': nomeClienteSelecionado,
                  'enderecoClienteSelecionado': enderecoClienteSelecionado,
                  'numeroEnderecoClienteSelecionado': numeroEnderecoClienteSelecionado,
                  'bairroClienteSelecionado': bairroClienteSelecionado,
                  'integrador': integrador,
                };

                listaPedidosSelecionados.add(novoPedido);
                listaIndexPedidosSelecionados.add(index);

                popupSelecionarMotoboy(
                  listaPedidosSelecionados,
                  enderecoClienteSelecionado,
                  numeroEnderecoClienteSelecionado,
                  bairroClienteSelecionado,
                  integrador,
                  numeroDelivery,
                  nomeClienteSelecionado,
                  valorLiquidoPedido
                );
              },
              child: Card(
                elevation: 3,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                // color: corGrid,
                child: Padding(
                  padding: EdgeInsets.all(paddingPadrao.clamp(8.0, 16.0)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Número do delivery
                      Text(
                        '#$numeroDelivery#',
                        style: TextStyle(
                          fontSize: fontPadraoNumeros,
                          fontWeight: FontWeight.bold,
                          color: corTexto,
                        ),
                      ),

                      // Ícone da moto
                      Icon(
                        Icons.motorcycle,
                        size: fontPadraoLetras * 4,
                        color: corTexto,
                      ),

                      // Cliente
                      Text(
                        nomeClienteSelecionado,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontPadraoLetras * 0.9,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),

                      // Intergrador
                      if(nomeIntegrador != "")
                      Padding(
                        padding: EdgeInsets.only(bottom: 2.0),
                        child: Text(
                          nomeIntegrador,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: fontPadraoLetras * 0.6,
                            fontWeight: FontWeight.w600,
                            color: corTexto,
                          ),
                        ),
                      ),

                      // Valor
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: corTexto.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'R\$ $valorLiquidoPedido',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: fontPadraoLetras,
                                fontWeight: FontWeight.w600,
                                color: corTexto,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void popupSelecionarMotoboy(
    List<dynamic> listaPedidosSelecionadosFuncao,
    enderecoClienteSelecionado,
    numeroEnderecoClienteSelecionado,
    bairroClienteSelecionado,
    String integrador,
    String numeroPedidoSelecionado,
    String nomeCliente,
    String valorPedido,
  ) {
    // Estado local do popup
    String motoboyNumeroLocal = "";
    String motoboyNomeLocal = "";
    int motoboyIndexLocal = -1;
    bool carregando = false;
    bool motoboySelecionado = false;
    String numeroPedidoSelecionadoLocal = numeroPedidoSelecionado;
    String nomeClienteLocal = nomeCliente;
    String valorPedidoLocal = valorPedido;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return StatefulBuilder(
          builder: (ctx, setPopupState) {
            final double screenWidth = MediaQuery.of(ctx).size.width;
            final double screenHeight = MediaQuery.of(ctx).size.height;
            final double dialogMaxWidth = screenWidth > 600 ? 600.0 : screenWidth * 0.95;
            final double dialogMaxHeight = screenHeight * 0.90;
            
            final double fontPadraoLetras = (dialogMaxWidth * 0.04).clamp(13.0, 16.0);
            
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogMaxWidth,
                  maxHeight: dialogMaxHeight,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ──
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.motorcycle, color: colorScheme.onPrimary, size: 24),
                          SizedBox(width: 10),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Confirmação de pedido',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                          // Botão fechar (X)
                          GestureDetector(
                            onTap: () {
                              listaPedidosSelecionados.clear();
                              listaIndexPedidosSelecionados.clear();
                              Navigator.of(dialogContext).pop();
                            },
                            child: Icon(Icons.close, color: colorScheme.onPrimary),
                          ),
                        ],
                      ),
                    ),

                    // ── Informações do pedido ──
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        children: [
                          Text(
                            "#$numeroPedidoSelecionadoLocal#",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            "$nomeClienteLocal - R\$ $valorPedidoLocal",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on, size: 18, color: colorScheme.primary),
                              SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      '$enderecoClienteSelecionado, $numeroEnderecoClienteSelecionado — $bairroClienteSelecionado',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colorScheme.onSurface.withOpacity(0.75),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Lista de motoboys em Grid responsiva
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: painelController.listaMotoboys.isEmpty
                            ? Center(
                                child: Text("Nenhum motoboy encontrado"),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  // Largura mínima desejada para cada item
                                  double larguraMinimaItem = 120.0;

                                  // Calcula automaticamente quantas colunas cabem
                                  int colunas = (constraints.maxWidth / larguraMinimaItem).floor().clamp(1, 10);

                                  return GridView.builder(
                                    padding: EdgeInsets.only(top: 8.0),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: colunas,
                                      crossAxisSpacing: 8.0,
                                      mainAxisSpacing: 8.0,
                                      childAspectRatio: 1.2,
                                    ),
                                    itemCount: painelController.listaMotoboys.length,
                                    itemBuilder: (context, index) {
                                      final motoboy = painelController.listaMotoboys[index];

                                      final selecionado = motoboySelecionado && nomeMotoboySelecionado == motoboy['nome'];

                                      return Card(
                                        margin: EdgeInsets.zero,
                                        color: selecionado ? colorScheme.scrim : null,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(12),
                                          onTap: () {
                                            if (selecionado) {
                                              motoboyNomeLocal = "";
                                              motoboyNumeroLocal = "";
                                              motoboyIndexLocal = -1;

                                              setPopupState(() {
                                                motoboySelecionado = false;
                                                nomeMotoboySelecionado = "";
                                                numeroMotoboySelecionado = "";
                                              });
                                            } else {
                                              motoboyNomeLocal = motoboy['nome'];
                                              motoboyNumeroLocal = motoboy['numero'];
                                              motoboyIndexLocal = index;

                                              setPopupState(() {
                                                motoboySelecionado = true;
                                                nomeMotoboySelecionado = motoboyNomeLocal;
                                                numeroMotoboySelecionado = motoboyNumeroLocal;
                                              });
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                // Número em cima
                                                FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    "${motoboy['numero']}",
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.bold,
                                                      color: selecionado
                                                          ? colorScheme.onPrimary
                                                          : null,
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(height: 4),

                                                // Nome embaixo
                                                Text(
                                                  "${motoboy['nome']}",
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: selecionado
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    color: selecionado
                                                        ? colorScheme.onPrimary
                                                        : null,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ),

                    if(motoboySelecionado)
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colorScheme.scrim,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Text(
                            "Motoboy selecionado: $nomeMotoboySelecionado - $numeroMotoboySelecionado",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Divider(height: 1),

                    // ── Botões ──
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: carregando
                          ? Center(
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraintsBtn) {
                                final isSmall = constraintsBtn.maxWidth < 250;
                                
                                final btnCancelar = OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: colorScheme.error.withOpacity(0.7),
                                    foregroundColor: colorScheme.error.withOpacity(0.7),
                                    side: BorderSide(color: colorScheme.error.withOpacity(0.7)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    minimumSize: Size.fromHeight(70),
                                  ),
                                  icon: Icon(
                                    Icons.close,
                                    size: fontPadraoLetras * 1.2,
                                    color: colorScheme.onPrimary,
                                  ),
                                  label: Text(
                                    'Cancelar',
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: fontPadraoLetras * 1.2, 
                                      fontWeight: FontWeight.w600, 
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                  },
                                );

                                final btnConfirmar = ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    minimumSize: Size.fromHeight(70),
                                  ),
                                  icon: Icon(
                                    Icons.check,
                                    size: fontPadraoLetras * 1.2,
                                  ),
                                  label: Text(
                                    maxLines: 1,
                                    'Confirmar',
                                    style: TextStyle(
                                      fontSize: fontPadraoLetras * 1.2, 
                                      fontWeight: FontWeight.w600
                                    ),
                                  ),
                                  onPressed: () async {
                                    if (!motoboySelecionado) {
                                      setPopupState(() => carregando = false);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Selecione um motoboy primeiro'),
                                          backgroundColor: colorScheme.error,
                                        ),
                                      );
                                    } else {
                                      // Persiste seleção no controller e estado da page
                                      setState(() {
                                        motoboySelecionadoIndex = motoboyIndexLocal;
                                        nomeMotoboySelecionado = motoboyNomeLocal;
                                        numeroMotoboySelecionado = motoboyNumeroLocal;
                                      });
                                      painelController.setMotoboy(
                                        motoboyNomeLocal,
                                        motoboyNumeroLocal,
                                      );

                                      // Confirmar envio
                                      setPopupState(() => carregando = true);
                                      try {
                                        bool conectado = await Connection.conectarBanconoSalvar();
                                        await _loadNumeroLicenca();
                                        if (conectado) {
                                          for (var pedido in listaPedidosSelecionadosFuncao) {
                                            await atualizarStatusEntrega(
                                              numeroDelivery: pedido['numerodelivery'].toString(),
                                              numeroMotoboy: motoboyNumeroLocal,
                                            );
                                            await inserirLogEntrega(
                                              numeroPedido: pedido['numero'],
                                              numeroUsuario: motoboyNumeroLocal,
                                              numeroTradepoint: numeroTradepointSelecionada,
                                              nomeMotoboy: motoboyNomeLocal,
                                            );
                                          }
                                          if (mounted) {
                                            Navigator.of(dialogContext).pop();
                                            await buscarPedidos();
                                            limparPage();
                                          }
                                        } else {
                                          setPopupState(() => carregando = false);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Sem conexão com a internet'),
                                              backgroundColor: colorScheme.error,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        setPopupState(() => carregando = false);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Erro ao confirmar expedição'),
                                            backgroundColor: colorScheme.error,
                                          ),
                                        );
                                      }
                                    } 
                                  },
                                );
                                // Botoes
                                if (isSmall) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      btnCancelar,
                                      SizedBox(height: 8),
                                      btnConfirmar,
                                    ],
                                  );
                                } else {
                                  return Row(
                                    children: [
                                      Expanded(child: btnCancelar),
                                      SizedBox(width: 8),
                                      Expanded(child: btnConfirmar),
                                    ],
                                  );
                                }
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final orientation = MediaQuery.of(context).orientation;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: SideNav(),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: Obx(() {
          final conectado = Connection.connectionStatus.value;
          return AppBar(
            backgroundColor: conectado
                ? colorScheme.primary
                : colorScheme.error,
            automaticallyImplyLeading: false,
            title: Stack(
              alignment: Alignment.center,
              children: [
                // MENU
                Align(
                  alignment: Alignment.centerLeft,
                  child: Builder(
                    builder: (context) => IconButton(
                      icon: Image.asset(
                        'assets/logo_branco2.png',
                        width: 30,
                        // 24
                        height: 30,
                        fit: BoxFit.contain,
                      ),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ),

                // CENTRO - Nome && Hora
                Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Nome observado em Obx
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
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

                // STATUS - precisa de Obx
                Align(
                  alignment: Alignment.centerRight,
                  child: 
                  Column(
                    // crossAxisAlignment: CrossAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(
                        () => Text(
                          Connection.connectionStatus.value ? 'Online' : 'Offline',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        "$versaoAplicacao",
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "${funcoesController.nomeTraidpoint}",
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // horizontal 
                if (orientation == Orientation.landscape) 
                Expanded(
                  flex: 1,
                  child: _buildGridMotoboysRow(),
                ),

                // Vertical
                if (orientation == Orientation.portrait) 
                Expanded(
                  flex: 1,
                  child: _buildGridMotoboysColumn(),
                ),
                // horizontal
                /* if (orientation == Orientation.landscape) 
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Coluna para motoboys 
                      Expanded(
                        flex: 3,
                        child: _buildMotoboysRowMaior(),
                      ),
                      // Pedidos e expedicao
                      Expanded(
                        flex: 10,
                        child: _buildPedidosExpedicaoRow(),
                      ),
                    ],
                  ),
                ),
                // vertical 
                if (orientation == Orientation.portrait) 
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Coluna para motoboys 
                      Expanded(
                        flex: 1,
                        child: _buildMotoboysRowMenor(),
                      ),
                      // Pedidos e expedicao
                      Expanded(
                        flex: 8,
                        child: _buildPedidosExpedicaoColumn(),
                      ),
                    ],
                  ),
                ), */
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:un_recepcao/controllers/views/funcoes_controller.dart';
import 'package:un_recepcao/controllers/views/painel_controller.dart';
import 'package:un_recepcao/data/data_class.dart';
import 'package:un_recepcao/services/servicoNotificacao.dart';
import 'package:un_recepcao/widgets/side_nav.dart';

class PainelCozinha extends StatefulWidget {
  const PainelCozinha({super.key});

  @override
  State<PainelCozinha> createState() => _PainelCozinhaState();
}

class _PainelCozinhaState extends State<PainelCozinha> {
  final numeroController = TextEditingController();
  final nomeController = TextEditingController();
  final funcoesController = Get.put(FuncoesController());
  String nomeTerminalEstatico = "";
  String numeroTerminalEstatico = "";
  String _horaAtual = '';
  late Timer _timerHora;
  Timer? _timerPedidos;

  // List<dynamic> listaPedidos = []; // select ser em painel controller 

  final painelController = Get.put(PainelController());
  List<dynamic> gruposQuantidade = [];
  List<dynamic> outrosPedidos = [];

  // Guard para evitar execuções sobrepostas do timer
  bool _atualizando = false;
  // Flag para indicar se a carga inicial já foi feita
  bool _cargaInicialConcluida = false;

  bool _popupTerminalAberto = false;

  bool isLoadingConfirmar = false;

  @override
  void initState() {
    super.initState();
    carregarNomeTerminal();
    _atualizarHora();
    _timerHora = Timer.periodic(Duration(seconds: 1), (timer) {
      _atualizarHora();
    });
    painelController.estaNoPainelCozinha.value = true;

    // Configura o áudio e faz a carga inicial dos pedidos
    // Na carga inicial, preenche os IDs sem tocar som
    _inicializarPainelCozinha();
  }

  Future<void> _inicializarPainelCozinha() async {
    await ServicoNotificacao.configurarAudio();
    if (!mounted) return;

    // Busca os pedidos já existentes e preenche os IDs iniciais SEM tocar som
    await painelController.buscarPedidosEmPreparo();
    if (!mounted) return;

    ServicoNotificacao.preencherIdsIniciais(painelController.listaPedidosEmPreparo);
    _cargaInicialConcluida = true;

    _timerPedidos = Timer.periodic(Duration(seconds: 5), (timer) {
      atualizarNumeroPedidos();
    });
  }

  @override
  void dispose() {
    _timerHora.cancel();
    _timerPedidos?.cancel();
    // Libera o player Singleton e reseta o flag de configuração.
    ServicoNotificacao.liberar();
    painelController.estaNoPainelCozinha.value = false;
    super.dispose();
  }

  String formatarNumero(String valor) {
    valor = valor.replaceAll('.', '');
    final regex = RegExp(r'(\d)(?=(\d{3})+(?!\d))');

    return valor.replaceAllMapped(
      regex,
      (match) => '${match[1]}.',
    );
  }

  void popupInfoPedido(String descricaoPedido, String horaPedido, String itensPorPedido, List<dynamic> pedidos, String numeroPedidoFuncao) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Align(
            alignment: Alignment.center,
            child: Column(
              children: [
                Text(
                  "$descricaoPedido",
                  style: TextStyle(
                    fontSize: 20, 
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Itens: $itensPorPedido - $horaPedido",
                  style: TextStyle(
                    fontSize: 15, 
                  ),
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: pedidos.isEmpty
                ? Center(child: Text("Nenhum usuário encontrado"))
                : ListView.builder(
                    itemCount: pedidos.length,
                    itemBuilder: (context, pedidoIndex) {
                      final pedido = pedidos[pedidoIndex];
                      final nomeProduto = pedido['nome_produto'] ?? "";
                      final tipoPedido = pedido['tipo_produto'] ?? "";
                      final sabores = pedido['sabores'] ?? "";
                      final observacaoVenda = pedido['observacaovenda'].toString() ?? "";
                      List saboresLista = sabores.toString().split('|').where((e)=>e.trim().isNotEmpty).toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// TAMANHO
                          Text(
                            nomeProduto,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          /// SABORES
                          if(tipoPedido == "PZ")
                            ...saboresLista
                                .map((item){
                          List partes =
                          item.split("::");
                              String sabor = partes[0];
                              String fracao = partes.length > 1 ? partes[1] : "";

                              return Padding(
                                padding: EdgeInsets.only(bottom: 5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "$fracao $sabor",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              );
                            }), 
                          SizedBox(height: 10),
                          if(observacaoVenda != "" && observacaoVenda != "null")
                          Text(
                            observacaoVenda,
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Divider(),
                          /* SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              shownDialogTwoBottom(
                                context: context,
                                title: "Confirmar pedido como pronto?",
                                icon: Icons.check,
                                onConfirm: () async {
                                  await confirmarPedido(numeroPedidoFuncao);
                                  await painelController.buscarPedidosEmPreparo();
                                },
                                onCancel: () async {},
                              );
                            },
                            child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Confirmar",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          fontSize: MediaQuery.of(context).size.width * 0.020,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ), */
                        ],
                      );
                    },
                  ),
          ),
          actions: [
            Column(
              children: [
                SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    shownDialogTwoBottom(
                      context: context,
                      title: "Confirmar pedido como pronto?",
                      icon: Icons.check,
                      onConfirm: () async {
                        await confirmarPedido(numeroPedidoFuncao);
                        await painelController.buscarPedidosEmPreparo();
                        Navigator.of(context).pop();
                      },
                      onCancel: () async {},
                    );
                  },
                  child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Confirmar",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: MediaQuery.of(context).size.width * 0.020,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("Cancelar"),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ).then((_) {
      // _popupGarcomAberto = false;
    });
  }

  Future<void> atualizarNumeroPedidos() async {
    // Guard contra execuções sobrepostas: se a anterior ainda está rodando, pula
    if (_atualizando) return;
    // Só executa verificação de novos pedidos após a carga inicial
    if (!_cargaInicialConcluida) return;

    _atualizando = true;
    try {
      await painelController.buscarPedidosEmPreparo();
      // Toda a lógica de verificação de IDs e decisão de tocar som
      // está centralizada no ServicoNotificacao
      await ServicoNotificacao.verificarENotificar(
        painelController.listaPedidosEmPreparo,
      );
    } catch (e) {
      print('[PainelCozinha] Erro ao atualizar pedidos: $e');
    } finally {
      _atualizando = false;
    }
  }

  ///responsavel por confirmar pedido para a cozinha
  Future<void> confirmarPedido(String numeroFuncao) async {
    // String numeroFormatado = formatarNumero(numeroFuncao);
    try {
      // 2 = pronto
      await Connection().transaction([
        "UPDATE delivery SET statuspainel = '2' WHERE numeropedido_FK = '$numeroFuncao'",
        "UPDATE servidorproducao SET status = '2' WHERE numeropedido_FK = '$numeroFuncao'",
      ]);
    } catch (e) {
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


  void carregarNomeTerminal() {

    setState(() {
      nomeTerminalEstatico = painelController.nomeTerminalSelecionado.value;
      numeroTerminalEstatico = painelController.numeroTerminalSelecionado.value;
    });
  }

  // Dialogo com dois botões de erro
  Future<void> shownDialogTwoBottom({
    required BuildContext context,
    String title = 'Confirmação',
    String? message,
    IconData icon = Icons.home,
    String cancelText = 'Não',
    String confirmText = 'Sim',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    TextEditingController? textController,
    FocusNode? focusNode,
    ValueChanged<String>? onSubmitted, // Callback ao submeter o texto
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false, // Não pode fechar tocando fora
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícone central
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(ctx).colorScheme.primary.withOpacity(0.08),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    icon,
                    size: 40,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                ),

                SizedBox(height: 10),

                // Título opcional
                if (title.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      title,
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Botões centralizados
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Botão Cancelar
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (onCancel != null) onCancel();
                      },
                      child: Text(
                        cancelText.toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.onPrimary,
                          fontSize: 20,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        backgroundColor: Theme.of(ctx).colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: 10),
                    // Botão Confirmar
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (onConfirm != null) onConfirm();
                      },
                      child: Text(
                        confirmText.toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.onPrimary,
                          fontSize: 20,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        backgroundColor: Theme.of(ctx).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid(List<dynamic> items) {

    // Agrupa pela descrição do pedido
    Map<String, List<dynamic>> pedidosAgrupados = {};

    for (var pedido in items) {
      String chave = pedido["descricaopedido"].toString();

      pedidosAgrupados.putIfAbsent(chave, () => []);

      pedidosAgrupados[chave]!.add(pedido);
    }

    final grupos = pedidosAgrupados.entries.toList();
    gruposQuantidade = pedidosAgrupados.entries.toList();

    // manda lista da quantidade de pedidos
    // numeroPedidos(gruposQuantidade);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = 10.0;
        final double totalWidth = constraints.maxWidth;
        final double totalHeight = constraints.maxHeight;
        
        // Calcula o Aspect Ratio para ocupar 3 colunas e 2 linhas perfeitamente
        final double childWidth = (totalWidth - (spacing * 2)) / 3;
        final double childHeight = (totalHeight - spacing) / 2;
        final double aspectRatio = childWidth / childHeight;

        return GridView.builder(
            padding: EdgeInsets.zero,
            physics: NeverScrollableScrollPhysics(), 
            itemCount: 6, // Sempre 6 cards
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: aspectRatio > 0 ? aspectRatio : 1.0,
            ),
            itemBuilder: (context, index) {
              if (index >= grupos.length) {
                // Slot vazio — ValueKey garante que o Flutter não confunda
              // este widget com um card real durante rebuild
              return  Card(
                  key: ValueKey('slot_vazio_$index'),
                  elevation: 0,
                  color: Colors.transparent,
                  child: const Center(
                    child: Icon(Icons.hourglass_empty, color: Colors.transparent, size: 40),
                  ),
                );
              }

              final grupo = grupos[index];
              final descricaoPedido = grupo.key;
              final pedidos = grupo.value;
              final horaPedido = pedidos.first['min(v.datahora)'] ?? "";
              final dataHoraFormatada = DateFormat('HH:mm').format(DateTime.parse(horaPedido));
              final numeroPedido = pedidos[0]['numeropedido'].toString();
              
              final itensPorPedido = pedidos.length;

              // 0 -> entrega // 1 -> balcao
              final tipoPedido = pedidos[0]['entregapedido'].toString();
              if (tipoPedido == "0") {
                
              } else if (tipoPedido == "1") {
                
              } else {

              }

              // ValueKey baseada no número real do pedido:
              // → Flutter mantém o estado do card correto ao reorganizar
              // → Evita o "salto" visual quando um pedido sai da fila
              return Card(
                  key: ValueKey('pedido_$numeroPedido'),
                  elevation: 4,
                child: Container(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (tipoPedido == "0")
                                        Image.asset(
                                          'assets/retirada_balcao_icone.png',
                                          width: MediaQuery.of(context).size.width * 0.020,
                                          height: MediaQuery.of(context).size.width * 0.020,
                                        )
                                      else
                                        Image.asset(
                                          'assets/icone_moto_delivery.png',
                                          width: MediaQuery.of(context).size.width * 0.025,
                                          height: MediaQuery.of(context).size.width * 0.025,
                                        ),

                                      SizedBox(width: 5),

                                      Expanded(
                                        child: Text(
                                          descricaoPedido,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: MediaQuery.of(context).size.width * 0.015,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "Itens: $itensPorPedido",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  dataHoraFormatada,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: pedidos.length,
                          itemBuilder: (context, pedidoIndex) {
                            final pedido = pedidos[pedidoIndex];
                            final nomeProduto = pedido['nome_produto'] ?? "";
                            final tipoPedido = pedido['tipo_produto'] ?? "";
                            final sabores = pedido['sabores'] ?? "";
                            final observacaoVenda = pedido['observacaovenda'].toString() ?? "";
                            List saboresLista = sabores.toString().split('|').where((e)=>e.trim().isNotEmpty).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// TAMANHO
                                Text(
                                  nomeProduto,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                /// SABORES
                                if(tipoPedido == "PZ")
                                  ...saboresLista
                                      .map((item){
                                List partes =
                                item.split("::");
                                    String sabor = partes[0];
                                    String fracao = partes.length > 1 ? partes[1] : "";

                                    return Padding(
                                      padding: EdgeInsets.only(bottom: 5),
                                      child: Column(
                                        children: [
                                          Text(
                                            "$fracao $sabor",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                      /* if(observacaoVenda != "")
                                      Text(
                                        observacaoVenda,
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey[700],
                                        ),
                                      ), */
                                        ],
                                      ),
                                    );
                                  }), 
                                SizedBox(height: 10),
                                if(observacaoVenda != "" && observacaoVenda != "null")
                                Text(
                                  observacaoVenda,
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Divider(),
                              ],
                            );
                          },
                        ),
                      ),
                      Divider(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            shownDialogTwoBottom(
                              context: context,
                              title: "Confirmar pedido como pronto?",
                              icon: Icons.check,
                              onConfirm: () async {
                                await confirmarPedido(numeroPedido);
                                await painelController.buscarPedidosEmPreparo();
                              },
                              onCancel: () async {},
                            );
                          },
                          child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Confirmar",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontSize: MediaQuery.of(context).size.width * 0.020,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ); // fecha AnimatedSwitcher
            },
        );
      }
    );
  }

  Widget _buildProntosRow() {
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
              Padding(
                padding:  EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            "PEDIDOS",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                        Text(
                          "${gruposQuantidade.length}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Divider(),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: gruposQuantidade.length > 6 ? gruposQuantidade.length - 6 : 0,
                  itemBuilder: (context, index) {
                    final actualIndex = index + 6;
                    final grupo = gruposQuantidade[actualIndex];
                    final descricaoPedido = grupo.key;
                    final horaRaw = grupo.value.first['min(v.datahora)'] ?? '';
                    final pedidos = grupo.value;
                    final itensPorPedido = pedidos.length;
                    final numeroPedido = pedidos[0]['numeropedido'].toString();
                    String horaPedido = "";
                    if (horaRaw != "") {
                      try {
                        horaPedido = DateFormat('HH:mm').format(DateTime.parse(horaRaw));
                      } catch (_) {}
                    }
                    
                    return Card(
                      elevation: 1,
                      margin: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: colorScheme.primary.withOpacity(0.2)),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          String itensPorPedidoString = itensPorPedido.toString();
                          // abrir dialogo informacoes do pedido
                          popupInfoPedido(descricaoPedido, horaPedido, itensPorPedidoString, pedidos, numeroPedido);
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                descricaoPedido,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              if (horaPedido != "")
                                Text(
                                  "${horaPedido} - ${itensPorPedido} itens",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildProntosColumn() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color:colorScheme.primary.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "PEDIDOS EM PREPARO COLUNA",
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 10),
            Card(
              elevation: 1,
              margin: EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: colorScheme.primary.withOpacity(0.2)),
              ),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            "${gruposQuantidade.length}",
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.primary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
        
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // botao confg
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.surfaceDim,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      
                    },
                    child: Icon(Icons.settings, color: colorScheme.onPrimary,),
                  ),
                ),
                SizedBox(width: 10),
                // botao x
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      
                    },
                    child: Icon(Icons.close, color: colorScheme.onPrimary,),
                  ),
                ),
              ],
            )
            /* Expanded(
              child: Obx(() => ListView.builder(
                    itemCount: painelController.listaPedidosEmPreparo.length,
                    itemBuilder: (context, index) {
                      final pedido = painelController.listaPedidosEmPreparo[index];
                      final descricaoPedido = pedido['descricaopedido'] ?? "";
                      final nomeProduto = pedido['nome_produto'] ?? "";
                      final horaPedido = pedido['min(v.datahora)'] ?? "";
                      String horaFormatada = "";
                      try {
                        horaFormatada = DateFormat('HH:mm').format(DateTime.parse(horaPedido));
                      } catch (_) {}
        
                      return Card(
                        elevation: 1,
                        margin: EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.green.withOpacity(0.2)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    descricaoPedido,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    horaFormatada,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                nomeProduto,
                                style: TextStyle(fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )),
            ), */
          ],
        ),
      ),
    );
  }

  void popupSelecionarTerminal() {
    if (_popupTerminalAberto) return;
    _popupTerminalAberto = true;    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Align(
            alignment: Alignment.center,
            child: Text(
              "Selecione um terminal",
              style: TextStyle(
                fontSize: 20, // ou qualquer outro estilo que desejar
              ),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: painelController.listaTerminais.isEmpty
                ? Center(child: Text("Nenhum terminal encontrado"))
                : ListView.builder(
                    itemCount: painelController.listaTerminais.length,
                    itemBuilder: (context, index) {
                      final terminal = painelController.listaTerminais[index];

                      return Card(
                        child: ListTile(
                          title: Text(terminal['nome'].toString()),
                          // subtitle: Text("Número: ${garcom['numero']}"),
                          onTap: () async {
                            Navigator.pop(context);
                            String nome = terminal['nome'].toString();
                            String numero = terminal['numero'].toString();
                            painelController.setTerminal(nome, numero);
                            carregarNomeTerminal();
                            // Reseta os IDs do terminal anterior
                            ServicoNotificacao.resetarIdsNotificados();
                            // Busca os pedidos do novo terminal e preenche IDs sem tocar som
                            await painelController.buscarPedidosEmPreparo();
                            ServicoNotificacao.preencherIdsIniciais(
                              painelController.listaPedidosEmPreparo,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancelar"),
            ),
          ],
        );
      },
    ).then((_) {
      _popupTerminalAberto = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      drawer: const SideNav(),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: Obx(() {
          // este Obx cuida APENAS do que realmente depende de conexão
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

                // CENTRO - Nome do terminal
                Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          popupSelecionarTerminal();
                        },
                        child: Text(
                          "$nomeTerminalEstatico",
                          style: GoogleFonts.montserrat(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${funcoesController.dataAtual.value}",
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(width: 15),
                          Text(
                            _horaAtual,
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
      body: Obx(() {
        return Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //if (orientation == Orientation.landscape) 
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Coluna Principal - Pedidos em Preparo (4/5)
                        Expanded(
                          flex: 6,
                          child: _buildGrid(painelController.listaPedidosEmPreparo),
                        ),
                        Expanded(
                          flex: 1,
                          child: _buildProntosRow(),
                        ),
                        
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
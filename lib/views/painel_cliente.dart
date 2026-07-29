import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:un_recepcao/controllers/views/painel_controller.dart';
import 'package:un_recepcao/data/data_class.dart';
import 'package:un_recepcao/models/monitor.dart';
import 'package:un_recepcao/services/servicoNotificacao.dart';
import 'package:un_recepcao/widgets/side_nav.dart';
import 'package:win32/win32.dart';
import 'package:window_manager/window_manager.dart';

class PainelCliente extends StatefulWidget {
  const PainelCliente({super.key});

  @override
  State<PainelCliente> createState() => _PainelClienteState();
}

class _PainelClienteState extends State<PainelCliente> with WidgetsBindingObserver {
  final painelController = Get.put(PainelController());

  // Timer de atualização periódica de dados (5 s)
  Timer? _timerDados;

  // Timer de inatividade do mouse — reiniciado a cada movimento
  Timer? _timerMouse;

  List<dynamic> listaPedidosEmPreparo = [];
  List<dynamic> listaPedidosProntos = [];

  /// Flag de controle: evita chamadas duplicadas ao window_manager.
  /// false = interface visível | true = fullscreen ativo
  bool _isFullScreen = false;

  int? pedidoHoverIndexPreparo;
  int? pedidoHoverIndexPronto;

  /// IDs de pedidos já notificados por status.
  /// Inicializados como null → na primeira chamada apenas preenche sem tocar som.
  Set<String>? _idsNotificadosPreparo;
  Set<String>? _idsNotificadosPronto;

  @override
  void initState() {
    super.initState();
    // Observa mudanças de ciclo de vida do app (ex.: foco ganho/perdido)
    if(Platform.isWindows){
      WidgetsBinding.instance.addObserver(this);
    }

    // Busca inicial dos dados
    if(Platform.isWindows){
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _buscarEOrganizar();
      });
    }else{
      _buscarEOrganizar();
    }

    // Atualização periódica de dados a cada 5 segundos
    _timerDados = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await painelController.buscarPedidosDelivery();
      organizarListas();
    });

    painelController.estaNoPainelCozinha.value = false;

    // Inicializa fullscreen somente no Windows
    if (Platform.isWindows) {
      _initWindowsFullScreen();
    }
  }

  @override
  void dispose() {
    if(Platform.isWindows){
      WidgetsBinding.instance.removeObserver(this);
    }
    _timerDados?.cancel();
    _timerMouse?.cancel();
    super.dispose();
  }

  /// Chamado pelo sistema quando a janela ganha ou perde foco.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
  }

  // Fullscreen kiosk

  // Inicializa a janela em fullscreen kiosk ao abrir a tela.
  Future<void> _initWindowsFullScreen() async {
    if (Platform.isWindows) {
      await windowManager.ensureInitialized();
      await ocultarInterfaceWindows();
    }
  }

  // Sai do fullscreen → restaura barra de título → maximiza janela.
  Future<void> mostrarInterfaceWindows() async {
    if (Platform.isWindows) {
      if (!_isFullScreen) return; // já está visível, nada a fazer
      _isFullScreen = false;
      await windowManager.setTitleBarStyle(TitleBarStyle.normal);
      await windowManager.setFullScreen(false);
      await windowManager.maximize();
    }
  }

  // Entra em fullscreen → esconde barra de título.
  Future<void> ocultarInterfaceWindows() async {
    if (Platform.isWindows){
      if (_isFullScreen) return; // já em fullscreen, nada a fazer
      _isFullScreen = true;
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.setFullScreen(true);
    }
  }

  // Cancela o timer anterior e inicia um novo de 5 segundos.
  // Ao expirar (mouse parado), volta ao fullscreen automaticamente.
  void reiniciarTimerMouse() {
    if(Platform.isWindows){
      _timerMouse?.cancel();
      _timerMouse = Timer(const Duration(seconds: 5), () {
        if (mounted && Platform.isWindows) {
          ocultarInterfaceWindows();
        }
      });
    }
  }

  // Alternância de monitores
  Future<void> moverParaOutroMonitor() async {
    if (!Platform.isWindows) return;

    //  1. Obtém o HWND da janela principal 
    final hwnd = await windowManager.getId();
    if (hwnd == 0) {
      debugPrint('[Monitor] HWND inválido — operação cancelada.');
      return;
    }

    //  2. Enumera os monitores sem callbacks 
    final monitores = enumerarMonitores();
    debugPrint('[Monitor] Total de monitores detectados: ${monitores.length}');

    if (monitores.length < 2) {
      debugPrint('[Monitor] Apenas 1 monitor ativo. Nenhuma ação necessária.');
      return;
    }

    //  3. Descobre em qual monitor a janela está atualmente ─
    //   MONITOR_DEFAULTTONEAREST: retorna o monitor mais próximo caso a janela
    //   esteja parcialmente fora de qualquer monitor.
    final hMonitorAtual = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);

    final indiceAtual = monitores.indexWhere((m) => m.handle == hMonitorAtual);
    if (indiceAtual == -1) {
      debugPrint('[Monitor] Monitor atual não encontrado na lista.');
      return;
    }

    //  4. Calcula o índice do próximo monitor (circular) 
    final indiceDestino = (indiceAtual + 1) % monitores.length;
    final destino = monitores[indiceDestino];

    //  5. Sai do fullscreen antes de mover ─
    //   É necessário sair do fullscreen para que o SetWindowPos possa
    //   reposicionar a janela corretamente no outro monitor.
    _isFullScreen = false; // reseta a flag antes de chamar window_manager
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    await windowManager.setFullScreen(false);

    // Aguarda o Windows processar a saída do fullscreen
    await Future.delayed(const Duration(milliseconds: 150));

    //  6. Move e redimensiona a janela para cobrir o monitor destino 
    SetWindowPos(
      hwnd,
      HWND_TOP,
      destino.left,
      destino.top,
      destino.width,
      destino.height,
      SWP_NOZORDER | SWP_SHOWWINDOW,
    );

    // Aguarda o Windows processar o reposicionamento antes de reativar fullscreen
    await Future.delayed(const Duration(milliseconds: 250));

    //  7. Reativa o fullscreen no novo monitor 
    await ocultarInterfaceWindows();
  }

  // Dados
  Future<void> _buscarEOrganizar() async {
    await painelController.buscarPedidosDelivery();
    organizarListas();
  }

  void organizarListas() {
    if (!mounted) return;
    listaPedidosEmPreparo.clear();
    listaPedidosProntos.clear();
    setState(() {
      if (painelController.listaPedidosDelivery.isNotEmpty) {
        for (var pedido in painelController.listaPedidosDelivery) {
          if (pedido['statuspainel'] == '1') {
            listaPedidosEmPreparo.add(pedido);
          } else if (pedido['statuspainel'] == '2') {
            listaPedidosProntos.add(pedido);
          }
        }
      }
    });

    // ── Notificação por ID ──────────────────────────────────────────
    // Extrai IDs atuais de cada lista
    final idsPreparoAgora = listaPedidosEmPreparo.map((p) => p['numeropedido']?.toString() ?? '').where((id) => id.isNotEmpty).toSet();

    final idsProntoAgora = listaPedidosProntos.map((p) => p['numeropedido']?.toString() ?? '').where((id) => id.isNotEmpty).toSet();

    if (_idsNotificadosPreparo == null) {
      // Primeira execução: preenche sem tocar som
      _idsNotificadosPreparo = Set.from(idsPreparoAgora);
    } else {
      final ineditos = idsPreparoAgora.difference(_idsNotificadosPreparo!);
      if (ineditos.isNotEmpty) {
        _idsNotificadosPreparo!.addAll(ineditos);
        ServicoNotificacao.tocarSom();
      }
    }

    if (_idsNotificadosPronto == null) {
      // Primeira execução: preenche sem tocar som
      _idsNotificadosPronto = Set.from(idsProntoAgora);
    } else {
      final ineditos = idsProntoAgora.difference(_idsNotificadosPronto!);
      if (ineditos.isNotEmpty) {
        _idsNotificadosPronto!.addAll(ineditos);
        ServicoNotificacao.tocarSom();
      }
    }
  }

  Future<void> mudarStatusPedidoRetirado(String numeroPedido) async {
    try {
      await Connection().transaction([
        "UPDATE delivery SET statuspainel = 3 WHERE numeropedido_FK = '$numeroPedido'",
        "UPDATE servidorproducao SET status = 3 WHERE numeropedido_FK = '$numeroPedido'",
      ]);
    } catch (e) {
      print(e);
    }
    _buscarEOrganizar();
  }

  ///responsavel por confirmar pedido para a cozinha
  Future<void> confirmarPedidoPronto(String numeroFuncao) async {
    // String numeroFormatado = formatarNumero(numeroFuncao);
    try {
      // 2 = pronto
      await Connection().transaction([
        "UPDATE delivery SET statuspainel = '2' WHERE numeropedido_FK = '$numeroFuncao'",
        "UPDATE servidorproducao SET status = '2' WHERE numeropedido_FK = '$numeroFuncao'",
      ]);
    } catch (e) {
    }
    _buscarEOrganizar();
  }

  // ─ Diálogo padrão 

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
    ValueChanged<String>? onSubmitted,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
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
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(ctx).colorScheme.primary.withOpacity(0.08),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    icon,
                    size: 80,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 10),
                if (title.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      title,
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 50,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (onCancel != null) onCancel();
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        backgroundColor: Theme.of(ctx).colorScheme.error.withOpacity(0.60),
                      ),
                      child: Text(
                        cancelText.toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.onPrimary,
                          fontSize: 25,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (onConfirm != null) onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        backgroundColor: Theme.of(ctx).colorScheme.primary,
                      ),
                      child: Text(
                        confirmText.toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.onPrimary,
                          fontSize: 25,
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
    );
  }

  // ─ Build ─

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget body = Scaffold(
      backgroundColor: colorScheme.background,
      drawer: SideNav(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final maxH = constraints.maxHeight;
            final isWideScreen = maxW > 768;

            final orientation = MediaQuery.of(context).orientation;

            //  Escala dinâmica proporcional à resolução 

            final double appBarHeight = (maxH * 0.08).clamp(50.0, 120.0);
            final double appBarFontSize = (maxW * 0.018).clamp(14.0, 42.0);
            final double appBarLetterSpacing = (maxW * 0.002).clamp(1.0, 6.0);
            final double iconSize = (appBarHeight * 0.5).clamp(24.0, 56.0);

            final double headerFontSize = (maxW * 0.022).clamp(16.0, 52.0);
            final double headerPaddingV = (maxH * 0.022).clamp(10.0, 40.0);

            final double preparoNumeroFontSize = orientation == Orientation.landscape ? (maxW * 0.035).clamp(28.0, 80.0) * 1.5 : (maxW * 0.035).clamp(28.0, 80.0);
            final double preparoNomeFontSize = orientation == Orientation.landscape ? (maxW * 0.022).clamp(16.0, 52.0) * 1.5 : (maxW * 0.022).clamp(16.0, 52.0);
            final double preparoNumeroWidth = orientation == Orientation.landscape ? (maxW * 0.08).clamp(70.0, 200.0) * 1.5 : (maxW * 0.08).clamp(70.0, 200.0);

            final double prontoNumeroFontSize = orientation == Orientation.landscape ? (maxW * 0.048).clamp(36.0, 110.0) * 1.5 : (maxW * 0.048).clamp(36.0, 110.0);
            final double prontoNomeFontSize = orientation == Orientation.landscape ? (maxW * 0.032).clamp(22.0, 72.0) * 1.5 : (maxW * 0.032).clamp(22.0, 72.0);
            final double prontoNumeroWidth = orientation == Orientation.landscape ? (maxW * 0.09).clamp(80.0, 240.0) * 1.5 : (maxW * 0.09).clamp(80.0, 240.0);

            final double itemSpacingH = (maxW * 0.012).clamp(8.0, 30.0);
            final double listPaddingH = (maxW * 0.018).clamp(10.0, 44.0);
            final double listPaddingV = (maxH * 0.018).clamp(10.0, 36.0);
            final double separatorPaddingV = (maxH * 0.005).clamp(2.0, 12.0);

            //  AppBar customizada 
            // GestureDetector.onDoubleTap → alterna para a outra janela
            final appBar = GestureDetector(
              onDoubleTap: Platform.isWindows
                  ? () => moverParaOutroMonitor()
                  : null,
              child: Container(
                width: double.infinity,
                height: appBarHeight,
                padding: EdgeInsets.symmetric(horizontal: maxW * 0.01),
                child: Row(
                  children: [
                    Builder(
                      builder: (ctx) => IconButton(
                        icon: Image.asset(
                          'assets/app_icon2.png',
                          width: iconSize,
                          height: iconSize,
                          fit: BoxFit.contain,
                        ),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'ACOMPANHE SEU PEDIDO',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: appBarLetterSpacing,
                          fontSize: appBarFontSize,
                        ),
                      ),
                    ),
                    Container(
                      width: iconSize + 16,
                      height: iconSize + 16,
                      color: Colors.transparent,
                    ),
                  ],
                ),
              ),
            );

            //  Coluna EM PREPARO 
            final colunaPreparo = Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: headerPaddingV),
                  decoration: BoxDecoration(
                    color: colorScheme.scrim.withOpacity(0.08),
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.scrim.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    'EM PREPARO',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: headerFontSize,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.scrim,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                // status do painel tem que ser 1
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: listPaddingH,
                      vertical: listPaddingV,
                    ),
                    itemCount: listaPedidosEmPreparo.length,
                    separatorBuilder: (_, __) => Padding(
                      padding: EdgeInsets.symmetric(vertical: separatorPaddingV),
                      child: Divider(
                        color: colorScheme.outline.withOpacity(0.08),
                        thickness: 1,
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final pedido = listaPedidosEmPreparo[index];
                      final nomeCliente = pedido['nomecliente'].toString();
                      final numeroPedido = pedido['numerodelivery'].toString();
                      final numeroPedidoFuncao = pedido['numeropedido'].toString();
                      final bool selecionado = pedidoHoverIndexPreparo == index;

                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        onEnter: (_) {
                          setState(() {
                            pedidoHoverIndexPreparo = index;
                          });
                        },
                        onExit: (_) {
                          setState(() {
                            pedidoHoverIndexPreparo = null;
                          });
                        },
                        child: GestureDetector(
                          onTap: (){
                            shownDialogTwoBottom(
                              context: context,
                              title: 'Pedido #$numeroPedido\npronto?',
                              icon: Icons.check,
                              onConfirm: () async {
                                await confirmarPedidoPronto(numeroPedidoFuncao);
                                _buscarEOrganizar();
                              },
                              onCancel: () {},
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: separatorPaddingV),
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 150),
                              padding: EdgeInsets.symmetric(
                                vertical: separatorPaddingV,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: pedidoHoverIndexPreparo == index
                                    ? colorScheme.primary.withOpacity(0.08)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: pedidoHoverIndexPreparo == index
                                      ? colorScheme.primary
                                      : Colors.transparent,
                                  width: pedidoHoverIndexPreparo == index ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: preparoNumeroWidth,
                                    child: Text(
                                      numeroPedido,
                                      textAlign: TextAlign.start,
                                      style: GoogleFonts.montserrat(
                                        fontSize: preparoNumeroFontSize,
                                        fontWeight: FontWeight.w900,
                                        color: colorScheme.scrim,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                  // SizedBox(width: itemSpacingH),
                                  Flexible(
                                    child: Text(
                                      nomeCliente.toUpperCase(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                        fontSize: preparoNomeFontSize,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onSurface.withOpacity(0.82),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              /* Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: preparoNumeroWidth,
                                    child: Text(
                                      numeroPedido,
                                      textAlign: TextAlign.start,
                                      style: GoogleFonts.montserrat(
                                        fontSize: preparoNumeroFontSize,
                                        fontWeight: FontWeight.w900,
                                        color: colorScheme.scrim,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: itemSpacingH),
                                  Text(
                                    nomeCliente.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.montserrat(
                                      fontSize: preparoNomeFontSize,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface.withOpacity(0.82),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ), */
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );

            //  Coluna PRONTO 
            final colunaPronto = Column(
              children: [
                // Cabeçalho também responde ao duplo clique para alternar janelas
                GestureDetector(
                  onDoubleTap: Platform.isWindows
                      ? () => moverParaOutroMonitor()
                      : null,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: headerPaddingV),
                    decoration: BoxDecoration(
                      color: colorScheme.shadow.withOpacity(0.08),
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.shadow.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'PRONTO',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: headerFontSize,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.shadow,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                // status do painel tem que ser 2
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: listPaddingH,
                      vertical: listPaddingV,
                    ),
                    itemCount: listaPedidosProntos.length,
                    separatorBuilder: (_, __) => Padding(
                      padding: EdgeInsets.symmetric(vertical: separatorPaddingV),
                      child: Divider(
                        color: colorScheme.outline.withOpacity(0.08),
                        thickness: 1,
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final pedido = listaPedidosProntos[index];
                      final nomeCliente = pedido['nomecliente'].toString();
                      final numeroPedido = pedido['numerodelivery'].toString();
                      final numeroPedidoReal = pedido['numeropedido'].toString();

                      final bool selecionadoFuncao = pedidoHoverIndexPronto == index;

                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        onEnter: (_) {
                          setState(() {
                            pedidoHoverIndexPronto = index;
                          });
                        },
                        onExit: (_) {
                          setState(() {
                            pedidoHoverIndexPronto = null;
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: separatorPaddingV),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 150),
                            padding: EdgeInsets.symmetric(
                              vertical: separatorPaddingV,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selecionadoFuncao
                                  ? colorScheme.primary.withOpacity(0.08)
                                  : Colors.transparent,
                              border: Border.all(
                                color: selecionadoFuncao
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                width: selecionadoFuncao ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                shownDialogTwoBottom(
                                  context: context,
                                  title: 'Pedido #$numeroPedido#\nretirado?',
                                  icon: Icons.check,
                                  onConfirm: () async {
                                    await mudarStatusPedidoRetirado(numeroPedidoReal);
                                    _buscarEOrganizar();
                                  },
                                  onCancel: () {},
                                );
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: prontoNumeroWidth,
                                    child: Text(
                                      numeroPedido,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.montserrat(
                                        fontSize: prontoNumeroFontSize,
                                        fontWeight: FontWeight.w900,
                                        color: colorScheme.shadow,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: itemSpacingH),
                                  Flexible(
                                    child: Text(
                                      nomeCliente.toUpperCase(),
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                        fontSize: prontoNomeFontSize,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onSurface.withOpacity(0.82),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              /* Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: prontoNumeroWidth,
                                    child: Text(
                                      numeroPedido,
                                      textAlign: TextAlign.start,
                                      style: GoogleFonts.montserrat(
                                        fontSize: prontoNumeroFontSize,
                                        fontWeight: FontWeight.w900,
                                        color: colorScheme.shadow,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: itemSpacingH),
                                  Expanded(
                                    child: Text(
                                      nomeCliente.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                        fontSize: prontoNomeFontSize,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onSurface.withOpacity(0.82),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ), */
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );

            //  Layout final ─
            if (isWideScreen) {
              return Column(
                children: [
                  appBar,
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: colunaPreparo),
                        Container(
                          width: 2,
                          color: colorScheme.outline.withOpacity(0.15),
                        ),
                        Expanded(child: colunaPronto),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  appBar,
                  Expanded(child: colunaPreparo),
                  Divider(
                    height: 2,
                    thickness: 2,
                    color: colorScheme.outline.withOpacity(0.15),
                  ),
                  Expanded(child: colunaPronto),
                ],
              );
            }
          },
        ),
      ),
    );

    //  MouseRegion (somente Windows) ─
    // Envolve TODO o Scaffold. A cada movimento do mouse:
    //   1. Sai do fullscreen (mostra barra de título + taskbar)
    //   2. Reinicia o timer de 5 s de inatividade
    if (Platform.isWindows) {
      body = MouseRegion(
        onHover: (_) {
          mostrarInterfaceWindows();
          reiniciarTimerMouse();
        },
        child: body,
      );
    }

    return body;
  }
}
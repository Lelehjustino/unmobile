import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:un_recepcao/controllers/views/painel_controller.dart';
import 'package:un_recepcao/data/data_class.dart';
import 'package:un_recepcao/widgets/side_nav.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
class PainelCliente extends StatefulWidget {
  const PainelCliente({super.key});

  @override
  State<PainelCliente> createState() => _PainelClienteState();
}

class _PainelClienteState extends State<PainelCliente> {
  final painelController = Get.put(PainelController());
  Timer? _timer;

  List<dynamic> listaPedidosEmPreparo = [];
  List<dynamic> listaPedidosProntos = [];
  bool _isFullScreen = true;

  @override
  void initState() {
    super.initState();
    // Inicialização e busca dos dados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buscarEOrganizar();
    });

    // Inicia o timer para atualizar a cada 5 segundos
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await painelController.buscarPedidosDelivery();
      organizarListas();
    });

    painelController.estaNoPainelCozinha.value = false;

    if (Platform.isWindows) {
      _initWindowsFullScreen();
    }
  }

  Future<void> _initWindowsFullScreen() async {
    await windowManager.ensureInitialized();
    await windowManager.setFullScreen(true);
    _isFullScreen = true;
    if (mounted) setState(() {});
  }

  Future<void> _buscarEOrganizar() async {
    await painelController.buscarPedidosProntos();
    organizarListas();
  }

  void organizarListas() {
    if (mounted) {
      listaPedidosEmPreparo.clear();
      listaPedidosProntos.clear();
      setState(() {
        if (painelController.listaPedidosDelivery.isNotEmpty) {
          for (var pedido in painelController.listaPedidosDelivery) {
            // No controller o campo se chama 'statuspainel'
            // em preparo = 1
            if (pedido['statuspainel'] == "1") {
              listaPedidosEmPreparo.add(pedido);
              // pronto = 2
            } else if (pedido['statuspainel'] == "2") {
              listaPedidosProntos.add(pedido);
            }
          }
        }
      });
    }
  }

  Future<void> mudarStatusPedido(String numeroPedido) async {
    // update o status do pedido para 3
    try {
      // mudar para 3
      await Connection().transaction([
        "UPDATE delivery SET statuspainel = 3 WHERE numeropedido_FK = '$numeroPedido'",
        "UPDATE servidorproducao SET status = 3 WHERE numeropedido_FK = '$numeroPedido'",
      ]);
    } catch (e) {
      print(e);
    }
    _buscarEOrganizar();
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
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // SizedBox(height: 5),

                // Texto centralizado
                if (message != null && message.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 15,
                        color: Theme.of(ctx).colorScheme.onSurface,
                      ),
                    ),
                  ),

                // O SEU NOVO CAMPO DE TEXTO COM OS CONTROLADORES
                if (textController !=
                    null) // Só mostra o TextField se um controller for fornecido
                  Padding(
                    padding: EdgeInsets.only(bottom: 15.0),
                    child: TextField(
                      keyboardType: TextInputType.number, // TECLADO NUMÉRICO
                      controller: textController, // Usa o controller passado
                      focusNode: focusNode, // Usa o focusNode passado
                      onSubmitted: onSubmitted, // Usa o onSubmitted passado
                      autofocus:
                          focusNode ==
                          true, // Autofoco padrão se não houver FocusNode
                      textAlign:
                          TextAlign.center, // Centraliza o texto e o ponteiro
                      decoration: InputDecoration(
                        hintText: 'Digite aqui...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
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
                        backgroundColor: Theme.of(ctx).colorScheme.error,
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
                        backgroundColor: Theme.of(
                          ctx,
                        ).colorScheme.primary.withOpacity(0.05),
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Verifica quantas instâncias (janelas) do mesmo executável estão abertas.
  /// Se houver exatamente 2, alterna o foco para a outra janela (a que não está em foreground no momento)
  /// e garante que ela seja maximizada.
  Future<void> _verificarEAlternarJanelas() async {
    if (!Platform.isWindows) return;

    final className = 'FLUTTER_RUNNER_WIN32_WINDOW'.toNativeUtf16();
    int hwnd = FindWindowEx(0, 0, className, nullptr);
    
    // Lista para guardar os ponteiros das janelas abertas
    List<int> appHwnds = [];
    // Caminho do próprio executável rodando (ex: C:\..\under_recepcao.exe)
    final myExeName = Platform.resolvedExecutable.toLowerCase();

    // Varre todas as janelas do tipo FLUTTER (FindWindowEx vai para a próxima a cada chamada)
    while (hwnd != 0) {
      final pPid = calloc<Uint32>();
      GetWindowThreadProcessId(hwnd, pPid);
      final pid = pPid.value;
      free(pPid);

      // 0x1000 = PROCESS_QUERY_LIMITED_INFORMATION (Suficiente para pegar o caminho do executável)
      final hProcess = OpenProcess(0x1000, 0, pid);
      if (hProcess != 0) {
        final buffer = wsalloc(MAX_PATH);
        final size = calloc<Uint32>()..value = MAX_PATH;
        
        // Verifica se conseguiu recuperar o path daquele processo
        if (QueryFullProcessImageName(hProcess, 0, buffer, size) != 0) {
          final processPath = buffer.toDartString().toLowerCase();
          // Se for o mesmo executável, assumimos que é uma janela irmã
          if (processPath == myExeName) {
            appHwnds.add(hwnd);
          }
        }
        free(buffer);
        free(size);
        CloseHandle(hProcess);
      }
      // Pega próxima janela da fila
      hwnd = FindWindowEx(0, hwnd, className, nullptr);
    }
    // Libera a string ffi da memória
    free(className);

    // Regra: "Se existirem duas janelas/telas abertas, alternar para a outra janela"
    if (appHwnds.length == 2) {
      // Como o usuário acabou de clicar duas vezes, essa janela atual está focada
      final currentForeground = GetForegroundWindow();
      
      // Procura na lista a janela que não seja a janela focada
      int targetHwnd = appHwnds.firstWhere(
        (h) => h != currentForeground, 
        orElse: () => 0
      );

      if (targetHwnd != 0) {
        // Envia o comando para maximizar caso esteja minimizada
        // 3 representa o comando nativo Windows SW_SHOWMAXIMIZED
        ShowWindow(targetHwnd, 3);
        // Coloca a janela encontrada em primeiro plano no Windows
        SetForegroundWindow(targetHwnd);
      }
    }
  }

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

            //  ESCALA DINÂMICA BASEADA NA RESOLUÇÃO 
            // Todos os tamanhos são calculados proporcionalmente
            // usando maxW e maxH como referência

            // AppBar responsiva
            final double appBarHeight = (maxH * 0.08).clamp(50.0, 120.0);
            final double appBarFontSize = (maxW * 0.018).clamp(14.0, 42.0);
            final double appBarLetterSpacing = (maxW * 0.002).clamp(1.0, 6.0);
            final double iconSize = (appBarHeight * 0.5).clamp(24.0, 56.0);

            // Cabeçalhos das colunas (EM PREPARO / PRONTO)
            final double headerFontSize = (maxW * 0.022).clamp(16.0, 52.0);
            final double headerPaddingV = (maxH * 0.022).clamp(10.0, 40.0);

            // Itens da lista – coluna EM PREPARO
            final double preparoNumeroFontSize = (maxW * 0.035).clamp(28.0, 80.0);
            final double preparoNomeFontSize = (maxW * 0.022).clamp(16.0, 52.0);
            final double preparoNumeroWidth = (maxW * 0.08).clamp(70.0, 200.0);

            // Itens da lista – coluna PRONTO (maiores para destaque)
            final double prontoNumeroFontSize = (maxW * 0.048).clamp(36.0, 110.0);
            final double prontoNomeFontSize = (maxW * 0.032).clamp(22.0, 72.0);
            final double prontoNumeroWidth = (maxW * 0.09).clamp(80.0, 240.0);

            // Espaçamentos dinâmicos
            final double itemSpacingH = (maxW * 0.012).clamp(8.0, 30.0);
            final double listPaddingH = (maxW * 0.018).clamp(10.0, 44.0);
            final double listPaddingV = (maxH * 0.018).clamp(10.0, 36.0);
            final double separatorPaddingV = (maxH * 0.005).clamp(2.0, 12.0);

            //  APPBAR CUSTOMIZADA 
            final appBar = GestureDetector(
              onDoubleTap: () async {
                if (Platform.isWindows) {
                  await _verificarEAlternarJanelas();
                }
              },
              child: Container(
                width: double.infinity,
                height: appBarHeight,
                padding: EdgeInsets.symmetric(horizontal: maxW * 0.01),
                child: Row(
                  children: [
                    // Botão do drawer
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
                    // Título centralizado
                    Expanded(
                      child: Text(
                        "ACOMPANHE SEU PEDIDO",
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
                    // SizedBox(width: iconSize + 16)),
                  ],
                ),
              ),
            );

            //  COLUNA EM PREPARO 
            final colunaPreparo = Column(
              children: [
                // Cabeçalho
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
                    "EM PREPARO",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: headerFontSize,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.scrim,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                // Lista de pedidos
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

                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: separatorPaddingV),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // NUMERO — largura proporcional
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
                            // NOME — ocupa todo o espaço restante
                            Expanded(
                              child: Text(
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
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );

            //  COLUNA PRONTO 
            final colunaPronto = Column(
              children: [
                // Cabeçalho
                GestureDetector(
                  onDoubleTap: () async {
                    if (Platform.isWindows) {
                      await _verificarEAlternarJanelas();
                    }
                  },
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
                      "PRONTO",
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
                // Lista de pedidos
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

                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: separatorPaddingV),
                        child: GestureDetector(
                          onTap: () {
                            shownDialogTwoBottom(
                              context: context,
                              title: "Pedido $numeroPedido retirado?",
                              icon: Icons.check,
                              onConfirm: () async {
                                 // update o status do pedido para entregue
                                  await mudarStatusPedido(numeroPedidoReal);
                                  await painelController.buscarPedidosProntos();
                                  _buscarEOrganizar();
                              },
                              onCancel: () async {
                              },
                            );
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // NUMERO — largura proporcional (maior que "em preparo")
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
                              // NOME — ocupa todo o espaço restante
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
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );

            //  LAYOUT FINAL 
            if (isWideScreen) {
              // Tela larga: AppBar + colunas lado a lado
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
              // Tela estreita: AppBar + colunas empilhadas
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

    if (Platform.isWindows) {
      final screenHeight = MediaQuery.of(context).size.height;

      body = MouseRegion(
        onHover: (event) async {
          final dy = event.position.dy;
          // Se o mouse estiver no topo (<= 15) ou embaixo (>= screenHeight - 15) 
          // sai do fullscreen para mostrar título/taskbar nativa
          if (dy <= 15 || dy >= screenHeight - 15) {
            if (_isFullScreen) {
              _isFullScreen = false;
              await windowManager.setFullScreen(false);
              await windowManager.maximize();
            }
          } 
          // Se o mouse descer ou subir de volta para a região segura, volta a tela cheia
          else if (dy > 40 && dy < screenHeight - 40) {
            if (!_isFullScreen) {
              _isFullScreen = true;
              await windowManager.setFullScreen(true);
            }
          }
        },
        child: body,
      );
    }

    return body;
  }
}
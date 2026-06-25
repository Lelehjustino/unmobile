import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:un_recepcao/controllers/views/funcoes_controller.dart';
import 'package:un_recepcao/controllers/views/painel_controller.dart';
import 'package:un_recepcao/data/data_class.dart';
import 'package:un_recepcao/views/checkin_page.dart';
import 'package:un_recepcao/views/checkout_page.dart';
import 'package:un_recepcao/views/conta_page.dart';
import 'package:un_recepcao/views/garcom_page.dart';
import 'package:un_recepcao/views/notes_page.dart';
import 'package:un_recepcao/views/recepcao_page.dart';
import 'package:un_recepcao/widgets/side_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  @override
  State<MapaPage> createState() => MapaPageState();
}

class MapaPageState extends State<MapaPage> {

  String versaoAplicacao = FuncoesController().versaoDoApp;
  final FuncoesController funcoesController = Get.put(FuncoesController());
  final painelController = Get.put(PainelController());

  final TextEditingController comandaController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Teclado barra de busca
  final TextEditingController barraBusca = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isFocused = false;
  String? selectedModo;

  late Timer _timer;
  String _horaAtual = '';
  String nomeEmpresa = '';

  bool mostrarTodas = false;
  bool mostrarAbertas = true; // começa selecionado
  bool mostrarFechadas = false;

  bool mostrarMesas = false; // true = mesas, false = comandas
  bool mostrarMesaseComandas = true;

  bool _showKeyboardNome = false;
  List<dynamic> todasMesas = [];
  List<dynamic> abertasMesas = [];
  List<dynamic> fechadasMesas = [];
  List<dynamic> comandasVinculadas = [];
  List<dynamic> comandasVinculadasMesa = [];

  List<dynamic> todasComandas = [];
  List<dynamic> abertasComandas = [];
  List<dynamic> fechadasComandas = [];

  bool aberto = false;
  bool conta = false;
  bool servidorConectado = true;

  // Para fazer requisições em determinado tempo (1/3)
  Timer? _timerMesas;

  bool aparecerNote = false;
  bool aparecerCheckInOut = false;
  bool aparecerRecepcao = false;
  bool naoAparecerMapa = false;
  bool aparecerCheckIn = false;
  bool aparecerCheckOut = false;
  bool aparecerGarcom = true;

  String nomeCliente = '';
  bool isLoadingRefresh = false;

  // final variaveis = Get.find<VariaveisController>();

  String tipoDoPedido = "";
  bool logicaPorMesa = false;
  bool logicaPorComanda = false;
  bool logicaPorComandaNaMesa = false;

  String nomeEmpresaLoad = '';
  String numeroDaLicencaSelecionada = '';

  bool existePedidoMesa = false;
  bool comandaValida = false;
  bool mesaComandaNaoTemConta = true;
  bool existePedidoComanda = false;
  String numeropedido_FK = '';

  List<dynamic> validaComanda = [];

  String nomePVD = '';
  String mobileId = '';

  @override
  void initState() {
    super.initState();

    painelController.estaNoPainelCozinha.value = false;

    _atualizarHora();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _atualizarHora());
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
    _searchFocusNode.addListener(() {
      setState(() {
        _isFocused = _searchFocusNode.hasFocus;
      });
    });
    _carregarModo();
    _carregarNote();
    _carregarchecks();
    _carregargarcom();

    _toggleAberta();
    carregarTodasAsComandas();
    carregarAsComandasAbertas();
    carregarAsComandasFechadas();
    _carregarRecepcao();
    buscarTipoPedido();
    _loadNomeEmpresa();
    _loadNumeroLicenca();

    // Para fazer requisições em determinado tempo (2/3)
    /* _timerMesas = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
        _toggleAberta();
      }
    }); */
  }

  // Load nomeEmpresa
  Future<void> _loadNomeEmpresa() async {
    final prefs = await SharedPreferences.getInstance();
    final nomeEmpresaSalvo = prefs.getString('nomeEmpresa');
    if (nomeEmpresaSalvo != null) {
      setState(() {
        nomeEmpresaLoad = nomeEmpresaSalvo;
      });
    }
  }

  // Buscar tipo do pedido
  // Função para descobrir tipo do pedido
  Future<void> buscarTipoPedido() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT resultado FROM configuracoes WHERE numero='23';",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        String valor = lista[0]['resultado'].toString();

        setState(() {
          tipoDoPedido = valor;
          if (tipoDoPedido == "100") {
            logicaPorMesa = true;
          } else if (tipoDoPedido == "010") {
            logicaPorComanda = true;
          } else if (tipoDoPedido == "011") {
            logicaPorComandaNaMesa = true;
          }
        });
        print("Tipo do pedido: $tipoDoPedido");
      } else {
        // se a lista vier vazia
        setState(() {
          tipoDoPedido = "Não foi possível buscar tipo do pedido";
        });
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
      setState(() {
        tipoDoPedido = "0";
      });
    }
  }

  // Dialogo com só um botão - vermelho erro
  Future<void> showErrorDialog({
    required BuildContext context,
    String title = 'Confirmação',
    required String message,
    IconData icon = Icons.home,
    String cancelText = 'Cancelar',
    String confirmText = 'OK',
    VoidCallback? onConfirm,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(curvedAnim),
          child: FadeTransition(
            opacity: curvedAnim,
            child: Dialog(
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
                        color: Theme.of(
                          ctx,
                        ).colorScheme.error.withOpacity(0.08),
                      ),
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        icon,
                        size: 40,
                        color: Theme.of(ctx).colorScheme.error,
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

                    // Botões centralizados
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Confirmar
                        ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
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
                            backgroundColor: Theme.of(ctx).colorScheme.error,
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
  }

  Future<void> conectarBanco() async {
    final prefs = await SharedPreferences.getInstance();
    final servidor = prefs.getString('servidor');

    if (servidor == null || servidor.isEmpty) {
      print("Servidor não definido no SharedPreferences.");
      setState(() {
        servidorConectado = false;
        // _isLoading = false; // encerra o carregamento mesmo com erro
      });
      return;
    }

    try {
      servidorConectado = await Connection.conectarBanco();

      setState(() {
        servidorConectado = true; // Conexão OK
        // _isLoading = false; // Para o loading
      });
    } catch (e) {
      print("Erro ao conectar: $e");

      setState(() {
        servidorConectado = false; // Falhou
        // _isLoading = false; // Também para o loading
      });
    }
  }

  // Função carregar TODAS as comandas
  Future<void> carregarTodasAsComandas() async {
    try {
      await Future.delayed(Duration.zero);

      String dadosJson = await Connection().select(
        "SELECT nomecliente, numero, statuspedido, numeropedido_FK, numeromesa FROM cartoes WHERE ativo='1' ORDER BY numero",
      );

      if (!mounted) return;

      final List<dynamic> lista = jsonDecode(dadosJson);

      setState(() {
        todasComandas = lista;
      });
    } catch (e) {
      print("Erro ao carregar todas as comandas: $e");
      if (!mounted) return;
      setState(() => todasComandas = []);
    }
  }

  // Função carregar TODAS as mesas
  Future<void> carregarTodasAsMesas() async {
    try {
      await Future.delayed(Duration.zero);

      String dadosJson = await Connection().select(
        "SELECT numero, statuspedido, numeropedido_FK, comandavinculada, balcaovinculado FROM mesas WHERE ativo='1' ORDER BY numero",
      );

      if (!mounted) return;

      final List<dynamic> lista = jsonDecode(dadosJson);

      setState(() {
        todasMesas = lista;
      });
    } catch (e) {
      print("Erro ao carregar todas as mesas: $e");
      if (!mounted) return;
      setState(() => todasMesas = []);
    }
  }

  // Função carregar as comandas ABERTAS
  Future<void> carregarAsComandasAbertas() async {
    try {
      await Future.delayed(Duration.zero);

      String dadosJson = await Connection().select(
        "SELECT numero, statuspedido, numeropedido_FK, numeromesa, nomecliente, valorliquidopedido FROM cartoes WHERE ativo='1' AND (numeropedido_FK!='0') ORDER BY numero",
      );

      if (!mounted) return;

      final List<dynamic> lista = jsonDecode(dadosJson);

      setState(() {
        abertasComandas = lista;
      });
    } catch (e) {
      print("Erro ao carregar as comandas abertas: $e");
      if (!mounted) return;
      setState(() => abertasComandas = []);
    }
  }

  // Função carregar as mesas ABERTAS
  Future<void> carregarAsMesasAbertas() async {
    try {
      await Future.delayed(Duration.zero);

      String dadosJson = await Connection().select(
        "SELECT numero, statuspedido, numeropedido_FK, comandavinculada, balcaovinculado, valorliquidopedido FROM mesas WHERE ativo='1' AND (numeropedido_FK!='0' OR balcaovinculado = '1' OR comandavinculada = '1') ORDER BY numero",
      );

      if (!mounted) return;

      final List<dynamic> lista = jsonDecode(dadosJson);

      setState(() {
        abertasMesas = lista;
      });
    } catch (e) {
      print("Erro ao carregar as mesas abertas: $e");
      if (!mounted) return;
      setState(() => abertasMesas = []);
    }
  }

  // Função carregar as comandas FECHADAS
  Future<void> carregarAsComandasFechadas() async {
    try {
      await Future.delayed(Duration.zero);

      String dadosJson = await Connection().select(
        "SELECT numero, statuspedido, numeropedido_FK, numeromesa FROM cartoes WHERE ativo='1' AND numeropedido_FK='0' ORDER BY numero",
      );

      if (!mounted) return;

      final List<dynamic> lista = jsonDecode(dadosJson);

      setState(() {
        fechadasComandas = lista;
      });
    } catch (e) {
      print("Erro ao carregar as comandas fechadas: $e");
      if (!mounted) return;
      setState(() => fechadasComandas = []);
    }
  }

  // Função carregar as mesas FECHADAS
  Future<void> carregarAsMesasFechadas() async {
    try {
      await Future.delayed(Duration.zero);

      String dadosJson = await Connection().select(
        "SELECT numero, statuspedido, numeropedido_FK, comandavinculada, balcaovinculado FROM mesas WHERE ativo='1' AND numeropedido_FK='0' AND comandavinculada='0' AND balcaovinculado = '0' ORDER BY numero",
      );

      if (!mounted) return;

      final List<dynamic> lista = jsonDecode(dadosJson);

      setState(() {
        fechadasMesas = lista;
      });
    } catch (e) {
      print("Erro ao carregar as mesas fechadas: $e");
      if (!mounted) return;
      setState(() => fechadasMesas = []);
    }
  }

  // Função carregar TODAS as comandas vinculadas com mesa
  Future<List<dynamic>> buscarComandasMesa(dynamic numeroMesa) async {
    try {
      await Future.delayed(Duration.zero);

      String dadosJson = await Connection().select(
        "SELECT numero FROM cartoes WHERE numeromesa = $numeroMesa ORDER BY numero",
      );

      return jsonDecode(dadosJson);
    } catch (e) {
      print("Erro ao carregar comandas: $e");
      return [];
    }
  }

  void _atualizarHora() {
    if (mounted) {
      setState(() {
        _horaAtual = DateFormat.Hm().format(DateTime.now());
      });
    }
  }

  // Adiciona um número
  void _adicionarNumero(String numero) {
    HapticFeedback.lightImpact();
    setState(() {
      final textoAtual = comandaController.text;
      final novoTexto = textoAtual + numero;
      comandaController.text = novoTexto;
      comandaController.selection = TextSelection.fromPosition(
        TextPosition(offset: comandaController.text.length),
      );
    });
    FocusScope.of(context).requestFocus(_searchFocusNode);
  }

  // Apaga o último dígito
  void _apagarNumero() {
    HapticFeedback.lightImpact();
    setState(() {
      final textoAtual = comandaController.text;
      if (textoAtual.isNotEmpty) {
        final novoTexto = textoAtual.substring(0, textoAtual.length - 1);
        comandaController.text = novoTexto;
        comandaController.selection = TextSelection.fromPosition(
          TextPosition(offset: comandaController.text.length),
        );
      }
    });
    FocusScope.of(context).requestFocus(_searchFocusNode);
  }

  // Função para confirmar numero da comanda
  void _confirmar() {
    setState(() {
      _showKeyboardNome = false;
      FocusScope.of(context).unfocus(); // Esconde o teclado e remove o foco
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _focusNode.dispose();
    _searchFocusNode.dispose();
    comandaController.dispose();
    barraBusca.dispose();
    // Para fazer requisições em determinado tempo (3/3)
    _timerMesas?.cancel();
    super.dispose();
  }

  // Carregar recepcao
  Future<void> _carregarRecepcao() async {
    final prefs = await SharedPreferences.getInstance();
    final recepcaoJson = prefs.getString('recepcao_padrao');

    if (recepcaoJson != null) {
      final recepcaosSalvos = Set<String>.from(jsonDecode(recepcaoJson));

      if (recepcaosSalvos.contains('Recepção')) {
        // se recepcao selecionado
        setState(() {
          aparecerRecepcao = true;
        });
      } else {
        // se recepcao nao selecionado
        setState(() {
          aparecerRecepcao = false;
        });
      }
    } else {
      // configuração padrao
      setState(() {
        aparecerRecepcao = false;
      });
    }
  }

  // Carregar modo
  Future<void> _carregarModo() async {
    final prefs = await SharedPreferences.getInstance();
    final modoJson = prefs.getString('modo_padrao');

    if (modoJson != null) {
      final modosSalvos = Set<String>.from(jsonDecode(modoJson));

      if (modosSalvos.contains("Mesa") && !modosSalvos.contains("Comanda")) {
        setState(() {
          mostrarMesas = true;
          mostrarMesaseComandas = false;
          aparecerCheckInOut = false;
        });
      } else if (modosSalvos.contains("Mesa") &&
          modosSalvos.contains("Comanda")) {
        setState(() {
          mostrarMesas = false;
          mostrarMesaseComandas = true;
          aparecerCheckInOut = true;
        });
      } else if (!modosSalvos.contains("Mesa") &&
          modosSalvos.contains("Comanda")) {
        setState(() {
          mostrarMesas = false;
          mostrarMesaseComandas = false;
          aparecerCheckInOut = true;
        });
      } else if (!modosSalvos.contains("Mesa") &&
          !modosSalvos.contains("Comanda")) {
        setState(() {
          mostrarMesas = false;
          mostrarMesaseComandas = false;
          naoAparecerMapa = true;
          aparecerCheckInOut = false;
        });
      } else {
        setState(() {
          mostrarMesas = false;
          mostrarMesaseComandas = false;
          aparecerCheckInOut = true;
        });
      }
    } else {
      setState(() {
        // Se não tiver nada salvo, define padrão
        mostrarMesas = false;
        mostrarMesaseComandas = false;
      });
    }
  }

  // Carregar check
  Future<void> _carregarchecks() async {
    final prefs = await SharedPreferences.getInstance();
    final checkJson = prefs.getString('check_padrao');
    if (checkJson != null) {
      final checksSalvos = Set<String>.from(jsonDecode(checkJson));
      if (checksSalvos.contains("Ckeck-in") &&
          !checksSalvos.contains("Check-out")) {
        setState(() {
          aparecerCheckIn = true;
          aparecerCheckOut = false;
        });
      } else if (checksSalvos.contains("Check-out") &&
          !checksSalvos.contains("Ckeck-in")) {
        setState(() {
          aparecerCheckIn = false;
          aparecerCheckOut = true;
        });
      } else if (!checksSalvos.contains("Ckeck-in") &&
          !checksSalvos.contains("Check-out")) {
        setState(() {
          aparecerCheckIn = false;
          aparecerCheckOut = false;
        });
      } else if (checksSalvos.contains("Ckeck-in") &&
          checksSalvos.contains("Check-out")) {
        setState(() {
          aparecerCheckIn = true;
          aparecerCheckOut = true;
        });
      } else {
        setState(() {
          aparecerCheckIn = true;
          aparecerCheckOut = true;
        });
      }
    } else {
      setState(() {
        // Se não tiver nada salvo, define padrão
        aparecerCheckIn = false;
        aparecerCheckOut = false;
      });
    }
  }

  // Carregar garçom
  Future<void> _carregargarcom() async {
    final prefs = await SharedPreferences.getInstance();
    final garcomJson = prefs.getString('garcom_padrao');

    if (garcomJson != null) {
      final garcomSalvos = Set<String>.from(jsonDecode(garcomJson));

      if (garcomSalvos.contains("Modo Garçom")) {
        setState(() {
          aparecerGarcom = true;
        });
      } else if (!garcomSalvos.contains("Modo Garçom")) {
        setState(() {
          aparecerGarcom = false;
        });
      } else {
        setState(() {
          aparecerGarcom = true;
        });
      }

      /* if (garcomSalvos.contains("Sim") && !garcomSalvos.contains("Não")) {
        setState(() {
          aparecerGarcom = true;
        });
      } else if (!garcomSalvos.contains("Sim") && garcomSalvos.contains("Não")) {
        setState(() {
          aparecerGarcom = false;
        });
      } else if (!garcomSalvos.contains("Sim") && !garcomSalvos.contains("Não")) {
        setState(() {
          aparecerGarcom = true;
        });
      } else if(garcomSalvos.contains("Sim") && garcomSalvos.contains("Não")){
        setState(() {
          aparecerGarcom = true;
        });
      }
      else {
        setState(() {
          aparecerGarcom = true;
        });
      } */
    } else {
      setState(() {
        // Se não tiver nada salvo, define padrão
        aparecerGarcom = true;
      });
    }
  }

  // Carregar note
  Future<void> _carregarNote() async {
    final prefs = await SharedPreferences.getInstance();
    final noteJson = prefs.getString('note_padrao');

    if (noteJson != null) {
      final notesSalvos = Set<String>.from(jsonDecode(noteJson));

      if (notesSalvos.contains('Notes')) {
        // se note selecionado
        setState(() {
          aparecerNote = true;
        });
      } else {
        // se note nao selecionado
        setState(() {
          aparecerNote = false;
        });
      }
    } else {
      // configuração padrao
      setState(() {
        aparecerNote = false;
      });
    }
  }

  // Carregar selects
  Future<void> _toggleAberta() async {
    if (mostrarMesas) {
      await Future.wait([
        carregarTodasAsMesas(),
        carregarAsMesasAbertas(),
        carregarAsMesasFechadas(),
      ]);
    } else {
      await Future.wait([
        carregarTodasAsComandas(),
        carregarAsComandasAbertas(),
        carregarAsComandasFechadas(),
      ]);
    }

    if (mounted) {
      setState(() {});
    }
  }

  // Grid de mesas
  Widget _buildGridMesas(List<dynamic> items, bool isMesa) {
    return Expanded(
      child: GridView.builder(
        padding: EdgeInsets.all(8),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.9,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          final numeroMesa = item['numero'];
          final status = int.parse(item['statuspedido'] ?? '0');

          // Cada mesa decide seu estado individual
          final aberto = item['comandavinculada'].toString() != '0' || item['numeropedido_FK'].toString() != '0';
          final temConta = item['numeropedido_FK'].toString() != '0' && status == 2;
          final comandavinculada = item['comandavinculada'].toString() != '0';
          final valorContaRaw = item['valorliquidopedido'];
          final valorConta =
            (valorContaRaw != null &&
                valorContaRaw.toString() != 'null' &&
                valorContaRaw.toString() != '0' &&
                valorContaRaw.toString() != '0.00')
            ? valorContaRaw.toString()
            : null;

          // Define a cor do container
          Color corMesa;
          if (temConta) {
            corMesa = Theme.of(context).colorScheme.error; // aberta com conta
          } else if (!aberto) {
            corMesa = Theme.of(context).colorScheme.surfaceDim; // fechada
          } else {
            corMesa = Theme.of(
              context,
            ).colorScheme.tertiary; // aberta sem conta
          }

          return InkWell(
            onTap: () {
              if (logicaPorMesa) {
                if (comandavinculada) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Mesa vinculada a uma comanda!'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                } else if (temConta) {
                  // Ir para conta da mesa
                  Get.to(
                    () => ContaPage(),
                    arguments: {
                      'numeropedido': item['numeropedido_FK'].toString(),
                      'comanda': "0",
                      'mesa': item['numero'].toString(),
                      'page': "mapa",
                    },
                  );
                } else if (aberto) {
                  // Ir para o garçom para adicionar itens
                  Get.to(
                    () => GarcomPage(),
                    arguments: {
                      'numeropedido': item['numeropedido_FK'].toString(),
                      'comanda': "0",
                      'mesa': item['numero'].toString(),
                    },
                  );
                } else if (!aberto) {
                  // Ir para o garçom para iniciar comanda
                  Get.to(
                    () => GarcomPage(),
                    arguments: {
                      'numeropedido': "0",
                      'comanda': "0",
                      'mesa': item['numero'].toString(),
                    },
                  );
                }
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: corMesa,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double iconSize = constraints.maxWidth * 0.2;
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            comandavinculada
                                ? Column(
                                    children: [
                                      Icon(
                                        Icons.table_restaurant,
                                        size: iconSize,
                                        color: aberto
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onPrimary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onTertiary,
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Icon(
                                        Icons.table_restaurant,
                                        size: iconSize,
                                        color: aberto
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onPrimary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onTertiary,
                                      ),
                                    ],
                                  ),
                            Text(
                              numeroMesa,
                              maxLines: 1, // limita a 1 linha
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: constraints.maxWidth * 0.2,
                                color: aberto
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onTertiary,
                              ),
                            ),
                            if (comandavinculada)
                              SizedBox(
                                width: constraints.maxWidth,
                                child: FutureBuilder<List<dynamic>>(
                                  future: buscarComandasMesa(numeroMesa),
                                  builder: (context, snapshot) {
                                    final comandas = snapshot.data ?? [];

                                    final numerosFormatted = comandas
                                        .map((c) => c['numero'].toString())
                                        .join(', ');

                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'Comanda vinculada',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize:
                                                  constraints.maxWidth * 0.08,
                                              color: aberto
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.onPrimary
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.onTertiary,
                                            ),
                                          ),
                                        ),

                                        SizedBox(height: 4),

                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: Text(
                                            numerosFormatted.isEmpty
                                                ? '-'
                                                : numerosFormatted,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            softWrap: false,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize:
                                                  constraints.maxWidth * 0.10,
                                              color: aberto
                                                  ? Theme.of(
                                                      context,
                                                    ).colorScheme.onPrimary
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.onTertiary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            /* if (comandavinculada)
                              Column(
                                children: [
                                  if (comandavinculada)
                                    FutureBuilder<List<dynamic>>(
                                      // usado para lidar com operações assíncronas, no caso esperando a lista
                                      future: buscarComandasMesa(
                                        numeroMesa,
                                      ), // é isto que esta esperando
                                      builder: (context, snapshot) {
                                        // snapshot controla o estado
                                        final comandas =
                                            snapshot.data ??
                                            []; // você está pegando os dados que chegaram do Future
                                        final numerosFormatted = comandas
                                            .map((c) => c['numero'])
                                            .join(', ');
                                        // Retorna uma coluna com os dados
                                        return Column(
                                          children: [
                                            Text(
                                              'Comanda vinculada',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    constraints.maxWidth * 0.1,
                                                color: aberto
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.onPrimary
                                                    : Theme.of(
                                                        context,
                                                      ).colorScheme.onTertiary,
                                              ),
                                            ),
                                            Text(
                                              numerosFormatted,
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    constraints.maxWidth *
                                                    0.12,
                                                color: aberto
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.onPrimary
                                                    : Theme.of(context)
                                                          .colorScheme
                                                          .onTertiary,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                ],
                              ), */
                            /* SizedBox(
                                width: constraints.maxWidth,
                                child: FutureBuilder<List<dynamic>>(
                                  future: buscarComandasMesa(numeroMesa),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2)));
                                    }
                                    
                                    final comandas = snapshot.data ?? [];
                                    if (comandas.isEmpty) return const SizedBox();

                                    final numerosFormatted = comandas.map((c) => c['numero']).join(', ');

                                    return Text(
                                      numerosFormatted,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: constraints.maxWidth * 0.12,
                                        color: aberto
                                          ? Theme.of(context).colorScheme.onPrimary
                                          : Theme.of(context).colorScheme.onTertiary,
                                      ),
                                    );
                                  },
                                ),
                              ), */
                            /* SizedBox(
                                width: constraints.maxWidth,
                                child: FutureBuilder<List<dynamic>>(
                                  future: buscarComandasMesa(numeroMesa),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2)));
                                    }
                                    
                                    final comandas = snapshot.data ?? [];
                                    if (comandas.isEmpty) return const SizedBox();

                                    final numerosFormatted = comandas.map((c) => c['numero']).join(', ');

                                    return Text(
                                      numerosFormatted,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: constraints.maxWidth * 0.12,
                                        color: aberto
                                          ? Theme.of(context).colorScheme.onPrimary
                                          : Theme.of(context).colorScheme.onTertiary,
                                      ),
                                    );
                                  },
                                ),
                              ), */
                          ],
                        ),
                      );
                    },
                  ),
                  Column(
                    children: [
                      Text(
                        aberto ? (temConta ? 'Em conta' : 'Aberta') : 'Fechada',
                        style: TextStyle(
                          color: aberto
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onTertiary,
                        ),
                      ),
                      if (valorConta != null)
                        Column(
                          children: [
                            Text(
                              'R\$ $valorConta',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: aberto
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onTertiary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Função para atualizar comanda
  Future<void> atualizarComanda(String numeroPVD, String numeroComanda) async {
    String numeroPVDNoUpdate = numeroPVD;
    String numeroComandaNoUpdate = numeroComanda;

    // Monta o SQL UPDATE
    String sql =
        '''
      UPDATE cartoes SET atendimento='$numeroPVDNoUpdate' WHERE numero='$numeroComandaNoUpdate'; 
    ''';

    // Executa o SQL usando a função ipd
    String resultado = await Connection().ipd(sql);

    if (resultado == "sucesso") {
      print("Comanda atualizada com sucesso!");
    } else {
      print("Erro ao atualizar comanda.");
    }
  }

  Future<void> saveComanda(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('comanda', value);
  }

  Future<void> _loadNumeroLicenca() async {
    final prefs = await SharedPreferences.getInstance();
    final licencaSalvoNumero = prefs.getString('licencaNumero');
    if (licencaSalvoNumero != null && mounted) {
      setState(() {
        numeroDaLicencaSelecionada = licencaSalvoNumero;
      });
    }
  }

  // Função para zerar atendimento de uma comanda
  Future<void> zerarAtendimentoComanda() async {
    await _loadNumeroLicenca();
    // Monta o SQL UPDATE
    String sql =
        """
      UPDATE cartoes SET atendimento = '0' WHERE atendimento = '$numeroDaLicencaSelecionada';
      UPDATE mesas SET atendimento = '0' WHERE atendimento = '$numeroDaLicencaSelecionada';
    """;

    // Executa o SQL usando a função ipd
    String resultado = await Connection().ipd(sql);

    if (resultado == "sucesso") {
      print("Atendimento zerado com sucesso!");
    } else {
      print("Erro ao zerar atendimento.");
    }
  }

  // Função para validar comanda
  Future<void> validarComanda(String numeroComanda) async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, ativo, bloqueada, atendimento, statuspedido, numeropedido_FK, numeromesa, valorliquidopedido FROM cartoes WHERE numero='$numeroComanda';",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isEmpty) {
        print("Nenhuma comanda encontrada!");
        setState(() {
          validaComanda = [];
          comandaValida = false;
          mesaComandaNaoTemConta = true;
        });
        return;
      }
      Map<String, dynamic> comanda = lista[0];
      setState(() {
        numeropedido_FK = comanda['numeropedido_FK'];
      });

      // Exemplo de validações:
      if (comanda['numero'] == null) {
        setState(() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Comanda inexistente'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          comandaValida = false;
          mesaComandaNaoTemConta = true;
        });
      } else if (comanda['ativo'] == '0') {
        setState(() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Comanda inativa!'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          comandaValida = false;
          mesaComandaNaoTemConta = true;
        });
      } else if (comanda['bloqueada'] == '1') {
        setState(() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Comanda bloqueada!'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          comandaValida = false;
          mesaComandaNaoTemConta = true;
        });
      }
      // Verifica atendimento ANTES de verificar numeromesa
      else if (comanda['atendimento'] != '0') {
        // Carrega licença ANTES de comparar
        await _loadNumeroLicenca();

        // Select para conseguir o nome do PVD que já esta atendendo esta comanda
        String dadosJson = await Connection().select(
          "SELECT nome, numero FROM tradepoints WHERE numero='${comanda['atendimento']}';",
        );

        List<dynamic> lista = jsonDecode(dadosJson);
        print(dadosJson);

        if (lista.isNotEmpty) {
          final valor = lista[0]['nome'].toString();
          final valor2 = lista[0]['numero'].toString();
          setState(() {
            nomePVD = valor;
            mobileId = valor2;
          });
        } else {
          setState(() {
            nomePVD = "Não foi possível rastrear PDV";
          });
        }

        if (numeroDaLicencaSelecionada != mobileId) {
          // Outro PDV está atendendo - NÃO atualiza
          setState(() {
            showErrorDialog(
              context: context,
              title: "Comanda já esta sendo atendida pelo PVD $nomePVD!",
              message: "",
              icon: Icons.error, // você pode trocar para outro ícone
              onConfirm: () async {},
            );
            comandaValida = false;
          });
        } else {
          // Mesmo PDV - pode continuar
          try {
            await atualizarComanda(numeroDaLicencaSelecionada, numeroComanda);
            await saveComanda(numeroComanda);

            if (comanda['statuspedido'] == '2') {
              await atualizarComanda(numeroDaLicencaSelecionada, numeroComanda);
              setState(() {
                mesaComandaNaoTemConta = false;
                Get.to(
                  () => ContaPage(),
                  arguments: {
                    'numeropedido': comanda['numeropedido_FK'].toString(),
                    'comanda': numeroComanda,
                    'mesa': comanda['numeromesa'].toString(),
                    'page': "mapa",
                  },
                );
              });
            }

            if (logicaPorComanda) {
              setState(() {
                Get.to(
                  () => GarcomPage(),
                  arguments: {
                    'numeropedido': comanda['numeropedido_FK'].toString(),
                    'comanda': numeroComanda,
                    'mesa': "",
                  },
                );
              });
            } else if (logicaPorComandaNaMesa) {
              setState(() {
                Get.to(
                  () => GarcomPage(),
                  arguments: {
                    'numeropedido': comanda['numeropedido_FK'].toString(),
                    'comanda': numeroComanda,
                    'mesa': comanda['numeromesa'].toString(),
                  },
                );
              });
            }
          } catch (e) {
            setState(() {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao abrir comanda.'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
              comandaValida = false;
            });
          }
        }
        setState(() {
          validaComanda = lista;
        });
      } else if (comanda['statuspedido'] == '2') {
        await atualizarComanda(numeroDaLicencaSelecionada, numeroComanda);
        setState(() {
          mesaComandaNaoTemConta = false;
          Get.to(
            () => ContaPage(),
            arguments: {
              'numeropedido': comanda['numeropedido_FK'].toString(),
              'comanda': numeroComanda,
              'mesa': comanda['numeromesa'].toString(),
              'page': "mapa",
            },
          );
        });
      } else if (comanda['numeromesa'] != '0') {
        // Comanda com mesa vinculada e sem atendimento
        await _loadNumeroLicenca();
        await atualizarComanda(numeroDaLicencaSelecionada, numeroComanda);
        await saveComanda(numeroComanda);

        double valorLiquido =
            double.tryParse(comanda['valorliquidopedido'].toString()) ?? 0.0;

        if (logicaPorComanda) {
          setState(() {
            Get.to(
              () => GarcomPage(),
              arguments: {
                'numeropedido': comanda['numeropedido_FK'].toString(),
                'comanda': numeroComanda,
                'mesa': "",
              },
            );
          });
        } else if (logicaPorComandaNaMesa) {
          setState(() {
            Get.to(
              () => GarcomPage(),
              arguments: {
                'numeropedido': comanda['numeropedido_FK'].toString(),
                'comanda': numeroComanda,
                'mesa': comanda['numeromesa'].toString(),
              },
            );
          });
        }
        // COMANDA VAZIA PARA ABRIR
      } else {
        // Comanda Livre
        try {
          // Funções
          await _loadNumeroLicenca();
          await atualizarComanda(numeroDaLicencaSelecionada, numeroComanda);
          await saveComanda(numeroComanda);

          // Verificação se ja tem itens no pedido da comanda
          double valorLiquido =
              double.tryParse(comanda['valorliquidopedido'].toString()) ?? 0.0;

          setState(() {
            Get.to(
              () => GarcomPage(),
              arguments: {
                'numeropedido': comanda['numeropedido_FK'].toString(),
                'comanda': numeroComanda,
                'mesa': "",
              },
            );
          });
        } catch (e) {
          setState(() {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao abrir comanda. Tente novamente.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
            comandaValida = false;
            mesaComandaNaoTemConta = true;
          });
        }
      }
      setState(() {
        validaComanda = lista;
      });
    } catch (e) {
      print("Erro ao carregar validaComanda: $e");
    }
  }

  // Build Grid comandas
  Widget _buildGridComandas(List<dynamic> items, bool isMesa) {
    return Expanded(
      child: GridView.builder(
        padding: EdgeInsets.all(8),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.9,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          final numeroComanda = item['numero'];
          final status = int.parse(item['statuspedido'] ?? '0');
          var mesa = item['numeromesa'].toString();
          final nomeClienteName = item['nomecliente'].toString();
          String nomeClienteNameFinal = nomeClienteName ?? '';
          // item[0]['nomecliente'].toString();

          // Cada mesa decide seu estado individual
          final aberto = item['numeropedido_FK'].toString() != '0';
          final temConta =
              item['numeropedido_FK'].toString() != '0' && status == 2;
          final mesaVinculada = item['numeromesa'].toString() != '0';
          final valorContaRaw = item['valorliquidopedido'];
          final valorConta =
              (valorContaRaw != null &&
                  valorContaRaw.toString() != 'null' &&
                  valorContaRaw.toString() != '0' &&
                  valorContaRaw.toString() != '0.00')
              ? valorContaRaw.toString()
              : null;

          // Define a cor do container
          Color corComanda;
          if (temConta) {
            corComanda = Theme.of(
              context,
            ).colorScheme.error; // aberta com conta
          } else if (!aberto) {
            corComanda = Theme.of(context).colorScheme.surfaceDim; // fechada
          } else {
            corComanda = Theme.of(
              context,
            ).colorScheme.primaryContainer; // aberta sem conta
          }

          if (mesa == "") {
            mesa = "0";
          } else {
            mesa = mesa;
          }

          return InkWell(
            onTap: () async {
              if (logicaPorComanda || logicaPorComandaNaMesa) {
                await validarComanda(numeroComanda);

                /* if (temConta) {
                  // Ir para conta da comanda
                  Get.to(
                    () => ContaPage(),
                    arguments: {
                      'numeropedido': item['numeropedido_FK'].toString(),
                      'comanda': item['numero'].toString(),
                      'mesa': mesa,
                    },
                  );
                } else if (aberto) {
                  // Ir para o garçom para adicionar itens
                  Get.to(
                    () => GarcomPage(),
                    arguments: {
                      'numeropedido': item['numeropedido_FK'].toString(),
                      'comanda': item['numero'].toString(),
                      'mesa': mesa,
                    },
                  );
                } else if (!aberto) {
                  // Ir para o garçom para iniciar comanda
                  Get.to(
                    () => GarcomPage(),
                    arguments: {
                      'numeropedido': "0",
                      'comanda': item['numero'].toString(),
                      'mesa': "0",
                    },
                  );
                } */
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: corComanda,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  mesaVinculada
                      ? LayoutBuilder(
                          builder: (context, constraints) {
                            double iconSize = constraints.maxWidth * 0.3;
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.description,
                                    size: constraints.maxWidth * 0.3,
                                    color: aberto
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onTertiary,
                                  ),
                                  Text(
                                    "$numeroComanda",
                                    maxLines: 1, // limita a 1 linha
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: constraints.maxWidth * 0.2,
                                      color: aberto
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.onPrimary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onTertiary,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Column(
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                "Mesa: $mesa",
                                                maxLines: 1, // limita a 1 linha
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  // fontWeight: FontWeight.bold,
                                                  fontSize:
                                                      constraints.maxWidth *
                                                      0.12,
                                                  color: aberto
                                                      ? Theme.of(
                                                          context,
                                                        ).colorScheme.onPrimary
                                                      : Theme.of(context)
                                                            .colorScheme
                                                            .onTertiary,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Icon(
                                                Icons.table_bar,
                                                size:
                                                    constraints.maxWidth * 0.12,
                                                color: aberto
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.onPrimary
                                                    : Theme.of(
                                                        context,
                                                      ).colorScheme.onTertiary,
                                              ),
                                            ],
                                          ),
                                          if (valorConta != null)
                                            Column(
                                              children: [
                                                Text(
                                                  'R\$ $valorConta',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: aberto
                                                        ? Theme.of(context)
                                                              .colorScheme
                                                              .onPrimary
                                                        : Theme.of(context)
                                                              .colorScheme
                                                              .onTertiary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            double iconSize = constraints.maxWidth * 0.3;
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.description,
                                    size: constraints.maxWidth * 0.3,
                                    color: aberto
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onTertiary,
                                  ),
                                  Text(
                                    "$numeroComanda",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: constraints.maxWidth * 0.2,
                                      color: aberto
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.onPrimary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  if (!mesaVinculada)
                    Column(
                      children: [
                        Text(
                          aberto
                              ? (temConta ? 'Em conta' : 'Aberta')
                              : 'Fechada',
                          style: TextStyle(
                            color: aberto
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onTertiary,
                          ),
                        ),
                        if (valorConta != null)
                          Column(
                            children: [
                              Text(
                                'R\$ $valorConta',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: aberto
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onTertiary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  if (nomeClienteNameFinal != '')
                    Text(
                      aberto ? nomeClienteNameFinal : '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: aberto
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onTertiary,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Cria botões de filtro
  Widget _buildFiltroBotao(
    IconData icon,
    String label,
    bool ativo,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: ativo
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 30, color: Colors.white),
                SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    List<dynamic> itensParaMostrar;

    // 1. Determina qual lista de DADOS usar (mesas ou comandas)
    if (mostrarMesas) {
      // 2. Filtra a lista com base no botão selecionado (Todas, Abertas, Fechadas)
      if (mostrarTodas) {
        itensParaMostrar = todasMesas;
      } else if (mostrarAbertas) {
        itensParaMostrar = abertasMesas;
      } else {
        // mostrarFechadas
        itensParaMostrar = fechadasMesas;
      }
    } else {
      // Lógica para Comandas (quando implementado)
      if (mostrarTodas) {
        itensParaMostrar = todasComandas;
      } else if (mostrarAbertas) {
        itensParaMostrar = abertasComandas;
      } else {
        itensParaMostrar = fechadasComandas;
      }
    }

    // Busca na barra de pesquisa
    if (comandaController.text.isNotEmpty) {
      itensParaMostrar = itensParaMostrar.where((item) {
        return item['numero'].toString().contains(comandaController.text);
      }).toList();
    }

    // Cria a lista de status (aberto/fechado) correspondente aos itens filtrados
    List<bool> statusDosItens = itensParaMostrar.map<bool>((item) {
      return
      // item['numeropedido_FK'] != '0' ||
      // item['comandavinculada'] == '1' ||
      // item['balcaovinculado'] == '1' ||
      item['statuspedido'] == '1' || item['statuspedido'] == '2';
    }).toList();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: SideNav(),
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

                // CENTRO - Nome && Hora
                Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Nome observado em Obx
                      Text(
                        nomeEmpresaLoad,
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
                  /* Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                        "Versão: $versaoAplicacao",
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ), */
                ),
              ],
            ),
          );
        }),
      ),
      // return Scaffold(
      // drawer: SideNav(),
      // appBar: PreferredSize(
      //   preferredSize: Size.fromHeight(56),
      //   child:
      //   Obx(() {
      //     final conectado = Connection.connectionStatus.value;
      //     return AppBar(
      //       backgroundColor: Connection.connectionStatus.value ? colorScheme.primary : colorScheme.error,
      //       automaticallyImplyLeading: false,
      //       title: Stack(
      //         alignment: Alignment.center,
      //         children: [
      //           Align(
      //             alignment: Alignment.centerLeft,
      //             child: Builder(
      //               builder: (context) => IconButton(
      //                 icon: Icon(Icons.menu, color: colorScheme.onPrimary),
      //                 onPressed: () => Scaffold.of(context).openDrawer(),
      //               ),
      //             ),
      //           ),
      //           Padding(
      //             padding: EdgeInsets.all(5.0),
      //             child: Column(
      //               mainAxisAlignment: MainAxisAlignment.center,
      //               children: [
      //                 Obx(() => Text(
      //                       variaveis.nomeEmpresa.value,
      //                       style: TextStyle(
      //                         fontSize: 15,
      //                         fontWeight: FontWeight.bold,
      //                         color: colorScheme.onPrimary,
      //                       ),
      //                     )),
      //                 Text(
      //                   _horaAtual,
      //                   style: TextStyle(
      //                     color: colorScheme.onPrimary,
      //                     fontSize: 15,
      //                   ),
      //                 ),
      //               ],
      //             ),
      //           ),
      //           Align(
      //             alignment: Alignment.centerRight,
      //             child: Text(
      //               Connection.connectionStatus.value ? 'Online' : 'Offline',
      //               style: TextStyle(
      //                 color: colorScheme.onPrimary,
      //                 fontSize: 15,
      //                 fontWeight: FontWeight.bold,
      //               ),
      //             ),
      //           ),
      //         ],
      //       ),
      //     );
      //   }),
      // ),
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    _buildFiltroBotao(
                      Icons.lock_open,
                      'Abertas',
                      mostrarAbertas,
                      () {
                        setState(() {
                          mostrarTodas = false;
                          mostrarAbertas = true;
                          mostrarFechadas = false;
                        });
                      },
                    ),
                    SizedBox(width: 8),
                    _buildFiltroBotao(
                      Icons.lock,
                      'Fechadas',
                      mostrarFechadas,
                      () {
                        setState(() {
                          mostrarTodas = false;
                          mostrarAbertas = false;
                          mostrarFechadas = true;
                        });
                      },
                    ),
                    SizedBox(width: 8),
                    _buildFiltroBotao(Icons.list, 'Todas', mostrarTodas, () {
                      setState(() {
                        mostrarTodas = true;
                        mostrarAbertas = false;
                        mostrarFechadas = false;
                      });
                    }),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: Text(
                  mostrarMesas ? 'Mapa de mesas:' : 'Mapa de comandas:',
                  style: TextStyle(
                    color: colorScheme.onSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.06,
                        child: KeyboardActions(
                          disableScroll: true,
                          autoScroll: false,
                          config: KeyboardActionsConfig(
                            keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
                            nextFocus: false,
                            actions: [
                              KeyboardActionsItem(
                                focusNode: _searchFocusNode,
                                toolbarButtons: [
                                  (node) {
                                    return GestureDetector(
                                      onTap: () {
                                        node.unfocus();
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          "OK",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                ],
                              ),
                            ],
                          ),

                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: colorScheme.primary),
                            ),
                            child: TextField(
                              controller: comandaController,
                              focusNode: _searchFocusNode,
                              textAlign: TextAlign.center,
                              readOnly: false,
                              showCursor: true, // FORÇA o cursor piscando
                              cursorColor: Theme.of(context).colorScheme.primary,
                              keyboardType: TextInputType.number,
                              onTap: () {
                                Future.delayed(Duration(milliseconds: 300), () {
                                  if (_searchFocusNode.canRequestFocus) {
                                    _searchFocusNode.requestFocus();
                                  }
                                });
                              },
                              decoration: InputDecoration(
                                hintText: mostrarMesas
                                    ? 'Busque por mesas...'
                                    : 'Busque por comandas...',
                                filled: true,
                                fillColor: _isFocused
                                    ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
                                    : Theme.of(context).colorScheme.surface,
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // botões cloudy
                    // refresh
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AbsorbPointer(
                          // quando absorve o toque,  os filhos não são mais clicaveis
                          absorbing:
                              isLoadingRefresh, // true = bloqueia cliques
                          child: isLoadingRefresh
                              ? CircularProgressIndicator(
                                  strokeWidth: 6,
                                  valueColor: AlwaysStoppedAnimation(
                                    colorScheme.primary,
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: () async {
                                    setState(() => isLoadingRefresh = true);

                                    try {
                                      await _toggleAberta();
                                    } finally {
                                      if (mounted) {
                                        setState(
                                          () => isLoadingRefresh = false,
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: CircleBorder(),
                                    padding: EdgeInsets.all(20),
                                    backgroundColor: colorScheme.shadow,
                                    elevation: 8,
                                    shadowColor: Colors.black,
                                  ),
                                  child: Icon(
                                    Icons.refresh,
                                    size: 25,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                        ),
                        SizedBox(width: 3),
                        // botão mesa
                        if (mostrarMesaseComandas)
                          ElevatedButton(
                            onPressed: () async {
                              await _toggleAberta();
                              setState(() {
                                mostrarMesas = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              shape: CircleBorder(),
                              padding: EdgeInsets.all(20), // tamanho do círculo
                              backgroundColor: mostrarMesas
                                  ? colorScheme.tertiary
                                  : colorScheme.surfaceDim,
                              elevation:
                                  8, // Define a altura da sombra (quanto maior, mais "profunda" será a sombra)
                              shadowColor: Colors
                                  .black, // Cor da sombra com opacidade (ajuste conforme necessário)
                            ),
                            child: Icon(
                              Icons.table_restaurant,
                              size: 30,
                              color: colorScheme.onPrimary,
                            ),
                          ),

                        SizedBox(width: 3),
                        // botão comanda
                        if (mostrarMesaseComandas)
                          ElevatedButton(
                            onPressed: () async {
                              await _toggleAberta();
                              setState(() {
                                mostrarMesas = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              shape: CircleBorder(),
                              padding: EdgeInsets.all(20),
                              iconColor: colorScheme.secondary,
                              backgroundColor: mostrarMesas
                                  ? colorScheme.surfaceDim
                                  : colorScheme.primaryContainer,
                              elevation:
                                  8, // Define a altura da sombra (quanto maior, mais "profunda" será a sombra)
                              shadowColor: Colors
                                  .black, // Cor da sombra com opacidade (ajuste conforme necessário)
                            ),
                            child: Icon(
                              Icons.description,
                              size: 30,
                              color: colorScheme.onTertiary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // AQUI passamos as listas JÁ FILTRADAS para os widgets
              if (mostrarMesas)
                _buildGridMesas(itensParaMostrar, true)
              else
                _buildGridComandas(itensParaMostrar, false),
            ],
          ),
          /* if (_showKeyboardNome)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height:
                    MediaQuery.of(context).size.height *
                    0.4, // Tamanho do teclado
                width: MediaQuery.of(context).size.width, // Largura total
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final int crossAxisCount = 3;
                    final int itemCount = 12;
                    final double spacing = 8.0; // espaço entre teclas
                    final int rows = (itemCount / crossAxisCount).ceil();

                    // mantém proporção quadrada
                    final double cellWidth =
                        (constraints.maxWidth -
                            (spacing * (crossAxisCount - 1))) /
                        crossAxisCount;
                    final double cellHeight =
                        (constraints.maxHeight - (spacing * (rows - 1))) / rows;
                    final double childAspectRatio = cellWidth / cellHeight;

                    return GridView.builder(
                      padding: const EdgeInsets.all(
                        12,
                      ), // padding externo no grid inteiro
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: itemCount,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        if (index == 9) {
                          return ElevatedButton(
                            onPressed: _apagarNumero,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                              // padding: const EdgeInsets.all(16), // padding interno
                              padding: EdgeInsets.zero, // Remove o padding fixo
                              backgroundColor: colorScheme.onPrimary,
                            ),
                            child: Icon(
                              Icons.backspace,
                              size: 32, // ícone maior
                              color: colorScheme.primary,
                            ),
                          );
                        } else if (index == 10) {
                          return ElevatedButton(
                            onPressed: () => _adicionarNumero("0"),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                              // padding: const EdgeInsets.all(16), // padding interno
                              padding: EdgeInsets.zero, // Remove o padding fixo
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: const Text(
                                "0",
                                style: TextStyle(fontSize: 28), // número maior
                              ),
                            ),
                          );
                        } else if (index == 11) {
                          // Botão para fechar teclado
                          return ElevatedButton(
                            onPressed: _confirmar,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                              padding: EdgeInsets.zero, // Remove o padding fixo
                              backgroundColor: colorScheme.primary,
                            ),
                            child: Icon(
                              Icons.arrow_downward,
                              size: 32, // ícone maior
                              color: colorScheme.onPrimary,
                            ),
                          );
                        } else {
                          final numero = (index + 1).toString();
                          return ElevatedButton(
                            onPressed: () => _adicionarNumero(numero),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                              padding: EdgeInsets.zero, // Remove o padding fixo
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                numero,
                                style: const TextStyle(
                                  fontSize: 28,
                                ), // Isso será ajustado automaticamente
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ), */
        ],
      ),
      bottomNavigationBar:
          // Barra inferior com botões quadrados
          _showKeyboardNome
          ? Padding(
              padding: aparecerNote
                  ? EdgeInsets.only(
                      top: 5.0,
                      bottom: 0.0,
                      left: 10.0,
                      right: 10.0,
                    )
                  : EdgeInsets.only(
                      top: 5.0,
                      bottom: 0.0,
                      left: 15.0,
                      right: 15.0,
                    ),
              child: Row(),
            )
          :
            // Barra inferior com botões quadrados
            Padding(
              padding: aparecerNote
                  ? EdgeInsets.only(top: 5.0, bottom: 15.0)
                  : EdgeInsets.only(top: 5.0, bottom: 15.0),
              child: Row(
                children: [
                  SizedBox(width: 4),
                  // Botão Check In
                  if (aparecerCheckIn)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                transitionDuration:
                                    Duration.zero, // sem duração
                                reverseTransitionDuration:
                                    Duration.zero, // sem duração ao voltar
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        CheckinPage(),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      return child; // retorna direto, sem animação
                                    },
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.login,
                                    size: 30,
                                    color: colorScheme.onPrimary,
                                  ),
                                  SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Check In',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // if (aparecerCheckOut) SizedBox(width: 8),

                  // Botão Check Out
                  if (aparecerCheckOut)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                transitionDuration:
                                    Duration.zero, // sem duração
                                reverseTransitionDuration:
                                    Duration.zero, // sem duração ao voltar
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        CheckoutPage(),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      return child; // retorna direto, sem animação
                                    },
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: colorScheme.secondary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.logout,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Check Out',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // if (aparecerNote) SizedBox(width: 8),
                  if (aparecerNote)
                    // Botão Notes
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                transitionDuration:
                                    Duration.zero, // sem duração
                                reverseTransitionDuration:
                                    Duration.zero, // sem duração ao voltar
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        NotesPage(),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      return child; // retorna direto, sem animação
                                    },
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: colorScheme.shadow,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    // Icons.table_restaurant,
                                    Icons.note_add_sharp,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Notes',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        // fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // if (aparecerRecepcao) SizedBox(width: 8),
                  if (aparecerRecepcao)
                    // Botão Recepção
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                transitionDuration:
                                    Duration.zero, // sem duração
                                reverseTransitionDuration:
                                    Duration.zero, // sem duração ao voltar
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        RecepcaoPage(),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      return child; // retorna direto, sem animação
                                    },
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    // Icons.table_restaurant,
                                    Icons.person,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Recepçao',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        // fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // if (aparecerCheckInOut || !naoAparecerMapa)
                  //   SizedBox(width: 8),
                  if (!naoAparecerMapa)
                    // Botão Mapa de Mesas
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                transitionDuration:
                                    Duration.zero, // sem duração
                                reverseTransitionDuration:
                                    Duration.zero, // sem duração ao voltar
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        MapaPage(),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      return child; // retorna direto, sem animação
                                    },
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: colorScheme.scrim,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    // Icons.table_restaurant,
                                    Icons.map,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Mapa',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // if (aparecerGarcom) SizedBox(width: 8),
                  if (aparecerGarcom)
                    // Botão Garçom
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          onTap: () {
                            Get.toNamed('/garcom');
                          },
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: colorScheme.secondary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.table_restaurant,
                                    // Icons.person,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Garçom',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        // fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(width: 4),
                ],
              ),
            ),
    );
  }
}

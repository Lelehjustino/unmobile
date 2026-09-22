import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:un_recepcao/controllers/views/footer_buttons_controller.dart';
import 'package:un_recepcao/controllers/views/funcoes_controller.dart';
import 'package:un_recepcao/controllers/views/garcom_controller.dart';
import 'package:un_recepcao/controllers/views/mapa_controller.dart';
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
  final MapaController mapaController = Get.put(MapaController());
  final painelController = Get.put(PainelController());
  final footerButtonsController = Get.find<FooterButtonsController>();

  final TextEditingController comandaController = TextEditingController();
  final GarcomController garcomController = Get.find<GarcomController>();
  final FuncoesController funcoesController = Get.find<FuncoesController>();
  // final FocusNode _focusNode = FocusNode();

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
/*   List<dynamic> todasMesas = [];
  List<dynamic> abertasMesas = [];
  List<dynamic> fechadasMesas = []; */
  List<dynamic> comandasVinculadas = [];
  List<dynamic> comandasVinculadasMesa = [];

/*   List<dynamic> todasComandas = [];
  List<dynamic> abertasComandas = [];
  List<dynamic> fechadasComandas = []; */

  bool aberto = false;
  bool conta = false;
  bool servidorConectado = true;

  // Para fazer requisições em determinado tempo (1/3)
  Timer? _timerMesas;

  String nomeCliente = '';
  bool isLoadingRefresh = false;

  // final variaveis = Get.find<VariaveisController>();

  String tipoDoPedido = "";

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

  // Mesa selecionada no modo ComandaNaMesa
  String? mesaSelecionada;
  int? indexMesa;

  bool modoCarrossel = false;

  bool vendaBalcaoClicado = false;
  bool vendaComandaClicado = false;
  bool vendaComandaNaMesaClicado = false;
  bool vendaMesaClicado = false;

  @override
  void initState() {
    super.initState();

    arrumarFoco();

    painelController.estaNoPainelCozinha.value = false;

    _atualizarHora();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _atualizarHora());
    _loadNomeEmpresa();
    _loadNumeroLicenca();
    carregar();
  }

  void carregar() async {
    await mapaController.carregarTudo();
    clicarAutomaticamente();
  }

  void clicarAutomaticamente(){
    if(mapaController.vendaBalcao.value){
      vendaBalcao();
    } else if (mapaController.vendaComanda.value){
      vendaComanda();
    } else if (mapaController.vendaComandaNaMesa.value){
      vendaComandaNaMesa();
    } else if (mapaController.vendaMesa.value){
      vendaMesa();
    } else {
      vendaComanda();
    }
  }

  void vendaComanda(){
    setState(() {
      vendaComandaClicado = true;
      vendaComandaNaMesaClicado = false;
      vendaMesaClicado = false;
      vendaBalcaoClicado = false;
      mostrarMesas = false;
    });
  }

  void vendaComandaNaMesa(){
    _selecionarNenhumGrupo();
    setState(() {
      modoCarrossel = true;
      vendaComandaClicado = false;
      vendaComandaNaMesaClicado = true;
      vendaMesaClicado = false;
      vendaBalcaoClicado = false;
      mostrarMesas = false;
    });

    /* if(modoCarrossel){
      setState(() {
        modoCarrossel = false;
      });
    }else{
      _selecionarNenhumGrupo();
      setState(() {
        modoCarrossel = true;
      });
    } */
  }

  void vendaBalcao(){
    setState(() {
      vendaBalcaoClicado = true;
      vendaComandaClicado = false;
      vendaComandaNaMesaClicado = false;
      vendaMesaClicado = false;
      mostrarMesas = false;
    });
  }

  void vendaMesa(){
    setState(() {
      vendaComandaClicado = false;
      vendaComandaNaMesaClicado = false;
      vendaMesaClicado = true;
      vendaBalcaoClicado = false;
      mostrarMesas = true;
    });
  }

  void arrumarFoco() {
    // if(Platform.isIOS){
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.unfocus();
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        }
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _searchFocusNode.unfocus();
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        }
      });
    /* } else {
      Future.delayed(Duration(milliseconds: 300), () {
        if (_searchFocusNode.canRequestFocus) {
          _searchFocusNode.requestFocus();
        }
      });
    } */
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

  /* // Função carregar TODAS as comandas
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
  } */

  /* // Função carregar TODAS as mesas
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
  } */

  // Função carregar as comandas ABERTAS
  /* Future<void> carregarAsComandasAbertas() async {
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
  } */

  // Função carregar as mesas ABERTAS
  /* Future<void> carregarAsMesasAbertas() async {
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
  } */

  // Função carregar as comandas FECHADAS
  /* Future<void> carregarAsComandasFechadas() async {
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
  } */

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

  @override
  void dispose() {
    _timer.cancel();
    //_focusNode.dispose();
    _searchFocusNode.dispose();
    comandaController.dispose();
    barraBusca.dispose();
    // Para fazer requisições em determinado tempo (3/3)
    _timerMesas?.cancel();
    super.dispose();
  }

  /* // Carregar selects
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
  } */

  Future<void> _selecionarPrimeiroGrupo(List<dynamic> mesas) async {
    if(vendaComandaClicado && mapaController.vendaComandaNaMesa.value){
      final primeiro = mesas.first;
      indexMesa = 0;
      setState(() {
        mesaSelecionada = primeiro['numero'].toString();
        indexMesa = indexMesa;
      });
    }
  }

  Future<void> _selecionarNenhumGrupo() async {
    if(vendaComandaClicado && mapaController.vendaComandaNaMesa.value){
      indexMesa = 0;
      setState(() {
        mesaSelecionada = null;
        indexMesa = indexMesa;
      });
    }
  }

  Future<void> _selecionarMesa(List<dynamic> mesas, int index) async {
    setState(() {
      modoCarrossel = true;
    });
    if(vendaComandaClicado && mapaController.vendaComandaNaMesa.value){
      final mesa = mesas[index];
      setState(() {
        mesaSelecionada = mesa['numero'].toString();
        indexMesa = index;
      });
    }
  }

  // carrossel de comandas na mesa - modo touch com dois painéis
  Widget _buildGridComandaNaMesa(List<dynamic> itemsMesa, List<dynamic> itemsComanda) {
    // Filtra as comandas pela mesa selecionada
    final List<dynamic> comandasDaMesa = mesaSelecionada == null ? [] : itemsComanda.where((c) => c['numeromesa'].toString() == mesaSelecionada).toList();
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mesas
            Expanded(
              flex: 1,
              child: Container(
                margin: EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Grid de mesas
                    Expanded(
                      child: itemsMesa.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Nenhuma mesa',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.surfaceDim,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                const double itemMinWidth = 100.0;
                                final int cols = (constraints.maxWidth / itemMinWidth).floor().clamp(1, 4);
                                return GridView.builder(
                                  padding: EdgeInsets.all(8),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cols,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 0.85,
                                  ),
                                  itemCount: itemsMesa.length,
                                  itemBuilder: (context, index) {
                                    final mesa = itemsMesa[index];
                                    final numeroMesa = mesa['numero'].toString();
                                    final selecionada = mesaSelecionada == numeroMesa;
                                    final aberta = mesa['comandavinculada'].toString() != '0' || mesa['numeropedido_FK'].toString() != '0';
                                    final status = int.tryParse(mesa['statuspedido'] ?? '0') ?? 0;
                                    final temConta = mesa['numeropedido_FK'].toString() != '0' && status == 2;
                                    final List<dynamic> comandasDaMesaItem = itemsComanda.where((c) => c['numeromesa'].toString() == numeroMesa).toList();

                                    // Cor base da mesa (mesmo padrão do _buildGridMesas)
                                    Color corBase;
                                    if (temConta) {
                                      corBase = Theme.of(context).colorScheme.error;
                                    } else if (!aberta) {
                                      corBase = Theme.of(context).colorScheme.surfaceDim;
                                    } else {
                                      corBase = Theme.of(context).colorScheme.tertiary;
                                    }
        
                                    // Borda de destaque quando selecionada
                                    return GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        if(mesaSelecionada == numeroMesa){
                                          setState(() {
                                            mesaSelecionada = null;
                                            indexMesa = null;
                                          });
                                        }else{
                                          setState(() {
                                            mesaSelecionada = numeroMesa;
                                            indexMesa = index;
                                          });
                                        }
                                      },
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 200),
                                        curve: Curves.easeOut,
                                        decoration: BoxDecoration(
                                          color: selecionada
                                              ? Theme.of(context).colorScheme.scrim
                                              : corBase,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: EdgeInsets.all(4),
                                        child: LayoutBuilder(
                                          builder: (ctx, cons) {
                                            final double iconSize = cons.maxWidth * 0.28;
                                            final Color textColor = aberta
                                                ? Theme.of(context).colorScheme.onPrimary
                                                : Theme.of(context).colorScheme.onTertiary;
                                            return Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.table_restaurant,
                                                  size: iconSize,
                                                  color: textColor,
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  numeroMesa,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: cons.maxWidth * 0.25,
                                                    color: textColor,
                                                  ),
                                                ),
                                                Text(
                                                  "Qtd: ${comandasDaMesaItem.length}",
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: cons.maxWidth * 0.18,
                                                    color: textColor,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
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
        
            // PAINEL DIREITO
            Expanded(
              flex: 3,
              child: Container(
                margin: EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Conteúdo
                    Expanded(
                      child: mesaSelecionada == null
                          // NAO TEM MESA SELECIONADA
                          // mostrar todas as comandas abertas
                          ? LayoutBuilder(
                              builder: (context, constraints) {
                                const double itemMinWidth = 110.0;
                                final int cols = (constraints.maxWidth / itemMinWidth)
                                    .floor()
                                    .clamp(2, 8);
                                return GridView.builder(
                                  padding: const EdgeInsets.all(8),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cols,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 0.8,
                                  ),
                                  itemCount: mapaController.abertasComandas.length,
                                  itemBuilder: (context, index) {
                                    final item = mapaController.abertasComandas[index];
                                    final numeroComanda = item['numero'].toString();
                                    final status = int.tryParse(item['statuspedido'] ?? '0') ?? 0;
                                    final aberto = item['numeropedido_FK'].toString() != '0';
                                    final temConta = aberto && status == 2;
                                    final nomeCliente = item['nomecliente']?.toString() ?? '';
                                    final valorContaRaw = item['valorliquidopedido'];
                                    final valorConta = (valorContaRaw != null && valorContaRaw.toString() != 'null' && valorContaRaw.toString() != '0' && valorContaRaw.toString() != '0.00') ? valorContaRaw.toString() : null;
                                    var mesa = item['numeromesa'].toString();
                                    Color corComanda;
                                    if (temConta) {
                                      corComanda = Theme.of(context).colorScheme.error;
                                    } else if (!aberto) {
                                      corComanda = Theme.of(context).colorScheme.surfaceDim;
                                    } else {
                                      corComanda = Theme.of(context).colorScheme.primaryContainer;
                                    }
    
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () async {
                                        if (vendaComandaClicado && mapaController.vendaComandaNaMesa.value) {
                                          await validarComanda(numeroComanda);
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: corComanda,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: LayoutBuilder(
                                          builder: (ctx, cons) {
                                            final Color textColor = aberto
                                                ? Theme.of(context).colorScheme.onPrimary
                                                : Theme.of(context).colorScheme.onTertiary;
                                            return Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.description,
                                                  size: cons.maxWidth * 0.3,
                                                  color: textColor,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  numeroComanda,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: cons.maxWidth * 0.18,
                                                    color: textColor,
                                                  ),
                                                ),
                                                Text(
                                                  aberto
                                                      ? (temConta ? 'Em conta' : 'Aberta')
                                                      : 'Fechada',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: cons.maxWidth * 0.11,
                                                    color: textColor,
                                                  ),
                                                ),
                                                if(mesa != "0" && mesa != "null")
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "Mesa: $mesa",
                                                      maxLines: 1, // limita a 1 linha
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        // fontWeight: FontWeight.bold,
                                                        fontSize: cons.maxWidth * 0.11,
                                                        color: aberto ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onTertiary,
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.table_bar,
                                                      size:cons.maxWidth * 0.12,
                                                      color: aberto ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onTertiary,
                                                    ),
                                                  ],
                                                ),
                                                if (valorConta != null)
                                                  Text(
                                                    'R\$ $valorConta',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: cons.maxWidth * 0.1,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                if (nomeCliente.isNotEmpty)
                                                  Text(
                                                    nomeCliente,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: cons.maxWidth * 0.1,
                                                      color: textColor,
                                                    ),
                                                  ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            )
                          : comandasDaMesa.isEmpty
                              // Mesa selecionada sem comandas
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Nenhuma comanda nesta mesa',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.surfaceDim,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              // Grid de comandas filtradas
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    const double itemMinWidth = 110.0;
                                    final int cols = (constraints.maxWidth / itemMinWidth).floor().clamp(2, 8);
                                    return GridView.builder(
                                      padding: const EdgeInsets.all(8),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: cols,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                        childAspectRatio: 0.8,
                                      ),
                                      itemCount: comandasDaMesa.length,
                                      itemBuilder: (context, index) {
                                        final item = comandasDaMesa[index];
                                        final numeroComanda = item['numero'].toString();
                                        final status = int.tryParse(item['statuspedido'] ?? '0') ?? 0;
                                        final aberto = item['numeropedido_FK'].toString() != '0';
                                        final temConta = aberto && status == 2;
                                        final nomeCliente = item['nomecliente']?.toString() ?? '';
                                        final valorContaRaw = item['valorliquidopedido'];
                                        final valorConta = (valorContaRaw != null &&
                                                valorContaRaw.toString() != 'null' &&
                                                valorContaRaw.toString() != '0' &&
                                                valorContaRaw.toString() != '0.00')
                                            ? valorContaRaw.toString()
                                            : null;
                                        var mesa = item['numeromesa'].toString();
        
                                        Color corComanda;
                                        if (temConta) {
                                          corComanda = Theme.of(context).colorScheme.error;
                                        } else if (!aberto) {
                                          corComanda = Theme.of(context).colorScheme.surfaceDim;
                                        } else {
                                          corComanda = Theme.of(context).colorScheme.primaryContainer;
                                        }
        
                                        return InkWell(
                                          borderRadius: BorderRadius.circular(10),
                                          onTap: () async {
                                            if (vendaComandaClicado && mapaController.vendaComandaNaMesa.value) {
                                              await validarComanda(numeroComanda);
                                            }
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: corComanda,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            child: LayoutBuilder(
                                              builder: (ctx, cons) {
                                                final Color textColor = aberto
                                                    ? Theme.of(context).colorScheme.onPrimary
                                                    : Theme.of(context).colorScheme.onTertiary;
                                                return Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.description,
                                                      size: cons.maxWidth * 0.3,
                                                      color: textColor,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      numeroComanda,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: cons.maxWidth * 0.18,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                    Text(
                                                      aberto
                                                          ? (temConta ? 'Em conta' : 'Aberta')
                                                          : 'Fechada',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: cons.maxWidth * 0.11,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          "Mesa: $mesa",
                                                          maxLines: 1, // limita a 1 linha
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            // fontWeight: FontWeight.bold,
                                                            fontSize: cons.maxWidth * 0.11,
                                                            color: aberto ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onTertiary,
                                                          ),
                                                        ),
                                                        Icon(
                                                          Icons.table_bar,
                                                          size:cons.maxWidth * 0.12,
                                                          color: aberto ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onTertiary,
                                                        ),
                                                      ],
                                                    ),
                                                    if (valorConta != null)
                                                      Text(
                                                        'R\$ $valorConta',
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontSize: cons.maxWidth * 0.1,
                                                          color: textColor,
                                                        ),
                                                      ),
                                                    if (nomeCliente.isNotEmpty)
                                                      Text(
                                                        nomeCliente,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontSize: cons.maxWidth * 0.1,
                                                          color: textColor,
                                                        ),
                                                      ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              if(mesaSelecionada != null)
                              SizedBox(
                                width: double.infinity,
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await Get.toNamed(
                                        '/visualizar_comandas_mesa',
                                        preventDuplicates: false,
                                        arguments: {
                                          'mesa': mesaSelecionada,
                                          'indexMesa': indexMesa,
                                          'listaComandas': comandasDaMesa,
                                        },
                                      )?.then((_) {
                                        if (mounted) {
                                          setState(() {
                                            modoCarrossel = true;
                                          });
                                          _selecionarMesa(mapaController.abertasMesas.toList(), indexMesa!);
                                        }
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.55),
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      'Visualizar',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridBalcao(List<dynamic> items) {
    return Expanded(
      child: GridView.builder(
        padding: EdgeInsets.all(8),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 165,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, index) {
          final item = items[index];

          final numeroDelivery = item['numerodelivery']?.toString() ?? '0';
          final statusPedido =int.tryParse(item['statuspedido']?.toString() ?? '0') ?? 0;

          final statusEntrega =int.tryParse(item['statusentrega']?.toString() ?? '0') ?? 0;

          final nomeCliente =item['nomecliente']?.toString() ?? '';

          final atendimento = item['atendimento']?.toString() ?? '';

          final integrador = item['integrador']?.toString() ?? '';

          final dataHoraAbertura =item['datahoraabertura']?.toString() ?? '';

          final valorContaRaw = item['valorliquidopedido'];

          final valorConta = (valorContaRaw != null && valorContaRaw.toString() != 'null' &&  valorContaRaw.toString() != '0' && valorContaRaw.toString() != '0.00')
            ? valorContaRaw.toString()
            : null;

          // Pedido aberto
          final aberto = statusPedido == 1;

          // Pedido pronto
          final pronto = statusPedido == 2;

          // Cor base
          Color corDelivery = Theme.of(context).colorScheme.tertiary;
          Color corTexto = Theme.of(context).colorScheme.onPrimary;

          corDelivery = integrador.contains("PEDEAQUI") 
              ? const Color.fromARGB(255, 177, 167, 179)
              : integrador.contains("IFOOD")
              ? const Color.fromARGB(255, 240, 147, 140)
              : Theme.of(context).colorScheme.tertiary;

          corDelivery = integrador.contains("PEDEAQUI")
              ? const Color.fromARGB(255, 73, 21, 82)
              : integrador.contains("IFOOD") || integrador.contains("P10") || integrador.contains("P 10")
              ? const Color.fromARGB(255, 154, 33, 24)
              : integrador.contains("NEEMO")
              ? Theme.of(context).colorScheme.scrim
              : integrador.contains("99FOOD")
              ? const Color.fromARGB(255, 236, 162, 2)
              : integrador.contains("ANOTA AI")
              ? const Color.fromARGB(255, 27, 88, 220)
              : Theme.of(context).colorScheme.tertiary;
          
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

          // informacoes pagamento 
          final numeroPedidoBalcao = item['numeropedido_FK'].toString();

          return InkWell(
            onTap: () {
              // Coloque aqui a navegação do delivery
              // Exemplo:
              //
              // Get.to(
              //   () => GarcomPage(),
              //   arguments: {
              //     'numerodelivery': numeroDelivery,
              //     'page': 'delivery',
              //   },
              // );
              Get.to(
                () => ContaPage(),
                arguments: {
                  'numeropedido': numeroPedidoBalcao,
                  'comanda': '0',
                  'mesa': '0',
                  'page': "mapa",
                  'nome': nomeCliente
                },
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: corDelivery,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double iconSize = constraints.maxWidth * 0.20;

                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/retirada_balcao_icone.png',
                              width: MediaQuery.of(context).size.width * 0.080,
                              height: MediaQuery.of(context).size.width * 0.080,
                              color: corTexto,
                            ),
                            /* Icon(
                              Icons.delivery_dining,
                              size: iconSize,
                              color: corTexto,
                            ), */

                            SizedBox(height: 4),

                            Text(
                              '#$numeroDelivery',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                // fontWeight: FontWeight.bold,
                                fontSize: constraints.maxWidth * 0.20,
                                color: corTexto,
                              ),
                            ),

                            if (nomeCliente.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  nomeCliente,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    // fontWeight: FontWeight.bold,
                                    fontSize: constraints.maxWidth * 0.09,
                                    color: corTexto,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 4),

                  Column(
                    children: [
                      /* Text(
                        pronto
                            ? 'Pronto'
                            : aberto
                                ? 'Em preparo'
                                : 'Aberto',
                        style: TextStyle(
                          // fontWeight: FontWeight.bold,
                          color: corTexto,
                        ),
                      ), */
                      if(nomeIntegrador != "")
                      Text(
                        nomeIntegrador,
                        style: TextStyle(
                          // fontWeight: FontWeight.bold,
                          color: corTexto,
                        ),
                      ),

                      if (atendimento.isNotEmpty && atendimento != '0')
                      Text(
                        atendimento,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: corTexto,
                        ),
                      ),

                      if (valorConta != null)
                        Text(
                          'R\$ $valorConta',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            // fontWeight: FontWeight.bold,
                            color: corTexto,
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
    );
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
              if ((vendaMesaClicado && mapaController.vendaMesa.value)) {
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

            if ((vendaComandaClicado && mapaController.vendaComanda.value)) {
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
            } else if (vendaComandaClicado && mapaController.vendaComandaNaMesa.value) {
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

        if ((vendaComandaClicado && mapaController.vendaComanda.value)) {
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
        } else if (vendaComandaClicado && mapaController.vendaComandaNaMesa.value) {
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
              if ((vendaComandaClicado && mapaController.vendaComanda.value) || vendaComandaClicado && mapaController.vendaComandaNaMesa.value) {
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
                                                  fontSize:constraints.maxWidth * 0.12,
                                                  color: aberto ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onTertiary,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Icon(
                                                Icons.table_bar,
                                                size:constraints.maxWidth * 0.12,
                                                color: aberto ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onTertiary,
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

    List<dynamic> itensParaMostrar = [];

    List<dynamic> itensParaMostrarMesa = [];
    List<dynamic> itensParaMostrarComanda = [];

    if((vendaComandaClicado && mapaController.vendaComanda.value) || (vendaMesaClicado && mapaController.vendaMesa.value)){
      // 1. Determina qual lista de DADOS usar (mesas ou comandas)
      if (mostrarMesas) {
        // 2. Filtra a lista com base no botão selecionado (Todas, Abertas, Fechadas)
        if (mostrarTodas) {
          itensParaMostrar = mapaController.todasMesas.toList();
        } else if (mostrarAbertas) {
          itensParaMostrar = mapaController.abertasMesas.toList();
        } else {
          // mostrarFechadas
          itensParaMostrar = mapaController.fechadasMesas.toList();
        }
      } else {
        // Lógica para Comandas (quando implementado)
        if (mostrarTodas) {
          itensParaMostrar = mapaController.todasComandas.toList();
        } else if (mostrarAbertas) {
          itensParaMostrar = mapaController.abertasComandas.toList();
        } else {
          itensParaMostrar = mapaController.fechadasComandas.toList();
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
        return item['statuspedido'] == '1' || item['statuspedido'] == '2';
      }).toList();
    }

    if(vendaComandaClicado && mapaController.vendaComandaNaMesa.value){
      if (mostrarMesas) {
        // 2. Filtra a lista com base no botão selecionado (Todas, Abertas, Fechadas)
        if (mostrarTodas) {
          itensParaMostrar = mapaController.todasMesas.toList();
        } else if (mostrarAbertas) {
          itensParaMostrar = mapaController.abertasMesas.toList();
        } else {
          // mostrarFechadas
          itensParaMostrar = mapaController.fechadasMesas.toList();
        }
      } else {
        // Lógica para Comandas (quando implementado)
        if (mostrarTodas) {
          itensParaMostrar = mapaController.todasComandas.toList();
        } else if (mostrarAbertas) {
          itensParaMostrar = mapaController.abertasComandas.toList();
        } else {
          itensParaMostrar = mapaController.fechadasComandas.toList();
        }
      }
      // Lógica para Comandas (quando implementado)
      if (mostrarTodas) {
        itensParaMostrarComanda = mapaController.todasComandas.toList();
        itensParaMostrarMesa = mapaController.todasMesas.toList();
      } else if (mostrarAbertas) {
        itensParaMostrarComanda = mapaController.abertasComandas.toList();
        itensParaMostrarMesa = mapaController.abertasMesas.toList();
      } else {
        itensParaMostrarComanda = mapaController.fechadasComandas.toList();
        itensParaMostrarMesa = mapaController.fechadasMesas.toList();
      }

      // Busca na barra de pesquisa
      if (comandaController.text.isNotEmpty) {
        itensParaMostrarComanda = itensParaMostrarComanda.where((item) {
          return item['numero'].toString().contains(comandaController.text);
        }).toList();
        itensParaMostrarMesa = itensParaMostrarMesa.where((item) {
          return item['numero'].toString().contains(comandaController.text);
        }).toList();
      }

      // Cria a lista de status (aberto/fechado) correspondente aos itens filtrados
      List<bool> statusDosItens = itensParaMostrarComanda.map<bool>((item) {
        return item['statuspedido'] == '1' || item['statuspedido'] == '2';
      }).toList();
    }

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
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 8),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      // f(vendaComandaClicado || vendaMesaClicado)
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
                                      return Expanded(
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () {
                                            node.unfocus();
                                          },
                                          child: Container(
                                            height: 44,
                                            alignment: Alignment.center,
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 16,
                                              ),
                                              child: Align(
                                                alignment: Alignment.centerRight,
                                                child: Text(
                                                  'OK',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
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
                              autofocus: false,
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
                        /* Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AbsorbPointer(
                              // quando absorve o toque,  os filhos não são mais clicaveis
                              absorbing: isLoadingRefresh, // true = bloqueia cliques
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
                                      mapaController.carregarTudo();
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
                            Text(
                              'Atualizar', 
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.shadow,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ), */
                        if(!modoCarrossel)
                        SizedBox(width: 3),
                        // Botao tres funções - abertas - fechadas - todas
                        if(vendaComandaClicado || vendaMesaClicado)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                // reveza os botoes 
                                if (mostrarAbertas) {
                                  setState(() {
                                    mostrarAbertas = false;
                                    mostrarFechadas = true;
                                    mostrarTodas = false;
                                  });
                                } else if (mostrarFechadas) {
                                  setState(() {
                                    mostrarAbertas = false;
                                    mostrarFechadas = false;
                                    mostrarTodas = true;
                                  });
                                } else {
                                  setState(() {
                                    mostrarAbertas = true;
                                    mostrarFechadas = false;
                                    mostrarTodas = false;
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                shape: CircleBorder(),
                                padding: EdgeInsets.all(20), // tamanho do círculo
                                backgroundColor: colorScheme.scrim,
                                elevation: 8, // Define a altura da sombra (quanto maior, mais "profunda" será a sombra)
                                shadowColor: Colors.black, // Cor da sombra com opacidade (ajuste conforme necessário)
                              ),
                              child: Icon(
                                mostrarAbertas ? Icons.lock_open : mostrarFechadas ? Icons.lock : Icons.list,
                                size: 30,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                            Text(
                              mostrarAbertas ? 'Abertas' : mostrarFechadas ? 'Fechadas' : 'Todas',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.scrim,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ),
                        /* SizedBox(width: 3),
                        if(mapaController.vendaComandaNaMesa.value)
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                if(modoCarrossel){
                                  setState(() {
                                    modoCarrossel = false;
                                  });
                                }else{
                                  _selecionarNenhumGrupo();
                                  setState(() {
                                    modoCarrossel = true;
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                shape: CircleBorder(),
                                padding: EdgeInsets.all(20), // tamanho do círculo
                                backgroundColor: colorScheme.primary,
                                elevation: 8, // Define a altura da sombra (quanto maior, mais "profunda" será a sombra)
                                shadowColor: Colors.black, // Cor da sombra com opacidade (ajuste conforme necessário)
                              ),
                              child: Icon(
                                modoCarrossel ? Icons.grid_view :  Icons.list,
                                size: 25,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                            Text(
                              modoCarrossel ? 'Lista' : 'Grade',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ), */
                        SizedBox(width: 3),
                        if(mapaController.vendaComandaNaMesa.value)
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                vendaComandaNaMesa();
                              },
                              style: ElevatedButton.styleFrom(
                                shape: CircleBorder(),
                                padding: EdgeInsets.all(20), // tamanho do círculo
                                backgroundColor: !vendaComandaNaMesaClicado ? colorScheme.surfaceDim : colorScheme.primary,
                                elevation: 8, // Define a altura da sombra (quanto maior, mais "profunda" será a sombra)
                                shadowColor: Colors.black, // Cor da sombra com opacidade (ajuste conforme necessário)
                              ),
                              child: Icon(
                                Icons.grid_view,
                                // modoCarrossel ? Icons.grid_view :  Icons.list,
                                size: 25,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                            Text(
                              'Touch',
                              style: TextStyle(
                                fontSize: 10,
                                color: !vendaComandaNaMesaClicado ? colorScheme.surfaceDim : colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ),
                        SizedBox(width: 3),
                        // botão mesa
                        if (mapaController.vendaMesa.value)
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  // mapaController.carregarTudo();
                                  vendaMesa();
                                  setState(() {
                                    vendaComandaClicado = false;
                                    vendaComandaNaMesaClicado = false;
                                    vendaMesaClicado = true;
                                    vendaBalcaoClicado = false;
                                    mostrarMesas = true;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(20), // tamanho do círculo
                                  backgroundColor: mostrarMesas ? colorScheme.tertiary : colorScheme.surfaceDim,
                                  elevation: 8, // Define a altura da sombra (quanto maior, mais "profunda" será a sombra)
                                  shadowColor: Colors.black, // Cor da sombra com opacidade (ajuste conforme necessário)
                                ),
                                child: Icon(
                                  Icons.table_restaurant,
                                  size: 30,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                              Text(
                              'Mesa',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: mostrarMesas ? colorScheme.tertiary : colorScheme.surfaceDim,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          ),

                        SizedBox(width: 3),
                        // botão comanda
                        if (mapaController.vendaComanda.value)
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  // mapaController.carregarTudo();
                                  vendaComanda();
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(20),
                                  iconColor: colorScheme.secondary,
                                  backgroundColor: !vendaComandaClicado ? colorScheme.surfaceDim : colorScheme.primaryContainer,
                                  elevation:8, // Define a altura da sombra (quanto maior, mais "profunda" será a sombra)
                                  shadowColor: Colors.black, // Cor da sombra com opacidade (ajuste conforme necessário)
                                ),
                                child: Icon(
                                  Icons.description,
                                  size: 30,
                                  color: colorScheme.onTertiary,
                                ),
                              ),
                              Text(
                                'Comanda',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: !vendaComandaClicado ? colorScheme.surfaceDim : colorScheme.primaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                          ),
                          SizedBox(width: 3),
                        // botão balcao
                        if (mapaController.vendaBalcao.value)
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  vendaBalcao();
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(20),
                                  iconColor: colorScheme.secondary,
                                  backgroundColor: !vendaBalcaoClicado ? colorScheme.surfaceDim : colorScheme.tertiary,
                                  elevation:8, // Define a altura da sombra (quanto maior, mais "profunda" será a sombra)
                                  shadowColor: Colors.black, // Cor da sombra com opacidade (ajuste conforme necessário)
                                ),
                                child: Image.asset(
                                  'assets/retirada_balcao_icone.png',
                                  width: MediaQuery.of(context).size.width * 0.070,
                                  height: MediaQuery.of(context).size.width * 0.070,
                                  color: colorScheme.onTertiary,
                                ),
                                /*  Icon(
                                  Icons.room_service,
                                  size: 30,
                                  color: colorScheme.onTertiary,
                                ), */
                              ),
                              Text(
                                'Balcão',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: !vendaBalcaoClicado ? colorScheme.surfaceDim : colorScheme.tertiary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // body
            // mapa mesa 
            if(mapaController.vendaMesa.value && vendaMesaClicado)
            _buildGridMesas(itensParaMostrar, true),

            // mapa comanda 
            if(mapaController.vendaComanda.value && vendaComandaClicado)
            _buildGridComandas(itensParaMostrar, false),

            // mapa comanda na mesa 
            if(mapaController.vendaComandaNaMesa.value && vendaComandaNaMesaClicado && modoCarrossel)
            _buildGridComandaNaMesa(mapaController.abertasMesas.toList(), mapaController.abertasComandas.toList()),

            // mapa balcao (corrigido duplicidade)
            if(mapaController.vendaBalcao.value && vendaBalcaoClicado)
            _buildGridBalcao(mapaController.balcao.toList())
            ],
          ),
        ],
      ),
      /* bottomNavigationBar:
          // Barra inferior com botões quadrados
          _showKeyboardNome
          ? Padding(
              padding: footerButtonsController.aparecerNote.value ? EdgeInsets.only(top: 5.0, bottom: 0.0, left: 10.0, right: 10.0) : EdgeInsets.only(top: 5.0, bottom: 0.0, left: 15.0, right: 15.0),
              child: Row(),
            )
          :
            // Barra inferior com botões quadrados
            Padding(
              padding: footerButtonsController.aparecerNote.value ? EdgeInsets.only(top: 5.0, bottom: 15.0) : EdgeInsets.only(top: 5.0, bottom: 15.0),
              child: Row(
                children: [
                  SizedBox(width: 4),
                  // Botão Check In
                  if (footerButtonsController.aparecerCheckIn.value)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                transitionDuration: Duration.zero, // sem duração
                                reverseTransitionDuration: Duration.zero, // sem duração ao voltar
                                pageBuilder: (context, animation, secondaryAnimation) => CheckinPage(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) => child, // retorna direto, sem animação
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
                  if (footerButtonsController.aparecerCheckOut.value)
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
                  if (footerButtonsController.aparecerNote.value)
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
                  if (footerButtonsController.aparecerRecepcao.value)
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
                  if (footerButtonsController.aparecerMapa.value)
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
                  if (footerButtonsController.aparecerGarcom.value)
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
                                      'Atendente',
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
            ), */
    );
  }
}

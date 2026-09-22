import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:pinput/pinput.dart';
import 'package:un_recepcao/controllers/carrinho_controller.dart';
import 'package:un_recepcao/controllers/navegacao_inteligente.dart';
import 'package:un_recepcao/controllers/views/footer_buttons_controller.dart';
import 'package:un_recepcao/controllers/views/funcoes_controller.dart';
import 'package:un_recepcao/controllers/views/garcom_controller.dart';
import 'package:un_recepcao/controllers/views/painel_controller.dart';
import 'package:un_recepcao/data/data_class.dart';
import 'package:un_recepcao/services/stone_service.dart';
import 'package:un_recepcao/views/checkin_page.dart';
import 'package:un_recepcao/views/checkout_page.dart';
import 'package:un_recepcao/views/expedicao_motoboy_page.dart';
import 'package:un_recepcao/views/garcom_page.dart';
import 'package:un_recepcao/views/inicial_page.dart';
import 'package:un_recepcao/views/mapa_page.dart';
import 'package:un_recepcao/views/notes_page.dart';
import 'package:un_recepcao/views/painel_cliente.dart';
import 'package:un_recepcao/views/painel_cozinha.dart';
import 'package:un_recepcao/views/recepcao_page.dart';
import 'package:un_recepcao/widgets/side_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => ConfiguracoesPageState();
}

class ConfiguracoesPageState extends State<ConfiguracoesPage>
    with WidgetsBindingObserver {
  String versaoAplicacao = Get.find<FuncoesController>().versaoDoApp;
  final FuncoesController funcoesController = Get.find<FuncoesController>();
  final StoneService stoneService = Get.find<StoneService>();

  final TextEditingController senhaController = TextEditingController();
  final FooterButtonsController footerButtonsController = Get.find<FooterButtonsController>();
  final FocusNode senhaFocusNode = FocusNode();
  String erro = "";
  bool isloadingSenha = true;
  bool erroBool = false;
  Timer? _timer;
  String _horaAtual = '';
  bool isProcessing = false;
  String? selectedModo;
  final TextEditingController servidorController = TextEditingController();
  final FocusNode servidorFocusNode = FocusNode();
  bool _isFocused = false;
  String nomeEmpresa = '';
  bool isloading = false;
  bool isLoadingSalvar = false;

  // Flags / Sets
  List<String> recepcao = ['Recepção'];
  Set<String> recepcaoSelecionados = {};

  List<String> modos = ['Mapa'];
  Set<String> modosSelecionados = {};

  List<String> vendas = ['Venda Balcão', 'Venda Comanda', 'Venda Comanda Na Mesa','Venda Mesa'];
  Set<String> vendasSelecionados = {};

  List<String> notes = ['Fila de espera'];
  Set<String> notesSelecionados = {};

  List<String> check = ['Check-in', 'Check-out'];
  Set<String> checkSelecionados = {};

  List<String> vendaComanda = ['Venda comanda'];
  Set<String> vendaComandaSelecionados = {'0'};

  List<String> vendaMesa = ['Venda mesa'];
  Set<String> vendaMesaSelecionados = {};

  // List<String> paineis = ['KDS', 'Pedidos', 'Expedição motoboy'];
  List<String> paineis = ['Expedição cliente', 'Expedição motoboy', 'KDS'];
  Set<String> paineisSelecionados = {};

  // List<String> rotas = ['Home', 'Painel cliente'];
  List<String> rotas = ['Home', 'Expedição cliente', 'Expedição motoboy'];
  Set<String> rotasSelecionadas = {'Home'};

  List<String> cupomAvulso = ['Cupom Avulso'];
  Set<String> cupomAvulsoSelecionados = {};

  List<String> modoCarrinhoComandas = ['Carrinho comandas'];
  Set<String> modoCarrinhoComandasSelecionados = {};

  List<String> cadastroCliente = ['Cadastro Cliente'];
  Set<String> cadastroClienteSelecionados = {};
  List<String> tipoCadastroCliente = ['CPF', 'Telefone'];
  Set<String> tipoCadastroClienteSelecionados = {};
  List<String> forcarCadastroCliente = ['Forçar cadastro'];
  Set<String> forcarCadastroClienteSelecionados = {};
  List<String> retirarBalcao = ['Venda balcão'];
  Set<String> retirarBalcaoSelecionados = {};

  bool servidorConectado = false;

  bool clicado = false;

  final ScrollController _scrollController = ScrollController();
  final CarrinhoController carrinhoController = Get.find<CarrinhoController>();

  bool aparecerCheckInOut = false;
  bool aparecerCheckIn = false;
  bool aparecerCheckOut = false;
  bool aparecerGarcom = false;
  bool aparecerNote = false;
  bool aparecerRecepcao = false;
  bool naoAparecerMapa = true;
  bool aparecerModoCarrinhoComandas = false;
  bool aparecerVendaComanda = false;
  bool aparecerVendaMesa = false;

  // Variaveis de Licença
  bool licencaSelecionada = false;

  bool nomeDaLicencaDoLoad = false;
  String nomeDaLicencaSelecionada = "";
  String numeroDaLicencaSelecionada = "";
  String mobileId = "";
  bool naoEstaCadastrado = false;
  bool existePVDcomMobile = false;
  bool naoAparecerSelecionarSilenca = false;
  bool aparecerConectar = false;

  String nomeDaLicenca = "";
  String nomeDaLicencaDisponivel = "";
  String numeroDaLicenca = "";
  String numeroDaLicencaDisponivel = "";
  List<dynamic> listaLicencaComId = [];
  List<dynamic> listaLicencaDisponivel = [];
  bool carregamento = true;

  String numeroDaLicencaComId = "";
  String nomeDaLicencaComId = "";

  // Variaveis de Garçom
  bool garcomSelecionadoFuncao = false;
  bool _popupGarcomAberto = false;
  bool _popupLicencaAberto = false;

  List<dynamic> listaGarcom = [];
  String nomeDoGarcom = "";
  String numeroDoGarcom = "";
  String nomeGarcom = "";
  bool nomeDoGarcomDoLoad = false;
  bool nomeDoGarcomSelecionado = false;

  // Variaveis de Servidor
  String servidor = "";
  String servidorAntigo = "";
  // Snapshot do servidor no momento em que a tela abriu — usado para comparação confiável no Salvar
  String _servidorNoLoad = "";
  String servidorAntigoFuncao = "";

  // Snapshot da rota no momento em que a tela abriu — usado para validação de login
  String _rotaNoLoad = "";

  int shakeKey = 0;

  final painelController = Get.find<PainelController>();
  final GarcomController garcomController = Get.find<GarcomController>();

  // Variaveis de Rota
  bool rotaHome = true;
  bool rotaPainelCliente = false;
  bool rotaExpedicaoMotoboy = false;

  String rotaAntiga = "";
  String rotaNova = "";

  // Variaveis de Painel
  bool aparecerExpedicaoCliente = false;
  bool aparecerKDS = false;
  bool aparecerExpedicaoMotoboy = false;

  bool isloadingProdutos = false;

  bool aparecerCupomAvulso = false;

  bool aparecerCadastroCliente = false;

  // Listener nomeado para poder ser removido corretamente no dispose
  void _onServidorFocusChange() {
    if (!mounted) return;
    setState(() {
      _isFocused = servidorFocusNode.hasFocus;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    painelController.estaNoPainelCozinha.value = false;

    // inicia timer seguro (não assume que será não-nulo)
    _atualizarHora();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) return;
      _atualizarHora();
    });

    // focus listener — usando referência nomeada para remoção segura no dispose
    servidorFocusNode.addListener(_onServidorFocusChange);

    _loadServidor();
    _loadModoSalvo();
    _loadNoteSalvo();
    _loadRecepcaoSalvo();
    _loadCheckSalvo();
    _loadVendaComanda();
    _loadVendaMesa();
    _loadServidorAntigo();
    _loadPainelSalvo();
    carregarRota();
    _loadCupomAvulsoSalvo();
    carregarCupomAvulso();

    _carregarModos();
    _carregarNote();
    _carregarRecepcao();
    _carregargarcom();
    carregarchecks();
    _loadNomeEmpresa();
    pegarServidorAntigo();
    pegarRotaAntiga();
    _loadCadastroClienteSalvo();
    _loadTipoCadastroClienteSalvo();
    _loadFocarCadastroClienteSalvo();
    _loadModoCarrinhoComandasSalvo();
    _loadRetirarBalcao();
    _loadVendas();

   // arrumarListaVendas();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Remove pela mesma referência adicionada no initState — sem vazamento de listener
    servidorFocusNode.removeListener(_onServidorFocusChange);
    servidorFocusNode.dispose();
    _timer?.cancel();
    servidorController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  arrumarListaVendas(){
    if(!funcoesController.vendaBalcao.value){
      // venda balcao 
      vendas.remove('Venda Balcão');
      vendasSelecionados.remove('0');
    }
    if (!funcoesController.vendaComanda.value){
      // venda comanda
      vendas.remove('Venda Comanda');
      vendasSelecionados.remove('1');
    }
    if (!garcomController.vendaComandaNaMesa.value){
      // venda comanda na mesa 
      vendas.remove('Venda Comanda Na Mesa');
      vendasSelecionados.remove('2');
    }
    if (!funcoesController.vendaMesa.value){
      // venda mesa 
      vendas.remove('Venda Mesa');
      vendasSelecionados.remove('3');
    } 
  }

  navegar() async {
    if (footerButtonsController.rotaPainelCliente.value) {
      Get.toNamed('/painel_cliente');
    } else if (footerButtonsController.rotaExpedicaoMotoboy.value) {
      Get.toNamed('/expedicao_motoboy');
    } else {
      if (footerButtonsController.aparecerCheckIn.value) {
        Get.toNamed('/checkin');
      } else if (footerButtonsController.aparecerGarcom.value) {
        // venda comanda marcada 
        if(footerButtonsController.vendaComanda.value){
          garcomController.retirarBalcaoRota.value = false;
          garcomController.vendaComanda.value = true;
          garcomController.vendaMesa.value = false;
        } 
        // venda mesa marcada 
        else if (footerButtonsController.vendaMesa.value) {
          garcomController.retirarBalcaoRota.value = false;
          garcomController.vendaComanda.value = false;
          garcomController.vendaMesa.value = true;
        } 
        // venda balcao marcada 
        else if (footerButtonsController.retirarBalcao.value) {
          garcomController.retirarBalcaoRota.value = false;
          garcomController.vendaComanda.value = true;
          garcomController.vendaMesa.value = false;
        }
        else {
          garcomController.retirarBalcaoRota.value = false;
          garcomController.vendaComanda.value = true;
          garcomController.vendaMesa.value = false;
        }
        Get.toNamed('/garcom');
      } else if (footerButtonsController.aparecerCheckOut.value) {
        Get.toNamed('/checkout');
      } else if (footerButtonsController.aparecerMapa.value) {
        Get.toNamed('/mapa');
      } else if (footerButtonsController.aparecerRecepcao.value) {
        Get.toNamed('/recepcao');
      } else if (footerButtonsController.aparecerNote.value) {
        Get.toNamed('/notes');
      } 
      // expedicao cliente
      else if(footerButtonsController.aparecerExpedicaoCliente.value){
        Get.toNamed('/painel_cliente');
      }
      // KDS
      else if(footerButtonsController.aparecerKDS.value){
        Get.toNamed('/painel_cozinha');
      }
      // expedicao motoboy
      else if(footerButtonsController.aparecerExpedicaoMotoboy.value){
        Get.toNamed('/expedicao_motoboy');
      } 
      else if(footerButtonsController.aparecerCupomAvulso.value){
        Get.toNamed('/cupom_avulso');
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selecione uma rota!',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Preenche o cupom avulso salvo
  Future<void> _loadCupomAvulsoSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getString('cupom_avulso');

    if (valor == null || valor.isEmpty) return;

    Set<String> setLocal;

    if (valor.startsWith('[')) {
      // Novo formato (JSON)
      setLocal = Set<String>.from(jsonDecode(valor));
    } else {
      // Formato antigo
      setLocal = {valor};
    }

    if (!mounted) return;

    setState(() {
      cupomAvulsoSelecionados = setLocal;
    });
  }

  // Carrega o cupom avulso - bool para rota
  Future<void> carregarCupomAvulso() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getString('cupom_avulso');

    if (valor == null || valor.isEmpty) {
      setState(() => aparecerCupomAvulso = false);
      return;
    }

    Set<String> setLocal;

    if (valor.startsWith('[')) {
      setLocal = Set<String>.from(jsonDecode(valor));
    } else {
      setLocal = {valor};
    }

    setState(() {
      aparecerCupomAvulso = setLocal.contains('Cupom Avulso');
    });
  }

  // Salva o cupom avulso
  _saveCupomAvulso(Set<String> cupomAvulsoSelecionados) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'cupom_avulso',
      jsonEncode(cupomAvulsoSelecionados.toList()),
    );
  }

  // Carrega o cadastro do cliente - bool para rota
  Future<void> _loadCadastroClienteSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getString('cadastro_cliente');

    if (valor == null || valor.isEmpty) return;

    Set<String> setLocal;

    if (valor.startsWith('[')) {
      setLocal = Set<String>.from(jsonDecode(valor));
    } else {
      setLocal = {valor};
    }

    if (!mounted) return;

    setState(() {
      cadastroClienteSelecionados = setLocal;
    });
  }

  // Carrega o modo carrinho de comandas - bool para rota
  Future<void> _loadModoCarrinhoComandasSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getString('modo_carrinho_comandas');

    if (valor == null || valor.isEmpty) return;

    Set<String> setLocal;

    if (valor.startsWith('[')) {
      setLocal = Set<String>.from(jsonDecode(valor));
    } else {
      setLocal = {valor};
    }

    if (!mounted) return;

    setState(() {
      modoCarrinhoComandasSelecionados = setLocal;
    });
  }

  // Carrega se retirar balcao esta marcado 
  Future<void> _loadVendas() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getString('vendas_selecionados');

    if (valor == null || valor.isEmpty) return;

    Set<String> setLocal;

    if (valor.startsWith('[')) {
      setLocal = Set<String>.from(jsonDecode(valor));
    } else {
      setLocal = {valor};
    }

    if (!mounted) return;

    setState(() {
      vendasSelecionados = setLocal;
    });
  }

  // salvar retirar balcao 
  _saveVendas(Set<String> vendasSelecionados) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'vendas_selecionados',
      jsonEncode(vendasSelecionados.toList()),
    );
  }

  // Carrega se retirar balcao esta marcado 
  Future<void> _loadRetirarBalcao() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getString('retirar_balcao');

    if (valor == null || valor.isEmpty) return;

    Set<String> setLocal;

    if (valor.startsWith('[')) {
      setLocal = Set<String>.from(jsonDecode(valor));
    } else {
      setLocal = {valor};
    }

    if (!mounted) return;

    setState(() {
      retirarBalcaoSelecionados = setLocal;
    });
  }

  // salvar retirar balcao 
  _saveRetirarBalcao(Set<String> retirarBalcaoSelecionados) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'retirar_balcao',
      jsonEncode(retirarBalcaoSelecionados.toList()),
    );
  }

  // Carrega se retirar balcao esta marcado 
  Future<void> _loadVendaMesa() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getString('venda_mesa');

    if (valor == null || valor.isEmpty) return;

    Set<String> setLocal;

    if (valor.startsWith('[')) {
      setLocal = Set<String>.from(jsonDecode(valor));
    } else {
      setLocal = {valor};
    }

    if (!mounted) return;

    setState(() {
      vendaMesaSelecionados = setLocal;
    });
  }

  // salvar retirar balcao 
  _saveVendaMesa(Set<String> vendaMesaSelecionados) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'venda_mesa',
      jsonEncode(vendaMesaSelecionados.toList()),
    );
  }

  // Carrega se retirar balcao esta marcado 
  Future<void> _loadVendaComanda() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getString('venda_comanda');

    if (valor == null || valor.isEmpty) return;

    Set<String> setLocal;

    if (valor.startsWith('[')) {
      setLocal = Set<String>.from(jsonDecode(valor));
    } else {
      setLocal = {valor};
    }

    if (!mounted) return;

    setState(() {
      vendaComandaSelecionados = setLocal;
    });
  }

  // salvar retirar balcao 
  _saveVendaComanda(Set<String> vendaMesaSelecionados) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'venda_comanda',
      jsonEncode(vendaMesaSelecionados.toList()),
    );
  }

  // Salva o modo carrinho de comandas
  _saveModoCarrinhoComandas(Set<String> modoCarrinhoComandasSelecionados) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'modo_carrinho_comandas',
      jsonEncode(modoCarrinhoComandasSelecionados.toList()),
    );
  }

  // Salva o cupom avulso
  _saveCadastroCliente(Set<String> cadastroClienteSelecionados) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'cadastro_cliente',
      jsonEncode(cadastroClienteSelecionados.toList()),
    );
  }

  // Carrega o tipo de cadastro do cliente - bool para rota
  Future<void> _loadTipoCadastroClienteSalvo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCheck = prefs.getString('tipo_cadastro_cliente');
      if (savedCheck != null) {
        final setLocal = Set<String>.from(jsonDecode(savedCheck));
        if (!mounted) return;
        setState(() {
          tipoCadastroClienteSelecionados = setLocal;
        });
      }
    } catch (e, st) {
      // debugPrint("Erro _loadCheckSalvo(): $e\n$st");
    }
  }

  // Salva o tipo de cadastro do cliente
  _saveTipoCadastroCliente(Set<String> tipoCadastroClienteSelecionados) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'tipo_cadastro_cliente',
      jsonEncode(tipoCadastroClienteSelecionados.toList()),
    );
  }

  // Carrega se deve forcar popup aparecer 
  Future<void> _loadFocarCadastroClienteSalvo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCheck = prefs.getString('forcar_cadastro_cliente');
      if (savedCheck != null) {
        final setLocal = Set<String>.from(jsonDecode(savedCheck));
        if (!mounted) return;
        setState(() {
          forcarCadastroClienteSelecionados = setLocal;
        });
      }
    } catch (e, st) {
      // debugPrint("Erro _loadCheckSalvo(): $e\n$st");
    }
  }

  // Salva o tipo de cadastro do cliente
  _saveForcarCadastroCliente(Set<String> forcarCadastroClienteSelecionados) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'forcar_cadastro_cliente',
      jsonEncode(forcarCadastroClienteSelecionados.toList()),
    );
  }

  void pegarServidorAntigo() async {
    await _loadServidorAntigo();
    servidorAntigoFuncao = servidorController.text;
  }

  void pegarRotaAntiga() async {
    await carregarRota();
    if (rotaHome) {
      rotaAntiga = "Home";
    } else if (rotaPainelCliente) {
      rotaAntiga = "Cliente";
    } else if (rotaExpedicaoMotoboy) {
      rotaAntiga = "Expedição motoboy";
    }

    // debugPrint("rotaAntiga: $rotaAntiga");
  }

  Future<void> salvarNomeEmpresa() async {
    String nomeEmpresaFunction = await carregarNomeEmpresa();
    await _saveNomeEmpresa(nomeEmpresaFunction);
    await _loadNomeEmpresa();
  }

  Future<void> _saveNomeEmpresa(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nomeEmpresa', value);
    } catch (e, st) {
      // debugPrint("Erro _saveNomeEmpresa(): $e\n$st");
    }
  }

  Future<String> carregarNomeEmpresa() async {
    try {
      final dadosJson = await Connection().select(
        "SELECT nomefantasia FROM empresa WHERE numero='1' LIMIT 1",
      );

      if (dadosJson == null || dadosJson.isEmpty) {
        nomeEmpresa = "Sem nome";
        return nomeEmpresa;
      }

      final lista = jsonDecode(dadosJson) as List<dynamic>;

      if (lista.isEmpty) {
        nomeEmpresa = "Sem conexão";
        return nomeEmpresa;
      }

      nomeEmpresa = lista[0]['nomefantasia'].toString();
      return nomeEmpresa;
    } catch (e, st) {
      // debugPrint("Erro ao carregar nome da empresa: $e\n$st");
      nomeEmpresa = "Erro de DB";
      return nomeEmpresa;
    }
  }

  // Função para forçar o mobileId
  Future<void> forcarMobileId() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT mobileid, nome, numero FROM tradepoints WHERE numero = '3';",
      );

      if (!mounted) return;
      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        String valor = lista[0]['mobileid'];
        String valor2 = lista[0]['nome'];
        String valor3 = lista[0]['numero'];

        setState(() {
          mobileId = valor;
          nomeDaLicenca = valor2;
          _saveNumeroLicenca(valor3);
          _saveLicenca(valor2);
        });
        // popupSelecionarGarcom();
      }
    } catch (e) {
      print("Erro ao carregar forcar mobileId: $e");
    }
  }

  // Função para verificar se o id do aparelho já esta com licença
  Future<void> vefificacaoLicencaComId() async {
    if ((servidorController.text == "192.192.192.192") ||
        (servidorController.text == "192192192192")) {
      await forcarMobileId();
      if (mounted) {
        setState(() {
          existePVDcomMobile = true;
          naoAparecerSelecionarSilenca = true;
          aparecerConectar = false;
          naoEstaCadastrado = false;
        });
      }
      return;
    }
    String mobileId = await pegarMobileId();
    if (!mounted) return;
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, nome FROM tradepoints WHERE mobileid='$mobileId' AND tipo='Mobile' AND ativo='1' ORDER BY numero;",
      );

      if (!mounted) return;
      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        String valor = lista[0]['numero'].toString();
        String valor2 = lista[0]['nome'];

        setState(() {
          numeroDaLicencaComId = valor;
          nomeDaLicencaComId = valor2;
          nomeDaLicenca = nomeDaLicencaComId;
          listaLicencaComId = lista;
          existePVDcomMobile = true;
          naoEstaCadastrado = false;
          _saveNumeroLicenca(valor);
          _saveLicenca(valor2);
        });
      } else {
        setState(() {
          numeroDaLicencaComId = "";
          nomeDaLicencaComId = "";
          listaLicencaComId = [];
          existePVDcomMobile = false;
          naoEstaCadastrado = true;
        });
        verificarLicencasDisponiveis();
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
      if (!mounted) return;
      setState(() {
        numeroDaLicencaComId = "0";
        nomeDaLicencaComId = "0";
        listaLicencaComId = [];
        existePVDcomMobile = false;
      });
      verificarLicencasDisponiveis();
    }
  }

  // Função para pegar o id do aparelho
  Future<String> pegarMobileId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      final id = iosInfo.identifierForVendor ?? 'unknown_ios';
      if (mounted) {
        setState(() {
          mobileId = id;
        });
      } else {
        mobileId = id;
      }
      return id;
    }

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      if (mounted) {
        setState(() {
          mobileId = androidInfo.id;
        });
      } else {
        mobileId = androidInfo.id;
      }
      return androidInfo.id; // ID do Android
    }

    if (Platform.isMacOS) {
      final macInfo = await deviceInfo.macOsInfo;
      final id = macInfo.systemGUID ?? 'unknown_macos';
      if (mounted) {
        setState(() {
          mobileId = id;
        });
      } else {
        mobileId = id;
      }
      return id;
    }

    if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      if (mounted) {
        setState(() {
          mobileId = windowsInfo.deviceId;
        });
      } else {
        mobileId = windowsInfo.deviceId;
      }
      return windowsInfo.deviceId;
    }

    return 'unknown_device';
  }

  // Função para verificar licenças disponíveis
  Future<void> verificarLicencasDisponiveis() async {
    await pegarMobileId();
    setState(() {
      carregamento = true;
    });
    if (!mounted) return;
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, nome FROM tradepoints WHERE mobileid = '' AND tipo='Mobile' AND ativo='1';",
      );

      if (!mounted) return;
      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        String valor = lista[0]['numero'].toString();
        String valor2 = lista[0]['nome'];

        setState(() {
          numeroDaLicencaDisponivel = valor; // agora é uma string "0" ou "1"
          nomeDaLicencaDisponivel = valor2;
          nomeDaLicenca = nomeDaLicencaDisponivel;
          listaLicencaDisponivel = lista;
        });
      } else {
        setState(() {
          numeroDaLicencaDisponivel = ""; // agora é uma string "0" ou "1"
          nomeDaLicencaDisponivel = "";
          listaLicencaDisponivel = [];
        });
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
      if (!mounted) return;
      setState(() {
        numeroDaLicencaDisponivel = "0";
        nomeDaLicencaDisponivel = "0";
        listaLicencaDisponivel = [];
      });
    }
  }

  Future<void> _saveNumeroLicenca(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('licencaNumero', value);
    } catch (e, st) {
      // debugPrint("Erro _saveLicenca(): $e\n$st");
    }
  }

  Future<void> _saveLicenca(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('licenca', value);
    } catch (e, st) {
      // debugPrint("Erro _saveLicenca(): $e\n$st");
    }
  }

  Future<void> funcoesLicenca() async {
    await vefificacaoLicencaComId();
    if (!existePVDcomMobile) {
      await verificarLicencasDisponiveis();
      popupSelecionarLicenca();
    } else {
      licencaSelecionada = true;
      nomeDaLicencaDoLoad = true;
      await funcoesGarcom();
    }
  }

  // Função que retorna informações garçom
  Future<void> informacoesGarcom() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, nome FROM usuarios WHERE ativo = '1' AND numero != '1' ORDER BY nome;",
      );

      if (!mounted) return;
      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        String valor = lista[0]['numero'].toString();
        String valor2 = lista[0]['nome'];

        setState(() {
          numeroDoGarcom = valor; // agora é uma string "0" ou "1"
          nomeDoGarcom = valor2;
          listaGarcom = lista;
        });
      } else {
        setState(() {
          numeroDoGarcom = ""; // agora é uma string "0" ou "1"
          nomeDoGarcom = "";
          listaGarcom = [];
        });
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
    }
  }

  Future<void> _saveGarcom(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('garcom', value);
    } catch (e, st) {
      // debugPrint("Erro _saveGarcom(): $e\n$st");
    }
  }

  Future<void> _saveNumeroGarcom(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('numeroGarcom', value);
    } catch (e, st) {
      // debugPrint("Erro _saveGarcom(): $e\n$st");
    }
  }

  Future<void> funcoesGarcom() async {
    listaGarcom.clear();
    await informacoesGarcom();
    popupSelecionarGarcom();
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

  // Carregar Modos
  Future<void> _carregarModos() async {
    final prefs = await SharedPreferences.getInstance();
    final modoJson = prefs.getString('modo_padrao');

    if (modoJson != null) {
      final modosSalvos = Set<String>.from(jsonDecode(modoJson));

      setState(() {
        // Regra: O mapa aparece se "Mesa" OU "Comanda" estiverem selecionados
        naoAparecerMapa = !(modosSalvos.contains("0"));

        // Lógica de aparecerCheckInOut baseada nos modos Comanda/Mesa
        if (modosSalvos.contains("0")) {
          aparecerCheckInOut = true;
        } else if (!modosSalvos.contains("0")) {
          aparecerCheckInOut = false;
        } else {
          aparecerCheckInOut = false;
        }
      });
    } else {
      setState(() {
        // Se não existir configuração salva (primeira execução), mapa deve vir DESABILITADO
        naoAparecerMapa = true;
        aparecerCheckInOut = true; // Mantendo o padrão deste arquivo
      });
    }
  }

  // Carregar check
  Future<void> carregarchecks() async {
    final prefs = await SharedPreferences.getInstance();
    final checkJson = prefs.getString('check_padrao');

    if (checkJson != null) {
      final checksSalvos = Set<String>.from(jsonDecode(checkJson));
      /* final checksSalvos = List<String>.from(jsonDecode(checkJson));

      final bool checkInPreenchido = checksSalvos.length <= 0 || checksSalvos[0].trim().isNotEmpty;

      final bool checkOutPreenchido = checksSalvos.length <= 1 || checksSalvos[1].trim().isNotEmpty; */

      if (checksSalvos.contains("0") && !checksSalvos.contains("1")) {
          aparecerCheckIn = true;
          aparecerCheckOut = false;
      } else if (checksSalvos.contains("1") && !checksSalvos.contains("0")) {
          aparecerCheckIn = false;
          aparecerCheckOut = true;
      } else if (!checksSalvos.contains("0") && !checksSalvos.contains("1")) {
          aparecerCheckIn = false;
          aparecerCheckOut = false;
      } else if (checksSalvos.contains("0") && checksSalvos.contains("1")) {
          aparecerCheckIn = true;
          aparecerCheckOut = true;
      } else {
          aparecerCheckIn = false;
          aparecerCheckOut = false;
      }

      /* if (checkInPreenchido && !checkOutPreenchido) {
        aparecerCheckIn.value = true;
        aparecerCheckOut.value = false;
      } else if (!checkInPreenchido && checkOutPreenchido) {
        aparecerCheckIn.value = false;
        aparecerCheckOut.value = true;
      } else if (!checkInPreenchido && !checkOutPreenchido) {
        aparecerCheckIn.value = false;
        aparecerCheckOut.value = false;
      } else {
        aparecerCheckIn.value = true;
        aparecerCheckOut.value = true;
      } */
    } else {
        // Se não tiver nada salvo, define padrão
        aparecerCheckIn = false;
        aparecerCheckOut = false;
    }
  }
  /* Future<void> _carregarchecks() async {
    final prefs = await SharedPreferences.getInstance();
    final checkJson = prefs.getString('check_padrao');

    if (checkJson != null) {
      final checksSalvos = Set<String>.from(jsonDecode(checkJson));

      if (checksSalvos.contains("Check-in") &&
          !checksSalvos.contains("Check-out")) {
        setState(() {
          aparecerCheckIn = true;
          aparecerCheckOut = false;
        });
      } else if (checksSalvos.contains("Check-out") &&
          !checksSalvos.contains("Check-in")) {
        setState(() {
          aparecerCheckIn = false;
          aparecerCheckOut = true;
        });
      } else if (!checksSalvos.contains("Check-in") &&
          !checksSalvos.contains("Check-out")) {
        setState(() {
          aparecerCheckIn = false;
          aparecerCheckOut = false;
        });
      } else if (checksSalvos.contains("Check-in") &&
          checksSalvos.contains("Check-out")) {
        setState(() {
          aparecerCheckIn = true;
          aparecerCheckOut = true;
        });
      } else {
        setState(() {
          aparecerCheckIn = false;
          aparecerCheckOut = false;
        });
      }
    } else {
      setState(() {
        // Se não tiver nada salvo, define padrão
        aparecerCheckIn = false;
        aparecerCheckOut = false;
      });
    }
  } */

  // Carregar garçom
  Future<void> _carregargarcom() async {
    final prefs = await SharedPreferences.getInstance();
    final garcomJson = prefs.getString('garcom_padrao');

    if (garcomJson != null) {
      final garcomSalvos = Set<String>.from(jsonDecode(garcomJson));
      // A chave usada na UI é 'Modo Garçom'.
      // Se está no set → garçom ativo; se não está → garçom inativo.
      setState(() {
        aparecerGarcom = garcomSalvos.contains('0');
      });
      // debugPrint('[_carregargarcom] garcomSalvos=$garcomSalvos → aparecerGarcom=$aparecerGarcom');
    } else {
      setState(() {
        // Nenhuma configuração salva: garçom ativo por padrão
        aparecerGarcom = true;
      });
      // debugPrint('[_carregargarcom] nenhum valor salvo → aparecerGarcom=true (padrão)');
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

  // Carregar recepcao
  Future<void> _carregarRecepcao() async {
    final prefs = await SharedPreferences.getInstance();
    final recepcaoJson = prefs.getString('recepcao_padrao');

    if (recepcaoJson != null) {
      final recepcaosSalvos = Set<String>.from(jsonDecode(recepcaoJson));

      if (recepcaosSalvos.contains('0')) {
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

  // Atualiza hora — não faz setState se widget desmontado
  void _atualizarHora() {
    final agora = DateTime.now();
    final horaFormatada = DateFormat.Hm().format(agora);
    if (!mounted) return;
    setState(() {
      _horaAtual = horaFormatada;
    });
  }

  // Função para conectar banco
  Future<void> conectarBanco() async {
    try {
      bool conectado = await Connection.conectarBanco();

      // Só atualiza o visual se o estado mudar de desconectado -> conectado
      if (!servidorConectado && conectado) {
        setState(() {
          servidorConectado = true;
        });
        print(" Servidor conectado com sucesso!");
      }
    } catch (e) {
      // Só atualiza o visual se o estado mudar de conectado -> desconectado
      if (servidorConectado) {
        setState(() {
          servidorConectado = false;
        });
      }
      print(" Erro ao conectar ao banco: $e");
    }
  }

  // Carregamentos do SharedPreferences — sempre atualize localmente e depois chame setState se mounted
  Future<void> _loadServidor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final servidorSalvo = prefs.getString('servidor') ?? '';
      // debugPrint('Servidor carregado: $servidorSalvo');
      if (!mounted) return;
      setState(() {
        servidorController.text = servidorSalvo;
        // Snapshot do momento de abertura da tela — referência confiável para comparação
        _servidorNoLoad = servidorSalvo.trim();
        servidorAntigo = servidorSalvo;
      });
    } catch (e, st) {
      // debugPrint("Erro _loadServidor(): $e\n$st");
    }
  }

  Future<void> _saveServidor(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('servidor', value);
    } catch (e, st) {
      // debugPrint("Erro _saveServidor(): $e\n$st");
    }
  }

  // Servidor antigo
  Future<void> _saveServidorAntigo(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('servidorAntigo', value);
      if (mounted) {
        setState(() {
          servidorAntigo = value;
        });
      }
    } catch (e, st) {
      // debugPrint("Erro _saveServidorAntigo(): $e\n$st");
    }
  }

  Future<void> _loadServidorAntigo() async {
    final prefs = await SharedPreferences.getInstance();
    final servidorSalvo = prefs.getString('servidorAntigo');
    if (servidorSalvo != null && mounted) {
      setState(() {
        servidorAntigo = servidorSalvo;
      });
    }
  }

  Future<void> _loadModoSalvo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedModo = prefs.getString('modo_padrao');
      if (savedModo != null) {
        final setLocal = Set<String>.from(jsonDecode(savedModo));
        if (!mounted) return;
        setState(() {
          modosSelecionados = setLocal;
        });
      }
    } catch (e, st) {
      // debugPrint("Erro _loadModoSalvo(): $e\n$st");
    }
  }

  Future<void> salvarModoSalvo(Set<String> modosSalvos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('modo_padrao', jsonEncode(modosSalvos.toList()));
    } catch (e, st) {
      // debugPrint("Erro salvarModoSalvo(): $e\n$st");
    }
  }

  Future<void> _loadNoteSalvo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNote = prefs.getString('note_padrao');
      if (savedNote != null) {
        final setLocal = Set<String>.from(jsonDecode(savedNote));
        if (!mounted) return;
        setState(() {
          notesSelecionados = setLocal;
        });
      }
    } catch (e, st) {
      // debugPrint("Erro _loadNoteSalvo(): $e\n$st");
    }
  }

  Future<void> salvarNoteSalvo(Set<String> notesSalvos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('note_padrao', jsonEncode(notesSalvos.toList()));
    } catch (e, st) {
      // debugPrint("Erro salvarNoteSalvo(): $e\n$st");
    }
  }

  Future<void> _loadRecepcaoSalvo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRecepcao = prefs.getString('recepcao_padrao');
      if (savedRecepcao != null) {
        final setLocal = Set<String>.from(jsonDecode(savedRecepcao));
        if (!mounted) return;
        setState(() {
          recepcaoSelecionados = setLocal;
        });
      }
    } catch (e, st) {
      // debugPrint("Erro _loadRecepcaoSalvo(): $e\n$st");
    }
  }

  Future<void> salvarRecepcaoSalvo(Set<String> recepcaoSalvos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'recepcao_padrao',
        jsonEncode(recepcaoSalvos.toList()),
      );
    } catch (e, st) {
      // debugPrint("Erro salvarRecepcaoSalvo(): $e\n$st");
    }
  }

  Future<void> _loadCheckSalvo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCheck = prefs.getString('check_padrao');
      if (savedCheck != null) {
        final setLocal = Set<String>.from(jsonDecode(savedCheck));
        if (!mounted) return;
        setState(() {
          checkSelecionados = setLocal;
        });
      }
    } catch (e, st) {
      // debugPrint("Erro _loadCheckSalvo(): $e\n$st");
    }
  }

  Future<void> salvarCheckSalvo(Set<String> checkSalvos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('check_padrao', jsonEncode(checkSalvos.toList()));
    } catch (e, st) {
      // debugPrint("Erro salvarCheckSalvo(): $e\n$st");
    }
  }

  // save painel
  Future<void> salvarPainelSalvo(Set<String> painelSalvos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('painel_padrao', jsonEncode(painelSalvos.toList()));
    } catch (e, st) {
      // debugPrint("Erro salvarPainelSalvo(): $e\n$st");
    }
  }

  // load painel
  Future<void> _loadPainelSalvo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPainel = prefs.getString('painel_padrao');
      if (savedPainel != null) {
        final setLocal = Set<String>.from(jsonDecode(savedPainel));
        if (!mounted) return;
        setState(() {
          paineisSelecionados = setLocal;
        });
      }
    } catch (e, st) {
      // debugPrint("Erro _loadPainelSalvo(): $e\n$st");
    }
  }

  // Carregar rota
  Future<void> carregarRota() async {
    final prefs = await SharedPreferences.getInstance();
    final rotaJson = prefs.getString('rota_padrao');

    if (rotaJson != null) {
      final rotasSalvas = Set<String>.from(jsonDecode(rotaJson));

      setState(() {
        rotasSelecionadas = Set<String>.from(rotasSalvas);
      });

      if (rotasSalvas.contains("0") && !rotasSalvas.contains("1") && !rotasSalvas.contains("2")) {
        setState(() {
          rotaHome = true;
          rotaPainelCliente = false;
          rotaExpedicaoMotoboy = false;
        });
      } else if (rotasSalvas.contains("1") && !rotasSalvas.contains("0") && !rotasSalvas.contains("2")) {
        setState(() {
          rotaHome = false;
          rotaPainelCliente = true;
          rotaExpedicaoMotoboy = false;
        });
      }else if (!rotasSalvas.contains("0") && !rotasSalvas.contains("1") && rotasSalvas.contains("2")){
        setState(() {
          rotaHome = false;
          rotaPainelCliente = false;
          rotaExpedicaoMotoboy = true;
        });
      } else {
        setState(() {
          rotasSelecionadas = {"Home"};
          rotaHome = true;
          rotaPainelCliente = false;
        });
      }
    }
  }

  // Salvar Rota
  Future<void> salvarRota(Set<String> rotasSalvas) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('rota_padrao', jsonEncode(rotasSalvas.toList()));
    } catch (e, st) {
      // debugPrint("Erro salvarRota(): $e\n$st");
    }
  }

  Future<void> identificarNovaRota() async {
    await carregarRota();
    if (rotaHome && !rotaPainelCliente && !rotaExpedicaoMotoboy) {
      setState(() {
        rotaNova = "Home";
      });
    } else if (!rotaHome && rotaPainelCliente && !rotaExpedicaoMotoboy) {
      setState(() {
        rotaNova = "Painel cliente";
      });
    } else if (!rotaHome && !rotaPainelCliente && rotaExpedicaoMotoboy) {
      setState(() {
        rotaNova = "Expedição motoboy";
      });
    }
    // debugPrint("rotaNova: $rotaNova");
    // debugPrint("rotaAntiga: $rotaAntiga");
  }



  Future<void> _salvarConfiguracoes() async {
    await salvarModoSalvo(modosSelecionados);
    await salvarNoteSalvo(notesSelecionados);
    await salvarRecepcaoSalvo(recepcaoSelecionados);
    await _saveServidor(servidorController.text);
    await salvarCheckSalvo(checkSelecionados);
    await _saveVendaComanda(vendaComandaSelecionados);
    await _saveVendaMesa(vendaMesaSelecionados);
    await salvarPainelSalvo(paineisSelecionados);
    await salvarRota(rotasSelecionadas);
    await _saveCupomAvulso(cupomAvulsoSelecionados);
    await _saveCadastroCliente(cadastroClienteSelecionados);
    await _saveTipoCadastroCliente(tipoCadastroClienteSelecionados);
    await _saveForcarCadastroCliente(forcarCadastroClienteSelecionados);
    await _saveModoCarrinhoComandas(modoCarrinhoComandasSelecionados);
    await _saveRetirarBalcao(retirarBalcaoSelecionados);
    await _saveVendas(vendasSelecionados);
  }

  // Deriva as variáveis booleanas de navegação diretamente dos Sets já em memória.
  // NÃO relê SharedPreferences — usa os Sets que acabaram de ser salvos.
  // Faz apenas 1 setState, eliminando os ~14 rebuilds por salvamento.
  Future<void> _aplicarConfiguracoesDaMemoria() async {
    // --- mapa ---
    final bool novoNaoAparecerMapa = !modosSelecionados.contains('0');
    final bool novoAparecerCheckInOut = modosSelecionados.contains('0');

    // --- check ---
    final bool novoCheckIn  = checkSelecionados.contains('0');
    final bool novoCheckOut = checkSelecionados.contains('1');

    // --- venda comanda ---
    final bool novoVendaComanda = vendaComandaSelecionados.contains('0');

    // --- venda mesa ---
    final bool novoVendaMesa = vendaMesaSelecionados.contains('0');

    // --- note ---
    final bool novoNote = notesSelecionados.contains('Notes');

    // --- recepção ---
    final bool novoRecepcao = recepcaoSelecionados.contains('0');

    // --- painéis (if independentes, não if/else-if) ---
    final bool novoKDS              = paineisSelecionados.contains('0');
    final bool novoExpCliente       = paineisSelecionados.contains('1');
    final bool novoExpMotoboy       = paineisSelecionados.contains('2');

    // --- rota ---
    final bool novoRotaHome         = rotasSelecionadas.contains('0') ||
        (!rotasSelecionadas.contains('1') && !rotasSelecionadas.contains('2'));
    final bool novoRotaCliente      = rotasSelecionadas.contains('1') &&
        !rotasSelecionadas.contains('0');
    final bool novoRotaMotoboy      = rotasSelecionadas.contains('2') &&
        !rotasSelecionadas.contains('0') && !rotasSelecionadas.contains('1');

    // --- cupom avulso ---
    final bool novoCupomAvulso = cupomAvulsoSelecionados.contains('Cupom Avulso');

    // --- cadastro cliente ---
    final bool novoCadastroCliente  = cadastroClienteSelecionados.contains('0');

    // --- modo carrinho comandas ---
    final bool novoModoCarrinhoComandas = modoCarrinhoComandasSelecionados.contains('0');

    // --- retirar balcão ----
    final bool novoRetirarBalcao = retirarBalcaoSelecionados.contains('0');

    if (!mounted) return;
    setState(() {
      naoAparecerMapa = novoNaoAparecerMapa;
      aparecerCheckInOut = novoAparecerCheckInOut;
      aparecerCheckIn = novoCheckIn;
      aparecerCheckOut = novoCheckOut;
      aparecerVendaComanda = novoVendaComanda;
      aparecerVendaMesa = novoVendaMesa;
      aparecerNote = novoNote;
      aparecerRecepcao = novoRecepcao;
      aparecerKDS = novoKDS;
      aparecerExpedicaoCliente = novoExpCliente;
      aparecerExpedicaoMotoboy = novoExpMotoboy;
      rotaHome = novoRotaHome;
      rotaPainelCliente = novoRotaCliente;
      rotaExpedicaoMotoboy = novoRotaMotoboy;
      aparecerCupomAvulso = novoCupomAvulso;
      aparecerCadastroCliente = novoCadastroCliente;
      aparecerModoCarrinhoComandas = novoModoCarrinhoComandas;
    });

    footerButtonsController.carregarConfiguracoes();
  }

  Future<void> salvarGarcomSalvo(Set<String> garcomSalvos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('garcom_padrao', jsonEncode(garcomSalvos.toList()));
    } catch (e, st) {
      // debugPrint("Erro salvarGarcomSalvo(): $e\n$st");
    }
  }

  // Função quando cliente já existe por cpf
  Future<String> atualizarTradepoint(String mobileId, String numero) async {
    String mobileIdDoUpdate = mobileId;
    String numeroDoUpdate = numero;

    // Monta o SQL UPDATE
    String sql =
        '''
      UPDATE tradepoints
      SET 
        mobileid='$mobileIdDoUpdate'
      WHERE numero='$numeroDoUpdate';
    ''';

    // Executa o SQL usando a função ipd
    String resultado = await Connection().ipd(sql);

    if (resultado == "sucesso") {
      setState(() {
        existePVDcomMobile = true;
      });
      print(sql);
      print("Cliente atualizado com sucesso!");
    } else {
      print("Erro ao atualizar cliente.");
    }

    return resultado;
  }

  void popupSelecionarGarcom() {
    /* if (_popupGarcomAberto) return;
    _popupGarcomAberto = true;

    /*  if (!servidorConectado) {
      _popupGarcomAberto = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Sem conexão com o servidor."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    } */

    if (nomeDaLicenca == "" && rotaHome) {
      _popupGarcomAberto = false;
      /* ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Selecione uma licença primeiro."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      ); */
      return;
    } */

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Align(
            alignment: Alignment.center,
            child: Text(
              "Selecione um usuário",
              style: TextStyle(
                fontSize: 20, // ou qualquer outro estilo que desejar
              ),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: funcoesController.listaGarcom.isEmpty
                ? Center(child: Text("Nenhum usuário encontrado"))
                : ListView.builder(
                    itemCount: funcoesController.listaGarcom.length,
                    itemBuilder: (context, index) {
                      final garcom = funcoesController.listaGarcom[index];

                      return Card(
                        child: ListTile(
                          title: Text(garcom['nome']),
                          // subtitle: Text("Número: ${garcom['numero']}"),
                          onTap: () async {
                            Navigator.pop(context);
                            aparecerConectar = true;
                            // abrir pop up senha
                            popupDigitarSenha(
                              context: context,
                              senhaDoGarcom: garcom['senhanova'],
                              nomeDoGarcomFuncao: garcom['nome'],
                              numeroDoGarcomFuncao: garcom['numero'],
                              funcaoDoGarcomFuncao: garcom['funcao'],
                              title: "Insira a senha do usuário ${garcom['nome']}",
                              message: "",
                              icon: Icons.lock,
                              textController: senhaController,
                              focusNode: senhaFocusNode,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  aparecerConectar = true;
                  carregamento = false;
                });
              },
              child: Text("Cancelar"),
            ),
          ],
        );
      },
    ).then((_) {
      _popupGarcomAberto = false;
    });
  }

  Future<void> popupDigitarSenha({
    required BuildContext context,
    required String senhaDoGarcom,
    required String nomeDoGarcomFuncao,
    required String numeroDoGarcomFuncao,
    required String funcaoDoGarcomFuncao,
    String title = 'Confirmação',
    required String message,
    IconData icon = Icons.home,
    String cancelText = 'Cancelar',
    String confirmText = 'Confirmar',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    TextEditingController? textController,
    FocusNode? focusNode,
    ValueChanged<String>? onSubmitted, // Callback ao submeter o texto
  }) {
    shakeKey = 0;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        String erro = "";

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: isloadingSenha
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Ícone central
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(
                                ctx,
                              ).colorScheme.primary.withOpacity(0.08),
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
                                style: Theme.of(ctx).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          SizedBox(height: 5),

                          Animate(
                            key: ValueKey(shakeKey),
                            effects: shakeKey == 0
                                ? []
                                : [
                                    ShakeEffect(
                                      duration: Duration(milliseconds: 500),
                                      hz: 4,
                                      offset: Offset(10, 0),
                                    ),
                                  ],
                            child: Pinput(
                              autofocus: true,
                              controller: senhaController,
                              focusNode: senhaFocusNode,
                              length: 6, // quantidade de bolinhas

                              keyboardType: TextInputType.number,
                              obscureText: true,
                              obscuringCharacter: "•",

                              defaultPinTheme: PinTheme(
                                width: 55,
                                height: 55,
                                textStyle: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: erroBool
                                        ? Theme.of(ctx).colorScheme.error
                                        : Theme.of(ctx).colorScheme.primary,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),

                              focusedPinTheme: PinTheme(
                                width: 55,
                                height: 55,
                                textStyle: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(ctx).colorScheme.secondary,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),

                              errorPinTheme: PinTheme(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(ctx).colorScheme.error,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),

                              onChanged: (value) {
                                setDialogState(() {
                                  erro = "";
                                  erroBool = false;
                                });
                              },

                              onCompleted: (value) async {
                                // executa quando preencher os 6 dígitos
                                if (value != senhaDoGarcom) {
                                  setDialogState(() {
                                    erro = "Senha incorreta";
                                    shakeKey = 1;
                                    senhaController.clear();
                                    erroBool = true;
                                    Future.delayed(
                                      Duration(milliseconds: 300),
                                      () {
                                        if (senhaFocusNode.canRequestFocus) {
                                          senhaFocusNode.requestFocus();
                                        }
                                      },
                                    );
                                  });
                                  print("Senha incorreta");
                                } else {
                                  setDialogState(() {
                                    isloadingSenha = false;
                                  });
                                  setState(() {
                                    garcomSelecionadoFuncao = true;
                                    numeroDoGarcom = numeroDoGarcomFuncao;
                                    nomeDoGarcom = nomeDoGarcomFuncao;
                                  });
                                  await _saveGarcom(nomeDoGarcomFuncao);
                                  await _saveNumeroGarcom(numeroDoGarcomFuncao);
                                  await _saveNumeroLicenca(
                                    numeroDaLicencaSelecionada,
                                  );
                                  await atualizarTradepoint(
                                    mobileId,
                                    numeroDaLicencaDisponivel,
                                  );
                                  await _saveLicenca(nomeDaLicencaSelecionada);
                                  await navegar();
                                  servidorAntigo = servidorController.text;
                                  _saveServidorAntigo(servidorAntigo);
                                  funcoesController.controlarAparecimentoBotaoPagar(funcaoDoGarcomFuncao);
                                  print("Senha correta");
                                  setDialogState(() {
                                    isloadingSenha = true;
                                  });
                                }
                              },
                            ),
                          ),

                          SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  // popupSelecionarGarcom();
                                  Future.delayed(
                                    Duration(milliseconds: 100),
                                    () => popupSelecionarGarcom(),
                                  );
                                  aparecerConectar = true;
                                  senhaController.clear();
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
                                ),
                                child: Text(
                                  "Cancelar",
                                  style: TextStyle(
                                    color: Theme.of(ctx).colorScheme.onPrimary,
                                  ),
                                ),
                              ),

                              SizedBox(width: 10),

                              ElevatedButton(
                                onPressed: () async {
                                  isloadingSenha = false;
                                  if (senhaController.text != senhaDoGarcom) {
                                    setDialogState(() {
                                      erro = "Senha incorreta";
                                      shakeKey = 1;
                                      senhaController.clear();
                                      erroBool = true;
                                      Future.delayed(
                                        Duration(milliseconds: 300),
                                        () {
                                          if (senhaFocusNode.canRequestFocus) {
                                            senhaFocusNode.requestFocus();
                                          }
                                        },
                                      );
                                    });
                                    print("Senha incorreta");
                                  } else {
                                    setDialogState(() {
                                      isloadingSenha = true;
                                    });
                                    setState(() {
                                      garcomSelecionadoFuncao = true;
                                      numeroDoGarcom = numeroDoGarcomFuncao;
                                      nomeDoGarcom = nomeDoGarcomFuncao;
                                    });
                                    await _saveGarcom(nomeDoGarcomFuncao);
                                    await _saveNumeroGarcom(
                                      numeroDoGarcomFuncao,
                                    );
                                    await navegar();
                                    servidorAntigo = servidorController.text;
                                    _saveServidorAntigo(servidorAntigo);
                                    funcoesController
                                        .controlarAparecimentoBotaoPagar(
                                          funcaoDoGarcomFuncao,
                                        );
                                    setDialogState(() {
                                      isloadingSenha = false;
                                    });
                                    print("Senha correta");
                                  }
                                  // Navigator.pop(ctx);
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
                                ),
                                child: Text(
                                  "Confirmar",
                                  style: TextStyle(
                                    color: Theme.of(ctx).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : SizedBox(
                        width: 280,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(
                                  ctx,
                                ).colorScheme.primary.withOpacity(0.08),
                              ),
                              child: SizedBox(
                                width: 45,
                                height: 45,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              ),
                            ),

                            SizedBox(height: 20),

                            Text(
                              "Validando usuário",
                              style: Theme.of(ctx).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),

                            SizedBox(height: 8),

                            Text(
                              "Aguarde alguns instantes...",
                              textAlign: TextAlign.center,
                              style: Theme.of(ctx).textTheme.bodySmall,
                            ),

                            SizedBox(height: 10),
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

  // Função com o popup para selecionar licenças diponiveis
  void popupSelecionarLicenca() {
    if (_popupLicencaAberto) return;
    _popupLicencaAberto = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Align(
            alignment: Alignment.center,
            child: Text(
              "Selecione uma licença",
              style: TextStyle(
                fontSize: 20, // ou qualquer outro estilo que desejar
              ),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: listaLicencaDisponivel.isEmpty
                ? Center(child: Text("Nenhuma licença encontrada"))
                : ListView.builder(
                    itemCount: listaLicencaDisponivel.length,
                    itemBuilder: (context, index) {
                      final licenca = listaLicencaDisponivel[index];

                      return Card(
                        child: ListTile(
                          title: Text(licenca['nome']),
                          // subtitle: Text("Número: ${licenca['numero']}"),
                          onTap: () async {
                            setState(() {
                              licencaSelecionada = true;
                              numeroDaLicencaDisponivel = licenca['numero']
                                  .toString();
                              nomeDaLicencaDisponivel = licenca['nome'];
                              nomeDaLicencaSelecionada = licenca['nome']
                                  .toString();
                              numeroDaLicencaSelecionada = licenca['numero']
                                  .toString();
                              nomeDaLicenca = nomeDaLicencaSelecionada;
                              nomeDaLicencaDoLoad = true;
                            });
                            Navigator.of(context).pop(); // fecha o popup
                            await funcoesGarcom();
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  aparecerConectar = true;
                  carregamento = false;
                });
              },
              child: Text("Cancelar"),
            ),
          ],
        );
      },
    ).then((_) {
      _popupLicencaAberto = false;
    });
  }

  // Widget build
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                  child: Column(
                    // crossAxisAlignment: CrossAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(
                        () => Text(
                          Connection.connectionStatus.value
                              ? 'Online'
                              : 'Offline',
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
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            /* Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                  Text(
                    'Configurações de rede:',
                    style: TextStyle(
                      color: colorScheme.onSecondary,
                      fontSize: 15,
                    // fontWeight: FontWeight.bold,
                  ),
                ),
              ]
            ), */
            // SizedBox(height: 2),
           /*  ElevatedButton(
              onPressed: () async {
                final resultado = await stoneService.pagar(
                  valor: 1000,
                  referencia: 'TESTE-001',
                );

                print(resultado);
              },
              child: Text('TESTAR STONE'),
            ), */
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Text(
                      'IP:',
                      style: TextStyle(
                        color: colorScheme.onSecondary,
                        fontSize: 15,
                        // fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isloading)
                    Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 6,
                          valueColor: AlwaysStoppedAnimation(
                            colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  if (!isloading)
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
                                focusNode: servidorFocusNode,
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

                          child: TextField(
                            readOnly: false, 
                            showCursor: true, // FORÇA o cursor piscando
                            cursorColor: Theme.of(context).colorScheme.primary,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            controller: servidorController,
                            focusNode: servidorFocusNode,
                            onTap: () async {
                              Future.delayed(Duration(milliseconds: 300), () {
                                if (servidorFocusNode.canRequestFocus) {
                                  servidorFocusNode.requestFocus();
                                }
                              });
                            },  
                            onChanged: (value) {
                              // quando entrar "," substituir por "."
                              if (value.contains(",")) {
                                servidorController.text = value.replaceAll(",", ".");
                              }
                              setState(() {
                                aparecerConectar = true;
                              });
                            },
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: "Digite aqui o seu servidor:",
                              hintStyle: TextStyle(color: colorScheme.onSurface),
                              filled: true,
                              fillColor: _isFocused
                                  ? colorScheme.secondary
                                  : colorScheme.surface,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(width: 5),

                  if (!isloading)
                    ElevatedButton(
                      onPressed: () async {
                        isloading = true;

                        if (servidorController.text.isNotEmpty) {
                          if (!mounted) return;
                          setState(() => isloading = true);

                          try {
                            if (servidorController.text.isEmpty) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Por favor, preencha o campo com o servidor.',
                                  ),
                                  backgroundColor: colorScheme.primary,
                                ),
                              );
                              setState(() => isloading = false);
                              return;
                            }
                            if (servidorController.text.isNotEmpty) {
                              await _saveServidor(servidorController.text);
                              bool conectado =
                                  await Connection.conectarBanconoSalvar();
                              if (!mounted) return;
                              if (conectado) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Servidor apto para conexão.',
                                    ),
                                    backgroundColor: colorScheme.primary,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Erro ao conectar ao servidor. Verifique as configurações.',
                                    ),
                                    backgroundColor: colorScheme.error,
                                  ),
                                );
                              }
                              setState(() {
                                isloading = false;
                              });
                            }
                          } catch (e, st) {
                            // debugPrint('Erro ao testar conexão: $e\n$st');
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Erro ao conectar servidor. Tente novamente.',
                                ),
                                backgroundColor: colorScheme.primary,
                              ),
                            );
                          } finally {
                            if (!mounted) return;
                            setState(() => isloading = false);
                          }
                        }

                        isloading = false;
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: colorScheme.primary,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        'Conectar',
                        style: TextStyle(color: colorScheme.onPrimary),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 7),
           /*  SizedBox(
              height: MediaQuery.of(context).size.height * 0.65, */
              Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                          Flexible(
                            child: Text(
                              textAlign: TextAlign.center,
                              'Configurações de tela:',
                              style: TextStyle(
                                color: colorScheme.onSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Venda comanda
                      if(funcoesController.vendaComanda.value)
                      Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: vendaComanda.length,
                            itemBuilder: (context, index) {
                              String modo = vendaComanda[index];
                              String indexStr = index.toString();
                              bool isChecked = vendaComandaSelecionados.contains(indexStr);
                              return CheckboxListTile(
                                controlAffinity: ListTileControlAffinity.leading,
                                // Diminui o espaço vertical
                                dense: true,
                                visualDensity: const VisualDensity(
                                  horizontal: -2,
                                  vertical: -3,
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                                title: Text(modo, style: TextStyle(
                                  fontSize: 15
                                ),),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (vendaComandaSelecionados.length <= 2)
                                        vendaComandaSelecionados.add(indexStr);
                                        if (modo == '0') {
                                          vendaComandaSelecionados.add('0');
                                        } 
                                    } else {
                                      vendaComandaSelecionados.remove(indexStr);
                                      if (modo == '0') {
                                        vendaComandaSelecionados.remove('0');
                                      }
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        // Venda mesa
                        if(funcoesController.vendaMesa.value)
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: vendaMesa.length,
                            itemBuilder: (context, index) {
                              String modo = vendaMesa[index];
                              String indexStr = index.toString();
                              bool isChecked = vendaMesaSelecionados.contains(indexStr);
                              return CheckboxListTile(
                                controlAffinity: ListTileControlAffinity.leading,
                                // Diminui o espaço vertical
                                dense: true,
                                visualDensity: const VisualDensity(
                                  horizontal: -2,
                                  vertical: -3,
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                                title: Text(modo, style: TextStyle(
                                  fontSize: 15
                                ),),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (vendaMesaSelecionados.length <= 2)
                                        vendaMesaSelecionados.add(indexStr);
                                        if (modo == '0') {
                                          vendaMesaSelecionados.add('0');
                                        } 
                                    } else {
                                      vendaMesaSelecionados.remove(indexStr);
                                      if (modo == '0') {
                                        vendaMesaSelecionados.remove('0');
                                      }
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        // if(funcoesController.vendaBalcao.value)
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: retirarBalcao.length,
                            itemBuilder: (context, index) {
                              String modo = retirarBalcao[index];
                              String indexStr = index.toString();
                              bool isChecked = retirarBalcaoSelecionados.contains(indexStr);

                              return CheckboxListTile(
                                controlAffinity: ListTileControlAffinity.leading,
                                // Diminui o espaço vertical
                                dense: true,
                                visualDensity: const VisualDensity(
                                  horizontal: -2,
                                  vertical: -3,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                title: Text(modo, style: TextStyle(
                                  fontSize: 15
                                ),),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      retirarBalcaoSelecionados.add(indexStr);
                                    } else {
                                      retirarBalcaoSelecionados.remove(indexStr);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      // check in e check out
                      if (check.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: check.length,
                            itemBuilder: (context, index) {
                              String modo = check[index];
                              String indexStr = index.toString();
                              
                              final bool isChecked = checkSelecionados.contains(indexStr);
                              return CheckboxListTile(
                                controlAffinity: ListTileControlAffinity.leading,
                                // Diminui o espaço vertical
                                  dense: true,
                                  visualDensity: const VisualDensity(
                                    horizontal: -2,
                                    vertical: -3,
                                  ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                                title: Text(modo, style: TextStyle(
                                  fontSize: 15
                                ),),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (checkSelecionados.length <= 2)
                                        checkSelecionados.add(indexStr); // só pode ter até duas opções selecionadas na lista
                                        if (modo == '0') {
                                          checkSelecionados.add('0');
                                        } 
                                        if (modo == '1') {
                                          checkSelecionados.add('1');
                                        }
                                    } else {
                                      checkSelecionados.remove(indexStr);
                                      if (modo == '0') {
                                        checkSelecionados.remove('0');
                                      } 
                                      if (modo == '1') {
                                        checkSelecionados.remove('1');
                                      }
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        if (paineis.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: paineis.length,
                            itemBuilder: (context, index) {
                              String modo = paineis[index];
                              String indexStr = index.toString();
                              bool isChecked = paineisSelecionados.contains(
                                indexStr,
                              );
                              return CheckboxListTile(
                                activeColor: colorScheme.primary,
                                controlAffinity:  ListTileControlAffinity.leading,
                                dense: true,
                                visualDensity: const VisualDensity(
                                  horizontal: -2,
                                  vertical: -3,
                                ),
                                title: Text(modo, style: TextStyle(
                                  fontSize: 15
                                ),),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                        paineisSelecionados.add(indexStr);
                                    } else {
                                      paineisSelecionados.remove(indexStr);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                     /*  Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                          Flexible(
                            child: Text(
                              textAlign: TextAlign.center,
                              'Configurações de mapa:',
                              style: TextStyle(
                                color: colorScheme.onSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ), */
                      // SizedBox(height: 2),
                      // MAPA 
                      if (modos.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: modos.length,
                            itemBuilder: (context, index) {
                              String modo = modos[index];
                              String indexStr = index.toString();
                              bool isChecked = modosSelecionados.contains(indexStr);
                              return CheckboxListTile(
                                controlAffinity: ListTileControlAffinity.leading,
                                // Diminui o espaço vertical
                                dense: true,
                                visualDensity: const VisualDensity(
                                  horizontal: -2,
                                  vertical: -3,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 0.0
                                ),
                                title: Text(modo, style: TextStyle(
                                  fontSize: 15
                                ),),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                        modosSelecionados.add(indexStr);
                                    } else {
                                      modosSelecionados.remove(indexStr);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        // CONFIGURACOES DO MAPA 
                        if (modosSelecionados.contains('0'))
                        Padding(
                          padding: EdgeInsets.only(right: 8, left: 20),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: vendas.length,
                            itemBuilder: (context, index) {
                              String modo = vendas[index];
                              String indexStr = "";
                              if (modo == 'Venda Balcão') indexStr = '0';
                              else if (modo == 'Venda Comanda') indexStr = '1';
                              else if (modo == 'Venda Comanda Na Mesa') indexStr = '2';
                              else if (modo == 'Venda Mesa') indexStr = '3';
                              bool isChecked = vendasSelecionados.contains(indexStr);
                              return CheckboxListTile(
                                controlAffinity: ListTileControlAffinity.leading,
                                // Diminui o espaço vertical
                                dense: true,
                                visualDensity: const VisualDensity(
                                  horizontal: -2,
                                  vertical: -3,
                                ),
                                activeColor: colorScheme.tertiary,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                title: Text(modo, style: TextStyle(
                                  fontSize: 15
                                ),),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      vendasSelecionados.add(indexStr);
                                    } else {
                                      vendasSelecionados.remove(indexStr);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      // SizedBox(height: 2),
                      /* Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              textAlign: TextAlign.center,
                              'Configurações notes:',
                              style: TextStyle(
                                color: colorScheme.onSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ), */
                      // SizedBox(height: 2),
                      if (notes.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: notes.length,
                            itemBuilder: (context, index) {
                              String modo = notes[index];
                              final String indexStr = index.toString();
                              bool isChecked = notesSelecionados.contains(indexStr);
                              return CheckboxListTile(
                                controlAffinity: ListTileControlAffinity.leading,
                                // Diminui o espaço vertical
                                dense: true,
                                visualDensity: const VisualDensity(
                                  horizontal: -2,
                                  vertical: -3,
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                                title: Text(modo, style: TextStyle(
                                  fontSize: 15
                                ),),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (notesSelecionados.length <= 2)
                                        notesSelecionados.add(indexStr); // só pode ter até duas opções selecionadas na lista
                                        if (modo == '0') {
                                          notesSelecionados.add('0');
                                        } 
                                    } else {
                                      notesSelecionados.remove(indexStr);
                                      if (modo == '0') {
                                        notesSelecionados.remove('0');
                                      } 
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      /* Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              textAlign: TextAlign.center,
                              'Configurações de recepção:',
                              style: TextStyle(
                                color: colorScheme.onSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ), */
                      // SizedBox(height: 2),
                      if (recepcao.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: recepcao.length,
                            itemBuilder: (context, index) {
                              String modo = recepcao[index];
                              String indexStr = index.toString();
                              bool isChecked = recepcaoSelecionados.contains(indexStr);
                              return CheckboxListTile(
                                controlAffinity: ListTileControlAffinity.leading,
                                // Diminui o espaço vertical
                                dense: true,
                                visualDensity: const VisualDensity(
                                  horizontal: -2,
                                  vertical: -3,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                title: Text(modo, style: TextStyle(
                                  fontSize: 15
                                ),),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                    if (recepcaoSelecionados.length <= 2)
                                      recepcaoSelecionados.add(indexStr); // só pode ter até duas opções selecionadas na lista
                                      if (modo == '0') {
                                        recepcaoSelecionados.add('0');
                                      } 
                                    } else {
                                      recepcaoSelecionados.remove(indexStr);
                                      if (modo == '0') {
                                        recepcaoSelecionados.remove('0');
                                      } 
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      /* Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              textAlign: TextAlign.center,
                              'Configurações garçom:',
                              style: TextStyle(
                                color: colorScheme.onSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ), */
                      /* // SizedBox(height: 2),
                      if (garcom.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: garcom.length,
                            itemBuilder: (context, index) {
                              String modo = garcom[index];
                              String indexStr = index.toString();
                              bool isChecked = garcomSelecionados.contains(indexStr);
                              return CheckboxListTile(
                                controlAffinity: ListTileControlAffinity.leading,
                                // Diminui o espaço vertical
                                dense: true,
                                visualDensity: const VisualDensity(
                                  horizontal: -2,
                                  vertical: -3,
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                                title: Text(modo, style: TextStyle(
                                  fontSize: 15
                                ),),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (garcomSelecionados.length <= 2)
                                        garcomSelecionados.add(indexStr);
                                        if (modo == '0') {
                                          garcomSelecionados.add('0');
                                        } 
                                    } else {
                                      garcomSelecionados.remove(indexStr);
                                      if (modo == '0') {
                                        garcomSelecionados.remove('0');
                                      }
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ), */

                      // SizedBox(height: 2),

                      /* Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              textAlign: TextAlign.center,
                              'Configuração dos painéis:',
                              style: TextStyle(
                                color: colorScheme.onSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ), */
                      /* // SizedBox(height: 2), */

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              textAlign: TextAlign.center,
                              'Cadastro cliente(Abertura comanda):',
                              style: TextStyle(
                                color: colorScheme.onSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // SizedBox(height: 2),
                      if (cadastroCliente.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: cadastroCliente.length,
                            itemBuilder: (context, index) {
                              String modo = cadastroCliente[index];
                              String indexStr = index.toString();
                              bool isChecked = cadastroClienteSelecionados.contains(indexStr);

                              return CheckboxListTile(
                                controlAffinity: ListTileControlAffinity.leading,
                                // Diminui o espaço vertical
                                dense: true,
                                visualDensity: const VisualDensity(
                                  horizontal: -2,
                                  vertical: -3,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                title: Text(modo, style: TextStyle(
                                  fontSize: 15
                                ),),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      cadastroClienteSelecionados.add(indexStr);
                                    } else {
                                      cadastroClienteSelecionados.remove(indexStr);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      // SizedBox(height: 2),
                      if (cadastroClienteSelecionados.contains('0'))
                        Padding(
                          padding: EdgeInsets.only(right: 8, left: 20),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: tipoCadastroCliente.length,
                            itemBuilder: (context, index) {
                              String modo = tipoCadastroCliente[index];
                              String indexStr = index.toString();
                              bool isChecked = tipoCadastroClienteSelecionados.contains(indexStr);
                              return RadioListTile<String>(
                                controlAffinity: ListTileControlAffinity.leading,
                                // Diminui o espaço vertical
                                dense: true,
                                visualDensity: const VisualDensity(
                                  horizontal: -2,
                                  vertical: -3,
                                ),
                                activeColor: colorScheme.secondary,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                title: Text(modo, style: TextStyle(
                                  fontSize: 15
                                ),),
                                value: indexStr,
                                groupValue: tipoCadastroClienteSelecionados.isNotEmpty ? tipoCadastroClienteSelecionados.first : null,
                                onChanged: (String? value) {
                                  if (value == null) return;

                                  setState(() {
                                    tipoCadastroClienteSelecionados.clear();
                                    tipoCadastroClienteSelecionados.add(value);
                                  });
                                },
                              );
                              /* CheckboxListTile(
                                controlAffinity: ListTileControlAffinity.leading,
                                // Diminui o espaço vertical
                                dense: true,
                                visualDensity: const VisualDensity(
                                  horizontal: -2,
                                  vertical: -3,
                                ),
                                activeColor: colorScheme.secondary,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                title: Text(modo, style: TextStyle(
                                fontSize: 15),),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      tipoCadastroClienteSelecionados.clear();
                                      tipoCadastroClienteSelecionados.add(indexStr);
                                    } else {
                                      tipoCadastroClienteSelecionados.remove(indexStr);
                                    }
                                  });
                                },
                              ); */
                            },
                          ),
                        ),
                        if (cadastroClienteSelecionados.contains('0'))
                        Padding(
                          padding: EdgeInsets.only(right: 8, left: 20),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: forcarCadastroCliente.length,
                            itemBuilder: (context, index) {
                              String modo = forcarCadastroCliente[index];
                              String indexStr = index.toString();
                              bool isChecked = forcarCadastroClienteSelecionados.contains(indexStr);
                              return CheckboxListTile(
                                controlAffinity: ListTileControlAffinity.leading,
                                // Diminui o espaço vertical
                                dense: true,
                                visualDensity: const VisualDensity(
                                  horizontal: -2,
                                  vertical: -3,
                                ),
                                activeColor: colorScheme.tertiary,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                title: Text(modo, style: TextStyle(
                                  fontSize: 15
                                ),),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      forcarCadastroClienteSelecionados.clear();
                                      forcarCadastroClienteSelecionados.add(indexStr);
                                    } else {
                                      forcarCadastroClienteSelecionados.remove(indexStr);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),

                      /* Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              textAlign: TextAlign.center,
                              'Configuração dos painéis:',
                              style: TextStyle(
                                color: colorScheme.onSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // SizedBox(height: 2),
                      if (paineis.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: paineis.length,
                            itemBuilder: (context, index) {
                              String modo = paineis[index];
                              String indexStr = index.toString();
                              bool isChecked = paineisSelecionados.contains(
                                indexStr,
                              );
                              return CheckboxListTile(
                                activeColor: colorScheme.primary,
                                controlAffinity:  ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                title: Text(modo, style: TextStyle(
                                  fontSize: 15
                                ),),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                        paineisSelecionados.add(indexStr);
                                    } else {
                                      paineisSelecionados.remove(indexStr);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ), */

                      /* Center(
                        child: Text(
                          'Configuração cupom avulso:',
                          style: TextStyle(
                            color: colorScheme.onSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      // SizedBox(height: 2),
                      if (cupomAvulso.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: cupomAvulso.length,
                            itemBuilder: (context, index) {
                              String modo = cupomAvulso[index];
                              bool isChecked = cupomAvulsoSelecionados.contains(modo);
                              return CheckboxListTile(
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                title: Text(modo, style: TextStyle(
                                fontSize: 15),),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (cupomAvulsoSelecionados.length <= 3)
                                        cupomAvulsoSelecionados.add(modo);
                                    } else {
                                      cupomAvulsoSelecionados.remove(modo);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ), */

                        Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              textAlign: TextAlign.center,
                              'Carrinho de comandas(Vendas):',
                              style: TextStyle(
                                color: colorScheme.onSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // SizedBox(height: 2),
                      if (modoCarrinhoComandas.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: modoCarrinhoComandas.length,
                            itemBuilder: (context, index) {
                              String modo = modoCarrinhoComandas[index];
                              String indexStr = index.toString();
                              bool isChecked = modoCarrinhoComandasSelecionados.contains(indexStr);

                              return CheckboxListTile(
                                controlAffinity: ListTileControlAffinity.leading,
                                // Diminui o espaço vertical
                                dense: true,
                                visualDensity: const VisualDensity(
                                  horizontal: -2,
                                  vertical: -3,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                title: Text(modo, style: TextStyle(
                                  fontSize: 15
                                ),),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      modoCarrinhoComandasSelecionados.add(indexStr);
                                    } else {
                                      modoCarrinhoComandasSelecionados.remove(indexStr);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              textAlign: TextAlign.center,
                              'Configuração de rota inicial:',
                              style: TextStyle(
                                color: colorScheme.onSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // SizedBox(height: 2),
                      if (paineis.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: rotas.length,
                            itemBuilder: (context, index) {
                              String modo = rotas[index];
                              String indexStr = index.toString();
                              bool isChecked = rotasSelecionadas.contains(indexStr);
                              
                              return RadioListTile<String>(
                                controlAffinity: ListTileControlAffinity.leading,
                                // Diminui o espaço vertical
                                dense: true,
                                visualDensity: const VisualDensity(
                                  horizontal: -2,
                                  vertical: -3,
                                ),
                                activeColor: colorScheme.scrim,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                title: Text(modo, style: TextStyle(
                                  fontSize: 15
                                ),),
                                value: indexStr,
                                groupValue: rotasSelecionadas.isNotEmpty
                                    ? rotasSelecionadas.first
                                    : null,
                                onChanged: (String? value) {
                                  if (value == null) return;

                                  setState(() {
                                    rotasSelecionadas.clear();
                                    rotasSelecionadas.add(value);
                                  });
                                },
                              );/* 
                              CheckboxListTile(
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                title: Text(modo, style: TextStyle(
                                fontSize: 15),),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      rotasSelecionadas.clear();
                                      rotasSelecionadas.add(indexStr);
                                    } else {
                                      rotasSelecionadas.remove(indexStr);
                                    }
                                  });
                                },
                              ); */
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 5),
            // Botão salvar
            AbsorbPointer(
              absorbing: isLoadingSalvar, // true = bloqueia cliques
              child: Center(
                child: isLoadingSalvar
                    ? CircularProgressIndicator(
                        strokeWidth: 6,
                        valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          setState(() => isLoadingSalvar = true);

                          try {
                            if (servidorController.text.isEmpty) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Por favor, preencha todas as informações antes de salvar.',
                                  ),
                                  backgroundColor: colorScheme.primary,
                                ),
                              );
                              return;
                            }

                            // Snapshot confiável: capturado no load da tela, independente de SharedPreferences
                            final String servidorNovo = servidorController.text.trim();
                            bool servidorMudou = servidorAntigoFuncao != servidorNovo;

                            await _salvarConfiguracoes();
                            await _aplicarConfiguracoesDaMemoria();

                            bool conectado = await Connection.conectarBanco();

                            if (!mounted) return;

                            if (conectado) {
                              await salvarNomeEmpresa();

                              if (servidorMudou) {
                                // Servidor mudou: atualiza snapshot e executa licença + garçom
                                _servidorNoLoad = servidorNovo;
                                servidorAntigo = servidorController.text;
                                await _saveServidorAntigo(servidorAntigo);
                                await _saveServidor(servidorController.text);
                                await funcoesLicenca();
                              } else {
                                await identificarNovaRota();
                                if (rotaNova == 'Home' && (rotaAntiga == 'Cliente' || rotaAntiga == 'Expedição motoboy')) {
                                  popupSelecionarGarcom();
                                  return;
                                }
                                // Servidor não mudou: navega com booleanos já atualizados
                                await navegar();
                                footerButtonsController.carregarConfiguracoes();
                                carrinhoController.carrinho.clear();
                              }
                            }
                          } catch (e, st) {
                            // debugPrint('Erro ao salvar: $e\n$st');
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Erro ao salvar as configurações. Tente novamente.',
                                ),
                                backgroundColor: colorScheme.primary,
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() {
                                isLoadingSalvar = false;
                              });
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          padding: EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Salvar',
                          style: TextStyle(
                            fontSize: 20,
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
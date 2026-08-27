import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:un_recepcao/controllers/carrinho_controller.dart';
import 'package:un_recepcao/controllers/views/funcoes_controller.dart';
import 'package:un_recepcao/controllers/views/painel_controller.dart';
import 'package:un_recepcao/data/data_class.dart';
import 'package:un_recepcao/models/itemPizzaGrafico.dart';
import 'package:un_recepcao/views/garcom_page.dart';
import 'package:un_recepcao/widgets/side_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

class PizzaPage extends StatefulWidget {
  const PizzaPage({super.key});

  @override
  State<PizzaPage> createState() => PizzaPageState();
}

class PizzaPageState extends State<PizzaPage> with SingleTickerProviderStateMixin {

  String versaoAplicacao = FuncoesController().versaoDoApp;

  bool nunca = false;

  final CarrinhoController carrinhoController = Get.find<CarrinhoController>();
  // Variáveis para receber e ajeitar args
  final String tamanhoSelecionado = Get.arguments['tamanhoSelecionado'];
  final String comandaDoPedido = Get.arguments['comanda'];
  final String mesaDoPedido = Get.arguments['mesa'];
  final String numeroDoPedidoArgs = Get.arguments['numeroDoPedido'];

  final String clienteIdArgs = Get.arguments['clienteId'] ?? '';
  final String clienteNomeArgs = Get.arguments['clienteNome'] ?? '';
  final String clienteCpfArgs = Get.arguments['clienteCpf'] ?? '';
  final String clienteTelefoneArgs = Get.arguments['clienteTelefone'] ?? '';
  final String clienteDataNascimentoArgs = Get.arguments['clienteDataNascimento'] ?? '';

  // edição de pizza
  final int index = Get.arguments['index'];
  final Produto? produtoSelecionado = Get.arguments['produtoSelecionado'];
  final bool editar = Get.arguments['editar'];

  String comandaDoPedidoParaInsert = "";
  String mesaDoPedidoParaInsert = "";

  final TextEditingController comandaController = TextEditingController();
  final TextEditingController servidorController = TextEditingController();
  String nomeEmpresa = '';
  String mensagem = 'Insira o número da comanda';
  bool corMensagem = true;
  bool iconeMensagem = true;
  bool animacaoAparecer = false;

  late Timer _timer;
  String _horaAtual = '';

  bool checkIn = true;
  bool checkout = false;
  bool mapaDeMesaoOuComanda = false;
  bool comandas = true;

  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  // Controle dos filtros de mesas e comandas
  bool mostrarTodas = true;
  bool mostrarAbertas = false;
  bool mostrarFechadas = false;
  bool mesaAberta = true;
  bool _isLoading = true;
  bool servidorConectado = false;

  Timer? _timerApagar;

  List<dynamic> validaComanda = [];
  String numeroDoPedido = '';
  String valorTotalLiquido = '';
  String statusPedido = '';
  String numeroDoProduto = '';

  bool aparecerNote = false;

  // Contraladores da animação    
  late AnimationController animationController;
  late Animation<double> scaleAnimation;
  bool animacaoCerto = true;

  bool isLoading = false;

  String comandaNumero = '';
  bool comandaRegistrada = false;
  bool aparecerCheckInOut = false; 
  bool aparecerRecepcao = false;
  bool naoAparecerMapa = true;
  bool aparecerCheckIn = false;
  bool aparecerCheckOut = false;
  bool aparecerGarcom = true;

  bool botoesAparecerem = true;

  static final ValueNotifier<bool> isConnected = ValueNotifier(false);
  // final variaveis = Get.find<VariaveisController>();

  String numeroTradepointSelecionada = "";
  String numeroUsuario = "";

  // Variáveis  para lógica de pizza 
  List<dynamic> listaSaboresPizza = [];
  // List<dynamic> listaTamanhosPizza = [];
  // List<dynamic> listaSaboresBordasPizza = [];
  List<dynamic> listaSaboresPizzaDentroDoGrupo = [];
  // List<dynamic> listaGruposPizza = [];
  List<dynamic> listaSaboresPrecoPizzaDentroDoGrupo = [];
  List<dynamic> listaSaboresPrecoPizzaDentroDoTamanhoNoGrupo = [];
  String tamanhoSelecionadoNaPage = '';
  String tamanhoDaPizza = '';
  String numeroTamanhoPizza = '';

  bool configurarPizza = true;
  bool terminarPizza = false;

  // Primeira view - configurarPizza = true;
  final TextEditingController numeroPizzaBordaSelecionadoController = TextEditingController();
  final FocusNode numeroPizzaBordaSelecionadoFocus = FocusNode();
  final TextEditingController quantidadePizzaBordaSelecionadoController = TextEditingController();
  final FocusNode quantidadePizzaBordaSelecionadoFocus = FocusNode();
  final TextEditingController observacaoSaborSelecionadoController = TextEditingController();
  final FocusNode observacaoSaborSelecionadoFocus = FocusNode();
  final TextEditingController cardapioController = TextEditingController();
  final FocusNode cardapioFocus = FocusNode();

  // Segunda view - terminarPizza = true;
  final TextEditingController observacaoPizzaController = TextEditingController();
  final FocusNode observacaoPizzaFocus = FocusNode();
  final TextEditingController quantidadePizzaController = TextEditingController();
  final FocusNode quantidadePizzaFocus = FocusNode();
  int quantidadeInicialPizza = 1;

  List<Produto> listaSaboresSelecionados = [];
  List<Produto> listaBordasSelecionadas = [];
  List<Produto> listaSaboresBordasSelecionados = [];

  // Variáveis para abrirSelecaoGrupoProduto();
  bool mostrarGrupos = true;
  bool mostrarSabores = false;

  bool aparecerLista = false;
  bool aparecerSaboresBordas = true;
  bool aparecerCardapio = true;

  bool showKeyboardAlfa = false;
  bool showKeyboardNumero = false;

  String campoAtivo = "";

  // Lista para buscar sabores de pizza
  List<dynamic> listaSaboresPrecoPizzaDentroDoGrupoFiltrada = [];

  String valorDoProdutoSelecionado = "";
  String idDoProdutoSelecionado = "";
  String diversidadeSabores = "";
  String diversidadeSaboresNaPage = "";
  String diversidadeSaboresNoVisual = "";

  bool podeTrocarTamanho = false;
  String numeroProdutoTamanhoPizza = "";

  final FuncoesController funcoesController = Get.find<FuncoesController>();
  final PainelController painelController = Get.find<PainelController>();
  final ItemPizzaGrafico itemPizzaGraficoController = Get.find<ItemPizzaGrafico>();

  bool editarPizza = false;

  bool modoTouch = false; 
  bool modoCarrinho = true;
  String grupoSelecionadoNoTouch = "";

  int posicaoUltimoGrupo = 0;


  @override
  void initState() {
    super.initState();

    painelController.estaNoPainelCozinha.value = false;

    // Inicializa o controller da animação
    animationController = AnimationController(
      duration: Duration(milliseconds: 3000),
      vsync: this,
    );

    // Define o tipo da animação
    scaleAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.elasticOut,
    );

    // conectarBanco();
    _atualizarHora();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _atualizarHora();
    });
    _focusNode.addListener(() {
      if (!mounted) return;
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
    _carregarNote();
    _carregarModo();
    _carregarServidor();
    _loadServidor();
    _loadComanda();
    _loadNomeEmpresa();
    _carregarModos();
    _carregarRecepcao();
    _carregarchecks();
    _carregargarcom();
    _loadNumeroLicenca();
    _loadNumeroGarcom();
    arrumaVazioComanda();
    arrumarVazioMesa();
    carregarTamanhoSelecionado();
    limparView();

    // Busca para lógica pizza 
    /* buscarTamanhosPizza();
    buscarSaboresBordasPizza();
    buscarGruposPizza();
 */
    // Entrar em foco no campo de cardapio
   /*  Future.delayed(Duration(milliseconds: 200), () {
      if (cardapioFocus.canRequestFocus) {
        cardapioFocus.requestFocus();
      }
    }); */
    
    Future.delayed(Duration(milliseconds: 300), () {
      verificarEdicao();
    });

    itemPizzaGraficoController.listaSabores.clear();
    itemPizzaGraficoController.listaBordas.clear();

  }

  void entrarModoTouch(){
    setState(() {
      modoTouch = true;
      modoCarrinho = false;
      numeroPizzaBordaSelecionadoController.text = "";
      cardapioController.text = "";
      valorDoProdutoSelecionado = "";
      idDoProdutoSelecionado = "";
    });

    _selecionarPrimeiroGrupo();

    /* Future.delayed(Duration(milliseconds: 200), () {
      cardapioFocus.unfocus();
    }); */

    // logica anterior
    /* setState(() {
      mostrarGrupos = true;
      mostrarSabores = false;
    });
    abrirSelecaoGrupoProduto(); */
  }

  void sairModoTouch(){
    setState(() {
      modoTouch = false;
      modoCarrinho = true;
    });
  }

  /// Seleciona automaticamente o primeiro grupo disponível e carrega seus produtos.
  void _selecionarPrimeiroGrupo() {
    if (funcoesController.listaGruposPizza.isEmpty) return;

    final primeiro = funcoesController.listaGruposPizza.first;
    setState(() {
      grupoSelecionadoNoTouch = primeiro['numero'].toString();
      listaSaboresPrecoPizzaDentroDoTamanhoNoGrupo = produtosPorGrupo(grupoSelecionadoNoTouch);
    });
  }

  void _selecionarUltimoGrupo() {
    if (funcoesController.listaGruposPizza.isEmpty) return;

    final ultimo = funcoesController.listaGruposPizza[posicaoUltimoGrupo];
    setState(() {
      grupoSelecionadoNoTouch = ultimo['numero'].toString();
      listaSaboresPrecoPizzaDentroDoTamanhoNoGrupo = produtosPorGrupo(grupoSelecionadoNoTouch);
    });
  } 

  void _guardarUltimoGrupoPosicao(int posicao){
    posicaoUltimoGrupo = posicao;
  }

  void verificarEdicao() {
    if (editar) {
      editarPizza = true;
      if(produtoSelecionado != null) {
        preencherCampos(produtoSelecionado!);
      }
    } else {
      editarPizza = false;
      Future.delayed(Duration(milliseconds: 200), () {
        if (cardapioFocus.canRequestFocus) {
          cardapioFocus.requestFocus();
        }
      });
    }
  }

  void preencherCampos(Produto produto) {
    Future.delayed(Duration(milliseconds: 300), () {
      if (cardapioFocus.hasFocus) {
        cardapioFocus.unfocus();
      }
    });

    quantidadePizzaController.text = produto.quantidade.toString();
    observacaoPizzaController.text = produto.observacaoEscrita;

    listaSaboresSelecionados.clear();
    listaBordasSelecionadas.clear();
    listaSaboresBordasSelecionados.clear();

    for (var adicional in produto.adicionais) {
      if (adicional.id == 'P') {
        listaSaboresSelecionados.add(adicional);
        listaSaboresBordasSelecionados.add(adicional);
      } else if (adicional.id == 'B') {
        listaBordasSelecionadas.add(adicional);
        listaSaboresBordasSelecionados.add(adicional);
      }
    }

    _atualizarGrafico();
    
    setState(() {
      if (listaSaboresSelecionados.isNotEmpty || listaBordasSelecionadas.isNotEmpty) {
        configurarPizza = true;
        aparecerCardapio = true;
        mostrarGrupos = false;
        aparecerSaboresBordas = true;
      }
    });
  }

  void _atualizarGrafico() {
    // 1) Limpa o que já existe
    itemPizzaGraficoController.listaSabores.clear();
    itemPizzaGraficoController.listaBordas.clear();

    // 2) Adiciona os sabores selecionados
    for (var sabor in listaSaboresSelecionados) {
      itemPizzaGraficoController.listaSabores.add(
        ItemPizzaGrafico(
          nome: sabor.nome,
          quantidade: sabor.quantidade.toDouble(),
          id: sabor.id,
        ),
      );
    }

    // 3) Adiciona as bordas selecionadas
    for (var borda in listaBordasSelecionadas) {
      itemPizzaGraficoController.listaBordas.add(
        ItemPizzaGrafico(
          nome: borda.nome,
          quantidade: borda.quantidade.toDouble(),
          id: borda.id,
        ),
      );
    }
  }

  void limparView() {
    setState(() {
      // ── Seleções da pizza ───────────────────────────────────────────────
      listaSaboresSelecionados.clear();
      listaBordasSelecionadas.clear();

      // ── Controllers de texto ────────────────────────────────────────────
      comandaController.clear();
      cardapioController.clear();
      observacaoPizzaController.clear();
      quantidadePizzaController.clear();
      observacaoSaborSelecionadoController.clear();
      numeroPizzaBordaSelecionadoController.clear();
      quantidadePizzaBordaSelecionadoController.clear();

      // ── Estado de configuração da pizza ─────────────────────────────────
      configurarPizza = true;
      terminarPizza = false;
      mostrarGrupos = true;
      mostrarSabores = false;
      aparecerLista = false;
      aparecerSaboresBordas = true;
      aparecerCardapio = true;
      quantidadeInicialPizza = 1;

      // ── Variáveis de validação ──────────────────────────────────────────
      validaComanda.clear();
      numeroDoPedido = '';
      valorTotalLiquido = '';
      statusPedido = '';
      mensagem = 'Insira o número da comanda';
      corMensagem = true;
      iconeMensagem = true;
      animacaoAparecer = false;

      // ── Valores do produto selecionado ──────────────────────────────────
      valorDoProdutoSelecionado = '';
      idDoProdutoSelecionado = '';
      diversidadeSabores = '';
      diversidadeSaboresNaPage = '';
      diversidadeSaboresNoVisual = '';
      numeroProdutoTamanhoPizza = '';

      // ── Keyboard ────────────────────────────────────────────────────────
      showKeyboardAlfa = true;
      showKeyboardNumero = false;
      campoAtivo = 'cardapioController';
    });
  }

  // Função para carregar tamanho selecionado
  void carregarTamanhoSelecionado() async {
    setState(() {
      tamanhoSelecionadoNaPage = tamanhoSelecionado;
    });
    await buscarNumeroTamanhoPizza(tamanhoSelecionadoNaPage);
    await buscarSaboresPrecoPizzaDentroDoTamanho(numeroTamanhoPizza);
    await verificarQuantidadeSabores(diversidadeSaboresNaPage, tamanhoSelecionadoNaPage);
    setState(() {
      diversidadeSaboresNaPage = diversidadeSabores;
    });
  }

  // Função que verifica a quantidade de sabores e bordas selecionados pela quantidade de sabores
  verificarQuantidadeSabores(String diversidadeSaboresSelect, String nomeTamanho) {
    int diversidadeSabores = int.tryParse(diversidadeSaboresSelect) ?? 1;

    // Verifica se a quantidade atual de sabores ou bordas ultrapassa o limite do novo tamanho
    bool ultrapassouBordas = listaBordasSelecionadas.length > diversidadeSabores;
    bool ultrapassouSabores = listaSaboresSelecionados.length > diversidadeSabores;

    setState(() {
      if (ultrapassouBordas || ultrapassouSabores) {
        // Se ultrapassar, não permite trocar o tamanho
        podeTrocarTamanho = false;
      } else {
        // Se estiver dentro do limite (menor ou igual), permite trocar
        podeTrocarTamanho = true;
        diversidadeSaboresNaPage = diversidadeSaboresSelect;
        tamanhoSelecionadoNaPage = nomeTamanho;
      }
    });
  }

  // Função para arrumar vazio da comanda
  void arrumaVazioComanda(){
    if(comandaDoPedido == ""){
      comandaDoPedidoParaInsert = "0";
    } 
    else if (comandaDoPedido != ""){
      comandaDoPedidoParaInsert = comandaDoPedido;
    } else {
      comandaDoPedidoParaInsert = comandaDoPedido;   
    }
  }

  // Função para arrumar vazio da mesa
  void arrumarVazioMesa(){
    if(mesaDoPedido == ""){
      mesaDoPedidoParaInsert = "0";
    } 
    else if (mesaDoPedido != ""){
      mesaDoPedidoParaInsert = mesaDoPedido;
    } else {
      mesaDoPedidoParaInsert = mesaDoPedido;   
    }
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
  // Carregar modo 
  Future<void> _carregarModos() async {
    final prefs = await SharedPreferences.getInstance();
    final modoJson = prefs.getString('modo_padrao');

    if (modoJson != null) {
      final modosSalvos = Set<String>.from(jsonDecode(modoJson));

      if (modosSalvos.contains("Mesa") && !modosSalvos.contains("Comanda")) {
        setState(() {
          aparecerCheckInOut = false;
        });
      } else if (modosSalvos.contains("Mesa") && modosSalvos.contains("Comanda")) {
        setState(() {
          aparecerCheckInOut = true;
        });
      } else if (!modosSalvos.contains("Mesa") && modosSalvos.contains("Comanda")) {
        setState(() {
          aparecerCheckInOut = true;
        });
      } else if(!modosSalvos.contains("Mesa") && !modosSalvos.contains("Comanda")){
          setState(() {
            naoAparecerMapa = true;
            aparecerCheckInOut = false;
          });
      }
      else {
        setState(() {
          aparecerCheckInOut = true;
        });
      }

    } else {
      setState(() {
        // Se não tiver nada salvo, define padrão
        aparecerCheckInOut = true;
      });
    }
  }

  // Carregar check 
  Future<void> _carregarchecks() async {
    final prefs = await SharedPreferences.getInstance();
    final checkJson = prefs.getString('check_padrao');

    if (checkJson != null) {
      final checksSalvos = Set<String>.from(jsonDecode(checkJson));

      if (checksSalvos.contains("Ckeck-in") && !checksSalvos.contains("Check-out")) {
        setState(() {
          aparecerCheckIn = true;
          aparecerCheckOut = false;
        });
      } else if (checksSalvos.contains("Check-out") && !checksSalvos.contains("Ckeck-in")) {
        setState(() {
          aparecerCheckIn = false;
          aparecerCheckOut = true;
        });
      } else if (!checksSalvos.contains("Ckeck-in") && !checksSalvos.contains("Check-out")) {
        setState(() {
          aparecerCheckIn = false;
          aparecerCheckOut = false;
        });
      } else if(checksSalvos.contains("Ckeck-in") && checksSalvos.contains("Check-out")){
          setState(() {
            aparecerCheckIn = true;
            aparecerCheckOut = true;
          });
      }
      else {
        setState(() {
          aparecerCheckIn = true;
          aparecerCheckOut = true;
        });
      }

    } else {
      setState(() {
        // Se não tiver nada salvo, define padrão
        aparecerCheckIn = true;
        aparecerCheckOut = true;
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

      if (notesSalvos.contains('Notes')) { // se note selecionado
        setState(() {
          aparecerNote = true;
        });
      } else { // se note nao selecionado
        setState(() {
          aparecerNote = false;
        });
      }

    } else { // configuração padrao 
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

      if (recepcaosSalvos.contains('Recepção')) { // se recepcao selecionado
        setState(() {
          aparecerRecepcao = true;
        });
      } else { // se recepcao nao selecionado
        setState(() {
          aparecerRecepcao = false;
        });
      }

    } else { // configuração padrao 
      setState(() {
        aparecerRecepcao = false;
      });
    }
  }

  // FUNÇÃO PARA BUSCAR TAXA DE SERVIÇO
  Future<String> configuracaoServico() async {

    String valor = "0";

    try {
      String dadosJson = await Connection().select(
        "SELECT resultado FROM configuracoes WHERE numero='3';",
      );  

      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        valor = lista[0]['resultado'].toString();
        setState(() {
          valor = lista[0]['resultado'].toString();
        });
      } else {
        setState(() {
          valor =  "0"; 
        });
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
      setState(() {
        valor = "0";
      });      
    }

    return valor;
  }

  // Função para fazer fechar pedido
  Future<void> zerarAtendimento() async {
    String sql =
        """
      UPDATE cartoes 
      SET 
        atendimento = '0'
      WHERE atendimento = '$numeroTradepointSelecionada';
      UPDATE mesas 
      SET 
        atendimento = '0'
      WHERE atendimento = '$numeroTradepointSelecionada';
    """;
    try {
      String resultado = await Connection().ipd(sql);

      if (resultado == 'sucesso') {
        print("Atendimento zerado");
      } else {
        print("Erro ao zerar atendiemnto: $resultado");
      }
    } catch (e) {
      print("Erro inesperado ao atualizar cartão: $e");
    }
  }

  void _atualizarHora() {
    if (!mounted) return;
    final agora = DateTime.now();
    final horaFormatada = DateFormat.Hm().format(agora);
    setState(() {
      _horaAtual = horaFormatada;
    });
    _loadComanda();
  }

  @override
  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    _timerApagar?.cancel();
    _focusNode.dispose();
    animationController.dispose();
    super.dispose();
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

  // Salavr comanda 
  Future<void> saveComanda(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('comanda', value);
  }

  Future<void> _loadComanda() async {
    final prefs = await SharedPreferences.getInstance();
    final comandaSalva = prefs.getString('comanda');
    if (comandaSalva != null) {
      setState(() {
        comandaNumero = comandaSalva;
        comandaRegistrada = true;
      });
    }
  }

  // Pegar numero do garçom
  Future<void> _loadNumeroGarcom() async {
    final prefs = await SharedPreferences.getInstance();
    var numeroGarcomSalvo = prefs.getString('numeroGarcom');
    if (numeroGarcomSalvo != null) {
      setState(() {
        numeroUsuario = numeroGarcomSalvo;
      });
    }
  }

  // PEGAR O MODO SALVO
  Future<String?> getModoSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('modo_padrao');
  }

  Future<void> _carregarModo() async {
    final prefs = await SharedPreferences.getInstance();
    final modo = prefs.getString('modo_padrao');
    // print("Modo carregado: $modo");
    setState(() {
      if (modo == "Comanda") {
        comandas = false;
      } else if (modo == "Mesa") {
        comandas = true;
      }
    });
  }

  // Carregar servidor
  Future<void> _carregarServidor() async {
    final prefs = await SharedPreferences.getInstance();
    final servidorSalvo = prefs.getString('servidor');
    // print('Servidor carregado: $servidorSalvo'); // Log para ver o valor carregado
    if (servidorSalvo != null) {
      setState(() {
        servidorController.text =
            servidorSalvo; // Atualiza o controller com o valor carregado
      });
    }
  }

  // Servidor
  Future<void> _saveServidor(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('servidor', value);
  }

  Future<void> _loadServidor() async {
    final prefs = await SharedPreferences.getInstance();
    final servidorSalvo = prefs.getString('servidor');
    print('Servidor carregado: $servidorSalvo'); // Adicione este log
    if (servidorSalvo != null) {
      setState(() {
        servidorController.text = servidorSalvo;
      });
    }
  }

  // Função para inserir texto com teclado Alfa
  _inserirTextoNoTecladoAlfa(
    TextEditingController controller,
    String valor, [
    Function(String)? validador,
  ]) {
    HapticFeedback.lightImpact();
    final newText = controller.text + valor;

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    if (validador != null) validador(controller.text);
  }

  // Função para adicionar no teclado alfanumérico 
  _adicionarTeclaNoTecladoAlfa(tecla) {
    /* setState(() {
      switch(campoAtivo){
        case 'observacaoSaborSelecionadoController':
           _inserirTextoNoTecladoAlfa(
            observacaoSaborSelecionadoController,
            tecla,
          );
        break;
        case 'cardapioController':
           _inserirTextoNoTecladoAlfa(
            cardapioController,
            tecla,
            (newText) => filtrarSabores(newText),
          );
          setState(() {
            configurarPizza = false;
            aparecerCardapio = true;
            aparecerLista = true;
            aparecerSaboresBordas = false;
            showKeyboardAlfa = true;
            showKeyboardNumero = false;
          });
        break;
        case 'observacaoPizzaController':
           _inserirTextoNoTecladoAlfa(
            observacaoPizzaController,
            tecla,
          );
        break;
      }
    }); */
  }

  // Função para fechat teclado no teclado Alfanumérico
  void _fecharTecladoNoTecladoAlfa() {
    setState(() {
      showKeyboardAlfa = false;
    /*   aparecerLista = false;
      configurarPizza = true; */
      FocusScope.of(context).unfocus(); // Esconde o teclado e remove o foco
    });
  }

  // Função para o check do teclado alfanumérico
  void _confirmarNoTecladoAlfa() {
    setState(() {
      showKeyboardAlfa = false;
      aparecerLista = false;
      configurarPizza = true;
      FocusScope.of(context).unfocus(); // Esconde o teclado e remove o foco
    });
  }

  // Função para remover último caractere no teclado alfa
  void _removerUltimoCaractereNoTecladoAlfa(
    TextEditingController controller, [
    Function(String)? validador,
  ]) {
    if (controller.text.isEmpty) return;
    final newText = controller.text.substring(0, controller.text.length - 1);
    controller.text = newText;
    if(campoAtivo == 'cardapioController'){
      filtrarSabores(newText);
    }
    if (validador != null) validador(newText);
  }

  // Função para apagar no teclado alfanumérico
  _apagarNoTecladoAlfa() {
    setState(() {
      /* switch(campoAtivo){
        case 'observacaoSaborSelecionadoController':
           _removerUltimoCaractereNoTecladoAlfa(
            observacaoSaborSelecionadoController,
          );
        break;
        case 'cardapioController':
           _removerUltimoCaractereNoTecladoAlfa(
            cardapioController,
            filtrarSabores(cardapioController.text)
          );
        break;
        case 'observacaoPizzaController':
           _removerUltimoCaractereNoTecladoAlfa(
            observacaoPizzaController
          );
        break;
      } */
    });
  }

  _apagarVariosNoTecladoAlfa() {
    /* switch (campoAtivo) {
      case 'observacaoSaborSelecionadoController':
        final texto = observacaoSaborSelecionadoController.text;

        if (texto.isEmpty) return;

        int tamanhoAtual = texto.length;

        // Decide quantos caracteres remover
        int numCaracteresRemover = tamanhoAtual <= 3 ? 2 : 3;

        // GARANTIA: nunca deixar índice negativo
        int novoTamanho = tamanhoAtual - numCaracteresRemover;
        if (novoTamanho <= 0) {
          observacaoSaborSelecionadoController.clear();
          return;
        }
        observacaoSaborSelecionadoController.text = texto.substring(0, novoTamanho);
        // Mantém o cursor no final
        observacaoSaborSelecionadoController.selection = TextSelection.fromPosition(
          TextPosition(offset: observacaoSaborSelecionadoController.text.length),
        );
        break;

      case 'cardapioController':
        final texto = cardapioController.text;

        if (texto.isEmpty) return;

        int tamanhoAtual = texto.length;

        // Decide quantos caracteres remover
        int numCaracteresRemover = tamanhoAtual <= 3 ? 2 : 3;

        // GARANTIA: nunca deixar índice negativo
        int novoTamanho = tamanhoAtual - numCaracteresRemover;
        if (novoTamanho <= 0) {
          cardapioController.clear();
          return;
        }
        cardapioController.text = texto.substring(
          0,
          novoTamanho,
        );
        // Mantém o cursor no final
        cardapioController.selection =
            TextSelection.fromPosition(
              TextPosition(
                offset: cardapioController.text.length,
              ),
            );
      break;
      case 'observacaoPizzaController':
        final texto = observacaoPizzaController.text;

        if (texto.isEmpty) return;

        int tamanhoAtual = texto.length;

        // Decide quantos caracteres remover
        int numCaracteresRemover = tamanhoAtual <= 3 ? 2 : 3;

        // GARANTIA: nunca deixar índice negativo
        int novoTamanho = tamanhoAtual - numCaracteresRemover;
        if (novoTamanho <= 0) {
          observacaoPizzaController.clear();
          return;
        }
        observacaoPizzaController.text = texto.substring(
          0,
          novoTamanho,
        );
        // Mantém o cursor no final
        observacaoPizzaController.selection =
            TextSelection.fromPosition(
              TextPosition(
                offset: observacaoPizzaController.text.length,
              ),
            );
      break;
    } */
  }

  // Função para apagar vários no teclado Alfa
  _iniciarApagarNoTecladoAlfa() {
    _timerApagar = Timer.periodic(Duration(milliseconds: 300), (_) {
      _apagarVariosNoTecladoAlfa();
    });
  }

  // Função para parar de apagar Alfa
  _pararApagarNoTecladoAlfa() {
    _timerApagar?.cancel();
  }

  // Apaga o último caractere
  void _removerUltimoCaractere(TextEditingController controller) {
    if (controller.text.isEmpty) return;
    final newText = controller.text.substring(0, controller.text.length - 1);
    controller.text = newText;
  }

  // Função para apagar último número
  void _apagarNumero(){
    HapticFeedback.lightImpact();
    setState(() {
      /* switch (campoAtivo) {
        // Quantidade controller 
        case 'quantidadePizzaBordaSelecionadoController':
          _removerUltimoCaractere(quantidadePizzaBordaSelecionadoController);
        break;
      } */
    });
  }

  // Inserir texto
  void _inserirTexto(TextEditingController controller, String valor) {
    final newText = controller.text + valor;

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  // Função nova para adicionar número
  void _adicionarNumero(String valor) {
    HapticFeedback.lightImpact();
    setState(() {
     /*  switch (campoAtivo) {
        // Quantidade controller 
        case 'quantidadePizzaBordaSelecionadoController':
          _inserirTexto(quantidadePizzaBordaSelecionadoController, valor);
        break;
      } */
    });
  }

  // Confirmar no teclado numérico 
  void _confirmar() async {
    HapticFeedback.lightImpact();

  }

  // Função para filtrar produtos
  filtrarSabores(String termo) {
    setState(() {
      aparecerLista = true;

      if (termo.isEmpty) {
        listaSaboresPrecoPizzaDentroDoGrupoFiltrada =
            listaSaboresPrecoPizzaDentroDoGrupo;

        // ORDENA ALFABETICAMENTE
        listaSaboresPrecoPizzaDentroDoGrupoFiltrada.sort((a, b) {
          final nomeA = a['Sabor'].toString().toLowerCase();
          final nomeB = b['Sabor'].toString().toLowerCase();

          aparecerLista = false;
          aparecerSaboresBordas = true;
          configurarPizza = true;
          return nomeA.compareTo(nomeB);
        });

      } else {
        aparecerLista = true;
        aparecerSaboresBordas = false;
        configurarPizza = false;

        listaSaboresPrecoPizzaDentroDoGrupoFiltrada = listaSaboresPrecoPizzaDentroDoGrupo.where((produto) {
        final nome = produto['Sabor'].toString().toLowerCase();
        final busca = termo.toLowerCase();

        return nome.startsWith(busca);
      }).toList();

        // ORDENA ALFABETICAMENTE
        listaSaboresPrecoPizzaDentroDoGrupoFiltrada.sort((a, b) {
          final nomeA = a['Sabor'].toString().toLowerCase();
          final nomeB = b['Sabor'].toString().toLowerCase();

          return nomeA.compareTo(nomeB);
        });
      }
    });
  }
  /* filtrarSabores(String termo) {  // listaSaboresPrecoPizzaDentroDoGrupo
    setState(() {
      aparecerLista = true;
      if (termo.isEmpty) {
        listaSaboresPrecoPizzaDentroDoGrupoFiltrada = listaSaboresPrecoPizzaDentroDoGrupo;
      } else {
        if(termo.length > 1){
          aparecerLista = true;
        } else {
          aparecerLista = false;
        }
        listaSaboresPrecoPizzaDentroDoGrupoFiltrada = listaSaboresPrecoPizzaDentroDoGrupo.where((produto) {
          final nome = produto['Sabor'].toString().toLowerCase();
          final busca = termo.toLowerCase();

          return nome.startsWith(busca);
        }).toList();
      }
    });
  } */

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

  // Select dos sabores de pizza 
  Future<void> buscarSaboresPizza(String numeroGrupoSelecionado) async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numerovenda, nome FROM sabores WHERE numerogrupo_FK = '$numeroGrupoSelecionado' AND ativo='1';",
      );  

      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        listaSaboresPizza = lista;
        setState(() {
          listaSaboresPizza = lista;
        });
      } else {
        setState(() {
          listaSaboresPizza =  [];
        });
      }
    } catch (e) {
      print("Erro ao carregar buscarSaboresPizza: $e");
      setState(() {
        listaSaboresPizza = [];
      });      
    }
  }

  /* // Selectama dos tamanhos de pizza
  Future<void> buscarTamanhosPizza() async {
    try {
      /* String dadosJson = await Connection().select(
        "SELECT numeroproduto_FK, nome, diversidadesabores FROM tamanhopizza WHERE ativo = '1' ORDER BY nome;",
      );   */
      String dadosJson = await Connection().select(
         """
        SELECT 
          g.numero AS grupo_numero,
          g.nome   AS grupo_nome,
          pr.numero AS produto_numero,
          pr.nome   AS produto_nome,
          pr.valor  AS produto_valor,
          pr.id AS produto_id
        FROM produtos AS pr
        JOIN grupos AS g 
          ON g.numero = pr.numerogrupocardapio_FK
        WHERE g.mobile = '1' AND pr.id = 'PZ';
        """,
      );  

      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        listaTamanhosPizza = lista;
        setState(() {
          listaTamanhosPizza = lista;
        });
      } else {
        setState(() {
          listaTamanhosPizza =  [];
        });
      }
    } catch (e) {
      print("Erro ao carregar buscarTamanhosPizza: $e");
      setState(() {
        listaTamanhosPizza = [];
      });      
    }
  } 

  // Select dos sabores e bordas de pizza 
  Future<void> buscarSaboresBordasPizza() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, nome, numerovenda, id FROM sabores WHERE ativo='1' ORDER BY nome;",
      );  

      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        listaSaboresBordasPizza = lista;
        setState(() {
          listaSaboresBordasPizza = lista;
        });
      } else {
        setState(() {
          listaSaboresBordasPizza =  [];
        });
      }
    } catch (e) {
      print("Erro ao carregar buscarSaboresBordasPizza: $e");
      setState(() {
        listaSaboresBordasPizza = [];
      });      
    }
  }

  // Select para buscar grupos da pizza 
  Future<void> buscarGruposPizza() async {
    try {
     /*   String dadosJson = await Connection().select(
        "SELECT numeroproduto_FK, nome, diversidadesabores FROM tamanhopizza WHERE ativo = '1' ORDER BY nome;",
      );   */
      String dadosJson = await Connection().select(
        "SELECT numero, nome FROM grupos WHERE id = 'PZ';",
      );  

      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        listaGruposPizza = lista;
        setState(() {
          listaGruposPizza = lista;
        });
      } else {
        setState(() {
          listaGruposPizza =  [];
        });
      }
    } catch (e) {
      print("Erro ao carregar buscarSaboresBordasPizza: $e");
      setState(() {
        listaGruposPizza = [];
      });      
    }
  } */

  // Select do número do tamanho da pizza 
  Future<void> buscarNumeroTamanhoPizza(String nomeTamanho) async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, numeroproduto_FK, diversidadesabores FROM tamanhopizza WHERE nome ='$nomeTamanho';",
      );  

      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        String valor = lista[0]['numero'].toString();
        String valor2 = lista[0]['diversidadesabores'].toString();
        String valor3 = lista[0]['numeroproduto_FK'].toString();
        await verificarQuantidadeSabores(valor2, nomeTamanho);
        if(podeTrocarTamanho){
          setState(() {
            numeroTamanhoPizza = valor;
            diversidadeSabores = valor2;
            numeroProdutoTamanhoPizza = valor3;
          });
        } else {
         
        }
      } else {
        setState(() {
          numeroTamanhoPizza =  '';
          diversidadeSabores = '';
        });
      }
    } catch (e) {
      print("Erro ao carregar buscarNumeroTamanhoPizza: $e");
      setState(() {
        numeroTamanhoPizza = '';
        diversidadeSabores = '';
      });      
    }
  }

  // Buscar sabor de pizza em determinado grupo
  Future<void> buscarSaboresPizzaDentroDoGrupo() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, nome, numerovenda, valorsabor, id, (SELECT nome FROM grupos WHERE numero = numerogrupo_FK), numerogrupo_FK FROM sabores WHERE ativo='1' ORDER BY nome;",
      );  

      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        listaSaboresPizzaDentroDoGrupo = lista;
        setState(() {
          listaSaboresPizzaDentroDoGrupo = lista;
        });
      } else {
        setState(() {
          listaSaboresPizzaDentroDoGrupo =  [];
        });
      }
    } catch (e) {
      print("Erro ao carregar buscarSaboresPizzaDentroDoGrupo: $e");
      setState(() {
        listaSaboresPizzaDentroDoGrupo = [];
      });      
    }
  }

  // Selecionar nome e preço do sabor, pelo tamanho 
  Future<void> buscarSaboresPrecoPizzaDentroDoTamanho(String numeroTamanhoSelecionado) async {
    try {
      String dadosJson = await Connection().select(
        """
          SELECT
            s.nome AS Sabor,
            t.nome AS Tamanho,
            s.numero AS NumeroSabor,
            s.numerogrupo_FK AS Grupo,
            s.id AS IdSabor,
            CASE t.numero
                WHEN 1 THEN s.valor1
                WHEN 2 THEN s.valor2
                WHEN 3 THEN s.valor3
                WHEN 4 THEN s.valor4
                WHEN 5 THEN s.valor5
                WHEN 6 THEN s.valor6
                WHEN 7 THEN s.valor7
                WHEN 8 THEN s.valor8
                WHEN 9 THEN s.valor9
                WHEN 10 THEN s.valor10
                WHEN 11 THEN s.valor11
                WHEN 12 THEN s.valor12
                WHEN 13 THEN s.valor13
                WHEN 14 THEN s.valor14
                WHEN 15 THEN s.valor15
                WHEN 16 THEN s.valor16
                WHEN 17 THEN s.valor17
                WHEN 18 THEN s.valor18
                WHEN 19 THEN s.valor19
                WHEN 20 THEN s.valor20
                WHEN 21 THEN s.valor21
                WHEN 22 THEN s.valor22
                WHEN 23 THEN s.valor23
                WHEN 24 THEN s.valor24
                WHEN 25 THEN s.valor25
                WHEN 26 THEN s.valor26
                WHEN 27 THEN s.valor27
                WHEN 28 THEN s.valor28
                WHEN 29 THEN s.valor29
                WHEN 30 THEN s.valor30
                ELSE 0
            END AS Preco_Final
        FROM
            sabores s,
            tamanhopizza t
        WHERE
            t.numero = '$numeroTamanhoSelecionado';
        """,
      );  

      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        listaSaboresPrecoPizzaDentroDoGrupo = lista;
        listaSaboresPrecoPizzaDentroDoGrupoFiltrada = lista;
        print(listaSaboresPrecoPizzaDentroDoGrupoFiltrada);
        setState(() {
          listaSaboresPrecoPizzaDentroDoGrupo = lista;
          listaSaboresPrecoPizzaDentroDoGrupoFiltrada = lista;
        });
      } else {
        setState(() {
          listaSaboresPrecoPizzaDentroDoGrupo =  [];
        });
      }
    } catch (e) {
      print("Erro ao carregar buscarSaboresPizzaDentroDoGrupo: $e");
      setState(() {
        listaSaboresPrecoPizzaDentroDoGrupo = [];
      });      
    }
  }

  // Lista que vincula tipos de sabores e sabores
  List<dynamic> produtosPorGrupo(String numeroGrupoSelecionadoFunc) {
    List<dynamic> lista = listaSaboresPrecoPizzaDentroDoGrupo.where((produto) {
      return produto['Grupo'].toString() == numeroGrupoSelecionadoFunc;
    }).toList();
    print(lista);
    return lista;
  }

  // buscarSaboresPrecoPizzaDentroDoTamanhoNoGrupo
  Future<void> buscarSaboresPrecoPizzaDentroDoTamanhoNoGrupo(String numeroTamanhoSelecionado, String numeroGrupoSelecionado) async {
    try {
      String dadosJson = await Connection().select(
        """
          SELECT
            s.nome AS Sabor,
            t.nome AS Tamanho,
            s.numerovenda AS NumeroSabor,
            s.id AS IdSabor,
            CASE t.numero
                WHEN 1 THEN s.valor1
                WHEN 2 THEN s.valor2
                WHEN 3 THEN s.valor3
                WHEN 4 THEN s.valor4
                WHEN 5 THEN s.valor5
                WHEN 6 THEN s.valor6
                WHEN 7 THEN s.valor7
                WHEN 8 THEN s.valor8
                WHEN 9 THEN s.valor9
                WHEN 10 THEN s.valor10
                WHEN 11 THEN s.valor11
                WHEN 12 THEN s.valor12
                WHEN 13 THEN s.valor13
                WHEN 14 THEN s.valor14
                WHEN 15 THEN s.valor15
                WHEN 16 THEN s.valor16
                WHEN 17 THEN s.valor17
                WHEN 18 THEN s.valor18
                WHEN 19 THEN s.valor19
                WHEN 20 THEN s.valor20
                WHEN 21 THEN s.valor21
                WHEN 22 THEN s.valor22
                WHEN 23 THEN s.valor23
                WHEN 24 THEN s.valor24
                WHEN 25 THEN s.valor25
                WHEN 26 THEN s.valor26
                WHEN 27 THEN s.valor27
                WHEN 28 THEN s.valor28
                WHEN 29 THEN s.valor29
                WHEN 30 THEN s.valor30
                ELSE 0
            END AS Preco_Final
        FROM
            sabores s
            JOIN tamanhopizza t
            JOIN grupos g ON g.numero = s.numerogrupo_FK
        WHERE
            t.numero = '$numeroTamanhoSelecionado' AND
            s.numerogrupo_FK = '$numeroGrupoSelecionado';
        """,
      );  

      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        listaSaboresPrecoPizzaDentroDoTamanhoNoGrupo = lista;
        setState(() {
          listaSaboresPrecoPizzaDentroDoTamanhoNoGrupo = lista;
        });
      } else {
        setState(() {
          listaSaboresPrecoPizzaDentroDoTamanhoNoGrupo =  [];
        });
      }
    } catch (e) {
      print("Erro ao carregar buscarSaboresPizzaDentroDoGrupo: $e");
      setState(() {
        listaSaboresPrecoPizzaDentroDoGrupo = [];
      });      
    }
  }

  // Função com op up para selecionar tamanho da Pizza 
  void popupSelecionarTamanho() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Align(
            alignment: Alignment.center,
            child: Text(
              "Selecione tamanho da pizza",
              style: TextStyle(
                fontSize: 20, // ou qualquer outro estilo que desejar
              ),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: funcoesController.listaTamanhosPizza.isEmpty
              ? Center(child: Text("Nenhum tamanho encontrado"))
              : ListView.builder(
                  itemCount: funcoesController.listaTamanhosPizza.length,
                  itemBuilder: (context, index) {
                    final tamanho = funcoesController.listaTamanhosPizza[index];

                    return Card(
                      child: ListTile(
                        title: Text(tamanho['produto_nome']),
                        // subtitle: Text("Número: ${garcom['numero']}"),
                        onTap: () async {
                          tamanhoDaPizza = tamanho['produto_nome'].toString();
                          numeroTamanhoPizza = tamanho['produto_numero'].toString();
                          /* diversidadeSaboresNaPage = tamanho['diversidadesabores'].toString(); */
                          await buscarNumeroTamanhoPizza(tamanhoDaPizza);
                  
                          if(!podeTrocarTamanho){
                            showErrorDialog(
                              context: context,
                              title: "Não foi possível trocar tamanho da pizza",
                              message: "Os sabores ou bordas ultrapassam a quantidade permitida para o tamanho selecionado",
                              icon: Icons.error, // você pode trocar para outro ícone
                              onConfirm: () async {
                                setState(() {
                                  podeTrocarTamanho = false;
                                  tamanhoSelecionadoNaPage = tamanhoSelecionadoNaPage;
                                });
                                // await buscarGruposPizza();
                                // await buscarSaboresBordasPizza();
                              },
                            );
                          } else {
                            Navigator.pop(context);
                            tamanhoSelecionadoNaPage = tamanhoDaPizza;
                            carregarTamanhoSelecionado();
                          }
                          // await verificarQuantidadeSabores(diversidadeSaboresNaPage, tamanhoDaPizza);
                          setState(() {
                            mostrarGrupos = true;
                            mostrarSabores = false;
                          });
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
    );
  }

  // Função para configurar pizza
  funcaoConfigurarPizza(String numero, String nome, String valor, String id) {
    // Atualiza os controladores fora do setState
    numeroPizzaBordaSelecionadoController.text = numero;
    cardapioController.text = nome;

    setState(() {
      valorDoProdutoSelecionado = valor;
      idDoProdutoSelecionado = id;
      configurarPizza = true;
      terminarPizza = false;
      showKeyboardAlfa = false;
    });
  }

  // Função para configurar quantidade
  String formatarFracaoQuantidade({ // função que recebe int e devolve String
    required double quantidadeItem, //recebe a quantidade desde item
    required double quantidadeTotal, //recebe a quantidade total
  }) {
    if (quantidadeTotal <= 0) return '0'; // Se o total for 0 ou negativo, não dá pra fazer conta nenhuma

    if (quantidadeItem == quantidadeTotal) { // Se este for o único item, devolve 1
      return '1';
    }

    return '${quantidadeItem.toInt()}/${quantidadeTotal.toInt()}'; // Se não for o único item, devolve a fração
  }


  // Função para adicionar produto ao carrinho
  adicionarProdutoLista(
    String produtoNome,
    String produtoValor,
    String produtoNumero,
    double produtoQuantidade,
    String observacaoEscrita,
    String idDoProdutoSelecionado
  ) {
    // Escolhe a lista correta para verificar se o produto já existe
    final List<Produto> listaParaVerificar = idDoProdutoSelecionado == 'P'
        ? listaSaboresSelecionados
        : listaBordasSelecionadas;

    // Função que verifica se já existe este produto
    final int indexExistente = listaParaVerificar.indexWhere((produto) {
      return produto.numero == produtoNumero &&
          produto.preco == produtoValor &&
          observacaoEscrita == produto.observacaoEscrita;
    });

    if (indexExistente != -1) {
      // Se já existe, atualiza a quantidade na lista específica
      listaParaVerificar[indexExistente].quantidade += produtoQuantidade;

      // E atualiza também na lista geral (listaSaboresBordasSelecionados)
      final int indexGeral = listaSaboresBordasSelecionados.indexWhere((produto) {
        return produto.numero == produtoNumero &&
            produto.preco == produtoValor &&
            observacaoEscrita == produto.observacaoEscrita;
      });
      
      if (indexGeral != -1) {
        listaSaboresBordasSelecionados[indexGeral].quantidade += produtoQuantidade;
      }
    } else {
      // Se não existe, verifica os limites antes de adicionar
      int diversidadeMaxima = int.tryParse(diversidadeSabores) ?? 1;

      if (idDoProdutoSelecionado == 'P' && listaSaboresSelecionados.length >= diversidadeMaxima) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Você pode adicionar apenas $diversidadeMaxima sabores'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        limparCamposPizza();
        return;
      }

      // Limite de bordas é a mesma diversidade de sabores
      if (idDoProdutoSelecionado == 'B' && listaBordasSelecionadas.length >= diversidadeMaxima) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Você pode adicionar apenas $diversidadeMaxima borda'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        limparCamposPizza();
        return;
      }

      // Adiciona na lista geral
      listaSaboresBordasSelecionados.add(
        Produto(
          nome: produtoNome,
          preco: produtoValor,
          numero: produtoNumero,
          quantidade: produtoQuantidade,
          observacaoEscrita: observacaoEscrita,
          id: idDoProdutoSelecionado,
        ),
      );

      // Adiciona na lista específica
      if (idDoProdutoSelecionado == 'P') {
        listaSaboresSelecionados.add(
          Produto(
            nome: produtoNome,
            preco: produtoValor,
            numero: produtoNumero,
            quantidade: produtoQuantidade,
            observacaoEscrita: observacaoEscrita,
            id: idDoProdutoSelecionado
          ),
        );
      } else if (idDoProdutoSelecionado == 'B') {
        listaBordasSelecionadas.add(
          Produto(
            nome: produtoNome,
            preco: produtoValor,
            numero: produtoNumero,
            quantidade: produtoQuantidade,
            observacaoEscrita: observacaoEscrita,
            id: idDoProdutoSelecionado
          ),
        );
      }
    }
    limparCamposPizza();
  }

  // Função para remover produto da lista 
  void removerProdutoLista(
    String produtoNumero,
    String produtoValor,
    int produtoQuantidade,
    String observacaoEscrita,
    String idDoProdutoSelecionado,
  ) {
    // Lista específica (sabores ou bordas)
    final List<Produto> listaParaRemover = idDoProdutoSelecionado == 'P' ? listaSaboresSelecionados : listaBordasSelecionadas;

    // REMOVE / ATUALIZA LISTA ESPECÍFICA
    final int indexEspecifico = listaParaRemover.indexWhere((produto) {
      return produto.numero == produtoNumero &&
          produto.preco == produtoValor &&
          produto.observacaoEscrita == observacaoEscrita;
    });

    if (indexEspecifico != -1) {
      listaParaRemover[indexEspecifico].quantidade -= produtoQuantidade;

      if (listaParaRemover[indexEspecifico].quantidade <= 0) {
        listaParaRemover.removeAt(indexEspecifico);
      }
    }

    // REMOVE / ATUALIZA LISTA GERAL
    final int indexGeral = listaSaboresBordasSelecionados.indexWhere((produto) {
      return produto.numero == produtoNumero &&
          produto.preco == produtoValor &&
          produto.observacaoEscrita == observacaoEscrita;
    });

    if (indexGeral != -1) {
      listaSaboresBordasSelecionados[indexGeral].quantidade -= produtoQuantidade;

      if (listaSaboresBordasSelecionados[indexGeral].quantidade <= 0) {
        listaSaboresBordasSelecionados.removeAt(indexGeral);
      }
    }

    limparCamposPizza();
  }

  // Função para limpar campos
  void limparCamposPizza() {
    cardapioController.clear();
    valorDoProdutoSelecionado = '';
    numeroPizzaBordaSelecionadoController.clear();
    quantidadePizzaController.clear();
    quantidadePizzaBordaSelecionadoController.clear();
    observacaoSaborSelecionadoController.clear();
    setState(() {
      configurarPizza = false;
      terminarPizza = false;
      showKeyboardAlfa = false;
      showKeyboardNumero = false;
    });
  }

 // Lista que vincula produtos e grupo
  List<dynamic> saboresPorGrupo(String idDoGrupo) {
    return listaSaboresPizza.where((produto) {
      return produto['grupo_numero'].toString() == idDoGrupo;
    }).toList();
  }

  // Função que monta lista para visualição de grupos e produtos
  void abrirSelecaoGrupoProduto() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String? grupoSelecionado;
            return Container(
              padding: EdgeInsets.all(12),
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Center(
                    child: Text(
                      mostrarGrupos
                          ? 'Selecione um grupo'
                          : 'Selecione um sabor',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(height: 12),

                  // Lista de grupos
                  Expanded(
                    child: mostrarGrupos
                        ? ListView.builder(
                            itemCount: funcoesController.listaGruposPizza.length,
                            itemBuilder: (context, index) {
                              final grupo = funcoesController.listaGruposPizza[index];
                              return GestureDetector(
                                onTap: () async {
                                  final numeroGrupoSelecionado = grupo['numero'].toString();
                                  listaSaboresPrecoPizzaDentroDoTamanhoNoGrupo = produtosPorGrupo(numeroGrupoSelecionado);
                                  // await buscarSaboresPrecoPizzaDentroDoTamanhoNoGrupo(numeroTamanhoPizza, numeroGrupoSelecionado);
                                  setModalState(() {
                                    grupoSelecionado = grupo['numero'].toString();
                                    mostrarGrupos = false;
                                    mostrarSabores = true;
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      grupo['nome'],
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        // Lista de produtos
                        // Se a lista dos produtos não estiver vazia 
                        : listaSaboresPrecoPizzaDentroDoTamanhoNoGrupo.isNotEmpty ? 
                        ListView.builder(
                            itemCount: listaSaboresPrecoPizzaDentroDoTamanhoNoGrupo.length,
                            itemBuilder: (context, index) {
                              final sabor = listaSaboresPrecoPizzaDentroDoTamanhoNoGrupo[index];
                              final numero = sabor['NumeroSabor'];
                              final nome = sabor['Sabor'];
                              final valor = sabor['Preco_Final'];
                              final id = sabor['IdSabor'];
                              return  GestureDetector(
                                // Quando clicar em um produto
                                onTap: () async {
                                  if(valor == '0.00'){
                                    showErrorDialog(
                                      context: context,
                                      title: "Sabor indisponível",
                                      message: "O sabor $nome não está disponível para o tamanho selecionado",
                                      icon: Icons.error,
                                      onConfirm: () async {
                                        setState(() {
                                          mostrarGrupos = false;
                                          mostrarSabores = true;
                                        });
                                      },
                                    );
                                  } else {
                                    sairModoTouch();
                                    setState(() {
                                      configurarPizza = true;
                                      terminarPizza = false;
                                      aparecerLista = false;
                                      aparecerSaboresBordas = true;
                                      funcaoConfigurarPizza(numero, nome, valor, id);
                                      mostrarGrupos = true;
                                      mostrarSabores = false;
                                      Future.delayed(Duration(milliseconds: 300), () {
                                        if (quantidadePizzaBordaSelecionadoFocus.canRequestFocus) {
                                          quantidadePizzaBordaSelecionadoFocus.requestFocus();
                                        }
                                      });
                                    });
                                  }
                                },
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child:
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: valor != '0.00'
                                            ? Text(
                                                nome,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              )
                                            : Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    nome,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Theme.of(context).colorScheme.onSurface,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Sabor indisponível para este tamanho',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Theme.of(context).colorScheme.onSurface,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                      Text(
                                        valor != '0.00'
                                            ? 'R\$ $valor'
                                            : 'R\$ -.--',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ) : 
                          // Se estiver vazia 
                          Center(
                            child: Text(
                              'Não há sabores para este grupo'
                            ),
                          ),
                  ),

                  // Botão voltar para grupos
                  if (mostrarSabores)
                    IconButton(
                      onPressed: () {
                        setModalState(() {
                          mostrarSabores = false;
                          mostrarGrupos = true;
                        });
                      },
                      icon: Icon(Icons.arrow_back, size: 40),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Dialogo com dois botões de alerta
  // Dialogo com dois botões de erro
  Future<void> shownDialogaAlertTwoBottom({
    required BuildContext context,
    String title = 'Confirmação',
    String? message,
    IconData icon = Icons.home,
    String cancelText = 'Cancelar',
    String confirmText = 'Continuar',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
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
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícone central
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(ctx).colorScheme.scrim.withOpacity(0.08),
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
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

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

                    // Campo de texto opcional
                    if (textController != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 15.0),
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: textController,
                          focusNode: focusNode,
                          onSubmitted: onSubmitted,
                          autofocus: focusNode != null,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: 'Digite aqui...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                      ),

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
                              backgroundColor: Theme.of(ctx).colorScheme.scrim,
                              minimumSize: Size(100, 48),
                            ),
                            child: Text(
                              cancelText.toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(ctx).colorScheme.onPrimary,
                                fontSize: 13,
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
                              backgroundColor: Theme.of(ctx).colorScheme.primary,
                              minimumSize: Size(100, 48),
                            ),
                            child: Text(
                              confirmText.toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(ctx).colorScheme.onPrimary,
                                fontSize: 13,
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
  }

  // Dialogo com dois botões de erro
  Future<void> shownDialogErrorTwoBottom({
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
                    color: Theme.of(ctx).colorScheme.error.withOpacity(0.08),
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

  Widget _buildPizzaVisual({
    required List<ItemPizzaGrafico> sabores,
    required List<ItemPizzaGrafico> bordas,
  }) {
    if (sabores.isEmpty && bordas.isEmpty) {
      return Container();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final tamanho = min(
          (constraints.maxWidth),
          (constraints.maxHeight),
        ) * 0.70;

        /* return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Padding 
            if(sabores.isNotEmpty)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Sabores", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
              ],
            ),

            // Grafico 
            Center(
              child: SizedBox(
                width: tamanho,
                height: tamanho,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // BORDA - ANEL EXTERNO
                    if (bordas.isNotEmpty)
                    SizedBox(
                      width: tamanho,
                      height: tamanho,
                      child: PieChart(
                        PieChartData(
                          startDegreeOffset: 180,
                          sectionsSpace: 1,
                          /* centerSpaceRadius: tamanho * 0.32, */
                          centerSpaceRadius: 0,
                          sections: itemPizzaGraficoController.criarSecoes(
                            bordas,
                            tamanho * 0.47,
                            mostrarTexto: false,
                          ),
                        ),
                      ),
                    ),
            
                    // SABORES - PARTE INTERNA
                    if (sabores.isNotEmpty)
                    SizedBox(
                      width: tamanho * 0.80,
                      height: tamanho * 0.80,
                      child: PieChart(
                        PieChartData(
                          startDegreeOffset: -90,
                          sectionsSpace: 2,
                          // centerSpaceRadius: tamanho * 0.16,
                          centerSpaceRadius: 0,
                          sections: itemPizzaGraficoController.criarSecoes(
                            sabores,
                            tamanho * 0.40,
                            mostrarTexto: false,
                          ),
                        ),
                      ),
                    ),
            
                    /* // CENTRO
                    Container(
                      width: tamanho * 0.30,
                      height: tamanho * 0.30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context)
                            .colorScheme
                            .surface,
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'PIZZA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ), */
                  ],
                ),
              ),
            ),

            // Padding 
            if(bordas.isNotEmpty)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Bordas", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),)
              ],
            ),
          ],
        ); */

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // LEGENDA
           /*  if (sabores.isNotEmpty || bordas.isNotEmpty)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /* if (sabores.isNotEmpty) ...[
                      Text(
                        'Sabores',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),

                      ...sabores.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;

                        final cor = itemPizzaGraficoController.obterCorPizza(index);

                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: cor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Expanded(
                                  child: Text(
                                    item.nome ?? '',
                                    maxLines: 2,
                                    style: const TextStyle(fontSize: 11),
                                    // overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ], */

                  /*   if (bordas.isNotEmpty) ...[
                      SizedBox(height: 10),

                      Text(
                        'Bordas',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),

                      ...bordas.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;

                        final cor = itemPizzaGraficoController.obterCorBorda(index);

                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: cor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6),
                              Flexible(
                                child: Expanded(
                                  child: Text(
                                    item.nome ?? '',
                                    maxLines: 2,
                                    style: TextStyle(fontSize: 11),
                                    // overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ), */ */

            // GRÁFICO
            SizedBox(
              width: tamanho,
              height: tamanho,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // BORDA - ANEL EXTERNO
                  if (bordas.isNotEmpty)
                    SizedBox(
                      width: tamanho,
                      height: tamanho,
                      child: PieChart(
                        PieChartData(
                          startDegreeOffset: 90,
                          sectionsSpace: 1,
                          // centerSpaceRadius: 0,
                          centerSpaceRadius: tamanho * 0.23,
                          sections: itemPizzaGraficoController.criarSecoes(
                            bordas,
                            /* tamanho * 0.47, */
                            tamanho * 0.30,
                            mostrarTexto: false,
                            textoForaDoGrafico: true,
                          ),
                        ),
                      ),
                    ),

                  // SABORES - PARTE INTERNA
                  if (sabores.isNotEmpty)
                    SizedBox(
                      width: tamanho * 0.80,
                      height: tamanho * 0.80,
                      child: PieChart(
                        PieChartData(
                          startDegreeOffset: -90,
                          sectionsSpace: 2,
                          centerSpaceRadius: 0,
                          sections: itemPizzaGraficoController.criarSecoes(
                            sabores,
                            tamanho * 0.50,
                            mostrarTexto: true,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Dialogo de erro um botão -- vermelho
  Future<void> showErrorDialog({
    required BuildContext context,
    String title = 'Confirmação',
    required String message,
    IconData icon = Icons.home,
    String cancelText = 'Não',
    String confirmText = 'Sim',
    VoidCallback? onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false, // não pode fechar tocando fora
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
                    color: Theme.of(ctx).colorScheme.error.withOpacity(0.08),
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

                SizedBox(height: 5),

                // Texto centralizado
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w400),
                ),

                SizedBox(height: 10),

                // Botões centralizados
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Confirmar
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
                        backgroundColor: Theme.of(ctx).colorScheme.error,
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

  void desfocarTeclado() {
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    void desfocarTodosOsCampos() {
      cardapioFocus.unfocus();
      quantidadePizzaBordaSelecionadoFocus.unfocus();
      observacaoSaborSelecionadoFocus.unfocus();
      observacaoPizzaFocus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final orientation = MediaQuery.of(context).orientation;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          desfocarTeclado();
          if (FocusManager.instance.primaryFocus != null) {
            FocusManager.instance.primaryFocus?.unfocus();
            FocusScope.of(context).unfocus();
            return;
          }
          
          Navigator.of(context).pop();
          // Aqui você pode executar outra ação,
          // caso o teclado já esteja fechado.
        },
        child: Scaffold(
            resizeToAvoidBottomInset: false,
            drawer: SideNav(),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(56),
            child: Obx(() {   // este Obx cuida APENAS do que realmente depende de conexão
              final conectado = Connection.connectionStatus.value;
              return AppBar(
                backgroundColor: conectado ? colorScheme.primary : colorScheme.error,
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
                         /*  Obx(() => Text(
                            variaveis.nomeEmpresa.value,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimary,
                            ),
                          )), */
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
          // Corpo da tela
          body: Stack(
            children: [
              Column(
                children: [
                  // Detalhes do pedidio 
                  Container(
                    height: MediaQuery.of(context).size.height * 0.07,
                    color: colorScheme.tertiary,
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onTap: () {
                              if(configurarPizza){
                                Get.offAllNamed('/garcom',
                                  arguments: {
                                    'numeropedido': numeroDoPedidoArgs,
                                    'comanda': comandaDoPedido,
                                    'mesa': mesaDoPedido,
                                    'clienteId': clienteIdArgs,
                                    'clienteNome': clienteNomeArgs,
                                    'clienteCpf': clienteCpfArgs,
                                    'clienteTelefone': clienteTelefoneArgs,
                                    'clienteDataNascimento': clienteDataNascimentoArgs,
                                  },
                                );
                              } else if (terminarPizza){
                                setState(() {
                                  terminarPizza = false;
                                  configurarPizza = true;
                                  aparecerCardapio = true;
                                  aparecerLista = false;
                                  showKeyboardAlfa = false;
                                  showKeyboardNumero = false;
                                });
                              } else {
                                Get.offAllNamed('/garcom',
                                  arguments: {
                                    'numeropedido': numeroDoPedidoArgs,
                                    'comanda': comandaDoPedido,
                                    'mesa': mesaDoPedido,
                                    'clienteId': clienteIdArgs,
                                    'clienteNome': clienteNomeArgs,
                                    'clienteCpf': clienteCpfArgs,
                                    'clienteTelefone': clienteTelefoneArgs,
                                    'clienteDataNascimento': clienteDataNascimentoArgs,
                                  },
                                );
                              }
                            },
                            child: Icon(
                                Icons.arrow_back,
                                color: colorScheme.onPrimary,
                                size: 30,
                              ),
                          ),
                        ),
                        Expanded(child: Container()),
                        Center(
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  popupSelecionarTamanho();
                                },
                                child: Text(
                                  tamanhoSelecionadoNaPage,
                                  style: TextStyle(
                                      color: colorScheme.onPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ),
                              IconButton(
                                onPressed: (){
                                  popupSelecionarTamanho();
                                }, 
                                icon: Icon(
                                  Icons.swap_vert,
                                  color: colorScheme.onPrimary,
                                )
                              ),
                            ],
                          ),
                          ),
                          Expanded(child: Container()),
                          if (listaSaboresSelecionados.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (terminarPizza && !configurarPizza) {
                                    final produtoNome = tamanhoSelecionadoNaPage;
                                    final produtoNumero = numeroProdutoTamanhoPizza;
                                    final quantidadeInicial = double.tryParse(quantidadePizzaController.text) ?? 1;
                                    final produtoObservacao = observacaoPizzaController.text;
                                    final adicionais = listaSaboresBordasSelecionados;
                                    double produtoValor = 0.0;
        
                                    if(editarPizza) {
                                      carrinhoController.editarProdutoAoCarrinho(
                                        index,
                                        produtoNome,
                                        produtoValor.toString(),
                                        produtoNumero,
                                        quantidadeInicial,
                                        produtoObservacao,
                                        'PZ',
                                        adicionais: adicionais,
                                        observacoesTexto: [],
                                      );
                                    } else {
                                      carrinhoController.adicionarProdutoAoCarrinho(
                                        produtoNome,
                                        produtoValor.toString(),
                                        produtoNumero,
                                        quantidadeInicial,
                                        produtoObservacao,
                                        'PZ',
                                        adicionais: adicionais,
                                      );
                                    }
        
                                    Get.offAllNamed('/garcom',
                                      arguments: {
                                        'numeropedido': numeroDoPedidoArgs,
                                        'comanda': comandaDoPedido,
                                        'mesa': mesaDoPedido,
                                        'clienteId': clienteIdArgs,
                                        'clienteNome': clienteNomeArgs,
                                        'clienteCpf': clienteCpfArgs,
                                        'clienteTelefone': clienteTelefoneArgs,
                                        'clienteDataNascimento': clienteDataNascimentoArgs,
                                      },
                                    );
                                    return;
                                  }
        
                                  if (listaSaboresSelecionados.isNotEmpty) {
                                    sairModoTouch();
                                    setState(() {
                                      terminarPizza = true;
                                      aparecerCardapio = false;
                                      configurarPizza = false;
                                      quantidadePizzaController.text = "1";
                                      campoAtivo = 'observacaoPizzaController';
                                      showKeyboardAlfa = true;
                                      showKeyboardNumero = false;
                                      aparecerLista = false;
                                      aparecerSaboresBordas = true;
                                    });
                                    // Navegação mantendo um estado de transição sem travar 
                                    /* Future.delayed(Duration(milliseconds: 300), () {
                                      if (observacaoPizzaFocus.canRequestFocus) {
                                        observacaoPizzaFocus.requestFocus();
                                      }
                                    }); */
                                    Future.delayed(Duration(milliseconds: 300), () {
                                      if (observacaoPizzaFocus.hasFocus) {
                                        observacaoPizzaFocus.unfocus();
                                      }
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.all(5),
                                  elevation: 5,
                                  minimumSize: Size(45, 45),
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 30,
                                ),
                              ),
                            ),
                        ],
                      )
                    ),
              
                    // Cardapio 
                    if(aparecerCardapio)
                    Padding(
                      padding: EdgeInsets.only(left: 8,right: 8, top: 0,bottom: 0,),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 0,right: 0, top: 0,bottom: 0,),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Ícone do cardápio
                                Padding(
                                  padding: EdgeInsets.only(left: 8,right: 0, top: 14,bottom: 0,),
                                  child: Column(
                                    children: [
                                        IconButton(
                                        icon: Icon(
                                          modoTouch ? Icons.local_pizza : Icons.fingerprint,
                                          // size: 30,
                                          color: modoTouch ? colorScheme.onTertiary : colorScheme.onTertiary,
                                        ),
                                        onPressed: () async {
                                          if(modoTouch){
                                            sairModoTouch();
                                          } else {
                                            entrarModoTouch();
                                          }
                                        },
                                        style: IconButton.styleFrom(
                                          backgroundColor: modoTouch ? colorScheme.scrim : colorScheme.shadow,
                                          padding: EdgeInsets.all(10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        modoTouch ? 'Carrinho' : 'Touch',
                                        style: TextStyle(
                                          color:modoTouch ? colorScheme.scrim : colorScheme.shadow,
                                          fontWeight: FontWeight.bold
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                      
                                SizedBox(width: 5,),
                            
                                // Campo de busca expandido
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: TextField(
                                      onTap: () async {
                                        // await buscarSaboresPrecoPizzaDentroDoTamanho(numeroTamanhoPizza);
                                        setState(() {
                                          campoAtivo = 'cardapioController';
                                          aparecerLista = false;
                                          aparecerSaboresBordas = true;
                                          configurarPizza = true;
                                          terminarPizza = false;
                                          showKeyboardAlfa = false;
                                          showKeyboardNumero = false;
                                        });
                                      },
                                      onChanged: (text) {
                                        filtrarSabores(text);
                                      },
                                      readOnly: false, // impede digitação pelo teclado nativo
                                      showCursor: true, // FORÇA o cursor piscando
                                      cursorColor: Theme.of(context).colorScheme.primary,
                                      keyboardType: TextInputType.text, // garante que o teclado não abra
                                      controller: cardapioController,
                                      focusNode: cardapioFocus,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        hintText: "Digite o produto...",
                                        hintStyle: TextStyle(
                                          color: colorScheme.onSurface,
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surface,
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
              
                    if(aparecerLista)
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              // height: MediaQuery.of(context).size.height * 1,
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                // borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: colorScheme.primary),
                              ),
                              child: ListView.builder(
                                // itemCount: listaSaboresPrecoPizzaDentroDoGrupo.length, // listaSaboresPrecoPizzaDentroDoGrupoFiltrada
                                itemCount: listaSaboresPrecoPizzaDentroDoGrupoFiltrada.length,
                                itemBuilder: (context, index) {
                                  /* final sabores = listaSaboresPrecoPizzaDentroDoGrupo[index]; */
                                  final sabores = listaSaboresPrecoPizzaDentroDoGrupoFiltrada[index];
                                  final numero = sabores['NumeroSabor'];
                                  final nome = sabores['Sabor'];
                                  final valor = sabores['Preco_Final'];
                                  final id = sabores['IdSabor'];
                                  return InkWell(
                                    // quando eu clilcar no produto filtrado
                                    onTap: () async {
                            
                                      aparecerLista = false;
                                      if(valor == '0.00'){
                                        showErrorDialog(
                                          context: context,
                                          title: "Sabor indisponível",
                                          message: "O sabor $nome não está disponível para o tamanho selecionado",
                                          icon: Icons.error,
                                          onConfirm: () async {
                                            setState(() {
                                              mostrarGrupos = false;
                                              mostrarSabores = true;
                                            });
                                          },
                                        );
                                      } else {
                                        await funcaoConfigurarPizza(numero, nome, valor, id);
                                        setState(() {
                                          aparecerLista = false;
                                          configurarPizza = true;
                                          terminarPizza = false;
                                          showKeyboardAlfa = false;
                                          aparecerSaboresBordas = true;
                                          
                                          campoAtivo = 'quantidadePizzaBordaSelecionadoController';
                                          Future.delayed(Duration(milliseconds: 300), () {
                                            if (quantidadePizzaBordaSelecionadoFocus.canRequestFocus) {
                                              quantidadePizzaBordaSelecionadoFocus.requestFocus();
                                            }
                                          });
        
                                          showKeyboardNumero = true;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 14,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: colorScheme.primary.withOpacity(0.2),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              valor != '0.00'
                                                  ? sabores['Sabor']
                                                  : 'Sabor ${sabores['Sabor']} indisponível para este tamanho',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                              fontSize: 15,
                                              color: colorScheme.onSurface,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
        
                                        SizedBox(width: 8),
        
                                        Text(
                                          valor != '0.00'
                                              ? 'R\$ ${sabores['Preco_Final']}'
                                              : 'R\$ -.--',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: colorScheme.onSurface,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      ],
                                    ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          // Botão para voltar ao carrinho 
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  aparecerLista = false;
                                  aparecerCardapio = true;
                                  aparecerSaboresBordas = true;
                                  configurarPizza = true;
                                });
                                sairModoTouch();
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                child: Row(
                                  children: [
                                    Icon(Icons.arrow_back, color: colorScheme.primary),
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          'Voltar ao carrinho',
                                          style: TextStyle(color: colorScheme.primary),
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.arrow_back, color: colorScheme.onPrimary),
                                  ],
                                ),
                              ),
                            )
                          ),
                        ],
                      ),
                    ),
              
                    // Configuração da pizza 
                    if(configurarPizza && modoCarrinho)
                    Padding(
                    padding: EdgeInsets.only(left: 8, right: 8, top: 0, bottom: 0,),
                    child: Container(
                      padding: EdgeInsets.only(left: 8, right: 8, top: 0, bottom: 0,),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          //COLUNA ESQUERDA
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                // PRIMEIRA LINHA
                                Row(
                                  children: [
                                    // Número da pizza ou borda 
                                    Expanded(
                                      child: TextField(
                                        controller: numeroPizzaBordaSelecionadoController,
                                        readOnly:true, // impede digitação pelo teclado nativo
                                        showCursor: false, // FORÇA o cursor piscando
                                        // cursorColor: Theme.of(context,).colorScheme.onSurface,
                                        keyboardType: TextInputType.none, // garante que o teclado não abra
                                        decoration: InputDecoration(
                                        hintText: 'N° ou Cod.B',
                                          filled: true,
                                          fillColor: Colors.grey.shade300,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8,),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
              
                                    // Quantidade
                                    Expanded(
                                      child: KeyboardActions(
                                        disableScroll: true,
                                        autoScroll: false,
                                        config: KeyboardActionsConfig(
                                          keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
                                          nextFocus: false,
                                          actions: [
                                            KeyboardActionsItem(
                                              focusNode: quantidadePizzaBordaSelecionadoFocus,
                                              toolbarButtons: [
                                                (node) {
                                                  return GestureDetector(
                                                    onTap: () {
                                                      node.unfocus();
                                                    },
                                                    child: Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 16),
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
                                          controller: quantidadePizzaBordaSelecionadoController,
                                          readOnly: false, // impede digitação pelo teclado nativo
                                          showCursor:true, // FORÇA o cursor piscando
                                          cursorColor: Theme.of(context,).colorScheme.onSurface,
                                          keyboardType: TextInputType.number, // garante que o teclado não abra
                                          focusNode: quantidadePizzaBordaSelecionadoFocus,
                                          onTap: () {
                                            setState(() {
                                              campoAtivo = 'quantidadePizzaBordaSelecionadoController';
                                              showKeyboardAlfa = false;
                                              showKeyboardNumero = true;
                                              Future.delayed(Duration(milliseconds: 300), () {
                                                if (quantidadePizzaBordaSelecionadoFocus.canRequestFocus) {
                                                  quantidadePizzaBordaSelecionadoFocus.requestFocus();
                                                }
                                              });
                                            });
                                          },
                                          decoration: InputDecoration(
                                            hintText: 'Qtde.',
                                            filled: true,
                                            fillColor: Colors.grey.shade300,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8,),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
              
                                SizedBox(height: 8),
              
                                // SEGUNDA LINHA
                                Row(
                                  children: [
                                    // Botão OBS
                                   /*  SizedBox(
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'OBS',
                                          style: TextStyle(
                                            color: colorScheme.onPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
              
                                    SizedBox(width: 8), */
              
                                    // Observação - TextField
                                    Expanded(
                                      child: TextField(
                                        controller: observacaoSaborSelecionadoController,
                                        focusNode: observacaoSaborSelecionadoFocus,
                                        onTap: () {
                                          setState(() {
                                            campoAtivo = 'observacaoSaborSelecionadoController';
                                            showKeyboardAlfa = true;
                                            showKeyboardNumero = false;
                                          });
                                        },
                                        readOnly: false, // impede digitação pelo teclado nativo
                                        showCursor: true, // FORÇA o cursor piscando
                                        cursorColor: Theme.of(context,).colorScheme.onSurface,
                                        keyboardType: TextInputType.text, // garante que o teclado não abra
                                        decoration: InputDecoration(
                                          hintText: 'Observação',
                                          filled: true,
                                          fillColor: Colors.grey.shade300,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8,),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
              
                          SizedBox(width: 8),
              
                          // COLUNA DIREITA
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 110,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if(cardapioController.text.isEmpty){
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Selecione um sabor'),
                                        backgroundColor: colorScheme.error,
                                      ),
                                    );
                                  } else {
                                    int produtoQuantidade = int.tryParse(quantidadePizzaBordaSelecionadoController.text) ?? 1;
                                    if(produtoQuantidade > 5){
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Você pode pedir até 5 partes para um mesmo sabor'),
                                          backgroundColor: colorScheme.error,
                                        ),
                                      );
                                      setState(() {
                                        configurarPizza = true;
                                        campoAtivo = "quantidadePizzaBordaSelecionadoController";
                                        Future.delayed(Duration(milliseconds: 300), () {
                                          if (quantidadePizzaBordaSelecionadoFocus.canRequestFocus) {
                                            quantidadePizzaBordaSelecionadoFocus.requestFocus();
                                          }
                                        });
                                        showKeyboardNumero = true;
                                        showKeyboardAlfa = false;
                                      });
                                    } else {
                                      final produtoNome = cardapioController.text;
                                      final produtoValor = valorDoProdutoSelecionado;
                                      final produtoNumero = numeroPizzaBordaSelecionadoController.text;
                                      final produtoQuantidade = quantidadePizzaBordaSelecionadoController.text;
                                      final observacaoEscrita = observacaoSaborSelecionadoController.text;
                                      if(produtoNome != ""){
                                        await adicionarProdutoLista(
                                          produtoNome,
                                          produtoValor,
                                          produtoNumero,
                                          double.tryParse(produtoQuantidade) ?? 1,
                                          observacaoEscrita,
                                          idDoProdutoSelecionado
                                        );
                                        await buscarSaboresPrecoPizzaDentroDoTamanho(numeroTamanhoPizza);
                                      }
                                      setState(() {
        
                                        campoAtivo = 'cardapioController';
                                        aparecerLista = false;
                                        aparecerSaboresBordas = true;
                                        configurarPizza = true;
                                        terminarPizza = false;
                                        showKeyboardAlfa = true;
                                        showKeyboardNumero = false;
                                        
                                      });
                                    }
                                  }
                                  _atualizarGrafico();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.tertiary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: colorScheme.onTertiary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              
                  if(terminarPizza)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // OBSERVAÇÃO
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: observacaoPizzaController,
                          focusNode: observacaoPizzaFocus,
                          onTap: () {
                            setState(() {
                              showKeyboardAlfa = true;
                              showKeyboardNumero = false;
                              campoAtivo = 'observacaoPizzaController';
                            });
                          },
                          readOnly: false,
                          showCursor: true,
                          cursorColor: colorScheme.primary,
                          cursorWidth: 2.5,
                          keyboardType: TextInputType.text,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: "Digite uma observação geral...",
                            filled: true,
                            fillColor: colorScheme.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: colorScheme.primary),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: colorScheme.primary, width: 2),
                            ),
                          ),
                        ),
                      ),
              
                     SizedBox(height: 8),
              
                      // CONTROLE DE QUANTIDADE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Botão -
                          IconButton(
                            icon: Icon(Icons.remove),
                            iconSize: 32,
                            color: colorScheme.primary,
                            onPressed: () {
                              if (quantidadeInicialPizza > 1) {
                                quantidadeInicialPizza--;
                                setState(() {
                                  quantidadePizzaController.text = quantidadeInicialPizza.toString();
                                });
                              }
                            },
                          ),
              
                          // Campo quantidade
                          Expanded(
                            child: SizedBox(
                              width: 80,
                              child: TextField(
                                controller: quantidadePizzaController,
                                focusNode: quantidadePizzaFocus,
                                readOnly: true,
                                showCursor: false,
                                keyboardType: TextInputType.none,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: colorScheme.surface,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: colorScheme.primary),
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
              
                          // Botão +
                          IconButton(
                            icon: Icon(Icons.add),
                            iconSize: 32,
                            color: colorScheme.primary,
                            onPressed: () {
                              quantidadeInicialPizza++;
                              setState(() {
                                quantidadePizzaController.text = quantidadeInicialPizza.toString();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
              
                  // Lista de sabores e bordas selecionadas 
                  if(aparecerSaboresBordas && (modoCarrinho || terminarPizza))
                  Expanded(
                    child: Column(
                      children: [
                        // Lista de sabores e bordas — altura fixa para ~4 itens
                        SizedBox(
                          // height: 236,
                          height: MediaQuery.of(context).size.height * 0.30,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                // COLUNA SABORES
                                Expanded(
                                  child: Column(
                                    children: [
                                      // Cabeçalho
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(vertical: 8),
                                        color: colorScheme.primary,
                                        child: Text(
                                          'SABORES',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                            
                                      // Lista de sabores
                                      Expanded(
                                        child: listaSaboresSelecionados.isEmpty
                                          ? SizedBox()
                                          : ListView.builder(
                                              itemCount: listaSaboresSelecionados.length,
                                              itemBuilder: (context, index) {
                                                final sabor = listaSaboresSelecionados[index];
                                                final double quantidadeTotalSabores = listaSaboresSelecionados.fold( // pega a lista de sabores selecionados e soma a quantidade de cada um
                                                  0,
                                                  (total, produto) => total + produto.quantidade,
                                                );
                                                return Card(
                                                  margin: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                  child: Padding(
                                                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                                    child: Padding(
                                                      padding: EdgeInsets.all(2.0),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          GestureDetector(
                                                            onTap: () async {
                                                              if(sabor.quantidade <= 1){
                                                                // aparecer aviso 
                                                                shownDialogErrorTwoBottom(
                                                                  context: context,
                                                                  title: "Excluir ${sabor.nome}?",
                                                                  message: "Deseja descartar ${sabor.nome} do pedido?",
                                                                  icon: Icons.shopping_cart,
                                                                  onConfirm: () async {
                                                                    removerProdutoLista(
                                                                      sabor.numero,
                                                                      sabor.preco,
                                                                      1,
                                                                      sabor.observacaoEscrita,
                                                                      sabor.id // ou 'B'
                                                                    );
                                                                    setState(() {
                                                                      configurarPizza = true;
                                                                      aparecerSaboresBordas = true;
                                                                    });
                                                                    _atualizarGrafico();
                                                                  },
                                                                  onCancel: () async {
                                                                    setState(() {
                                                                      configurarPizza = true;
                                                                      aparecerSaboresBordas = true;
                                                                    });
                                                                  },
                                                                );
                                                              } else {
                                                                removerProdutoLista(
                                                                  sabor.numero,
                                                                  sabor.preco,
                                                                  1,
                                                                  sabor.observacaoEscrita,
                                                                  sabor.id
                                                                );
                                                                setState(() {
                                                                  configurarPizza = true;
                                                                  aparecerSaboresBordas = true;
                                                                });
                                                              }
                                                              _atualizarGrafico();
                                                            },
                                                            child: Icon(
                                                              Icons.remove, 
                                                              size: 18,
                                                              color: colorScheme.error,
                                                            ),
                                                          ),
                                                          // Fração do sabor
                                                          Text(
                                                            formatarFracaoQuantidade(
                                                              quantidadeItem: sabor.quantidade,
                                                              quantidadeTotal: quantidadeTotalSabores,
                                                            ),
                                                             style: TextStyle(fontWeight: FontWeight.bold),
                                                          ),
                                                          SizedBox(width: 4),
                                                          // Nome do sabor sem observação
                                                          if(sabor.observacaoEscrita.isEmpty)
                                                          Flexible(
                                                            child: Text(
                                                              sabor.nome,
                                                              /*  style: TextStyle(fontWeight: FontWeight.bold), */
                                                            ),
                                                          ),
                                                          SizedBox(width: 4),
                                                          if(sabor.observacaoEscrita.isNotEmpty)
                                                          Expanded(
                                                            child: Align(
                                                              alignment: Alignment.centerLeft,
                                                              child: Column(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text(
                                                                    sabor.nome,
                                                                    /*  style: TextStyle(fontWeight: FontWeight.bold), */
                                                                  ),
                                                                  if(sabor.observacaoEscrita.isNotEmpty)
                                                                  Text(
                                                                    sabor.observacaoEscrita,
                                                                    style: TextStyle(fontSize: 10),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          GestureDetector(
                                                            onTap: () async {
                                                              final produtoNome = sabor.nome;
                                                              final produtoValor = sabor.preco;
                                                              final produtoNumero = sabor.numero;
                                                              final produtoQuantidade = 1.0;
                                                              final observacaoEscrita = sabor.observacaoEscrita;
                                                              if(produtoNome != ""){
                                                                await adicionarProdutoLista(
                                                                  produtoNome,
                                                                  produtoValor,
                                                                  produtoNumero,
                                                                  produtoQuantidade,
                                                                  observacaoEscrita,
                                                                  sabor.id
                                                                );
                                                                // await buscarSaboresPrecoPizzaDentroDoTamanho(numeroTamanhoPizza);
                                                                setState(() {
                                                                  configurarPizza = true;
                                                                  aparecerSaboresBordas = true;
                                                                });
                                                                _atualizarGrafico();
                                                              }
                                                            },
                                                            child: Icon(
                                                              Icons.add, 
                                                              size: 18,
                                                              color: colorScheme.primary,
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
                          
                                    SizedBox(width: 6),
                                
                                    // COLUNA BORDAS
                                    Expanded(
                                      child: Column(
                                        children: [
                                          // Cabeçalho
                                          Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.symmetric(vertical: 8),
                                            color: colorScheme.primary,
                                            child: Text(
                                              'BORDAS',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                
                                          // Lista de bordas
                                          Expanded(
                                            child: listaBordasSelecionadas.isEmpty
                                              ? SizedBox()
                                              : ListView.builder(
                                                  itemCount: listaBordasSelecionadas.length,
                                                  itemBuilder: (context, index) {
                                                    final borda = listaBordasSelecionadas[index];
                                                    final double quantidadeTotalBordas = listaBordasSelecionadas.fold(
                                                      0,
                                                      (total, produto) => total + produto.quantidade,
                                                    );
                                                    return Card(
                                                      margin: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                      child: Padding(
                                                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                                        child: Padding(
                                                          padding: EdgeInsets.all(2.0),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            crossAxisAlignment: CrossAxisAlignment.center,
                                                            children: [
                                                              GestureDetector(
                                                              onTap: () async {
                                                                if(borda.quantidade <= 1){
                                                                  shownDialogErrorTwoBottom(
                                                                    context: context,
                                                                    title: "Excluir ${borda.nome}?",
                                                                    message: "Deseja descartar ${borda.nome} do pedido?",
                                                                    icon: Icons.shopping_cart,
                                                                    onConfirm: () async {
                                                                      removerProdutoLista(
                                                                        borda.numero,
                                                                        borda.preco,
                                                                        1,
                                                                        borda.observacaoEscrita,
                                                                        'B', // ou 'B'
                                                                      );
                                                                      setState(() {
                                                                        configurarPizza = true;
                                                                        aparecerSaboresBordas = true;
                                                                      });
                                                                      _atualizarGrafico();
                                                                    },
                                                                    onCancel: () async {
                                                                      setState(() {
                                                                        configurarPizza = true;
                                                                        aparecerSaboresBordas = true;
                                                                      });
                                                                    },
                                                                  );
                                                                } else {
                                                                  removerProdutoLista(
                                                                    borda.numero,
                                                                    borda.preco,
                                                                    1,
                                                                    borda.observacaoEscrita,
                                                                    'B', // ou 'B'
                                                                  );
                                                                  setState(() {
                                                                    configurarPizza = true;
                                                                    aparecerSaboresBordas = true;
                                                                  });
                                                                }
                                                                _atualizarGrafico();
                                                              },
                                                              child: Icon(
                                                                Icons.remove, 
                                                                size: 18,
                                                                color: colorScheme.error,
                                                              ),
                                                            ),
                                                              Text(
                                                                formatarFracaoQuantidade(
                                                                  quantidadeItem: borda.quantidade,
                                                                  quantidadeTotal: quantidadeTotalBordas,
                                                                ),
                                                                style: TextStyle(fontWeight: FontWeight.bold),
                                                              ),
                                                              SizedBox(width: 4),
        
                                                              // SEM OBSERVAÇÃO
                                                              if (borda.observacaoEscrita.isEmpty)
                                                              Flexible(
                                                                child: Text(
                                                                  borda.nome,
                                                                ),
                                                              ),
        
                                                              SizedBox(width: 4),
        
                                                              // COM OBSERVAÇÃO
                                                              if (borda.observacaoEscrita.isNotEmpty)
                                                                Expanded(
                                                                  child: Align(
                                                                    alignment: Alignment.centerLeft,
                                                                    child: Column(
                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        Text(
                                                                          borda.nome,
                                                                        ),
                                                                        Text(
                                                                          borda.observacaoEscrita,
                                                                          style: const TextStyle(
                                                                            fontSize: 10,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                             /*  Expanded(
                                                                child: Column(
                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(
                                                                      borda.nome,
                                                                      style: TextStyle(fontSize: 14),
                                                                    ),
                                                                    if(borda.observacaoEscrita.isNotEmpty)
                                                                    Text(
                                                                      borda.observacaoEscrita,
                                                                      style: TextStyle(fontSize: 10),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ), */
                                                              GestureDetector(
                                                              onTap: () async {
                                                                final produtoNome = borda.nome;
                                                                final produtoValor = borda.preco;
                                                                final produtoNumero = borda.numero;
                                                                final produtoQuantidade = 1.0;
                                                                final observacaoEscrita = borda.observacaoEscrita;
                                                                if(produtoNome != ""){
                                                                  await adicionarProdutoLista(
                                                                    produtoNome,
                                                                    produtoValor,
                                                                    produtoNumero,
                                                                    produtoQuantidade,
                                                                    observacaoEscrita,
                                                                    'B'
                                                                  );
                                                                  // await buscarSaboresPrecoPizzaDentroDoTamanho(numeroTamanhoPizza);
                                                                  setState(() {
                                                                    configurarPizza = true;
                                                                    aparecerSaboresBordas = true;
                                                                  });
                                                                }
                                                                _atualizarGrafico();
                                                              },
                                                              child: Icon(
                                                                Icons.add, 
                                                                size: 18,
                                                                color: colorScheme.primary,
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
                                    ],
                                  ),
                                ),
                              ),
                              // GRAFICO PIZZA — centralizado no espaço restante
                              /* if((!cardapioFocus.hasFocus && !quantidadePizzaBordaSelecionadoFocus.hasFocus && !observacaoSaborSelecionadoFocus.hasFocus && modoCarrinho && !terminarPizza) 
                              || (terminarPizza && !observacaoPizzaFocus.hasFocus)) */
                              /* Expanded(
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 8.0, right: 8.0, top: 0.0, bottom: 8.0),
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: _buildPizzaVisual(bordas: itemPizzaGraficoController.listaBordas, sabores: itemPizzaGraficoController.listaSabores),
                                    ),
                                  ),
                                ),
                              ), */
                            ],
                          ),
                        ),
        
                        if(modoTouch && !aparecerLista)
                        Expanded(
                          child: LayoutBuilder(
                          builder: (context, boxConstraints) {
                            // Largura proporcional: grupos ~20%, produtos o restante
                            final double totalWidth = boxConstraints.maxWidth;
                            final double gruposWidth = (totalWidth * 0.20).clamp(80.0, 220.0);
                            final double totalHeight = boxConstraints.maxHeight;
                            final double gruposHeight = (totalHeight * 0.05).clamp(80.0, 220.0);
                            final double alturaItemGrupo = (boxConstraints.maxHeight * 0.08).clamp(55.0, 80.0);
                            return Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // COLUNA DE GRUPOS (largura proporcional ~20%)
                              if(funcoesController.listaGrupo.length > 1)
                              SizedBox(
                                width: gruposWidth,
                                height: gruposHeight,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListView.builder(
                                    itemCount: funcoesController.listaGruposPizza.length,
                                    itemBuilder: (context, index) {
                                      final grupo = funcoesController.listaGruposPizza[index];
                                      final selecionado = grupoSelecionadoNoTouch == grupo['numero'].toString();
                                      return GestureDetector(
                                        onTap: () {
                                          _guardarUltimoGrupoPosicao(index);
                                          setState(() {
                                            grupoSelecionadoNoTouch = grupo['numero'].toString();
                                            listaSaboresPrecoPizzaDentroDoTamanhoNoGrupo = produtosPorGrupo(grupoSelecionadoNoTouch);
                                          });
                                        },
                                        child: Container(
                                          height: alturaItemGrupo,
                                          margin: EdgeInsets.only(
                                            top: 6,
                                            left: 6,
                                            right: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: selecionado
                                                ? colorScheme.primary
                                                : colorScheme.surface,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Center(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              child: Text(
                                                grupo['nome'],
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: selecionado
                                                      ? colorScheme.onPrimary
                                                      : colorScheme.onSurface,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
        
                              SizedBox(width: 8),
        
                              // ÁREA DE PRODUTOS (Expanded — ocupa todo o restante)
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      // Número de colunas adaptável à largura disponível
                                      const double itemMinWidth = 110.0;
                                      final int cols = (constraints.maxWidth / itemMinWidth).floor().clamp(2, 8);
                                      final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
                                      // Fonte fixa na vertical
                                      final double fontSize = isLandscape ? (constraints.maxWidth * 0.018).clamp(10.0, 20.0) : 14.0;
                                      return GridView.builder(
                                    padding: const EdgeInsets.all(8),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: cols,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 1.5,
                                    ),
                                    itemCount: listaSaboresPrecoPizzaDentroDoTamanhoNoGrupo.length,
                                    itemBuilder: (context, index) {
                                      final sabor = listaSaboresPrecoPizzaDentroDoTamanhoNoGrupo[index];
                                      final numero = sabor['NumeroSabor'];
                                      final nome = sabor['Sabor'];
                                      final valor = sabor['Preco_Final'];
                                      final id = sabor['IdSabor'];
        
                                      return GestureDetector(
                                        onTap: () async {
                                          aparecerLista = false;
                                          if(valor == '0.00'){
                                            showErrorDialog(
                                              context: context,
                                              title: "Sabor indisponível",
                                              message: "O sabor $nome não está disponível para o tamanho selecionado",
                                              icon: Icons.error,
                                              onConfirm: () async {
                                                setState(() {
                                                  mostrarGrupos = false;
                                                  mostrarSabores = true;
                                                });
                                              },
                                            );
                                          } else {
                                            await funcaoConfigurarPizza(numero, nome, valor, id);
                                            setState(() {
                                              aparecerLista = false;
                                              configurarPizza = true;
                                              terminarPizza = false;
                                              showKeyboardAlfa = false;
                                              aparecerSaboresBordas = true;
                                              sairModoTouch();
                                              Future.delayed(Duration(milliseconds: 300), () {
                                                if (quantidadePizzaBordaSelecionadoFocus.canRequestFocus) {
                                                  quantidadePizzaBordaSelecionadoFocus.requestFocus();
                                                }
                                              });
                                            });
                                          }
                                        },
                                        // Visual do card de produto
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: colorScheme.surface,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            children: [
                                              // Nome ocupa todo o espaço restante
                                              Expanded(
                                                child: Center(
                                                  child: AutoSizeText(
                                                    nome,
                                                    textAlign: TextAlign.center,
                                                    maxLines: 3,
                                                    minFontSize: 8,
                                                    maxFontSize: isLandscape ? 12 : 14,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: isLandscape ? 12 : 14,
                                                      fontWeight: FontWeight.w500,
                                                    ), 
                                                  ),
                                                ),
                                              ),
        
                                              // Preço
                                              Align(
                                                alignment: Alignment.bottomRight,
                                                child: Container(
                                                  margin: EdgeInsets.only(right: 4, bottom: 4),
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 0,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: valor != "0.00"
                                                        ? colorScheme.primary.withOpacity(0.8)
                                                        : colorScheme.scrim,
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: valor != "0.00"
                                                ? Text(
                                                    "R\$ ${(double.tryParse(valor.toString()) ?? 0).toStringAsFixed(2)}",
                                                    style: TextStyle(
                                                      color: colorScheme.onPrimary,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: isLandscape ? 10 : 15,
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons.local_pizza,
                                                    size: isLandscape ? 12 : 20,
                                                    color: colorScheme.onPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                      );
                                    },
                                  );
                                  }
                                ),
                              ),
                              ),
                            ],
                          ),
                          );
                          }
                          ),
                        ),
                        /* Expanded(
                          flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                color: Colors.amber,
                              ),
                            )
                        ) */
                      ],
                    ),
                    /* if((!cardapioFocus.hasFocus && !quantidadePizzaBordaSelecionadoFocus.hasFocus && !observacaoSaborSelecionadoFocus.hasFocus && modoCarrinho && !terminarPizza) 
                      || (terminarPizza && !observacaoPizzaFocus.hasFocus)) */
                    // vertical 
                    if((modoCarrinho && !terminarPizza && orientation == Orientation.portrait) || (terminarPizza && orientation == Orientation.portrait))
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(left: 8.0, right: 8.0, top: 0.0, bottom: 8.0),
                          child: SizedBox(
                           //  aspectRatio: 1,
                            child: _buildPizzaVisual(bordas: itemPizzaGraficoController.listaBordas, sabores: itemPizzaGraficoController.listaSabores),
                          ),
                        ),
                      ),
                    ),

                    // horizontal
                    if((modoCarrinho && !terminarPizza && orientation == Orientation.landscape) || (terminarPizza && orientation == Orientation.landscape))
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(left: 8.0, right: 8.0, top: 0.0, bottom: 8.0),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.30,
                            width: MediaQuery.of(context).size.width * 0.40,
                            child: _buildPizzaVisual(bordas: itemPizzaGraficoController.listaBordas, sabores: itemPizzaGraficoController.listaSabores),
                          ),
                        ),
                      ),
                    ),
                  
                    // if (showKeyboardAlfa)
                    if(nunca)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 100),
                        padding: EdgeInsets.only(
                          bottom: showKeyboardAlfa ? 1: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        height: showKeyboardAlfa ? configurarPizza || terminarPizza ? MediaQuery.of(context).size.height * 0.40 : MediaQuery.of(context).size.height * 0.40 : 0,
                        child: showKeyboardAlfa
                            ? Container(
                                color: Theme.of(context).colorScheme.surface,
                                child: Column(
                                  children: [
                                    // LINHAS DO TECLADO
                                    _buildKeyboardRow(['1', '2', '3', '4', '5', '6', '7', '8', '9', '0',]),
          
                                    _buildKeyboardRow(['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P',]),
          
                                    _buildKeyboardRow(['1/2', 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', '1/2',]),
          
                                    _buildKeyboardRow(['', '', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '⌫',]),
          
                                    _buildKeyboardRow(['ESP', 'OK'], isLastRow: true),
          
                                    _buildKeyboardRow(['', '', '', 'fechar',], isLastRow: true),
                                    // SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                                  ],
                                ),
                              )
                            : SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
        }

       Widget _buildKeyboardRow(List<String> letras, {bool isLastRow = false}) {
        return Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Conta quantos '' no início e no fim (spacers)
              int leading = 0;
              while (leading < letras.length && letras[leading] == '') leading++;

              int trailing = 0;
              while (trailing < letras.length - leading &&
                  letras[letras.length - 1 - trailing] == '') {
                trailing++;
              }

              // Somente teclas visíveis
              final visibleKeys = letras.where((t) => t != '').toList();

              // Define flex real (EXATAMENTE o do Row)
              List<int> flexList = visibleKeys.map((t) {
                // Como a largura dos botões será distribuída
                if (t == '') return 2; // um espaço inteiro
                if (t == 'ESP') return 10; // espaço grande
                if (t == '⌫') return 4; // botão maior
                if (t == '1/2') return 1; // meio espaço
                return 2; // tecla normal
              }).toList();

              // Flex total
              int totalFlex = leading + flexList.reduce((a, b) => a + b) + trailing;

              // Largura por flex unit
              double unit = constraints.maxWidth / totalFlex;

              // Hitboxes precisas
              List<({double start, double end, String key})> hit = [];
              double cursor = leading * unit;

              for (int i = 0; i < visibleKeys.length; i++) {
                double w = flexList[i] * unit;
                hit.add((start: cursor, end: cursor + w, key: visibleKeys[i]));
                cursor += w;
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  double dx = details.localPosition.dx;

                  for (var box in hit) {
                    if (dx >= box.start && dx <= box.end) {
                      switch (box.key) {
                        case '⌫':
                          _apagarNoTecladoAlfa();
                          break;
                        case 'OK':
                          _confirmarNoTecladoAlfa();
                          break;
                        case 'ESP':
                          _adicionarTeclaNoTecladoAlfa(' ');
                          break;
                        case 'fechar':
                          _fecharTecladoNoTecladoAlfa();
                          break;
                        case '1/2':
                          // NÃO FAZ NADA -> é só espaçamento visual
                          break;
                        default:
                          _adicionarTeclaNoTecladoAlfa(box.key);
                      }
                      break;
                    }
                  }
                },
                onLongPressStart: (details) {
                  double dx = details.localPosition.dx;

                  for (var box in hit) {
                    if (dx >= box.start && dx <= box.end) {
                      if (box.key == '⌫') {
                        _iniciarApagarNoTecladoAlfa(); // AÇÃO DO TOQUE LONGO
                      }
                      break;
                    }
                  }
                },
                // PARA QUANDO SOLTA
                onLongPressEnd: (_) {
                  _pararApagarNoTecladoAlfa();
                },

                // GARANTE PARADA SE CANCELAR O TOQUE
                onTapUp: (_) {
                  _pararApagarNoTecladoAlfa();
                },

                onTapCancel: () {
                  _pararApagarNoTecladoAlfa();
                },
                child: Row(
                  children: [
                    if (leading > 0) Spacer(flex: leading),

                    for (int i = 0; i < visibleKeys.length; i++)
                      Expanded(
                        flex: flexList[i],
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: _buildVisualButton(visibleKeys[i]),
                        ),
                      ),

                    if (trailing > 0) Spacer(flex: trailing),
                  ],
                ),
              );
            },
          ),
        );
      }

      Widget _buildVisualButton(String tecla) {
        ColorScheme cs = Theme.of(context).colorScheme;

        if (tecla == '1/2') {
          return Container(); // espaço vazio para alinhar visualmente
        }

        if (tecla == 'fechar') {
          return Container(
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Center(
              child: Icon(Icons.arrow_drop_down, color: cs.onSecondaryContainer),
            ),
          );
        }

        if (tecla == '⌫') {
          return Container(
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Center(
              child: Icon(Icons.backspace, color: cs.onSecondaryContainer),
            ),
          );
        }

        if (tecla == 'OK') {
          return Container(
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Center(child: Icon(Icons.keyboard_return, color: cs.onPrimary)),
          );
        }

        if (tecla == 'ESP') {
          return Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Center(child: Icon(Icons.space_bar, color: cs.onSurface)),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Center(
            child: Text(
              tecla,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.height * 0.025,
                color: cs.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }
    }


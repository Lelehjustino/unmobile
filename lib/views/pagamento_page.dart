import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:un_recepcao/controllers/maquininhas/paymentServiceOficial.dart';
import 'package:un_recepcao/controllers/payment_service.dart';
import 'package:un_recepcao/controllers/views/funcoes_controller.dart';
import 'package:un_recepcao/controllers/views/garcom_controller.dart';
import 'package:un_recepcao/controllers/views/painel_controller.dart';
import 'package:un_recepcao/data/data_class.dart';
import 'package:un_recepcao/services/cielo/cielo_payment_service.dart';
import 'package:un_recepcao/services/cielo/cielo_service.dart';
import 'package:un_recepcao/services/maquininhas/paymentProvider.dart';
import 'package:un_recepcao/services/pagBank/smartPos/pagbank_smartpos.dart';
import 'package:un_recepcao/views/conta_page.dart';
import 'package:un_recepcao/views/garcom_page.dart';
import 'package:un_recepcao/views/mapa_page.dart';
import 'package:un_recepcao/widgets/side_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class PagamentoPage extends StatefulWidget {
  const PagamentoPage({super.key});

  @override
  State<PagamentoPage> createState() => PagamentoPageState();
}

class PagamentoPageState extends State<PagamentoPage>
    with SingleTickerProviderStateMixin {

  String versaoAplicacao = FuncoesController().versaoDoApp;

  final FuncoesController funcoesController = Get.find<FuncoesController>();
  final GarcomController garcomController = Get.find<GarcomController>();
  final painelController = Get.put(PainelController());

  // Variáveis para receber e ajeitar args
  String numeropedido = Get.arguments['numeropedido'];
  String comandaDoPedido = Get.arguments['comanda'];
  String mesaDoPedido = Get.arguments['mesa'];
  String nomeClienteDoPedido = Get.arguments['nome'];
  String numeroTurnoCaixa = Get.arguments['numeroTurnoCaixa'];
  String statusCaixa = Get.arguments['statusCaixa'];
  String numeroCaixa = Get.arguments['numeroCaixa'];
  String nomeCaixa = Get.arguments['nomeCaixa'];
  String rotaAnterior = Get.arguments['pageAnterior'];
  String numeroClienteDoPedidoBalcao = Get.arguments['numeroBalcao'];

  String numeroTurnoCaixaSelecionado = "";
  String statusCaixaSelecionado = "";
  String numeroCaixaSelecionado = "";
  String nomeCaixaSelecionado = "";
  String rotaAnteriorSelecionado = "";

  String comandaDoPedidoParaInsert = "";
  String mesaDoPedidoParaInsert = "";

  final TextEditingController comandaController = TextEditingController();
  final TextEditingController servidorController = TextEditingController();

  final TextEditingController nomeMoedaController = TextEditingController();
  final TextEditingController numeroMoedaController = TextEditingController();
  final TextEditingController valorPagarController = TextEditingController();
  final FocusNode nomeMoedaFocus = FocusNode();
  final FocusNode valorPagarFocus = FocusNode();

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
  final ScrollController _scrollController = ScrollController();

  // Controle dos filtros de mesas e comandas
  bool mostrarTodas = true;
  bool mostrarAbertas = false;
  bool mostrarFechadas = false;
  bool mesaAberta = true;
  bool _isLoading = true;
  bool servidorConectado = false;

  // Para fazer requisições em determinado tempo (1/3)
  // Timer? _timerConexao;
  // Timer? _timerConexaoCair;

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

  String totalProdutoString = '0.00';
  String totalAdicionaisString = '0.00';
  String totalServicoString = '0.00';
  String totalDescontoString = '0.00';

  String numeroDePessoasString = '1';
  int numeroDePessoasInt = 1;

  double totalDaComanda = 0;
  double totalPorPessoa = 0;
  String totalDaComandaString = '0.00';
  String totalPorPessoaString = '0.00';

  String numeroTradepointSelecionada = "";

  // Varáveis para lista de produtos
  List<dynamic> listaProdutos = [];

  // Variáveis para valores do pedido
  List<dynamic> listaValoresDoPedidoSelect = [];
  String valorProdutosSelect = '0.00';
  String valorAdicionaisSelect = '0.00';
  String valorServicoSelect = '0.00';
  String valorDescontoSelect = '0.00';
  String valorTotalLiquidoSelect = '0.00';

  // Variáveis para mandar insert
  String numeroUsuario = "";
  String numeroComanda = "";
  String numeroMesa = "";

  // Variáveis para tamanhos
  double tamanhoLetrasPequenas = 10;

  // Variáveis para status do pedido
  bool mesaEmConta = false;
  bool comandaEmConta = false;

  // Variáveis para pessoas
  String pessoasSelect = '1';
  String totalPorPessoaSelect = '0.00';

  // Formatador de moeda
  final formatoReal = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

/*   String tipoDoPedido = "";
  bool logicaPorMesa = false;
  bool logicaPorComanda = false;
  bool logicaPorComandaNaMesa = false; */

  bool cliqueiConta = false;

  // List<dynamic> listaFormasDePagamento = [];
  List<dynamic> listaFormasDePagamentoSelecionadas = [];

  String valorRecebido = '0.00';
  String valorAReceber = '0.00';
  String valorTroco = '0.00';
  double valorRecebidoDouble = 0.0;
  double valorReceberDouble = 0.0;
  double valorTrocoDouble = 0.0;

  bool cliqueiPagarPedido = false;
  bool _processandoCielo = false;

  bool showKeyboardNumero = false;

  bool isProcessingConfirmar = false;

  bool aparecerConfirmar = false;
  bool dialogoConfirmacaoAberto = false;

  String tipoMoedaSelecionado = "";

  // List<dynamic> listaCaixas = [];

  String detalhesPedido = "";

  @override
  void initState() {
    super.initState();

    painelController.estaNoPainelCozinha.value = false;

    valorPagarFocus.addListener(() {
      // Quando perder o foco
      if (!valorPagarFocus.hasFocus) {
        fecharTeclado();
      }
    });

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );

    // Inicializa o controller da animação
    animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    // Define o tipo da animação
    scaleAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutCubic,
    );

    // conectarBanco();
    _atualizarHora();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _atualizarHora();
    });
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
        _isFocused = true;
      });
    });
    _carregarNote();
    _carregarModo();
    _carregarServidor();
    _loadServidor();
    _loadComanda();
    _carregarModos();
    _carregarRecepcao();
    _carregarchecks();
    _carregargarcom();
    numeroDePessoasInt = 1;
    numeroDePessoasString = '1';
    buscarListaProdutos();
    buscarValoresDoPedido();
    calcularTotalPorPessoa();
    _loadNumeroLicenca();
    _loadNumeroGarcom();
    arrumaVazioComanda();
    arrumarVazioMesa();
    zeraValores();
    _loadNomeEmpresa();
    calcularValorReceberInicial();
    arrumarDadosCaixa();
    detalhesPedidoFunc();

    // buscarTipoPedido();
    // buscarPagamento();
    // buscarCaixas();
  }

  void detalhesPedidoFunc(){
    String texto = "";
    (comandaDoPedido == "0" && mesaDoPedido != "0")
    ? texto = 'MESA: $mesaDoPedido'
    : (mesaDoPedido == "0" && comandaDoPedido != "0")
    ? texto = 'COMANDA: $comandaDoPedido'
    : (comandaDoPedido != "0" && mesaDoPedido != "0")
    ? texto = 'COMANDA: $comandaDoPedido MESA: $mesaDoPedido'
    : (comandaDoPedido != "0")
    ? texto = 'COMANDA: $comandaDoPedido'
    : (mesaDoPedido != "0")
    ? texto = 'MESA: $mesaDoPedido'
    : (nomeClienteDoPedido != "0")
    ? texto = '#$numeroClienteDoPedidoBalcao# $nomeClienteDoPedido'
    : (numeroClienteDoPedidoBalcao != "0")
    ? texto = '#$numeroClienteDoPedidoBalcao#'
    : texto = '';

    detalhesPedido = texto;
  }

  /* pedirConta() async{
    await buscarMesaEmConta(mesaDoPedidoParaInsert);
    await buscarComandaEmConta(comandaDoPedidoParaInsert);
    if (!mesaEmConta && !comandaEmConta) {
      await _loadNumeroGarcom();
      await _loadNumeroLicenca();
      // pedir conta
      await inserirConta(
        numeroTradepointSelecionada,
        numeroUsuario, // numero do nome selecionado
        comandaDoPedidoParaInsert, 
        mesaDoPedidoParaInsert,
        numeroDePessoasString,
      );

      await zerarAtendimento();
    }
  } */

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    _timer.cancel();
    _scrollController.dispose();
    _focusNode.dispose();
    animationController.dispose();
    super.dispose();
  }

  void fecharTeclado() {
    FocusScope.of(context).unfocus();

    Future.delayed(
      const Duration(milliseconds: 150),
      () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        }
      },
    );
  } 

  arrumarDadosCaixa(){
    setState(() {
      numeroTurnoCaixaSelecionado = numeroTurnoCaixa;
      statusCaixaSelecionado = statusCaixa;
      numeroCaixaSelecionado = numeroCaixa;
      nomeCaixaSelecionado = nomeCaixa;
      rotaAnteriorSelecionado = rotaAnterior;
    });
  }

  calcularValorReceberInicial() async {
    await buscarValoresDoPedido();
    valorReceberDouble = _parseString(valorTotalLiquidoSelect);
    valorAReceber = _formatDouble(valorReceberDouble);
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

  // Função para zerar valores
  zeraValores() {
    print("numeropedido: $numeropedido");
    print("comandaDoPedido: $comandaDoPedido");
    print("mesaDoPedido: $mesaDoPedido");
    if (numeropedido == "") {
      numeropedido = "0";
    }
    if (comandaDoPedido == "") {
      comandaDoPedido = "0";
    }
    if (mesaDoPedido == "") {
      mesaDoPedido = "0";
    }
    if(nomeClienteDoPedido == ""){
      nomeClienteDoPedido = "0";
    }
  }

  /* // Função para descobrir tipo do pedido
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
  } */

  // Função para arrumar vazio da comanda
  void arrumaVazioComanda() {
    if (comandaDoPedido == "") {
      comandaDoPedidoParaInsert = "0";
      buscarComandaEmConta(comandaDoPedidoParaInsert);
    } else if (comandaDoPedido != "") {
      comandaDoPedidoParaInsert = comandaDoPedido;
      buscarComandaEmConta(comandaDoPedidoParaInsert);
    } else {
      comandaDoPedidoParaInsert = comandaDoPedido;
      buscarComandaEmConta(comandaDoPedidoParaInsert);
    }
  }

  // Função para arrumar vazio da mesa
  void arrumarVazioMesa() {
    if (mesaDoPedido == "") {
      mesaDoPedidoParaInsert = "0";
      buscarMesaEmConta(mesaDoPedidoParaInsert);
    } else if (mesaDoPedido != "") {
      mesaDoPedidoParaInsert = mesaDoPedido;
      buscarMesaEmConta(mesaDoPedidoParaInsert);
    } else {
      mesaDoPedidoParaInsert = mesaDoPedido;
      buscarMesaEmConta(mesaDoPedidoParaInsert);
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

  // Função para calcular o total por pessoa
  void calcularTotalPorPessoa() async {
    await buscarValoresDoPedido();
    totalPorPessoa = double.parse(valorTotalLiquidoSelect) / numeroDePessoasInt;
    setState(() {
      totalPorPessoaString = totalPorPessoa.toStringAsFixed(2);
    });
  }

  // Função para aumentar a quantidade de pessoas
  void aumentarQuantidadePessoas() {
    if (numeroDePessoasInt < 99) {
      numeroDePessoasInt++;
      setState(() {
        numeroDePessoasString = numeroDePessoasInt.toString();
        calcularTotalPorPessoa();
      });
    }
  }

  // Função para diminuir a quantidade de pessoas
  void diminuirQuantidadePessoas() {
    if (numeroDePessoasInt > 1) {
      numeroDePessoasInt--;
      setState(() {
        numeroDePessoasString = numeroDePessoasInt.toString();
        calcularTotalPorPessoa();
      });
    }
  }

  // Carregar modo
  Future<void> _carregarModos() async {
    final prefs = await SharedPreferences.getInstance();
    final modoJson = prefs.getString('modo_padrao');

    if (modoJson != null) {
      final modosSalvos = Set<String>.from(jsonDecode(modoJson));

      setState(() {
        // Regra: O mapa aparece se "Mesa" OU "Comanda" estiverem selecionados
        naoAparecerMapa =
            !(modosSalvos.contains("Mesa") || modosSalvos.contains("Comanda"));

        // Lógica de aparecerCheckInOut baseada nos modos Comanda/Mesa
        if (modosSalvos.contains("Mesa") && !modosSalvos.contains("Comanda")) {
          aparecerCheckInOut = false;
        } else if (modosSalvos.contains("Comanda")) {
          aparecerCheckInOut = true;
        } else {
          aparecerCheckInOut = false;
        }
      });
    } else {
      setState(() {
        // Se não existir configuração salva (primeira execução), mapa deve vir DESABILITADO
        naoAparecerMapa = true;
        aparecerCheckInOut = true; // Mantendo o padrão deste arquivo para esta variável se nada salvo
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
          valor = "0";
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
    final agora = DateTime.now();
    final horaFormatada = DateFormat.Hm().format(agora);
    setState(() {
      _horaAtual = horaFormatada;
      _loadComanda();
    });

    // Ouvir mudanças de foco
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  Future<void> buscarListaProdutos() async {
    try {
      String dadosJson = await Connection().select("""
        SELECT
          p.nome AS nome_produto,
          p.id   AS tipo_produto,

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
        """);

      List<dynamic> lista = jsonDecode(dadosJson);
      print('Numero do pedido $numeropedido');

      setState(() {
        listaProdutos = lista;
        calcularTotalPorPessoa();
      });
    } catch (e) {
      print("Erro ao carregar listaProdutos: $e");
      setState(() {
        listaProdutos = [];
      });
    }
  }

  // Buscar se mesa esta em conta
  Future<void> buscarMesaEmConta(String numeroDaMesa) async {
    try {
      String dadosJson = await Connection().select("""
          SELECT statuspedido FROM mesas WHERE numero = '$numeroDaMesa';
        """);

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        if (lista[0]['statuspedido'] == '2') {
          setState(() {
            mesaEmConta = true;
          });
        } else {
          setState(() {
            mesaEmConta = false;
          });
        }
      }
    } catch (e) {
      print("Erro ao buscar status: $e");
      mesaEmConta = false;
    }
  }

  // Buscar se comanda esta em conta
  Future<void> buscarComandaEmConta(String numeroDaComanda) async {
    try {
      String dadosJson = await Connection().select("""
          SELECT statuspedido FROM cartoes WHERE numero = '$numeroDaComanda';
        """);

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        if (lista[0]['statuspedido'] == '2') {
          setState(() {
            comandaEmConta = true;
          });
        } else {
          setState(() {
            comandaEmConta = false;
          });
        }
      }
    } catch (e) {
      print("Erro ao buscar status: $e");
      comandaEmConta = false;
    }
  }

  // Função para buscar valores do pedido
  Future<void> buscarValoresDoPedido() async {
    // $numeropedido
    try {
      String dadosJson = await Connection().select("""
         SELECT valorprodutos, valoradicionais, valorservico, valordesconto, valortotalliquido, pessoas, valortotalliquido / pessoas AS totalPorPessoa  FROM pedidos    WHERE numero = '$numeropedido';
        """);

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        final valor = lista[0]['valorprodutos'].toString();
        final valor2 = lista[0]['valoradicionais'].toString();
        final valor3 = lista[0]['valorservico'].toString();
        final valor4 = lista[0]['valordesconto'].toString();
        final valor5 = lista[0]['valortotalliquido'].toString();
        final valor6 = lista[0]['pessoas'].toString();
        final valor7 = lista[0]['totalPorPessoa'].toString();

        setState(() {
          listaValoresDoPedidoSelect = lista;
          valorProdutosSelect = valor;
          valorAdicionaisSelect = valor2;
          valorServicoSelect = valor3;
          valorDescontoSelect = valor4;
          valorTotalLiquidoSelect = valor5;
          pessoasSelect = valor6;
          totalPorPessoaSelect = valor7;
        });
      } else {
        setState(() {
          listaValoresDoPedidoSelect = [];
          valorProdutosSelect = "0.00";
          valorAdicionaisSelect = "0.00";
          valorServicoSelect = "0.00";
          valorDescontoSelect = "0.00";
          valorTotalLiquidoSelect = "0.00";
          pessoasSelect = "1";
          totalPorPessoaSelect = "0.00";
        });
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
      setState(() {
        listaValoresDoPedidoSelect = [];
        valorProdutosSelect = "0.00";
        valorAdicionaisSelect = "0.00";
        valorServicoSelect = "0.00";
        valorDescontoSelect = "0.00";
        valorTotalLiquidoSelect = "0.00";
        pessoasSelect = "1";
        totalPorPessoaSelect = "0.00";
      });
    }
  }

/*   // Função para inserir venda
  Future<void> inserirConta(
    // conta
    String numerotradepointInsert,
    String numeroUsuarioInsert, // número usuario
    String numeroComandaInsert, // se não tiver -> manda 0
    String numeroMesaInsert, // se não tiver -> manda 0
    String numeroDePessoas,
  ) async {
    String numerosabor1 = "0";
    String numerosabor2 = "0";
    String numerosabor3 = "0";
    String numerosabor4 = "0";
    String numerosabor5 = "0";
    String numerosabor6 = "0";
    String numerosabor7 = "0";
    String numerosabor8 = "0";
    String obssabor1 = "";
    String obssabor2 = "";
    String obssabor3 = "";
    String obssabor4 = "";
    String obssabor5 = "";
    String obssabor6 = "";
    String obssabor7 = "";
    String obssabor8 = "";
    String numeroborda1 = "0";
    String numeroborda2 = "0";
    String numeroborda3 = "0";
    String numeroborda4 = "0";
    String numeroborda5 = "0";
    String numeroborda6 = "0";
    String numeroborda7 = "0";
    String numeroborda8 = "0";
    String obsborda1 = "";
    String obsborda2 = "";
    String obsborda3 = "";
    String obsborda4 = "";
    String obsborda5 = "";
    String obsborda6 = "";
    String obsborda7 = "";
    String obsborda8 = "";
    String divisaoPizza = "00000000";
    String observacaoInsert = "";
    String adicionalInsert = "";
    String numeroDePessoasInsert = numeroDePessoas;
    try {
      await Connection().ipd("""
        INSERT INTO vendasmobiles (
          numerotradepoint_FK,
          numeroUsuario_FK,
          numerocartao,
          numeroMesa,
          observacao,
          adicional,
          status,
          numerosabor1_FK,
          numerosabor2_FK,
          numerosabor3_FK,
          numerosabor4_FK,
          numerosabor5_FK,
          numerosabor6_FK,
          numerosabor7_FK,
          numerosabor8_FK,
          obssabor1,
          obssabor2,
          obssabor3,
          obssabor4,
          obssabor5,
          obssabor6,
          obssabor7,
          obssabor8,
          numeroborda1_FK,
          numeroborda2_FK,
          numeroborda3_FK,
          numeroborda4_FK,
          numeroborda5_FK,
          numeroborda6_FK,
          numeroborda7_FK,
          numeroborda8_FK,
          obsborda1,
          obsborda2,
          obsborda3,
          obsborda4,
          obsborda5,
          obsborda6,
          obsborda7,
          obsborda8,
          divisaosabores,
          numeropessoas
        ) VALUES (
          '$numerotradepointInsert',
          '$numeroUsuarioInsert',
          '$numeroComandaInsert',
          '$numeroMesaInsert',
          '$observacaoInsert',
          '$adicionalInsert',
          '5',
          '$numerosabor1',
          '$numerosabor2',
          '$numerosabor3',
          '$numerosabor4',
          '$numerosabor5',
          '$numerosabor6',
          '$numerosabor7',
          '$numerosabor8',
          '$obssabor1',
          '$obssabor2',
          '$obssabor3',
          '$obssabor4',
          '$obssabor5',
          '$obssabor6',
          '$obssabor7',
          '$obssabor8',
          '$numeroborda1',
          '$numeroborda2',
          '$numeroborda3',
          '$numeroborda4',
          '$numeroborda5',
          '$numeroborda6',
          '$numeroborda7',
          '$numeroborda8',
          '$obsborda1',
          '$obsborda2',
          '$obsborda3',
          '$obsborda4',
          '$obsborda5',
          '$obsborda6',
          '$obsborda7',
          '$obsborda8',
          '$divisaoPizza',
          '$numeroDePessoasInsert'
        )
        """);
      print(">>>Conta pedida com sucesso<<<");
    } catch (e) {
      print(">>>Erro ao inserir conta: $e<<<");
    }
  } */

  // Pagar pedido
  /* Future<void> buscarPagamento() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, moeda, tipo FROM formaspagamento WHERE operante='1' AND (tipo!='5' AND tipo!='99')",
      );

      // Decode fora do setState
      final List<dynamic> lista = jsonDecode(dadosJson);
      // print(">>>Formas de pagamento: $lista<<<");

      if (lista.isNotEmpty) {
        listaFormasDePagamento = lista;
      } else {
        listaFormasDePagamento = [];
      }
    } catch (e) {
      listaFormasDePagamento = [];
    }
  } */

/*   // Função para escolher cor do botão
  List<Color> listaCores = [
    Color.fromRGBO(87, 154, 146, 1),
    Color.fromARGB(255, 72, 160, 75),
    Color.fromRGBO(218, 176, 6, 1),
    Color.fromRGBO(228, 84, 216, 1),
    Color.fromRGBO(22, 22, 189, 1),
    Color.fromRGBO(201, 192, 42, 1),
    Color.fromRGBO(175, 70, 70, 1),
    Color.fromRGBO(137, 165, 255, 1),
    Color.fromRGBO(186, 163, 110, 1), 
    Color.fromRGBO(255, 0, 0, 1),
    Color.fromRGBO(0, 0, 255, 1),
  ];

  Color escolherCorBotao(int index) {
    return listaCores[index % listaCores.length];
  } */
 Color escolherCorTipo(int tipo) {
  switch (tipo) {
    case 1:
      return Color.fromRGBO(87, 154, 146, 1);

    case 20:
      return Color.fromARGB(255, 72, 160, 75);

    case 3:
      return Color.fromRGBO(218, 176, 6, 1);

    case 4:
      return Color.fromRGBO(84, 106, 228, 1);

    case 5:
      return Color.fromRGBO(28, 73, 22, 1);

    case 50:
      return Color.fromRGBO(201, 192, 42, 1);

    case 10:
      return Color.fromRGBO(175, 70, 70, 1);

    case 11:
      return Color.fromRGBO(201, 51, 59, 1);

    case 99:
      return Color.fromRGBO(186, 163, 110, 1);

    default:
      return Colors.grey; // tipo desconhecido
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

  // Função para limpar view
  limparView() {
    numeropedido = '';
    comandaDoPedido = '';
    mesaDoPedido = '';
    // Dados vindos por argumento
    comandaDoPedidoParaInsert = "";
    mesaDoPedidoParaInsert = "";

    // Totais formatados
    totalProdutoString = '0.00';
    totalAdicionaisString = '0.00';
    totalServicoString = '0.00';
    totalDescontoString = '0.00';

    // Pessoas
    numeroDePessoasString = '1';
    numeroDePessoasInt = 1;

    // Totais numéricos
    totalDaComanda = 0.0;
    totalPorPessoa = 0.0;
    totalDaComandaString = '0.00';
    totalPorPessoaString = '0.00';

    // Tradepoint
    numeroTradepointSelecionada = "";

    // Listas
    listaProdutos.clear();
    listaValoresDoPedidoSelect.clear();

    // Valores do pedido
    valorProdutosSelect = '0.00';
    valorAdicionaisSelect = '0.00';
    valorServicoSelect = '0.00';
    valorDescontoSelect = '0.00';
    valorTotalLiquidoSelect = '0.00';

    // Dados para insert
    numeroUsuario = "";
    numeroComanda = "";
    numeroMesa = "";

    // Conexão (opcional – use só se fizer sentido no seu fluxo)
    isConnected.value = false;
    dialogoConfirmacaoAberto = false;
  }

  // Funcoes teclado
  void _apagarNumero() {
    if (valorPagarController.text.isEmpty) return;
    final newText = valorPagarController.text.substring(
      0,
      valorPagarController.text.length - 1,
    );
    valorPagarController.text = newText;

    if (valorPagarController.text.isEmpty) {
      setState(() {
        aparecerConfirmar = false;
      });
    } else {
      setState(() {
        aparecerConfirmar = true;
      });
    }
  }

  void _adicionarNumero(String numero) {
    String texto = valorPagarController.text;

    if (numero == ",") {
      if (texto.contains(",")) {
        return;
      } else {
        texto += numero;
        valorPagarController.text = texto;
      }
    } else {
      texto += numero;
      valorPagarController.text = texto;
    }

    if (valorPagarController.text.isEmpty) {
      setState(() {
        aparecerConfirmar = false;
      });
    } else {
      setState(() {
        aparecerConfirmar = true;
      });
    }
  }

  void _confirmarTeclado() {
    if (isProcessingConfirmar) {
      return;
    }

    try {
      isProcessingConfirmar = true;
      if (valorPagarController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preencha o valor a pagar.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        isProcessingConfirmar = false;
        return;
      }

      adicionarPagamentoLista(
        nomeMoedaController.text,
        numeroMoedaController.text,
        valorPagarController.text,
      );
      setState(() {
        showKeyboardNumero = false;
      });
    } catch (e) {
      isProcessingConfirmar = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao adicionar pagamento.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
    isProcessingConfirmar = false;
  }

  String montarDescricaoFormasPagamento() {
    return listaFormasDePagamentoSelecionadas.map((pagamento) {
      double valorPagamentoDouble = _parseString(pagamento['valor'].toString());
      String valorPagamento = valorPagamentoDouble.toStringAsFixed(2);
      String nomeMoeda = pagamento['moeda'].toString();
      return "$nomeMoeda($valorPagamento)";
    }).join(" | ");
  }
  
  // Funcao que insere os pagamentos
  Future<bool>  insertPagamentos() async {
    try {
      String descricaoFormasPagamento = montarDescricaoFormasPagamento();
      for(var pagamento in listaFormasDePagamentoSelecionadas) {
        String numeroMoeda = pagamento['numero'].toString();
        String nomeMoeda = pagamento['moeda'].toString();
        double valorPagamentoDouble = _parseString(pagamento['valor'].toString());
        String valorPagamento = valorPagamentoDouble.toStringAsFixed(2);
        String numeroTurnoCaixa = numeroTurnoCaixaSelecionado;
        String numeroPedido = numeropedido;
        await inserirPagamento(numeroPedido, numeroTurnoCaixa, numeroMoeda, nomeMoeda, valorPagamento, descricaoFormasPagamento);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> inserirPagamento(
    String numeroPedido, 
    String numeroTurnoCaixa, 
    String numeroMoeda, 
    String nomeMoeda, 
    String valorPagamento,
    String descricaoFormasPagamento
    ) async {

    String trocoInsert = valorTrocoDouble > 0.0 ? valorTroco : "0";

    try {
      List<String> queries = [];

      // 1. Insert formas de pagamento
      queries.add("""
        INSERT INTO formapagamentopedidos (
          numeropedido_FK,
          numeromoeda_FK,
          valor
        ) 
        VALUES 
        (
          '$numeroPedido',
          '$numeroMoeda',
          '$valorPagamento'
        )
      """);

      // 2. Update no pedido
      queries.add("""
        UPDATE pedidos 
        SET 
          status = '3',
          fechamento = CURRENT_TIMESTAMP,
          valordesconto = '$valorDescontoSelect',
          valortotalliquido = '$valorTotalLiquidoSelect',
          troco = '$trocoInsert',
          numerocaixa_FK = '$numeroCaixaSelecionado',
          numerousuariofechamento_FK = '$numeroUsuario',
          numerotradepointfechamento_FK = '$numeroTradepointSelecionada',
          numeromovimentacaocaixa_FK = '$numeroTurnoCaixa',
          descricaoformaspagamento = '$descricaoFormasPagamento',
          lastsync = '0000-00-00 00:00:00'
        WHERE numero = '$numeroPedido'
        LIMIT 1;
      """);

      // 3. Update vendas 
      queries.add("""
        UPDATE vendas 
        SET 
          lastmodified = CURRENT_TIMESTAMP,
          lastsync = '0000-00-00 00:00:00'
        WHERE numeropedido_FK = '$numeroPedido';
      """);

      // 4. Update formas de pagamento (lastmodified)
      queries.add("""
        UPDATE formapagamentopedidos 
          SET 
            lastmodified = CURRENT_TIMESTAMP,
            lastsync = '0000-00-00 00:00:00'
          WHERE numeropedido_FK = '$numeroPedido';
      """);

      (comandaDoPedido == "0" && mesaDoPedido != "0")
        ? 
          // mesa 
          queries.add("""
          UPDATE mesas 
            SET 
              atendimento = '0',
              statuspedido = '0',
              numeropedido_FK = '0',
              comandavinculada = '0',
              pessoas = '0',
              valorliquidopedido = '0.00',
              nomecliente = '',
              lastsync = '0000-00-00 00:00:00'
            WHERE numero = '$mesaDoPedidoParaInsert'
            LIMIT 1;
        """)
        : (mesaDoPedido == "0" && comandaDoPedido != "0")
        ? 
          // comanda
          queries.add("""
            UPDATE cartoes 
            SET 
              atendimento = '0',
              statuspedido = '0',
              numeropedido_FK = '0',
              pessoas = '0',
              valorliquidopedido = '0.00',
              nomecliente = '',
              numeromesa = '0',
              lastsync = '0000-00-00 00:00:00'
            WHERE numero = '$comandaDoPedidoParaInsert'
            LIMIT 1;
          """)
        : (comandaDoPedido != "0" && mesaDoPedido != "0")
        ? {
            // comanda na mesa
            queries.add("""
              UPDATE cartoes 
              SET 
                atendimento = '0',
                statuspedido = '0',
                numeropedido_FK = '0',
                pessoas = '0',
                valorliquidopedido = '0.00',
                nomecliente = '',
                numeromesa = '0',
                lastsync = '0000-00-00 00:00:00'
              WHERE numero = '$comandaDoPedidoParaInsert'
              LIMIT 1;
            """),

            queries.add("""
              UPDATE mesas 
              SET 
                comandavinculada = '0',
                lastsync = '0000-00-00 00:00:00'
              WHERE numero = '$mesaDoPedidoParaInsert'
              LIMIT 1;
            """)
          }
        : (comandaDoPedido != "0")
        ? 
          // comanda
          queries.add("""
            UPDATE cartoes 
            SET 
              atendimento = '0',
              statuspedido = '0',
              numeropedido_FK = '0',
              pessoas = '0',
              valorliquidopedido = '0.00',
              nomecliente = '',
              numeromesa = '0',
              lastsync = '0000-00-00 00:00:00'
            WHERE numero = '$comandaDoPedidoParaInsert'
            LIMIT 1;
          """)
        : (mesaDoPedido != "0")
        ? 
          // mesa 
          queries.add("""
          UPDATE mesas 
            SET 
              atendimento = '0',
              statuspedido = '0',
              numeropedido_FK = '0',
              comandavinculada = '0',
              pessoas = '0',
              valorliquidopedido = '0.00',
              nomecliente = '',
              lastsync = '0000-00-00 00:00:00'
            WHERE numero = '$mesaDoPedidoParaInsert'
            LIMIT 1;
        """)
        : (nomeClienteDoPedido != "0")
        ? 
          // balcao 
          queries.add("""
            UPDATE delivery 
              SET 
                atendimento = '0',
                statuspedido = '3',
                numeropedido_FK = '0',
                valorliquidopedido = '0.00',
                nomecliente = '',
                lastsync = '0000-00-00 00:00:00'
              WHERE numeropedido_FK = '$numeroPedido'
              LIMIT 1;
          """)

        // caso nada funcione
        : 
        queries.add("""
          UPDATE cartoes 
          SET 
            atendimento = '0',
            statuspedido = '0',
            numeropedido_FK = '0',
            pessoas = '0',
            valorliquidopedido = '0.00',
            nomecliente = '',
            numeromesa = '0',
            lastsync = '0000-00-00 00:00:00'
          WHERE numero = '$comandaDoPedidoParaInsert'
          LIMIT 1;
        """);

        queries.add("""
          UPDATE mesas 
          SET 
            comandavinculada = '0',
            lastsync = '0000-00-00 00:00:00'
          WHERE numero = '$mesaDoPedidoParaInsert'
          LIMIT 1;
        """);

      /* // Logica Balcao 
      if(funcoesController.vendaBalcao.value && nomeClienteDoPedido != ""){
        queries.add("""
          UPDATE delivery 
            SET 
              atendimento = '0',
              statuspedido = '0',
              numeropedido_FK = '0',
              valorliquidopedido = '0.00',
              nomecliente = '',
              lastsync = '0000-00-00 00:00:00'
            WHERE numeropedido_FK = '$numeroPedido'
            LIMIT 1;
        """);
      } */
      
      
     /*  // Logica por Mesa
      if(garcomController.vendaMesa.value){
        queries.add("""
          UPDATE mesas 
            SET 
              atendimento = '0',
              statuspedido = '0',
              numeropedido_FK = '0',
              comandavinculada = '0',
              pessoas = '0',
              valorliquidopedido = '0.00',
              nomecliente = '',
              lastsync = '0000-00-00 00:00:00'
            WHERE numero = '$mesaDoPedidoParaInsert'
            LIMIT 1;
        """);
      } */
      
     /*  // Logica por Comanda
      if(garcomController.vendaComanda.value && !garcomController.vendaComandaNaMesa.value){
        queries.add("""
          UPDATE cartoes 
          SET 
            atendimento = '0',
            statuspedido = '0',
            numeropedido_FK = '0',
            pessoas = '0',
            valorliquidopedido = '0.00',
            nomecliente = '',
            numeromesa = '0',
            lastsync = '0000-00-00 00:00:00'
          WHERE numero = '$comandaDoPedidoParaInsert'
          LIMIT 1;
        """);
      } */

      /* if(garcomController.vendaComanda.value && garcomController.vendaComandaNaMesa.value){
        // Comandas
        queries.add("""
          UPDATE cartoes 
          SET 
            atendimento = '0',
            statuspedido = '0',
            numeropedido_FK = '0',
            pessoas = '0',
            valorliquidopedido = '0.00',
            nomecliente = '',
            numeromesa = '0',
            lastsync = '0000-00-00 00:00:00'
          WHERE numero = '$comandaDoPedidoParaInsert'
          LIMIT 1;
        """);

        queries.add("""
          UPDATE mesas 
          SET 
            comandavinculada = '0',
            lastsync = '0000-00-00 00:00:00'
          WHERE numero = '$mesaDoPedidoParaInsert'
          LIMIT 1;
        """);
      } */

      String res = await Connection().safeQuery(queries);
      
      return res == 'sucesso';
    } catch (e) {
      return false;
    }
  }

  // Funcao que retorna valor do pagamento no formato PagBank
  Future<int> valorPagamentoFormatado (valorPagamento) async {
    // chega -> "67.50" 
    final double valorEmDouble = double.parse(
      valorPagamento.toString().replaceAll(',', '.'),
    );

    final int valorEmIntFormatado = (valorEmDouble * 100).round();

    return valorEmIntFormatado;
  }

  // Switch que retorna forma de pagamento 
  Future<String> tipoPagamento (tipoNumero) async {
      String tipoPagamentoPagBank = "";
      switch (tipoNumero){
        // dinheiro
        case "1":
          return tipoPagamentoPagBank = "";

        // pix
        case "20":
          return tipoPagamentoPagBank = "pix";

        // credito
        case "3":
          return tipoPagamentoPagBank = "credito";

        // debito
        case "4":
          return tipoPagamentoPagBank = "debito";

        // pendura
        case "5":
          return tipoPagamentoPagBank = "";

        // pre pago 
        case "50":
          return tipoPagamentoPagBank = "";

        // vale alimentacao
        case "10":
          return tipoPagamentoPagBank = "";

        // voucher 
        case "11":
          return tipoPagamentoPagBank = "voucher";

        // outros 
        case "99":
          return tipoPagamentoPagBank = "";

        default:
          return tipoPagamentoPagBank = "";
      }
  }
  
  // Funcao para pagar usando cielo
  Future<void> pagarPedidoCielo(
    List<dynamic> listaFormasDePagamentoSelecionadasCielo) async {
    // Proteção: bloqueia segunda transação simultânea
    if (_processandoCielo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pagamento Cielo já está em andamento.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (listaFormasDePagamentoSelecionadasCielo.isEmpty) {
      print('Nenhuma forma de pagamento selecionada.');
      return;
    }

    // Objeto que veio da lista
    final formaPagamento = listaFormasDePagamentoSelecionadasCielo.first;
    // Pega o número
    final numero = formaPagamento['numero'].toString();

    String paymentCode = await tipoPagamentoCielo(numero);

    if (paymentCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Forma de pagamento não suportada pela Cielo!'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Calcula valor real em centavos a partir do valorTotalLiquidoSelect
    final double valorDouble = double.tryParse(valorTotalLiquidoSelect.replaceAll(',', '.'),) ?? 0.0;
    final int valorCentavos = (valorDouble * 100).round();

    // Gera referência única baseada no número do pedido
    final String referencia = (numeropedido.isNotEmpty && numeropedido != '0') ? 'CIELO_$numeropedido' : 'CIELO_${DateTime.now().millisecondsSinceEpoch}';

    print('==============================');
    print('PAGAMENTO CIELO');
    print('PaymentCode: $paymentCode');
    print('Valor centavos: $valorCentavos');
    print('Referência: $referencia');
    print('==============================');

    // Bloqueia UI
    if (mounted) setState(() => _processandoCielo = true);

    // Exibe snackbar de processamento
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              SizedBox(width: 14),
              Expanded(child: Text('Aguardando pagamento na Cielo...')),
            ],
          ),
          duration: Duration(minutes: 4),
        ),
      );
    }

    // Aguarda o resultado (Completer resolve quando callback chegar ou timeout)
    final resultado = await CieloPaymentService.pagar(
      valorCentavos: valorCentavos,
      referencia: referencia,
      paymentCode: paymentCode,
    );

    // Fecha o snackbar de processamento
    if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Desbloqueia UI
    if (mounted) setState(() => _processandoCielo = false);

    if (!mounted) return;

    // Trata resultado
    switch (resultado.status) {
      case CieloPaymentStatus.aprovado:
        // insertPagamentos já registra tudo no banco.
        // A PagamentoPage decide a navegação via pedidoPagoComSucesso()
        // que usa rotaAnterior (vinda dos arguments) — sem depender do nativo.
        bool pagamentoSucesso = await insertPagamentos();
        if (pagamentoSucesso) {
          // pedidoPagoComSucesso();
          volteiDoCielo(true);
        } else {
          // erroAoPagarPedido();
          volteiDoCielo(false);
        }
        break;

      case CieloPaymentStatus.cancelado:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                //'Pagamento cancelado na maquininha Cielo.'
                'Pagamento não processado!',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: Duration(seconds: 4),
            ),
          );
          // erroAoPagarPedido();
          volteiDoCielo(false);
        }
        break;

      case CieloPaymentStatus.erro:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                // resultado.mensagem ?? 'Erro no pagamento Cielo.',
                'Pagamento não processado!',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: Duration(seconds: 5),
            ),
          );
          // erroAoPagarPedido();
          volteiDoCielo(false);
        }
        break;

      case CieloPaymentStatus.timeout:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                // 'Não foi possível confirmar o pagamento. Verifique na maquininha.',
                'Pagamento não processado!',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: Duration(seconds: 6),
            ),
          );
          // erroAoPagarPedido();
          volteiDoCielo(false);
        }
        break;
    }
  }

  // Tipos de pagamento para cielo 
  Future<String> tipoPagamentoCielo(String tipoNumero) async {
    switch (tipoNumero) {
      // Dinheiro
      case "1":
        return "";

      // Pix
      case "20":
        return "PIX";

      // Crédito
      case "3":
        return "CREDITO_AVISTA";

      // Débito
      case "4":
        return "DEBITO_AVISTA";

      // Pendura
      case "5":
        return "";

      // Pré-pago
      case "50":
        return "";

      // Vale alimentação
      case "10":
        return "VOUCHER_ALIMENTACAO";

      // Voucher / Vale refeição
      case "11":
        return "VOUCHER_REFEICAO";

      // Outros
      case "99":
        return "";

      default:
        return "";
    }
  }

  // Funcao chamada quando volta da aplicao da cielo 
  Future<void> volteiDoCielo(bool sucesso) async {
    // Se teve sucesso no pagamento 
    if(sucesso) {
      /* if (rotaAnterior == "mapa"){
        // ir para o mapa 
        // Get.toNamed('/mapa');
        // Get.to('/mapa');
        Get.to(() => MapaPage());
      } else if (rotaAnterior == "garcom"){
        // ir para garcom 
        // Get.toNamed('/garcom');
        // Get.to('/garcom');
        Get.to(() => GarcomPage());
      } else {
        // rota padrao 
        // Get.toNamed('/garcom');
        // Get.to('/garcom');
        Get.to(() => GarcomPage());
      } */

      pedidoPagoComSucesso();
    } 
    // Se pagamento deu errado
    else {
      erroAoPagarPedido();
      Get.to(
        () => PagamentoPage(),
          arguments: {
            'numeropedido': numeropedido,
            'comanda': comandaDoPedido,
            'mesa': mesaDoPedido,
            'numeroTurnoCaixa': funcoesController.numeroTurnoCaixa.value,
            'statusCaixa': funcoesController.statusCaixa.value,
            'numeroCaixa': funcoesController.numeroCaixa.value,
            'nomeCaixa': funcoesController.nomeCaixa.value,
            'pageAnterior': rotaAnterior,
            'nome': nomeClienteDoPedido
          },
        );
    }
  }

  // Funcao chamada quando clicar em pagar e eu estiver dentro de uma maquininha da pagbank
  // Segue o fluxo oficial SmartCoffee: doPayment bloqueante + PlugPagEventListener
  Future<bool> pagarPedidoPagBank(List<dynamic> listaPagamento) async {
    // Filtra apenas formas suportadas antes de iniciar qualquer transação
    final List<Map<String, dynamic>> formasSuportadas = [];
    for (var forma in listaPagamento) {
      final String tipoNumero = forma['numero'].toString();
      final String valorPagamento = forma['valor'].toString();
      final String tipoPag = await tipoPagamento(tipoNumero);
      final int valorPag = await valorPagamentoFormatado(valorPagamento);
      if (tipoPag.isNotEmpty && valorPag >= 100) {
        formasSuportadas.add({'tipo': tipoPag, 'valor': valorPag, 'forma': forma});
      }
    }

    // Se não há formas suportadas pelo PagBank, pula direto
    if (formasSuportadas.isEmpty) {
      return true;
    }

    for (var item in formasSuportadas) {
      final String tipoPagamentoPagBank = item['tipo'] as String;
      final int valorPagamentoPagBank = item['valor'] as int;

      // Referência da venda: usa o número do pedido real
      final String referencia = (numeropedido.isNotEmpty && numeropedido != '0') ? 'PED$numeropedido' : 'UNMOBILE${DateTime.now().millisecondsSinceEpoch}';

      // Formata o valor em reais para exibição no diálogo
      final double valorEmReais = valorPagamentoPagBank / 100.0;
      final String valorExibicao = 'R\$ ${valorEmReais.toStringAsFixed(2).replaceAll('.', ',')}';

      // Estado interno do diálogo de pagamento
      String statusMensagem = 'Iniciando pagamento...';
      String senhaDigitos = ''; // SmartCoffee: acumula '●' para EVENT_CODE_DIGIT_PASSWORD
      bool cancelando = false;
      StateSetter? setDialogStateFn;

      // Ouve o EventChannel para capturar mensagens reais do PlugPag em tempo real
      StreamSubscription<Map<String, dynamic>>? sub;

      // Abre o diálogo de status ANTES de iniciar o pagamento
      // para que o usuário veja as mensagens desde o início
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (ctx, setDialogState) {
              setDialogStateFn = setDialogState;
              final theme = Theme.of(ctx);

              return PopScope(
                canPop: false,
                child: Dialog(
                  backgroundColor: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 24, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'PAGAMENTO PAGBANK',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          valorExibicao,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 24),
                        SizedBox(
                          height: 36,
                          width: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          statusMensagem,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        // Exibe os dígitos da senha quando houver
                        if (senhaDigitos.isNotEmpty) ...[
                          SizedBox(height: 8),
                          Text(
                            senhaDigitos,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                        SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: cancelando
                                ? null
                                : () async {
                                    setDialogState(() {
                                      cancelando = true;
                                      statusMensagem = 'Cancelando...';
                                    });
                                    await PagBankSmartPOS
                                        .cancelarPagamento();
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                              side: BorderSide(color: theme.colorScheme.error),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(
                                  vertical: 14),
                            ),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
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

      // Inscreve no stream de eventos do PlugPag
      // SmartCoffee: EVENT_CODE_DIGIT_PASSWORD → acumula '●'
      // SmartCoffee: EVENT_CODE_NO_PASSWORD → "Digite a senha"
      // Outros → customMessage do PlugPag
      sub = PagBankSmartPOS.eventos.listen((evento) {
        final String msg = evento['mensagem']?.toString() ?? '';
        final String tipo = evento['tipo']?.toString() ?? '';

        if (msg.isNotEmpty && setDialogStateFn != null && mounted) {
          setDialogStateFn!(() {
            if (msg == '●') {
              // SmartCoffee: EVENT_CODE_DIGIT_PASSWORD → acumula caractere
              senhaDigitos += '●';
            } else {
              // Qualquer outra mensagem reseta a senha e atualiza a mensagem
              senhaDigitos = '';
              statusMensagem = msg;
            }
          });
        }
      });

      // Executa o pagamento bloqueante no Kotlin via MethodChannel
      Map<String, dynamic> resultado;
      try {
        resultado = await PagBankSmartPOS.pagar(
          valorCentavos: valorPagamentoPagBank,
          tipo: tipoPagamentoPagBank,
          referencia: referencia,
        );
      } catch (e) {
        resultado = {
          'status': 'ERRO',
          'aprovado': false,
          'mensagem': 'Erro inesperado: $e',
        };
      }

      // Cancela a inscrição no stream de eventos
      await sub.cancel();

      // Fecha o diálogo de status
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      final String status = resultado['status']?.toString() ?? 'ERRO';
      final bool aprovado = resultado['aprovado'] == true;

      if (aprovado) {
        // Pagamento aprovado: mostra diálogo de sucesso brevemente
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              final theme = Theme.of(ctx);
              // Fecha automaticamente após 2 segundos
              Future.delayed(Duration(seconds: 2), () {
                if (Navigator.canPop(ctx)) {
                  Navigator.of(ctx).pop();
                }
              });
              return Dialog(
                backgroundColor: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.green, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Pagamento aprovado',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (resultado['mensagem']?.toString().isNotEmpty == true) ...[
                        SizedBox(height: 10),
                        Text(
                          resultado['mensagem'].toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        }
        // Pagamento aprovado: continua o fluxo normalmente para próxima forma
        continue;
      }

      // Pagamento não aprovado: exibe resultado e interrompe o loop
      if (!mounted) return false;

      final String mensagemErro = resultado['mensagem']?.toString() ?? '';
      final String codigoErro = resultado['codigoErro']?.toString() ?? '';

      String tituloErro;
      Color corIcone;
      IconData iconeErro;

      switch (status) {
        case 'NEGADO':
          tituloErro = 'Pagamento não aprovado';
          corIcone = Theme.of(context).colorScheme.error;
          iconeErro = Icons.cancel_outlined;
          break;
        case 'CANCELADO':
          tituloErro = 'Pagamento cancelado';
          corIcone = Theme.of(context).colorScheme.tertiary;
          iconeErro = Icons.do_not_disturb_alt_outlined;
          break;
        default:
          tituloErro = 'Erro no pagamento';
          corIcone = Theme.of(context).colorScheme.error;
          iconeErro = Icons.error_outline;
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final theme = Theme.of(ctx);
          return Dialog(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(iconeErro, color: corIcone, size: 64),
                  SizedBox(height: 16),
                  Text(
                    tituloErro,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (mensagemErro.isNotEmpty) ...[
                    SizedBox(height: 10),
                    Text(
                      mensagemErro,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                  if (codigoErro.isNotEmpty && codigoErro != '0') ...[
                    SizedBox(height: 6),
                    Text(
                      'Código: $codigoErro',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'OK',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      return false;
    }

    return true;
  }

  Future<void> realizarPagamentoMaquininhas(List<dynamic> listaFormasDePagamentoSelecionadas) async {
    final provedor = await PaymentServiceOficial.identificarProvedor();

    switch (provedor) {
      case PaymentProvider.pagBank:
        await pagarPedidoPagBank(listaFormasDePagamentoSelecionadas);
        break;

      case PaymentProvider.cielo:
        await pagarPedidoCielo(listaFormasDePagamentoSelecionadas);
        break;

      case PaymentProvider.desconhecido:
        await pagarPedido();
        break;
    }
  }

  // Funcoo chamanda quando clicar em pagar
  Future<void> pagarPedido() async {
    // com a conta pedida / sem conta
    double faltaReceber = double.tryParse(valorAReceber) ?? 0;
    if (faltaReceber > 0) {
      // Se valor a receber for MAIOR que zero, bloqueia o pedido
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ainda faltam R\$ $valorAReceber a receber'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // irsert
    // dialogo com load enquanto nao paga 
    bool pagamentoSucesso = await insertPagamentos();
    if(pagamentoSucesso){
      // dialogo de pagemnto realizado com suceso ou sem sucesso
      pedidoPagoComSucesso();
    } else {
      // dialogo de pagemnto realizado sem 
      erroAoPagarPedido();
    }
    
  }

  // calcular recebimentos com o dialogo
  // Helpers para conversão e formatação
  double _parseString(String value) {
    if (value.isEmpty) return 0.0;
    return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
  }

  String _formatDouble(double value) {
    return value.toStringAsFixed(2);
  }

  calcularRecebimentos({bool mostrarDialogo = true}) {
    double totalRecebido = 0.0;

    // Soma todos os valores já adicionados na lista de pagamentos
    for (var forma in listaFormasDePagamentoSelecionadas) {
      totalRecebido += _parseString(forma['valor'].toString());
    }

    // Pega o valor total da comanda
    double totalComanda = _parseString(valorTotalLiquidoSelect);
    
    // Normaliza para 2 casas decimais para evitar erros de ponto flutuante
    totalRecebido = double.parse(totalRecebido.toStringAsFixed(2));
    totalComanda = double.parse(totalComanda.toStringAsFixed(2));

    // Calcula quanto ainda falta receber (com normalização de precisão)
    double valorAReceberCalculado = double.parse((totalComanda - totalRecebido).toStringAsFixed(2));
    double valorTrocoDoubleCalculado = 0.0;

    // Se o valor recebido for maior que o total, gera troco
    if (valorAReceberCalculado < 0) {
      valorTrocoDoubleCalculado = valorAReceberCalculado.abs();
      valorAReceberCalculado = 0.0;
    }

    setState(() {
      valorRecebido = _formatDouble(totalRecebido);
      valorRecebidoDouble = totalRecebido;
      valorAReceber = _formatDouble(valorAReceberCalculado);
      valorReceberDouble = valorAReceberCalculado;
      valorTrocoDouble = valorTrocoDoubleCalculado;
      valorTroco = _formatDouble(valorTrocoDoubleCalculado);
    });

    // Se o valor total foi atingido e não houver diálogo aberto, abre confirmação
    if (mostrarDialogo && valorAReceberCalculado <= 0.0 && !dialogoConfirmacaoAberto) {
      dialogoConfirmacaoAberto = true;
      shownDialogaAlertTwoBottom(
        context: context,
        title: "Confirmar pagamento?",
        message: valorTrocoDoubleCalculado > 0.0
            ? "Valor do troco: R\$${_formatDouble(valorTrocoDoubleCalculado)}\nConfirma pagamento?"
            : "",
        icon: Icons.check,
        onConfirm: () async {          
          // Revalida se ainda falta algo (por segurança)
          if (valorReceberDouble > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ainda faltam R\$ $valorAReceber a receber'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
            dialogoConfirmacaoAberto = false;
            return;
          }

          // ----------------------------------------------------------- OFICIAL ---------------------------------------------------------------
          /* final bool maquininhaDisponivel = await PagBankSmartPOS.estaDisponivel();

          if (maquininhaDisponivel) {
            // SmartPOS disponível: executa pagamento PagBank primeiro
            final bool pagBankAprovado = await pagarPedidoPagBank(listaFormasDePagamentoSelecionadas);
            if (pagBankAprovado) {
              // Todas as formas PagBank aprovadas: finaliza o pedido
              await pagarPedido();
            }
            // Se não aprovado, não finaliza — o diálogo de erro já foi exibido
          } else {
            // Sem SmartPOS: finaliza o pedido diretamente
            await pagarPedido();
          } */

          // -------------------------------------------------------------------------------------------------------------------------------

          // await realizarPagamentoMaquininhas(listaFormasDePagamentoSelecionadas);

          await pagarPedidoCielo(listaFormasDePagamentoSelecionadas);

          dialogoConfirmacaoAberto = false;
        },
        onCancel: () async {
          dialogoConfirmacaoAberto = false;
        },
      );
    }
  }

  adicionarPagamentoLista(
    String nomeMoeda,
    String numeroMoeda,
    String valorPagamento,
  ) {
    // Verifica se os campos não estão vazios
    if (nomeMoedaController.text.isNotEmpty &&
        valorPagarController.text.isNotEmpty) {
      /* String nomeMoedaSelecionada = 'Moeda Desconhecida';
      String numeroMoedaSelecionada = '0';

      // Busca o nome da moeda na lista original pelo número
      for (var f in listaFormasDePagamento) {
        if (f['numero'].toString() == nomeMoedaController.text) {
          nomeMoedaSelecionada = f['moeda'].toString();
          numeroMoedaSelecionada = f['numero'].toString();
          break;
        }
      } */

      setState(() {
        // Adiciona à lista de selecionadas
        listaFormasDePagamentoSelecionadas.add({
          'numero': numeroMoeda,
          'moeda': nomeMoeda,
          'valor': valorPagamento,
        });

        // Limpa os campos após adicionar (opcional)
        nomeMoedaController.clear();
        valorPagarController.clear();
      });

      calcularRecebimentos();
    } else {
      // Opcional: mostrar um aviso de que precisa preencher os campos
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preencha o código da moeda e o valor.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /* // Dialogo para escolher forma de pagamento
  Future<void> pagarPedidoSemConta() async {
    try {
      if (!mesaEmConta && !comandaEmConta) {
        double faltaReceber = double.tryParse(valorAReceber) ?? 0;
        if (faltaReceber > 0) {
          // Se valor a receber for MAIOR que zero, bloqueia o pedido
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ainda faltam R\$ $valorAReceber a receber'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          return;
        } else {
          calcularRecebimentos();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível pedir conta, tente novamente'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  } */

  Future<void> botaoPagarPedido() async {
    /* try {
      if (!mesaEmConta && !comandaEmConta) {
        await pagarPedidoComConta();
      } else if (mesaEmConta || comandaEmConta) {
        await pagarPedidoSemConta();
      }
    } catch (e) {} */
    // com a conta pedida / sem conta
    double faltaReceber = double.tryParse(valorAReceber) ?? 0;
    if (faltaReceber > 0) {
      // Se valor a receber for MAIOR que zero, bloqueia o pedido
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ainda faltam R\$ $valorAReceber a receber'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    try {
      if (mesaEmConta && comandaEmConta) {
        double faltaReceber = double.tryParse(valorAReceber) ?? 0;
        if (faltaReceber > 0) {
          // Se valor a receber for MAIOR que zero, bloqueia o pedido
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ainda faltam R\$ $valorAReceber a receber'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          return;
        } else {
          calcularRecebimentos();
        }
      } else {
        calcularRecebimentos();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível pedir conta, tente novamente'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // Dialogo para escolher forma de pagamento
  /* Future<void> pagarPedidoComConta() async {
    // pedir conta
    await inserirConta(
      numeroTradepointSelecionada,
      numeroUsuario, // numero do nome selecionado
      comandaDoPedidoParaInsert,
      mesaDoPedidoParaInsert,
      numeroDePessoasString,
    );

    await zerarAtendimento();

    if (!mesaEmConta && !comandaEmConta) {
      double faltaReceber = double.tryParse(valorAReceber) ?? 0;
      if (faltaReceber > 0) {
        // Se valor a receber for MAIOR que zero, bloqueia o pedido
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ainda faltam R\$ $valorAReceber a receber'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      } else {
        calcularRecebimentos();
      }
      /* try{
        shownDialogaAlertTwoBottom(
        context: context,
        title: 'Confirma solicitação de conta?',
        message: () => 'Informe o número de pessoas:',
        message2: () => numeroDePessoasInt > 1 ?'Total por pessoa: R\$ $totalPorPessoaString | Nº pessoas: $numeroDePessoasString' : 'No valor de R\$ $valorTotalLiquidoSelect',
        icon: Icons.error,
        cancelText: 'Cancelar',
        confirmText: 'Sim',
        onConfirm: () async {
          try{
            
            await inserirConta(
              numeroTradepointSelecionada,
              numeroUsuario, // numero do nome selecionado 
              comandaDoPedidoParaInsert,
              mesaDoPedidoParaInsert,
              numeroDePessoasString
            );

            await zerarAtendimento();
            
            GarcomPageState().zerarAtendimento(); 

            if (!mounted) return;
            Navigator.pop(context); // Fecha o diálogo de "Pedir Conta"

            // Pequeno delay para a animação do diálogo anterior terminar
            Future.delayed(Duration(milliseconds: 100), () {
              if (mounted) showDialogFormasPagamento();
            });
            
          } catch(e){
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Não foi possível pedir conta, tente novamente'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
      );
      } catch(e){
        setState(() {
          cliqueiPagarPedido = false;
        });
      } */
    }
  } */

 void adicionarValor(){
    // Cliquei em confirmar
    if (aparecerConfirmar) {
      // Regra de validação: Dinheiro (1) pode ter troco, outros não
      double valorAPagarDouble = _parseString(valorPagarController.text);
      // Normaliza para evitar erro de precisão
      valorAPagarDouble = double.parse(valorAPagarDouble.toStringAsFixed(2));
      double valorReceberNormalizado = double.parse(valorReceberDouble.toStringAsFixed(2));

      if (valorReceberDouble <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Você já informou o valor total'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else if (tipoMoedaSelecionado != "1" && valorAPagarDouble > valorReceberNormalizado) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Esta forma de pagamento não pode gerar troco'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() {
          tipoMoedaSelecionado = "";
        });
      } else {
        // Adiciona o pagamento
        adicionarPagamentoLista(
          nomeMoedaController.text,
          numeroMoedaController.text,
          valorPagarController.text,
        );
        setState(() {
          aparecerConfirmar = false;
          showKeyboardNumero = false;
          tipoMoedaSelecionado = "";
        });
      }
    } else {
      // Abre o campo para digitar valor
      if (valorReceberDouble > 0.0) {
        setState(() {
          valorPagarController.text = valorAReceber;
          aparecerConfirmar = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Você já informou o valor total'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      calcularRecebimentos(mostrarDialogo: false);
    }
  }

  Future<void> showDialogFormasPagamento() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        // Criamos a lista de widgets uma única vez aqui para performance
        final botoesPagamento = funcoesController.listaFormasDePagamento.map((forma) {
          String moeda = forma['moeda'].toString();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: getCorPagamento(moeda, theme),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  print(
                    "Selecionado: ${forma['moeda']} (ID: ${forma['numero']})",
                  );
                  Navigator.pop(context);
                  await limparView();
                  Get.back();
                  if (mounted)
                    setState(() {
                      cliqueiPagarPedido = false;
                    });
                },
                child: Text(
                  moeda.toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          );
        }).toList();

        return Dialog(
          insetPadding: EdgeInsets.all(15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width > 600
                ? 500
                : double.infinity,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(onPressed: () {}, child: Text('CPF')),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (mounted)
                            setState(() {
                              cliqueiPagarPedido = false;
                            });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                        ),
                        child: Text(
                          'CANCELAR',
                          style: TextStyle(color: theme.colorScheme.onPrimary),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    'R\$ $valorTotalLiquidoSelect',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Selecione a forma de pagamento',
                    style: TextStyle(color: theme.colorScheme.surfaceDim),
                  ),
                  SizedBox(height: 10),
                  Divider(),
                  SizedBox(height: 10),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(children: botoesPagamento),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color getCorPagamento(String moeda, ThemeData theme) {
    moeda = moeda.toLowerCase();
    if (moeda.contains('debito')) return theme.colorScheme.primary;
    if (moeda.contains('credito')) return theme.colorScheme.secondary;
    if (moeda.contains('pix')) return theme.colorScheme.tertiary;
    if (moeda.contains('vale') ||
        moeda.contains('refeicao') ||
        moeda.contains('voucher'))
      return theme.colorScheme.shadow;
    return theme.colorScheme.outline;
  }

  // Função para mostrar mensagem de pedido pago com sucesso
  Future<void> pedidoPagoComSucesso() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        /* Future.delayed(Duration(milliseconds: 1388), () {
          if (Navigator.canPop(ctx)) {
            Navigator.pop(ctx);
          }
        }); */
        // Future.delayed(Duration(milliseconds: 1388), () {
        Future.delayed(Duration(milliseconds: 2000), () {
          if (Navigator.canPop(ctx)) {
            // Navigator.pop(ctx);
            if (rotaAnterior == "garcom") {
              Get.toNamed('/garcom');
            } else if (rotaAnterior == "mapa") {
              Get.toNamed('/mapa');
            } else {
              Get.toNamed('/garcom');
            } 
          }
        });

        return Center(
          child: TweenAnimationBuilder(
            duration: Duration(milliseconds: 500),
            tween: Tween<double>(begin: 0, end: 1),
            curve: Curves.easeOutCubic,
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Dialog(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                          size: 80,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Pedido pago com sucesso!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Função para mostrar mensagem de erro ao pagar pedido
  Future<void> erroAoPagarPedido() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(Duration(milliseconds: 1400), () {
          if (Navigator.canPop(ctx)) {
            Navigator.pop(ctx);
          }
        });

        return Center(
          child: TweenAnimationBuilder(
            duration: Duration(milliseconds: 500),
            tween: Tween<double>(begin: 0, end: 1),
            curve: Curves.easeOutCubic,
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Dialog(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error,
                          color: Theme.of(context).colorScheme.error,
                          size: 80,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Erro ao pagar pedido!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Dialogo com dois botões de erro
  Future<void> shownDialogaAlertTwoBottom({
    required BuildContext context,
    String title = 'Confirmação',
    IconData icon = Icons.home,
    String cancelText = 'Não',
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
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // Texto centralizado (atualizado para ser reativo)
                        if (message != null && message != "")
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

                        // Texto centralizado (atualizado para ser reativo)
                        if (message2 != null)
                          Padding(
                            padding: EdgeInsets.only(bottom: 10.0),
                            child: Text(
                              message2 is Function
                                  ? (message2 as Function)()
                                  : message2.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 15,
                                color: Theme.of(ctx).colorScheme.onSurface,
                              ),
                            ),
                          ),

                        if (message2 != null || message2 != "")
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
                                  backgroundColor: Theme.of(
                                    ctx,
                                  ).colorScheme.primary,
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
      },
    );
  }

  // Buscar se comanda esta em conta
 /*  Future<void> buscarCaixas() async {
    try {
      String dadosJson = await Connection().select("""
          SELECT MAX(mc.numero), mc.status, mc.numerocaixa_FK, c.nome FROM movimentacaocaixas AS mc, caixas AS c WHERE mc.numerocaixa_FK=c.numero AND mc.STATUS='1' GROUP BY mc.numerocaixa_FK ORDER BY mc.numerocaixa_FK;
        """);

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        listaCaixas = lista;
        print(">>>Lista de caixas<<<$lista"); // flutter: >>>Lista de caixas<<<[{MAX(mc.numero): 254, status: 1, numerocaixa_FK: 1, nome: SALAO}]
      } else {
        listaCaixas = [];
      }
    } catch (e) {
      print(">>>Erro ao buscar caixas: $e<<<");
    }
  } */

  // Função com o popup para selecionar garçom
  void popupSelecionarCaixa() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Align(
            alignment: Alignment.center,
            child: Text(
              "Selecione um caixa",
              style: TextStyle(
                fontSize: 20, // ou qualquer outro estilo que desejar
              ),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: funcoesController.listaCaixas.isEmpty
                ? Center(child: Text("Nenhum caixa disponível!!!"))
                : ListView.builder(
                    itemCount: funcoesController.listaCaixas.length,
                    itemBuilder: (context, index) {
                      final caixa = funcoesController.listaCaixas[index];

                      return Card(
                        child: ListTile(
                          title: Text("${caixa['numerocaixa_FK'].toString()} - ${caixa['nome']}"),
                          // subtitle: Text("Número: ${garcom['numero']}"),
                          onTap: () async {
                            setState(() {
                              numeroTurnoCaixaSelecionado = caixa['MAX(mc.numero)'].toString();
                              statusCaixaSelecionado = caixa['status'].toString();
                              numeroCaixaSelecionado = caixa['numerocaixa_FK'].toString();
                              nomeCaixaSelecionado = caixa['nome'].toString();
                            });
                            Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
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
      // Corpo da tela
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double h = constraints.maxHeight;
          final double k = MediaQuery.of(context).size.height * 0.20;
          return SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              height: showKeyboardNumero ? h + k : h,
              child: Column(
                children: [
                  // Detalhes do pedidio
                  Container(
                    height: MediaQuery.of(context).size.height * 0.07,
                    decoration: BoxDecoration(
                      color: colorScheme.outline,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Botão Voltar
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                await limparView();
                                Get.back();
                              },
                            ),
                          ),
                        ),

                        // Centro - Detalhes do Pedido
                        Align(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'DETALHES DO PEDIDO',
                                style: TextStyle(
                                  color: colorScheme.onPrimary.withOpacity(0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                detalhesPedido,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Direita - Total
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () async {
                                // await buscarCaixas();
                                setState(() {
                                  showKeyboardNumero = false;
                                });
                                popupSelecionarCaixa();
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'CAIXA ${numeroCaixaSelecionado}',
                                    style: TextStyle(
                                      color: colorScheme.onPrimary.withOpacity(0.8),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${nomeCaixaSelecionado}',
                                    style: TextStyle(
                                      color: colorScheme.onPrimary.withOpacity(0.8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ), 
                      ],
                    ),
                  ),

                  // Cabeçalho da tabela
                  // Seção de entrada de pagamento (Código da Forma e Valor)
                  /* Padding(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 4, top: 4),
            child: Row(
              children: [
                // Campo: Código da Forma de Pagamento
                Expanded(
                  flex: 3,
                  child: Container(
                    alignment: Alignment.center,
                    height: 55,
                    child: TextField(
                      controller: nomeMoedaController,
                      focusNode: nomeMoedaFocus,
                      readOnly: true,
                      showCursor: true,
                      cursorColor: colorScheme.primary,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'NOME:',
                        labelStyle: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                        filled: true,
                        fillColor: colorScheme.primary.withOpacity(0.05),
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.transparent,
                            width: 1,
                          ),
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.transparent, // cor normal
                            width: 1,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                colorScheme.primary, // cor quando selecionado
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // Campo: Valor a Pagar
                Expanded(
                  flex: 5,
                  child: Container(
                    alignment: Alignment.center,
                    height: 55,
                    child: TextField(
                      controller: valorPagarController,
                      focusNode: valorPagarFocus,
                      onTap: () {
                        setState(() {
                          showKeyboardNumero = true;
                          Future.delayed(Duration(milliseconds: 150), () {
                            if (valorPagarFocus.canRequestFocus) {
                              valorPagarFocus.requestFocus();
                            }
                          });
                        });
                      },
                      readOnly: true,
                      showCursor: true,
                      cursorColor: colorScheme.primary,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'VALOR A PAGAR',
                        labelStyle: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                        prefixText: 'R\$ ',
                        prefixStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                        filled: true,
                        fillColor: colorScheme.primary.withOpacity(0.05),
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.transparent,
                            width: 1,
                          ),
                        ),

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.transparent, // cor normal
                            width: 1,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                colorScheme.primary, // cor quando selecionado
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // Botão Confirmar Pagamento
                Material(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      adicionarPagamentoLista(
                        nomeMoedaController.text,
                        numeroMoedaController.text,
                        valorPagarController.text,
                      );
                      setState(() {
                        showKeyboardNumero = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 50,
                      height: 50,
                      child: Icon(
                        Icons.check_rounded,
                        color: colorScheme.onPrimary,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ), */

                  // Lista de metodos pagamento
                  if (funcoesController.listaFormasDePagamento.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              size: 48,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Nenhuma forma de pagamento adicionada',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: MediaQuery.textScalerOf(
                                  context,
                                ).scale(14),
                              ),
                            ),
                            SizedBox(height: 8),
                            CircularProgressIndicator(),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.30,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: GridView.builder(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 100,
                                  crossAxisSpacing: 5,
                                  mainAxisSpacing: 5,
                                  childAspectRatio: 0.9,
                                ),
                            itemCount: funcoesController.listaFormasDePagamento.length,
                            itemBuilder: (context, index) {
                              final forma = funcoesController.listaFormasDePagamento[index];
                              final nomeMoeda = forma['moeda'].toString();
                              final numeroMoeda = forma['numero'].toString();
                              // final tipoMoedaFunc = int.parse(forma['tipo'].toString()) ?? 0 ;
                              final tipoMoeda = forma['tipo'].toString();

                              final UpperCaseNomeMoeda = nomeMoeda.toUpperCase();
                              Color corBotao = escolherCorTipo(
                                int.tryParse(tipoMoeda.toString()) ?? 0
                              );

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    // HapticFeedback.lightImpact();
                                    nomeMoedaController.text = nomeMoeda;
                                    numeroMoedaController.text = numeroMoeda;
                                    setState(() {
                                      showKeyboardNumero = true;
                                      aparecerConfirmar = false;
                                      tipoMoedaSelecionado = tipoMoeda;
                                    });
                                    Future.delayed(
                                      const Duration(milliseconds: 150),
                                      () {
                                        if (valorPagarFocus.canRequestFocus) {
                                          FocusScope.of(context).requestFocus(valorPagarFocus);
                                        }
                                        if (_scrollController.hasClients) {
                                          _scrollController.animateTo(
                                            _scrollController.position.maxScrollExtent,
                                            duration: const Duration(milliseconds: 500),
                                            curve: Curves.easeOutCubic,
                                          );
                                        }
                                      },
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      color: corBotao,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: corBotao,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          numeroMoeda,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: colorScheme.onPrimary,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Text(
                                            nomeMoeda.toUpperCase(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onPrimary,
                                              letterSpacing: 0.2,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
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
                      ),
                    ),

                  // LISTA E FORMULARIO
                  Expanded(
                    child: Row(
                      children: [
                        /* // Lado Esquerdo - Lista de pagamentos registrados
                        Expanded(
                          flex: 1,
                          child: listaFormasDePagamentoSelecionadas.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet_outlined,
                                        size: 30,
                                        color: Colors.grey.withOpacity(0.3),
                                      ),
                                      SizedBox(height: 10),
                                      Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          'Nenhum pagamento registrado',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey.withOpacity(0.6),
                                            fontSize: MediaQuery.textScalerOf(
                                              context,
                                            ).scale(14),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface.withOpacity(0.5),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(5),
                                    ),
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.symmetric(vertical: 0),
                                    itemCount:
                                        listaFormasDePagamentoSelecionadas
                                            .length,
                                    itemBuilder: (context, index) {
                                      final forma =
                                          listaFormasDePagamentoSelecionadas[index];

                                      final nomeMoeda =
                                          forma['moeda']?.toString() ?? '';

                                      final valorMoeda = double.tryParse(
                                        forma['valor'].toString().replaceAll(
                                          ',',
                                          '.',
                                        ),
                                      );

                                      return Card(
                                        margin: EdgeInsets.symmetric(
                                          vertical: 4,
                                          horizontal: 8,
                                        ),
                                        elevation: 1,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Row(
                                            children: [
                                              // Informações do Pagamento
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      nomeMoeda,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    SizedBox(height: 2),
                                                    Text(
                                                      'R\$ ${valorMoeda?.toStringAsFixed(2).replaceAll('.', ',')}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 12,
                                                        color:
                                                            colorScheme.primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Botão de Excluir
                                              IconButton(
                                                onPressed: () async {
                                                  setState(() {
                                                    listaFormasDePagamentoSelecionadas
                                                        .removeAt(index);
                                                  });
                                                  await calcularRecebimentos(mostrarDialogo: false);
                                                },
                                                padding: EdgeInsets.zero,
                                                constraints: BoxConstraints(),
                                                icon: Icon(
                                                  Icons.delete_outline,
                                                  size: 20,
                                                  color: colorScheme.error,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                      /* Container(
                                  margin: EdgeInsets.only(
                                    left: 0,
                                    right: 0,
                                    top: 4,
                                    bottom: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    leading: Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withOpacity(
                                          0.1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        onPressed: () async {
                                          setState(() {
                                            listaFormasDePagamentoSelecionadas
                                                .removeAt(index);
                                          });
                                          await calcularRecebimentos(mostrarDialogo: false);
                                        },
                                        icon: Icon(
                                          Icons.delete_outline,
                                          // size: 10,
                                          color: colorScheme.error,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      nomeMoeda,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        // fontSize: 10,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'R\$ ${valorMoeda?.toStringAsFixed(2).replaceAll('.', ',')}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 10,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        /* IconButton(
                                          onPressed: () async {
                                            setState(() {
                                              listaFormasDePagamentoSelecionadas
                                                  .removeAt(index);
                                            });
                                            await calcularRecebimentos(mostrarDialogo: false);
                                          },
                                          icon: Icon(
                                            Icons.delete_outline,
                                            size: 10,
                                            color: colorScheme.error,
                                          ),
                                        ), */
                                      ],
                                    ),
                                  ),
                                ); */
                                    },
                                  ),
                                ),
                        ), */

                        // Lado Direito - Nova Coluna
                        if (nomeMoedaController.text.isEmpty)
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.monetization_on,
                                    size: 30,
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                  SizedBox(height: 10),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      'Selecione uma forma de pagamento',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.withOpacity(0.6),
                                        fontSize: MediaQuery.textScalerOf(
                                          context,
                                        ).scale(14),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                constraints: BoxConstraints(maxHeight: 220),
                                margin: EdgeInsets.only(
                                  top: 5,
                                  left: 8,
                                  bottom: 5,
                                  right: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: 8.0,
                                    right: 8.0,
                                    top: 8.0,
                                    bottom: 8.0,
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          margin: EdgeInsets.only(bottom: 5),
                                          child: TextField(
                                            controller: nomeMoedaController,
                                            focusNode: nomeMoedaFocus,
                                            readOnly: true,
                                            showCursor: false,
                                            cursorColor: colorScheme.primary,
                                            textAlign: TextAlign.center,
                                            textAlignVertical:
                                                TextAlignVertical.center,
                                            expands: true,
                                            maxLines: null,
                                            style: TextStyle(fontSize: 15, color: colorScheme.primary),
                                            decoration: InputDecoration(
                                              labelText: 'MOEDA:',
                                              labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.primary),
                                              filled: true,
                                              fillColor: colorScheme.primary.withOpacity(0.05),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: colorScheme.primary,
                                                  width: 1,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: colorScheme.primary,
                                                  width: 1,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: colorScheme.primary,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Campo: Valor a Pagar
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          margin: EdgeInsets.symmetric(vertical: 5),
                                          child: KeyboardActions(
                                            disableScroll: true,
                                            autoScroll: false,
                                            config: KeyboardActionsConfig(
                                              keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
                                              nextFocus: false,
                                              actions: [
                                                KeyboardActionsItem(
                                                  focusNode: valorPagarFocus,
                                                  toolbarButtons: [
                                                    (node) {
                                                      return GestureDetector(
                                                        onTap: () {
                                                          adicionarValor();
                                                          setState(() {
                                                            showKeyboardNumero = false;
                                                          });
                                                          FocusScope.of(context).unfocus();
                                                          Future.delayed(const Duration(milliseconds: 150), () {
                                                            if (_scrollController.hasClients) {
                                                              _scrollController.animateTo(
                                                                0, // volta para o topo
                                                                duration: const Duration(milliseconds: 500),
                                                                curve: Curves.easeOutCubic,
                                                              );
                                                            }
                                                          });
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
                                            controller: valorPagarController,
                                            focusNode: valorPagarFocus,
                                            onTap: () {
                                              setState(() {
                                                showKeyboardNumero = true;
                                              });
                                              Future.delayed(
                                                const Duration(milliseconds: 150),
                                                () {
                                                  if (valorPagarFocus.canRequestFocus) {
                                                    FocusScope.of(context).requestFocus(valorPagarFocus);
                                                  }
                                                  if (_scrollController.hasClients) {
                                                    _scrollController.animateTo(
                                                      _scrollController.position.maxScrollExtent,
                                                      duration: const Duration(milliseconds: 500),
                                                      curve: Curves.easeOutCubic,
                                                    );
                                                  }
                                                },
                                              );
                                            },
                                            onChanged: (value) {
                                              if (valorPagarController.text.isEmpty) {
                                                setState(() {
                                                  aparecerConfirmar = false;
                                                });
                                              } else {
                                                setState(() {
                                                  aparecerConfirmar = true;
                                                });
                                              }
                                            },
                                            onSubmitted: (value) {
                                              adicionarValor();
                                              setState(() {
                                                showKeyboardNumero = false;
                                              });
                                              FocusScope.of(context).unfocus();
                                              Future.delayed(const Duration(milliseconds: 150), () {
                                                if (_scrollController.hasClients) {
                                                  _scrollController.animateTo(
                                                    0, // volta para o topo
                                                    duration: const Duration(milliseconds: 500),
                                                    curve: Curves.easeOutCubic,
                                                    );  
                                                  }
                                                });
                                              },
                                              readOnly: false,
                                              showCursor: true,
                                              cursorColor: colorScheme.primary,
                                              textAlign: TextAlign.center,
                                              textAlignVertical: TextAlignVertical.center,
                                              // keyboardType: TextInputType.number,
                                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                                              expands: true,
                                              maxLines: null,
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: colorScheme.primary,
                                              ),
                                              decoration: InputDecoration(
                                                labelText: 'VALOR A PAGAR',
                                                labelStyle: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.primary,
                                                ),
                                                prefixText: 'R\$ ',
                                                prefixStyle: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.primary,
                                                ),
                                                filled: true,
                                                fillColor: colorScheme.primary.withOpacity(0.05),
                                                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                    color: colorScheme.primary,
                                                    width: 1,
                                                  ),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                    color: colorScheme.primary,
                                                    width: 1,
                                                  ),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                    color: colorScheme.primary,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Botão Confirmar Pagamento
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          margin: EdgeInsets.only(top: 5),
                                          child: Material(
                                            color: aparecerConfirmar
                                                ? colorScheme.primary
                                                : colorScheme.primaryFixed,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            elevation: 2,
                                            child: InkWell(
                                              onTap: () async {
                                                // Cliquei em confirmar
                                                  if (aparecerConfirmar) {
                                                    // Regra de validação: Dinheiro (1) pode ter troco, outros não
                                                    double valorAPagarDouble = _parseString(valorPagarController.text);
                                                    // Normaliza para evitar erro de precisão
                                                    valorAPagarDouble = double.parse(valorAPagarDouble.toStringAsFixed(2));
                                                    double valorReceberNormalizado = double.parse(valorReceberDouble.toStringAsFixed(2));
                            
                                                    if (valorReceberDouble <= 0) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Você já informou o valor total'),
                                                          backgroundColor: Theme.of(context).colorScheme.error,
                                                        ),
                                                      );
                                                    } else if (tipoMoedaSelecionado != "1" && valorAPagarDouble > valorReceberNormalizado) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Esta forma de pagamento não pode gerar troco'),
                                                          backgroundColor: Theme.of(context).colorScheme.error,
                                                        ),
                                                      );
                                                      setState(() {
                                                        tipoMoedaSelecionado = "";
                                                      });
                                                    } else {
                                                      // Adiciona o pagamento
                                                      adicionarPagamentoLista(
                                                        nomeMoedaController.text,
                                                        numeroMoedaController.text,
                                                        valorPagarController.text,
                                                      );
                                                      setState(() {
                                                        aparecerConfirmar = false;
                                                        showKeyboardNumero = false;
                                                        tipoMoedaSelecionado = "";
                                                      });
                                                    }
                                                  } else {
                                                    // Abre o campo para digitar valor
                                                    if (valorReceberDouble > 0.0) {
                                                      setState(() {
                                                        valorPagarController.text = valorAReceber;
                                                        aparecerConfirmar = true;
                                                      });
                                                    } else {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Você já informou o valor total'),
                                                          backgroundColor: Theme.of(context).colorScheme.error,
                                                        ),
                                                      );
                                                    }
                                                    calcularRecebimentos(mostrarDialogo: false);
                                                  }
                                              },
                                              borderRadius: BorderRadius.circular(
                                                12,
                                              ),
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    // Adicionar com valor
                                                    if (!aparecerConfirmar)
                                                      Text(
                                                        'Adicionar',
                                                        style: TextStyle(
                                                          color: colorScheme.onPrimary,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    if (!aparecerConfirmar)
                                                      Text(
                                                        'R\$ $valorAReceber',
                                                        style: TextStyle(
                                                          color: colorScheme
                                                              .onPrimary,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    if (aparecerConfirmar)
                                                      Text(
                                                        'Confirmar',
                                                        style: TextStyle(
                                                          color: colorScheme
                                                              .onPrimary,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Lado Esquerdo - Lista de pagamentos registrados
                        Expanded(
                          flex: 1,
                          child: listaFormasDePagamentoSelecionadas.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet_outlined,
                                        size: 30,
                                        color: Colors.grey.withOpacity(0.3),
                                      ),
                                      SizedBox(height: 10),
                                      Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          'Nenhum pagamento registrado',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey.withOpacity(0.6),
                                            fontSize: MediaQuery.textScalerOf(
                                              context,
                                            ).scale(14),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface.withOpacity(0.5),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(5),
                                    ),
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.symmetric(vertical: 0),
                                    itemCount:
                                        listaFormasDePagamentoSelecionadas
                                            .length,
                                    itemBuilder: (context, index) {
                                      final forma =
                                          listaFormasDePagamentoSelecionadas[index];

                                      final nomeMoeda =
                                          forma['moeda']?.toString() ?? '';

                                      final valorMoeda = double.tryParse(
                                        forma['valor'].toString().replaceAll(
                                          ',',
                                          '.',
                                        ),
                                      );

                                      return GestureDetector(
                                        onTap: () async {
                                          shownDialogaAlertTwoBottom(
                                            context: context,
                                            title: "Deseja remover pagamento?",
                                            message:
                                                "Remover $valorMoeda de $nomeMoeda?",
                                            icon: Icons.delete_outline,
                                            onConfirm: () async {
                                              setState(() {
                                                listaFormasDePagamentoSelecionadas
                                                    .removeAt(index);
                                              });
                                              await calcularRecebimentos(mostrarDialogo: false);
                                            },
                                            onCancel: () async {
                                              setState(() {});
                                            },
                                          );
                                        },
                                        child: Card(
                                          margin: EdgeInsets.only(
                                            top: 4,
                                            bottom: 4,
                                            left: 8,
                                            right: 16,
                                          ),
                                          elevation: 1,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Row(
                                              children: [
                                                // Informações do Pagamento
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        nomeMoeda,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      SizedBox(height: 2),
                                                      Text(
                                                        'R\$ ${valorMoeda?.toStringAsFixed(2).replaceAll('.', ',')}',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 12,
                                                          color: colorScheme
                                                              .primary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Botão de Excluir
                                                IconButton(
                                                  onPressed: () async {
                                                    shownDialogaAlertTwoBottom(
                                                      context: context,
                                                      title:
                                                          "Deseja remover pagamento?",
                                                      message:
                                                          "Remover $valorMoeda de $nomeMoeda?",
                                                      icon:
                                                          Icons.delete_outline,
                                                      onConfirm: () async {
                                                        setState(() {
                                                          listaFormasDePagamentoSelecionadas
                                                              .removeAt(index);
                                                        });
                                                        await calcularRecebimentos(mostrarDialogo: false);
                                                      },
                                                      onCancel: () async {
                                                        setState(() {});
                                                      },
                                                    );
                                                  },
                                                  padding: EdgeInsets.zero,
                                                  constraints: BoxConstraints(),
                                                  icon: Icon(
                                                    Icons.delete_outline,
                                                    size: 20,
                                                    color: colorScheme.error,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                      /* Container(
                                  margin: EdgeInsets.only(
                                    left: 0,
                                    right: 0,
                                    top: 4,
                                    bottom: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    leading: Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withOpacity(
                                          0.1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        onPressed: () async {
                                          setState(() {
                                            listaFormasDePagamentoSelecionadas
                                                .removeAt(index);
                                          });
                                          await calcularRecebimentos(mostrarDialogo: false);
                                        },
                                        icon: Icon(
                                          Icons.delete_outline,
                                          // size: 10,
                                          color: colorScheme.error,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      nomeMoeda,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        // fontSize: 10,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'R\$ ${valorMoeda?.toStringAsFixed(2).replaceAll('.', ',')}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 10,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        /* IconButton(
                                          onPressed: () async {
                                            setState(() {
                                              listaFormasDePagamentoSelecionadas
                                                  .removeAt(index);
                                            });
                                            await calcularRecebimentos(mostrarDialogo: false);
                                          },
                                          icon: Icon(
                                            Icons.delete_outline,
                                            size: 10,
                                            color: colorScheme.error,
                                          ),
                                        ), */
                                      ],
                                    ),
                                  ),
                                ); */
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  // if (!showKeyboardNumero)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        /* Container(
                          // color: colorScheme.secondary.withOpacity(0.5),
                          color: colorScheme.secondary.withOpacity(0.8),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'TOTAL:',
                                  style: TextStyle(
                                    fontSize: MediaQuery.textScalerOf(
                                      context,
                                    ).scale(15),
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'R\$ $valorTotalLiquidoSelect',
                                  style: TextStyle(
                                    fontSize: MediaQuery.textScalerOf(
                                      context,
                                    ).scale(15),
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ), */
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Container(
                                color: colorScheme.scrim.withOpacity(0.8),
                                padding: EdgeInsets.all(5.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      valorReceberDouble > 0 ||
                                              valorReceberDouble == 0
                                          ? 'À RECEBER:'
                                          : 'TROCO:',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: MediaQuery.textScalerOf(
                                          context,
                                        ).scale(12),
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.6),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        valorReceberDouble > 0 ||
                                                valorReceberDouble == 0
                                            ? 'R\$ $valorAReceber'
                                            : 'R\$ $valorTroco',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: MediaQuery.textScalerOf(
                                            context,
                                          ).scale(12),
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface
                                              .withOpacity(0.6),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Container(
                                color: colorScheme.surfaceTint.withOpacity(0.8),
                                padding: EdgeInsets.all(5.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'RECEBIDO',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: MediaQuery.textScalerOf(
                                          context,
                                        ).scale(12),
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.6),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        'R\$ $valorRecebido',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: MediaQuery.textScalerOf(
                                            context,
                                          ).scale(12),
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface
                                              .withOpacity(0.6),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        IntrinsicHeight(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Coluna de Pessoas e Por Pessoa
                              Expanded(
                                flex: 2,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    /* Text(
                                    textAlign: TextAlign.center,
                                    'Nº DE PESSOAS',
                                    style: TextStyle(
                                      fontSize: MediaQuery.textScalerOf(
                                        context,
                                      ).scale(10),
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: 5), */
                                    // Nº de Pessoas
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          // height: MediaQuery.of(context).size.height * 0.055,
                                          height:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.035,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              IconButton(
                                                onPressed:
                                                    diminuirQuantidadePessoas,
                                                icon: Icon(Icons.remove),
                                                color: colorScheme.primary,
                                                iconSize:
                                                    MediaQuery.textScalerOf(
                                                      context,
                                                    ).scale(15),
                                                padding: EdgeInsets.zero,
                                                constraints: BoxConstraints(
                                                  minWidth:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.width *
                                                      0.1,
                                                ),
                                              ),
                                              Text(
                                                numeroDePessoasString,
                                                style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.textScalerOf(
                                                        context,
                                                      ).scale(15),
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed:
                                                    aumentarQuantidadePessoas,
                                                icon: Icon(Icons.add),
                                                color: colorScheme.primary,
                                                iconSize:
                                                    MediaQuery.textScalerOf(
                                                      context,
                                                    ).scale(15),
                                                padding: EdgeInsets.zero,
                                                constraints: BoxConstraints(
                                                  minWidth:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.width *
                                                      0.1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                    // Por Pessoa
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'POR PESSOA:',
                                          style: TextStyle(
                                            fontSize: MediaQuery.textScalerOf(
                                              context,
                                            ).scale(12),
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface
                                                .withOpacity(0.6),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        // SizedBox(height: 6),
                                        SizedBox(height: 5),
                                        Container(
                                          height:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.035,
                                          width: double.infinity,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: colorScheme.secondary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: colorScheme.secondary
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            !mesaEmConta && !comandaEmConta
                                                // sem conta
                                                ? 'R\$ $totalPorPessoaString'
                                                // com conta
                                                : 'R\$ $totalPorPessoaString',
                                            // totalPorPessoaSelect
                                            style: TextStyle(
                                              fontSize: MediaQuery.textScalerOf(
                                                context,
                                              ).scale(15),
                                              fontWeight: FontWeight.w800,
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondary.withOpacity(
                                      0.2,
                                    ),
                                    // borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.all(5.0),
                                  child: Column(
                                    // mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        // CrossAxisAlignment.start,
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        textAlign: TextAlign.center,
                                        'TOTAL:',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: MediaQuery.textScalerOf(
                                            context,
                                          ).scale(15),
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      Center(
                                        child: Text(
                                          textAlign: TextAlign.center,
                                          'R\$ $valorTotalLiquidoSelect',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: MediaQuery.textScalerOf(
                                              context,
                                            ).scale(15),
                                            color: colorScheme.primary,
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
                      ],
                    ),
                  ),

                  // Linha com botoes caso conta nao pedida
                  // if (!showKeyboardNumero)
                    Row(
                      children: [
                        // Botão pagar pedido
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 8,
                              bottom: 8,
                            ),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.07,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: valorReceberDouble <= 0.0
                                      ? Theme.of(context).colorScheme.outline
                                      : Theme.of(
                                          context,
                                        ).colorScheme.surfaceTint,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: () {
                                  if (cliqueiPagarPedido || _processandoCielo) {
                                    return;
                                  }
                                  cliqueiPagarPedido = true;
                                  try {
                                    if (valorReceberDouble <= 0.0) {
                                      botaoPagarPedido();
                                    } else {
                                      return;
                                    }
                                  } catch (e) {
                                    cliqueiPagarPedido = false;
                                  }
                                  cliqueiPagarPedido = false;
                                },
                                child: Text(
                                  'PAGAR',
                                  style: TextStyle(
                                    fontSize: MediaQuery.textScalerOf(
                                      context,
                                    ).scale(14),
                                    fontWeight: FontWeight.bold,
                                    color: valorReceberDouble >= 0.0
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  /* if (showKeyboardNumero)
                    Container(
                      height: MediaQuery.of(context).size.height * 0.40,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(),
                          /* // GRID DO TECLADO
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final int crossAxisCount = 3;
                                final int itemCount =
                                    12; // agora vai até 10 somente
                                final double spacing = 8.0;

                                final int rows = (itemCount / crossAxisCount)
                                    .ceil();

                                final double cellWidth =
                                    (constraints.maxWidth -
                                        (spacing * (crossAxisCount - 1))) /
                                    crossAxisCount;
                                final double cellHeight =
                                    (constraints.maxHeight -
                                        (spacing * (rows - 1))) /
                                    rows;
                                final double childAspectRatio =
                                    cellWidth / cellHeight;

                                return GridView.builder(
                                  padding: const EdgeInsets.all(12),
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: itemCount,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
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
                                          padding: EdgeInsets.zero,
                                          backgroundColor:
                                              colorScheme.onPrimary,
                                        ),
                                        child: Icon(
                                          Icons.backspace,
                                          size: 32,
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
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: const Text(
                                            "0",
                                            style: TextStyle(fontSize: 28),
                                          ),
                                        ),
                                      );
                                    } else if (index == 11) {
                                      // Botão para fechar teclado
                                      return ElevatedButton(
                                        onPressed: () => _adicionarNumero(","),
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.zero,
                                          ),
                                          padding: EdgeInsets.zero,
                                          backgroundColor: colorScheme.primary,
                                        ),
                                        child: Center(
                                          child: Transform.translate(
                                            offset: Offset(0, -8),
                                            child: Text(
                                              ",",
                                              style: TextStyle(
                                                fontSize: 32,
                                                color: colorScheme.onPrimary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                      /* ElevatedButton(
                                onPressed: isProcessingConfirmar
                                    ? null
                                    : _confirmarTeclado,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  padding: EdgeInsets.zero,
                                  backgroundColor: colorScheme.primary,
                                ),
                                child: Icon(
                                  Icons.keyboard_return,
                                  size: 32,
                                  color: colorScheme.onPrimary,
                                ),
                              ); */
                                    }

                                    final numero = (index + 1).toString();
                                    return ElevatedButton(
                                      onPressed: () => _adicionarNumero(numero),
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.zero,
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          numero,
                                          style: TextStyle(fontSize: 28),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ), */

                          /* // BOTÃO FECHAR TECLADO
                          Container(
                            width: double.infinity,
                            height: 60,
                            /* padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: ,
                    ), */
                            padding: EdgeInsets.only(
                              bottom: 8,
                              top: 8,
                              right: 12,
                              left: 12,
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  showKeyboardNumero = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(0),
                                ),
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_down_outlined,
                                size: 32, // ícone maior
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ), */
                        ],
                      ),
                    ), */
                  // ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
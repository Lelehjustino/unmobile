import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:un_recepcao/api/stone_service.dart';
import 'package:un_recepcao/controllers/payment_service.dart';
import 'package:un_recepcao/controllers/views/funcoes_controller.dart';
import 'package:un_recepcao/controllers/views/painel_controller.dart';
import 'package:un_recepcao/data/data_class.dart';
import 'package:un_recepcao/views/garcom_page.dart';
import 'package:un_recepcao/views/mapa_page.dart';
import 'package:un_recepcao/views/pagamento_page.dart';
import 'package:un_recepcao/widgets/side_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class InformacoesPedidoPage extends StatefulWidget {
  const InformacoesPedidoPage({super.key});

  @override
  State<InformacoesPedidoPage> createState() => InformacoesPedidoPageState();
}

class InformacoesPedidoPageState extends State<InformacoesPedidoPage>
    with SingleTickerProviderStateMixin {

  String versaoAplicacao = FuncoesController().versaoDoApp;

  final FuncoesController funcoesController = Get.find<FuncoesController>();
  final PainelController painelController = Get.find<PainelController>();

  // Variáveis para receber e ajeitar args
  String numeropedido = Get.arguments['numeropedido'];
  String rotaAnterior = Get.arguments['page'];
  String numeroDelivery = Get.arguments['numeroDelivery'];
  String rotaAnteriorPage = "";

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

  String abertoPedido = "";
  String fechadoPedido = "";
  String clienetePedido = "";
  String telefonePedido = "";

/*   String tipoDoPedido = "";
  bool logicaPorMesa = false;
  bool logicaPorComanda = false;
  bool logicaPorComandaNaMesa = false; */

  bool cliqueiConta = false;

  String formaPagamento = "";

  //List<dynamic> listaFormasDePagamento = [];
  bool cliqueiPagarPedido = false;


 /*  String numeroTurnoCaixa = "";
  String statusCaixa = "";
  String numeroCaixa = "";
  String nomeCaixa = "";
  List<dynamic> listaCaixas = []; */
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
    calcularTotalPorPessoa();
    _loadNumeroLicenca();
    _loadNumeroGarcom();
    zeraValores();
    _loadNomeEmpresa();
    numeroDePessoasInt = 1;
    numeroDePessoasString = '1';

    // Selects
    buscarInformacoesCliente();
    buscarListaProdutos();
    buscarValoresDoPedido();
    buscarFormaPagamento();
    
    // buscarPagamento();
    //buscarCaixas();
  }

  rotaAnteriorFuncao() {
    setState(() {
      rotaAnteriorPage = rotaAnterior;
    });
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
    print("numeroDelivery: $numeroDelivery ");
    if (numeropedido == "") {
      numeropedido = "0";
    }
    if (numeroDelivery == "") {
      numeroDelivery = "0";
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
  void calcularTotalPorPessoa() {
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
    await _loadNumeroLicenca();
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
      String dadosJson = await Connection().select(
        """
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
        """,
      );

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

  // Função para buscar valores do pedido
  Future<void> buscarFormaPagamento() async {
    try {
      String dadosJson = await Connection().select(
        """
          SELECT formapagamento FROM delivery WHERE numerodelivery = '$numeroDelivery';
        """,
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        final valor = lista[0]['formapagamento'].toString();

        setState(() {
          formaPagamento = valor;
        });
      } else {
        setState(() {
          formaPagamento = "";
        });
      }
    } catch (e) {
      print("Erro ao carregar forma de pagamento: $e");
      setState(() {
        formaPagamento = "";
      });
    }
  }

  // Função para buscar valores do pedido
  Future<void> buscarValoresDoPedido() async {
    print('numero pedido $numeropedido');
    try {
      String dadosJson = await Connection().select(
        """
         SELECT descricaoformaspagamento, abertura, fechamento, valorprodutos, valoradicionais, valorservico, valordesconto, valortotalliquido, pessoas, valortotalliquido / pessoas AS totalPorPessoa  FROM pedidos    WHERE numero = '$numeropedido';
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

        final aberturaFormatado = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.parse(valor8));
        final fechamentoFormatado = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.parse(valor9));

        setState(() {
          listaValoresDoPedidoSelect = lista;
          valorProdutosSelect = valor;
          valorAdicionaisSelect = valor2;
          valorServicoSelect = valor3;
          valorDescontoSelect = valor4;
          valorTotalLiquidoSelect = valor5;
          pessoasSelect = valor6;
          totalPorPessoaSelect = valor7;
          abertoPedido = aberturaFormatado;
          fechadoPedido = fechamentoFormatado;
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
          abertoPedido = "";
          fechadoPedido = "";
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
        abertoPedido = "";
        fechadoPedido = "";
      });
    }
  }

  // Função para buscar valores do pedido
  Future<void> buscarInformacoesCliente() async {
    // $numeropedido
    try {
      /* String dadosJson = await Connection().select(
        """
         SELECT abertura, fechamento, valorprodutos, valoradicionais, valorservico, valordesconto, valortotalliquido, pessoas, valortotalliquido / pessoas AS totalPorPessoa  FROM pedidos    WHERE numero = '$numeropedido';
        """,
      ); */

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
              c.telefone AS telefoneCliente
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

        final aberturaFormatado = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.parse(valor8));
        final fechamentoFormatado = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.parse(valor9));

        setState(() {
          listaValoresDoPedidoSelect = lista;
          valorProdutosSelect = valor;
          valorAdicionaisSelect = valor2;
          valorServicoSelect = valor3;
          valorDescontoSelect = valor4;
          valorTotalLiquidoSelect = valor5;
          pessoasSelect = valor6;
          totalPorPessoaSelect = valor7;
          abertoPedido = aberturaFormatado;
          fechadoPedido = fechamentoFormatado;
          clienetePedido = valor10;
          telefonePedido = valor11;
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
          abertoPedido = "";
          fechadoPedido = "";
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
        abertoPedido = "";
        fechadoPedido = "";
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _focusNode.dispose();
    animationController.dispose();
    super.dispose();
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
    numeroDelivery = '';

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
  }

  // Dialogo com dois botões de erro
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
                                  ?.copyWith(fontWeight: FontWeight.bold),
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

                        // Controlador de quantidade de pessoas
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.055,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    diminuirQuantidadePessoas();
                                    setDialogState(() {});
                                  },
                                  icon: Icon(Icons.remove),
                                  color: Theme.of(ctx).colorScheme.primary,
                                  iconSize: MediaQuery.textScalerOf(
                                    context,
                                  ).scale(20),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(
                                    minWidth:
                                        MediaQuery.of(context).size.width * 0.1,
                                  ),
                                ),
                                Text(
                                  numeroDePessoasString,
                                  style: TextStyle(
                                    fontSize: MediaQuery.textScalerOf(
                                      context,
                                    ).scale(20),
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(ctx).colorScheme.onSurface,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    aumentarQuantidadePessoas();
                                    setDialogState(() {});
                                  },
                                  icon: Icon(Icons.add),
                                  color: Theme.of(ctx).colorScheme.primary,
                                  iconSize: MediaQuery.textScalerOf(
                                    context,
                                  ).scale(20),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(
                                    minWidth:
                                        MediaQuery.of(context).size.width * 0.1,
                                  ),
                                ),
                              ],
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

  @override
  Widget build(BuildContext context) {
    // Agrupar produtos iguais
    // Lista que vai ser apresentada na tela
    Map<String, dynamic> produtosAgrupados = {};
    // Varre a lista de produtos
    for (var item in listaProdutos) {
      // Cria uma chave única para cada produto
      String key =
          "${item['nome_produto']}_${item['valorunitario']}_${item['sabores']}_${item['observacao']}_${item['tipo_produto']}";
      // Se a chave já existir, soma a quantidade
      if (produtosAgrupados.containsKey(key)) {
        // Soma a quantidade
        double qtdAtual =
            double.tryParse(
              produtosAgrupados[key]['total_quantidade'].toString(),
            ) ??
            0; // pega o do atual
        double qtdNova =
            double.tryParse(item['total_quantidade'].toString()) ??
            0; // pega o do novo -> que esta sendo adicionado / varrido
        produtosAgrupados[key]['total_quantidade'] = (qtdAtual + qtdNova)
            .toString(); // soma as quantidades

        // Soma o valor
        double valorAtual =
            double.tryParse(produtosAgrupados[key]['total_valor'].toString()) ??
            0; // pega o do atual
        double valorNovo =
            double.tryParse(item['total_valor'].toString()) ??
            0; // pega o do novo -> que esta sendo adicionado / varrido
        produtosAgrupados[key]['total_valor'] = (valorAtual + valorNovo)
            .toStringAsFixed(2); // soma os valores
      } else {
        produtosAgrupados[key] = Map<String, dynamic>.from(
          item,
        ); // adiciona o item na lista, pois não tem igual
      }
    }
    List<dynamic> listaAgrupada = produtosAgrupados.values
        .toList(); // transforma o map em lista

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
      // Corpo da tela
      body: Column(
        children: [
          // Barra superior com botão voltar
          Container(
            height: MediaQuery.of(context).size.height * 0.06,
            color: colorScheme.outline,
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: GestureDetector(
                    onTap: () async {
                      await limparView();
                      await rotaAnteriorFuncao();
                      Get.back();
                    },
                    child: Icon(
                      Icons.arrow_back, 
                      color: colorScheme.onPrimary,
                      size: 40,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'INFORMAÇÕES DO PEDIDO',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Icon(Icons.arrow_back, color: Colors.transparent),
                ),
              ],
            ),
          ),

         /*  // Cabeçalho superior (Pedido Aberto)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pedido aberto',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ), */

          // Seção de Informações do Pedido (3 quadros)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Quadro 1: Número Delivery
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            numeroDelivery,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Delivery entrega',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Quadro 2: Detalhes do Cliente/Pedido
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildInfoRow('Pedido:', numeropedido),
                          _buildInfoRow('Cliente:', clienetePedido),
                          _buildInfoRow('Telefone:', telefonePedido),
                          _buildInfoRow('Aberto:', abertoPedido),
                          _buildInfoRow('Fechado:', fechadoPedido),
                          _buildInfoRow('Motoboy:', painelController.nomeMotoboySelecionado.value),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Quadro 3: Pagamento e Entrega
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
                            ),
                            child: Text(
                              'Entrega',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Moeda Pagamento', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                    SizedBox(height: 4),
                                    Text(
                                      formaPagamento,
                                      style: TextStyle(
                                        color: Colors.blue.shade900,
                                        fontSize: 16,
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
                  ),
                ],
              ),
            ),
          ),

          // Cabeçalho da tabela
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
            child: Container(
              color: Colors.grey.shade200,
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Row(
                children: [
                  _buildTableHeader('Nº', 1),
                  _buildTableHeader('Produto', 4),
                  _buildTableHeader('Un', 1),
                  _buildTableHeader('Qtde', 2),
                  _buildTableHeader('Vendedor', 2),
                  _buildTableHeader('Produzido', 2),
                  _buildTableHeader('Serv(R\$)', 2),
                  _buildTableHeader('Unit(R\$)', 2),
                  _buildTableHeader('Total', 2, textAlign: TextAlign.end),
                  _buildTableHeader('Data/Hora', 3, textAlign: TextAlign.end),
                ],
              ),
            ),
          ),

          // Lista de produtos
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.symmetric(vertical: BorderSide(color: Colors.grey.shade300)),
                ),
                child: listaProdutos.isEmpty
                    ? Center(child: Text('Nenhum item adicionado', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: listaAgrupada.length,
                        itemBuilder: (context, index) {
                          final produto = listaAgrupada[index];
                          final nomeDoProduto = produto['nome_produto'].toString();
                          final quantidadeDoProduto = produto['total_quantidade'].toString();
                          final precoDoProduto = produto['valorunitario'].toString();
                          final totalDoProduto = produto['total_valor'].toString();
                          final id = produto['tipo_produto'].toString();
                          final saboresRaw = produto['sabores'] ?? '';
                          final observacao = produto['observacao'] ?? '';
                          final double quantidadeDoProdutoInt = double.tryParse(quantidadeDoProduto) ?? 0;
                          final nomeDoGarcom = produto['nome_garcom'] ?? '';
                          // DateFormat logic
                          String dataHora = '';
                          try {
                            if (produto['datahora'] != null) {
                               dataHora = DateFormat('dd/MM HH:mm').format(DateTime.parse(produto['datahora'].toString()));
                            }
                          } catch (_) {}

                          final List<Map<String, String>> sabores = saboresRaw
                              .toString()
                              .split('||')
                              .where((s) => s.isNotEmpty)
                              .map((item) {
                                final partes = item.split('::');
                                return {
                                  'nome': partes[0],
                                  'fracao': partes.length > 1 ? partes[1] : '',
                                };
                              })
                              .toList();

                          return Container(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                              color: index % 2 == 1 ? Colors.grey.shade50 : null,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            child: Row(
                              children: [
                                _buildTableCell(produto['numeroproduto_FK']?.toString() ?? '', 1),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nomeDoProduto,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (id == 'PZ')
                                        ...sabores.map((sabor) => Text(
                                          '${sabor['fracao'] == '1/1' ? '1' : sabor['fracao']} ${sabor['nome']}',
                                          style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                                        )),
                                      if (observacao.isNotEmpty)
                                        Text(
                                          'Obs: $observacao',
                                          style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.red.shade700),
                                        ),
                                    ],
                                  ),
                                ),
                                _buildTableCell('Un', 1),
                                _buildTableCell(quantidadeDoProdutoInt.toStringAsFixed(3), 2),
                                _buildTableCell(nomeDoGarcom, 2),
                                _buildTableCell('Sim', 2),
                                _buildTableCell('0.00', 2),
                                _buildTableCell(precoDoProduto, 2),
                                _buildTableCell(totalDoProduto, 2, textAlign: TextAlign.end, isBold: true),
                                _buildTableCell(dataHora, 3, textAlign: TextAlign.end),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),

          // Resumo financeiro (Subtotal, Adicionais, etc.)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      _buildSummaryBox('Subtotal', 'R\$ $valorProdutosSelect'),
                      SizedBox(width: 4),
                      _buildSummaryBox('Adicionais', 'R\$ $valorAdicionaisSelect'),
                      SizedBox(width: 4),
                      _buildSummaryBox('Serviços', 'R\$ $valorServicoSelect'),
                      SizedBox(width: 4),
                      _buildSummaryBox('Desconto', 'R\$ $valorDescontoSelect'),
                      SizedBox(width: 4),
                      _buildSummaryBox('TOTAL', 'R\$ $valorTotalLiquidoSelect', isTotal: true),
                    ],
                  ),
                ),
                /* SizedBox(width: 16),
                // Tabela de moedas lateral (Pagamentos)
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Column(
                      children: [
                        Container(
                          color: Colors.grey.shade100,
                          padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text('Moeda', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                              Expanded(flex: 1, child: Text('Valor', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.end)),
                            ],
                          ),
                        ),
                        Divider(height: 1),
                        Container(
                          height: 60,
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          child: Text('Nenhum pagamento', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                ), */
              ],
            ),
          ),

          /* // Seção Inferior: Auditoria e Conferência
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tabela de Auditoria (Logs)
                Expanded(
                  flex: 4,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Column(
                      children: [
                        // Cabeçalho da Auditoria
                        Container(
                          color: Colors.grey.shade200,
                          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: Row(
                            children: [
                              Expanded(flex: 1, child: Text('Hora', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                              Expanded(flex: 2, child: Text('Usuário', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                              Expanded(flex: 2, child: Text('PDV', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                              Expanded(flex: 6, child: Text('Operação', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                        Divider(height: 1),
                        // Lista de Auditoria (Vazia por enquanto)
                        Expanded(
                          child: Center(
                            child: Text('Nenhum registro de auditoria', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16),
                // Botão Conferência e Detalhes de Troco
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      // Botão Conferência (F5)
                      Container(
                        width: double.infinity,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 24, color: Colors.white),
                            Text('Conferência', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      // Recebido / Troco
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recebido:', style: TextStyle(fontSize: 10)),
                            Text('R\$ 0,00', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Troco:', style: TextStyle(fontSize: 10)),
                            Text('R\$ -$valorTotalLiquidoSelect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ), */
        ],
      ),
    );
  }

  // --- Assistentes de Visual ---

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          SizedBox(width: 4),
          Expanded(child: Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, int flex, {TextAlign textAlign = TextAlign.start}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 24,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey.shade400, width: 0.5)),
        ),
        child: Text(
          text,
          textAlign: textAlign,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, int flex, {TextAlign textAlign = TextAlign.start, bool isBold = false, Color color = Colors.black}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 24,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey.shade400, width: 0.5)),
        ),
        child: Text(
          text,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildSummaryBox(String label, String value, {bool isTotal = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          SizedBox(height: 2),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isTotal ? Theme.of(context).colorScheme.primary : Color(0xFFE0E0E0),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
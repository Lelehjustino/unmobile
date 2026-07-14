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
import 'package:un_recepcao/controllers/carrinho_controller.dart';

class ContaPage extends StatefulWidget {
  const ContaPage({super.key});

  @override
  State<ContaPage> createState() => ContaPageState();
}

class ContaPageState extends State<ContaPage>
    with SingleTickerProviderStateMixin {

  String versaoAplicacao = FuncoesController().versaoDoApp;

  final FuncoesController funcoesController = Get.put(FuncoesController());

  // Variáveis para receber e ajeitar args
  String numeropedido = Get.arguments['numeropedido'];
  String comandaDoPedido = Get.arguments['comanda'];
  String mesaDoPedido = Get.arguments['mesa'];
  String rotaAnterior = Get.arguments['page'];
  String comandaDoPedidoParaInsert = "";
  String mesaDoPedidoParaInsert = "";
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
  bool produtoKilo = false;

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

  //List<dynamic> listaFormasDePagamento = [];
  bool cliqueiPagarPedido = false;

  final painelController = Get.put(PainelController());

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
    arrumaVazioComanda();
    arrumarVazioMesa();
    zeraValores();
    _loadNomeEmpresa();
    numeroDePessoasInt = 1;
    numeroDePessoasString = '1';

    // Selects
    buscarListaProdutos();
    buscarValoresDoPedido();
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

  // Função para buscar lista de produtos
  /* Future<void> buscarListaProdutos() async {
    try {
      String dadosJson = await Connection().select(
        """
        SELECT
          v.numeroproduto_FK,
          v.valorunitario,

          SUM(
            CASE
              WHEN v.numerounidade_FK = '1' AND p.id IN ('E', 'P')
              THEN v.quantidade
              ELSE 0
            END
          ) AS total_quantidade,

          SUM(v.valorliquido) AS total_valor,
          v.datahora
        FROM vendas v
        INNER JOIN produtos p ON p.numero = v.numeroproduto_FK
        WHERE v.numeropedido_FK = '$numeropedido'
          AND v.cancelado = '0'
        GROUP BY
          v.numeroproduto_FK,
          v.valorunitario,
          v.datahora
        """
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      setState(() {
        listaProdutos = lista;
      });
    } catch (e) {
      print("Erro ao carregar listaProdutos: $e");
      setState(() {
        listaProdutos = [];
      });
    }
  } */
  Future<void> buscarListaProdutos() async {
    try {
      String dadosJson = await Connection().select(
        """
        SELECT
            p.nome AS nome_produto,
            p.id   AS tipo_produto,
            un.simbolo AS produto_un,

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

          INNER JOIN unidades un
            ON un.numero = p.numerounidade_FK

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

  /* // Buscar se comanda esta em conta
  Future<void> buscarCaixas() async {
    try {
      /* String dadosJson = await Connection().select("""
          SELECT MAX(mc.numero), mc.status, mc.numerocaixa_FK, c.nome FROM movimentacaocaixas AS mc, caixas AS c WHERE mc.numerocaixa_FK=c.numero AND mc.STATUS='1' GROUP BY mc.numerocaixa_FK ORDER BY mc.numero DESC;
        """); */

      String dadosJson = await Connection().select("""
        SELECT MAX(mc.numero), mc.status, mc.numerocaixa_FK, c.nome FROM movimentacaocaixas AS mc, caixas AS c WHERE mc.numerocaixa_FK=c.numero AND mc.STATUS='1' GROUP BY mc.numerocaixa_FK ORDER BY mc.numerocaixa_FK;
      """);

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        listaCaixas = lista;
        if (listaCaixas.length == 1) {
          setState(() {
            numeroTurnoCaixa = listaCaixas[0]['MAX(mc.numero)'].toString();
            statusCaixa = listaCaixas[0]['status'].toString();
            numeroCaixa = listaCaixas[0]['numerocaixa_FK'].toString();
            nomeCaixa = listaCaixas[0]['nome'].toString();
          });
        }
        print(
          ">>>Lista de caixas<<<$lista",
        ); // flutter: >>>Lista de caixas<<<[{MAX(mc.numero): 254, status: 1, numerocaixa_FK: 1, nome: SALAO}]
      } else {
        listaCaixas = [];
      }
    } catch (e) {
      print(">>>Erro ao buscar caixas: $e<<<");
    }
  } */

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
      String dadosJson = await Connection().select(
        """
         SELECT valorprodutos, valoradicionais, valorservico, valordesconto, valortotalliquido, pessoas, valortotalliquido / pessoas AS totalPorPessoa  FROM pedidos    WHERE numero = '$numeropedido';
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

  // Função para inserir venda
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
  }

  // Pagar pedido
  /* Future<void> buscarPagamento() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, moeda FROM formaspagamento WHERE operante='1' AND (tipo!='5' AND tipo!='99')",
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
  }

  // Dialogo para escolher forma de pagamento
  Future<void> pagarPedido() async {
    await funcoesController.buscarCaixas();
    await rotaAnteriorFuncao();
    if (funcoesController.listaCaixas.length == 1) {
      if (funcoesController.numeroTurnoCaixa.value != "") {
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
            'pageAnterior': rotaAnteriorPage,
          },
        );
      } else {
        popupSelecionarCaixa();
      }
    } else {
      popupSelecionarCaixa();
    }
  }

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
                          title: Text(
                            "${caixa['numerocaixa_FK'].toString()} - ${caixa['nome']}",
                          ),
                          // subtitle: Text("Número: ${garcom['numero']}"),
                          onTap: () async {
                            setState(() {
                              funcoesController.numeroTurnoCaixa.value = caixa['MAX(mc.numero)'].toString();
                              funcoesController.statusCaixa.value = caixa['status'].toString();
                              funcoesController.numeroCaixa.value = caixa['numerocaixa_FK'].toString();
                              funcoesController.nomeCaixa.value = caixa['nome'].toString();

                              Navigator.pop(context);
                            });

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
                                'pageAnterior': rotaAnteriorPage,
                              },
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
    );
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
    Map<String, dynamic> produtosAgrupados = {};

    for (var item in listaProdutos) {
    bool produtoKilo = item['produto_un']?.toString().toUpperCase() == 'KG';

    String key = "${item['nome_produto']}_${item['valorunitario']}_${item['sabores']}_${item['observacao']}_${item['tipo_produto']}";

    // Produto por KG nunca agrupa
    if (produtoKilo) {
      produtosAgrupados["${key}_${item['datahora']}_${item.hashCode}"] = Map<String, dynamic>.from(item);
      continue;
    }

    // Produtos UN agrupam normalmente
    if (produtosAgrupados.containsKey(key)) {
      double qtdAtual = double.tryParse(produtosAgrupados[key]['total_quantidade'].toString()) ?? 0;

      double qtdNova = double.tryParse(item['total_quantidade'].toString()) ?? 0;

      produtosAgrupados[key]['total_quantidade'] = (qtdAtual + qtdNova).toString();

      double valorAtual = double.tryParse(produtosAgrupados[key]['total_valor'].toString()) ?? 0;

      double valorNovo = double.tryParse(item['total_valor'].toString()) ?? 0;

      produtosAgrupados[key]['total_valor'] = (valorAtual + valorNovo).toStringAsFixed(2);
    } else {
      produtosAgrupados[key] = Map<String, dynamic>.from(item);
    }
  }

  List<dynamic> listaAgrupada = produtosAgrupados.values.toList();

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
      body: Column(
        children: [
          // Detalhes do pedidio
          Container(
            height: MediaQuery.of(context).size.height * 0.05,
            color: colorScheme.outline,
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () async {
                      await limparView();
                      await rotaAnteriorFuncao();
                      if(rotaAnteriorPage == "garcom"){
                        Get.back();
                      }else if(rotaAnteriorPage == "mapa"){
                        await zerarAtendimento();
                        Get.back();
                      } else {
                        await zerarAtendimento();
                        Get.back();
                      }
                    },
                    child: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
                  ),
                ),
                /* Expanded(child: Container()), */
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  'DETALHES DO PEDIDO',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  funcoesController.logicaPorMesa.value
                                      ? 'MESA: $mesaDoPedido'
                                      : funcoesController.logicaPorComanda.value
                                      ? 'COMANDA: $comandaDoPedido'
                                      : comandaDoPedido != "0" &&
                                            mesaDoPedido != "0"
                                      ? 'COMANDA: $comandaDoPedido MESA: $mesaDoPedido'
                                      : comandaDoPedido != "0"
                                      ? 'COMANDA: $comandaDoPedido'
                                      : mesaDoPedido != "0"
                                      ? 'MESA: $mesaDoPedido'
                                      : '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                /* Center(
                  child: Row(
                    children: [
                      Text(
                        'DETALHES DO PEDIDO',
                        maxLines: 1, // limita a 1 linha
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(
                        '-',
                        maxLines: 1, // limita a 1 linha
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                        SizedBox(width: 5),
                        Text(
                        logicaPorMesa ? 'MESA: $mesaDoPedido' : 'COMANDA: $comandaDoPedido',
                        maxLines: 1, // limita a 1 linha
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  ), */
                /* Expanded(child: Container()), */
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.arrow_back, color: Colors.transparent),
                ),
              ],
            ),
          ),

          // Cabeçalho da tabela
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'Produto',
                    style: TextStyle(
                      fontSize: MediaQuery.textScalerOf(context).scale(15),
                    ),
                  ),
                ),
                Expanded(flex: 1, child: Container()),
                /* Expanded(flex: 2, child: Text(
                  'Qtde.', 
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: MediaQuery.textScalerOf(context).scale(15),
                  ),
                )),
                Expanded(flex: 2, child: Text(
                  'Unit.', 
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: MediaQuery.textScalerOf(context).scale(15),
                  ),
                )), */
                Expanded(
                  flex: 2,
                  child: Text(
                    'Total',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: MediaQuery.textScalerOf(context).scale(15),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1),

          // Lista de produtos vazia
          if (listaProdutos.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Nenhum item adicionado',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            // Lista de produtos
            Expanded(
              child: ListView.builder(
                itemCount: listaAgrupada.length,
                itemBuilder: (context, index) {
                  final produto = listaAgrupada[index];
                  final nomeDoProduto = produto['nome_produto'].toString();
                  final quantidadeDoProduto = produto['total_quantidade']
                      .toString();
                  final precoDoProduto = produto['valorunitario'].toString();
                  final totalDoProduto = produto['total_valor'].toString();
                  final id = produto['tipo_produto'].toString();
                  final saboresRaw = produto['sabores'] ?? '';
                  final observacao = produto['observacao'] ?? '';
                  final double quantidadeDoProdutoDouble =
                      double.tryParse(quantidadeDoProduto) ?? 0;
                  final int quantidadeDoProdutoInt =
                      int.tryParse(quantidadeDoProduto) ?? 0;
                  final nomeDoGarcom = produto['nome_garcom'] ?? '';
                


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

                  return Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nomeDoProduto,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        // fontSize: tamanhoLetrasPequenas,
                                        fontSize: MediaQuery.textScalerOf(
                                          context,
                                        ).scale(12),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    Row(
                                      children: [
                                        Text(
                                          'Aten: ',
                                          style: TextStyle(
                                            fontSize: MediaQuery.textScalerOf(
                                              context,
                                            ).scale(12),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '$nomeDoGarcom',
                                          style: TextStyle(
                                            fontSize: MediaQuery.textScalerOf(
                                              context,
                                            ).scale(12),
                                            /* fontWeight: FontWeight.bold, */
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (id == 'PZ')
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: sabores.map((sabor) {
                                          if (sabor['fracao'].toString() ==
                                              '1/1') {
                                            sabor['fracao'] = '1';
                                          } else {
                                            sabor['fracao'] = sabor['fracao']
                                                .toString();
                                          }
                                          return Row(
                                            children: [
                                              Text(
                                                '${sabor['fracao']}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.textScalerOf(
                                                        context,
                                                      ).scale(10),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              Text(
                                                '${sabor['nome']}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.textScalerOf(
                                                        context,
                                                      ).scale(10),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                  ],
                                ),
                              ),
                              /* Expanded(flex: 2, child: 
                            Text((
                              double.tryParse(quantidadeDoProduto) ?? 0).toInt().toString(), 
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: MediaQuery.textScalerOf(context).scale(12),
                              ),
                            )), */
                              Expanded(
                                flex: 2,
                                child: Text(
                                  quantidadeDoProdutoDouble % 1 == 0
                                      ? '${quantidadeDoProdutoDouble.toInt()} x R\$ $precoDoProduto'
                                      : '${quantidadeDoProdutoDouble} x R\$ $precoDoProduto',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: MediaQuery.textScalerOf(
                                      context,
                                    ).scale(12), 
                                  ),
                                ),
                                /* child: Text(
                                  produtoKilo ?
                                  '${quantidadeDoProdutoDouble.toStringAsFixed(3)} x R\$ $precoDoProduto' : '${quantidadeDoProdutoDouble.toStringAsFixed(0)} x R\$ $precoDoProduto',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: MediaQuery.textScalerOf(
                                      context,
                                    ).scale(12),
                                    /* fontWeight: FontWeight.bold, */
                                  ),
                                ), */
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'R\$ $totalDoProduto',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontSize: MediaQuery.textScalerOf(
                                      context,
                                    ).scale(12),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // ADICIONAIS E OBSERVAÇÕES
                          Row(
                            children: [
                              if (observacao != "")
                                Flexible(
                                  child: Text(
                                    observacao,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: MediaQuery.textScalerOf(
                                        context,
                                      ).scale(12),
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
              ),
            ),

          // Resumo financeiro
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Prod.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.textScalerOf(
                              context,
                            ).scale(15),
                          ),
                        ),
                        Text(
                          'R\$ $valorProdutosSelect',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: MediaQuery.textScalerOf(
                              context,
                            ).scale(15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Adic.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.textScalerOf(
                              context,
                            ).scale(15),
                          ),
                        ),
                        Text(
                          'R\$ $valorAdicionaisSelect',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: MediaQuery.textScalerOf(
                              context,
                            ).scale(15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Serv.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.textScalerOf(
                              context,
                            ).scale(15),
                          ),
                        ),
                        Text(
                          'R\$ $valorServicoSelect',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: MediaQuery.textScalerOf(
                              context,
                            ).scale(15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Desc.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.textScalerOf(
                              context,
                            ).scale(15),
                          ),
                        ),
                        Text(
                          'R\$ $valorDescontoSelect',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: MediaQuery.textScalerOf(
                              context,
                            ).scale(15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Número de pessoas + Total
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            // padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 1. Contador de Pessoas (Esquerda)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Nº DE PESSOAS:',
                        style: TextStyle(
                          fontSize: MediaQuery.textScalerOf(context).scale(12),
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface.withOpacity(0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      Container(
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
                              onPressed: diminuirQuantidadePessoas,
                              icon: Icon(Icons.remove),
                              color: colorScheme.primary,
                              iconSize: MediaQuery.textScalerOf(
                                context,
                              ).scale(15),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(
                                minWidth:
                                    MediaQuery.of(context).size.width * 0.1,
                              ),
                            ),
                            Text(
                              !mesaEmConta && !comandaEmConta
                                  ? numeroDePessoasString
                                  : pessoasSelect,
                              style: TextStyle(
                                fontSize: MediaQuery.textScalerOf(
                                  context,
                                ).scale(15),
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            IconButton(
                              onPressed: aumentarQuantidadePessoas,
                              icon: Icon(Icons.add),
                              color: colorScheme.primary,
                              iconSize: MediaQuery.textScalerOf(
                                context,
                              ).scale(15),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(
                                minWidth:
                                    MediaQuery.of(context).size.width * 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 12),

                // Total Por Pessoa (Meio)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'POR PESSOA:',
                        style: TextStyle(
                          fontSize: MediaQuery.textScalerOf(context).scale(12),
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface.withOpacity(0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 6),

                      Container(
                        height: MediaQuery.of(context).size.height * 0.055,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.secondary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          !mesaEmConta && !comandaEmConta
                              ? numeroDePessoasInt > 1
                                    ? 'R\$ $totalPorPessoaString'
                                    : 'R\$ $valorTotalLiquidoSelect'
                              : formatoReal.format(
                                  double.tryParse(totalPorPessoaSelect) ?? 0.0,
                                ),
                          /* numeroDePessoasInt > 1 ? 'R\$ $totalPorPessoaString' : 'R\$ $valorTotalLiquidoSelect', */
                          style: TextStyle(
                            fontSize: MediaQuery.textScalerOf(
                              context,
                            ).scale(15),
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 12),

                // 3. Total Geral (Direita)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'TOTAL:',
                        style: TextStyle(
                          fontSize: MediaQuery.textScalerOf(context).scale(12),
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface.withOpacity(0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      Container(
                        height: MediaQuery.of(context).size.height * 0.055,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'R\$ $valorTotalLiquidoSelect',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: MediaQuery.textScalerOf(
                              context,
                            ).scale(15),
                            fontWeight: FontWeight.bold,
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
          if (!mesaEmConta && !comandaEmConta)
            Row(
              children: [
                // Botão pedir conta
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 8,
                      top: 8,
                      bottom: 8,
                    ),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.07,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cliqueiConta
                              ? Theme.of(
                                  context,
                                ).colorScheme.error.withOpacity(0.5)
                              : Theme.of(context).colorScheme.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () async {
                          if (cliqueiConta) return;
                          setState(() {
                            cliqueiConta = true;
                          });

                          try {
                            shownDialogaAlertTwoBottom(
                              context: context,
                              title: 'Confirma solicitação de conta?',
                              message: () => 'Informe o número de pessoas:',
                              message2: () => numeroDePessoasInt > 1
                                  ? 'Total por pessoa: R\$ $totalPorPessoaString | Nº pessoas: $numeroDePessoasString'
                                  : 'No valor de R\$ $valorTotalLiquidoSelect',
                              icon: Icons.error,
                              cancelText: 'Cancelar',
                              confirmText: 'Sim',
                              onConfirm: () async {
                                try {
                                  await inserirConta(
                                    numeroTradepointSelecionada,
                                    numeroUsuario, // numero do nome selecionado
                                    comandaDoPedidoParaInsert,
                                    mesaDoPedidoParaInsert,
                                    numeroDePessoasString,
                                  );

                                  Get.put(CarrinhoController()).limparCarrinho();

                                  await zerarAtendimento();

                                  Get.toNamed('/garcom');

                                  // GarcomPageState().zerarAtendimento(); // zera o atendimento da pagina de garcom
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Não foi possível pedir conta, tente novamente',
                                      ),
                                      backgroundColor: colorScheme.error,
                                    ),
                                  );
                                  setState(() {
                                    cliqueiConta = false;
                                  });
                                }
                              },
                              onCancel: () {
                                setState(() {
                                  cliqueiConta = false;
                                });
                              },
                            );
                          } catch (e) {
                            setState(() {
                              cliqueiConta = false;
                            });
                          }
                        },
                        child: Text(
                          'PEDIR CONTA',
                          style: TextStyle(
                            fontSize: MediaQuery.textScalerOf(context).scale(
                              14,
                            ), // Diminuído um pouco para caber lado a lado
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if(funcoesController.aparecerBotaoPagar.value)
                // Botão pagar pedido
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 8,
                      right: 16,
                      top: 8,
                      bottom: 8,
                    ),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.07,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () async {
                          if (cliqueiPagarPedido) {
                            return;
                          }
                          cliqueiPagarPedido = true;
                          try {
                            await pagarPedido();
                            cliqueiPagarPedido = false;
                          } catch (e) {
                            setState(() {
                              cliqueiPagarPedido = false;
                            });
                          }  
                        },
                        child: Text(
                          'PAGAR PEDIDO',
                          style: TextStyle(
                            fontSize: MediaQuery.textScalerOf(
                              context,
                            ).scale(14),
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

          // Botão pagar conta
          if (mesaEmConta || comandaEmConta)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              //  padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  if(funcoesController.aparecerBotaoPagar.value)
                  Expanded(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.07,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          /* backgroundColor: Theme.of(context).colorScheme.error, */
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () async {
                          pagarPedido();
                        },
                        child: Text(
                          'PAGAR PEDIDO',
                          style: TextStyle(
                            fontSize: MediaQuery.textScalerOf(context).scale(18),
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
        ],
      ),
    );
  }
}
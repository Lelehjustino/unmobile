import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:un_recepcao/api/stone_service.dart';
import 'package:un_recepcao/controllers/carrinho_controller.dart';
import 'package:un_recepcao/controllers/comanda_carrinho.dart';
import 'package:un_recepcao/controllers/views/funcoes_controller.dart';
import 'package:un_recepcao/controllers/views/painel_controller.dart';
import 'package:un_recepcao/data/data_class.dart';
import 'package:un_recepcao/views/garcom_page.dart';
import 'package:un_recepcao/views/mapa_page.dart';
import 'package:un_recepcao/widgets/side_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class CarrinhoComandasPage extends StatefulWidget {
  const CarrinhoComandasPage({super.key});

  @override
  State<CarrinhoComandasPage> createState() => CarrinhoComandasPageState();
}

class CarrinhoComandasPageState extends State<CarrinhoComandasPage>
    with SingleTickerProviderStateMixin {

  String versaoAplicacao = FuncoesController().versaoDoApp;

  // Variáveis para receber e ajeitar args
  String numeropedido = Get.arguments['numeropedido'];
  String comandaDoPedido = Get.arguments['comanda'];
  String mesaDoPedido = Get.arguments['mesa'];
  String comandaDoPedidoParaInsert = "";
  String mesaDoPedidoParaInsert = "";

  final CarrinhoController carrinhoController = Get.find<CarrinhoController>();
  final ComandaCarrinhoController comandaCarrinhoController = Get.find<ComandaCarrinhoController>();

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
  bool aparecerCheckInOut = true;
  bool aparecerRecepcao = false;
  bool naoAparecerMapa = true;
  bool aparecerCheckIn = true;
  bool aparecerCheckOut = true;
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
  bool logicaPorMesa = false;
  bool logicaPorComanda = false;
  bool logicaPorComandaNaMesa = false;

  // Removido cliqueiFazerPedido para usar o estado centralizado

  String comandaCard = "";
  String mesaCard = "";

  final FuncoesController funcoesController = Get.put(FuncoesController());
  final painelController = Get.put(PainelController());

  bool isProcessing = false;
  bool cliqueiFazerPedido = false;
  bool fizPedido = false;

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
    _loadNumeroLicenca(); // Inicializa numeroTradepointSelecionada
    _loadNumeroGarcom(); // Inicializa numeroUsuario
    numeroDePessoasInt = 1;
    numeroDePessoasString = '1';

    buscarListaProdutos();
    buscarValoresDoPedido();
    
    arrumaVazioComanda();
    arrumarVazioMesa();
    zeraValores();
    _loadNomeEmpresa();
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
      if (mounted) {
        setState(() {
          tipoDoPedido = "0";
        });
      }
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
  /* Future<void> _carregarModos() async {
    final prefs = await SharedPreferences.getInstance();
    final modoJson = prefs.getString('modo_padrao');

    if (modoJson != null) {
      final modosSalvos = Set<String>.from(jsonDecode(modoJson));

      if (modosSalvos.contains("Mesa") && !modosSalvos.contains("Comanda")) {
        setState(() {
          aparecerCheckInOut = false;
        });
      } else if (modosSalvos.contains("Mesa") &&
          modosSalvos.contains("Comanda")) {
        setState(() {
          aparecerCheckInOut = true;
        });
      } else if (!modosSalvos.contains("Mesa") &&
          modosSalvos.contains("Comanda")) {
        setState(() {
          aparecerCheckInOut = true;
        });
      } else if (!modosSalvos.contains("Mesa") &&
          !modosSalvos.contains("Comanda")) {
        setState(() {
          naoAparecerMapa = true;
          aparecerCheckInOut = false;
        });
      } else {
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
  } */
 /* Future<void> _carregarModos() async {
    final prefs = await SharedPreferences.getInstance();
    final modoJson = prefs.getString('modo_padrao');

    if (modoJson != null) {
      final modosSalvos = Set<String>.from(jsonDecode(modoJson));

      setState(() {
        // Regra: O mapa aparece se "Mesa" OU "Comanda" estiverem selecionados
        naoAparecerMapa = !(modosSalvos.contains("Mesa") || modosSalvos.contains("Comanda"));

        if (funcoesController.logicaPorComanda.value){
          if (modosSalvos.contains("Comanda")) {
            aparecerCheckInOut = false;
            naoAparecerMapa = false;
          } else {
            aparecerCheckInOut = true;
            naoAparecerMapa = true;
          }
        }

        if(funcoesController.logicaPorMesa.value){
          if (modosSalvos.contains("Mesa")) {
            aparecerCheckInOut = false;
            naoAparecerMapa = false;
          } else {
            aparecerCheckInOut = true;
            naoAparecerMapa = true;
          }
        }

        if(funcoesController.logicaPorComandaNaMesa.value){
          if (modosSalvos.contains("Comanda") || modosSalvos.contains("Mesa")) {
            aparecerCheckInOut = false;
            naoAparecerMapa = false;
          } else {
            aparecerCheckInOut = true;
            naoAparecerMapa = true;
          }
        }
      });
    } else {
      setState(() {
        naoAparecerMapa = true;
        aparecerCheckInOut = true;
      });
    }
  } */

 Future<void> _carregarModos() async {
    final prefs = await SharedPreferences.getInstance();
    final modoJson = prefs.getString('modo_padrao');

    if (modoJson != null) {
      final modosSalvos = Set<String>.from(jsonDecode(modoJson));

      setState(() {
        // Regra: O mapa aparece se "Mesa" OU "Comanda" estiverem selecionados
        naoAparecerMapa = !(modosSalvos.contains("Mesa") || modosSalvos.contains("Comanda"));

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
        aparecerCheckInOut = true; // Mantendo o padrão deste arquivo
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
      String dadosJson = await Connection.select(
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
        /* """
        SELECT
          p.nome AS nome_produto,
          p.id   AS tipo_produto,

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

        WHERE v.numeropedido_FK = '$numeropedido'
          AND v.cancelado = '0'

        GROUP BY
          v.numero,
          v.numeroproduto_FK,
          v.valorunitario,
          v.datahora;
        """ */
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
      listaProdutos = [];
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
      String dadosJson = await Connection().select(
        /*  """
          SELECT
            valorprodutos,
            valoradicionais,
            valorservico,
            valordesconto,
            valortotalliquido,
            pessoas
          FROM pedidos
          WHERE numero = '$numeropedido'
        """ */
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

  // Função para mostrar mensagem de venda inserida com sucesso
  void vendaInseridaComSucesso() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(Duration(milliseconds: 1388), () {
          if (Navigator.canPop(ctx)) {
            Navigator.pop(ctx);
          }
        });

        return Center(
          child: TweenAnimationBuilder(
            duration: Duration(milliseconds: 500),
            tween: Tween<double>(begin: 0, end: 1),
            curve: Curves.elasticOut,
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
                          'Pedido feito com sucesso!',
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

  // Função para mostrar mensagem de erro ao inserir pedido
  void erroAoInserirPedido() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(Duration(milliseconds: 1388), () {
          if (Navigator.canPop(ctx)) {
            Navigator.pop(ctx);
          }
        });

        return Center(
          child: TweenAnimationBuilder(
            duration: Duration(milliseconds: 500),
            tween: Tween<double>(begin: 0, end: 1),
            curve: Curves.elasticOut,
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
                          'Erro ao inserir pedido!',
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


  // Função para inserir venda
 /*  Future<void> inserirConta(
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
        INSERT INTO vendasmobiles(
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

  // -------------------------------- FUNCOES PARA INSERIR PEDIDO --------------------------------------

  // Funcao para limpar page carrinho_comandas_page
  void limparPage() {
    comandaCarrinhoController.limparTudo();
    Get.toNamed('/garcom');
  }

  // Funcao que chama enviarCarrinho
  Future<void> enviarCarrinhoComandas(
    ComandaCarrinhoController comandasController,
  ) async {
    final listaComandas = List<CarrinhoArmazenado>.from(comandasController.listaCompleta);
    bool houveErroGeral = false;
    
    for (var comandaItem in listaComandas) {
      // Garante que mesa e comanda não cheguem vazios ao banco
      final String mesaFinal = comandaItem.mesa.isEmpty ? "0" : comandaItem.mesa;
      final String comandaFinal = comandaItem.comanda.isEmpty ? "0" : comandaItem.comanda;

      bool sucessoComanda = await enviarCarrinho(
        produtos: comandaItem.produtos, // Passa os produtos específicos desta comanda
        numeroComanda: comandaFinal,
        numeroMesa: mesaFinal,
        numeroTradepoint: numeroTradepointSelecionada,
      );

      if (sucessoComanda) {
        // Se a comanda enviou com sucesso, removemos ela do repositório local
        comandasController.removerCarrinho(comandaItem.mesa, comandaItem.comanda);
      } else {
        houveErroGeral = true;
      }
    }

    if (!houveErroGeral) {
      // Se TUDO deu certo, limpa a página (vai pro garçom) e avisa
      limparPage();
      vendaInseridaComSucesso();
      funcoesController.zerarAtendimentoGlobal();
    } else {
      // Se algo falhou, avisa o erro (as comandas que falharam continuam na lista)
      erroAoInserirPedido();
      funcoesController.zerarAtendimentoGlobal();
      // Atualiza a tela para sumir com os produtos que deram sucesso e exibir apenas os que falharam
      if (mounted) {
        setState(() {});
      }
    }
  }

  // Função intermediária para enviar o carrinho inteiro para inserirProdutos
  Future<bool> enviarCarrinho({
    required List<Produto> produtos, // Recebe a lista específica
    required String numeroComanda,
    required String numeroMesa,
    required String numeroTradepoint,
  }) async {
    //  Cópia imutável do carrinho
    final List<Produto> carrinhoSnapshot = List.from(produtos);

    if (carrinhoSnapshot.isEmpty) {
      return true;
    }

    bool todasSucesso = true;

    for (final produto in carrinhoSnapshot) {
      bool sucesso = false;
      if (produto.id == 'P' || produto.id == 'E') {
        sucesso = await inserirProdutos(  
          produto.numero,
          numeroComanda,
          numeroMesa,
          produto.nome,
          montarObservacoes(produto, produto.adicionais),
          montarAdicionais(produto),
          produto.quantidade,
          numeroTradepoint,
          produto.id,
          '00000000',
        );
      } else if (produto.id == 'PZ') {
        final partes = montarSaboresEBordas(
          produto.adicionais,
        );

        sucesso = await inserirProdutosPizza(
          produto.numero,
          numeroComanda,
          numeroMesa,
          produto.nome,
          produto.observacaoEscrita,
          '',
          produto.quantidade,
          numeroTradepoint,
          produto.id,
          montarPartesPizza(
            produto.adicionais,
          ), // divisão 00000000
          // SABORES
          partes.sabores[0],
          partes.sabores[1],
          partes.sabores[2],
          partes.sabores[3],
          partes.sabores[4],
          partes.sabores[5],
          partes.sabores[6],
          partes.sabores[7],
          // OBS SABORES
          partes.obsSabores[0],
          partes.obsSabores[1],
          partes.obsSabores[2],
          partes.obsSabores[3],
          partes.obsSabores[4],
          partes.obsSabores[5],
          partes.obsSabores[6],
          partes.obsSabores[7],
          // BORDAS
          partes.bordas[0],
          partes.bordas[1],
          partes.bordas[2],
          partes.bordas[3],
          partes.bordas[4],
          partes.bordas[5],
          partes.bordas[6],
          partes.bordas[7],
          // OBS BORDAS
          partes.obsBordas[0],
          partes.obsBordas[1],
          partes.obsBordas[2],
          partes.obsBordas[3],
          partes.obsBordas[4],
          partes.obsBordas[5],
          partes.obsBordas[6],
          partes.obsBordas[7],
        );
      }

      if (sucesso) {
        // Remove da lista original assim que insere com sucesso
        // Isso evita duplicação se o usuário tentar reenviar a comanda após uma falha parcial
        produtos.remove(produto);
      } else {
        todasSucesso = false;
        break; // Interrompe o loop no primeiro erro para evitar cascata de timeouts
      }
    }

    return todasSucesso;
  }

  // -------------------------------- MÉTODOS AUXILIARES E DATABASE --------------------------------------

  PartesPizza montarSaboresEBordas(List<Produto> adicionais) {
    List<String> sabores = [];
    List<String> obsSabores = [];
    List<String> bordas = [];
    List<String> obsBordas = [];

    for (var adicional in adicionais) {
      if (adicional.id == 'P') {
        sabores.add(adicional.numero);
        obsSabores.add(adicional.observacaoEscrita);
      }

      if (adicional.id == 'B') {
        bordas.add(adicional.numero);
        obsBordas.add(adicional.observacaoEscrita);
      }
    }

    // Completa até 8 posições
    while (sabores.length < 8) {
      sabores.add('0');
      obsSabores.add('');
    }

    while (bordas.length < 8) {
      bordas.add('0');
      obsBordas.add('');
    }

    return PartesPizza(
      sabores: sabores,
      obsSabores: obsSabores,
      bordas: bordas,
      obsBordas: obsBordas,
    );
  }

  // Função para completar com zeros os sabores de pizza
  String montarPartesPizza(List<Produto> adicionais) {
    const int totalDigitos = 8;
    StringBuffer buffer = StringBuffer();

    for (final adicional in adicionais) {
      if (adicional.id == 'P') {
        buffer.write(adicional.quantidade.toString());
      }
    }

    String resultado = buffer.toString();
    if (resultado.length < totalDigitos) {
      resultado = resultado.padRight(totalDigitos, '0');
    }
    if (resultado.length > totalDigitos) {
      resultado = resultado.substring(0, totalDigitos);
    }
    return resultado;
  }

  // Função para montar observação de pizza
  String montarObservacoesPizza(Produto produto) {
    if (produto.adicionais.isEmpty) return '';

    return produto.adicionais
        .expand((a) => List.filled(a.quantidade.toInt(), a.nome))
        .join(' | ');
  }

  // Função para montar observação
  String montarObservacoes(Produto produto, List<Produto> adicionais) {
    final List<String> obs = [];

    if (produto.observacaoEscrita.isNotEmpty) {
      obs.add(produto.observacaoEscrita);
    }

    if (produto.observacoesTexto.isNotEmpty) {
      obs.addAll(produto.observacoesTexto);
    }

    if (adicionais.isNotEmpty) {
      for (var adicional in adicionais) {
        obs.add(adicional.nome);
      }
    }

    return obs.join('|');
  }

  // Função para montar adicionais produto tipo P
  String montarAdicionais(Produto produto) {
    if (produto.adicionais.isEmpty) return '';

    return produto.adicionais
        .expand((a) => List.filled(a.quantidade.toInt(), a.numero))
        .join('|');
  }

  // Função para completar com zeros os sabores de pizza
  String completarComZeros(String divisaoDeSabores) {
    const int totalDigitos = 8;
    if (divisaoDeSabores.length >= totalDigitos) {
      return divisaoDeSabores.substring(0, totalDigitos);
    }
    return divisaoDeSabores.padRight(totalDigitos, '0');
  }

  // Função para inserir um produto pizza
  Future<bool> inserirProdutosPizza(
    String numeroDoProduto,
    String numeroComanda,
    String numeroMesa,
    String nomeProduto,
    String observacao,
    String adicional,
    double quantidade,
    String numeroTradepoint,
    String id,
    String divisaoDeSabores,
    String n1, 
    String n2, 
    String n3, 
    String n4,
    String n5, 
    String n6, 
    String n7, 
    String n8,
    String o1, 
    String o2, 
    String o3, 
    String o4,
    String o5, 
    String o6, 
    String o7, 
    String o8,
    String b1, 
    String b2, 
    String b3, 
    String b4,
    String b5, 
    String b6, 
    String b7, 
    String b8,
    String ob1, String ob2, String ob3, String ob4,
    String ob5, String ob6, String ob7, String ob8,
  ) async {
    String divisao = completarComZeros(divisaoDeSabores);
    try {
      String sql = """
        INSERT INTO vendasmobiles(
          numeroserie,
          numerotradepoint_FK,
          numerousuario_FK,
          numerocartao,
          numeroproduto_FK,
          quantidade,
          observacao,
          adicional,
          nomeproduto,
          numeromesa,
          status,
          divisaosabores,
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
          obsborda8
        ) VALUES (
          '1',
          '$numeroTradepoint',
          '$numeroUsuario',
          '$numeroComanda',
          '$numeroDoProduto',
          $quantidade,
          '$observacao',
          '$adicional',
          '$nomeProduto',
          '$numeroMesa',
          '1',
          '$divisao',
          '$n1',
          '$n2',
          '$n3',
          '$n4',
          '$n5',
          '$n6',
          '$n7',
          '$n8',
          '$o1',
          '$o2',
          '$o3',
          '$o4',
          '$o5',
          '$o6',
          '$o7',
          '$o8',
          '$b1',
          '$b2',
          '$b3',
          '$b4',
          '$b5',
          '$b6',
          '$b7',
          '$b8',
          '$ob1',
          '$ob2',
          '$ob3',
          '$ob4',
          '$ob5',
          '$ob6',
          '$ob7',
          '$ob8'
        )
      """;
      String resultado = await Connection().ipd(sql);
      return resultado == 'sucesso';
    } catch (e) {
      print("Erro inserirProdutosPizza: $e");
      return false;
    }
  }

  // Função para inserir um produto
  Future<bool> inserirProdutos(
    String numeroDoProduto,
    String numeroComanda,
    String numeroMesa,
    String nomeProduto,
    String observacao,
    String adicional,
    double quantidade,
    String numeroTradepoint,
    String id,
    String divisaoDeSabores,
  ) async {
    String divisao = completarComZeros(divisaoDeSabores);
    try {
      String sql = """
        INSERT INTO vendasmobiles(
          numeroserie, 
          numerotradepoint_FK, 
          numerousuario_FK, 
          numerocartao, 
          numeroproduto_FK, 
          quantidade, 
          observacao, 
          adicional, 
          nomeproduto, 
          numeromesa, 
          status, 
          divisaosabores
        ) VALUES (
          '1', 
          '$numeroTradepoint', 
          '$numeroUsuario', 
          '$numeroComanda',
          '$numeroDoProduto', 
          $quantidade, 
          '$observacao', 
          '$adicional', 
          '$nomeProduto',
          '$numeroMesa', 
          '1', 
          '$divisao'
        )
      """;
      String resultado = await Connection().ipd(sql);
      return resultado == 'sucesso';
    } catch (e) {
      print("Erro inserirProdutos: $e");
      return false;
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
      bool conectado = await Connection.conectarBanconoSalvar();

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

                        /* // Controlador de quantidade de pessoas
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
                        ), */

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
                      Get.back();
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
                                  'CARRINHO DE COMANDAS',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              /*   Flexible(
                                child: Text(
                                  logicaPorMesa
                                      ? 'MESA: $mesaDoPedido'
                                      : logicaPorComanda ? 'COMANDA: $comandaDoPedido'
                                      : comandaDoPedido != "0" && mesaDoPedido != "0" ? 'COMANDA: $comandaDoPedido MESA: $mesaDoPedido'
                                      : comandaDoPedido != "0" ? 'COMANDA: $comandaDoPedido'
                                      : mesaDoPedido != "0" ? 'MESA: $mesaDoPedido'
                                      : '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ), */
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
          Expanded(
            child: Obx(() {
              final comandas = comandaCarrinhoController.listaCompleta;

              if (comandas.isEmpty) {
                return Center(child: Text('Nenhuma comanda salva'));
              }

              return ListView.builder(
                itemCount: comandas.length,
                itemBuilder: (context, index) {
                  final  comanda = comandas[index];

                  // Transforma zero em vazio e define variáveis LOCAIS para cada card
                  final String localComanda = comanda.comanda == "0" ? "" : comanda.comanda;
                  final String localMesa = comanda.mesa == "0" ? "" : comanda.mesa;

                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: colorScheme.primary.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        // color: colorScheme.primaryContainer.withOpacity(0.15),
                      ),
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // CABEÇALHO DA COMANDA E TOTAL
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (localComanda.isNotEmpty && localMesa.isNotEmpty)
                                      Text(
                                        'Comanda: $localComanda | Mesa: $localMesa',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      )
                                    else if (localMesa.isNotEmpty)
                                      Text(
                                        'Mesa: $localMesa',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      )
                                    else if (localComanda.isNotEmpty)
                                      Text(
                                        'Comanda: $localComanda',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Total: ${formatoReal.format(double.parse(comanda.totalLiquido))}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Botão de remover comanda
                              Material(
                                color: Colors.transparent,
                                child: IconButton(
                                  constraints: BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    shownDialogaAlertTwoBottom(
                                      context: context,
                                      title: "Deseja remover a comanda?",
                                      message:
                                          "Tem certeza que deseja remover a comanda ${localComanda.isNotEmpty ? localComanda : localMesa}?",
                                      icon: Icons.delete_outline,
                                      onConfirm: () async {
                                        comandaCarrinhoController.removerCarrinho(
                                          comanda.mesa,
                                          comanda.comanda,
                                        );
                                      },
                                      onCancel: () async {
                                        setState(() {});
                                      },
                                    );
                                  },
                                  icon: Icon(
                                    Icons.delete,
                                    color: colorScheme.error.withOpacity(0.8),
                                    size: 26,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          Divider(),

                          // LISTA DE PRODUTOS DA COMANDA
                          Column(
                            children: comanda.produtos.map((produto) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        produto.nome,
                                        style: TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${produto.quantidade.toInt()} x R\$ ${produto.preco}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.end,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          // Botão pedir conta
          if (comandaCarrinhoController.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              //  padding: EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.07,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    /* backgroundColor: Theme.of(context).colorScheme.error, */
                    backgroundColor: cliqueiFazerPedido ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // Retornar null caso esteja processando desabilita o botão nativamente, prevenindo duplo clique
                  onPressed: cliqueiFazerPedido ? null : () async {
                    if (cliqueiFazerPedido) return; // Segurança extra

                    setState(() {
                      cliqueiFazerPedido = true;
                    });

                    try {
                      await enviarCarrinhoComandas(comandaCarrinhoController);
                      // comandaCarrinhoController.limparTudo();
                      //Get.toNamed('/garcom');
                    } catch (e) {
                      print(e);
                    } finally {
                      if (mounted) {
                        setState(() {
                          cliqueiFazerPedido = false;
                        });
                      }
                    }
                  },
                  child: Text(
                    cliqueiFazerPedido ? 'FAZENDO PEDIDO...' : 'FAZER PEDIDO',
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
    );
  }
}

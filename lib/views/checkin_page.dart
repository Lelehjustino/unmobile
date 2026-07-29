import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:un_recepcao/controllers/views/funcoes_controller.dart';
import 'package:un_recepcao/controllers/views/painel_controller.dart';
import 'package:un_recepcao/data/data_class.dart';
import 'package:un_recepcao/views/checkout_page.dart';
import 'package:un_recepcao/views/mapa_page.dart';
import 'package:un_recepcao/views/notes_page.dart';
import 'package:un_recepcao/views/recepcao_page.dart';
import 'package:un_recepcao/widgets/side_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});

  @override
  State<CheckinPage> createState() => CheckinPageState();
}

class CheckinPageState extends State<CheckinPage>
    with SingleTickerProviderStateMixin {
  final FuncoesController funcoesController = Get.put(FuncoesController());
  String versaoAplicacao = FuncoesController().versaoDoApp;
  final TextEditingController comandaController = TextEditingController();
  final FocusNode comandaFocus = FocusNode();
  final TextEditingController servidorController = TextEditingController();
  String nomeEmpresa = '';
  String mensagem = 'Insira o número da comanda';
  bool corMensagem = true;
  bool iconeMensagem = true;
  bool animacaoAparecer = false;

  late Timer _timer;
  String _horaAtual = '';

  bool checkIn = false;
  bool checkout = false;
  bool mapaDeMesaoOuComanda = false;
  bool comandas = true;

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

  String numeroUsuario = "";
  String nomeDoGarcom = "";
  String nomeDoGarcomSelecionado = "";
  bool nomeDoGarcomDoLoad = false;
  bool garcomSelecionado = false;

  String numeroDaLicencaSelecionada = '';
  String nomeEmpresaLoad = '';
  static final ValueNotifier<bool> isConnected = ValueNotifier(false);
  // final variaveis = Get.find<VariaveisController>();
  // final MainController controller = Get.put(MainController());

  bool cliqueiCheck = false;

  final painelController = Get.put(PainelController());

  String numeroPedidoInserido = "";
  String configuracaoServicoValor = "";

  List<dynamic> observacoesEadicionais = [];
  RxList<dynamic> observacoesSelecionadas = <dynamic>[].obs;

  bool cliqueiFora = true;
  bool loadingConfirmar = false;

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
    comandaFocus.addListener(() {
      setState(() {
        _isFocused = comandaFocus.hasFocus;
        _isFocused = true;
      });
    });
    _carregarNote();
    _carregarModo();
    _carregarServidor();
    _loadServidor();
    _loadComanda();
    // carregarNomeEmpresa();
    _carregarModos();
    _carregarRecepcao();
    _carregarchecks();
    _carregargarcom();
    _loadGarcom();
    _loadNumeroLicenca();
    _loadNomeEmpresa();

    Future.delayed(Duration(milliseconds: 300), () {
      if (comandaFocus.canRequestFocus) {
        comandaFocus.requestFocus();
      }
    });
  }

  // ABRIR COMANDA
  // 2026 - 07 - 06
  /* fazerCheckIn(String numeroComanda) async {
    await abrirPedido(numeroComanda, await configuracaoServico());
    await devolverPedido(numeroComanda);
    await atualizarCartoes(numeroComanda, valorTotalLiquido, statusPedido);
    await buscarNumeroProduto(numeroComanda);
    await verificacaoProduto(numeroComanda, await configuracaoProdutoNaComanda(numeroComanda));
  } */

  limparPage(){
    setState(() {
      mensagem = 'Insira o número da comanda';
      corMensagem = true;
      iconeMensagem = true;
      animacaoAparecer = false;
      _isFocused = true;
      animacaoCerto = true;
      cliqueiFora = true;
      comandaController.clear();
    });
    Future.delayed(Duration(milliseconds: 300), () {
      if (comandaFocus.canRequestFocus) {
        comandaFocus.requestFocus();
      }
    });
  }


  fazerCheckIn(String numeroComanda) async {
    bool temProdutoNaComanda = await buscarNumeroProduto(numeroComanda); 
    String produtoEncontradoFK = await configuracaoProdutoNaComanda(numeroComanda);

    if(temProdutoNaComanda){
      // fluxo quando tem produto na comanda
      List<dynamic> observacoesEadicionaisFuncao = await buscarObservacoesEadicionais(produtoEncontradoFK);
      // verifica se tem observacoes e adicionais 
      if(observacoesEadicionaisFuncao.isNotEmpty){
        // abrir o seletor de observacoes e adicionais
        showModalAdicionaisObservacoes(
          context,
          produtoEncontradoFK,
          observacoesEadicionaisFuncao,
          numeroComanda,
          numeroUsuario,
          numeroDaLicencaSelecionada,
        );
      } else {
        await fluxoComProdutoSemObs (numeroComanda, valorTotalLiquido, statusPedido, produtoEncontradoFK, numeroUsuario, numeroDaLicencaSelecionada);
      }
    } else {
      // fluxo direto quando nao tem nada na comanda
      await fluxoSemProduto (numeroComanda, valorTotalLiquido, statusPedido, produtoEncontradoFK, numeroUsuario, numeroDaLicencaSelecionada);
    }
  }

  Future<void> checkInRealizadoComSucesso(String numeroComandaFuncao) async {
    setState(() {
      isLoading = false;
      mensagem = "Comanda $numeroComandaFuncao aberta com sucesso!!!";
      corMensagem = true;
      animacaoCerto = true;
      iconeMensagem = true;
      saveComanda(numeroComandaFuncao);
      observacoesSelecionadas.clear();
    });
    _dispararAnimacaoDeResultado(true);
  }

  Future<void> checkInRealizadoSemSucesso(String numeroComandaFuncao) async {
    setState(() {
      mensagem = "Operação cancelada! Comanda: $numeroComandaFuncao";
      corMensagem = false;
      iconeMensagem = false;
      animacaoCerto = false;
      observacoesSelecionadas.clear();
      isLoading = false;
    });
    _dispararAnimacaoDeResultado(false);
    comandaController.clear();
  }

  Future<void> fluxoSemProduto (numeroComandaFuncao, valorTotalLiquidoFuncao, statusPedidoFuncao, produtoEncontradoFKFuncao, numeroUsuarioFuncao, numeroDaLicencaSelecionadaFuncao) async {
    await abrirPedido(numeroComandaFuncao, await configuracaoServico());
    await devolverPedido(numeroComandaFuncao);
    await atualizarCartoes(numeroComandaFuncao, valorTotalLiquidoFuncao, statusPedidoFuncao);
    await inserirProduto(produtoEncontradoFKFuncao, numeroComandaFuncao, numeroUsuario, numeroDaLicencaSelecionada);
    await checkInRealizadoComSucesso(numeroComandaFuncao);
  }

  Future<void> fluxoComProdutoSemObs (numeroComandaFuncao, valorTotalLiquidoFuncao, statusPedidoFuncao, produtoEncontradoFKFuncao, numeroUsuarioFuncao, numeroDaLicencaSelecionadaFuncao) async {
    await abrirPedido(numeroComandaFuncao, await configuracaoServico());
    await devolverPedido(numeroComandaFuncao);
    await atualizarCartoes(numeroComandaFuncao, valorTotalLiquidoFuncao, statusPedidoFuncao);
    await inserirProduto(produtoEncontradoFKFuncao, numeroComandaFuncao, numeroUsuario, numeroDaLicencaSelecionada);
    await checkInRealizadoComSucesso(numeroComandaFuncao); 
  }

  // Função para montar observação
  String montarObservacoes(List<dynamic> observacoes) {
    final List<String> obs = [];

    // Varrendo os adicionais para incluir o nome nas observações
    if (observacoes.isNotEmpty) {
      for (var observacao in observacoes) {
        obs.add(observacao);
      }
    } 

    return obs.join('|');
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

  // Buscar numero licença
  // Carregar/Salvar licença
  Future<void> _loadNumeroLicenca() async {
    final prefs = await SharedPreferences.getInstance();
    final licencaSalvoNumero = prefs.getString('licencaNumero');
    if (licencaSalvoNumero != null && mounted) {
      setState(() {
        numeroDaLicencaSelecionada = licencaSalvoNumero;
      });
    }
  }

  // Buscar numero garcom
  Future<void> buscarNumeroUsuario(String nomeDoGarcomSelect) async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero FROM usuarios WHERE nome = '$nomeDoGarcomSelect';",
      );

      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        final valor = lista[0]['numero'].toString();
        setState(() {
          numeroUsuario = lista[0]['numero'].toString();
        });
      } else {
        setState(() {
          numeroUsuario = "0";
        });
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
      setState(() {
        numeroUsuario = "0";
      });
    }
  }

  // Carregar/Salvar garçom
  Future<void> _loadGarcom() async {
    final prefs = await SharedPreferences.getInstance();
    final garcomSalvo = prefs.getString('garcom');
    if (garcomSalvo != null && mounted) {
      buscarNumeroUsuario(garcomSalvo);
      setState(() {
        nomeDoGarcom = garcomSalvo;
        nomeDoGarcomSelecionado = garcomSalvo;
        nomeDoGarcomDoLoad = true;
        garcomSelecionado = true;
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
  /* Future<void> _carregarModos() async {
    final prefs = await SharedPreferences.getInstance();
    final modoJson = prefs.getString('modo_padrao');

    if (modoJson != null) {
      final modosSalvos = Set<String>.from(jsonDecode(modoJson));

      setState(() {
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
            aparecerCheckInOut = false;
            naoAparecerMapa = true;
          }
        }
        if(funcoesController.logicaPorMesa.value){
          if (modosSalvos.contains("Mesa")) {
            aparecerCheckInOut = false;
            naoAparecerMapa = false;
          } else {
            aparecerCheckInOut = false;
            naoAparecerMapa = true;
          }
        }
        if(funcoesController.logicaPorComandaNaMesa.value){
          if (modosSalvos.contains("Comanda") || modosSalvos.contains("Mesa")) {
            aparecerCheckInOut = false;
            naoAparecerMapa = false;
          } else {
            aparecerCheckInOut = false;
            naoAparecerMapa = true;
          }
        }
      });
    } else {
      setState(() {
        naoAparecerMapa = true;
        aparecerCheckInOut = false;
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
  } */

  // Carregar check
  // Carregar check
  Future<void> _carregarchecks() async {
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
  }
  /* Future<void> _carregarchecks() async {
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

  // Função para instanciar animação
  void animacao() {
    animationController.forward(from: 0.0);
  }

  // Função para fazer sumir animação SUMIR ANIMAÇÃO
  void _dispararAnimacaoDeResultado(bool sucesso) async {
    // Um parâmetro booleano que indica se a operação foi bem-sucedida (true) ou se houve erro (false).
    // 1. Define o estado para mostrar a animação correta (sucesso ou erro)
    setState(() {
      animacaoAparecer = true;
      animacaoCerto = sucesso;
    });

    // 2. Inicia a animação visual (o efeito de "elasticOut")
    animationController.forward(from: 0.0); // Reinicia a animaçã

    // 3. Agenda a animação para sumir após 3 segundos
    Future.delayed(Duration(seconds: 1), () {
      // Verifica se o widget ainda está na tela para evitar erros
      if (mounted) {
        setState(() {
          animacaoAparecer = false; // Faz a animação sumir
          // comandaController.clear(); // Limpa o campo de texto
        });
        // Devolve o foco para o campo de texto
        // FocusScope.of(context).requestFocus(comandaFocus);
      }
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    await limparPage();
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

  // Função para fazer check in
  Future<void> validarComanda(String numeroComanda) async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, ativo, bloqueada, atendimento, statuspedido, numeropedido_FK "
        "FROM cartoes WHERE numero='$numeroComanda' LIMIT 1",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isEmpty) {
        print("Nenhuma comanda encontrada!");
        setState(() {
          validaComanda = [];
          mensagem = "Nenhuma comanda encontrada!";
          corMensagem = false;
          iconeMensagem = false;
          animacaoCerto = false;
          comandaController.clear();
        });
        _dispararAnimacaoDeResultado(false);
        return;
      }
      Map<String, dynamic> comanda = lista[0];
      // Exemplo de validações:
      if (comanda['ativo'] == '0') {
        setState(() {
          mensagem = "Comanda inativa!";
          corMensagem = false;
          iconeMensagem = false;
          animacaoCerto = false;
          comandaController.clear();
        });
        _dispararAnimacaoDeResultado(false);
      } else if (comanda['bloqueada'] == '1') {
        setState(() {
          mensagem = "Comanda bloqueada!";
          corMensagem = false;
          iconeMensagem = false;
          animacaoCerto = false;
          comandaController.clear(); 
        });
        _dispararAnimacaoDeResultado(false);
      } else if (comanda['numeropedido_FK'] != '0') {
        setState(() {
          mensagem = "Está comanda já está em uso!";
          corMensagem = false;
          iconeMensagem = false;
          animacaoCerto = false;
          comandaController.clear();
        });
        _dispararAnimacaoDeResultado(false);
      } else if (comanda['numero'] == null) {

        setState(() {
          mensagem = "Comanda inexistente";
          corMensagem = false;
          iconeMensagem = false;
          animacaoCerto = false;
          comandaController.clear();
        });
        _dispararAnimacaoDeResultado(false);
      } else {
        try {
          setState(() {
            isLoading = true;
          });
          await fazerCheckIn(numeroComanda);
          /* setState(() {
            isLoading = false;
            mensagem = "Comanda $numeroComanda aberta com sucesso!!!";
            corMensagem = true;
            animacaoCerto = true;
            iconeMensagem = true;
            saveComanda(numeroComanda);
          });
          _dispararAnimacaoDeResultado(true); */
        } catch (e) {
          print('Nao foi possivel abrir comanda $e');
          // Você pode adicionar uma mensagem de erro genérica aqui também
          setState(() {
            isLoading = false;
            mensagem = "Erro ao abrir comanda.";
            corMensagem = false;
          });
          _dispararAnimacaoDeResultado(false);
        }
      }
      setState(() {
        validaComanda = lista;
      });
    } catch (e) {
      print("Erro ao carregar validaComanda: $e");
      setState(() {
        validaComanda = [];
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
          configuracaoServicoValor = lista[0]['resultado'];
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

  // Função verificação produto
  verificacaoProduto(String numeroComanda, String numeroproduto_FK) async {
    configuracaoProdutoNaComanda(numeroComanda);
    String produtoEncontradoFK = await configuracaoProdutoNaComanda(
      numeroComanda,
    );
    if (produtoEncontradoFK == "0") {
      print("Produto não encontrado na comanda");
    } else {
      // select de observacoes e adicionais 
      List<dynamic> observacoesEadicionaisFuncao = await buscarObservacoesEadicionais(numeroproduto_FK);
      // verifica se tem observacoes e adicionais 
      if(observacoesEadicionaisFuncao.isNotEmpty){
        // abrir o seletor de observacoes e adicionais
        showModalAdicionaisObservacoes(
          context,
          numeroproduto_FK,
          observacoesEadicionaisFuncao,
          numeroComanda,
          numeroUsuario,
          numeroDaLicencaSelecionada,
        );
      } else {
        await inserirProduto(
          numeroproduto_FK,
          numeroComanda,
          numeroUsuario,
          numeroDaLicencaSelecionada,
        );
      }
    }
  }

  Future<bool> buscarSeTemProdutoNaComandaComObservacao(String numeroComanda) async {
    try {
      String dadosJson = await Connection().select(
        "SELECT * FROM comandas WHERE numero = '$numeroComanda' AND numeroobservacao_FK != '0';",
      );

      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Erro ao buscar se tem produto na comanda com observacao: $e");
      return false;
    }
  }

  // Função para buscar observacoes e adicionais
  Future<List<dynamic>> buscarObservacoesEadicionais(String numeroProduto) async {
    try {
      String dadosJson = await Connection().select(
        """
          SELECT 
          numeroproduto_FK AS numeroproduto, 
          IF(numeroobservacao_FK = '0', '0', (SELECT observacao FROM observacoes WHERE numero = numeroobservacao_FK)) AS nomeobservacao, 
          numeroprodutoadicional_FK AS numeroadicional, 
          IF(numeroprodutoadicional_FK = '0', '', (SELECT nome FROM produtos WHERE numero = numeroprodutoadicional_FK)) AS nomeadicional, 
          numeroobservacao_FK AS numeroobservacao 
          FROM observacoesadicionaisprodutos 
          WHERE numeroproduto_FK = $numeroProduto 
          ORDER BY numeroproduto_FK;  
        """,
      );

      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        return lista;
      } else {
        return [];
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
      return [];
    }
  }

  // Função para ver se tem produto na comanda
  Future<String> configuracaoProdutoNaComanda(String numeroComanda) async {
    String numeroproduto_FK = "0";

    try {
      String dadosJson = await Connection().select(
        "SELECT numeroproduto_FK FROM checkinautomatico WHERE numerocomanda_FK='$numeroComanda' LIMIT 1",
      );

      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        numeroproduto_FK = lista[0]['numeroproduto_FK'].toString();
        setState(() {
          numeroproduto_FK = lista[0]['numeroproduto_FK'].toString();
        });
      } else {
        setState(() {
          numeroproduto_FK = "0";
        });
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
      setState(() {
        numeroproduto_FK = "0";
      });
    }

    return numeroproduto_FK;
  }

  // Função que retorna número do pedido e valor liquido
  Future<void> devolverPedido(String numeroComanda) async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, valortotalliquido, status FROM pedidos WHERE numerocartao_FK='$numeroComanda' AND (STATUS='1' OR STATUS='2') ORDER BY numero DESC LIMIT 1;",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        String valor = lista[0]['numero'].toString();
        String valor2 = lista[0]['valortotalliquido'];
        String valor3 = lista[0]['status'];

        setState(() {
          numeroDoPedido = valor; // agora é uma string "0" ou "1"
          valorTotalLiquido = valor2;
          statusPedido = valor3;
        });
      } else {
        setState(() {
          numeroDoPedido = "0"; // padrão caso não ache nada
          valorTotalLiquido = "0";
          statusPedido = "0";
        });
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
      setState(() {
        numeroDoPedido = "0";
        valorTotalLiquido = "0";
      });
    }
  }

  // Update para atualizar cartoes
  Future<void> atualizarCartoes(
    String numeroComanda,
    String valorTotalLiquido,
    String statusPedido,
  ) async {
    // Variáveis locais
    String numeroPedido = numeroDoPedido; // pego de alguma variável global/controlador
    String numeroDaComanda = numeroComanda;
    String valorTotal = valorTotalLiquido;
    String statuspedido = statusPedido;

    // Montando o SQL
    String sql =
        """
      UPDATE cartoes 
      SET 
        numeropedido_FK = '$numeroPedido', 
        valorliquidopedido = '$valorTotal', 
        statuspedido = '$statuspedido', 
        pessoas = '1'
      WHERE numero = '$numeroDaComanda'
    """;

    try {
      String resultado = await Connection().ipd(sql);

      if (resultado == 'sucesso') {
        print(
          "Cartão $numeroDaComanda atualizado com sucesso (pedido $numeroPedido).",
        );
      } else {
        print("Erro ao atualizar cartão $numeroDaComanda: $resultado");
      }
    } catch (e) {
      print("Erro inesperado ao atualizar cartão: $e");
    }
  }

  // Update para abrir pedido
  Future<void> abrirPedido(String numeroComanda, String valor) async {
    // Valores fixos
    String numeroCaixaAtual = '0';
    String numeroUsuarioAtual = '1';
    String numeroTradepointAtual = '1';
    String cobrarTaxa = valor;
    String NumeroComanda = numeroComanda;
    int numeroPedido = 0;

    // Montando o SQL
    String sql = "INSERT INTO pedidos (numerocartao_FK,numerocaixa_FK,numerousuarioabertura_FK,status,pessoas,observacao,numerotradepointabertura_FK,taxaservico,descricaopedido,abertura,numerocliente_FK) VALUES ('$NumeroComanda','$numeroCaixaAtual','$numeroUsuarioAtual','1','1','','$numeroTradepointAtual','$cobrarTaxa','Comanda - $NumeroComanda', CURRENT_TIMESTAMP,'$numeroPedido')";
    try {
      String numeroPedido = await Connection().insertId(sql);

      if (numeroPedido != "") {
        print("Pedido aberto com sucesso para comanda $NumeroComanda");
        comandaController.clear();
        setState(() {
          comandaController.text = ''; // limpar campo textField
        });
        numeroPedidoInserido = numeroPedido;
      } else {
        print(" Erro ao abrir pedido: $numeroPedido");
        setState(() {
          comandaController.text = ''; // limpar campo textField
        });
        numeroPedidoInserido = "";
      }
    } catch (e) {
      print(" Erro inesperado: $e");
      setState(() {
        comandaController.text = ''; // limpar campo textField
      });
      numeroPedidoInserido = "";
    }
  }

  // Função que retorna o número do produto vinculado à comanda
  Future<bool> buscarNumeroProduto(String numeroComanda) async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numeroproduto_FK FROM checkinautomatico WHERE numerocomanda_FK='$numeroComanda' LIMIT 1;",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        // pega apenas o campo numeroproduto_FK
        String numeroProduto = lista[0]['numeroproduto_FK'].toString();

        setState(() {
          numeroDoProduto = numeroProduto; // salva em uma variável de estado
        });

        print("Número do produto encontrado: $numeroProduto");
        return true;
      } else {
        setState(() {
          numeroDoProduto = "0"; // caso não encontre nada
        });
        print("Nenhum produto encontrado para comanda $numeroComanda");
        return false;
      }
    } catch (e) {
      print("Erro ao buscar número do produto: $e");
      setState(() {
        numeroDoProduto = "0";
      });
      return false;
    }
  }

  // Função para inserir um produto
  Future<void> inserirProduto(
    String numeroDoProduto,
    String numeroComanda,
    String numeroUsuario,
    String numeroDaLicencaSelecionada,
  ) async {
    String numeroSerie = '1';
    String numeroTradepointFK = numeroDaLicencaSelecionada;
    String numeroUsuarioFK = numeroUsuario;
    String numeroCartao = numeroComanda;
    String numeroProdutoFK = numeroDoProduto;
    String nomeProduto = '';
    int numeroMesa = 0;
    String observacao = '';

    // Valores numéricos
    int quantidade = 1;
    String adicional = '';

    String status = '1';

    try {
      String sql =
          """
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
          status
        ) VALUES (
          '$numeroSerie',
          '$numeroTradepointFK',
          '$numeroUsuarioFK',
          '$numeroCartao',
          '$numeroProdutoFK',
          $quantidade,
          '$observacao',
          '$adicional',
          '$nomeProduto',
          $numeroMesa,
          '$status'
        )
      """;

      String resultado = await Connection().ipd(sql);

      if (resultado == 'sucesso') {
        print("Venda inserida com sucesso! Pedido: | Produto: ");
      } else {
        print("Erro ao inserir venda: $resultado");
      }
    } catch (e) {
      print("Erro inesperado ao inserir venda: $e");
    }
  }

  // Função para inserir um produto
  Future<void> inserirProdutoComObservacoes(
    String numeroDoProduto,
    String numeroComanda,
    String numeroUsuario,
    String numeroDaLicencaSelecionada,
    String observacao,
  ) async {
    String numeroSerie = '1';
    String numeroTradepointFK = numeroDaLicencaSelecionada;
    String numeroUsuarioFK = numeroUsuario;
    String numeroCartao = numeroComanda;
    String numeroProdutoFK = numeroDoProduto;
    String nomeProduto = '';
    int numeroMesa = 0;
    String observacaoSelect = observacao;

    // Valores numéricos
    int quantidade = 1;
    String adicional = '';

    String status = '1';

    try {
      String sql =
          """
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
          status
        ) VALUES (
          '$numeroSerie',
          '$numeroTradepointFK',
          '$numeroUsuarioFK',
          '$numeroCartao',
          '$numeroProdutoFK',
          $quantidade,
          '$observacaoSelect',
          '$adicional',
          '$nomeProduto',
          $numeroMesa,
          '$status'
        )
      """;

      String resultado = await Connection().ipd(sql);

      if (resultado == 'sucesso') {
        print("Venda inserida com sucesso! Pedido: | Produto: ");
      } else {
        print("Erro ao inserir venda: $resultado");
      }
    } catch (e) {
      print("Erro inesperado ao inserir venda: $e");
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
    comandaFocus.addListener(() {
      setState(() {
        _isFocused = comandaFocus.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
    comandaFocus.dispose();
    animationController.dispose();
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
    // Mantém o foco no TextField
    FocusScope.of(context).requestFocus(comandaFocus);
    setState(() {
      mensagem = 'Insira o número da comanda';
      corMensagem = true;
      iconeMensagem = true;
      animacaoAparecer = false;
      _isFocused = true;
      animacaoCerto = true;
    });
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
    // Mantém o foco no TextField
    FocusScope.of(context).requestFocus(comandaFocus);
    setState(() {
      mensagem = 'Insira o número da comanda';
      corMensagem = true;
      iconeMensagem = true;
      animacaoAparecer = false;
      _isFocused = true;
      animacaoCerto = true;
    });
  }

  // Função para limpar comanda
  void limparComanda() {
    comandaController.text = '';
    comandaController.clear();
  }

  // Função para confirmar numero da comanda
  void _confirmar() async {
    HapticFeedback.lightImpact();
    if (cliqueiCheck) return;
    setState(() {
      cliqueiCheck = true;
    });
    try {
      String numeroComanda = comandaController.text;
      await validarComanda(numeroComanda);
      await limparComanda;
    } catch (e) {
      cliqueiCheck = false;
      print("nao foi possivel validar comanda");
    }
    cliqueiCheck = false;
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

  void showModalAdicionaisObservacoes(
    BuildContext context,
    String numeroProduto,
    List<dynamic> listaCompleta,
    String numeroComandaFuncao,
    String numeroUsuarioFuncao,
    String numeroDaLicencaSelecionadaFuncao,
  ) {
    // observacoes
    String ultimoNumeroObservacaoSelecionado = '';
    String ultimoNomeObservacaoSelecionado = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TÍTULO DA COMANDA
                  Center(
                    child: Text(
                      'Comanda $numeroComandaFuncao',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // MENSAGEM SE A LISTA ESTIVER VAZIA
                  if (listaCompleta.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Este produto não tem observações',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  // CORPO ROLÁVEL (LISTA DE OBSERVAÇÕES)
                  Expanded(
                    child: ListView(
                      children: [
                        if (listaCompleta.isNotEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Text(
                                'Deseja selecionar uma observação?',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        
                        // Grid de observações
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const larguraMinimaCard = 100.0;
                            final crossAxisCount = (constraints.maxWidth / larguraMinimaCard).floor().clamp(1, 8);

                            final listaObservacoes = listaCompleta.where((item) {
                              return item['numeroobservacao'].toString() != "0" && item['nomeobservacao'].toString() != "0";
                            }).toList();

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: listaObservacoes.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                              itemBuilder: (context, index) {
                                final item = listaObservacoes[index];
                                final nomeObservacao = item['nomeobservacao'].toString();
                                final numeroObservacao = item['numeroobservacao'].toString();

                                // final selecionado = ultimoNumeroObservacaoSelecionado == numeroObservacao;
                                final selecionado = observacoesSelecionadas.contains(nomeObservacao);

                                return GestureDetector(
                                  onTap: () {
                                    if(selecionado){
                                      setModalState(() {
                                        ultimoNumeroObservacaoSelecionado = "";
                                        ultimoNomeObservacaoSelecionado = "";
                                        observacoesSelecionadas.remove(nomeObservacao);
                                      });
                                    } else {
                                      setModalState(() {
                                        ultimoNumeroObservacaoSelecionado = numeroObservacao;
                                        ultimoNomeObservacaoSelecionado = nomeObservacao;
                                        observacoesSelecionadas.add(nomeObservacao);
                                      });
                                    }
                                  },
                                  child: Card(
                                    color: selecionado
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.surfaceContainerLow,
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          nomeObservacao,
                                          textAlign: TextAlign.center,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: selecionado
                                                ? Theme.of(context).colorScheme.onPrimary
                                                : Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        SizedBox(height: 8,),
                        Row(
                          children: [
                            loadingConfirmar ?
                              Expanded(
                                child: Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                    ),
                                  ),
                                ),
                              )
                            : Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if(observacoesSelecionadas.isNotEmpty){
                                    loadingConfirmar = true;
                                    String observacoesSelecionadasFinal = "";
                                    if(observacoesSelecionadas.length > 1) {
                                      observacoesSelecionadasFinal = await montarObservacoes(await observacoesSelecionadas);
                                    } else {
                                      observacoesSelecionadasFinal = observacoesSelecionadas[0];
                                    }
                                      
                                    cliqueiFora = false;

                                    Navigator.pop(context);
                                    
                                    if (ultimoNumeroObservacaoSelecionado != "") {
                                      await abrirPedido(numeroComandaFuncao, await configuracaoServico());
                                      await devolverPedido(numeroComandaFuncao);
                                      await atualizarCartoes(numeroComandaFuncao, valorTotalLiquido, statusPedido);
                                      await inserirProdutoComObservacoes(
                                        numeroProduto,
                                        numeroComandaFuncao,
                                        numeroUsuarioFuncao,
                                        numeroDaLicencaSelecionadaFuncao,
                                        observacoesSelecionadasFinal,
                                      );
                                      await checkInRealizadoComSucesso(numeroComandaFuncao);
                                      
                                      loadingConfirmar = false;
                                    } 
                                  } 
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: observacoesSelecionadas.length > 0
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.surfaceDim,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Confirmar',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color:  observacoesSelecionadas.length > 0
                                            ? Theme.of(context).colorScheme.onPrimary 
                                            : Theme.of(context).colorScheme.onPrimary ,
                                            /* : Theme.of(context).colorScheme.onSurfaceVariant, */
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.check,
                                      color: observacoesSelecionadas.length > 0
                                          ? Theme.of(context).colorScheme.onPrimary 
                                          : Theme.of(context).colorScheme.onPrimary ,
                                          // : Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ESPAÇAMENTO ENTRE A LISTA E OS BOTÕES
                  const SizedBox(height: 16),

                  // PAINEL DE BOTÕES FIXOS EM BAIXO
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 2ª LINHA: CANCELAR E NÃO INFORMAR (LADO A LADO)
                      Row(
                        children: [
                          // Botão Cancelar
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                cliqueiFora = false;
                                await checkInRealizadoSemSucesso(numeroComandaFuncao);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.error,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Theme.of(context).colorScheme.onError,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 12), // Espaço horizontal entre os dois botões

                          // Botão Não Informar
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                cliqueiFora = false;
                                
                                Navigator.pop(context);

                                await abrirPedido(numeroComandaFuncao, await configuracaoServico());
                                await devolverPedido(numeroComandaFuncao);
                                await atualizarCartoes(numeroComandaFuncao, valorTotalLiquido, statusPedido);
                                await inserirProdutoComObservacoes(
                                  numeroProduto,
                                  numeroComandaFuncao,
                                  numeroUsuarioFuncao,
                                  numeroDaLicencaSelecionadaFuncao,
                                  ultimoNomeObservacaoSelecionado,
                                );
                                await checkInRealizadoComSucesso(numeroComandaFuncao);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.shadow,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Não informar',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Theme.of(context).colorScheme.onTertiary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) async {
      if(cliqueiFora){
        await checkInRealizadoSemSucesso(numeroComandaFuncao);
      }
    });
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
      //   drawer: SideNav(),
      //   appBar: PreferredSize(
      //     preferredSize: Size.fromHeight(56),
      //     child:
      //     Obx(() {
      //       final conectado = Connection.connectionStatus.value;
      //       return AppBar(
      //         backgroundColor: Connection.connectionStatus.value ? colorScheme.primary : colorScheme.error,
      //         automaticallyImplyLeading: false,
      //         title: Stack(
      //           alignment: Alignment.center,
      //           children: [
      //             Align(
      //               alignment: Alignment.centerLeft,
      //               child: Builder(
      //                 builder: (context) => IconButton(
      //                   icon: Icon(Icons.menu, color: colorScheme.onPrimary),
      //                   onPressed: () => Scaffold.of(context).openDrawer(),
      //                 ),
      //               ),
      //             ),
      //             Padding(
      //               padding: EdgeInsets.all(5.0),
      //               child: Column(
      //                 mainAxisAlignment: MainAxisAlignment.center,
      //                 children: [
      //                   Obx(() => Text(
      //                         variaveis.nomeEmpresa.value,
      //                         style: TextStyle(
      //                           fontSize: 15,
      //                           fontWeight: FontWeight.bold,
      //                           color: colorScheme.onPrimary,
      //                         ),
      //                       )),
      //                   Text(
      //                     _horaAtual,
      //                     style: TextStyle(
      //                       color: colorScheme.onPrimary,
      //                       fontSize: 15,
      //                     ),
      //                   ),
      //                 ],
      //               ),
      //             ),
      //             Align(
      //               alignment: Alignment.centerRight,
      //               child: Text(
      //                 Connection.connectionStatus.value ? 'Online' : 'Offline',
      //                 style: TextStyle(
      //                   color: colorScheme.onPrimary,
      //                   fontSize: 15,
      //                   fontWeight: FontWeight.bold,
      //                 ),
      //               ),
      //             ),
      //           ],
      //         ),
      //       );
      //     }),
      //   ),
      // Corpo da tela
      body:
          // Quando servidor já está salvo
          Padding(
            padding: EdgeInsets.all(0.0),
            child: Column(
              children: [
                SizedBox(height: 10),
                // Ícone de usuário
                Icon(Icons.login, size: 50, color: colorScheme.primary),
                // Mensagem
                Text(
                  'Check In',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, color: colorScheme.primary),
                ),

                SizedBox(height: 0),
                SizedBox(
                  height: 150,
                  child: AnimatedSwitcher(
                    // ele troca os widgets de forma animada sempre que o conteúdo mudar
                    duration: Duration(
                      milliseconds: 300,
                    ), // quanto tempo vai durar a animação de troca entre os widgets
                    transitionBuilder:
                        (child, animation) => // sacele = tipo da animação
                        ScaleTransition(
                          scale: animation,
                          child: child,
                        ), // está sendo usada uma animação de escala (scale), ou seja, o widget vai crescer ou encolher ao ser exibido
                    child: animacaoAparecer
                        ? Stack(
                            key: ValueKey('iconStack'),
                            alignment: Alignment.center,
                            children: [
                              // Fundo circular mais claro
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      (animacaoCerto
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.error)
                                          .withOpacity(0.15),
                                ),
                              ),

                              // Ícone principal (check ou erro)
                              Icon(
                                animacaoCerto
                                    ? Icons.check_circle_outline
                                    : Icons.error_outline,
                                size: 100,
                                color: animacaoCerto
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                              ),
                            ],
                          )
                        : SizedBox(
                            key: ValueKey('textField'),
                            width: 250,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: TextField(
                                    controller: comandaController,
                                    focusNode: comandaFocus,
                                    readOnly:
                                        true, // impede digitação pelo teclado nativo
                                    showCursor: true, // FORÇA o cursor piscando
                                    cursorColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    keyboardType: TextInputType
                                        .none, // garante que o teclado não abr
                                    textAlign: TextAlign.center,
                                    // keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor:
                                          // _isFocused? colorScheme.primary.withOpacity(0.15)
                                          //   :
                                          animacaoCerto
                                          ? colorScheme.primary.withOpacity(
                                              0.15,
                                            )
                                          : colorScheme.error.withOpacity(0.15),
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 30,
                                        horizontal: 16,
                                      ),
                                    ),
                                    style: TextStyle(fontSize: 60),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 10),

                // Mensagem
                isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 6,
                          valueColor: AlwaysStoppedAnimation(
                            colorScheme.primary,
                          ),
                        ),
                      )
                    : Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                mensagem,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  color: corMensagem
                                      ? colorScheme.primary
                                      : colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 5),
                          ],
                        ),
                      ),

                if (comandaRegistrada)
                  Text(
                    comandaRegistrada
                        ? 'Última comanda inserida: $comandaNumero'
                        : '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                SizedBox(height: 15),

                // Teclado numérico
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final int crossAxisCount = 3;
                      final int itemCount = 12;
                      final double spacing = 8.0; // espaço entre teclas
                      final int rows = (itemCount / crossAxisCount).ceil();

                      // mantém proporção quadrada ou ajusta à área disponível
                      double cellWidth =
                          (constraints.maxWidth -
                              (spacing * (crossAxisCount - 1))) /
                          crossAxisCount;
                      double cellHeight =
                          (constraints.maxHeight - (spacing * (rows - 1))) /
                          rows;

                      // Logs temporários solicitados para rastrear os valores envolvidos
                      print(
                        '[CheckinPage] constraints: ${constraints.maxWidth} x ${constraints.maxHeight}',
                      );
                      print(
                        '[CheckinPage] cellWidth original: $cellWidth, cellHeight original: $cellHeight',
                      );

                      // A causa raiz do problema: se a tela encolher muito
                      // (ex: na abertura do teclado numérico ou redimensionamento da janela),
                      // constraints.maxHeight pode ficar menor que o espaço consumido apenas pelos paddings (spacing * (rows - 1)).
                      // Com isso, (constraints.maxHeight - spacing) fica <= 0, tornando o cellHeight <= 0.
                      // Consequentemente, childAspectRatio resultará em algo <= 0 ou Infinity caindo no AssertionError do GridView.

                      // Correção: Garantir que cellWidth e cellHeight sempre sejam positivos estritos (> 0).
                      if (cellWidth <= 0) cellWidth = 1.0;
                      if (cellHeight <= 0) cellHeight = 1.0;

                      final double childAspectRatio = cellWidth / cellHeight;
                      print(
                        '[CheckinPage] childAspectRatio final: $childAspectRatio',
                      );

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
                                padding:
                                    EdgeInsets.zero, // Remove o padding fixo
                                backgroundColor: colorScheme.onPrimary,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Icon(
                                  Icons.backspace,
                                  size: 32, // ícone maior
                                  color: colorScheme.primary,
                                ),
                              ),
                            );
                          } else if (index == 10) {
                            return ElevatedButton(
                              onPressed: () => _adicionarNumero("0"),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                                padding:
                                    EdgeInsets.zero, // Remove o padding fixo
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: const Text(
                                  "0",
                                  style: TextStyle(
                                    fontSize: 28,
                                  ), // número maior
                                ),
                              ),
                            );
                          } else if (index == 11) {
                            return ElevatedButton(
                              onPressed: _confirmar,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                                padding:
                                    EdgeInsets.zero, // Remove o padding fixo
                                backgroundColor: cliqueiCheck
                                    ? colorScheme.primary.withOpacity(0.01)
                                    : colorScheme.primary,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Icon(
                                  Icons.check,
                                  size: 32, // ícone maior
                                  color: colorScheme.onPrimary,
                                ),
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
                                padding:
                                    EdgeInsets.zero, // Remove o padding fixo
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
                SizedBox(height: 0),

                // Barra inferior com botões quadrados
                Padding(
                  padding: aparecerNote
                      ? EdgeInsets.only(
                          top: 5.0,
                          bottom: 15.0,
                          left: 10.0,
                          right: 10.0,
                        )
                      : EdgeInsets.only(
                          top: 5.0,
                          bottom: 15.0,
                          left: 15.0,
                          right: 15.0,
                        ),
                  child: Row(
                    children: [
                      // SizedBox(width: 4),
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
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => CheckinPage(),
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
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => CheckoutPage(),
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

                      /* if( aparecerCheckInOut || !naoAparecerMapa)
                        SizedBox(width: 8),
                        if(!naoAparecerMapa)
                        // Botão Mapa de Mesas
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration: Duration.zero, // sem duração
                                  reverseTransitionDuration: Duration.zero, // sem duração ao voltar
                                  pageBuilder:(context, animation, secondaryAnimation,) => MapaPage(),
                                  transitionsBuilder: (context, animation, secondaryAnimation,child,) {
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
                        ), */
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
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => NotesPage(),
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
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => RecepcaoPage(),
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
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => MapaPage(),
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
                      // SizedBox(width: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

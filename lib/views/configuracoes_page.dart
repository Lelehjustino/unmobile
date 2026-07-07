import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:pinput/pinput.dart';
import 'package:un_recepcao/controllers/navegacao_inteligente.dart';
import 'package:un_recepcao/controllers/views/funcoes_controller.dart';
import 'package:un_recepcao/controllers/views/painel_controller.dart';
import 'package:un_recepcao/data/data_class.dart';
import 'package:un_recepcao/views/checkin_page.dart';
import 'package:un_recepcao/views/checkout_page.dart';
import 'package:un_recepcao/views/garcom_page.dart';
import 'package:un_recepcao/views/inicial_page.dart';
import 'package:un_recepcao/views/mapa_page.dart';
import 'package:un_recepcao/views/notes_page.dart';
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
  String versaoAplicacao = FuncoesController().versaoDoApp;
  final FuncoesController funcoesController = Get.put(FuncoesController());

  final TextEditingController senhaController = TextEditingController();
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
  // final variaveis = Get.find<VariaveisController>();

  /* List<dynamic> listaAdicionaisObservacoesDoProduto = [];
  List<dynamic> listaAdicionaisDoProduto = [];
  List<dynamic> listaObservacaoesDoProduto =[]; */

  // Flags / Sets
  List<String> recepcao = ['Recepção'];
  Set<String> recepcaoSelecionados = {};

  List<String> modos = ['Mesa', 'Comanda'];
  // Set<String> modosSelecionados = {'Mesa', 'Comanda'};
  Set<String> modosSelecionados = {};

  List<String> notes = ['Notes'];
  Set<String> notesSelecionados = {};

  List<String> check = ['Ckeck-in', 'Check-out'];
  Set<String> checkSelecionados = {};

  List<String> garcom = ['Modo Garçom'];
  Set<String> garcomSelecionados = {'Modo Garçom'};

  // List<String> paineis = ['KDS', 'Pedidos', 'Expedição motoboy'];
  List<String> paineis = ['KDS', 'Expedição cliente', 'Expedição motoboy'];
  Set<String> paineisSelecionados = {};

  // List<String> rotas = ['Home', 'Painel cliente'];
  List<String> rotas = ['Home', 'Expedição cliente'];
  Set<String> rotasSelecionadas = {'Home'};

  bool servidorConectado = false;

  bool clicado = false;

  final ScrollController _scrollController = ScrollController();

  bool aparecerCheckInOut = false;
  bool aparecerCheckIn = false;
  bool aparecerCheckOut = false;
  bool aparecerGarcom = false;
  bool aparecerNote = false;
  bool aparecerRecepcao = false;
  bool naoAparecerMapa = true;

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

  final painelController = Get.put(PainelController());

  // Variaveis de Rota
  bool rotaHome = true;
  bool rotaPainelCliente = false;

  String rotaAntiga = "";
  String rotaNova = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    painelController.estaNoPainelCozinha.value = false;

    // inicia timer seguro (não assume que será não-nulo)
    _atualizarHora();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      // sem setState direto sem checar mounted
      if (!mounted) return;
      _atualizarHora();
    });

    // focus listener
    servidorFocusNode.addListener(() {
      if (!mounted) return;
      setState(() {
        _isFocused = servidorFocusNode.hasFocus;
      });
    });

    _loadServidor();
    _loadModoSalvo();
    _loadNoteSalvo();
    _loadRecepcaoSalvo();
    _loadCheckSalvo();
    _loadGarcomSalvo();
    _loadServidorAntigo();
    _loadPainelSalvo();
    carregarRota();

    _carregarModos();
    _carregarNote();
    _carregarRecepcao();
    _carregargarcom();
    _carregarchecks();
    _loadNomeEmpresa();
    pegarServidorAntigo();
    pegarRotaAntiga();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    servidorFocusNode.removeListener(() {});
    servidorFocusNode.dispose();
    _timer?.cancel();
    servidorController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  navegar() async {
    // debugPrint('\n─── navegar() chamado ───');
    // debugPrint('  rotaPainelCliente: $rotaPainelCliente');
    // debugPrint('  aparecerGarcom   : $aparecerGarcom');
    // debugPrint('  aparecerCheckIn  : $aparecerCheckIn');
    // debugPrint('  aparecerCheckOut : $aparecerCheckOut');
    // debugPrint('  naoAparecerMapa  : $naoAparecerMapa  (mapa=${!naoAparecerMapa})');
    // debugPrint('  aparecerRecepcao : $aparecerRecepcao');
    // debugPrint('  aparecerNote     : $aparecerNote');

    if (rotaPainelCliente) {
      // debugPrint('  → Navegando para: /painel_cliente');
      Get.toNamed('/painel_cliente');
    } else {
      if (aparecerGarcom) {
        // debugPrint('  → Navegando para: /garcom');
        Get.toNamed('/garcom');
      } else if (aparecerCheckIn) {
        // debugPrint('  → Navegando para: CheckinPage');
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => CheckinPage()));
      } else if (aparecerCheckOut) {
        // debugPrint('  → Navegando para: CheckoutPage');
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => CheckoutPage()));
      } else if (!naoAparecerMapa) {
        // debugPrint('  → Navegando para: MapaPage');
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => MapaPage()));
      } else if (aparecerRecepcao) {
        // debugPrint('  → Navegando para: RecepcaoPage');
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => RecepcaoPage()));
      } else if (aparecerNote) {
        // debugPrint('  → Navegando para: NotesPage');
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => NotesPage()));
      } else {
        // debugPrint('  → Fallback: Navegando para /garcom (nenhuma opção configurada)');
        Get.toNamed('/garcom');
      }
    }
    // debugPrint('─────────────────────────\n');
  }

  void pegarServidorAntigo() async {
    await _loadServidorAntigo();
    servidorAntigoFuncao = servidorController.text;
  }

  void pegarRotaAntiga() async {
    await carregarRota();
    if (rotaHome) {
      rotaAntiga = "Home";
    } else {
      rotaAntiga = "Cliente";
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
      // A chave usada na UI é 'Modo Garçom'.
      // Se está no set → garçom ativo; se não está → garçom inativo.
      setState(() {
        aparecerGarcom = garcomSalvos.contains('Modo Garçom');
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
      final rotasSalvos = Set<String>.from(jsonDecode(rotaJson));

      if (rotasSalvos.contains("Home") &&
          !rotasSalvos.contains("Expedição cliente")) {
        // home
        setState(() {
          rotaHome = true;
          rotaPainelCliente = false;
        });
      } else if (rotasSalvos.contains("Expedição cliente") &&
          !rotasSalvos.contains("Home")) {
        // painel cliente
        setState(() {
          rotaHome = false;
          rotaPainelCliente = true;
        });
      } else {
        // home
        setState(() {
          rotaHome = true;
          rotaPainelCliente = false;
        });
      }
    } else {
      // home
      setState(() {
        rotaHome = true;
        rotaPainelCliente = false;
      });
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
    if (rotaHome && !rotaPainelCliente) {
      setState(() {
        rotaNova = "Home";
      });
    } else if (!rotaHome && rotaPainelCliente) {
      setState(() {
        rotaNova = "Painel cliente";
      });
    }
    // debugPrint("rotaNova: $rotaNova");
    // debugPrint("rotaAntiga: $rotaAntiga");
  }


  Future<void> _loadGarcomSalvo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // CORRIGIDO: lia 'rota_padrao' por engano — deve ser 'garcom_padrao'
      final savedGarcom = prefs.getString('garcom_padrao');
      if (savedGarcom != null) {
        final setLocal = Set<String>.from(jsonDecode(savedGarcom));
        if (!mounted) return;
        setState(() {
          garcomSelecionados = setLocal;
        });
      }
    } catch (e, st) {
      // debugPrint("Erro _loadGarcomSalvo(): $e\n$st");
    }
  }

  /// Deriva as variáveis booleanas de navegação diretamente dos Sets em memória.
  /// Deve ser chamada APÓS salvar os Sets, eliminando a necessidade de reler
  /// o SharedPreferences e evitando race conditions.
  void _aplicarConfiguracoesDaMemoria() {
    // debugPrint('\n═══ _aplicarConfiguracoesDaMemoria ═══');
    // debugPrint('  modosSelecionados   : $modosSelecionados');
    // debugPrint('  checkSelecionados   : $checkSelecionados');
    // debugPrint('  garcomSelecionados  : $garcomSelecionados');
    // debugPrint('  notesSelecionados   : $notesSelecionados');
    // debugPrint('  recepcaoSelecionados: $recepcaoSelecionados');
    // debugPrint('  rotasSelecionadas   : $rotasSelecionadas');

    // --- Modos (Mesa / Comanda) → mapa e check-in/out ---
    final temMesa = modosSelecionados.contains('Mesa');
    final temComanda = modosSelecionados.contains('Comanda');
    naoAparecerMapa = !(temMesa || temComanda);
    if (temMesa && !temComanda) {
      aparecerCheckInOut = false;
    } else if (temComanda) {
      aparecerCheckInOut = true;
    } else {
      aparecerCheckInOut = false;
    }

    // --- Check-in / Check-out ---
    aparecerCheckIn = checkSelecionados.contains('Ckeck-in');
    aparecerCheckOut = checkSelecionados.contains('Check-out');

    // --- Garçom ---
    // A chave usada na UI é 'Modo Garçom'.
    // Se está no set → garçom ativo; se não está → garçom inativo.
    aparecerGarcom = garcomSelecionados.contains('Modo Garçom');

    // --- Notes ---
    aparecerNote = notesSelecionados.contains('Notes');

    // --- Recepção ---
    aparecerRecepcao = recepcaoSelecionados.contains('Recepção');

    // --- Rota ---
    final temPainelCliente = rotasSelecionadas.contains('Expedição cliente');
    rotaPainelCliente = temPainelCliente;
    rotaHome = !temPainelCliente;

    // --- Atualiza rotaNova para comparação com rotaAntiga ---
    rotaNova = rotaPainelCliente ? 'Painel cliente' : 'Home';

    // debugPrint('  ─── Resultado ───');
    // debugPrint('  aparecerGarcom    : $aparecerGarcom');
    // debugPrint('  aparecerCheckIn   : $aparecerCheckIn');
    // debugPrint('  aparecerCheckOut  : $aparecerCheckOut');
    // debugPrint('  naoAparecerMapa   : $naoAparecerMapa  (mapa=${!naoAparecerMapa})');
    // debugPrint('  aparecerRecepcao  : $aparecerRecepcao');
    // debugPrint('  aparecerNote      : $aparecerNote');
    // debugPrint('  rotaPainelCliente : $rotaPainelCliente');
    // debugPrint('  rotaNova          : $rotaNova');
    // debugPrint('════════════════════════════════════════\n');
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
                                  navegar();
                                  servidorAntigo = servidorController.text;
                                  _saveServidorAntigo(servidorAntigo);
                                  funcoesController
                                      .controlarAparecimentoBotaoPagar(
                                        funcaoDoGarcomFuncao,
                                      );
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
                                    navegar();
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

  // Função com o popup para selecionar garçom
  /*   void popupSelecionarGarcom() {
    if (!servidorConectado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Sem conexão com o servidor."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (nomeDaLicenca == "") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Selecione uma licença primeiro."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

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
                            setState(() {
                              garcomSelecionadoFuncao = true;
                              numeroDoGarcom = garcom['numero'].toString();
                              nomeDoGarcom = garcom['nome'];
                             });
                            await _saveGarcom(garcom['nome']);
                            await _saveNumeroGarcom(garcom['numero']);
                            navegar();
                            servidorAntigo = servidorController.text;
                            _saveServidorAntigo(servidorAntigo);
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
    );
  } */

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
            Center(
              child: Text(
                'Configurações de rede:',
                style: TextStyle(
                  color: colorScheme.onSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                children: [
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
                        'Testar conexão',
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
                      // modos, notes, recepcao (sem alterações lógicas — já protegidas)
                      Center(
                        child: Text(
                          'Configurações de modo e mapa:',
                          style: TextStyle(
                            color: colorScheme.onSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      if (modos.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(right: 150),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: modos.length,
                            itemBuilder: (context, index) {
                              String modo = modos[index];
                              bool isChecked = modosSelecionados.contains(modo);
                              return CheckboxListTile(
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                title: Text(modo),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (modosSelecionados.length <= 2)
                                        modosSelecionados.add(modo);
                                    } else {
                                      modosSelecionados.remove(modo);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      SizedBox(height: 7),
                      Center(
                        child: Text(
                          'Configurações notes:',
                          style: TextStyle(
                            color: colorScheme.onSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      if (notes.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(right: 150),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: notes.length,
                            itemBuilder: (context, index) {
                              String modo = notes[index];
                              bool isChecked = notesSelecionados.contains(modo);
                              return CheckboxListTile(
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                title: Text(modo),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (notesSelecionados.length <= 2)
                                        notesSelecionados.add(modo);
                                    } else {
                                      notesSelecionados.remove(modo);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      Center(
                        child: Text(
                          'Configurações de recepção:',
                          style: TextStyle(
                            color: colorScheme.onSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      if (recepcao.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(right: 150),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: recepcao.length,
                            itemBuilder: (context, index) {
                              String modo = recepcao[index];
                              bool isChecked = recepcaoSelecionados.contains(
                                modo,
                              );
                              return CheckboxListTile(
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                title: Text(modo),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (recepcaoSelecionados.length <= 2)
                                        recepcaoSelecionados.add(modo);
                                    } else {
                                      recepcaoSelecionados.remove(modo);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      Center(
                        child: Text(
                          'Configurações check-in e check-out:',
                          style: TextStyle(
                            color: colorScheme.onSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      if (check.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(right: 150),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: check.length,
                            itemBuilder: (context, index) {
                              String modo = check[index];
                              bool isChecked = checkSelecionados.contains(modo);
                              return CheckboxListTile(
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                title: Text(modo),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (checkSelecionados.length <= 2)
                                        checkSelecionados.add(
                                          modo,
                                        ); // só pode ter até duas opções selecionadas na lista
                                    } else {
                                      checkSelecionados.remove(modo);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      Center(
                        child: Text(
                          'Configurações garçom:',
                          style: TextStyle(
                            color: colorScheme.onSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      if (garcom.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(right: 150),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: garcom.length,
                            itemBuilder: (context, index) {
                              String modo = garcom[index];
                              bool isChecked = garcomSelecionados.contains(
                                modo,
                              );
                              return CheckboxListTile(
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                title: Text(modo),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (garcomSelecionados.length <= 2)
                                        garcomSelecionados.add(modo);
                                    } else {
                                      garcomSelecionados.remove(modo);
                                    }
                                  });
                                  /*  setState(() {
                               if (value == true) { // se for true, significa que o usuário marcou uma alternativa 
                                  // Ao selecionar uma opção, desmarque as outras
                                  garcomSelecionados.clear(); // limpa absolutamente tudo 
                                  garcomSelecionados.add(modo); // adiciona apenas o checkbox marcado 
                                } else {
                                  // Se desmarcar, remove a opção da lista
                                  garcomSelecionados.remove(modo); // se o usuario desmarcar o checkbox, remove
                                }
                            }); */
                                },
                              );
                            },
                          ),
                        ),
                      Center(
                        child: Text(
                          'Configuração dos painéis:',
                          style: TextStyle(
                            color: colorScheme.onSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      if (paineis.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(right: 150),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: paineis.length,
                            itemBuilder: (context, index) {
                              String modo = paineis[index];
                              bool isChecked = paineisSelecionados.contains(
                                modo,
                              );
                              return CheckboxListTile(
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                title: Text(modo),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (paineisSelecionados.length <= 3)
                                        paineisSelecionados.add(modo);
                                    } else {
                                      paineisSelecionados.remove(modo);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),

                      Center(
                        child: Text(
                          'Configuração de rota inicial:',
                          style: TextStyle(
                            color: colorScheme.onSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      if (paineis.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.only(right: 150),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: rotas.length,
                            itemBuilder: (context, index) {
                              String modo = rotas[index];
                              bool isChecked = rotasSelecionadas.contains(modo);
                              return CheckboxListTile(
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                title: Text(modo),
                                value: isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      rotasSelecionadas.clear();
                                      rotasSelecionadas.add(modo);
                                    } else {
                                      rotasSelecionadas.remove(modo);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Teclado numérico
            /* Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final int crossAxisCount = 3;
                  final int itemCount = 12;
                  final double spacing = 8.0;
                  final int rows = (itemCount / crossAxisCount).ceil();
                  final double cellWidth =
                      (constraints.maxWidth -
                          (spacing * (crossAxisCount - 1))) /
                      crossAxisCount;
                  final double cellHeight =
                      (constraints.maxHeight - (spacing * (rows - 1))) / rows;
                  final double childAspectRatio = cellWidth / cellHeight;
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
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
                            padding: EdgeInsets.zero,
                            backgroundColor: colorScheme.onPrimary,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Icon(
                              Icons.backspace,
                              size: 32,
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
                        return ElevatedButton(
                          onPressed: () => _adicionarNumero("."),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            backgroundColor: colorScheme.primary,
                            padding: EdgeInsets.zero,
                          ),
                          child: Center(
                            child: Text(
                              ".",
                              style: TextStyle(
                                fontSize: 15,
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
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
                            padding: EdgeInsets.zero,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              numero,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ), */
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

                            // ── PASSO 1: Salva todos os Sets no SharedPreferences ──
                            await salvarModoSalvo(modosSelecionados);
                            await salvarNoteSalvo(notesSelecionados);
                            await salvarRecepcaoSalvo(recepcaoSelecionados);
                            await _saveServidor(servidorController.text);
                            await salvarCheckSalvo(checkSelecionados);
                            await salvarGarcomSalvo(garcomSelecionados);
                            await salvarPainelSalvo(paineisSelecionados);
                            await salvarRota(rotasSelecionadas);

                            // ── PASSO 2: Deriva booleanos de navegação DIRETO da memória ──
                            // Não relemos o SharedPreferences — os Sets em memória já são a
                            // fonte da verdade. Isso elimina I/O desnecessário e race conditions.
                            _aplicarConfiguracoesDaMemoria();

                            // ── PASSO 3: Conecta ao banco e navega ──
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
                                if (rotaNova == 'Home' && rotaAntiga == 'Cliente') {
                                  popupSelecionarGarcom();
                                  return;
                                }
                                // Servidor não mudou: navega com booleanos já atualizados
                                await navegar();
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
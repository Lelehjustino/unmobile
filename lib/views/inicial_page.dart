import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:un_recepcao/controllers/connectivity_controller.dart';
import 'package:un_recepcao/controllers/inicial_controller.dart';
import 'package:un_recepcao/controllers/views/footer_buttons_controller.dart';
import 'package:un_recepcao/controllers/views/funcoes_controller.dart';
import 'package:un_recepcao/controllers/views/garcom_controller.dart';
import 'package:un_recepcao/controllers/zerar_atendimento.dart';
import 'package:un_recepcao/data/data_class.dart';
import 'package:un_recepcao/views/checkin_page.dart';
import 'package:un_recepcao/views/checkout_page.dart';
import 'package:un_recepcao/views/configuracoes_page.dart';
import 'package:un_recepcao/views/garcom_page.dart';
import 'package:un_recepcao/views/mapa_page.dart';
import 'package:un_recepcao/views/notes_page.dart';
import 'package:un_recepcao/views/recepcao_page.dart';
import 'package:uuid/uuid.dart';

class InicialPage extends StatefulWidget {
  const InicialPage({super.key});

  @override
  State<InicialPage> createState() => InicialPageState();
}

class InicialPageState extends State<InicialPage> {
  final FuncoesController funcoesController = Get.find<FuncoesController>();
  final FooterButtonsController footerButtonsController = Get.find<FooterButtonsController>();
  final GarcomController garcomController = Get.find<GarcomController>();
  late String versaoAplicacao = funcoesController.versaoDoApp;
  
  // Controller reativo para o fluxo de entrarAutomaticamente
  late final InicialController _inicialCtrl;

  final TextEditingController servidorController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  // bool showKeyboard = false; // Removido: Usaremos teclado nativo agora

  final TextEditingController senhaController = TextEditingController();
  final FocusNode senhaFocusNode = FocusNode();

  String? selectedModo;

  late Timer _timer;
  String _horaAtual = '';
  String nomeEmpresa = '';

  bool aberto = false;
  bool conta = false;
  bool servidorConectado = false;

  String nomeCliente = '';
  bool isLoadingRefresh = false;
  bool isloading = false;

  String numeroDaLicencaComId = "";
  String nomeDaLicencaComId = "0";
  List<dynamic> listaLicencaComId = [];

  List<dynamic> listaGarcom = [];
  String numeroDoGarcom = "";
  String nomeDoGarcom = "";
  bool garcomSelecionado = false;
  bool nomeDoGarcomDoLoad = false;
  String nomeDoGarcomSelecionado = 'nomeDoGarcomSelecionado';

  List<dynamic> listaLicencaDisponivel = [];
  String numeroDaLicencaDisponivel = "";
  String nomeDaLicencaDisponivel = "";
  bool licencaSelecionada = false;
  String numeroDaLicencaSelecionada = "";

  String nomeDaLicenca = "";
  String nomeDaLicencaSelecionada = "";
  bool nomeDaLicencaDoLoad = false;

  String mobileId = "";
  bool existePVDcomMobile = false;

  bool isLoadingSalvar = false;

  String nomeGarcom = "";

  String telefoneEmpresa = "";

  bool aparecerBotaoSelecionarLicenca = false;
  bool _selecionandoLicenca = false;

  bool get mostrarSelecionarLicenca => (!nomeDaLicencaDoLoad && servidorConectado && !isloading && !_inicialCtrl.emExecucao.value) || aparecerModificarLicencaGarcom;
  bool naoEstaCadastrado = true;
  bool aparecerConectar = false;
  String _ipSalvo = "";

  bool carregamento = false;
  bool naoAparecerSelecionarSilenca = false;

  String servidor = "";
  String servidorAntigo = "";

  bool isloadingSenha = true;
  bool erroBool = false;
  int _tentativaLogin = 0;
  void Function()? _resetDialogSenha;

  // Proteção Global contra múltiplos diálogos abertos
  bool _dialogAtivo = false;

  bool aparecerModificarLicencaGarcom = false;

  Timer? _timerSenha;

  void _atualizarHora() {
    if (mounted) {
      setState(() {
        _horaAtual = DateFormat.Hm().format(DateTime.now());
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // Registra o controller reativo (lazy, sem permanent pois é específico desta página)
    _inicialCtrl = Get.put(InicialController());

    entrarAutomaticamente();
    _atualizarHora();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _atualizarHora(),
    );
    _loadServidor();
    _loadGarcom();
    pegarMobileId();
    _loadLicenca();
    _loadNumeroLicenca();
  }

  @override
  void dispose() {
    _timer.cancel();
    Get.delete<InicialController>();
    super.dispose();
  }

  navegacao_inteligente() async {
    await _saveNumeroLicenca(numeroDaLicencaSelecionada);
    await _saveLicenca(nomeDaLicencaSelecionada);
    footerButtonsController.carregarConfiguracoes();
    if (footerButtonsController.rotaPainelCliente.value) {
      Get.toNamed('/painel_cliente');
    } else if (footerButtonsController.rotaExpedicaoMotoboy.value) {
      Get.toNamed('/expedicao_motoboy');
    } else {
      if (footerButtonsController.aparecerCheckIn.value) {
        Get.toNamed('/checkin');
      } else if ((footerButtonsController.vendaComanda.value && garcomController.vendaComanda.value) || (footerButtonsController.vendaMesa.value && garcomController.vendaMesa.value) || (footerButtonsController.retirarBalcao.value && funcoesController.vendaBalcao.value)) {
        // venda comanda marcada 
        if(footerButtonsController.vendaComanda.value && garcomController.vendaComanda.value){
          garcomController.retirarBalcaoRota.value = false;
          garcomController.vendaComanda.value = true;
          garcomController.vendaMesa.value = false;
        } 
        // venda mesa marcada 
        else if (footerButtonsController.vendaMesa.value && garcomController.vendaMesa.value) {
          garcomController.retirarBalcaoRota.value = false;
          garcomController.vendaComanda.value = false;
          garcomController.vendaMesa.value = true;
        } 
        // venda balcao marcada 
        else if (footerButtonsController.retirarBalcao.value && funcoesController.vendaBalcao.value) {
          garcomController.retirarBalcaoRota.value = true;
          garcomController.vendaComanda.value = false;
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
      // cupom avulso
      else if(footerButtonsController.aparecerCupomAvulso.value){
        Get.toNamed('/cupom_avulso');
      }
      else {
        Get.toNamed('/garcom');
        // venda comanda 
        if(garcomController.vendaComanda.value){
          garcomController.retirarBalcaoRota.value = false;
          garcomController.vendaComanda.value = true;
          garcomController.vendaMesa.value = false;
        } else if (garcomController.vendaMesa.value){
          garcomController.retirarBalcaoRota.value = false;
          garcomController.vendaComanda.value = false;
          garcomController.vendaMesa.value = true;
        } else if (funcoesController.vendaBalcao.value){
          garcomController.retirarBalcaoRota.value = true;
          garcomController.vendaComanda.value = false;
          garcomController.vendaMesa.value = false;
        }
      }
    }
  }


  // entrarAutomaticamente 
  Future<void> entrarAutomaticamente() async {
    // Guard: evita múltiplas execuções simultâneas
    if (_inicialCtrl.emExecucao.value) return;
    _inicialCtrl.emExecucao.value = true;

    if (mounted) setState(() => aparecerConectar = false);

    try {
      // ── ETAPA 1: tentar servidor salvo ────────────────────────────────────
      _inicialCtrl.atualizar(
        StatusConexao.conectandoSalvo,
        '',
      );

      await _loadNumeroLicenca();
      await _loadLicenca();
      await _loadGarcom();

      bool conectado = await Connection.conectarBanconoSalvar();
      if (!mounted) return;

      if (conectado) {
        setState(() => servidorConectado = true);
      }

      

      // ── ETAPA 2: descoberta UDP (fallback) ────────────────────────────────
      if (!servidorConectado) {
        _inicialCtrl.atualizar(
          StatusConexao.descobrindoServidor,
          '',
        );

        final String? discoveredIp = await ConnectivityController.discoverServer();
        if (!mounted) return;

        if (discoveredIp != null && discoveredIp.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('servidor', discoveredIp);

          if (mounted) {
            setState(() => servidorController.text = discoveredIp);
          }

          conectado = await Connection.conectarBanconoSalvar();
          if (!mounted) return;

          if (conectado) setState(() => servidorConectado = true);
        }
      }

      // ── ETAPA 3: falha total ──────────────────────────────────────────────
      if (!servidorConectado) {
        _inicialCtrl.atualizar(
          StatusConexao.falhaConexao,
          '',
        );
        if (mounted) setState(() => aparecerConectar = true);
        return; // Interrompe o fluxo
      }

      // ── ETAPA 4: carrega dados do servidor ────────────────────────────────
      _inicialCtrl.atualizar(
        StatusConexao.carregandoDados,
        '',
      );
      await funcoesController.carregarTudo();

      await carregarNomeEmpresa();
      if (!mounted) return;

      await informacoesGarcom();
      if (!mounted) return;

      await pegarMobileId();
      if (!mounted) return;

      // ── ETAPA 5: verifica licença vinculada ao dispositivo ─────────────────
      _inicialCtrl.atualizar(
        StatusConexao.verificandoLicenca,
        '',
      );

      await vefificacaoLicencaComId();
      if (!mounted) return;

      _inicialCtrl.atualizar(StatusConexao.pronto, '');

      if (existePVDcomMobile) {
        // Licença válida para este dispositivo — exige seleção de usuário
        if (mounted) {
          setState(() {
            nomeDaLicencaDoLoad = true;
            licencaSelecionada = true;
            aparecerBotaoSelecionarLicenca = true;
            naoEstaCadastrado = false;
          });
        }

        await informacoesGarcom();
        if (!mounted) return;

        // Sempre exige seleção de usuário ao entrar (sem restaurar sessão anterior)
        await footerButtonsController.carregarRota();
        if (listaGarcom.isNotEmpty && !footerButtonsController.rotaPainelCliente.value && !footerButtonsController.rotaExpedicaoMotoboy.value) {
          await Get.find<ZerarAtendimentoController>().loadNumeroLicenca();
          await Get.find<ZerarAtendimentoController>().zerarAtendimento();
          popupSelecionarGarcom();
        } else {
          navegacao_inteligente();
        }
      } else {
        // Sem licença válida para este dispositivo — exige seleção de licença
        if (!naoAparecerSelecionarSilenca) {
          if (mounted) {
            setState(() {
              nomeDaLicencaDoLoad = false;
              licencaSelecionada = false;
              aparecerBotaoSelecionarLicenca = false;
              naoEstaCadastrado = true;
            });
          }
          await verificarLicencasDisponiveis();
          if (!mounted) return;
          popupSelecionarLicenca();
        }
      }
    } catch (e, st) {
      debugPrint('[entrarAutomaticamente] Erro: $e\n$st');
      _inicialCtrl.atualizar(
        StatusConexao.falhaConexao,
        'Erro inesperado. Tente novamente.',
      );
      if (mounted) setState(() => aparecerConectar = true);
    } finally {
      _inicialCtrl.emExecucao.value = false;
    }
  }
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
        aparecerCheckInOut = true;
        naoAparecerMapa = true;
      });
    }
  } */
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
          naoAparecerMapa = true;
        });
      }
    } else {
      setState(() {
        // Se não tiver nada salvo, define padrão
        aparecerCheckInOut = true;
        naoAparecerMapa = true;
      });
    }
  } */

  // Carregar/Salvar servidor
  Future<void> _loadServidor() async {
    final prefs = await SharedPreferences.getInstance();
    final servidorSalvo = prefs.getString('servidor');
    if (servidorSalvo != null && mounted) {
      setState(() {
        servidorController.text = servidorSalvo;
        _ipSalvo = servidorSalvo;
      });
    }
  }

  Future<void> _saveServidor(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('servidor', value);
      if (mounted) {
        setState(() {
          _ipSalvo = value;
        });
      }
    } catch (e, st) {
      debugPrint("Erro _saveServidor(): $e\n$st");
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
      debugPrint("Erro _saveServidorAntigo(): $e\n$st");
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

  // Carregar/Salvar licença
  // Apenas carrega valores brutos — flags de validação (nomeDaLicencaDoLoad,
  // licencaSelecionada) são setadas somente após vefificacaoLicencaComId().
  Future<void> _loadLicenca() async {
    final prefs = await SharedPreferences.getInstance();
    final licencaSalvo = prefs.getString('licenca');
    if (licencaSalvo != null && mounted) {
      setState(() {
        nomeDaLicenca = licencaSalvo;
        nomeDaLicencaSelecionada = licencaSalvo;
      });
    }
  }

  Future<void> _saveLicenca(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('licenca', value);
    } catch (e, st) {
      debugPrint("Erro _saveLicenca(): $e\n$st");
    }
  }

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

  Future<void> _saveNumeroLicenca(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('licencaNumero', value);
    } catch (e, st) {
      debugPrint("Erro _saveLicenca(): $e\n$st");
    }
  }


  // Carregar/Salvar garçom
  // O garçom NÃO é restaurado entre sessões — a seleção é sempre exigida
  // ao abrir o app. A escolha persiste apenas em memória durante a sessão.
  Future<void> _loadGarcom() async {
    // Intencionalmente vazio: garçom não é restaurado do SharedPreferences.
  }

  Future<void> _saveGarcom(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('garcom', value);
    } catch (e, st) {
      debugPrint("Erro _saveGarcom(): $e\n$st");
    }
  }

  Future<void> _saveNumeroGarcom(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('numeroGarcom', value);
    } catch (e, st) {
      debugPrint("Erro _saveGarcom(): $e\n$st");
    }
  }

  Future<void> carregarNomeEmpresa() async {
    try {
      final dadosJson = await Connection().select(
        "SELECT nomefantasia, telefone FROM empresa WHERE numero='1' LIMIT 1",
      );

      if (dadosJson == null || dadosJson.isEmpty) {
        nomeEmpresa = "Sem nome";
        telefoneEmpresa = '';
        return;
      }

      final lista = jsonDecode(dadosJson) as List<dynamic>;

      if (lista.isEmpty) {
        nomeEmpresa = "Sem conexão";
        telefoneEmpresa = '';
        return;
      }

      nomeEmpresa = lista[0]['nomefantasia'].toString();
      _saveNomeEmpresa(nomeEmpresa);

      // telefone cru vindo do banco
      final telefoneBruto = lista[0]['telefone'].toString().replaceAll(
        RegExp(r'\D'),
        '',
      );

      // GARANTE que existe DDD
      if (telefoneBruto.length >= 2) {
        telefoneEmpresa = telefoneBruto.substring(
          0,
          2,
        ); // Pega os 2 primeiros dígitos
      } else {
        telefoneEmpresa = '';
      }
    } catch (e, st) {
      debugPrint("Erro ao carregar nome da empresa: $e\n$st");
      nomeEmpresa = "Erro de DB";
      telefoneEmpresa = '';
    }
  }

  Future<void> _saveNomeEmpresa(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nomeEmpresa', value);
    } catch (e, st) {
      debugPrint("Erro _saveNomeEmpresa(): $e\n$st");
    }
  }

  // Função para resetar dados da sessão ao trocar de servidor
  Future<void> _resetarDadosSessao() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('licenca');
    await prefs.remove('licencaNumero');
    await prefs.remove('garcom');
    await prefs.remove('numeroGarcom');
    await prefs.remove('nomeEmpresa');

    setState(() {
      nomeEmpresa = "";
      telefoneEmpresa = "";

      nomeDaLicenca = "";
      nomeDaLicencaSelecionada = "";
      numeroDaLicencaSelecionada = "";
      nomeDaLicencaDoLoad = false;
      licencaSelecionada = false;

      nomeDoGarcom = "";
      nomeDoGarcomSelecionado = "nomeDoGarcomSelecionado";
      nomeDoGarcomDoLoad = false;
      garcomSelecionado = false;
      numeroDoGarcom = "";

      existePVDcomMobile = false;
      listaLicencaComId = [];
      listaLicencaDisponivel = [];
      listaGarcom = [];

      listaLicencaComId.clear();
      listaLicencaDisponivel.clear();
      listaGarcom.clear();

      print(listaLicencaComId);
      print(listaLicencaDisponivel);
      print(listaGarcom);
    });
  }

  // Função para conectar banco
  Future<void> conectarBanco() async {
    try {
      bool conectado = await Connection.conectarBanco();
      if (!mounted) return;
      if (conectado) {
        setState(() => servidorConectado = true);
        await carregarNomeEmpresa();
        if (!mounted) return;
        await informacoesGarcom();
        if (!mounted) return;
        await pegarMobileId();
        if (!mounted) return;
        await vefificacaoLicencaComId();
      } else {
        setState(() => servidorConectado = false);
      }
    } catch (e) {
      print(" Erro ao conectar ao banco: $e");
    }
  }

  // Função para pegar o id do aparelho
  Future<String> pegarMobileId() async {
    final prefs = await SharedPreferences.getInstance();

    // Tenta recuperar o ID já existente
    String? idSalvo = prefs.getString('mobile_id');

    // Se já existe, retorna o mesmo ID
    if (idSalvo != null && idSalvo.isNotEmpty) {
      mobileId = idSalvo;

      if (mounted) {
        setState(() {});
      }

      return idSalvo;
    }

    // Se não existe, gera um UUID único
    final novoId = const Uuid().v4();

    // Salva permanentemente no aparelho
    await prefs.setString('mobile_id', novoId);

    mobileId = novoId;

    if (mounted) {
      setState(() {});
    }

    return novoId;
  }
  /* Future<String> pegarMobileId() async {
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
  } */

  // Função para verificar se o id do aparelho já esta com licença.
  // Valida se a licença salva no SharedPreferences pertence ao Mobile ID atual.
  Future<void> vefificacaoLicencaComId() async {
    if ((servidorController.text == "192.192.192.192") || (servidorController.text == "192192192192")) {
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

      // ── Deduplicar por número de licença ──────────────────────────────────
      final Map<String, dynamic> licencasPorNumero = {};
      for (final item in lista) {
        final num = item['numero'].toString();
        if (!licencasPorNumero.containsKey(num)) {
          licencasPorNumero[num] = item;
        }
      }
      final listaDedup = licencasPorNumero.values.toList();

      if (listaDedup.isNotEmpty) {
        setState(() => listaLicencaComId = listaDedup);

        // ── Verifica se a licença salva pertence a este dispositivo ──────────
        final licencaSalvaValida = numeroDaLicencaSelecionada.isNotEmpty &&
            licencasPorNumero.containsKey(numeroDaLicencaSelecionada);

        if (licencaSalvaValida) {
          // Licença salva é válida para este dispositivo — usa ela
          final licValida = licencasPorNumero[numeroDaLicencaSelecionada]!;
          setState(() {
            numeroDaLicencaComId = licValida['numero'].toString();
            nomeDaLicencaComId = licValida['nome'];
            nomeDaLicenca = nomeDaLicencaComId;
            nomeDaLicencaSelecionada = nomeDaLicencaComId;
            existePVDcomMobile = true;
            naoEstaCadastrado = false;
          });
        } else if (listaDedup.length == 1) {
          // Apenas uma licença vinculada — seleciona automaticamente
          final lic = listaDedup[0];
          final String num = lic['numero'].toString();
          final String nome = lic['nome'];
          setState(() {
            numeroDaLicencaComId = num;
            nomeDaLicencaComId = nome;
            nomeDaLicenca = nome;
            numeroDaLicencaSelecionada = num;
            nomeDaLicencaSelecionada = nome;
            existePVDcomMobile = true;
            naoEstaCadastrado = false;
          });
          await _saveNumeroLicenca(num);
          await _saveLicenca(nome);
        } else {
          // Licença salva inválida e múltiplas opções — força nova seleção
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('licenca');
          await prefs.remove('licencaNumero');
          setState(() {
            numeroDaLicencaComId = "";
            nomeDaLicencaComId = "";
            numeroDaLicencaSelecionada = "";
            nomeDaLicencaSelecionada = "";
            nomeDaLicenca = "";
            existePVDcomMobile = false;
            naoEstaCadastrado = true;
            // Usa as licenças do dispositivo como opções de seleção
            listaLicencaDisponivel = listaDedup;
          });
        }
      } else {
        // Nenhuma licença vinculada a este dispositivo — limpa e força seleção
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('licenca');
        await prefs.remove('licencaNumero');
        setState(() {
          numeroDaLicencaComId = "";
          nomeDaLicencaComId = "";
          listaLicencaComId = [];
          numeroDaLicencaSelecionada = "";
          nomeDaLicencaSelecionada = "";
          nomeDaLicenca = "";
          nomeDaLicencaDoLoad = false;
          licencaSelecionada = false;
          existePVDcomMobile = false;
          naoEstaCadastrado = true;
        });
      }
    } catch (e) {
      print("Erro ao carregar vefificacaoLicencaComId: $e");
      if (!mounted) return;
      setState(() {
        numeroDaLicencaComId = "0";
        nomeDaLicencaComId = "0";
        listaLicencaComId = [];
        existePVDcomMobile = false;
      });
    }
  }

  // Função para verificar licenças disponíveis (sem Mobile ID vinculado).
  // Resultados são deduplicados por número de licença.
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

      // ── Deduplicar por número de licença ──────────────────────────────────
      final Map<String, dynamic> licencasPorNumero = {};
      for (final item in lista) {
        final num = item['numero'].toString();
        if (!licencasPorNumero.containsKey(num)) {
          licencasPorNumero[num] = item;
        }
      }
      final listaDedup = licencasPorNumero.values.toList();

      if (listaDedup.isNotEmpty) {
        String valor = listaDedup[0]['numero'].toString();
        String valor2 = listaDedup[0]['nome'];

        setState(() {
          numeroDaLicencaDisponivel = valor;
          nomeDaLicencaDisponivel = valor2;
          nomeDaLicenca = nomeDaLicencaDisponivel;
          listaLicencaDisponivel = listaDedup;
        });
      } else {
        setState(() {
          numeroDaLicencaDisponivel = "";
          nomeDaLicencaDisponivel = "";
          listaLicencaDisponivel = [];
        });
      }
    } catch (e) {
      print("Erro ao carregar verificarLicencasDisponiveis: $e");
      if (!mounted) return;
      setState(() {
        numeroDaLicencaDisponivel = "0";
        nomeDaLicencaDisponivel = "0";
        listaLicencaDisponivel = [];
      });
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

  void iniciarContador() {
    int segundos = 0;

    // Cancela contador anterior, se existir
    _timerSenha?.cancel();

    _timerSenha = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        segundos++;

        if (segundos >= 20) {
          timer.cancel();
          _timerSenha = null;

          if (!mounted) return;

          setState(() {
            isloadingSenha = true;
          });

          cancelarEntrarSistema();
        }
      },
    );
  }

  void cancelarEntrarSistema() {
    _tentativaLogin++;
    senhaController.clear();
    erroBool = false;

    if (_resetDialogSenha != null) {
      _resetDialogSenha!();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Falha ao entrar no sistema!',
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );

    Future.delayed(Duration(milliseconds: 300), () {
      if (senhaFocusNode.canRequestFocus) {
        senhaFocusNode.requestFocus();
      }
    });
  }
  
  // Função que retorna informações garçom
  Future<void> informacoesGarcom() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, nome, senhanova, funcao, pgtomobile FROM usuarios WHERE ativo = '1' AND numero != '1' AND mobile = '1' ORDER BY nome;",
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
          nomeDoGarcom = "0";
          listaGarcom = [];
        });
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
    }
  }

  // Função com o popup para selecionar garçom
  void popupSelecionarGarcom() {
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

    // ── Validação 3: popup já aberto (evita duplicata) ───────────────────
    if (_dialogAtivo) {
      return;
    }
    _dialogAtivo = true;

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
            child: listaGarcom.isEmpty
                ? Center(child: Text("Nenhum usuário encontrado"))
                : ListView.builder(
                    itemCount: listaGarcom.length,
                    itemBuilder: (context, index) {
                      final garcom = listaGarcom[index];

                      return Card(         
                        child: ListTile(
                          title: Text(garcom['nome']),
                          // subtitle: Text("Número: ${garcom['numero']}"),
                          onTap: () async {
                            Navigator.pop(context, 'transition');
                            _dialogAtivo = false; // Libera flag para o próximo popup
                            aparecerConectar = true;
                            Future.delayed(const Duration(milliseconds: 80), () {
                              if (senhaFocusNode.canRequestFocus) {
                                senhaFocusNode.requestFocus();
                              }
                            });
                            erroBool = false;
                            // abrir pop up senha 
                            popupDigitarSenha(
                              context: context,
                              senhaDoGarcom: garcom['senhanova'],
                              nomeDoGarcomFuncao: garcom['nome'],
                              numeroDoGarcomFuncao: garcom['numero'],
                              funcaoDoGarcomFuncao: garcom['funcao'],
                              pagamentoDoGarcomFuncao: garcom['pgtomobile'],
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
                _dialogAtivo = false;
                setState(() {
                  aparecerConectar = true;
                  carregamento = false;
                  aparecerModificarLicencaGarcom = true;
                });
              },
              child: Text("Cancelar"),
            ),
          ],
        );
      },
    ).then((value) {
      if (value != 'transition') {
        _dialogAtivo = false;
      }
    });
  }

  Future<void> popupDigitarSenha({
    required BuildContext context,
    required String senhaDoGarcom,
    required String nomeDoGarcomFuncao,
    required String numeroDoGarcomFuncao,
    required String funcaoDoGarcomFuncao,
    required String pagamentoDoGarcomFuncao,
    String title = 'Confirmação',
    required String message,
    IconData icon = Icons.home,
    String cancelText = 'Cancelar',
    String confirmText = 'Confirmar',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    TextEditingController? textController,
    required FocusNode focusNode,
    ValueChanged<String>? onSubmitted, // Callback ao submeter o texto
  }) {
    if (_dialogAtivo) return Future.value();
    _dialogAtivo = true;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        String erro = "";
        int _shakeCount = 0;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            _resetDialogSenha = () {
              setDialogState(() {
                 isloadingSenha = true;
              });
            };
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: isloadingSenha ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícone central
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(ctx).colorScheme.primary.withOpacity(0.08),
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
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    SizedBox(height: 5),

                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: _shakeCount.toDouble()),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(math.sin(value * 3 * 3.1415926535 * 2) * 8, 0),
                          child: child,
                        );
                      },
                      child: Pinput(
                        controller: textController,
                        focusNode: focusNode,
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
                            color: erroBool ? Theme.of(ctx).colorScheme.error : Theme.of(ctx).colorScheme.primary,
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
                            senhaController.clear();
                            erroBool = true;
                            _shakeCount++;
                            Future.delayed(Duration(milliseconds: 300), () {
                              if (senhaFocusNode.canRequestFocus) {
                                senhaFocusNode.requestFocus();
                              }
                            });
                          });
                          print("Senha incorreta");
                        } else {
                          setDialogState(() {
                            isloadingSenha = false;
                          });
                          _tentativaLogin++;
                          final int minhaTentativa = _tentativaLogin;
                          iniciarContador();

                          try {
                            await Get.find<ZerarAtendimentoController>().loadNumeroLicenca();
                            if (minhaTentativa != _tentativaLogin) return;
                            await Get.find<ZerarAtendimentoController>().zerarAtendimento();
                            if (minhaTentativa != _tentativaLogin) return;
                            await _saveGarcom(nomeDoGarcomFuncao); 
                            await _saveNumeroGarcom(numeroDoGarcomFuncao);
                            if (minhaTentativa != _tentativaLogin) return;
                            await navegacao_inteligente();
                            if (minhaTentativa != _tentativaLogin) return;
                            funcoesController.controlarAparecimentoBotaoPagar(pagamentoDoGarcomFuncao);
                            print("Senha correta");
                          } finally {
                            if (minhaTentativa == _tentativaLogin) {
                              _timerSenha?.cancel();
                              setDialogState(() {
                                isloadingSenha = true;
                              });
                            }
                          }
                        }
                      },
                    ),
                    ),

                    SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: (){
                            Navigator.pop(ctx, 'transition');
                            _dialogAtivo = false; // Libera flag
                            popupSelecionarGarcom();
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
                            backgroundColor: Theme.of(ctx).colorScheme.primary,
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
                                senhaController.clear();
                                erroBool = true;
                                _shakeCount++;
                                Future.delayed(Duration(milliseconds: 300), () {
                                  if (senhaFocusNode.canRequestFocus) {
                                    senhaFocusNode.requestFocus();
                                  }
                                });
                              });
                              print("Senha incorreta");
                            } else {
                              setDialogState(() {
                                isloadingSenha = false;
                              });
                              _tentativaLogin++;
                              final int minhaTentativa = _tentativaLogin;
                              iniciarContador();
                              
                              try {
                                await Get.find<ZerarAtendimentoController>().loadNumeroLicenca();
                                if (minhaTentativa != _tentativaLogin) return;
                                await Get.find<ZerarAtendimentoController>().zerarAtendimento();
                                if (minhaTentativa != _tentativaLogin) return;
                                await funcoesController.carregarTudo();
                                if (minhaTentativa != _tentativaLogin) return;
                                await _saveGarcom(nomeDoGarcomFuncao);
                                nomeGarcom = nomeDoGarcomFuncao;
                                await _saveNumeroGarcom(numeroDoGarcomFuncao,);
                                if (minhaTentativa != _tentativaLogin) return;
                                await navegacao_inteligente();
                                if (minhaTentativa != _tentativaLogin) return;
                                funcoesController.controlarAparecimentoBotaoPagar(pagamentoDoGarcomFuncao);
                                print("Senha correta");
                              } finally {
                                if (minhaTentativa == _tentativaLogin) {
                                  _timerSenha?.cancel();
                                  setDialogState(() {
                                    isloadingSenha = true;
                                  });
                                }
                              }
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
                            backgroundColor: Theme.of(ctx).colorScheme.primary,
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
                          color: Theme.of(ctx).colorScheme.primary.withOpacity(0.08),
                        ),
                        child: SizedBox(
                          width: 45,
                          height: 45,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      ),

                      SizedBox(height: 20),

                      Text(
                        "Validando usuário",
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
    ).then((value) {
      if (value != 'transition') {
        _dialogAtivo = false;
      }
    });
  }

  // Função com o popup para selecionar licenças diponiveis
  void popupSelecionarLicenca() async {
    if (_dialogAtivo) return;
    _dialogAtivo = true;

    await showDialog(
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
                            final String numSel = licenca['numero'].toString();
                            final String nomeSel = licenca['nome'].toString();

                            setState(() {
                              licencaSelecionada = true;
                              numeroDaLicencaDisponivel = numSel;
                              nomeDaLicencaDisponivel = nomeSel;
                              nomeDaLicencaSelecionada = nomeSel;
                              numeroDaLicencaSelecionada = numSel;
                              nomeDaLicenca = nomeSel;
                              nomeDaLicencaDoLoad = true;
                              naoEstaCadastrado = false;
                              carregamento = false;
                            });

                            // Salva e vincula o Mobile ID à licença selecionada
                            await _saveNumeroLicenca(numSel);
                            await _saveLicenca(nomeSel);
                            await atualizarTradepoint(mobileId, numSel);

                            Navigator.of(context).pop('transition'); // fecha the popup
                            _dialogAtivo = false; // Libera flag para o próximo popup

                            // Carrega usuários e exige seleção (sem loop)
                            await informacoesGarcom();
                            if (!mounted) return;
                            await Get.find<ZerarAtendimentoController>().loadNumeroLicenca();
                            await Get.find<ZerarAtendimentoController>().zerarAtendimento();
                            await footerButtonsController.carregarRota();
                            if (listaGarcom.isNotEmpty && !footerButtonsController.rotaPainelCliente.value && !footerButtonsController.rotaExpedicaoMotoboy.value) {
                              popupSelecionarGarcom();
                            } else {
                              navegacao_inteligente();
                            }
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
                _dialogAtivo = false;
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
    ).then((value) {
      if (value != 'transition') {
        _dialogAtivo = false;
      }
    });
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

  // Método para trocar de licença a qualquer momento.
  // Combina licenças do dispositivo + disponíveis e exibe popup de seleção.
  Future<void> _trocarLicenca() async {
    if (_selecionandoLicenca) return;
    setState(() => _selecionandoLicenca = true);
    try {
      // Busca licenças vinculadas a este dispositivo
      String mobileId = await pegarMobileId();
      String dadosComId = await Connection().select(
        "SELECT numero, nome FROM tradepoints WHERE mobileid='$mobileId' AND tipo='Mobile' AND ativo='1' ORDER BY numero;",
      );
      final List<dynamic> listaComId = jsonDecode(dadosComId);

      // Busca licenças disponíveis (sem vínculo)
      String dadosDisponivel = await Connection().select(
        "SELECT numero, nome FROM tradepoints WHERE mobileid = '' AND tipo='Mobile' AND ativo='1';",
      );
      final List<dynamic> listaDisponivel = jsonDecode(dadosDisponivel);

      // Combina e deduplica as duas listas por número
      final Map<String, dynamic> todasLicencas = {};
      for (final item in listaComId) {
        todasLicencas[item['numero'].toString()] = item;
      }
      for (final item in listaDisponivel) {
        final num = item['numero'].toString();
        if (!todasLicencas.containsKey(num)) {
          todasLicencas[num] = item;
        }
      }

      if (!mounted) return;

      // Limpa licença salva para forçar nova seleção
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('licenca');
      await prefs.remove('licencaNumero');

      setState(() {
        listaLicencaDisponivel = todasLicencas.values.toList();
        nomeDaLicencaDoLoad = false;
        licencaSelecionada = false;
        existePVDcomMobile = false;
        naoEstaCadastrado = true;
        numeroDaLicencaSelecionada = "";
        nomeDaLicencaSelecionada = "";
      });

      if (mounted) popupSelecionarLicenca();
    } catch (e) {
      debugPrint('[_trocarLicenca] Erro: $e');
    } finally {
      if (mounted) setState(() => _selecionandoLicenca = false);
    }
  }

  Future<void> showConfirmationDialog({
    required BuildContext context,
    String title = 'Confirmação',
    required String message,
    IconData icon = Icons.home,
    String cancelText = 'Cancelar',
    String confirmText = 'OK',
    VoidCallback? onConfirm,
  }) {
    if (_dialogAtivo) return Future.value();
    _dialogAtivo = true;

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
                        _dialogAtivo = false;
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
    ).then((_) {
      _dialogAtivo = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ZerarAtendimentoController zerarAtendimentoController = Get.put(
      ZerarAtendimentoController(),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true, // Permitir que o Flutter redimensione a tela para o teclado
      //  drawer: SideNav(),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: Obx(() {
          // este Obx cuida APENAS do que realmente depende de conexão
          final conectado = Connection.connectionStatus.value;
          return AppBar(
            backgroundColor: conectado
                ? colorScheme.primary
                : colorScheme.primary,
            automaticallyImplyLeading: false,
            title: Stack(
              alignment: Alignment.center,
              children: [
                // MENU
                Align(
                  alignment: Alignment.centerLeft,
                  child: Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.settings, color: colorScheme.onPrimary),
                      onPressed: () {
                        showConfirmationDialog(
                          context: context,
                          title: "Faça seu login",
                          message: "Faça seu login para ter acesso as configurações",
                          icon: Icons.error, // você pode trocar para outro ícone
                          onConfirm: () async {
                            Navigator.push(context,
                              PageRouteBuilder(
                                transitionDuration: Duration.zero, // sem duração
                                reverseTransitionDuration: Duration.zero, // sem duração ao voltar
                                pageBuilder: (context, animation, secondaryAnimation) => InicialPage(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return child;
                                },
                              ),
                            );
                          },
                        );
                      },
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
                      /* Obx(() => Text(
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                Image.asset(
                  'assets/app_icon.png',
                  width: 100.0,
                  height: 100.0,
                  fit: BoxFit.cover, // Ajuste a imagem para cobrir a área
                ),
                SizedBox(height: 5),

                Column(
                  children: [
                    Text(
                      servidorController.text.isEmpty
                          ? 'Servidor não conectado:'
                          : 'Servidor: ${servidorController.text}',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (servidorConectado && nomeDaLicencaDoLoad)
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  "Você já está em uma licença:",
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              SizedBox(width: 3),
                              Text(
                                nomeDaLicenca,
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                    SizedBox(height: 15),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15.0),
                      child: Row(
                        children: [
                          if (isloading)
                            Expanded(
                              child: Column(
                                children: [
                                  Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 6,
                                      valueColor: AlwaysStoppedAnimation(
                                        colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (!isloading)
                            Expanded(
                              child: TextField(
                                readOnly: false,
                                showCursor: true,
                                cursorColor: Theme.of(context).colorScheme.primary,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                controller: servidorController,
                                focusNode: _focusNode,
                                textAlign: TextAlign.center,
                                onChanged: (value) {
                                  if(servidorController.text.contains(",")){
                                    servidorController.text = servidorController.text.replaceAll(",", ".");
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: "Digite aqui o seu servidor:",
                                  hintStyle: TextStyle(
                                    color: colorScheme.onSurface,
                                  ),
                                  filled: true,
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
                          SizedBox(width: 5),
                          /* if (!isloading && servidorController.text.isNotEmpty) */
                          if (aparecerConectar)
                            ElevatedButton(
                              onPressed:
                                  (servidorConectado && !aparecerConectar)
                                  ? null
                                  : () async {
                                      /* setState(() {
                                        showKeyboard = false;
                                      }); */ // Removido

                                      if (servidorController.text.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Por favor, preencha o campo com o servidor.',
                                            ),
                                            backgroundColor:
                                                colorScheme.primary,
                                          ),
                                        );
                                        return;
                                      }

                                      if (!mounted) return;
                                      setState(() {
                                        isloading = true;
                                        aparecerConectar = false;
                                      });

                                      try {
                                        await _saveServidor(servidorController.text);
                                        await _loadServidor();

                                        await _resetarDadosSessao();

                                        // bool conectado = await Connection.conectarBanconoSalvar();
                                        bool conectado = await Connection.conectarBanconoSalvar();
                                        entrarAutomaticamente();

                                        if (!mounted) return;

                                        if (conectado) {
                                          setState(
                                            () => servidorConectado = true,
                                          );
                                          await _saveServidorAntigo(servidorController.text);
                                          await carregarNomeEmpresa();
                                          if (!mounted) return;
                                          await pegarMobileId();
                                          if (!mounted) return;
                                          await vefificacaoLicencaComId();
                                          if (!mounted) return;

                                          if (existePVDcomMobile) {
                                            // Já tem licença vinculada, vai direto pro fluxo de garçom
                                            setState(() {
                                              nomeDaLicencaDoLoad = true;
                                              licencaSelecionada = true;
                                              naoEstaCadastrado = false;
                                            });
                                            await informacoesGarcom();
                                            if (!mounted) return;
                                            /* if (listaGarcom.isNotEmpty) {
                                              popupSelecionarGarcom();
                                            } */
                                           await footerButtonsController.carregarRota();
                                           if (listaGarcom.isNotEmpty && !footerButtonsController.rotaPainelCliente.value && !footerButtonsController.rotaExpedicaoMotoboy.value) {
                                              popupSelecionarGarcom();
                                            } else {
                                              navegacao_inteligente();
                                            }
                                          } else {
                                            // Não tem licença, mostra popup para selecionar
                                            await verificarLicencasDisponiveis();
                                            if (!mounted) return;
                                            setState(() {
                                              naoEstaCadastrado = true;
                                              // aqui
                                              aparecerBotaoSelecionarLicenca = false;
                                            });
                                            popupSelecionarLicenca();
                                          }

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Servidor conectado.',
                                              ),
                                              backgroundColor:
                                                  colorScheme.primary,
                                            ),
                                          );
                                        } else {
                                          await _resetarDadosSessao();

                                          if (!mounted) return;
                                          setState(() {
                                            aparecerConectar = true;
                                          });

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Erro ao conectar ao servidor.',
                                              ),
                                              backgroundColor:
                                                  colorScheme.error,
                                            ),
                                          );
                                        }
                                      } catch (e, st) {
                                        debugPrint(
                                          'Erro ao testar conexão: $e\n$st',
                                        );

                                        if (!mounted) return;
                                        setState(() {
                                          aparecerConectar = true;
                                        });
                                        //
                                        if (e.toString().contains(
                                          'ERRO_MYSQL',
                                        )) {
                                          servidorController.clear();
                                          final prefs =
                                              await SharedPreferences.getInstance();
                                          await prefs.remove('servidor');
                                          _ipSalvo = "";
                                          //
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Erro ao conectar servidor.',
                                              ),
                                              backgroundColor:
                                                  colorScheme.primary,
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (!mounted) return;
                                        setState(() {
                                          isloading = false;
                                          if (!servidorConectado)
                                            aparecerConectar = true;
                                        });
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: 20,
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
                    /* if(mostrarSelecionarLicenca) */
                    /* if (naoEstaCadastrado && servidorConectado && !licencaSelecionada) */
                      if(mostrarSelecionarLicenca)
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            /* if (listaLicencaDisponivel.isEmpty)
                              Column(
                                children: [
                                  Text("Não tem licenças disponiveis"),
                                ],
                              ), */
                            if (listaLicencaDisponivel.isNotEmpty && servidorConectado)
                              Text(
                                "Selecione uma licença:",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w300,
                                  color: colorScheme.primary,
                                ),
                              ),
                            SizedBox(height: 5),
                            ElevatedButton(
                              // MUDAR
                              onPressed: _selecionandoLicenca
                                  ? null
                                  : () async {
                                    setState(
                                      () => _selecionandoLicenca = true,
                                    );
                                      try {
                                        await vefificacaoLicencaComId();
                                        await verificarLicencasDisponiveis();
                                        if (mounted) popupSelecionarLicenca();
                                      } finally {
                                        if (mounted)
                                          setState(
                                            () => _selecionandoLicenca = false,
                                          );
                                      }
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
                                licencaSelecionada ? "Modificar licença" : "Selecionar licença",
                                style: TextStyle(color: colorScheme.onPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 20),
                    if (servidorConectado && nomeDaLicencaDoLoad)
                      Column(
                        children: [
                          if (listaLicencaDisponivel.isEmpty)
                            Column(
                              children: [
                                // Row(
                                //   mainAxisAlignment: MainAxisAlignment.center,
                                //   children: [
                                //     Flexible(
                                //       child: Text(
                                //         "Você já está em uma licença:",
                                //         style: TextStyle(
                                //           color: colorScheme.onSurface,
                                //           fontSize: 15,
                                //           fontWeight: FontWeight.w400,
                                //         ),
                                //       ),
                                //     ),
                                //     SizedBox(width: 3,),
                                //     Text(
                                //       nomeDaLicencaSelecionada,
                                //       style: TextStyle(
                                //         color: colorScheme.primary,
                                //         fontSize: 15,
                                //         fontWeight: FontWeight.bold,
                                //       ),
                                //     ),
                                //   ],
                                // )
                              ],
                            ),
                          // SizedBox(height: 5,),
                          if (!licencaSelecionada && nomeDaLicenca != "")
                            AbsorbPointer(
                              absorbing: isLoadingSalvar,
                              child: isLoadingSalvar
                                  ? CircularProgressIndicator(
                                      strokeWidth: 6,
                                      valueColor: AlwaysStoppedAnimation(
                                        colorScheme.primary,
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: () async {
                                        await verificarLicencasDisponiveis();
                                        popupSelecionarLicenca();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 20,
                                        ),
                                        backgroundColor: colorScheme.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          side: BorderSide(
                                            color: colorScheme.primary,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        "Selecionar licença",
                                        style: TextStyle(
                                          color: colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                            ),
                          if (carregamento)
                            CircularProgressIndicator(
                              strokeWidth: 6,
                              valueColor: AlwaysStoppedAnimation(
                                colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                    // ─── Status reativo do fluxo de conexão ────────────────────
                    Obx(() {
                      final ctrl = _inicialCtrl;
                      final status = ctrl.status.value;
                      final msg = ctrl.mensagem.value;
                      final emExec = ctrl.emExecucao.value;

                      // Só exibe quando em execução ou em falha
                      if (!emExec && status != StatusConexao.falhaConexao) {
                        return const SizedBox.shrink();
                      }

                      final Color cor = status == StatusConexao.falhaConexao
                          ? colorScheme.error
                          : colorScheme.primary;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 24.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (status != StatusConexao.falhaConexao) ...[
                              SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    cor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ] else ...[
                              /* Icon(
                                Icons.warning_amber_rounded,
                                color: cor,
                                size: 18,
                              ),
                              const SizedBox(width: 8), */
                            ],
                            Flexible(
                              child: Text(
                                msg,
                                style: TextStyle(
                                  color: cor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    // ───────────────────────────────────────────────────────────
                    SizedBox(height: 50),
                  ],
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
    );
  }
}
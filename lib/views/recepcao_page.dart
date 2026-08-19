import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:un_recepcao/controllers/views/footer_buttons_controller.dart';
import 'package:un_recepcao/controllers/views/funcoes_controller.dart';
import 'package:un_recepcao/controllers/views/painel_controller.dart';
import 'package:un_recepcao/controllers/views/pedidos_controller.dart';
import 'package:un_recepcao/data/data_class.dart';
import 'package:un_recepcao/views/checkin_page.dart';
import 'package:un_recepcao/views/checkout_page.dart';
import 'package:un_recepcao/views/mapa_page.dart';
import 'package:un_recepcao/views/notes_page.dart';
import 'package:un_recepcao/widgets/side_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cpf_cnpj_validator/cpf_validator.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:get/get.dart';

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    // Remove tudo que não for número
    text = text.replaceAll(RegExp(r'[^0-9]'), '');

    // Aplica a formatação dd/MM/yyyy
    if (text.length > 2 && text.length <= 4) {
      text = '${text.substring(0, 2)}/${text.substring(2)}';
    } else if (text.length > 4) {
      text = '${text.substring(0, 2)}/${text.substring(2, 4)}/${text.substring(4)}';
    }

    // Limita a 10 caracteres (dd/MM/yyyy)
    if (text.length > 10) {
      text = text.substring(0, 10);
    }

    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class RecepcaoPage extends StatefulWidget {
  RecepcaoPage({super.key});

  @override
  State<RecepcaoPage> createState() => RecepcaoPageState();
}

class RecepcaoPageState extends State<RecepcaoPage> {
  String versaoAplicacao = FuncoesController().versaoDoApp;
  final funcoesController = Get.find<FuncoesController>();
  final painelController = Get.find<PainelController>();
  final footerButtonsController = Get.find<FooterButtonsController>();
  // final pedidosController = Get.put(PedidosController());

  final ScrollController _scrollController = ScrollController();
  late Timer _timer;
  String _horaAtual = '';
  String _horaBanco = '';
  String nomeEmpresa = '';
  String cidadeEmpresa = '';
  String ufEmpresa = '';
  String nomeEmpresaLoad = '';

  bool checkIn = true;
  bool checkout = false;
  bool mapaDeMesaoOuComanda = false;
  bool comandas = true;

  int atual = 1;

  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  // Controle dos filtros de mesas e comandas
  bool mostrarTodas = true;
  bool mostrarAbertas = false;
  bool mostrarFechadas = false;
  bool mesaAberta = true;

  bool servidorConectado = true;

  List<dynamic> validaComanda = [];
  bool carregando = true;

  // Para fazer requisições em determinado tempo (1/3)
  Timer? _timerSelect;

  String tipoRegistro = 'CPF'; // Variável que define qual tipo de registro o cliente vai usar
  final TextEditingController nomeController = TextEditingController(); //
  final TextEditingController numeroController = TextEditingController();
  final TextEditingController numeroControllerTelefone = TextEditingController();
  final TextEditingController cpfControllerNoCpf = TextEditingController();
  final TextEditingController cpfControllerNoTelefone = TextEditingController();
  final TextEditingController dataNascimentoController = TextEditingController();
  final TextEditingController comandaController = TextEditingController();
  final TextEditingController adicionalController = TextEditingController();

  final FocusNode nomeFocusNode = FocusNode();
  final FocusNode numeroFocusNode = FocusNode();
  final FocusNode numeroTelefoneFocusNode = FocusNode();
  final FocusNode cpfnoCpfFocusNode = FocusNode();
  final FocusNode cpfnoTelefoneFocusNode = FocusNode();
  final FocusNode nascimentoFocusNode = FocusNode();
  final FocusNode comandaFocusNode = FocusNode();
  final FocusNode adicionalFocusNode = FocusNode();

  final _formKey = GlobalKey<FormState>();
  bool corBorda = true;

  List<String> listaSexo = ['MAS', 'FEM', 'NI'];

  String? sexoSelecionado;
  bool radioPreenchido = false;

  bool cpfValido = false;
  bool telefoneValido = false;
  bool dataCorreta = false;
  bool nomeValido = false;
  bool telefoneValidoTel = false;
  bool cpfValidoNumero = false;

  bool inserirComanda = false;
  bool botaoCpf = true;
  bool botaotelefone = false;
  bool vazioCpf = true;
  bool vazioTelefone = true;
  bool corAlerta = true;
  bool corComanda = false;

  String mensagem = '';
  String mensagem2 = '';
  bool isLoading = false;
  bool isLoading2 = false;

  String numeroDoPedido = '';
  String valorTotalLiquido = '';
  String statusPedido = '';
  int numeroDoProduto = 0;

  String comandaNumero = '';
  bool comandaRegistrada = false;

  bool icone = false;

  final FocusNode _searchFocusNode = FocusNode();
  bool _showKeyboardNome = false;
  bool _showKeyboardMaior = false;

  String _campoAtivo = '';
  bool tecladoAlfa = false;

  // ── Guard de foco: impede requestFocus concorrentes ──────────────────────
  bool _focusPendente = false;

  String numeroCliente = '';
  int numeroClienteInt = 0;
  String telefoneCliente = '';
  String cpfCliente = '';
  String sexoCliente = '';
  String datanascimentoCliente = '';
  String nomeCliente = '';
  List<Map<String, dynamic>> adicionais = [];

  bool retornoCpf = false;
  bool retornoNumero = false;

  int couvert = 0;
  String textoComanda = '';
  String comanda = '';

  bool precisoCadastrarCliente = false;

  bool desaparecerTema = false;

  bool comandaFoiValidada = false;
  bool comandaValida = false;
  bool mostrarBotoes = true;

  // final variaveis = Get.find<VariaveisController>();

  String telefoneEmpresa = '';
  String sexoSelecionadoFomatadoSql = '';
  String sexoSelecionadoForm = '';

  bool clienteExiste = false;

  String numeroDaLicencaSelecionada = '';
  String numeroUsuario = '';
  String nomeDoGarcom = '';
  String nomeDoGarcomSelecionado = '';
  bool nomeDoGarcomDoLoad = false;
  bool garcomSelecionado = false;
  String numeroDoGarcom = '';

  bool cliqueiRecepcao = false;
  bool isProcessing = false;

  String numeroPedido = "";

  final MaskTextInputFormatter _maskFormatterTelefone = MaskTextInputFormatter(
    mask: '(##)#####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // A máscara permite 10 ou 11 dígitos para o número (com DDD)
  final _maskFormatter = MaskTextInputFormatter(
    mask: '(##)#####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  String get telefoneEmpresaMascara {
    if (telefoneEmpresa.isEmpty) return '(  )';
    return '($telefoneEmpresa)';
  }

  Timer? _timerApagar;

  Future<void> reiniciarPagina() async {
    nomeController.clear();
    numeroController.clear();
    numeroControllerTelefone.clear();
    cpfControllerNoCpf.clear();
    cpfControllerNoTelefone.clear();
    dataNascimentoController.clear();
    comandaController.clear();
    adicionalController.clear();

    // Libera o foco de forma unificada e segura para evitar bug de teclado
    FocusScope.of(context).unfocus();

    setState(() {
      checkIn = true;
      checkout = false;

      mostrarTodas = true;
      mostrarAbertas = false;
      mostrarFechadas = false;

      sexoSelecionado = null;
      radioPreenchido = false;

      cpfValido = false;
      telefoneValido = false;
      telefoneValidoTel = false;
      cpfValidoNumero = false;
      inserirComanda = false;
      vazioCpf = true;
      vazioTelefone = true;
      dataCorreta = false;
      nomeValido = false;

      corBorda = true;
      corAlerta = true;
      corComanda = false;
      
      mensagem = '';
      mensagem2 = '';

      isLoading = false;
      isLoading2 = false;
      isProcessing = false;
      cliqueiRecepcao = false;
      desaparecerTema = false;

      adicionais.clear();

      botaoCpf = true;
      botaotelefone = false;
      _showKeyboardNome = true;
      _showKeyboardMaior = false;
      mostrarBotoes = true;

      // Limpar formatações
      _maskFormatter.clear();
      _maskFormatterTelefone.clear();

      // Limpando variáveis de estado residuais
      numeroDoPedido = '';
      valorTotalLiquido = '';
      statusPedido = '';
      numeroDoProduto = 0;
      comandaNumero = '';
      comandaRegistrada = false;
      icone = false;
      _campoAtivo = '';
      tecladoAlfa = false;
      numeroCliente = '';
      numeroClienteInt = 0;
      telefoneCliente = '';
      cpfCliente = '';
      sexoCliente = '';
      datanascimentoCliente = '';
      nomeCliente = '';
      retornoCpf = false;
      retornoNumero = false;
      couvert = 0;
      textoComanda = '';
      comanda = '';
      precisoCadastrarCliente = false;
      comandaFoiValidada = false;
      comandaValida = false;
      clienteExiste = false;
      numeroPedido = "";
    });

    //setState(() {});

    // Get.toNamed('/recepcao');

    // Garante que o guard esteja limpo antes de solicitar foco
    _focusPendente = false;
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _solicitarFoco(cpfnoCpfFocusNode, 'cpfCpf');
    });
  }

  /* Future<void> reiniciarPagina() async {
    await Future.delayed(Duration(milliseconds: 300), () {
      if (cpfnoCpfFocusNode.canRequestFocus) {
        cpfnoCpfFocusNode.requestFocus();
      }
    });
    setState(() {
      nomeController.clear();
      numeroController.clear();
      numeroControllerTelefone.clear();
      cpfControllerNoCpf.clear();
      cpfControllerNoTelefone.clear();
      dataNascimentoController.clear();
      comandaController.clear();
      adicionalController.clear();
      _showKeyboardNome = true;
      mostrarBotoes = true;
      isLoading2 = false;
      isProcessing = false;
      cliqueiRecepcao = false;
      desaparecerTema = false;
    });
  } */

  // Salvar nomeEmpresa
  Future<void> _saveNomeEmpresa(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nomeEmpresa', value);
    } catch (e, st) {
      debugPrint("Erro _saveNomeEmpresa(): $e\n$st");
    }
  }

  // Load nomeEmpresa do cache local
  Future<void> _loadNomeEmpresa() async {
    final prefs = await SharedPreferences.getInstance();
    final nomeEmpresaSalvo = prefs.getString('nomeEmpresa');
    if (nomeEmpresaSalvo != null) {
      setState(() {
        nomeEmpresa = nomeEmpresaSalvo;
        nomeEmpresaLoad = nomeEmpresaSalvo;
      });
    }
  }

  Future<void> carregarNomeEmpresa() async {
    await _loadNomeEmpresa();

    try {
      final dadosJson = await Connection().select(
        "SELECT nomefantasia, telefone FROM empresa WHERE numero='1' LIMIT 1",
      );

      if (dadosJson == "[]" || dadosJson.isEmpty) {
        setState(() {
          nomeEmpresa = "Sem nome";
          telefoneEmpresa = '';
        });
        return;
      }

      final lista = jsonDecode(dadosJson) as List<dynamic>;

      if (lista.isEmpty) {
        setState(() {
          nomeEmpresa = "Sem conexão";
          telefoneEmpresa = '';
        });
        return;
      }

      setState(() {
        nomeEmpresa = lista[0]['nomefantasia'].toString();

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
      });

      _saveNomeEmpresa(nomeEmpresa);
    } catch (e, st) {
      setState(() {
        nomeEmpresa = nomeEmpresaLoad;
        telefoneEmpresa = '';
      });
    }
  }

  // Função para pegar numero da base quando cliente não existir
  Future<void> encontrarNumeroClientePeloTelefone(String telefone) async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero FROM clientes WHERE telefone='$telefone'",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        String valor = lista[0]['numero'].toString();

        setState(() {
          numeroCliente = valor;
          numeroClienteInt = int.parse(valor);
        });
        print("Número do cliente: $numeroCliente");
      } else {
        numeroCliente = '0';
        numeroClienteInt = 0;
      }
    } catch (e) {
      numeroCliente = '0';
      numeroClienteInt = 0;
    }
  }
  /* // Função para pegar numero da base quando cliente não existir
  Future<void> encontrarNumeroClientePeloTelefone(String telefone) async {
    try {
      String jsonResult = await Connection().select(
        "SELECT numero FROM clientes WHERE telefone='$telefone' LIMIT 1",
      );

      final resultadoProcessado = await Isolate.run(() {
        final List<dynamic> lista = jsonDecode(jsonResult);

        if (lista.isNotEmpty) {
          String valor = lista[0]['numero'].toString();
          int numeroInt = int.tryParse(valor) ?? 0;

          return {'numero': valor, 'numeroInt': numeroInt};
        } else {
          return {'numero': '0', 'numeroInt': 0};
        }
      });

      setState(() {
        numeroCliente = resultadoProcessado['numero'] as String;
        numeroClienteInt = resultadoProcessado['numeroInt'] as int;
      });
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
      setState(() {
        numeroCliente = '0';
        numeroClienteInt = 0;
      });
    }
  } */

  // Função para pegar numero da base quando cliente não existir
  Future<void> encontrarNumeroClientePeloCpf(String cpf) async {
    try {
      String jsonResult = await Connection().select(
        "SELECT numero FROM clientes WHERE cpf='$cpf' LIMIT 1",
      );

      List<dynamic> lista = jsonDecode(jsonResult);

      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        String valor = lista[0]['numero'].toString();

        setState(() {
          numeroCliente = valor;
          numeroClienteInt = int.parse(valor);
        });
        print("Número do cliente: $numeroCliente");
      } else {
        numeroCliente = '0';
        numeroClienteInt = 0;
      }
    } catch (e) {
      numeroCliente = '0';
      numeroClienteInt = 0;
    }
  }

  // Função para buscar cliente por cpf
  Future<void> buscarPorCpf(String cpf) async {
    try {
      // Permite a UI renderizar antes do processo pesado
      await Future.delayed(Duration.zero);

      String jsonResult = await Connection().select(
        "SELECT nome, numero, telefone, cpf, sexo, datanascimento FROM clientes WHERE cpf='$cpf' LIMIT 1",
      );

      // Decode fora do setState
      final List<dynamic> lista = jsonDecode(jsonResult);

      if (lista.isNotEmpty) {
        final item = lista[0];

        String valor = item['numero']?.toString() ?? '0';
        String valor2 = item['telefone']?.toString() ?? '0';
        String valor3 = item['cpf']?.toString() ?? '0';
        String valor4 = item['sexo']?.toString() ?? 'NI';
        String valor5 = item['datanascimento']?.toString() ?? '';
        String valor6 = item['nome']?.toString() ?? '';

        // Formatação de data FORA do setState
        String dataFormatada = '';
        if (valor5.isNotEmpty && valor5 != 'null') {
          try {
            DateTime data = DateTime.parse(valor5);
            dataFormatada = '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
          } catch (_) {
            dataFormatada = '';
          }
        }

        setState(() {
          precisoCadastrarCliente = false;
          numeroCliente = valor;
          telefoneCliente = valor2;
          cpfCliente = valor3;
          sexoCliente = valor4;
          datanascimentoCliente = dataFormatada;
          dataCorreta = true;
          nomeCliente = valor6;
          retornoCpf = true;
        });

        execucaoretornoCpf(); // fora do setState melhora performance
      } else {
        setState(() {
          precisoCadastrarCliente = true;
          numeroCliente = '0';
          telefoneCliente = '0';
          cpfCliente = '0';
          sexoCliente = 'NI';
          datanascimentoCliente = '0';
          nomeCliente = '';
        });
      }
    } catch (e) {
      setState(() {
        precisoCadastrarCliente = true;
        numeroCliente = '0';
        telefoneCliente = '0';
        cpfCliente = '0';
        sexoCliente = 'NI';
        datanascimentoCliente = '0';
        nomeCliente = '';
      });
    }
  }

  // // Função para buscar cliente por cpf
  // Future<void> buscarPorCpf(String cpf) async {
  //   try {
  //     String jsonResult = await Connection().select(
  //       "SELECT nome, numero, telefone, cpf, sexo, datanascimento FROM clientes WHERE cpf='$cpf' LIMIT 1",
  //     );

  //     final List<dynamic> lista = jsonDecode(jsonResult);

  //     if (lista.isNotEmpty) {
  //       // pega apenas o campo resultado
  //       String valor = lista[0]['numero'].toString();
  //       String valor2 = lista[0]['telefone'].toString();
  //       String valor3 = lista[0]['cpf'].toString();
  //       String valor4 = lista[0]['sexo'].toString();
  //       String valor5 = lista[0]['datanascimento'].toString();
  //       String valor6 = lista[0]['nome'].toString();

  //       //Formatação de data
  //       String dataFormatada = '';
  //       try {
  //         if (valor5.isNotEmpty && valor5 != 'null') {
  //           DateTime data = DateTime.parse(valor5);
  //           dataFormatada = '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  //         }
  //       } catch (e) {
  //         dataFormatada = '';
  //       }
  //       setState(() {
  //         precisoCadastrarCliente = false;
  //         numeroCliente = valor;
  //         telefoneCliente = valor2;
  //         cpfCliente = valor3;
  //         sexoCliente = valor4;
  //         datanascimentoCliente = dataFormatada;
  //         dataCorreta = true;
  //         nomeCliente = valor6;
  //         retornoCpf = true;
  //         execucaoretornoCpf();
  //       });
  //     } else {
  //       setState(() {
  //         precisoCadastrarCliente = true;
  //         numeroCliente = '0';
  //         telefoneCliente = '0';
  //         cpfCliente = '0';
  //         sexoCliente = 'NI';
  //         datanascimentoCliente = '0';
  //         nomeCliente = '';
  //         // if(botaoCpf){
  //         //   encontrarNumeroClientePeloCpf(cpf);
  //         // } else if (botaotelefone){
  //         //   encontrarNumeroClientePeloTelefone(numeroControllerTelefone.text);
  //         // }

  //       });
  //     }
  //   } catch (e) {
  //     print("Erro ao carregar configuracaoServico: $e");
  //     setState(() {
  //       precisoCadastrarCliente = true;
  //       numeroCliente = '0';
  //       telefoneCliente = '0';
  //       cpfCliente = '0';
  //       sexoCliente = 'NI';
  //       datanascimentoCliente = '0';
  //       nomeCliente = '';
  //     });
  //   }
  // }

  // Listener do nomeFocusNode — fora do initState para facilitar remoção no dispose
  void _onNomeFocusChange() {
    if (!mounted) return;
    final hora = DateTime.now();
    if (!nomeFocusNode.hasFocus && !_focusPendente) {
      if (mounted) {
        setState(() {
          mostrarBotoes = true;
        });
      }
    }
  }

  // ── Helper centralizado de requestFocus com guard anti-concorrência ───────
  void _solicitarFoco(FocusNode destino, String nomeCampo) {
    if (!mounted) return;
    // Reseta o guard imediatamente para não bloquear chamadas subsequentes
    _focusPendente = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _focusPendente = false;
        return;
      }
      if (destino.canRequestFocus) {
        FocusScope.of(context).requestFocus(destino);
        debugPrint('[FOCO] ${DateTime.now().toIso8601String()} → $nomeCampo (primaryFocus antes: ${FocusManager.instance.primaryFocus?.debugLabel})');
      }
      Future.delayed(const Duration(milliseconds: 150), () {
        _focusPendente = false;
      });
    });
  }
  // ──────────────────────────────────────────────────────────────────────────

  void execucaoretornoNumero() {
    final hora = DateTime.now().toIso8601String();

    clienteExiste = true;

    // Formata o sexo ANTES do setState
    String sexoSelecionadoFomatado = listaSexo[2];

    if (sexoCliente == "FEMININO") {
      sexoSelecionadoFomatado = listaSexo[1];
    } else if (sexoCliente == "MASCULINO") {
      sexoSelecionadoFomatado = listaSexo[0];
    }

    final String telefoneClienteForm = telefoneCliente;

    // Um único setState agrupando TODAS as mudanças
    setState(() {
      _campoAtivo = 'comanda';

      _showKeyboardNome = true;
      _showKeyboardMaior = false;

      desaparecerTema = true;
      dataCorreta = true;
      mostrarBotoes = true;

      nomeController.text = nomeCliente;

      cpfControllerNoCpf.text = cpfCliente;
      cpfControllerNoTelefone.text = cpfCliente;

      dataNascimentoController.text = datanascimentoCliente;

      sexoSelecionado = sexoSelecionadoFomatado;

      radioPreenchido = true;
      inserirComanda = true;

      numeroClienteInt = int.tryParse(numeroCliente) ?? 0;

      numeroControllerTelefone.text = telefoneClienteForm;
    });

    // Solicita foco FORA do setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;

        _solicitarFoco(comandaFocusNode, 'comanda');
      });
    });

    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;

      _scrollToField(comandaFocusNode);
    });
  }

  /* void execucaoretornoNumero() {
    final hora = DateTime.now().toIso8601String();
    debugPrint('[NUMERO→COMANDA] $hora execucaoretornoNumero iniciado');

    clienteExiste = true;

    String sexoSelecionadoFomatado = listaSexo[2];

    if (sexoCliente == "FEMININO") {
      sexoSelecionadoFomatado = listaSexo[1];
    } else if (sexoCliente == "MASCULINO") {
      sexoSelecionadoFomatado = listaSexo[0];
    }

    setState(() {
      _campoAtivo = 'comanda';
      _showKeyboardNome = true;
      _showKeyboardMaior = false;
      desaparecerTema = true;
      dataCorreta = true;
      mostrarBotoes = true;

      nomeController.text = nomeCliente;

      cpfControllerNoCpf.text = cpfCliente;
      cpfControllerNoTelefone.text = cpfCliente;

      dataNascimentoController.text = datanascimentoCliente;

      sexoSelecionado = sexoSelecionadoFomatado;

      radioPreenchido = true;
      inserirComanda = true;

      numeroClienteInt = int.tryParse(numeroCliente) ?? 0;

      numeroControllerTelefone.text = telefoneCliente;
    });

    debugPrint(
      '[TECLADO] ${DateTime.now().toIso8601String()} execucaoretornoNumero → solicitando foco: comanda',
    );

    _solicitarFoco(comandaFocusNode, 'comanda');

    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;

      if (comandaFocusNode.hasFocus) {
        _scrollToField(comandaFocusNode);
      }
    });

    debugPrint(
      '[NUMERO→COMANDA] ${DateTime.now().toIso8601String()} execucaoretornoNumero concluído',
    );
  } */

  // Função executada após cpf existir
  void execucaoretornoCpf() {
    final hora = DateTime.now().toIso8601String();
    debugPrint('[CPF→COMANDA] $hora execucaoretornoCpf iniciado');
    clienteExiste = true;

    // Formata o sexo ANTES do setState
    String sexoSelecionadoFomatado = listaSexo[2];
    if (sexoCliente == "FEMININO") {
      sexoSelecionadoFomatado = listaSexo[1];
    } else if (sexoCliente == "MASCULINO") {
      sexoSelecionadoFomatado = listaSexo[0];
    }

    final String telefoneClienteForm = telefoneCliente;

    // ── Prepara valores de telefone FORA do setState (evita setState aninhado) ──
    final rawValue = telefoneEmpresa;
    final onlyDigits = rawValue.replaceAll(RegExp(r'\D'), '');
    final valorParaMascara = onlyDigits.isEmpty ? telefoneEmpresa : onlyDigits;
    String maskedText = _maskFormatter.maskText(valorParaMascara);
    if (maskedText == '($telefoneEmpresa') maskedText = '($telefoneEmpresa)';
    // ──────────────────────────────────────────────────────────────────────────

    debugPrint('[TECLADO] ${DateTime.now().toIso8601String()} execucaoretornoCpf → setState único agrupado');

    // Um único setState agrupando TODAS as mudanças de estado
    setState(() {
      // Inicializa telefone diretamente — sem chamar método com Future.delayed
      numeroController.text = maskedText;

      _campoAtivo = 'comanda';
      _showKeyboardNome = true;
      _showKeyboardMaior = false;
      desaparecerTema = true;
      dataCorreta = true;
      mostrarBotoes = true;
      nomeController.text = nomeCliente;
      cpfControllerNoCpf.text = cpfCliente;
      cpfControllerNoTelefone.text = cpfCliente;
      dataNascimentoController.text = datanascimentoCliente;
      sexoSelecionado = sexoSelecionadoFomatado;
      radioPreenchido = true;
      inserirComanda = true;
      numeroClienteInt = int.tryParse(numeroCliente) ?? 0;
      numeroControllerTelefone.text = telefoneClienteForm;
    });

    debugPrint('[TECLADO] ${DateTime.now().toIso8601String()} execucaoretornoCpf → solicitando foco: comanda');

    // requestFocus centralizado FORA do setState — via guard anti-concorrência
    _solicitarFoco(comandaFocusNode, 'comanda');
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _scrollToField(comandaFocusNode);
    });

    debugPrint('[CPF→COMANDA] ${DateTime.now().toIso8601String()} execucaoretornoCpf concluído');
  }

  // Função para buscar cliente por Numero
  Future<void> buscarPorNumero(String telefone) async {
    try {
      // Dá um respiro para a UI antes do processamento pesado
      await Future.delayed(Duration.zero);

      String jsonResult = await Connection().select(
        "SELECT nome, numero, telefone, cpf, sexo, datanascimento FROM clientes WHERE (telefone='$telefone' OR telefone2='$telefone') LIMIT 1",
      );

      if (!mounted) return;

      // Decode fora do setState
      final List<dynamic> lista = jsonDecode(jsonResult);

      if (lista.isNotEmpty) {
        final item = lista[0];

        String valor = item['numero']?.toString() ?? '0';
        String valor2 = item['telefone']?.toString() ?? '0';
        String valor3 = item['cpf']?.toString() ?? '0';
        String valor4 = item['sexo']?.toString() ?? 'NI';
        String valor5 = item['datanascimento']?.toString() ?? '';
        String valor6 = item['nome']?.toString() ?? '';

        // Formatação de data FORA do setState
        String dataFormatada = '';
        if (valor5.isNotEmpty && valor5 != 'null') {
          try {
            DateTime data = DateTime.parse(valor5);
            dataFormatada =
                '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
          } catch (_) {
            dataFormatada = '';
          }
        }

        if (!mounted) return;
        setState(() {
          nomeCliente = valor6;
          numeroCliente = valor;
          telefoneCliente = valor2;
          cpfCliente = valor3;
          sexoCliente = valor4;
          datanascimentoCliente = dataFormatada;
          retornoNumero = true;
          precisoCadastrarCliente = false;
        });

        // Executa fora do setState para evitar rebuild pesado
        if (botaoCpf) {
          execucaoretornoCpf();
        } else {
          execucaoretornoNumero();
        }
      } else {
        if (!mounted) return;
        setState(() {
          precisoCadastrarCliente = true;
          numeroCliente = '0';
          telefoneCliente = '0';
          cpfCliente = '0';
          sexoCliente = 'NI';
          datanascimentoCliente = '0';
        });
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
      if (!mounted) return;
      setState(() {
        precisoCadastrarCliente = true;
        numeroCliente = '0';
        telefoneCliente = '0';
        cpfCliente = '0';
        sexoCliente = 'NI';
        datanascimentoCliente = '0';
      });
    }
  }
  // Future<void> buscarPorNumero(String telefone) async {
  //   try {
  //     String jsonResult = await Connection().select(
  //       "SELECT nome, numero, telefone, cpf, sexo, datanascimento FROM clientes WHERE (telefone='$telefone' OR telefone2='$telefone') LIMIT 1",
  //     );

  //     if (!mounted) return;

  //     List<dynamic> lista = jsonDecode(jsonResult);

  //     if (lista.isNotEmpty) {
  //       // pega apenas o campo resultado
  //       String valor = lista[0]['numero'].toString();
  //       String valor2 = lista[0]['telefone'].toString();
  //       String valor3 = lista[0]['cpf'].toString();
  //       String valor4 = lista[0]['sexo'].toString();
  //       String valor5 = lista[0]['datanascimento'].toString();
  //       String valor6 = lista[0]['nome'].toString();

  //       // Formatação de data
  //       String dataFormatada = '';
  //       try {
  //         if (valor5.isNotEmpty && valor5 != 'null') {
  //           DateTime data = DateTime.parse(valor5);
  //           dataFormatada =
  //               '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  //         }
  //       } catch (e) {
  //         dataFormatada = '';
  //       }
  //       if (!mounted) return;
  //       setState(() {
  //         nomeCliente = valor6;
  //         numeroCliente = valor;
  //         telefoneCliente = valor2;
  //         cpfCliente = valor3;
  //         sexoCliente = valor4;
  //         datanascimentoCliente = dataFormatada;
  //         retornoNumero = true;
  //         precisoCadastrarCliente = false;
  //         execucaoretornoCpf();
  //       });
  //     } else {
  //       if (!mounted) return;
  //       setState(() {
  //         precisoCadastrarCliente = true;
  //         numeroCliente = '0';
  //         telefoneCliente = '0';
  //         cpfCliente = '0';
  //         sexoCliente = 'NI';
  //         datanascimentoCliente = '0';
  //       });
  //     }
  //   } catch (e) {
  //     print("Erro ao carregar configuracaoServico: $e");
  //     if (!mounted) return;
  //     setState(() {
  //       precisoCadastrarCliente = true;
  //       numeroCliente = '0';
  //       telefoneCliente = '0';
  //       cpfCliente = '0';
  //       sexoCliente = 'NI';
  //       datanascimentoCliente = '0';
  //     });
  //   }
  // }

  // Para limpar o que chega
  void limparValores() {
    numeroCliente = '';
    telefoneCliente = '';
    cpfCliente = '';
    sexoCliente = '';
    datanascimentoCliente = '';
  }

  // Função para obter a lista
  Future<List<Map<String, dynamic>>> listaAdicionais() async {
    String dadosJson = await Connection().select(
      "SELECT numero, nome FROM produtos WHERE ativo='1' AND tipoAdicional != '2' AND tipoAdicional != '3' AND id='A' ORDER BY nome",
    );

    if (dadosJson == '[]') {
      print("Sem lista de adicionais.");

      adicionais = [
        {'numero': '', 'nome': ' '},
      ];
      return adicionais;
    }

    try {
      final List decodedList = jsonDecode(dadosJson);
      adicionais = decodedList
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      adicionais.insert(0, {'numero': '', 'nome': ' '});

      return adicionais;
    } catch (e, stack) {
      print("Erro ao decodificar JSON: $e");
      print(stack);

      adicionais = [
        {'numero': '', 'nome': ' '},
      ];
      return adicionais;
    }
  }

  // FUNÇÃO PARA ADICONAR NUMERO
  void _adicionarNumero(String valor) {
    HapticFeedback.lightImpact();
    /* setState(() {
      switch (_campoAtivo) {
        case 'nome':
          _inserirTexto(nomeController, valor, validarNome);
          break;

        // case 'numero':
        //   _inserirTextoComFormatter(
        //     numeroController,
        //     valor,
        //     _maskFormatter,
        //     validarTelefoneNoCPF,
        //   );
        //   break;

        case 'numero':
          // LÓGICA ESPECÍFICA DO TELEFONE
          final controller = numeroController;

          // 1. Limpa o valor atual
          final oldDigits = controller.text.replaceAll(RegExp(r'\D'), '');

          // 2. Concatena o novo dígito
          final newDigits = oldDigits + valor;

          // 3. Aplica a máscara e gera o texto
          final maskedText = _maskFormatter.maskText(newDigits);

          // 4. Define o novo valor e a SELEÇÃO no final
          controller.value = TextEditingValue(
            text: maskedText,
            selection: TextSelection.collapsed(offset: maskedText.length),
          );

          // 5. Validação e Salva o valor limpo
          validarTelefoneNoCPF(controller.text);
          // Atualize variaveis.telefoneEmpresa() aqui se necessário.
          break;

        // case 'numeroTelefone':
        //   _inserirTextoComFormatter(
        //     numeroControllerTelefone,
        //     valor,
        //     _maskFormatterTelefone,
        //     validarTelefoneNoNumero,
        //   );
        //   break;
        case 'numeroTelefone':
          // LÓGICA ESPECÍFICA DO TELEFONE
          final controller = numeroControllerTelefone;

          // 1. Limpa o valor atual
          final oldDigits = controller.text.replaceAll(RegExp(r'\D'), '');

          // 2. Concatena o novo dígito
          final newDigits = oldDigits + valor;

          // 3. Aplica a máscara e gera o texto
          final maskedText = _maskFormatterTelefone.maskText(newDigits);

          // 4. Define o novo valor e a SELEÇÃO no final
          controller.value = TextEditingValue(
            text: maskedText,
            selection: TextSelection.collapsed(offset: maskedText.length),
          );

          // 5. Validação e Salva o valor limpo
          validarTelefoneNoNumero(controller.text);
          // Atualize variaveis.telefoneEmpresa() aqui se necessário.

          break;

        case 'cpfTelefone':
          _inserirTexto(cpfControllerNoTelefone, valor, validarCPFnoNumero);
          break;

        case 'cpfCpf':
          _inserirTexto(cpfControllerNoCpf, valor, validarCPFnoCpf);
          break;

        case 'nascimento':
          _inserirTextoComFormatter(
            dataNascimentoController,
            valor,
            DateInputFormatter(),
            validarNascimento,
          );
          break;

        case 'comanda':
          _inserirTexto(comandaController, valor, null);
          break;

        case 'adicional':
          _inserirTexto(adicionalController, valor, null);
          break;
      }
    }); */
  }

  // FUNÇÃO PARA APAGAR NUMERO
  void _apagarNumero() {
    HapticFeedback.lightImpact();
    /* setState(() {
      switch (_campoAtivo) {
        case 'nome':
          _removerUltimoCaractere(nomeController, validarNome);
          break;

        case 'numero':
          final controller = numeroController;

          // Limpa o valor atual
          final oldDigits = controller.text.replaceAll(RegExp(r'\D'), '');

          // Remove o último dígito APENAS se houver algo para remover
          if (oldDigits.isNotEmpty) {
            final newDigits = oldDigits.substring(0, oldDigits.length - 1);

            // Aplica a máscara ao novo conjunto de dígitos
            final maskedText = _maskFormatter.maskText(newDigits);

            // Define o novo valor e o cursor no final
            controller.value = TextEditingValue(
              text: maskedText,
              selection: TextSelection.collapsed(offset: maskedText.length),
            );

            // Validação e Salva o valor limpo
            validarTelefoneNoCPF(controller.text);
          }
          break;

        case 'numeroTelefone':
          final controller = numeroControllerTelefone;

          // Limpa o valor atual
          final oldDigits = controller.text.replaceAll(RegExp(r'\D'), '');

          // Remove o último dígito APENAS se houver algo para remover
          if (oldDigits.isNotEmpty) {
            final newDigits = oldDigits.substring(0, oldDigits.length - 1);

            // Aplica a máscara ao novo conjunto de dígitos
            final maskedText = _maskFormatterTelefone.maskText(newDigits);

            // Define o novo valor e o cursor no final
            controller.value = TextEditingValue(
              text: maskedText,
              selection: TextSelection.collapsed(offset: maskedText.length),
            );

            // Validação e Salva o valor limpo
            validarTelefoneNoNumero(controller.text);
          }
          break;

        case 'cpfCpf':
          _removerUltimoCaractere(cpfControllerNoCpf, validarCPFnoCpf);
          break;

        case 'cpfTelefone':
          _removerUltimoCaractere(cpfControllerNoTelefone, validarCPFnoNumero);
          break;

        case 'nascimento':
          _removerUltimoCaractereComFormatter(
            dataNascimentoController,
            DateInputFormatter(),
            validarNascimento,
          );
          break;

        case 'comanda':
          _removerUltimoCaractere(comandaController, null);
          break;

        case 'adicional':
          _removerUltimoCaractere(adicionalController, null);
          break;
      }
    }); */
  }

  void _apagarNumeroVarios() {
   /*  setState(() {
      switch (_campoAtivo) {
        case 'nome':
          _removerVariosCaractere(nomeController, validarNome);
          break;

        case 'numero':
          _removerVariosCaractereComFormatter(
            numeroController,
            _maskFormatter,
            validarTelefoneNoCPF,
          );
          break;

        case 'numeroTelefone':
          _removerVariosCaractereComFormatter(
            numeroControllerTelefone,
            _maskFormatterTelefone,
            validarTelefoneNoNumero,
          );
          break;

        case 'cpfCpf':
          _removerVariosCaractere(cpfControllerNoCpf, validarCPFnoCpf);
          break;

        case 'cpfTelefone':
          _removerVariosCaractere(cpfControllerNoTelefone, validarCPFnoNumero);
          break;

        case 'nascimento':
          _removerVariosCaractereComFormatter(
            dataNascimentoController,
            DateInputFormatter(),
            validarNascimento,
          );
          break;

        case 'comanda':
          _removerVariosCaractere(comandaController, null);
          break;

        case 'adicional':
          _removerVariosCaractere(adicionalController, null);
          break;
      }
    }); */
  }

  void _iniciarApagar() {
    // Inicia o Timer para apagar repetidamente enquanto o botão estiver pressionado
    _timerApagar = Timer.periodic(Duration(milliseconds: 300), (_) {
      _apagarNumeroVarios();
    });
  }

  void _pararApagar() {
    // Para o Timer quando o botão for solto
    _timerApagar?.cancel();
  }

  // Funções auxíliares para formatação
  void _inserirTexto(
    TextEditingController controller,
    String valor,
    Function(String)? validador,
  ) {
    HapticFeedback.lightImpact();
    final oldValue = controller.value;
    final newString = oldValue.text + valor;
    final newValue = TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
    controller.value = newValue;
    if (validador != null) validador(controller.text);
  }

  void _inserirTextoComFormatter(
    TextEditingController controller,
    String valor,
    TextInputFormatter formatter,
    Function(String)? validador,
  ) {
    HapticFeedback.lightImpact();
    final oldValue = controller.value;
    final newString = oldValue.text + valor;
    final newValue = TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );

    // Aplica o formatter como se o usuário tivesse digitado
    final formattedValue = formatter.formatEditUpdate(oldValue, newValue);
    controller.value = formattedValue.copyWith(
      selection: TextSelection.collapsed(offset: formattedValue.text.length),
    );

    if (validador != null) validador(controller.text);
  }

  // Remove apenas último caractere
  void _removerUltimoCaractere(
    TextEditingController controller,
    Function(String)? validador,
  ) {
    if (controller.text.isEmpty) return;
    final newText = controller.text.substring(0, controller.text.length - 1);
    
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
    
    if (validador != null) validador(newText);
  }

  // Remove vários caracteres
  void _removerVariosCaractere(
    TextEditingController controller,
    Function(String)? validador,
  ) {
    // Verifica se o texto está vazio
    if (controller.text.isEmpty) return;

    // Determina o número de caracteres a remover (no máximo 3, mas não mais que o tamanho do texto)
    int numCaracteresRemover = controller.text.length <= 3 ? 2 : 3;

    // Garante que não tentaremos remover mais caracteres do que o texto permite
    numCaracteresRemover = numCaracteresRemover > controller.text.length
        ? controller.text.length
        : numCaracteresRemover;

    // Cria o novo texto com a remoção dos caracteres
    final newText = controller.text.substring(
      0,
      controller.text.length - numCaracteresRemover,
    );

    // Atualiza o texto no controlador mantendo cursor no final
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );

    // Se a função validadora for fornecida, chamamos ela com o novo texto
    if (validador != null) validador(newText);
  }

  // Remove último caractere com formatação
  void _removerUltimoCaractereComFormatter(
    TextEditingController controller,
    TextInputFormatter formatter,
    Function(String)? validador,
  ) {
    if (controller.text.isEmpty) return;

    final oldValue = controller.value;
    final newValue = TextEditingValue(
      text: oldValue.text.substring(0, oldValue.text.length - 1),
      selection: TextSelection.collapsed(offset: oldValue.text.length - 1),
    );

    final formattedValue = formatter.formatEditUpdate(oldValue, newValue);
    controller.value = formattedValue.copyWith(
      selection: TextSelection.collapsed(offset: formattedValue.text.length),
    );

    if (validador != null) validador(controller.text);
  }

  // Remove vários caractere com formatação
  void _removerVariosCaractereComFormatter(
    TextEditingController controller,
    TextInputFormatter formatter,
    Function(String)? validador,
  ) {
    if (controller.text.isEmpty) return;

    final oldValue = controller.value;
    final newValue = TextEditingValue(
      text: oldValue.text.substring(0, oldValue.text.length - 3),
      selection: TextSelection.collapsed(offset: oldValue.text.length - 3),
    );

    final formattedValue = formatter.formatEditUpdate(oldValue, newValue);
    controller.value = formattedValue.copyWith(
      selection: TextSelection.collapsed(offset: formattedValue.text.length),
    );

    if (validador != null) validador(controller.text);
  }

  // Função para apagar no teclado alfanumérico
  _apagarNoTecladoAlfa() {
    HapticFeedback.lightImpact();
    if (nomeController.text.isEmpty) return;
    final newText = nomeController.text.substring(
      0,
      nomeController.text.length - 1,
    );
    nomeController.text = newText;
  }

  _apagarVariosNoTecladoAlfa() {
    HapticFeedback.lightImpact();
    final texto = nomeController.text;

    if (texto.isEmpty) return;

    int tamanhoAtual = texto.length;

    // Decide quantos caracteres remover
    int numCaracteresRemover = tamanhoAtual <= 3 ? 2 : 3;

    // GARANTIA: nunca deixar índice negativo
    int novoTamanho = tamanhoAtual - numCaracteresRemover;

    if (novoTamanho <= 0) {
      nomeController.clear();
      return;
    }

    nomeController.text = texto.substring(0, novoTamanho);

    // Mantém o cursor no final
    nomeController.selection = TextSelection.fromPosition(
      TextPosition(offset: nomeController.text.length),
    );
  }

  // Função para apagar vários no teclado Alfa
  _iniciarApagarNoTecladoAlfa() {
    _timerApagar = Timer.periodic(Duration(milliseconds: 300), (_) {
      _apagarVariosNoTecladoAlfa();
      // if(nomeController.text.isEmpty){
      //   _pararApagarNoTecladoAlfa();
      // }
    });
  }

  // Função para parar de apagar Alfa
  _pararApagarNoTecladoAlfa() {
    _timerApagar?.cancel();
  }

  // Função para adicionar tecla no teclado Alfa
  _adicionarTeclaNoTecladoAlfa(tecla) {
    HapticFeedback.lightImpact();
    final oldValue = nomeController.value;
    final newValue = TextEditingValue(
      text: oldValue.text + tecla,
      selection: TextSelection.collapsed(offset: oldValue.text.length + 1),
    );
    nomeController.value = newValue;
  }

  // Função para confirmar numero da comanda
  void _confirmar() {
    HapticFeedback.lightImpact();
    // unfocus FORA do setState para evitar rebuild que re-solicita foco
    FocusScope.of(context).unfocus();
    setState(() {
      _showKeyboardNome = false;
    });
  }

  // Função para fechar teclado no teclado Alfanumérico
  void _fecharTecladoNoTecladoAlfa() {
    // unfocus FORA do setState para evitar rebuild que re-solicita foco
    FocusScope.of(context).unfocus();
    setState(() {
      _showKeyboardMaior = false;
    });
  }

  // Função para o check do teclado alfanumérico
  void _confirmarNoTecladoAlfa() {
    final hora = DateTime.now().toIso8601String();
    debugPrint('[TECLADO-ALFA] $hora _confirmarNoTecladoAlfa → botaoCpf=$botaoCpf | botaotelefone=$botaotelefone');

    if (botaoCpf) {
      // Atualiza estado — SEM requestFocus dentro do setState
      setState(() {
        _showKeyboardNome = true;
        _campoAtivo = 'numero';
        _showKeyboardMaior = false;
      });
      // requestFocus fora do setState, via guard anti-concorrência
      _solicitarFoco(numeroFocusNode, 'numero');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _scrollToField(numeroFocusNode);
      });
    } else if (botaotelefone) {
      // Atualiza estado — SEM requestFocus dentro do setState
      setState(() {
        _showKeyboardNome = true;
        _campoAtivo = 'cpfTelefone';
        _showKeyboardMaior = false;
      });
      // requestFocus fora do setState, via guard anti-concorrência
      _solicitarFoco(cpfnoTelefoneFocusNode, 'cpfTelefone');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _scrollToField(cpfnoTelefoneFocusNode);
      });
    }
  }

  // Função para pegar data e hora atuais para jogar no abrirCliente
  String obterDataHoraMysql() {
    final now = DateTime.now();
    String doisDigitos(int n) => n.toString().padLeft(2, '0');
    return "${now.year}-"
        "${doisDigitos(now.month)}-"
        "${doisDigitos(now.day)} "
        "${doisDigitos(now.hour)}:"
        "${doisDigitos(now.minute)}:"
        "${doisDigitos(now.second)}";
  }

  @override
  void initState() {
    super.initState();
    _atualizarHora();

    painelController.estaNoPainelCozinha.value = false;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _atualizarHora();
    });

    limparCampos();
    _carregarModo();
    listaAdicionais();
    carregarCidadeUf();
    carregarNomeEmpresa();
    _loadNumeroLicenca();
    _loadGarcom();
    _getNumeroGarcom();
    nomeFocusNode.addListener(_onNomeFocusChange);
  }

  Future<void> _getNumeroGarcom() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      numeroDoGarcom = prefs.getString('numeroGarcom') ?? '';
    } catch (e, st) {
      debugPrint("Erro _getNumeroGarcom(): $e\n$st");
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

  void _inicializarTelefoneComDDD() {
    // Usamos o DDD local carregado da empresa
    final rawValue = telefoneEmpresa;

    // 1. Mantém apenas números
    final onlyDigits = rawValue.replaceAll(RegExp(r'\D'), '');

    // 2. Se estiver vazio, garante o uso do DDD da empresa
    final valorParaMascara = onlyDigits.isEmpty ? telefoneEmpresa : onlyDigits;

    // 3. Informa ao formatador como se o usuário tivesse digitado via teclado
    final initialTextValue = TextEditingValue(text: valorParaMascara);
    final formattedValue = _maskFormatterTelefone.formatEditUpdate(
      TextEditingValue.empty,
      initialTextValue,
    );

    // 4. Se a máscara não tiver fechado o parênteses, forçamos o texto correto e re-hidrata o formatador
    // (Issó acontece apenas se o DDD tiver menos formatação, mas ajuda no visual nativo)
    String finalString = formattedValue.text;
    if (finalString == '($telefoneEmpresa' || finalString == '($telefoneEmpresa)') {
      finalString = '($telefoneEmpresa) ';
      // Sincroniza o formatter injetando o espaço para que ele não resete
      _maskFormatterTelefone.formatEditUpdate(
        formattedValue,
        TextEditingValue(text: finalString),
      );
    }

    // 5. Define tudo no controller com tudo centralizado sem setTimeout
    numeroControllerTelefone.value = TextEditingValue(
      text: finalString,
      selection: TextSelection.collapsed(offset: finalString.length),
    );
  }

  // NOTA: Esta função foi substituída por lógica inline em execucaoretornoCpf()
  // para eliminar o problema de setState aninhado causado pelo Future.delayed interno.
  // Mantida como referência — NÃO REMOVER sem revisar execucaoretornoCpf().
  // ignore: unused_element
  void _inicializarTelefoneComDDDNoCpf() {
    // Usamos o DDD local carregado da empresa
    final rawValue = telefoneEmpresa;

    // 1. Mantém apenas números
    final onlyDigits = rawValue.replaceAll(RegExp(r'\D'), '');

    // 2. Se estiver vazio, garante o uso do DDD da empresa
    final valorParaMascara = onlyDigits.isEmpty ? telefoneEmpresa : onlyDigits;

    // 3. Informa ao formatador como se o usuário tivesse digitado via teclado
    final initialTextValue = TextEditingValue(text: valorParaMascara);
    final formattedValue = _maskFormatter.formatEditUpdate(
      TextEditingValue.empty,
      initialTextValue,
    );

    // 4. Mesma correção visual mantendo estado do MaskFormatter 
    String finalString = formattedValue.text;
    if (finalString == '($telefoneEmpresa' || finalString == '($telefoneEmpresa)') {
      finalString = '($telefoneEmpresa) ';
      _maskFormatter.formatEditUpdate(
        formattedValue,
        TextEditingValue(text: finalString),
      );
    }

    // 5. Define tudo no controller com tudo centralizado
    numeroController.value = TextEditingValue(
      text: finalString,
      selection: TextSelection.collapsed(offset: finalString.length),
    );
  }

  // Limpa campos quando cpf vazio
  limparCamposCpf() {
    nomeController.clear();
    dataNascimentoController.clear();
    comandaController.clear();
    adicionalController.clear();
    numeroController.clear();
    radioPreenchido = false;
    // numeroController.text = '($telefoneEmpresaMascara)';
  }

  // Limpa campos quando numero vazio
  limparCamposNumero() {
    nomeController.clear();
    cpfControllerNoTelefone.clear();
    dataNascimentoController.clear();
    comandaController.clear();
    adicionalController.clear();
    sexoSelecionado = null;
    radioPreenchido = false;
    // numeroControllerTelefone.text = '($telefoneEmpresaMascara)';
  }

  // Função para limpar todos os campos
  void limparCampos() {
    setState(() {
      nomeController.clear();
      cpfControllerNoCpf.clear();
      cpfControllerNoTelefone.clear();
      dataNascimentoController.clear();
      comandaController.clear();
      adicionalController.clear();
      numeroController.clear();
      numeroControllerTelefone.clear();
      _maskFormatter.clear();
      _maskFormatterTelefone.clear();
      sexoSelecionado = null;
      radioPreenchido = false;
      cpfValido = false;
      telefoneValido = false;
      dataCorreta = false;
      nomeValido = false;
      inserirComanda = false;
      telefoneValidoTel = false;
      cpfValidoNumero = false;
      vazioTelefone = true;
      vazioCpf = true;
      corAlerta = false;
      mensagem = '';
      mensagem2 = '';

      // numeroController.text = '($telefoneEmpresaMascara)';
      // numeroControllerTelefone.text = '($telefoneEmpresaMascara)';
    });
  }

  // LÓGICA PARA RECEBER SEXO SELECIONADO DE MANEIRA CORRETA
  passarSexoSelecionado(String sexoSelecionado) {
    if (sexoSelecionado == "FEM") {
      setState(() {
        sexoSelecionadoForm = 'FEMININO';
      });
    } else if (sexoSelecionado == "MAS") {
      setState(() {
        sexoSelecionadoForm = 'MASCULINO';
      });
    } else {
      sexoSelecionadoForm = '';
    }
  }

  // Função para fazer check in
  Future<void> validarComanda(String numeroComanda) async {
    mostrarBotoes = true;

    try {
      String dadosJson = await Connection().select(
        "SELECT numero, ativo, bloqueada, atendimento, statuspedido, numeropedido_FK "
        "FROM cartoes WHERE numero='$numeroComanda' LIMIT 1",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isEmpty) {
        setState(() {
          validaComanda = [];
          mensagem = "Nenhuma comanda encontrada!";
          corAlerta = false;
          icone = false;
        });
        return;
      }

      Map<String, dynamic> comanda = lista.first;

      if (comanda['ativo'].toString() == '0') {
        setState(() {
          mensagem = "Comanda inativa!";
          corAlerta = false;
          corComanda = false;
          icone = false;
        });
        return;
      }

      if (comanda['bloqueada'].toString() == '1') {
        setState(() {
          mensagem = "Comanda bloqueada!";
          corAlerta = false;
          corComanda = false;
          icone = false;
        });
        return;
      }

      if (comanda['numeropedido_FK'].toString() != '0') {
        setState(() {
          mensagem = "Esta comanda já está em uso!";
          corAlerta = false;
          corComanda = false;
          icone = false;
        });
        return;
      }

      if (comanda['numero'] == null) {
        setState(() {
          mensagem = "Comanda inexistente";
          corAlerta = false;
          corComanda = false;
          icone = false;
        });
        return;
      }

      try {
        setState(() => isLoading = true);

        await passarSexoSelecionado(sexoSelecionado.toString());

        // CPF
        if (botaoCpf) {
          telefoneCliente = numeroController.text;

          if (precisoCadastrarCliente) {
            numeroCliente = await abrirCliente(
              nomeCliente,
              cpfCliente,
              datanascimentoCliente,
              telefoneCliente,
              sexoSelecionadoForm,
            );
            await encontrarNumeroClientePeloCpf(cpfCliente);
          } else {
            await atualizarClientePorCpf(
              nomeCliente,
              cpfCliente,
              datanascimentoCliente,
              telefoneCliente,
              sexoSelecionadoForm,
            );
          }

          // TELEFONE
        } else if (botaotelefone) {
          telefoneCliente = numeroControllerTelefone.text;

          if (precisoCadastrarCliente) {
            numeroCliente = await abrirCliente(
              nomeCliente,
              cpfCliente,
              datanascimentoCliente,
              telefoneCliente,
              sexoSelecionadoForm,
            );
            // await encontrarNumeroClientePeloTelefone(telefoneCliente);
          } else {
            await atualizarClientePorNumero(
              nomeCliente,
              cpfCliente,
              datanascimentoCliente,
              telefoneCliente,
              sexoSelecionadoForm,
            );
          }
        }

        // GARANTINDO QUE numeroClienteInt É INT
        if (numeroClienteInt is String) {
          numeroClienteInt = int.tryParse(numeroClienteInt.toString()) ?? 0;
        }

        numeroPedido = await abrirPedido(
          numeroComanda,
          await configuracaoServico(),
          int.parse(numeroCliente),
        );

        await devolverPedido(numeroComanda);
        await atualizarCartoes(
          numeroComanda,
          valorTotalLiquido,
          statusPedido,
          nomeCliente,
        );
        await buscarNumeroProduto(numeroComanda);

        if (numeroDoProduto != null && numeroDoProduto != 0) {
          await inserirProduto(
            numeroDoProduto,
            numeroComanda,
            numeroDaLicencaSelecionada,
            numeroDoGarcom,
          );

          /* String taxaServico =  await pedidosController.configuracaoServicoComanda();
          await pedidosController.inserirVenda(
            numeroPedidoFk: numeroDoPedido, 
            numeroProdutoFk: numeroDoProduto.toString(), 
            valorUnitario: 0, 
            quantidade: 1, 
            observacao: "", 
            numeroVendedorFk: numeroUsuario, 
            numeroTradepointFk: numeroDaLicencaSelecionada, 
            numeroEstoqueFk: "0", 
            taxaServico: int.parse(taxaServico), 
            numeroAtendenteFk: numeroUsuario, 
            comissao: 0, 
            valorComissao: 0, 
            idIntegracao: "0", 
            temCashback: 0, 
            percentualCashback: 0, 
            valorCashback: 0, 
            valorLiquido: 0, 
            valorServico: 0, 
            numeroPromocaoFk: "0"
          );
        } */

        if (couvert != 0) {
          await inserirProduto(
            couvert,
            numeroComanda,
            numeroDaLicencaSelecionada,
            numeroUsuario,
          );
        }
          /* String taxaServico =  await pedidosController.configuracaoServicoComanda();
          await pedidosController.inserirVenda(
            numeroPedidoFk: numeroDoPedido, 
            numeroProdutoFk: couvert.toString(), 
            valorUnitario: 0, 
            quantidade: 1, 
            observacao: "", 
            numeroVendedorFk: numeroUsuario, 
            numeroTradepointFk: numeroDaLicencaSelecionada, 
            numeroEstoqueFk: "0", 
            taxaServico: int.parse(taxaServico), 
            numeroAtendenteFk: numeroUsuario, 
            comissao: 0, 
            valorComissao: 0, 
            idIntegracao: "0", 
            temCashback: 0, 
            percentualCashback: 0, 
            valorCashback: 0, 
            valorLiquido: 0, 
            valorServico: 0, 
            numeroPromocaoFk: "0"
          ); */
        }

        setState(() {
          comandaFoiValidada = true;
          comandaValida = true;
          isLoading = false;
          corAlerta = true;
          icone = true;
          mensagem = "Comanda $numeroComanda aberta com sucesso!!!";
          saveComanda(numeroComanda);
          limparCampos();
        });
      } catch (e) {
        print('Não foi possível abrir comanda: $e');
        setState(() {
          isLoading = false;
          corAlerta = false;
          icone = false;
          mensagem = "Erro ao abrir comanda.";
        });
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

  Future<String> atualizarClientePorNumero(
    String nomeCliente,
    String cpfCliente,
    String dataNascimentoCliente,
    String telefoneCliente,
    String sexoSelecionadoForm,
  ) async {
    String dataNascimentoFormatada = "1000-01-01";
    String telefoneClienteFormatado = "(  )     -";

    String nome = nomeCliente;
    String cidade = cidadeEmpresa;
    String uf = ufEmpresa;
    String rg = '';
    String cpf = cpfCliente;
    String sexo = sexoSelecionadoForm;

    try {
      // Tenta converter a data para o formato yyyy-MM-dd
      DateTime dataObj = DateFormat('dd/MM/yyyy').parse(dataNascimentoCliente);
      dataNascimentoFormatada = dataObj.toIso8601String().substring(0, 10);
    } catch (e) {
      dataNascimentoFormatada = "1000-01-01";
    }

    try {
      // Formata telefone padrão
      if (telefoneCliente.trim().isEmpty ||
          telefoneCliente == "($telefoneEmpresa)") {
        telefoneClienteFormatado = "(  )     -";
      } else {
        telefoneClienteFormatado = telefoneCliente;
      }
    } catch (e) {
      telefoneClienteFormatado = "(  )     -";
    }

    String telefone = telefoneClienteFormatado;
    String contato = '';
    String observacao = '';

    // Monta o SQL UPDATE
    String sql =
        '''
      UPDATE clientes
      SET 
        nome = '$nome',
        cidade = '$cidade',
        uf = '$uf',
        cpf = '$cpf',
        sexo = '$sexo',
        datanascimento = '$dataNascimentoFormatada',
        telefone = '$telefone',
        observacao = '$observacao'
      WHERE telefone = '$telefone';
    ''';

    // Executa o SQL usando a função ipd
    String resultado = await Connection().ipd(sql);

    if (resultado == "sucesso") {
      print(sql);
      print("Cliente atualizado com sucesso!");
    } else {
      print("Erro ao atualizar cliente.");
    }

    return resultado;
  }

  // Função quando cliente já existe por cpf
  Future<String> atualizarClientePorCpf(
    String nomeCliente,
    String cpfCliente,
    String dataNascimentoCliente,
    String telefoneCliente,
    String sexoSelecionadoForm,
  ) async {
    String dataNascimentoFormatada = "1000-01-01";
    String telefoneClienteFormatado = "(  )     -";

    String nome = nomeCliente.toUpperCase();
    String cidade = cidadeEmpresa;
    String uf = ufEmpresa;
    String rg = '';
    String cpf = cpfCliente;
    String sexo = sexoSelecionadoForm;

    try {
      // Tenta converter a data para o formato yyyy-MM-dd
      DateTime dataObj = DateFormat('dd/MM/yyyy').parse(dataNascimentoCliente);
      dataNascimentoFormatada = dataObj.toIso8601String().substring(0, 10);
    } catch (e) {
      dataNascimentoFormatada = "1000-01-01";
    }

    try {
      // Formata telefone padrão
      if (telefoneCliente.trim().isEmpty ||
          telefoneCliente == "($telefoneEmpresa)") {
        telefoneClienteFormatado = "(  )     -";
      } else {
        telefoneClienteFormatado = telefoneCliente;
      }
    } catch (e) {
      telefoneClienteFormatado = "(  )     -";
    }

    String telefone = telefoneClienteFormatado;
    String contato = '';
    String observacao = '';

    // Monta o SQL UPDATE
    String sql =
        '''
      UPDATE clientes
      SET 
        nome = '$nome',
        cidade = '$cidade',
        uf = '$uf',
        cpf = '$cpf',
        sexo = '$sexo',
        datanascimento = '$dataNascimentoFormatada',
        telefone = '$telefone',
        observacao = '$observacao'
      WHERE cpf = '$cpf';
    ''';

    // Executa o SQL usando a função ipd
    String resultado = await Connection().ipd(sql);

    if (resultado == "sucesso") {
      print(sql);
      print("Cliente atualizado com sucesso!");
    } else {
      print("Erro ao atualizar cliente.");
    }

    return resultado;
  }

  // Função quando cliente não existe
  Future<String> abrirCliente(
    nomeCliente,
    cpfCliente,
    dataNascimentoCliente,
    telefoneCliente,
    sexoSelecionadoForm,
  ) async {
    String dataNascimentoFormatada = "1000-01-01";
    String telefoneClienteFormatado = "(  )     -";
    String dataCadastroFormatado = obterDataHoraMysql();

    String nome = nomeCliente.toUpperCase();
    String cidade = cidadeEmpresa;
    String uf = ufEmpresa;
    String rg = '';
    String cpf = cpfCliente;
    String sexo = sexoSelecionadoForm;

    try {
      DateTime dataObj = DateFormat('dd/MM/yyyy').parse(dataNascimentoCliente);
      dataNascimentoFormatada = dataObj.toIso8601String().substring(0, 10);
    } catch (e) {
      dataNascimentoFormatada = "1000-01-01";
    }

    try {
      if (telefoneCliente == "($telefoneEmpresa)") {
        telefoneClienteFormatado = "(  )     -";
      } else {
        telefoneClienteFormatado = telefoneCliente;
      }
    } catch (e) {
      telefoneClienteFormatado = "(  )     -";
    }

    String telefone = telefoneClienteFormatado;
    String contato = '';
    String observacao = '';

    // String sql = '''INSERT INTO clientes (nome, cidade, uf, cpf, sexo, datanascimento, telefone, observacao) VALUES ('LE', '', '', $cpf, $sexo, $dataNascimentoFormatada, $telefoneClienteFormatado, ''); ''';
    String sql =
        '''
      INSERT INTO clientes 
      (nome, cidade, uf, cpf, sexo, datanascimento, telefone, observacao, dataCadastro)
      VALUES ('$nome', '$cidade', '$uf', '$cpf', '$sexo', '$dataNascimentoFormatada', '$telefoneClienteFormatado', '$observacao', '$dataCadastroFormatado');
    ''';
    try {
      String resultado = await Connection().insertId(sql);
      print(sql);
      if (resultado != '') {
        return resultado;
      } else {
        return "";
      }
    } catch (e) {
      return "";
    }
  }

  // Insert para abrir pedido
  Future<String> abrirPedido(
    String numeroComanda,
    String taxaservico,
    int numeroClienteInt,
  ) async {
    // Valores fixos
    String numeroCaixaAtual = '0';
    String numeroUsuarioAtual = numeroDoGarcom;
    String numeroTradepointAtual = numeroDaLicencaSelecionada;
    String cobrarTaxa = taxaservico;
    String NumeroComanda = numeroComanda;
    int numeroCliente = numeroClienteInt;

    // Montando o SQL
    String sql = "INSERT INTO pedidos (numerocartao_FK,numerocaixa_FK,numerousuarioabertura_FK,status,pessoas,observacao,numerotradepointabertura_FK,taxaservico,descricaopedido,abertura,numerocliente_FK) VALUES ('$NumeroComanda','$numeroCaixaAtual','$numeroUsuarioAtual','1','1','','$numeroTradepointAtual','$cobrarTaxa','Comanda - $NumeroComanda', CURRENT_TIMESTAMP,'$numeroCliente')";
    try {
      String numeroPedido = await Connection().insertId(sql);

      if (numeroPedido != "") {
        return numeroPedido;
      } else {
        return "";
      }
    } catch (e) {
      return "";
    }
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
    String nomeCliente,
  ) async {
    // Variáveis locais
    String numeroPedido =
        numeroDoPedido; // pego de alguma variável global/controlador
    String numeroDaComanda = numeroComanda;
    String valorTotal = valorTotalLiquido;
    String statuspedido = statusPedido;
    String clienteNome = nomeCliente;

    // Montando o SQL
    String sql =
        """
      UPDATE cartoes 
      SET 
        numeropedido_FK = '$numeroPedido', 
        valorliquidopedido = '$valorTotal', 
        statuspedido = '$statuspedido', 
        pessoas = '1',
        nomecliente = '$clienteNome'
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

  // Função para validar dados cliente quando CPF escolhido
  validaDadosCliente() {
    if (nomeController.text.isNotEmpty) {
      setState(() {
        inserirComanda = true;
      });
    } else {
      setState(() {
        inserirComanda = false;
      });
    }
  }

  // Função que retorna o número do produto vinculado à comanda
  Future<void> buscarNumeroProduto(String numeroComanda) async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numeroproduto_FK FROM checkinautomatico WHERE numerocomanda_FK='$numeroComanda' LIMIT 1;",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        // pega o campo numeroproduto_FK e converte para int
        int numeroProduto =
            int.tryParse(lista[0]['numeroproduto_FK'].toString()) ?? 0;

        setState(() {
          numeroDoProduto = numeroProduto; // agora é inteiro
        });

        print("Número do produto encontrado: $numeroProduto");
      } else {
        setState(() {
          numeroDoProduto = 0; // valor padrão se não encontrar
        });
        print("Nenhum produto encontrado para comanda $numeroComanda");
      }
    } catch (e) {
      print("Erro ao buscar número do produto: $e");
      setState(() {
        numeroDoProduto = 0;
      });
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

  // Função para inserir um produto
  Future<void> inserirProduto(
    int numeroDoProduto,
    String numeroComanda,
    String numeroDaLicencaSelecionada,
    String numeroUsuario,
  ) async {
    String numeroSerie = '1';
    String numeroTradepointFK = numeroDaLicencaSelecionada;
    String numeroUsuarioFK = numeroUsuario;
    String numeroCartao = numeroComanda;
    int numeroProdutoFK = numeroDoProduto; // numero couvert artistico || numero produto
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

  void validarNome(String nome) {
    setState(() {
      if (nome.isEmpty) {
        nomeValido = false;
      } else {
        // Agora, o resultado do validador é o único a ser atribuído
        nomeValido = true;
        // _inicializarTelefoneComDDDNoCpf();
        validaDadosCliente();
      }
    });
    if (botaotelefone) {
      _showKeyboardNome = false;
      //mostrarBotoes = true;
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

  // Função de validação de cpf
  void validarCPFnoCpf(String cpf) {
    final hora = DateTime.now().toIso8601String();
    debugPrint('[CAMPO] $hora validarCPFnoCpf → cpf="$cpf" | campoAtivo=$_campoAtivo');

    if (cpf.isEmpty) {
      debugPrint('[CAMPO] $hora validarCPFnoCpf → CPF vazio, limpando campos');
      setState(() {
        _showKeyboardMaior = false;
        vazioCpf = true;
        cpfValido = false;
        inserirComanda = false;
        desaparecerTema = false;
        clienteExiste = false;
      });
      limparCamposCpf();
      return;
    }

    final bool cpfEhValido = CPFValidator.isValid(cpf);
    debugPrint('[CAMPO] $hora validarCPFnoCpf → CPF válido: $cpfEhValido | clienteExiste: $clienteExiste');

    setState(() {
      _showKeyboardMaior = false;
      vazioCpf = false;
      cpfValido = cpfEhValido;
      inserirComanda = false;
      desaparecerTema = false;
      // Reseta clienteExiste para garantir estado limpo antes da nova busca
      clienteExiste = false;
    });
    limparCamposCpf();
    validaDadosCliente();

    if (!cpfEhValido) {
      debugPrint('[CAMPO] $hora validarCPFnoCpf → CPF inválido, nenhum foco solicitado');
      return;
    }

    // CPF válido: inicia busca assíncrona — foco será definido em execucaoretornoCpf()
    debugPrint('[CAMPO] $hora validarCPFnoCpf → CPF válido, iniciando buscarPorCpf (assíncrono)');
    buscarPorCpf(cpfControllerNoCpf.text);
    // NÃO solicitar foco aqui. O foco correto será solicitado por execucaoretornoCpf()
    // quando a busca retornar, evitando completamente a condição de corrida.
  }

  void validarCPFnoNumero(String cpf) {
    final hora = DateTime.now().toIso8601String();
    debugPrint('[CAMPO] $hora validarCPFnoNumero → cpf="$cpf"');

    if (cpf.isEmpty) {
      setState(() {
        _showKeyboardMaior = false;
        cpfValidoNumero = false;
        inserirComanda = false;
        mostrarBotoes = true;
      });
      return;
    }

    final bool cpfEhValido = CPFValidator.isValid(cpf);
    setState(() {
      cpfValidoNumero = cpfEhValido;
      inserirComanda = false;
      _showKeyboardMaior = false;
    });
    validaDadosCliente();

    if (cpfEhValido) {
      debugPrint('[TECLADO] $hora validarCPFnoNumero → foco em: nascimento');
      setState(() {
        _showKeyboardMaior = false;
        _showKeyboardNome = true;
        mostrarBotoes = true;
        _campoAtivo = 'nascimento';
      });
      // requestFocus fora do setState, via guard
      _solicitarFoco(nascimentoFocusNode, 'nascimento');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _scrollToField(nascimentoFocusNode);
      });
    }
  }

  // Função de validação de telefone
  void validarTelefoneNoCPF(String telefone) {
    final hora = DateTime.now().toIso8601String();
    debugPrint('[CAMPO] $hora validarTelefoneNoCPF → telefone="$telefone"');

    final String telefoneSomenteNumeros = telefone.replaceAll(RegExp(r'[^0-9]'), '');

    if (telefoneSomenteNumeros.isEmpty) {
      setState(() {
        telefoneValido = false;
        mostrarBotoes = true;
      });
      return;
    }

    final bool telEhValido = telefone.length == 14;
    setState(() {
      telefoneValido = telEhValido;
    });
    validaDadosCliente();

    if (telEhValido) {
      debugPrint('[TECLADO] $hora validarTelefoneNoCPF → foco em: nascimento');
      setState(() {
        _showKeyboardMaior = false;
        _showKeyboardNome = true;
        mostrarBotoes = true;
        _campoAtivo = 'nascimento';
      });
      // requestFocus fora do setState, via guard
      _solicitarFoco(nascimentoFocusNode, 'nascimento');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _scrollToField(nascimentoFocusNode);
      });
    }
  }

  // Função de validação de telefone
  void validarTelefoneNoNumero(String telefone) {
    final hora = DateTime.now().toIso8601String();
    debugPrint(
      '[CAMPO] $hora validarTelefoneNoNumero → telefone="$telefone"',
    );

    final String telefoneSomenteNumeros =
        telefone.replaceAll(RegExp(r'[^0-9]'), '');

    // Campo vazio
    if (telefoneSomenteNumeros.isEmpty) {
      if (!vazioTelefone || telefoneValidoTel) {
        setState(() {
          vazioTelefone = true;
          telefoneValidoTel = false;
          desaparecerTema = false;
        });
      }

      limparCamposNumero();
      return;
    }

    final bool telEhValido = telefoneSomenteNumeros.length == 11;

    // Atualiza estado apenas se necessário
    if (vazioTelefone ||
        telefoneValidoTel != telEhValido ||
        desaparecerTema) {
      setState(() {
        vazioTelefone = false;
        telefoneValidoTel = telEhValido;
        desaparecerTema = false;
      });
    }

    validaDadosCliente();

    // Só executa quando o telefone estiver completo
    if (!telEhValido) {
      return;
    }

    // Busca cliente pelo telefone
    buscarPorNumero(numeroControllerTelefone.text);

    /* debugPrint(
      '[TECLADO] $hora validarTelefoneNoNumero → foco em: comanda',
    ); */

    desaparecerTema = true;

    setState(() {
      _campoAtivo = 'comanda';
      _showKeyboardNome = true;
      _showKeyboardMaior = false;
      mostrarBotoes = false;
    });

    // Solicita foco somente após o frame atual
    // _solicitarFoco(comandaFocusNode, 'comanda');

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _solicitarFoco(comandaFocusNode, 'comanda');
    });
  }
  /* void validarTelefoneNoNumero(String telefone) {
    final hora = DateTime.now().toIso8601String();
    debugPrint('[CAMPO] $hora validarTelefoneNoNumero → telefone="$telefone"');

    final String telefoneSomenteNumeros = telefone.replaceAll(RegExp(r'[^0-9]'), '');

    if (telefoneSomenteNumeros.isEmpty) {
      setState(() {
        vazioTelefone = true;
        telefoneValidoTel = false;
        desaparecerTema = false;
      });
      limparCamposNumero();
      return;
    }

    final bool telEhValido = telefone.length == 14;
    setState(() {
      vazioTelefone = false;
      telefoneValidoTel = telEhValido;
      desaparecerTema = false;
    });
    limparCamposNumero();
    validaDadosCliente();
    buscarPorNumero(numeroControllerTelefone.text);

    if (telEhValido) {
      debugPrint('[TECLADO] $hora validarTelefoneNoNumero → foco em: nome');
      desaparecerTema = true;
      setState(() {
        _campoAtivo = 'nome';
        _showKeyboardNome = false;
        _showKeyboardMaior = true;
        mostrarBotoes = false;
      });
      // requestFocus fora do setState, via guard
      _solicitarFoco(nomeFocusNode, 'nome');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _scrollToField(nomeFocusNode);
      });
    }
  } */

  // Função de validação de data
  void validarNascimento(String data) {
    final hora = DateTime.now().toIso8601String();
    debugPrint('[CAMPO] $hora validarNascimento → data="$data"');

    final String dataNascimento = data.replaceAll(RegExp(r'[^0-9]'), '');

    if (dataNascimento.isEmpty) {
      setState(() {
        dataCorreta = false;
      });
      return;
    }

    final bool dataEhCorreta = dataNascimento.length >= 8;
    setState(() {
      dataCorreta = dataEhCorreta;
    });
    validaDadosCliente();

    if (dataEhCorreta) {
      debugPrint('[TECLADO] $hora validarNascimento → foco em: comanda');
      setState(() {
        _campoAtivo = 'comanda';
        _showKeyboardNome = true;
      });
      // requestFocus fora do setState, via guard
      _solicitarFoco(comandaFocusNode, 'comanda');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _scrollToField(comandaFocusNode);
      });
    }
  }


  // Função para carregar cidade e uf
  Future<void> carregarCidadeUf() async {
    String telefoneEmpresaLocal = '';
    try {
      String dadosJson = await Connection().select(
        "SELECT telefone, cidade, uf FROM empresa WHERE numero='1' LIMIT 1",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        cidadeEmpresa = lista[0]['cidade'].toString();
        ufEmpresa = lista[0]['uf'].toString();
        telefoneEmpresaLocal = lista[0]['telefone'].toString();
      }

      String codigoArea = telefoneEmpresaLocal.substring(1, 3);
      telefoneEmpresa = codigoArea;
    } catch (e) {
      setState(() {
        cidadeEmpresa = '';
        ufEmpresa = '';
      });
    }
  }

  // Função para atualizar hora
  void _atualizarHora() {
    final agora = DateTime.now();

    // Formato para exibição (HH:mm)
    final horaFormatada = DateFormat.Hm().format(agora);

    // Formato completo para MySQL (YYYY-MM-DD HH:mm:ss)
    final horaMySQL = DateFormat('yyyy-MM-dd HH:mm:ss').format(agora);

    setState(() {
      _horaAtual = horaFormatada; // para mostrar no app
      _horaBanco = horaMySQL; // para enviar ao banco
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _timerSelect?.cancel();
    _timerApagar?.cancel();
    _focusNode.dispose();
    nomeFocusNode.removeListener(_onNomeFocusChange);
    nomeFocusNode.dispose();
    numeroFocusNode.dispose();
    numeroTelefoneFocusNode.dispose();
    cpfnoCpfFocusNode.dispose();
    cpfnoTelefoneFocusNode.dispose();
    nascimentoFocusNode.dispose();
    comandaFocusNode.dispose();
    adicionalFocusNode.dispose();
    _searchFocusNode.dispose();
    nomeController.dispose();
    numeroController.dispose();
    numeroControllerTelefone.dispose();
    cpfControllerNoCpf.dispose();
    cpfControllerNoTelefone.dispose();
    dataNascimentoController.dispose();
    comandaController.dispose();
    adicionalController.dispose();
    super.dispose();
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
      });
    }
  }

  Future<void> _scrollToField(FocusNode focusNode) async {
    if (!mounted) return;

    // Obtém o insets inferior atual (tamanho do teclado físico sobre a tela).
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0.0;

    if (!isKeyboardOpen) {
      // Se o teclado ainda está falso fechado (começou a subir),
      // aguardamos sua animação de subida concluir, juntamente com o seu
      // AnimatedPadding de 300ms. Esperamos ~350 a 400ms para uma margem de segurança.
      await Future.delayed(const Duration(milliseconds: 400));
    } else {
      // Se o teclado já estava totalmente aberto (ex: pulando foco entre campos),
      // aguardamos apenas 50ms para que qualquer widget rebuild conclua seu frame.
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (!mounted) return;
    
    final ctx = focusNode.context;
    if (ctx == null || !ctx.mounted) return;

    // Realiza a rolagem com a tela já no tamanho e estados finais.
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      alignment: 0.3, // Mantém com margem superior confortável acima do teclado
    );
  }

  /* // Função auxilia na rolagel
  void _scrollToField(FocusNode focusNode) {
    if (!mounted) return;
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;

      final ctx = focusNode.context;
      if (ctx == null) return;

      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        alignment: 0.3,
      );
    });
  } */

  // Diálogo de confirmação
  Future<void> showConfirmationDialog({
    required BuildContext context,
    String title = 'Confirmação',
    required String message,
    IconData icon = Icons.home,
    String cancelText = 'Cancelar',
    String confirmText = 'OK',
    VoidCallback? onConfirm,
  }) {
    bool isSuccess = icon == Icons.check_circle;
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
                    color: isSuccess
                        ? Theme.of(ctx).colorScheme.shadow.withOpacity(0.08)
                        : Theme.of(ctx).colorScheme.error.withOpacity(0.08),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    icon,
                    size: 40,
                    color: isSuccess
                        ? Theme.of(ctx).colorScheme.shadow
                        : Theme.of(ctx).colorScheme.error,
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
                        backgroundColor: isSuccess
                            ? Theme.of(ctx).colorScheme.shadow
                            : Theme.of(ctx).colorScheme.error,
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

  Widget _buildWithKeyboardActions({
    required FocusNode focusNode,
    required Widget child,
  }) {
    return KeyboardActions(
      disableScroll: true,
      autoScroll: false,
      config: KeyboardActionsConfig(
        keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
        nextFocus: false,
        actions: [
          KeyboardActionsItem(
            focusNode: focusNode,
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
            /* toolbarButtons: [
              (node) {
                return GestureDetector(
                  onTap: () {
                    node.unfocus();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "OK",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ], */
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    List<String> _letras = [];
    for (int i = 65; i <= 90; i++) {
      _letras.add(String.fromCharCode(i));
    }
    // Adiciona um placeholder para o botão de apagar e fechar. Total de 27 itens.
    final List<String?> _keyItems = [..._letras, null];
    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: SideNav(),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: Obx(() {
          final conectado = Connection.connectionStatus.value;
          return AppBar(
            backgroundColor: Connection.connectionStatus.value
                ? colorScheme.primary
                : colorScheme.error,
            automaticallyImplyLeading: false,
            title: Stack(
              alignment: Alignment.center,
              children: [
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
                Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
      // Corpo da tela
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(0.0),
              child: Column(
                children: [
                  if (!desaparecerTema) SizedBox(height: 10),
                  Column(
                    children: [
                      Padding(
                        padding: footerButtonsController.aparecerNote.value ? EdgeInsets.only(top: 5.0, bottom: 15.0, left: 10.0, right: 10.0,)
                            : EdgeInsets.only(top: 5.0, bottom: 15.0, left: 15.0, right: 15.0,),
                        child: Form(
                          key: _formKey,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Título e seletor de tipo
                                  if (!desaparecerTema)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Recepção',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                          ),
                                        ),
                                        // botões 'CPF', 'Número'
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // botão CPF
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  limparCampos();
                                                  corBorda = false;
                                                  botaoCpf = true;
                                                  botaotelefone = false;
                                                  radioPreenchido = false;
                                                  cpfValido = false;
                                                  telefoneValido = false;
                                                  dataCorreta = false;
                                                  nomeValido = false;
                                                  inserirComanda = false;
                                                  telefoneValidoTel = false;
                                                  cpfValidoNumero = false;
                                                  _showKeyboardNome = true;
                                                  _campoAtivo = 'cpfCpf';
                                                  if (!mounted) return;
                                                  Future.delayed(
                                                    Duration(milliseconds: 300),
                                                    () {
                                                      _scrollToField(
                                                        cpfnoCpfFocusNode,
                                                      );
                                                    },
                                                  );
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                shape: CircleBorder(),
                                                padding: EdgeInsets.all(
                                                  20,
                                                ), // tamanho do círculo
                                                backgroundColor:
                                                    colorScheme.shadow,
                                              ),
                                              child: Text(
                                                'CPF',
                                                style: TextStyle(
                                                  color: colorScheme.onPrimary,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 3),
                                            // botão numero
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  limparCampos();
                                                  corBorda = false;
                                                  botaoCpf = false;
                                                  botaotelefone = true;
                                                  radioPreenchido = false;
                                                  cpfValido = false;
                                                  telefoneValido = false;
                                                  dataCorreta = false;
                                                  nomeValido = false;
                                                  inserirComanda = false;
                                                  telefoneValidoTel = false;
                                                  cpfValidoNumero = false;
                                                  _showKeyboardNome = true;
                                                  mostrarBotoes = true;
                                                  _campoAtivo =
                                                      'numeroTelefone';
                                                  if (!mounted) return;
                                                  Future.delayed(
                                                    Duration(milliseconds: 300),
                                                    () {
                                                      _scrollToField(
                                                        numeroTelefoneFocusNode,
                                                      );
                                                    },
                                                  );
                                                  _inicializarTelefoneComDDD();
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                shape: CircleBorder(),
                                                padding: EdgeInsets.all(
                                                  20,
                                                ), // tamanho do círculo
                                                backgroundColor:
                                                    colorScheme.tertiary,
                                              ),
                                              child: Icon(
                                                Icons.phone,
                                                // size: 25,
                                                color: colorScheme.onPrimary,
                                              ),
                                            ),

                                            SizedBox(width: 3),
                                          ],
                                        ),
                                      ],
                                    ),
                                  // SizedBox(height: 16),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.85, // Ajuste ligeiro para os botões do final
                                    child: Padding(
                                      // Utilizamos a injeção em tempo real da medida do teclado físico
                                      padding: EdgeInsets.only(
                                        bottom: MediaQuery.of(context).viewInsets.bottom,
                                      ),
                                      child: Container(
                                        child: SingleChildScrollView(
                                          controller: _scrollController,
                                          physics: BouncingScrollPhysics(),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              // #region REGIÃO BOTÃO CPF
                                              if (botaoCpf)
                                                Padding(
                                                  padding: EdgeInsets.only(bottom: 12.0, top: 15.0,),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: <Widget>[
                                                      // CAMPO DE TEXTO (CPF)
                                                      Expanded(
                                                        child: _buildWithKeyboardActions(
                                                          focusNode: cpfnoCpfFocusNode,
                                                          child: TextFormField(
                                                            controller: cpfControllerNoCpf,
                                                            readOnly: false,
                                                            showCursor: true,
                                                            cursorColor: Theme.of(context,).colorScheme.primary,
                                                            focusNode: cpfnoCpfFocusNode,
                                                            textInputAction: TextInputAction.next,
                                                            keyboardType: TextInputType.number,
                                                            textAlign: TextAlign.center,
                                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                                                            onChanged:(valorDigitado,)=> validarCPFnoCpf(valorDigitado,),
                                                            onTap: () {
                                                              // _toggleKeyboardMaior(false);
                                                              setState(() {
                                                                _showKeyboardNome = true;
                                                                _showKeyboardMaior = false;
                                                                _campoAtivo = 'cpfCpf';
                                                              });
                                                              if (!mounted) return;
                                                              Future.delayed(Duration(milliseconds: 300,), () {
                                                                _scrollToField(cpfnoCpfFocusNode,);
                                                              },);   
                                                            },
                                                            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold,),
                                                            decoration: InputDecoration(
                                                              labelText: 'CPF',
                                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10,),),
                                                              filled: true,
                                                              fillColor: vazioCpf
                                                                  ? colorScheme.surface.withOpacity(0.5,)
                                                                  : cpfValido
                                                                  ? colorScheme.primary.withOpacity(0.5,)
                                                                  : colorScheme.error.withOpacity(0.5,),
                                                              contentPadding: EdgeInsets.symmetric(vertical:15, horizontal:10,),
                                                            ),
                                                          ),
                                                        ),
                                                      ),

                                                      // 2. BOTÃO DE BUSCA
                                                      if (cpfValido)
                                                        // Adicione um pequeno espaço entre o campo e o botão
                                                        Padding(
                                                          padding: EdgeInsets.only(left: 10.0,),
                                                          child: ElevatedButton(
                                                            onPressed: () {
                                                              buscarPorCpf(cpfControllerNoCpf.text,);
                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                              shape: CircleBorder(),
                                                              padding: EdgeInsets.all(15,),   
                                                              backgroundColor: colorScheme.shadow,                                                          
                                                              elevation: 8,
                                                              shadowColor: Colors.black,
                                                            ),
                                                            child: Icon(Icons.search, size: 25, color: colorScheme.onPrimary,),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              SizedBox(height: 15),
                                              if (cpfValido)
                                                Padding(
                                                  padding: EdgeInsets.only(bottom: 12.0,),                                                  
                                                  child: _buildWithKeyboardActions(
                                                    focusNode: nomeFocusNode,
                                                    child: TextFormField(
                                                      controller: nomeController,
                                                      textCapitalization: TextCapitalization.characters,
                                                      readOnly: false,
                                                      showCursor: true,
                                                      cursorColor: Theme.of(context).colorScheme.primary,
                                                      keyboardType: TextInputType.text,
                                                      focusNode: nomeFocusNode,
                                                      textInputAction: TextInputAction.next,
                                                      textAlign: TextAlign.center,
                                                      onChanged: (valorDigitado) {
                                                        nomeController.text = valorDigitado.toUpperCase();
                                                        nomeController.selection = TextSelection.collapsed(offset: nomeController.text.length,); // Manter o cursor no final
                                                        validarNome(valorDigitado);
                                                      },
                                                      onTap: () {
                                                        setState(() {
                                                          _showKeyboardNome = false;
                                                          _showKeyboardMaior = true;
                                                          mostrarBotoes = false;
                                                        });
                                                      },
                                                      onFieldSubmitted: (_) {
                                                        setState(() {
                                                          mostrarBotoes = true;
                                                          Future.delayed(const Duration(milliseconds: 300,), () {
                                                              _showKeyboardNome = true;
                                                            },); 
                                                          _campoAtivo = 'numero';
                                                          FocusScope.of(context).requestFocus(numeroFocusNode);
                                                          //_showKeyboardNative = false;
                                                        });
                                                      },
                                                      decoration: InputDecoration(
                                                        labelText: 'Nome',
                                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10,),),
                                                        fillColor: nomeController.text.isNotEmpty
                                                            ? colorScheme.primary.withOpacity(0.5,)
                                                            : colorScheme.surface.withOpacity(0.5,),
                                                        filled: true,
                                                        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10,),
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                              if (cpfValido)
                                                Padding(
                                                  padding: EdgeInsets.only(bottom: 12.0,),
                                                  child: _buildWithKeyboardActions(
                                                    focusNode: numeroFocusNode,
                                                    child: TextFormField(
                                                      controller: numeroController,
                                                      readOnly: false,
                                                      showCursor: true, // FORÇA o cursor piscando
                                                      cursorColor: Theme.of(context).colorScheme.primary,
                                                      // keyboardType: TextInputType.none, // garante que o teclado não abra
                                                      focusNode: numeroFocusNode,
                                                      textInputAction: TextInputAction.next,
                                                      onFieldSubmitted: (_) {
                                                        FocusScope.of(context).requestFocus(nascimentoFocusNode);
                                                      },
                                                      keyboardType: TextInputType.number,
                                                      inputFormatters: [_maskFormatter],
                                                      onChanged: (valorDigitado) => validarTelefoneNoCPF(valorDigitado),
                                                      onTap: () {
                                                        setState(() {
                                                          mostrarBotoes = true;
                                                          _showKeyboardMaior = false;
                                                          _showKeyboardNome = true;
                                                          _campoAtivo = 'numero';
                                                          //_showKeyboardNative = false;
                                                        });
                                                        Future.delayed(Duration(milliseconds: 300,), () {
                                                            if (!mounted) return;
                                                            _scrollToField(numeroFocusNode);
                                                          },
                                                        );
                                                      },
                                                      textAlign: TextAlign.center,
                                                      decoration: InputDecoration(
                                                        labelText: 'Número telefone',
                                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10,),
                                                        ),
                                                        fillColor: telefoneValido
                                                            ? colorScheme.primary.withOpacity(0.5,)
                                                            : colorScheme.surface.withOpacity(0.5,),
                                                        filled: true,
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                              if (cpfValido)
                                                // O Padding externo garante um espaçamento consistente
                                                Padding(
                                                  padding: EdgeInsets.only(bottom: 12.0,),
                                                  child: Row(
                                                    children: listaSexo.map((sexo,) {
                                                      //Envolva o RadioListTile em Flexible para restringir o tamanho
                                                      return Flexible(
                                                        child: Center(
                                                          child: RadioListTile<String>(
                                                            title: Text(
                                                              sexo,
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                            value: sexo,
                                                            groupValue: sexoSelecionado,
                                                            onChanged: (value) {
                                                              setState(() {
                                                                sexoSelecionado = value;
                                                                radioPreenchido = true;
                                                                validaDadosCliente();
                                                              });
                                                            },
                                                            contentPadding: EdgeInsets.zero,
                                                            dense: true,
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),

                                              if (cpfValido)
                                                Padding(
                                                  padding: EdgeInsets.only(bottom: 12.0,),
                                                  child: _buildWithKeyboardActions(
                                                    focusNode: nascimentoFocusNode,
                                                    child: TextFormField(
                                                      controller: dataNascimentoController,
                                                      readOnly: false,
                                                      showCursor: true,
                                                      cursorColor: Theme.of(context).colorScheme.primary,
                                                      keyboardType: TextInputType.number,
                                                      focusNode: nascimentoFocusNode,
                                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, DateInputFormatter(),],
                                                      textInputAction: TextInputAction.next,
                                                      onFieldSubmitted: (_) {
                                                        FocusScope.of(context).requestFocus(comandaFocusNode);
                                                      },
                                                      textAlign: TextAlign.center,
                                                      onChanged: (valorDigitado) => validarNascimento(valorDigitado),
                                                      onTap: () {
                                                        setState(() {
                                                          _showKeyboardNome = true;
                                                          // _toggleKeyboardMaior(false);
                                                          _showKeyboardMaior = false;
                                                          mostrarBotoes = true;
                                                          _campoAtivo = 'nascimento';
                                                          //_showKeyboardNative = false;
                                                        });
                                                        Future.delayed(
                                                          Duration(milliseconds: 300,),
                                                          () {
                                                            if (!mounted) return;
                                                            _scrollToField(nascimentoFocusNode);
                                                          },
                                                        );
                                                      },
                                                      decoration: InputDecoration(
                                                        labelText: 'Data de aniversário',
                                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10,),
                                                        ),
                                                        fillColor: dataCorreta
                                                            ? colorScheme.primary.withOpacity(0.5,)
                                                            : colorScheme.surface.withOpacity(0.5,),
                                                        filled: true,
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                              // #region REGIÃO BOTÃO TELEFONE
                                              if (botaotelefone)
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    bottom: 12.0,
                                                  ),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: <Widget>[
                                                      // 1. CAMPO DE TEXTO (TELEFONE)
                                                      Expanded(
                                                        child: _buildWithKeyboardActions(
                                                          focusNode:numeroTelefoneFocusNode,
                                                          child: TextFormField(
                                                            controller: numeroControllerTelefone,
                                                            textInputAction: TextInputAction.next,
                                                            onFieldSubmitted: (_) {
                                                              FocusScope.of(context).requestFocus(nomeFocusNode);
                                                            },
                                                            readOnly: false,
                                                            showCursor: true,
                                                            cursorColor: Theme.of(context).colorScheme.primary,
                                                            focusNode: numeroTelefoneFocusNode,
                                                            keyboardType:TextInputType.number,
                                                            inputFormatters: [
                                                              _maskFormatterTelefone,
                                                            ],
                                                            onChanged: (text) {
                                                              validarTelefoneNoNumero(text);
                                                            },
                                                            onTap: () {
                                                              setState(() {
                                                                _showKeyboardNome = true;
                                                                _showKeyboardMaior = false;
                                                                mostrarBotoes = true;
                                                                _campoAtivo = 'numeroTelefone';
                                                                if (!mounted) return;
                                                              });
                                                              _scrollToField(numeroTelefoneFocusNode);
                                                            },
                                                            style: TextStyle(
                                                              fontSize: 25,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                            textAlign: TextAlign.center,
                                                            decoration: InputDecoration(
                                                              labelText: 'Número telefone',
                                                              border: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(10,),
                                                              ),
                                                              filled: true,
                                                              fillColor: vazioTelefone
                                                                  ? colorScheme.surface.withOpacity(0.5,)
                                                                  : telefoneValidoTel
                                                                  ? colorScheme.primary.withOpacity(0.5,)
                                                                  : colorScheme.error.withOpacity(0.5,),
                                                              contentPadding: EdgeInsets.symmetric(
                                                                vertical: 15,
                                                                horizontal: 10,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),

                                                      // 2. BOTÃO DE BUSCA
                                                      if (telefoneValidoTel)
                                                        Padding(
                                                          padding: EdgeInsets.only(left: 10.0,),
                                                          child: ElevatedButton(
                                                            onPressed: () {
                                                              buscarPorNumero(numeroControllerTelefone.text,);
                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                              shape: CircleBorder(),
                                                              padding: EdgeInsets.all(15,),
                                                              backgroundColor: colorScheme.shadow,
                                                              elevation: 8,
                                                              shadowColor: Colors.black,
                                                            ),
                                                            child: Icon(
                                                              Icons.search,
                                                              size: 25,
                                                              color: colorScheme.onPrimary,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),

                                              if (telefoneValidoTel)
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    bottom: 12.0,
                                                  ),
                                                  child: _buildWithKeyboardActions(
                                                    focusNode: nomeFocusNode,
                                                    child: TextFormField(
                                                      controller: nomeController,
                                                      readOnly: false,
                                                      showCursor: true,
                                                      cursorColor: Theme.of(context).colorScheme.primary,
                                                      keyboardType: TextInputType.text,
                                                      focusNode: nomeFocusNode,
                                                      textAlign: TextAlign.center,
                                                      textInputAction: TextInputAction.next,
                                                      textCapitalization: TextCapitalization.characters,
                                                      onFieldSubmitted: (_) {
                                                        setState(() {
                                                          mostrarBotoes = true;
                                                          Future.delayed(const Duration(milliseconds: 300),
                                                            () {
                                                              _showKeyboardNome = true;
                                                            },
                                                          );
                                                          _campoAtivo = 'numero';
                                                          FocusScope.of(context).requestFocus(cpfnoTelefoneFocusNode);
                                                        });
                                                      },
                                                      // onChanged: (valorDigitado) => validarNome(valorDigitado,),
                                                      onChanged: (valorDigitado) {
                                                        nomeController.text = valorDigitado.toUpperCase();
                                                        nomeController.selection = TextSelection.collapsed(offset: nomeController.text.length);
                                                        validarNome(valorDigitado,);
                                                      },
                                                      onTap: () {
                                                        setState(() {
                                                          _showKeyboardNome = false;
                                                          mostrarBotoes = false;
                                                          _showKeyboardMaior = true;
                                                        });
                                                      },
                                                      decoration: InputDecoration(
                                                        labelText: 'Nome',
                                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10,),
                                                        ),
                                                        fillColor: nomeController.text.isNotEmpty ? colorScheme.primary.withOpacity(0.5) : colorScheme.surface.withOpacity(0.5),  
                                                        filled: true,
                                                        contentPadding: EdgeInsets.symmetric(vertical: 15,horizontal: 10,),                                                        
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                              if (telefoneValidoTel)
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    bottom: 12.0,
                                                  ),
                                                  child: _buildWithKeyboardActions(
                                                    focusNode: cpfnoTelefoneFocusNode,
                                                    child: TextFormField(
                                                      controller: cpfControllerNoTelefone,
                                                      readOnly: false,
                                                      showCursor: true,
                                                      cursorColor: Theme.of(context).colorScheme.primary,
                                                      focusNode: cpfnoTelefoneFocusNode,
                                                      keyboardType: TextInputType.number,
                                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly,],
                                                      textAlign: TextAlign.center,
                                                      onChanged: (valorDigitado) => validarCPFnoNumero(valorDigitado),
                                                      onTap: () {
                                                        setState(() {
                                                          _showKeyboardMaior = false;
                                                          mostrarBotoes = true;
                                                          _showKeyboardNome = true;
                                                          _campoAtivo = 'cpfTelefone';
                                                        });
                                                        Future.delayed(Duration(milliseconds: 300), () {
                                                          if (!mounted) return;
                                                          _scrollToField(numeroFocusNode);
                                                          },
                                                        );
                                                      },
                                                      decoration: InputDecoration(
                                                        labelText: 'CPF',
                                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),),
                                                        fillColor: cpfValidoNumero ? colorScheme.primary.withOpacity(0.5) : colorScheme.surface.withOpacity(0.5),
                                                        filled: true,
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                              if (telefoneValidoTel)
                                                // O Padding externo garante um espaçamento consistente
                                                Padding(
                                                  padding: EdgeInsets.only(bottom: 12.0,),
                                                  child: Row(
                                                    children: listaSexo.map((
                                                      sexo,
                                                    ) {
                                                      // Envolva o RadioListTile em Flexible para restringir o tamanho
                                                      return Flexible(
                                                        child: Center(
                                                          child: RadioListTile<String>(
                                                            title: Text(
                                                              sexo,
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                            value: sexo,
                                                            groupValue: sexoSelecionado,
                                                            onChanged: (value) {
                                                              setState(() {
                                                                sexoSelecionado = value;
                                                                radioPreenchido = true;
                                                                validaDadosCliente();
                                                                passarSexoSelecionado(sexoSelecionado.toString());
                                                              });
                                                            },
                                                            contentPadding: EdgeInsets.zero,
                                                            dense: true,
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),

                                              if (telefoneValidoTel)
                                                Padding(
                                                  padding: EdgeInsets.only(bottom: 12.0,),
                                                  child: _buildWithKeyboardActions(
                                                    focusNode: nascimentoFocusNode,
                                                    child: TextFormField(
                                                      controller: dataNascimentoController,
                                                      readOnly: false,
                                                      showCursor: true,
                                                      cursorColor: Theme.of(context).colorScheme.primary,
                                                      // keyboardType: TextInputType.none, // garante que o teclado não abra
                                                      textInputAction: TextInputAction.next, // Mostra o botão "Próximo"
                                                      onFieldSubmitted: (_) {
                                                        FocusScope.of(context).requestFocus(comandaFocusNode);
                                                      },
                                                      keyboardType: TextInputType.number,
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter.digitsOnly,
                                                        DateInputFormatter(),
                                                      ],
                                                      textAlign: TextAlign.center,
                                                      onChanged: (valorDigitado) => validarNascimento(valorDigitado),
                                                      onTap: () {
                                                        setState(() {
                                                          _showKeyboardNome = true;
                                                          mostrarBotoes = true;
                                                          _campoAtivo = 'nascimento';
                                                          _showKeyboardMaior = false;
                                                          // _toggleKeyboardMaior(false);
                                                        });
                                                        Future.delayed(
                                                          Duration(milliseconds: 300,),
                                                          () {
                                                            if (!mounted) {return;}
                                                            _scrollToField(nascimentoFocusNode);
                                                          },
                                                        );
                                                      },
                                                      decoration: InputDecoration(
                                                        labelText: 'Data de aniversário',
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(10,),
                                                        ),
                                                        fillColor: dataCorreta
                                                            ? colorScheme.primary.withOpacity(0.5)
                                                            : colorScheme.surface.withOpacity(0.5),
                                                        filled: true,
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                              // #region REGIÃO COMANDA
                                              if (botaoCpf ? inserirComanda && cpfValido: inserirComanda && telefoneValidoTel)
                                              // if (inserirComanda && (botaoCpf ? cpfValido : telefoneValidoTel))
                                                Padding(
                                                  padding: EdgeInsets.only(bottom: 12.0,),
                                                  child: Stack(
                                                    alignment: Alignment.centerRight,
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          showModalBottomSheet<String>(
                                                            context: context,
                                                            builder: (ctx) {
                                                              return SafeArea(
                                                                child: ListView.separated(
                                                                  shrinkWrap: true,
                                                                  itemCount: adicionais.length,
                                                                  separatorBuilder: (_, __) => Divider(height: 1,),
                                                                  itemBuilder: (context, index) {
                                                                        final item = adicionais[index];
                                                                        final nome = item['nome'] ?? ''; item['nome'] ?? '';
                                                                        return ListTile(
                                                                          title: Text(nome),
                                                                          onTap: () {
                                                                            Navigator.of(context).pop(nome);
                                                                          },
                                                                        );
                                                                      },
                                                                ),
                                                              );
                                                            },
                                                          ).then((selected) {
                                                            if (selected != null) {
                                                              final itemSelecionado = adicionais.firstWhere(
                                                                  (it) => it['nome'] == selected,
                                                                  orElse: () => {},
                                                                );
                                                              final numero = int.tryParse(itemSelecionado['numero'].toString(),) ?? 0;
                                                              setState(() {
                                                                adicionalController.text = selected;
                                                                couvert = numero;
                                                              });
                                                            }
                                                          });
                                                        },
                                                        child: AbsorbPointer(
                                                          child: _buildWithKeyboardActions(
                                                            focusNode: adicionalFocusNode,
                                                            child: TextFormField(
                                                              controller: adicionalController,
                                                              readOnly: false,
                                                              showCursor: true,
                                                              cursorColor: Theme.of(context,).colorScheme.primary,
                                                              keyboardType: TextInputType.none,
                                                              textAlign: TextAlign.center,
                                                              decoration: InputDecoration(
                                                                labelText: 'Adicional',
                                                                border: OutlineInputBorder(
                                                                  borderRadius: BorderRadius.circular(10,),
                                                                ),
                                                                contentPadding: EdgeInsets.symmetric(
                                                                  horizontal: 12,
                                                                  vertical: 14,
                                                                ),
                                                                enabledBorder: OutlineInputBorder(
                                                                  borderRadius: BorderRadius.circular(10,),
                                                                  borderSide: BorderSide(
                                                                    color: colorScheme.onSecondary.withOpacity(0.6),
                                                                    width: 1,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              if (botaoCpf? inserirComanda && cpfValido: inserirComanda && telefoneValidoTel)
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    // Campo COMANDA ajustável
                                                    Expanded(
                                                      child: Padding(
                                                        padding: EdgeInsets.only(bottom: 12.0,), 
                                                        child: _buildWithKeyboardActions(
                                                          focusNode: comandaFocusNode,
                                                          child: TextFormField(
                                                            controller: comandaController,
                                                            readOnly: false,
                                                            showCursor: true, // FORÇA o cursor piscando
                                                            cursorColor: Theme.of(context,).colorScheme.primary,
                                                            keyboardType: TextInputType.number, 
                                                            focusNode: comandaFocusNode,
                                                            textAlign: TextAlign.center,
                                                            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                                                            onTap: () {
                                                              setState(() {
                                                                _showKeyboardNome = true;
                                                                mostrarBotoes = true;
                                                                _campoAtivo = 'comanda';
                                                                textoComanda = comandaController.text;
                                                                _showKeyboardMaior = false;
                                                              });
                                                              if (!mounted) return;
                                                              Future.delayed(Duration(milliseconds: 300),
                                                                () => _scrollToField(comandaFocusNode),
                                                              );
                                                            },
                                                            decoration: InputDecoration(
                                                              labelText: 'Comanda',
                                                              border: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(10,),
                                                              ),
                                                              fillColor: corComanda
                                                                  ? colorScheme.error.withOpacity(0.5,)
                                                                  : colorScheme.surface.withOpacity(0.5),
                                                              contentPadding: EdgeInsets.symmetric(vertical: 30, horizontal: 16,),
                                                              filled: true,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                    Padding(
                                                      padding: EdgeInsets.only(bottom: 12.0, right: 12.0, left: 12.0,),
                                                      child: IconButton(
                                                        icon: Icon(Icons.check, size: 38, color: Theme.of(context).colorScheme.onTertiary,),
                                                        onPressed: () async {
                                                          if (isProcessing) return;

                                                          if (!cliqueiRecepcao) {
                                                            cliqueiRecepcao = true;
                                                          } else { return; }

                                                          setState(() {
                                                            isProcessing = true;
                                                          });

                                                          setState(() {
                                                            isLoading2 = true;
                                                            comanda = comandaController.text;
                                                            nomeCliente = nomeController.text;
                                                            cpfCliente = botaoCpf
                                                                ? cpfControllerNoCpf.text
                                                                : cpfControllerNoTelefone.text;
                                                            datanascimentoCliente = dataNascimentoController.text;
                                                            telefoneCliente = numeroController.text.isNotEmpty
                                                                ? numeroController.text
                                                                : numeroControllerTelefone.text;
                                                          });

                                                          // requer apenas cpf
                                                          if (botaoCpf) {
                                                            if (nomeController.text.isEmpty) {
                                                              ScaffoldMessenger.of(context,).showSnackBar(
                                                                SnackBar(
                                                                  content: Text('Por favor, preencha o nome antes de salvar.'),
                                                                  backgroundColor: colorScheme.error,
                                                                ),
                                                              );
                                                              setState(() {
                                                                _campoAtivo = 'nome';
                                                                FocusScope.of(context,).requestFocus(nomeFocusNode,);
                                                                _showKeyboardMaior = true;
                                                                mostrarBotoes = true;
                                                                isLoading2 = false;
                                                                isProcessing = false;
                                                                cliqueiRecepcao = false;
                                                                if (!mounted) return;
                                                                Future.delayed(Duration(milliseconds: 300,),
                                                                  () {
                                                                    _scrollToField(
                                                                      nomeFocusNode,
                                                                    );
                                                                  },
                                                                );
                                                              });
                                                            } else if (!cpfValido) {
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'Por favor, preencha o cpf antes de salvar.',
                                                                  ),  
                                                                  backgroundColor: colorScheme.error,
                                                                ),
                                                              );
                                                              setState(() {
                                                                if (botaoCpf) {
                                                                  _campoAtivo = 'cpfCpf';
                                                                  FocusScope.of(context,).requestFocus(cpfnoCpfFocusNode,);
                                                                  _showKeyboardNome = true;
                                                                  mostrarBotoes = true;
                                                                  isLoading2 = false;
                                                                  isProcessing = false;
                                                                  cliqueiRecepcao = false;
                                                                  Future.delayed(
                                                                    Duration(milliseconds: 300,),
                                                                    () {
                                                                      if (!mounted) return;
                                                                      _scrollToField(cpfnoCpfFocusNode,);
                                                                    },
                                                                  );
                                                                }
                                                              });
                                                            } else if (comandaController.text.isEmpty) { 
                                                              ScaffoldMessenger.of(context,).showSnackBar(SnackBar(content: Text('Por favor, preencha o número da comanda antes de salvar.',),
                                                                  backgroundColor: colorScheme.error,));
                                                              setState(() {
                                                                _campoAtivo = 'comanda';
                                                                FocusScope.of(context,).requestFocus(comandaFocusNode,);
                                                                _showKeyboardNome = true;
                                                                mostrarBotoes = true;
                                                                isLoading2 = false;
                                                                isProcessing = false;
                                                                cliqueiRecepcao = false;
                                                                if (!mounted) return;
                                                                Future.delayed(Duration(milliseconds: 300,),() {
                                                                    _scrollToField(comandaFocusNode,
                                                                    );
                                                                  },
                                                                );
                                                              });
                                                            } else if (dataNascimentoController.text.isNotEmpty && !dataCorreta) {
                                                              ScaffoldMessenger.of(context,).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'Por favor, preencha corretamente a data de nascimento.',
                                                                  ),
                                                                  backgroundColor: colorScheme.error,
                                                                ),
                                                              );
                                                              setState(() {
                                                                _campoAtivo = 'nascimento';
                                                                FocusScope.of(context,).requestFocus(nascimentoFocusNode,);
                                                                _showKeyboardNome = true;
                                                                mostrarBotoes = true;
                                                                isLoading2 = false;
                                                                isProcessing = false;
                                                                cliqueiRecepcao = false;
                                                                if (!mounted) return;
                                                                Future.delayed(Duration(milliseconds: 300,), () {
                                                                    _scrollToField(nascimentoFocusNode,);
                                                                  },
                                                                );
                                                              });
                                                            } else {
                                                              try {
                                                                await validarComanda(comanda);
                                                                if (comandaValida) {
                                                                  showConfirmationDialog(
                                                                    context: context,
                                                                    title: "Cliente recepcinado com sucesso!!!",
                                                                    message: "Comanda: ${comanda} \n",
                                                                    icon: Icons.check_circle, 
                                                                    onConfirm: () async {
                                                                      reiniciarPagina();
                                                                    },
                                                                  );
                                                                } else {
                                                                  showConfirmationDialog(
                                                                    context: context,
                                                                    title: '${mensagem}',
                                                                    message: "Cliente: ${nomeController.text}\n Comanda: ${comandaController.text} \n",
                                                                    icon: Icons.error,
                                                                    onConfirm: () async {
                                                                      comandaController.clear();
                                                                      setState(() {
                                                                        _campoAtivo = 'comanda';
                                                                        _showKeyboardNome = true;
                                                                        mostrarBotoes = true;
                                                                      });
                                                                      // requestFocus FORA do setState
                                                                      _focusPendente = false;
                                                                      _solicitarFoco(comandaFocusNode, 'comanda');
                                                                      Future.delayed(const Duration(milliseconds: 350), () {
                                                                        if (mounted) _scrollToField(comandaFocusNode);
                                                                      });
                                                                    },
                                                                  );
                                                                }
                                                              } catch (e) {
                                                                cliqueiRecepcao = false;
                                                                showConfirmationDialog(
                                                                  context: context,
                                                                  title: 'ERRO',
                                                                  message: 'Cliente: ${nomeController.text}\n Comanda: ${comandaController.text}\n Erro na recepção!!!',
                                                                  icon: Icons.error, // você pode trocar para outro ícone
                                                                  onConfirm: () async {
                                                                    Navigator.push(
                                                                      context,
                                                                      PageRouteBuilder(
                                                                        transitionDuration: Duration.zero, // sem duração
                                                                        reverseTransitionDuration: Duration.zero, // sem duração ao voltar
                                                                        pageBuilder: (context,animation,secondaryAnimation,) => RecepcaoPage(),
                                                                        transitionsBuilder: (context,animation,secondaryAnimation,child,) {
                                                                          return child;
                                                                        },
                                                                      ),
                                                                    );
                                                                  },
                                                                );
                                                              } finally {
                                                                // sempre executa, mesmo se der erro
                                                                setState(() {
                                                                  isLoading2 = false;
                                                                  cliqueiRecepcao = false;
                                                                  isProcessing = false;
                                                                });
                                                              }
                                                            }
                                                          }

                                                          // requer apenas telefone
                                                          if (botaotelefone) {
                                                            if (dataNascimentoController.text.isNotEmpty && !dataCorreta) {
                                                              ScaffoldMessenger.of(context,).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'Por favor, preencha corretamente a data de nascimento.',
                                                                  ),
                                                                  backgroundColor: colorScheme.error,
                                                                ),
                                                              );
                                                              setState(() {
                                                                _campoAtivo = 'nascimento';
                                                                FocusScope.of(context,).requestFocus(nascimentoFocusNode,);
                                                                _showKeyboardNome = true;
                                                                mostrarBotoes = true;
                                                                isLoading2 = false;
                                                                isProcessing = false;
                                                                cliqueiRecepcao = false;
                                                                if (!mounted) return;
                                                                Future.delayed(Duration(milliseconds: 300,), () {
                                                                  _scrollToField(nascimentoFocusNode,);
                                                                });
                                                              });
                                                            }
                                                            if (nomeController.text.isEmpty) {
                                                              ScaffoldMessenger.of(context,).showSnackBar(
                                                                SnackBar(
                                                                  content: Text('Por favor, preencha o nome antes de salvar.',),
                                                                  backgroundColor: colorScheme.error,
                                                                ),
                                                              );
                                                              setState(() {
                                                                _campoAtivo = 'nome';
                                                                FocusScope.of(context,).requestFocus(nomeFocusNode,);
                                                                _showKeyboardNome = true;
                                                                mostrarBotoes = true;
                                                                isLoading2 = false;
                                                                isProcessing = false;
                                                                cliqueiRecepcao = false;
                                                                Future.delayed(Duration(milliseconds: 300,), () {
                                                                  if (!mounted) return;
                                                                  _scrollToField(nomeFocusNode,);
                                                                },);
                                                              }); 
                                                            } else if (!telefoneValidoTel) {
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'Por favor, preencha o número de telefone antes de salvar.',
                                                                  ),
                                                                  backgroundColor:
                                                                      colorScheme
                                                                          .error,
                                                                ),
                                                              );
                                                              setState(() {
                                                                _campoAtivo =
                                                                    'numeroTelefone';
                                                                FocusScope.of(
                                                                  context,
                                                                ).requestFocus(
                                                                  numeroTelefoneFocusNode,
                                                                );
                                                                _showKeyboardNome =
                                                                    true;
                                                                mostrarBotoes =
                                                                    true;
                                                                isLoading2 =
                                                                    false;
                                                                isProcessing =
                                                                    false;
                                                                cliqueiRecepcao =
                                                                    false;
                                                                Future.delayed(
                                                                  Duration(
                                                                    milliseconds:
                                                                        300,
                                                                  ),
                                                                  () {
                                                                    if (!mounted)
                                                                      return;
                                                                    _scrollToField(
                                                                      numeroTelefoneFocusNode,
                                                                    );
                                                                  },
                                                                );
                                                              });
                                                            } else if (comandaController
                                                                .text
                                                                .isEmpty) {
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'Por favor, preencha o número da comanda antes de salvar.',
                                                                  ),
                                                                  backgroundColor:
                                                                      colorScheme
                                                                          .error,
                                                                ),
                                                              );
                                                              setState(() {
                                                                comandaController
                                                                    .clear();
                                                                _campoAtivo =
                                                                    'comanda';
                                                                FocusScope.of(
                                                                  context,
                                                                ).requestFocus(
                                                                  comandaFocusNode,
                                                                );
                                                                _showKeyboardNome =
                                                                    true;
                                                                mostrarBotoes =
                                                                    true;
                                                                isLoading2 =
                                                                    false;
                                                                isProcessing =
                                                                    false;
                                                                cliqueiRecepcao =
                                                                    false;
                                                                if (!mounted)
                                                                  return;
                                                                Future.delayed(
                                                                  Duration(
                                                                    milliseconds:
                                                                        300,
                                                                  ),
                                                                  () {
                                                                    _scrollToField(
                                                                      comandaFocusNode,
                                                                    );
                                                                  },
                                                                );
                                                              });
                                                            } else if (dataNascimentoController
                                                                    .text
                                                                    .isNotEmpty &&
                                                                !dataCorreta) {
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'Por favor, preencha corretamente a data de nascimento.',
                                                                  ),
                                                                  backgroundColor:
                                                                      colorScheme
                                                                          .error,
                                                                ),
                                                              );
                                                              setState(() {
                                                                _campoAtivo =
                                                                    'nascimento';
                                                                FocusScope.of(
                                                                  context,
                                                                ).requestFocus(
                                                                  nascimentoFocusNode,
                                                                );
                                                                _showKeyboardNome =
                                                                    true;
                                                                mostrarBotoes =
                                                                    true;
                                                                isLoading2 =
                                                                    false;
                                                                isProcessing =
                                                                    false;
                                                                cliqueiRecepcao =
                                                                    false;
                                                                if (!mounted)
                                                                  return;
                                                                Future.delayed(
                                                                  Duration(
                                                                    milliseconds:
                                                                        300,
                                                                  ),
                                                                  () {
                                                                    _scrollToField(
                                                                      nascimentoFocusNode,
                                                                    );
                                                                  },
                                                                );
                                                              });
                                                            } else {
                                                              try {
                                                                await validarComanda(
                                                                  comanda,
                                                                );
                                                                if (comandaValida) {
                                                                  showConfirmationDialog(
                                                                    context: context,
                                                                    title:"Cliente recepcinado com sucesso!!!",
                                                                    message: "Comanda: ${comanda} \n",
                                                                    icon: 
                                                                    // icone ? 
                                                                    Icons.check_circle,
                                                                    // : Icons.error, // você pode trocar para outro ícone
                                                                    onConfirm: () async {
                                                                      reiniciarPagina();
                                                                      /* setState(() {
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
                                                                                  return child;
                                                                                },
                                                                          ),
                                                                        );
                                                                      }); */
                                                                    },
                                                                  );
                                                                } else {
                                                                  showConfirmationDialog(
                                                                    context: context,
                                                                    title:
                                                                        '${mensagem}',
                                                                    message:
                                                                        "Cliente: ${nomeController.text}\n Comanda: ${comandaController.text} \n",
                                                                    icon: Icons.error,
                                                                    onConfirm: () async {
                                                                      comandaController.clear();
                                                                      setState(() {
                                                                        _campoAtivo = 'comanda';
                                                                        _showKeyboardNome = true;
                                                                        mostrarBotoes = true;
                                                                      });
                                                                      // requestFocus FORA do setState
                                                                      _focusPendente = false;
                                                                      _solicitarFoco(comandaFocusNode, 'comanda');
                                                                      Future.delayed(const Duration(milliseconds: 350), () {
                                                                        if (mounted) _scrollToField(comandaFocusNode);
                                                                      });
                                                                    },
                                                                  );
                                                                }
                                                              } catch (e) {
                                                                showConfirmationDialog(
                                                                  context:
                                                                      context,
                                                                  title: 'ERRO',
                                                                  message:
                                                                      'Cliente: ${nomeController.text}\n Comanda: ${comandaController.text}\n Erro na recepção!!!',
                                                                  icon: Icons
                                                                      .error, // você pode trocar para outro ícone
                                                                  onConfirm: () async {
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
                                                                            ) =>
                                                                                RecepcaoPage(),
                                                                        transitionsBuilder:
                                                                            (
                                                                              context,
                                                                              animation,
                                                                              secondaryAnimation,
                                                                              child,
                                                                            ) {
                                                                              return child;
                                                                            },
                                                                      ),
                                                                    );
                                                                  },
                                                                );
                                                              } finally {
                                                                // sempre executa, mesmo se der erro
                                                                setState(() {
                                                                  isLoading2 =
                                                                      false;
                                                                  isProcessing =
                                                                      false;
                                                                  cliqueiRecepcao =
                                                                      false;
                                                                });
                                                              }
                                                            }
                                                          }

                                                          if (mounted) {
                                                            setState(() {
                                                              isProcessing =
                                                                  false;
                                                              cliqueiRecepcao =
                                                                  false;
                                                              isLoading2 =
                                                                  false;
                                                            });
                                                          }
                                                        },
                                                        style: IconButton.styleFrom(
                                                          backgroundColor:
                                                              comandaController
                                                                  .text
                                                                  .isNotEmpty
                                                              ? isProcessing
                                                                    ? Theme.of(
                                                                        context,
                                                                      ).colorScheme.surfaceDim
                                                                    : Theme.of(
                                                                        context,
                                                                      ).colorScheme.scrim
                                                              : Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .surfaceDim,
                                                          padding: EdgeInsets.all(
                                                            22,
                                                          ), // Ajuste este valor
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
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
                                  ),
                                  //////
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // APARECER BOTÕES
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: colorScheme.surface,
                child: Column(
                  mainAxisSize: MainAxisSize
                      .min, // importante para não ocupar a tela toda
                  children: [
                    // if(mostrarBotoes)
                    Padding(
                      padding: footerButtonsController.aparecerNote.value
                          ? EdgeInsets.only(top: 5, bottom: 10, left: 10, right: 10,)
                          : EdgeInsets.only(top: 5, bottom: 10, left: 15, right: 15,),
                      child: SizedBox(width: double.infinity),
                    ),

                    // Barra inferior com botões quadrados
                    Container(
                      color: colorScheme.surface,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.14,
                        child:
                            // Barra inferior com botões quadrados
                            Padding(
                              padding: footerButtonsController.aparecerNote.value
                                  ? EdgeInsets.only(top: 5.0, bottom: 15.0, left: 10.0, right: 10.0,)
                                  : EdgeInsets.only(top: 5.0, bottom: 15.0, left: 15.0, right: 15.0,),
                              child: Row(
                                children: [
                                  // Botão Check In
                                  if (footerButtonsController.aparecerCheckIn.value)
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4.0,
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                transitionDuration: Duration.zero, // sem duração
                                                reverseTransitionDuration: Duration.zero, // sem duração ao voltar
                                                pageBuilder: (context, animation, secondaryAnimation) => CheckinPage(),
                                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                    return child; // retorna direto, sem animação
                                                },
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                          child: Container(
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.login,
                                                    size: 30,
                                                    color:
                                                        colorScheme.onPrimary,
                                                  ),
                                                  SizedBox(height: 4),
                                                  FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      'Check In',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: colorScheme
                                                            .onPrimary,
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
                                  if (footerButtonsController.aparecerCheckOut.value)
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4.0,
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                transitionDuration: Duration.zero, // sem duração
                                                reverseTransitionDuration: Duration.zero, // sem duração ao voltar
                                                pageBuilder: (context, animation, secondaryAnimation) => CheckoutPage(),
                                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                    return child; // retorna direto, sem animação
                                                },
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                          child: Container(
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: colorScheme.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.logout,
                                                    size: 30,
                                                    color:
                                                        colorScheme.onPrimary,
                                                  ),
                                                  SizedBox(height: 4),
                                                  FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      'Check Out',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: colorScheme
                                                            .onPrimary,
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
                                  if (footerButtonsController.aparecerNote.value)
                                    // Botão Notes
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4.0,
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                transitionDuration: Duration.zero, // sem duração
                                                reverseTransitionDuration: Duration.zero, // sem duração ao voltar
                                                pageBuilder: (context, animation, secondaryAnimation) => NotesPage(),
                                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                    return child; // retorna direto, sem animação
                                                },
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                          child: Container(
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: colorScheme.shadow,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.note_add_sharp,
                                                    size: 30,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(height: 4),
                                                  FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      'Notes',
                                                      textAlign:
                                                          TextAlign.center,
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
                                  if (footerButtonsController.aparecerRecepcao.value)
                                    // Botão Recepção
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4.0,
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                transitionDuration: Duration.zero,
                                                reverseTransitionDuration: Duration.zero,
                                                pageBuilder: (context, animation, secondaryAnimation) => RecepcaoPage(),
                                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                    return child;
                                                },
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                          child: Container(
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary,
                                              borderRadius:
                                                  BorderRadius.circular(3),
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
                                                      textAlign:
                                                          TextAlign.center,
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
                                  // if( aparecerCheckInOut || !naoAparecerMapa)
                                  // SizedBox(width: 8),
                                  if (footerButtonsController.aparecerMapa.value)
                                    // Botão Mapa de Mesas
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4.0,
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                transitionDuration:
                                                    Duration.zero,
                                                reverseTransitionDuration:
                                                    Duration.zero,
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
                                                      return child;
                                                    },
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                          child: Container(
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: colorScheme.scrim,
                                              borderRadius:
                                                  BorderRadius.circular(3),
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
                                                      textAlign:
                                                          TextAlign.center,
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
                                  // if(aparecerGarcom)
                                  // SizedBox(width: 8),
                                  if (footerButtonsController.aparecerGarcom.value)
                                    // Botão Garçom
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4.0,
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            Get.toNamed('/garcom');
                                          },
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                          child: Container(
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: colorScheme.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(3),
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
                                                      textAlign:
                                                          TextAlign.center,
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
    );
  }
}

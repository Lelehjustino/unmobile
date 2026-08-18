import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:un_recepcao/controllers/views/funcoes_controller.dart';
import 'package:un_recepcao/controllers/views/painel_controller.dart';
import 'package:un_recepcao/data/data_class.dart';
import 'package:un_recepcao/views/checkin_page.dart';
import 'package:un_recepcao/views/mapa_page.dart';
import 'package:un_recepcao/views/notes_page.dart';
import 'package:un_recepcao/views/recepcao_page.dart';
import 'package:un_recepcao/widgets/side_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => CheckoutPageState();
}

class CheckoutPageState extends State<CheckoutPage>
    with SingleTickerProviderStateMixin {

  String versaoAplicacao = FuncoesController().versaoDoApp;
  final FuncoesController funcoesController = Get.find<FuncoesController>();
  
  final TextEditingController comandaController = TextEditingController();
  final FocusNode comandaFocus = FocusNode();
  String? _mensagem;

  late Timer _timer;
  String _horaAtual = '';
  String nomeEmpresa = '';

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

  bool servidorConectado = true;

  bool corMensagem = true;

  bool aparecerNote = false;

  List<dynamic> validaComanda = [];
  String mensagem = 'Insira o número da comanda';
  bool iconeMensagem = true;

  // Contraladores da animação
  late AnimationController animationController;
  late Animation<double> scaleAnimation;
  bool animacaoCerto = true;
  bool animacaoAparecer = false;
  bool aparecerCheckInOut = false;
  bool aparecerRecepcao = false;
  bool naoAparecerMapa = true;
  bool aparecerCheckIn = false;
  bool aparecerCheckOut = false;
  bool aparecerGarcom = true;

  StreamSubscription? _conexaoSubscription;

  // final variaveis = Get.find<VariaveisController>();

  final painelController = Get.put(PainelController());

  bool cliqueiCheck = false;

  @override
  void initState() {
    super.initState();

    painelController.estaNoPainelCozinha.value = false;

    // Inicializa o controller da animação
    animationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
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
      });
    });
    _carregarModo();
    _carregarNote();
    _carregarModos();
    _carregarRecepcao();
    _carregarchecks();
    _carregargarcom();
    _loadNomeEmpresa();

    Future.delayed(Duration(milliseconds: 300), () {
      if (comandaFocus.canRequestFocus) {
        comandaFocus.requestFocus();
      }
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

  // VERSÃO CORRIGIDA (mais simples)
  void animacao() {
    animationController.forward(from: 0.0);
  }

  // Adicione esta nova função na sua classe State
  void _dispararAnimacaoDeResultado(bool sucesso) {
    // 1. Define o estado para mostrar a animação correta (sucesso ou erro)
    setState(() {
      animacaoAparecer = true;
      animacaoCerto = sucesso;
    });

    // 2. Inicia a animação visual (o efeito de "elasticOut")
    animationController.forward(from: 0.0);

    // 3. Agenda a animação para sumir após 3 segundos
    Future.delayed(Duration(seconds: 2), () {
      // Verifica se o widget ainda está na tela para evitar erros
      if (mounted) {
        setState(() {
          animacaoAparecer = false; // Faz a animação sumir
          comandaController.clear(); // Limpa o campo de texto
        });
        // Devolve o foco para o campo de texto
        FocusScope.of(context).requestFocus(comandaFocus);
      }
    });
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

  // Carregar modo
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
  } */

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

  // Função para fazer check in
  Future<void> validarComanda(String numeroComanda) async {
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
          corMensagem = false;
          iconeMensagem = false;
          animacaoCerto = false;
          _dispararAnimacaoDeResultado(false);
        });
        return;
      }
      Map<String, dynamic> comanda = lista[0];

      // Exemplo de validações:
      if (comanda['ativo'] == 0) {
        setState(() {
          mensagem = "Comanda inativa!";
          corMensagem = false;
          iconeMensagem = false;
          animacaoCerto = false;
          _dispararAnimacaoDeResultado(false);
        });
      } else if (comanda['bloqueada'] == 1) {
        setState(() {
          mensagem = "Comanda bloqueada!";
          corMensagem = false;
          iconeMensagem = false;
          animacaoCerto = false;
          _dispararAnimacaoDeResultado(false);
        });
      } else if (comanda['numeropedido_FK'] != '0') {
        setState(() {
          mensagem = "A comanda $numeroComanda ainda não foi finalizada!";
          corMensagem = false;
          iconeMensagem = false;
          animacaoCerto = false;
          _dispararAnimacaoDeResultado(false);
        });
      } else if (comanda['numero'] == null) {
        setState(() {
          mensagem = "Comanda inexistente";
          corMensagem = false;
          iconeMensagem = false;
          animacaoCerto = false;
          _dispararAnimacaoDeResultado(false);
        });
      } else if (comanda['numeropedido_FK'] == '0') {
        setState(() {
          mensagem = "Comanda $numeroComanda liberada!!!";
          corMensagem = true;
          animacaoCerto = true;
          iconeMensagem = true;
          _dispararAnimacaoDeResultado(true);
        });
      } else {
        print("Comanda válida para check-out");
        try {
          setState(() {
            mensagem = "Comanda fechada com sucesso!!!";
            corMensagem = true;
            animacaoCerto = true;
            iconeMensagem = true;
            _dispararAnimacaoDeResultado(true);
          });
        } catch (e) {
          print('Nao foi possivel fechar comanda $e');
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

  void _atualizarHora() {
    final agora = DateTime.now();
    final horaFormatada = DateFormat.Hm().format(agora);
    setState(() {
      _horaAtual = horaFormatada;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _conexaoSubscription?.cancel();
    comandaFocus.dispose();
    comandaController.dispose();
    super.dispose();
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
        // _isLoading = false; // Também para o loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool conectado = Connection.connectionStatus.value;
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
      // return Scaffold(
      // drawer: SideNav(),
      // appBar: PreferredSize(
      //   preferredSize: Size.fromHeight(56),
      //   child:
      //   Obx(() {
      //     final conectado = Connection.connectionStatus.value;
      //     return AppBar(
      //       backgroundColor: Connection.connectionStatus.value ? colorScheme.primary : colorScheme.error,
      //       automaticallyImplyLeading: false,
      //       title: Stack(
      //         alignment: Alignment.center,
      //         children: [
      //           Align(
      //             alignment: Alignment.centerLeft,
      //             child: Builder(
      //               builder: (context) => IconButton(
      //                 icon: Icon(Icons.menu, color: colorScheme.onPrimary),
      //                 onPressed: () => Scaffold.of(context).openDrawer(),
      //               ),
      //             ),
      //           ),
      //           Padding(
      //             padding: EdgeInsets.all(5.0),
      //             child: Column(
      //               mainAxisAlignment: MainAxisAlignment.center,
      //               children: [
      //                 Obx(() => Text(
      //                       variaveis.nomeEmpresa.value,
      //                       style: TextStyle(
      //                         fontSize: 15,
      //                         fontWeight: FontWeight.bold,
      //                         color: colorScheme.onPrimary,
      //                       ),
      //                     )),
      //                 Text(
      //                   _horaAtual,
      //                   style: TextStyle(
      //                     color: colorScheme.onPrimary,
      //                     fontSize: 15,
      //                   ),
      //                 ),
      //               ],
      //             ),
      //           ),
      //           Align(
      //             alignment: Alignment.centerRight,
      //             child: Text(
      //               Connection.connectionStatus.value ? 'Online' : 'Offline',
      //               style: TextStyle(
      //                 color: colorScheme.onPrimary,
      //                 fontSize: 15,
      //                 fontWeight: FontWeight.bold,
      //               ),
      //             ),
      //           ),
      //         ],
      //       ),
      //     );
      //   }),
      // ),

      // Corpo da tela
      body: Padding(
        padding: EdgeInsets.all(0.0),
        child: Column(
          children: [
            SizedBox(height: 10),
            // Ícone de usuário
            Icon(Icons.logout, size: 50, color: colorScheme.secondary),
            Text(
              'Check Out',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, color: colorScheme.secondary),
            ),
            SizedBox(height: 0),

            // TextField número da comanda
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
                                          : Theme.of(context).colorScheme.error)
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
                                ).colorScheme.secondary,
                                keyboardType: TextInputType
                                    .none, // garante que o teclado não abr
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor:
                                      // _isFocused? colorScheme.primary.withOpacity(0.15)
                                      //   :
                                      animacaoCerto
                                      ? colorScheme.primary.withOpacity(0.15)
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
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                color: corMensagem ? colorScheme.secondary : colorScheme.error,
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

                  // mantém proporção quadrada
                  final double cellWidth =
                      (constraints.maxWidth -
                          (spacing * (crossAxisCount - 1))) /
                      crossAxisCount;
                  final double cellHeight =
                      (constraints.maxHeight - (spacing * (rows - 1))) / rows;
                  final double childAspectRatio = cellWidth / cellHeight;

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
                            padding: EdgeInsets.zero, // Remove o padding fixo
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
                            padding: EdgeInsets.zero, // Remove o padding fixo
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: const Text(
                              "0",
                              style: TextStyle(fontSize: 28), // número maior
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
                            padding: EdgeInsets.zero, // Remove o padding fixo
                            backgroundColor: colorScheme.primary,
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
                            padding: EdgeInsets.zero, // Remove o padding fixo
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
                                    (context, animation, secondaryAnimation) =>
                                        CheckinPage(),
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

                  // if (aparecerCheckOut) SizedBox(width: 8),

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
                                    (context, animation, secondaryAnimation) =>
                                        CheckoutPage(),
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
                                    (context, animation, secondaryAnimation) =>
                                        NotesPage(),
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
                                    (context, animation, secondaryAnimation) =>
                                        RecepcaoPage(),
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
                                    (context, animation, secondaryAnimation) =>
                                        MapaPage(),
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
                                      'Atendente',
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
                ],
              ),
            ),
            // Padding(
            //   padding: aparecerNote ? EdgeInsets.only(top: 5.0, bottom: 15.0,left: 10.0,right: 10.0,) : EdgeInsets.only(top: 5.0, bottom: 15.0, left: 15.0, right: 15.0),
            //   child: Row(
            //     children: [
            //       // Botão Check In
            //       if(aparecerCheckInOut)
            //       Expanded(
            //         child: InkWell(
            //           onTap: () {
            //             Navigator.push(
            //               context,
            //               PageRouteBuilder(
            //                 transitionDuration: Duration.zero, // sem duração
            //                 reverseTransitionDuration: Duration.zero, // sem duração ao voltar
            //                 pageBuilder: (context, animation, secondaryAnimation,) => CheckinPage(),
            //                 transitionsBuilder:(context, animation, secondaryAnimation, child,) {
            //                   return child; // retorna direto, sem animação
            //                 },
            //               ),
            //             );
            //           },
            //           borderRadius: BorderRadius.circular(3),
            //           child: Container(
            //             height: 80,
            //             decoration: BoxDecoration(
            //               color: colorScheme.primary,
            //               borderRadius: BorderRadius.circular(3),
            //             ),
            //             child: Center(
            //               child: Column(
            //                 mainAxisSize: MainAxisSize.min,
            //                 children: [
            //                   Icon(
            //                     Icons.login,
            //                     size: 30,
            //                     color: colorScheme.onPrimary,
            //                   ),
            //                   SizedBox(height: 4),
            //                   Text(
            //                     'Check In',
            //                     style: TextStyle(
            //                       fontSize: 12,
            //                       color: colorScheme.onPrimary,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ),
            //         ),
            //       ),

            //       SizedBox(width: 8),

            //       // Botão Check Out
            //       if(aparecerCheckInOut)
            //       Expanded(
            //         child: InkWell(
            //           onTap: () {
            //             Navigator.push(
            //               context,
            //               PageRouteBuilder(
            //                 transitionDuration: Duration.zero, // sem duração
            //                 reverseTransitionDuration: Duration.zero, // sem duração ao voltar
            //                 pageBuilder: (context, animation, secondaryAnimation,) => CheckoutPage(),
            //                 transitionsBuilder: (context, animation, secondaryAnimation, child,) {
            //                   return child; // retorna direto, sem animação
            //                 },
            //               ),
            //             );
            //           },
            //           borderRadius: BorderRadius.circular(3),
            //           child: Container(
            //             height: 80,
            //             decoration: BoxDecoration(
            //               color: colorScheme.secondary,
            //               borderRadius: BorderRadius.circular(3),
            //             ),
            //             child: Center(
            //               child: Column(
            //                 mainAxisSize: MainAxisSize.min,
            //                 children: [
            //                   Icon(
            //                     Icons.logout,
            //                     size: 30,
            //                     color: Colors.white,
            //                   ),
            //                   SizedBox(height: 4),
            //                   Text(
            //                     'Check Out',
            //                     style: TextStyle(
            //                       fontSize: 12,
            //                       color: Colors.white,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ),
            //         ),
            //       ),

            //       if(aparecerCheckInOut)
            //       SizedBox(width: 8),

            //       // Botão Mapa de Mesas
            //       Expanded(
            //         child: InkWell(
            //           onTap: () {
            //             Navigator.push(
            //               context,
            //               PageRouteBuilder(
            //                 transitionDuration: Duration.zero, // sem duração
            //                 reverseTransitionDuration: Duration.zero, // sem duração ao voltar
            //                 pageBuilder:(context, animation, secondaryAnimation,) => MapaPage(),
            //                 transitionsBuilder: (context, animation, secondaryAnimation,child,) {
            //                   return child; // retorna direto, sem animação
            //                 },
            //               ),
            //             );
            //           },
            //           borderRadius: BorderRadius.circular(3),
            //           child: Container(
            //             height: 80,
            //             decoration: BoxDecoration(
            //               color: colorScheme.scrim,
            //               borderRadius: BorderRadius.circular(3),
            //             ),
            //             child: Center(
            //               child: Column(
            //                 mainAxisSize: MainAxisSize.min,
            //                 children: [
            //                   Icon(
            //                     // Icons.table_restaurant,
            //                     Icons.map,
            //                     size: 30,
            //                     color: Colors.white,
            //                   ),
            //                   SizedBox(height: 4),
            //                   Text(
            //                     'Mapa',
            //                     textAlign: TextAlign.center,
            //                     style: TextStyle(
            //                       fontSize: 12,
            //                       color: Colors.white,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ),
            //         ),
            //       ),
            //       if(aparecerNote)
            //       SizedBox(width: 8),

            //       if(aparecerNote)
            //       // Botão Mapa de Notes
            //       Expanded(
            //         child: InkWell(
            //           onTap: () {
            //             Navigator.push(
            //               context,
            //               PageRouteBuilder(
            //                 transitionDuration: Duration.zero, // sem duração
            //                 reverseTransitionDuration: Duration.zero, // sem duração ao voltar
            //                 pageBuilder: (context, animation, secondaryAnimation) => NotesPage(),
            //                 transitionsBuilder: (context, animation, secondaryAnimation, child) {
            //                   return child; // retorna direto, sem animação
            //                 },
            //               ),
            //             );
            //           },
            //           borderRadius: BorderRadius.circular(3),
            //           child: Container(
            //             height: 80,
            //             decoration: BoxDecoration(
            //               color: colorScheme.shadow,
            //               borderRadius: BorderRadius.circular(3),
            //             ),
            //             child: Center(
            //               child: Column(
            //                 mainAxisSize: MainAxisSize.min,
            //                 children: [
            //                   Icon(
            //                     // Icons.table_restaurant,
            //                     Icons.note_add_sharp,
            //                     size: 30,
            //                     color: Colors.white,
            //                   ),
            //                   SizedBox(height: 4),
            //                   Text(
            //                     'Notes',
            //                     textAlign: TextAlign.center,
            //                     style: TextStyle(
            //                       fontSize: 12,
            //                       color: Colors.white,
            //                       // fontWeight: FontWeight.bold,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ),
            //         ),
            //       ),
            //       if(aparecerRecepcao)
            //       SizedBox(width: 8),
            //       if(aparecerRecepcao)
            //       // Botão Recepção
            //       Expanded(
            //         child: InkWell(
            //           onTap: () {
            //             Navigator.push(
            //               context,
            //               PageRouteBuilder(
            //                 transitionDuration: Duration.zero, // sem duração
            //                 reverseTransitionDuration: Duration.zero, // sem duração ao voltar
            //                 pageBuilder: (context, animation, secondaryAnimation) => RecepcaoPage(),
            //                 transitionsBuilder: (context, animation, secondaryAnimation, child) {
            //                   return child; // retorna direto, sem animação
            //                 },
            //               ),
            //             );
            //           },
            //           borderRadius: BorderRadius.circular(3),
            //           child: Container(
            //             height: 80,
            //             decoration: BoxDecoration(
            //               color: colorScheme.primary,
            //               borderRadius: BorderRadius.circular(3),
            //             ),
            //             child: Center(
            //               child: Column(
            //                 mainAxisSize: MainAxisSize.min,
            //                 children: [
            //                   Icon(
            //                     // Icons.table_restaurant,
            //                     Icons.person,
            //                     size: 30,
            //                     color: Colors.white,
            //                   ),
            //                   SizedBox(height: 4),
            //                   Text(
            //                     'Recepçao',
            //                     textAlign: TextAlign.center,
            //                     style: TextStyle(
            //                       fontSize: 12,
            //                       color: Colors.white,
            //                       // fontWeight: FontWeight.bold,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

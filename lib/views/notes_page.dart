import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:un_recepcao/controllers/views/footer_buttons_controller.dart';
import 'package:un_recepcao/controllers/views/funcoes_controller.dart';
import 'package:un_recepcao/controllers/views/painel_controller.dart';
import 'package:un_recepcao/data/data_class.dart';
import 'package:un_recepcao/views/checkin_page.dart';
import 'package:un_recepcao/views/checkout_page.dart';
import 'package:un_recepcao/views/mapa_page.dart';
import 'package:un_recepcao/views/recepcao_page.dart';
import 'package:un_recepcao/widgets/side_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class NotesPage extends StatefulWidget {
  NotesPage({super.key});

  @override
  State<NotesPage> createState() => NotesPageState();
}

class NotesPageState extends State<NotesPage> {

  String versaoAplicacao = FuncoesController().versaoDoApp;
  final FuncoesController funcoesController = Get.find<FuncoesController>();
  final FooterButtonsController footerButtonsController = Get.find<FooterButtonsController>();
   final painelController = Get.find<PainelController>();

  final TextEditingController nomeClienteController = TextEditingController();
  final TextEditingController quantidadeController = TextEditingController();

  final FocusNode nomeFocusNode = FocusNode();
  final FocusNode quantidadeFocusNode = FocusNode();

  late Timer _timer;
  String _horaAtual = '';
  String _horaBanco = '';
  // String nomeEmpresa = '';

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

  // Para fazer requisições em determinado tempo (1/3)
  // Timer? _timerConexao;

  List<dynamic> validaComanda = [];
  String mensagem = 'Insira o número da comanda...';

  String nomeDoCliente = '';
  String entradaDoCliente = '';
  String saidaDoCliente = '';
  String pessoasDoCliente = '';
  String statusDoCliente = '';

  List<Map<String, dynamic>> listaClientes = [];
  bool carregando = true;

  // Para fazer requisições em determinado tempo (1/3)
  Timer? _timerSelect;

  int _totalPessoas = 0;

  String nomeEmpresa = '';

  // String para formatar hora quando cehga do Banco
  String _formatHora(String dataHora) {
    try {
      // Supondo que 'dataHora' seja uma string no formato 'yyyy-MM-dd HH:mm:ss'
      DateTime entrada = DateTime.parse(dataHora);
      return DateFormat(
        'HH:mm',
      ).format(entrada); // Exibe apenas a hora e minutos
    } catch (e) {
      print('Erro ao formatar hora: $e');
      return 'Hora inválida';
    }
  }

  bool isLoading = false;
  // final variaveis = Get.find<VariaveisController>();

  RxBool tecladoAtivo = false.obs;
  bool _showKeyboard = false;

  Timer? _timerApagar;

  @override
  void initState() {
    super.initState();

    painelController.estaNoPainelCozinha.value = false;

    carregarClientes();
    _atualizarHora();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _atualizarHora();
    });

    Future.delayed(Duration(milliseconds: 300), () {
      if (nomeFocusNode.canRequestFocus) {
        nomeFocusNode.requestFocus();
      }
    });

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
    _carregarModo();
    _timerSelect = Timer.periodic(Duration(seconds: 30), (timer) {
      carregarClientes();
    });
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

  // Função que você chama para abrir/fechar o teclado
  void _toggleKeyboardMaior(bool novoValor) {
    setState(() {
      _showKeyboard = novoValor;
      // _setSystemUIVisibility(_showKeyboard);
    });
  }

  void carregarClientes() async {
    List<Map<String, dynamic>> resultado = await configuracaoClientes();
    setState(() {
      listaClientes = resultado;
      carregando = false;
    });

    // _timerSelect = Timer.periodic(Duration(milliseconds: 3500), (timer) {
    //   configuracaoClientes();
    // });

    quantidadeController.text = atual.toString();
    footerButtonsController.carregargarcom();
    quantidadeController.clear();
    quantidadeController.text = '1';
  }

  // FUNÇÃO PARA BUSCAR INFORMAÇÕES DOS CLIENTES
  Future<List<Map<String, dynamic>>> configuracaoClientes() async {
    List<Map<String, dynamic>> lista = []; // garante escopo global no método

    try {
      String dadosJson = await Connection().select(
        "SELECT nome, entrada, saida, pessoas, status, numero FROM notes WHERE status='1' ORDER BY numero DESC;",
      );

      lista = List<Map<String, dynamic>>.from(jsonDecode(dadosJson));

      // varre a lista de pessoas e soma
      int somaTotal = lista.fold<int>(0, (somaAnterior, cliente) {
        final pessoasDoCliente =
            int.tryParse(cliente['pessoas'].toString()) ?? 0;
        return somaAnterior + pessoasDoCliente;
      });

      if (lista.isNotEmpty) {
        // Pega o primeiro cliente (exemplo)
        final cliente = lista.first;

        setState(() {
          nomeDoCliente = cliente['nome'].toString();
          entradaDoCliente = cliente['entrada'].toString();
          saidaDoCliente = cliente['saida'].toString();
          pessoasDoCliente = cliente['pessoas'].toString();
          statusDoCliente = cliente['status'].toString();
          _totalPessoas = somaTotal;
        });
      } else {
        _resetarCamposCliente();
      }
    } catch (e) {
      print("Erro ao carregar configuracaoClientes: $e");
      _resetarCamposCliente();
      setState(() {
        isLoading = true;
        lista = [];
      });
    }

    return lista;
  }

  /* // Função para inserir uma nova venda
  Future<void> inserirVenda(
    String nomeClienteSalvo,
    String _horaBanco,
    String quantidadePessoasSalvo,
  ) async {
    try {
      String sql =
          """
        INSERT INTO notes (
          nome,
          entrada,
          pessoas
        ) VALUES (
          '$nomeClienteSalvo',
          '$_horaBanco',
          '$quantidadePessoasSalvo'
        )
      """;

      // Executa o SQL
      String resultado = await Connection().ipd(sql);

      print("Venda inserida com sucesso: $resultado");
    } catch (e) {
      print("Erro inesperado ao inserir venda: $e");
      setState(() {
        isLoading = true;
      });
    }
    setState(() {
      quantidadeController.clear();
      nomeClienteController.text = '';
      quantidadeController.text = '';
    });
  }
 */

// Função para inserir uma nova venda
  Future<void> inserirVenda(
    String nomeClienteSalvo,
    String _horaBanco,
    String quantidadePessoasSalvo,
  ) async {
    try {
      String sql =
          """
        INSERT INTO notes (
          nome,
          entrada,
          pessoas
        ) VALUES (
          '$nomeClienteSalvo',
          '$_horaBanco',
          '$quantidadePessoasSalvo'
        )
      """;

      // Executa o SQL
      String idNotes = await Connection().insertId(sql);

      print("Id notes retornado: $idNotes");
    } catch (e) {
      print("Erro inesperado ao inserir venda: $e");
      setState(() {
        isLoading = true;
      });
    }
    setState(() {
      quantidadeController.clear();
      nomeClienteController.text = '';
      quantidadeController.text = '';
    });
  }

  // função auxiliar para limpar os campos
  void _resetarCamposCliente() {
    setState(() {
      nomeDoCliente = "Nome";
      entradaDoCliente = "00:00";
      saidaDoCliente = "00:00";
      pessoasDoCliente = "0";
      statusDoCliente = "0";
    });
  }

  // Diálogo de confirmação
  Future<void> showConfirmationDialogSoOk({
    required BuildContext context,
    String title = 'Confirmação',
    required String message,
    IconData icon = Icons.home,
    String cancelText = 'Cancelar',
    String confirmText = 'OK',
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
                    color: Theme.of(ctx).colorScheme.shadow.withOpacity(0.08),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    icon,
                    size: 40,
                    color: Theme.of(ctx).colorScheme.shadow,
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
                        backgroundColor: Theme.of(ctx).colorScheme.shadow,
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

  Future<void> showConfirmationDialog({
    required BuildContext context,
    String title = 'Confirmação',
    required String message,
    IconData icon = Icons.help_outline,
    String cancelText = 'Cancelar',
    String confirmText = 'Confirmar',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
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
                // Título
                if (title.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      title,
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Ícone
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(ctx).colorScheme.shadow.withOpacity(0.08),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    icon,
                    size: 40,
                    color: Theme.of(ctx).colorScheme.shadow,
                  ),
                ),

                SizedBox(height: 12),

                // Mensagem
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),

                SizedBox(height: 20),

                // Botões
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botão Cancelar
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (onCancel != null) onCancel();
                      },
                      child: Text(
                        cancelText.toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Botão Confirmar
                    ElevatedButton(
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
                      ),
                      child: Text(confirmText.toUpperCase()),
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
    _focusNode.dispose();
    _timerSelect?.cancel();
    super.dispose();
  }

  // Função para adicionar numero
  void _adicionarNumero(String tecla) {
    HapticFeedback.lightImpact();
    final oldValue = nomeClienteController.value;
    final newValue = TextEditingValue(
      text: oldValue.text + tecla,
      selection: TextSelection.collapsed(offset: oldValue.text.length + 1),
    );
    nomeClienteController.value = newValue;
  }

  // Função para apagar numero
  void _apagarNumero() {
    if (nomeClienteController.text.isEmpty) return;
    HapticFeedback.lightImpact();
    final newText = nomeClienteController.text.substring(
      0,
      nomeClienteController.text.length - 1,
    );
    nomeClienteController.text = newText;
  }

  // Função para iniciar apagar
  void _iniciarApagar() {
    HapticFeedback.lightImpact();
    _timerApagar = Timer.periodic(Duration(milliseconds: 300), (_) {
      _apagarVarios();
      // if(nomeClienteController.text.isEmpty){
      //   _pararApagar();
      // }
    });
  }

  // Função para parar de apagar
  _pararApagar() {
    _timerApagar?.cancel();
  }

  // Função responsável por apagar vários caracteres
  // _apagarVarios(){
  //   if (nomeClienteController.text.isEmpty) return;
  //   // Verifica o número de caracteres restantes e remove 2 ou 3, dependendo
  //   int numCaracteresRemover = nomeClienteController.text.length <= 3 ? 2 : 3;
  //   final newText = nomeClienteController.text.substring(0, nomeClienteController.text.length - numCaracteresRemover);

  //   // Atualiza o texto no controlador
  //   nomeClienteController.text = newText;
  // }
  _apagarVarios() {
    final texto = nomeClienteController.text;

    if (texto.isEmpty) return;

    int tamanhoAtual = texto.length;

    // Decide quantos caracteres remover
    int numCaracteresRemover = tamanhoAtual <= 3 ? 2 : 3;

    // GARANTIA: nunca deixar índice negativo
    int novoTamanho = tamanhoAtual - numCaracteresRemover;

    if (novoTamanho <= 0) {
      nomeClienteController.clear();
      return;
    }

    nomeClienteController.text = texto.substring(0, novoTamanho);

    // Mantém o cursor no final
    nomeClienteController.selection = TextSelection.fromPosition(
      TextPosition(offset: nomeClienteController.text.length),
    );
  }

  _fechatTeclado() {
    _showKeyboard = false;
  }

  // Confirmar
  void _confirmar() {
    HapticFeedback.lightImpact();
    setState(() {
      _showKeyboard = false;
      _toggleKeyboardMaior(false);

      try {
        if (quantidadeController.text.isEmpty ||
            nomeClienteController.text.isEmpty) {
          showConfirmationDialogSoOk(
            context: context,
            title: '',
            message: 'Por favor, preencha todas as informações antes de salvar.',
            icon: Icons.cancel, // você pode trocar para Icons.home ou outro
            onConfirm: () async {
              try {
                carregarClientes();
                await configuracaoClientes();
                if (quantidadeController.text.isEmpty) {
                  setState(() {
                    FocusScope.of(context).requestFocus(quantidadeFocusNode);
                    _showKeyboard = false;
                  });
                } else if (nomeClienteController.text.isEmpty) {
                  setState(() {
                    FocusScope.of(context).requestFocus(nomeFocusNode);
                    _showKeyboard = true;
                  });
                }
              } catch (e) {
                setState(() {
                  isLoading = true;
                });
              }
            },
          );
          return;
        }
        inserirVenda(
          nomeClienteController.text,
          _horaBanco,
          quantidadeController.text,
        );
        setState(() {
          nomeClienteController.text = '';
          quantidadeController.clear();
          quantidadeController.text = '';
        });
        showConfirmationDialogSoOk(
          context: context,
          title: '',
          message: 'Informações salvas com sucesso!',
          icon: Icons.check, // você pode trocar para Icons.home ou outro
          onConfirm: () async {
            carregarClientes();
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                pageBuilder: (context, animation, secondaryAnimation) =>
                    NotesPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return child;
                    },
              ),
            );
          },
        );
        // Adicionando a lógica do contador de 5 segundos para fechar o diálogo automaticamente
        Future.delayed(Duration(seconds: 5), () {
          if (Navigator.canPop(context)) {
            carregarClientes();
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                pageBuilder: (context, animation, secondaryAnimation) =>
                    NotesPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return child;
                    },
              ),
            );
          }
        });
      } catch (e) {
        showConfirmationDialogSoOk(
          context: context,
          title: '',
          message: 'Erro ao salvar as informações. Tente novamente.',
          icon: Icons.check, // você pode trocar para Icons.home ou outro
          onConfirm: () async {
            carregarClientes();
          },
        );
        // );
        print('Erro ao salvar: $e');
      }
    });
  }

  // Função para incrementar quantidade de pessoas
  void _incrementarQuantidade() {
    HapticFeedback.lightImpact();
    setState(() {
      atual++;
      quantidadeController.text = atual.toString();
    });
  }

  // Função para diminiur quantidade de pessoas
  void _diminuirQuantidade() {
    HapticFeedback.lightImpact();
    setState(() {
      if (atual > 1) atual--;
      quantidadeController.text = atual.toString();
    });
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
        // _isLoading = false; // Também para o loading
      });
    }
  }

  // perde_foco() async {
  //   Future.delayed(Duration(milliseconds: 200), () {
  //     setState(() {
  //       FocusScope.of(context).unfocus();
  //     });
  //   });
  // }

  // falsificar_teclado(){
  //    Future.delayed(Duration(milliseconds: 500), () {
  //     setState(() {
  //       tecladoAtivo.value = false;
  //     });
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
      body: Stack(
        children: [
          GestureDetector(
            onTap: () async {
              _showKeyboard = false;
              _toggleKeyboardMaior(false);
            },
            child: Padding(
              padding: EdgeInsets.all(0.0),
              child: Column(
                children: [
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment
                        .center, // garante alinhamento vertical
                    children: [
                      // Texto
                      Text(
                        'Notes',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          color: colorScheme.shadow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  Center(
                    child: Text(
                      'Nome do cliente:',
                      style: TextStyle(
                        color: colorScheme.onSecondary,
                        fontSize: 15,
                        // fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // (nome do cliente)
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 40,
                            child: TextField(
                              controller: nomeClienteController,
                              focusNode: nomeFocusNode,
                              readOnly: false, // impede digitação pelo teclado nativo
                              showCursor: true, // FORÇA o cursor piscando
                              cursorColor: Theme.of(context).colorScheme.shadow,
                              // keyboardType: TextInputType.none, // garante que o teclado não abr
                              keyboardType: TextInputType.text,
                              textAlign: TextAlign.center,
                              textCapitalization: TextCapitalization.characters,
                              maxLines: 1, // nunca quebra
                              // textAlign: TextAlign.start, // evita estouro visual
                              textAlignVertical: TextAlignVertical.center,
                              style: const TextStyle(overflow: TextOverflow.clip, // corta corretamente
                              ),
                              scrollPhysics: BouncingScrollPhysics(),
                              onTap: () {
                                FocusScope.of(context).requestFocus(nomeFocusNode);
                                _showKeyboard = true;
                                _toggleKeyboardMaior(true);
                              },
                              // onEditingComplete: () async {
                              //   perde_foco();
                              //   falsificar_teclado();
                              // },
                              //  onSubmitted: (_) {
                              //    perde_foco();
                              //    falsificar_teclado();
                              //  },
                              onChanged: (text) {
                                nomeClienteController.text = text.toUpperCase();
                                nomeClienteController
                                    .selection = TextSelection.fromPosition(
                                  TextPosition(
                                    offset: nomeClienteController.text.length,
                                  ),
                                );
                              },
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: "",
                                filled: true,
                                fillColor: _isFocused
                                    ? colorScheme.shadow
                                    : colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: colorScheme
                                        .onSurface, // Cor da borda quando o campo NÃO tem foco
                                    width: 2.0,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: colorScheme
                                        .shadow, // Cor da borda quando o campo TEM foco
                                    width: 2.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            // await perde_foco();
                            // await falsificar_teclado();
                            _showKeyboard = false;
                            _toggleKeyboardMaior(false);
                            _diminuirQuantidade();
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: colorScheme.shadow,
                            child: Icon(
                              Icons.remove,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        // Text field
                        Expanded(
                          flex: 0, // deixa o campo com tamanho mínimo possível
                          child: SizedBox(
                            width: 50,
                            height: 40,
                            child: TextField(
                              controller: quantidadeController,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter
                                    .digitsOnly, // permite apenas números
                                LengthLimitingTextInputFormatter(
                                  2,
                                ), // máximo 2 dígitos
                              ],
                              focusNode: quantidadeFocusNode,
                              decoration: InputDecoration(
                                labelText: '',
                                filled: true,
                                fillColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: colorScheme.shadow, // Cor da borda
                                    width: 2, // Largura da borda
                                  ),
                                ),
                              ),
                              style: TextStyle(
                                height:
                                    1, // Ajusta a altura das linhas para centralizar o texto verticalmente
                              ),
                              readOnly: true, // Impede a edição com o teclado
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        // Botão mais
                        GestureDetector(
                          onTap: () async {
                            // await perde_foco();
                            // await falsificar_teclado();
                            _showKeyboard = false;
                            _toggleKeyboardMaior(false);
                            _incrementarQuantidade();
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: colorScheme.shadow,
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        SizedBox(width: 30),

                        // Botão de confirmação
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              isLoading = true;
                              try{
                                if(nomeClienteController.text.isNotEmpty){
                                  inserirVenda(
                                    nomeClienteController.text,
                                    _horaBanco,
                                    quantidadeController.text,
                                  );
                                  setState(() {
                                    nomeClienteController.text = '';
                                    quantidadeController.clear();
                                    quantidadeController.text = '1';
                                    isLoading = false;
                                  });
                                  carregarClientes();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Por favor, insira o nome do cliente.',
                                    ),
                                    backgroundColor: colorScheme.error,
                                  ),
                                );
                                isLoading = false;
                                }
                              } catch(e){
                                print(e);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Erro ao inserir cliente. Tente novamente.',
                                    ),
                                    backgroundColor: colorScheme.error,
                                  ),
                                );
                                isLoading = false;
                              }
                              
                              /* // await perde_foco();
                              // await falsificar_teclado();
                              _showKeyboard = false;
                              _toggleKeyboardMaior(false);
                              FocusScope.of(context).unfocus();
                              try {
                                if (quantidadeController.text.isEmpty ||
                                    nomeClienteController.text.isEmpty) {
                                  showConfirmationDialogSoOk(
                                    context: context,
                                    title: '',
                                    message:
                                        'Por favor, preencha todas as informações antes de salvar.',
                                    icon: Icons
                                        .cancel, // você pode trocar para Icons.home ou outro
                                    onConfirm: () async {
                                      try {
                                        carregarClientes();
                                        if (quantidadeController.text.isEmpty) {
                                          setState(() {
                                            FocusScope.of(
                                              context,
                                            ).requestFocus(quantidadeFocusNode);
                                            _showKeyboard = false;
                                          });
                                        } else if (nomeClienteController
                                            .text
                                            .isEmpty) {
                                          setState(() {
                                            FocusScope.of(
                                              context,
                                            ).requestFocus(nomeFocusNode);
                                            _showKeyboard = true;
                                          });
                                        }
                                      } catch (e) {
                                        setState(() {
                                          isLoading = true;
                                        });
                                      }
                                    },
                                  );
                                  return;
                                }

                                inserirVenda(
                                  nomeClienteController.text,
                                  _horaBanco,
                                  quantidadeController.text,
                                );
                                setState(() {
                                  nomeClienteController.text = '';
                                  quantidadeController.clear();
                                  quantidadeController.text = '';
                                });
                                showConfirmationDialogSoOk(
                                  context: context,
                                  title: '',
                                  message: 'Informações salvas com sucesso!',
                                  icon: Icons
                                      .check, // você pode trocar para Icons.home ou outro
                                  onConfirm: () async {
                                    carregarClientes();
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        transitionDuration: Duration.zero,
                                        reverseTransitionDuration:
                                            Duration.zero,
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
                                              return child;
                                            },
                                      ),
                                    );
                                  },
                                );
                                // Adicionando a lógica do contador de 5 segundos para fechar o diálogo automaticamente
                                Future.delayed(Duration(seconds: 5), () {
                                  if (Navigator.canPop(context)) {
                                    carregarClientes();
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        transitionDuration: Duration.zero,
                                        reverseTransitionDuration:
                                            Duration.zero,
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
                                              return child;
                                            },
                                      ),
                                    );
                                  }
                                });
                              } catch (e) {
                                showConfirmationDialogSoOk(
                                  context: context,
                                  title: '',
                                  message:
                                      'Erro ao salvar as informações. Tente novamente.',
                                  icon: Icons
                                      .check, // você pode trocar para Icons.home ou outro
                                  onConfirm: () async {
                                    carregarClientes();
                                  },
                                );
                                // );
                                print('Erro ao salvar: $e');
                              } */
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.shadow,
                              padding: EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Confirmar',
                              style: TextStyle(
                                // fontSize: 15,
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        ElevatedButton(
                          onPressed: () {
                            carregarClientes();
                          },
                          style: ElevatedButton.styleFrom(
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(20), // tamanho do círculo
                            backgroundColor: colorScheme.tertiary,
                            elevation:
                                8, // Define a altura da sombra (quanto maior, mais "profunda" será a sombra)
                            shadowColor: Colors
                                .black, // Cor da sombra com opacidade (ajuste conforme necessário)
                          ),
                          child: Icon(
                            Icons.refresh,
                            size: 20,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 30),

                  SizedBox(height: 8),
                  if (isLoading)
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 6,
                            valueColor: AlwaysStoppedAnimation(
                              colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!isLoading)
                    Expanded(
                      child: listaClientes.isEmpty
                          ? Center(
                              child: Text(
                                'Você não tem clientes na fila :(',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: colorScheme.shadow.withOpacity(0.5),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: listaClientes.length,
                              itemBuilder: (context, index) {
                                final cliente = listaClientes.reversed.toList()[index];
                                final numero = cliente['numero'];
                                return Card(
                                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8,),
                                  color: colorScheme.secondary,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8.0,
                                      horizontal: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        // Botão confirmar
                                        IconButton(
                                          icon: Icon(
                                            Icons.check_circle,
                                            color: colorScheme.primary,
                                            size: 40,
                                          ),
                                          onPressed: () {
                                            showConfirmationDialog(
                                              context: context,
                                              title: '',
                                              message: 'Tem certeza que deseja confirmar entrada de ${cliente['nome']}?',
                                              icon: Icons.person, // você pode trocar para Icons.home ou outro
                                              onConfirm: () async {
                                                try {
                                                  String sql = """UPDATE notes SET status = '2', saida = '${_horaBanco}' WHERE numero = '$numero'""";
                                                  String resultado = await Connection().ipd(sql,);
                                                  carregarClientes();
                                                  FocusScope.of(context,).unfocus();
                                                } catch (e) {
                                                  setState(() {
                                                    isLoading = true;
                                                  });
                                                }
                                              },
                                              onCancel: () async {
                                                carregarClientes();
                                                FocusScope.of(context,).unfocus();
                                              },
                                            );
                                          },
                                        ),

                                        // Informações do cliente
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${cliente['nome']} - ${_formatHora(cliente['entrada'])}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.onSecondary,
                                                ),
                                              ),
                                              Text(
                                                'Pessoas: ${cliente['pessoas']}',
                                                style: TextStyle(
                                                  color: colorScheme.onSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Botão excluir
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: colorScheme.error,
                                            size: 40,
                                          ),
                                          onPressed: () {
                                            showConfirmationDialog(
                                              context: context,
                                              title: '',
                                              message:'Tem certeza que deseja cancelar entrada de ${cliente['nome']}?',
                                              icon: Icons.cancel, // você pode trocar para Icons.home ou outro
                                              onConfirm: () async {
                                                try {
                                                  String sql = """UPDATE notes SET status = '0', saida = '${_horaBanco}' WHERE numero = '$numero'""";
                                                  String resultado = await Connection().ipd(sql,);
                                                  carregarClientes();
                                                  FocusScope.of(context,).unfocus();
                                                } catch (e) {
                                                  setState(() {
                                                    isLoading = true;
                                                  });
                                                }
                                              },
                                              onCancel: () async {
                                                carregarClientes();
                                                FocusScope.of(context,).unfocus();
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  if (!tecladoAtivo.value)
                    listaClientes.isEmpty
                        ? Center(
                            child: Text(
                              '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: colorScheme.shadow.withOpacity(0.5),
                              ),
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Container(
                              color: colorScheme.secondary,
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.0,
                                    horizontal: 12,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment
                                        .center, // Centraliza os elementos verticalmente
                                    crossAxisAlignment: CrossAxisAlignment
                                        .center, // Centraliza os elementos horizontalmente
                                    children: [
                                      // Primeira coluna
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment
                                                .center, // Centraliza horizontalmente
                                            children: [
                                              Text(
                                                'Lista de espera:',
                                                style: TextStyle(
                                                  color:
                                                      colorScheme.onSecondary,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 8,
                                              ), // Adiciona um pequeno espaço entre os textos
                                              Text(
                                                '${listaClientes.length}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      colorScheme.onSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      // Espaço entre os blocos
                                      SizedBox(
                                        height: 12,
                                      ), // Adiciona um pequeno espaço entre os dois blocos
                                      // Segunda coluna
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment
                                                .center, // Centraliza horizontalmente
                                            children: [
                                              Text(
                                                'Quantidade de pessoas na lista:',
                                                style: TextStyle(
                                                  color:
                                                      colorScheme.onSecondary,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 8,
                                              ), // Adiciona um pequeno espaço entre os textos
                                              Text(
                                                '$_totalPessoas',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      colorScheme.onSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                  // Barra inferior com botões quadrados
                  // if (!_showKeyboard)
                    // Barra inferior com botões quadrados
                    Padding(
                      padding: footerButtonsController.aparecerNote.value
                          ? EdgeInsets.only(top: 5.0, bottom: 15.0, left: 10.0, right: 10.0)
                          : EdgeInsets.only(top: 5.0, bottom: 15.0, left: 15.0, right: 15.0),
                      child: Row(
                        children: [
                          // Botão Check In
                          if (footerButtonsController.aparecerCheckIn.value)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.0),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        transitionDuration: Duration.zero, // sem duração
                                        reverseTransitionDuration: Duration.zero, // sem duração ao voltar
                                        pageBuilder: (context, animation, secondaryAnimation,) => CheckinPage(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child,) {
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

                          // if(aparecerCheckOut)
                          // SizedBox(width: 8),

                          // Botão Check Out
                          if (footerButtonsController.aparecerCheckOut.value)
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
                                        reverseTransitionDuration: Duration
                                            .zero, // sem duração ao voltar
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
                          // if (aparecerNote) SizedBox(width: 8),
                          if (footerButtonsController.aparecerNote.value)
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
                                        reverseTransitionDuration: Duration
                                            .zero, // sem duração ao voltar
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
                          if (footerButtonsController.aparecerRecepcao.value)
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
                                        reverseTransitionDuration: Duration
                                            .zero, // sem duração ao voltar
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
                          //if (aparecerCheckInOut || !naoAparecerMapa)
                          //  SizedBox(width: 8),
                          if (footerButtonsController.aparecerMapa.value)
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
                                        reverseTransitionDuration: Duration
                                            .zero, // sem duração ao voltar
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
                          if (footerButtonsController.aparecerGarcom.value)
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
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 100),
              padding: EdgeInsets.only(
                bottom: _showKeyboard
                    ? 1
                    : MediaQuery.of(context).viewInsets.bottom,
              ),
              height: _showKeyboard
                  ? 0 // MediaQuery.of(context).size.height * 0.38 
                  : 0,
              child: _showKeyboard
                  ? Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: Column(
                        // Cinco linhas para o teclado
                        children: [
                          _buildKeyboardRow([
                            '1',
                            '2',
                            '3',
                            '4',
                            '5',
                            '6',
                            '7',
                            '8',
                            '9',
                            '0',
                          ]),

                          _buildKeyboardRow([
                            'Q',
                            'W',
                            'E',
                            'R',
                            'T',
                            'Y',
                            'U',
                            'I',
                            'O',
                            'P',
                          ]),

                          _buildKeyboardRow([
                            '1/2',
                            'A',
                            'S',
                            'D',
                            'F',
                            'G',
                            'H',
                            'J',
                            'K',
                            'L',
                            '1/2',
                          ]),

                          _buildKeyboardRow([
                            '',
                            '',
                            'Z',
                            'X',
                            'C',
                            'V',
                            'B',
                            'N',
                            'M',
                            '⌫',
                          ]),

                          _buildKeyboardRow(['ESP', 'OK'], isLastRow: true),

                          _buildKeyboardRow([
                            '',
                            '',
                            '',
                            'fechar',
                          ], isLastRow: true),
                          // SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                        ],
                      ),
                    )
                  : SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para montar as linhas de botões
  Widget _buildKeyboardRow(List<String> letras, {bool isLastRow = false}) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Conta quantos '' no início e no fim (spacers)
          int leading = 0;
          while (leading < letras.length && letras[leading] == '') leading++;
          // Calculam quantos espaços vazios existem no início
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
            if (t == '') return 2;
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
          // Calculando a posição e o tamanho de cada botão
          List<({double start, double end, String key})> hit =
              []; // a lista é formada por onde ela começa (start), onde ela termina (end) e o valor da tecla (key).
          // Controla posição atual ao longo da linha de teclas
          double cursor = leading * unit;

          // Calculando a posição e o tamanho de cada tecla
          for (int i = 0; i < visibleKeys.length; i++) {
            double w = flexList[i] * unit; // Calculando a largura de cada tecla
            hit.add((
              start: cursor,
              end: cursor + w,
              key: visibleKeys[i],
            )); // armazena no hitbox
            cursor += w; // atualiza a posição do cursor
          }

          return GestureDetector(
            behavior: HitTestBehavior
                .opaque, // Isso garante que o GestureDetector detecte toques em toda a área do widget
            onTapDown: (details) {
              // passa o local e posição do toque
              double dx = details.localPosition.dx;

              // Verifica qual tecla foi tocada
              for (var box in hit) {
                if (dx >= box.start && dx <= box.end) {
                  // Ele verifica se a posição horizontal do toque (dx) está dentro dos limites da tecla
                  switch (box.key) {
                    case '⌫':
                      _apagarNumero();
                      break;
                    case 'OK':
                      _confirmar();
                      break;
                    case 'ESP':
                      _adicionarNumero(' ');
                      break;
                    case 'fechar':
                      _fechatTeclado();
                      break;
                    case '1/2':
                      // NÃO FAZ NADA -> é só espaçamento visual
                      break;
                    default:
                      _adicionarNumero(box.key);
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
                    _iniciarApagar(); // AÇÃO DO TOQUE LONGO
                  }
                  break;
                }
              }
            },
            // PARA QUANDO SOLTA
            onLongPressEnd: (_) {
              _pararApagar();
            },

            // GARANTE PARADA SE CANCELAR O TOQUE
            onTapUp: (_) {
              _pararApagar();
            },

            onTapCancel: () {
              _pararApagar();
            },
            // Layout
            child: Row(
              children: [
                if (leading > 0) Spacer(flex: leading),
                // Layout da linha de teclas
                for (int i = 0; i < visibleKeys.length; i++)
                  Expanded(
                    flex: flexList[i],
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: _buildVisualButton(
                        visibleKeys[i],
                      ), // Chama a função de layout e passa valor da lista
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

  // Widget para montar o visual dos botões
  Widget _buildVisualButton(String tecla) {
    ColorScheme cs = Theme.of(context).colorScheme;

    if (tecla == '1/2') {
      return Container(); // espaço vazio para alinhar visualmente
    }

    if (tecla == '') {
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

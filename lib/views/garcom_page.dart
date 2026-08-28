import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cpf_cnpj_validator/cpf_validator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:pinput/pinput.dart';
import 'package:un_recepcao/controllers/carrinho_controller.dart';
import 'package:un_recepcao/controllers/comanda_carrinho.dart';
import 'package:un_recepcao/controllers/views/footer_buttons_controller.dart';
import 'package:un_recepcao/controllers/views/funcoes_controller.dart';
import 'package:un_recepcao/controllers/views/garcom_controller.dart';
import 'package:un_recepcao/controllers/views/painel_controller.dart';
import 'package:un_recepcao/data/data_class.dart';
import 'package:un_recepcao/views/carrinho_comandas_page.dart';
import 'package:un_recepcao/views/checkin_page.dart';
import 'package:un_recepcao/views/checkout_page.dart';
import 'package:un_recepcao/views/conta_page.dart';
import 'package:un_recepcao/views/mapa_page.dart';
import 'package:un_recepcao/views/notes_page.dart';
import 'package:un_recepcao/views/pizza_page.dart';
import 'package:un_recepcao/views/recepcao_page.dart';
import 'package:un_recepcao/widgets/side_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

// Modelo auxiliar somente usado para montar pizza
class PartesPizza {
  List<String> sabores;
  List<String> obsSabores;
  List<String> bordas;
  List<String> obsBordas;

  PartesPizza({
    required this.sabores,
    required this.obsSabores,
    required this.bordas,
    required this.obsBordas,
  });
}

// Objeto produto
class Produto {
  final String nome;
  final String preco;
  final String numero;
  double quantidade;

  // Indica se o produto suporta meia porção (vem da base de dados)
  bool temMeiaPorcao;

  // Observação digitada
  final String observacaoEscrita;

  // Observações selecionadas (checkbox / select)
  final List<String> observacoesTexto;

  // Adicionais do produto
  final List<Produto> adicionais;

  // Id para saber se é P ou PZ
  final String id;

  Produto({
    required this.nome,
    required this.preco,
    required this.numero,
    required this.quantidade,
    required this.observacaoEscrita,
    /*   SEM GELO|SEM LIMAO 12|2|4 */
    required this.id, // string
    this.temMeiaPorcao = false,
    List<String>? observacoesTexto,
    List<Produto>? adicionais,
  }) : observacoesTexto = observacoesTexto ?? [],
       adicionais = adicionais ?? [];
}

class GarcomPage extends StatefulWidget {
  const GarcomPage({super.key});

  @override
  State<GarcomPage> createState() => GarcomPageState();
}

class GarcomPageState extends State<GarcomPage>
    with SingleTickerProviderStateMixin {

  String versaoAplicacao = FuncoesController().versaoDoApp;

  final ScrollController _scrollController = ScrollController();

  /*   final String tamanhoSelecionado = Get.arguments['tamanhoSelecionado'];
  final String comandaDoPedido = Get.arguments['comanda'];
  final String mesaDoPedido = Get.arguments['mesa']; */

  final TextEditingController servidorController = TextEditingController();
  final TextEditingController comandaController = TextEditingController();
  final TextEditingController mesaController = TextEditingController();
  final TextEditingController cardapioController = TextEditingController(); // barra busca
  final TextEditingController numeroProdutoSelecionadoController = TextEditingController();
  final TextEditingController quantidadeProdutoSelecionadoController = TextEditingController();
  final TextEditingController observacaoProdutoSelecionadoController = TextEditingController();
  final TextEditingController quantidadeProdutoSelecionadoModalController = TextEditingController();
  final TextEditingController adicionalProdutoSelecionadoController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  final TextEditingController observacaoProdutoSelecionadoObsAddController = TextEditingController();

  final TextEditingController nomeClienteDialogoController = TextEditingController();
  final TextEditingController telefoneClienteDialogoController = TextEditingController();
  final TextEditingController cpfClienteDialogoController = TextEditingController();
  final TextEditingController dataNascimentoClienteDialogoController = TextEditingController();

  final FocusNode comandaFocus = FocusNode();
  final FocusNode mesaFocus = FocusNode();
  final FocusNode cardapioFocus = FocusNode();
  final FocusNode numeroProdutoSelecionadoFocus = FocusNode();
  final FocusNode quantidadeProdutoSelecionadoModalFocus = FocusNode();
  final FocusNode quantidadeProdutoSelecionadoFocus = FocusNode();
  final FocusNode observacaoProdutoSelecionadoFocus = FocusNode();
  final FocusNode senhaFocus = FocusNode();
  final FocusNode observacaoProdutoSelecionadoObsAddFocus = FocusNode();

  final FocusNode nomeClienteDialogoFocus = FocusNode();
  final FocusNode telefoneClienteDialogoFocus = FocusNode();
  final FocusNode cpfClienteDialogoFocus = FocusNode();
  final FocusNode dataNascimentoClienteDialogoFocus = FocusNode();

  final CarrinhoController carrinhoController = Get.find<CarrinhoController>();
  final ComandaCarrinhoController comandaCarrinhoController = Get.find<ComandaCarrinhoController>();
  final GarcomController garcomController = Get.find<GarcomController>();

  bool isProcessing = false;
  String nomeEmpresa = '';
  String mensagem = 'Insira o número da comanda';
  String mensagemNaMesa = '';
  bool corMensagem = true;
  bool iconeMensagem = true;
  bool animacaoAparecer = false;

  bool showKeyboardAlfa = false;
  bool showKeyboardQuantidade = false;
  bool showKeyboardNumero = false;

  List<Produto> carrinho = [];

  // List<dynamic> listaGarcom = [];
  String numeroDoGarcom = "";
  String nomeDoGarcom = "";

  late Timer _timer;
  String _horaAtual = '';

  bool checkIn = true;
  bool checkout = false;
  bool mapaDeMesaoOuComanda = false;
  bool comandas = true;
  bool garcomSelecionado = true;

  final FocusNode _focusNode = FocusNode();
  final FocusNode _focusNodeCardapio = FocusNode();
  bool _isFocused = false;
  bool _popupGarcomAberto = false;

  // Controle dos filtros de mesas e comandas
  bool mostrarTodas = true;
  bool mostrarAbertas = false;
  bool mostrarFechadas = false;
  bool mesaAberta = true;
  bool _isLoading = true;
  bool servidorConectado = false;

  List<dynamic> validaComanda = [];
  List<dynamic> validaMesa = [];
  String numeroDoPedido = '';
  String valorTotalLiquido = '';
  String statusPedido = '';
  // String numeroDoProduto = '';

  // Variáveis dos grupos
  /* String numeroDoGrupo = "";
  String nomeDoGrupo = "";
  String idDoGrupo = "";
  List<dynamic> listaGrupo = []; */

  // Variáveis dos produtos
  // String numeroDoProduto = "";
  // String nomeDoProduto = "";
  // String idDoProduto = "";
  String idDoProdutoSelecionado = "";
  // List<dynamic> listaProduto = [];
  List<dynamic> listaProdutoFiltrada = [];

  // Variáveis dos adicionais e observações
  // List<dynamic> listaAdicionaisObservacoes = [];
  List<Produto> adicionaisSelecionados = [];

  List<dynamic> listaAdicionaisObservacoesDoProduto = [];
  List<dynamic> listaAdicionaisDoProduto = [];
  List<dynamic> listaObservacaoesDoProduto = [];
  List<Produto> listaAdicionaisSelecionados = [];
  List<String> listaObservacoesSelecionadas = [];

  // Contraladores da animação
  late AnimationController animationController;
  late Animation<double> scaleAnimation;
  bool animacaoCerto = true;

  bool isLoading = false;

  String comandaNumero = '';
  bool comandaRegistrada = false;

  bool cadastrarPorMesa = false;
  bool cadastrarPorComanda = true;

  String nomeDoGarcomSelecionado = "";
  bool nomeDoGarcomDoLoad = false;

  static final ValueNotifier<bool> isConnected = ValueNotifier(false);

  String nomePVD = "";
  String numeroDaLicencaSelecionada = "";

  bool comandaValida = false;
  bool mesaValida = false;
  bool icone = false;
  bool desejaMesa = false;
  bool aparecerCardapio = false;
  bool vinculandoMesa = false;

  StateSetter? estadoPopupCadastro;

  bool mostrarProdutos = false;
  bool mostrarGrupos = true;
  List<dynamic> produtosFiltrados = [];
  bool aparecerLista = false;
  bool aparecerCarrinho = true;
  bool aparecerConfiguracaoProduto = false;
  bool aparecerBotoes = true;

  // Variáveis para adicionar produto no carrinho
  String produtoNomeCarrinho = "";
  String produtoValorCarrinho = "";
  String produtoNumeroCarrinho = "";
  int produtoQuantidadeCarrinho = 0;
  String produtoObservacaoCarrinho = "";

  String valorDoProdutoSelecionado = "";
  String numeroDoProdutoSelecionado = "";

  String _campoAtivo = "";

  bool temAdicionalObservacao = false;
  int quantidadeInicial = 1;

  bool aparecerFazerPedido = false;

  String meuMobileId = "";
  String mobileId = "";

  String numeroComandaEmUso = "";
  String numeroMesaEmUso = "";

  bool mesaComandaNaoTemConta = true;

  int quantidadeadicionalProdutoSelecionado = 1;

  bool mesaVinculada = false;
  bool _isZerando = false;
  bool fizPedido = false;

  // Variáveis para contatores de adicionais e observações
  Map<String, double> quantidadesAdicionais = {};
  Map<String, double> quantidadesObservacoes = {};

  String numeropedido_FK = "";

  bool mostrarDentroComandaMesa = false;
  bool produtoKilo = false;
  int contadorPonto = 0;

  bool enviarComanda = false;

  String numeroMesaParaCarrinho = "";

  bool isProcessingConfirmar = false;

  // Variável cliqueiFazerPedido foi removida a favor do estado global no FuncoesController

  final FuncoesController funcoesController = Get.find<FuncoesController>();
  final FooterButtonsController footerButtonsController = Get.find<FooterButtonsController>();

  bool cliqueiFazerPedido = false;

  bool nunca = false;
  bool erroBool = false;
  bool isLoadingSenha = true;

  int shakeKey = 0;

  /// Flag que indica se o bloqueio global de foco está ativo.
  bool _bloqueandoFoco = false;

  /// Flag que bloqueia toda interação de toque enquanto um diálogo está ativo
  /// ou operações assíncronas críticas estão sendo executadas.
  /// Controlado por AbsorbPointer no body do Scaffold.
  bool _telaBloqueada = false;

  bool aparecerVendaTouch = false;
  String grupoSelecionadoNoTouch = "";

  bool empurrarBotoes = false;

  bool modoAnteriorTouch = false;

  bool arrastei = true;

  bool aparecerCarrinhoForcado = false;

  RxList<dynamic> observacoesSelecionadas = <dynamic>[].obs;
  List<String> observacoesSelecionadasObs = [];
  String ultimoNumeroObservacaoSelecionado = "";
  String ultimoNomeObservacaoSelecionado = "";
  bool aparecerGrid = true;
  int indexClicado = 0;
  bool cliqueiEditarProduto = false;

  int posicaoUltimoGrupo = 0;

  bool meiaPorcaoProduto = false;
  bool meiaPorcaoClicado = false;

  // Cadastro cliente 
  bool cadastrarCliente = false;
  bool querCadastrarCliente = false;

  bool telefoneValido = false;
  bool dataNascimentoValida = false;
  bool cpfValido = false;
  bool nomeValido = false;

  bool telefoneErro = false;
  bool dataNascimentoErro = false;
  bool cpfErro = false;
  bool nomeErro = false;

  RxBool clienteJaCadastrado = false.obs;
  int numeroCliente = 0;
  String numeroClienteString = "0";

  // Snapshot dos dados originais do cliente ao abrir o popup
  String _snapshotNome = '';
  String _snapshotTelefone = '';
  String _snapshotCpf = '';
  String _snapshotDataNascimento = '';

  int cliquei = 0;

  bool cliqueiSelecionarGarcom = false;

  bool clienteJaExisteComanda = false;

  bool volteiPizza = false;

  bool clienteCadastradoVisual = false;

  // A máscara permite 10 ou 11 dígitos para o número (com DDD)
  final _maskFormatter = MaskTextInputFormatter(
    mask: '(##)#####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  String get telefoneEmpresaMascara {
    if (garcomController.telefoneEmpresa.isEmpty) return '(  )';
    return '(${garcomController.telefoneEmpresa})';
  }

  /// FocusNode "buraco negro" — enquanto estiver com primaryFocus,
  late final FocusNode _focoBloqueio = FocusNode(
    debugLabel: 'focoBloqueioDialogo',
    skipTraversal: true,
    canRequestFocus: true,
  );
 
  final painelController = Get.find<PainelController>();

  bool cliqueiSenha = false;

  @override
  void initState() {
    super.initState();

    painelController.estaNoPainelCozinha.value = false; 

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

    // conexão hora
    _atualizarHora();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _atualizarHora();
    });

    // Único listener do _focusNode — sem setState desnecessário
    _focusNode.addListener(() {
      if (!mounted) return;
      final focus = _focusNode.hasFocus;
      if (focus != _isFocused) {
        setState(() {
          _isFocused = focus;
        });
      }
    });
    _carregarModo();
    _carregarServidor();
    _loadServidor();
    _loadComanda();
    _loadGarcom();
    _loadNumeroLicenca();
    _loadNomeEmpresa();
    listaProdutoFiltrada = funcoesController.listaProduto;
    _selecionarPrimeiroGrupo();

    // Se já existem itens no carrinho OU foi passado algum argumento, restaura o estado ANTES de ligar os listeners
    if (carrinhoController.carrinho.isNotEmpty || Get.arguments != null) {
      // iniciaComCarrinho() já chama sairModoTouch() internamente e salva "Carrinho".
      // NÃO chamar carregarUltimaConfiguracao() aqui, pois ela leria "Touch" do
      // SharedPreferences e reativaria o modo touch logo após sairModoTouch().
      iniciaComCarrinho();
    } else {
      chamarFocoInicial();
      carrinhoController.carrinho.clear();
    }

    carregarUltimoAdicionalObservacaoSelecionado();

    // Sincronizar showKeyboardAlfa com o foco nativo dos campos de texto
    cardapioFocus.addListener(_syncKeyboardAlfaFromFocus);
    observacaoProdutoSelecionadoFocus.addListener(_syncKeyboardAlfaFromFocus);

    // limparCarrinho();

    garcomController.configuracoesCadastroCliente();
  }

  Future<void> atualizarValores(
    StateSetter setStatePopup,
    String nome,
    String telefone,
    String cpf,
    String dataNascimento,
  ) async {
    try {
      setStatePopup(() {
        nomeClienteDialogoController.text = nome;
        telefoneClienteDialogoController.text = telefone;
        cpfClienteDialogoController.text = cpf;
        dataNascimentoClienteDialogoController.text = dataNascimento;
      });
    } catch (e) {
      nomeClienteDialogoController.text = nome;
      telefoneClienteDialogoController.text = telefone;
      cpfClienteDialogoController.text = cpf;
      dataNascimentoClienteDialogoController.text = dataNascimento;
    }
  }

  // Função para buscar valores do pedido
  Future<bool> buscarInformacoesClientePedidoAberto (String numeroPedido, StateSetter setStatePopup) async {
    try {
      String dadosJson = await Connection().select(
        """
        SELECT p.numerocliente_FK, p.numero, c.nome, c.telefone, c.cpf, c.datanascimento
          FROM pedidos p
          INNER JOIN clientes c
              ON c.numero = p.numerocliente_FK WHERE p.numero = '$numeroPedido';
        """,
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        final valor = lista[0]['numerocliente_FK'].toString();
        final valor1 = lista[0]['nome'].toString();
        final valor2 = lista[0]['telefone'].toString();
        final valor3 = lista[0]['cpf'].toString();
        final valor4 = lista[0]['datanascimento'].toString();
        numeroClienteString = valor;
        
        String dataFormatada = valor4;
        if (dataFormatada.contains('1000-01-01') || dataFormatada == '01/01/1000') {
          dataFormatada = "";
        } else if (dataFormatada.isNotEmpty && dataFormatada != 'null') {
          try {
             dataFormatada = formatarData(dataFormatada);
          } catch (_) {}
        } else {
          dataFormatada = "";
        }
        nomeClienteDialogoController.text = valor1;
        telefoneClienteDialogoController.text = valor2;
        cpfClienteDialogoController.text = valor3;
        dataNascimentoClienteDialogoController.text = dataFormatada;
        
        setState(() {
          clienteJaCadastrado.value = true;
          clienteCadastradoVisual = true;
        });

        await atualizarValores(setStatePopup, valor1, valor2, valor3, dataFormatada);
        return true;
      } else {
        numeroClienteString = "0";
        setState(() {
          clienteJaCadastrado.value = false;
          clienteCadastradoVisual = false;
        });
        return false;
      }
    } catch (e) {
      numeroClienteString = "0";
      setState(() {
        clienteJaCadastrado.value = false;
        clienteCadastradoVisual = false;
      });
      return false;
    }
  }

  void verCadastroCliente (){
    bool podeCadastrar = false;

    if(nomeClienteDialogoController.text.isNotEmpty || telefoneClienteDialogoController.text.isNotEmpty || cpfClienteDialogoController.text.isNotEmpty || dataNascimentoClienteDialogoController.text.isNotEmpty){
      querCadastrarCliente = true;
    } else {
      querCadastrarCliente = false;
    }

    bool cadastroTelefoneCompleto = (nomeValido && telefoneValido && dataNascimentoValida) && (garcomController.tipoCadastroClienteTelefone.value);
    bool cadastroCpfCompleto = (nomeValido && cpfValido && dataNascimentoValida) && (garcomController.tipoCadastroClienteCpf.value);
    
    if(querCadastrarCliente){
      if(cadastroTelefoneCompleto || cadastroCpfCompleto){
        cadastrarCliente = true;
      }
    }
  }

  void validarCampos(){
    validarNomeDialogo(nomeClienteDialogoController.text);
    validarTelefoneDialogo(telefoneClienteDialogoController.text);
    validarCpfDialogo(cpfClienteDialogoController.text); 
    validarDataNascimentoDialogo(dataNascimentoClienteDialogoController.text);
  }

  bool validarCamposCadastroCliente(StateSetter setStatePopup){
    validarCampos();

    final bool nomeValido = nomeClienteDialogoController.text.isNotEmpty;
    bool valido = true;

    setStatePopup(() {
      // Limpa os erros antes de validar
      nomeErro = false;
      telefoneErro = false;
      cpfErro = false;
      dataNascimentoErro = false;
      
      bool focoAjustado = false;

      if (garcomController.tipoCadastroClienteTelefone.value) {
        if (!nomeValido) {
          nomeErro = true;
          valido = false;
          if (!focoAjustado) {
            focoAjustado = true;
            Future.delayed(Duration(milliseconds: 300), () {
              if (nomeClienteDialogoFocus.canRequestFocus) {
                nomeClienteDialogoFocus.requestFocus();
              }
            });
          }
        }

        if (!telefoneValido) {
          telefoneErro = true;
          valido = false;
          if (!focoAjustado) {
            focoAjustado = true;
            Future.delayed(Duration(milliseconds: 300), () {
              if (telefoneClienteDialogoFocus.canRequestFocus) {
                telefoneClienteDialogoFocus.requestFocus();
              }
            });
          }
        }

        if (!dataNascimentoValida) {
          dataNascimentoErro = true;
          valido = false;
          if (!focoAjustado) {
            focoAjustado = true;
            Future.delayed(Duration(milliseconds: 300), () {
              if (dataNascimentoClienteDialogoFocus.canRequestFocus) {
                dataNascimentoClienteDialogoFocus.requestFocus();
              }
            });
          }
        }
      } else if (garcomController.tipoCadastroClienteCpf.value) {
        if (!nomeValido) {
          nomeErro = true;
          valido = false;
          if (!focoAjustado) {
            focoAjustado = true;
            Future.delayed(Duration(milliseconds: 300), () {
              if (nomeClienteDialogoFocus.canRequestFocus) {
                nomeClienteDialogoFocus.requestFocus();
              }
            });
          }
        }

        if (!cpfValido) {
          cpfErro = true;
          valido = false;
          if (!focoAjustado) {
            focoAjustado = true;
            Future.delayed(Duration(milliseconds: 300), () {
              if (cpfClienteDialogoFocus.canRequestFocus) {
                cpfClienteDialogoFocus.requestFocus();
              }
            });
          }
        }

        if (!dataNascimentoValida) {
          dataNascimentoErro = true;
          valido = false;
          if (!focoAjustado) {
            focoAjustado = true;
            Future.delayed(Duration(milliseconds: 300), () {
              if (dataNascimentoClienteDialogoFocus.canRequestFocus) {
                dataNascimentoClienteDialogoFocus.requestFocus();
              }
            });
          }
        }
      }
    });

    setState(() {
      nomeErro = nomeErro;
      telefoneErro = telefoneErro;
      cpfErro = cpfErro;
      dataNascimentoErro = dataNascimentoErro;
    });

    return valido;
  }

  // Preencher campos cadastro cliente 
   puxarSeClienteCadastrado(String cpfOuTelefone) async {
    if(garcomController.tipoCadastroClienteCpf.value){
      // buscar por cpf 
      await buscarPorCpf(cpfOuTelefone);
    } else {
      // buscar por telefone 
      await buscarPorNumero(cpfOuTelefone);
    }
  }

  // Função para buscar cliente por cpf
  Future<void> buscarPorCpf(String cpf) async {
    try {
      // Permite a UI renderizar antes do processo pesado
      await Future.delayed(Duration.zero);

      String jsonResult = await Connection().select(
        "SELECT nome, datanascimento FROM clientes WHERE cpf='$cpf' LIMIT 1",
      );

      // Decode fora do setState
      final List<dynamic> lista = jsonDecode(jsonResult);

      if (lista.isNotEmpty) {
        final item = lista[0];

        String dataNascimento = item['datanascimento']?.toString() ?? '';
        String nome = item['nome']?.toString() ?? '';

        // Formatação de data FORA do setState
        String dataFormatada = '';
        if (dataNascimento.isNotEmpty && dataNascimento != 'null') {
          try {
            dataFormatada = formatarData(dataNascimento);
          } catch (_) {
            dataFormatada = '';
          }
        }

        if (!mounted) return;
        dataNascimentoClienteDialogoController.text = dataFormatada;
        nomeClienteDialogoController.text = nome;
        setState(() {
          clienteJaCadastrado.value = true;
          clienteCadastradoVisual = true;
        });
        if (estadoPopupCadastro != null) {
          estadoPopupCadastro!(() {
            clienteCadastradoVisual = true;
          });
        }
       
      } else {
        if (!mounted) return;
        setState(() {
          clienteJaCadastrado.value = false;
          clienteCadastradoVisual = false;
        });
        if (estadoPopupCadastro != null) {
          estadoPopupCadastro!(() {
            clienteCadastradoVisual = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      clienteJaCadastrado.value = false;
    }
  }

  // Função para buscar cliente por Numero
  Future<void> buscarPorNumero(String telefone) async {
    try {
      // Dá um respiro para a UI antes do processamento pesado
      await Future.delayed(Duration.zero);

      String jsonResult = await Connection().select(
        "SELECT nome, datanascimento FROM clientes WHERE (telefone='$telefone' OR telefone2='$telefone') LIMIT 1",
      );

      if (!mounted) return;

      // Decode fora do setState
      final List<dynamic> lista = jsonDecode(jsonResult);

      if (lista.isNotEmpty) {
        final item = lista[0];

        String dataNascimento = item['datanascimento']?.toString() ?? '';
        String nome = item['nome']?.toString() ?? '';

        // Formatação de data FORA do setState
        String dataFormatada = '';
        if (dataNascimento.isNotEmpty && dataNascimento != 'null') {
          try {
            dataFormatada = formatarData(dataNascimento);
          } catch (_) {
            dataFormatada = '';
          }
        }

        setState(() {
          dataNascimentoClienteDialogoController.text = dataFormatada;
          nomeClienteDialogoController.text = nome;
          clienteJaCadastrado.value = true;
          clienteCadastradoVisual = true;
        });
        if (estadoPopupCadastro != null) {
          estadoPopupCadastro!(() {
            clienteCadastradoVisual = true;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          clienteJaCadastrado.value = false;
          clienteCadastradoVisual = false;
        });
        if (estadoPopupCadastro != null) {
          estadoPopupCadastro!(() {
            clienteCadastradoVisual = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        clienteJaCadastrado.value = false;
        clienteCadastradoVisual = false;
      });
      if (estadoPopupCadastro != null) {
        estadoPopupCadastro!(() {
          clienteCadastradoVisual = false;
        });
      }
    }
  }

  // Carrega os valores da mesa e comanda - quando comanda aberta 
  void carregarValoresMesaComanda() {

    String numeroComanda = carrinhoController.numeroComanda.value;
    String numeroMesa = carrinhoController.numeroMesa.value;

    if(numeroMesa != "" || numeroComanda != ""){
      iniciaComCarrinho();
      entrarModoTouch();
    } else {
      chamarFocoInicial();
    }
  }

  void marcarObservacoes(List<String> observacoesTextoFuncao) {
    setState(() {
      observacoesSelecionadasObs.clear();
      observacoesSelecionadasObs.addAll(observacoesTextoFuncao);
    });
  }

  void marcarAdicionais(List<Produto> adicionaisFuncao) {
    setState(() {
      quantidadesAdicionais.clear();
      for (var adicional in adicionaisFuncao) {
        String numero = adicional.numero;
        double quantidade = adicional.quantidade;
        if (quantidadesAdicionais.containsKey(numero)) {
          quantidadesAdicionais[numero] = quantidadesAdicionais[numero]! + quantidade;
        } else {
          quantidadesAdicionais[numero] = quantidade;
        }
      }
    });
  }

  editarProdutoDoCarrinho(Produto produto, int index, String? produtoUnidade) {
    final String nomeFuncao = produto.nome;
    final String precoFuncao = produto.preco;
    final String numeroFuncao = produto.numero;

    // Observação digitada
    final String observacaoEscritaFuncao = produto.observacaoEscrita;

    // Observações selecionadas
    final List<String> observacoesTextoFuncao = produto.observacoesTexto;

    // Adicionais do produto
    final List<Produto> adicionaisFuncao = produto.adicionais;

    // ID para saber se é P, E ou PZ
    final String idFuncao = produto.id;

    // Verifica se o produto é vendido por Kg
    final bool ehKilo = nomeFuncao.contains("(Kg)");

    // meiaPorcaoFuncao = se o produto SUPORTA meia porção (vem da base de dados via produto.temMeiaPorcao)
    // produto.quantidade pode ser 0.5 mesmo que não seja meia porção ativa
    final bool estavaEmMeiaPorcao = produto.temMeiaPorcao && produto.quantidade == 0.5;

    final String quantidadeFormatada = ehKilo
      ? produto.quantidade.toString()
      : estavaEmMeiaPorcao ? produto.quantidade.toString() : produto.quantidade.toInt().toString();

    meiaPorcaoProduto = produto.temMeiaPorcao;
    // Inicializa meiaPorcaoClicado com base na quantidade salva, independente do valor numérico isolado
    meiaPorcaoClicado = estavaEmMeiaPorcao;

    // Produto normal ou adicional
    if (idFuncao == 'P' || idFuncao == 'E') {
      // Define se o produto é vendido por Kg
      produtoKilo = ehKilo;

      // Always clear or set observations and additionals to avoid state leaking
      marcarObservacoes(observacoesTextoFuncao);
      marcarAdicionais(adicionaisFuncao);

      if(observacoesTextoFuncao.isNotEmpty || adicionaisFuncao.isNotEmpty){
        mostrarAdicionaisEObservacoes(
          numeroFuncao, 
          nomeFuncao, 
          precoFuncao, 
          numeroFuncao, 
          produto.quantidade, 
          observacaoEscritaFuncao
        );
      }

      setState(() {
        // Atualiza os controllers
        cardapioController.text = nomeFuncao;
        numeroProdutoSelecionadoController.text = numeroFuncao;
        numeroDoProdutoSelecionado = numeroFuncao;
        valorDoProdutoSelecionado = precoFuncao;
        idDoProdutoSelecionado = idFuncao;
        quantidadeProdutoSelecionadoController.text = quantidadeFormatada;
        observacaoProdutoSelecionadoController.text = observacaoEscritaFuncao;

        aparecerBotoes = false;
        aparecerLista = false;
        aparecerCarrinho = false;
        aparecerConfiguracaoProduto = true;
        aparecerCardapio = true;
        cliqueiEditarProduto = true;
      });
    }

    // Produto do tipo pizza
    else if (idFuncao == 'PZ') {
      Get.offAllNamed(
        '/pizza',
        // preventDuplicates: false,
        arguments: {
          'tamanhoSelecionado': nomeFuncao,
          'comanda': comandaController.text,
          'mesa': mesaController.text,
          'produtoSelecionado': produto,
          'index': index,
          'editar': true,
          'numeroDoPedido': numeroDoPedido,
          'clienteNome': nomeClienteDialogoController.text,
          'clienteCpf': cpfClienteDialogoController.text,
          'clienteTelefone': telefoneClienteDialogoController.text,
          'clienteDataNascimento': dataNascimentoClienteDialogoController.text,
        },
      )?.then((_) {
        if (mounted) {
          // Garante que o modo touch é desativado e o carrinho aparece ao retornar da PizzaPage.
          sairModoTouch();
        }
      });
    }
  }

  // Salvar ultimo modo de visualizacao
  Future<void> salvarUltimoAdicionalObservacaoSelecionado(String modo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'carregar_ultimo_adicional_observacao_selecionado',
        modo,
      );
    } catch (e, st) {
      // debugPrint("Erro salvarRota(): $e\n$st");
    }
  }

  // Carregar ultimo modo de visualizacao
  Future<void> carregarUltimoAdicionalObservacaoSelecionado() async {
    final prefs = await SharedPreferences.getInstance();
    final modo = prefs.getString('carregar_ultimo_adicional_observacao_selecionado');
    if (modo != null) {
      if(modo == "lista"){
        aparecerGrid = false;
      }else{
        aparecerGrid = true;
      }
    }
  }

  // Salvar ultima configuracao
  Future<void> salvarUltimaConfiguracao(String rotasSalvas) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'carregar_ultima_configuracao',
        rotasSalvas,
      );
    } catch (e, st) {
      // debugPrint("Erro salvarRota(): $e\n$st");
    }
  }

  // Carregar ultima configuracao
  Future<void> carregarUltimaConfiguracao() async {
    final prefs = await SharedPreferences.getInstance();
    final modo = prefs.getString('carregar_ultima_configuracao');

    if (modo == "Touch") {
      entrarModoTouch();
    } else {
      sairModoTouch();
    }
  }

  /* Future<void> _carregarPreco() async {
    final prefs = await SharedPreferences.getInstance();
    final modo = prefs.getString('carregar_aparecer_preco');

    if (modo == "Sim") {
      aparecerPreco = true;
    } else {
      aparecerPreco = false;
    }
  }

  Future<void> salvarAparecerPreco(String modo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('carregar_aparecer_preco', modo);
    } catch (e, st) {
      // debugPrint("Erro salvarRota(): $e\n$st");
    }
  } */

  /// Seleciona automaticamente o primeiro grupo disponível e carrega seus produtos.
  void _selecionarPrimeiroGrupo() {
    if (funcoesController.listaGrupo.isEmpty) return;

    final primeiro = funcoesController.listaGrupo.first;
    setState(() {
      grupoSelecionadoNoTouch = primeiro['numero'].toString();
      produtosFiltrados = produtosPorGrupo(grupoSelecionadoNoTouch);
    });
  }

  void _selecionarUltimoGrupo() {
    if (funcoesController.listaGrupo.isEmpty) return;

    final ultimo = funcoesController.listaGrupo[posicaoUltimoGrupo];
    setState(() {
      grupoSelecionadoNoTouch = ultimo['numero'].toString();
      produtosFiltrados = produtosPorGrupo(grupoSelecionadoNoTouch);
    });
  } 

  void _guardarUltimoGrupoPosicao(int posicao){
    posicaoUltimoGrupo = posicao;
  }

  iniciarModoTouch(){
    setState(() {
      modoAnteriorTouch = false;
      aparecerCarrinho = false;
      aparecerConfiguracaoProduto = false;
      aparecerVendaTouch = true;
      cardapioController.clear();
      cardapioController.text = "";
    });

    // _selecionarPrimeiroGrupo();
    String modo = "Touch";
    salvarUltimaConfiguracao(modo);
  }

  entrarModoTouch(){
    FocusScope.of(context).unfocus();

    setState(() {
      // forcar aparecer carrinho
      aparecerCarrinhoForcado = true;
      aparecerLista = false;
      modoAnteriorTouch = false;
      aparecerCarrinho = false;
      aparecerConfiguracaoProduto = false;
      aparecerVendaTouch = true;
      cardapioController.clear();
      cardapioController.text = "";
    });

    cliqueiEditarProduto = false;
    meiaPorcaoProduto = false;
    
    // _selecionarPrimeiroGrupo();
    String modo = "Touch";
    salvarUltimaConfiguracao(modo);
    Future.delayed(const Duration(milliseconds: 300), () {
      cardapioFocus.unfocus();
    }); 
    _selecionarUltimoGrupo();
  }

  sairModoTouch(){ //carrinho
    // FocusScope.of(context).unfocus();
    setState(() {
      modoAnteriorTouch = true;
      aparecerCarrinho = true;
      aparecerConfiguracaoProduto = false;
      aparecerVendaTouch = false;
      grupoSelecionadoNoTouch = "";
      cardapioController.clear();
      cardapioController.text = "";
    });
    cliqueiEditarProduto = false;
    meiaPorcaoProduto = false;
    /* Future.delayed(Duration(milliseconds: 300), () {
      if (cardapioFocus.canRequestFocus) {
        cardapioFocus.requestFocus();
      }
    });  */
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && cardapioFocus.canRequestFocus && cardapioFocus.context != null) {
        // cardapioFocus.requestFocus();
        cardapioFocus.unfocus();
      }
    });
    String modo = "Carrinho";
    salvarUltimaConfiguracao(modo);
  }

  Future<void> tirarFoco() async {
    comandaFocus.unfocus();
    mesaFocus.unfocus();
    cardapioFocus.unfocus();
    numeroProdutoSelecionadoFocus.unfocus();
    quantidadeProdutoSelecionadoFocus.unfocus();
    observacaoProdutoSelecionadoFocus.unfocus();
    senhaFocus.unfocus();
    FocusScope.of(context).unfocus();
  }

  void iniciarComandaMesa() {
    if (funcoesController.logicaPorMesa.value) {
      mesaController.addListener(_onMesaChanged);
    } else if (funcoesController.logicaPorComanda.value) {
      comandaController.addListener(_onComandaChanged);
    } else if (funcoesController.logicaPorComandaNaMesa.value) {
      comandaController.addListener(_onComandaChanged);
    }
  }

  // Função para mostrar aviso de carrinho cheio
  void avisoCarrinhoCheio() {
    shownDialogErrorTwoBottom(
      context: context,
      title: "Carrinho cheio!",
      message: "Deseja descartar este pedido?",
      icon: Icons.shopping_cart,
      onConfirm: () async {
        _executarLimpezaGeral();
      },
      onCancel: () async {
        _isZerando = false;
        comandaController.removeListener(_onComandaChanged);
        mesaController.removeListener(_onMesaChanged);

        comandaController.text = numeroComandaEmUso;
        mesaController.text = numeroMesaEmUso;

        comandaController.addListener(_onComandaChanged);
        mesaController.addListener(_onMesaChanged);

        setState(() {
          aparecerCardapio = true;
          aparecerCarrinho = true;
          aparecerLista = false;
          aparecerConfiguracaoProduto = false;
        });
      },
    );
  }

  // Verificar se tem conta quando reconstroi a tela
  verificarSeTemConta(String numero) async {
    if (funcoesController.logicaPorComanda.value ||
        funcoesController.logicaPorComandaNaMesa.value) {
      String dadosJson = await Connection().select(
        "SELECT valorliquidopedido FROM cartoes WHERE numero='$numero';",
      );
      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        double valorLiquido = double.tryParse(lista[0]['valorliquidopedido'].toString()) ?? 0.0;
        if (valorLiquido != 0.0) {
          setState(() {
            mostrarDentroComandaMesa = true;
          });
        } else {
          setState(() {
            mostrarDentroComandaMesa = false;
          });
        }
      } else {
        setState(() {
          mostrarDentroComandaMesa = false;
        });
      }
    } else {
      String dadosJson = await Connection().select(
        "SELECT valorliquidopedido FROM mesas WHERE numero='$numero';",
      );
      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        double valorLiquido =  double.tryParse(lista[0]['valorliquidopedido'].toString()) ?? 0.0;
        if (valorLiquido != 0.0) {
          setState(() {
            mostrarDentroComandaMesa = true;
          });
        } else {
          setState(() {
            mostrarDentroComandaMesa = false;
          });
        }
      } else {
        setState(() {
          mostrarDentroComandaMesa = false;
        });
      }
    }
  }

  // Função para iniciar com carrinho
  void iniciaComCarrinho() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Get.arguments != null) {

      String comandaDoPedido = Get.arguments['comanda'] ?? '';
      String mesaDoPedido = Get.arguments['mesa'] ?? '';
      String numeropedido = Get.arguments['numeropedido'] ?? '0';

      String clienteId = Get.arguments['clienteId'] ?? '';
      String clienteNome = Get.arguments['clienteNome'] ?? '';
      String clienteCpf = Get.arguments['clienteDocumento'] ?? '';
      String clienteTelefone = Get.arguments['clienteTelefone'] ?? '';
      String clienteDataNascimento = Get.arguments['clienteDataNascimento'] ?? '';

      if (mesaDoPedido == "0" || mesaDoPedido == '0') {
        mesaDoPedido = "";
      }

      if(mesaDoPedido == ""){
        mesaDoPedido = carrinhoController.numeroMesa.value;
      }

      if (comandaDoPedido == "0" || comandaDoPedido == '0') {
        comandaDoPedido = "";
      }

      if(comandaDoPedido == ""){
        comandaDoPedido = carrinhoController.numeroComanda.value;
      }

      if(clienteId == ""){
        clienteId = carrinhoController.clienteId.value;
      }

      if(clienteNome == ""){
        clienteNome = carrinhoController.clienteNome.value;
      }

      if(clienteCpf == ""){
        clienteCpf = carrinhoController.clienteCpf.value;
      }

      if(clienteTelefone == ""){
        clienteTelefone = carrinhoController.clienteTelefone.value;
      }

      if(clienteDataNascimento == ""){
        clienteDataNascimento = carrinhoController.clienteDataNascimento.value;
      }

      carrinhoController.clienteId.value = clienteId;
      carrinhoController.clienteNome.value = clienteNome;
      carrinhoController.clienteCpf.value = clienteCpf;
      carrinhoController.clienteTelefone.value = clienteTelefone;
      carrinhoController.clienteDataNascimento.value = clienteDataNascimento;

      nomeClienteDialogoController.text = clienteNome;
      telefoneClienteDialogoController.text = clienteTelefone;
      cpfClienteDialogoController.text = clienteCpf;
      dataNascimentoClienteDialogoController.text = clienteDataNascimento;

      // await buscarTipoPedido();

      if (numeropedido == "0") {
        if (funcoesController.logicaPorComanda.value ||
            funcoesController.logicaPorComandaNaMesa.value) {
          validarComanda(comandaDoPedido);
        } else {
          validarMesa(mesaDoPedido);
        }
      } else {
        if (funcoesController.logicaPorComanda.value ||
            funcoesController.logicaPorComandaNaMesa.value) {
          verificarSeTemConta(comandaDoPedido);
        } else {
          verificarSeTemConta(mesaDoPedido);
        }

        if (funcoesController.logicaPorComanda.value ||
            funcoesController.logicaPorComandaNaMesa.value) {
          buscarNumeroPedido(comandaDoPedido);
        } else {
          buscarNumeroPedido(mesaDoPedido);
        }
      }

      informacoesCliente();

      setState(() {
        volteiPizza = true;
        aparecerCarrinho = true;
        aparecerCardapio = true;
        showKeyboardAlfa = false;

        showKeyboardQuantidade = false;
        aparecerLista = false;
        aparecerConfiguracaoProduto = false;
        aparecerBotoes = false;
        comandaController.text = comandaDoPedido;
        mesaController.text = mesaDoPedido;
        aparecerFazerPedido = true;

        numeroComandaEmUso = comandaDoPedido;
        numeroMesaEmUso = mesaDoPedido;

        _campoAtivo = 'cardapioController';

        Future.delayed(Duration(milliseconds: 300), () {
          if (cardapioFocus.canRequestFocus) {
            cardapioFocus.requestFocus();
          }
        });
      });

      sairModoTouch();
      } else {
        String comandaDoPedido = carrinhoController.numeroComanda.value;
        String mesaDoPedido = carrinhoController.numeroMesa.value;
        String numeropedido = "";

        String clienteId = carrinhoController.clienteId.value;
        String clienteNome = carrinhoController.clienteNome.value;
        String clienteCpf = carrinhoController.clienteCpf.value;
        String clienteTelefone = carrinhoController.clienteTelefone.value;
        String clienteDataNascimento = carrinhoController.clienteDataNascimento.value;
        
        if (funcoesController.logicaPorComanda.value ||
            funcoesController.logicaPorComandaNaMesa.value) {
          await buscarNumeroPedido(comandaDoPedido);
          numeropedido = carrinhoController.numeroPedido.value;
        } else {
          await buscarNumeroPedido(mesaDoPedido);
          numeropedido = carrinhoController.numeroPedido.value;
        }

        if (mesaDoPedido == "0" || mesaDoPedido == '0') {
          mesaDoPedido = "";
        }

        if(mesaDoPedido == ""){
          mesaDoPedido = carrinhoController.numeroMesa.value;
        }

        if (comandaDoPedido == "0" || comandaDoPedido == '0') {
          comandaDoPedido = "";
        }

        if(comandaDoPedido == ""){
          comandaDoPedido = carrinhoController.numeroComanda.value;
        }

        carrinhoController.clienteId.value = clienteId;
        carrinhoController.clienteNome.value = clienteNome;
        carrinhoController.clienteCpf.value = clienteCpf;
        carrinhoController.clienteTelefone.value = clienteTelefone;
        carrinhoController.clienteDataNascimento.value = clienteDataNascimento;

        nomeClienteDialogoController.text = clienteNome;
        telefoneClienteDialogoController.text = clienteTelefone;
        cpfClienteDialogoController.text = clienteCpf;
        dataNascimentoClienteDialogoController.text = clienteDataNascimento;

        // await buscarTipoPedido();

        if (numeropedido == "0") {
          if (funcoesController.logicaPorComanda.value ||
              funcoesController.logicaPorComandaNaMesa.value) {
            validarComanda(comandaDoPedido);
          } else {
            validarMesa(mesaDoPedido);
          }
        } else {
          if (funcoesController.logicaPorComanda.value ||
              funcoesController.logicaPorComandaNaMesa.value) {
            verificarSeTemConta(comandaDoPedido);
          } else {
            verificarSeTemConta(mesaDoPedido);
          }

          if (funcoesController.logicaPorComanda.value ||
              funcoesController.logicaPorComandaNaMesa.value) {
            buscarNumeroPedido(comandaDoPedido);
          } else {
            buscarNumeroPedido(mesaDoPedido);
          }
        }

        informacoesCliente();

        setState(() {
          volteiPizza = true;
          aparecerCarrinho = true;
          aparecerCardapio = true;
          showKeyboardAlfa = false;

          showKeyboardQuantidade = false;
          aparecerLista = false;
          aparecerConfiguracaoProduto = false;
          aparecerBotoes = false;
          comandaController.text = comandaDoPedido;
          mesaController.text = mesaDoPedido;
          aparecerFazerPedido = true;

          numeroComandaEmUso = comandaDoPedido;
          numeroMesaEmUso = mesaDoPedido;

          _campoAtivo = 'cardapioController';

          Future.delayed(Duration(milliseconds: 300), () {
            if (cardapioFocus.canRequestFocus) {
              cardapioFocus.requestFocus();
            }
          });
        });

        sairModoTouch();
      }
    });
  }

  // ─── Bloqueio global de foco ────────────────────────────────────────────────

  /// Ativa o modo de bloqueio de foco: o [_focoBloqueio] sequestra o
  /// primaryFocus do [FocusManager], impedindo que qualquer outro FocusNode
  /// da árvore receba foco enquanto o bloqueio estiver ativo.
  ///
  /// Como funciona:
  ///   1. Desabilitamos [FocusManager.instance.highlightStrategy] para suprimir
  ///      qualquer sinal de highlight durante o período.
  ///   2. Chamamos [_focoBloqueio.requestFocus()] via [FocusManager.instance]
  ///      para que ele assuma o primaryFocus imediatamente.
  ///   3. Qualquer chamada subsequente a [requestFocus()] em outros nós será
  ///      ignorada pelo Flutter pois [_focoBloqueio] retém o primaryFocus e
  ///      não está dentro da rota de baixo.
  void _bloquearFocoGlobal() {
    if (_bloqueandoFoco) return;
    _bloqueandoFoco = true;
    // Remove qualquer foco ativo antes de assumir
    FocusManager.instance.primaryFocus?.unfocus();
    // Solicita foco para o nó bloqueio — ele passa a ser o primaryFocus
    FocusScope.of(context).requestFocus(_focoBloqueio);
    // Bloqueia também toda interação de toque na tela
    if (mounted) {
      setState(() {
        _telaBloqueada = true;
      });
    }
    debugPrint('[FOCO-GARCOM] Bloqueio global de foco ATIVADO');
  }

  /// Desativa o modo de bloqueio de foco e libera o [_focoBloqueio].
  void _liberarFocoGlobal() {
    if (!_bloqueandoFoco) return;
    _bloqueandoFoco = false;
    _focoBloqueio.unfocus();
    // Libera a interação de toque na tela
    if (mounted) {
      setState(() {
        _telaBloqueada = false;
      });
    }
    debugPrint('[FOCO-GARCOM] Bloqueio global de foco LIBERADO');
  }

  // ─── Diálogo de sucesso ──────────────────────────────────────────────────────

  // Função para mostrar mensagem de venda inserida com sucesso
  /// Exibe o diálogo de sucesso e aguarda seu fechamento antes de retornar.
  /// A tela fica bloqueada para toque durante todo o período.
  Future<void> vendaInseridaComSucesso() async {
    if (!mounted) return;

    // 1. Bloqueia foco + toque ANTES de abrir o diálogo
    _bloquearFocoGlobal();

    // 2. Completer garante que o await só resolve quando o diálogo fechar
    final completer = Completer<void>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // Agenda o fechamento do diálogo
        Future.delayed(const Duration(milliseconds: 1388), () {
          if (Navigator.canPop(ctx)) {
            Navigator.pop(ctx);
          }
        });

        // FocusScope protege descendentes do diálogo
        return FocusScope(
          canRequestFocus: false,
          descendantsAreFocusable: false,
          child: Center(
            child: TweenAnimationBuilder(
              duration: const Duration(milliseconds: 500),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                            size: 80,
                          ),
                          const SizedBox(height: 20),
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
          ),
        );
      },
    );

    // 3. Só libera foco/toque após o diálogo ter fechado de fato
    _liberarFocoGlobal();
    if (!completer.isCompleted) completer.complete();
    return completer.future;
  }

  // Função para mostrar mensagem de erro ao inserir pedido
  /// Exibe o diálogo de erro e aguarda seu fechamento antes de retornar.
  /// A tela fica bloqueada para toque durante todo o período.
  Future<void> erroAoInserirPedido() async {
    if (!mounted) return;

    // 1. Bloqueia foco + toque ANTES de abrir o diálogo
    _bloquearFocoGlobal();

    final completer = Completer<void>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 1388), () {
          if (Navigator.canPop(ctx)) {
            Navigator.pop(ctx);
          }
        });

        return FocusScope(
          canRequestFocus: false,
          descendantsAreFocusable: false,
          child: Center(
            child: TweenAnimationBuilder(
              duration: const Duration(milliseconds: 500),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error,
                            color: Theme.of(context).colorScheme.error,
                            size: 80,
                          ),
                          const SizedBox(height: 20),
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
          ),
        );
      },
    );

    // 3. Só libera foco/toque após o diálogo ter fechado de fato
    _liberarFocoGlobal();
    if (!completer.isCompleted) completer.complete();
    return completer.future;
  }

  // Função para reiniciar a página
  void reiniciarPage() {
    zerarAtendimento();
    setState(() {
      aparecerBotoes = false;
      aparecerCardapio = false;
      showKeyboardNumero = true;
      aparecerConfiguracaoProduto = false;
      aparecerLista = false;
    });
  }

  // Funcao que chama enviarCarrinho
  Future<void> enviarCarrinhoComandas(
    ComandaCarrinhoController comandasController,
  ) async {
    final listaComandas = List<CarrinhoArmazenado>.from(
      comandasController.listaCompleta,
    );
    bool houveErroGeral = false;

    for (var comandaItem in listaComandas) {
      // Garante que mesa e comanda não cheguem vazios ao banco
      final String mesaFinal = comandaItem.mesa.isEmpty
          ? "0"
          : comandaItem.mesa;
      final String comandaFinal = comandaItem.comanda.isEmpty
          ? "0"
          : comandaItem.comanda;

      bool sucessoComanda = await enviarCarrinhoParaComandas(
        produtos:
            comandaItem.produtos, // Passa os produtos específicos desta comanda
        numeroComanda: comandaFinal,
        numeroMesa: mesaFinal,
        numeroTradepoint: numeroDaLicencaSelecionada,
      );

      if (sucessoComanda) {
        // Se a comanda enviou com sucesso, removemos ela do repositório local
        comandasController.removerCarrinho(
          comandaItem.mesa,
          comandaItem.comanda,
        );
      } else {
        houveErroGeral = true;
      }
    }

    if (!houveErroGeral) {
      // Se TUDO deu certo, limpa a página (vai pro garçom) e avisa
      await tirarFoco();
      await vendaInseridaComSucesso();
      await zerarAtendimento();
      await limparAmbas();
      // Aguarda o diálogo fechar (1388ms) + margem antes de devolver o foco.
      // Isso evita o race condition onde chamarFoco() disparava DURANTE o diálogo.
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) chamarFoco();
      });
    } else {
      // Se algo falhou, avisa o erro (as comandas que falharam continuam na lista)
      erroAoInserirPedido();
      if (mounted) {
        setState(() {
          aparecerBotoes = false;
          aparecerCardapio = false;
          showKeyboardNumero = true;
          aparecerConfiguracaoProduto = false;
          aparecerLista = false;
          aparecerCarrinho = true;
        });
      }
    }
  }

  // Função intermediária para enviar o carrinho inteiro para inserirProdutos
  Future<bool> enviarCarrinhoParaComandas({
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
        final partes = montarSaboresEBordas(produto.adicionais);

        if(produto.quantidade > 1){
          for(int i = 0; i < produto.quantidade; i++){
            sucesso = await inserirProdutosPizza(
              produto.numero,
              numeroComanda,
              numeroMesa,
              produto.nome,
              produto.observacaoEscrita,
              '',
              1.0,
              numeroTradepoint,
              produto.id,
              montarPartesPizza(produto.adicionais), // divisão 00000000
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
        } else {
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
              montarPartesPizza(produto.adicionais), // divisão 00000000
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
        }
      if (!sucesso) {
        todasSucesso = false;
      }
    }

    return todasSucesso;
  }

  // Função intermediária para enviar o carrinho inteiro para inserirProdutos
  Future<void> enviarCarrinho({
    required String numeroComanda,
    required String numeroMesa,
    required String numeroTradepoint,
  }) async {
    //  Cópia imutável do carrinho
    final List<Produto> carrinhoSnapshot = List.from(
      carrinhoController.carrinho,
    );

    if (carrinhoSnapshot.isEmpty) {
      await tirarFoco();
      await vendaInseridaComSucesso();
      await limparAmbas();
      await zerarAtendimento();
      Future.delayed(const Duration(milliseconds: 2000), () {
        chamarFoco();
      });
      return;
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
        final partes = montarSaboresEBordas(produto.adicionais);

        if(produto.quantidade > 1){
          for(int i = 0; i < produto.quantidade; i++){
            sucesso = await inserirProdutosPizza(
              produto.numero,
              numeroComanda,
              numeroMesa,
              produto.nome,
              produto.observacaoEscrita,
              '',
              1.0,
              numeroTradepoint,
              produto.id,
              montarPartesPizza(produto.adicionais), // divisão 00000000
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
        } else {

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
          montarPartesPizza(produto.adicionais), // divisão 00000000
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
      }

      if (!sucesso) {
        todasSucesso = false;
      }
    }

    if (todasSucesso) {
      await tirarFoco();
      await vendaInseridaComSucesso();
      await limparAmbas();
      await zerarAtendimento();
      // Aguarda o diálogo fechar (1388ms) + margem antes de devolver o foco.
      // Isso evita o race condition onde chamarFoco() disparava DURANTE o diálogo.
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) chamarFoco();
      });
    } else {
      erroAoInserirPedido();
      setState(() {
        aparecerBotoes = false;
        aparecerCardapio = false;
        showKeyboardNumero = true;
        aparecerConfiguracaoProduto = false;
        aparecerLista = false;
        aparecerCarrinho = true;
      });
    }
  }

  // Montar números de sabores e bordas
  PartesPizza montarSaboresEBordas(List<Produto> adicionais) {
    List<String> sabores = [];
    List<String> obsSabores = [];
    List<String> bordas = [];
    List<String> obsBordas = [];

    for (var adicional in adicionais) {
      if (adicional.id == 'P') {
        sabores.add(adicional.numero);
        obsSabores.add(adicional.observacaoEscrita ?? '');
      }

      if (adicional.id == 'B') {
        bordas.add(adicional.numero);
        obsBordas.add(adicional.observacaoEscrita ?? '');
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
    // Retorna uma string com os sabores de pizza completados com zeros
    const int totalDigitos = 8;

    // StringBuffer é só uma forma eficiente de ir juntando textos aos poucos.
    StringBuffer buffer = StringBuffer();

    /* for (final adicional in adicionais) { // Varre todos os adicionais
      if (adicional.id == 'P') {
        for (int i = 0; i < adicional.quantidade; i++) { // Varre a quantidade de cada adicional
          buffer.write(adicional.numero); // Adiciona o número do adicional
        }
      }
    } */
    for (final adicional in adicionais) {
      // Varre todos os adicionais
      if (adicional.id == 'P') {
        buffer.write(adicional.quantidade.toString());
        /*  for (int i = 0; i < adicional.quantidade; i++) { // Varre a quantidade de cada adicional
          buffer.write(adicional.numero); // Adiciona o número do adicional
        } */
      }
    }

    String resultado = buffer.toString(); // Transforma o StringBuffer em String

    // Completa com zeros se faltar
    if (resultado.length < totalDigitos) {
      resultado = resultado.padRight(totalDigitos, '0');
    }

    // Corta se passar de 8
    if (resultado.length > totalDigitos) {
      resultado = resultado.substring(0, totalDigitos);
    }

    return resultado; // Retorna buffer.toString();
  }

  // Função para montar observação de pizza
  String montarObservacoesPizza(Produto produto) {
    if (produto.adicionais.isEmpty) return '';

    return produto.adicionais
        .expand((a) => List.filled(a.quantidade.toInt(), a.nome))
        .join(' | ');
  }

  // Função para montar observação
  /* String montarObservacoes(Produto produto, List<Produto> adicionais) {
    final List<String> obs = [];

    if (produto.observacaoEscrita.isNotEmpty) {
      obs.add(produto.observacaoEscrita);
    }

    if (produto.observacoesTexto.isNotEmpty) {
      obs.addAll(produto.observacoesTexto);
    }

    // Varrendo os adicionais para incluir o nome nas observações
    /* if (adicionais.isNotEmpty) {
      for (var adicional in adicionais) {
        if (adicional.quantidade > 1) {
          // obs.add("${adicional.quantidade}x ${adicional.nome}");
          obs.add(adicional.nome);
        } else {
          obs.add(adicional.nome);
        }
      }
    } */

    return obs.join('|');
  } */

  // Função para montar observação
  String montarObservacoes(Produto produto, List<Produto> adicionais) {
    final List<String> obs = [];

    if (produto.observacaoEscrita.isNotEmpty) {
      obs.add(produto.observacaoEscrita);
    }

    if (produto.observacoesTexto.isNotEmpty) {
      obs.addAll(produto.observacoesTexto);
    }

    if (obs.isEmpty) return '';

    return '${obs.join('|')}|';
  }

  // Função para montar adicionais produto tipo P
  /* String montarAdicionais(Produto produto) {
    if (produto.adicionais.isEmpty) return '';
    return produto.adicionais
        .expand((a) => List.filled(a.quantidade.toInt(), a.numero))
        .join('|');
  } */

 String montarAdicionais(Produto produto) {
    if (produto.adicionais.isEmpty) return '';

    final adicionais = produto.adicionais
        .expand((a) => List.filled(a.quantidade.toInt(), a.numero))
        .join('|');

    return '$adicionais|';
  }

  // Função para completar com zeros os sabores de pizza
  String completarComZeros(String divisaoDeSabores) {
    const int totalDigitos = 8;

    // Se já tiver 8 ou mais, corta para 8
    if (divisaoDeSabores.length >= totalDigitos) {
      return divisaoDeSabores.substring(0, totalDigitos);
    }

    // Completa com zeros até dar 8
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
    String divisaoDeSabores, // 00000000
    String numerosabor1_FK,
    String numerosabor2_FK,
    String numerosabor3_FK,
    String numerosabor4_FK,
    String numerosabor5_FK,
    String numerosabor6_FK,
    String numerosabor7_FK,
    String numerosabor8_FK,
    String obssabor1,
    String obssabor2,
    String obssabor3,
    String obssabor4,
    String obssabor5,
    String obssabor6,
    String obssabor7,
    String obssabor8,
    String numeroborda1_FK,
    String numeroborda2_FK,
    String numeroborda3_FK,
    String numeroborda4_FK,
    String numeroborda5_FK,
    String numeroborda6_FK,
    String numeroborda7_FK,
    String numeroborda8_FK,
    String obsborda1,
    String obsborda2,
    String obsborda3,
    String obsborda4,
    String obsborda5,
    String obsborda6,
    String obsborda7,
    String obsborda8,
  ) async {
    String divisaoDeSaboresParaInsert = completarComZeros(divisaoDeSabores);
    String numeroSerie = '1';
    String numeroTradepointParaInsert = numeroTradepoint;
    String numeroUsuarioFK = numeroDoGarcom;
    String numeroComandaParaInsert = numeroComanda;
    String numeroProdutoParaInsert = numeroDoProduto;
    double quantidadeParaInsert = quantidade;
    String observacaoParaInsert = observacao;
    String adicionalParaInsert = adicional;
    String nomeProdutoParaInsert = nomeProduto;
    /* int numeroMesaParaInsert = int.tryParse(numeroMesa) ?? 0; */
    String numeroMesaParaInsert = numeroMesa;
    String status = '1';

    // Números sabores
    String numerosabor1_FKParaInsert = numerosabor1_FK;
    String numeroSabor2_FKParaInsert = numerosabor2_FK;
    String numeroSabor3_FKParaInsert = numerosabor3_FK;
    String numeroSabor4_FKParaInsert = numerosabor4_FK;
    String numeroSabor5_FKParaInsert = numerosabor5_FK;
    String numeroSabor6_FKParaInsert = numerosabor6_FK;
    String numeroSabor7_FKParaInsert = numerosabor7_FK;
    String numeroSabor8_FKParaInsert = numerosabor8_FK;

    // Observações sabores
    String obsabor1ParaInsert = obssabor1;
    String obsabor2ParaInsert = obssabor2;
    String obsabor3ParaInsert = obssabor3;
    String obsabor4ParaInsert = obssabor4;
    String obsabor5ParaInsert = obssabor5;
    String obsabor6ParaInsert = obssabor6;
    String obsabor7ParaInsert = obssabor7;
    String obsabor8ParaInsert = obssabor8;

    // Números bordas
    String numeroborda1_FKParaInsert = numeroborda1_FK;
    String numeroborda2_FKParaInsert = numeroborda2_FK;
    String numeroborda3_FKParaInsert = numeroborda3_FK;
    String numeroborda4_FKParaInsert = numeroborda4_FK;
    String numeroborda5_FKParaInsert = numeroborda5_FK;
    String numeroborda6_FKParaInsert = numeroborda6_FK;
    String numeroborda7_FKParaInsert = numeroborda7_FK;
    String numeroborda8_FKParaInsert = numeroborda8_FK;

    // Observações bordas
    String obsborda1ParaInsert = obsborda1;
    String obsborda2ParaInsert = obsborda2;
    String obsborda3ParaInsert = obsborda3;
    String obsborda4ParaInsert = obsborda4;
    String obsborda5ParaInsert = obsborda5;
    String obsborda6ParaInsert = obsborda6;
    String obsborda7ParaInsert = obsborda7;
    String obsborda8ParaInsert = obsborda8;

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
          obsborda8,
          numerocliente_FK
        ) VALUES (
          '$numeroSerie',
          '$numeroTradepointParaInsert',
          '$numeroUsuarioFK',
          '$numeroComandaParaInsert',
          '$numeroProdutoParaInsert',
          $quantidadeParaInsert,
          '$observacaoParaInsert',
          '$adicionalParaInsert',
          '$nomeProdutoParaInsert',
          '$numeroMesaParaInsert',
          '$status',
          '$divisaoDeSaboresParaInsert',
          '$numerosabor1_FKParaInsert',
          '$numeroSabor2_FKParaInsert',
          '$numeroSabor3_FKParaInsert',
          '$numeroSabor4_FKParaInsert',
          '$numeroSabor5_FKParaInsert',
          '$numeroSabor6_FKParaInsert',
          '$numeroSabor7_FKParaInsert',
          '$numeroSabor8_FKParaInsert',
          '$obsabor1ParaInsert',
          '$obsabor2ParaInsert',
          '$obsabor3ParaInsert',
          '$obsabor4ParaInsert',
          '$obsabor5ParaInsert',
          '$obsabor6ParaInsert',
          '$obsabor7ParaInsert',
          '$obsabor8ParaInsert',
          '$numeroborda1_FKParaInsert',
          '$numeroborda2_FKParaInsert',
          '$numeroborda3_FKParaInsert',
          '$numeroborda4_FKParaInsert',
          '$numeroborda5_FKParaInsert',
          '$numeroborda6_FKParaInsert',
          '$numeroborda7_FKParaInsert',
          '$numeroborda8_FKParaInsert',
          '$obsborda1ParaInsert',
          '$obsborda2ParaInsert',
          '$obsborda3ParaInsert',
          '$obsborda4ParaInsert',
          '$obsborda5ParaInsert',
          '$obsborda6ParaInsert',
          '$obsborda7ParaInsert',
          '$obsborda8ParaInsert',
          '$numeroClienteString'
        )
      """;
      print('SQL: $sql');

      String resultado = await Connection().ipd(sql);

      if (resultado == 'sucesso') {
        print(
          "Venda inserida com sucesso! Pedido: $numeroComanda | Produto: $nomeProduto",
        );
        return true;
      } else {
        print("Erro ao inserir venda: $resultado");
        return false;
      }
    } catch (e) {
      print("Erro inesperado ao inserir venda: $e");
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
    String divisaoDeSabores, // 00000000
  ) async {
    String divisaoDeSaboresParaInsert = completarComZeros(divisaoDeSabores);
    String numeroSerie = '1';
    String numeroTradepointParaInsert = numeroTradepoint;
    String numeroUsuarioFK = numeroDoGarcom;
    String numeroComandaParaInsert = numeroComanda;
    String numeroProdutoParaInsert = numeroDoProduto;
    double quantidadeParaInsert = quantidade;
    String observacaoParaInsert = observacao;
    String adicionalParaInsert = adicional;
    String nomeProdutoParaInsert = nomeProduto;
    /* int numeroMesaParaInsert = int.tryParse(numeroMesa) ?? 0; */
    String numeroMesaParaInsert = numeroMesa;
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
          status,
          divisaosabores,
          numerocliente_FK
        ) VALUES (
          '$numeroSerie',
          '$numeroTradepointParaInsert',
          '$numeroUsuarioFK',
          '$numeroComandaParaInsert',
          '$numeroProdutoParaInsert',
          $quantidadeParaInsert,
          '$observacaoParaInsert',
          '$adicionalParaInsert',
          '$nomeProdutoParaInsert',
          '$numeroMesaParaInsert',
          '$status',
          '$divisaoDeSaboresParaInsert',
          '$numeroClienteString'
        )
      """;

      String resultado = await Connection().ipd(sql);
      print('>>>>>>>>>>>>>>>>>>>>>>resultado: $resultado');

      if (resultado == 'sucesso') {
        print(
          "Venda inserida com sucesso! Pedido: $numeroComanda | Produto: $nomeProduto",
        );
        return true;
      } else {
        print("Erro ao inserir venda: $resultado");
        return false;
      }
    } catch (e) {
      print("Erro inesperado ao inserir venda: $e");
      return false;
    }
  }

  // Função para limpar ambas as seleções e estado de venda
  Future<void> limparAmbas() async {
    carrinhoController.limparCarrinho();
    limparInformacoesProduto();
    cliquei = 0;
    quantidadesAdicionais.clear();
    quantidadesObservacoes.clear();

    volteiPizza = false;
    carrinhoController.numeroComanda.value = "";
    carrinhoController.numeroMesa.value = "";
    carrinhoController.numeroPedido.value = "";
    
    // Reseta controllers e variáveis de controle
    comandaController.clear();
    mesaController.clear();
    numeroComandaEmUso = "";
    numeroMesaEmUso = "";
    
    setState(() {
      fizPedido = false;
      aparecerCarrinho = false;
      aparecerCardapio = false;
      aparecerFazerPedido = false;
      comandaValida = false;
      mesaValida = false;
      mostrarDentroComandaMesa = false;
    });
  }

  // Função que executa ação se mudar TextField da comanda
  // Função que executa ação se mudar TextField da comanda
  void _onComandaChanged() {
    final value = comandaController.text;
    if (value.isEmpty || value == numeroComandaEmUso) return;

    // Se já estiver com comanda válida ou se houver itens no carrinho
    if ((comandaValida && value.isNotEmpty) ||
        carrinhoController.carrinho.isNotEmpty) {
      if (value != numeroComandaEmUso && value.isNotEmpty) {
        zerarAtendimento();
      }
    }
  }

  // Função que executa ação se mudar TextField da mesa
  void _onMesaChanged() {
    final value = mesaController.text;
    if (value.isEmpty || value == numeroMesaEmUso) return;

    // Se já estiver com mesa válida ou se houver itens no carrinho
    if (mesaValida || carrinhoController.carrinho.isNotEmpty) {
      zerarAtendimento();
    }
  }

  void chamarFocoInicial() {
    if (funcoesController.logicaPorComanda.value ||
        funcoesController.logicaPorComandaNaMesa.value) {
      setState(() {
        showKeyboardNumero = true;
        empurrarBotoes = false;
        _campoAtivo = 'comandaController';
      });
      Future.delayed(Duration(milliseconds: 300), () {
        if (comandaFocus.canRequestFocus) {
          comandaFocus.requestFocus();
        }
      });
    } else if (funcoesController.logicaPorMesa.value) {
      setState(() {
        showKeyboardNumero = true;
        empurrarBotoes = false;
        _campoAtivo = 'mesaController';
      });
      Future.delayed(Duration(milliseconds: 300), () {
        if (mesaFocus.canRequestFocus) {
          mesaFocus.requestFocus();
        }
      });
    }
  }

  // Função para chamar foco
  void chamarFoco() {
    // Se o bloqueio de foco estiver ativo (diálogo visível), aborta silenciosamente
    if (_bloqueandoFoco) return;

    if (carrinhoController.carrinho.isNotEmpty) {
      empurrarBotoes = false;
      iniciaComCarrinho();
      return;
    }
    if (funcoesController.logicaPorComanda.value ||
        funcoesController.logicaPorComandaNaMesa.value) {
      setState(() {
        showKeyboardNumero = true;
        empurrarBotoes = false;
        _campoAtivo = 'comandaController';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_bloqueandoFoco && mounted && comandaFocus.canRequestFocus) {
          comandaFocus.requestFocus();
        }
      });
    } else if (funcoesController.logicaPorMesa.value) {
      setState(() {
        showKeyboardNumero = true;
        _campoAtivo = 'mesaController';
        empurrarBotoes = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_bloqueandoFoco && mounted && mesaFocus.canRequestFocus) {
          mesaFocus.requestFocus();
        }
      });
    }
  }

  // Função para zerar o atendimento
  Future<void> zerarAtendimento() async {
    if (_isZerando) return;
    if (!fizPedido) {
      if (carrinhoController.carrinho.isNotEmpty) {
        _isZerando = true;
        shownDialogErrorTwoBottom(
          context: context,
          title: "Carrinho cheio!",
          message: "Deseja descartar este pedido?",
          icon: Icons.shopping_cart,
          onConfirm: () async {
            _executarLimpezaGeral();
          },
          onCancel: () async {
            _isZerando = false;
            comandaController.removeListener(_onComandaChanged);
            mesaController.removeListener(_onMesaChanged);

            comandaController.text = numeroComandaEmUso;
            mesaController.text = numeroMesaEmUso;

            comandaController.addListener(_onComandaChanged);
            mesaController.addListener(_onMesaChanged);

            setState(() {
              aparecerCardapio = true;
              aparecerCarrinho = true;
              aparecerLista = false;
              aparecerConfiguracaoProduto = false;
            });
          },
        );
      } else {
        _isZerando = true;
        _executarLimpezaGeral();
      }
    } else {
      _isZerando = true;
      _executarLimpezaGeral();
      fizPedido = false;
    }
  }

  // Função para realizar a limpeza geral de estado e banco - FUNÇÃO AUXILIAR DE ZERARATENDIMENTO
  Future<void> _executarLimpezaGeral() async {
    // tirar o foco
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    
    setState(() {
      isProcessingConfirmar = false;
    });

    String sql =
        """
      UPDATE cartoes SET atendimento = '0' WHERE atendimento = '$numeroDaLicencaSelecionada';
      UPDATE mesas SET atendimento = '0' WHERE atendimento = '$numeroDaLicencaSelecionada';
    """;

    try {
      await Connection().ipd(sql);
    } catch (e) {
      print("Erro ao zerar atendimento no banco: $e");
    }

    nomeClienteDialogoController.clear();
    telefoneClienteDialogoController.clear();
    cpfClienteDialogoController.clear();
    dataNascimentoClienteDialogoController.clear();
    cliquei = 0;

    cadastrarCliente = false;
    querCadastrarCliente = false;
    clienteJaCadastrado.value = false;
    nomeValido = false;
    telefoneValido = false;
    cpfValido = false;
    dataNascimentoValida = false;

    nomeErro = false;
    telefoneErro = false;
    cpfErro = false;
    dataNascimentoErro = false;

    isProcessing = false;
    aparecerFazerPedido = false;
    aparecerCardapio = false;
    aparecerCarrinho = false;
    aparecerLista = false;
    aparecerConfiguracaoProduto = false;
    aparecerBotoes = true;
    mostrarDentroComandaMesa = false;
    mesaVinculada = false;
    produtoKilo = false;
    contadorPonto = 0;
    enviarComanda = false;
    isProcessingConfirmar = false;
    numeroMesaParaCarrinho = "";
    isProcessing = false;

    if (mounted) {
      setState(() {

        carrinhoController.numeroComanda.value = "";
        carrinhoController.numeroMesa.value = "";
        carrinhoController.numeroPedido.value = "";

        comandaValida = false;
        mesaValida = false;

        comandaController.removeListener(_onComandaChanged);
        mesaController.removeListener(_onMesaChanged);

        comandaController.clear();
        mesaController.clear();
        cardapioController.clear();

        comandaController.text = '';
        mesaController.text = '';
        cardapioController.text = '';

        comandaController.addListener(_onComandaChanged);
        mesaController.addListener(_onMesaChanged);

        carrinhoController.carrinho.clear();

        numeroComandaEmUso = "";
        numeroMesaEmUso = "";
        // isProcessing e cliqueiFazerPedido substituídos pelo FuncoesController

        // chama o foco para o campo de comanda ou mesa
        // Só solicita foco se o bloqueio global NÃO estiver ativo
        // (ex: diálogo de sucesso/erro ainda visível)
        if (!_bloqueandoFoco) {
          if (funcoesController.logicaPorComanda.value ||
              funcoesController.logicaPorComandaNaMesa.value) {
            showKeyboardAlfa = false;
            showKeyboardNumero = true;
            _campoAtivo = 'comandaController';
          } else if (funcoesController.logicaPorMesa.value) {
            showKeyboardAlfa = false;
            showKeyboardNumero = true;
            _campoAtivo = 'mesaController';
          }
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
             if (!_bloqueandoFoco && mounted) {
                FocusNode node = funcoesController.logicaPorMesa.value ? mesaFocus : comandaFocus;
                if (node.canRequestFocus) {
                  node.requestFocus();
                }
             }
          });
        }
      });
    }
    _isZerando = false;
  }

  // Função para pegar o id do aparelho
  Future<String> pegarmeuMobileId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      setState(() {
        meuMobileId = androidInfo.id;
      });
      return androidInfo.id; // ID do Android
    }

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      setState(() {
        meuMobileId = iosInfo.identifierForVendor ?? 'unknown_ios';
      });
      return iosInfo.identifierForVendor ?? 'unknown_ios';
    }

    if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      setState(() {
        meuMobileId = windowsInfo.deviceId;
      });
      return windowsInfo.deviceId;
    }

    return 'unknown_device';
  }

  // Função para limpar informações do produto após jogá-lo no carrinho
  void limparInformacoesProduto() {
    numeroProdutoSelecionadoController.clear();
    quantidadeProdutoSelecionadoController.clear();
    observacaoProdutoSelecionadoController.clear();
    adicionalProdutoSelecionadoController.clear();

    idDoProdutoSelecionado = "";
  }

  // Função para remover produto do carrinho
  void removerProdutoDoCarrinhoPorNumeroIndex(String produtoNumero, int index) {
    carrinhoController.carrinho.removeAt(index);
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

  // Buscar numero da licença que eu estou usando
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

  // Buscar numero pedido
  Future<void> buscarNumeroPedido(String numero) async {
    if (funcoesController.logicaPorComanda.value ||
        funcoesController.logicaPorComandaNaMesa.value) {
      try {
        String dadosJson = await Connection().select(
          "SELECT numeropedido_FK FROM cartoes WHERE numero='$numero';",
        );

        List<dynamic> lista = jsonDecode(dadosJson);

        if (lista.isNotEmpty) {
          // pega apenas o campo resultado
          String valor = lista[0]['numeropedido_FK'].toString();

          setState(() {
            numeropedido_FK = valor;
            carrinhoController.numeroPedido.value = valor;
          });
          print("Número do pedido: $numeropedido_FK");
        } else {
          // se a lista vier vazia
          setState(() {
            numeropedido_FK = "Não foi possível buscar número do pedido";
          });
        }
      } catch (e) {
        print("Erro ao carregar configuracaoServico: $e");
        setState(() {
          numeropedido_FK = "";
        });
      }
    } else if (funcoesController.logicaPorMesa.value) {
      try {
        String dadosJson = await Connection().select(
          "SELECT numeropedido_FK FROM mesas WHERE numero='$numero';",
        );

        List<dynamic> lista = jsonDecode(dadosJson);

        if (lista.isNotEmpty) {
          // pega apenas o campo resultado
          String valor = lista[0]['numeropedido_FK'].toString();

          setState(() {
            numeropedido_FK = valor;
          });
          print("Número do pedido: $numeropedido_FK");
        } else {
          // se a lista vier vazia
          setState(() {
            numeropedido_FK = "Não foi possível buscar número do pedido";
          });
        }
      } catch (e) {
        print("Erro ao carregar configuracaoServico: $e");
        setState(() {
          numeropedido_FK = "";
        });
      }
    }
  }

  // Função para validar comanda
  Future<void> validarComanda(String numeroComanda) async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, ativo, bloqueada, atendimento, statuspedido, numeropedido_FK, numeromesa, valorliquidopedido FROM cartoes WHERE numero='$numeroComanda';",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isEmpty) {
        print("Nenhuma comanda encontrada!");
        setState(() {
          validaComanda = [];
          mensagem = "Nenhuma comanda encontrada!";
          comandaValida = false;
          mesaComandaNaoTemConta = true;
        });
        return;
      }
      Map<String, dynamic> comanda = lista[0];
      setState(() {
        numeropedido_FK = comanda['numeropedido_FK'];
      });

      // Exemplo de validações:
      if (comanda['numero'] == null) {
        setState(() {
          mensagem = "Comanda inexistente";
          comandaValida = false;
          icone = false;
          mesaComandaNaoTemConta = true;
        });
      } else if (comanda['ativo'] == '0') {
        setState(() {
          mensagem = "Comanda inativa!";
          comandaValida = false;
          icone = false;
          mesaComandaNaoTemConta = true;
        });
      } else if (comanda['bloqueada'] == '1') {
        setState(() {
          mensagem = "Comanda bloqueada!";
          comandaValida = false;
          icone = false;
          mesaComandaNaoTemConta = true;
        });
      } else if (comanda['statuspedido'] == '2') {
        // Chamar dialogo de dois botões e ir para a pagina de conta mandando o número da comanda
        setState(() {
          mesaComandaNaoTemConta = false;
        });
        shownDialogErrorTwoBottom(
          context: context,
          title: "Comanda em conta!",
          message: "Deseja visualizar este pedido?",
          icon: Icons.error,
          onConfirm: () async {
            mesaComandaNaoTemConta = true;
            Get.to(
              () => ContaPage(),
              arguments: {
                'numeropedido': comanda['numeropedido_FK'],
                'comanda': numeroComanda,
                'mesa': comanda['numeromesa'],
                'page': "garcom",
              },
            );
            comandaController.clear();
            chamarFoco();
          },
          onCancel: () async {
            mesaComandaNaoTemConta = true;
            zerarAtendimento();
            // await buscarTipoPedido();
          },
        );
      }
      // Verifica atendimento ANTES de verificar numeromesa
      else if (comanda['atendimento'] != '0') {
        // Carrega licença ANTES de comparar
        await _loadNumeroLicenca();

        // Select para conseguir o nome do PVD que já esta atendendo esta comanda
        String dadosJson = await Connection().select(
          "SELECT nome, numero FROM tradepoints WHERE numero='${comanda['atendimento']}';",
        );

        List<dynamic> lista = jsonDecode(dadosJson);
        print(dadosJson);

        if (lista.isNotEmpty) {
          final valor = lista[0]['nome'].toString();
          final valor2 = lista[0]['numero'].toString();
          setState(() {
            nomePVD = valor;
            mobileId = valor2;
          });
        } else {
          setState(() {
            nomePVD = "Não foi possível rastrear PDV";
          });
        }

        if (numeroDaLicencaSelecionada != mobileId) {
          // Outro PDV está atendendo - NÃO atualiza
          setState(() {
            mensagem = "Comanda já esta sendo atendida pelo PVD $nomePVD!";
            comandaValida = false;
            icone = false;
          });
        } else {
          // Mesmo PDV - pode continuar
          try {
            setState(() {
              isLoading = true;
            });

            await atualizarComanda(numeroDaLicencaSelecionada, numeroComanda);
            await saveComanda(numeroComanda);

            double valorLiquido = double.tryParse(comanda['valorliquidopedido'].toString()) ?? 0.0;

            if (funcoesController.logicaPorComanda.value) {
              setState(() {
                numeroComandaEmUso = numeroComanda;
                comandaValida = true;
                mesaComandaNaoTemConta = true;
                mostrarDentroComandaMesa = valorLiquido != 0.0;
              });
              _irParaCardapio();
            } else if (funcoesController.logicaPorComandaNaMesa.value) {
              setState(() {
                numeroComandaEmUso = numeroComanda;
                numeroMesaEmUso = comanda['numeromesa'];
                mesaController.text = numeroMesaEmUso;
                comandaValida = true;
                mesaVinculada = comanda['numeromesa'] != '0';
                mesaComandaNaoTemConta = true;
                mostrarDentroComandaMesa = valorLiquido != 0.0;
                aparecerFazerPedido = true;
              });
            }
          } catch (e) {
            setState(() {
              mensagem = "Erro ao abrir comanda.";
              comandaValida = false;
              icone = false;
            });
          }
        }
        setState(() {
          validaComanda = lista;
        });
      } else if (comanda['numeromesa'] != '0') {
        // Comanda com mesa vinculada e sem atendimento
        await _loadNumeroLicenca();
        await atualizarComanda(numeroDaLicencaSelecionada, numeroComanda);
        await saveComanda(numeroComanda);

        double valorLiquido = double.tryParse(comanda['valorliquidopedido'].toString()) ?? 0.0;

        if (funcoesController.logicaPorComanda.value) {
          setState(() {
            numeroComandaEmUso = numeroComanda;
            comandaValida = true;
            mesaComandaNaoTemConta = true;
            mostrarDentroComandaMesa = valorLiquido != 0.0;
            _irParaCardapio();
          });
        } else if (funcoesController.logicaPorComandaNaMesa.value) {
          setState(() {
            numeroComandaEmUso = numeroComanda;
            numeroMesaEmUso = comanda['numeromesa'];
            mesaController.text = numeroMesaEmUso;
            comandaValida = true;
            mesaVinculada = true;
            mesaComandaNaoTemConta = true;
            mostrarDentroComandaMesa = valorLiquido != 0.0;
            aparecerFazerPedido = true;
          });
        }
      } else {
        // Comanda Livre
        try {
          setState(() {
            isLoading = true;
          });

          // Funções
          await _loadNumeroLicenca();
          await atualizarComanda(numeroDaLicencaSelecionada, numeroComanda);
          await saveComanda(numeroComanda);

          // Verificação se ja tem itens no pedido da comanda
          double valorLiquido =  double.tryParse(comanda['valorliquidopedido'].toString()) ?? 0.0;

          setState(() {
            numeroComandaEmUso = numeroComanda;
            comandaValida = true;
            aparecerFazerPedido = true;
            mesaComandaNaoTemConta = true;
            mostrarDentroComandaMesa = valorLiquido!= 0.0;
          });
        } catch (e) {
          setState(() {
            mensagem = "Erro ao abrir comanda.";
            comandaValida = false;
            icone = false;
            mesaComandaNaoTemConta = true;
          });
        }
      }
      setState(() {
        validaComanda = lista;
      });
    } catch (e) {
      print("Erro ao carregar validaComanda: $e");
      /*   setState(() {
        validaComanda = [];
        comandaValida = false;
        icone = false;
      }); */
    }
  }

  // Função para atualizar comanda
  Future<void> atualizarComanda(String numeroPVD, String numeroComanda) async {
    String numeroPVDNoUpdate = numeroPVD;
    String numeroComandaNoUpdate = numeroComanda;

    // Monta o SQL UPDATE
    String sql =
        '''
      UPDATE cartoes SET atendimento='$numeroPVDNoUpdate' WHERE numero='$numeroComandaNoUpdate'; 
    ''';

    // Executa o SQL usando a função ipd
    String resultado = await Connection().ipd(sql);

    if (resultado == "sucesso") {
      print("Cliente atualizado com sucesso!");
    } else {
      print("Erro ao atualizar cliente.");
    }
  }

  // Função para validar mesa
  Future<void> validarMesa(String numeroMesa) async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, ativo, atendimento, statuspedido, numeropedido_FK, comandavinculada, valorliquidopedido FROM mesas WHERE numero='$numeroMesa';",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isEmpty) {
        setState(() {
          validaMesa = [];
          mensagemNaMesa = "Nenhuma mesa encontrada!";
          icone = false;
          mesaValida = false;
          mesaComandaNaoTemConta = true;
        });
        return;
      }
      Map<String, dynamic> mesa = lista[0];

      setState(() {
        numeropedido_FK = mesa['numeropedido_FK'];
      });

      // Exemplo de validações:
      if (mesa['numero'] == null) {
        setState(() {
          mensagemNaMesa = "Mesa inexistente";
          mesaValida = false;
          icone = false;
          mesaComandaNaoTemConta = true;
        });
      } else if (mesa['ativo'] == '0') {
        setState(() {
          mensagemNaMesa = "Mesa inativa!";
          mesaValida = false;
          icone = false;
          mesaComandaNaoTemConta = true;
        });
      } else if (mesa['statuspedido'] == '2') {
        setState(() {
          mesaComandaNaoTemConta = false;
        });
        // Chamar dialogo de dois botões e ir para a pagina de conta mandando o número da comanda
        shownDialogErrorTwoBottom(
          context: context,
          title: "Mesa em conta!",
          message: "Deseja visualizar esta conta?",
          icon: Icons.error,
          onConfirm: () async {
            Get.to(
              () => ContaPage(),
              arguments: {
                'numeropedido': mesa['numeropedido_FK'],
                'comanda': mesa['comandavinculada'],
                'mesa': numeroMesa,
                'page': "garcom",
              },
            );
            mesaController.clear();
            // chamarFoco();
            setState(() {
              mesaComandaNaoTemConta = true;
            });
          },
          onCancel: () {
            Get.to(() => GarcomPage());
          },
        );
        // Se a mesa estiver aberta e a logica for por comanda na mesa
      } else if (funcoesController.logicaPorComandaNaMesa.value &&
          mesa['numeropedido_FK'] != '0') {
        setState(() {
          validaMesa = [];
          mensagemNaMesa = "Mesa $numeroMesa já esta aberta!";
          icone = false;
          mesaValida = false;
          mesaComandaNaoTemConta = true;
        });
      }
      // Nao pode abrir mesa com pedido
      else if (mesa['comandavinculada'] != '0' && funcoesController.logicaPorMesa.value) {
        setState(() {
          validaMesa = [];
          mensagemNaMesa = "Mesa $numeroMesa já esta vinculada a uma comanda!";
          icone = false;
          mesaValida = false;
          mesaComandaNaoTemConta = true;
        });

        zerarAtendimento();
      } else if (mesa['atendimento'] != '0') {
        // Select para conseguir o nome do PVD que já esta atendendo esta mesa
        String dadosJson = await Connection().select(
          "SELECT nome, numero FROM tradepoints WHERE numero='${mesa['atendimento']}';",
        );

        List<dynamic> lista = jsonDecode(dadosJson);

        if (lista.isNotEmpty) {
          final valor = lista[0]['nome'].toString();
          final valor2 = lista[0]['numero'].toString();
          setState(() {
            nomePVD = valor;
            mobileId = valor2;
          });
        } else {
          setState(() {
            nomePVD = "Não foi possível rastrear PDV";
          });
        }

        if (numeroDaLicencaSelecionada != mobileId) {
          setState(() {
            mensagemNaMesa = "A mesa $numeroMesa já esta sendo atendida pelo PDV:\n$nomePVD!";
            mesaValida = false;
            icone = false;
            mesaComandaNaoTemConta = true;
            zerarAtendimento();
          });
        } else {
          try {
            setState(() {
              isLoading = true;
            });

            // Funções
            await _loadNumeroLicenca();
            await atualizarMesa(numeroDaLicencaSelecionada, numeroMesa);

            double valorLiquido = double.tryParse(mesa['valorliquidopedido'].toString()) ?? 0.0;

            if (funcoesController.logicaPorMesa.value) {
              carrinhoController.numeroMesa.value = numeroMesa;
              setState(() {
                numeroMesaEmUso = numeroMesa;
                mesaValida = true;
                aparecerFazerPedido = true;
                mesaComandaNaoTemConta = true;
                mostrarDentroComandaMesa = valorLiquido != 0.0;
                _campoAtivo = 'cardapioController';
                showKeyboardQuantidade = false;
                showKeyboardNumero = false;
                Future.delayed(Duration(milliseconds: 300), () {
                  if (cardapioFocus.canRequestFocus) {
                    cardapioFocus.requestFocus();
                  }
                });
              });
            } else if (funcoesController.logicaPorComandaNaMesa.value) {
              carrinhoController.numeroMesa.value = numeroMesa;
              // Atualização da tela
              setState(() {
                numeroMesaEmUso = numeroMesa;
                mesaValida = true;
                aparecerFazerPedido = true;
                mesaComandaNaoTemConta = true;
                // mostrarDentroComandaMesa = valorLiquido != 0.0;
              });
            }
          } catch (e) {
            setState(() {
              mensagemNaMesa = "Erro ao abrir mesa.";
              mesaValida = false;
              icone = false;
              mesaComandaNaoTemConta = true;
            });
          }
        }
      } else {
        // Mesa Livre
        setState(() {
          isLoading = true;
        });
        // Funções
        await _loadNumeroLicenca();
        await atualizarMesa(numeroDaLicencaSelecionada, numeroMesa);

        // Verificação se ja tem itens no pedido da mesa
        double valorLiquido = double.tryParse(mesa['valorliquidopedido'].toString()) ?? 0.0;

        carrinhoController.numeroMesa.value = numeroMesa;
        setState(() {
          aparecerFazerPedido = true;
          mesaValida = true;
          numeroMesaEmUso = numeroMesa;
          mesaComandaNaoTemConta = true;
        });

        if(funcoesController.logicaPorMesa.value){
          setState(() {
            mostrarDentroComandaMesa = valorLiquido != 0.0;
          });
        }
      }
      setState(() {
        validaMesa = lista;
      });
    } catch (e) {
      print("Erro ao carregar validaMesa: $e");
      setState(() {
        validaMesa = [];
        icone = false;
        mesaComandaNaoTemConta = true;
        mensagemNaMesa = "Erro ao carregar validaMesa";
        mesaComandaNaoTemConta = true;
      });
    }
  }

  // Função para atualizar Mesa
  Future<void> atualizarMesa(String numeroPVD, String numeroMesa) async {
    String numeroPVDNoUpdate = numeroPVD;
    String numeroMesaNoUpdate = numeroMesa;

    // Monta o SQL UPDATE
    String sql =
        '''
      UPDATE mesas SET atendimento = '$numeroPVDNoUpdate' WHERE numero = '$numeroMesaNoUpdate'; 
    ''';

    // Executa o SQL usando a função ipd
    String resultado = await Connection().ipd(sql);

    if (resultado == "sucesso") {
      print(sql);
      print("Cliente atualizado com sucesso!");
    } else {
      print("Erro ao atualizar cliente.");
    }
  }

  // Função auxiliar para normalizar texto (remove acentos e caracteres especiais)
  String _normalizarTexto(String texto) {
    const comAcento =
        'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const semAcento =
        'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    String resultado = texto.toLowerCase();
    for (int i = 0; i < comAcento.length; i++) {
      resultado = resultado.replaceAll(comAcento[i], semAcento[i]);
    }
    return resultado;
  }

  // Função para filtrar 
  filtrarProdutos(String termo) async {
    final prefs = await SharedPreferences.getInstance();
    final ultimodo = prefs.getString('carregar_ultima_configuracao');
    setState(() {
      aparecerLista = true;

      if (termo.isEmpty) {
        if(ultimodo == "Touch"){
          aparecerVendaTouch = true;
        } else {
          aparecerVendaTouch = false;
        }
        aparecerLista = false;
        aparecerCarrinho = true;
        listaProdutoFiltrada = [];
        return;
      }

      if (termo.isNotEmpty) {
        aparecerVendaTouch = false;
        aparecerCarrinho = false;
        aparecerLista = true;
      }

      final termoNormalizado = _normalizarTexto(termo);

      // VERIFICA SE É NÚMERO
      final isNumero = double.tryParse(termoNormalizado) != null;

      // FILTRO NUMÉRICO
      if (isNumero) {
        listaProdutoFiltrada = funcoesController.listaProduto.where((produto) {
          final numero = produto['produto_numero']?.toString() ?? '';

          return numero.startsWith(termoNormalizado);
        }).toList();

        // ORDENA NUMERICAMENTE
        listaProdutoFiltrada.sort((a, b) {
          final numeroA = int.tryParse(a['produto_numero'].toString()) ?? 0;
          final numeroB = int.tryParse(b['produto_numero'].toString()) ?? 0;

          return numeroA.compareTo(numeroB);
        });

        return;
      }

      // FILTRO POR TEXTO
      final termos = termoNormalizado.split(' ').where((t) => t.isNotEmpty).toList();

      listaProdutoFiltrada = funcoesController.listaProduto.where((produto) {
        final nome = _normalizarTexto(produto['produto_nome'] ?? '');

        return termos.every((t) {
          return nome.split(' ').any((palavra) => palavra.startsWith(t));
        });
      }).toList();

      // ORDENA ALFABETICAMENTE
      listaProdutoFiltrada.sort((a, b) {
        final nomeA = _normalizarTexto(a['produto_nome'] ?? '');
        final nomeB = _normalizarTexto(b['produto_nome'] ?? '');

        return nomeA.compareTo(nomeB);
      });
    });
  }
  
  // Lista que vincula produtos e grupo
  List<dynamic> produtosPorGrupo(String idDoGrupo) {
    return funcoesController.listaProduto.where((produto) {
      return produto['grupo_numero'].toString() == idDoGrupo;
    }).toList();
  }

  // Função que monta lista para visualição de grupos e produtos
  void abrirSelecaoGrupoProduto() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String? grupoSelecionado;
            return Container(
              padding: EdgeInsets.all(12),
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Center(
                    child: Text(
                      mostrarGrupos
                          ? 'Selecione um grupo'
                          : 'Selecione um produto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(height: 12),

                  // Lista de grupos
                  Expanded(
                    child: mostrarGrupos
                        ? ListView.builder(
                            itemCount: funcoesController.listaGrupo.length,
                            itemBuilder: (context, index) {
                              final grupo = funcoesController.listaGrupo[index];

                              return GestureDetector(
                                onTap: () {
                                  aparecerCarrinho = false;
                                  setModalState(() {
                                    grupoSelecionado = grupo['numero']
                                        .toString();
                                    produtosFiltrados = produtosPorGrupo(
                                      grupoSelecionado!,
                                    );

                                    mostrarGrupos = false;
                                    mostrarProdutos = true;
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      grupo['nome'],
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        // Lista de produtos
                        : ListView.builder(
                            itemCount: produtosFiltrados.length,
                            itemBuilder: (context, index) {
                              final produto = produtosFiltrados[index];

                              return GestureDetector(
                                // Quando clicar em um produto
                                onTap: () {
                                  // Se o produto for do tipo produto
                                  if (produto['produto_id'] == 'P') {
                                    Navigator.pop(context);

                                    // Atualiza controllers

                                    if (produto['produto_un'] == "Kg") {
                                      produtoKilo = true;
                                    } else {
                                      produtoKilo = false;
                                    }

                                    cardapioController.text = produtoKilo
                                        ? "${produto['produto_nome']} (Kg)"
                                        : "${produto['produto_nome']} (${produto['produto_un']})";
                                    numeroProdutoSelecionadoController.text = produto['produto_numero'];
                                    numeroDoProdutoSelecionado = produto['produto_numero'];
                                    valorDoProdutoSelecionado = produto['produto_valor'];

                                    quantidadeProdutoSelecionadoController.text = "";
                                    quantidadeProdutoSelecionadoController.clear();

                                    observacaoProdutoSelecionadoController.text = "";
                                    observacaoProdutoSelecionadoController.clear();

                                    setState(() {
                                      idDoProdutoSelecionado = produto['produto_id'];
                                      aparecerBotoes = false;
                                      aparecerLista = false;
                                      aparecerCarrinho = false;
                                      aparecerConfiguracaoProduto = true;
                                      aparecerCardapio = true;

                                      if (produtoKilo) {
                                        showKeyboardAlfa = false;
                                        showKeyboardNumero = false;
                                        showKeyboardQuantidade = true;
                                        _campoAtivo = 'quantidadeProdutoSelecionadoController';
                                        Future.delayed(
                                          Duration(milliseconds: 300),
                                          () {
                                            if (quantidadeProdutoSelecionadoFocus.canRequestFocus) {
                                              quantidadeProdutoSelecionadoFocus.requestFocus();
                                            }
                                          },
                                        );
                                      } else {
                                        showKeyboardAlfa = false;
                                        showKeyboardNumero = true;
                                        showKeyboardQuantidade = false;
                                        _campoAtivo = 'quantidadeProdutoSelecionadoController';
                                        Future.delayed(
                                          Duration(milliseconds: 300),
                                          () {
                                            if (quantidadeProdutoSelecionadoFocus.canRequestFocus) {
                                              quantidadeProdutoSelecionadoFocus.requestFocus();
                                            }
                                          },
                                        );
                                      }
                                    });
                                  } // Se o produto for do tipo pizza
                                  else if (produto['produto_id'] == 'PZ') {
                                    Navigator.pop(context);
                                    Get.offAllNamed('/pizza',
                                      // preventDuplicates: false,
                                      arguments: {
                                        'tamanhoSelecionado': produto['produto_nome'],
                                        'comanda': comandaController.text,
                                        'mesa': mesaController.text,
                                        'index': index,
                                        'editar': false,
                                        'numeroDoPedido': numeroDoPedido,
                                        'clienteNome': nomeClienteDialogoController.text,
                                        'clienteCpf': cpfClienteDialogoController.text,
                                        'clienteTelefone': telefoneClienteDialogoController.text,
                                        'clienteDataNascimento': dataNascimentoClienteDialogoController.text,
                                      },
                                    )?.then((_) {
                                      if (mounted) {
                                        // Garante que o modo touch é desativado e o carrinho aparece ao retornar da PizzaPage.
                                        sairModoTouch();
                                      }
                                    });
                                  } else if (produto['produto_id'] == 'E') {
                                    Navigator.pop(context);

                                    Future.delayed(Duration(milliseconds: 50), () {
                                      if (!mounted) return;

                                      // Atualiza controladores fora do setModalState
                                      cardapioController.text = produto['produto_nome'];
                                      numeroProdutoSelecionadoController.text = produto['produto_numero'];
                                      numeroDoProdutoSelecionado = produto['produto_numero'];
                                      valorDoProdutoSelecionado = produto['produto_valor'];

                                      setModalState(() {
                                        idDoProdutoSelecionado = produto['produto_id'];
                                        showKeyboardAlfa = false;
                                        showKeyboardNumero = true;
                                        _campoAtivo = 'quantidadeProdutoSelecionadoController';

                                        aparecerLista = false;
                                        aparecerCarrinho = false;
                                        aparecerBotoes = false;
                                        aparecerConfiguracaoProduto = true;
                                        aparecerCardapio = true;
                                      });

                                      // Foco e scroll após o build
                                      WidgetsBinding.instance.addPostFrameCallback((
                                        _,
                                      ) {
                                        if (!mounted) return;
                                        /* _scrollToField(quantidadeProdutoSelecionadoFocus); */
                                        quantidadeProdutoSelecionadoFocus.requestFocus();
                                      });
                                    });
                                  }
                                },
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (produto['produto_numero'] != '0')
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${produto['produto_numero']} - ${produto['produto_nome']}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                            Text(
                                              '(${produto['produto_un']})',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                          ],
                                        ),
                                      /* Text(produto['produto_nome']), */
                                      if (produto['produto_valor'] != '0.00')
                                        Text("R\$ ${(double.tryParse(produto['produto_valor'].toString()) ?? 0).toStringAsFixed(2)}"),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Botão voltar para grupos
                  if (mostrarProdutos)
                    IconButton(
                      onPressed: () {
                        setModalState(() {
                          mostrarProdutos = false;
                          mostrarGrupos = true;
                        });
                      },
                      icon: Icon(Icons.arrow_back, size: 40),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Função que verifica se um produto tem adicionais
  void verificacaoSeTemAdicionalObservacao(
    String numero,
    List<dynamic> listaCompleta,
  ) {
    final itensProduto = listaCompleta
        .where((e) => e['numeroproduto'].toString() == numero)
        .toList();
    if (itensProduto.isEmpty) {
      temAdicionalObservacao = false;
    } else {
      temAdicionalObservacao = true;
    }
  }

  void verificacaoSeTemAdicionalObservacaoFavoritos(
    String numero,
    List<dynamic> listaCompleta,
  ) {
    final itensProduto = listaCompleta
        .where((e) => e['numeroproduto'].toString() == numero)
        .toList();
    if (itensProduto.isEmpty) {
      temAdicionalObservacao = false;
    } else {
      temAdicionalObservacao = true;
    }
  }

  void mostrarAdicionaisEObservacoes(numeroDoProdutoSelecionadoFuncao, nomeFuncao, valorFuncao, numeroFuncao, quantidadeFuncao, observacaoFuncao){
    showModalAdicionaisObservacoes(
      context,
      numeroDoProdutoSelecionadoFuncao,
      funcoesController.listaAdicionaisObservacoesFiltrada, 
      funcoesController.adicionaisFuncaoFiltrada,
      funcoesController.observacoesFuncaoFiltrada,
      nomeFuncao,
      valorFuncao,
      numeroFuncao,
      quantidadeFuncao,
      observacaoFuncao,
    );
    temAdicionalObservacao = false;
  }

  // Função que eu abro para aparecer adicionais e observações
  void showModalAdicionaisObservacoes(
    BuildContext context,
    String numeroProduto,
    List<dynamic> listaCompleta,
    List<dynamic> listaAdicionais,
    List<dynamic> listaObservacoes,
    String produtoNome,
    String produtoValor,
    String produtoNumero,
    double produtoQuantidade,
    String produtoObservacao,
  ) {
    arrastei = true;
    // Vendo de qual produto que são as observações e os adicionais
    final itensProduto = listaCompleta.where((e) => e['numeroproduto'].toString() == numeroProduto).toList();

    final itensAdicionais = listaAdicionais.where((e) => e['numeroproduto'].toString() == numeroProduto).toList();

    final itensObservacoes = listaObservacoes.where((e) => e['numeroproduto'].toString() == numeroProduto).toList();

    // Colocando os adicionais e observações do produto em uma outra lista
    listaAdicionaisObservacoesDoProduto = itensProduto;

    // Separando observações (adicionais) garantindo que sejam únicos por ID
    final mapAdicionais = <String, dynamic>{};
    for (var e in itensAdicionais.where((e) => e['numeroadicional'].toString() != '0')) {
      mapAdicionais[e['numeroadicional'].toString()] = e;
    }
    listaAdicionaisDoProduto = mapAdicionais.values.map((e) {
      final novoItem = Map<String, dynamic>.from(e as Map);
      novoItem['selecionado'] = false; // para controlar o ckeck box
      return novoItem;
    }).toList();

    // Separando adicionais (observações) garantindo que sejam únicos por ID
    final mapObservacoes = <String, dynamic>{};
    for (var e in itensObservacoes.where((e) => e['nomeobservacao'].toString() != '0')) {
      mapObservacoes[e['numeroobservacao'].toString()] = e;
    }
    listaObservacaoesDoProduto = mapObservacoes.values.map((e) {
      final novoItem = Map<String, dynamic>.from(e as Map);
      novoItem['selecionado'] = false; // para controlar o ckeck box
      return novoItem;
    }).toList();
    double quantidadeInicial = produtoQuantidade;

    quantidadeProdutoSelecionadoController.text = produtoKilo
        ? quantidadeInicial.toString()
        : meiaPorcaoProduto ? quantidadeInicial.toString() : quantidadeInicial.toInt().toString();

    quantidadeProdutoSelecionadoModalController.text = produtoKilo
        ? quantidadeInicial.toString()
        : meiaPorcaoProduto ? quantidadeInicial.toString() : quantidadeInicial.toInt().toString();
    // Lista para adicionar as quantidades de cada adicional
    for (var item in listaAdicionaisDoProduto) {
      final numero = item['numeroadicional'].toString();
      quantidadesAdicionais.putIfAbsent(numero, () => 0);
    }

    // Lista para adicionar as quantidades de cada observação
    for (var item in listaObservacaoesDoProduto) {
      // final nome = item['nomeobservacao'].toString();
      final id = item['numeroobservacao'].toString();
      quantidadesObservacoes.putIfAbsent(id, () => 0);
    }

    observacaoProdutoSelecionadoObsAddController.text = produtoObservacao;

    carregarUltimoAdicionalObservacaoSelecionado();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            aparecerGrid ? Icons.list : Icons.grid_view,
                            color: aparecerGrid ? Theme.of(context,).colorScheme.shadow : Theme.of(context,).colorScheme.scrim,
                          ),
                          onPressed: () async {
                            if(aparecerGrid){
                              setModalState(() {
                                aparecerGrid = false;
                              });
                              String modo = "lista";
                              salvarUltimoAdicionalObservacaoSelecionado(modo);
                            } else {
                              setModalState(() {
                                aparecerGrid = true;
                              });
                              String modo = "grid";
                              salvarUltimoAdicionalObservacaoSelecionado(modo);
                            }
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            // backgroundColor: aparecerVendaTouch ? Theme.of(context,).colorScheme.scrim : Theme.of(context,).colorScheme.shadow,
                            padding: EdgeInsets.all(10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10,),
                            ),
                          ),
                        ),
                        /* Text(
                          aparecerGrid ? "List" : "Grid",
                          style: TextStyle(
                            color: aparecerGrid ? Theme.of(context,).colorScheme.shadow : Theme.of(context,).colorScheme.scrim,
                            // color: colorScheme.shadow,
                            fontWeight: FontWeight.bold,
                          ),
                        ), */
                        Expanded(
                          child: Center(
                            child: Text(
                              produtoNome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              // 'Adicionais e Observações',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.shadow,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 30,
                        )
                      ],
                    ),

                    /* Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 8,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(

                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Botão de menos
                              if (!meiaPorcaoClicado)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (quantidadeInicial > 1) {
                                      setModalState(() {
                                        quantidadeInicial--;

                                        final texto = quantidadeInicial.toInt().toString();

                                        quantidadeProdutoSelecionadoController.text = texto;
                                        quantidadeProdutoSelecionadoModalController.text = texto;
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color.fromRGBO(216, 216, 216, 0.843),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                      horizontal: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.remove,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    size: 28,
                                  ),
                                ),
                              ),
                          
                              // Text Field de quantidade
                              Padding(
                                padding: EdgeInsets.only(top: 4.0, bottom: 4.0, left: 4.0, right: 4.0),
                                child: SizedBox(
                                  width: MediaQuery.of(context,).size.width * 0.3,
                                  child: TextField(
                                    controller: quantidadeProdutoSelecionadoModalController,
                                    focusNode: quantidadeProdutoSelecionadoModalFocus,
                                    style: TextStyle(
                                      fontSize: 30, // aumenta o tamanho do número
                                      fontWeight: FontWeight.bold,
                                      height: 1,
                                    ),
                                    readOnly: true, // impede digitação pelo teclado nativo
                                    showCursor: false, // FORÇA o cursor piscando
                                    cursorColor: Theme.of(context,).colorScheme.onSurface,
                                    keyboardType: TextInputType.none, // garante que o teclado não abra
                                    enableInteractiveSelection: false, // evita seleção/copiar
                                    textAlign: TextAlign.center,
                                    onTap: () {
                                      if (produtoKilo) {
                                        showKeyboardNumero = false;
                                        showKeyboardAlfa = false;
                                        showKeyboardQuantidade = true;
                                      } else {
                                        showKeyboardNumero = true;
                                        showKeyboardAlfa = false;
                                        showKeyboardQuantidade = false;
                                      }
                                    },
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Theme.of(context,).colorScheme.primary.withOpacity(0.2),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Botão de mais
                              if (!meiaPorcaoClicado)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    setModalState(() {
                                      quantidadeInicial++;

                                      final texto = produtoKilo
                                          ? quantidadeInicial.toString()
                                          : quantidadeInicial.toInt().toString();

                                      quantidadeProdutoSelecionadoController.text = texto;
                                      quantidadeProdutoSelecionadoModalController.text = texto;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color.fromRGBO(216, 216, 216, 0.843),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 15,
                                      horizontal: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    size: 28,
                                  ),
                                ),
                              ),

                              // Botão de meia porção
                              if(meiaPorcaoProduto)
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: larguraBotao,
                                  height: 60,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (meiaPorcaoClicado) {
                                        setModalState(() {
                                          meiaPorcaoClicado = false;
                                          quantidadeProdutoSelecionadoModalController.text =
                                              "1";
                                          quantidadeInicial = 1;
                                        });
                                      } else {
                                        setModalState(() {
                                          meiaPorcaoClicado = true;
                                          quantidadeProdutoSelecionadoModalController.text =
                                              "0.5";
                                          quantidadeInicial = 0.5;
                                        });
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.scrim,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      '1/2 +',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              /* Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if(meiaPorcaoClicado){
                                        setModalState(() {
                                          meiaPorcaoClicado = false;
                                          quantidadeProdutoSelecionadoModalController.text = "1";
                                          quantidadeInicial = 1;
                                        });
                                      } else {
                                        setModalState(() {
                                          meiaPorcaoClicado = true;
                                          quantidadeProdutoSelecionadoModalController.text = "0.5";
                                          quantidadeInicial = 0.5;
                                        });
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      // backgroundColor: meiaPorcaoClicado ? Theme.of(context).colorScheme.scrim : Theme.of(context).colorScheme.surfaceDim,
                                      backgroundColor: Theme.of(context).colorScheme.scrim,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 15,
                                        horizontal: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: 
                                    Text(
                                      '1/2 +',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    )
                                  ),
                                ),
                              ), */
                            ],
                          ),
                        ),
                      ),
                    ), */
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Largura responsiva dos botões
                              final larguraBotao = ((constraints.maxWidth * 0.18).clamp(60.0, 100.0)) / 1.5;
                              final alturaBotao = ((constraints.maxWidth * 0.18).clamp(60.0, 100.0)) / 1.5;

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [

                                  // Botão de menos
                                  if (!meiaPorcaoClicado)
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: SizedBox(
                                        width: larguraBotao,
                                        height: alturaBotao,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (quantidadeInicial > 1) {
                                              setModalState(() {
                                                quantidadeInicial--;

                                                final texto =
                                                    quantidadeInicial.toInt().toString();

                                                quantidadeProdutoSelecionadoController.text =
                                                    texto;

                                                quantidadeProdutoSelecionadoModalController.text =
                                                    texto;
                                              });
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color.fromRGBO(216, 216, 216, 0.843),
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.remove,
                                            color: Theme.of(context).colorScheme.onPrimary,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Quantidade
                                  Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: SizedBox(
                                      width: constraints.maxWidth * 0.3,
                                      height: alturaBotao,
                                      child: TextField(
                                        controller: quantidadeProdutoSelecionadoModalController,
                                        focusNode: quantidadeProdutoSelecionadoModalFocus,
                                        style: TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                          height: 1,
                                        ),
                                        readOnly: true,
                                        showCursor: false,
                                        keyboardType: TextInputType.none,
                                        enableInteractiveSelection: false,
                                        textAlign: TextAlign.center,
                                        onTap: () {
                                          if (produtoKilo) {
                                            showKeyboardNumero = false;
                                            showKeyboardAlfa = false;
                                            showKeyboardQuantidade = true;
                                          } else {
                                            showKeyboardNumero = true;
                                            showKeyboardAlfa = false;
                                            showKeyboardQuantidade = false;
                                          }
                                        },
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Botão de mais
                                  if (!meiaPorcaoClicado)
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: SizedBox(
                                        width: larguraBotao,
                                        height: alturaBotao,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setModalState(() {
                                              quantidadeInicial++;

                                              final texto = produtoKilo ? quantidadeInicial.toString() : quantidadeInicial.toInt().toString();

                                              quantidadeProdutoSelecionadoController.text = texto;

                                              quantidadeProdutoSelecionadoModalController.text = texto;
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color.fromRGBO(216, 216, 216, 0.843),
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            color: Theme.of(context).colorScheme.onPrimary,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Botão de meia porção
                                  if (meiaPorcaoProduto)
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: SizedBox(
                                        width: larguraBotao,
                                        height: alturaBotao,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (meiaPorcaoClicado) {
                                              setModalState(() {
                                                meiaPorcaoClicado = false;
                                                quantidadeProdutoSelecionadoModalController.text = "1";
                                                quantidadeInicial = 1;
                                              });
                                            } else {
                                              setModalState(() {
                                                meiaPorcaoClicado = true;
                                                quantidadeProdutoSelecionadoModalController.text = "0.5";
                                                quantidadeInicial = 0.5;
                                              });
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(context).colorScheme.scrim,
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: Text(
                                            '1/2 +',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onPrimary,
                                              fontSize: alturaBotao * 0.3,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
                          child: TextField(
                            controller: observacaoProdutoSelecionadoObsAddController,
                            focusNode: observacaoProdutoSelecionadoObsAddFocus,
                            onTap: () {
                              Future.delayed(Duration(milliseconds: 300), () {
                                if (observacaoProdutoSelecionadoObsAddFocus.canRequestFocus) {
                                  observacaoProdutoSelecionadoObsAddFocus.requestFocus();
                                }
                              });
                            },
                            cursorColor: Theme.of(context).colorScheme.onSurface,
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'Observação',
                              hintStyle: TextStyle(
                                color: const Color.fromARGB(255, 195, 195, 195),
                              ),
                              filled: true,
                              fillColor: const Color.fromARGB(255, 238, 238, 238),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    Expanded(
                      child: ListView(
                        children: [
                          // OBSERVAÇÕES
                          if (listaObservacaoesDoProduto.isNotEmpty && !aparecerGrid)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: listaObservacaoesDoProduto.length,
                            itemBuilder: (context, index) {
                              final observacao = listaObservacaoesDoProduto[index];
                              final nome = observacao['nomeobservacao'].toString();
                              final numero = observacao['numeroobservacao'].toString();
                              final quantidade = quantidadesObservacoes[numero] ?? 0;

                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Card(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            nome,
                                            maxLines: 1, // limita a 1 linha
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),

                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 8,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.remove),
                                                onPressed: () {
                                                  if (quantidade > 0) {
                                                    setModalState(() {
                                                      quantidadesObservacoes[numero] = quantidade - 1;
                                                    });
                                                  }
                                                },
                                              ),

                                              Text(
                                                double.parse(
                                                  quantidade.toString(),
                                                ).toStringAsFixed(0),
                                              ),

                                              IconButton(
                                                icon: Icon(Icons.add),
                                                onPressed: () {
                                                  setModalState(() {
                                                    quantidadesObservacoes[numero] = quantidade + 1;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          if(listaObservacaoesDoProduto.isNotEmpty && aparecerGrid)
                          LayoutBuilder(
                          builder: (context, constraints) {
                            const larguraMinimaCard = 100.0;
                            final crossAxisCount = (constraints.maxWidth / larguraMinimaCard).floor().clamp(1, 8);

                            return Padding(
                              padding: EdgeInsets.all(8.0),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: listaObservacaoesDoProduto.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 1,
                                ),
                                itemBuilder: (context, index) {
                                  final observacao = listaObservacaoesDoProduto[index];
                                  final nome = observacao['nomeobservacao'].toString();
                                  final numero = observacao['numeroobservacao'].toString();
                                  final quantidade = quantidadesObservacoes[numero] ?? 0;
                                  // final selecionado = ultimoNumeroObservacaoSelecionado == numeroObservacao;
                              
                                  final selecionado = observacoesSelecionadasObs.contains(nome);
                              
                                  return GestureDetector(
                                    onTap: () {
                                      if(selecionado){
                                        setModalState(() {
                                          ultimoNumeroObservacaoSelecionado = "";
                                          ultimoNomeObservacaoSelecionado = "";
                                          observacoesSelecionadasObs.remove(nome);
                                        });
                                      } else {
                                        setModalState(() {
                                          ultimoNumeroObservacaoSelecionado = numero;
                                          ultimoNomeObservacaoSelecionado = nome;
                                          observacoesSelecionadasObs.add(nome);
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
                                            nome,
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
                              ),
                            );
                          },
                        ),

                          // ADICIONAIS
                          if (listaAdicionaisDoProduto.isNotEmpty)
                            Align(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 0,
                                  ),
                                  child: Text(
                                    'Adicionais',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          /*  ...listaAdicionaisDoProduto.map((item) {
                            return  */
                          if (listaAdicionaisDoProduto.isNotEmpty)
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: listaAdicionaisDoProduto.length,
                              itemBuilder: (context, index) {
                                final adicionais = listaAdicionaisDoProduto[index];
                                final numero = adicionais['numeroadicional'].toString();
                                final quantidade =  double.tryParse(quantidadesAdicionais[numero].toString(),) ?? 1;

                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 0,
                                  ),
                                  child: Card(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 8,
                                                  horizontal: 8,
                                                ),
                                                child: Text(
                                                  adicionais['nomeadicional'],
                                                  maxLines: 1, // limita a 1 linha
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            // Controlador de quantidade
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 8,
                                                horizontal: 8,
                                              ),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    // Botão para remover
                                                    IconButton(
                                                      onPressed: () {
                                                        if (quantidade > 0) {
                                                          setModalState(() {
                                                            quantidadesAdicionais[numero] = quantidade - 1;
                                                          });
                                                        }
                                                      },
                                                      icon: Icon(Icons.remove),
                                                    ),

                                                    // Quantidade do adicional
                                                    Text(
                                                      double.parse(
                                                        quantidade.toString(),
                                                      ).toStringAsFixed(0),
                                                    ),

                                                    // Botão para remover
                                                    IconButton(
                                                      onPressed: () {
                                                        setModalState(() {
                                                          quantidadesAdicionais[numero] =
                                                              quantidade + 1;
                                                        });
                                                      },
                                                      icon: Icon(Icons.add),
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
                                );
                              },
                            ),
                        ],
                      ),
                    ),

                    // Controlador de quantidade e botões
                    SizedBox(
                      width: double.infinity,
                      child: Center(
                        child: Column(
                          children: [
                            // Botões
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final fontSize = (MediaQuery.of(context).size.width * 0.025).clamp(20.0, 32.0);

                                final iconSize = (MediaQuery.of(context).size.width * 0.030).clamp(24.0, 36.0);

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Botão de fechar
                                    Expanded(
                                      flex: 4,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          arrastei = false;
                                          meiaPorcaoProduto = false;
                                          quantidadesAdicionais.clear();
                                          quantidadesObservacoes.clear();
                                          observacoesSelecionadasObs.clear();
                                          Navigator.pop(context);
                                          if(!modoAnteriorTouch){
                                            entrarModoTouch();
                                          }else{
                                            sairModoTouch();
                                          }
                                          meiaPorcaoClicado = false;
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.55),
                                          // backgroundColor: Colors.red.withOpacity(0.55),
                                          padding: EdgeInsets.symmetric(
                                            vertical: 25,
                                            horizontal: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: 
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.close,
                                                size: iconSize,
                                                color: Theme.of(context).colorScheme.onPrimary,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Fechar',
                                                style: TextStyle(
                                                  fontSize: fontSize,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                
                                    SizedBox(width: 6),
                                
                                    // Botão de Adicionar
                                    Expanded(
                                      flex: 6,
                                      child: ElevatedButton(
                                          onPressed: () {
                                            arrastei = false;
                                            
                                            // Montando a lista de adicionais
                                            List<Produto> listaAdicionaisSelecionados = [];
                                            if (quantidadesAdicionais.isNotEmpty) {
                                              quantidadesAdicionais.forEach((numero, quantidade) {
                                                if (quantidade > 0) {
                                                  final item = listaAdicionaisDoProduto.firstWhere((e) => e['numeroadicional'].toString() == numero);
                                        
                                                  for (int i = 0; i < quantidade; i++) {
                                                    listaAdicionaisSelecionados.add(
                                                      Produto(
                                                        nome: item['nomeadicional'],
                                                        preco: item['valoradicionasl'].toString(),
                                                        numero: numero,
                                                        quantidade: 1, // SEMPRE 1
                                                        observacaoEscrita: "",
                                                        id: idDoProdutoSelecionado,
                                                      ),
                                                    );
                                                  }
                                                }
                                              });
                                            }
                                        
                                            // Montando a lista de observações
                                            List<String> observacoesSelecionadas = [];

                                            if (!aparecerGrid && quantidadesObservacoes.isNotEmpty) {
                                              quantidadesObservacoes.forEach((numero, quantidade) {
                                                if (quantidade > 0) {
                                                  final item = listaObservacaoesDoProduto.firstWhere(
                                                    (e) => e['numeroobservacao'].toString() == numero,
                                                  );

                                                  for (int i = 0; i < quantidade; i++) {
                                                    observacoesSelecionadas.add(
                                                      item['nomeobservacao'].toString(),
                                                    );
                                                  }
                                                }
                                              });
                                            }

                                            if(aparecerGrid && observacoesSelecionadasObs.isNotEmpty){
                                              observacoesSelecionadas.addAll(observacoesSelecionadasObs);
                                            }
                                        
                                            // Adicionando o produto ao carrinho
                                            if (cliqueiEditarProduto) {
                                              carrinhoController.editarProdutoAoCarrinho(
                                                indexClicado,
                                                produtoNome,
                                                produtoValor,
                                                produtoNumero,
                                                quantidadeInicial.toDouble(),
                                                observacaoProdutoSelecionadoObsAddController.text,
                                                idDoProdutoSelecionado,
                                                temMeiaPorcao: meiaPorcaoProduto,
                                                adicionais: listaAdicionaisSelecionados,
                                                observacoesTexto: observacoesSelecionadas,
                                              );
                                            } else {
                                              carrinhoController.adicionarProdutoAoCarrinho(
                                                produtoNome,
                                                produtoValor,
                                                produtoNumero,
                                                quantidadeInicial.toDouble(),
                                                observacaoProdutoSelecionadoObsAddController.text,
                                                idDoProdutoSelecionado,
                                                temMeiaPorcao: meiaPorcaoProduto,
                                                adicionais: listaAdicionaisSelecionados,
                                                observacoesTexto: observacoesSelecionadas,
                                              );
                                            }
                                        
                                            // Limpa listas
                                            listaAdicionaisSelecionados.clear();
                                            observacoesSelecionadas.clear();
                                            cardapioController.clear();
                                            quantidadesObservacoes.clear();
                                            quantidadesAdicionais.clear();
                                            observacoesSelecionadasObs.clear();
                                            limparInformacoesProduto();
                                            cliqueiEditarProduto = false;
                                        
                                            Navigator.pop(context);
                                        
                                            setState(() {
                                              aparecerConfiguracaoProduto = false;
                                              aparecerBotoes = true;
                                              quantidadeInicial = 1;
                                              cliqueiEditarProduto = false;
                                            });

                                            meiaPorcaoProduto = false;
                                            meiaPorcaoClicado = false;
                                        
                                            sairModoTouch();
                                          },
                                        
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            padding: EdgeInsets.symmetric(
                                              vertical: 25,
                                              horizontal: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check,
                                                  size: iconSize,
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Confirmar',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context).colorScheme.onPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          /* FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check,
                                                  size: 24,
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Confirmar',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context).colorScheme.onPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ), */
                                      ),
                                    ),
                                  ],
                                );
                              }
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // Executa após o usuário fechar o modal
      if(arrastei){
        quantidadesAdicionais.clear();
        quantidadesObservacoes.clear();
        observacoesSelecionadasObs.clear();
        meiaPorcaoProduto = false;
        meiaPorcaoClicado = false;
        if(!modoAnteriorTouch){
          entrarModoTouch();
        }else{
          sairModoTouch();
        }
      }
    });
  }

  // Função que retorna informações garçom
  Future<void> informacoesGarcom(String nomeDoGarcomSelect) async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, nome FROM usuarios WHERE nome = '$nomeDoGarcomSelect';",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        String valor = lista[0]['numero'].toString();
        String valor2 = lista[0]['nome'];

        setState(() {
          numeroDoGarcom = valor;
          nomeDoGarcom = valor2;
        });
      } else {
        setState(() {
          numeroDoGarcom = ""; // agora é uma string "0" ou "1"
          nomeDoGarcom = "0";
        });
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
      setState(() {
        numeroDoGarcom = "0";
        nomeDoGarcom = "0";
      });
    }
  }

  // Função que retorna informações garçom
  /* Future<void> informacoesListaGarcom() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, nome FROM usuarios WHERE ativo = '1' AND numero != '1' ORDER BY nome;",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        String valor = lista[0]['numero'].toString();
        String valor2 = lista[0]['nome'];

        setState(() {
          listaGarcom = lista;
        });
      } else {
        setState(() {
          listaGarcom = [];
        });
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
      setState(() {
        listaGarcom = [];
      });
    }
  } */

 // Função com o popup para selecionar garçom
  void abrirCarrinhoNaVendaTouch(List<Produto> carrinhoFuncao) {
    if (_popupGarcomAberto) return;
    _popupGarcomAberto = true;    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Align(
            alignment: Alignment.center,
            child: Text(
              "Carrinho",
              style: TextStyle(
                fontSize: 20, // ou qualquer outro estilo que desejar
              ),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: carrinhoFuncao.isEmpty
                ? Center(child: Text("Seu carrinho não tem itens :("))
                : ListView.builder(
                    shrinkWrap: true,
                    controller: _scrollController,
                    physics: BouncingScrollPhysics(),
                    itemCount: carrinhoController.carrinho.length,
                    itemBuilder: (context, index) {
                      final produto = carrinhoController.carrinho[index];
                      final bool ehKilo;

                      // Agrupa os adicionais/sabores/bordas por nome para exibição
                      final Map<String, int> adicionaisAgrupados = {};
                      for (final adicional in produto.adicionais) {
                        final nome = adicional.nome;
                        adicionaisAgrupados[nome] =
                            (adicionaisAgrupados[nome] ?? 0) +
                            adicional.quantidade.toInt();
                      }

                      // Verifica se o produto é vendido por Kg
                      if (produto.nome.contains("(Kg)")) {
                        ehKilo = true;
                      } else {
                        ehKilo = false;
                      }

                      // Agrupa observações de texto repetidas
                      final Map<String, int> observacoesAgrupadas = {};
                      for (final obs in produto.observacoesTexto) {
                        final texto = obs.trim();
                        if (texto.isNotEmpty) {
                          observacoesAgrupadas[texto] =
                              (observacoesAgrupadas[texto] ?? 0) + 1;
                        }
                      }

                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // REMOVER PRODUTO
                                    GestureDetector(
                                      onTap: () {
                                        shownDialogErrorTwoBottom(
                                          context: context,
                                          title: "Deseja descartar este ${produto.nome}?",
                                          icon: Icons.delete,
                                          onConfirm: () {
                                            removerProdutoDoCarrinhoPorNumeroIndex(
                                              produto.numero,
                                              index,
                                            );
                                            setState(() {});
                                          },
                                          onCancel: () {
                                            Navigator.of(context).pop();
                                          },
                                        );
                                      },
                                      child: Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    ),

                                    SizedBox(width: 8),

                                    // DADOS DO PRODUTO
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 0.0,
                                            ),
                                            child: Text(
                                              produto.nome,
                                              /* maxLines: 1, */
                                              /* overflow: TextOverflow.ellipsis, */
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                            ),
                                          ),

                                          if (produto
                                              .observacaoEscrita
                                              .isNotEmpty)
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                produto.observacaoEscrita,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                  color:  Theme.of(context).colorScheme.surfaceDim,
                                                ),
                                              ),
                                            ),

                                          if (produto
                                              .observacoesTexto
                                              .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: observacoesAgrupadas
                                                    .entries
                                                    .map(
                                                      (entry) => Text(
                                                        '${entry.value}x ${entry.key}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontStyle: FontStyle.italic,
                                                          color:  Theme.of(context).colorScheme.surfaceDim,
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                            ),

                                          if (produto.adicionais.isNotEmpty)
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: 6,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: adicionaisAgrupados
                                                    .entries
                                                    .map((entry) {
                                                      //.entries = le
                                                      //.map = traduz e quadra
                                                      return Text(
                                                        // value = int
                                                        // key = string
                                                        '${entry.value}x ${entry.key}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:  Theme.of(context).colorScheme
                                                              .surfaceDim,
                                                        ),
                                                      );
                                                    })
                                                    .toList(),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // CONTROLE DE QUANTIDADE
                                    Container(
                                      width:
                                          MediaQuery.of(context).size.width *
                                          0.35,
                                      decoration: BoxDecoration(
                                        color: ehKilo
                                            ? Colors.transparent
                                            :  Theme.of(context).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(
                                          8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .center, // Centraliza os elementos
                                        children: [
                                          if (!ehKilo)
                                            IconButton(
                                              icon: Icon(
                                                Icons.remove,
                                                color: ehKilo
                                                    ? Colors.transparent
                                                    : Colors.black,
                                              ),
                                              onPressed: ehKilo
                                                  ? null
                                                  : () {
                                                      if (produto.quantidade >
                                                          1) {
                                                        setState(
                                                          () => produto
                                                              .quantidade--,
                                                        );
                                                      } else {
                                                        shownDialogErrorTwoBottom(
                                                          context: context,
                                                          title:
                                                              "Deseja descartar este ${produto.nome}?",
                                                          icon: Icons.delete,
                                                          onConfirm: () {
                                                            removerProdutoDoCarrinhoPorNumeroIndex(
                                                              produto.numero,
                                                              index,
                                                            );
                                                            setState(() {});
                                                          },
                                                          onCancel: () {
                                                            Navigator.of(
                                                              context,
                                                            ).pop();
                                                          },
                                                        );
                                                      }
                                                    },
                                            ),

                                          Flexible(
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 4,
                                              ),
                                              child: Text(
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                                ehKilo
                                                    ? produto.quantidade.toStringAsFixed(3)
                                                    : produto.temMeiaPorcao
                                                        ? produto.quantidade.toStringAsFixed(2)
                                                        : produto.quantidade.toStringAsFixed(0),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                ),
                                              ),
                                            ),
                                          ),

                                          if (!ehKilo)
                                            IconButton(
                                              icon: Icon(
                                                Icons.add,
                                                color: ehKilo
                                                    ? Colors.transparent
                                                    : Colors.black,
                                              ),
                                              onPressed: ehKilo
                                                  ? null
                                                  : () {
                                                      setState(
                                                        () => produto
                                                            .quantidade++,
                                                      );
                                                    },
                                            ),
                                        ],
                                      ),
                                    ),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancelar"),
            ),
          ],
        );
      },
    ).then((_) {
      _popupGarcomAberto = false;
    });
  }
 

  // Função com o popup para selecionar garçom
  void popupSelecionarGarcom() {
    if (_popupGarcomAberto) return;
    if (!cliqueiSelecionarGarcom) return;
    _popupGarcomAberto = true;    
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
                            cliqueiSenha = true;
                            cliqueiSelecionarGarcom = false;
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
                              focusNode: senhaFocus,
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
                cliqueiSelecionarGarcom = false;
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
  // Dialogo selecionar senha 
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
    FocusNode? focusNode,
    ValueChanged<String>? onSubmitted, // Callback ao submeter o texto
  }) {
    shakeKey = 0;

    if (focusNode != null) {
      if (focusNode.hasFocus) focusNode.unfocus();
      Future.delayed(Duration(milliseconds: 300), () {
        if (focusNode.canRequestFocus) {
          focusNode.requestFocus();
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        }
      });
    }

    if (!cliqueiSenha) {
      Navigator.of(context).pop();
    }
    
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
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: isLoadingSenha ? Column(
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

                    Animate(
                      key: ValueKey(shakeKey),
                      effects: shakeKey == 0 ? [] : [
                        ShakeEffect(
                          duration: Duration(milliseconds: 500),
                          hz: 4,
                          offset: Offset(10, 0),
                        ),
                      ],
                      child:  Pinput(
                        autofocus: true,
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
                          if (erroBool) {
                            setDialogState(() {
                              erro = "";
                              erroBool = false;
                            });
                          }
                        },
                      
                        onCompleted: (value) async {
                          // executa quando preencher os 6 dígitos
                          if (value != senhaDoGarcom) {
                            setDialogState(() {
                              erro = "Senha incorreta";
                              shakeKey++;
                              senhaController.clear();
                              erroBool = true;
                              Future.delayed(Duration(milliseconds: 300), () {
                                if (senhaFocus.canRequestFocus) {
                                  senhaFocus.requestFocus();
                                }
                              });
                            });
                            print("Senha incorreta");
                          } else {
                            setDialogState(() {
                              isLoadingSenha = false;
                            });
                            await funcoesController.carregarTudo();
                            await _saveGarcom(nomeDoGarcomFuncao);
                            await _saveNumeroGarcom(numeroDoGarcomFuncao);
                            garcomSelecionado = true;
                            numeroDoGarcom = numeroDoGarcomFuncao.toString();
                            nomeDoGarcom = nomeDoGarcomFuncao;
                            nomeDoGarcomSelecionado = nomeDoGarcom;
                            senhaController.text = "";
                            funcoesController.controlarAparecimentoBotaoPagar(pagamentoDoGarcomFuncao);
                            if (Navigator.canPop(ctx)) {
                              Navigator.of(ctx, rootNavigator: true).pop();
                            }
                            setDialogState(() {
                              isLoadingSenha = true;
                            });
                            cliqueiSenha = false;
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
                            Navigator.pop(ctx);
                            senhaController.clear();
                            cliqueiSenha = false;
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
                            if (senhaController.text != senhaDoGarcom) {
                              setDialogState(() {
                                erro = "Senha incorreta";
                                shakeKey++;
                                senhaController.clear();
                                erroBool = true;
                                Future.delayed(Duration(milliseconds: 300), () {
                                  if (senhaFocus.canRequestFocus) {
                                    senhaFocus.requestFocus();
                                  }
                                });
                              });
                            } else {
                              setDialogState(() {
                                isLoadingSenha = false;
                              });
                              await funcoesController.carregarTudo();
                              await _saveGarcom(nomeDoGarcomFuncao); 
                              await _saveNumeroGarcom(numeroDoGarcomFuncao);
                              garcomSelecionado = true;
                              numeroDoGarcom = numeroDoGarcomFuncao.toString();
                              nomeDoGarcom = nomeDoGarcomFuncao;
                              nomeDoGarcomSelecionado = nomeDoGarcom;
                              senhaController.text = "";
                              funcoesController.controlarAparecimentoBotaoPagar(pagamentoDoGarcomFuncao);
                              if (Navigator.canPop(ctx)) {
                                Navigator.of(ctx, rootNavigator: true).pop();
                              }
                              setDialogState(() {
                                isLoadingSenha = true;
                              });
                              cliqueiSenha = false;
                            }
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
                ) : 
                SizedBox(
                  width: 280,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      Container(
                        padding: EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(ctx)
                              .colorScheme
                              .primary
                              .withOpacity(0.08),
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
                        style: Theme.of(ctx)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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

  // Função para atualizar hora
  void _atualizarHora() {
    if (!mounted) return;
    final agora = DateTime.now();
    final horaFormatada = DateFormat.Hm().format(agora);
    setState(() {
      _horaAtual = horaFormatada;
    });
    _loadComanda();
  }

  // Sincroniza showKeyboardAlfa com o estado real do foco nativo
  void _syncKeyboardAlfaFromFocus() {
    if (!mounted) return;
    // Se o bloqueio global de foco estiver ativo (diálogo aberto),
    // ignora qualquer mudança de teclado para não abrir o teclado durante o diálogo.
    if (_bloqueandoFoco) return;
    final hasFocus = cardapioFocus.hasFocus || observacaoProdutoSelecionadoFocus.hasFocus;
    if (hasFocus != showKeyboardAlfa) {
      setState(() {
        showKeyboardAlfa = hasFocus;
      });
    }
  }

  @override
  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    cardapioFocus.removeListener(_syncKeyboardAlfaFromFocus);
    observacaoProdutoSelecionadoFocus.removeListener(_syncKeyboardAlfaFromFocus);
    
    // Check if these objects are properly disposed.
    // _focoBloqueio.dispose();
    // _focusNode.dispose();
    // _focusNodeCardapio.dispose();
    // animationController.dispose();
    // comandaController.dispose();
    // mesaController.dispose();
    // comandaFocus.dispose();
    // mesaFocus.dispose();
    // cardapioFocus.dispose();
    // numeroProdutoSelecionadoFocus.dispose();
    // quantidadeProdutoSelecionadoFocus.dispose();
    // observacaoProdutoSelecionadoFocus.dispose();
    // senhaFocus.dispose();
    // _scrollController.dispose();
    
    super.dispose();
  }

  // Função para limpar comanda
  void limparComanda() {
    comandaController.text = '';
    comandaController.clear();
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
        servidorController.text = servidorSalvo; // Atualiza o controller com o valor carregado
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

  // Carregar/Salvar garçom
  Future<void> _loadGarcom() async {
    final prefs = await SharedPreferences.getInstance();
    final garcomSalvo = prefs.getString('garcom');
    if (garcomSalvo != null && mounted) {
      nomeDoGarcom = garcomSalvo;
      nomeDoGarcomSelecionado = garcomSalvo;
      setState(() {
        nomeDoGarcom = garcomSalvo;
        nomeDoGarcomSelecionado = garcomSalvo;
        nomeDoGarcomDoLoad = true;
        garcomSelecionado = true;
      });
      informacoesGarcom(nomeDoGarcom);
    }
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

  // Funcao para adicionar no teclado quantidade
  void _adicionarNumeroQuantidade(String valor) {
    String textoAtual = quantidadeProdutoSelecionadoController.text;

    if (valor == ".") {
      if (!textoAtual.contains(".")) {
        final newText = textoAtual + valor;

        quantidadeProdutoSelecionadoController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    } else {
      final newText = textoAtual + valor;

      quantidadeProdutoSelecionadoController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }
  /* void _adicionarNumeroQuantidade(String valor) {
    String textoAtual = quantidadeProdutoSelecionadoController.text;

    // verifica se ainda existe ponto no texto
    if (!textoAtual.contains(".")) {
      contadorPonto = 0;
    }

    if (valor == ".") {
      if (contadorPonto == 0) {
        final newText = textoAtual + valor;

        quantidadeProdutoSelecionadoController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );

        contadorPonto = 1;
      }
    } else {
      final newText = textoAtual + valor;

      quantidadeProdutoSelecionadoController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  } */

  // Funcao para remover
  void _apagarNumeroQuantidade() {
    if (quantidadeProdutoSelecionadoController.text.isEmpty) return;
    final newText = quantidadeProdutoSelecionadoController.text.substring(
      0,
      quantidadeProdutoSelecionadoController.text.length - 1,
    );
    quantidadeProdutoSelecionadoController.text = newText;
  }

  // Inserir texto
  void _inserirTexto(TextEditingController controller, String valor) {
    final newText = controller.text + valor;

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  // Função nova para adicionar número
  void _adicionarNumero(String valor) {
    HapticFeedback.lightImpact();
    setState(() {
      switch (_campoAtivo) {
        // Servidor controller
        case 'servidorController':
          _inserirTexto(servidorController, valor);
          break;

        // Comanda controller
        case 'comandaController':
          _inserirTexto(comandaController, valor);
          break;

        // Mesa controller
        case 'mesaController':
          _inserirTexto(mesaController, valor);
          break;

        // Campo de busca - Cardapio controller
        case 'cardapioController':
          _inserirTexto(cardapioController, valor);
          filtrarProdutos(cardapioController.text);
          break;

        // Numero do produto selecionado - numeroProdutoSelecionadoController
        case 'numeroProdutoSelecionadoController':
          _inserirTexto(numeroProdutoSelecionadoController, valor);
          break;

        // Quantidade do produto selecionado - quantidadeProdutoSelecionadoController
        case 'quantidadeProdutoSelecionadoController':
          _inserirTexto(quantidadeProdutoSelecionadoController, valor);
          break;

        // Observacao do produto selecionado - observacaoProdutoSelecionadoController
        case 'observacaoProdutoSelecionadoController':
          _inserirTexto(observacaoProdutoSelecionadoController, valor);
          break;
      }
    });
  }

  // Apaga o último caractere
  void _removerUltimoCaractere(TextEditingController controller) {
    if (controller.text.isEmpty) return;
    final newText = controller.text.substring(0, controller.text.length - 1);
    controller.text = newText;
    if (controller.text.isEmpty && _campoAtivo == 'comandaController') {
      zerarAtendimento();
    }
    if (controller.text.isEmpty && _campoAtivo == 'mesaController') {
      zerarAtendimento();
    }
  }

  // Função para aágar último digito
  void _apagarNumero() {
    HapticFeedback.lightImpact();
    setState(() {
      switch (_campoAtivo) {
        // Servidor controller
        case 'servidorController':
          _removerUltimoCaractere(servidorController);
          break;

        // Comanda controller
        case 'comandaController':
          _removerUltimoCaractere(comandaController);
          break;

        // Mesa controller
        case 'mesaController':
          _removerUltimoCaractere(mesaController);
          break;

        // Campo de busca - Cardapio controller
        case 'cardapioController':
          _removerUltimoCaractere(cardapioController);
          filtrarProdutos(cardapioController.text);
          break;

        // Numero do produto selecionado - numeroProdutoSelecionadoController
        case 'numeroProdutoSelecionadoController':
          _removerUltimoCaractere(numeroProdutoSelecionadoController);
          break;

        // Quantidade do produto selecionado - quantidadeProdutoSelecionadoController
        case 'quantidadeProdutoSelecionadoController':
          _removerUltimoCaractere(quantidadeProdutoSelecionadoController);
          break;

        // Observacao do produto selecionado - observacaoProdutoSelecionadoController
        case 'observacaoProdutoSelecionadoController':
          _removerUltimoCaractere(observacaoProdutoSelecionadoController);
          break;
      }
    });
  }

  // Função para confirmar no dialogo
  confirmarQueroMesa(String numeroMesa, String numeroComanda) async {
    await validarMesa(numeroMesa);
    if (mesaController.text.isNotEmpty) {
      if (mesaValida) {
        aparecerFazerPedido = true;
      } else {
        if (!funcoesController.logicaPorMesa.value) {
          if (mesaComandaNaoTemConta) {
            showErrorDialog(
              context: context,
              title: mensagemNaMesa != ""
                  ? "$mensagemNaMesa"
                  : "Mesa indisponível!",
              message: "",
              icon: Icons.error, // você pode trocar para outro ícone
              onConfirm: () async {
                _dialogVincularMesa(false);
                if (funcoesController.logicaPorComandaNaMesa.value) {
                  comandaController.text = numeroComanda;
                  numeroComandaEmUso = numeroComanda;
                }
              },
            );
            if (funcoesController.logicaPorComandaNaMesa.value) {
              comandaController.text = numeroComanda;
              numeroComandaEmUso = numeroComanda;
            }
          }
        }
      }
    } else {
      // Quando esta vazio dialogo de mesa so passa reto
      await verificarSeTemConta(comandaController.text);
      mesaController.clear();
      /* comandaController.text = numeroComandaEmUso; */
      numeroComandaEmUso = numeroComanda;
      _irParaCardapio();
      if (mesaVinculada) {
        /* mesaController.text = numeroMesaEmUso; */
        numeroComandaEmUso = numeroComanda;
      }
    }
  }

  nada() {}

  // Função para confirmar numero da comanda
  void _confirmar() async {
    // Se estiver configurando produto
    HapticFeedback.lightImpact();

    if (isProcessingConfirmar) return;

    setState(() {
      isProcessingConfirmar = true;
    });

    try {
      if (aparecerConfiguracaoProduto) {
        _confirmarProduto();
        return;
      }

      // Se não pode continuar
      if (!mesaComandaNaoTemConta) return;

      // Se está na tela de escolha de mesa
      if (funcoesController.logicaPorComandaNaMesa.value) {
        await _fluxoComandaNaMesa();
        return;
      }

      if (funcoesController.logicaPorMesa.value) {
        await _fluxoMesa();
        return;
      }

      if (funcoesController.logicaPorComanda.value) {
        await _fluxoComanda();
        aparecerPopUpCliente();
        return;
      }
    } finally {
      setState(() {
        isProcessingConfirmar = false;
      });
    }
  }

  // Funçãp para configurar produto
  void _confirmarProduto() {
    final nome = cardapioController.text;
    final numero = numeroProdutoSelecionadoController.text;
    final qtdText = quantidadeProdutoSelecionadoController.text.replaceAll(',', '.');
    final quantidade = produtoKilo 
        ? (double.tryParse(qtdText) ?? 1.0)
        : (double.tryParse(qtdText)?.roundToDouble() ?? 1.0);
    final observacao = observacaoProdutoSelecionadoController.text;
    final valor = valorDoProdutoSelecionado.toString();

    carrinhoController.adicionarProdutoAoCarrinho(
      nome,
      valor,
      numero,
      quantidade,
      observacao,
      idDoProdutoSelecionado,
      adicionais: adicionaisSelecionados,
    );

    setState(() {
      aparecerConfiguracaoProduto = false;
      aparecerBotoes = true;
      aparecerCarrinho = true;
      aparecerLista = false;
      mostrarGrupos = true;
      mostrarProdutos = false;
      showKeyboardAlfa = false;
      showKeyboardNumero = false;
      showKeyboardQuantidade = false;
      aparecerFazerPedido = true;
      quantidadeInicial = 1;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      limparInformacoesProduto();
      cardapioController.clear();
    });
  }

  void aparecerPopUpCliente() async {
    clienteJaExisteComanda = await buscarInformacoesClientePedidoAberto(numeropedido_FK, estadoPopupCadastro ?? setState);
    if(garcomController.forcarCadastroCliente.value){
      if(garcomController.cadastroCliente.value && !clienteJaExisteComanda){
        popupCadastrarCliente();
      }
    }
  }

  void informacoesCliente() async {
    clienteJaExisteComanda = await buscarInformacoesClientePedidoAberto(numeropedido_FK, estadoPopupCadastro ?? setState);
  }

  // Função para lógica comanda na mesa
  Future<void> _fluxoComandaNaMesa() async {
    if (vinculandoMesa) {
      _dialogVincularMesa(false); 
      return;
    }

    if (comandaController.text.isEmpty) {
      _erroComanda();
      return;
    }

    await validarComanda(comandaController.text);

    if(comandaValida){
      carrinhoController.numeroComanda.value = comandaController.text;
      informacoesCliente();
    }

    if (!comandaValida) {
      _erroComanda();
      return;
    }

    if (comandaValida && !mesaVinculada) {
      _dialogVincularMesa(true);
      carrinhoController.numeroComanda.value = comandaController.text;
      setState(() {
        empurrarBotoes = false;
      });
      return;
    }

    if (mesaVinculada) {
      carrinhoController.numeroMesa.value = mesaController.text;
      _irParaCardapio();
      aparecerPopUpCliente();
      return;
    }
  }

  //Função lógica mesa
  Future<void> _fluxoMesa() async {
    await validarMesa(mesaController.text);

    if (mesaValida) {
      setState(() {
        carrinhoController.numeroMesa.value = mesaController.text;
        aparecerFazerPedido = true;
        aparecerCardapio = true;
        numeroMesaEmUso = mesaController.text;
        comandaValida = true;
        empurrarBotoes = false;
        /* Future.delayed(Duration(milliseconds: 300), () {
          if (cardapioFocus.canRequestFocus) {
            cardapioFocus.requestFocus();
          }
        }); */
        // carregarUltimaConfiguracao();
      });
      informacoesCliente();
      entrarModoTouch();
      _selecionarPrimeiroGrupo();
      return;
    }

    _erroMesa();
  }

  // Função lógica comanda
  Future<void> _fluxoComanda() async {
    await validarComanda(comandaController.text);

    if (comandaValida) {
      setState(() {
        carrinhoController.numeroComanda.value = comandaController.text;
        aparecerFazerPedido = true;
        aparecerCardapio = true;
        numeroComandaEmUso = comandaController.text;
        /* Future.delayed(Duration(milliseconds: 300), () {
          if (cardapioFocus.canRequestFocus) {
            cardapioFocus.requestFocus();
          }
        }); */
        // carregarUltimaConfiguracao();
      });
      entrarModoTouch();
      _selecionarPrimeiroGrupo();
      return;
    }

    _erroComanda();
  }

  // Função Diálogo de vincular mesa
  void _dialogVincularMesa(bool aparecer) {
    setState(() {
      _campoAtivo = 'mesaController';
      Future.delayed(Duration(milliseconds: 300), () {
        if (mesaFocus.canRequestFocus) {
          mesaFocus.requestFocus();
        }
      });
    });
    if (!funcoesController.logicaPorMesa.value) {
      shownDialogTwoBottomKeyboard(
        context: context, 
        title: "Deseja vincular a uma mesa?",
        message: "",
        icon: Icons.table_bar,
        textController: mesaController,
        focusNode: mesaFocus,
        onConfirm: () async {
          await confirmarQueroMesa(mesaController.text, comandaController.text);
          if (mesaValida) {
            comandaController.text = numeroComandaEmUso;
            carrinhoController.numeroMesa.value = mesaController.text;
            _irParaCardapio();
            entrarModoTouch();
            _selecionarPrimeiroGrupo();
            await verificarSeTemConta(comandaController.text);
            setState(() {
              aparecerFazerPedido = true;
            });
          }
          if(aparecer){
            aparecerPopUpCliente();
          }
        },
        onCancel: () async {
          await verificarSeTemConta(comandaController.text);
          mesaController.clear();
          comandaController.text = numeroComandaEmUso;
          _irParaCardapio();
          entrarModoTouch();
          _selecionarPrimeiroGrupo();
          setState(() {
            aparecerFazerPedido = true;
          });
          if (mesaVinculada) {
            mesaController.text = numeroMesaEmUso;
          }
          if(aparecer){
            aparecerPopUpCliente();
          }
        },
      );
    } else {
      mesaController.clear();
    }
  }

  // Função de ir para cardápio
  void _irParaCardapio() {
    setState(() {
      aparecerCardapio = true;
      aparecerCarrinho = true;
      desejaMesa = true;
      showKeyboardAlfa = true;
      showKeyboardQuantidade = false;
      showKeyboardNumero = false;
      empurrarBotoes = false;
      _campoAtivo = 'cardapioController';
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (cardapioFocus.canRequestFocus) {
        cardapioFocus.requestFocus();
      }
    });

    entrarModoTouch();
    _selecionarPrimeiroGrupo();
  }

  // Diálogo de error de mesa
  void _erroMesa() {
    if (mesaComandaNaoTemConta) {
      showErrorDialog(
        context: context,
        title: "$mensagemNaMesa",
        message: "",
        icon: Icons.error, // você pode trocar para outro ícone
        onConfirm: () async {
          if(funcoesController.logicaPorMesa.value){
            // Navigator.pushNamed(context, '/garcom');
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => GarcomPage(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          } else {
          _dialogVincularMesa(false);
          }
        },
      );
      if (funcoesController.logicaPorComandaNaMesa.value) {
        comandaController.text = numeroComandaEmUso;
      }
    }
  }

  // Diálogo de erro de comanda
  void _erroComanda() {
    if (mesaComandaNaoTemConta) {
      showErrorDialog(
        context: context,
        title: "Comanda: ${comandaController.text}\n$mensagem",
        message: "",
        icon: Icons.error,
        onConfirm: () {
          comandaController.clear();
          comandaFocus.requestFocus();
        },
      );
    }
  }

  void colocarFoco(){
    if(garcomController.tipoCadastroClienteCpf.value){
      Future.delayed(Duration(milliseconds: 300), () {
        if (cpfClienteDialogoFocus.canRequestFocus) {
          cpfClienteDialogoFocus.requestFocus();
        }
      });
    } else if (garcomController.tipoCadastroClienteTelefone.value){
      Future.delayed(Duration(milliseconds: 300), () {
        if (telefoneClienteDialogoFocus.canRequestFocus) {
          telefoneClienteDialogoFocus.requestFocus();
        }
      });
    }
  }


  // Dialogo com só um botão - verde confirmação
  Future<void> showConfirmationDialog({
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
                    color: icone
                        ? Theme.of(ctx).colorScheme.shadow.withOpacity(0.08)
                        : Theme.of(ctx).colorScheme.error.withOpacity(0.08),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    icon,
                    size: 40,
                    color: icone
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
                        backgroundColor: icone
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

  // Dialogo com só um botão - vermelho erro
  Future<void> showErrorDialog({
    required BuildContext context,
    String title = 'Confirmação',
    required String message,
    IconData icon = Icons.home,
    String cancelText = 'Cancelar',
    String confirmText = 'OK',
    VoidCallback? onConfirm,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(curvedAnim),
          child: FadeTransition(
            opacity: curvedAnim,
            child: Dialog(
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
                        color: Theme.of(
                          ctx,
                        ).colorScheme.error.withOpacity(0.08),
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

                    // Botões centralizados
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Confirmar
                        ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
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
                            backgroundColor: Theme.of(ctx).colorScheme.error,
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
  }

  // Dialogo com dois botões
  Future<void> shownDialogTwoBottom({
    required BuildContext context,
    String title = 'Confirmação',
    required String message,
    IconData icon = Icons.home,
    String cancelText = 'Não',
    String confirmText = 'Sim',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    TextEditingController? textController,
    FocusNode? focusNode,
    ValueChanged<String>? onSubmitted, // Callback ao submeter o texto
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(curvedAnim),
          child: FadeTransition(
            opacity: curvedAnim,
            child: Dialog(
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
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    SizedBox(height: 5),

                    // Campo de texto com controladores
                    if (textController != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 15.0),
                        child: TextField(
                          onTap: () {
                            focusNode?.requestFocus();
                          },
                          keyboardType: TextInputType.number,
                          controller: textController,
                          focusNode: focusNode,
                          onSubmitted: onSubmitted,
                          autofocus: true,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: 'Digite aqui...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(12),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(ctx).colorScheme.primary,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(ctx).colorScheme.primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                    // Botões centralizados
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Botão Cancelar
                        ElevatedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(ctx).pop();
                            if (onCancel != null) onCancel();
                          },
                          child: Text(
                            cancelText.toUpperCase(),
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
                            backgroundColor: Theme.of(ctx).colorScheme.primary,
                          ),
                        ),
                        SizedBox(width: 10),
                        // Botão Confirmar
                        ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
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
                            backgroundColor: Theme.of(
                              ctx,
                            ).colorScheme.secondary,
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
  }

  Widget _buildCampoCliente({
    required BuildContext context,
    required TextEditingController controller,
    required FocusNode currentFocus,
    FocusNode? nextFocus,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    TextCapitalization textCapitalization = TextCapitalization.none,
    VoidCallback? onDone,
    List<TextInputFormatter>? inputFormatters,
    required double tamanhoFonte,
    required double tamanhoHint,
    required double paddingInterno,
    Function(String)? onChanged,
    required bool mostrarErro,
  }) {
    return TextField(
      controller: controller,
      focusNode: currentFocus,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: clienteJaExisteComanda ? textCapitalization : TextCapitalization.none,
      inputFormatters: inputFormatters,
      readOnly: clienteJaExisteComanda,
      textAlign: TextAlign.center,
      onTap: () {
        currentFocus.requestFocus();
      },
      onSubmitted: (_) {
        if (nextFocus != null) {
          nextFocus.requestFocus();
        } else if (onDone != null) {
          onDone();
        }
      },
      onChanged: onChanged,
      style: TextStyle(
        fontSize: tamanhoFonte,
        fontWeight: FontWeight.bold,
        color: const Color.fromARGB(255, 71, 71, 71),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: const Color.fromARGB(255, 173, 173, 173),
          fontSize: tamanhoHint,
        ),
        contentPadding: EdgeInsets.all(paddingInterno),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: mostrarErro ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: mostrarErro ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> shownDialogTwoBottomKeyboard({
    required BuildContext context,
    String title = 'Confirmação',
    required String message,
    IconData icon = Icons.home,
    String cancelText = 'Não',
    String confirmText = 'Sim',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    TextEditingController? textController,
    FocusNode? focusNode,
    ValueChanged<String>? onSubmitted, // Callback ao submeter o texto
  }) {
    Future<void> handleConfirm(BuildContext ctx) async {
      Navigator.of(ctx).pop();

      if (onConfirm != null) {
        onConfirm();
      }
    }

    return showDialog(
      context: context,
      barrierDismissible: false, // Não pode fechar tocando fora
      builder: (ctx) {
        return Scaffold(
          backgroundColor: Colors.transparent, // Torna o Scaffold transparente para agir como um wrapper
          resizeToAvoidBottomInset: false, // Nós controlaremos o insets via AnimatedPadding
          body: AnimatedPadding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.9, // Altura máxima 90%
                  maxWidth: MediaQuery.of(ctx).size.width > 600 ? 500 : MediaQuery.of(ctx).size.width * 0.95, // Largura em tabelt/TV e mobile
                ),
                child: Material(
                  color: Theme.of(ctx).dialogBackgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double largura = constraints.maxWidth;
                      final double altura = constraints.maxHeight;

                      // Tamanhos responsivos
                      final double tamanhoFonte = (largura * 0.035).clamp(16.0, 25.0);
                      final double tamanhoHint = (largura * 0.028).clamp(13.0, 20.0);
                      final double espacamento = (altura * 0.015).clamp(8.0, 15.0);
                      final double paddingInterno = (largura * 0.025).clamp(10.0, 20.0);

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // Não usamos Expanded para o layout acompanhar o conteúdo
                          children: [
                            // Ícone central
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(ctx).colorScheme.primary.withOpacity(0.08),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                icon,
                                size: 40,
                                color: Theme.of(ctx).colorScheme.primary,
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Título opcional
                            if (title.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  title,
                                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(255, 71, 71, 71),
                                    fontSize: 24,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            const SizedBox(height: 5),

                            // CAMPO DE TEXTO OPCIONAL EXISTENTE (comanda/mesa)
                            if (textController != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 15.0),
                                child: TextField(
                                  onTap: () {
                                    focusNode?.requestFocus();
                                  },
                                  keyboardType: TextInputType.number, // TECLADO NUMÉRICO
                                  controller: textController,
                                  readOnly: false,
                                  showCursor: true,
                                  focusNode: focusNode,
                                  onSubmitted: (value) async {
                                    await handleConfirm(ctx);
                                    /* if (mesaController.text.isEmpty) {
                                      await verificarSeTemConta(comandaController.text);
                                      mesaController.clear();
                                      comandaController.text = numeroComandaEmUso;
                                      _irParaCardapio();
                                      setState(() {
                                        aparecerFazerPedido = true;
                                      });
                                      if (mesaVinculada) {
                                        mesaController.text = numeroMesaEmUso;
                                      }
                                    } else {
                                      await confirmarQueroMesa(mesaController.text, comandaController.text);
                                      if (mesaValida) {
                                        comandaController.text = numeroComandaEmUso;
                                        _irParaCardapio();
                                        await verificarSeTemConta(comandaController.text);
                                        setState(() {
                                          aparecerFazerPedido = true;
                                        });
                                      }
                                    }
                                    Navigator.pop(ctx); */
                                  },
                                  autofocus: focusNode == null ? true : false,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 35,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 71, 71, 71),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Digite aqui...',
                                    hintStyle: const TextStyle(
                                      color: Color.fromARGB(255, 173, 173, 173),
                                      fontSize: 20,
                                    ),
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.all(20),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Theme.of(ctx).colorScheme.primary,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Theme.of(ctx).colorScheme.primary,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),

                            // Botões centralizados
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Botão Cancelar
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        if (onCancel != null) onCancel();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 26,
                                          vertical: 20,
                                        ),
                                        backgroundColor: Theme.of(ctx).colorScheme.error.withOpacity(0.7),
                                      ),
                                      child: Text(
                                        cancelText.toUpperCase(),
                                        style: TextStyle(
                                          color: Theme.of(ctx).colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  // Botão Confirmar
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        handleConfirm(ctx);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 26,
                                          vertical: 20,
                                        ),
                                        backgroundColor: Theme.of(ctx).colorScheme.primary,
                                      ),
                                      child: Text(
                                        confirmText.toUpperCase(),
                                        style: TextStyle(
                                          color: Theme.of(ctx).colorScheme.onPrimary,
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
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /* String formatarData(String data) {
    if (data.trim() == "01/01/1000" || data.contains("1000-01-01")) {
      return "";
    }
    
    DateTime date;

    try {
      if (data.contains('-')) {
        date = DateTime.parse(data);
        if (data.trim().endsWith('/1000')) {
          final partes = data.trim().split('/');

          final dia = int.parse(partes[0]);
          final mes = int.parse(partes[1]);

          date = DateTime(2000, mes, dia);
          date = DateFormat('dd/MM').parse(data.substring(0, 5));
        }
      } else {
        date = DateFormat('dd/MM/yyyy').parse(data);
      }
    } catch (_) {
      return data;
    }

    String dataFormatada = data.trim().endsWith('/1000') ? DateFormat('dd/MM').format(date) : DateFormat('dd/MM/yyyy').format(date);
    if (dataFormatada == '01/01/1000') {
      return "";
    }
    return dataFormatada;
  } */

  String formatarData(String data) {
    data = data.trim();

    if (data == "01/01/1000" || data.contains("1000-01-01")) {
      return "";
    }

    try {
      // Data especial: 07/12/1000
      if (data.endsWith('/1000')) {
        final partes = data.split('/');

        if (partes.length >= 2) {
          final dia = int.parse(partes[0]);
          final mes = int.parse(partes[1]);

          // Cria uma data usando ano fictício apenas internamente
          final date = DateTime(2000, mes, dia);

          return DateFormat('dd/MM').format(date);
        }
      }

      // Data vinda do banco: 2021-02-01
      if (data.contains('-')) {
        final date = DateTime.parse(data);
        if (date.year == 1000) {
          return DateFormat('dd/MM').format(date);
        }
        return DateFormat('dd/MM/yyyy').format(date);
      }

      // Data normal: 07/12/2006
      final date = DateFormat('dd/MM/yyyy').parseStrict(data);
      if (date.year == 1000) {
        return DateFormat('dd/MM').format(date);
      }
      return DateFormat('dd/MM/yyyy').format(date);

    } catch (_) {
      return data;
    }
  }

  Future<void> popupCadastrarCliente() {
    // ── Snapshot dos dados originais ao abrir o popup ──────────────────────
    clienteCadastradoVisual = clienteJaCadastrado.value;
    _snapshotNome = nomeClienteDialogoController.text;
    _snapshotTelefone = telefoneClienteDialogoController.text;
    _snapshotCpf = cpfClienteDialogoController.text;
    if(dataNascimentoClienteDialogoController.text.isNotEmpty){
      _snapshotDataNascimento = formatarData(dataNascimentoClienteDialogoController.text);
      dataNascimentoClienteDialogoController.text = _snapshotDataNascimento;
    } else {
      _snapshotDataNascimento = "";
    }

    if (_snapshotDataNascimento.trim() == "01/01/1000" || 
        dataNascimentoClienteDialogoController.text.trim() == "01/01/1000" ||
        _snapshotDataNascimento.contains("1000-01-01") ||
        dataNascimentoClienteDialogoController.text.contains("1000-01-01")) {
        
      dataNascimentoClienteDialogoController.text = "";
      _snapshotDataNascimento = "";
    }

    if (clienteJaExisteComanda) {
      _snapshotTelefone = telefoneClienteDialogoController.text;
    } else if (telefoneClienteDialogoController.text.isEmpty && !clienteJaExisteComanda) {
      _maskFormatter.clear();
      String empTel = garcomController.telefoneEmpresa;
      var initialVal = _maskFormatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
          text: empTel,
          selection: TextSelection.collapsed(offset: empTel.length),
        ),
      );

      String finalString = initialVal.text;
      if (finalString == '($empTel' || finalString == '($empTel)') {
        finalString = '($empTel) ';
        initialVal = _maskFormatter.formatEditUpdate(
          initialVal,
          TextEditingValue(
            text: finalString,
            selection: TextSelection.collapsed(offset: finalString.length),
          ),
        );
      }
      telefoneClienteDialogoController.value = initialVal;
    }

    colocarFoco();

    return showDialog(
      context: context,
      barrierDismissible: false, // Não pode fechar tocando fora
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStatePopup) {
            estadoPopupCadastro = setStatePopup;
            return Scaffold(
              backgroundColor: Colors.transparent, // Torna o Scaffold transparente para agir como um wrapper
          resizeToAvoidBottomInset: false, // Nós controlaremos o insets via AnimatedPadding
          body: AnimatedPadding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.9, // Altura máxima 90%
                  maxWidth: MediaQuery.of(ctx).size.width > 600 ? 500 : MediaQuery.of(ctx).size.width * 0.95, // Largura em tabelt/TV e mobile
                ),
                child: Material(
                  color: Theme.of(ctx).dialogBackgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double largura = constraints.maxWidth;
                      final double altura = constraints.maxHeight;

                      // Tamanhos responsivos
                      final double tamanhoFonte = (largura * 0.035).clamp(16.0, 25.0);
                      final double tamanhoHint = (largura * 0.028).clamp(13.0, 20.0);
                      final double espacamento = (altura * 0.015).clamp(8.0, 15.0);
                      final double paddingInterno = (largura * 0.025).clamp(10.0, 20.0);

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // Não usamos Expanded para o layout acompanhar o conteúdo
                          children: [
                            // Ícone central
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(ctx).colorScheme.primary.withOpacity(0.08),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Theme.of(ctx).colorScheme.primary,
                              ),
                            ),

                            SizedBox(height: 10),

                            Padding(
                              padding: EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                clienteJaExisteComanda ? "Informações do cliente:" : "Deseja vincular a um cliente?",
                                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromARGB(255, 71, 71, 71),
                                  fontSize: 24,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            // TELEFONE
                            if(garcomController.tipoCadastroClienteTelefone.value)
                            Padding(
                              padding: EdgeInsets.only(bottom: espacamento),
                              child: _buildCampoCliente(
                                context: context,
                                controller: telefoneClienteDialogoController,
                                currentFocus: telefoneClienteDialogoFocus,
                                nextFocus: cpfClienteDialogoFocus,
                                hintText: 'Telefone',
                                keyboardType: TextInputType.phone,
                                tamanhoFonte: tamanhoFonte,
                                tamanhoHint: tamanhoHint,
                                paddingInterno: paddingInterno,
                                inputFormatters: [_maskFormatter],
                                onChanged: (value) {
                                  validarTelefoneDialogo(value);
                                  if(!telefoneValido){
                                    nomeClienteDialogoController.clear();
                                    nomeClienteDialogoController.text = "";
                                    dataNascimentoClienteDialogoController.clear();
                                    dataNascimentoClienteDialogoController.text = "";
                                    clienteCadastradoVisual = false;
                                  }
                                  if(telefoneValido && nomeClienteDialogoController.text.isEmpty){
                                    Future.delayed(Duration(milliseconds: 300), () {
                                      if (nomeClienteDialogoFocus.canRequestFocus) {
                                        nomeClienteDialogoFocus.requestFocus();
                                      }
                                    });
                                    clienteCadastradoVisual = false;
                                  }

                                  if(telefoneValido && nomeClienteDialogoController.text.isNotEmpty){
                                    clienteCadastradoVisual = true;
                                  }
                                  setStatePopup(() {});
                                },
                                mostrarErro: telefoneErro
                              ),
                            ),

                            // CPF
                            if(garcomController.tipoCadastroClienteCpf.value)
                            Padding(
                              padding: EdgeInsets.only(bottom: espacamento),
                              child: _buildCampoCliente(
                                context: context,
                                controller: cpfClienteDialogoController,
                                currentFocus: cpfClienteDialogoFocus,
                                nextFocus: dataNascimentoClienteDialogoFocus,
                                hintText: 'CPF',
                                keyboardType: TextInputType.number,
                                tamanhoFonte: tamanhoFonte,
                                tamanhoHint: tamanhoHint,
                                paddingInterno: paddingInterno,
                                onChanged: (value) {
                                  validarCpfDialogo(value);
                                  if(!cpfValido){
                                    nomeClienteDialogoController.clear();
                                    nomeClienteDialogoController.text = "";
                                    dataNascimentoClienteDialogoController.clear();
                                    dataNascimentoClienteDialogoController.text = "";
                                    clienteCadastradoVisual = false;
                                  }
                                  if(cpfValido && nomeClienteDialogoController.text.isEmpty){
                                    Future.delayed(Duration(milliseconds: 300), () {
                                      if (nomeClienteDialogoFocus.canRequestFocus) {
                                        nomeClienteDialogoFocus.requestFocus();
                                      }
                                    });
                                    clienteCadastradoVisual = false;
                                  }

                                  if(cpfValido && nomeClienteDialogoController.text.isNotEmpty){
                                    clienteCadastradoVisual = true;
                                  }
                                  setStatePopup(() {});
                                },
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(11),
                                ],
                                mostrarErro: cpfErro
                              ),
                            ),

                            
                            // NOME
                            if((garcomController.tipoCadastroClienteCpf.value && cpfValido) || (garcomController.tipoCadastroClienteTelefone.value && telefoneValido) || (clienteJaExisteComanda))
                            Padding(
                              padding: EdgeInsets.only(bottom: espacamento),
                              child: _buildCampoCliente(
                                context: context,
                                controller: nomeClienteDialogoController,
                                currentFocus: nomeClienteDialogoFocus,
                                nextFocus: dataNascimentoClienteDialogoFocus,
                                hintText: 'Nome do cliente',
                                textCapitalization: TextCapitalization.words,
                                tamanhoFonte: tamanhoFonte,
                                tamanhoHint: tamanhoHint,
                                paddingInterno: paddingInterno,
                                onChanged: (value) {
                                  validarNomeDialogo(value);
                                  setStatePopup(() {});
                                },
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-ZÀ-ÿ\s]'),
                                  ),
                                  UpperCaseTextFormatter(),
                                ],
                                mostrarErro: nomeErro
                              ),
                            ),

                            // DATA NASCIMENTO
                            if((garcomController.tipoCadastroClienteCpf.value && cpfValido) || (garcomController.tipoCadastroClienteTelefone.value && telefoneValido) || (clienteJaExisteComanda))
                            Padding(
                              padding: EdgeInsets.only(bottom: espacamento),
                              child: _buildCampoCliente(
                                context: context,
                                controller: dataNascimentoClienteDialogoController,
                                currentFocus: dataNascimentoClienteDialogoFocus,
                                textInputAction: TextInputAction.done,
                                hintText: 'Data de nascimento',
                                keyboardType: TextInputType.datetime,
                                tamanhoFonte: tamanhoFonte,
                                tamanhoHint: tamanhoHint,
                                paddingInterno: paddingInterno,
                                onChanged: (value) {
                                  validarDataNascimentoDialogo(value);
                                  setStatePopup(() {});
                                },
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly, DateInputFormatter(), LengthLimitingTextInputFormatter(10)],
                                mostrarErro: dataNascimentoErro
                              ),
                            ),

                            if(clienteJaExisteComanda)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        Navigator.of(ctx).pop();
                                        _irParaCardapio();
                                        entrarModoTouch();
                                        return;
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 26,
                                          vertical: 20,
                                        ),
                                        backgroundColor: Theme.of(ctx).colorScheme.shadow,
                                      ),
                                      child: Text(
                                        "OK",
                                        style: TextStyle(
                                          color: Theme.of(ctx).colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Botões centralizados
                            if(!clienteJaExisteComanda)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Botão Cancelar
                                  Expanded(
                                    flex: 1,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if(!clienteJaExisteComanda && !volteiPizza){
                                          nomeClienteDialogoController.clear();
                                          telefoneClienteDialogoController.clear();
                                          cpfClienteDialogoController.clear();
                                          dataNascimentoClienteDialogoController.clear();
                                        }
                                        Navigator.of(ctx).pop();
                                        _irParaCardapio();
                                        entrarModoTouch();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 26,
                                          vertical: 20,
                                        ),
                                        backgroundColor: Theme.of(ctx).colorScheme.error.withOpacity(0.7),
                                      ),
                                      child: Text(
                                        "NÃO",
                                        style: TextStyle(
                                          color: Theme.of(ctx).colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  // Botão Confirmar
                                  Expanded(
                                    flex: 1,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final String nomeAtual = nomeClienteDialogoController.text;
                                        final String telefoneAtual = telefoneClienteDialogoController.text;
                                        final String cpfAtual = cpfClienteDialogoController.text;
                                        String dataNascimentoAtual = dataNascimentoClienteDialogoController.text;
                                        if(dataNascimentoAtual.length == 5){
                                          dataNascimentoAtual = dataNascimentoAtual + "/1000";
                                        }

                                        // ── Detectar se chave de busca (telefone/cpf) mudou ────────────
                                        final bool telefoneMudou = garcomController.tipoCadastroClienteTelefone.value && telefoneAtual != _snapshotTelefone;
                                        final bool cpfMudou = garcomController.tipoCadastroClienteCpf.value && cpfAtual != _snapshotCpf;
                                        final bool chaveBuscaMudou = telefoneMudou || cpfMudou;

                                        // ── Detectar se qualquer dado foi alterado ──────────────────
                                        final bool dadosMudaram = nomeAtual != _snapshotNome || telefoneAtual != _snapshotTelefone || cpfAtual != _snapshotCpf || dataNascimentoAtual != _snapshotDataNascimento;

                                        // Validar todos os campos 

                                        bool todosValidos = validarCamposCadastroCliente(setStatePopup);

                                        if(!todosValidos){
                                          return;
                                        } else {
                                          // ── Cenário 1: nada mudou → fechar sem ação ─────────────────
                                          if (!dadosMudaram) {
                                            Navigator.of(ctx).pop();
                                            _irParaCardapio();
                                            entrarModoTouch();
                                            return;
                                          }

                                          // ── Cenário 2: chave de busca mudou com cliente já carregado
                                          //              → nova busca / troca de cliente ───────────────
                                          if (clienteJaCadastrado.value && chaveBuscaMudou) {
                                            // Limpar cliente atual
                                            setState(() {
                                              clienteJaCadastrado.value = false;
                                              numeroCliente = 0;
                                              numeroClienteString = '0';
                                            });

                                            // Nova busca pelo valor digitado
                                            if (garcomController.tipoCadastroClienteTelefone.value) {
                                              await buscarPorNumero(telefoneAtual);
                                            } else {
                                              await buscarPorCpf(cpfAtual);
                                            }

                                            if (clienteJaCadastrado.value) {
                                              // Encontrou outro cliente: apenas atualizar o ID
                                              String? idClienteStr;
                                              if (garcomController.tipoCadastroClienteTelefone.value) {
                                                idClienteStr = await garcomController.buscarNumeroClientePorTelefone(telefoneAtual);
                                              } else {
                                                idClienteStr = await garcomController.buscarNumeroClientePorCpf(cpfAtual);
                                              }
                                              setState(() {
                                                numeroClienteString = idClienteStr ?? '0';
                                                numeroCliente = int.tryParse(numeroClienteString) ?? 0;
                                              });
                                            } else {
                                              // Não encontrou: permite cadastrar novo cliente
                                              validarCampos();
                                              verCadastroCliente();
                                              if (querCadastrarCliente && cadastrarCliente) {
                                                int idClienteRetornado = await garcomController.abrirCliente(
                                                  nomeClienteDialogoController.text,
                                                  cpfAtual,
                                                  dataNascimentoClienteDialogoController.text,
                                                  telefoneAtual,
                                                );
                                                setState(() {
                                                  numeroCliente = idClienteRetornado;
                                                  numeroClienteString = idClienteRetornado.toString();
                                                });
                                              }
                                            }

                                            Navigator.of(ctx).pop();
                                            _irParaCardapio();
                                            entrarModoTouch();
                                            return;
                                          }

                                          // ── Cenário 3: validar e chamar abrirCliente ────────────────
                                          validarCampos();
                                          verCadastroCliente();
                                          if(querCadastrarCliente && cadastrarCliente){
                                            if(!clienteJaCadastrado.value){
                                              // Novo cliente
                                              int idClienteRetornado = await garcomController.abrirCliente(
                                                nomeAtual,
                                                cpfAtual,
                                                dataNascimentoAtual,
                                                telefoneAtual,
                                              );
                                              setState(() {
                                                numeroCliente = idClienteRetornado;
                                                numeroClienteString = idClienteRetornado.toString();
                                              });
                                            } else {
                                              // Atualizar cliente existente
                                              if (garcomController.tipoCadastroClienteTelefone.value) {
                                                String? idClienteStr = await garcomController.buscarNumeroClientePorTelefone(telefoneAtual);
                                                setState(() {
                                                  numeroClienteString = idClienteStr ?? '0';
                                                  numeroCliente = int.tryParse(numeroClienteString) ?? 0;
                                                });
                                                garcomController.atualizarClientePorNumero(
                                                  nomeAtual,
                                                  cpfAtual,
                                                  dataNascimentoAtual,
                                                  telefoneAtual,
                                                );
                                              } else if (garcomController.tipoCadastroClienteCpf.value) {
                                                String? idClienteStr = await garcomController.buscarNumeroClientePorCpf(cpfAtual);
                                                setState(() {
                                                  numeroClienteString = idClienteStr ?? '0';
                                                  numeroCliente = int.tryParse(numeroClienteString) ?? 0;
                                                });
                                                garcomController.atualizarClientePorCpf(
                                                  nomeAtual,
                                                  cpfAtual,
                                                  dataNascimentoAtual,
                                                  telefoneAtual,
                                                );
                                              }
                                              /* int idClienteRetornado = await garcomController.abrirCliente(
                                                nomeAtual,
                                                cpfAtual,
                                                dataNascimentoAtual,
                                                telefoneAtual,
                                              ); */
                                            }
                                            _irParaCardapio();
                                            entrarModoTouch();
                                            Navigator.of(ctx).pop();
                                          } else if (querCadastrarCliente && !cadastrarCliente){
                                            validarCampos();
                                            setStatePopup(() {
                                              if(garcomController.tipoCadastroClienteTelefone.value){
                                                if(!nomeClienteDialogoController.text.isNotEmpty) nomeErro = true;
                                                if(!telefoneValido) telefoneErro = true;
                                                if(!dataNascimentoValida) dataNascimentoErro = true;
                                              } else if (garcomController.tipoCadastroClienteCpf.value){
                                                if(!nomeValido) nomeErro = true;
                                                if(!cpfValido) cpfErro = true;
                                                if(!dataNascimentoValida) dataNascimentoErro = true;
                                              }
                                            });
                                            if(garcomController.tipoCadastroClienteTelefone.value){
                                              setState(() {
                                                if(!nomeValido) nomeErro = true;
                                                if(!telefoneValido) telefoneErro = true;
                                                if(!dataNascimentoValida) dataNascimentoErro = true;
                                              });
                                            } else if (garcomController.tipoCadastroClienteCpf.value){
                                              setState(() {
                                                if(!nomeValido) nomeErro = true;
                                                if(!cpfValido) cpfErro = true;
                                                if(!dataNascimentoValida) dataNascimentoErro = true;
                                              });
                                            }
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 26,
                                          vertical: 20,
                                        ),
                                        backgroundColor: clienteCadastradoVisual ? Theme.of(ctx).colorScheme.primary : Theme.of(ctx).colorScheme.shadow,
                                      ),
                                      child: Text(
                                        clienteCadastradoVisual ? "VINCULAR" : "CADASTRAR",
                                        style: TextStyle(
                                          color: Theme.of(ctx).colorScheme.onPrimary,
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
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        });
      },
    );
  }

  void validarNomeDialogo(String value) {
    if(value.isNotEmpty){
      setState(() {
        nomeValido = true;
        nomeErro = false;
      });
    } else {
      setState(() {
        nomeValido = false;
      });
    }
  }

  void validarTelefoneDialogo(String value) {
    if(value.length == 14){
      setState(() {
        telefoneValido = true;
        telefoneErro = false;
        puxarSeClienteCadastrado(value);
      });
    } else {
      setState(() {
        telefoneValido = false;
      });
    }
  }

  void validarCpfDialogo(String value) {
    final hora = DateTime.now().toIso8601String();

    final bool cpfEhValido = CPFValidator.isValid(value);

    if(cpfEhValido){
      puxarSeClienteCadastrado(value);
      setState(() {
        cpfValido = true;
        cpfErro = false;
      });
    } else {
      setState(() {
        cpfValido = false;
      });
    }
  }

  /* void validarDataNascimentoDialogo(String data) {
    final hora = DateTime.now().toIso8601String();

    final String dataNascimento = data.replaceAll(RegExp(r'[^0-9]'), '');

    if (dataNascimento.isEmpty) {
      setState(() {
        dataNascimentoValida = false;
      });
      return;
    }

    final bool dataEhCorreta = dataNascimento.length >= 8;
    setState(() {
      dataNascimentoValida = dataEhCorreta;
    });
  } */

  /* void validarDataNascimentoDialogo(String data) {
    final String valor = data.replaceAll(RegExp(r'[^0-9]'), '');

    if (valor.length != 8) {
      setState(() {
        dataNascimentoValida = false;
      });
      return;
    }

    final int dia = int.parse(valor.substring(0, 2));
    final int mes = int.parse(valor.substring(2, 4));
    final int ano = int.parse(valor.substring(4, 8));

    try {
      final DateTime dataNascimento = DateTime(ano, mes, dia);

      final bool dataValida = dataNascimento.year == ano && dataNascimento.month == mes && dataNascimento.day == dia;

      setState(() {
        dataNascimentoValida = dataValida;
        if (dataValida) dataNascimentoErro = false;
      });
    } catch (_) {
      setState(() {
        dataNascimentoValida = false;
      });
    }
  } */

  void validarDataNascimentoDialogo(String data) {
    if(dataNascimentoClienteDialogoController.text.isEmpty ){
      setState(() {
        dataNascimentoValida = true;
        dataNascimentoErro = false;
      });
      return;
    }

    if(data.length == 10){
      try {
        DateFormat('dd/MM/yyyy').parseStrict(data);
        setState(() {
          dataNascimentoValida = true;
          dataNascimentoErro = false;
        });
      } catch (e) {
        setState(() {
          dataNascimentoValida = false;
          dataNascimentoErro = true;
        });
      }
    }

    if(data.length == 5){
      if(validarDiaMes(data)){
        setState(() {
          dataNascimentoValida = true;
          dataNascimentoErro = false;
        });
        dataNascimentoClienteDialogoController.text = "${data}";
      } else {
        setState(() {
          dataNascimentoValida = false;
          dataNascimentoErro = true;
        });
        dataNascimentoClienteDialogoController.text = "${data}";
      }
    }
  }

  bool validarDiaMes(String valor) {
    final partes = valor.split('/');

    if (partes.length != 2) return false;

    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);

    if (dia == null || mes == null) return false;
    if (mes < 1 || mes > 12) return false;

    final diasPorMes = <int, int>{
      1: 31,
      2: 28,
      3: 31,
      4: 30,
      5: 31,
      6: 30,
      7: 31,
      8: 31,
      9: 30,
      10: 31,
      11: 30,
      12: 31,
    };

    bool resposta = dia >= 1 && dia <= diasPorMes[mes]!;

    return resposta;
  }

  void permitirApenasInteiros(String value) {
    String novoTexto = '';
    for (var letra in value.split('')) {
      if (letra.contains(RegExp(r'[0-9]'))) {
        novoTexto += letra;
      }
    }

    // Só atualiza se houve alteração
    if (novoTexto != value) {
      quantidadeProdutoSelecionadoController.value = TextEditingValue(
        text: novoTexto,
        selection: TextSelection.collapsed(
          offset: novoTexto.length,
        ),
      );
    }
  }

  // Função para permitir apenas uma vírgula ou ponto
  void permitirUmaVirgula(String value) {
    String novoTexto = '';
    bool temSeparador = false;

    for (var letra in value.split('')) {
      if (letra == ',' || letra == '.') {
        // Mantém apenas o primeiro separador encontrado
        if (!temSeparador) {
          temSeparador = true;

          // Se quiser padronizar tudo para vírgula:
          novoTexto += ',';
        }
      } else {
        novoTexto += letra;
      }
    }

    // Só atualiza se houve alteração
    if (novoTexto != value) {
      quantidadeProdutoSelecionadoController.value = TextEditingValue(
        text: novoTexto,
        selection: TextSelection.collapsed(
          offset: novoTexto.length,
        ),
      );
    }
  }

  // Dialogo com dois botões de erro
  Future<void> shownDialogErrorTwoBottom({
    required BuildContext context,
    String title = 'Confirmação',
    String? message,
    IconData icon = Icons.home,
    String cancelText = 'Não',
    String confirmText = 'Sim',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    TextEditingController? textController,
    FocusNode? focusNode,
    ValueChanged<String>? onSubmitted, // Callback ao submeter o texto
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false, // Não pode fechar tocando fora
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

                // SizedBox(height: 5),

                // Texto centralizado
                if (message != null && message.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 15,
                        color: Theme.of(ctx).colorScheme.onSurface,
                      ),
                    ),
                  ),

                // O SEU NOVO CAMPO DE TEXTO COM OS CONTROLADORES
                if (textController !=
                    null) // Só mostra o TextField se um controller for fornecido
                  Padding(
                    padding: EdgeInsets.only(bottom: 15.0),
                    child: TextField(
                      keyboardType: TextInputType.number, // TECLADO NUMÉRICO
                      controller: textController, // Usa o controller passado
                      focusNode: focusNode, // Usa o focusNode passado
                      onSubmitted: onSubmitted, // Usa o onSubmitted passado
                      autofocus:
                          focusNode ==
                          true, // Autofoco padrão se não houver FocusNode
                      textAlign:
                          TextAlign.center, // Centraliza o texto e o ponteiro
                      decoration: InputDecoration(
                        hintText: 'Digite aqui...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),

                // Botões centralizados
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Botão Cancelar
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (onCancel != null) onCancel();
                      },
                      child: Text(
                        cancelText.toUpperCase(),
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
                    SizedBox(width: 10),
                    // Botão Confirmar
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
                        backgroundColor: Theme.of(
                          ctx,
                        ).colorScheme.primary.withOpacity(0.05),
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
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                ),
                /* Align(
                  alignment: Alignment.centerLeft,
                  child: Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.menu, color: colorScheme.onPrimary),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ), */

                // CENTRO - Nome && Hora
                Padding(
                  padding: EdgeInsets.all(5.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Nome observado em Obx
                      /* Obx(
                        () => Text(
                          variaveis.nomeEmpresa.value,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ), */
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
                  ), */
                ),
              ],
            ),
          );
        }),
      ),
      // Corpo da tela
      // AbsorbPointer envolve TODO o body: quando _telaBloqueada=true,
      // nenhum toque, botão, TextField ou FocusNode da tela responde.
      // O bloqueio é ativado ANTES do showDialog e liberado DEPOIS que
      // o diálogo fecha e todas as operações async terminam.
      body: AbsorbPointer(
        absorbing: _telaBloqueada,
        child: Stack(
          children: [
          Padding(
            padding: EdgeInsets.all(0.0),
            child: Column(
              children: [
                // Com o garçom já selecionado
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                      child: Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Ajuste para melhor distribuição
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Nome garçom
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: GestureDetector(
                                        onTap: () {
                                          // quando clicar no nome
                                          cliqueiSelecionarGarcom = true;
                                          popupSelecionarGarcom();
                                        },
                                        child: Container(
                                          color: colorScheme.tertiary,
                                          child: Padding(
                                            padding: EdgeInsets.all(15.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    nomeDoGarcomSelecionado.toUpperCase(),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: colorScheme.onPrimary,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  /* ), */
                                                ),
                                                Icon(
                                                  Icons.person,
                                                  size: 15,
                                                  color: colorScheme.onPrimary,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Ir para conta
                                  if (mostrarDentroComandaMesa)
                                    Expanded(
                                      child: GestureDetector(
                                        // quando clicar em fazer pedido
                                        onTap: () async {
                                          if (funcoesController.logicaPorComanda.value) {
                                            Get.to(
                                              () => ContaPage(),
                                              arguments: {
                                                'numeropedido': numeropedido_FK,
                                                'comanda': numeroComandaEmUso,
                                                'mesa': '0',
                                                'page': "garcom",
                                              },
                                            );
                                          } else if (funcoesController.logicaPorMesa.value) {
                                            Get.to(
                                              () => ContaPage(),
                                              arguments: {
                                                'numeropedido': numeropedido_FK,
                                                'comanda': '0',
                                                'mesa': numeroMesaEmUso,
                                                'page': "garcom",
                                              },
                                            );
                                          } else if (funcoesController.logicaPorComandaNaMesa.value) {
                                            Get.to(
                                              () => ContaPage(),
                                              arguments: {
                                                'numeropedido': numeropedido_FK,
                                                'comanda': numeroComandaEmUso,
                                                'mesa': numeroMesaEmUso,
                                                'page': "garcom",
                                              },
                                            );
                                          }
                                        },
                                        child: Container(
                                          color: colorScheme.outline,
                                          child: Padding(
                                            padding: EdgeInsets.all(15.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                // SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    "CONTA",
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color:
                                                          colorScheme.onPrimary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.search,
                                                  size: 15,
                                                  color: colorScheme.onPrimary,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Enviar comanda
                                  /* if(enviarComanda)
                                    Expanded(
                                      child: GestureDetector(
                                        // quando clicar em fazer pedido
                                        onTap: () async {
                                          numeroMesaParaCarrinho = mesaController.text;
                                          comandaCarrinhoController.salvarCarrinho(
                                            mesaController.text,      // Número da mesa
                                            comandaController.text,   // Número da comanda
                                            carrinhoController.carrinho, // Lista de produtos atual
                                          );
                                          setState(() {
                                            aparecerCardapio = true;
                                            aparecerCarrinho = false;
                                            aparecerLista = false;
                                          });
                                        },
                                        // Fazer pedido
                                        child: Container(
                                          color: colorScheme.error,
                                          child: Padding(
                                            padding: EdgeInsets.all(15.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                // SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    "Adicionar comanda",
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: colorScheme.onPrimary,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.check,
                                                  size: 15,
                                                  color: colorScheme.onPrimary,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ), */
                                  // Fazer pedido
                                  // Fazer pedido
                                  if (aparecerFazerPedido && carrinhoController.carrinho.isNotEmpty && comandaCarrinhoController.isEmpty)
                                  Expanded(
                                    child: GestureDetector(
                                      // quando clicar em fazer pedido
                                      onTap: () async {
                                        if (isProcessing) return;

                                        empurrarBotoes = true;

                                        setState(() => isProcessing = true);

                                        try {
                                          fizPedido = true;
                                          if (carrinhoController.carrinho.isNotEmpty) {
                                            if (comandaController.text == '') {
                                              comandaController.text = '0';
                                            }
                                            if (mesaController.text == '') {
                                              mesaController.text = '0';
                                            }
                                            await enviarCarrinho(
                                              numeroComanda: comandaController.text,
                                              numeroMesa: mesaController.text,
                                              numeroTradepoint: numeroDaLicencaSelecionada,
                                            );

                                            _selecionarPrimeiroGrupo();

                                            setState(() {
                                              aparecerCardapio = false;
                                              aparecerCarrinho = false;
                                              aparecerLista = false;
                                            });

                                            if (funcoesController.logicaPorComanda.value ||
                                                funcoesController.logicaPorComandaNaMesa.value) {
                                              setState(() {
                                                showKeyboardNumero = true;
                                                showKeyboardAlfa = false;
                                                _campoAtivo = 'comandaController';
                                                FocusScope.of(context).requestFocus(comandaFocus);
                                              });
                                              conectarBanco();
                                            } else if (funcoesController.logicaPorMesa.value) {
                                              setState(() {
                                                showKeyboardNumero = true;
                                                showKeyboardAlfa = false;
                                                _campoAtivo = 'mesaController';
                                                FocusScope.of(context).requestFocus(mesaFocus);
                                              });
                                              conectarBanco();
                                            } else {
                                              setState(() {
                                                showKeyboardNumero = true;
                                                showKeyboardAlfa = false;
                                                _campoAtivo = 'comandaController';
                                                FocusScope.of(context).requestFocus(comandaFocus);
                                              });
                                              conectarBanco();
                                            }
                                          }
                                        } finally {
                                          if (mounted) {
                                            setState(() {
                                              isProcessing = false;
                                              cliqueiFazerPedido = false;
                                            });
                                          }
                                        }
                                      },
                                      // Fazer pedido carrinho
                                      child: Container(
                                        color: isProcessing
                                            ? colorScheme.surfaceDim
                                            : (carrinhoController.carrinho.isNotEmpty
                                                  ? colorScheme.secondary
                                                  : colorScheme.surfaceDim),
                                        child: Padding(
                                          padding: EdgeInsets.all(15.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              // SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  isProcessing
                                                      ? "ENVIANDO..."
                                                      : "FAZER PEDIDO",
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color:
                                                        colorScheme.onPrimary,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                              isProcessing
                                                  ? SizedBox(
                                                      width: 15,
                                                      height: 15,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: colorScheme
                                                                .onPrimary,
                                                          ),
                                                    )
                                                  : Icon(
                                                      Icons.check,
                                                      size: 15,
                                                      color: colorScheme
                                                          .onPrimary,
                                                    ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                 
                                  // Fazer pedido carrinho
                                  if (comandaCarrinhoController.isNotEmpty &&
                                      aparecerFazerPedido)
                                    Expanded(
                                      child: GestureDetector(
                                        // quando clicar em fazer pedido
                                        onTap: () async {
                                          if (isProcessing) return;

                                          empurrarBotoes = true;

                                          if (!cliqueiFazerPedido) {
                                            cliqueiFazerPedido = true;
                                          } else {
                                            return;
                                          }

                                          setState(() {
                                            isProcessing = true;
                                          });

                                          try {
                                            fizPedido = true; // Define que o pedido foi iniciado
                                            if (carrinhoController.carrinho.isNotEmpty) {
                                              numeroMesaParaCarrinho = mesaController.text;

                                              comandaCarrinhoController.salvarCarrinho(
                                                mesaController.text, // Número da mesa
                                                comandaController.text, // Número da comanda
                                                carrinhoController.carrinho, // Lista de produtos atual
                                              );

                                              // Chama funcao para fazer pedido - Esta função já chama zerarAtendimento() internamente em caso de sucesso
                                              await enviarCarrinhoComandas(
                                                comandaCarrinhoController,
                                              );

                                              _selecionarPrimeiroGrupo();
                                            } else {
                                              setState(() {
                                                isProcessing = false;
                                                cliqueiFazerPedido = false;
                                                fizPedido = false;
                                              });
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Carrinho vazio, acrescente produtos ao carrinho!',
                                                  ),
                                                  backgroundColor: colorScheme.error,
                                                  behavior: SnackBarBehavior.floating,
                                                  margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                                  duration: Duration(seconds: 3),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              setState(() {
                                                isProcessing = false;
                                                cliqueiFazerPedido = false;
                                                fizPedido = false;
                                              });
                                            }
                                            print("Erro ao enviar carrinho de comandas: $e<<<<<<<<<<");
                                          }
                                        },
                                        // Fazer pedido
                                        child: Container(
                                          color: isProcessing ? colorScheme.surfaceDim : (carrinhoController.carrinho.isNotEmpty ? colorScheme.tertiary : colorScheme.surfaceDim),
                                          child: Padding(
                                            padding: EdgeInsets.all(15.0),
                                            child: Row(
                                              mainAxisAlignment:  MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                // SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    isProcessing ? "ENVIANDO..." : "FAZER PEDIDO CARRINHO",
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: colorScheme.onPrimary,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ),
                                                isProcessing ? SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary,),) : Icon(Icons.check, size: 15, color: colorScheme.onPrimary,), 
                                              ],
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
                    // LÓGICA DA COMANDA
                    if (funcoesController.logicaPorComanda.value)
                      Padding(
                        padding: EdgeInsets.all(0.0),
                        child: Container(
                          color: colorScheme.primary,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 0,
                                  right: 0,
                                  top: 5,
                                  bottom: 0,
                                ),
                                child: Text(
                                  'Insira o número da comanda:',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // botão comanda
                                  GestureDetector(
                                    onTap: () {
                                      if (carrinhoController
                                          .carrinho
                                          .isNotEmpty) {
                                        zerarAtendimento();
                                      } else {
                                        zerarAtendimento();
                                        comandaController.clear();
                                        setState(() {
                                          aparecerCardapio = false;
                                          aparecerCarrinho = false;
                                          aparecerLista = false;
                                          aparecerConfiguracaoProduto = false;
                                          aparecerBotoes = true;
                                        });
                                      }
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: 20,
                                        right: 0,
                                        top: 0,
                                        bottom: 0,
                                      ),
                                      child: Icon(
                                        Icons.description,
                                        size: 45,
                                        color: colorScheme.onTertiary,
                                      ),
                                    ),
                                  ),
                                  // Flexibe com TextField de comanda e botão de comanda
                                  Flexible(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: 20,
                                        right: comandaValida ? 20 : 90,
                                        top: 10,
                                        bottom: 10,
                                      ),
                                      child: SizedBox(
                                        height: MediaQuery.of(context).size.height * 0.06, // ajuste conforme necessário
                                        child: KeyboardActions(
                                          disableScroll: true,
                                          autoScroll: false,

                                          config: KeyboardActionsConfig(
                                            keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
                                            nextFocus: false,
                                            actions: [
                                              KeyboardActionsItem(
                                                focusNode: comandaFocus,
                                                toolbarButtons: [
                                                  (node) {
                                                    return Expanded(
                                                      child: GestureDetector(
                                                        behavior: HitTestBehavior.opaque,
                                                        onTap: () {
                                                          if (comandaController.text.isNotEmpty) {
                                                            _confirmar();
                                                          }
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
                                                        if (comandaController.text.isNotEmpty) {
                                                          _confirmar();
                                                        }

                                                        node.unfocus();
                                                      },
                                                      child: Container(
                                                        padding: EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          // vertical: 16
                                                        ),
                                                        child: Text(
                                                          "OK",
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: Theme.of(context).colorScheme.onSurface,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                ], */
                                              ),
                                            ],
                                          ),

                                          child: TextField(
                                            controller: comandaController,
                                            focusNode: comandaFocus,

                                            onTap: () {
                                              setState(() {
                                                showKeyboardNumero = true;
                                                showKeyboardAlfa = false;
                                                _campoAtivo = 'comandaController';
                                                vinculandoMesa = false;
                                              });
                                            },

                                            onChanged: (value) async {
                                              if (value.isNotEmpty && comandaValida) {
                                                zerarAtendimento();
                                                limparAmbas();
                                                limparInformacoesProduto();
                                                Future.delayed(const Duration(milliseconds: 2000), () {
                                                  chamarFoco();
                                                });
                                                empurrarBotoes = true;
                                              }
                                            },

                                            onSubmitted: (value) {
                                              if (value.isNotEmpty) {
                                                _confirmar();
                                              }
                                            },

                                            keyboardType: TextInputType.number,
                                            readOnly: false,
                                            showCursor: true,
                                            enableInteractiveSelection: false,
                                            cursorColor: colorScheme.onPrimary,

                                            textAlign: TextAlign.center,

                                            decoration: InputDecoration(
                                              // hintText: "Insira o número da comanda:",
                                              hintStyle: TextStyle(
                                                color: colorScheme.onPrimary,
                                              ),
                                              filled: true,
                                              fillColor: colorScheme.secondary.withOpacity(0.5),
                                              contentPadding: EdgeInsets.zero,

                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide(
                                                  color: colorScheme.primary,
                                                ),
                                              ),

                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide(
                                                  color: colorScheme.secondary,
                                                  width: 2,
                                                ),
                                              ),
                                            ),

                                            style: TextStyle(
                                              fontSize: 40,
                                              color: colorScheme.onPrimary,
                                              fontWeight: FontWeight.bold,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Botão de adicionar comanda
                                  if (comandaValida)
                                    GestureDetector(
                                      onTap: () {
                                        // Adicionar comanda
                                        if (carrinhoController
                                            .carrinho
                                            .isNotEmpty) {
                                          numeroMesaParaCarrinho = mesaController.text;

                                          comandaCarrinhoController.salvarCarrinho(
                                            mesaController.text, // Número da mesa
                                            comandaController.text, // Número da comanda
                                            carrinhoController.carrinho, // Lista de produtos atual
                                          );
                                          carrinhoController.carrinho.clear();
                                          setState(() {
                                            zerarAtendimento();
                                          });
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Carrinho vazio, acrescente produtos ao carrinho!',
                                              ),
                                              backgroundColor:
                                                  colorScheme.error,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              margin: EdgeInsets.fromLTRB(
                                                0,
                                                0,
                                                0,
                                                0,
                                              ),
                                              duration: Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          left: 0,
                                          right: 20,
                                          top: 0,
                                          bottom: 0,
                                        ),
                                        child: Icon(
                                          Icons.add_shopping_cart,
                                          size: 45,
                                          color: colorScheme.onTertiary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              // Botao para aparecer
                              // Botão para visualizar carrinho de comandas
                              if (comandaCarrinhoController.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    // Visualizar carrinho de comandas
                                    Get.to(
                                      () => CarrinhoComandasPage(),
                                      arguments: {
                                        'numeropedido': numeropedido_FK,
                                        'comanda': numeroComandaEmUso,
                                        'mesa': '0',
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          colorScheme.primary,
                                          colorScheme.primaryContainer,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.primary
                                              .withOpacity(0.4),
                                          blurRadius: 6,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.receipt_long_rounded,
                                          color: colorScheme.onPrimary,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            "Visualizar carrinho comandas",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: colorScheme.onPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.onPrimary,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            '${comandaCarrinhoController.listaCompleta.length}',
                                            style: TextStyle(
                                              color: colorScheme.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
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

                    // LÓGICA DA MESA
                    if (funcoesController.logicaPorMesa.value)
                      Padding(
                        padding: EdgeInsets.all(0.0),
                        child: Container(
                          color: colorScheme.primary,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 0,
                                  right: 0,
                                  top: 5,
                                  bottom: 0,
                                ),
                                child: Text(
                                  'Insira o número da mesa:',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // botão mesa
                                  GestureDetector(
                                    onTap: () async {
                                      if (carrinhoController.carrinho.isNotEmpty) {
                                        await zerarAtendimento();
                                      } else {
                                        await zerarAtendimento();
                                        mesaController.clear();
                                        setState(() {
                                          aparecerCardapio = false;
                                          aparecerCarrinho = false;
                                          aparecerLista = false;
                                          aparecerConfiguracaoProduto = false;
                                          aparecerBotoes = true;
                                        });
                                        
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (!_bloqueandoFoco && mounted && mesaFocus.canRequestFocus) {
                                            mesaFocus.requestFocus();
                                          }
                                        });

                                        _selecionarPrimeiroGrupo();
                                      }
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: 20,
                                        right: 0,
                                        top: 0,
                                        bottom: 0,
                                      ),
                                      child: Icon(
                                        Icons.table_bar,
                                        /*  size: 60, */
                                        size: 45,
                                        color: colorScheme.onTertiary,
                                      ),
                                    ),
                                  ),
                                  // Flexible com TextField de mesa
                                  Flexible(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: 20,
                                        right: 60,
                                        top: 10,
                                        bottom: 10,
                                      ),
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
                                                focusNode: mesaFocus,
                                                toolbarButtons: [
                                                  (node) {
                                                    return Expanded(
                                                      child: GestureDetector(
                                                        behavior: HitTestBehavior.opaque,
                                                        onTap: () {
                                                          if (mesaController.text.isNotEmpty) {
                                                            _confirmar();
                                                          }
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
                                                        if (mesaController.text.isNotEmpty) {
                                                          _confirmar();
                                                        }
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
                                                ], */
                                              ),
                                            ],
                                          ),
                                          child: TextField(
                                            controller: mesaController,
                                            focusNode: mesaFocus,
                                            onTap: () {
                                              setState(() {
                                                showKeyboardNumero = true;
                                                showKeyboardAlfa = false;
                                                _campoAtivo = 'mesaController';
                                              });
                                            },
                                            onChanged: (value) {
                                              if (value.isNotEmpty) {
                                                if (mesaValida) {
                                                  FocusScope.of(context).unfocus();
                                                  zerarAtendimento();
                                                  limparAmbas();
                                                  limparInformacoesProduto();
                                                  chamarFoco();
                                                  empurrarBotoes = true;
                                                }
                                              }
                                            },
                                            onSubmitted: (value) {
                                              if (value.isNotEmpty) {
                                                _confirmar();
                                              }
                                            },
                                            readOnly: false,
                                            showCursor: true,
                                            keyboardType: TextInputType.number,
                                            enableInteractiveSelection: false,
                                            cursorColor: colorScheme.onPrimary,
                                            textAlign: TextAlign.center,
                                            decoration: InputDecoration(
                                              hintStyle: TextStyle(
                                                color: colorScheme.onPrimary,
                                              ),
                                              filled: true,
                                              contentPadding: EdgeInsets.symmetric(
                                                vertical: 0,
                                              ),
                                              fillColor: colorScheme.secondary.withOpacity(0.5),
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
                                                  color: colorScheme.secondary,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontSize: 40,
                                              color: colorScheme.onPrimary,
                                              fontWeight: FontWeight.bold,
                                              height: 1.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: 0,
                                      right: 0,
                                      top: 0,
                                      bottom: 0,
                                    ),
                                    child: Icon(
                                      Icons.table_bar,
                                      size: 25,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                    // LÓGICA DA COMANDA NA MESA
                    if (funcoesController.logicaPorComandaNaMesa.value)
                      Padding(
                        padding: EdgeInsets.all(0.0),
                        child: Container(
                          color: colorScheme.primary,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 0,
                                  right: 0,
                                  top: 5,
                                  bottom: 0,
                                ),
                                child: Text(
                                  'Insira o número da comanda:',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // botão comanda
                                  GestureDetector(
                                    onTap: () async {
                                      if (carrinhoController.carrinho.isNotEmpty) {
                                        await zerarAtendimento();
                                      } else {
                                        await zerarAtendimento();
                                        comandaController.clear();
                                        setState(() {
                                          aparecerCardapio = false;
                                          aparecerCarrinho = false;
                                          aparecerLista = false;
                                          aparecerConfiguracaoProduto = false;
                                          aparecerBotoes = true;
                                          empurrarBotoes = true;
                                        });

                                        _selecionarPrimeiroGrupo();
                                        
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (!_bloqueandoFoco && mounted && comandaFocus.canRequestFocus) {
                                            comandaFocus.requestFocus();
                                          }
                                        });
                                      }
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: 20,
                                        right: 0,
                                        top: 0,
                                        bottom: 0,
                                      ),
                                      child: Icon(
                                        Icons.description,
                                        size: 45,
                                        color: colorScheme.onTertiary,
                                      ),
                                    ),
                                  ),
                                  // Flexibe com TextField de comanda e botão de comanda
                                  Flexible(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: 20,
                                        right: comandaValida ? 20 : 90,
                                        top: 10,
                                        bottom: 10,
                                      ),
                                      child: SizedBox(
                                        height: MediaQuery.of(context).size.height * 0.06,
                                        child: KeyboardActions(
                                          disableScroll: true,
                                          autoScroll: false,

                                          config: KeyboardActionsConfig(
                                            keyboardActionsPlatform:
                                                KeyboardActionsPlatform.IOS,
                                            nextFocus: false,
                                            actions: [
                                              KeyboardActionsItem(
                                                focusNode: comandaFocus,
                                                toolbarButtons: [
                                                  (node) {
                                                    return Expanded(
                                                      child: GestureDetector(
                                                        behavior: HitTestBehavior.opaque,
                                                        onTap: () {
                                                          if (comandaController.text.isNotEmpty) {
                                                            _confirmar();
                                                          }

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
                                                        if (comandaController.text.isNotEmpty) {
                                                          _confirmar();
                                                        }

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
                                                ], */
                                              ),
                                            ],
                                          ),

                                          child: TextField(
                                            controller: comandaController,
                                            focusNode: comandaFocus,

                                            onTap: () {
                                              setState(() {
                                                showKeyboardNumero = true;
                                                showKeyboardAlfa = false;
                                                _campoAtivo = 'comandaController';
                                                vinculandoMesa = false;
                                              });
                                            },

                                            /* onChanged: (value) {
                                              if (comandaValida) {
                                                zerarAtendimento();
                                                limparAmbas();
                                                limparInformacoesProduto();
                                                chamarFoco();
                                              }
                                            }, */

                                            onChanged: (value) async {
                                              if (value.isNotEmpty && comandaValida) {
                                                FocusScope.of(context).unfocus();
                                                zerarAtendimento();
                                                limparAmbas();
                                                limparInformacoesProduto();
                                                chamarFoco();
                                              }
                                            },

                                            onSubmitted: (value) {
                                              if (value.isNotEmpty) {
                                                _confirmar();
                                              }
                                            },

                                            keyboardType: TextInputType.number,
                                            readOnly: false,
                                            showCursor: true,
                                            enableInteractiveSelection: false,
                                            cursorColor: colorScheme.onPrimary,

                                            textAlign: TextAlign.center,

                                            decoration: InputDecoration(
                                              // hintText: "Insira o número da comanda:",
                                              hintStyle: TextStyle(
                                                color: colorScheme.onPrimary,
                                              ),
                                              filled: true,
                                              fillColor: colorScheme.secondary
                                                  .withOpacity(0.5),
                                              contentPadding: EdgeInsets.zero,

                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide(
                                                  color: colorScheme.primary,
                                                ),
                                              ),

                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: BorderSide(
                                                  color: colorScheme.secondary,
                                                  width: 2,
                                                ),
                                              ),
                                            ),

                                            style: TextStyle(
                                              fontSize: 40,
                                              color: colorScheme.onPrimary,
                                              fontWeight: FontWeight.bold,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Botão de adicionar comanda
                                  if (comandaValida)
                                    GestureDetector(
                                      onTap: () {
                                        // Adicionar comanda
                                        if (carrinhoController
                                            .carrinho
                                            .isNotEmpty) {
                                          numeroMesaParaCarrinho =
                                              mesaController.text;
                                          comandaCarrinhoController.salvarCarrinho(
                                            mesaController
                                                .text, // Número da mesa
                                            comandaController
                                                .text, // Número da comanda
                                            carrinhoController
                                                .carrinho, // Lista de produtos atual
                                          );
                                          carrinhoController.carrinho.clear();
                                          setState(() {
                                            zerarAtendimento();
                                          });
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Carrinho vazio, acrescente produtos ao carrinho!',
                                              ),
                                              backgroundColor:
                                                  colorScheme.error,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              margin: EdgeInsets.fromLTRB(
                                                0,
                                                0,
                                                0,
                                                0,
                                              ),
                                              duration: Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          left: 0,
                                          right: 20,
                                          top: 0,
                                          bottom: 0,
                                        ),
                                        child: Icon(
                                          Icons.add_shopping_cart,
                                          size: 45,
                                          color: colorScheme.onTertiary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              // Botão para visualizar carrinho de comandas
                              if (comandaCarrinhoController.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    // Visualizar carrinho de comandas
                                    Get.to(
                                      () => CarrinhoComandasPage(),
                                      arguments: {
                                        'numeropedido': numeropedido_FK,
                                        'comanda': numeroComandaEmUso,
                                        'mesa': '0',
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          colorScheme.primary,
                                          colorScheme.primaryContainer,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.primary
                                              .withOpacity(0.4),
                                          blurRadius: 6,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.receipt_long_rounded,
                                          color: colorScheme.onPrimary,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            "Visualizar carrinho comandas",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: colorScheme.onPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.onPrimary,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            '${comandaCarrinhoController.listaCompleta.length}',
                                            style: TextStyle(
                                              color: colorScheme.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
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
                  ],
                ),
                if (aparecerCardapio)
                  Padding(
                    /* padding: EdgeInsets.only(left: 8,right: 8, top: 4,bottom: 4,), */
                    padding: EdgeInsets.only(
                      left: 8,
                      right: 8,
                      top: 0,
                      bottom: 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            left: 0,
                            right: 0,
                            top: 0,
                            bottom: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Ícone do cardápio
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 0,
                                  right: 0,
                                  top: 14,
                                  bottom: 0,
                                ),
                                child: Column(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        aparecerConfiguracaoProduto 
                                          ? (!modoAnteriorTouch ? Icons.fingerprint : Icons.shopping_cart)
                                          : (aparecerVendaTouch ? aparecerCarrinhoForcado ? Icons.shopping_cart : Icons.fingerprint : Icons.fingerprint),
                                        // Icons.fingerprint,
                                        // size: 30,
                                        color: Theme.of(context,).colorScheme.onTertiary,
                                      ),
                                      onPressed: () async {
                                        if (aparecerConfiguracaoProduto) {
                                          if (!modoAnteriorTouch) {
                                            entrarModoTouch();
                                          } else {
                                            sairModoTouch();
                                          }
                                        } else {
                                          if(aparecerVendaTouch){
                                            aparecerCarrinho = true;
                                            aparecerLista = false;
                                            aparecerCarrinhoForcado = (!aparecerCarrinho && aparecerVendaTouch) || (aparecerCarrinho);
                                            sairModoTouch();
                                          } else {
                                            // modo touch 
                                            entrarModoTouch();
                                          }
                                        }
                                      },
                                      style: IconButton.styleFrom(
                                        backgroundColor: aparecerConfiguracaoProduto
                                            ? (!modoAnteriorTouch ? Theme.of(context,).colorScheme.shadow : Theme.of(context,).colorScheme.scrim)
                                            : (aparecerVendaTouch ? aparecerCarrinhoForcado ? Theme.of(context,).colorScheme.scrim : Theme.of(context,).colorScheme.shadow : Theme.of(context,).colorScheme.shadow),
                                        // backgroundColor: aparecerVendaTouch ? Theme.of(context,).colorScheme.scrim : Theme.of(context,).colorScheme.shadow,
                                        padding: EdgeInsets.all(10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10,),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      aparecerConfiguracaoProduto
                                          ? (!modoAnteriorTouch ? 'Touch' : 'Carrinho')
                                          : (aparecerVendaTouch ? aparecerCarrinhoForcado ? 'Carrinho' : 'Touch' : 'Touch'),
                                      // 'Touch',
                                      style: TextStyle(
                                        color: aparecerConfiguracaoProduto
                                            ? (!modoAnteriorTouch ? colorScheme.shadow : colorScheme.scrim)
                                            : (aparecerVendaTouch ? aparecerCarrinhoForcado ? colorScheme.scrim : colorScheme.shadow : colorScheme.shadow),
                                        // color: colorScheme.shadow,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(width: 5),

                              // Campo de busca expandido
                              Expanded(
                                child: TextField(
                                  onTap: () {
                                    setState(() {
                                      showKeyboardQuantidade = false;
                                      showKeyboardNumero = false;
                                      aparecerLista = false;
                                      _campoAtivo = 'cardapioController';
                                      aparecerCarrinho = true;
                                      aparecerConfiguracaoProduto = false;
                                    });
                                  },
                                  onChanged: (text) {
                                    filtrarProdutos(text);
                                  },
                                  cursorColor: Theme.of(context,).colorScheme.primary,
                                  keyboardType: TextInputType.text,
                                  textCapitalization: TextCapitalization.characters,
                                  controller: cardapioController,
                                  focusNode: cardapioFocus,
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    hintText: "Digite o produto...",
                                    hintStyle: TextStyle(
                                      color: colorScheme.onSurface,
                                    ),
                                    filled: true,
                                    fillColor: colorScheme.surface,
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

                              // Ícone da mesa
                              if (funcoesController.logicaPorComandaNaMesa.value)
                                Padding(
                                  padding: EdgeInsets.only(left: 8, right: 0, top: 16, bottom: 8,),
                                  child: GestureDetector(
                                    onTap: () {
                                      // Controladores e focus nodes do dialog
                                      final TextEditingController mesaDialogController = TextEditingController(text: mesaController.text);
                                      final FocusNode mesaDialogFocus = FocusNode();

                                      setState(() {
                                        aparecerCardapio = true;
                                        aparecerCarrinho = false;
                                        aparecerLista = false;
                                        aparecerConfiguracaoProduto = false;
                                        aparecerBotoes = true;
                                        showKeyboardAlfa = false;

                                        showKeyboardQuantidade = false;
                                        _campoAtivo = 'mesaController';
                                        mesaDialogController.text = numeroMesaEmUso;
                                      });

                                      Future.delayed(Duration(milliseconds: 300), () {
                                        if (mesaDialogFocus.canRequestFocus) {
                                          mesaDialogFocus.requestFocus();
                                        }
                                      });

                                      shownDialogTwoBottomKeyboard(
                                        context: context,
                                        title: mesaDialogController.text.isEmpty ? "Deseja vincular a uma mesa?" : "Modificar a mesa?",
                                        message: "",
                                        icon: Icons.table_bar,
                                        textController: mesaDialogController,
                                        focusNode: mesaDialogFocus,
                                        onConfirm: () async {
                                          mesaController.removeListener(_onMesaChanged);
                                          mesaController.text = mesaDialogController.text;
                                          await confirmarQueroMesa(mesaController.text, comandaController.text);
                                          mesaController.addListener(_onMesaChanged);

                                          setState(() {
                                            desejaMesa = true;
                                            aparecerCardapio = true;
                                            aparecerCarrinho = true;
                                          });
                                        },
                                        onCancel: () {
                                          // Remove listener antes de alterar o controller para não disparar _onMesaChanged
                                          mesaController.removeListener(_onMesaChanged);
                                          if (mesaDialogController.text != "") {
                                            mesaDialogController.text = numeroMesaEmUso;
                                          }
                                          // Atribuição FORA do setState e com listener já removido
                                          mesaController.text = numeroMesaEmUso;
                                          setState(() {
                                            aparecerCarrinho = true;
                                            desejaMesa = false;
                                            aparecerCardapio = true;
                                            showKeyboardQuantidade = false;
                                          });
                                          // Re-adiciona o listener após a atribuição
                                          mesaController.addListener(_onMesaChanged);
                                        },
                                      );
                                    },
                                    child: Column(
                                      children: [
                                        (mesaController.text.isEmpty || mesaController.text == "0")?
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Icon(
                                              Icons.table_bar,
                                              size: 35,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                            Positioned(
                                              // right: -2,
                                              top: -1,
                                              left: -0.5,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white,
                                                  border: BoxBorder.all(
                                                    color: Theme.of(context).colorScheme.primary,
                                                  )
                                                ),
                                                child: Icon(
                                                  Icons.add,
                                                  size: 15,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ) : 
                                        Icon(
                                          Icons.table_bar,
                                          size: 20,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                        if(mesaController.text.isNotEmpty && mesaController.text != "0")
                                        SizedBox(
                                          width: 50,
                                          child: Text(
                                            mesaController.text,
                                            softWrap: true,
                                            maxLines: 1,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                if(garcomController.cadastroCliente.value && !funcoesController.logicaPorMesa.value)
                                Padding(
                                  padding: EdgeInsets.only(left: 8, right: 8, top: 16, bottom: 8,),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          validarCampos();
                                          if(garcomController.cadastroCliente.value){
                                            popupCadastrarCliente();
                                          }
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if(nomeClienteDialogoController.text.isNotEmpty)
                                            Icon(
                                              Icons.person,
                                              size: 35,
                                              color: Theme.of(context).colorScheme.scrim,
                                            ),
                                            if(nomeClienteDialogoController.text.isEmpty)
                                            Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  Icons.person,
                                                  size: 35,
                                                  color: Theme.of(context).colorScheme.scrim,
                                                ),
                                                Positioned(
                                                  // right: -2,
                                                  top: -1,
                                                  left: -0.5,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.white,
                                                      border: BoxBorder.all(
                                                        color: Theme.of(context).colorScheme.scrim,
                                                      )
                                                    ),
                                                    child: Icon(
                                                      Icons.add,
                                                      size: 15,
                                                      color: Theme.of(context).colorScheme.scrim,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            /* Row(
                                              children: [
                                                Icon(
                                                  Icons.add,
                                                  size: 18,
                                                  color: colorScheme.scrim,
                                                ),
                                                Icon(
                                                  Icons.person,
                                                  size: 35,
                                                  color: Theme.of(context).colorScheme.scrim,
                                                ),
                                              ],
                                            ), */
                                          ],
                                        ),
                                      ),

                                      if(nomeClienteDialogoController.text.isNotEmpty)
                                      SizedBox(
                                        width: 50, // largura máxima do nome
                                        child: Text(
                                          nomeClienteDialogoController.text.toUpperCase(),
                                          softWrap: true,
                                          maxLines: 1,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.scrim,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                /* Padding(
                                  padding: EdgeInsets.only(left: 8, right: 0, top: 16, bottom: 8,),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          validarCampos();
                                          popupCadastrarCliente();
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min, // IMPEDIR QUE QUEBRE O LAYOUT
                                          children: [
                                            // if (mesaController.text.isNotEmpty)
                                            Icon(
                                              Icons.person,
                                              size: 35,
                                              color: Theme.of(context,).colorScheme.scrim,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        nomeClienteDialogoController.text,
                                        softWrap: true,
                                        maxLines: 1,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.scrim,
                                        ),
                                      ),
                                    ],
                                  ),
                                ) */
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 5),

                // Lista filtrada logo abaixo do TextField
                if (aparecerLista)
                  Flexible(
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              // borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: colorScheme.primary),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: listaProdutoFiltrada.length,
                              itemBuilder: (context, index) {
                                final produto = listaProdutoFiltrada[index];
                                return InkWell(
                                  // quando eu clilcar no produto filtrado
                                  onTap: () {
                                    filtrarProdutos(
                                      '',
                                    ); // sempre zera primeiro para aparecer tudo

                                    final meiaPorcao = produto['produto_meia_porcao'];

                                    if(produto['produto_meia_porcao'] != '0'){
                                      meiaPorcaoProduto = true;
                                    }else{
                                      meiaPorcaoProduto = false;
                                    }

                                    if (produto['produto_id'] == 'P') {
                                      if (produto['produto_un'] == "Kg") {
                                        produtoKilo = true;
                                      } else {
                                        produtoKilo = false;
                                      }

                                      idDoProdutoSelecionado = produto['produto_id'];

                                      verificacaoSeTemAdicionalObservacao(
                                        produto['produto_numero'],
                                        funcoesController.listaAdicionaisObservacoes,
                                      );

                                      // Atualiza os controladores fora do setState para evitar loops de rebuild
                                      cardapioController.text = produtoKilo
                                          ? "${produto['produto_nome']} (Kg)"
                                          : "${produto['produto_nome']} (${produto['produto_un']})";
                                      numeroProdutoSelecionadoController.text = produto['produto_numero'];

                                      // Atribuições de lógica que não dependem do setState
                                      idDoProdutoSelecionado = produto['produto_id'];
                                      _campoAtivo = 'quantidadeProdutoSelecionadoController';
                                      numeroDoProdutoSelecionado = produto['produto_numero'];
                                      valorDoProdutoSelecionado = produto['produto_valor'];
                                      quantidadeProdutoSelecionadoController.text = "";
                                      quantidadeProdutoSelecionadoController.clear();
                                      observacaoProdutoSelecionadoController.text = "";
                                      observacaoProdutoSelecionadoController.clear();

                                      final numeroProduto = produto['produto_numero'];
                                      double quantidade = 1;
                                      final nome = cardapioController.text;
                                      final observacao = observacaoProdutoSelecionadoController.text;
                                      final valor = produto['produto_valor'].toString();
                                    

                                      setState(() {
                                        aparecerBotoes = false;
                                        aparecerLista = false;
                                        aparecerCarrinho = false;
                                        aparecerConfiguracaoProduto = true;
                                        showKeyboardAlfa = false;
                                        _campoAtivo =  "quantidadeProdutoSelecionadoController";
                                        if (produtoKilo) {
                                          showKeyboardNumero = false;
                                          showKeyboardAlfa = false;
                                          showKeyboardQuantidade = true;
                                          _campoAtivo = 'quantidadeProdutoSelecionadoController';
                                          if(!temAdicionalObservacao){
                                            Future.delayed(
                                              Duration(milliseconds: 300),
                                              () {
                                                if (quantidadeProdutoSelecionadoFocus.canRequestFocus) {
                                                  quantidadeProdutoSelecionadoFocus.requestFocus();
                                                }
                                              },
                                            );
                                          }
                                        } else {
                                          showKeyboardNumero = true;
                                          showKeyboardAlfa = false;
                                          showKeyboardQuantidade = false;
                                          _campoAtivo =
                                              'quantidadeProdutoSelecionadoController';
                                          if(!temAdicionalObservacao){
                                            Future.delayed(
                                              Duration(milliseconds: 300),
                                              () {
                                                if (quantidadeProdutoSelecionadoFocus.canRequestFocus) {
                                                  quantidadeProdutoSelecionadoFocus.requestFocus();
                                                }
                                              },
                                            );
                                          }
                                        }
                                      });

                                      if(temAdicionalObservacao){
                                        mostrarAdicionaisEObservacoes(
                                          numeroProduto, 
                                          nome, 
                                          valor, 
                                          numeroProduto, 
                                          quantidade, 
                                          observacao
                                        );
                                      }
                                    } else if (produto['produto_id'] == 'PZ') {
                                      Navigator.pop(context);
                                      Get.offAllNamed('/pizza',
                                        // preventDuplicates: false,
                                        arguments: {
                                          'tamanhoSelecionado': produto['produto_nome'],
                                          'comanda': comandaController.text,
                                          'mesa': mesaController.text,
                                          'index': index,
                                          'editar': false,
                                          'numeroDoPedido': numeroDoPedido,
                                          'clienteId': carrinhoController.clienteId.value,
                                          'clienteNome': nomeClienteDialogoController.text,
                                          'clienteCpf': cpfClienteDialogoController.text,
                                          'clienteTelefone': telefoneClienteDialogoController.text,
                                          'clienteDataNascimento': dataNascimentoClienteDialogoController.text,
                                        },
                                      )?.then((_) {
                                        if (mounted) {
                                          // Garante que o modo touch é desativado e o carrinho aparece ao retornar da PizzaPage.
                                          sairModoTouch();
                                        }
                                      });
                                    } else if (produto['produto_id'] == 'E') {
                                      // Atualiza os controladores fora do setState para evitar loops de rebuild
                                      cardapioController.text = produto['produto_nome'];
                                      numeroProdutoSelecionadoController.text = produto['produto_numero'];

                                      // Atribuições de lógica que não dependem do setState
                                      idDoProdutoSelecionado = produto['produto_id'];
                                      _campoAtivo = 'quantidadeProdutoSelecionadoController';
                                      numeroDoProdutoSelecionado = produto['produto_numero'];
                                      valorDoProdutoSelecionado = produto['produto_valor'];

                                      setState(() {
                                        aparecerLista = false;
                                        aparecerCarrinho = false;
                                        aparecerConfiguracaoProduto = true;
                                        aparecerBotoes = false;
                                        if (produtoKilo) {
                                          showKeyboardNumero = false;
                                          showKeyboardAlfa = false;
                                          showKeyboardQuantidade = true;
                                          _campoAtivo =
                                              'quantidadeProdutoSelecionadoController';
                                          if(!temAdicionalObservacao){
                                            Future.delayed(
                                              Duration(milliseconds: 300),
                                              () {
                                                if (quantidadeProdutoSelecionadoFocus.canRequestFocus) {
                                                  quantidadeProdutoSelecionadoFocus.requestFocus();
                                                }
                                              },
                                            );
                                          }
                                        } else {
                                          showKeyboardNumero = true;
                                          showKeyboardAlfa = false;
                                          showKeyboardQuantidade = false;
                                          _campoAtivo =
                                              'quantidadeProdutoSelecionadoController';
                                          if(!temAdicionalObservacao){
                                            Future.delayed(
                                              Duration(milliseconds: 300),
                                              () {
                                                if (quantidadeProdutoSelecionadoFocus.canRequestFocus) {
                                                  quantidadeProdutoSelecionadoFocus.requestFocus();
                                                }
                                              },
                                            );
                                          }
                                        }
                                      });

                                      // Solicita o foco após a construção do frame para evitar engasgos
                                      if(!temAdicionalObservacao){
                                        Future.delayed(
                                          Duration(milliseconds: 300),
                                          () {
                                            if (quantidadeProdutoSelecionadoFocus.canRequestFocus) {
                                              quantidadeProdutoSelecionadoFocus.requestFocus();
                                            }
                                          },
                                        );
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: colorScheme.primary.withOpacity(0.2),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Nome produto
                                              Text(
                                                '${produto['produto_numero']} - ${produto['produto_nome']}',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: colorScheme.onSurface,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              // Unidade produto 
                                              Text(
                                                '(${produto['produto_un']})',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: colorScheme.onSurface,
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // icone pizza -> se for pizza
                                        if(produto['produto_id'] == 'PZ')
                                        Flexible(
                                          child: Padding(
                                            padding: EdgeInsets.only(right: 17),
                                            child: Icon(
                                              Icons.local_pizza,
                                              size: 23,
                                              color: colorScheme.scrim,
                                            ),
                                          ),
                                        ),
                                        
                                        // icone para meia porcao 
                                        if (produto['produto_meia_porcao'] != '0')
                                        Container(
                                          width: 28,
                                          height: 28,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: colorScheme.outline,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '½',
                                            style: TextStyle(
                                              color: colorScheme.onPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                       //  Expanded(child: Row()),
                                       // preco
                                        if (produto['produto_valor'] != '0.00')
                                          Flexible(
                                            child: Text(
                                              'R\$ ${(double.tryParse(produto['produto_valor'].toString()) ?? 0).toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: colorScheme.onSurface,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Botão para voltar ao carrinho
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              aparecerLista = false;
                              aparecerCarrinho = true;
                              aparecerCardapio = true;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 20,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  aparecerLista = false;
                                  aparecerCarrinho = true;
                                  aparecerCardapio = true;
                                });
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.arrow_back,
                                    color: colorScheme.primary,
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        'Voltar ao carrinho',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_back,
                                    color: colorScheme.onPrimary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Quando nao tem carrinho cheio
                if (carrinhoController.carrinho.isEmpty && !aparecerLista && !aparecerConfiguracaoProduto && !aparecerVendaTouch && (comandaValida || mesaValida)) ...[
                  /* Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 4),50
                        Text(
                          'Meu carrinho:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ), */
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                        'Carrinho vazio :(',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 35,
                          color: colorScheme.primary.withOpacity(0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Carrinho
                if (carrinhoController.carrinho.isNotEmpty && !aparecerLista && !aparecerConfiguracaoProduto && !aparecerVendaTouch) ...[
                  // TÍTULO DO CARRINHO
                  /* Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Meu carrinho:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ), */

                  // LISTA DO CARRINHO
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      controller: _scrollController,
                      physics: BouncingScrollPhysics(),
                      itemCount: carrinhoController.carrinho.length,
                      itemBuilder: (context, index) {
                        final produto = carrinhoController.carrinho[index];
                        final bool ehKilo;

                        // Agrupa os adicionais/sabores/bordas por nome para exibição
                        final Map<String, int> adicionaisAgrupados = {};
                        for (final adicional in produto.adicionais) {
                          final nome = adicional.nome;
                          adicionaisAgrupados[nome] = (adicionaisAgrupados[nome] ?? 0) +  adicional.quantidade.toInt();
                        }

                        // Verifica se o produto é vendido por Kg
                        if (produto.nome.contains("(Kg)")) {
                          ehKilo = true;
                        } else {
                          ehKilo = false;
                        }

                        // Usa o campo dedicado para saber se o produto suporta meia porção,
                        // sem depender exclusivamente do valor da quantidade.
                        bool produtoMeiaPorcaoCarrinho = produto.temMeiaPorcao;
                        bool formatarMeiaPorcao = produto.quantidade % 1 == 0;

                        final match = RegExp(r'\((.*?)\)').firstMatch(produto.nome);

                        final String? unidade = match?.group(1);

                        // Agrupa observações de texto repetidas
                        final Map<String, int> observacoesAgrupadas = {};
                        for (final obs in produto.observacoesTexto) {
                          final texto = obs.trim();
                          if (texto.isNotEmpty) {
                            observacoesAgrupadas[texto] =
                                (observacoesAgrupadas[texto] ?? 0) + 1;
                          }
                        }

                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 8,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // REMOVER PRODUTO
                                      GestureDetector(
                                        onTap: () {
                                          shownDialogErrorTwoBottom(
                                            context: context,
                                            title: "Deseja descartar este ${produto.nome}?",
                                            icon: Icons.delete,
                                            onConfirm: () {
                                              removerProdutoDoCarrinhoPorNumeroIndex(
                                                produto.numero,
                                                index,
                                              );
                                              setState(() {});
                                            },
                                            onCancel: () {
                                             //  Navigator.of(context).pop();
                                            },
                                          );
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 8.0),
                                          child: Icon(
                                            Icons.delete,
                                            size: 25,
                                            color: Theme.of(context).colorScheme.error,
                                          ),
                                        ),
                                      ),

                                      SizedBox(width: 8),

                                      // DADOS DO PRODUTO
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 0.0,
                                              ),
                                              child: Text(
                                                produto.nome,
                                                /* maxLines: 1, */
                                                /* overflow: TextOverflow.ellipsis, */
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                            ),

                                            if (produto.observacaoEscrita.isNotEmpty)
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Text(
                                                  produto.observacaoEscrita,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontStyle: FontStyle.italic,
                                                    color: colorScheme.outlineVariant,
                                                  ),
                                                ),
                                              ),

                                            if (produto.observacoesTexto.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 2,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: observacoesAgrupadas
                                                      .entries
                                                      .map(
                                                        (entry) => Text(
                                                          '${entry.value}x ${entry.key}',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontStyle: FontStyle
                                                                .italic,
                                                            color: colorScheme.outlineVariant,
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                              ),

                                            if (produto.adicionais.isNotEmpty)
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  top: 6,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: adicionaisAgrupados.entries.map((entry) {
                                                        return Text(
                                                          '${entry.value}x ${entry.key}',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: colorScheme.outlineVariant,
                                                          ),
                                                        );
                                                      })
                                                      .toList(),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                      // CONTROLE DE QUANTIDADE
                                      Container(
                                        width: MediaQuery.of(context).size.width * 0.35,
                                        decoration: BoxDecoration(
                                          color: ehKilo || produto.temMeiaPorcao
                                              ? Colors.transparent
                                              : colorScheme.surface,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center, // Centraliza os elementos
                                          children: [
                                            if (!(ehKilo || produto.temMeiaPorcao))
                                              IconButton(
                                                icon: Icon(
                                                  Icons.remove,
                                                  color: ehKilo ? Colors.transparent : Colors.black,
                                                ),
                                                onPressed: ehKilo ? null : () {
                                                    if (produto.quantidade > 1) {
                                                      setState(() => produto.quantidade--);
                                                    } else {
                                                      shownDialogErrorTwoBottom(
                                                        context: context,
                                                        title:
                                                            "Deseja descartar este ${produto.nome}?",
                                                        icon: Icons.delete,
                                                        onConfirm: () {
                                                          removerProdutoDoCarrinhoPorNumeroIndex(
                                                            produto.numero,
                                                            index,
                                                          );
                                                          setState(() {});
                                                        },
                                                        onCancel: () {
                                                          Navigator.of(context).pop();
                                                        },
                                                      );
                                                    }
                                                  },
                                              ),

                                            Flexible(
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                ),
                                                child: Text(
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  ehKilo
                                                      ? produto.quantidade.toStringAsFixed(3)
                                                      : produtoMeiaPorcaoCarrinho ? formatarMeiaPorcao ? produto.quantidade.toStringAsFixed(0) : produto.quantidade.toStringAsFixed(2) 
                                                      : produto.quantidade.toStringAsFixed(0),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: colorScheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            if (!(ehKilo || produto.temMeiaPorcao))
                                              IconButton(
                                                icon: Icon(
                                                  Icons.add,
                                                  color: ehKilo ? Colors.transparent : Colors.black,
                                                ),
                                                onPressed: ehKilo ? null : () {
                                                  setState(() => produto.quantidade++);
                                                },
                                              ),
                                          ],
                                        ),
                                      ),
                                      if(!(produto.temMeiaPorcao))
                                      GestureDetector(
                                        onTap: () {
                                          FocusScope.of(context).unfocus();
                                          editarProdutoDoCarrinho(produto, index, unidade);
                                          indexClicado = index;
                                          cliqueiEditarProduto = true;
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.only(left: 8.0),
                                          child: Icon(
                                            Icons.edit,
                                            size: 25,
                                            color: Theme.of(context).colorScheme.scrim,
                                          ),
                                        ),
                                      ),
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
                ],

                //Parte para configurar o produto
                if (aparecerConfiguracaoProduto)
                  Padding(
                    padding: EdgeInsets.only(left: 8, right: 8, top: 0, bottom: 0),
                    child: Container(
                      padding: EdgeInsets.only(left: 8, right: 8, top: 0, bottom: 0),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          //COLUNA ESQUERDA
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                // PRIMEIRA LINHA
                                Row(
                                  children: [
                                    // Número do produto
                                    Expanded(
                                      child: TextField(
                                        controller: numeroProdutoSelecionadoController,
                                        readOnly: true, // impede digitação pelo teclado nativo
                                        showCursor:false, // FORÇA o cursor piscando
                                        cursorColor: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        keyboardType: TextInputType
                                            .none, // garante que o teclado não abra
                                        decoration: InputDecoration(
                                          hintText: numeroDoProdutoSelecionado,
                                          filled: true,
                                          fillColor: Colors.grey.shade300,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),

                                    // Quantidade
                                    Expanded(
                                      child: 
                                        TextField(
                                          controller: quantidadeProdutoSelecionadoController,
                                          focusNode: quantidadeProdutoSelecionadoFocus,
                                          readOnly: false, 
                                          showCursor: true, 
                                          cursorColor: Theme.of(context).colorScheme.onSurface,
                                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                                          onTap: () {
                                            if (quantidadeProdutoSelecionadoFocus.canRequestFocus) {
                                              FocusScope.of(context).requestFocus(
                                                quantidadeProdutoSelecionadoFocus,
                                              );
                                            }
                                          },
                                          onChanged: (value){
                                            if(produtoKilo){
                                              permitirUmaVirgula(value);
                                            } else {
                                              permitirApenasInteiros(value);
                                            }
                                          },
                                          
                                          decoration: InputDecoration(
                                            hintText: 'Qtde.',
                                            filled: true,
                                            fillColor: Colors.grey.shade300,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(
                                                8,
                                              ),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                        ),
                                      ),

                                      if(meiaPorcaoProduto)
                                      SizedBox(width: 8,),

                                      if(meiaPorcaoProduto)
                                      SizedBox(
                                        height: 48,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            try{
                                              setState(() {
                                                quantidadeProdutoSelecionadoController.text = "0.5";
                                              });
                                              // lanca carrinho
                                              final numero = numeroProdutoSelecionadoController.text;
                                              final nome = cardapioController.text;
                                              final qtdText = quantidadeProdutoSelecionadoController.text.replaceAll(',', '.');
                                              final quantidade = produtoKilo 
                                                  ? (double.tryParse(qtdText) ?? 1.0)
                                                  : meiaPorcaoProduto ? (double.tryParse(qtdText) ?? 1.0) : (double.tryParse(qtdText)?.roundToDouble() ?? 1.0);
                                              final observacao = observacaoProdutoSelecionadoController.text;
                                              final valor = valorDoProdutoSelecionado.toString();

                                              // adiciona no carrinho
                                              if(cliqueiEditarProduto){
                                                carrinhoController.editarProdutoAoCarrinho(
                                                  indexClicado,
                                                  nome,
                                                  valor,  
                                                  numero,
                                                  quantidade,
                                                  observacao,
                                                  idDoProdutoSelecionado,
                                                  temMeiaPorcao: meiaPorcaoProduto,
                                                  adicionais: carrinhoController.carrinho[indexClicado].adicionais,
                                                  observacoesTexto: carrinhoController.carrinho[indexClicado].observacoesTexto,
                                                );
                                              } else {
                                                carrinhoController.adicionarProdutoAoCarrinho(
                                                  nome,
                                                  valor,  
                                                  numero,
                                                  quantidade,
                                                  observacao,
                                                  idDoProdutoSelecionado,
                                                  temMeiaPorcao: meiaPorcaoProduto,
                                                  adicionais: adicionaisSelecionados,
                                                );
                                              }

                                              // altera estado visual
                                              // setState(() {
                                                aparecerConfiguracaoProduto = false;
                                                aparecerBotoes = true;
                                                aparecerLista = false;
                                                temAdicionalObservacao = false;
                                                quantidadeInicial = 1;
                                                cliqueiEditarProduto = false;
                                                meiaPorcaoProduto = false;
                                              // });
                                              limparInformacoesProduto();

                                              sairModoTouch();
                                            } catch(e){
                                              print(e);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: colorScheme.scrim,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(
                                                8,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            '1/2 +',
                                            style: TextStyle(
                                              color: colorScheme.onPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    // ),
                                  ],
                                ),

                                SizedBox(height: 8),

                                // SEGUNDA LINHA
                                Row(
                                  children: [
                                    // Botão meia porcao
                                    /* if(meiaPorcaoProduto)
                                    SizedBox(
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          quantidadeProdutoSelecionadoController.text = "0.5";
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.scrim,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          '1/2',
                                          style: TextStyle(
                                            color: colorScheme.onPrimary,
                                          ),
                                        ),
                                      ),
                                    ),

                                    if(meiaPorcaoProduto)
                                    SizedBox(width: 8,), */

                                    // Botão OBS
                                    SizedBox(
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if(listaObservacaoesDoProduto.isEmpty && listaAdicionaisDoProduto.isEmpty){
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text("Este produto não tem observações ou adicionais:("),
                                                backgroundColor: Theme.of(context).colorScheme.error,
                                              ),
                                            );
                                            return;
                                          }
                                          
                                          final numero = numeroProdutoSelecionadoController.text;
                                          double quantidade = double.tryParse(quantidadeProdutoSelecionadoController.text) ?? 1.0;
                                          final nome = cardapioController.text;
                                          final observacao = observacaoProdutoSelecionadoController.text;
                                          final valor = valorDoProdutoSelecionado.toString();
                                          mostrarAdicionaisEObservacoes(
                                            numero, 
                                            nome, 
                                            valor, 
                                            numero, 
                                            quantidade, 
                                            observacao
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'OBS',
                                          style: TextStyle(
                                            color: colorScheme.onPrimary,
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(width: 8),

                                    // Observação - TextField
                                    Expanded(
                                      child: TextField(
                                        controller: observacaoProdutoSelecionadoController,
                                        focusNode: observacaoProdutoSelecionadoFocus,
                                        onTap: () {
                                          setState(() {
                                            _campoAtivo = 'observacaoProdutoSelecionadoController';
                                            showKeyboardNumero = false;
                                            showKeyboardQuantidade = false;
                                          });
                                        },
                                        cursorColor: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        keyboardType: TextInputType.text,
                                        textCapitalization: TextCapitalization.characters,
                                        decoration: InputDecoration(
                                          hintText: 'Observação',
                                          filled: true,
                                          fillColor: Colors.grey.shade300,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(width: 8),

                          // COLUNA DIREITA
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 110,
                              child: ElevatedButton(
                                onPressed: () {
                                  final numero = numeroProdutoSelecionadoController.text;
                                  final nome = cardapioController.text;
                                  final qtdText = quantidadeProdutoSelecionadoController.text.replaceAll(',', '.');
                                  final quantidade = produtoKilo 
                                      ? (double.tryParse(qtdText) ?? 1.0)
                                      : meiaPorcaoProduto ? (double.tryParse(qtdText) ?? 1.0) : (double.tryParse(qtdText)?.roundToDouble() ?? 1.0);
                                  final observacao = observacaoProdutoSelecionadoController.text;
                                  final valor = valorDoProdutoSelecionado.toString();

                                  // adiciona no carrinho
                                  if(cliqueiEditarProduto){
                                    carrinhoController.editarProdutoAoCarrinho(
                                      indexClicado,
                                      nome,
                                      valor,  
                                      numero,
                                      quantidade,
                                      observacao,
                                      idDoProdutoSelecionado,
                                      temMeiaPorcao: meiaPorcaoProduto,
                                      adicionais: carrinhoController.carrinho[indexClicado].adicionais,
                                      observacoesTexto: carrinhoController.carrinho[indexClicado].observacoesTexto,
                                    );
                                  } else {
                                    carrinhoController.adicionarProdutoAoCarrinho(
                                      nome,
                                      valor,  
                                      numero,
                                      quantidade,
                                      observacao,
                                      idDoProdutoSelecionado,
                                      temMeiaPorcao: meiaPorcaoProduto,
                                      adicionais: adicionaisSelecionados,
                                    );
                                  }

                                  // altera estado visual
                                  // setState(() {
                                    aparecerConfiguracaoProduto = false;
                                    aparecerBotoes = true;
                                    aparecerLista = false;
                                    temAdicionalObservacao = false;
                                    quantidadeInicial = 1;
                                    cliqueiEditarProduto = false;
                                    meiaPorcaoProduto = false;
                                  // });
                                  limparInformacoesProduto();

                                  sairModoTouch();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.tertiary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: colorScheme.onTertiary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if(aparecerVendaTouch && !aparecerConfiguracaoProduto && aparecerCardapio)
                Expanded(
                  child: LayoutBuilder(
                  builder: (context, boxConstraints) {
                    // Largura proporcional: grupos ~20%, produtos o restante
                    final double totalWidth = boxConstraints.maxWidth;
                    final double gruposWidth = (totalWidth * 0.20).clamp(80.0, 220.0);
                    final double totalHeight = boxConstraints.maxHeight;
                    final double gruposHeight = (totalHeight * 0.05).clamp(80.0, 220.0);
                    final double alturaItemGrupo = (boxConstraints.maxHeight * 0.08).clamp(55.0, 80.0);
                    return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // COLUNA DE GRUPOS (largura proporcional ~20%)
                      if(funcoesController.listaGrupo.length > 1)
                      SizedBox(
                        width: gruposWidth,
                        height: gruposHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.builder(
                            itemCount: funcoesController.listaGrupo.length,
                            itemBuilder: (context, index) {
                              final grupo = funcoesController.listaGrupo[index];
                              final selecionado = grupoSelecionadoNoTouch == grupo['numero'].toString();

                              return GestureDetector(
                                onTap: () {
                                  _guardarUltimoGrupoPosicao(index);
                                  setState(() {
                                    grupoSelecionadoNoTouch = grupo['numero'].toString();
                                    produtosFiltrados = produtosPorGrupo(grupoSelecionadoNoTouch);
                                  });
                                },
                                child: Container(
                                  height: alturaItemGrupo,
                                  margin: const EdgeInsets.only(
                                    top: 6,
                                    left: 6,
                                    right: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selecionado
                                        ? colorScheme.primary
                                        : colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        grupo['nome'],
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: selecionado
                                              ? colorScheme.onPrimary
                                              : colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      SizedBox(width: 8),

                      // ÁREA DE PRODUTOS (Expanded — ocupa todo o restante)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Número de colunas adaptável à largura disponível
                              const double itemMinWidth = 110.0;
                              final int cols = (constraints.maxWidth / itemMinWidth).floor().clamp(2, 8);
                              final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
                              // Fonte fixa na vertical
                              final double fontSize = isLandscape ? (constraints.maxWidth * 0.018).clamp(10.0, 20.0) : 14.0;
                              return GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1.5,
                            ),
                            itemCount: produtosFiltrados.length,
                            itemBuilder: (context, index) {
                              final produto = produtosFiltrados[index];
                              final numeroProduto = produto['produto_id'];
                              double quantidade = 1;
                              final nome = cardapioController.text;
                              final observacao = observacaoProdutoSelecionadoController.text;
                              final valor = produto['produto_valor'].toString();
                              final meiaPorcao = produto['produto_meia_porcao'];

                              return GestureDetector(
                                onTap: () {
                                  verificacaoSeTemAdicionalObservacao(
                                    produto['produto_numero'],
                                    funcoesController.listaAdicionaisObservacoes,
                                  );

                                  if(produto['produto_meia_porcao'] != '0'){
                                    meiaPorcaoProduto = true;
                                  }else{
                                    meiaPorcaoProduto = false;
                                  }

                                  // Se o produto for do tipo produto
                                  if (produto['produto_id'] == 'P') {
                                    if (produto['produto_un'] == "Kg") {
                                      produtoKilo = true;
                                    } else {
                                      produtoKilo = false;
                                    }

                                    cardapioController.text = produtoKilo
                                        ? "${produto['produto_nome']} (Kg)"
                                        : "${produto['produto_nome']} (${produto['produto_un']})";
                                    numeroProdutoSelecionadoController.text = produto['produto_numero'];
                                    numeroDoProdutoSelecionado = produto['produto_numero'];
                                    valorDoProdutoSelecionado = produto['produto_valor'];

                                    quantidadeProdutoSelecionadoController.text = "";
                                    quantidadeProdutoSelecionadoController.clear();

                                    observacaoProdutoSelecionadoController.text = "";
                                    observacaoProdutoSelecionadoController.clear();

                                    setState(() {
                                      idDoProdutoSelecionado = produto['produto_id'];
                                      aparecerBotoes = false;
                                      aparecerLista = false;
                                      aparecerCarrinho = false;
                                      aparecerConfiguracaoProduto = true;
                                      aparecerCardapio = true;

                                      if (produtoKilo) {
                                        showKeyboardAlfa = false;
                                        showKeyboardNumero = false;
                                        showKeyboardQuantidade = true;
                                        _campoAtivo = 'quantidadeProdutoSelecionadoController';
                                        if(!temAdicionalObservacao){
                                          Future.delayed(
                                            Duration(milliseconds: 300),
                                            () {
                                              if (quantidadeProdutoSelecionadoFocus.canRequestFocus) {
                                                quantidadeProdutoSelecionadoFocus.requestFocus();
                                              }
                                            },
                                          );
                                        }
                                        if(temAdicionalObservacao){
                                          mostrarAdicionaisEObservacoes(
                                            produto['produto_numero'], 
                                            produto['produto_nome'], 
                                            produto['produto_valor'].toString(), 
                                            produto['produto_numero'], 
                                            1.0, 
                                            ""
                                          );
                                        } 
                                      } else {
                                        showKeyboardAlfa = false;
                                        showKeyboardNumero = true;
                                        showKeyboardQuantidade = false;
                                        _campoAtivo = 'quantidadeProdutoSelecionadoController';
                                        if(!temAdicionalObservacao){
                                          Future.delayed(
                                            Duration(milliseconds: 300),
                                            () {
                                              if (quantidadeProdutoSelecionadoFocus.canRequestFocus) {
                                                quantidadeProdutoSelecionadoFocus.requestFocus();
                                              }
                                            },
                                          );
                                        }
                                        if(temAdicionalObservacao){
                                          mostrarAdicionaisEObservacoes(
                                            produto['produto_numero'], 
                                            produto['produto_nome'], 
                                            produto['produto_valor'].toString(), 
                                            produto['produto_numero'], 
                                            1.0, 
                                            ""
                                          );
                                        }
                                      }
                                    });
                                  }
                                  // Se o produto for do tipo pizza
                                  else if (produto['produto_id'] == 'PZ') {
                                    Get.offAllNamed('/pizza',
                                      // preventDuplicates: false,
                                      arguments: {
                                        'tamanhoSelecionado': produto['produto_nome'],
                                        'comanda': comandaController.text,
                                        'mesa': mesaController.text,
                                        'index': index,
                                        'editar': false,
                                        'numeroDoPedido': numeroDoPedido,
                                        'clienteId': carrinhoController.clienteId.value,
                                        'clienteNome': nomeClienteDialogoController.text,
                                        'clienteCpf': cpfClienteDialogoController.text,
                                        'clienteTelefone': telefoneClienteDialogoController.text,
                                        'clienteDataNascimento': dataNascimentoClienteDialogoController.text,
                                      },
                                    )?.then((_) {
                                      if (mounted) {
                                        // Garante que o modo touch é desativado e o carrinho aparece ao retornar da PizzaPage.
                                        sairModoTouch();
                                      }
                                    });
                                  } else if (produto['produto_id'] == 'E') {
                                    Future.delayed(Duration(milliseconds: 50), () {
                                      if (!mounted) return;

                                      cardapioController.text = produto['produto_nome'];
                                      numeroProdutoSelecionadoController.text = produto['produto_numero'];
                                      numeroDoProdutoSelecionado = produto['produto_numero'];
                                      valorDoProdutoSelecionado = produto['produto_valor'];

                                      setState(() {
                                        idDoProdutoSelecionado = produto['produto_id'];
                                        showKeyboardAlfa = false;
                                        showKeyboardNumero = true;
                                        _campoAtivo = 'quantidadeProdutoSelecionadoController';

                                        aparecerLista = false;
                                        aparecerCarrinho = false;
                                        aparecerBotoes = false;
                                        aparecerConfiguracaoProduto = true;
                                        aparecerCardapio = true;
                                      });

                                      if(!temAdicionalObservacao){
                                        Future.delayed(
                                          Duration(milliseconds: 300),
                                          () {
                                            if (quantidadeProdutoSelecionadoFocus.canRequestFocus) {
                                              quantidadeProdutoSelecionadoFocus.requestFocus();
                                            }
                                          },
                                        );
                                      }
                                    });
                                    if(temAdicionalObservacao){
                                      mostrarAdicionaisEObservacoes(
                                        produto['produto_numero'], 
                                        produto['produto_nome'], 
                                        produto['produto_valor'].toString(), 
                                        produto['produto_numero'], 
                                        1.0, 
                                        ""
                                      );
                                    }
                                  }
                                },
                                // Visual do card de produto
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      // Nome ocupa todo o espaço restante
                                      Expanded(
                                        child: Center(
                                          child: AutoSizeText(
                                            produto['produto_nome'],
                                            textAlign: TextAlign.center,
                                            maxLines: 3,
                                            minFontSize: 8,
                                            maxFontSize: isLandscape ? 12 : 14,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: isLandscape ? 12 : 14,
                                              fontWeight: FontWeight.w500,
                                            ), 
                                          ),
                                        ),
                                      ),
                                      /* Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 0),
                                          child: Center(
                                            child: Text(
                                              produto['produto_nome'],
                                              textAlign: TextAlign.center,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: fontSize,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ), */

                                      // Preço
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Container(
                                          margin: EdgeInsets.only(right: 4, bottom: 4),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: produto['produto_valor'] != "0.00"
                                                ? colorScheme.primary.withOpacity(0.8)
                                                : colorScheme.scrim,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: produto['produto_valor'] != "0.00"
                                        ? Text(
                                            "R\$ ${(double.tryParse(produto['produto_valor'].toString()) ?? 0).toStringAsFixed(2)}",
                                            style: TextStyle(
                                              color: colorScheme.onPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: isLandscape ? 10 : 15,
                                            ),
                                          )
                                        : Icon(
                                            Icons.local_pizza,
                                            size: isLandscape ? 12 : 20,
                                            color: colorScheme.onPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                              );
                            },
                          );
                          }
                        ),
                      ),
                      ),
                    ],
                  ),
                  );
                  }
                  ),
                ),
                /* if(aparecerVendaTouch && !aparecerConfiguracaoProduto && aparecerCardapio)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.12,
                ), */
              ],
            ),
          ),
          /* if(aparecerVendaTouch)
          Positioned(
            bottom: 110,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                abrirCarrinhoNaVendaTouch(carrinhoController.carrinho);
              },
              child: Icon(Icons.shopping_cart),
            ),
          ), */

          /* if (carrinhoController.carrinho.isEmpty && !aparecerLista && !aparecerConfiguracaoProduto && !aparecerVendaTouch && (comandaValida || mesaValida))
          Positioned(
            left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height * 0.05,
              bottom: 0,
              child: Center(
                child: Text(
                'Carrinho vazio :(',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: colorScheme.primary.withOpacity(0.5),
                ),
              ),
            ),
          ), */

          /* // Botoes de baixo
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: footerButtonsController.aparecerNote.value
                    ? EdgeInsets.only(top: 5.0, bottom: 15.0, left: 10.0, right: 10.0,)
                    : EdgeInsets.only(top: 5.0, bottom: 15.0, left: 5.0, right: 5.0),
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: Row(
                    children: [
                      // Botão Check In
                      if (footerButtonsController.aparecerCheckIn.value)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkWell(
                              onTap: () {
                                if (carrinhoController.carrinho.isNotEmpty) {
                                  shownDialogErrorTwoBottom(
                                    context: context,
                                    title: "Carrinho cheio!",
                                    message: "Deseja descartar este pedido?",
                                    icon: Icons.shopping_cart,
                                    onConfirm: () async {
                                      _executarLimpezaGeral();
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          transitionDuration: Duration.zero, 
                                          reverseTransitionDuration: Duration.zero, 
                                          pageBuilder: (context, animation, secondaryAnimation) => CheckinPage(),
                                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                  return child; 
                                              },
                                        ),
                                      );
                                    },
                                    onCancel: () async {
                                      _isZerando = false;
                                      comandaController.removeListener(_onComandaChanged);
                                      mesaController.removeListener(_onMesaChanged);
                              
                                      comandaController.text = numeroComandaEmUso;
                                      mesaController.text = numeroMesaEmUso;
                              
                                      comandaController.addListener(_onComandaChanged);
                                      mesaController.addListener(_onMesaChanged);
                              
                                      setState(() {
                                        aparecerCardapio = true;
                                        aparecerCarrinho = true;
                                        aparecerLista = false;
                                        aparecerConfiguracaoProduto = false;
                                      });
                                    },
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      transitionDuration: Duration.zero, 
                                      reverseTransitionDuration: Duration.zero, 
                                      pageBuilder: (context, animation, secondaryAnimation) => CheckinPage(),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return child; // retorna direto, sem animação
                                      },
                                    ),
                                  );
                                  zerarAtendimento();
                                  _executarLimpezaGeral();
                                }
                              },
                              borderRadius: BorderRadius.circular(3),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: 56,
                                  maxHeight: math.max(
                                    56.0,
                                    MediaQuery.of(context).size.height * 0.10,
                                  ),
                                ),
                                child: Container(
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
                                        size: 26,
                                        color: colorScheme.onPrimary,
                                      ),
                                      const SizedBox(height: 4),
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
                        ),
                              
                      // if (aparecerCheckOut) SizedBox(width: 8),
                              
                      // Botão Check Out
                      if (footerButtonsController.aparecerCheckOut.value)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkWell(
                              onTap: () {
                                if (carrinhoController.carrinho.isNotEmpty) {
                                  shownDialogErrorTwoBottom(
                                    context: context,
                                    title: "Carrinho cheio!",
                                    message: "Deseja descartar este pedido?",
                                    icon: Icons.shopping_cart,
                                    onConfirm: () async {
                                      _executarLimpezaGeral();
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
                                    onCancel: () async {
                                      _isZerando = false;
                                      comandaController.removeListener(_onComandaChanged);
                                      mesaController.removeListener(_onMesaChanged);
                              
                                      comandaController.text = numeroComandaEmUso;
                                      mesaController.text = numeroMesaEmUso;
                              
                                      comandaController.addListener(_onComandaChanged);
                                      mesaController.addListener(_onMesaChanged);
                              
                                      setState(() {
                                        aparecerCardapio = true;
                                        aparecerCarrinho = true;
                                        aparecerLista = false;
                                        aparecerConfiguracaoProduto = false;
                                      });
                                    },
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      transitionDuration: Duration.zero,
                                      reverseTransitionDuration: Duration.zero,
                                      pageBuilder: (context, animation, secondaryAnimation) => CheckoutPage(),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return child; // retorna direto, sem animação
                                      },
                                    ),
                                  );
                                  zerarAtendimento();
                                  _executarLimpezaGeral();
                                }
                              },
                              borderRadius: BorderRadius.circular(3),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: 56,
                                  maxHeight: math.max(
                                    56.0,
                                    MediaQuery.of(context).size.height * 0.10,
                                  ),
                                ),
                                child: Container(
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
                                        size: 26,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 4),
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
                        ),
                              
                      // if (aparecerNote) SizedBox(width: 8),
                      if (footerButtonsController.aparecerNote.value)
                        // Botão Notes
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkWell(
                              onTap: () {
                                if (carrinhoController.carrinho.isNotEmpty) {
                                  shownDialogErrorTwoBottom(
                                    context: context,
                                    title: "Carrinho cheio!",
                                    message: "Deseja descartar este pedido?",
                                    icon: Icons.shopping_cart,
                                    onConfirm: () async {
                                      _executarLimpezaGeral();
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          transitionDuration:Duration.zero, // sem duração
                                          reverseTransitionDuration: Duration.zero, // sem duração ao voltar
                                          pageBuilder: (context, animation, secondaryAnimation) => NotesPage(),
                                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                            return child; // retorna direto, sem animação
                                          },
                                        ),
                                      );
                                    },
                                    onCancel: () async {
                                      _isZerando = false;
                                      comandaController.removeListener(_onComandaChanged);
                                      mesaController.removeListener(_onMesaChanged);
                              
                                      comandaController.text = numeroComandaEmUso;
                                      mesaController.text = numeroMesaEmUso;
                              
                                      comandaController.addListener(_onComandaChanged);
                                      mesaController.addListener(_onMesaChanged);
                              
                                      setState(() {
                                        aparecerCardapio = true;
                                        aparecerCarrinho = true;
                                        aparecerLista = false;
                                        aparecerConfiguracaoProduto = false;
                                      });
                                    },
                                  );
                                } else {
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
                                  zerarAtendimento();
                                  _executarLimpezaGeral();
                                }
                              },
                              borderRadius: BorderRadius.circular(3),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: 56,
                                  maxHeight: math.max(
                                    56.0,
                                    MediaQuery.of(context).size.height * 0.10,
                                  ),
                                ),
                                child: Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.shadow,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.note_add_sharp,
                                        size: 26,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 4),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Notes',
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
                        ),
                      // if (aparecerRecepcao) SizedBox(width: 8),
                      if (footerButtonsController.aparecerRecepcao.value)
                        // Botão Recepção
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkWell(
                              onTap: () {
                                if (carrinhoController.carrinho.isNotEmpty) {
                                  shownDialogErrorTwoBottom(
                                    context: context,
                                    title: "Carrinho cheio!",
                                    message: "Deseja descartar este pedido?",
                                    icon: Icons.shopping_cart,
                                    onConfirm: () async {
                                      _executarLimpezaGeral();
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          transitionDuration: Duration.zero, // sem duração
                                          reverseTransitionDuration: Duration.zero, // sem duração ao voltar
                                          pageBuilder: (context, animation, secondaryAnimation) => RecepcaoPage(),
                                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                            return child; // retorna direto, sem animação
                                          },
                                        ),
                                      );
                                    },
                                    onCancel: () async {
                                      _isZerando = false;
                                      comandaController.removeListener(_onComandaChanged);
                                      mesaController.removeListener(_onMesaChanged);
                              
                                      comandaController.text = numeroComandaEmUso;
                                      mesaController.text = numeroMesaEmUso;
                              
                                      comandaController.addListener(_onComandaChanged);
                                      mesaController.addListener(_onMesaChanged);
                              
                                      setState(() {
                                        aparecerCardapio = true;
                                        aparecerCarrinho = true;
                                        aparecerLista = false;
                                        aparecerConfiguracaoProduto = false;
                                      });
                                    },
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      transitionDuration: Duration.zero, // sem duração
                                      reverseTransitionDuration: Duration.zero, // sem duração ao voltar
                                      pageBuilder: (context, animation, secondaryAnimation) => RecepcaoPage(),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return child; // retorna direto, sem animação
                                      },
                                    ),
                                  );
                                  zerarAtendimento();
                                  _executarLimpezaGeral();
                                }
                              },
                              borderRadius: BorderRadius.circular(3),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: 56,
                                  maxHeight: math.max(
                                    56.0,
                                    MediaQuery.of(context).size.height * 0.10,
                                  ),
                                ),
                                child: Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 26,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 4),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Recepçao',
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
                        ),
                      // if (!naoAparecerMapa) SizedBox(width: 8), 
                      if (footerButtonsController.aparecerMapa.value)
                        // Botão Mapa de Mesas
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkWell(
                              onTap: () {
                                if (carrinhoController.carrinho.isNotEmpty) {
                                  shownDialogErrorTwoBottom(
                                    context: context,
                                    title: "Carrinho cheio!",
                                    message: "Deseja descartar este pedido?",
                                    icon: Icons.shopping_cart,
                                    onConfirm: () async {
                                      _executarLimpezaGeral();
                                      Get.toNamed('/mapa');
                                    },
                                    onCancel: () async {
                                      _isZerando = false;
                                      comandaController.removeListener(_onComandaChanged);
                                      mesaController.removeListener(_onMesaChanged);
                              
                                      comandaController.text = numeroComandaEmUso;
                                      mesaController.text = numeroMesaEmUso;
                              
                                      comandaController.addListener(_onComandaChanged);
                                      mesaController.addListener(_onMesaChanged);
                              
                                      setState(() {
                                        aparecerCardapio = true;
                                        aparecerCarrinho = true;
                                        aparecerLista = false;
                                        aparecerConfiguracaoProduto = false;
                                      });
                                    },
                                  );
                                } else {
                                  zerarAtendimento();
                                  _executarLimpezaGeral();
                                  Get.toNamed('/mapa');
                                }
                              },
                              borderRadius: BorderRadius.circular(3),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: 56,
                                  maxHeight: math.max(
                                    56.0,
                                    MediaQuery.of(context).size.height * 0.10,
                                  ),
                                ),
                                child: Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.scrim,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.map,
                                        size: 26,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 4),
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
                        ),
                      // if (aparecerGarcom) SizedBox(width: 8),
                      if (footerButtonsController.aparecerGarcom.value)
                        // Botão Garçom
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkWell(
                              onTap: () {},
                              borderRadius: BorderRadius.circular(3),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: 56,
                                  maxHeight: math.max(
                                    56.0,
                                    MediaQuery.of(context).size.height * 0.10,
                                  ),
                                ),
                                child: Container(
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
                                        size: 26,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 4),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Atendente',
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
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ), */
        ],
        ), // fecha Stack
      ), // fecha AbsorbPointer
    );
  }
}
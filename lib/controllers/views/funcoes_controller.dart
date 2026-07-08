import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:un_recepcao/data/data_class.dart';
// importar final FuncoesController funcoesController = Get.put(FuncoesController());
class FuncoesController extends GetxController {
  // --- Controle de Atendimento (Fazer Pedido) ---
  RxBool isEnviandoPedido = false.obs;
  String atendimentoAtual = "";
  String nomeTraidpoint = "";

  // String versaoDoApp = "1.9.18";
  String versaoDoApp = "1.9.19";

  // Controlar o aparecimento do botão pagar
  RxBool aparecerBotaoPagar = false.obs;

  // data atual
  RxString dataAtual = "".obs;

  dia() async {
    DateTime hoje = DateTime.now();
    String dia = "${hoje.day}/${hoje.month}/${hoje.year}";

    dataAtual.value = dia;
  }

  // Funcao que controla o aparecimento do botão pagar
  controlarAparecimentoBotaoPagar(String pagamento) {
    int pag = int.parse(pagamento);
    if (pag == 1) {
      aparecerBotaoPagar.value = true;
    } else {
      aparecerBotaoPagar.value = false;
    }
  }

  // Numero licença
  Future<String> _loadNumeroLicenca() async {
    final prefs = await SharedPreferences.getInstance();
    final licencaSalvoNumero = prefs.getString('licencaNumero');
    if (licencaSalvoNumero != null) {
      return licencaSalvoNumero;
    } else {
      return "";
    }
  }

  // Nome licenca
  Future<void> _loadNomeLicenca() async {
    final prefs = await SharedPreferences.getInstance();
    final licencaSalvo = prefs.getString('licenca');
    if (licencaSalvo != null) {
      nomeTraidpoint = licencaSalvo;
    }
  }

  iniciarAtendimento() async {
    atendimentoAtual = await _loadNumeroLicenca();
    isEnviandoPedido.value = true;
  }

  void finalizarAtendimento() {
    isEnviandoPedido.value = false;
    atendimentoAtual = "";
  }

  Future<void> salvarModoSalvo(Set<String> modosSalvos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('modo_padrao', jsonEncode(modosSalvos.toList()));
    } catch (e, st) {
    }
  }

  Future<void> zerarAtendimentoGlobal() async {
    if (atendimentoAtual.isEmpty) return;

    String sql = """
      UPDATE cartoes 
      SET atendimento = '0'
      WHERE atendimento = '$atendimentoAtual';

      UPDATE mesas 
      SET atendimento = '0'
      WHERE atendimento = '$atendimentoAtual';
    """;

    try {
      // Como o UDP não bloqueia queries e já cuida do status, chamamos ipd direto.
      await Connection().ipd(sql);
      print("Atendimento zerado com sucesso para: $atendimentoAtual");
    } catch (e) {
      print("Erro ao zerar atendimento global no banco: $e");
    } finally {
      finalizarAtendimento();
    }
  } 

    // adicionaisObservacoesProdutos
    RxList<dynamic> listaAdicionaisObservacoes = <dynamic>[].obs;

    // buscarTipoPedido
    RxString tipoDoPedido = ''.obs;
    RxBool logicaPorMesa = false.obs;
    RxBool logicaPorComanda = false.obs;
    RxBool logicaPorComandaNaMesa = false.obs;

    // pegarmeuMobileId
    RxString meuMobileId = ''.obs;

    // informacoesListaGarcom
    RxList<dynamic> listaGarcom = <dynamic>[].obs;

    // buscarGrupos
    RxString numeroDoGrupo = ''.obs;
    RxString nomeDoGrupo = ''.obs;
    RxString idDoGrupo = ''.obs;
    RxList<dynamic> listaGrupo = <dynamic>[].obs;

    // buscarProdutos
    RxString numeroDoProduto = ''.obs;
    RxString nomeDoProduto = ''.obs;
    RxString idDoProduto = ''.obs;
    RxList<dynamic> listaProduto = <dynamic>[].obs;
    RxList<dynamic> listaProdutoFiltrada = <dynamic>[].obs;

    // buscarTamanhosPizza
    RxList<dynamic> listaTamanhosPizza = <dynamic>[].obs;

    // buscarSaboresBordasPizza
    RxList<dynamic> listaSaboresBordasPizza = <dynamic>[].obs;

    // buscarGruposPizza
    RxList<dynamic> listaGruposPizza = <dynamic>[].obs;

    // listaFormasDePagamento
    RxList<dynamic> listaFormasDePagamento = <dynamic>[].obs;

    // buscarCaixas
    RxString numeroTurnoCaixa = "".obs;
    RxString statusCaixa = "".obs;
    RxString numeroCaixa = "".obs;
    RxString nomeCaixa = "".obs;
    RxList<dynamic> listaCaixas = <dynamic>[].obs;

    RxList<dynamic> listaFavoritos = <dynamic>[].obs;
    RxList<dynamic> listaAdicionaisObservacoesFavoritos = <dynamic>[].obs;

    @override
    void onInit() {
      super.onInit();
      carregarTudo();
    }

    Future<void> carregarTudo() async {
      await buscarTipoPedido();
      await adicionaisObservacoesProdutos();
      await pegarmeuMobileId();
      await informacoesListaGarcom();
      await buscarGrupos();
      await buscarProdutos();

      await buscarTamanhosPizza();
      await buscarSaboresBordasPizza();
      await buscarGruposPizza();

      await buscarPagamento();
      await buscarCaixas();
      await iniciarAtendimento();
      await _loadNomeLicenca();
      await _loadNumeroLicenca();
      await dia();      
    }

    // Funcao para zerar atendimento
    Future<void> zerarAtendimento() async {

      final prefs = await SharedPreferences.getInstance();
      final licencaSalvoNumero = prefs.getString('licencaNumero');
      String numeroDaLicencaSelecionada = "";
      if (licencaSalvoNumero != null) {
        numeroDaLicencaSelecionada = licencaSalvoNumero;
      }

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
    }

    // Função que retorna adicionais e observações dos produtos
    Future<void> adicionaisObservacoesProdutos() async {
      try {
        String dadosJson = await Connection().select(
          "SELECT numeroproduto_FK AS numeroproduto, if(numeroobservacao_FK = '0','0',(SELECT observacao FROM observacoes WHERE numero=numeroobservacao_FK)) AS nomeobservacao, numeroprodutoadicional_FK AS numeroadicional, if(numeroprodutoadicional_FK = '0', '', (SELECT nome FROM produtos WHERE numero=numeroprodutoadicional_FK)) AS nomeadicional, numeroobservacao_FK as numeroobservacao FROM observacoesadicionaisprodutos ORDER BY numeroproduto_FK;",
        );

        List<dynamic> lista = jsonDecode(dadosJson);
        // print(lista);
      if (lista.isNotEmpty) {
        listaAdicionaisObservacoes.assignAll(lista);
      } else {
        listaAdicionaisObservacoes.assignAll([]);
      }
    } catch (e) {
      print("Erro ao carregar adicionais: $e");
      listaAdicionaisObservacoes.assignAll([]);
    }
  }

  // Função para descobrir tipo do pedido
  Future<void> buscarTipoPedido() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT resultado FROM configuracoes WHERE numero='23';",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        String valor = lista[0]['resultado'].toString();

        tipoDoPedido.value = valor;
        logicaPorMesa.value = false;
        logicaPorComanda.value = false;
        logicaPorComandaNaMesa.value = false;
        
        if (tipoDoPedido == "100") {
          logicaPorMesa.value = true;
          // Set<String> modosSelecionados = {'Mesa'};
          // salvarModoSalvo(modosSelecionados);
        } else if (tipoDoPedido == "010") {
          logicaPorComanda.value = true;
          // Set<String> modosSelecionados = {'Comanda'};
          // salvarModoSalvo(modosSelecionados);
        } else if (tipoDoPedido == "011") {
          logicaPorComandaNaMesa.value = true;
          // Set<String> modosSelecionados = {'Mesa', 'Comanda'};
          // salvarModoSalvo(modosSelecionados);
        }
        print("Tipo do pedido: $tipoDoPedido");
      } else {
        // se a lista vier vazia
        tipoDoPedido.value = "Não foi possível buscar tipo do pedido";
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
      tipoDoPedido.value = "0";
    }
  }

  // Função para pegar o id do aparelho
  Future<String> pegarmeuMobileId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      meuMobileId.value = androidInfo.id;
      return androidInfo.id; // ID do Android
    }

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      meuMobileId.value = iosInfo.identifierForVendor ?? 'unknown_ios';
      return iosInfo.identifierForVendor ?? 'unknown_ios';
    }

    if (Platform.isMacOS) {
      final macInfo = await deviceInfo.macOsInfo;
      meuMobileId.value = macInfo.computerName;
      return macInfo.computerName;
    }

    if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      meuMobileId.value = windowsInfo.deviceId;
      return windowsInfo.deviceId;
    }

    return 'unknown_device';
  }

  // Função que retorna informações garçom
  Future<void> informacoesListaGarcom() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, nome, senhanova, funcao, pgtomobile FROM usuarios WHERE ativo = '1' AND numero != '1' AND mobile = '1' ORDER BY nome;",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        String valor = lista[0]['numero'].toString();
        String valor2 = lista[0]['nome'];

        listaGarcom.assignAll(lista);
      } else {
        listaGarcom.assignAll([]);
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
      listaGarcom.assignAll([]);
    }
  }

  // Função que busca grupos
  Future<void> buscarGrupos() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, nome, ID FROM grupos WHERE mobile='1' AND id='P' ORDER BY nome;",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        String valor = lista[0]['numero'].toString();
        String valor2 = lista[0]['nome'];
        String valor3 = lista[0]['ID'].toString();

        numeroDoGrupo.value = valor;
        nomeDoGrupo.value = valor2;
        idDoGrupo.value = valor3;
        listaGrupo.assignAll(lista);
      } else {
        numeroDoGrupo.value = "";
        nomeDoGrupo.value = "";
        idDoGrupo.value = "";
        listaGrupo.assignAll([]);
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
      numeroDoGrupo.value = "";
      nomeDoGrupo.value = "";
      idDoGrupo.value = "";
      listaGrupo.assignAll([]);
    }
  }

  // Função que busca produtos
  Future<void> buscarProdutos() async {
    try {
      String dadosJson = await Connection().select("""
        SELECT 
          g.numero AS grupo_numero,
          g.nome   AS grupo_nome,
          pr.numero AS produto_numero,
          pr.nome   AS produto_nome,
          pr.valor  AS produto_valor,
          pr.id AS produto_id,
          un.simbolo AS produto_un
        FROM produtos AS pr
        JOIN grupos AS g 
          ON g.numero = pr.numerogrupocardapio_FK
        JOIN unidades AS un
          ON un.numero = pr.numerounidade_FK
        
        WHERE g.mobile = '1'
          AND pr.ativo = '1'
        ORDER BY pr.nome ASC;
        """);
      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        String valor = lista[0]['grupo_numero'].toString();
        String valor2 = lista[0]['produto_numero'].toString();
        String valor3 = lista[0]['produto_nome'].toString();
        String valor4 = lista[0]['produto_valor'].toString();


          numeroDoProduto.value = valor;
          nomeDoProduto.value = valor2;
          idDoProduto.value = valor3;
          listaProduto.assignAll(lista);
          listaProdutoFiltrada.assignAll(lista);
      } else {
          numeroDoProduto.value = "";
          nomeDoProduto.value = "";
          idDoProduto.value = "";
          listaProduto.assignAll([]);
          listaProdutoFiltrada.assignAll([]);
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
        numeroDoProduto.value = "";
        nomeDoProduto.value = "";
        idDoProduto.value = "";
        listaProduto.assignAll([]);
        listaProdutoFiltrada.assignAll([]);
    }
  }

  // Selectama dos tamanhos de pizza
  Future<void> buscarTamanhosPizza() async {
    try {
      /* String dadosJson = await Connection().select(
        "SELECT numeroproduto_FK, nome, diversidadesabores FROM tamanhopizza WHERE ativo = '1' ORDER BY nome;",
      );   */
      String dadosJson = await Connection().select(
         """
        SELECT 
          g.numero AS grupo_numero,
          g.nome   AS grupo_nome,
          pr.numero AS produto_numero,
          pr.nome   AS produto_nome,
          pr.valor  AS produto_valor,
          pr.id AS produto_id
        FROM produtos AS pr
        JOIN grupos AS g 
          ON g.numero = pr.numerogrupocardapio_FK
        WHERE g.mobile = '1' AND pr.id = 'PZ' ORDER BY pr.nome ASC;
        """,
      );  

      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
          listaTamanhosPizza.assignAll(lista);
      } else {

          listaTamanhosPizza.assignAll([]);
      }
    } catch (e) {
      print("Erro ao carregar buscarTamanhosPizza: $e");
      listaTamanhosPizza.assignAll([]);     
    }
  } 

  // Select dos sabores e bordas de pizza 
  Future<void> buscarSaboresBordasPizza() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, nome, numerovenda, id, numerogrupo_FK FROM sabores WHERE ativo='1' ORDER BY nome;",
      );  

      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        listaSaboresBordasPizza.assignAll(lista);
      } else {
        listaSaboresBordasPizza.assignAll([]);
      }
    } catch (e) {
      print("Erro ao carregar buscarSaboresBordasPizza: $e");
      listaSaboresBordasPizza.assignAll([]);     
    }
  }

  // Select para buscar grupos da pizza 
  Future<void> buscarGruposPizza() async {
    try {
     /*   String dadosJson = await Connection().select(
        "SELECT numeroproduto_FK, nome, diversidadesabores FROM tamanhopizza WHERE ativo = '1' ORDER BY nome;",
      );   */
      String dadosJson = await Connection().select(
        "SELECT numero, nome FROM grupos WHERE id = 'PZ';",
      );  

      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        listaGruposPizza.assignAll(lista);
      } else {
        listaGruposPizza.assignAll([]);
      }
    } catch (e) {
      print("Erro ao carregar buscarSaboresBordasPizza: $e");
      listaGruposPizza.assignAll([]);   
    }
  }

  Future<void> buscarPagamento() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, moeda, tipo FROM formaspagamento WHERE operante='1' AND mobile='1' AND (tipo!='5' AND tipo!='99')",
      );

      // Decode fora do setState
      final List<dynamic> lista = jsonDecode(dadosJson);
      // print(">>>Formas de pagamento: $lista<<<");

      if (lista.isNotEmpty) {
        listaFormasDePagamento.assignAll(lista);
      } else {
        listaFormasDePagamento.assignAll([]);
      }
    } catch (e) {
      listaFormasDePagamento.assignAll([]);
    }
  }

  // Buscar se comanda esta em conta
  Future<void> buscarCaixas() async {
    try {
      /* String dadosJson = await Connection().select("""
          SELECT MAX(mc.numero), mc.status, mc.numerocaixa_FK, c.nome FROM movimentacaocaixas AS mc, caixas AS c WHERE mc.numerocaixa_FK=c.numero AND mc.STATUS='1' GROUP BY mc.numerocaixa_FK ORDER BY mc.numero DESC;
        """); */

      String dadosJson = await Connection().select("""
        SELECT MAX(mc.numero), mc.status, mc.numerocaixa_FK, c.nome FROM movimentacaocaixas AS mc, caixas AS c WHERE mc.numerocaixa_FK=c.numero AND mc.STATUS='1' AND c.mobile='1' GROUP BY mc.numerocaixa_FK ORDER BY mc.numerocaixa_FK;
      """);

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        listaCaixas.assignAll(lista);
        if (listaCaixas.length == 1) {
          numeroTurnoCaixa.value = listaCaixas[0]['MAX(mc.numero)'].toString();
          statusCaixa.value = listaCaixas[0]['status'].toString();
          numeroCaixa.value = listaCaixas[0]['numerocaixa_FK'].toString();
          nomeCaixa.value = listaCaixas[0]['nome'].toString();
        }
        print(
          ">>>Lista de caixas<<<$lista",
        ); // flutter: >>>Lista de caixas<<<[{MAX(mc.numero): 254, status: 1, numerocaixa_FK: 1, nome: SALAO}]
      } else {
        listaCaixas.assignAll([]);
      }
    } catch (e) {
      print(">>>Erro ao buscar caixas: $e<<<");
      listaCaixas.assignAll([]);
    }
  }
}

/* import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:un_recepcao/data/data_class.dart';
// importar final FuncoesController funcoesController = Get.put(FuncoesController());
class FuncoesController extends GetxController {
  // --- Controle de Atendimento (Fazer Pedido) ---
  RxBool isEnviandoPedido = false.obs;
  String atendimentoAtual = "";
  String nomeTraidpoint = "";

  // String versaoDoApp = "1.9.18";
  String versaoDoApp = "1.9.18";

  // Controlar o aparecimento do botão pagar
  RxBool aparecerBotaoPagar = false.obs;

  // data atual
  RxString dataAtual = "".obs;

   dia() async {
    DateTime hoje = DateTime.now();
    String dia = "${hoje.day}/${hoje.month}/${hoje.year}";

    dataAtual.value = dia;
  }

  // Funcao que controla o aparecimento do botão pagar
  controlarAparecimentoBotaoPagar(String pagamento) {
    int pag = int.parse(pagamento);
    if (pag == 1) {
      aparecerBotaoPagar.value = true;
    } else {
      aparecerBotaoPagar.value = false;
    }
  }

  // Numero licença
  Future<String> _loadNumeroLicenca() async {
    final prefs = await SharedPreferences.getInstance();
    final licencaSalvoNumero = prefs.getString('licencaNumero');
    if (licencaSalvoNumero != null) {
      return licencaSalvoNumero;
    } else {
      return "";
    }
  }

  // Nome licenca
  Future<void> _loadNomeLicenca() async {
    final prefs = await SharedPreferences.getInstance();
    final licencaSalvo = prefs.getString('licenca');
    if (licencaSalvo != null) {
      nomeTraidpoint = licencaSalvo;
    }
  }

  iniciarAtendimento() async {
    atendimentoAtual = await _loadNumeroLicenca();
    isEnviandoPedido.value = true;
  }

  void finalizarAtendimento() {
    isEnviandoPedido.value = false;
    atendimentoAtual = "";
  }

  Future<void> salvarModoSalvo(Set<String> modosSalvos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('modo_padrao', jsonEncode(modosSalvos.toList()));
    } catch (e, st) {
    }
  }

  Future<void> zerarAtendimentoGlobal() async {
    if (atendimentoAtual.isEmpty) return;

    String sql = """
      UPDATE cartoes 
      SET atendimento = '0'
      WHERE atendimento = '$atendimentoAtual';

      UPDATE mesas 
      SET atendimento = '0'
      WHERE atendimento = '$atendimentoAtual';
    """;

    try {
      // Como o UDP não bloqueia queries e já cuida do status, chamamos ipd direto.
      await Connection().ipd(sql);
      print("Atendimento zerado com sucesso para: $atendimentoAtual");
    } catch (e) {
      print("Erro ao zerar atendimento global no banco: $e");
    } finally {
      finalizarAtendimento();
    }
  } 

    // adicionaisObservacoesProdutos
    RxList<dynamic> listaAdicionaisObservacoes = <dynamic>[].obs;

    // buscarTipoPedido
    RxString tipoDoPedido = ''.obs;
    RxBool logicaPorMesa = false.obs;
    RxBool logicaPorComanda = false.obs;
    RxBool logicaPorComandaNaMesa = false.obs;

    // pegarmeuMobileId
    RxString meuMobileId = ''.obs;

    // informacoesListaGarcom
    RxList<dynamic> listaGarcom = <dynamic>[].obs;

    // buscarGrupos
    RxString numeroDoGrupo = ''.obs;
    RxString nomeDoGrupo = ''.obs;
    RxString idDoGrupo = ''.obs;
    RxList<dynamic> listaGrupo = <dynamic>[].obs;

    // buscarProdutos
    RxString numeroDoProduto = ''.obs;
    RxString nomeDoProduto = ''.obs;
    RxString idDoProduto = ''.obs;
    RxList<dynamic> listaProduto = <dynamic>[].obs;
    RxList<dynamic> listaProdutoFiltrada = <dynamic>[].obs;

    // buscarTamanhosPizza
    RxList<dynamic> listaTamanhosPizza = <dynamic>[].obs;

    // buscarSaboresBordasPizza
    RxList<dynamic> listaSaboresBordasPizza = <dynamic>[].obs;

    // buscarGruposPizza
    RxList<dynamic> listaGruposPizza = <dynamic>[].obs;

    // listaFormasDePagamento
    RxList<dynamic> listaFormasDePagamento = <dynamic>[].obs;

    // buscarCaixas
    RxString numeroTurnoCaixa = "".obs;
    RxString statusCaixa = "".obs;
    RxString numeroCaixa = "".obs;
    RxString nomeCaixa = "".obs;
    RxList<dynamic> listaCaixas = <dynamic>[].obs;

    @override
    void onInit() {
      super.onInit();
      carregarTudo();
    }

    Future<void> carregarTudo() async {
      await buscarTipoPedido();
      await adicionaisObservacoesProdutos();
      await pegarmeuMobileId();
      await informacoesListaGarcom();
      await buscarGrupos();
      await buscarProdutos();

      await buscarTamanhosPizza();
      await buscarSaboresBordasPizza();
      await buscarGruposPizza();

      await buscarPagamento();
      await buscarCaixas();
      await iniciarAtendimento();
      await _loadNomeLicenca();
      await _loadNumeroLicenca();
      await dia();      
    }

    // Função que retorna adicionais e observações dos produtos
    Future<void> adicionaisObservacoesProdutos() async {
      try {
        String dadosJson = await Connection().select(
          "SELECT numeroproduto_FK AS numeroproduto, if(numeroobservacao_FK = '0','0',(SELECT observacao FROM observacoes WHERE numero=numeroobservacao_FK)) AS nomeobservacao, numeroprodutoadicional_FK AS numeroadicional, if(numeroprodutoadicional_FK = '0', '', (SELECT nome FROM produtos WHERE numero=numeroprodutoadicional_FK)) AS nomeadicional, numeroobservacao_FK as numeroobservacao FROM observacoesadicionaisprodutos ORDER BY numeroproduto_FK;",
        );

        List<dynamic> lista = jsonDecode(dadosJson);
        // print(lista);
      if (lista.isNotEmpty) {
        listaAdicionaisObservacoes.assignAll(lista);
      } else {
        listaAdicionaisObservacoes.assignAll([]);
      }
    } catch (e) {
      print("Erro ao carregar adicionais: $e");
      listaAdicionaisObservacoes.assignAll([]);
    }
  }

  // Função para descobrir tipo do pedido
  Future<void> buscarTipoPedido() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT resultado FROM configuracoes WHERE numero='23';",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        String valor = lista[0]['resultado'].toString();

        tipoDoPedido.value = valor;
        logicaPorMesa.value = false;
        logicaPorComanda.value = false;
        logicaPorComandaNaMesa.value = false;
        
        if (tipoDoPedido == "100") {
          logicaPorMesa.value = true;
          // Set<String> modosSelecionados = {'Mesa'};
          // salvarModoSalvo(modosSelecionados);
        } else if (tipoDoPedido == "010") {
          logicaPorComanda.value = true;
          // Set<String> modosSelecionados = {'Comanda'};
          // salvarModoSalvo(modosSelecionados);
        } else if (tipoDoPedido == "011") {
          logicaPorComandaNaMesa.value = true;
          // Set<String> modosSelecionados = {'Mesa', 'Comanda'};
          // salvarModoSalvo(modosSelecionados);
        }
        print("Tipo do pedido: $tipoDoPedido");
      } else {
        // se a lista vier vazia
        tipoDoPedido.value = "Não foi possível buscar tipo do pedido";
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
      tipoDoPedido.value = "0";
    }
  }

  // Função para pegar o id do aparelho
  Future<String> pegarmeuMobileId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      meuMobileId.value = androidInfo.id;
      return androidInfo.id; // ID do Android
    }

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      meuMobileId.value = iosInfo.identifierForVendor ?? 'unknown_ios';
      return iosInfo.identifierForVendor ?? 'unknown_ios';
    }

    if (Platform.isMacOS) {
      final macInfo = await deviceInfo.macOsInfo;
      meuMobileId.value = macInfo.computerName;
      return macInfo.computerName;
    }

    if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      meuMobileId.value = windowsInfo.deviceId;
      return windowsInfo.deviceId;
    }

    return 'unknown_device';
  }

  // Função que retorna informações garçom
  Future<void> informacoesListaGarcom() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, nome, senhanova, funcao, pgtomobile FROM usuarios WHERE ativo = '1' AND numero != '1' AND mobile = '1' ORDER BY nome;",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        String valor = lista[0]['numero'].toString();
        String valor2 = lista[0]['nome'];

        listaGarcom.assignAll(lista);
      } else {
        listaGarcom.assignAll([]);
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
      listaGarcom.assignAll([]);
    }
  }

  // Função que busca grupos
  Future<void> buscarGrupos() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, nome, ID FROM grupos WHERE mobile='1' AND id='P' ORDER BY nome;",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        String valor = lista[0]['numero'].toString();
        String valor2 = lista[0]['nome'];
        String valor3 = lista[0]['ID'].toString();

        numeroDoGrupo.value = valor;
        nomeDoGrupo.value = valor2;
        idDoGrupo.value = valor3;
        listaGrupo.assignAll(lista);
      } else {
        numeroDoGrupo.value = "";
        nomeDoGrupo.value = "";
        idDoGrupo.value = "";
        listaGrupo.assignAll([]);
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
      numeroDoGrupo.value = "";
      nomeDoGrupo.value = "";
      idDoGrupo.value = "";
      listaGrupo.assignAll([]);
    }
  }

  // Função que busca produtos
  Future<void> buscarProdutos() async {
    try {
      String dadosJson = await Connection().select("""
        SELECT 
          g.numero AS grupo_numero,
          g.nome   AS grupo_nome,
          pr.numero AS produto_numero,
          pr.nome   AS produto_nome,
          pr.valor  AS produto_valor,
          pr.id AS produto_id,
          un.simbolo AS produto_un
        FROM produtos AS pr
        JOIN grupos AS g 
          ON g.numero = pr.numerogrupocardapio_FK
        JOIN unidades AS un
          ON un.numero = pr.numerounidade_FK
        
        WHERE g.mobile = '1'
          AND pr.ativo = '1'
        ORDER BY pr.nome ASC;
        """);
      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        String valor = lista[0]['grupo_numero'].toString();
        String valor2 = lista[0]['produto_numero'].toString();
        String valor3 = lista[0]['produto_nome'].toString();
        String valor4 = lista[0]['produto_valor'].toString();
          numeroDoProduto.value = valor;
          nomeDoProduto.value = valor2;
          idDoProduto.value = valor3;
          listaProduto.assignAll(lista);
          listaProdutoFiltrada.assignAll(lista);
      } else {
          numeroDoProduto.value = "";
          nomeDoProduto.value = "";
          idDoProduto.value = "";
          listaProduto.assignAll([]);
          listaProdutoFiltrada.assignAll([]);
      }
    } catch (e) {
      print("Erro ao carregar configuracaoServico: $e");
        numeroDoProduto.value = "";
        nomeDoProduto.value = "";
        idDoProduto.value = "";
        listaProduto.assignAll([]);
        listaProdutoFiltrada.assignAll([]);
    }
  }

  // Selectama dos tamanhos de pizza
  Future<void> buscarTamanhosPizza() async {
    try {
      /* String dadosJson = await Connection().select(
        "SELECT numeroproduto_FK, nome, diversidadesabores FROM tamanhopizza WHERE ativo = '1' ORDER BY nome;",
      );   */
      String dadosJson = await Connection().select(
         """
        SELECT 
          g.numero AS grupo_numero,
          g.nome   AS grupo_nome,
          pr.numero AS produto_numero,
          pr.nome   AS produto_nome,
          pr.valor  AS produto_valor,
          pr.id AS produto_id
        FROM produtos AS pr
        JOIN grupos AS g 
          ON g.numero = pr.numerogrupocardapio_FK
        WHERE g.mobile = '1' AND pr.id = 'PZ' ORDER BY pr.nome ASC;
        """,
      );  

      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
          listaTamanhosPizza.assignAll(lista);
      } else {

          listaTamanhosPizza.assignAll([]);
      }
    } catch (e) {
      print("Erro ao carregar buscarTamanhosPizza: $e");
      listaTamanhosPizza.assignAll([]);     
    }
  } 

  // Select dos sabores e bordas de pizza 
  Future<void> buscarSaboresBordasPizza() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, nome, numerovenda, id, numerogrupo_FK FROM sabores WHERE ativo='1' ORDER BY nome;",
      );  

      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        listaSaboresBordasPizza.assignAll(lista);
      } else {
        listaSaboresBordasPizza.assignAll([]);
      }
    } catch (e) {
      print("Erro ao carregar buscarSaboresBordasPizza: $e");
      listaSaboresBordasPizza.assignAll([]);     
    }
  }

  // Select para buscar grupos da pizza 
  Future<void> buscarGruposPizza() async {
    try {
     /*   String dadosJson = await Connection().select(
        "SELECT numeroproduto_FK, nome, diversidadesabores FROM tamanhopizza WHERE ativo = '1' ORDER BY nome;",
      );   */
      String dadosJson = await Connection().select(
        "SELECT numero, nome FROM grupos WHERE id = 'PZ';",
      );  

      List<dynamic> lista = jsonDecode(dadosJson);
      if (lista.isNotEmpty) {
        // pega apenas o campo resultado
        listaGruposPizza.assignAll(lista);
      } else {
        listaGruposPizza.assignAll([]);
      }
    } catch (e) {
      print("Erro ao carregar buscarSaboresBordasPizza: $e");
      listaGruposPizza.assignAll([]);   
    }
  }

  Future<void> buscarPagamento() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, moeda, tipo FROM formaspagamento WHERE operante='1' AND mobile='1' AND (tipo!='5' AND tipo!='99')",
      );

      // Decode fora do setState
      final List<dynamic> lista = jsonDecode(dadosJson);
      // print(">>>Formas de pagamento: $lista<<<");

      if (lista.isNotEmpty) {
        listaFormasDePagamento.assignAll(lista);
      } else {
        listaFormasDePagamento.assignAll([]);
      }
    } catch (e) {
      listaFormasDePagamento.assignAll([]);
    }
  }

  // Buscar se comanda esta em conta
  Future<void> buscarCaixas() async {
    try {
      /* String dadosJson = await Connection().select("""
          SELECT MAX(mc.numero), mc.status, mc.numerocaixa_FK, c.nome FROM movimentacaocaixas AS mc, caixas AS c WHERE mc.numerocaixa_FK=c.numero AND mc.STATUS='1' GROUP BY mc.numerocaixa_FK ORDER BY mc.numero DESC;
        """); */

      String dadosJson = await Connection().select("""
        SELECT MAX(mc.numero), mc.status, mc.numerocaixa_FK, c.nome FROM movimentacaocaixas AS mc, caixas AS c WHERE mc.numerocaixa_FK=c.numero AND mc.STATUS='1' AND c.mobile='1' GROUP BY mc.numerocaixa_FK ORDER BY mc.numerocaixa_FK;
      """);

      List<dynamic> lista = jsonDecode(dadosJson);

      if (lista.isNotEmpty) {
        listaCaixas.assignAll(lista);
        if (listaCaixas.length == 1) {
          numeroTurnoCaixa.value = listaCaixas[0]['MAX(mc.numero)'].toString();
          statusCaixa.value = listaCaixas[0]['status'].toString();
          numeroCaixa.value = listaCaixas[0]['numerocaixa_FK'].toString();
          nomeCaixa.value = listaCaixas[0]['nome'].toString();
        }
        print(
          ">>>Lista de caixas<<<$lista",
        ); // flutter: >>>Lista de caixas<<<[{MAX(mc.numero): 254, status: 1, numerocaixa_FK: 1, nome: SALAO}]
      } else {
        listaCaixas.assignAll([]);
      }
    } catch (e) {
      print(">>>Erro ao buscar caixas: $e<<<");
      listaCaixas.assignAll([]);
    }
  }
} */
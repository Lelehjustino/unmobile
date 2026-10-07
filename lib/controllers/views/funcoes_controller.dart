import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:un_recepcao/controllers/views/garcom_controller.dart';
import 'package:un_recepcao/data/data_class.dart';
import 'package:world_holidays/world_holidays.dart';
// importar final FuncoesController funcoesController = Get.put(FuncoesController());
class FuncoesController extends GetxController {
  final GarcomController garcomController = Get.find<GarcomController>();
  // --- Controle de Atendimento (Fazer Pedido) ---
  RxBool isEnviandoPedido = false.obs;
  String atendimentoAtual = "";
  String nomeTraidpoint = "";
  
  String versaoDoApp = "1.9.27";
  String seuToken = "403f2607-f69e-40e0-86ec-5127ffcf00011669e17c44a695e98e8ea63c42f70b9be7c3-0ade-41ac-8d48-4d3358966eb8";

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
    RxList<dynamic> listaAdicionaisObservacoesFiltrada = <dynamic>[].obs;

    // buscarTipoPedido
    RxString tipoDoPedido = ''.obs;
    RxBool vendaComanda = false.obs;
    RxBool vendaMesa = false.obs;
    RxBool vendaBalcao = false.obs;

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
    RxList<dynamic> listaImpressoras = <dynamic>[].obs;

    RxList<dynamic> observacoesFuncaoFiltrada = <dynamic>[].obs;
    RxList<dynamic> adicionaisFuncaoFiltrada = <dynamic>[].obs;

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
      await buscarImpressoras(); 
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
          UPDATE delivery SET atendimento = '0' WHERE atendimento = '$numeroDaLicencaSelecionada';
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

        /* String dadosJson = await Connection().select(
          """
          SELECT
            numeroproduto_FK AS numeroproduto,

            numeroobservacao_FK AS numeroobservacao,
            IF(numeroobservacao_FK = '0', '0', (SELECT observacao FROM observacoes WHERE numero = numeroobservacao_FK)) AS nomeobservacao,
            diasdasemana_obs AS diasDaSemanaObs,
            horainicio_obs AS inicioObs,
            horatermino_obs AS fimObs,

            numeroprodutoadicional_FK AS numeroadicional,
            IF(numeroprodutoadicional_FK = '0', '', (SELECT nome FROM produtos WHERE numero = numeroprodutoadicional_FK)) AS nomeadicional,
            diasdasemana_adc AS diasDaSemanaAdd,
            horainicio_adc AS inicioAdd,
            horatermino_adc AS fimAdd,
            valor_adc AS valorAdicional

          FROM observacoesadicionaisprodutos
          ORDER BY nomeadicional, nomeobservacao;
          """,
        ); */

        String dadosJson = await Connection().select(
          """
            SELECT
              oap.numeroproduto_FK AS numeroproduto,

              oap.numeroobservacao_FK AS numeroobservacao,
              IF(
                  oap.numeroobservacao_FK = '0',
                  '0',
                  o.observacao
              ) AS nomeobservacao,

              oap.diasdasemana_obs AS diasDaSemanaObs,
              oap.horainicio_obs AS inicioObs,
              oap.horatermino_obs AS fimObs,

              oap.numeroprodutoadicional_FK AS numeroadicional,
              IF(
                  oap.numeroprodutoadicional_FK = '0',
                  '',
                  p.nome
              ) AS nomeadicional,

              oap.diasdasemana_adc AS diasDaSemanaAdd,
              oap.horainicio_adc AS inicioAdd,
              oap.horatermino_adc AS fimAdd,
              oap.valor_adc AS valorAdicional

          FROM observacoesadicionaisprodutos oap

          LEFT JOIN observacoes o
              ON o.numero = oap.numeroobservacao_FK

          LEFT JOIN produtos p
              ON p.numero = oap.numeroprodutoadicional_FK
              AND p.ativo = 1

          WHERE
              oap.numeroprodutoadicional_FK = '0'
              OR p.numero IS NOT NULL

          ORDER BY nomeadicional, nomeobservacao;
          """,
        );

        List<dynamic> lista = jsonDecode(dadosJson);
        // print(lista);
      if (lista.isNotEmpty) {
        listaAdicionaisObservacoes.assignAll(lista);
        await filtrarAdicionaisObservacoes(lista);
      } else {
        listaAdicionaisObservacoes.assignAll([]);
        listaAdicionaisObservacoesFiltrada.assignAll([]);
      }
    } catch (e) {
      print("Erro ao carregar adicionais: $e");
      listaAdicionaisObservacoes.assignAll([]);
      listaAdicionaisObservacoesFiltrada.assignAll([]);
    }
  }

  Future<bool> buscarFeriado() async {
    final worldHolidays = WorldHolidays();
    final hoje = DateTime.now();

    bool ehFeriadoBase = false;

    try {
      await worldHolidays.getHolidays('BR');

      final ehFeriadoNacional = worldHolidays.isHoliday('BR', hoje);

      String dadosJson = await Connection().select(
        "SELECT DATA FROM feriados;",
      );

      List<dynamic> lista = jsonDecode(dadosJson);

      final dataHoje = hoje.toIso8601String().substring(0, 10);

      ehFeriadoBase = lista.any((item) => item['DATA'] == dataHoje);

      bool ehFeriado = true;

      if(!ehFeriadoNacional && !ehFeriadoBase){
        ehFeriado = false;
      }

      return ehFeriado;
    } catch (e) {
      print("Erro ao carregar buscarFeriado: $e");
      return ehFeriadoBase;
    }
  }

  Future<void> filtrarAdicionaisObservacoes(List<dynamic> observacoesEadicionaisFuncao) async {
    List<dynamic> observacoesEadicionaisFuncaoFiltrada = [];
    int inicio = 0;
    int fim = 0;
    bool hojeEhFeriado = await buscarFeriado();

    if (hojeEhFeriado){
      inicio = 7;
      fim = 8;
    }else if(DateTime.now().weekday == 1){
      inicio = 0;
      fim = 1;
    }else if(DateTime.now().weekday == 2){
      inicio = 1;
      fim = 2;
    }else if(DateTime.now().weekday == 3){
      inicio = 2;
      fim = 3;
    }else if(DateTime.now().weekday == 4){
      inicio = 3;
      fim = 4;
    }else if(DateTime.now().weekday == 5){
      inicio = 4;
      fim = 5;
    }else if(DateTime.now().weekday == 6){
      inicio = 5;
      fim = 6;
    }else if(DateTime.now().weekday == 7){
      inicio = 6;
      fim = 7;
    }else if(DateTime.now().weekday == 0){
      inicio = 6;
      fim = 7;
    }
    for(var i = 0; i < observacoesEadicionaisFuncao.length; i++){
      if((observacoesEadicionaisFuncao[i]['diasDaSemanaObs'].toString().substring(inicio, fim) == '1')){
        if (hojeEhFeriado) {
          final inicioObs = observacoesEadicionaisFuncao[i]['inicioObs'].toString();
          final fimObs = observacoesEadicionaisFuncao[i]['fimObs'].toString();

          final horaInicio = int.parse(inicioObs.substring(0, 2));
          final minutoInicio = int.parse(inicioObs.substring(3, 5));

          final horaFim = int.parse(fimObs.substring(0, 2));
          final minutoFim = int.parse(fimObs.substring(3, 5));

          final inicioHorario = horaInicio * 60 + minutoInicio;
          final fimHorario = horaFim * 60 + minutoFim;

          final agoraMinutos = DateTime.now().hour * 60 + DateTime.now().minute;

          if (agoraMinutos >= inicioHorario && agoraMinutos <= fimHorario) {
            observacoesFuncaoFiltrada.add(observacoesEadicionaisFuncao[i]);
          }
        } else {
          final inicioObs = observacoesEadicionaisFuncao[i]['inicioObs'].toString();
          final fimObs = observacoesEadicionaisFuncao[i]['fimObs'].toString();

          final horaInicio = int.parse(inicioObs.substring(0, 2));
          final minutoInicio = int.parse(inicioObs.substring(3, 5));

          final horaFim = int.parse(fimObs.substring(0, 2));
          final minutoFim = int.parse(fimObs.substring(3, 5));

          final inicioHorario = horaInicio * 60 + minutoInicio;
          final fimHorario = horaFim * 60 + minutoFim;

          final agoraMinutos = DateTime.now().hour * 60 + DateTime.now().minute;

          if(agoraMinutos >= inicioHorario && agoraMinutos <= fimHorario){
            observacoesFuncaoFiltrada.add(observacoesEadicionaisFuncao[i]);
          }
        }
      }

      /* if(observacoesEadicionaisFuncao[i]['diasDaSemanaObs'].toString().substring(7, 8) == '1' && hojeEhFeriado){
        observacoesFuncaoFiltrada.add(observacoesEadicionaisFuncao[i]);
      } */
      
      if((observacoesEadicionaisFuncao[i]['diasDaSemanaAdd'].toString().substring(inicio, fim) == '1')){
        if (hojeEhFeriado) {
          final inicioObs = observacoesEadicionaisFuncao[i]['inicioAdd'].toString();
          final fimObs = observacoesEadicionaisFuncao[i]['fimAdd'].toString();

          final horaInicio = int.parse(inicioObs.substring(0, 2));
          final minutoInicio = int.parse(inicioObs.substring(3, 5));

          final horaFim = int.parse(fimObs.substring(0, 2));
          final minutoFim = int.parse(fimObs.substring(3, 5));

          final inicioHorario = horaInicio * 60 + minutoInicio;
          final fimHorario = horaFim * 60 + minutoFim;

          final agoraMinutos = DateTime.now().hour * 60 + DateTime.now().minute;

          if (agoraMinutos >= inicioHorario && agoraMinutos <= fimHorario) {
            adicionaisFuncaoFiltrada.add(observacoesEadicionaisFuncao[i]);
          }
        } else {
          final inicioObs = observacoesEadicionaisFuncao[i]['inicioAdd'].toString();
          final fimObs = observacoesEadicionaisFuncao[i]['fimAdd'].toString();

          final horaInicio = int.parse(inicioObs.substring(0, 2));
          final minutoInicio = int.parse(inicioObs.substring(3, 5));

          final horaFim = int.parse(fimObs.substring(0, 2));
          final minutoFim = int.parse(fimObs.substring(3, 5));

          final inicioHorario = horaInicio * 60 + minutoInicio;
          final fimHorario = horaFim * 60 + minutoFim;

          final agoraMinutos = DateTime.now().hour * 60 + DateTime.now().minute;

          if(agoraMinutos >= inicioHorario && agoraMinutos <= fimHorario){
            adicionaisFuncaoFiltrada.add(observacoesEadicionaisFuncao[i]);
          }
        }
      }
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
        // String valor = lista[0]['resultado'].toString();
        String valor = lista[0]['resultado'].toString();

        String mesa = valor.length >= 3 ? valor.substring(0, 1) : valor;
        String comanda = valor.length >= 3 ? valor.substring(1, 2) : valor;
        String comandaNaMesa = valor.length >= 3 ? valor.substring(2, 3) : valor;
        String balcao = "";

        try {
          balcao = valor.length >= 3 ? valor.substring(3, 4) : valor;
        } catch (e){
          balcao = "";
        }

        tipoDoPedido.value = valor;
        vendaComanda.value = false;
        vendaMesa.value = false;
        vendaBalcao.value = false;
        garcomController.vendaComandaNaMesa.value = false;

        if (mesa == "1"){
          vendaMesa.value = true;
          garcomController.vendaMesa.value = true;
        } 

        if (comanda == "1"){
          vendaComanda.value = true;
          garcomController.vendaComanda.value = true;
        }

        if (comandaNaMesa == "1"){
          vendaComanda.value = true;
          garcomController.vendaComandaNaMesa.value = true;
          garcomController.vendaComanda.value = true;
        }

        if (balcao == "1"){
          vendaBalcao.value = true;
        }
        
        /* if (tipoDoPedido == "100") {
          // venda comanda
          logicaPorMesa.value = true;
          vendaComanda.value = true;
          garcomController.vendaComandaNaMesa.value = false;
          vendaMesa.value = false;
        } else if (tipoDoPedido == "010") {
          // venda comanda
          logicaPorComanda.value = true;
          vendaComanda.value = true;
          vendaMesa.value = false;
          garcomController.vendaComandaNaMesa.value = false;
        } else if (tipoDoPedido == "011") {
          // venda mesa
          logicaPorComandaNaMesa.value = true;
          vendaComanda.value = false;
          vendaMesa.value = true;
          garcomController.vendaComandaNaMesa.value = true;
        } else if (tipoDoPedido == "111"){
          // venda mesa e comanda
          logicaPorComandaNaMesaEMesa.value = true;
          vendaComanda.value = true;
          vendaMesa.value = true;
          garcomController.vendaComandaNaMesa.value = true;
        } else if (tipoDoPedido == "110"){
          // venda mesa e comanda
          logicaPorComandaEMesa.value = true;
          vendaComanda.value = true;
          vendaMesa.value = true;
          garcomController.vendaComandaNaMesa.value = false;
        }
        print("Tipo do pedido: $tipoDoPedido");
        // quarta posicao em try catch 
      } else {
        // se a lista vier vazia
        tipoDoPedido.value = "Não foi possível buscar tipo do pedido";
      } */
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
      /* String dadosJson = await Connection().select("""
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
        """); */
      String dadosJson = await Connection().select("""
        SELECT 
          g.numero AS grupo_numero,
          g.nome   AS grupo_nome,
          pr.numero AS produto_numero,
          pr.nome   AS produto_nome,
          pr.valor  AS produto_valor,
          pr.meiaporcao AS produto_meia_porcao,
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

  Future<void> buscarImpressoras() async {
    try {
      String dadosJson = await Connection().select(
        "SELECT numero, nome, colunas FROM impressoras;",
      );

      // Decode fora do setState
      final List<dynamic> lista = jsonDecode(dadosJson);
      // print(">>>Formas de pagamento: $lista<<<");

      if (lista.isNotEmpty) {
        listaImpressoras.assignAll(lista);
      } else {
        listaImpressoras.assignAll([]);
      }
    } catch (e) {
      listaImpressoras.assignAll([]);
    }
  }
}
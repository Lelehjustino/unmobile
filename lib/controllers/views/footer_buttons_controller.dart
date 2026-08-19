import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:un_recepcao/controllers/views/garcom_controller.dart';

class FooterButtonsController extends GetxController {

  RxBool aparecerCheckIn = false.obs;
  RxBool aparecerCheckOut = false.obs;
  RxBool aparecerNote = false.obs;
  RxBool aparecerRecepcao = false.obs;
  RxBool aparecerGarcom = false.obs;
  RxBool aparecerMapa = false.obs;
  RxBool aparecerKDS = false.obs;
  RxBool aparecerPedidos = false.obs;
  RxBool aparecerExpedicaoMotoboy = false.obs;
  RxBool aparecerExpedicaoCliente = false.obs;
  RxBool rotaHome = false.obs;
  RxBool rotaPainelCliente = false.obs;
  RxBool rotaExpedicaoMotoboy = false.obs;
  RxBool aparecerCupomAvulso = false.obs;

  RxBool cadastroCliente = false.obs;
  RxBool tipoCadastroClienteCpf = false.obs;
  RxBool tipoCadastroClienteTelefone = false.obs;
  RxBool forcarCadastroCliente = false.obs;

  GarcomController garcomController = Get.find();

  @override
  void onInit() {
    super.onInit();
    carregarConfiguracoes();
  }

  void carregarConfiguracoes() async {
    await carregarchecks();
    await carregarNote();
    await carregarRecepcao();
    await carregargarcom();
    await carregarMapa();
    await carregarRota();
    await carregarPaineis();
    await carregarCupomAvulso();
    await configuracoesCadastroCliente();
  }

  // Checkin e Checkout
  Future<void> carregarchecks() async {
    final prefs = await SharedPreferences.getInstance();
    final checkJson = prefs.getString('check_padrao');

    if (checkJson != null) {
      final checksSalvos = Set<String>.from(jsonDecode(checkJson));
      /* final checksSalvos = List<String>.from(jsonDecode(checkJson));

      final bool checkInPreenchido = checksSalvos.length <= 0 || checksSalvos[0].trim().isNotEmpty;

      final bool checkOutPreenchido = checksSalvos.length <= 1 || checksSalvos[1].trim().isNotEmpty; */

      if (checksSalvos.contains("0") && !checksSalvos.contains("1")) {
          aparecerCheckIn.value = true;
          aparecerCheckOut.value = false;
      } else if (checksSalvos.contains("1") && !checksSalvos.contains("0")) {
          aparecerCheckIn.value = false;
          aparecerCheckOut.value = true;
      } else if (!checksSalvos.contains("0") && !checksSalvos.contains("1")) {
          aparecerCheckIn.value = false;
          aparecerCheckOut.value = false;
      } else if (checksSalvos.contains("0") && checksSalvos.contains("1")) {
          aparecerCheckIn.value = true;
          aparecerCheckOut.value = true;
      } else {
          aparecerCheckIn.value = false;
          aparecerCheckOut.value = false;
      }

      /* if (checkInPreenchido && !checkOutPreenchido) {
        aparecerCheckIn.value = true;
        aparecerCheckOut.value = false;
      } else if (!checkInPreenchido && checkOutPreenchido) {
        aparecerCheckIn.value = false;
        aparecerCheckOut.value = true;
      } else if (!checkInPreenchido && !checkOutPreenchido) {
        aparecerCheckIn.value = false;
        aparecerCheckOut.value = false;
      } else {
        aparecerCheckIn.value = true;
        aparecerCheckOut.value = true;
      } */
    } else {
        // Se não tiver nada salvo, define padrão
        aparecerCheckIn.value = false;
        aparecerCheckOut.value = false;
    }
  }
  
  // Notes
  Future<void> carregarNote() async {
    final prefs = await SharedPreferences.getInstance();
    final noteJson = prefs.getString('note_padrao');

    if (noteJson != null) {
      final notesSalvos = Set<String>.from(jsonDecode(noteJson));

      if (notesSalvos.contains('0')) {
          aparecerNote.value = true;
      } else {
          aparecerNote.value = false;
      }
    } else {
      aparecerNote.value = false;
    }
  }

  // Recepcao 
  Future<void> carregarRecepcao() async {
    final prefs = await SharedPreferences.getInstance();
    final recepcaoJson = prefs.getString('recepcao_padrao');

    if (recepcaoJson != null) {
      final recepcaosSalvos = Set<String>.from(jsonDecode(recepcaoJson));

      if (recepcaosSalvos.contains('0')) {
        // se recepcao selecionado
        aparecerRecepcao.value = true;
      } else {
        // se recepcao nao selecionado
        aparecerRecepcao.value = false;
      }
    } else {
      // configuração padrao
      aparecerRecepcao.value = false;
    }
  }

  // Mapa 
  Future<void> carregarMapa() async {
    final prefs = await SharedPreferences.getInstance();
    final modoJson = prefs.getString('modo_padrao');

    if (modoJson != null) {
      final modosSalvos = Set<String>.from(jsonDecode(modoJson));
      // Regra: O mapa aparece se "Mesa" OU "Comanda" estiverem selecionados
      aparecerMapa.value = (modosSalvos.contains("Mapa"));
    } else {
      // Se não existir configuração salva (primeira execução), mapa deve vir DESABILITADO
      aparecerMapa.value = false;
    }
  }

  // Garcom
  Future<void> carregargarcom() async {
    final prefs = await SharedPreferences.getInstance();
    final garcomJson = prefs.getString('garcom_padrao');

    if (garcomJson != null) {
      final garcomSalvos = Set<String>.from(jsonDecode(garcomJson));

      if (garcomSalvos.contains("0")) {
        aparecerGarcom.value = true;
      } else if (!garcomSalvos.contains("0")) {
        aparecerGarcom.value = false;
      } else {
        aparecerGarcom.value = true;
      }
    } else {
      // Se não tiver nada salvo, define padrão
      aparecerGarcom.value = true;
    }
  }

  // Configuracao paineis 
  Future<void> carregarPaineis() async {
    final prefs = await SharedPreferences.getInstance();
    final painelJson = prefs.getString('painel_padrao');

    if (painelJson != null) {
      final paineisSalvos = Set<String>.from(jsonDecode(painelJson));

      if (paineisSalvos.contains('0')) { // se KDS selecionado
          aparecerKDS.value = true;
      } else { // se KDS nao selecionado
          aparecerKDS.value = false;
      }

      if (paineisSalvos.contains('1')) { // se Pedidos selecionado
          aparecerExpedicaoCliente.value = true;
      } else { // se Pedidos nao selecionado
          aparecerExpedicaoCliente.value = false;
      }

      if (paineisSalvos.contains('2')) { // se Expedição motoboy selecionado
          aparecerExpedicaoMotoboy.value = true;
      } else { // se Expedição motoboy nao selecionado
          aparecerExpedicaoMotoboy.value = false;
      }

    } else { // configuração padrao 
      aparecerKDS.value = false;
      aparecerExpedicaoCliente.value = false;
      aparecerExpedicaoMotoboy.value = false;
    }
  }

  // Rota inicial 
  Future<void> carregarRota() async {
    final prefs = await SharedPreferences.getInstance();
    final rotaJson = prefs.getString('rota_padrao');

    if (rotaJson != null) {
      final rotasSalvos = Set<String>.from(jsonDecode(rotaJson));

      if (rotasSalvos.contains("0") && !rotasSalvos.contains("1") && !rotasSalvos.contains("2")) {
        rotaHome.value = true;
        rotaPainelCliente.value = false;
        rotaExpedicaoMotoboy.value = false;
      } else if (rotasSalvos.contains("1") && !rotasSalvos.contains("0") && !rotasSalvos.contains("2")) {
        rotaHome.value = false;
        rotaPainelCliente.value = true;
        rotaExpedicaoMotoboy.value = false;
      }else if (!rotasSalvos.contains("0") && !rotasSalvos.contains("1") && rotasSalvos.contains("2")){
        rotaHome.value = false;
        rotaPainelCliente.value = false;
        rotaExpedicaoMotoboy.value = true;
      } else {
        rotaHome.value = true;
        rotaPainelCliente.value = false;
        rotaExpedicaoMotoboy.value = false;
      }
    } else {
      rotaHome.value = true;
      rotaPainelCliente.value = false;
      rotaExpedicaoMotoboy.value = false;
    }
  }

  // Carrega o cupom avulso - bool para rota
  Future<void> carregarCupomAvulso() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getString('cupom_avulso');

    if (valor == null || valor.isEmpty) {
      aparecerCupomAvulso.value = false;
      return;
    }

    Set<String> setLocal;

    if (valor.startsWith('[')) {
      setLocal = Set<String>.from(jsonDecode(valor));
    } else {
      setLocal = {valor};
    }

    aparecerCupomAvulso.value = setLocal.contains('Cupom Avulso');
  }

  Future<void> configuracoesCadastroCliente() async {
    await carregarCadastroCliente();
    await carregarTipoCadastroCliente();
    await carregarForcarCadastroCliente();
  }

  Future<void> carregarForcarCadastroCliente() async {
    final prefs = await SharedPreferences.getInstance();
    final recepcaoJson = prefs.getString('forcar_cadastro_cliente');

    if (recepcaoJson != null) {
      final recepcaosSalvos = Set<String>.from(jsonDecode(recepcaoJson));

      if (recepcaosSalvos.contains('0')) {
        // se forcar cadastro selecionado
        forcarCadastroCliente.value = true;
      } else {
        // se forcar cadastro nao selecionado
        forcarCadastroCliente.value = false;
      }
    } else {
      // configuração padrao
      forcarCadastroCliente.value = false;
    }
  }

  // Carregar cadastro cliente
  Future<void> carregarCadastroCliente() async {
    final prefs = await SharedPreferences.getInstance();
    final recepcaoJson = prefs.getString('cadastro_cliente');

    if (recepcaoJson != null) {
      final recepcaosSalvos = Set<String>.from(jsonDecode(recepcaoJson));

      if (recepcaosSalvos.contains('0')) {
        // se cadastro cliente selecionado
        cadastroCliente.value = true;
      } else {
        // se cadastro cliente nao selecionado
        cadastroCliente.value = false;
      }
    } else {
      // configuração padrao
      cadastroCliente.value = false;
    }
  }

  // Carregar tipo de cadastro cliente
  Future<void> carregarTipoCadastroCliente() async {
    final prefs = await SharedPreferences.getInstance();
    final recepcaoJson = prefs.getString('tipo_cadastro_cliente');

    if (recepcaoJson != null) {
      final recepcaosSalvos = Set<String>.from(jsonDecode(recepcaoJson));

      if (recepcaosSalvos.contains('0') && !recepcaosSalvos.contains('1')) {
        // se recepcao selecionado
        tipoCadastroClienteCpf.value = true;
        tipoCadastroClienteTelefone.value = false;
      } else if (!recepcaosSalvos.contains('0') && recepcaosSalvos.contains('1')) {
        // se recepcao nao selecionado
        tipoCadastroClienteCpf.value = false;
        tipoCadastroClienteTelefone.value = true;
      } else {
        // se recepcao nao selecionado
        tipoCadastroClienteCpf.value = false;
        tipoCadastroClienteTelefone.value = true;
      }
    } else {
      // configuração padrao
      tipoCadastroClienteCpf.value = false;
      tipoCadastroClienteTelefone.value = true;
    }
  }

}
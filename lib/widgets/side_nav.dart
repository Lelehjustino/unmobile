import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:un_recepcao/controllers/carrinho_controller.dart';
import 'package:un_recepcao/controllers/views/funcoes_controller.dart';
import 'package:un_recepcao/views/checkin_page.dart';
import 'package:un_recepcao/views/checkout_page.dart';
import 'package:un_recepcao/views/configuracoes_page.dart';
import 'package:un_recepcao/views/garcom_page.dart' hide Padding;
import 'package:un_recepcao/views/mapa_page.dart';
import 'package:un_recepcao/views/notes_page.dart';
import 'package:un_recepcao/views/recepcao_page.dart';
import 'package:window_manager/window_manager.dart';

class SideNav extends StatefulWidget {
  const SideNav({super.key});

  @override
  State<SideNav> createState() {
    return SideNavState();
  }
}

class SideNavState extends State<SideNav> {
  String? selectedModo;
  bool aparecerCheckIn = false;
  bool aparecerCheckOut = false;
  bool aparecerMapa = false;
  bool aparecerGarcom = false;
  bool aparecerRecepcao = false;
  bool aparecerNote = false;
  bool aparecerKDS = false;
  bool aparecerPedidos = false;
  bool aparecerExpedicaoMotoboy = false;
  bool rotaHome = true;
  bool rotaPainelCliente = false;
  bool aparecerCupomAvulso = false;
  bool rotaExpedicaoMotoboy = false;

  final FuncoesController funcoesController = Get.put(FuncoesController());
  final CarrinhoController carrinhoController = Get.find<CarrinhoController>();

  bool isloadingProdutos = false;

  @override
  void initState() {
    super.initState();
    carregarNavegacao();
  }

  // Carregar funções de navegação
  void carregarNavegacao() async {
    await _carregarModos();
    await _carregarchecks();
    await _carregargarcom();
    await _carregarRecepcao();
    await _carregarNote();
    await _carregarPaineis();
    await carregarRota();
    await _carregarCupomAvulso();
  }

  // Carregar cupom avulso
  Future<void> _carregarCupomAvulso() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getString('cupom_avulso');

    if (valor == null || valor.isEmpty) {
      setState(() => aparecerCupomAvulso = false);
      return;
    }

    Set<String> setLocal;

    if (valor.startsWith('[')) {
      setLocal = Set<String>.from(jsonDecode(valor));
    } else {
      setLocal = {valor};
    }

    setState(() {
      aparecerCupomAvulso = setLocal.contains('Cupom Avulso');
    });
  }

  // Carregar rota 
  Future<void> carregarRota() async {
    final prefs = await SharedPreferences.getInstance();
    final rotaJson = prefs.getString('rota_padrao');

    if (rotaJson != null) {
      final rotasSalvos = Set<String>.from(jsonDecode(rotaJson));

      if (rotasSalvos.contains("Home") && !rotasSalvos.contains("Expedição cliente") && !rotasSalvos.contains("Expedição motoboy")) {
        setState(() {
          rotaHome = true;
          rotaPainelCliente = false;
          rotaExpedicaoMotoboy = false;
        });
      } else if (rotasSalvos.contains("Expedição cliente") && !rotasSalvos.contains("Home") && !rotasSalvos.contains("Expedição motoboy")) {
        setState(() {
          rotaHome = false;
          rotaPainelCliente = true;
          rotaExpedicaoMotoboy = false;
        });
      }else if (!rotasSalvos.contains("Expedição cliente") && !rotasSalvos.contains("Home") && rotasSalvos.contains("Expedição motoboy")){
        setState(() {
          rotaHome = false;
          rotaPainelCliente = false;
          rotaExpedicaoMotoboy = true;
        });
      } else {
        setState(() {
          rotaHome = true;
          rotaPainelCliente = false;
          rotaExpedicaoMotoboy = false;
        });
      }
    } else {
      setState(() {
        rotaHome = true;
        rotaPainelCliente = false;
        rotaExpedicaoMotoboy = false;
      });
    }
  }

  // Carregar paineis
  Future<void> _carregarPaineis() async {
    final prefs = await SharedPreferences.getInstance();
    final painelJson = prefs.getString('painel_padrao');

    if (painelJson != null) {
      final paineisSalvos = Set<String>.from(jsonDecode(painelJson));

      if (paineisSalvos.contains('KDS')) { // se KDS selecionado
        setState(() {
          aparecerKDS = true;
        });
      } else { // se KDS nao selecionado
        setState(() {
          aparecerKDS = false;
        });
      }

      if (paineisSalvos.contains('Expedição cliente')) { // se Pedidos selecionado
        setState(() {
          aparecerPedidos = true;
        });
      } else { // se Pedidos nao selecionado
        setState(() {
          aparecerPedidos = false;
        });
      }

      if (paineisSalvos.contains('Expedição motoboy')) { // se Expedição motoboy selecionado
        setState(() {
          aparecerExpedicaoMotoboy = true;
        });
      } else { // se Expedição motoboy nao selecionado
        setState(() {
          aparecerExpedicaoMotoboy = false;
        });
      }

    } else { // configuração padrao 
      setState(() {
        aparecerKDS = false;
        aparecerPedidos = false;
        aparecerExpedicaoMotoboy = false;
      });
    }
  }

  // Carregar note
  Future<void> _carregarNote() async {
    final prefs = await SharedPreferences.getInstance();
    final noteJson = prefs.getString('note_padrao');

    if (noteJson != null) {
      final notesSalvos = Set<String>.from(jsonDecode(noteJson));

      if (notesSalvos.contains('Notes')) { // se note selecionado
        setState(() {
          aparecerNote = true;
        });
      } else { // se note nao selecionado
        setState(() {
          aparecerNote = false;
        });
      }

    } else { // configuração padrao 
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

      if (recepcaosSalvos.contains('Recepção')) { // se recepcao selecionado
        setState(() {
          aparecerRecepcao = true;
        });
      } else { // se recepcao nao selecionado
        setState(() {
          aparecerRecepcao = false;
        });
      }

    } else { // configuração padrao 
      setState(() {
        aparecerRecepcao = false;
      });
    }
  }

  // Carregar Modos
  Future<void> _carregarModos() async {
    final prefs = await SharedPreferences.getInstance();
    final modoJson = prefs.getString('modo_padrao');

    if (modoJson != null) {
      final modosSalvos = Set<String>.from(jsonDecode(modoJson));

      if (modosSalvos.contains("Mesa") && !modosSalvos.contains("Comanda")) {
        setState(() {
          aparecerMapa = true;
        });
      } else if (modosSalvos.contains("Mesa") && modosSalvos.contains("Comanda")) {
        setState(() {
          aparecerMapa = true;
        });
      } else if (!modosSalvos.contains("Mesa") && modosSalvos.contains("Comanda")) {
        setState(() {
          aparecerMapa = true;
        });
      } else if(!modosSalvos.contains("Mesa") && !modosSalvos.contains("Comanda")){
          setState(() {
            aparecerMapa = false;
          });
      }
      else {
        setState(() {
          aparecerMapa = false;
        });
      }

    } else {
      setState(() {
        // Se não tiver nada salvo, define padrão
        aparecerMapa = false;
      });
    }
  }

  // Carregar check 
  Future<void> _carregarchecks() async {
    final prefs = await SharedPreferences.getInstance();
    final checkJson = prefs.getString('check_padrao');

    if (checkJson != null) {
      final checksSalvos = Set<String>.from(jsonDecode(checkJson));

      if (checksSalvos.contains("Ckeck-in") && !checksSalvos.contains("Check-out")) {
        setState(() {
          aparecerCheckIn = true;
          aparecerCheckOut = false;
        });
      } else if (checksSalvos.contains("Check-out") && !checksSalvos.contains("Ckeck-in")) {
        setState(() {
          aparecerCheckIn = false;
          aparecerCheckOut = true;
        });
      } else if (!checksSalvos.contains("Ckeck-in") && !checksSalvos.contains("Check-out")) {
        setState(() {
          aparecerCheckIn = false;
          aparecerCheckOut = false;
        });
      } else if(checksSalvos.contains("Ckeck-in") && checksSalvos.contains("Check-out")){
          setState(() {
            aparecerCheckIn = true;
            aparecerCheckOut = true;
          });
      }
      else {
        setState(() {
          aparecerCheckIn = true;
          aparecerCheckOut = true;
        });
      }

    } else {
      setState(() {
        // Se não tiver nada salvo, define padrão
        aparecerCheckIn = true;
        aparecerCheckOut = true;
      });
    }
  }

  // Carregar garçom
  Future<void> _carregargarcom() async {
    final prefs = await SharedPreferences.getInstance();
    final garcomJson = prefs.getString('garcom_padrao');

    if (garcomJson != null) {
      final garcomSalvos = Set<String>.from(jsonDecode(garcomJson));

      if (garcomSalvos.contains("Sim") && !garcomSalvos.contains("Não")) {
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
      }

    } else {
      setState(() {
        // Se não tiver nada salvo, define padrão
        aparecerGarcom = true;
      });
    }
  }

  // Função para navegar conforme navegação 
  void navegacao_inteligente() async {
    if(rotaPainelCliente){
      Get.toNamed('/painel_cliente');
    } else {
      if(aparecerGarcom){
      Get.toNamed('/garcom');
      } else if(aparecerCheckIn){
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => CheckinPage()));
      } else if(aparecerCheckOut){
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => CheckoutPage()));
      } else if (aparecerMapa){
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => MapaPage()));
      } else if(aparecerRecepcao){
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecepcaoPage()));
      } else if (aparecerNote){
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => NotesPage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível entrar na aplicação, tente novamente'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } 
  }

  @override
  Widget build(BuildContext context) {
    String? currentRoute = ModalRoute.of(context)?.settings.name;
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Icons.assignment
                  if(rotaHome)
                  ListTile(
                    leading: Icon(
                      Icons.home,
                      color: currentRoute == '/'
                          ? colorScheme.surface
                          : colorScheme.onSurface,
                    ),
                    title: Text(
                      "Home",
                      style: TextStyle(
                        color: currentRoute == '/'
                            ? colorScheme.surface
                            : colorScheme.onSurface,
                      ),
                    ),
                    selected: currentRoute == '/',
                    selectedTileColor: colorScheme.primary,
                    onTap: () {
                      navegacao_inteligente();
                      funcoesController.zerarAtendimento();
                    },
                  ),
                  if((aparecerPedidos || rotaPainelCliente) && !rotaExpedicaoMotoboy)
                  ListTile(
                    leading: Icon(
                      Icons.person,
                      color: currentRoute == '/painel_cliente'
                          ? colorScheme.surface
                          : colorScheme.onSurface,
                    ),
                    title: Text(
                      "Expedição cliente",
                      style: TextStyle(
                        color: currentRoute == '/painel_cliente'
                            ? colorScheme.surface
                            : colorScheme.onSurface,
                      ),
                    ),
                    selected: currentRoute == '/painel_cliente',
                    selectedTileColor: colorScheme.primary,
                    onTap: () async {
                      Get.toNamed('/painel_cliente');
                      funcoesController.zerarAtendimento();
                      if (Platform.isWindows) {
                        await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
                        await windowManager.setFullScreen(true);
                      }
                    },
                  ),
                  if(aparecerKDS && rotaHome)
                  ListTile(
                    leading: Icon(
                      Icons.soup_kitchen,
                      color: currentRoute == '/painel_cozinha'
                          ? colorScheme.surface
                          : colorScheme.onSurface,
                    ),
                    title: Text(
                      "KDS",
                      style: TextStyle(
                        color: currentRoute == '/painel_cozinha'
                            ? colorScheme.surface
                            : colorScheme.onSurface,
                      ),
                    ),
                    selected: currentRoute == '/painel_cozinha',
                    selectedTileColor: colorScheme.primary,
                    onTap: () {
                      Get.toNamed('/painel_cozinha');
                      funcoesController.zerarAtendimento();
                    },
                  ),  
                  if((aparecerExpedicaoMotoboy && rotaHome) || rotaExpedicaoMotoboy)
                  ListTile(
                    leading: Icon(
                      Icons.motorcycle,
                      color: currentRoute == '/expedicao_motoboy'
                          ? colorScheme.surface
                          : colorScheme.onSurface,
                    ),
                    title: Text(
                      "Expedição Motoboy",
                      style: TextStyle(
                        color: currentRoute == '/expedicao_motoboy'
                            ? colorScheme.surface
                            : colorScheme.onSurface,
                      ),
                    ),
                    selected: currentRoute == '/expedicao_motoboy',
                    selectedTileColor: colorScheme.primary,
                    onTap: () {
                      Get.toNamed('/expedicao_motoboy');
                      funcoesController.zerarAtendimento();
                    },
                  ), 
                  if(rotaHome)
                  ListTile(
                    leading: Icon(
                      Icons.print,
                      color: currentRoute == '/cupom_avulso'
                          ? colorScheme.surface
                          : colorScheme.onSurface,
                    ),
                    title: Text(
                      "Cupom Avulso",
                      style: TextStyle(
                        color: currentRoute == '/cupom_avulso'
                            ? colorScheme.surface
                            : colorScheme.onSurface,
                      ),
                    ),
                    selected: currentRoute == '/cupom_avulso',
                    selectedTileColor: colorScheme.primary,
                    onTap: () {
                      Get.toNamed('/cupom_avulso');
                      funcoesController.zerarAtendimento();
                    },
                  ), 
                  ListTile(
                    leading: Icon(
                      Icons.settings,
                      color: currentRoute == '/configuracoes'
                          ? colorScheme.surface
                          : colorScheme.onSurface,
                    ),
                    title: Text(
                      "Configurações",
                      style: TextStyle(
                        color: currentRoute == '/configuracoes'
                            ? colorScheme.surface
                            : colorScheme.onSurface,
                      ),
                    ),
                    selected: currentRoute == '/configuracoes',
                    selectedTileColor: colorScheme.primary,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConfiguracoesPage()));
                      funcoesController.zerarAtendimento();
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: currentRoute == '/configuracoes'
                          ? colorScheme.surface
                          : colorScheme.onSurface,
                    ),
                    title: Text(
                      "Sair do aplicativo",
                      style: TextStyle(
                        color: currentRoute == '/configuracoes'
                            ? colorScheme.surface
                            : colorScheme.onSurface,
                      ),
                    ),
                    selected: currentRoute == '/configuracoes',
                    selectedTileColor: colorScheme.primary,
                    // onTap: () {  // Fecha a aplicação
                    //   SystemNavigator.pop();
                    // },
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Confirmar saída"),
                            content: Text(
                              "Você tem certeza que quer sair da aplicação?",
                            ),
                            actions: <Widget>[
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        funcoesController.zerarAtendimento();
                                        SystemNavigator.pop(); // Fecha a aplicação
                                      },
                                      child: Text("Sim"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // Fecha o diálogo
                                      },
                                      child: Text("Não"),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            // Spacer(),
              isloadingProdutos ? 
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.scrim,
                    ),
                  ),
                ) : 
                Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 4.0,
                  horizontal: 8.0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (isloadingProdutos) {
                        return;
                      }

                      setState(() {
                        isloadingProdutos = true;
                      });

                      try {
                        await funcoesController.adicionaisObservacoesProdutos();
                        await funcoesController.informacoesListaGarcom();
                        await funcoesController.buscarGrupos();
                        await funcoesController.buscarProdutos();

                        await funcoesController.buscarTamanhosPizza();
                        await funcoesController.buscarSaboresBordasPizza();
                        await funcoesController.buscarGruposPizza();
                      } catch (e) {
                        setState(() {
                          isloadingProdutos = false;
                        });
                      } finally {
                        setState(() {
                          isloadingProdutos = false;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      backgroundColor: colorScheme.scrim,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Recarregar produtos',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              )
              /* Padding(
                padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 2),
                child: ElevatedButton(
                  onPressed: () async {
                    if (isloadingProdutos) {
                      return;
                    }
                    
                    setState(() {
                      isloadingProdutos = true;
                    });
                    
                    try {
                      await funcoesController.adicionaisObservacoesProdutos();
                      await funcoesController.informacoesListaGarcom();
                      await funcoesController.buscarGrupos();
                      await funcoesController.buscarProdutos();
                    } catch (e) {
                      setState(() {
                        isloadingProdutos = false;
                      });
                    } finally {
                      setState(() {
                        isloadingProdutos = false;
                      });
                    }
                    },
                    style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    backgroundColor: colorScheme.scrim,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: colorScheme.scrim,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    'Recarregar produtos',
                    style: TextStyle(color: colorScheme.onPrimary),
                  ),
                ),
              ), */
          ],
        ),
      ),
    );
  }
}

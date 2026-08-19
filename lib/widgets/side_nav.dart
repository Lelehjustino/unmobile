import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:un_recepcao/controllers/carrinho_controller.dart';
import 'package:un_recepcao/controllers/views/footer_buttons_controller.dart';
import 'package:un_recepcao/controllers/views/funcoes_controller.dart';
import 'package:un_recepcao/models/monitor.dart';
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

  final FuncoesController funcoesController = Get.put(FuncoesController());
  final CarrinhoController carrinhoController = Get.find<CarrinhoController>();
  final FooterButtonsController footerButtonsController = Get.put(FooterButtonsController());

  bool isloadingProdutos = false;

  @override
  void initState() {
    super.initState();
    carregarNavegacao();
  }

  // Carregar funções de navegação
  void carregarNavegacao() {
    footerButtonsController.carregarConfiguracoes();
  }

  // Função para navegar conforme navegação 
  void navegacao_inteligente() async {
    if(footerButtonsController.rotaPainelCliente.value){
      Get.toNamed('/painel_cliente');
    } else {
      if(footerButtonsController.aparecerGarcom.value){
      Get.toNamed('/garcom');
      } else if(footerButtonsController.aparecerCheckIn.value){
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => CheckinPage()));
      } else if(footerButtonsController.aparecerCheckOut.value){
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => CheckoutPage()));
      } else if (footerButtonsController.aparecerMapa.value){
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => MapaPage()));
      } else if(footerButtonsController.aparecerRecepcao.value){
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecepcaoPage()));
      } else if (footerButtonsController.aparecerNote.value){
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
                  if(footerButtonsController.rotaHome.value)
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
                  if((footerButtonsController.aparecerExpedicaoCliente.value || footerButtonsController.rotaPainelCliente.value) && !footerButtonsController.rotaPainelCliente.value)
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
                  if(footerButtonsController.aparecerKDS.value && footerButtonsController.rotaHome.value)
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
                  if((footerButtonsController.aparecerExpedicaoMotoboy.value && footerButtonsController.rotaHome.value) || footerButtonsController.rotaExpedicaoMotoboy.value)
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
                  if(footerButtonsController.rotaHome.value)
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

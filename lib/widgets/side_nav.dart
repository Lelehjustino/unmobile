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
import 'package:un_recepcao/controllers/views/garcom_controller.dart';
import 'package:un_recepcao/models/monitor.dart';
import 'package:un_recepcao/views/checkin_page.dart';
import 'package:un_recepcao/views/checkout_page.dart';
import 'package:un_recepcao/views/configuracoes_page.dart';
import 'package:un_recepcao/views/expedicao_motoboy_page.dart';
import 'package:un_recepcao/views/garcom_page.dart' hide Padding;
import 'package:un_recepcao/views/mapa_page.dart';
import 'package:un_recepcao/views/notes_page.dart';
import 'package:un_recepcao/views/painel_cliente.dart';
import 'package:un_recepcao/views/painel_cozinha.dart';
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
  final GarcomController garcomController = Get.find<GarcomController>();

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

  void carrinhoCheio(Widget page){
    shownDialogErrorTwoBottom(
      context: context,
      title: "Carrinho cheio!",
      message: "Deseja descartar este pedido e continuar?",
      icon: Icons.shopping_cart,
      onConfirm: () async {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
        funcoesController.zerarAtendimento();
        carrinhoController.zerarAtendimentoCarrinho();
      },
      onCancel: () async {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => GarcomPage()));
      },
    );
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
                if (textController != null) // Só mostra o TextField se um controller for fornecido
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

  Widget checkInPage(String? currentRoute, ColorScheme colorScheme){
    return ListTile(
      leading: Icon(
        Icons.login,
        color: currentRoute == '/checkin'
            ? colorScheme.surface
            : colorScheme.onSurface,
      ),
      title: Text(
        "Check-in",
        style: TextStyle(
          color: currentRoute == '/checkin'
              ? colorScheme.surface
              : colorScheme.onSurface,
        ),
      ),
      selected: currentRoute == '/checkin',
      selectedTileColor: colorScheme.primary,
      onTap: () {
        if(carrinhoController.carrinho.isNotEmpty){
          carrinhoCheio(CheckinPage());
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => CheckinPage()));
          funcoesController.zerarAtendimento();
          carrinhoController.zerarAtendimentoCarrinho();
        }
      },
    );
  }

  Widget checkOutPage(String? currentRoute, ColorScheme colorScheme){
    return ListTile(
      leading: Icon(
        Icons.logout,
        color: currentRoute == '/checkout'
            ? colorScheme.surface
            : colorScheme.onSurface,
      ),
      title: Text(
        "Check-out",
        style: TextStyle(
          color: currentRoute == '/checkout'
              ? colorScheme.surface
              : colorScheme.onSurface,
        ),
      ),
      selected: currentRoute == '/checkout',
      selectedTileColor: colorScheme.primary,
      onTap: () {
        if(carrinhoController.carrinho.isNotEmpty){
          carrinhoCheio(CheckoutPage());
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => CheckoutPage()));
          funcoesController.zerarAtendimento();
          carrinhoController.zerarAtendimentoCarrinho();
        }
      },
    );
  }

  Widget notesPage(String? currentRoute, ColorScheme colorScheme){
    return ListTile(
    leading: Icon(
      Icons.note_add_sharp,
      color: currentRoute == '/notes'
          ? colorScheme.surface
          : colorScheme.onSurface,
    ),
    title: Text(
      "Fila de espera",
      style: TextStyle(
        color: currentRoute == '/notes'
            ? colorScheme.surface
            : colorScheme.onSurface,
      ),
    ),
    selected: currentRoute == '/notes',
    selectedTileColor: colorScheme.primary,
    onTap: () {
      if(carrinhoController.carrinho.isNotEmpty){
        carrinhoCheio(NotesPage());
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => NotesPage()));
          funcoesController.zerarAtendimento();
          carrinhoController.zerarAtendimentoCarrinho();
        }
      },
    );
  }

  Widget receptionPage(String? currentRoute, ColorScheme colorScheme){
    return ListTile(
      leading: Icon(
        Icons.person,
        color: currentRoute == '/recepcao'
            ? colorScheme.surface
            : colorScheme.onSurface,
      ),
      title: Text(
        "Recepção",
        style: TextStyle(
          color: currentRoute == '/recepcao'
              ? colorScheme.surface
              : colorScheme.onSurface,
        ),
      ),
      selected: currentRoute == '/recepcao',
      selectedTileColor: colorScheme.primary,
      onTap: () {
        if(carrinhoController.carrinho.isNotEmpty){
          carrinhoCheio(RecepcaoPage());
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecepcaoPage()));
          funcoesController.zerarAtendimento();
          carrinhoController.zerarAtendimentoCarrinho();
        }
      },
    );
  }

  Widget mapPage(String? currentRoute, ColorScheme colorScheme){
    return  ListTile(
      leading: Icon(
        Icons.map,
        color: currentRoute == '/mapa'
            ? colorScheme.surface
            : colorScheme.onSurface,
      ),
      title: Text(
        "Mapa",
        style: TextStyle(
          color: currentRoute == '/mapa'
              ? colorScheme.surface
              : colorScheme.onSurface,
        ),
      ),
      selected: currentRoute == '/mapa',
      selectedTileColor: colorScheme.primary,
      onTap: () {
        if(carrinhoController.carrinho.isNotEmpty){
          carrinhoCheio(MapaPage());
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => MapaPage()));
          funcoesController.zerarAtendimento();
          carrinhoController.zerarAtendimentoCarrinho();
        }
      },
    );
  }

  Widget vendasComandaPage(String? currentRoute, ColorScheme colorScheme){
    return ListTile(
      leading: Icon(
        Icons.description,
        color: colorScheme.onSurface,
      ),
      title: Text(
        "Venda Comanda",
        style: TextStyle(
          color: colorScheme.onSurface,
        ),
      ),
      // selected: currentRoute == '/garcom',
      // selectedTileColor: colorScheme.primary,
      onTap: () {
        garcomController.retirarBalcaoRota.value = false;
        garcomController.vendaComanda.value = true;
        garcomController.vendaMesa.value = false;
        if(carrinhoController.carrinho.isNotEmpty){
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => GarcomPage()));
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => GarcomPage()));
          funcoesController.zerarAtendimento();
          carrinhoController.zerarAtendimentoCarrinho();
        }
      },
    );
  }

  Widget vendasMesaPage(String? currentRoute, ColorScheme colorScheme){
    return ListTile(
      leading: Icon(
        Icons.table_bar,
        color: colorScheme.onSurface,
      ),
      title: Text(
        "Venda Mesa",
        style: TextStyle(
          color: colorScheme.onSurface,
        ),
      ),
      //selected: currentRoute == '/garcom',
      //selectedTileColor: colorScheme.primary,
      onTap: () {
        garcomController.retirarBalcaoRota.value = false;
        garcomController.vendaComanda.value = false;
        garcomController.vendaMesa.value = true;
        if(carrinhoController.carrinho.isNotEmpty){
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => GarcomPage()));
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => GarcomPage()));
          funcoesController.zerarAtendimento();
          carrinhoController.zerarAtendimentoCarrinho();
        }
      },
    );
  }

  Widget retirarBalcao(String? currentRoute, ColorScheme colorScheme){
    return ListTile(
      leading: 
      Image.asset(
        'assets/retirada_balcao_icone.png',
        width: MediaQuery.of(context).size.width * 0.060,
        height: MediaQuery.of(context).size.width * 0.060,
        color: colorScheme.onSurface,
      ),
      /* Icon(
        Icons.room_service,
        color: colorScheme.onSurface,
      ), */
      title: Text(
        "Venda balcão",
        style: TextStyle(
          color: colorScheme.onSurface,
        ),
      ),
      //selected: currentRoute == '/garcom',
      //selectedTileColor: colorScheme.primary,
      onTap: () {
        garcomController.retirarBalcaoRota.value = true;
        if(carrinhoController.carrinho.isNotEmpty){
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => GarcomPage()));
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => GarcomPage()));
          funcoesController.zerarAtendimento();
          carrinhoController.zerarAtendimentoCarrinho();
        }
      },
    );
  }

  Widget expedicaoClientePage(String? currentRoute, ColorScheme colorScheme){
    return ListTile(
      leading: Icon(
        Icons.person,
        color: currentRoute == '/painel_cliente'
            ? colorScheme.surface
            : colorScheme.onSurface,
      ),
      title: Text(
        "Expedição Cliente",
        style: TextStyle(
          color: currentRoute == '/painel_cliente'
              ? colorScheme.surface
              : colorScheme.onSurface,
        ),
      ),
      selected: currentRoute == '/painel_cliente',
      selectedTileColor: colorScheme.primary,
      onTap: () async {
        if(carrinhoController.carrinho.isNotEmpty){
          carrinhoCheio(PainelCliente());
        } else {
          Get.toNamed('/painel_cliente');
          funcoesController.zerarAtendimento();
          carrinhoController.zerarAtendimentoCarrinho();
          if (Platform.isWindows) {
            await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
            await windowManager.setFullScreen(true);
          }
        }
      },
    );
  }

  Widget kdsPage(String? currentRoute, ColorScheme colorScheme){
    return ListTile(
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
        if(carrinhoController.carrinho.isNotEmpty){
          carrinhoCheio(PainelCozinha());
        } else {
          Get.toNamed('/painel_cozinha');
          funcoesController.zerarAtendimento();
          carrinhoController.zerarAtendimentoCarrinho();
        }
      },
    );
  }

  Widget expedicaoMotoboyPage(String? currentRoute, ColorScheme colorScheme){
    return ListTile(
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
        if(carrinhoController.carrinho.isNotEmpty){
          carrinhoCheio(ExpedicaoMotoboyPage());
        } else {
          Get.toNamed('/expedicao_motoboy');
          funcoesController.zerarAtendimento();
          carrinhoController.zerarAtendimentoCarrinho();
        }
      },
    );
  }

  Widget cupomAvulsoPage(String? currentRoute, ColorScheme colorScheme){
    return ListTile(
      leading: Icon(
        Icons.print,
        color: currentRoute == '/cupom_avulso'
            ? colorScheme.surface
            : colorScheme.onSurface,
      ),
      title: Text(
        "Cupom Avulso / Teste",
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
        carrinhoController.zerarAtendimentoCarrinho();
      },
    );
  }

  Widget configuracoesPage(String? currentRoute, ColorScheme colorScheme){
    return ListTile(
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
        if(carrinhoController.carrinho.isNotEmpty){
          carrinhoCheio(ConfiguracoesPage());
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConfiguracoesPage()));
          funcoesController.zerarAtendimento();
          carrinhoController.zerarAtendimentoCarrinho();
        }
      },
    );
  }

  Widget sairApp(String? currentRoute, ColorScheme colorScheme){
    return ListTile(
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
                          carrinhoController.zerarAtendimentoCarrinho();
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
    );
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

                  if (footerButtonsController.vendaComanda.value && footerButtonsController.rotaHome.value && funcoesController.vendaComanda.value)
                  vendasComandaPage(currentRoute, colorScheme),

                  if (footerButtonsController.vendaMesa.value && footerButtonsController.rotaHome.value && funcoesController.vendaMesa.value)
                  vendasMesaPage(currentRoute, colorScheme),

                  if(footerButtonsController.retirarBalcao.value && footerButtonsController.rotaHome.value && funcoesController.vendaBalcao.value)
                  retirarBalcao(currentRoute, colorScheme),
            
                  if (footerButtonsController.aparecerCheckIn.value && footerButtonsController.rotaHome.value)
                  checkInPage(currentRoute, colorScheme),

                  if (footerButtonsController.aparecerCheckOut.value && footerButtonsController.rotaHome.value)
                  checkOutPage(currentRoute, colorScheme),

                  if (footerButtonsController.rotaHome.value)
                  cupomAvulsoPage(currentRoute, colorScheme),

                  if ((footerButtonsController.aparecerExpedicaoCliente.value || footerButtonsController.rotaPainelCliente.value) &&(footerButtonsController.rotaHome.value || footerButtonsController.rotaPainelCliente.value))
                  expedicaoClientePage(currentRoute, colorScheme),

                  if ((footerButtonsController.aparecerExpedicaoMotoboy.value && footerButtonsController.rotaHome.value) || footerButtonsController.rotaExpedicaoMotoboy.value)
                  expedicaoMotoboyPage(currentRoute, colorScheme),

                  if (footerButtonsController.aparecerKDS.value && footerButtonsController.rotaHome.value)
                  kdsPage(currentRoute, colorScheme),

                  if (footerButtonsController.aparecerMapa.value && footerButtonsController.rotaHome.value)
                  mapPage(currentRoute, colorScheme),

                  if (footerButtonsController.aparecerNote.value && footerButtonsController.rotaHome.value)
                  notesPage(currentRoute, colorScheme),

                  if (footerButtonsController.aparecerRecepcao.value && footerButtonsController.rotaHome.value)
                  receptionPage(currentRoute, colorScheme),

                  configuracoesPage(currentRoute, colorScheme),
                  
                  sairApp(currentRoute, colorScheme),
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

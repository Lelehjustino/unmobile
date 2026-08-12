import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:un_recepcao/services/remote_config_service.dart';
import 'package:un_recepcao/views/cupom_avulso_page.dart';
import 'package:un_recepcao/views/fechar_page.dart';

import 'firebase_options.dart';

import 'package:un_recepcao/controllers/carrinho_controller.dart';
import 'package:un_recepcao/controllers/views/garcom_controller.dart';
import 'package:un_recepcao/controllers/zerar_atendimento.dart';
import 'package:un_recepcao/controllers/comanda_carrinho.dart';
import 'package:un_recepcao/controllers/connectivity_controller.dart';
import 'package:un_recepcao/services/servicoNotificacao.dart';

import 'package:un_recepcao/views/carrinho_comandas_page.dart';
import 'package:un_recepcao/views/checkin_page.dart';
import 'package:un_recepcao/views/checkout_page.dart';
import 'package:un_recepcao/views/configuracoes_page.dart';
import 'package:un_recepcao/views/expedicao_motoboy_page.dart';
import 'package:un_recepcao/views/garcom_page.dart';
import 'package:un_recepcao/views/inicial_page.dart';
import 'package:un_recepcao/views/mapa_page.dart';
import 'package:un_recepcao/views/notes_page.dart';
import 'package:un_recepcao/views/painel_cliente.dart';
import 'package:un_recepcao/views/painel_cozinha.dart';
import 'package:un_recepcao/views/pizza_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:un_recepcao/views/recepcao_page.dart';
import 'package:un_recepcao/views/splash_page.dart';
import 'package:un_recepcao/views/force_update_screen.dart';
import 'package:un_recepcao/views/maintenance_screen.dart';
import 'package:un_recepcao/views/visualizar_comandas_mesa_page.dart';

// projeto versao com app Apple

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await RemoteConfigService.instance.initialize();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  try {
    await dotenv.load(fileName: "arquivos.env");
  } catch (e) {
    print("Erro ao carregar env: $e");
  }

  Get.put(ConnectivityController(), permanent: true); // UDP monitoring — deve ser o PRIMEIRO
  Get.put(CarrinhoController(), permanent: true);
  Get.put(ComandaCarrinhoController(), permanent: true);
  Get.put(ZerarAtendimentoController(), permanent: true);
  Get.put(GarcomController(), permanent: true);

  ServicoNotificacao.configurarAudio();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  //late final _LifecycleHandler _lifecycleHandler;

  @override
  void initState() {
    super.initState();
    //_lifecycleHandler = _LifecycleHandler();
    //WidgetsBinding.instance.addObserver(_lifecycleHandler);
  }

  @override
  void dispose() {
    //WidgetsBinding.instance.removeObserver(_lifecycleHandler);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nubi PDV',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: const Color.fromRGBO(76, 175, 80, 1),
              brightness: Brightness.light,
            ).copyWith(
              primary: const Color.fromRGBO(87, 154, 146, 1),
              onPrimary: Colors.white,
              primaryContainer: const Color.fromRGBO(87, 154, 146, 0.85),
              primaryFixed: const Color.fromARGB(255, 72, 160, 75),
              secondary: const Color.fromRGBO(173, 216, 208, 1.0),
              onSecondary: Colors.black,
              tertiary: const Color.fromRGBO(255, 216, 99, 1),
              onTertiary: const Color.fromRGBO(249, 248, 245, 1),
              surface: Colors.white,
              onSurface: Colors.black,
              error: Colors.red,
              surfaceDim: const Color.fromRGBO(155, 155, 155, 0.85),
              shadow: const Color.fromRGBO(1, 132, 152, 1),
              scrim: const Color.fromRGBO(243, 153, 48, 1),
              surfaceTint: const Color.fromARGB(193, 196, 191, 191),
              outline: const Color.fromARGB(255, 185, 93, 114),
              outlineVariant: const Color.fromRGBO(55, 55, 55, 0.843),
            ),
      ),
      initialRoute: '/splash',

      getPages: [
        GetPage(
          name: '/expedicao_motoboy',
          page: () => ExpedicaoMotoboyPage(),
        ),
        GetPage(
          name: '/painel_cliente',
          page: () => PainelCliente(),
        ), 
        GetPage(
          name: '/painel_cozinha',
          page: () => PainelCozinha(),
        ),
        GetPage(
          name: '/',
          page: () => CheckinPage(),
        ),
        GetPage(
          name: '/checkin',
          page: () => CheckinPage(),
        ),
        GetPage(
          name: '/configuracoes',
          page: () => ConfiguracoesPage(),
        ),
        GetPage(name: '/inicial', page: () => InicialPage()),
        GetPage(
          name: '/pizza',
          page: () => PizzaPage(),
        ),
        GetPage(
          name: '/garcom',
          page: () => GarcomPage(),
        ),
        GetPage(
          name: '/carrinho_comandas',
          page: () => CarrinhoComandasPage(),
        ),
        GetPage(name: '/mapa', page: () => MapaPage()),
        GetPage(name: '/splash', page: () => SplashPage()),
        GetPage(name: '/recepcao', page: () => RecepcaoPage()),
        GetPage(name: '/notes', page: () => NotesPage()),
        GetPage(name: '/checkout', page: () => CheckoutPage()),
        GetPage(name: '/cupom_avulso', page: () => CupomAvulsoPage()),
        GetPage(name: '/visualizar_comandas_mesa', page: () => VisualizarComandasMesaPage()),
        GetPage(
          name: '/force_update',
          page: () {
            final args = Get.arguments as Map<String, dynamic>? ?? {};
            return ForceUpdateScreen(
              minimumVersion: args['minimumVersion'] ?? '0.0.0',
              installedVersion: args['installedVersion'] ?? '0.0.0',
              storeUrlAndroid: args['storeUrlAndroid'] ?? '',
              storeUrlIos: args['storeUrlIos'] ?? '',
            );
          },
        ),
        GetPage(
          name: '/maintenance',
          page: () => const MaintenanceScreen(),
        ),
        GetPage(
          name: '/fechar',
          page: () => FecharPage(),
        ),
      ],
    );
  }
}

// class _LifecycleHandler with WidgetsBindingObserver {
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     // Quando o app é minimzado
//     if (state == AppLifecycleState.paused) {
//       Connection.enterProtected();
//       print('App minimizado - Navegação e reconexão BLOQUEADAS');
//     }

//     // Quando o app é fachado
//     if (state == AppLifecycleState.inactive) {
//       Connection.enterProtected();
//       print('App fechado - Navegação e reconexão BLOQUEADAS');
//     }

//     // Volto a usar o app após fechado ou minimizado
//     if (state == AppLifecycleState.resumed) {
//       Connection.volteiApp();

//       // Connection.enterProtected();

//       // Future.delayed(const Duration(seconds: 10), () {
//       //   Connection.exitProtected();
//       //   print('Sistema LIBERADO após 5 segundo');
//       // });
//       // print('App ativo novamente - Navegação liberada');
//     }
//   }
// }

/// Widget que impede rotação e mostra alerta se o usuário girar a tela
class OrientationRestrictedPage extends StatelessWidget {
  final Widget child;

  const OrientationRestrictedPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // impede botão voltar
        return false;
      },
      child: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: AlertDialog(
                  title: const Text('Aviso'),
                  content: const Text('Você não pode girar a tela.'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),
            );
          }
          return child;
        },
      ),
    );
  }
}

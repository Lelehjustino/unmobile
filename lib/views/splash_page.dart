import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:un_recepcao/controllers/views/painel_controller.dart';
import 'package:un_recepcao/models/update_status.dart';
import 'package:un_recepcao/services/update_service.dart';
import 'package:un_recepcao/widgets/update_dialog.dart';

/// SplashPage — ponto de entrada do aplicativo.
///
/// Responsabilidades:
///   1. Exibir a tela de carregamento (branding)
///   2. Executar a verificação de versão (UpdateService)
///   3. Navegar para a tela correta com base no resultado
///
/// Fluxo:
///   ┌───────────────────────────────────────┐
///   │             SplashPage                │
///   │                                       │
///   │  1. Exibe logo + loading              │
///   │  2. UpdateService.checkForUpdate()    │
///   │  3. Avalia UpdateCheckResult          │
///   │                                       │
///   │  maintenance?  → /maintenance         │
///   │  forceUpdate?  → /force_update        │
///   │  optionalUpdate? → Dialog → /inicial  │
///   │  upToDate?     → /inicial             │
///   └───────────────────────────────────────┘
///
/// Tratamento de erros:
///   Se checkForUpdate() falhar (sem internet, Firebase fora, timeout),
///   retorna UpdateCheckResult.fallback() com status upToDate.
///   O app continua normalmente — nunca bloqueia por falha de infra.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final PainelController painelController = Get.put(PainelController());

  @override
  void initState() {
    super.initState();
    painelController.estaNoPainelCozinha.value = false;
    _init();
  }

  Future<void> _init() async {
    // Tempo mínimo de exibição da splash para UX
    // (evita flash rápido demais na tela)
    final minDisplayFuture = Future.delayed(const Duration(seconds: 2));

    // Verificação de versão em paralelo com o delay
    final updateFuture = UpdateService.instance.checkForUpdate();

    // Aguarda ambos (whichever for mais lento)
    final results = await Future.wait([minDisplayFuture, updateFuture]);
    final result = results[1] as dynamic;

    if (!mounted) return;

    // ─── Decisão de navegação baseada no status ───
    switch (result.status as UpdateStatus) {
      case UpdateStatus.maintenance:
        // Bloqueia tudo — backend indisponível
        Get.offAllNamed('/maintenance');
        break;

      case UpdateStatus.forceUpdate:
        // Bloqueia — versão incompatível ou kill switch ativo
        Get.offAllNamed(
          '/force_update',
          arguments: {
            'minimumVersion': result.minimumVersion,
            'installedVersion': result.installedVersion,
            'storeUrlAndroid': result.storeUrlAndroid,
            'storeUrlIos': result.storeUrlIos,
          },
        );
        break;

      case UpdateStatus.optionalUpdate:
        // Exibe dialog — após fechar, vai para /inicial
        await UpdateDialog.show(
          context,
          installedVersion: result.installedVersion,
          latestVersion: result.latestVersion,
          updateNotes: result.updateNotes,
          storeUrlAndroid: result.storeUrlAndroid,
          storeUrlIos: result.storeUrlIos,
          onDismiss: () {
            // Usuário escolheu "Lembrar depois"
            if (mounted) {
              Get.offAllNamed('/inicial');
            }
          },
        );
        break;

      case UpdateStatus.upToDate:
        // Tudo ok — segue para a Home
        Get.offAllNamed('/inicial');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(84, 134, 135, 1),
              Color.fromRGBO(84, 134, 135, 1),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  const Spacer(flex: 3),

                  // Logo/Ícone
                  Container(
                    padding: const EdgeInsets.all(0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                    ),
                    child: Image.asset(
                      'assets/app_icon2.png',
                      height: constraints.maxHeight * 0.15,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Título principal
                  Text(
                    'UnMobile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: constraints.maxHeight * 0.045,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Mensagem acolhedora
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        const Text(
                          textAlign: TextAlign.center,
                          'Bem-vindo de volta!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Estamos preparando tudo para você...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Indicador de carregamento
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),

                  const Spacer(flex: 3),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

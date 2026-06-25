import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:un_recepcao/controllers/views/painel_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
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
    // Simulando carregamento inicial
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Get.offAllNamed('/inicial');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // color: Color.fromRGBO(84, 134, 135, 1),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(84, 134, 135, 1),
              Color.fromRGBO(84, 134, 135, 1),
              // Color.fromRGBO(55, 95, 96, 1),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  const Spacer(flex: 3),

                  // Logo/Ícone com um leve fundo circular para destaque
                  Container(
                    padding: EdgeInsets.all(0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      // shape: BoxShape.circle,
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
                        Text(
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

                  // Indicador de carregamento polido
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Informação de versão no rodapé
                  /* Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      'v1.0.0',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ), */
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

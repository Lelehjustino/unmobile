import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:un_recepcao/utils/platform_update.dart';

class FecharPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // WillPopScope com onWillPop retornando false bloqueia:
    //   - Botão voltar físico (Android)
    //   - Gesto de swipe back (iOS)
    //   - Navigator.pop() programático
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromRGBO(84, 134, 135, 1),
                Color.fromRGBO(65, 110, 111, 1),
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // ─── Ícone ───
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.system_update_rounded,
                          size: constraints.maxHeight * 0.08,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ─── Título ───
                      Text(
                        'Fechar o app para atualizar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: constraints.maxHeight * 0.032,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ─── Botão Atualizar ───
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => _fecharApp(),
                          icon: const Icon(
                            Icons.refresh,
                            color: Color.fromRGBO(84, 134, 135, 1),
                          ),
                          label: Text(
                            'FECHAR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color.fromRGBO(84, 134, 135, 1),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor:
                                const Color.fromRGBO(84, 134, 135, 1),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),

                      // ─── Rodapé informativo ───
                      Text(
                        'Após atualizar, abra o aplicativo novamente.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _fecharApp() {
   SystemNavigator.pop(); 
   exit(0);
  }
}
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:un_recepcao/utils/platform_update.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tela de atualização obrigatória.
///
/// Exibida quando:
///   - force_update = true no Remote Config (kill switch)
///   - A versão instalada é MENOR que minimum_version
///
/// Comportamento:
///   - Bloqueia completamente o app
///   - Sem botão voltar (WillPopScope retorna false)
///   - Sem botão cancelar
///   - Único caminho: pressionar "Atualizar" → abre a loja
///
/// Arquitetura:
///   SplashPage ──→ ForceUpdateScreen ──→ PlatformUpdate.openStore()
///                                             │
///                                    Google Play / App Store
///
/// Design:
///   Segue o padrão visual do app (cor primária da splash).
///   Usa ícone, título, descrição e botão centralizado.
class ForceUpdateScreen extends StatelessWidget {
  /// Versão mínima exigida — exibida na mensagem.
  final String minimumVersion;

  /// Versão atualmente instalada — exibida na mensagem.
  final String installedVersion;

  /// URL personalizada do Google Play (do Remote Config).
  final String storeUrlAndroid;

  /// URL personalizada da App Store (do Remote Config).
  final String storeUrlIos;

  const ForceUpdateScreen({
    super.key,
    required this.minimumVersion,
    required this.installedVersion,
    this.storeUrlAndroid = '',
    this.storeUrlIos = '',
  });

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
                        'Atualização Necessária',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: constraints.maxHeight * 0.032,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ─── Descrição ───
                      Text(
                        'Uma nova versão do aplicativo é obrigatória '
                        'para continuar utilizando o sistema.\n\n'
                        'Versão instalada: $installedVersion\n'
                        'Versão mínima: $minimumVersion',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),

                      const Spacer(flex: 1),

                      // ─── Botão Atualizar ───
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => _onUpdatePressed(),
                          icon: const Icon(
                            Icons.download_rounded,
                            color: Color.fromRGBO(84, 134, 135, 1),
                          ),
                          label: const Text(
                            'Atualizar Agora',
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

  /// Abre a loja correspondente à plataforma.
  void _onUpdatePressed() {
    PlatformUpdate.openStore(
      customAndroidUrl: storeUrlAndroid,
      customIosUrl: storeUrlIos,
    );
    Get.offAllNamed('/fechar');
  }
}

class PlatformUpdate {
  static Future<void> openStore({
    String? customAndroidUrl,
    String? customIosUrl,
    String? customMacOsUrl,
  }) async {
    String? urlString;

    // 1. Prioridade para URLs customizadas enviadas via Firebase / Parâmetros
    if (Platform.isAndroid && customAndroidUrl != null && customAndroidUrl.isNotEmpty) {
      urlString = customAndroidUrl;
    } else if (Platform.isIOS && customIosUrl != null && customIosUrl.isNotEmpty) {
      urlString = customIosUrl;
    } else if (Platform.isMacOS && customMacOsUrl != null && customMacOsUrl.isNotEmpty) {
      urlString = customMacOsUrl;
    } else {
      // 2. Fallbacks padrão das lojas de acordo com a plataforma
      if (Platform.isAndroid) {
        // Formato para abrir diretamente no app da Google Play Store
        // Substitua 'com.seuempresa.seuapp' pelo Package Name real do seu app
        final packageInfo = await PackageInfo.fromPlatform();
        final packageName = packageInfo.packageName; // Retorna "com.un.recepcao" automaticamente
        urlString = 'market://details?id=$packageName';
      } else if (Platform.isIOS) {
        // Substitua 'id123456789' pelo seu ID numérico de App Store
        urlString = 'https://apps.apple.com/app/id6761431507';
      } else if (Platform.isMacOS) {
        // Para Mac App Store
        urlString = 'macappstore://apps.apple.com/app/id6761431507';
      }
    }

    if (urlString == null) return;

    final uri = Uri.parse(urlString);

    try {
      // Tenta abrir no app nativo da loja
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      // Fallback para Android em browsers caso market:// falhe
      if (!launched && Platform.isAndroid && urlString.startsWith('market://')) {
        const packageName = 'com.un.recepcao';
        final webUri = Uri.parse('https://play.google.com/store/apps/details?id=$packageName');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erro ao tentar abrir a loja: $e');
    }
  }
}

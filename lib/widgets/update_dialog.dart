import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:un_recepcao/utils/platform_update.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dialog de atualização opcional.
///
/// Exibido quando:
///   - UpdateStatus == optionalUpdate
///   - Versão instalada < latest_version
///   - Versão instalada >= minimum_version (senão seria forceUpdate)
///
/// Comportamento:
///   - "Atualizar" → abre a loja (Google Play / App Store)
///   - "Lembrar depois" → fecha o dialog e segue para a Home
///   - Notas da versão são exibidas quando disponíveis
///
/// Por que um Widget separado (SRP)?
///   - Isola a lógica e UI do dialog
///   - Facilita reutilização (pode ser chamado de qualquer lugar)
///   - Facilita testes de widget
class UpdateDialog extends StatelessWidget {
  /// Versão atualmente instalada.
  final String installedVersion;

  /// Última versão disponível nas lojas.
  final String latestVersion;

  /// Notas da versão / changelog. Vazio se não houver.
  final String updateNotes;

  /// URL personalizada do Google Play (do Remote Config).
  final String storeUrlAndroid;

  /// URL personalizada da App Store (do Remote Config).
  final String storeUrlIos;

  /// Callback chamado quando o usuário escolhe "Lembrar depois".
  final VoidCallback onDismiss;

  const UpdateDialog({
    super.key,
    required this.installedVersion,
    required this.latestVersion,
    required this.updateNotes,
    required this.onDismiss,
    this.storeUrlAndroid = '',
    this.storeUrlIos = '',
  });

  /// Exibe o dialog como overlay na tela atual.
  ///
  /// Uso:
  ///   await UpdateDialog.show(context, result: ..., onDismiss: ...);
  ///
  /// barrierDismissible = false → obriga o usuário a escolher.
  /// Ele pode ignorar clicando em "Lembrar depois", mas não pode
  /// simplesmente tocar fora para fechar.
  static Future<void> show(
    BuildContext context, {
    required String installedVersion,
    required String latestVersion,
    required String updateNotes,
    required VoidCallback onDismiss,
    String storeUrlAndroid = '',
    String storeUrlIos = '',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateDialog(
        installedVersion: installedVersion,
        latestVersion: latestVersion,
        updateNotes: updateNotes,
        onDismiss: onDismiss,
        storeUrlAndroid: storeUrlAndroid,
        storeUrlIos: storeUrlIos,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = const Color.fromRGBO(84, 134, 135, 1);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),

      // ─── Ícone de cabeçalho ───
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.system_update_rounded,
          size: 36,
          color: primaryColor,
        ),
      ),

      // ─── Título ───
      title: const Text(
        'Nova Versão Disponível',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      // ─── Conteúdo ───
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informação de versão
          Center(
            child: Text(
              '$installedVersion → $latestVersion',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Notas da versão (se existirem)
          if (updateNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const SizedBox(height: 8),
            // Container com scroll para notas longas
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Text(
                  updateNotes,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),

      // ─── Botões de ação ───
      actions: [
        // Botão "Lembrar depois" (secundário)
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss();
          },
          child: Text(
            'Lembrar depois',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Botão "Atualizar" (primário)
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            PlatformUpdate.openStore(
              customAndroidUrl: storeUrlAndroid,
              customIosUrl: storeUrlIos,
            );
            Get.offAllNamed('/fechar');
          },
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text(
            'Atualizar',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
      ],
    );
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
        final packageInfo = await PackageInfo.fromPlatform();
        final packageName = packageInfo.packageName; // Retorna "com.un.recepcao" automaticamente
        final webUri = Uri.parse('https://play.google.com/store/apps/details?id=$packageName');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erro ao tentar abrir a loja: $e');
    }
  }
}

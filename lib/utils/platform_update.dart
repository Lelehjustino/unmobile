import 'dart:io';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Classe utilitária para abrir a loja de atualização correta
/// de acordo com a plataforma (Android / iOS).
///
/// Responsabilidades:
///   1. Detectar a plataforma em tempo de execução
///   2. No Android: tentar In-App Update (via MethodChannel), senão abre Google Play
///   3. No iOS: abrir a App Store
///   4. Suportar URLs personalizadas vindas do Remote Config
///
/// Arquitetura:
///   ForceUpdateScreen / UpdateDialog
///               │
///       PlatformUpdate.openStore()
///               │
///       ┌───────┴───────┐
///       │               │
///    Android           iOS
///       │               │
///    In-App Update   App Store URL
///    (ou Google Play)
///
/// Por que uma classe separada?
///   - Isola lógica de plataforma (SRP)
///   - Facilita testes (pode ser mockada)
///   - Ponto único de mudança se o mecanismo de atualização mudar
class PlatformUpdate {
  const PlatformUpdate._();

  /// Package name do app Android.
  /// Usado para construir a URL padrão do Google Play.
  /// IMPORTANTE: Altere para o package name do SEU aplicativo.
  static const String _androidPackageName = 'com.unMobile.un_recepcao';

  /// Apple ID do app na App Store.
  /// Usado para construir a URL padrão da App Store.
  /// IMPORTANTE: Altere para o Apple ID do SEU aplicativo.
  /// Encontre em App Store Connect → App Information → Apple ID.
  static const String _appleAppId = 'SEU_APPLE_ID_AQUI';

  /// Canal de comunicação com código nativo Android.
  /// Usado para tentar o In-App Update via Google Play.
  ///
  /// O nome do canal deve ser único e seguir a convenção
  /// reversa do package name para evitar conflitos.
  static const MethodChannel _channel =
      MethodChannel('com.unMobile.un_recepcao/in_app_update');

  /// Abre a loja correspondente à plataforma.
  ///
  /// Parâmetros:
  ///   [customAndroidUrl] — URL personalizada do Google Play (do Remote Config).
  ///                        Se vazia, usa a URL padrão.
  ///   [customIosUrl] — URL personalizada da App Store (do Remote Config).
  ///                    Se vazia, usa a URL padrão.
  ///
  /// Fluxo Android:
  ///   1. Tenta In-App Update (immediate) via MethodChannel
  ///   2. Se falhar, abre a URL do Google Play no navegador
  ///
  /// Fluxo iOS:
  ///   1. Abre a URL da App Store no navegador/app
  ///
  /// Tratamento de erros:
  ///   Se tudo falhar, a exceção é capturada e logada.
  ///   O app não crasha — o usuário vê a tela de ForceUpdate
  ///   e pode tentar novamente manualmente.
  static Future<void> openStore({
    String customAndroidUrl = '',
    String customIosUrl = '',
  }) async {
    try {
      if (Platform.isAndroid) {
        await _openAndroidStore(customAndroidUrl);
      } else if (Platform.isIOS) {
        await _openIosStore(customIosUrl);
      }
    } catch (e) {
      print('[PlatformUpdate] Erro ao abrir a loja: $e');
    }
  }

  /// Tenta atualizar via In-App Update (Android) ou abre a Google Play.
  ///
  /// In-App Update (Immediate):
  ///   - Tela de atualização NATIVA do Google Play dentro do app
  ///   - Usuário não sai do app durante a atualização
  ///   - Requer integração nativa via MethodChannel
  ///
  /// Fallback (Google Play URL):
  ///   - Se o In-App Update não estiver disponível ou falhar
  ///   - Abre a página do app na Google Play Store
  ///   - Funciona em 100% dos casos
  static Future<void> _openAndroidStore(String customUrl) async {
    // Tenta In-App Update (necessário código nativo configurado)
    try {
      final bool available = await _channel.invokeMethod('checkForUpdate');
      if (available) {
        await _channel.invokeMethod('startImmediateUpdate');
        return; // Sucesso — In-App Update foi iniciado
      }
    } on PlatformException catch (e) {
      print('[PlatformUpdate] In-App Update indisponível: ${e.message}');
    } on MissingPluginException {
      // MethodChannel não configurado no lado nativo — usa fallback
      print('[PlatformUpdate] In-App Update não configurado, usando fallback');
    } catch (e) {
      print('[PlatformUpdate] Erro no In-App Update: $e');
    }

    // Fallback: abre a Google Play Store
    final url = customUrl.isNotEmpty
        ? customUrl
        : 'https://play.google.com/store/apps/details?id=$_androidPackageName';

    await _launchUrl(url);
  }

  /// Abre a Apple App Store.
  ///
  /// No iOS, não existe In-App Update nativo.
  /// A única opção é direcionar o usuário para a App Store.
  ///
  /// A URL usa o formato "itms-apps://" que abre diretamente
  /// o app da App Store ao invés do navegador, proporcionando
  /// uma experiência mais fluida.
  static Future<void> _openIosStore(String customUrl) async {
    final url = customUrl.isNotEmpty
        ? customUrl
        : 'https://apps.apple.com/app/id$_appleAppId';

    await _launchUrl(url);
  }

  /// Abre uma URL no navegador/app externo.
  ///
  /// Usa [url_launcher] para abrir URLs de forma segura.
  /// Se a URL não puder ser aberta, loga o erro e retorna.
  static Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      print('[PlatformUpdate] Não foi possível abrir: $url');
    }
  }

  /// Tenta iniciar um Flexible Update (Android).
  ///
  /// Flexible Update:
  ///   - Download acontece em background
  ///   - Usuário continua usando o app normalmente
  ///   - Quando o download termina, exibe "Reiniciar para atualizar"
  ///
  /// Usado no dialog de atualização OPCIONAL.
  /// Se não funcionar, cai no fallback (abre Google Play).
  static Future<bool> tryFlexibleUpdate() async {
    if (!Platform.isAndroid) return false;

    try {
      final bool available = await _channel.invokeMethod('checkForUpdate');
      if (available) {
        final bool started =
            await _channel.invokeMethod('startFlexibleUpdate');
        return started;
      }
    } on PlatformException catch (e) {
      print('[PlatformUpdate] Flexible Update falhou: ${e.message}');
    } on MissingPluginException {
      print('[PlatformUpdate] Flexible Update não configurado');
    } catch (e) {
      print('[PlatformUpdate] Erro no Flexible Update: $e');
    }

    return false;
  }

  /// Completa a instalação de um Flexible Update (Android).
  ///
  /// Chamado após o download do Flexible Update terminar.
  /// Reinicia o app com a nova versão instalada.
  static Future<void> completeFlexibleUpdate() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('completeFlexibleUpdate');
    } catch (e) {
      print('[PlatformUpdate] Erro ao completar Flexible Update: $e');
    }
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Serviço responsável por gerenciar o Firebase Remote Config.
///
/// Encapsula:
///   1. Inicialização do Firebase
///   2. Configuração de defaults, cache e timeout
///   3. Fetch e Activate dos parâmetros remotos
///   4. Leitura segura dos valores com fallback
///   5. Tratamento completo de erros
///
/// Arquitetura:
///   RemoteConfigService ──→ Firebase Remote Config (nuvem)
///        ↓
///   UpdateService (consome os valores)
///
/// Se o Firebase estiver indisponível, os valores padrão (defaults)
/// são utilizados, garantindo que o app NUNCA bloqueie o usuário
/// por falha de infraestrutura.
class RemoteConfigService {
  RemoteConfigService._();

  static final RemoteConfigService _instance = RemoteConfigService._();

  /// Singleton — garante uma única instância em toda a aplicação.
  /// Motivo: Remote Config deve manter um estado consistente;
  /// múltiplas instâncias causariam race conditions no fetch/activate.
  static RemoteConfigService get instance => _instance;

  FirebaseRemoteConfig? _remoteConfig;

  /// Flag que indica se a inicialização foi bem-sucedida.
  bool _isInitialized = false;

  /// Valores padrão utilizados quando:
  ///   - Firebase está offline
  ///   - Primeiro uso do app (sem cache)
  ///   - Parâmetro não existe no console
  ///   - Qualquer exceção durante o fetch
  ///
  /// IMPORTANTE: Esses defaults permitem que o app funcione normalmente
  /// mesmo sem conexão com o Firebase. O princípio "fail-open" garante
  /// que o usuário nunca fique bloqueado por falha de infraestrutura.
  static const Map<String, dynamic> _defaults = {
    'latest_version': '0.0.0',
    'minimum_version': '0.0.0',
    'force_update': false,
    'maintenance': false,
    'update_notes': '',
    'store_url_android': '',
    'store_url_ios': '',
  };

  /// Inicializa o Firebase e o Remote Config.
  ///
  /// Configurações de cache e timeout:
  ///   - fetchTimeout: 15s — tempo máximo para buscar dados remotos
  ///   - minimumFetchInterval: 5min — evita chamadas excessivas ao servidor
  ///     Em PRODUÇÃO, recomenda-se 12h (Duration(hours: 12)).
  ///     Em DEBUG, 5min permite testar mudanças rapidamente.
  ///
  /// O método é idempotente: chamar múltiplas vezes não causa erro.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Inicializa o Firebase (necessário antes de qualquer serviço Firebase)
      await Firebase.initializeApp();

      // 2. Obtém a instância do Remote Config
      _remoteConfig = FirebaseRemoteConfig.instance;

      // 3. Configura timeout e intervalo de cache
      /* await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 15),
          // Em produção, use Duration(hours: 12)
          // Em debug, 5 minutos para testar mudanças rápidas
          minimumFetchInterval: const Duration(minutes: 5),
        ),
      ); */
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 15),
          // Zera o cache para garantir que cada 'flutter run' busque os dados atualizados
          minimumFetchInterval: Duration.zero,
        ),
      );

      // 4. Define valores padrão (fallback)
      await _remoteConfig!.setDefaults(_defaults);

      // 5. Busca e ativa os valores remotos em uma única operação
      //    fetchAndActivate() = fetch() + activate() juntos
      //    Retorna true se os valores foram atualizados
      await _remoteConfig!.fetchAndActivate();

      print('=== REMOTE CONFIG LOADED ===');
      print('Latest Version no Firebase: ${latestVersion}');
      print('Minimum Version no Firebase: ${minimumVersion}');

      // 6. (Opcional) Escuta mudanças em tempo real
      //    Quando você altera um valor no Firebase Console,
      //    o app recebe a atualização sem precisar reiniciar.
      _remoteConfig!.onConfigUpdated.listen(
        (RemoteConfigUpdate event) async {
          await _remoteConfig!.activate();
        },
        onError: (error) {
          // Silencia erros de realtime — não é crítico
          print('[RemoteConfig] Erro no listener em tempo real: $error');
        },
      );

      _isInitialized = true;
    } on FirebaseException catch (e) {
      // Firebase específico: credenciais inválidas, projeto não encontrado, etc.
      print('[RemoteConfig] Erro Firebase: ${e.message}');
      _isInitialized = false;
    } catch (e) {
      // Qualquer outro erro: sem internet, timeout, etc.
      print('[RemoteConfig] Erro inesperado na inicialização: $e');
      _isInitialized = false;
    }
  }

  // ─────────────────────────────────────────────
  // Getters seguros — sempre retornam um valor válido
  // ─────────────────────────────────────────────

  /// Última versão publicada nas lojas.
  /// Usada para exibir dialog de atualização opcional.
  ///
  /// Exemplo no Firebase Console: "2.0.0"
  String get latestVersion {
    return _getString('latest_version', '0.0.0');
  }

  /// Versão mínima aceitável.
  /// Se a versão instalada for MENOR que essa, o app bloqueia.
  ///
  /// Exemplo no Firebase Console: "1.8.0"
  String get minimumVersion {
    return _getString('minimum_version', '0.0.0');
  }

  /// Kill switch — força atualização independente da versão.
  ///
  /// Exemplo: vulnerabilidade crítica descoberta → force_update = true
  bool get forceUpdate {
    return _getBool('force_update', false);
  }

  /// Flag de manutenção — bloqueia todo o app.
  ///
  /// Exemplo: migração de banco em andamento → maintenance = true
  bool get maintenance {
    return _getBool('maintenance', false);
  }

  /// Notas da versão (changelog resumido).
  /// Exibidas no dialog de atualização opcional.
  ///
  /// Exemplo: "• Novo sistema de pagamento\n• Correção de bugs"
  String get updateNotes {
    return _getString('update_notes', '');
  }

  /// URL personalizada da Google Play (caso queira sobrescrever a padrão).
  String get storeUrlAndroid {
    return _getString('store_url_android', '');
  }

  /// URL personalizada da App Store (caso queira sobrescrever a padrão).
  String get storeUrlIos {
    return _getString('store_url_ios', '');
  }

  // ─────────────────────────────────────────────
  // Métodos privados de leitura segura
  // ─────────────────────────────────────────────

  /// Lê uma String do Remote Config com fallback.
  ///
  /// Se o Remote Config não estiver inicializado ou o parâmetro
  /// não existir, retorna [defaultValue].
  String _getString(String key, String defaultValue) {
    if (!_isInitialized || _remoteConfig == null) return defaultValue;

    try {
      final value = _remoteConfig!.getString(key);
      // Remote Config retorna string vazia quando o parâmetro não existe
      return value.isNotEmpty ? value : defaultValue;
    } catch (e) {
      print('[RemoteConfig] Erro ao ler "$key": $e');
      return defaultValue;
    }
  }

  /// Lê um bool do Remote Config com fallback.
  ///
  /// Se o Remote Config não estiver inicializado ou o parâmetro
  /// não existir, retorna [defaultValue].
  bool _getBool(String key, bool defaultValue) {
    if (!_isInitialized || _remoteConfig == null) return defaultValue;

    try {
      return _remoteConfig!.getBool(key);
    } catch (e) {
      print('[RemoteConfig] Erro ao ler "$key": $e');
      return defaultValue;
    }
  }


}

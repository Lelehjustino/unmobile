import 'package:package_info_plus/package_info_plus.dart';

import 'package:un_recepcao/models/update_status.dart';
import 'package:un_recepcao/services/remote_config_service.dart';
import 'package:un_recepcao/services/version_comparator.dart';

/// Resultado completo da verificação de versão.
///
/// Contém todas as informações que a UI precisa para:
///   - Decidir qual tela exibir (Home, ForceUpdate, Maintenance)
///   - Exibir o dialog de atualização opcional
///   - Abrir a loja correta (Google Play / App Store)
///   - Exibir notas da versão
class UpdateCheckResult {
  /// Status da verificação (upToDate, optionalUpdate, forceUpdate, maintenance).
  final UpdateStatus status;

  /// Versão atualmente instalada no dispositivo.
  final String installedVersion;

  /// Última versão disponível nas lojas (do Remote Config).
  final String latestVersion;

  /// Versão mínima aceitável (do Remote Config).
  final String minimumVersion;

  /// Notas da versão / changelog (do Remote Config).
  final String updateNotes;

  /// URL personalizada da loja Android (do Remote Config).
  /// Vazia = usa a URL padrão do Google Play.
  final String storeUrlAndroid;

  /// URL personalizada da loja iOS (do Remote Config).
  /// Vazia = usa a URL padrão da App Store.
  final String storeUrlIos;

  const UpdateCheckResult({
    required this.status,
    required this.installedVersion,
    required this.latestVersion,
    required this.minimumVersion,
    required this.updateNotes,
    required this.storeUrlAndroid,
    required this.storeUrlIos,
  });

  /// Factory para o resultado padrão quando ocorre um erro.
  ///
  /// Princípio "fail-open": se algo der errado, o app continua
  /// funcionando normalmente com status [upToDate].
  factory UpdateCheckResult.fallback() {
    return const UpdateCheckResult(
      status: UpdateStatus.upToDate,
      installedVersion: '0.0.0',
      latestVersion: '0.0.0',
      minimumVersion: '0.0.0',
      updateNotes: '',
      storeUrlAndroid: '',
      storeUrlIos: '',
    );
  }

  @override
  String toString() {
    return 'UpdateCheckResult('
        'status: $status, '
        'installed: $installedVersion, '
        'latest: $latestVersion, '
        'minimum: $minimumVersion'
        ')';
  }
}

/// Serviço responsável por orquestrar a verificação de versão.
///
/// Fluxo:
///   1. Inicializa o RemoteConfigService (Firebase + fetch + activate)
///   2. Obtém a versão instalada via PackageInfo
///   3. Lê latest_version, minimum_version, force_update, maintenance do Remote Config
///   4. Usa VersionComparator para comparar versões
///   5. Determina o UpdateStatus correto
///   6. Retorna um UpdateCheckResult completo
///
/// Arquitetura:
///   ┌─────────────────────────────────────────────────┐
///   │                  UpdateService                  │
///   │                                                 │
///   │  RemoteConfigService ──→ valores remotos        │
///   │  PackageInfo ──→ versão instalada               │
///   │  VersionComparator ──→ comparação semântica     │
///   │                                                 │
///   │  Resultado: UpdateCheckResult                   │
///   └─────────────────────────────────────────────────┘
///
/// Decisão: Singleton
///   O serviço é stateless (não guarda estado interno),
///   mas usamos Singleton para evitar múltiplas inicializações
///   concorrentes do RemoteConfigService.
class UpdateService {
  UpdateService._();

  static final UpdateService _instance = UpdateService._();

  /// Singleton — garante uma única instância em toda a aplicação.
  static UpdateService get instance => _instance;

  /// Referência ao serviço de Remote Config.
  /// Injetada via construtor privado para facilitar testes futuros.
  final RemoteConfigService _remoteConfig = RemoteConfigService.instance;

  /// Executa a verificação completa de versão.
  ///
  /// Este é o método principal que a SplashPage chama.
  ///
  /// Fluxo de decisão (em ordem de prioridade):
  ///   1. Manutenção? → maintenance (bloqueia tudo)
  ///   2. Force update global? → forceUpdate
  ///   3. Versão < minimum_version? → forceUpdate
  ///   4. Versão < latest_version? → optionalUpdate
  ///   5. Caso contrário → upToDate
  ///
  /// A ordem importa! Manutenção tem prioridade máxima porque
  /// durante migrações de banco, mesmo usuários com a versão
  /// mais recente não devem acessar o app.
  ///
  /// Tratamento de erros:
  ///   - Se qualquer etapa falhar, retorna [UpdateCheckResult.fallback()]
  ///   - O app continua funcionando normalmente
  ///   - Nunca bloqueia o usuário por falha de infraestrutura
  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      // ─── Etapa 1: Inicializar Remote Config ───
      // Garante que Firebase está inicializado e os valores
      // remotos foram buscados e ativados.
      await _remoteConfig.initialize();

      // ─── Etapa 2: Obter versão instalada ───
      // package_info_plus lê a versão do pubspec.yaml
      // (versionName no Android, CFBundleShortVersionString no iOS)
      final packageInfo = await PackageInfo.fromPlatform();
      final installedVersion = packageInfo.version; // Ex: "1.9.22"

      // ─── Etapa 3: Ler valores do Remote Config ───
      final latestVersion = _remoteConfig.latestVersion;
      final minimumVersion = _remoteConfig.minimumVersion;
      final forceUpdate = _remoteConfig.forceUpdate;
      final maintenance = _remoteConfig.maintenance;
      final updateNotes = _remoteConfig.updateNotes;
      final storeUrlAndroid = _remoteConfig.storeUrlAndroid;
      final storeUrlIos = _remoteConfig.storeUrlIos;

      // ─── Etapa 4: Determinar o status ───
      final status = _determineStatus(
        installedVersion: installedVersion,
        latestVersion: latestVersion,
        minimumVersion: minimumVersion,
        forceUpdate: forceUpdate,
        maintenance: maintenance,
      );

      final result = UpdateCheckResult(
        status: status,
        installedVersion: installedVersion,
        latestVersion: latestVersion,
        minimumVersion: minimumVersion,
        updateNotes: updateNotes,
        storeUrlAndroid: storeUrlAndroid,
        storeUrlIos: storeUrlIos,
      );

      print('[UpdateService] $result');

      return result;
    } catch (e) {
      // ─── Fallback: App continua funcionando ───
      // Princípio "fail-open": se algo der errado na verificação,
      // o usuário não é penalizado. Isso é intencional.
      //
      // Cenários cobertos:
      //   - Sem internet
      //   - Firebase fora do ar
      //   - Timeout no Remote Config
      //   - package_info_plus falhou
      //   - Qualquer exceção inesperada
      print('[UpdateService] Erro na verificação de versão: $e');
      return UpdateCheckResult.fallback();
    }
  }

  /// Determina o [UpdateStatus] com base nos parâmetros.
  ///
  /// Prioridade das verificações (do mais crítico ao menos):
  ///   1. Manutenção — backend indisponível, ninguém acessa
  ///   2. Force Update — kill switch ativado manualmente
  ///   3. Versão abaixo do mínimo — versão incompatível com o backend
  ///   4. Versão desatualizada — nova versão disponível, mas funcional
  ///   5. Atualizado — tudo ok
  ///
  /// Por que essa ordem?
  ///   - Manutenção > Force Update: durante manutenção, mesmo quem tem
  ///     a versão mais recente não pode acessar.
  ///   - Force Update > minimum_version: force_update é um kill switch
  ///     manual, pode ser ativado mesmo se minimum_version não mudou.
  ///   - minimum_version > latest_version: se a versão é menor que a mínima,
  ///     NÃO pode ser tratada como atualização opcional.
  UpdateStatus _determineStatus({
    required String installedVersion,
    required String latestVersion,
    required String minimumVersion,
    required bool forceUpdate,
    required bool maintenance,
  }) {
    // 1. Manutenção tem prioridade absoluta
    if (maintenance) {
      return UpdateStatus.maintenance;
    }

    // 2. Kill switch global
    if (forceUpdate) {
      return UpdateStatus.forceUpdate;
    }

    // 3. Versão abaixo do mínimo aceito
    //    Ex: minimum_version = "1.8.0", installed = "1.7.0" → BLOQUEIA
    if (VersionComparator.isOlderThan(installedVersion, minimumVersion)) {
      return UpdateStatus.forceUpdate;
    }

    // 4. Existe versão mais nova, mas a atual ainda é aceitável
    //    Ex: latest_version = "2.0.0", installed = "1.9.0" → SUGERE
    if (VersionComparator.isOlderThan(installedVersion, latestVersion)) {
      return UpdateStatus.optionalUpdate;
    }

    // 5. Tudo ok — versão está em dia
    return UpdateStatus.upToDate;
  }
}

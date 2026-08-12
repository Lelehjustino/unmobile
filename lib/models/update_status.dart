/// Enum que representa o resultado da verificação de versão.
///
/// O [UpdateService] retorna um desses estados após comparar
/// a versão instalada com os parâmetros do Firebase Remote Config.
///
/// Fluxo:
///   UpdateService.checkForUpdate() → UpdateStatus
///   SplashPage lê o status → navega para a tela correta
enum UpdateStatus {
  /// App está na versão mais recente. Segue para a Home normalmente.
  upToDate(
    label: 'Atualizado',
    description: 'O aplicativo está na versão mais recente.',
  ),

  /// Existe uma versão mais nova, mas a atualização NÃO é obrigatória.
  /// Exibe um Dialog amigável: "Atualizar agora?" / "Lembrar depois".
  optionalUpdate(
    label: 'Atualização disponível',
    description: 'Uma nova versão está disponível para download.',
  ),

  /// A versão instalada está ABAIXO da minimum_version OU force_update=true.
  /// Bloqueia o app com tela cheia — sem botão voltar.
  forceUpdate(
    label: 'Atualização obrigatória',
    description: 'É necessário atualizar o aplicativo para continuar.',
  ),

  /// O backend está em manutenção. App totalmente bloqueado.
  /// Exibe tela de manutenção — sem ação do usuário.
  maintenance(
    label: 'Em manutenção',
    description: 'O sistema está em manutenção. Tente novamente mais tarde.',
  );

  const UpdateStatus({
    required this.label,
    required this.description,
  });

  /// Nome legível para exibição em UI ou logs.
  final String label;

  /// Descrição detalhada do estado.
  final String description;

  /// Retorna true se o estado exige bloqueio total do app.
  bool get isBlocking => this == forceUpdate || this == maintenance;

  /// Retorna true se é um estado onde o app pode continuar normalmente.
  bool get canContinue => this == upToDate || this == optionalUpdate;
}

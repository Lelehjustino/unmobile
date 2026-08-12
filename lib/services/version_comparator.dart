/// Classe utilitária para comparação semântica de versões.
///
/// Por que NÃO usar comparação de Strings?
/// → "1.9.0".compareTo("1.10.0") retorna valor positivo (9 > 1 lexicograficamente)
/// → Porém 1.10.0 é MAIOR que 1.9.0
/// → Precisamos dividir por segmentos e comparar como inteiros.
///
/// Suporta versões com 1, 2 ou 3 segmentos:
///   "1.0"     → [1, 0, 0]
///   "1.0.0"   → [1, 0, 0]
///   "1.2.10"  → [1, 2, 10]
///   "10.4.12" → [10, 4, 12]
class VersionComparator {
  const VersionComparator._();

  /// Converte uma string de versão em uma lista de inteiros.
  ///
  /// "1.9.22"  → [1, 9, 22]
  /// "2.0"     → [2, 0, 0]
  /// "1"       → [1, 0, 0]
  ///
  /// Segmentos faltantes são preenchidos com 0.
  /// Caracteres não numéricos (como sufixos "+43") são removidos.
  static List<int> _parse(String version) {
    // Remove tudo a partir de '+' ou '-' (ex: "1.9.22+43" → "1.9.22")
    final cleanVersion = version.split(RegExp(r'[+-]')).first.trim();

    final segments = cleanVersion.split('.');
    final result = <int>[];

    for (var i = 0; i < 3; i++) {
      if (i < segments.length) {
        result.add(int.tryParse(segments[i]) ?? 0);
      } else {
        // Preenche segmentos faltantes com 0
        // "1.2" → [1, 2, 0]
        result.add(0);
      }
    }

    return result;
  }

  /// Compara duas versões segmento a segmento.
  ///
  /// Retorna:
  ///   - valor negativo se [installed] < [remote]
  ///   - zero se [installed] == [remote]
  ///   - valor positivo se [installed] > [remote]
  ///
  /// Exemplo:
  ///   compare("1.9.22", "2.0.0") → negativo (installed é menor)
  ///   compare("2.0.0", "2.0.0")  → 0 (iguais)
  ///   compare("2.1.0", "2.0.0")  → positivo (installed é maior)
  static int compare(String installed, String remote) {
    final installedParts = _parse(installed);
    final remoteParts = _parse(remote);

    // Compara major → minor → patch
    for (var i = 0; i < 3; i++) {
      final diff = installedParts[i] - remoteParts[i];
      if (diff != 0) return diff;
    }

    return 0; // Versões idênticas
  }

  /// Verifica se a versão instalada é menor que a versão remota.
  ///
  /// Exemplo:
  ///   isOlderThan("1.9.22", "2.0.0") → true
  ///   isOlderThan("2.0.0", "2.0.0")  → false
  ///   isOlderThan("2.1.0", "2.0.0")  → false
  static bool isOlderThan(String installed, String remote) {
    return compare(installed, remote) < 0;
  }

  /// Verifica se a versão instalada é igual ou mais recente que a remota.
  ///
  /// Exemplo:
  ///   isAtLeast("2.0.0", "2.0.0")  → true
  ///   isAtLeast("2.1.0", "2.0.0")  → true
  ///   isAtLeast("1.9.0", "2.0.0")  → false
  static bool isAtLeast(String installed, String remote) {
    return compare(installed, remote) >= 0;
  }
}

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

class MobileIdService {
  static const MethodChannel _channel = MethodChannel('com.un.mobile/mobile_id');
  static const String _prefsKey = 'mobile_id';

  /// Obtém o Mobile ID.
  /// 
  /// Fluxo:
  /// 1. Verifica se já existe um `mobileId` salvo localmente (SharedPreferences).
  ///    Se existir, retorna o valor salvo imediatamente.
  /// 2. Se não existir, invoca o método nativo:
  ///    - No Android: Obtém `Settings.Secure.ANDROID_ID`.
  ///    - No iOS: Obtém `UIDevice.current.identifierForVendor?.uuidString`.
  /// 3. Converte esse identificador numérico de forma determinística em um decimal/inteiro.
  /// 4. Salva no `SharedPreferences` para garantir persistência.
  /// 
  /// Situações que podem fazer o identificador nativo mudar antes de ser salvo:
  /// - Android: Realizar um "Factory Reset" (redefinição de fábrica) no aparelho. A desinstalação/reinstalação 
  ///   não costuma afetar no Android 8.0+, mas o Factory Reset cria um novo ANDROID_ID.
  /// - iOS: O `identifierForVendor` permanece o mesmo para aplicativos do mesmo fornecedor (vendor).
  ///   Entretanto, se TODOS os aplicativos desse vendor forem desinstalados do aparelho, e depois
  ///   algum deles for reinstalado, um novo `identifierForVendor` será gerado.
  static Future<String> getMobileId() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Verifica se já existe salvo no SharedPreferences
    final savedId = prefs.getString(_prefsKey);
    if (savedId != null && savedId.isNotEmpty) {
      return savedId;
    }

    String? nativeId;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        nativeId = await _channel.invokeMethod<String>('getNativeId');
      }
    } on PlatformException catch (e) {
      print('Erro ao obter identificador nativo do aparelho: ${e.message}');
    } catch (e) {
      print('Erro inesperado ao acessar channel nativo: $e');
    }

    if (nativeId == null || nativeId.isEmpty) {
      // Como fallback extremo caso o recurso em alguma plataforma não esteja acessível
      // (ex: rodando no Windows testando, ou erro nas permissões)
      // Neste caso, para fim de simulação determinística fora do mobile:
      nativeId = "FALLBACK-ID-UNKNOWN";
      print('Aviso: MobileIdService não conseguiu ler o identificador nativo. Usando Fallback.');
    }

    // Converte o identificador nativo de forma determinística para número decimal
    final decimalId = _convertToDeterministicDecimal(nativeId);

    // Salva o `mobileId` persitentemente e localmente
    await prefs.setString(_prefsKey, decimalId);

    return decimalId;
  }

  /// Converte a string nativa (`ANDROID_ID` hexa ou `identifierForVendor` UUID)
  /// para uma representação estritamente decimal de comprimento variável, 
  /// sem limite de tamanho (retorna String contendo só números).
  static String _convertToDeterministicDecimal(String input) {
    // 1. Remove formatações como hífens no UUID e deixa minúsculo
    String cleanStr = input.replaceAll('-', '').toLowerCase();
    
    // 2. Remove caracteres que não sejam hexadecimais para garantir o parse
    cleanStr = cleanStr.replaceAll(RegExp(r'[^0-9a-f]'), '');
    
    // Se a string original não contiver nada que seja hexadecimal,
    // garantimos uma string hexadecimal usando os code units como fallback.
    if (cleanStr.isEmpty) {
        cleanStr = input.codeUnits.map((e) => e.toRadixString(16)).join();
    }
    
    // 3. Converte o bloco hexadecimal para decimal usando BigInt
    // O BigInt garante que não haverá overflow, independentemente do tamanho:
    // - ANDROID_ID tem 64 bits de entropia (16 dígitos hex)
    // - UUID (iOS) tem 128 bits de entropia (32 dígitos hex)
    // O resultado será uma string inteira, ex: "11887373801831415058"
    try {
      final bigInt = BigInt.parse(cleanStr, radix: 16);
      return bigInt.toString();
    } catch (e) {
      // Último recurso de segurança, quase impossível de alcançar, converte 
      // somando as charCodes dos caracteres de forma simples.
      int soma = 0;
      for (var rune in input.runes) {
        soma += rune;
      }
      return soma.toString();
    }
  }
}

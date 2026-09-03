import 'dart:convert';
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MobileIdService {
  static const MethodChannel _channel = MethodChannel('com.un.mobile/mobile_id');

  static const String _prefsKey = 'mobile_id';

  /// Retorna o Mobile ID do aparelho.
  /// Android: Utiliza o ANDROID_ID.
  /// iOS: Utiliza um identificador armazenado no Keychain.

  /// O SharedPreferences é utilizado como cache.
  static Future<String> getMobileId() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Verifica se já existe no SharedPreferences

    /* final savedId = prefs.getString(_prefsKey);

    if (savedId != null && savedId.isNotEmpty) {
      return savedId;
    } */

    // 2. Obtém o identificador nativo

    String? nativeId;

    try {
      if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
        nativeId = await _channel.invokeMethod<String>(
          'getNativeId',
        );
      }
    } on PlatformException catch (e) {
      print(
        'Erro ao obter identificador nativo: ${e.message}',
      );
    } catch (e) {
      print(
        'Erro inesperado ao obter identificador nativo: $e',
      );
    }

    // 3. Se conseguiu o identificador nativo

    if (nativeId != null && nativeId.isNotEmpty) {
      final mobileId = _convertToDeterministicDecimal(
        nativeId,
      );

      await prefs.setString(
        _prefsKey,
        mobileId,
      );

      return mobileId;
    }

    // 4. Fallback

    final fallbackId = await _gerarIdAparelho();

    await prefs.setString(
      _prefsKey,
      fallbackId,
    );

    return fallbackId;
  }

  /// Fallback caso o identificador nativo não esteja disponível.
  ///
  /// IMPORTANTE:
  /// Este método não deve ser a estratégia principal.
  static Future<String> _gerarIdAparelho() async {
    final deviceInfo = DeviceInfoPlugin();

    String identificador = '';

    if (Platform.isAndroid) {
      /* final android = await deviceInfo.androidInfo;

      identificador = android.id; */
      identificador = await _gerarIdAparelhoManual();
    } else if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;

      identificador = ios.identifierForVendor ?? '';
      // identificador = await _gerarIdAparelhoManual();
    }

    if (identificador.isEmpty) {
      return await _gerarIdAparelhoManual();
    }

    return _convertToDeterministicDecimal(
      identificador,
    );
  }

   static Future<String> _gerarIdAparelhoManual() async {
    final deviceInfo = DeviceInfoPlugin();

    String fabricante = '';
    String modelo = '';
    String sistema = '';
    String identificador = '';

    // ANDROID

    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;

      fabricante = android.manufacturer;
      modelo = android.model;
      sistema = 'android_${android.version.release}';

      // ANDROID_ID é a melhor opção dentro do fallback Android.
      //
      // Em versões modernas do Android ele é normalmente estável
      // entre desinstalação e reinstalação do aplicativo.
      identificador = android.id;
    }

    // IOS

    else if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;

      fabricante = 'Apple';
      modelo = ios.utsname.machine;
      sistema = 'ios_${ios.systemVersion}';

      // Identificador disponível pelo device_info_plus.
      identificador = ios.identifierForVendor ?? '';
    }

    // Combinação determinística

    final dados = [
      'fabricante=$fabricante',
      'modelo=$modelo',
      'sistema=$sistema',
      'identificador=$identificador',
    ].join('|');

    print('Dados utilizados para gerar Mobile ID: $dados');

    // SHA-256 transforma a combinação em um valor determinístico.
    //
    // O mesmo aparelho fornecendo os mesmos dados
    // produzirá exatamente o mesmo hash.
    final hash = sha256.convert(
      utf8.encode(dados),
    );

    String finalId = _convertToDeterministicDecimal(hash.toString());
    String finalId2 = finalId + "G";

    // Converte o hash hexadecimal para decimal.
    return finalId2;
  }

  /// Converte um identificador hexadecimal/UUID para decimal.
  ///
  /// Exemplo:
  ///
  /// a4f83c91b27e5d12
  ///
  /// vira:
  ///
  /// 118836472938475...
  ///
  /// BigInt é utilizado para evitar overflow.
  static String _convertToDeterministicDecimal(
    String input,
  ) {
    var cleanStr = input
        .replaceAll('-', '')
        .replaceAll('{', '')
        .replaceAll('}', '')
        .toLowerCase();

    // Mantém apenas caracteres hexadecimais.
    cleanStr = cleanStr.replaceAll(
      RegExp(r'[^0-9a-f]'),
      '',
    );

    if (cleanStr.isEmpty) {
      throw Exception(
        'Identificador nativo inválido: $input',
      );
    }

    try {
      final bigInt = BigInt.parse(
        cleanStr,
        radix: 16,
      );

      return bigInt.toString();
    } catch (e) {
      // Fallback extremamente improvável.
      final hash = sha256.convert(
        input.codeUnits,
      );

      final hashInt = BigInt.parse(
        hash.toString(),
        radix: 16,
      );

      return hashInt.toString();
    }
  }
}

/* import 'dart:convert';
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MobileIdService {
  static const MethodChannel _channel =
      MethodChannel('com.un.mobile/mobile_id');

  static const String _prefsKey = 'mobile_id';

  /// Obtém o Mobile ID.
  ///
  /// Ordem:
  /// 1. Retorna o ID já salvo.
  /// 2. Tenta obter o identificador nativo.
  /// 3. Caso o nativo retorne null/vazio, gera um ID determinístico
  ///    usando informações do próprio aparelho.
  static Future<String> getMobileId() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. ID já salvo

    final savedId = prefs.getString(_prefsKey);

    if (savedId != null && savedId.isNotEmpty) {
      return savedId;
    }

    // 2. Tenta obter o ID nativo

    String? nativeId;

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        nativeId = await _channel.invokeMethod<String>('getNativeId');
      }
    } on PlatformException catch (e) {
      print(
        'Erro ao obter identificador nativo: ${e.message}',
      );
    } catch (e) {
      print(
        'Erro inesperado ao acessar identificador nativo: $e',
      );
    }

    // 3. Se conseguiu o ID nativo, utiliza ele

    if (nativeId != null && nativeId.isNotEmpty) {
      final decimalId = _convertToDeterministicDecimal(nativeId);

      await prefs.setString(_prefsKey, decimalId);

      return decimalId;
    }

    // 4. Fallback:
    // gera um ID determinístico baseado no aparelho

    final fallbackId = await _gerarIdAparelho();

    await prefs.setString(_prefsKey, fallbackId);

    return fallbackId;
  }

  /// Gera um identificador determinístico baseado em informações
  /// fornecidas pelo próprio aparelho.
  static Future<String> _gerarIdAparelho() async {
    final deviceInfo = DeviceInfoPlugin();

    String fabricante = '';
    String modelo = '';
    String sistema = '';
    String identificador = '';

    // ANDROID

    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;

      fabricante = android.manufacturer;
      modelo = android.model;
      sistema = 'android_${android.version.release}';

      // ANDROID_ID é a melhor opção dentro do fallback Android.
      //
      // Em versões modernas do Android ele é normalmente estável
      // entre desinstalação e reinstalação do aplicativo.
      identificador = android.id;
    }

    // IOS

    else if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;

      fabricante = 'Apple';
      modelo = ios.utsname.machine;
      sistema = 'ios_${ios.systemVersion}';

      // Identificador disponível pelo device_info_plus.
      identificador = ios.identifierForVendor ?? '';
    }

    // Combinação determinística

    final dados = [
      'fabricante=$fabricante',
      'modelo=$modelo',
      'sistema=$sistema',
      'identificador=$identificador',
    ].join('|');

    print('Dados utilizados para gerar Mobile ID: $dados');

    // SHA-256 transforma a combinação em um valor determinístico.
    //
    // O mesmo aparelho fornecendo os mesmos dados
    // produzirá exatamente o mesmo hash.
    final hash = sha256.convert(
      utf8.encode(dados),
    );

    // Converte o hash hexadecimal para decimal.
    return _convertToDeterministicDecimal(hash.toString());
  }

  /// Converte hexadecimal para decimal sem limite de tamanho.
  static String _convertToDeterministicDecimal(String input) {
    String cleanStr = input
        .replaceAll('-', '')
        .toLowerCase();

    cleanStr = cleanStr.replaceAll(
      RegExp(r'[^0-9a-f]'),
      '',
    );

    if (cleanStr.isEmpty) {
      cleanStr = input.codeUnits
          .map((e) => e.toRadixString(16))
          .join();
    }

    try {
      final bigInt = BigInt.parse(
        cleanStr,
        radix: 16,
      );

      return bigInt.toString();
    } catch (e) {
      int soma = 0;

      for (final rune in input.runes) {
        soma += rune;
      }

      String finalId = soma.toString() + 'g';

      return finalId;
    }
  }
}


/* import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:mysql_client/mysql_protocol.dart';
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
      nativeId = gerarIdAparelho(

      );
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
 */ */
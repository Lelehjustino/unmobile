import 'package:flutter/services.dart';

class StoneService {
  final MethodChannel _channel =
      MethodChannel('stone.pos.channel');

  Future<String> initializeStone() async {
    final result = await _channel.invokeMethod('initializeStone');
    return result;
  }
}

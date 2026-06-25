import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:un_recepcao/data/data_class.dart';

// IMPORTAR: final ZerarAtendimentoController zerarAtendimentoController = Get.find<ZerarAtendimentoController>();
// CHAMAR: zerarAtendimentoController.zerarAtendimento();
// await Get.find<ZerarAtendimentoController>().loadNumeroLicenca();
// await Get.find<ZerarAtendimentoController>().zerarAtendimento();

class ZerarAtendimentoController extends GetxController {

  String numeroDaLicencaSelecionada = "";

  Future<void> loadNumeroLicenca() async {
    final prefs = await SharedPreferences.getInstance();
    final licencaSalvoNumero = prefs.getString('licencaNumero');
    if (licencaSalvoNumero != null) {
      numeroDaLicencaSelecionada = licencaSalvoNumero;
    }
  }

  Future<void> zerarAtendimento() async {
    String sql = """
      UPDATE cartoes SET atendimento = '0' WHERE atendimento = '$numeroDaLicencaSelecionada';
      UPDATE mesas SET atendimento = '0' WHERE atendimento = '$numeroDaLicencaSelecionada';
    """;

    try {
      await Connection().ipd(sql);
    } catch (e) {
      print("Erro ao zerar atendimento no banco: $e");
    }
  }
}
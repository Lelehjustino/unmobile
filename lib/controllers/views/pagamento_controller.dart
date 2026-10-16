import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:un_recepcao/controllers/maquininhas/paymentServiceOficial.dart';
import 'package:un_recepcao/services/maquininhas/paymentProvider.dart';

class PagamentoController extends GetxController{

  // Tipos de venda para fluxo 
  RxBool pagBank = false.obs;
  RxBool cielo = false.obs;
  RxBool mobile = false.obs;

  @override
  void onInit() {
    super.onInit();
    carregarTudo();
  }

  Future<void> carregarTudo() async {
    await verificaSeEstaNaMaquininha();
  }

  // Para colocar os valores para centavos na ceilo
  int valorParaCentavos(Object? valor) {
    String texto = (valor ?? '')
        .toString()
        .trim()
        .replaceAll('R\$', '')
        .replaceAll(' ', '');

    if (texto.isEmpty) return 0;

    final int ultimaVirgula = texto.lastIndexOf(',');
    final int ultimoPonto = texto.lastIndexOf('.');

    if (ultimaVirgula >= 0 && ultimoPonto >= 0) {
      // O último separador é o decimal.
      if (ultimaVirgula > ultimoPonto) {
        texto = texto.replaceAll('.', '').replaceAll(',', '.');
      } else {
        texto = texto.replaceAll(',', '');
      }
    } else if (ultimaVirgula >= 0) {
      texto = texto.replaceAll(',', '.');
    } else if (ultimoPonto >= 0) {
      // Um único ponto seguido por três dígitos é tratado
      // como separador de milhar.
      final casas = texto.length - ultimoPonto - 1;
      if (casas == 3) {
        texto = texto.replaceAll('.', '');
      }
    }

    final partes = texto.split('.');
    if (partes.length > 2) return 0;

    final inteiroTexto = partes[0];
    final decimalTexto = partes.length > 1 ? partes[1] : '';

    if (inteiroTexto.isEmpty ||
        !RegExp(r'^\d+$').hasMatch(inteiroTexto) ||
        (decimalTexto.isNotEmpty &&
            !RegExp(r'^\d+$').hasMatch(decimalTexto))) {
      return 0;
    }

    final inteiro = int.tryParse(inteiroTexto);
    if (inteiro == null) return 0;

    final decimais = decimalTexto.padRight(2, '0');
    int centavos = inteiro * 100;

    if (decimais.isNotEmpty) {
      centavos += int.parse(decimais.substring(0, 2));
    }

    // Arredondamento comercial quando há mais de duas casas.
    if (decimalTexto.length > 2 &&
        int.parse(decimalTexto[2]) >= 5) {
      centavos++;
    }

    return centavos;
  }

  // Centavos sql cielo
  String centavosParaValorSql(int centavos) {
    final reais = centavos ~/ 100;
    final centavosRestantes = centavos % 100;

    return '$reais.${centavosRestantes.toString().padLeft(2, '0')}';
  }

  // Dialogo com só um botão - vermelho erro
  Future<void> showErrorDialog({
    required BuildContext context,
    String title = 'Confirmação',
    required String message,
    IconData icon = Icons.home,
    String cancelText = 'Cancelar',
    String confirmText = 'OK',
    VoidCallback? onConfirm,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(curvedAnim),
          child: FadeTransition(
            opacity: curvedAnim,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícone central
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(
                          ctx,
                        ).colorScheme.error.withOpacity(0.08),
                      ),
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        icon,
                        size: 40,
                        color: Theme.of(ctx).colorScheme.error,
                      ),
                    ),

                    SizedBox(height: 10),

                    // Título opcional
                    if (title.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          title,
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    if (message.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          message,
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w300,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Botões centralizados
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Confirmar
                        ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.of(ctx).pop();
                            if (onConfirm != null) onConfirm();
                          },
                          child: Text(
                            confirmText.toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(ctx).colorScheme.onPrimary,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            backgroundColor: Theme.of(ctx).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Função que verifica tipo e se esta em uma maquininha 
  Future<void> verificaSeEstaNaMaquininha() async {
    final provedor = await PaymentServiceOficial.identificarProvedor();

    pagBank.value = false;
    cielo.value = false;
    mobile.value = false;

    switch (provedor) {
      // pagar pedido bagBank 
      case PaymentProvider.pagBank:
        pagBank.value = true;
      break;

      // pagar pedido cielo 
      case PaymentProvider.cielo:
        cielo.value = true;
      break;

      // se nao tiver maquininha 
      case PaymentProvider.desconhecido:
        mobile.value = true;
      break;
    }
  }

}
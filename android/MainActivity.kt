package com.un_recepcao

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

class MainActivity: FlutterActivity() {

    private val CHANNEL = "stone_payment"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                if (call.method == "pagar") {

                    val valor = call.argument<Double>("valor") ?: 0.0

                    simularPagamento(valor, result)

                } else {
                    result.notImplemented()
                }
            }
    }

    private fun simularPagamento(valor: Double, result: MethodChannel.Result) {

        thread {
            try {
                Thread.sleep(2000) // simula tempo da máquina

                val sucesso = valor <= 100 // regra fake

                if (sucesso) {
                    result.success(
                        mapOf(
                            "status" to "sucesso",
                            "codigo" to "123456",
                            "mensagem" to "Pagamento aprovado"
                        )
                    )
                } else {
                    result.success(
                        mapOf(
                            "status" to "falha",
                            "mensagem" to "Cartão recusado"
                        )
                    )
                }

            } catch (e: Exception) {
                result.error("ERRO", e.message, null)
            }
        }
    }
}
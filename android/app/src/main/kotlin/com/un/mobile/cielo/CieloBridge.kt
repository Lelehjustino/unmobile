package com.un.mobile.cielo

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.util.Base64
import io.flutter.plugin.common.MethodChannel

object CieloBridge {

    private const val METHOD_INICIAR_DEEP_LINK = "iniciarDeepLink"
    private const val METHOD_RETORNO = "onRetornoCielo"

    // Referência ao channel mantida para poder invocar o Flutter no retorno.
    private var channel: MethodChannel? = null

    fun configurar(channel: MethodChannel, activity: Activity) {
        this.channel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_INICIAR_DEEP_LINK -> {
                    val uri = call.argument<String>("uri")
                    if (uri.isNullOrBlank()) {
                        result.error("CIELO_URI_INVALIDA", "URI não informada", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uri))
                        activity.startActivity(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("CIELO_ERRO_INTENT", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Chamado pelo MainActivity.onNewIntent() quando a Cielo retorna via urlCallback.
     * Decodifica o query param "response" (Base64 JSON) e entrega ao Flutter.
     */
    fun processarRetorno(intent: Intent) {

        println("CIELO: onNewIntent recebido")
        println("CIELO: action = ${intent.action}")
        println("CIELO: data = ${intent.data}")

        if (Intent.ACTION_VIEW != intent.action) {
            println("CIELO: action não é ACTION_VIEW")
            return
        }

        val uri: Uri = intent.data ?: run {
            println("CIELO: intent.data é null")
            return
        }

        println("CIELO: URI recebida = $uri")

        val responseBase64 =
            uri.getQueryParameter("response")

        if (responseBase64.isNullOrBlank()) {
            println("CIELO: parâmetro response não encontrado")
            return
        }

        println("CIELO: response Base64 recebido")

        val json = try {

            String(
                Base64.decode(
                    responseBase64,
                    Base64.DEFAULT
                )
            )

        } catch (e: Exception) {

            println("CIELO: erro ao decodificar response: ${e.message}")

            return
        }

        println("CIELO: JSON recebido = $json")

        channel?.invokeMethod(
            METHOD_RETORNO,
            json
        )

        println("CIELO: retorno enviado para Flutter")
    }
}

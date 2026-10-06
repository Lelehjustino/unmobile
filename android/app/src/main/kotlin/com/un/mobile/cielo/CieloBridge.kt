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
        if (Intent.ACTION_VIEW != intent.action) return
        val uri: Uri = intent.data ?: return
        val responseBase64 = uri.getQueryParameter("response") ?: return
        val json = try {
            String(Base64.decode(responseBase64, Base64.DEFAULT))
        } catch (e: Exception) {
            return
        }
        channel?.invokeMethod(METHOD_RETORNO, json)
    }
}

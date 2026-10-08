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

    // Intent pendente: guardado quando o callback chega antes do Flutter estar
    // pronto (cenário de recriação da Activity). Será despachado logo que o
    // listener Dart se registrar via CieloService.escutarRetorno().
    private var jsonPendente: String? = null

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
                // Flutter registrou o listener → despacha JSON pendente (se houver)
                "registrarListener" -> {
                    result.success(null)
                    val pendente = jsonPendente
                    if (pendente != null) {
                        println("CIELO: despachando JSON pendente para Flutter")
                        jsonPendente = null
                        channel.invokeMethod(METHOD_RETORNO, pendente)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Chamado pelo MainActivity.onNewIntent() (singleTop — app estava vivo)
     * ou pelo MainActivity.onCreate() (app foi recriado pelo sistema).
     * Decodifica o query param "response" (Base64 JSON) e entrega ao Flutter.
     * Se o Flutter ainda não estiver pronto, guarda o JSON para despacho posterior.
     */
    fun processarRetorno(intent: Intent) {

        println("CIELO: processarRetorno chamado")
        println("CIELO: action = ${intent.action}")
        println("CIELO: data  = ${intent.data}")

        if (Intent.ACTION_VIEW != intent.action) {
            println("CIELO: action não é ACTION_VIEW — ignorado")
            return
        }

        val uri: Uri = intent.data ?: run {
            println("CIELO: intent.data é null — ignorado")
            return
        }

        println("CIELO: URI recebida = $uri")

        val responseBase64 = uri.getQueryParameter("response")

        if (responseBase64.isNullOrBlank()) {
            println("CIELO: parâmetro 'response' ausente — ignorado")
            return
        }

        val json = try {
            String(Base64.decode(responseBase64, Base64.DEFAULT))
        } catch (e: Exception) {
            println("CIELO: erro ao decodificar Base64: ${e.message}")
            return
        }

        println("CIELO: JSON decodificado = $json")

        val ch = channel
        if (ch != null) {
            // Flutter já está pronto → despacha imediatamente
            ch.invokeMethod(METHOD_RETORNO, json)
            println("CIELO: retorno enviado para Flutter (imediato)")
        } else {
            // Flutter ainda não configurou o channel (início a frio)
            // Guarda para despachar quando o listener Dart se registrar
            jsonPendente = json
            println("CIELO: Flutter não pronto — JSON guardado como pendente")
        }
    }
}

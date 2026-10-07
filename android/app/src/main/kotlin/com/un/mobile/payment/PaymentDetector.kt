package com.un.mobile.payment

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.content.pm.PackageManager
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

object PaymentDetector {

    private const val PLUGPAG_PACKAGE = "br.com.uol.pagseguro.plugpagservice"
    private const val TIMEOUT_MS = 3000L

    fun configurar(channel: MethodChannel, context: Context) {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "identificarProvedor" -> {
                    thread {
                        val provedor = identificar(context)
                        android.os.Handler(android.os.Looper.getMainLooper()).post {
                            result.success(provedor)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun identificar(context: Context): String {
        println("PAYMENT DETECTOR: iniciando identificação")

        // ── 1. Verificar Cielo Smart ──────────────────────────────────────
        println("PAYMENT DETECTOR: verificando Cielo")
        if (isCieloDisponivel(context)) {
            println("PAYMENT DETECTOR: Cielo identificada")
            return "cielo"
        }
        println("PAYMENT DETECTOR: Cielo não encontrada")

        // ── 2. Verificar PagBank / PlugPag ────────────────────────────────
        println("PAYMENT DETECTOR: verificando PagBank")
        if (isPagBankDisponivel(context)) {
            println("PAYMENT DETECTOR: PagBank identificado")
            return "pagbank"
        }
        println("PAYMENT DETECTOR: PagBank não encontrado")

        println("PAYMENT DETECTOR: nenhum provedor identificado")
        return "desconhecido"
    }

    /**
     * Verifica se a Cielo Smart está presente no terminal consultando o PackageManager
     * para saber se algum app resolve o scheme "lio://" (scheme oficial Cielo Deep Link).
     * Não lança nenhum deep link — apenas consulta o sistema.
     */
    private fun isCieloDisponivel(context: Context): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("lio://payment"))
            val pm = context.packageManager
            val activities = pm.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
            val encontrado = activities.isNotEmpty()
            println("PAYMENT DETECTOR: Cielo resolvers encontrados = ${activities.size}")
            encontrado
        } catch (e: Exception) {
            println("PAYMENT DETECTOR: erro ao verificar Cielo: ${e.message}")
            false
        }
    }

    /**
     * Verifica se o PlugPagService está instalado no terminal.
     * Mesma verificação usada pelo PagBankBridge.verificarRequisitos() —
     * sem criar nova instância de PlugPag nem alterar o PagBankBridge.
     */
    private fun isPagBankDisponivel(context: Context): Boolean {
        return try {
            context.packageManager.getPackageInfo(PLUGPAG_PACKAGE, 0)
            println("PAYMENT DETECTOR: PlugPagService package encontrado")
            true
        } catch (e: Exception) {
            println("PAYMENT DETECTOR: PlugPagService não encontrado: ${e.message}")
            false
        }
    }
}

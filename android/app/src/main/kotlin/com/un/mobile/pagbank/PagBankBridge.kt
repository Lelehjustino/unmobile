package com.un.mobile.pagbank

import android.content.Context
import android.content.pm.PackageManager
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPag
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagCustomPrinterLayout
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagEventData
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagEventListener
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagPaymentData
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagTransactionResult
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

/**
 * PagBankBridge — Camada de integração Flutter → PlugPagServiceWrapper.
 *
 * Baseado no fluxo real do SmartCoffee (PaymentViewModel.kt) do PagBank.
 *
 * Arquitetura:
 *   Flutter/Dart → MethodChannel('unmobile/pagbank') → PagBankBridge → PlugPag → SmartPOS
 *   PlugPag → EventChannel('unmobile/pagbank/eventos') → Flutter/Dart
 *
 * Wrapper versão: 1.35.0
 */
class PagBankBridge {

    companion object {

        private const val PLUGPAG_SERVICE_PACKAGE_NAME = "br.com.uol.pagseguro.plugpagservice"

        /**
         * Instância singleton do PlugPag — conforme orientação oficial:
         * "Utilize o Wrapper como um Singleton em sua aplicação."
         */
        private var plugPag: PlugPag? = null

        /**
         * Controle de concorrência — impede dupla execução simultânea.
         * @Volatile garante visibilidade entre threads.
         */
        @Volatile
        private var executandoPagamento = false

        /**
         * Sink do EventChannel para emitir eventos de status em tempo real.
         * Null quando o Flutter não está ouvindo.
         */
        @Volatile
        private var eventoSink: EventChannel.EventSink? = null

        /**
         * Inicializa o PlugPag singleton.
         * Deve ser chamado sempre com o applicationContext para evitar leak de Activity.
         */
        private fun getPlugPag(context: Context): PlugPag {
            if (plugPag == null) {
                plugPag = PlugPag(context.applicationContext)
            }
            return plugPag!!
        }

        /**
         * Verifica os pré-requisitos conforme SmartCoffee:
         * 1. PlugPagService instalado no terminal
         * 2. Serviço autenticado (isAuthenticated)
         * Retorna null se OK, ou mensagem de erro.
         */
        private fun verificarRequisitos(plugpag: PlugPag, packageManager: PackageManager): String? {
            try {
                packageManager.getPackageInfo(PLUGPAG_SERVICE_PACKAGE_NAME, 0)
            } catch (ex: Exception) {
                return "PlugPagService não instalado no terminal"
            }

            if (!plugpag.isAuthenticated()) {
                plugpag.startOnBoarding()
                return "Terminal não autenticado. Onboarding iniciado."
            }

            return null // OK
        }

        /**
         * Emite um evento de status para o Flutter via EventChannel.
         * Sempre executado na UI thread para thread-safety do EventSink.
         */
        private fun emitirEvento(evento: Map<String, Any?>) {
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                try {
                    eventoSink?.success(evento)
                } catch (e: Exception) {
                    println("PAGBANK: Erro ao emitir evento: ${e.message}")
                }
            }
        }

        /**
         * Registra o handler do MethodChannel e o EventChannel.
         * Chamado uma única vez durante o configureFlutterEngine.
         */
        fun configurar(channel: MethodChannel, eventChannel: EventChannel, context: Context) {

            println("PAGBANK: PagBankBridge configurando...")

            // ── EventChannel: gerencia o lifecycle do sink quando Flutter ouve o stream ──
            // O Flutter SDK envia 'listen' quando o stream é aberto e 'cancel' quando fechado.
            // O StreamHandler DEVE estar registrado antes de qualquer subscribe do Dart.
            eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    println("PAGBANK: Flutter conectou ao EventChannel de eventos")
                    eventoSink = events
                }

                override fun onCancel(arguments: Any?) {
                    println("PAGBANK: Flutter desconectou do EventChannel de eventos")
                    eventoSink = null
                }
            })

            // ── MethodChannel: comandos do Flutter → Kotlin ──
            channel.setMethodCallHandler { call, result ->

                println("PAGBANK: método recebido = ${call.method}")

                when (call.method) {

                    // ═══════════════════════════════════════════════════
                    // verificarSmartPOS
                    // Verifica se o terminal SmartPOS está disponível
                    // ═══════════════════════════════════════════════════
                    "verificarSmartPOS" -> {
                        thread {
                            try {
                                val pp = getPlugPag(context)
                                val pm = context.packageManager
                                val erro = verificarRequisitos(pp, pm)

                                val disponivel = erro == null && !pp.isServiceBusy
                                responderUiThread(result) { result.success(disponivel) }
                            } catch (e: Exception) {
                                println("PAGBANK: verificarSmartPOS erro: ${e.message}")
                                responderUiThread(result) { result.success(false) }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════
                    // realizarPagamento
                    // Fluxo idêntico ao doPay() do SmartCoffee
                    // ═══════════════════════════════════════════════════
                    "realizarPagamento" -> {

                        // Proteção contra concorrência (SmartCoffee: executingPayment)
                        if (executandoPagamento) {
                            result.success(
                                mapOf(
                                    "status" to "ERRO",
                                    "aprovado" to false,
                                    "codigo" to "BUSY",
                                    "codigoErro" to "PP1047",
                                    "mensagem" to "Já existe uma transação em andamento"
                                )
                            )
                            return@setMethodCallHandler
                        }

                        val valorCentavos = call.argument<Int>("valorCentavos") ?: 0
                        val tipo = call.argument<String>("tipo") ?: "credito"
                        val referencia = call.argument<String>("referencia") ?: "UNMOBILE"

                        println("PAGBANK: pagamento solicitado tipo=$tipo valor=${valorCentavos}c ref=$referencia")

                        // Valor mínimo: 1 real (100 centavos) — SmartCoffee: MIN_AMOUNT = 1_00
                        if (valorCentavos < 100) {
                            result.success(
                                mapOf(
                                    "status" to "ERRO",
                                    "aprovado" to false,
                                    "codigo" to "INVALID_AMOUNT",
                                    "codigoErro" to "INVALID_AMOUNT",
                                    "mensagem" to "Valor mínimo é R\$ 1,00"
                                )
                            )
                            return@setMethodCallHandler
                        }

                        executandoPagamento = true

                        // Emite status inicial para o Flutter
                        emitirEvento(
                            mapOf(
                                "tipo" to "status",
                                "mensagem" to "Iniciando pagamento...",
                                "eventCode" to -1
                            )
                        )

                        // Execução fora da UI Thread — SmartCoffee usa Dispatchers.Default
                        // MethodChannel.Result DEVE ser chamado exatamente UMA VEZ
                        // Usamos flag para garantir isso mesmo em exceções concorrentes
                        var resultadoEnviado = false

                        thread {
                            try {
                                val pp = getPlugPag(context)
                                val pm = context.packageManager

                                // Verificação de requisitos (SmartCoffee: hasRequirements)
                                val erroRequisito = verificarRequisitos(pp, pm)
                                if (erroRequisito != null) {
                                    executandoPagamento = false
                                    emitirEvento(
                                        mapOf(
                                            "tipo" to "erro",
                                            "mensagem" to erroRequisito,
                                            "eventCode" to -1
                                        )
                                    )
                                    responderUiThread(result) {
                                        if (!resultadoEnviado) {
                                            resultadoEnviado = true
                                            result.success(
                                                mapOf(
                                                    "status" to "ERRO",
                                                    "aprovado" to false,
                                                    "codigo" to "SETUP_ERROR",
                                                    "codigoErro" to "SETUP_ERROR",
                                                    "mensagem" to erroRequisito
                                                )
                                            )
                                        }
                                    }
                                    return@thread
                                }

                                // Event listener — SmartCoffee: plugpag.setEventListener
                                // Repassa cada evento do PlugPag para o Flutter via EventChannel
                                pp.setEventListener(object : PlugPagEventListener {
                                    override fun onEvent(data: PlugPagEventData) {
                                        println("PAGBANK EVENT: code=${data.eventCode} msg=${data.customMessage}")
                                        emitirEvento(
                                            mapOf(
                                                "tipo" to "status",
                                                "mensagem" to (data.customMessage ?: ""),
                                                "eventCode" to (data.eventCode ?: -1)
                                            )
                                        )
                                    }
                                })

                                // Layout de impressão — SmartCoffee: setPlugPagCustomPrinterLayout
                                pp.setPlugPagCustomPrinterLayout(
                                    PlugPagCustomPrinterLayout(
                                        "Imprimir via do cliente?",
                                        "#000000",
                                        "#FFFFFF",
                                        "#A0A0A0",
                                        "#FFFFFF",
                                        "#000000",
                                        "#808080",
                                        "#FFFFFF",
                                        60
                                    )
                                )

                                // Mapear tipo do Flutter para constantes PlugPag
                                // SmartCoffee — PaymentType enum usa PlugPag.TYPE_CREDITO etc.
                                // NUNCA usar TYPE_PREAUTO_CARD / TYPE_PREAUTO_KEYED para venda normal
                                val paymentType = when (tipo) {
                                    "credito" -> PlugPag.TYPE_CREDITO
                                    "debito" -> PlugPag.TYPE_DEBITO
                                    "voucher" -> PlugPag.TYPE_VOUCHER
                                    "pix" -> PlugPag.TYPE_PIX
                                    else -> PlugPag.TYPE_CREDITO
                                }

                                // Crédito à vista: installmentType = 1 (A_VISTA), installmentAmount = 1
                                // SmartCoffee: PlugPagPaymentData(type, amount, installmentType, installmentAmount, userReference, printReceipt)
                                val paymentData = PlugPagPaymentData(
                                    paymentType,
                                    valorCentavos,
                                    1, // A_VISTA
                                    1, // 1 parcela
                                    referencia,
                                    true // imprimir comprovante
                                )

                                // SmartCoffee: plugpag.doPayment(...) — bloqueante, deve rodar fora da UI thread
                                val transactionResult: PlugPagTransactionResult = pp.doPayment(paymentData)

                                executandoPagamento = false

                                // Tratamento do resultado — SmartCoffee: result.errorCode
                                val resposta = montarResposta(transactionResult)

                                // Emite o resultado final via EventChannel também
                                emitirEvento(
                                    mapOf(
                                        "tipo" to "resultado",
                                        "status" to (resposta["status"] ?: "ERRO"),
                                        "mensagem" to (resposta["mensagem"] ?: ""),
                                        "eventCode" to -1
                                    )
                                )

                                // Tratar erros específicos — SmartCoffee: SV03 / PP1017 → abort
                                when (transactionResult.errorCode) {
                                    "SV03", "PP1017" -> {
                                        try { pp.abort() } catch (_: Exception) {}
                                    }
                                }

                                responderUiThread(result) {
                                    if (!resultadoEnviado) {
                                        resultadoEnviado = true
                                        result.success(resposta)
                                    }
                                }

                            } catch (e: Exception) {
                                executandoPagamento = false
                                println("PAGBANK: Erro na transação: ${e.message}")
                                emitirEvento(
                                    mapOf(
                                        "tipo" to "erro",
                                        "mensagem" to "Erro na transação: ${e.message}",
                                        "eventCode" to -1
                                    )
                                )
                                responderUiThread(result) {
                                    if (!resultadoEnviado) {
                                        resultadoEnviado = true
                                        result.success(
                                            mapOf(
                                                "status" to "ERRO",
                                                "aprovado" to false,
                                                "codigo" to "EXCEPTION",
                                                "codigoErro" to (e.message ?: "UNKNOWN"),
                                                "mensagem" to "Erro na transação: ${e.message}"
                                            )
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════
                    // cancelarPagamento
                    // SmartCoffee: abort()
                    // Direção: Flutter → Kotlin (comando de cancelamento)
                    // ═══════════════════════════════════════════════════
                    "cancelarPagamento" -> {
                        thread {
                            try {
                                val pp = getPlugPag(context)
                                pp.abort()
                                println("PAGBANK: abort() chamado com sucesso")
                                responderUiThread(result) {
                                    result.success(
                                        mapOf(
                                            "status" to "CANCELADO",
                                            "aprovado" to false,
                                            "codigo" to "ABORT",
                                            "codigoErro" to "0",
                                            "mensagem" to "Cancelamento solicitado"
                                        )
                                    )
                                }
                            } catch (e: Exception) {
                                println("PAGBANK: Erro ao cancelar: ${e.message}")
                                responderUiThread(result) {
                                    result.success(
                                        mapOf(
                                            "status" to "ERRO",
                                            "aprovado" to false,
                                            "codigo" to "ABORT_ERROR",
                                            "codigoErro" to (e.message ?: "UNKNOWN"),
                                            "mensagem" to "Erro ao cancelar: ${e.message}"
                                        )
                                    )
                                }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════
                    // Método não reconhecido
                    // ═══════════════════════════════════════════════════
                    else -> {
                        println("PAGBANK: método não implementado = ${call.method}")
                        result.notImplemented()
                    }
                }
            }

            println("PAGBANK: PagBankBridge configurado com sucesso")
        }

        /**
         * Monta a resposta para o Flutter baseado no PlugPagTransactionResult.
         * Códigos de erro documentados no SmartCoffee PaymentViewModel.
         */
        private fun montarResposta(tr: PlugPagTransactionResult): Map<String, Any?> {
            val errorCode = tr.errorCode ?: ""

            // "0000" = pagamento aprovado (SmartCoffee)
            val aprovado = errorCode == "0000"

            val status = when {
                aprovado -> "APROVADO"
                errorCode in listOf("C13", "B018") -> "CANCELADO"
                errorCode in listOf(
                    "R 05", "R 14", "R 51", "R 57", "R 59", "R 62", "R 63",
                    "R 65", "R 75", "R 78", "R 82", "R 91", "B024", "M3011", "R 55"
                ) -> "NEGADO"
                else -> "ERRO"
            }

            return mapOf(
                "status" to status,
                "aprovado" to aprovado,
                "codigo" to errorCode,
                "codigoErro" to errorCode,
                "mensagem" to (tr.message ?: ""),
                "transactionCode" to (tr.transactionCode ?: ""),
                "transactionId" to (tr.transactionId ?: ""),
                "date" to (tr.date ?: ""),
                "time" to (tr.time ?: ""),
                "hostNsu" to (tr.hostNsu ?: ""),
                "cardBrand" to (tr.cardBrand ?: ""),
                "bin" to (tr.bin ?: ""),
                "holder" to (tr.holder ?: ""),
                "terminalSerialNumber" to (tr.terminalSerialNumber ?: ""),
                "amount" to (tr.amount ?: ""),
                "availableBalance" to (tr.availableBalance ?: ""),
                "cardApplication" to (tr.cardApplication ?: ""),
                "label" to (tr.label ?: ""),
                "holderName" to (tr.holderName ?: "")
            )
        }

        /**
         * Executa callback na UI thread para MethodChannel.Result.
         * MethodChannel.Result DEVE ser respondido na main thread.
         * Usa try/catch para proteger contra resultado já enviado.
         */
        private fun responderUiThread(result: MethodChannel.Result, action: () -> Unit) {
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                try {
                    action()
                } catch (e: Exception) {
                    println("PAGBANK: Erro ao responder resultado: ${e.message}")
                }
            }
        }
    }
}

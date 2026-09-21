package com.un.mobile.pagbank

import android.content.Context
import android.content.pm.PackageManager
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPag
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagCustomPrinterLayout
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagEventData
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagEventListener
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagPaymentData
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagPrinterData
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagTransactionResult
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagVoidData
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

/**
 * PagBankBridge — Camada de integração Flutter → PlugPagServiceWrapper.
 *
 * Implementação fiel ao fluxo real do SmartCoffee oficial (PaymentViewModel.kt / OtherViewModel.kt).
 *
 * Arquitetura:
 *   Flutter/Dart → MethodChannel('unmobile/pagbank') → PagBankBridge → PlugPag → SmartPOS
 *   PlugPag → EventChannel('unmobile/pagbank/eventos') → Flutter/Dart
 *
 * Wrapper versão: 1.35.0
 *
 * Métodos implementados seguindo SmartCoffee:
 *   - verificarSmartPOS (hasRequirements + isServiceBusy)
 *   - realizarPagamento (doPayment bloqueante + PlugPagEventListener)
 *   - cancelarPagamento (abort)
 *   - estornarPagamento (voidPayment + PlugPagVoidData)
 *   - ultimaTransacao (getLastApprovedTransaction)
 *   - verificarAutenticacao (isAuthenticated)
 *   - iniciarAtivacao (startOnBoarding)
 *   - verificarServicoBusy (isServiceBusy)
 *   - reimprimirViaEstabelecimento (reprintStablishmentReceipt)
 *   - reimprimirViaCliente (reprintCustomerReceipt)
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
         * SmartCoffee: executingPayment
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
         * Verifica os pré-requisitos conforme SmartCoffee (PaymentViewModel.hasRequirements):
         * 1. PlugPagService instalado no terminal (getPackageInfo)
         * 2. Serviço autenticado (isAuthenticated) — se não, inicia onboarding
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
                "holderName" to (tr.holderName ?: ""),
                "paymentType" to (tr.paymentType ?: 0)
            )
        }

        /**
         * Executa callback na UI thread para MethodChannel.Result.
         * MethodChannel.Result DEVE ser respondido na main thread.
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

        /**
         * SmartCoffee: configura o PlugPagEventListener
         * Recebe os eventos de mensagens do serviço para instruir as ações do usuário.
         * EVENT_CODE_DIGIT_PASSWORD → monta string de '*'
         * EVENT_CODE_NO_PASSWORD → "Digite a senha"
         * Outros → customMessage do PlugPag
         */
        private fun configurarEventListener(pp: PlugPag) {
            pp.setEventListener(object : PlugPagEventListener {
                override fun onEvent(data: PlugPagEventData) {
                    println("PAGBANK EVENT: code=${data.eventCode} msg=${data.customMessage}")

                    val mensagem: String
                    val eventCode = data.eventCode ?: -1

                    when (eventCode) {
                        PlugPagEventData.EVENT_CODE_DIGIT_PASSWORD -> {
                            mensagem = "●"
                        }
                        PlugPagEventData.EVENT_CODE_NO_PASSWORD -> {
                            mensagem = "Digite a senha"
                        }
                        else -> {
                            mensagem = data.customMessage ?: ""
                        }
                    }

                    emitirEvento(
                        mapOf(
                            "tipo" to "status",
                            "mensagem" to mensagem,
                            "eventCode" to eventCode
                        )
                    )
                }
            })
        }

        /**
         * SmartCoffee: configura o popup de impressão da via do cliente
         * setPlugPagCustomPrinterLayout
         */
        private fun configurarLayoutImpressao(pp: PlugPag) {
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
        }

        /**
         * Registra o handler do MethodChannel e o EventChannel.
         * Chamado uma única vez durante o configureFlutterEngine.
         */
        fun configurar(channel: MethodChannel, eventChannel: EventChannel, context: Context) {

            println("PAGBANK: PagBankBridge configurando...")

            // ── EventChannel: gerencia o lifecycle do sink ──
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
                    // SmartCoffee: hasRequirements + isServiceBusy
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
                    // verificarAutenticacao
                    // SmartCoffee: isAuthenticated
                    // ═══════════════════════════════════════════════════
                    "verificarAutenticacao" -> {
                        thread {
                            try {
                                val pp = getPlugPag(context)
                                val autenticado = pp.isAuthenticated()
                                responderUiThread(result) { result.success(autenticado) }
                            } catch (e: Exception) {
                                println("PAGBANK: verificarAutenticacao erro: ${e.message}")
                                responderUiThread(result) { result.success(false) }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════
                    // iniciarAtivacao
                    // SmartCoffee: startOnBoarding
                    // ═══════════════════════════════════════════════════
                    "iniciarAtivacao" -> {
                        thread {
                            try {
                                val pp = getPlugPag(context)
                                pp.startOnBoarding()
                                responderUiThread(result) {
                                    result.success(
                                        mapOf(
                                            "status" to "OK",
                                            "mensagem" to "Onboarding iniciado"
                                        )
                                    )
                                }
                            } catch (e: Exception) {
                                println("PAGBANK: iniciarAtivacao erro: ${e.message}")
                                responderUiThread(result) {
                                    result.success(
                                        mapOf(
                                            "status" to "ERRO",
                                            "mensagem" to "Erro ao iniciar ativação: ${e.message}"
                                        )
                                    )
                                }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════
                    // verificarServicoBusy
                    // SmartCoffee: isServiceBusy
                    // ═══════════════════════════════════════════════════
                    "verificarServicoBusy" -> {
                        thread {
                            try {
                                val pp = getPlugPag(context)
                                val busy = pp.isServiceBusy
                                responderUiThread(result) { result.success(busy) }
                            } catch (e: Exception) {
                                println("PAGBANK: verificarServicoBusy erro: ${e.message}")
                                responderUiThread(result) { result.success(false) }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════
                    // realizarPagamento
                    // SmartCoffee: doPay() → doPayment(PlugPagPaymentData)
                    // BLOQUEANTE — roda em thread separada
                    // ═══════════════════════════════════════════════════
                    "realizarPagamento" -> {

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

                        // SmartCoffee: MIN_AMOUNT = 1_00
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
                        var resultadoEnviado = false

                        emitirEvento(
                            mapOf(
                                "tipo" to "status",
                                "mensagem" to "Iniciando pagamento...",
                                "eventCode" to -1
                            )
                        )

                        // SmartCoffee: viewModelScope.launch(Dispatchers.Default)
                        thread {
                            try {
                                val pp = getPlugPag(context)
                                val pm = context.packageManager

                                // SmartCoffee: hasRequirements
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

                                // SmartCoffee: plugpag.setEventListener
                                configurarEventListener(pp)

                                // SmartCoffee: setPlugPagCustomPrinterLayout
                                configurarLayoutImpressao(pp)

                                // SmartCoffee: mapear tipo → constante PlugPag
                                val paymentType = when (tipo) {
                                    "credito" -> PlugPag.TYPE_CREDITO
                                    "debito" -> PlugPag.TYPE_DEBITO
                                    "voucher" -> PlugPag.TYPE_VOUCHER
                                    "pix" -> PlugPag.TYPE_PIX
                                    else -> PlugPag.TYPE_CREDITO
                                }

                                // SmartCoffee: PlugPagPaymentData(type, amount, installmentType, installmentAmount, userReference, printReceipt)
                                val paymentData = PlugPagPaymentData(
                                    paymentType,
                                    valorCentavos,
                                    1, // A_VISTA
                                    1, // 1 parcela
                                    referencia,
                                    true
                                )

                                // SmartCoffee: plugpag.doPayment(...) — bloqueante
                                val transactionResult: PlugPagTransactionResult = pp.doPayment(paymentData)

                                executandoPagamento = false

                                val resposta = montarResposta(transactionResult)

                                // Emite resultado final via EventChannel
                                emitirEvento(
                                    mapOf(
                                        "tipo" to "resultado",
                                        "status" to (resposta["status"] ?: "ERRO"),
                                        "aprovado" to (resposta["aprovado"] ?: false),
                                        "mensagem" to (resposta["mensagem"] ?: ""),
                                        "eventCode" to -1,
                                        "transactionCode" to (resposta["transactionCode"] ?: ""),
                                        "transactionId" to (resposta["transactionId"] ?: "")
                                    )
                                )

                                // SmartCoffee: tratar SV03 / PP1017 → abort
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
                    // ultimaTransacao
                    // SmartCoffee OtherViewModel: getLastApprovedTransaction()
                    // ═══════════════════════════════════════════════════
                    "ultimaTransacao" -> {
                        thread {
                            try {
                                val pp = getPlugPag(context)
                                val lastTx = pp.getLastApprovedTransaction()

                                val temDados = lastTx.result != null &&
                                        lastTx.transactionCode?.isNotEmpty() == true &&
                                        lastTx.transactionId?.isNotEmpty() == true &&
                                        lastTx.amount?.isNotEmpty() == true

                                if (temDados) {
                                    responderUiThread(result) {
                                        result.success(montarResposta(lastTx))
                                    }
                                } else {
                                    responderUiThread(result) {
                                        result.success(
                                            mapOf(
                                                "status" to "VAZIO",
                                                "aprovado" to false,
                                                "codigo" to "NO_TRANSACTION",
                                                "codigoErro" to "NO_TRANSACTION",
                                                "mensagem" to "Nenhuma transação aprovada encontrada"
                                            )
                                        )
                                    }
                                }
                            } catch (e: Exception) {
                                println("PAGBANK: ultimaTransacao erro: ${e.message}")
                                responderUiThread(result) {
                                    result.success(
                                        mapOf(
                                            "status" to "ERRO",
                                            "aprovado" to false,
                                            "codigo" to "EXCEPTION",
                                            "codigoErro" to (e.message ?: "UNKNOWN"),
                                            "mensagem" to "Erro ao buscar última transação: ${e.message}"
                                        )
                                    )
                                }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════
                    // estornarPagamento
                    // SmartCoffee OtherViewModel: voidPayment(PlugPagVoidData)
                    //   Requer transactionCode + transactionId da transação original
                    // ═══════════════════════════════════════════════════
                    "estornarPagamento" -> {
                        val transactionCode = call.argument<String>("transactionCode") ?: ""
                        val transactionId = call.argument<String>("transactionId") ?: ""
                        val tipoOriginal = call.argument<Int>("paymentType") ?: 0

                        if (transactionCode.isEmpty() || transactionId.isEmpty()) {
                            result.success(
                                mapOf(
                                    "status" to "ERRO",
                                    "aprovado" to false,
                                    "codigo" to "MISSING_DATA",
                                    "codigoErro" to "MISSING_DATA",
                                    "mensagem" to "transactionCode e transactionId são obrigatórios"
                                )
                            )
                            return@setMethodCallHandler
                        }

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

                        executandoPagamento = true
                        var resultadoEnviado = false

                        thread {
                            try {
                                val pp = getPlugPag(context)
                                val pm = context.packageManager

                                val erroRequisito = verificarRequisitos(pp, pm)
                                if (erroRequisito != null) {
                                    executandoPagamento = false
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

                                // SmartCoffee: configura listener e layout para estorno
                                configurarEventListener(pp)
                                configurarLayoutImpressao(pp)

                                // SmartCoffee: voidType depende do tipo original
                                val voidType = when (tipoOriginal) {
                                    PlugPag.TYPE_PIX -> PlugPag.VOID_QRCODE
                                    else -> PlugPag.VOID_PAYMENT
                                }

                                // SmartCoffee: plugpag.voidPayment(PlugPagVoidData(...))
                                val voidResult = pp.voidPayment(
                                    PlugPagVoidData(
                                        transactionCode = transactionCode,
                                        transactionId = transactionId,
                                        voidType = voidType,
                                        printReceipt = true
                                    )
                                )

                                executandoPagamento = false

                                val resposta = montarResposta(voidResult)

                                emitirEvento(
                                    mapOf(
                                        "tipo" to "resultado",
                                        "status" to (resposta["status"] ?: "ERRO"),
                                        "aprovado" to (resposta["aprovado"] ?: false),
                                        "mensagem" to (resposta["mensagem"] ?: ""),
                                        "eventCode" to -1
                                    )
                                )

                                responderUiThread(result) {
                                    if (!resultadoEnviado) {
                                        resultadoEnviado = true
                                        result.success(resposta)
                                    }
                                }

                            } catch (e: Exception) {
                                executandoPagamento = false
                                println("PAGBANK: Erro no estorno: ${e.message}")
                                responderUiThread(result) {
                                    if (!resultadoEnviado) {
                                        resultadoEnviado = true
                                        result.success(
                                            mapOf(
                                                "status" to "ERRO",
                                                "aprovado" to false,
                                                "codigo" to "EXCEPTION",
                                                "codigoErro" to (e.message ?: "UNKNOWN"),
                                                "mensagem" to "Erro no estorno: ${e.message}"
                                            )
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════
                    // reimprimirViaEstabelecimento
                    // SmartCoffee OtherViewModel: reprintStablishmentReceipt()
                    // ═══════════════════════════════════════════════════
                    "reimprimirViaEstabelecimento" -> {
                        thread {
                            try {
                                val pp = getPlugPag(context)
                                pp.reprintStablishmentReceipt()
                                responderUiThread(result) {
                                    result.success(
                                        mapOf(
                                            "status" to "OK",
                                            "mensagem" to "Via do estabelecimento reimpressa"
                                        )
                                    )
                                }
                            } catch (e: Exception) {
                                println("PAGBANK: reimprimirViaEstabelecimento erro: ${e.message}")
                                responderUiThread(result) {
                                    result.success(
                                        mapOf(
                                            "status" to "ERRO",
                                            "mensagem" to "Erro ao reimprimir: ${e.message}"
                                        )
                                    )
                                }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════
                    // reimprimirViaCliente
                    // SmartCoffee OtherViewModel: reprintCustomerReceipt()
                    // ═══════════════════════════════════════════════════
                    "reimprimirViaCliente" -> {
                        thread {
                            try {
                                val pp = getPlugPag(context)
                                pp.reprintCustomerReceipt()
                                responderUiThread(result) {
                                    result.success(
                                        mapOf(
                                            "status" to "OK",
                                            "mensagem" to "Via do cliente reimpressa"
                                        )
                                    )
                                }
                            } catch (e: Exception) {
                                println("PAGBANK: reimprimirViaCliente erro: ${e.message}")
                                responderUiThread(result) {
                                    result.success(
                                        mapOf(
                                            "status" to "ERRO",
                                            "mensagem" to "Erro ao reimprimir: ${e.message}"
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
    }
}

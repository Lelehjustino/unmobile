package com.un.mobile.stone

import io.flutter.plugin.common.MethodChannel

/**
 * StoneBridge — Camada de integração Flutter → Stone SDK.
 *
 * Responsável por receber chamadas do Flutter via [MethodChannel]
 * e encaminhar para o SDK da Stone (quando integrado).
 *
 * Arquitetura:
 *   Flutter/Dart  →  MethodChannel('unmobile/stone')  →  StoneBridge  →  Stone SDK
 *
 * NOTA: A integração real com o SDK da Stone deve ser feita nesta classe.
 * Atualmente os métodos retornam STONE_NAO_CONFIGURADA como placeholder.
 * Para ativar a integração real, adicione o SDK da Stone ao build.gradle.kts
 * e implemente os métodos usando as classes oficiais do SDK.
 */
class StoneBridge {

    companion object {

        /**
         * Registra o handler do MethodChannel.
         * Chamado uma única vez durante a inicialização do FlutterEngine.
         */
        fun configurar(channel: MethodChannel) {

            println("STONE: StoneBridge configurado")

            channel.setMethodCallHandler { call, result ->

                println("STONE: método recebido = ${call.method}")

                when (call.method) {

                    // ─────────────────────────────────────────────────────
                    // Verifica se a integração Stone está disponível.
                    // Flutter: StoneService.verificarStone()
                    // ─────────────────────────────────────────────────────
                    "verificarStone" -> {
                        // TODO: retornar true quando o SDK Stone estiver configurado.
                        result.success(false)
                    }

                    // ─────────────────────────────────────────────────────
                    // Inicia uma transação de pagamento.
                    // Flutter: StoneService().pagar(valor: ..., referencia: ...)
                    //
                    // Parâmetros recebidos:
                    //   valor      (Int)    — valor em centavos
                    //   referencia (String) — identificador da venda
                    //
                    // Retorno esperado:
                    //   sucesso  (Boolean) — true se aprovado
                    //   codigo   (String)  — código da transação ou erro
                    //   mensagem (String)  — descrição legível
                    // ─────────────────────────────────────────────────────
                    "pagar" -> {

                        val valor = call.argument<Int>("valor")
                        val referencia = call.argument<String>("referencia")

                        println("STONE: pagamento solicitado")
                        println("STONE: Valor = $valor centavos")
                        println("STONE: Referência = $referencia")

                        // TODO: Substituir pelo código real do SDK Stone.
                        // Exemplo com SDK real:
                        //   val transacao = StoneTransaction()
                        //   transacao.amount = valor?.toLong() ?: 0L
                        //   transacao.shortName = referencia ?: ""
                        //   StoneStart.startTransaction(context, transacao) { response ->
                        //       result.success(mapOf("sucesso" to response.isApproved, "codigo" to response.authorizationCode))
                        //   }
                        result.success(
                            mapOf(
                                "sucesso" to false,
                                "codigo" to "STONE_NAO_CONFIGURADA",
                                "mensagem" to "Integração Stone ainda não configurada. Adicione o SDK ao build.gradle.kts."
                            )
                        )
                    }

                    // ─────────────────────────────────────────────────────
                    // Cancela uma transação existente.
                    // Flutter: StoneService.cancelar(transacaoId: ...)
                    //
                    // Parâmetros:
                    //   transacaoId (String) — ID da transação a cancelar
                    // ─────────────────────────────────────────────────────
                    "cancelar" -> {

                        val transacaoId = call.argument<String>("transacaoId")

                        println("STONE: cancelamento solicitado")
                        println("STONE: Transação = $transacaoId")

                        // TODO: Substituir pelo código real de cancelamento do SDK Stone.
                        result.success(
                            mapOf(
                                "sucesso" to false,
                                "codigo" to "STONE_NAO_CONFIGURADA",
                                "mensagem" to "Integração Stone ainda não configurada. Adicione o SDK ao build.gradle.kts."
                            )
                        )
                    }

                    // ─────────────────────────────────────────────────────
                    // Verifica o status de uma transação.
                    // Flutter: StoneService.verificarStatusTransacao(transacaoId: ...)
                    // ─────────────────────────────────────────────────────
                    "verificarStatusTransacao" -> {

                        val transacaoId = call.argument<String>("transacaoId")

                        println("STONE: verificação de status solicitada")
                        println("STONE: Transação = $transacaoId")

                        result.success(
                            mapOf(
                                "sucesso" to false,
                                "codigo" to "STONE_NAO_CONFIGURADA",
                                "mensagem" to "Integração Stone ainda não configurada."
                            )
                        )
                    }

                    // ─────────────────────────────────────────────────────
                    // Método não reconhecido
                    // ─────────────────────────────────────────────────────
                    else -> {
                        println("STONE: método não implementado = ${call.method}")
                        result.notImplemented()
                    }
                }
            }
        }
    }
}

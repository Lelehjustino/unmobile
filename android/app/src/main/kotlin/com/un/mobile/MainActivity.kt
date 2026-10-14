package com.un.mobile

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.un.mobile.stone.StoneBridge
import com.un.mobile.pagbank.PagBankBridge
import com.un.mobile.cielo.CieloBridge
import com.un.mobile.payment.PaymentDetector

class MainActivity : FlutterActivity() {

    private val CHANNEL = "unmobile/stone"
    private val MOBILE_ID_CHANNEL = "com.un.mobile/mobile_id"
    private val PAGBANK_CHANNEL = "unmobile/pagbank"
    private val PAGBANK_EVENTOS_CHANNEL = "unmobile/pagbank/eventos"
    private val CIELO_CHANNEL = "unmobile/cielo"
    private val PAYMENT_DETECTOR_CHANNEL = "unmobile/payment_detector"

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        println("STONE: MainActivity inicializada")

        // ── Stone MethodChannel (existente) ──
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        StoneBridge.configurar(channel)

        // ── Mobile ID MethodChannel (existente) ──
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MOBILE_ID_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "getNativeId") {
                val androidId = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
                if (androidId != null) {
                    result.success(androidId)
                } else {
                    result.error("UNAVAILABLE", "Android ID not available.", null)
                }
            } else {
                result.notImplemented()
            }
        }

        // ── PagBank SmartPOS MethodChannel + EventChannel ──
        val pagbankChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PAGBANK_CHANNEL
        )

        val pagbankEventosChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PAGBANK_EVENTOS_CHANNEL
        )

        PagBankBridge.configurar(pagbankChannel, pagbankEventosChannel, this)

        println("STONE: StoneBridge registrado")
        println("PAGBANK: PagBankBridge registrado")

        // ── Cielo Smart Deep Link MethodChannel ──
        val cieloChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CIELO_CHANNEL
        )
        CieloBridge.configurar(cieloChannel, this)
        println("CIELO: CieloBridge registrado")

        // ── Payment Detector MethodChannel ──
        val detectorChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PAYMENT_DETECTOR_CHANNEL
        )
        PaymentDetector.configurar(detectorChannel, this)
        println("PAYMENT DETECTOR: registrado")
    }

    // ── Tratamento do intent inicial ────────────────────────────────────────
    // Cenário: o sistema recriou a Activity (o app foi para background e o
    // Android o destruiu). Nesse caso o callback `unmobile://cielo` chega
    // via onCreate, NÃO via onNewIntent. Processamos aqui para garantir que
    // o Completer do CieloPaymentService seja resolvido mesmo nesse caso.
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Só processa se vier do scheme unmobile://cielo (evita loop na rota normal)
        val intentData = intent?.data
        if (intentData?.scheme == "unmobile" && intentData.host == "cielo") {
            println("CIELO: intent inicial detectado em onCreate → processando")
            CieloBridge.processarRetorno(intent)
            // Consome o intent para não ser reprocessado em onResume
            intent = Intent()
        }
    }

    // ── Tratamento singleTop: Activity já no topo ────────────────────────────
    // Cenário normal: launchMode=singleTop mantém a Activity viva; o retorno
    // da Cielo chega aqui.
    //
    // IMPORTANTE: para intents Cielo (unmobile://cielo), passamos Intent() vazio
    // ao super.onNewIntent, pois o FlutterActivity interpreta qualquer URI de
    // ACTION_VIEW como deep link e dispara pushRoute("/") internamente — o que
    // faz o GetX navegar para a rota "/" = CheckinPage antes da nossa lógica
    // rodar. Ao neutralizar o intent para o super, o roteamento automático do
    // Flutter não ocorre e o CieloBridge entrega o resultado pelo MethodChannel.
    override fun onNewIntent(intent: Intent) {
        val isCieloCallback = (intent.action == Intent.ACTION_VIEW
                && intent.data?.scheme == "unmobile"
                && intent.data?.host == "cielo")

        if (isCieloCallback) {
            // Passa intent vazio ao super para evitar pushRoute("/") automático
            super.onNewIntent(Intent())
        } else {
            super.onNewIntent(intent)
        }

        setIntent(intent)
        CieloBridge.processarRetorno(intent)
        // Consome o intent para não reprocessar em retomadas futuras
        this.intent = Intent()
    }
}
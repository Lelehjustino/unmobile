package com.un.mobile

import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.un.mobile.stone.StoneBridge
import com.un.mobile.pagbank.PagBankBridge

class MainActivity : FlutterActivity() {

    private val CHANNEL = "unmobile/stone"
    private val MOBILE_ID_CHANNEL = "com.un.mobile/mobile_id"
    private val PAGBANK_CHANNEL = "unmobile/pagbank"
    private val PAGBANK_EVENTOS_CHANNEL = "unmobile/pagbank/eventos"

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
    }
}
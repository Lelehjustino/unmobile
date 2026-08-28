package com.un.mobile

import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.un.mobile.stone.StoneBridge

class MainActivity : FlutterActivity() {

    private val CHANNEL = "unmobile/stone"
    private val MOBILE_ID_CHANNEL = "com.un.mobile/mobile_id"

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        println("STONE: MainActivity inicializada")

        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        StoneBridge.configurar(channel)

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

        println("STONE: StoneBridge registrado")
    }
}
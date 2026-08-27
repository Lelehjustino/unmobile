package com.un.mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.un.mobile.stone.StoneBridge

class MainActivity : FlutterActivity() {

    private val CHANNEL = "unmobile/stone"

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

        println("STONE: StoneBridge registrado")
    }
}
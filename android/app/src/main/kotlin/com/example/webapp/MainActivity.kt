package com.example.webapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.webapp/fg"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val title = call.argument<String>("title") ?: "Processing"
                    val text = call.argument<String>("text") ?: "Working..."
                    ForegroundService.start(this, title, text, 0)
                    result.success(true)
                }
                "update" -> {
                    val progress = call.argument<Int>("progress") ?: 0
                    val stage = call.argument<String>("stage") ?: ""
                    ForegroundService.update(this, stage, progress)
                    result.success(true)
                }
                "stop" -> {
                    ForegroundService.stop(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}

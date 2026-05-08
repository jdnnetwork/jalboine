package com.example.jalboine

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.jalboine/sound_mode"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setRingerMode" -> {
                        val mode = call.argument<String>("mode")
                        val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        when (mode) {
                            "sound" -> {
                                am.ringerMode = AudioManager.RINGER_MODE_NORMAL
                                result.success(true)
                            }
                            "vibrate" -> {
                                am.ringerMode = AudioManager.RINGER_MODE_VIBRATE
                                result.success(true)
                            }
                            else -> result.error("INVALID_MODE", "unknown mode: $mode", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}

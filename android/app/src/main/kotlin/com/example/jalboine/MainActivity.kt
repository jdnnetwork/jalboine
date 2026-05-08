package com.example.jalboine

import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val soundChannelName = "com.jalboine/sound_mode"
    private val onboardingChannelName = "com.jalboine/onboarding"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, soundChannelName)
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, onboardingChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isDefaultLauncher" -> result.success(isDefaultLauncher())
                    "requestDefaultLauncher" -> {
                        try {
                            requestDefaultLauncher()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("LAUNCHER_REQUEST_FAILED", e.message, null)
                        }
                    }
                    "isIgnoringBatteryOptimizations" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                            intent.data = Uri.parse("package:$packageName")
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            // 폴백: 배터리 최적화 설정 화면
                            try {
                                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                                startActivity(intent)
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("BATTERY_REQUEST_FAILED", e2.message, null)
                            }
                        }
                    }
                    "getSdkInt" -> result.success(Build.VERSION.SDK_INT)
                    else -> result.notImplemented()
                }
            }
    }

    private fun isDefaultLauncher(): Boolean {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        val info = packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
        return info?.activityInfo?.packageName == packageName
    }

    private fun requestDefaultLauncher() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val rm = getSystemService(Context.ROLE_SERVICE) as RoleManager
            if (rm.isRoleAvailable(RoleManager.ROLE_HOME)) {
                if (!rm.isRoleHeld(RoleManager.ROLE_HOME)) {
                    val intent = rm.createRequestRoleIntent(RoleManager.ROLE_HOME)
                    startActivity(intent)
                    return
                }
            }
        }
        // <Q 또는 ROLE_HOME 미사용: 시스템 홈 설정으로 보냄
        try {
            val intent = Intent(Settings.ACTION_HOME_SETTINGS)
            startActivity(intent)
        } catch (_: Exception) {
            // 마지막 폴백: HOME chooser
            val pickIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
            startActivity(Intent.createChooser(pickIntent, null))
        }
    }
}

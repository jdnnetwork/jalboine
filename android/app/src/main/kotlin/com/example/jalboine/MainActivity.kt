package com.example.jalboine

import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.CallLog
import android.provider.ContactsContract
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val soundChannelName = "com.jalboine/sound_mode"
    private val onboardingChannelName = "com.jalboine/onboarding"
    private val callLogChannelName = "com.jalboine/call_log"
    private val volumeChannelName = "com.jalboine/volume"
    private val requestCodeHomeRole = 0xA001

    // 강제 울리기 직전 볼륨을 저장해두기
    private var savedMusicVolume: Int? = null
    private var savedRingVolume: Int? = null

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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, volumeChannelName)
            .setMethodCallHandler { call, result ->
                val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                when (call.method) {
                    "setMaxVolume" -> {
                        try {
                            if (savedMusicVolume == null) {
                                savedMusicVolume = am.getStreamVolume(AudioManager.STREAM_MUSIC)
                                savedRingVolume = am.getStreamVolume(AudioManager.STREAM_RING)
                            }
                            val maxMusic = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                            val maxRing = am.getStreamMaxVolume(AudioManager.STREAM_RING)
                            am.setStreamVolume(AudioManager.STREAM_MUSIC, maxMusic, 0)
                            am.setStreamVolume(AudioManager.STREAM_RING, maxRing, 0)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("VOLUME_ERROR", e.message, null)
                        }
                    }
                    "restoreVolume" -> {
                        try {
                            savedMusicVolume?.let {
                                am.setStreamVolume(AudioManager.STREAM_MUSIC, it, 0)
                            }
                            savedRingVolume?.let {
                                am.setStreamVolume(AudioManager.STREAM_RING, it, 0)
                            }
                            savedMusicVolume = null
                            savedRingVolume = null
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("VOLUME_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, callLogChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getRecentCalls" -> {
                        val sinceMs = (call.argument<Number>("sinceMs"))?.toLong() ?: 0L
                        try {
                            result.success(getRecentCalls(sinceMs))
                        } catch (e: SecurityException) {
                            result.error("PERMISSION_DENIED", e.message, null)
                        } catch (e: Exception) {
                            result.error("CALL_LOG_ERROR", e.message, null)
                        }
                    }
                    "isKnownNumber" -> {
                        val number = call.argument<String>("number") ?: ""
                        try {
                            result.success(isKnownNumber(number))
                        } catch (e: SecurityException) {
                            result.error("PERMISSION_DENIED", e.message, null)
                        } catch (e: Exception) {
                            result.error("CONTACTS_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * sinceMs(epoch ms) 이후의 통화 기록을 최신 → 오래된 순으로 반환.
     * 발신/수신/부재중 모두 포함. number, timestampMs, durationSec, type 키.
     */
    private fun getRecentCalls(sinceMs: Long): List<Map<String, Any?>> {
        val out = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            CallLog.Calls.NUMBER,
            CallLog.Calls.DATE,
            CallLog.Calls.DURATION,
            CallLog.Calls.TYPE,
        )
        val selection = "${CallLog.Calls.DATE} > ?"
        val args = arrayOf(sinceMs.toString())
        val cursor = contentResolver.query(
            CallLog.Calls.CONTENT_URI,
            projection,
            selection,
            args,
            "${CallLog.Calls.DATE} DESC",
        ) ?: return out
        cursor.use { c ->
            val iNumber = c.getColumnIndex(CallLog.Calls.NUMBER)
            val iDate = c.getColumnIndex(CallLog.Calls.DATE)
            val iDur = c.getColumnIndex(CallLog.Calls.DURATION)
            val iType = c.getColumnIndex(CallLog.Calls.TYPE)
            while (c.moveToNext()) {
                out.add(
                    mapOf(
                        "number" to (c.getString(iNumber) ?: ""),
                        "timestampMs" to c.getLong(iDate),
                        "durationSec" to c.getInt(iDur),
                        "type" to c.getInt(iType),
                    )
                )
            }
        }
        return out
    }

    /**
     * 주어진 번호가 연락처에 등록돼 있으면 true.
     * 빈 문자열/null → 알 수 없음으로 처리해 true 반환 (오탐 방지).
     */
    private fun isKnownNumber(number: String): Boolean {
        if (number.isBlank()) return true
        val uri = Uri.withAppendedPath(
            ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
            Uri.encode(number),
        )
        val cursor = contentResolver.query(
            uri,
            arrayOf(ContactsContract.PhoneLookup._ID),
            null,
            null,
            null,
        ) ?: return false
        cursor.use { c -> return c.moveToFirst() }
    }

    private fun isDefaultLauncher(): Boolean {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        val info = packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
        return info?.activityInfo?.packageName == packageName
    }

    private fun requestDefaultLauncher() {
        // 1) Android Q+ : RoleManager.ROLE_HOME — 반드시 startActivityForResult 사용
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val rm = getSystemService(Context.ROLE_SERVICE) as RoleManager
                if (rm.isRoleAvailable(RoleManager.ROLE_HOME) &&
                    !rm.isRoleHeld(RoleManager.ROLE_HOME)) {
                    val intent = rm.createRequestRoleIntent(RoleManager.ROLE_HOME)
                    startActivityForResult(intent, requestCodeHomeRole)
                    return
                }
            } catch (_: Exception) {
                // 폴백으로 떨어짐
            }
        }
        // 2) 폴백: 시스템 홈 설정 화면
        try {
            startActivity(Intent(Settings.ACTION_HOME_SETTINGS))
            return
        } catch (_: Exception) {
            // 다음 폴백
        }
        // 3) 마지막 폴백: HOME chooser
        try {
            val pickIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
            startActivity(Intent.createChooser(pickIntent, null))
        } catch (_: Exception) {
            // 어떤 폴백도 안 되면 그냥 무시 (Dart 쪽이 다음 화면으로 진행)
        }
    }
}

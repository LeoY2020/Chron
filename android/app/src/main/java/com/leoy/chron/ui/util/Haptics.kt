package com.leoy.chron.ui.util

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext

/** Graded haptic intensities. */
enum class HapticLevel { LIGHT, MEDIUM, HEAVY }

/**
 * Graded haptics. Degrades to silence when vibration is unavailable, when the
 * user disabled haptic feedback, or when "remove animations" is on.
 */
class Haptics(context: Context) {

    private val appContext = context.applicationContext

    private val vibrator: Vibrator? = runCatching {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = appContext.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            manager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            appContext.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }.getOrNull()

    fun perform(level: HapticLevel) {
        if (isReduceMotion(appContext)) return
        if (!hapticsEnabled(appContext)) return
        val vibrator = vibrator ?: return
        if (!vibrator.hasVibrator()) return
        val amplitude: Int
        val durationMs: Long
        when (level) {
            HapticLevel.LIGHT -> { amplitude = 40; durationMs = 8L }
            HapticLevel.MEDIUM -> { amplitude = 120; durationMs = 14L }
            HapticLevel.HEAVY -> { amplitude = 220; durationMs = 24L }
        }
        runCatching {
            vibrator.vibrate(VibrationEffect.createOneShot(durationMs, amplitude))
        }
    }
}

private fun hapticsEnabled(context: Context): Boolean =
    Settings.System.getInt(context.contentResolver, Settings.System.HAPTIC_FEEDBACK_ENABLED, 1) == 1

@Composable
fun rememberHaptics(): Haptics {
    val context = LocalContext.current
    return remember(context) { Haptics(context) }
}
package com.leoy.chron.ui.util

import androidx.compose.ui.graphics.Color
import java.util.Calendar

/** Phase of day used to label the Sun clock. */
enum class SunPhase(val label: String) {
    NIGHT("Night"),
    DAWN("Dawn"),
    DAY("Day"),
    DUSK("Dusk")
}

/** A resolved time-of-day palette. */
data class SunPalette(
    val top: Color,
    val bottom: Color,
    val accent: Color,
    val glyph: Color,
    val phase: SunPhase
)

/**
 * Generates a background / foreground light preset from the current time and
 * interpolates smoothly between presets (never abrupt). Ported from the iOS
 * SunStyleProvider.
 */
object SunStyleProvider {

    private data class Rgb(val r: Double, val g: Double, val b: Double)

    private data class Keyframe(
        val hour: Double,
        val top: Rgb,
        val bottom: Rgb,
        val accent: Rgb,
        val glyph: Rgb,
        val phase: SunPhase
    )

    /** Keyframes ascend by hour; 0 and 24 share a colour for a seamless wrap. */
    private val keyframes = listOf(
        Keyframe(0.0, Rgb(9.0, 11.0, 22.0), Rgb(2.0, 3.0, 8.0), Rgb(96.0, 116.0, 176.0), Rgb(222.0, 230.0, 255.0), SunPhase.NIGHT),
        Keyframe(5.0, Rgb(16.0, 16.0, 30.0), Rgb(4.0, 4.0, 12.0), Rgb(140.0, 120.0, 170.0), Rgb(232.0, 232.0, 248.0), SunPhase.NIGHT),
        Keyframe(7.0, Rgb(48.0, 32.0, 52.0), Rgb(12.0, 12.0, 26.0), Rgb(244.0, 156.0, 112.0), Rgb(255.0, 230.0, 214.0), SunPhase.DAWN),
        Keyframe(12.0, Rgb(26.0, 44.0, 78.0), Rgb(10.0, 16.0, 34.0), Rgb(122.0, 192.0, 255.0), Rgb(242.0, 248.0, 255.0), SunPhase.DAY),
        Keyframe(16.0, Rgb(30.0, 44.0, 70.0), Rgb(10.0, 15.0, 30.0), Rgb(255.0, 196.0, 120.0), Rgb(248.0, 246.0, 240.0), SunPhase.DAY),
        Keyframe(19.0, Rgb(62.0, 36.0, 50.0), Rgb(14.0, 10.0, 22.0), Rgb(255.0, 150.0, 92.0), Rgb(255.0, 226.0, 202.0), SunPhase.DUSK),
        Keyframe(21.0, Rgb(24.0, 20.0, 38.0), Rgb(6.0, 6.0, 16.0), Rgb(150.0, 130.0, 190.0), Rgb(236.0, 232.0, 250.0), SunPhase.NIGHT),
        Keyframe(24.0, Rgb(9.0, 11.0, 22.0), Rgb(2.0, 3.0, 8.0), Rgb(96.0, 116.0, 176.0), Rgb(222.0, 230.0, 255.0), SunPhase.NIGHT)
    )

    fun paletteFor(millis: Long): SunPalette {
        val cal = Calendar.getInstance()
        cal.timeInMillis = millis
        val t = cal.get(Calendar.HOUR_OF_DAY).toDouble() + cal.get(Calendar.MINUTE).toDouble() / 60.0

        var lower = keyframes.first()
        var upper = keyframes.last()
        for (i in 0 until keyframes.size - 1) {
            if (t >= keyframes[i].hour && t <= keyframes[i + 1].hour) {
                lower = keyframes[i]
                upper = keyframes[i + 1]
                break
            }
        }
        val span = maxOf(0.0001, upper.hour - lower.hour)
        val raw = (t - lower.hour) / span
        val k = smoothstep(raw)

        return SunPalette(
            top = mix(lower.top, upper.top, k),
            bottom = mix(lower.bottom, upper.bottom, k),
            accent = mix(lower.accent, upper.accent, k),
            glyph = mix(lower.glyph, upper.glyph, k),
            phase = if (raw < 0.5) lower.phase else upper.phase
        )
    }

    private fun smoothstep(x: Double): Double {
        val c = x.coerceIn(0.0, 1.0)
        return c * c * (3 - 2 * c)
    }

    private fun mix(a: Rgb, b: Rgb, k: Double): Color = Color(
        red = ((a.r + (b.r - a.r) * k) / 255.0).toFloat(),
        green = ((a.g + (b.g - a.g) * k) / 255.0).toFloat(),
        blue = ((a.b + (b.b - a.b) * k) / 255.0).toFloat(),
        alpha = 1f
    )
}
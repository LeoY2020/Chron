package com.leoy.chron.data

import com.leoy.chron.model.ClockStyle
import com.leoy.chron.model.CountdownStyle

/**
 * All persisted user preferences. Colours are stored as ARGB longs so they can
 * round-trip through SharedPreferences without any extra dependency.
 */
data class ChronSettings(
    val countdownStyle: CountdownStyle = CountdownStyle.RING,
    val clockStyle: ClockStyle = ClockStyle.ANALOG,
    val countdownDurationMs: Long = 5 * 60_000L,
    val countdownColor: Long = 0xFFF5F5F7L,
    val clockColor: Long = 0xFFF5F5F7L,
    val backgroundOpacity: Float = 0f,
    val ringThickness: Float = 10f,
    val pomodoroFocusMs: Long = 25 * 60_000L,
    val pomodoroBreakMs: Long = 5 * 60_000L
)
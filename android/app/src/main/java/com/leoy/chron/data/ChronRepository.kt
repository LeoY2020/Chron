package com.leoy.chron.data

import android.content.Context
import com.leoy.chron.model.ClockStyle
import com.leoy.chron.model.CountdownStyle
import com.leoy.chron.model.FocusSession
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.json.JSONArray
import org.json.JSONObject

/**
 * Persistence for settings and pomodoro session history.
 *
 * Uses SharedPreferences with org.json (bundled with Android) to keep the app
 * dependency-light, mirroring Tick's preference-based storage. Reads happen
 * synchronously so the first composition already has the real values.
 */
class ChronRepository(context: Context) {

    private val prefs = context.applicationContext
        .getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private val _settings = MutableStateFlow(readSettings())
    val settings: StateFlow<ChronSettings> = _settings.asStateFlow()

    private val _sessions = MutableStateFlow(readSessions())
    val sessions: StateFlow<List<FocusSession>> = _sessions.asStateFlow()

    fun update(transform: (ChronSettings) -> ChronSettings) {
        val next = transform(_settings.value)
        _settings.value = next
        prefs.edit()
            .putString(KEY_COUNTDOWN_STYLE, next.countdownStyle.name)
            .putString(KEY_CLOCK_STYLE, next.clockStyle.name)
            .putLong(KEY_COUNTDOWN_DURATION, next.countdownDurationMs)
            .putLong(KEY_COUNTDOWN_COLOR, next.countdownColor)
            .putLong(KEY_CLOCK_COLOR, next.clockColor)
            .putFloat(KEY_BACKGROUND_OPACITY, next.backgroundOpacity)
            .putFloat(KEY_RING_THICKNESS, next.ringThickness)
            .putLong(KEY_POMODORO_FOCUS, next.pomodoroFocusMs)
            .putLong(KEY_POMODORO_BREAK, next.pomodoroBreakMs)
            .apply()
    }

    fun addSession(session: FocusSession) {
        val next = (_sessions.value + session).takeLast(MAX_SESSIONS)
        _sessions.value = next
        writeSessions(next)
    }

    private fun readSettings(): ChronSettings {
        val defaults = ChronSettings()
        return ChronSettings(
            countdownStyle = CountdownStyle.fromName(prefs.getString(KEY_COUNTDOWN_STYLE, null)),
            clockStyle = ClockStyle.fromName(prefs.getString(KEY_CLOCK_STYLE, null)),
            countdownDurationMs = prefs.getLong(KEY_COUNTDOWN_DURATION, defaults.countdownDurationMs),
            countdownColor = prefs.getLong(KEY_COUNTDOWN_COLOR, defaults.countdownColor),
            clockColor = prefs.getLong(KEY_CLOCK_COLOR, defaults.clockColor),
            backgroundOpacity = prefs.getFloat(KEY_BACKGROUND_OPACITY, defaults.backgroundOpacity),
            ringThickness = prefs.getFloat(KEY_RING_THICKNESS, defaults.ringThickness),
            pomodoroFocusMs = prefs.getLong(KEY_POMODORO_FOCUS, defaults.pomodoroFocusMs),
            pomodoroBreakMs = prefs.getLong(KEY_POMODORO_BREAK, defaults.pomodoroBreakMs)
        )
    }

    private fun readSessions(): List<FocusSession> {
        val raw = prefs.getString(KEY_SESSIONS, null) ?: return emptyList()
        return runCatching {
            val array = JSONArray(raw)
            buildList(array.length()) {
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    add(
                        FocusSession(
                            id = obj.getString("id"),
                            finishedAt = obj.getLong("finishedAt"),
                            durationMs = obj.getLong("durationMs"),
                            completed = obj.getBoolean("completed")
                        )
                    )
                }
            }
        }.getOrDefault(emptyList())
    }

    private fun writeSessions(sessions: List<FocusSession>) {
        val array = JSONArray()
        sessions.forEach { s ->
            array.put(
                JSONObject()
                    .put("id", s.id)
                    .put("finishedAt", s.finishedAt)
                    .put("durationMs", s.durationMs)
                    .put("completed", s.completed)
            )
        }
        prefs.edit().putString(KEY_SESSIONS, array.toString()).apply()
    }

    private companion object {
        const val PREFS = "chron_prefs"
        const val KEY_COUNTDOWN_STYLE = "countdown_style"
        const val KEY_CLOCK_STYLE = "clock_style"
        const val KEY_COUNTDOWN_DURATION = "countdown_duration"
        const val KEY_COUNTDOWN_COLOR = "countdown_color"
        const val KEY_CLOCK_COLOR = "clock_color"
        const val KEY_BACKGROUND_OPACITY = "background_opacity"
        const val KEY_RING_THICKNESS = "ring_thickness"
        const val KEY_POMODORO_FOCUS = "pomodoro_focus"
        const val KEY_POMODORO_BREAK = "pomodoro_break"
        const val KEY_SESSIONS = "focus_sessions"
        const val MAX_SESSIONS = 500
    }
}
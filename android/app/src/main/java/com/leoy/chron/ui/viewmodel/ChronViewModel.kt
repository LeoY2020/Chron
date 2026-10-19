package com.leoy.chron.ui.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.leoy.chron.data.ChronRepository
import com.leoy.chron.data.ChronSettings
import com.leoy.chron.model.ClockStyle
import com.leoy.chron.model.CountdownStyle
import com.leoy.chron.model.FocusSession
import com.leoy.chron.timer.CountdownEngine
import com.leoy.chron.timer.PomodoroEngine
import kotlinx.coroutines.flow.StateFlow

/**
 * Single application-scoped view model: owns persistence, the countdown and
 * pomodoro engines, and exposes settings as observable state.
 */
class ChronViewModel(app: Application) : AndroidViewModel(app) {

    private val repository = ChronRepository(app)

    val settings: StateFlow<ChronSettings> = repository.settings
    val sessions: StateFlow<List<FocusSession>> = repository.sessions

    val countdown = CountdownEngine(viewModelScope)
    val pomodoro = PomodoroEngine(viewModelScope) { repository.addSession(it) }

    init {
        val s = repository.settings.value
        countdown.setDuration(s.countdownDurationMs, applyNow = true)
        pomodoro.setDurations(s.pomodoroFocusMs, s.pomodoroBreakMs)
    }

    fun setCountdownStyle(style: CountdownStyle) =
        repository.update { it.copy(countdownStyle = style) }

    fun setClockStyle(style: ClockStyle) =
        repository.update { it.copy(clockStyle = style) }

    /** Set the countdown length; resets the running countdown to it. */
    fun setCountdownDuration(ms: Long) {
        repository.update { it.copy(countdownDurationMs = ms) }
        countdown.setDuration(ms, applyNow = true)
    }

    fun setCountdownColor(color: Long) =
        repository.update { it.copy(countdownColor = color) }

    fun setClockColor(color: Long) =
        repository.update { it.copy(clockColor = color) }

    fun setBackgroundOpacity(opacity: Float) =
        repository.update { it.copy(backgroundOpacity = opacity) }

    fun setRingThickness(thickness: Float) =
        repository.update { it.copy(ringThickness = thickness) }

    fun setPomodoroDurations(focusMs: Long, breakMs: Long) {
        repository.update { it.copy(pomodoroFocusMs = focusMs, pomodoroBreakMs = breakMs) }
        pomodoro.setDurations(focusMs, breakMs)
    }
}
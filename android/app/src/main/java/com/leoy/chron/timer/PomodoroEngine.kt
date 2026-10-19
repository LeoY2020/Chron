package com.leoy.chron.timer

import android.os.SystemClock
import com.leoy.chron.model.FocusSession
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.util.UUID

/** Pomodoro phase: focus or break. */
enum class PomodoroPhase(val title: String) {
    FOCUS("Focus"),
    BREAK("Break")
}

/**
 * Pomodoro state machine: alternating focus / break rounds.
 *
 * A completed focus round records a finished [FocusSession]; abandoning a focus
 * round after at least one minute records an incomplete one. Mirrors the iOS
 * PomodoroModel.
 */
class PomodoroEngine(
    private val scope: CoroutineScope,
    private val onSession: (FocusSession) -> Unit
) {

    private val _focusMs = MutableStateFlow(25 * 60_000L)
    val focusMs: StateFlow<Long> = _focusMs.asStateFlow()

    private val _breakMs = MutableStateFlow(5 * 60_000L)
    val breakMs: StateFlow<Long> = _breakMs.asStateFlow()

    private val _remainingMs = MutableStateFlow(_focusMs.value)
    val remainingMs: StateFlow<Long> = _remainingMs.asStateFlow()

    private val _phase = MutableStateFlow(PomodoroPhase.FOCUS)
    val phase: StateFlow<PomodoroPhase> = _phase.asStateFlow()

    private val _running = MutableStateFlow(false)
    val running: StateFlow<Boolean> = _running.asStateFlow()

    private val _completedCount = MutableStateFlow(0)
    val completedCount: StateFlow<Int> = _completedCount.asStateFlow()

    /** Fired when a phase ends; carries the phase that just finished. */
    var onPhaseComplete: ((PomodoroPhase) -> Unit)? = null

    private var endAt = 0L
    private var startedFocusMs = 0L
    private var ticker: Job? = null

    val phaseDurationMs: Long
        get() = if (_phase.value == PomodoroPhase.FOCUS) _focusMs.value else _breakMs.value

    /** Elapsed fraction 0..1 of the current phase. */
    val progress: Float
        get() {
            val length = phaseDurationMs
            if (length <= 0L) return 0f
            return (1f - _remainingMs.value.toFloat() / length.toFloat()).coerceIn(0f, 1f)
        }

    /** Update durations; only applies to the current phase when idle. */
    fun setDurations(focusMs: Long, breakMs: Long) {
        _focusMs.value = focusMs.coerceAtLeast(1000L)
        _breakMs.value = breakMs.coerceAtLeast(1000L)
        if (!_running.value) _remainingMs.value = phaseDurationMs
    }

    fun start() {
        if (_running.value) return
        if (_remainingMs.value <= 0L) return
        if (_phase.value == PomodoroPhase.FOCUS) startedFocusMs = _focusMs.value
        endAt = SystemClock.elapsedRealtime() + _remainingMs.value
        _running.value = true
        launchTicker()
    }

    fun pause() {
        if (!_running.value) return
        stopTicker()
        _running.value = false
        _remainingMs.value = (endAt - SystemClock.elapsedRealtime()).coerceAtLeast(0L)
    }

    fun toggle() {
        if (_running.value) pause() else start()
    }

    /** Abandon the current round, returning the phase to its initial state. */
    fun abandon() {
        if (_phase.value == PomodoroPhase.FOCUS && startedFocusMs > 0L && _running.value) {
            val elapsed = (_focusMs.value - _remainingMs.value).coerceAtLeast(0L)
            if (elapsed >= ABANDON_THRESHOLD_MS) {
                onSession(
                    FocusSession(
                        id = UUID.randomUUID().toString(),
                        finishedAt = System.currentTimeMillis(),
                        durationMs = elapsed,
                        completed = false
                    )
                )
            }
        }
        stopTicker()
        _running.value = false
        _remainingMs.value = phaseDurationMs
    }

    /** Skip the current phase without recording a focus session. */
    fun skip() {
        stopTicker()
        _running.value = false
        advancePhase(completed = false)
    }

    private fun launchTicker() {
        ticker?.cancel()
        ticker = scope.launch {
            while (isActive && _running.value) {
                val left = endAt - SystemClock.elapsedRealtime()
                if (left <= 0L) {
                    _remainingMs.value = 0L
                    _running.value = false
                    ticker = null
                    advancePhase(completed = true)
                    break
                }
                _remainingMs.value = left
                delay(TICK_MS)
            }
        }
    }

    private fun advancePhase(completed: Boolean) {
        if (_phase.value == PomodoroPhase.FOCUS) {
            if (completed && startedFocusMs > 0L) {
                onSession(
                    FocusSession(
                        id = UUID.randomUUID().toString(),
                        finishedAt = System.currentTimeMillis(),
                        durationMs = startedFocusMs,
                        completed = true
                    )
                )
                _completedCount.value += 1
            }
            val finished = PomodoroPhase.FOCUS
            _phase.value = PomodoroPhase.BREAK
            _remainingMs.value = _breakMs.value
            onPhaseComplete?.invoke(finished)
        } else {
            val finished = PomodoroPhase.BREAK
            _phase.value = PomodoroPhase.FOCUS
            startedFocusMs = _focusMs.value
            _remainingMs.value = _focusMs.value
            onPhaseComplete?.invoke(finished)
        }
    }

    private fun stopTicker() {
        ticker?.cancel()
        ticker = null
    }

    private companion object {
        const val TICK_MS = 33L
        const val ABANDON_THRESHOLD_MS = 60_000L
    }
}
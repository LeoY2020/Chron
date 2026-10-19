package com.leoy.chron.timer

import android.os.SystemClock
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * Countdown state.
 *
 * Remaining time is derived from an absolute end timestamp
 * ([SystemClock.elapsedRealtime]) so the value stays accurate after the app is
 * backgrounded, mirroring the iOS CountdownModel.
 */
class CountdownEngine(private val scope: CoroutineScope) {

    private val _durationMs = MutableStateFlow(5 * 60_000L)
    val durationMs: StateFlow<Long> = _durationMs.asStateFlow()

    private val _remainingMs = MutableStateFlow(_durationMs.value)
    val remainingMs: StateFlow<Long> = _remainingMs.asStateFlow()

    private val _running = MutableStateFlow(false)
    val running: StateFlow<Boolean> = _running.asStateFlow()

    /** Fired once when the countdown reaches zero. */
    var onComplete: (() -> Unit)? = null

    private var endAt = 0L
    private var ticker: Job? = null

    /** Elapsed fraction 0..1 over the current total. */
    val progress: Float
        get() {
            val total = _durationMs.value
            if (total <= 0L) return 0f
            return (1f - _remainingMs.value.toFloat() / total.toFloat()).coerceIn(0f, 1f)
        }

    /** Remaining fraction 0..1. */
    val fraction: Float
        get() = 1f - progress

    /** Update the total duration; optionally reset the remaining time to it. */
    fun setDuration(ms: Long, applyNow: Boolean) {
        _durationMs.value = ms.coerceAtLeast(1000L)
        if (applyNow) reset()
    }

    fun start() {
        if (_running.value) return
        if (_remainingMs.value <= 0L) return
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

    fun reset() {
        stopTicker()
        _running.value = false
        _remainingMs.value = _durationMs.value
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
                    onComplete?.invoke()
                    break
                }
                _remainingMs.value = left
                delay(TICK_MS)
            }
        }
    }

    private fun stopTicker() {
        ticker?.cancel()
        ticker = null
    }

    private companion object {
        const val TICK_MS = 33L
    }
}
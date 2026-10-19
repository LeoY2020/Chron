package com.leoy.chron.ui.util

import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Handler
import android.os.Looper

/** Minimal, non-jarring system cue tones complementing the haptics. */
object Cue {

    fun focusComplete(context: Context) = play(ToneGenerator.TONE_PROP_BEEP)

    fun breakComplete(context: Context) = play(ToneGenerator.TONE_PROP_ACK)

    private fun play(tone: Int) {
        runCatching {
            val generator = ToneGenerator(AudioManager.STREAM_NOTIFICATION, VOLUME)
            generator.startTone(tone, DURATION_MS)
            Handler(Looper.getMainLooper()).postDelayed(
                { runCatching { generator.release() } },
                DURATION_MS + RELEASE_DELAY_MS
            )
        }
    }

    private const val VOLUME = 70
    private const val DURATION_MS = 220
    private const val RELEASE_DELAY_MS = 150L
}
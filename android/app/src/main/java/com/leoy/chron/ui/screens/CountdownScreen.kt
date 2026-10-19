package com.leoy.chron.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.leoy.chron.model.CountdownStyle
import com.leoy.chron.ui.common.AdaptiveTimeText
import com.leoy.chron.ui.common.CloseIcon
import com.leoy.chron.ui.common.DurationWheelPanel
import com.leoy.chron.ui.common.FittedText
import com.leoy.chron.ui.common.PauseIcon
import com.leoy.chron.ui.common.PlayIcon
import com.leoy.chron.ui.common.ResetIcon
import com.leoy.chron.ui.common.ShrinkableScreen
import com.leoy.chron.ui.common.StyleEditor
import com.leoy.chron.ui.screens.countdown.CountdownStyleLayer
import com.leoy.chron.ui.theme.ChronColors
import com.leoy.chron.ui.theme.toColor
import com.leoy.chron.ui.util.HapticLevel
import com.leoy.chron.ui.util.formatCountdown
import com.leoy.chron.ui.util.rememberHaptics
import com.leoy.chron.ui.viewmodel.ChronViewModel

/** Countdown page: digits as the main visual, five switchable styles. */
@Composable
fun CountdownScreen(
    viewModel: ChronViewModel,
    onLockChange: (Boolean) -> Unit
) {
    val haptics = rememberHaptics()
    val settings by viewModel.settings.collectAsStateWithLifecycle()
    val remaining by viewModel.countdown.remainingMs.collectAsStateWithLifecycle()
    val duration by viewModel.countdown.durationMs.collectAsStateWithLifecycle()
    val running by viewModel.countdown.running.collectAsStateWithLifecycle()
    val engine = viewModel.countdown

    var wheelHours by remember { mutableIntStateOf((settings.countdownDurationMs / 3_600_000L).toInt()) }
    var wheelMinutes by remember { mutableIntStateOf(((settings.countdownDurationMs / 60_000L) % 60L).toInt()) }
    var wheelSeconds by remember { mutableIntStateOf(((settings.countdownDurationMs / 1000L) % 60L).toInt()) }

    val color = settings.countdownColor.toColor()
    val text = formatCountdown(remaining)
    val progress = if (duration > 0L) {
        (1f - remaining.toFloat() / duration.toFloat()).coerceIn(0f, 1f)
    } else {
        0f
    }
    val fraction = 1f - progress

    ShrinkableScreen(
        styleTitles = CountdownStyle.entries.map { it.title },
        selectedStyleIndex = settings.countdownStyle.ordinal,
        onSelectStyle = { viewModel.setCountdownStyle(CountdownStyle.entries[it]) },
        onLockChange = onLockChange,
        editor = {
            StyleEditor(
                color = settings.countdownColor,
                onColorChange = viewModel::setCountdownColor,
                ringThickness = settings.ringThickness,
                onRingThickness = viewModel::setRingThickness,
                backgroundOpacity = settings.backgroundOpacity,
                onBackgroundOpacity = viewModel::setBackgroundOpacity
            )
        },
        extraPanel = {
            if (!running) {
                DurationWheelPanel(
                    hours = wheelHours,
                    minutes = wheelMinutes,
                    seconds = wheelSeconds,
                    onChanged = { h, m, s ->
                        wheelHours = h
                        wheelMinutes = m
                        wheelSeconds = s
                        val total = (h * 3600L + m * 60L + s) * 1000L
                        if (total > 0L) viewModel.setCountdownDuration(total)
                    }
                )
            }
        }
    ) { shrunk ->
        Box(modifier = Modifier.fillMaxSize()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black)
            )
            if (settings.backgroundOpacity > 0.001f) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(ChronColors.SurfaceTint.copy(alpha = settings.backgroundOpacity))
                )
            }

            if (settings.countdownStyle == CountdownStyle.IMMERSIVE) {
                FittedText(text = text, color = color, modifier = Modifier.fillMaxSize())
            } else {
                CountdownStyleLayer(
                    style = settings.countdownStyle,
                    progress = progress,
                    fraction = fraction,
                    color = color,
                    ringThickness = settings.ringThickness,
                    modifier = Modifier.fillMaxSize()
                )
                AdaptiveTimeText(
                    text = text,
                    color = color,
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(horizontal = 16.dp)
                )
            }

            if (!shrunk) {
                Column(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(bottom = 44.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(18.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        CircleControl(
                            size = 58.dp,
                            background = Color.White.copy(alpha = 0.1f),
                            onClick = {
                                haptics.perform(HapticLevel.MEDIUM)
                                engine.toggle()
                            }
                        ) {
                            if (running) {
                                PauseIcon(color = Color.White, modifier = Modifier.size(20.dp))
                            } else {
                                PlayIcon(color = Color.White, modifier = Modifier.size(20.dp))
                            }
                        }

                        CircleControl(
                            size = 46.dp,
                            background = Color.White.copy(alpha = 0.06f),
                            onClick = {
                                haptics.perform(HapticLevel.LIGHT)
                                engine.reset()
                            }
                        ) {
                            ResetIcon(
                                color = Color.White.copy(alpha = 0.7f),
                                modifier = Modifier.size(19.dp)
                            )
                        }
                    }
                }
            }
        }
    }
}

/** Round, low-key control button. */
@Composable
private fun CircleControl(
    size: androidx.compose.ui.unit.Dp,
    background: Color,
    onClick: () -> Unit,
    content: @Composable () -> Unit
) {
    Box(
        modifier = Modifier
            .size(size)
            .clip(CircleShape)
            .background(background)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        content()
    }
}
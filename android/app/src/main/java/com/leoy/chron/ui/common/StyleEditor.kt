package com.leoy.chron.ui.common

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.leoy.chron.ui.theme.ChronColors
import com.leoy.chron.ui.theme.toColor
import com.leoy.chron.ui.util.HapticLevel
import com.leoy.chron.ui.util.rememberHaptics
import com.leoy.chron.ui.util.tabular

private val Swatches = listOf(
    0xFFF5F5F7L, 0xFFFFD36EL, 0xFFFF8A3DL, 0xFFFF6B6BL,
    0xFF7EC8FFL, 0xFF9B8CFFL, 0xFF6EE7B7L, 0xFFFFFFFFL
)

/**
 * In-place style editor: font colour, ring thickness and background opacity.
 * No navigation — it expands and collapses within the style bar.
 */
@Composable
fun StyleEditor(
    color: Long,
    onColorChange: (Long) -> Unit,
    ringThickness: Float,
    onRingThickness: (Float) -> Unit,
    backgroundOpacity: Float,
    onBackgroundOpacity: (Float) -> Unit,
    modifier: Modifier = Modifier,
    showRing: Boolean = true
) {
    val haptics = rememberHaptics()
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(ChronColors.SurfaceTint.copy(alpha = 0.65f))
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text(
            text = "Color",
            style = tabular(11.sp, FontWeight.Medium),
            color = Color.White.copy(alpha = 0.5f)
        )
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Swatches.forEach { swatch ->
                val selected = swatch == color
                Box(
                    modifier = Modifier
                        .size(28.dp)
                        .clip(CircleShape)
                        .background(swatch.toColor())
                        .border(
                            width = 2.dp,
                            color = if (selected) Color.White else Color.Transparent,
                            shape = CircleShape
                        )
                        .clickable {
                            haptics.perform(HapticLevel.LIGHT)
                            onColorChange(swatch)
                        }
                )
            }
        }

        if (showRing) {
            SliderRow(
                label = "Ring",
                valueText = ringThickness.toInt().toString(),
                range = 3f..30f,
                value = ringThickness,
                onValueChange = onRingThickness
            )
        }

        SliderRow(
            label = "Backdrop",
            valueText = null,
            range = 0f..0.6f,
            value = backgroundOpacity,
            onValueChange = onBackgroundOpacity
        )
    }
}

@Composable
private fun SliderRow(
    label: String,
    valueText: String?,
    range: ClosedRange<Float>,
    value: Float,
    onValueChange: (Float) -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text(
            text = label,
            style = tabular(11.sp, FontWeight.Medium),
            color = Color.White.copy(alpha = 0.5f),
            modifier = Modifier.width(60.dp)
        )
        Slider(
            value = value,
            onValueChange = onValueChange,
            valueRange = range,
            modifier = Modifier.weight(1f)
        )
        if (valueText != null) {
            Text(
                text = valueText,
                style = tabular(11.sp, FontWeight.Medium),
                color = Color.White.copy(alpha = 0.6f),
                modifier = Modifier.width(24.dp)
            )
        }
    }
}
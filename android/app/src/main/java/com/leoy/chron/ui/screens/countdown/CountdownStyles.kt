package com.leoy.chron.ui.screens.countdown

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import com.leoy.chron.model.CountdownStyle
import com.leoy.chron.ui.theme.ChronColors
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.sin

/** Progress layers drawn behind the countdown digits for each style. */
@Composable
fun CountdownStyleLayer(
    style: CountdownStyle,
    progress: Float,
    fraction: Float,
    color: Color,
    ringThickness: Float,
    modifier: Modifier = Modifier
) {
    when (style) {
        CountdownStyle.RING -> RingLayer(fraction, color, ringThickness, modifier)
        CountdownStyle.SECTOR -> SectorLayer(progress, modifier)
        CountdownStyle.DIAL -> DialLayer(progress, color, modifier)
        CountdownStyle.PLAIN, CountdownStyle.IMMERSIVE -> Unit
    }
}

/** Ring: depletes clockwise from 12 o'clock. */
@Composable
private fun RingLayer(fraction: Float, color: Color, thickness: Float, modifier: Modifier) {
    Canvas(modifier = modifier.fillMaxSize()) {
        val diameter = min(size.width, size.height) * 0.64f
        val stroke = thickness.dp.toPx()
        val topLeft = Offset((size.width - diameter) / 2f, (size.height - diameter) / 2f)
        val arcSize = Size(diameter, diameter)
        drawArc(
            color = color.copy(alpha = 0.14f),
            startAngle = 0f,
            sweepAngle = 360f,
            useCenter = false,
            topLeft = topLeft,
            size = arcSize,
            style = Stroke(width = stroke)
        )
        drawArc(
            color = color,
            startAngle = -90f,
            sweepAngle = 360f * fraction.coerceIn(0f, 1f),
            useCenter = false,
            topLeft = topLeft,
            size = arcSize,
            style = Stroke(width = stroke, cap = StrokeCap.Round)
        )
    }
}

/** Sector: full-screen wedge sweeping from 0 degrees, warm gradient. */
@Composable
private fun SectorLayer(progress: Float, modifier: Modifier) {
    Canvas(modifier = modifier.fillMaxSize()) {
        val radius = min(size.width, size.height) * 0.95f
        val center = Offset(size.width / 2f, size.height / 2f)
        val brush = Brush.verticalGradient(
            colors = listOf(ChronColors.SectorStart, ChronColors.SectorEnd),
            startY = 0f,
            endY = size.height
        )
        drawArc(
            brush = brush,
            startAngle = -90f,
            sweepAngle = 360f * progress.coerceIn(0f, 1f),
            useCenter = true,
            topLeft = Offset(center.x - radius, center.y - radius),
            size = Size(radius * 2f, radius * 2f)
        )
    }
}

/** Dial: a countdown hand rotates behind the digits as time depletes. */
@Composable
private fun DialLayer(progress: Float, color: Color, modifier: Modifier) {
    Canvas(modifier = modifier.fillMaxSize()) {
        val diameter = min(size.width, size.height) * 0.68f
        val radius = diameter / 2f
        val center = Offset(size.width / 2f, size.height / 2f)
        drawCircle(
            color = color.copy(alpha = 0.12f),
            radius = radius,
            center = center,
            style = Stroke(width = 1.5f.dp.toPx())
        )
        for (index in 0 until 60) {
            val major = index % 5 == 0
            val radians = Math.toRadians((index * 6).toDouble())
            val outerRadius = radius
            val innerRadius = radius - (if (major) 12f else 6f).dp.toPx()
            val start = Offset(
                center.x + innerRadius * sin(radians).toFloat(),
                center.y - innerRadius * cos(radians).toFloat()
            )
            val end = Offset(
                center.x + outerRadius * sin(radians).toFloat(),
                center.y - outerRadius * cos(radians).toFloat()
            )
            drawLine(
                color = color.copy(alpha = if (major) 0.55f else 0.22f),
                start = start,
                end = end,
                strokeWidth = if (major) 2f else 1f,
                cap = StrokeCap.Round
            )
        }
        val handLength = radius * 0.84f
        val handRadians = Math.toRadians((360f * progress.coerceIn(0f, 1f)).toDouble())
        val handEnd = Offset(
            center.x + handLength * sin(handRadians).toFloat(),
            center.y - handLength * cos(handRadians).toFloat()
        )
        drawLine(
            color = color,
            start = center,
            end = handEnd,
            strokeWidth = 3f.dp.toPx(),
            cap = StrokeCap.Round
        )
    }
}
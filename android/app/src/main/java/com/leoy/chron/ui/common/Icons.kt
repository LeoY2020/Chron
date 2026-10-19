package com.leoy.chron.ui.common

import androidx.compose.foundation.Canvas
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import kotlin.math.cos
import kotlin.math.sin

/**
 * Small hand-drawn control glyphs.
 *
 * They are drawn with Canvas rather than pulled from an icon pack so the app
 * stays dependency-light and every glyph matches Chron's restrained, thin look.
 */
@Composable
fun PlayIcon(color: Color, modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val path = Path().apply {
            moveTo(size.width * 0.30f, size.height * 0.16f)
            lineTo(size.width * 0.82f, size.height * 0.50f)
            lineTo(size.width * 0.30f, size.height * 0.84f)
            close()
        }
        drawPath(path, color)
    }
}

@Composable
fun PauseIcon(color: Color, modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val barWidth = size.width * 0.24f
        val gap = size.width * 0.18f
        val height = size.height * 0.62f
        val top = size.height * 0.19f
        val left = size.width * 0.5f - gap / 2f - barWidth
        val radius = CornerRadius(barWidth * 0.35f)
        drawRoundRect(color, topLeft = Offset(left, top), size = Size(barWidth, height), cornerRadius = radius)
        drawRoundRect(
            color,
            topLeft = Offset(left + barWidth + gap, top),
            size = Size(barWidth, height),
            cornerRadius = radius
        )
    }
}

@Composable
fun ResetIcon(color: Color, modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val stroke = size.minDimension * 0.11f
        val diameter = size.minDimension * 0.66f
        val topLeft = Offset((size.width - diameter) / 2f, (size.height - diameter) / 2f)
        val radius = diameter / 2f
        val centerX = size.width / 2f
        val centerY = size.height / 2f
        val startAngle = 52f
        drawArc(
            color = color,
            startAngle = startAngle,
            sweepAngle = 288f,
            useCenter = false,
            topLeft = topLeft,
            size = Size(diameter, diameter),
            style = Stroke(width = stroke, cap = StrokeCap.Round)
        )
        val radians = Math.toRadians(startAngle.toDouble())
        val px = centerX + radius * cos(radians).toFloat()
        val py = centerY + radius * sin(radians).toFloat()
        val head = size.minDimension * 0.2f
        rotate(degrees = startAngle + 90f, pivot = Offset(px, py)) {
            val path = Path().apply {
                moveTo(px - head * 0.45f, py - head * 0.5f)
                lineTo(px + head * 0.5f, py)
                lineTo(px - head * 0.45f, py + head * 0.5f)
                close()
            }
            drawPath(path, color)
        }
    }
}

@Composable
fun CloseIcon(color: Color, modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val stroke = size.minDimension * 0.13f
        val inset = size.minDimension * 0.26f
        drawLine(
            color, Offset(inset, inset), Offset(size.width - inset, size.height - inset),
            strokeWidth = stroke, cap = StrokeCap.Round
        )
        drawLine(
            color, Offset(size.width - inset, inset), Offset(inset, size.height - inset),
            strokeWidth = stroke, cap = StrokeCap.Round
        )
    }
}

@Composable
fun SkipIcon(color: Color, modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val stroke = size.minDimension * 0.12f
        val barX = size.width * 0.74f
        drawLine(
            color,
            Offset(barX, size.height * 0.22f),
            Offset(barX, size.height * 0.78f),
            strokeWidth = stroke,
            cap = StrokeCap.Round
        )
        val path = Path().apply {
            moveTo(size.width * 0.26f, size.height * 0.24f)
            lineTo(size.width * 0.68f, size.height * 0.5f)
            lineTo(size.width * 0.26f, size.height * 0.76f)
            close()
        }
        drawPath(path, color)
    }
}

@Composable
fun ChevronIcon(color: Color, up: Boolean, modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val stroke = size.minDimension * 0.14f
        val path = Path().apply {
            if (up) {
                moveTo(size.width * 0.24f, size.height * 0.62f)
                lineTo(size.width * 0.5f, size.height * 0.38f)
                lineTo(size.width * 0.76f, size.height * 0.62f)
            } else {
                moveTo(size.width * 0.24f, size.height * 0.38f)
                lineTo(size.width * 0.5f, size.height * 0.62f)
                lineTo(size.width * 0.76f, size.height * 0.38f)
            }
        }
        drawPath(path, color, style = Stroke(width = stroke, cap = StrokeCap.Round, join = StrokeJoin.Round))
    }
}
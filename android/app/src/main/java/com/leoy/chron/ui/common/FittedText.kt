package com.leoy.chron.ui.common

import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.sp
import com.leoy.chron.ui.util.tabular

/**
 * Text stretched to fill a fraction of its container, constrained by both width
 * and height so Immersive glyphs reach the edge without ever clipping.
 */
@Composable
fun FittedText(
    text: String,
    color: Color,
    modifier: Modifier = Modifier,
    widthFill: Float = 0.94f,
    heightFill: Float = 0.44f,
    weight: FontWeight = FontWeight.SemiBold
) {
    BoxWithConstraints(modifier = modifier) {
        val measurer = rememberTextMeasurer()
        val maxWidthPx = constraints.maxWidth.toFloat()
        val maxHeightPx = constraints.maxHeight.toFloat()
        if (text.isEmpty() || maxWidthPx <= 0f || maxHeightPx <= 0f) return@BoxWithConstraints

        val probeStyle = tabular(100.sp, weight)
        val measured = measurer.measure(AnnotatedString(text), probeStyle, maxLines = 1)
        val probeWidth = measured.size.width.toFloat().coerceAtLeast(1f)
        val probeHeight = measured.size.height.toFloat().coerceAtLeast(1f)
        val scale = minOf(
            (maxWidthPx * widthFill) / probeWidth,
            (maxHeightPx * heightFill) / probeHeight
        )
        Text(
            text = text,
            style = tabular((100f * scale).sp, weight),
            color = color,
            maxLines = 1,
            softWrap = false,
            overflow = TextOverflow.Clip
        )
    }
}

/**
 * Centered large digits: size adapts to the screen's short edge, shrinking for
 * longer strings (HH:MM:SS) so they always fit.
 */
@Composable
fun AdaptiveTimeText(
    text: String,
    color: Color,
    modifier: Modifier = Modifier,
    relativeSize: Float = 0.26f
) {
    BoxWithConstraints(
        modifier = modifier,
        contentAlignment = Alignment.Center
    ) {
        val density = LocalDensity.current
        val width = constraints.maxWidth.toFloat()
        val height = if (constraints.maxHeight == Int.MAX_VALUE) width else constraints.maxHeight.toFloat()
        val short = minOf(width, height)
        val lengthFactor = if (text.length > 5) 0.7f else 1f
        val sizeSp = with(density) { (short * relativeSize * lengthFactor).toSp() }
        Text(
            text = text,
            style = tabular(sizeSp, FontWeight.SemiBold),
            color = color,
            maxLines = 1,
            softWrap = false,
            overflow = TextOverflow.Clip
        )
    }
}
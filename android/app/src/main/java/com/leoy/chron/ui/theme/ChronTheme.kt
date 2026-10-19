package com.leoy.chron.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

/** The single source of colour truth for Chron. */
object ChronColors {
    val PureBlack = Color(0xFF000000)
    val Background = Color(0xFF08080A)
    val SurfaceTint = Color(0xFF12141C)
    val OnBackground = Color(0xFFF5F5F7)
    val Muted = Color(0xFF8A8A90)
    val Accent = Color(0xFFE8915A)
    val AccentDeep = Color(0xFFF08A3C)
    val SectorStart = Color(0xFFFFC46B)
    val SectorEnd = Color(0xFFF08A3C)
    val WarmBackgroundTop = Color(0xFF1A1310)
}

private val ChronColorScheme = darkColorScheme(
    primary = ChronColors.Accent,
    onPrimary = ChronColors.PureBlack,
    secondary = ChronColors.AccentDeep,
    background = ChronColors.Background,
    onBackground = ChronColors.OnBackground,
    surface = ChronColors.Background,
    onSurface = ChronColors.OnBackground,
    surfaceVariant = ChronColors.SurfaceTint,
    onSurfaceVariant = ChronColors.Muted
)

private val ChronShapes = Shapes(
    small = RoundedCornerShape(10.dp),
    medium = RoundedCornerShape(14.dp),
    large = RoundedCornerShape(24.dp)
)

/** Converts a stored ARGB long into a Compose [Color]. */
fun Long.toColor(): Color = Color(this.toInt())

@Composable
fun ChronTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = ChronColorScheme,
        shapes = ChronShapes,
        typography = Typography(),
        content = content
    )
}
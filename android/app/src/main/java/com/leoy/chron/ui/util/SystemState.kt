package com.leoy.chron.ui.util

import android.content.Context
import android.os.Build
import android.provider.Settings
import android.view.RoundedCorner
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/** True when the system "remove animations" accessibility scale is zero. */
fun isReduceMotion(context: Context): Boolean {
    val scale = Settings.Global.getFloat(
        context.contentResolver,
        Settings.Global.ANIMATOR_DURATION_SCALE,
        1f
    )
    return scale == 0f
}

/**
 * Screen corner radius (px -> dp), used so Immersive glyphs never clip against
 * rounded display corners. Returns 0 on devices without rounded corners.
 */
@Composable
fun rememberScreenCornerRadius(): Dp {
    val view = LocalView.current
    val density = LocalDensity.current
    return remember(view) {
        val radiusPx = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            runCatching {
                view.rootWindowInsets
                    ?.getRoundedCorner(RoundedCorner.POSITION_TOP_LEFT)
                    ?.radius ?: 0
            }.getOrDefault(0)
        } else {
            0
        }
        with(density) { radiusPx.toDp() }
    }
}

/** Convenience default when no rounded corner can be detected. */
val DefaultCornerRadius: Dp = 0.dp
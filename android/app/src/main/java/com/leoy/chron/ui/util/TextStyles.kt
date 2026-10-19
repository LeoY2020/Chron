package com.leoy.chron.ui.util

import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.em

/**
 * Rounded type is not guaranteed on Android, so the platform sans-serif is used
 * everywhere and we rely on the "tnum" OpenType feature for tabular digits so
 * widths never jitter. Letter spacing is expressed in em.
 */
fun tabular(
    size: TextUnit,
    weight: FontWeight = FontWeight.SemiBold,
    letterSpacingEm: Float = 0f
): TextStyle = TextStyle(
    fontFamily = FontFamily.SansSerif,
    fontWeight = weight,
    fontSize = size,
    letterSpacing = letterSpacingEm.em,
    fontFeatureSettings = "tnum"
)
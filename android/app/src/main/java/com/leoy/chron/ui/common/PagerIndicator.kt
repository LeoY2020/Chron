package com.leoy.chron.ui.common

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

/** Minimal page indicator: low-emphasis dots, never visually prominent. */
@Composable
fun PagerIndicator(
    pageCount: Int,
    currentPage: Int,
    modifier: Modifier = Modifier
) {
    Row(modifier = modifier, horizontalArrangement = Arrangement.spacedBy(7.dp)) {
        repeat(pageCount) { index ->
            Box(
                Modifier
                    .size(5.dp)
                    .background(
                        color = Color.White.copy(alpha = if (index == currentPage) 0.55f else 0.18f),
                        shape = CircleShape
                    )
            )
        }
    }
}
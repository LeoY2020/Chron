package com.leoy.chron.ui.common

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.leoy.chron.ui.util.HapticLevel
import com.leoy.chron.ui.util.rememberHaptics
import com.leoy.chron.ui.util.tabular

/**
 * Shared "shrink + bottom style bar" chrome used by the Countdown and Clock
 * pages.
 *
 * Long-press shrinks the whole screen (~0.92, springy) while the freed area
 * fills with black; a style bar slides up from the bottom. Long-press again or
 * tap empty space restores full screen. While shrunk, horizontal paging is
 * reported as locked through [onLockChange].
 */
@Composable
fun ShrinkableScreen(
    styleTitles: List<String>,
    selectedStyleIndex: Int,
    onSelectStyle: (Int) -> Unit,
    onLockChange: (Boolean) -> Unit,
    editor: @Composable () -> Unit,
    modifier: Modifier = Modifier,
    extraPanel: (@Composable () -> Unit)? = null,
    content: @Composable BoxScope.(Boolean) -> Unit
) {
    val haptics = rememberHaptics()
    var shrunk by rememberSaveable { mutableStateOf(false) }
    var showEditor by rememberSaveable { mutableStateOf(false) }

    LaunchedEffect(shrunk) { onLockChange(shrunk) }
    DisposableEffect(Unit) { onDispose { onLockChange(false) } }

    val scale by animateFloatAsState(
        targetValue = if (shrunk) 0.92f else 1f,
        animationSpec = spring(dampingRatio = 0.82f, stiffness = 300f)
    )
    val corner by animateDpAsState(
        targetValue = if (shrunk) 44.dp else 0.dp,
        animationSpec = spring(dampingRatio = 0.82f, stiffness = 300f)
    )

    Box(
        modifier = modifier
            .fillMaxSize()
            .pointerInput(Unit) {
                detectTapGestures(
                    onLongPress = {
                        haptics.perform(HapticLevel.MEDIUM)
                        shrunk = !shrunk
                        if (!shrunk) showEditor = false
                    },
                    onTap = {
                        if (shrunk) {
                            shrunk = false
                            showEditor = false
                        }
                    }
                )
            }
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer {
                    scaleX = scale
                    scaleY = scale
                }
                .clip(RoundedCornerShape(corner))
        ) {
            content(shrunk)
        }

        AnimatedVisibility(
            visible = shrunk,
            modifier = Modifier.align(Alignment.BottomCenter),
            enter = slideInVertically(initialOffsetY = { it }) + fadeIn(),
            exit = slideOutVertically(targetOffsetY = { it }) + fadeOut()
        ) {
            StyleSheet(
                styleTitles = styleTitles,
                selectedIndex = selectedStyleIndex,
                onSelectStyle = onSelectStyle,
                showEditor = showEditor,
                onToggleEditor = { showEditor = !showEditor },
                editor = editor,
                extraPanel = extraPanel
            )
        }
    }
}

@Composable
private fun StyleSheet(
    styleTitles: List<String>,
    selectedIndex: Int,
    onSelectStyle: (Int) -> Unit,
    showEditor: Boolean,
    onToggleEditor: () -> Unit,
    editor: @Composable () -> Unit,
    extraPanel: (@Composable () -> Unit)?
) {
    val haptics = rememberHaptics()
    Box(modifier = Modifier.fillMaxWidth()) {
        Box(
            modifier = Modifier
                .matchParentSize()
                .background(
                    Brush.verticalGradient(
                        0f to Color.Transparent,
                        0.45f to Color.Black.copy(alpha = 0.55f),
                        1f to Color.Black.copy(alpha = 0.92f)
                    )
                )
        )
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .windowInsetsPadding(WindowInsets.navigationBars)
                .padding(bottom = 10.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            if (extraPanel != null) {
                extraPanel()
            }
            AnimatedVisibility(
                visible = showEditor,
                enter = expandVertically() + fadeIn(),
                exit = shrinkVertically() + fadeOut()
            ) {
                Box(
                    modifier = Modifier
                        .padding(horizontal = 16.dp)
                        .padding(bottom = 8.dp)
                ) {
                    editor()
                }
            }
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                styleTitles.forEachIndexed { index, title ->
                    StyleChip(
                        title = title,
                        active = index == selectedIndex,
                        onClick = {
                            haptics.perform(HapticLevel.LIGHT)
                            if (index == selectedIndex) onToggleEditor() else onSelectStyle(index)
                        }
                    )
                }
            }
        }
    }
}

@Composable
private fun StyleChip(title: String, active: Boolean, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .width(84.dp)
            .height(50.dp)
            .clip(RoundedCornerShape(14.dp))
            .background(if (active) Color.White else Color.White.copy(alpha = 0.08f))
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = title,
            style = tabular(12.sp, FontWeight.Medium),
            color = if (active) Color.Black else Color.White.copy(alpha = 0.8f)
        )
    }
}
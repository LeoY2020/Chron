package com.leoy.chron.ui.common

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.gestures.snapping.rememberSnapFlingBehavior
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.leoy.chron.ui.util.HapticLevel
import com.leoy.chron.ui.util.rememberHaptics
import com.leoy.chron.ui.util.tabular
import kotlinx.coroutines.flow.filter
import kotlin.math.abs

/**
 * A single snap-scrolling wheel column. Items snap to the centre, the centred
 * item is enlarged while the others fade, and a light tick fires once per
 * settled graduation (never continuously while scrolling).
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun SnapWheel(
    count: Int,
    selected: Int,
    onSelected: (Int) -> Unit,
    modifier: Modifier = Modifier,
    itemHeight: Dp = 40.dp,
    label: (Int) -> String
) {
    val haptics = rememberHaptics()
    val listState = rememberLazyListState(initialFirstVisibleItemIndex = selected)
    val snapBehavior = rememberSnapFlingBehavior(lazyListState = listState)

    val centered by remember {
        derivedStateOf {
            val info = listState.layoutInfo
            if (info.visibleItemsInfo.isEmpty()) {
                listState.firstVisibleItemIndex
            } else {
                val center = (info.viewportStartOffset + info.viewportEndOffset) / 2f
                info.visibleItemsInfo.minByOrNull { item ->
                    abs(item.offset + item.size / 2f - center)
                }?.index ?: listState.firstVisibleItemIndex
            }
        }
    }

    var lastReported by remember { mutableIntStateOf(listState.firstVisibleItemIndex) }
    LaunchedEffect(listState) {
        snapshotFlow { centered to listState.isScrollInProgress }
            .filter { !it.second }
            .collect { (index, _) ->
                if (index != lastReported) {
                    lastReported = index
                    onSelected(index)
                    haptics.perform(HapticLevel.LIGHT)
                }
            }
    }

    Box(modifier = modifier, contentAlignment = Alignment.Center) {
        LazyColumn(
            state = listState,
            flingBehavior = snapBehavior,
            contentPadding = PaddingValues(vertical = itemHeight * 2),
            modifier = Modifier
                .fillMaxWidth()
                .height(itemHeight * 5)
        ) {
            items(count = count, key = { it }) { index ->
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(itemHeight),
                    contentAlignment = Alignment.Center
                ) {
                    val isCenter = index == centered
                    Text(
                        text = label(index),
                        style = tabular(
                            size = if (isCenter) 22.sp else 17.sp,
                            weight = if (isCenter) FontWeight.SemiBold else FontWeight.Normal
                        ),
                        color = Color.White.copy(alpha = if (isCenter) 1f else 0.4f)
                    )
                }
            }
        }
    }
}

/** Hours / minutes / seconds wheels used to set the countdown duration. */
@Composable
fun DurationWheelPanel(
    hours: Int,
    minutes: Int,
    seconds: Int,
    onChanged: (Int, Int, Int) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(modifier = modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        SnapWheel(
            count = 24,
            selected = hours,
            onSelected = { onChanged(it, minutes, seconds) },
            modifier = Modifier.weight(1f),
            label = { "${it}h" }
        )
        SnapWheel(
            count = 60,
            selected = minutes,
            onSelected = { onChanged(hours, it, seconds) },
            modifier = Modifier.weight(1f),
            label = { "${it}m" }
        )
        SnapWheel(
            count = 60,
            selected = seconds,
            onSelected = { onChanged(hours, minutes, it) },
            modifier = Modifier.weight(1f),
            label = { "${it}s" }
        )
    }
}
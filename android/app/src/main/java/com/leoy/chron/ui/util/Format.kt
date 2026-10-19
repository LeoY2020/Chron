package com.leoy.chron.ui.util

import android.content.Context
import android.text.format.DateFormat
import java.util.Calendar
import java.util.Locale

/** Zero-pad an integer to at least two digits. */
fun pad2(value: Int): String = String.format(Locale.US, "%02d", value)

/** "HH:MM:SS" when an hours component is present (or forced), else "MM:SS". */
fun formatCountdown(ms: Long, forceHours: Boolean = false): String {
    val total = (ms / 1000L).coerceAtLeast(0L)
    val h = total / 3600
    val m = (total % 3600) / 60
    val s = total % 60
    return if (h > 0 || forceHours) {
        "${pad2(h.toInt())}:${pad2(m.toInt())}:${pad2(s.toInt())}"
    } else {
        "${pad2(m.toInt())}:${pad2(s.toInt())}"
    }
}

/** Clock text; 12-hour hours are not zero-padded, matching iOS. */
fun formatClock(millis: Long, showSeconds: Boolean, use24Hour: Boolean): String {
    val cal = Calendar.getInstance()
    cal.timeInMillis = millis
    val hour24 = cal.get(Calendar.HOUR_OF_DAY)
    val minute = cal.get(Calendar.MINUTE)
    val second = cal.get(Calendar.SECOND)
    return if (use24Hour) {
        if (showSeconds) "${pad2(hour24)}:${pad2(minute)}:${pad2(second)}"
        else "${pad2(hour24)}:${pad2(minute)}"
    } else {
        val hour12 = ((hour24 + 11) % 12) + 1
        if (showSeconds) "$hour12:${pad2(minute)}:${pad2(second)}"
        else "$hour12:${pad2(minute)}"
    }
}

/** "AM" / "PM" marker for 12-hour clocks. */
fun meridiem(millis: Long): String {
    val cal = Calendar.getInstance()
    cal.timeInMillis = millis
    return if (cal.get(Calendar.HOUR_OF_DAY) < 12) "AM" else "PM"
}

/** Whether the system is configured for a 24-hour clock. */
fun uses24Hour(context: Context): Boolean = DateFormat.is24HourFormat(context)

/** Human readable duration, e.g. "1h 25m" / "25m". */
fun formatDuration(ms: Long): String {
    val total = (ms / 1000L).coerceAtLeast(0L)
    val h = total / 3600
    val m = (total % 3600) / 60
    return when {
        h > 0 && m > 0 -> "${h}h ${m}m"
        h > 0 -> "${h}h"
        else -> "${m}m"
    }
}
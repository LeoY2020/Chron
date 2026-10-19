package com.leoy.chron.model

/** A single focus round recorded by the pomodoro engine. */
data class FocusSession(
    val id: String,
    val finishedAt: Long,
    val durationMs: Long,
    val completed: Boolean
)
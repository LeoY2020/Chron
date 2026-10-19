package com.leoy.chron.model

/** Countdown page styles (spec section 2). */
enum class CountdownStyle(val title: String) {
    RING("Ring"),
    SECTOR("Sector"),
    DIAL("Dial"),
    PLAIN("Plain"),
    IMMERSIVE("Immersive");

    companion object {
        fun fromName(name: String?): CountdownStyle = entries.firstOrNull { it.name == name } ?: RING
    }
}

/** Clock page styles (spec section 4). */
enum class ClockStyle(val title: String) {
    ANALOG("Analog"),
    PLAIN("Plain"),
    IMMERSIVE("Immersive"),
    SEVEN_SEGMENT("Seven-segment"),
    SUN("Sun");

    companion object {
        fun fromName(name: String?): ClockStyle = entries.firstOrNull { it.name == name } ?: ANALOG
    }
}
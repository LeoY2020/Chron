# Chron - project specific ProGuard rules.

# Keep data/model classes (reflection-free but cheap insurance for release builds).
-keep class com.leoy.chron.model.** { *; }
-keep class com.leoy.chron.data.** { *; }

# Kotlin coroutines inline
-dontwarn kotlinx.coroutines.**
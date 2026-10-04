# Chron

A minimalist clock. Nothing else.

Chron is a quiet, distraction-free clock app: **no ads, no purchases, no
accounts, no clutter** — only time.

Three full-screen pages, swipe to move between them:

1. **Countdown** (left) — big monospaced digits, with five display styles:
   ring, sector (full-screen gradient sweep), dial hand, plain, and
   edge-to-edge immersive type.
2. **Pomodoro** (middle) — a warm, orange-toned focus timer with a
   pull-down summary of recent focus sessions, and a drag-scale picker.
3. **Clock** (right) — the current time, full-screen, with five styles:
   analog hands, plain, edge-to-edge immersive, retro seven-segment, and
   a "Sun" style whose light follows the time of day.

Long-press any page to shrink it and reveal the style bar. Tap the active
style again to edit it in place. All settings happen right there — Chron
never sends you to a settings screen.

## Platforms

| Directory | Platform | Stack |
| --- | --- | --- |
| `ios/` | iOS / iPadOS | SwiftUI |
| `macos/` | macOS | SwiftUI + AppKit |
| `android/` | Android | Kotlin + Jetpack Compose (Material 3) |
| `windows/` | Windows 10/11 | WinUI 3 (Windows App SDK, C#) |
| `linux/` | Linux | Qt 6 / C++ |
| `harmonyos/` | HarmonyOS | ArkTS |

Each platform is a native implementation: its own typography, gestures,
haptics, and motion follow the conventions of that system. No shared
cross-platform UI.

## Design principles

- Dark, calm backgrounds; the time is the only visual focus.
- Motion with a purpose: ease-in-out curves, gentle springs, no show-off
  effects.
- Haptics are graded (light for ticks and switches, medium for long-press
  and start/pause, heavy for a finished session) and respect system
  accessibility settings.
- Monospaced digits everywhere, so numbers never jitter.

## Building

Each platform directory is self-contained; open it with the respective
toolchain (Xcode, Android Studio, Visual Studio, Qt Creator, DevEco Studio).

## License

MIT — see [LICENSE](LICENSE).

# Chron — Product Spec

Chron is a minimalist, distraction-free clock app. Same family as Tick, but
fully independent. The core is the clock; focus and immersion are its natural
temperament, not a slogan.

Core values: no ads, no purchases, nothing flashy. Only time.

Visual details, motion curves, transitions, and sound design are up to each
platform implementation, within native design conventions of that platform.
Goals: comfortable to look at, delightful motion, never monotonous.

---

## 1. Structure

Three main screens, each full-screen, independent — never side-by-side,
never split view. Horizontal order (swipe order) only:

1. Countdown (left)
2. Pomodoro (middle)
3. Clock (right)

Switching:
- Only one screen visible at any time; each fills the entire screen.
- Left/right swipe is a full-screen page transition: current page fully
  exits, next page fully enters.
- Track the finger; light parallax or scale transitions allowed, but every
  page stays full-screen.
- Bounce at boundaries (native feel per platform).
- Fast flings across pages and slow drags both supported.
- Page indicator minimal, not visually prominent.
- While in the shrunken/settings state (long-press), horizontal paging is
  disabled; re-enabled on exit.

Global tone:
- Dark-dominant background; the time is the only visual focus.
- No ads, no IAP, no social, no accounts.
- All settings happen in place — no separate settings page (unless the
  platform convention demands it).

## 2. Countdown screen

Default state:
- Remaining time centered; large, clear digits as the main visual.
- Font: SF Pro Rounded / rounded type by default (map per platform).
- Pure background, no extra decoration.
- Below the time there may be one hairline progress hint, or none.

Long-press:
- Long-press the countdown screen → the interface shrinks (scale ~0.9–0.95);
  the freed area fills with pure black.
- Shrink animation springy, ~0.3–0.4s, natural easing.
- A style bar slides in from the bottom, with slight blur or gradient scrim.
- Long-press again or tap the blank area → restore full screen, bar slides out.

Style bar (bottom), styles switchable with transition animations:

| Style | Behavior |
| --- | --- |
| Ring | Remaining time shown with a circular ring progress; ring depletes/fills clockwise from 12 o'clock; color contrasts comfortably with background |
| Sector | Full-screen sector (pie) progress from 0° sweeping; orange-yellow → orange gradient; smooth edges |
| Dial | A countdown hand rotates behind the digits as time depletes; digits stay in the foreground |
| Plain | Only the remaining-time digits; no progress, no decoration |
| Immersive | SF Compact rounded type stretched edge-to-edge full screen; must detect screen corner radius so glyphs never clip; comfortable weight and tracking |

Editing:
- Tap the currently active style again → enter editing (font color etc.).
- The editor expands in place — no page navigation; natural expand animation.
- Editable items at minimum: font color, possibly background color/opacity,
  ring thickness (as sensible per style).
- Tap blank / back → collapse the editor, keep the settings.

Setting the duration:
- Scroll-wheel list for hours / minutes / seconds.
- Inertia, snapping, and haptic ticks; selected item highlighted/enlarged,
  non-selected fade out; bounce at the ends.

Start / pause / reset:
- Intuitive; buttons must not steal visual focus.
- Haptic feedback and light motion on actions.

## 3. Pomodoro screen

Visual tone:
- Background and type lean orange. Warm, focused, not glaring.
- Saturation controlled; must not look cheap.

Pull-down summary:
- Pull down on the pomodoro screen → expand recent-focus summary.
- Content designed to be clear, restrained, information-aesthetic — not a
  data dashboard.
- May show today/this week focus count, total duration, trend — concise.
- Smooth pull animation; on release, expand or spring back by distance.

Setting the duration:
- Tap the time in the middle → all other elements hide.
- A tick scale appears below the time (no numerals on the scale).
- An inverted triangle above the scale acts as the pointer.
- Drag the scale to change the time above; real-time feedback, smooth
  scrolling, time digits update live.
- Light haptic tick when passing each graduation; sensible density and range.

Focus flow:
- Start focus → countdown runs; the screen enters focus mode with fewer
  distractions.
- Round complete → clear but not jarring cue (haptic + visual + sound).
- Pause / resume / abandon supported.
- Break duration configurable; break screen visually distinct from focus.

## 4. Clock screen

Default state:
- Full-screen current time; digits as the main visual.
- Pure background, clearly readable.

Long-press: same as countdown (shrink, black fill, bottom style bar).

Style bar:

| Style | Behavior |
| --- | --- |
| Analog | Hands instead of digits; smooth sweep |
| Plain | Only the time |
| Immersive | SF Compact rounded stretched edge-to-edge (same rules as countdown) |
| Seven-segment | Retro seven-segment display — retro but not cheap |
| Sun | Auto-detects time of day and applies preset light that changes naturally with time; soft transitions, never abrupt; dawn / noon / dusk / night clearly distinct but blending naturally |

Editing: tap the active style again → in-place editor (font color etc.).

## 5. Typography

- Default font: SF Pro Rounded / rounded style; map to each platform's
  native rounded font — never force iOS fonts elsewhere.
- Immersive modes use SF Compact-like rounded type with corner handling and
  screen-corner detection to avoid overflow.
- Digits must be monospaced/tabular so widths never jitter.
- Size, weight, and tracking adapt to screen size.

## 6. Motion

- Comfortable, delightful, never monotonous.
- Purposeful motion: confirming actions, guiding the eye, expressing time
  flowing.
- No excessive animation, no showing off.
- Natural easing on transitions, scaling, fades, progress (project-wide
  preference: ease-in-out, cubic-bezier(0.4, 0, 0.2, 1)).
- Digit changes may have a slight flip / fade / slide — never flashy.
- On dark backgrounds, bright elements layered to avoid glare.
- Overall rhythm: quiet, breathing.

## 7. Haptics

Every perceivable action gives haptic feedback — restrained, graded, never
abusive. Haptics are confirmation and rhythm, not noise.

- Light: style switch, wheel snap, passing a tick, entering editor.
- Medium: long-press, start/pause focus, pull-down summary.
- Heavy: focus round complete, countdown reaching zero, key milestones.
- No continuous vibration while scrolling — only per-snap ticks.
- Implement per platform's native haptics. Devices without haptics degrade
  to light sound or micro-motion. Follow system accessibility settings
  (reduce motion / disable haptics).

## 8. Platforms

iOS, iPadOS, macOS, HarmonyOS, Windows, Android, Linux.

- The description above reflects iPadOS. Other systems: design the details
  for that system, following its native design conventions.
- Never port one platform's interactions rigidly to another.
- Desktop (macOS, Windows, Linux): mouse, trackpad, keyboard.
- Mobile (iOS, Android, HarmonyOS): gestures, haptics, screen corners,
  notches/punch-holes.
- Tablet (iPadOS): use the large screen without wasting it.

## 9. Overall requirements

- Comfortable, delightful, never monotonous.
- No ads, no IAP, no redundant features.
- Restrained, quiet, breathing.
- No relation to the name "Tick"; no TikTok-style visuals.
- Every perceivable action has graded haptics coordinated with motion and
  sound — supporting, never dominating.
- Engineering structure and code quality: same standard as Tick.

# 🎨 Party Pocket — Design System
**Document Type**: UX Design System  
**Version**: 1.0  
**Platform**: Android (Flutter / Material Design 3)  
**Audience**: Developers, Designers, AI Agents

---

## 1. App Identity & Personality

### Brand Character
The app is a **rowdy, inclusive house party** crammed into a phone. Think:
- **Bold** — nothing is timid; every button is confident
- **Playful** — rounded corners, bouncy animations, emoji-energy
- **Fast** — zero wasted seconds; every screen has one job
- **Legible at arm's length** — text readable from 50cm in a dim room

**Personality keywords**: Electric · Chaotic-fun · Instant · Accessible · Retro-arcade with modern gloss

---

## 2. Color Palette

### Primary Palette — "Neon Carnival"

| Token | Role | Hex | Usage |
|---|---|---|---|
| `partyYellow` | Primary accent, CTAs | `#FFD600` | Buttons, highlights, timers |
| `partyPurple` | Secondary accent | `#7C3AED` | Host elements, headers |
| `partyPink` | Tertiary accent | `#F72585` | Win states, celebrations |
| `partyBlue` | Info / Join flow | `#00B4D8` | Join buttons, QR borders |
| `partyGreen` | Success / Ready | `#06D6A0` | Ready states, positive feedback |
| `partyOrange` | Warning / Urgency | `#FF6B35` | Last-5-seconds timer, alerts |
| `partyRed` | Danger / Lose | `#EF233C` | Elimination, time-out |

### Surface Palette — "Dark Stage"

| Token | Hex | Description |
|---|---|---|
| `stageDark` | `#0D0D1A` | Primary background — near-black indigo |
| `stageCard` | `#1A1A2E` | Card surfaces, panels |
| `stageLift` | `#252545` | Elevated cards, modal backgrounds |
| `stageGlass` | `rgba(255,255,255,0.08)` | Frosted overlays, inactive zones |
| `textPrimary` | `#FFFFFF` | All primary copy |
| `textSecondary` | `#B8B8D4` | Subtitles, hints, labels |
| `textMuted` | `#5A5A7A` | Disabled, placeholders |

### Rationale
- **Dark background**: Reduces glare at parties (bright rooms, outdoor light), saves battery on OLED Android screens, and makes the neon accent colors pop with maximum contrast.
- **Neon accents on dark**: Achieves WCAG AA contrast (≥4.5:1) for primary text. Yellow on dark: ~14:1. White on dark: ~18:1.
- **Color per function**: Yellow=do it, Green=ready, Red=danger. Players learn fast through repetition.

### Flutter Color Scheme Seed

```dart
// In main.dart ThemeData — rename app from "My App" to "Party Pocket":
colorScheme: ColorScheme.dark(
  primary: Color(0xFFFFD600),       // partyYellow
  secondary: Color(0xFF7C3AED),     // partyPurple
  tertiary: Color(0xFFF72585),      // partyPink
  surface: Color(0xFF1A1A2E),       // stageCard
  onPrimary: Color(0xFF0D0D1A),     // dark text on yellow buttons
  onSecondary: Color(0xFFFFFFFF),
  onSurface: Color(0xFFFFFFFF),
  error: Color(0xFFEF233C),
),
scaffoldBackgroundColor: Color(0xFF0D0D1A),
```

---

## 3. Typography

### Font Stack

| Role | Font Family | Weight | Size | Line Height |
|---|---|---|---|---|
| **Game Title / Hero** | `Fredoka One` (Google Fonts) | 700 | 48–72sp | 1.1 |
| **Screen Title** | `Fredoka One` | 400 | 28–36sp | 1.2 |
| **Section Header** | `Nunito` | 800 | 20–24sp | 1.3 |
| **Body / Instructions** | `Nunito` | 600 | 16–18sp | 1.5 |
| **Label / Button** | `Nunito` | 700 | 14–16sp | 1.0 |
| **Caption / Score** | `Nunito` | 400 | 12–14sp | 1.4 |
| **Timer / Countdown** | `Fredoka One` | 700 | 72–120sp | 1.0 |

### Typography Rationale
- **Fredoka One**: Rounded letterforms feel fun, approachable, game-like. Bold weight readable from distance.
- **Nunito**: SemiBold weight ensures legibility. Rounded terminals complement Fredoka. Excellent Latin character support.
- **No serif fonts**: Party setting = quick scanning, not reading. Serifs slow the eye.
- **Minimum body size 16sp**: Accessible default; users won't need to squint.

### Text Scale Support
All sizes use `MediaQuery.textScaleFactor` awareness. Cap at `1.3×` for game screens (prevents layout break during fast gameplay), but full scaling on lobby/results.

```dart
// Pattern for game screens:
Text(
  'SHAKE!',
  style: TextStyle(fontSize: 72 / context.textScaleFactor.clamp(1.0, 1.3)),
)
```

---

## 4. Spacing & Grid

### 8dp Baseline Grid

```
4dp  — micro gaps (icon-to-label, internal padding)
8dp  — small gaps (list item padding, chip spacing)
16dp — standard margin (card padding, screen edge inset)
24dp — medium gap (section separation)
32dp — large gap (hero spacing)
48dp — xlarge (between major sections)
64dp — xxlarge (full-bleed hero areas)
```

### Screen Edge Insets
- **Portrait phone**: 16dp horizontal, 24dp top, 32dp bottom (above nav bar)
- **Landscape phone**: 24dp horizontal, 16dp vertical
- **Tablet (≥600dp wide)**: 32dp horizontal, constrain content to max 560dp centered

### Touch Targets
- **Minimum**: 48×48dp (Material spec)
- **Primary action buttons**: 56dp height, full-width or 280dp minimum width
- **Icon-only buttons**: 56×56dp hit area, 24dp visual icon
- **Player avatar taps**: 72×72dp minimum
- **Game area gestures**: Full screen — no tiny tap zones during gameplay

---

## 5. Elevation & Surfaces

```
0dp  — Background (stageDark)
1dp  — Inactive cards, list items
3dp  — Active cards, selected states
6dp  — Bottom sheets, mini FABs
8dp  — Navigation bars, app bars
12dp — Floating modals, countdown overlays  
24dp — Full-screen overlays (results, game over)
```

Use `Material` widget with `elevation` + `color: stageCard` for consistent shadow rendering on dark surfaces.

---

## 6. Border Radii

| Element | Radius |
|---|---|
| Primary buttons | 28dp (pill-shaped) |
| Cards | 20dp |
| Bottom sheets | 28dp top corners |
| Chips / badges | 50% (full circle) |
| Text fields | 16dp |
| Game tiles | 24dp |
| Avatars | 50% circle |
| Alert dialogs | 28dp |

**Rationale**: Generous rounding = approachable, playful. Nothing sharp or corporate.

---

## 7. Animation & Motion Philosophy

### Core Principle: **"Every action has a reaction"**
The app should feel *alive*. Buttons bounce. Scores count up. Transitions are purposeful — never jarring, never slow.

### Animation Timing Tokens

| Token | Duration | Easing | Use Case |
|---|---|---|---|
| `micro` | 100ms | `easeOut` | Button press feedback, ripple |
| `quick` | 200ms | `easeInOut` | State changes, highlights |
| `standard` | 300ms | `easeInOut` | Screen transitions, card expand |
| `deliberate` | 500ms | `easeOut` | Score reveals, modal appear |
| `dramatic` | 800ms | `elasticOut` | Win/lose moments, countdown |
| `epic` | 1200ms | `bounceOut` | Game results, confetti settle |

### Key Animation Patterns

#### Button Press — "Squash & Stretch"
```
Pointer down:  scale(0.94) in 100ms easeOut
Pointer up:    scale(1.06) in 80ms easeOut  →  scale(1.0) in 120ms elasticOut
```
Gives tactile-like feel on glass screens.

#### Screen Transitions
- **Forward navigation**: New screen slides UP from bottom (75% height) + fade in. Duration: 300ms easeOut.
- **Back navigation**: Current screen slides DOWN off screen. Duration: 250ms easeIn.
- **Game start**: Dramatic ZOOM from center (scale 0→1) with blur dissolve, 500ms.
- **Results reveal**: Screen "flies in" from above, bounces at rest, 800ms elasticOut.

#### Countdown Animation
```
Each number: 
  Appear at scale(2.0) opacity(0) 
  → scale(1.0) opacity(1.0) in 200ms easeOut
  → Hold at scale(1.0) for 600ms
  → Fade + scale(0.8) in 200ms easeIn at end
```

#### Score Count-Up
Numbers roll like an odometer: `AnimatedSwitcher` with `SlideTransition` UP for increases, DOWN for decreases. Duration: 600ms per digit.

#### Idle Animations (Lobby State)
- Avatar icons: Gentle float animation — `sin(time) * 4dp` vertical offset, 2s period, staggered per player.
- Background: Subtle slow-moving gradient blob (opacity 0.15), 8s cycle.
- "Waiting for players" text: Ellipsis dot animation (1→2→3→1), 500ms per step.

### Haptic Feedback
| Event | Haptic Pattern |
|---|---|
| Button tap | `HapticFeedback.lightImpact()` |
| Ready confirm | `HapticFeedback.mediumImpact()` |
| Game starts | `HapticFeedback.heavyImpact()` |
| Player joins | `HapticFeedback.selectionClick()` |
| Win / high score | 3× medium pulses, 100ms apart |
| Lose / eliminated | Long `HapticFeedback.vibrate()`, 300ms |
| Timer last 3 secs | Single light tick per second |

---

## 8. Iconography

### Icon Style: Rounded Filled
Use `Icons.*_rounded` variants exclusively. They match Fredoka One's rounded personality.

### Key Icons
| Concept | Icon |
|---|---|
| Host / Crown | `Icons.star_rounded` (yellow) |
| Join / Enter | `Icons.login_rounded` |
| Players | `Icons.people_rounded` |
| Timer | `Icons.timer_rounded` |
| Settings | `Icons.tune_rounded` |
| QR Code | `Icons.qr_code_scanner_rounded` |
| Ready | `Icons.check_circle_rounded` |
| Trophy | `Icons.emoji_events_rounded` |
| Shuffle | `Icons.shuffle_rounded` |
| Play | `Icons.play_circle_filled_rounded` |

**Icon sizes**: 24dp (inline), 32dp (action icons), 48dp (hero icons), 64dp (results icons)  
**Never use**: Sharp/outlined icon variants — they feel out of character.

---

## 9. Player Avatars & Identity

### Avatar System
Each player gets an **emoji avatar** + **neon color halo** automatically assigned on join. No setup required — instant identity.

### Avatar Assignment
8 unique combos (one per max player slot):

| Slot | Emoji | Halo Color | Label |
|---|---|---|---|
| P1 | 🦊 Fox | `#FFD600` Yellow | "PLAYER 1" |
| P2 | 🐸 Frog | `#06D6A0` Green | "PLAYER 2" |
| P3 | 🐙 Octopus | `#F72585` Pink | "PLAYER 3" |
| P4 | 🤖 Robot | `#00B4D8` Blue | "PLAYER 4" |
| P5 | 🦁 Lion | `#FF6B35` Orange | "PLAYER 5" |
| P6 | 🐱 Cat | `#7C3AED` Purple | "PLAYER 6" |
| P7 | 🐧 Penguin | `#FFFFFF` White | "PLAYER 7" |
| P8 | 🐻 Bear | `#FF4040` Red | "PLAYER 8" |

### Avatar Widget Spec
```
Circle: 56dp diameter (lobby), 40dp (scoreboard), 72dp (results)
Border: 3dp solid [haloColor]
Background: stageCard
Emoji: 32sp (lobby), 24sp (scoreboard), 42sp (results)
Halo glow: BoxShadow spread 4dp, blur 12dp, [haloColor] at 0.6 opacity
```

### Custom Nickname
Players can type a nickname (max 12 chars) that replaces "PLAYER X" label. Shows below avatar in all contexts.

---

## 10. Sound Design Philosophy

*(Implementation reference — not Flutter-specific)*

| Moment | Sound Character |
|---|---|
| App open | Punchy 2-note synth chord (C + E, 200ms) |
| Button tap | Soft tick (8-bit, 50ms) |
| Player joins | Upward blip (ascending 3-note arpeggio) |
| All players ready | Satisfying "lock-in" click + reverb tail |
| Countdown 3-2-1 | Deep drum hit per number, pitch rises |
| Game start ("GO!") | Air-horn blast (100ms), crowd cheer (500ms) |
| In-game ambient | Per-game BG music loop (8s), energetic |
| Win | Fanfare 4-note ascending (C-E-G-C), 800ms |
| Lose | Descending wah sound, 600ms |
| Score tick | Coin collect blip per point |

All sounds: Optional (system mute respected). Volume slider in settings.

---

## 11. Flutter Theme Configuration

```dart
// lib/theme/party_pocket_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PartyPocketTheme {
  // Colors
  static const partyYellow  = Color(0xFFFFD600);
  static const partyPurple  = Color(0xFF7C3AED);
  static const partyPink    = Color(0xFFF72585);
  static const partyBlue    = Color(0xFF00B4D8);
  static const partyGreen   = Color(0xFF06D6A0);
  static const partyOrange  = Color(0xFFFF6B35);
  static const partyRed     = Color(0xFFEF233C);
  static const stageDark    = Color(0xFF0D0D1A);
  static const stageCard    = Color(0xFF1A1A2E);
  static const stageLift    = Color(0xFF252545);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: stageDark,
    colorScheme: const ColorScheme.dark(
      primary: partyYellow,
      onPrimary: stageDark,
      secondary: partyPurple,
      onSecondary: Colors.white,
      tertiary: partyPink,
      surface: stageCard,
      onSurface: Colors.white,
      error: partyRed,
    ),
    textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.fredokaOne(
        fontSize: 72, color: Colors.white,
      ),
      headlineLarge: GoogleFonts.fredokaOne(
        fontSize: 36, color: Colors.white,
      ),
      headlineMedium: GoogleFonts.fredokaOne(
        fontSize: 28, color: Colors.white,
      ),
      titleLarge: GoogleFonts.nunito(
        fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white,
      ),
      bodyLarge: GoogleFonts.nunito(
        fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,
      ),
      labelLarge: GoogleFonts.nunito(
        fontSize: 16, fontWeight: FontWeight.w700, color: stageDark,
        letterSpacing: 0.5,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: partyYellow,
        foregroundColor: stageDark,
        minimumSize: const Size(280, 56),
        shape: const StadiumBorder(),
        elevation: 4,
        textStyle: GoogleFonts.nunito(
          fontSize: 16, fontWeight: FontWeight.w800,
        ),
      ),
    ),
    cardTheme: CardTheme(
      color: stageCard,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );
}
```

---

## 12. Accessibility Checklist

| Requirement | Implementation |
|---|---|
| **Color contrast ≥ 4.5:1** | All text on dark backgrounds. White on `stageDark` = 18:1 ✅ |
| **Touch targets ≥ 48dp** | All interactive elements enforced via `SizedBox` or `InkWell` constraints |
| **Screen reader support** | `Semantics()` wrappers on all custom widgets. Emoji avatars have `label` properties |
| **Text scaling** | Game UIs capped at 1.3×, lobby/results fully scalable |
| **Keyboard navigation** | All `Focus` nodes properly ordered. `FocusTraversalGroup` in forms |
| **Motion sensitivity** | "Reduce animations" toggle in settings, respects `MediaQuery.disableAnimations` |
| **Color-blind safe** | Never use color as the ONLY differentiator. Always pair with shape/icon/text |
| **Session labels** | Timer announced via `LiveRegion` / `SemanticsProperties.liveRegion` |
| **No time pressure on non-game screens** | Lobby/join screens have no countdown |

---

*Next: See `USER_FLOW_COMPLETE.md` for all user journeys and `WIREFRAME_SCREENS.md` for screen-by-screen layouts.*

# 📱 Party Pocket — Screen Wireframes & Layouts
**Document Type**: Wireframe Specifications  
**Version**: 1.0  
**Companion**: `UX_DESIGN_SYSTEM.md`, `USER_FLOW_COMPLETE.md`

All layouts described for a **portrait 390×844dp phone** (typical Android flagship).  
`[W]` = full width available. `dp` = density-independent pixels.

---

## SCREEN 01: Splash Screen

**Duration**: 1.5 seconds (non-skippable)  
**Purpose**: Brand moment, app initialization

```
┌─────────────────────────────────────┐  ← 390dp wide
│                                     │
│                                     │
│                                     │
│        ╔═══════════════╗            │
│        ║   🎉          ║            │
│        ║  PARTY        ║  ← Fredoka One, 72sp
│        ║  POCKET       ║    partyYellow
│        ╚═══════════════╝            │
│                                     │
│     "Grab your friends!"            │  ← Nunito 600, 16sp
│                                     │    textSecondary
│                                     │
│        ███████████████              │  ← Loading bar
│        ▓▓▓▓▓▓▓░░░░░░░              │    partyYellow, 4dp tall
│                                     │    animates 0→100% in 1.2s
└─────────────────────────────────────┘
  Background: stageDark (#0D0D1A)
  Animated background: 3 slow-floating blobs
    - partyPurple blob, top-left, 200dp, opacity 0.15
    - partyBlue blob, bottom-right, 150dp, opacity 0.12
    - partyPink blob, center, 120dp, opacity 0.08
```

### Animation Sequence
1. `t=0ms`: Background blobs fade in (500ms)
2. `t=300ms`: Logo icon scales in from 0→1.15→1.0 (elasticOut, 600ms)
3. `t=600ms`: "PARTY POCKET" slides up from -20dp (300ms easeOut)
4. `t=900ms`: Tagline fades in (200ms)
5. `t=1000ms`: Loading bar sweeps left to right (500ms linear)
6. `t=1500ms`: Crossfade to Home Screen

---

## SCREEN 02: Home / Welcome Screen

**Purpose**: Single decision point — host or join  
**Design Principle**: Two actions, nothing else. No nav bar, no tabs.

```
┌─────────────────────────────────────┐
│  ⚙️                           🔊    │  ← 56dp top bar
│  settings icon (left)  sound (right)│    both 48×48dp tap targets
│                                     │
│                                     │
│        🎉 PARTY POCKET               │  ← Fredoka One 48sp
│                                     │    partyYellow
│                                     │
│  ┌───────────────────────────────┐  │
│  │  🏠  HOST A GAME              │  │  ← Primary button
│  │      "Start a new party"      │  │    Height: 80dp
│  └───────────────────────────────┘  │    Background: partyYellow
│  ┌───────────────────────────────┐  │    Radius: 20dp
│  │  🚪  JOIN A GAME              │  │  ← Secondary button
│  │      "Enter a room code"      │  │    Height: 80dp
│  └───────────────────────────────┘  │    Background: stageLift
│                                     │    Border: 2dp partyBlue
│  ─────────── OR ───────────         │
│  ┌───────────────────────────────┐  │
│  │  🎲  SOLO PRACTICE            │  │  ← Tertiary (ghost)
│  │      "Try games by yourself"  │  │    Height: 64dp
│  └───────────────────────────────┘  │    Background: transparent
│                                     │    Border: 1dp textMuted
│                                     │
│  "Best with 2–8 friends on WiFi"    │  ← Caption, textMuted, 13sp
│                                     │
└─────────────────────────────────────┘
```

### Component Specs
- **HOST button**: Icon 28dp + text + subtitle. On tap: scale(0.94)→scale(1.0). Navigate to HOST_LOBBY.
- **JOIN button**: Same size. Navigates to JOIN_SCREEN.
- **SOLO button**: Smaller, clearly tertiary. For testing/demos.
- **Background**: Animated gradient blob (slow, subtle) behind main content.
- **Settings icon**: Top-left. 48×48dp tap target. Opens Settings bottom sheet.
- **Sound icon**: Top-right. Toggles audio. State persists in SharedPreferences.

### Accessibility
```dart
Semantics(
  label: 'Host a game. Start a new party for 2 to 8 players.',
  button: true,
  child: HostButton(),
)
Semantics(
  label: 'Join a game. Enter a room code from your host.',
  button: true,
  child: JoinButton(),
)
```

---

## SCREEN 03: Nickname Entry Screen

**Purpose**: One-time setup. Skipped on repeat launches.  
**When shown**: First HOST or JOIN action only.

```
┌─────────────────────────────────────┐
│  ←  (back to home)                  │  ← 48dp back button
│                                     │
│                                     │
│        👋 What's your name?         │  ← Fredoka One 36sp
│                                     │    white
│     We'll show this to your         │  ← Nunito 600, 16sp
│     friends in the game.            │    textSecondary
│                                     │
│  ┌─────────────────────────────┐   │
│  │   Alex                      │   │  ← TextField
│  └─────────────────────────────┘   │    Height: 60dp
│       12 chars max, auto-cap        │    Border: 2dp partyBlue
│       Hint: "Enter your name"       │    Focused: partyYellow
│                                     │
│   PICK YOUR LOOK:                   │  ← Nunito 800, 14sp
│                                     │    textSecondary
│  🦊  🐸  🐙  🤖  🦁  🐱  🐧  🐻    │  ← 8 emoji avatars
│  [selected has yellow ring]         │    56×56dp each, 8dp gap
│                                     │    Row scrollable if needed
│                                     │
│  ┌───────────────────────────────┐  │
│  │      LET'S PLAY! →            │  │  ← Primary button
│  └───────────────────────────────┘  │    Disabled if name empty
│                                     │    Height: 56dp
└─────────────────────────────────────┘
```

### Interaction Notes
- **Auto-focus**: TextField focused immediately on screen load, keyboard opens.
- **Avatar default**: First emoji pre-selected. Tapping selects with yellow ring animation.
- **Button state**: Disabled/grey until name has ≥1 non-space character.
- **On confirm**: Name + avatar saved to SharedPreferences. Screen dismissed.

---

## SCREEN 04: Host Lobby

**Purpose**: Room management, waiting for players, QR sharing  
**This is the host's "control room"**

```
┌─────────────────────────────────────┐
│  ← Home      🎉 YOUR PARTY    ⚙️    │  ← Top bar, 56dp
│                                     │
│  ┌─────────────────────────────┐   │
│  │  Room Code:                 │   │  ← Code card
│  │  ┌───┐ ┌───┐ ┌───┐ ┌───┐  │   │    stageCard, radius 20dp
│  │  │ P │ │ Z │ │ R │ │ K │  │   │    Code letters: Fredoka One 48sp
│  │  └───┘ └───┘ └───┘ └───┘  │   │    partyYellow, each in box
│  │                             │   │    4dp gap between boxes
│  │  ┌───────────────────────┐ │   │
│  │  │  ░░░▓▓░░░▓░░▓▓▓░░░   │ │   │  ← QR Code widget
│  │  │  ▓░░░░░▓▓░░░░░▓░░▓   │ │   │    140×140dp square
│  │  │  ░▓▓░░░░░░▓▓░░░░░░   │ │   │    white background
│  │  └───────────────────────┘ │   │    border: 4dp partyBlue
│  │                             │   │
│  │  [📋 COPY CODE] [📤 SHARE] │   │  ← Two small action buttons
│  └─────────────────────────────┘   │    Height: 40dp each
│                                     │
│  PLAYERS (2/8)                      │  ← Section label
│                                     │    Nunito 800, 14sp textSecondary
│  ┌─────────────────────────────┐   │
│  │ 🦊 Alex        👑 HOST      │   │  ← Player row
│  ├─────────────────────────────┤   │    Height: 64dp each
│  │ 🐸 Sam         ✅ READY     │   │    Avatar: 44dp
│  ├─────────────────────────────┤   │    Crown icon: 20dp partyYellow
│  │ 👤 Waiting...               │   │  ← Empty slot
│  │ 👤 Waiting...               │   │    Pulsing opacity: 0.4→0.7
│  │ 👤 Waiting...               │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  🎮  PICK A GAME →            │  │  ← CTA Button
│  └───────────────────────────────┘  │    Yellow when ≥2 players
│  "Waiting for 1 more player..."     │    Grey + text when <2
└─────────────────────────────────────┘
```

### Player Row States
```
Active / Host:   [Avatar] [Name]          [👑 HOST]      — gold crown right
Active / Ready:  [Avatar] [Name]          [✅ READY]     — green badge right
Active / Waiting:[Avatar] [Name]          (no badge)     — avatar subtle pulse
Disconnected:    [Avatar📵] [Name]        [⚠️ LOST]      — greyed avatar
Empty slot:      [👤]  [Waiting...]       —               — 40% opacity, wave pulse
```

### QR Code Widget
The QR encodes: `partypack://join?code=PZRK&host=Alex` — a deep link URL.  
If the target phone has the app, it opens directly to Join with code pre-filled.  
If not, it shows the app store link + the code prominently.

---

## SCREEN 05: Join Screen

**Purpose**: Entry point for guest players — scan or type  
**Goal**: Absolute minimum friction to get into a room

```
┌─────────────────────────────────────┐
│  ← Home      JOIN A GAME            │  ← Top bar
│                                     │
│  ┌─────────────────────────────┐   │
│  │  📷                         │   │  ← Camera viewfinder
│  │                             │   │    200×200dp square
│  │   [live camera feed]        │   │    Corner brackets (not full border)
│  │   [QR scanning overlay]     │   │    Animated scan line sweeps ↕
│  │   Aim at the QR code        │   │    Text below: 12sp textSecondary
│  └─────────────────────────────┘   │
│                                     │
│  ─────────── or type it ──────────  │  ← Divider with label
│                                     │
│     ┌────┐  ┌────┐  ┌────┐  ┌────┐ │  ← 4 letter boxes
│     │    │  │    │  │    │  │    │ │    Each: 68×80dp
│     │    │  │    │  │    │  │    │ │    Fredoka One 40sp
│     └────┘  └────┘  └────┘  └────┘ │    partyYellow text
│          ROOM CODE                  │    Active box: 2dp yellow border
│                                     │    Inactive: 1dp textMuted border
│  ┌───────────────────────────────┐  │
│  │      JOIN →                   │  │  ← Button: disabled until 4 chars
│  └───────────────────────────────┘  │    Auto-submits on 4th letter
│                                     │
│  "Make sure you're on the same WiFi"│  ← Helper text, 12sp textMuted
└─────────────────────────────────────┘
```

### Input Behavior
- **Physical keyboard**: Type letters, each fills a box left-to-right. Backspace clears last.
- **On-screen keyboard**: Automatically opens. Type freely.
- **Auto-uppercase**: All input forced to uppercase.
- **Auto-submit**: On 4th character entry, JOIN triggers automatically (no button tap needed).
- **QR scan**: Auto-triggers join when QR code detected. Camera permission requested here.
- **Error state**: Letter boxes shake (horizontal, 8px, 3 oscillations) + turn red briefly.

---

## SCREEN 06: Guest Lobby

**Purpose**: Player waits for host to start the game  
**Key emotion**: Anticipation, social — see who else is here

```
┌─────────────────────────────────────┐
│  ⚠️ (only if connection issues)      │  ← Top bar minimal
│                                     │
│  🎉 ALEX'S PARTY                    │  ← Room host name
│  Room: PZRK                        │    Fredoka One 28sp
│                                     │
│  ┌─────────────────────────────┐   │
│  │         YOUR SQUAD          │   │  ← stageCard panel
│  │                             │   │
│  │  🦊Alex 👑  🐸Sam ✅         │   │  ← Avatars in grid
│  │  🐙You! ●  🤖Mike           │   │    56dp each
│  │  👤...  👤...  👤...        │   │    "You!" label under yours
│  │                             │   │    Host has crown
│  └─────────────────────────────┘   │
│                                     │
│        "Waiting for Alex            │  ← Status text
│         to start the game..."       │    textSecondary, 16sp
│                                     │    Ellipsis animation
│  ┌─────────────────────────────┐   │
│  │    YOUR AVATAR: 🐙          │   │  ← Player's own info card
│  │    Name: Jordan             │   │    Compact, reassuring
│  │    [CHANGE ✏️]              │   │    Small edit button
│  └─────────────────────────────┘   │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  ✅  I'M READY!               │  │  ← Green button, full width
│  └───────────────────────────────┘  │    Toggles ready state
│  Tap to signal you're ready to play │    On tap → becomes "READY ✓" state
└─────────────────────────────────────┘
```

### Ready Button States
```
Not ready:  [Green bg]  "✅ I'M READY!"   — pulsing glow
Ready:      [Dark bg]   "✓ READY!"        — no pulse, checkmark, static
             ← avatar in group grid gets green halo
```

---

## SCREEN 07: Game Selection Screen

**Purpose**: Host chooses the next mini-game  
**Host-only screen** — guests see a "Host is picking..." screen simultaneously

```
HOST VIEW:
┌─────────────────────────────────────┐
│  ←      PICK A GAME          🎲     │  ← 🎲 = random button
│         "Your players: 4"           │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  🔍 Search games...          │  │  ← Search bar (optional)
│  └──────────────────────────────┘  │    Height: 48dp
│                                     │
│  ──── CROWD FAVORITES ────          │  ← Section header
│  (most popular based on play count) │
│                                     │
│  ┌──────────┐  ┌──────────┐        │
│  │          │  │          │        │  ← Game tiles
│  │   🤝     │  │   📱     │        │    2-column grid
│  │  SHAKE   │  │  QUICK   │        │    Each tile: 160×180dp
│  │  IT!     │  │  DRAW    │        │    stageCard bg
│  │          │  │          │        │    radius: 24dp
│  │ 2–8 👥  │  │ 2–6 👥   │        │    Game icon: 56dp emoji
│  │ ⏱ 30s   │  │ ⏱ 45s    │        │    Name: Fredoka One 20sp
│  └──────────┘  └──────────┘        │    Info: Nunito 12sp textSecondary
│  ┌──────────┐  ┌──────────┐        │    Player count + timer
│  │   🎯     │  │   🏃     │        │    Bottom of card
│  │  STEADY  │  │  TILT    │        │
│  │  HAND    │  │  RACER   │        │
│  │          │  │          │        │
│  │ 2–8 👥  │  │ 2–8 👥   │        │
│  │ ⏱ 60s   │  │ ⏱ 45s    │        │
│  └──────────┘  └──────────┘        │
│                                     │
│  [scroll for more...]               │
│                                     │
│  ─────── ALL GAMES (12) ──────      │
│  [continues scrolling...]           │
└─────────────────────────────────────┘

GUEST VIEW (simultaneously):
┌─────────────────────────────────────┐
│                                     │
│         🎮                          │  ← 80dp game controller icon
│                                     │    Bouncing animation
│   Alex is picking a game...         │  ← Fredoka One 28sp
│                                     │
│   ┌─────────────────────────────┐  │
│   │   Meanwhile, cast your vote! │  │
│   │                              │  │  ← Voting panel
│   │   👍 Play again (Shake It!)  │  │    textSecondary 14sp
│   │       ████████░░░  3 votes   │  │
│   │                              │  │
│   │   🔀 Something new           │  │
│   │       ████░░░░░░░  1 vote    │  │
│   └─────────────────────────────┘  │
│                                     │
│   These are suggestions only —      │  ← 12sp textMuted
│   Alex decides!                     │
└─────────────────────────────────────┘
```

### Game Tile Selected State
When host taps a tile:
1. Tile scales to 1.08×, yellow border appears (3dp)
2. Other tiles dim to 0.6 opacity
3. "START THIS GAME →" button appears at bottom (animated up)
4. Tap again to deselect (no accidental starts)

---

## SCREEN 08: Instruction Screen (Pre-Game)

**Purpose**: Teach everyone the game in ≤3 seconds  
**Shown on ALL players' phones simultaneously**

```
┌─────────────────────────────────────┐
│  ← PZRK                  ⏭ SKIP   │  ← Skip shown after 1s
│                                     │    Auto-proceeds at 3s
│                                     │
│            🤝                       │  ← Game icon, 80dp
│                                     │    bounces in at t=0
│       SHAKE IT!                     │  ← Fredoka One 48sp
│                                     │    white
│                                     │
│  ┌─────────────────────────────┐   │
│  │                             │   │  ← Instruction panel
│  │  Shake your phone as fast   │   │    stageCard, radius 20dp
│  │  as possible!               │   │    Nunito 700 20sp
│  │                             │   │    Centered
│  │    [PHONE ICON ANIMATION]   │   │  ← Animated phone graphic
│  │    ↕↕↕ shake illustration   │   │    SVG/Lottie, 120×120dp
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│       ┌────┐  ┌────┐  ┌────┐       │  ← 3 step indicators
│       │ ✓ │  │ 2  │  │ 3  │       │    28dp circles
│       └────┘  └────┘  └────┘       │    1 = yellow filled
│    Done    Hold    Score            │    2,3 = outline
│                                     │
│  ████████████████████████░░░░░      │  ← Auto-progress bar
│  Starts in 2 seconds...             │    sweeps right in 3s
└─────────────────────────────────────┘
```

### Multi-Step Instructions
For complex games (>1 step), the screen shows 3 steps max, each for 1 second:
- Step 1 shows, 1s → Step 2 shows (slide left), 1s → Step 3 shows, 1s → Go

### Skip Behavior
- Host taps SKIP → broadcasts skip to all → countdown begins immediately
- Guest taps SKIP → sends "ready" signal to host only (host sees ready indicators)
- When all guests tap skip OR timer expires → countdown triggers

---

## SCREEN 09: Countdown Screen

**Purpose**: Synchronization moment — all players at same pace

```
┌─────────────────────────────────────┐  ← Full-bleed, no chrome
│                                     │
│                                     │
│                                     │
│                                     │
│           ╔══════════╗              │
│           ║    3     ║              │  ← Fredoka One 144sp
│           ╚══════════╝              │    partyOrange
│                                     │    Enters: scale(2)→scale(1)
│                                     │    200ms easeOut
│                                     │    Haptic on each
│                                     │
│   🦊Alex 🐸Sam 🐙Jordan 🤖Mike     │  ← Player row
│                                     │    At bottom, 40dp avatars
│                                     │    All have green "READY" glow
└─────────────────────────────────────┘

Background: Solid partyPurple (or game-themed color)

Sequence:
  t=0ms   "3" — partyOrange — heavyImpact haptic
  t=1000ms "2" — partyOrange — heavyImpact haptic
  t=2000ms "1" — partyOrange — heavyImpact haptic
  t=3000ms "GO!" — partyYellow — 3× rapid pulses haptic
            Scale: 1.0 → 1.4 → 1.0 → game starts
```

---

## SCREEN 10: In-Game UI (Generic Template)

**Purpose**: Game-specific content — this is the shell around each mini-game  
**Design**: Near full-screen for game content. Status bar only at top.

```
┌─────────────────────────────────────┐
│  🦊 Alex        ⏱ 00:28    🐸 Sam  │  ← HUD bar: 48dp tall
│  [Score: 47]   [timer]  [Score: 32] │    stageDark background
│                 center              │    Semi-transparent overlay
│─────────────────────────────────────│
│                                     │
│                                     │
│         [GAME CONTENT AREA]         │  ← 100% remaining height
│                                     │    Each game owns this space
│   This area is fully custom         │    No standard chrome
│   per mini-game.                    │
│                                     │
│   Examples:                         │
│   - Full-screen shaking progress    │
│   - Tilt sensor canvas              │
│   - Tap-anywhere button             │
│   - Accelerometer visualization     │
│                                     │
│                                     │
└─────────────────────────────────────┘

TIMER STATES:
  > 10s: White text, standard size (32sp)
  ≤10s: partyOrange text, same size
  ≤ 5s: partyOrange text + pulse animation (scale 1.0→1.1 each second)
         + single haptic tick per second
  = 0s: "TIME'S UP!" flash — full screen white flash 200ms → results
```

### HUD for 3–8 Players (Compact Mode)
When 3+ players, HUD shows only current player's score + timer.  
Other players' scores in collapsible mini-bar below HUD.

### Pause / Emergency Exit
Long-press anywhere for 1 second → pause menu appears:  
`[RESUME]  [QUIT GAME]`  
This prevents accidental exits but allows recovery.

---

## SCREEN 11: Immediate Result (Per-Player)

**Purpose**: 2-second personal result flash before group scoreboard  
**Full screen — maximally impactful**

```
WIN STATE:
┌─────────────────────────────────────┐
│  [gold confetti particles falling]  │
│                                     │
│           🦊                        │  ← Player's avatar, 80dp
│           ⭐⭐⭐                     │    3 stars animate in
│                                     │
│        1st Place!                   │  ← Fredoka One 72sp
│                                     │    partyYellow
│        +250 points                  │  ← Score, 36sp white
│                                     │
│   [Auto-advances in 2 seconds...]   │
└─────────────────────────────────────┘
Background: Animated gold burst from center

LOSS STATE:
┌─────────────────────────────────────┐
│                                     │
│           😅                        │  ← Emoji, 80dp
│                                     │
│        4th Place                    │  ← Fredoka One 64sp
│                                     │    textSecondary (muted)
│        +30 points                   │  ← Score, 28sp
│                                     │
│   [Auto-advances in 2 seconds...]   │
└─────────────────────────────────────┘
Background: stageDark, no particles
```

---

## SCREEN 12: Results / Scoreboard

**Purpose**: Shared moment — show standings, celebrate/commiserate  
**Shown on ALL phones simultaneously (same data)**

```
┌─────────────────────────────────────┐
│       RESULTS — SHAKE IT!           │  ← Nunito 800 18sp textSecondary
│                                     │
│            🏆                       │  ← Trophy, 64dp, bounces in
│           🦊 Alex                   │  ← 1st place hero slot
│           1,247 pts                 │    Fredoka One 48sp partyYellow
│           ██████████████            │    Score bar 100% width
│                                     │
│        🥈  🐸 Sam  ·  891          │  ← 2nd place: 36sp
│             █████████░░             │
│        🥉  🤖 Mike ·  654          │  ← 3rd place: 28sp
│             ███████░░░░░            │
│                                     │
│  ─── OTHERS ───                     │
│  4.  🐙 Jordan        430  ████     │  ← Compact rows
│  5.  🐱 Sam K         210  ██       │    20sp each
│                                     │
│  THIS GAME  |  SESSION TOTAL        │  ← Tab selector
│  [tab underline animation]          │    switches between views
│                                     │
│  ┌───────────────────────────────┐  │
│  │  HOST: [PICK NEXT GAME]       │  │  ← Host sees this
│  │        [PLAY AGAIN]           │  │    Guest sees:
│  │        [END PARTY]            │  │    "Waiting for Alex..."
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

### Score Bar Animation
Each bar animates from 0→width in staggered order:
- 1st place: t=300ms, 600ms fill duration
- 2nd place: t=500ms, 500ms fill duration  
- 3rd place: t=700ms, 400ms fill duration
- Others: t=900ms+100ms each, 300ms duration

Score numbers count up from 0 like an odometer during bar fill.

---

## SCREEN 13: Settings Bottom Sheet

```
┌─────────────────────────────────────┐
│              Settings               │  ← Handle bar at top
│  ─────────────────────────────────  │    (12×4dp, rounded, textMuted)
│                                     │
│  🔊  Sound Volume                   │
│      ██████████░░░░  70%            │  ← Slider
│                                     │
│  📳  Vibration                      │
│                              [ON ●] │  ← Toggle
│                                     │
│  🎭  Reduce Animations              │
│                             [OFF ○] │  ← Toggle
│                                     │
│  👤  My Nickname                    │
│      ┌──────────────────────────┐   │
│      │  Alex                    │   │  ← Editable inline
│      └──────────────────────────┘   │
│                                     │
│  🎨  My Avatar                      │
│      🦊  🐸  🐙  🤖  🦁  🐱  🐧 🐻│  ← Scrollable row
│      [selected: yellow ring]        │
│                                     │
│  ─────────────────────────────────  │
│  v1.0.0  · Made with ❤️ in Flutter  │  ← Footer caption
│                                     │
│  ┌───────────────────────────────┐  │
│  │           DONE ✓              │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘

Sheet height: 65% of screen
Background: stageCard
Corner radius: 28dp top
```

---

## Responsive Behavior: Tablet / Large Screen

For screens ≥600dp wide (tablets, foldables), apply:

```
HOME SCREEN:      Two buttons side-by-side, max width 480dp centered
HOST LOBBY:       QR code stays visible alongside player list (two columns)
JOIN SCREEN:      Camera viewfinder larger (300×300dp), code boxes larger
GAME SELECTION:   3-column grid instead of 2
IN-GAME:          Content centered, max 480dp width, letterboxed sides
RESULTS:          Podium in center, scrollable list alongside
```

---

## Screen Inventory Summary

| # | Screen | Triggered By | Exit To |
|---|---|---|---|
| 01 | Splash | App launch | Home |
| 02 | Home | Splash end | Host Lobby / Join / Solo |
| 03 | Nickname Entry | First HOST or JOIN | Host Lobby / Join |
| 04 | Host Lobby | HOST button | Game Selection |
| 05 | Join Screen | JOIN button | Guest Lobby |
| 06 | Guest Lobby | Successful join | Pre-Game Instructions |
| 07 | Game Selection | Host taps PICK GAME | Pre-Game Instructions |
| 08 | Instruction Screen | Game selected | Countdown |
| 09 | Countdown | Instructions complete | In-Game |
| 10 | In-Game | Countdown ends | Immediate Result |
| 11 | Immediate Result | Game ends | Group Results |
| 12 | Results / Scoreboard | All results in | Game Selection / Home |
| 13 | Settings Sheet | ⚙️ icon (any screen) | Returns to previous |

**Total screens: 13** — lean and purposeful.

---

*Next: See `UX_DESIGN_MINIGAME_PATTERNS.md` for mini-game interaction patterns and `UX_DESIGN_MULTIPLAYER.md` for sync/accessibility specs.*

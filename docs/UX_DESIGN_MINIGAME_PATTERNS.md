# 🎮 Party Pocket — Mini-Game UX Patterns & Multiplayer Design
**Document Type**: Interaction Patterns & Multiplayer UX  
**Version**: 1.0  
**Companion**: `UX_DESIGN_SYSTEM.md`, `USER_FLOW_COMPLETE.md`, `WIREFRAME_SCREENS.md`

---

## Part 1: Mini-Game UX Patterns

### 1.1 The 3-Second Teaching Rule

Every mini-game must be learnable in **3 seconds or less**. This is non-negotiable. Party games fail when:
- Players have to read multiple paragraphs
- Rules require explanation from another human
- The mechanic isn't instantly obvious

**Design constraint**: If you can't explain the game in ≤12 words with one visual, redesign the mechanic.

### 1.2 Instruction Screen Pattern

#### The Single-Rule Template

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│    [GAME ICON — 80dp, animated bounce-in]                  │
│                                                             │
│    GAME NAME                        ← Fredoka One 48sp     │
│                                                             │
│    ┌─────────────────────────────────────────────────┐     │
│    │                                                 │     │
│    │  "[VERB] your phone [HOW] to [GOAL]"            │     │
│    │                                                 │     │
│    │    [ANIMATED GESTURE ILLUSTRATION]              │     │
│    │                                                 │     │
│    └─────────────────────────────────────────────────┘     │
│                                                             │
│    Auto-proceeds in [X] seconds...   ← progress bar        │
│    Tap anywhere to skip              ← 12sp textMuted       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Gesture Illustration Library

Each game type needs a gesture animation (Lottie or custom Flutter animation):

| Gesture | Animation Description | Duration |
|---|---|---|
| **Shake** | Phone icon oscillating ↕↕↕ rapidly with motion blur | Loop, 0.5s cycle |
| **Tilt left/right** | Phone rotating on Z-axis, arrow showing direction | Loop, 1.5s |
| **Tilt forward/back** | Phone rotating on X-axis | Loop, 1.5s |
| **Tap screen** | Finger icon descending onto screen, ripple | Loop, 1s |
| **Hold steady** | Phone icon with spirit level bubble centered | Loop, 2s |
| **Swipe** | Finger dragging across screen with trail | Loop, 1s |
| **Press & hold** | Finger pressing down, hold ring filling | Loop, 2s |
| **Rotate phone** | Phone spinning in 2D plane | Loop, 2s |

All animations: White phone icon on transparent bg, 120×120dp canvas.

---

### 1.3 Catalog of Mini-Game UX Types

Each game type has a standardized UI shell. Here are the 8 core interaction patterns:

---

#### Type A: SPEED CHALLENGE — "Shake It!"
**Mechanic**: Shake phone as fast as possible. Score = shake count in 30s.  
**Phone sensor**: Accelerometer  
**Players**: Each on their own phone, competing simultaneously

```
IN-GAME UI:
┌─────────────────────────────────────┐
│  🦊 47        ⏱ 00:14        🐸 31  │  ← HUD
│─────────────────────────────────────│
│                                     │
│           SHAKE!!                   │  ← Fredoka One 64sp
│                                     │    Text shakes when device shakes
│      ╔═══════════════════╗          │
│      ║ ████████████░░░░░ ║          │  ← Progress bar YOUR score
│      ║   47 SHAKES       ║          │    Live count
│      ╚═══════════════════╝          │
│                                     │
│   [Phone icon that shakes in sync   │  ← Visual feedback
│    with the actual device motion]   │    Flutter animation driven by
│                                     │    accelerometer magnitude
│      🦊 ████████████░░░░  47        │  ← Mini player bars
│      🐸 ██████████░░░░░░  31        │    UPDATE via WiFi every 500ms
│      🐙 ████░░░░░░░░░░░░  18        │
│                                     │
└─────────────────────────────────────┘
```

**Real-time feedback**: Player's bar fills as they shake. Opponent bars update via LAN every 500ms (not real-time — prevents network flooding).

**Scoring**: `score = accelerometerEventCount` filtered by magnitude threshold (>2.0 g-force = valid shake, prevents minor jitter counting).

---

#### Type B: PRECISION CHALLENGE — "Steady Hand"
**Mechanic**: Hold phone completely still. Last player to move wins.  
**Phone sensor**: Gyroscope + accelerometer  
**Players**: All active simultaneously — last one standing wins

```
IN-GAME UI:
┌─────────────────────────────────────┐
│  🦊 ✅  🐸 ✅  🐙 ✅  🤖 ✅        │  ← Checkmarks = still
│         ⏱ 00:45                     │    ✗ = eliminated
│─────────────────────────────────────│
│                                     │
│    ████████████████████████████     │  ← Stability meter
│    ███████████████████████░░░░░     │    Your own meter
│    [VERY STEADY]   ← label changes  │    Green→Yellow→Red
│                                     │
│         BE STILL...                 │  ← Text pulses very slowly
│                                     │
│    ╔═══════════════════════════╗    │
│    ║  ◉  ← spirit level ball  ║    │  ← Spirit level widget
│    ║       centered = good     ║    │    Circle, 180×180dp
│    ╚═══════════════════════════╝    │    Ball position mirrors phone tilt
│                                     │    Green zone = safe
│                                     │    Red zone = about to be eliminated
└─────────────────────────────────────┘

ELIMINATION:
When player moves too much (threshold exceeded):
  → Full-screen flash: RED
  → Huge "💥 OUT!" text
  → Device vibrates once (300ms)
  → Player's avatar greys out in HUD
  → Phone shows: "You're out! Watch the others..."
  → Screen switches to spectator view (see all players' stability meters)
```

---

#### Type C: REACTION CHALLENGE — "Quick Draw"
**Mechanic**: Tap the moment the signal appears. Fastest tap wins.  
**Phone sensor**: Touch screen  
**Players**: All tap their own screen simultaneously

```
WAITING PHASE:
┌─────────────────────────────────────┐
│              ⏱ —:—                  │
│─────────────────────────────────────│
│                                     │
│                                     │
│                                     │
│         DON'T TAP YET...            │  ← Red text, 48sp
│                                     │    Slight trembling animation
│                                     │    (psyches players out)
│         [RANDOM DELAY 1–5 seconds]  │
│                                     │
│                                     │
│                                     │
└─────────────────────────────────────┘
Background: partyRed (danger color = not yet)

FIRE PHASE:
┌─────────────────────────────────────┐
│              ⏱ 00:03               │  ← Counts UP after signal
│─────────────────────────────────────│
│                                     │
│                                     │
│                                     │
│    ██████████████████████████████   │
│    ██████████████████████████████   │
│           TAP!! TAP!! TAP!!         │  ← 96sp HUGE
│    ██████████████████████████████   │    Flashing yellow
│    ██████████████████████████████   │    Background: partyGreen
│                                     │
│                                     │
│                                     │
└─────────────────────────────────────┘

TAP RESULT (shown for 1 second):
  "⚡ 0.234s" — if fast
  "😤 0.891s" — if slow
  "🚫 Too Early!" — if tapped during red phase (penalty: +2s to score)
```

**Scoring**: Reaction time in milliseconds. Lower = better. Ranking determined server-side from each player's reported tap time.

**Anti-cheat**: "Too early" taps penalized. Impossible reaction times (<80ms) flagged and penalized.

---

#### Type D: TILT CHALLENGE — "Tilt Racer"
**Mechanic**: Tilt phone left/right to steer. Race to the finish line.  
**Phone sensor**: Gyroscope/accelerometer  
**Players**: Each on their own phone

```
IN-GAME UI (landscape orientation for this game):
┌──────────────────────────────────────────────────────┐
│  ⏱ 00:45                  🦊 Alex  🐸 1st  🐙 3rd   │  ← Compact HUD
│──────────────────────────────────────────────────────│
│                                                      │
│  ════════════════════════════════════════════════    │
│  ║ ・     ・                  ◉ ← YOUR BALL  ・     │  ← Track view
│  ║     ████    ・      ████                  ・     │    Obstacles
│  ╚════════════════════════════════════════════════   │
│                                                      │
│  TILT ←  to go left    TILT → to go right           │  ← Reminder
│  (shown for first 3 seconds only, then disappears)  │    12sp textMuted
│                                                      │
│                    [ FINISH LINE ▶▶ ]                │  ← Progress
└──────────────────────────────────────────────────────┘

Phone orientation: This game FORCES landscape.
Instruction screen note: "Rotate your phone to landscape mode"
Show rotation animation on instruction screen.
```

---

#### Type E: TIMING CHALLENGE — "Perfect Stop"
**Mechanic**: A bar oscillates back and forth. Tap when it's in the sweet spot.  
**Phone sensor**: Touch only  
**Players**: All do it simultaneously; best score wins

```
IN-GAME UI:
┌─────────────────────────────────────┐
│  ⏱ 00:20        Round: 3/5         │  ← HUD (5 rounds)
│─────────────────────────────────────│
│                                     │
│   TAP AT THE SWEET SPOT!            │  ← 24sp, bold
│                                     │
│  ┌───────────────────────────────┐  │
│  │  [RED] [RED] [GREEN] [RED] [RED]│  ← Oscillating bar
│  │            ▲                   │  │    Colored zones
│  │            │                   │  │    ← cursor slides L↔R
│  │         CURSOR                 │  │    Speed increases each round
│  └───────────────────────────────┘  │
│                                     │
│      ★★★★☆  (4/5 so far)           │  ← Stars for this player's accuracy
│                                     │
│  [ENTIRE SCREEN IS TAP TARGET]      │  ← Tap anywhere
└─────────────────────────────────────┘

HIT FEEDBACK (1 second):
  ✅ PERFECT! (+100) — yellow flash, coin sound
  👍 GOOD! (+75)   — green flash
  😬 OKAY (+50)   — white flash  
  ❌ MISSED! (+0)  — red flash, buzz

MISS is failing to tap during the green zone. No penalty, just 0 points.
```

---

#### Type F: COLLECTION CHALLENGE — "Tap Tap Tap"
**Mechanic**: Tap bubbles/targets as they appear. Score = hits in 30s.  
**Phone sensor**: Touch  
**Complexity**: Low — no coordination required. Friendly for new players.

```
IN-GAME UI:
┌─────────────────────────────────────┐
│  Score: 27        ⏱ 00:18          │  ← HUD
│─────────────────────────────────────│
│                                     │
│       ╭──╮                          │  ← Bubbles/targets
│       │ ● │  BOOM                   │    Random size: 48–96dp
│       ╰──╯                          │    Random position
│                ╭────╮               │    Fade in (200ms)
│                │ ●● │               │    Auto-despawn after 2s
│                ╰────╯               │    On tap: burst animation
│  ╭──╮                               │    + score +1 flies up
│  │ ● │                              │
│  ╰──╯                    ╭──╮       │
│                           │ ●│      │
│                           ╰──╯      │
│                                     │
└─────────────────────────────────────┘

TARGET VARIANTS (increases difficulty as game progresses):
  Green circle  (+1 pt)  — normal target
  Gold star     (+3 pts) — rare, smaller, disappears faster
  Red X         (-1 pt)  — tap to avoid! Bomb type
  Ghost         (+5 pts) — semi-transparent, very fast
```

---

#### Type G: ENDURANCE CHALLENGE — "Hold On!"
**Mechanic**: Hold your finger down on the screen. Let go = eliminated.  
**Phone sensor**: Touch  
**Duration**: Until one winner remains (no timer; could be 10s or 2min)

```
IN-GAME UI:
┌─────────────────────────────────────┐
│  🦊✋  🐸✋  🐙✋  🤖✋        4    │  ← HUD: who is holding
│─────────────────────────────────────│    Number still in
│                                     │
│   ████████████████████████████████  │  ← Your hold progress
│   HOLDING: 00:23                    │    Time held counter
│                                     │
│         ╔════════════╗              │  ← Your touch zone
│         ║            ║              │    140×140dp centered button
│         ║  HOLD HERE ║              │    Color pulsing
│         ║     ✋      ║              │    If finger lifts: immediate RED
│         ╚════════════╝              │    feedback
│                                     │
│  🦊Alex:    00:23  ✋ HOLDING        │  ← Leaderboard
│  🐸Sam:     00:23  ✋ HOLDING        │    Updates in real-time
│  🐙Jordan:  00:18  💨 OUT (18s)     │    Eliminated row greys out
│  🤖Mike:    00:23  ✋ HOLDING        │
│                                     │
└─────────────────────────────────────┘

ELIMINATION MOMENT:
  Finger lifts → RED full-screen flash (50ms)
  "YOU LASTED 00:23!" big text
  Devices switch to spectator view
  Can see remaining players' hold durations
  
WINNER MOMENT:
  Last player remaining: gold pulsing background
  "👑 LAST ONE STANDING!"
```

---

#### Type H: BALANCE CHALLENGE — "Don't Tip It"
**Mechanic**: Hold phone flat. A virtual glass of water shows on screen. Don't spill!  
**Phone sensor**: Gyroscope  
**Complexity**: Physical + visual

```
IN-GAME UI:
┌─────────────────────────────────────┐
│  ⏱ 00:45       Keep it full!       │  ← HUD
│─────────────────────────────────────│
│                                     │
│              💧💧                   │
│         ╔══════════╗                │  ← Glass of water widget
│         ║  ~~~~~~~ ║                │    Water level: starts full
│         ║ ~~~~~~~~ ║                │    Sloshes based on tilt
│         ║~~~~~~~~~~ ║               │    Water SPILLS if tilt too much
│         ╚══════════╝                │
│                                     │
│         83% full                    │  ← Percentage remaining
│       ████████░░░                   │    Progress bar
│                                     │
│   🦊 95%  🐸 71%  🐙 88%  🤖 62%   │  ← Others
│                                     │    WiFi updates every 1s
└─────────────────────────────────────┘

Physics: Water position calculated from phone rotation (Euler angles → 2D sloshing vector)
Spill rate: Proportional to tilt angle. Slight tilt = slow drip. Big tilt = rapid pour.
Winner: Most water remaining when time expires.
```

---

### 1.4 Win/Lose Moment Design

**The most important 2 seconds of any game.**

#### Win Moment Hierarchy

| Place | Screen bg | Text | Animation | Haptic |
|---|---|---|---|---|
| 1st 🥇 | Gold burst particles from center | "⭐ 1st Place!" 96sp partyYellow | Confetti rain (50 particles, 2s) | 3× medium pulse |
| 2nd 🥈 | Silver shimmer | "🥈 2nd Place!" 80sp white | Silver sparkle | 2× light pulse |
| 3rd 🥉 | Bronze tone | "🥉 3rd Place!" 72sp | Bronze sparkle | 1× light pulse |
| 4th+ | stageDark | "4th Place" 64sp textSecondary | None | 1× brief vibrate |
| Last | partyRed fade | "😅 Last!" 64sp | None | Long vibrate 400ms |

#### Confetti Implementation (Flutter)
```dart
// Confetti widget spec:
// Package: confetti ^0.8.0
// Direction: downward
// numberOfParticles: 50
// gravity: 0.3
// particleSize: 8.0
// colors: [partyYellow, partyPink, partyBlue, partyGreen, partyOrange]
// duration: 2 seconds
// Canvas: full screen overlay, AbsorbPointer: true
```

#### Lose Moment — Keep It Light
Critical UX principle: **Never shame players**. The loss state must be:
- Warm (textSecondary, not partyRed which feels harsh)
- Funny (emoji like 😅 😬 🙃, never 😢 or ❌)
- Brief (auto-advance, don't linger on failure)
- Immediately followed by their score (gives players something to improve)

---

### 1.5 Real-Time Feedback During Gameplay

**Feedback must be immediate** (within one frame, ~16ms).

| Player Action | Visual Feedback | Haptic | Sound |
|---|---|---|---|
| Shake detected | Screen flashes white briefly, count increments | none (avoid interrupting shake rhythm) | Count blip |
| Tap on target | Target bursts with particle effect | `lightImpact` | Pop sound |
| Miss / wrong tap | Brief red flash on tapped area | `mediumImpact` | Buzz |
| Achieve milestone | "+50 pts" text flies up, gold flash | 2× light pulse | Coin sound |
| Timer 5→0 | Timer pulses red each second | `lightImpact` per second | Tick sound |
| Eliminated | Full-screen red flash (100ms) | `heavyImpact` | Elimination sting |

**Rule**: All local feedback is instant (no round-trip to server needed). Server sync happens asynchronously in background.

---

## Part 2: Multiplayer UX Considerations

### 2.1 What Each Player Sees (Viewport Architecture)

The key multiplayer design insight: **every player has a private viewport into the same game.**

```
Player A (Host) sees:              Player B (Guest) sees:
┌──────────────────┐              ┌──────────────────┐
│ HUD: MY score    │              │ HUD: MY score    │
│ THEIR scores     │              │ THEIR scores     │
│                  │              │                  │
│ [MY game area]   │              │ [MY game area]   │
│ - My sensor data │              │ - My sensor data │
│ - My tap targets │              │ - My tap targets │
│                  │              │                  │
└──────────────────┘              └──────────────────┘
     ↕ WiFi sync (shared state)
     Score updates, game events,
     countdown, game end signals
```

**What IS shared** (synced via LAN):
- Room state (who's connected, ready status)
- Game start/stop/pause events
- Each player's score (every 500ms)
- Elimination events
- Countdown timing

**What is NOT shared** (stays local):
- Raw sensor data (too much bandwidth)
- Individual touch events (processed locally)
- Frame-by-frame position data
- Sound/haptic triggers

### 2.2 Synchronization Moments

Critical moments that MUST be synchronized across all devices:

#### Countdown Sync Architecture
```
Host device:
  t=0: Generate countdown start timestamp
  t=0: Broadcast "COUNTDOWN_START: {timestamp: T}" to all peers
  
All devices (including host):
  Receive COUNTDOWN_START message
  Calculate: displayTime = T + 3000ms - currentTime
  Each device runs its own countdown timer from this reference
  
Result: All devices show same countdown within ±50ms
(WiFi LAN latency is typically 1–5ms, well within tolerance)
```

#### Why Not Server-Driven Countdown?
LAN peer-to-peer is more reliable for consumer WiFi. A single broadcast + local timers eliminates the "countdown jitter" seen in client-server models on congested home networks.

#### Game End Sync
```
When game timer = 0 (on host):
  1. Host broadcasts "GAME_OVER: {timestamp: T}"
  2. All phones freeze their sensor readings at T
  3. Each phone broadcasts final score to host
  4. Host waits max 2 seconds for all scores
  5. After 2s: compile results, broadcast "RESULTS: {scores: [...]}"
  6. All phones transition to Results screen simultaneously
```

---

### 2.3 Handling Player Drop-Outs

#### Drop-Out Detection
```
Heartbeat: Each device sends ping to host every 2 seconds
Host: If no ping received for 4 seconds → mark player "suspicious"
      If no ping received for 6 seconds → mark player "disconnected"
```

#### UX Response by Drop-Out Timing

**Before game starts (in lobby)**:
```
Player leaves:
  → Avatar shrinks + fades out (300ms animation)
  → Toast: "[Name] left the party 👋"
  → Player slot opens (others can still join)
  → If <2 players remaining: START button disables, message updates
```

**During instruction/countdown screen**:
```
Player disconnects:
  → Their avatar shows 📵 in the player row
  → Toast to host: "[Name] disconnected"
  → Countdown continues (don't penalize ready players)
  → Game starts without them
```

**During gameplay**:
```
  < 1s gap: Silent reconnect attempt, UI unchanged
  1–3s gap: Host sees subtle warning badge on player's HUD score
  > 3s confirmed: Player's score column shows 📵
                   Game CONTINUES (fairness to other players)
                   Disconnected player gets 0 points for the round
                   No pause or interruption to active players
```

**Host disconnects during game**:
```
All guests:
  → Game PAUSES immediately
  → Full-screen overlay: "Host lost connection ⚠️"
                          "Waiting 10 seconds for reconnect..."
  → Progress bar counts down 10 seconds
  → If host reconnects: game resumes from approximate last state
  → If no reconnect: "Promote a new host?" dialog
                      First guest to tap becomes new host
                      New room code generated, current scores preserved
```

---

### 2.4 Late Join Handling

Host can toggle "Allow late joins" in pre-game settings (default: OFF).

**Late Join ON**:
```
Player scans QR mid-game:
  → Sees: "Game in progress! You'll join next round."
  → Shows spectator view of current scores
  → When next game starts, they're automatically added to lobby
  → Assigned the next available avatar slot
```

**Late Join OFF** (default):
```
Player tries to join mid-game:
  → App shows: "This party is in the middle of a game!"
                "Ask the host to let you in between rounds."
                [OK] → returns to HOME
```

---

### 2.5 Network Architecture Considerations for UX

**Peer-to-Peer vs Host-as-Server**: The app uses **host device as game server** (simpler LAN implementation). UX implications:

| Scenario | UX Impact | Mitigation |
|---|---|---|
| Host on slow WiFi | Score updates laggy for guests | Reduce sync frequency (1s instead of 500ms) |
| Crowded WiFi channel | Packet loss → stale scores | Show "⚡ live" vs "🔄 syncing" badge on scores |
| Host phone CPU throttled | Game events delayed | Offload heavy physics to guests, only sync scores |
| Guest drops briefly | Misses in-game events | Buffer events for 5s, replay on reconnect |

---

### 2.6 The "My Phone vs Their Game" Mental Model

Players must always feel **in control of their own device**. Clear design patterns:

**"This is yours" signals**:
- Your avatar appears **larger** than others (64dp vs 40dp)
- Your score **highlighted** (white bold vs textSecondary)
- Your game area occupies the **full screen** (not split)
- "YOU" or "YOUR TURN" label explicitly present when unclear

**"Others are there too" signals**:
- Opponents' mini scores/avatars in HUD
- Event notifications: "[Alex] scored!" toast (2s auto-dismiss)
- "4 players active" status in corner

**Never**:
- Show opponents' game area on your screen (crowding, confusion)
- Surprise the player with action they didn't initiate
- Put another player's data in a tap-zone

---

## Part 3: Accessibility & Inclusivity

### 3.1 Age-Inclusive Design

Party games span ages 8–80. Design for the least tech-savvy player in the room.

| Age Group | Consideration | Design Response |
|---|---|---|
| Children (8–12) | Can't read fast, smaller fingers | Large targets, icon-heavy instructions, no small text in-game |
| Teens/Adults | Main audience | Full feature set as designed |
| Older adults (50+) | May have tremor, reduced reaction speed | Threshold tolerances tuned, no reaction-time games are required |
| Mixed group | Some experienced, some not | Instructions non-skippable first time, tutorial mode |

### 3.2 Motor Accessibility

**Tremor/Shaky Hands**:
- Steady Hand game: Adjust elimination threshold in Settings ("Easy Mode")
- All tap targets ≥ 48dp
- Double-tap or long-press alternatives for important actions

**One-Handed Play**:
- Game area reachable with thumb (no critical targets in top corners during gameplay)
- Bottom 60% of screen preferred for game interactions
- Consider: phone in portrait, game controls in lower third

**Grip Variety**:
- Shake games work with any grip style
- Tilt games calibrate on game start ("Hold your phone normally, then press CALIBRATE")

```
// Calibration pattern for tilt games:
// Show dialog: "Hold your phone how you'll play"
//              [CALIBRATE] button
// On tap: record current gyro reading as "zero position"
// All subsequent tilt readings are relative to this baseline
```

### 3.3 Visual Accessibility

**Color Contrast Compliance** (WCAG AA):

| Text Element | Foreground | Background | Ratio | Status |
|---|---|---|---|---|
| Primary body text | #FFFFFF | #0D0D1A | 18.1:1 | ✅ AAA |
| Secondary text | #B8B8D4 | #0D0D1A | 7.2:1 | ✅ AA |
| Yellow on dark | #FFD600 | #0D0D1A | 14.3:1 | ✅ AAA |
| Dark on yellow buttons | #0D0D1A | #FFD600 | 14.3:1 | ✅ AAA |
| Muted text | #5A5A7A | #0D0D1A | 3.1:1 | ⚠️ Only for decorative |

**Color Blindness**: 
- Never use color as SOLE indicator. Always pair with:
  - Shape (✓ vs ✗ icons)
  - Text label ("READY" not just green dot)
  - Pattern (striped vs solid for eliminated vs active)
- Tested against: Deuteranopia (red/green), Protanopia, Tritanopia

**High Ambient Light** (outdoor parties):
- Dark theme helps (less washout than white backgrounds)
- All critical text ≥ 16sp, bold or semi-bold
- Game feedback animations use high-contrast flash (white on dark, not color-on-dark)

**Text Scaling**:
```dart
// Lobby screens: fully scalable
// In-game HUD: max 1.2x scale factor
// Countdown numbers: fixed size (game mechanic depends on visual impact)
// Instruction text: max 1.3x (still needs to fit)

// Implementation:
MediaQuery.withClampedTextScaling(
  minScaleFactor: 1.0,
  maxScaleFactor: isGameScreen ? 1.2 : 2.0,
  child: gameOrLobbyWidget,
)
```

### 3.4 Screen Reader (TalkBack) Support

All custom widgets must have semantic labels:

```dart
// Player avatar in lobby
Semantics(
  label: '${player.name}. ${player.isReady ? "Ready" : "Not ready"}. '
         '${player.isHost ? "Host. " : ""}Player ${player.slot}.',
  child: PlayerAvatarWidget(player: player),
)

// Room code
Semantics(
  label: 'Room code: ${code.split('').join(' ')}. '
         'Share this with your friends.',
  child: RoomCodeWidget(code: code),
)

// Timer
Semantics(
  liveRegion: true,  // TalkBack announces changes
  label: 'Time remaining: $timeString',
  child: TimerWidget(seconds: secondsLeft),
)

// Game tiles
Semantics(
  label: '$gameName. $gameDescription. '
         '${minPlayers} to ${maxPlayers} players. '
         '$gameDuration seconds.',
  button: true,
  child: GameTileWidget(game: game),
)
```

**Important**: Game instructions must be read aloud by TalkBack before the countdown starts. Add a 1-second delay after instruction screen if TalkBack is active.

### 3.5 Motion Sensitivity

Some players experience motion sickness from rapid animations.

**"Reduce Animations" mode** (in Settings):
| Animation | Default | Reduced |
|---|---|---|
| Screen transitions | Slide + scale | Crossfade only |
| Countdown numbers | Scale in/out | Fade in/out |
| Background blobs | Moving gradient | Static color |
| Avatar float | Sine wave float | Static |
| Confetti | Falling particles | Static emoji |
| Win/lose moment | Scale + flash | Color change only |

Detect system setting:
```dart
// Respect system accessibility preference:
final reduceMotion = MediaQuery.disableAnimationsOf(context);
```

### 3.6 Language & Literacy

**Target**: Playable without reading in some games.

**All instruction screens**:
- Visual animation MUST convey the rule without text
- Text is supplementary, not primary

**Avoid jargon**: "Tilt" not "Adjust gyroscopic orientation"

**Numeric-only information where possible**:
- Scores = numbers (universal)
- Timer = numbers (universal)
- Rankings = 1st/2nd with trophy icons (iconic)

**Emoji as universal language**: Use emoji liberally as universal visual shorthand. 🏆=win, ⏱=timer, 👑=host, ✅=ready. These transcend language barriers.

---

## Part 4: Sample Mini-Game Specification Sheet

*Use this template for each mini-game in the catalog*

```
═══════════════════════════════════════════════════════════
GAME SPEC: Shake It!
═══════════════════════════════════════════════════════════
ID:              shake_it
Duration:        30 seconds
Players:         2–8 (all simultaneous)
Sensor:          Accelerometer
Orientation:     Portrait (locked)
Instruction:     "Shake your phone as fast as possible!"
Visual Demo:     Phone icon oscillating rapidly (Lottie)

SCORING:
  +1 point per valid shake (magnitude > 2.0 g)
  No negative scores
  Tiebreaker: who reached tie score first

NETWORK SYNC:
  Send: score (integer) every 500ms
  Receive: all opponents' scores every 500ms
  Game end signal: from host at t=30s

IN-GAME UI:
  Full-screen shake zone (entire screen active)
  Your score: Fredoka One 72sp center
  Shake meter: animated progress bar responds to device motion
  Opponent mini-bars: bottom of screen, 32dp tall
  Timer: top center, turns orange at 10s

WIN CONDITION: Highest shake count at 30s
LOSE CONDITION: Any score ≤ last place

ACCESSIBILITY:
  Calibration: none needed
  One-handed: yes (any grip works)
  Difficulty scaling: none (no easy mode for shake speed)
  TalkBack: announces "Game started. Shake your phone."
             announces final score on game end.
═══════════════════════════════════════════════════════════
```

---

## Part 5: UX Quality Checklist

Before shipping any feature, verify:

### Onboarding & First Use
- [ ] New user can join a game in ≤10 seconds
- [ ] No text-only instructions during gameplay
- [ ] Gesture animations present for all sensor-based games
- [ ] Nickname + avatar setup ≤30 seconds

### Lobby Experience
- [ ] Player joins reflected within 1 second
- [ ] QR code scannable from 30cm distance
- [ ] Room code legible in dim lighting
- [ ] Host clearly distinguished (crown icon)
- [ ] Ready/not-ready state clearly visible

### Game Experience
- [ ] All touch targets ≥ 48dp
- [ ] Timer visible at all times during gameplay
- [ ] Score feedback immediate (≤1 frame / 16ms)
- [ ] Win/lose moment unmistakably clear
- [ ] Results auto-advance (no one gets stuck)

### Multiplayer Sync
- [ ] Countdown synchronized within ±100ms across devices
- [ ] Disconnection handled gracefully (no crash, no freeze)
- [ ] Game continues if non-host player disconnects
- [ ] Host migration implemented

### Accessibility
- [ ] All interactive elements have Semantics labels
- [ ] Contrast ratios meet WCAG AA minimum
- [ ] Reduce motion setting respected
- [ ] Text scaling applied correctly
- [ ] Color-blind test passed (no color-only indicators)

### Performance
- [ ] Lobby screen: 60fps idle, no jank on player join
- [ ] In-game: 60fps maintained during sensor reading + UI update
- [ ] Network payload per sync: < 1KB per player
- [ ] App launch to home screen: < 2 seconds

---

*Document set complete. For implementation guidance, see `GETTING_STARTED.md` and `ARCHITECTURE_OLLAMA_TOOLKIT.md`.*  
*Design System: `UX_DESIGN_SYSTEM.md` | Flows: `USER_FLOW_COMPLETE.md` | Screens: `WIREFRAME_SCREENS.md`*

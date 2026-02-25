# 🗺️ Party Pocket — Complete User Flows
**Document Type**: User Flow Diagrams  
**Version**: 1.0  
**Companion**: `UX_DESIGN_SYSTEM.md`, `WIREFRAME_SCREENS.md`

---

## Overview: The 10-Second Promise

A player who has never opened the app before should be **in a game within 10 seconds** of someone showing them the room code. Every flow is designed around this constraint.

**Key Flow Principles:**
1. No account creation required
2. No tutorial screens (teach by doing)
3. Maximum 3 taps to be in a game as a guest
4. Maximum 5 taps to start a game as host
5. All decision points are binary (host or join — that's it on the home screen)

---

## Flow 1: First Launch (New User)

```
App Opens
    │
    ▼
[Splash Screen — 1.5s]
  App logo animates in  
  "Party Pocket" text bounces
    │
    ▼
[Home Screen]
  No onboarding. No permissions gating.
  Two giant buttons: HOST  |  JOIN
    │
    ├──► User taps HOST  →  Flow 2: Host Flow
    │
    └──► User taps JOIN  →  Flow 3: Join Flow
```

**Design Decision**: Permissions (WiFi, microphone if used, vibration) are requested contextually — only when the specific feature is first needed — never upfront. This reduces friction and abandonment.

---

## Flow 2: Host Flow (Full Detail)

```
HOME SCREEN
User taps "HOST A GAME"
    │  [scale bounce animation 100ms]
    ▼
NICKNAME SCREEN  (if first time — otherwise skipped)
  "What's your name?"  
  Text field, 12 char max  
  Big confirm button  
  ────────────────────
  [Tap CONFIRM or press Enter]
    │
    ▼
HOST LOBBY
  Room code generated (4-letter: e.g. "PZRK")  
  QR code displayed prominently  
  Player list: Host avatar (crown) + empty slots (2–7 more)  
  ────────────────────
  [Players join via their phones → avatars animate in]
    │
    │  [Each join: avatar flies in + join sound]
    │  [Host sees: "Waiting for 1 more..." if <2 players]
    │  [Enable START when ≥2 players]
    │
    ├──► Host taps "PICK A GAME" when ≥2 players
    │       │
    │       ▼
    │    GAME SELECTION SCREEN
    │      Scrollable grid of mini-game tiles  
    │      Each tile: emoji icon + name + short descriptor  
    │      Optional: "RANDOM GAME" button (shuffle animation)  
    │      ────────────────────
    │      [Host selects a game]
    │           │
    │           ▼
    │        HOST CONFIRMS GAME
    │          "Starting: [GAME NAME] in 3..." 
    │          Broadcast to all players  
    │          All phones sync to same countdown  
    │               │
    │               ▼
    │            PRE-GAME INSTRUCTIONS  (all players)
    │              → Flow 5: Pre-Game Flow
    │
    └──► Host taps "SETTINGS" (optional)
            Volume, max players, allow late-join toggle
```

### Host Lobby States

| State | Visual | CTA Button |
|---|---|---|
| 1 player (just host) | "Share the code! 👇" message visible, big QR | "WAITING... (Need 1 more)" — disabled, grey |
| 2 players | QR visible, 2 avatars animate | "PICK A GAME 🎮" — enabled, yellow |
| 3–8 players | QR shrinks, player list expands | "PICK A GAME 🎮" — enabled, yellow |
| Max players (8) | QR disappears, "Room full!" badge | "PICK A GAME 🎮" — enabled, yellow |

---

## Flow 3: Join Flow (Full Detail)

```
HOME SCREEN
User taps "JOIN A GAME"
    │
    ▼
NICKNAME SCREEN  (if first time — otherwise skipped)
  "What's your name?"
    │
    ▼
JOIN SCREEN
  Two options visible simultaneously:
  ┌────────────────────────────────────┐
  │  📷  SCAN QR CODE                  │
  │  [Large camera viewfinder area]    │
  ├────────────────────────────────────┤
  │   — or type the room code —        │
  │  [ P ][ Z ][ R ][ K ]             │
  │  4 large individual letter boxes   │
  └────────────────────────────────────┘
  
  ────────────────────
  Option A: User points camera at host's QR code
    → Auto-detects → vibration feedback → proceeds
  
  Option B: User taps letter boxes, types 4-letter code
    → Auto-submits when 4th letter entered (no confirm button needed)
    │
    ▼
CONNECTING...
  "Finding PZRK..." with spinner  (≤2 seconds on LAN)
    │
    ├── Success →
    │       ▼
    │    GUEST LOBBY
    │      Shows room name, host avatar (crown badge)  
    │      Their own avatar appears in player list  
    │      Other player avatars already in the room  
    │      BIG "READY ✓" button at bottom  
    │      ────────────────────
    │      [Tap READY]
    │           │
    │           ├── Not all ready: "Waiting for X more players..."
    │           │     Ready avatar gets green glow + checkmark
    │           │
    │           └── All ready: → Pre-Game Instructions (Flow 5)
    │
    └── Failure →
            ▼
         ERROR STATE
           "Couldn't find that room 🤔"
           "Check the code and try again"
           [TRY AGAIN] button → back to JOIN SCREEN
           [GO BACK] → HOME SCREEN
```

### Join Code Design: Why 4-Letter Room Codes?

- **4 uppercase letters** = 456,976 combinations (enough for LAN parties)
- Excludes ambiguous chars: O, 0, I, 1, L (avoids confusion)
- Usable alphabet: A B C D E F G H J K M N P Q R S T U V W X Y Z (22 letters)
- Takes ≤5 keystrokes to enter manually
- More human-friendly than 6-digit numeric codes
- QR code is faster but code entry is the reliable fallback

---

## Flow 4: Between-Games Flow

```
GAME ENDS
    │
    ▼
RESULTS SCREEN (all players)
  Animated podium reveal  
  1st/2nd/3rd places fly in sequentially  
  Confetti/particles for winner  
  Full scoreboard scrollable below podium  
  ────────────────────
  Host sees: [PLAY AGAIN] [PICK NEW GAME] [END SESSION]
  Guests see: [VOTE: 👍 Play Again  |  🔀 New Game]
    │
    ├── Host taps PLAY AGAIN → Same game, new round
    │       → Pre-Game Instructions (Flow 5)
    │
    ├── Host taps PICK NEW GAME → GAME SELECTION SCREEN
    │       (with vote tallies shown as crowd enthusiasm indicators)
    │       → Pre-Game Instructions (Flow 5)
    │
    └── Host taps END SESSION
            │
            ▼
         FINAL SCOREBOARD (Session total)
           All-game trophy presentation  
           "Grand Champion: [Avatar]" hero moment  
           Scrollable per-game breakdown  
           [PLAY AGAIN FROM START] or [EXIT]
```

### Voting System (Guest Side)

Guests tap 👍 or 🔀 on their results screen. The host sees a live bar graph next to each button showing vote distribution. Host has final authority — democracy is consultative, not binding. This prevents the game from getting stuck if no consensus.

---

## Flow 5: Pre-Game Instructions Flow (All Players)

```
HOST PICKS GAME  
All players receive game selection broadcast  
    │
    ▼
INSTRUCTION SCREEN (3 seconds max — often skippable)
  ┌────────────────────────────────────────┐
  │  [Game Icon — 80dp emoji]              │
  │  GAME NAME (Fredoka One, 36sp)         │
  │                                        │
  │  🎮 [Single-sentence "how to play"]    │
  │     ≤12 words. BIG. One rule only.    │
  │                                        │
  │  [Visual demo: phone icon showing      │
  │   the gesture with arrow animation]    │
  │                                        │
  │  Auto-proceeds after 3 seconds         │
  │  OR tap anywhere to proceed faster     │
  └────────────────────────────────────────┘
    │
    ▼
READY CHECK SCREEN (synchronized)
  Huge countdown: 3... 2... 1...
  Each number fills the screen
  All players' avatars shown with "READY" badges
  Haptic on each number
  ────────────────────
  [GO!] text explodes onto screen
    │
    ▼
GAME IN PROGRESS (Flow 6)
```

### Instruction Screen Copy Template

Each mini-game gets ONE instruction following this formula:
> **[VERB] your phone [HOW] to [GOAL]**

Examples:
- *"Tilt your phone to steer the ball into the goal"*
- *"Shake your phone as fast as possible"*
- *"Tap the screen when the light turns green"*
- *"Hold your phone flat and don't tip it over"*

No more than 12 words. If it takes more than 12 words to explain, simplify the game mechanic.

---

## Flow 6: In-Game Flow

```
GAME ACTIVE
    │
    ├── Timer visible at top (always)
    │
    ├── Player performs action
    │       │
    │       ├── Success action → positive feedback (flash, sound, score)
    │       └── Failure/miss → gentle negative feedback (shake, buzz)
    │
    ├── At 10 seconds remaining: timer turns orange
    ├── At 5 seconds: timer pulses + haptic each second
    ├── At 0: "TIME'S UP!" flash → game over state
    │
    └── Game ends (time or condition met)
            │
            ▼
         IMMEDIATE LOCAL RESULT (on each phone)
           2-second full-screen: "⭐ 1st!" or "😅 4th!"
           Font size: 96sp
           Color: winner=partyYellow, loser=partyRed
           Haptic: win=3 pulses, lose=1 long
              │
              ▼
           → RESULTS SCREEN (Flow 4)
```

---

## Flow 7: Error & Edge Case Flows

### Player Drops Out During Game

```
Player disconnects during game
    │
    ├── <1 second gap: silent reconnect attempt (no UI shown)
    │
    ├── 1–3 second gap:
    │     "⚠️ [Name] lost connection" toast shown to host only
    │     Game continues
    │
    └── >3 seconds / confirmed disconnect:
          [Name] avatar grays out + "📵" icon
          Game continues without them
          Their slot shows "--" on scoreboard
          Host gets: [CONTINUE] [PAUSE GAME]
          
          After game ends → Results show "[Name] disconnected"
          Host lobby auto-removes disconnected player
```

### Host Drops Out

```
Host disconnects
    │
    ▼
ALL PLAYER SCREENS show:
  "⚠️ Host disconnected"
  "The party host left. Promote a new host?"
  
  [YES, I'LL HOST] — any player can tap
  
  First player to tap becomes new host
  → Host lobby reconstructed with existing players
  → New QR + code generated
```

### Room Code Collision (edge case)

```
Two games running with same code (rare)
    │
    ▼
App shows both rooms with host name:
  "PZRK — [Host Avatar] Alex's Party (3 players)"
  "PZRK — [Host Avatar] Sam's Party (2 players)"
  
Player selects the correct room → joins
```

### No WiFi / Network Not Found

```
User taps HOST or JOIN
    │
    WiFi permission or connection checked
    │
    └── No WiFi active:
          ┌──────────────────────────────┐
          │ 📶  No WiFi Connection       │
          │                              │
          │ Everyone needs to be on the  │
          │ same WiFi network to play.   │
          │                              │
          │ [OPEN WIFI SETTINGS]         │
          │ [TRY ANYWAY]                 │
          └──────────────────────────────┘
```

---

## Flow 8: Settings & Customization Flow

```
HOME SCREEN → Gear icon (top right corner, 40dp)
    │
    ▼
SETTINGS SHEET (bottom sheet, not full screen)
  ─────────────────────
  Sound Volume       [████░░] slider
  Vibration          [Toggle ON/OFF]
  Reduce Animations  [Toggle ON/OFF]  ← accessibility
  My Nickname        [Alex          ] text field
  My Avatar          [🦊][🐸][🐙]... select row
  ─────────────────────
  App version, credits
  [DONE]
```

**Design Decision**: Settings as bottom sheet (not separate screen) — accessible anywhere, no navigation overhead.

---

## Timing Summary: The 10-Second Promise

| Scenario | Steps | Est. Time |
|---|---|---|
| Guest joins existing room via QR | Open app → Tap JOIN → Scan QR | **~8 seconds** |
| Guest joins via room code | Open app → Tap JOIN → Type 4 letters | **~12 seconds** |
| Host starts first game | Open app → Tap HOST → Wait for 1 join → Pick game → Start | **~30–60s** (waiting-dependent) |
| Returning player (nickname saved) | Open app → Tap JOIN → Scan QR | **~5 seconds** |
| Between games, play again | Results screen → Host taps PLAY AGAIN | **~5 seconds** |

---

## State Machine Summary

```
App States:
  HOME ──host──► HOST_LOBBY ──start──► GAME_SELECTION ──pick──► PRE_GAME ──go──► IN_GAME ──end──► RESULTS
    │                                                                                                  │
    └──join──► JOIN_SCREEN ──connect──► GUEST_LOBBY ──all_ready──► PRE_GAME ──────────────────────────┘
                                                                      │
                                                              ◄── BETWEEN_GAMES ◄──
```

---

*Next: See `WIREFRAME_SCREENS.md` for screen-by-screen visual specifications.*

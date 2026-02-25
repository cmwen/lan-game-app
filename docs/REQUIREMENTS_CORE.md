---
title: Core Feature Requirements
type: requirements
version: 1.0.0
created: 2025-01-01
status: approved
stakeholders: [product-owner, architect, developer]
related_docs:
  - PRODUCT_VISION.md
  - USER_STORIES_MVP.md
  - ROADMAP_MVP.md
---

# 📋 Core Feature Requirements

## Table of Contents
1. [App Shell & Navigation](#1-app-shell--navigation)
2. [Host & Join Flow](#2-host--join-flow)
3. [P2P Local Network Multiplayer](#3-p2p-local-network-multiplayer)
4. [Mini-Game Catalog](#4-mini-game-catalog)
5. [Player Experience & Scoring](#5-player-experience--scoring)
6. [Non-Functional Requirements](#6-non-functional-requirements)

---

## 1. App Shell & Navigation

### 1.1 Home Screen
**Purpose**: Entry point that immediately communicates what the app is and offers two primary paths.

**Functional Requirements**:
- FR-1.1.1: Display app name ("Party Pocket") and tagline prominently
- FR-1.1.2: Present two clear CTAs: **"Host a Game"** and **"Join a Game"**
- FR-1.1.3: Display animated or energetic visual treatment to set party tone
- FR-1.1.4: Show current app version in footer
- FR-1.1.5: Require no login, account, or internet connectivity check

**Acceptance Criteria**:
- [ ] App opens to home screen in < 2 seconds on mid-range Android device
- [ ] Both Host and Join buttons are reachable within one tap from app open
- [ ] Screen works without any network connectivity

---

### 1.2 Lobby Screen (Host View)
**Purpose**: Host configures and manages the game session before it begins.

**Functional Requirements**:
- FR-1.2.1: Display generated room code (4-character alphanumeric, e.g. `ZFGK`)
- FR-1.2.2: Display QR code that encodes the room's local IP + port for fast joining
- FR-1.2.3: List all connected players with their chosen display names in real time
- FR-1.2.4: Allow host to kick a player from the lobby
- FR-1.2.5: Show minimum player count requirement (2 players to start)
- FR-1.2.6: Allow host to select or shuffle mini-game order before starting
- FR-1.2.7: Display "Start Game" button, enabled only when ≥ 2 players are connected
- FR-1.2.8: Allow host to set number of rounds (1–5, default: 3)

**Acceptance Criteria**:
- [ ] Room code is visible and large enough to read from 1 meter away
- [ ] Player list updates within 1 second of a new player joining
- [ ] "Start Game" button is disabled/greyed when fewer than 2 players connected
- [ ] Host can start the game with 2–8 players connected

---

### 1.3 Join Screen (Player View)
**Purpose**: Non-host players enter the session quickly.

**Functional Requirements**:
- FR-1.3.1: Provide manual room code entry (4-character input)
- FR-1.3.2: Provide QR code scanner to auto-fill room connection details
- FR-1.3.3: Allow player to enter a display name (2–16 characters)
- FR-1.3.4: Persist last-used display name via local storage
- FR-1.3.5: Show connection status feedback (connecting → connected → waiting for host)
- FR-1.3.6: Show waiting room once connected, listing all other players
- FR-1.3.7: Handle "room not found" and "room full" error states gracefully

**Acceptance Criteria**:
- [ ] Player can join a room in under 30 seconds from app open
- [ ] Display name persists across app sessions
- [ ] Error states show human-readable messages (not raw exceptions)
- [ ] QR scan flow takes ≤ 3 taps from home screen to connected

---

### 1.4 Game Selection Screen (Host View)
**Purpose**: Host chooses which mini-games to play and in what order.

**Functional Requirements**:
- FR-1.4.1: Display all available mini-games as cards with title, icon, and one-line description
- FR-1.4.2: Show player count range supported per game (e.g. "2–8 players")
- FR-1.4.3: Allow host to select/deselect games for the session playlist
- FR-1.4.4: Provide "Random Selection" option to auto-pick 3–5 games
- FR-1.4.5: Allow drag-to-reorder games in the playlist
- FR-1.4.6: Show estimated total session time based on selected games

**Acceptance Criteria**:
- [ ] All available games are visible without scrolling (or with minimal scroll)
- [ ] Host can configure a game set in under 60 seconds
- [ ] Random selection produces a valid, non-duplicate game list

---

## 2. Host & Join Flow

### 2.1 Connection Architecture
- FR-2.1.1: Host device acts as TCP/UDP server on a dynamically assigned local port
- FR-2.1.2: Room code maps to host device's local IP + port (encoded in QR + discoverable by code broadcast)
- FR-2.1.3: All game state flows through host; clients send inputs, host resolves game logic
- FR-2.1.4: mDNS/NSD (Network Service Discovery) used for room code → IP resolution on LAN
- FR-2.1.5: Fallback: manual IP:port entry if mDNS discovery fails

### 2.2 Session Lifecycle
- FR-2.2.1: Session states: `LOBBY` → `GAME_STARTING` → `IN_GAME` → `RESULTS` → `NEXT_GAME` → `FINAL_RESULTS`
- FR-2.2.2: Host can pause between games to allow bathroom breaks, readiness checks
- FR-2.2.3: If host disconnects mid-game, all clients see a "Host disconnected" screen with option to exit
- FR-2.2.4: If a non-host player disconnects, remaining players continue; disconnected player's score is frozen
- FR-2.2.5: Host can end session early from any screen via a persistent menu option

---

## 3. P2P Local Network Multiplayer

### 3.1 Transport Layer
- FR-3.1.1: Use TCP sockets for reliable state synchronization (game start, scores, results)
- FR-3.1.2: Use UDP for low-latency real-time input events (accelerometer deltas, rapid taps)
- FR-3.1.3: Maximum supported latency for playable experience: 50ms on local Wi-Fi
- FR-3.1.4: Message format: JSON-encoded payloads with message type, sender ID, timestamp, and payload

### 3.2 Message Protocol
All messages conform to:
```json
{
  "type": "MESSAGE_TYPE",
  "senderId": "player-uuid",
  "timestamp": 1710000000000,
  "payload": {}
}
```

**Core Message Types**:
| Type | Direction | Description |
|------|-----------|-------------|
| `JOIN_REQUEST` | Client → Host | Player requests to join with display name |
| `JOIN_ACK` | Host → Client | Confirms join, sends player ID and current lobby state |
| `PLAYER_JOINED` | Host → All | Broadcast when new player joins |
| `PLAYER_LEFT` | Host → All | Broadcast when player disconnects |
| `GAME_START` | Host → All | Game beginning, includes game type and config |
| `ROUND_START` | Host → All | New round beginning with countdown |
| `PLAYER_INPUT` | Client → Host | Player's in-game action/input event |
| `GAME_STATE` | Host → All | Periodic game state sync |
| `ROUND_END` | Host → All | Round results with scores |
| `GAME_END` | Host → All | Final game scores |
| `NEXT_GAME` | Host → All | Transitioning to next mini-game |
| `SESSION_END` | Host → All | Full session over, final leaderboard |
| `PING` | Both | Latency measurement |
| `ERROR` | Host → Client | Error notification with code and message |

### 3.3 Reliability & Resilience
- FR-3.3.1: Heartbeat ping every 2 seconds; player considered disconnected after 3 missed pings
- FR-3.3.2: Host buffers last 10 state messages for reconnection replay
- FR-3.3.3: Player reconnection window: 30 seconds before slot is freed
- FR-3.3.4: All network errors surface as user-friendly banners, not crashes

---

## 4. Mini-Game Catalog

> Design Philosophy: Each game must be learnable from a **4-word instruction** shown on screen for 3 seconds before the game starts. No tutorials. Pure instinct.

---

### 🎮 MG-01: Tilt Racer
**Tagline**: "Tilt to the finish!"
**Players**: 2–8
**Duration**: 15–20 seconds per round, best of 3
**Hardware**: Accelerometer

**Description**:
Each player has a ball on their screen rolling toward a goal. Tilt your phone left/right to steer. First to roll the ball into the hole wins the round. The ball physics respond to the device's accelerometer — tilting subtly steers, but tilting too much causes the ball to overshoot.

**Gameplay Details**:
- Each player sees their own screen with a top-down maze/track
- Host syncs "race start" simultaneously to all devices
- Players control their own ball locally; no cross-device sync needed for the ball physics
- First player to reach the goal sends `ROUND_WIN` message to host
- Host broadcasts winner and updates scores

**Win Condition**: First to reach the goal in best-of-3 rounds
**Instruction Text**: "Tilt to roll your ball!"

---

### 🎮 MG-02: Tap Frenzy
**Tagline**: "Tap faster than everyone!"
**Players**: 2–8
**Duration**: 10 seconds
**Hardware**: Touchscreen

**Description**:
A giant button appears on every player's screen. Tap it as fast as you can for 10 seconds. The player with the most taps wins. Simple, pure, exhausting. The button visually reacts to each tap with a satisfying bounce animation and click sound.

**Gameplay Details**:
- Each client counts taps locally
- At game end, each client sends final tap count to host
- Host validates (basic cheat detection: max ~20 taps/second is humanly possible)
- Leaderboard shows every player's tap count

**Win Condition**: Most taps in 10 seconds
**Instruction Text**: "Tap as fast as possible!"

---

### 🎮 MG-03: Hold Steady
**Tagline**: "Don't move a muscle!"
**Players**: 2–8
**Duration**: 15–30 seconds
**Hardware**: Accelerometer + Gyroscope

**Description**:
Hold your phone perfectly still. A "stillness meter" on screen shows how much you're moving — the needle drops when you move even slightly. The last player whose meter is still in the green zone wins. Players are gradually eliminated as they twitch, breathe too hard, or get laughed at.

**Gameplay Details**:
- Each device measures accelerometer variance locally
- Host sets a difficulty threshold (easy/medium/hard) that tightens over time
- Devices broadcast elimination events when a player exceeds the threshold
- Last player standing wins

**Win Condition**: Last player still within the stillness threshold
**Instruction Text**: "Hold your phone still!"

---

### 🎮 MG-04: Scream Meter
**Tagline**: "SCREAM LOUDER THAN EVERYONE!"
**Players**: 2–8
**Duration**: 5 seconds of screaming
**Hardware**: Microphone

**Description**:
When the countdown hits GO, every player screams into their phone as loud as they can for 5 seconds. The microphone measures peak and sustained volume. The loudest average screamer wins. Absolutely chaos in a room. Neighbors will complain.

**Gameplay Details**:
- Each device samples microphone volume (dB) locally at 60Hz
- Captures peak and average volume over the 5-second window
- At round end, each client sends their `peakDb` and `avgDb` to host
- Winner is determined by host from submitted values
- Warning screen: "This will be loud. You've been warned." (with cancel option)

**Win Condition**: Highest average decibel reading over 5 seconds
**Instruction Text**: "Scream as loud as you can!"

---

### 🎮 MG-05: Reaction Roulette
**Tagline**: "Tap when you see green!"
**Players**: 2–8
**Duration**: Up to 5 rounds, ~5 seconds each
**Hardware**: Touchscreen + Display

**Description**:
A large circle on screen pulses with colors. When it turns GREEN, tap it immediately. Tap early (false start) and you're disqualified for that round. The fastest valid tap wins each round. Points accumulate across 5 rounds. Adds mind games — sometimes the circle teases near-green before snapping away.

**Gameplay Details**:
- Host controls the exact millisecond the green signal fires (prevents pre-tapping)
- Host broadcasts `SIGNAL_FIRE` event with timestamp
- Each client records tap time relative to signal; sends delta to host
- False starts (tap before signal) result in -1 point
- Host resolves winner per round, broadcasts scores

**Win Condition**: Fastest cumulative reaction time over 5 rounds (with false start penalties)
**Instruction Text**: "Tap when it turns green!"

---

### 🎮 MG-06: Memory Chain
**Tagline**: "Remember the sequence!"
**Players**: 2–8
**Duration**: 60–90 seconds total
**Hardware**: Touchscreen

**Description**:
A sequence of colored buttons lights up on screen (like Simon Says). Players must remember and repeat the sequence by tapping the buttons in order. Each round adds one more step. Players are eliminated when they make a mistake. Last player standing wins.

**Gameplay Details**:
- All players see the same sequence (sent by host)
- Players input the sequence simultaneously
- Eliminated players see a "You're out!" screen but can watch remaining players
- Sequences start at 3 steps; add 1 per round; maximum 12 steps
- Host tracks per-player elimination round for scoring

**Win Condition**: Last player to correctly complete the longest sequence
**Instruction Text**: "Repeat the flashing pattern!"

---

### 🎮 MG-07: Hot Potato
**Tagline**: "Pass it before it explodes!"
**Players**: 3–8 (minimum 3 for meaningful play)
**Duration**: 15–45 seconds (randomized fuse)
**Hardware**: Touchscreen + Haptics + Audio

**Description**:
One player starts with a "hot potato" (a bomb timer visible only to them). They must pass it to another player by tapping their name in a list. The potato keeps moving. When the randomly-set timer expires, the player holding it loses a life. Three lives total — last player standing wins.

**Gameplay Details**:
- Host controls the bomb timer (secretly randomized 8–25 seconds per fuse)
- The player "holding" the potato has it highlighted on their screen; others see who has it
- The holder taps a player's name to pass it; host processes and updates state
- Explosion triggers haptic feedback + animation on the holding device
- Players can try to pass quickly but the pass has a 1-second cooldown to prevent instant chain-passing

**Win Condition**: Last player with remaining lives
**Instruction Text**: "Tap a name to pass the potato!"

---

### 🎮 MG-08: Mirror Draw
**Tagline**: "Draw the same thing!"
**Players**: 2–6
**Duration**: 45 seconds
**Hardware**: Touchscreen + Camera (optional for reveal)

**Description**:
All players receive the same secret word (e.g., "dog", "rocket", "sandwich"). Everyone draws it on their phone screen simultaneously using a simple finger-draw canvas. After time's up, all drawings are revealed on each screen side-by-side. Players vote on the funniest/worst drawing by tapping a thumbs-down. The most-voted drawing loses. The least-voted (best drawing) wins. Laughter is guaranteed.

**Gameplay Details**:
- Host sends the secret word simultaneously (word is hidden until the game starts)
- Canvas: single-color thick stroke, fill-bucket, undo button
- After timer: each client sends their drawing as a compressed PNG (base64, max 50KB)
- Host assembles all drawings and broadcasts the full gallery
- Voting: each player votes once (cannot vote for themselves)
- Results: most votes = most-laughed-at = gets -1 point; fewest votes = +2 points

**Win Condition**: Fewest "worst drawing" votes from other players
**Instruction Text**: "Draw the word on screen!"

---

## 5. Player Experience & Scoring

### 5.1 Pre-Game Countdown
- FR-5.1.1: 3-second countdown displayed in large, animated text after host starts a game
- FR-5.1.2: Short instruction text (≤ 8 words) visible during countdown
- FR-5.1.3: Countdown synchronized across all devices (host broadcasts start event)

### 5.2 In-Game UI Principles
- FR-5.2.1: Font size minimum 24sp for any actionable text
- FR-5.2.2: Timer always visible in top-right corner during timed games
- FR-5.2.3: Score/rank visible during games that support it (e.g., tap count)
- FR-5.2.4: Players never see a blank/loading screen for more than 500ms

### 5.3 Scoring System
- FR-5.3.1: Points awarded per game based on placement:
  | Place | Points |
  |-------|--------|
  | 1st | 3 pts |
  | 2nd | 2 pts |
  | 3rd | 1 pt |
  | 4th+ | 0 pts |
- FR-5.3.2: Some games (e.g., Reaction Roulette, Memory Chain) award points per-round, not just final placement
- FR-5.3.3: Scores accumulate across all mini-games in a session
- FR-5.3.4: Session leaderboard shown between every mini-game

### 5.4 Results Screen
- FR-5.4.1: After each mini-game: show per-game winner with celebratory animation
- FR-5.4.2: Show full player ranking with points earned in this game
- FR-5.4.3: Show running session totals
- FR-5.4.4: "Next Game" button available only to host
- FR-5.4.5: Minimum 5-second results display before host can advance

### 5.5 Final Results (End of Session)
- FR-5.5.1: Podium-style display: 1st, 2nd, 3rd place highlighted
- FR-5.5.2: Animated reveal — 3rd place first, then 2nd, then 1st (with drum roll)
- FR-5.5.3: Overall winner receives confetti animation
- FR-5.5.4: "Play Again" option (returns to lobby with same players)
- FR-5.5.5: "New Game" option (returns to home screen)

---

## 6. Non-Functional Requirements

### 6.1 Performance
- NFR-6.1.1: App cold start < 3 seconds on mid-range Android device (Snapdragon 665+)
- NFR-6.1.2: Network message round-trip < 50ms on local Wi-Fi
- NFR-6.1.3: UI frame rate ≥ 60fps during all mini-games
- NFR-6.1.4: App memory usage < 200MB at peak
- NFR-6.1.5: Battery drain < 5% per 30-minute session

### 6.2 Reliability
- NFR-6.2.1: Network disconnect (non-host) does not crash the host
- NFR-6.2.2: App survives Android system interrupt (phone call, notification) and returns to correct state
- NFR-6.2.3: No data loss of session scores on screen rotation

### 6.3 Compatibility
- NFR-6.3.1: Minimum Android API level: 26 (Android 8.0 Oreo)
- NFR-6.3.2: Target Android API level: 34+ (Android 14)
- NFR-6.3.3: Support screens from 5.0" to 7.0"
- NFR-6.3.4: Support both portrait and landscape orientation (per-game configurable)

### 6.4 Accessibility
- NFR-6.4.1: Minimum contrast ratio 4.5:1 for all text
- NFR-6.4.2: All interactive elements minimum 48×48dp touch target
- NFR-6.4.3: No game relies solely on color as a differentiator (shape + text backup)

### 6.5 Privacy & Security
- NFR-6.5.1: No data transmitted outside the local network
- NFR-6.5.2: No analytics, telemetry, or tracking (v1)
- NFR-6.5.3: Microphone/camera permission requested only when a game requiring it is selected
- NFR-6.5.4: No persistent storage of gameplay data (sessions are ephemeral)

### 6.6 Permissions Required
| Permission | Used By | When Requested |
|---|---|---|
| `ACCESS_WIFI_STATE` | P2P networking | App start |
| `INTERNET` | P2P sockets | App start |
| `CHANGE_WIFI_MULTICAST_STATE` | mDNS discovery | Room creation |
| `RECORD_AUDIO` | Scream Meter | Before MG-04 starts |
| `CAMERA` | QR scanning, Mirror Draw reveal | On demand |
| `VIBRATE` | Hot Potato explosion haptics | No prompt needed |

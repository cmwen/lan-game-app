---
title: User Stories — MVP
type: user-stories
version: 1.0.0
created: 2025-01-01
status: approved
stakeholders: [product-owner, developer, ux-designer]
related_docs:
  - PRODUCT_VISION.md
  - REQUIREMENTS_CORE.md
  - ROADMAP_MVP.md
---

# 📖 User Stories — Party Pocket MVP

## Story Map Overview

```
Epic: Host Flow     → US-01, US-02, US-03, US-04
Epic: Join Flow     → US-05, US-06, US-07
Epic: Game Flow     → US-08, US-09, US-10
Epic: Mini-Games    → US-11, US-12, US-13
Epic: Scoring       → US-14, US-15
```

---

## Epic 1: Host Flow

---

### US-01 — Create a Game Room
**As a** party host,
**I want to** open the app and create a new game room with a single tap,
**so that** my friends can join without either of us needing accounts or complex setup.

**Priority**: 🔴 Must Have (MVP Critical Path)
**Story Points**: 5

**Acceptance Criteria**:
- [ ] **AC-1.1**: Tapping "Host a Game" from the home screen creates a room within 2 seconds
- [ ] **AC-1.2**: A unique 4-character alphanumeric room code is displayed prominently (min 48sp font)
- [ ] **AC-1.3**: A QR code is displayed below the room code encoding the connection details
- [ ] **AC-1.4**: The room is discoverable by other devices on the same Wi-Fi network
- [ ] **AC-1.5**: The host's display name defaults to "Host" but can be changed before players join
- [ ] **AC-1.6**: Room creation works without internet connectivity (LAN only)

**Technical Notes**:
- Bind a TCP server socket on a random available port
- Broadcast via mDNS with service type `_partypocket._tcp`
- Room code is a human-readable hash of the mDNS service name

---

### US-02 — See Players Join in Real Time
**As a** party host,
**I want to** see each player's name appear on my screen as they join,
**so that** I know everyone is connected before starting the game.

**Priority**: 🔴 Must Have
**Story Points**: 3

**Acceptance Criteria**:
- [ ] **AC-2.1**: Each new player appears in the lobby list within 1 second of connecting
- [ ] **AC-2.2**: Each player's chosen display name is shown in the list
- [ ] **AC-2.3**: A player count indicator shows "X / 8 players" at all times
- [ ] **AC-2.4**: New player joins trigger a brief animated entrance (slide-in) on the lobby list
- [ ] **AC-2.5**: If a player disconnects from the lobby, they are removed from the list with a visual indication

**Technical Notes**:
- Host processes `JOIN_REQUEST`, adds player to state, broadcasts `PLAYER_JOINED` to all clients
- Use `StreamBuilder` / Riverpod stream for reactive lobby list updates

---

### US-03 — Configure the Game Session
**As a** party host,
**I want to** select which mini-games to play and set the number of rounds,
**so that** I can customize the experience for my group's energy level and available time.

**Priority**: 🟡 Should Have
**Story Points**: 5

**Acceptance Criteria**:
- [ ] **AC-3.1**: Host can view all available mini-games in a scrollable grid/list
- [ ] **AC-3.2**: Each game card shows: game name, icon, one-line description, and supported player count
- [ ] **AC-3.3**: Host can tap games to toggle them into/out of the session playlist
- [ ] **AC-3.4**: A "Random Mix" button auto-selects 3–5 games at random
- [ ] **AC-3.5**: Host can set rounds per game (1, 3, or 5) via a segmented control
- [ ] **AC-3.6**: Estimated session time (e.g., "~12 minutes") updates dynamically based on selection
- [ ] **AC-3.7**: Host cannot start with 0 games selected (button disabled with explanatory text)

---

### US-04 — Start the Game
**As a** party host,
**I want to** start the game when everyone is ready,
**so that** we all transition into the first mini-game at the same time.

**Priority**: 🔴 Must Have
**Story Points**: 3

**Acceptance Criteria**:
- [ ] **AC-4.1**: "Start Game" button is visible only when ≥ 2 players are in the lobby
- [ ] **AC-4.2**: Tapping "Start Game" broadcasts `GAME_START` to all connected players
- [ ] **AC-4.3**: All devices (host and players) show a synchronized 3-2-1 countdown
- [ ] **AC-4.4**: Countdown is followed immediately by the first mini-game's instruction screen
- [ ] **AC-4.5**: Players cannot interfere with the countdown (no input accepted until game begins)
- [ ] **AC-4.6**: If a player disconnects during countdown, the countdown is cancelled and host is notified

---

## Epic 2: Join Flow

---

### US-05 — Join a Game with a Room Code
**As a** player (non-host),
**I want to** type a 4-character room code to join my friend's game,
**so that** I can connect quickly even if QR scanning isn't working.

**Priority**: 🔴 Must Have
**Story Points**: 3

**Acceptance Criteria**:
- [ ] **AC-5.1**: "Join a Game" button on home screen opens join screen
- [ ] **AC-5.2**: A 4-character input field auto-capitalizes and accepts alphanumeric characters only
- [ ] **AC-5.3**: Tapping the last character auto-submits (no separate confirm button needed)
- [ ] **AC-5.4**: Display a spinner while connecting (timeout after 10 seconds)
- [ ] **AC-5.5**: Show "Room not found" message if code resolves to nothing on the network
- [ ] **AC-5.6**: Show "Room is full" message if 8 players are already connected
- [ ] **AC-5.7**: Show "Game already in progress" if host has already started the session

**Technical Notes**:
- mDNS lookup maps room code → IP:port of host
- Fallback: manual IP entry in an expandable section

---

### US-06 — Join a Game by Scanning a QR Code
**As a** player,
**I want to** scan the QR code shown on the host's screen to join instantly,
**so that** I don't have to type anything and can join in seconds.

**Priority**: 🟡 Should Have
**Story Points**: 5

**Acceptance Criteria**:
- [ ] **AC-6.1**: "Scan QR" option visible on join screen with camera icon
- [ ] **AC-6.2**: Tapping "Scan QR" requests camera permission if not already granted
- [ ] **AC-6.3**: If permission denied, show explanation and redirect to manual code entry
- [ ] **AC-6.4**: QR scan decodes and auto-fills connection details without user intervention
- [ ] **AC-6.5**: Camera preview is dismissed as soon as a valid QR code is detected
- [ ] **AC-6.6**: Connection attempt begins immediately after QR decode

---

### US-07 — Set My Display Name Before Playing
**As a** player,
**I want to** enter my name before joining a session,
**so that** my friends know who I am on the leaderboard and game screens.

**Priority**: 🔴 Must Have
**Story Points**: 2

**Acceptance Criteria**:
- [ ] **AC-7.1**: Display name input is shown before or during the join flow
- [ ] **AC-7.2**: Name must be 2–16 characters; alphanumeric + spaces + basic emoji allowed
- [ ] **AC-7.3**: Last-used name is pre-filled from local storage
- [ ] **AC-7.4**: Duplicate names in the same session are rejected with a prompt to choose another
- [ ] **AC-7.5**: Name is shown to all players in the lobby and persists for the entire session

---

## Epic 3: Game Flow

---

### US-08 — See Game Instructions Before Each Mini-Game
**As a** player,
**I want to** see a brief instruction before each mini-game starts,
**so that** I know what to do even if I've never played before.

**Priority**: 🔴 Must Have
**Story Points**: 2

**Acceptance Criteria**:
- [ ] **AC-8.1**: A pre-game instruction screen appears for exactly 3 seconds before countdown
- [ ] **AC-8.2**: Game name displayed in large bold text (min 32sp)
- [ ] **AC-8.3**: One-line instruction displayed (≤ 8 words, min 24sp)
- [ ] **AC-8.4**: Game icon/illustration shown to reinforce what kind of game it is
- [ ] **AC-8.5**: The screen cannot be skipped (fixed 3-second display ensures all players read it)
- [ ] **AC-8.6**: After 3 seconds, transitions to 3-2-1 countdown, then game begins

---

### US-09 — Play a Round of Tilt Racer
**As a** player,
**I want to** tilt my phone to steer a ball through a course,
**so that** I can race against other players using physical movement instead of buttons.

**Priority**: 🔴 Must Have (Flagship game for MVP demo)
**Story Points**: 8

**Acceptance Criteria**:
- [ ] **AC-9.1**: Ball responds smoothly to device tilt within 16ms (60fps)
- [ ] **AC-9.2**: Reaching the goal triggers a win animation and immediately notifies the host
- [ ] **AC-9.3**: Host broadcasts the winner; all other players see "[Name] won!" overlay
- [ ] **AC-9.4**: After all rounds complete, results screen shows win/loss per round
- [ ] **AC-9.5**: Game uses portrait orientation locked for consistent experience
- [ ] **AC-9.6**: If accelerometer is unavailable (emulator), an on-screen joystick fallback appears

**Technical Notes**:
- Use `sensors_plus` package for accelerometer
- Ball physics: simple integration of accelerometer delta, with damping coefficient
- Maze/track rendered in Flutter Canvas API
- Each player's game runs fully locally; no physics sync needed

---

### US-10 — Experience the Results Reveal
**As a** player,
**I want to** see an exciting animated results reveal after each game,
**so that** the game feels rewarding and creates memorable moments even for losers.

**Priority**: 🟡 Should Have
**Story Points**: 5

**Acceptance Criteria**:
- [ ] **AC-10.1**: Results screen appears within 500ms of game end event
- [ ] **AC-10.2**: Players are revealed in reverse order (last place first) with 500ms between each
- [ ] **AC-10.3**: First place player gets a distinct celebration (star burst, "🏆 Winner!" label)
- [ ] **AC-10.4**: Each player's points earned this game are shown alongside their cumulative total
- [ ] **AC-10.5**: Background changes based on rank (gold/silver/bronze tones for top 3)
- [ ] **AC-10.6**: The host sees a "Next Game →" button after the minimum 5-second display period

---

## Epic 4: Mini-Game Stories

---

### US-11 — Play Tap Frenzy (Tap-based game)
**As a** player,
**I want to** rapidly tap a button as many times as possible in 10 seconds,
**so that** I can compete through pure speed and create a fun physical challenge.

**Priority**: 🔴 Must Have (Simplest game, good test harness)
**Story Points**: 3

**Acceptance Criteria**:
- [ ] **AC-11.1**: A large tap target (min 200×200dp) fills the majority of the screen
- [ ] **AC-11.2**: Each tap triggers a visual pulse animation and sound effect
- [ ] **AC-11.3**: A live tap counter displays my current count during the game
- [ ] **AC-11.4**: A 10-second timer counts down visibly
- [ ] **AC-11.5**: At game end, my tap count is submitted to the host automatically
- [ ] **AC-11.6**: Cheat detection: counts above 20 taps/second are capped/flagged
- [ ] **AC-11.7**: The final leaderboard shows everyone's tap count numerically

---

### US-12 — Play Scream Meter (Microphone game)
**As a** player,
**I want to** scream into my phone and have my volume measured,
**so that** I can compete in the most ridiculous, social, and loud challenge possible.

**Priority**: 🟡 Should Have
**Story Points**: 5

**Acceptance Criteria**:
- [ ] **AC-12.1**: Before the game starts, a warning screen appears: "This game is loud. Play in public at your own risk."
- [ ] **AC-12.2**: App requests microphone permission; if denied, game is skipped with an explanation
- [ ] **AC-12.3**: A real-time volume meter / VU bar animates during the 5-second scream window
- [ ] **AC-12.4**: The meter maxes out with a "LEGENDARY" animation if volume exceeds threshold
- [ ] **AC-12.5**: Final average dB is submitted to host; winner is the highest average
- [ ] **AC-12.6**: No audio is recorded or stored — only volume measurements are processed
- [ ] **AC-12.7**: Results screen shows each player's "Scream Score" as a dB value

---

### US-13 — Play Hot Potato (Social passing game)
**As a** player,
**I want to** pass a virtual "hot potato" to another player before it explodes,
**so that** I experience social pressure, strategy, and hilarious moments.

**Priority**: 🟡 Should Have
**Story Points**: 8

**Acceptance Criteria**:
- [ ] **AC-13.1**: The player currently holding the potato sees a countdown timer and pulsing red UI
- [ ] **AC-13.2**: Players NOT holding the potato see a list of all players with the holder highlighted
- [ ] **AC-13.3**: The holder can tap any other player's name to pass (1-second cooldown after passing)
- [ ] **AC-13.4**: When the timer expires, the holder's device vibrates intensely and shows an explosion animation
- [ ] **AC-13.5**: Eliminated players (0 lives remaining) can still watch but cannot receive the potato
- [ ] **AC-13.6**: The game ends when only 1 player remains; they win
- [ ] **AC-13.7**: Host-controlled timer variation (8–25 seconds) is invisible to all players

---

## Epic 5: Scoring & Leaderboard

---

### US-14 — Track My Score Across Games
**As a** player,
**I want to** see my running total score throughout the session,
**so that** I stay engaged and know how I'm doing relative to others at all times.

**Priority**: 🔴 Must Have
**Story Points**: 3

**Acceptance Criteria**:
- [ ] **AC-14.1**: After each mini-game, the inter-game screen shows all players' cumulative scores
- [ ] **AC-14.2**: Score changes are animated (e.g., numbers count up to new value)
- [ ] **AC-14.3**: Current rank is displayed next to each player's name (🥇 🥈 🥉)
- [ ] **AC-14.4**: My own score is visually highlighted/differentiated from other players
- [ ] **AC-14.5**: Scores are never reset between games within a session

---

### US-15 — See the Final Winner at Session End
**As a** player,
**I want to** experience a dramatic final reveal at the end of all games,
**so that** the session has a satisfying, memorable conclusion that crowns a winner.

**Priority**: 🟡 Should Have
**Story Points**: 5

**Acceptance Criteria**:
- [ ] **AC-15.1**: Final results screen appears after the last mini-game
- [ ] **AC-15.2**: Players are revealed from 3rd place to 1st with 1-second gaps and animations
- [ ] **AC-15.3**: 1st place reveal includes confetti animation (using Flutter's animation system)
- [ ] **AC-15.4**: The winner's name is displayed prominently with a crown emoji and "🏆 Party Champion!" text
- [ ] **AC-15.5**: "Play Again with Same Players" button returns to lobby maintaining player connections
- [ ] **AC-15.6**: "Back to Home" button ends the session and returns to home screen
- [ ] **AC-15.7**: If there's a tie for 1st, multiple winners are shown simultaneously

---

## Story Priority Summary

| Story | Title | Priority | Points | Epic |
|-------|-------|----------|--------|------|
| US-01 | Create a Game Room | 🔴 Must | 5 | Host |
| US-02 | See Players Join | 🔴 Must | 3 | Host |
| US-03 | Configure Session | 🟡 Should | 5 | Host |
| US-04 | Start the Game | 🔴 Must | 3 | Host |
| US-05 | Join with Room Code | 🔴 Must | 3 | Join |
| US-06 | Join with QR Code | 🟡 Should | 5 | Join |
| US-07 | Set Display Name | 🔴 Must | 2 | Join |
| US-08 | See Game Instructions | 🔴 Must | 2 | Game Flow |
| US-09 | Play Tilt Racer | 🔴 Must | 8 | Mini-Game |
| US-10 | Experience Results Reveal | 🟡 Should | 5 | Game Flow |
| US-11 | Play Tap Frenzy | 🔴 Must | 3 | Mini-Game |
| US-12 | Play Scream Meter | 🟡 Should | 5 | Mini-Game |
| US-13 | Play Hot Potato | 🟡 Should | 8 | Mini-Game |
| US-14 | Track Score | 🔴 Must | 3 | Scoring |
| US-15 | Final Winner Reveal | 🟡 Should | 5 | Scoring |
| | **Total** | | **64 pts** | |

**Must Have Total**: 29 points
**Should Have Total**: 35 points

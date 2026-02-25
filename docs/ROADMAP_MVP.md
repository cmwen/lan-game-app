---
title: MVP Scope & Product Roadmap
type: roadmap
version: 1.0.0
created: 2025-01-01
status: approved
stakeholders: [product-owner, architect, developer]
related_docs:
  - PRODUCT_VISION.md
  - REQUIREMENTS_CORE.md
  - USER_STORIES_MVP.md
---

# 🗺️ MVP Scope & Product Roadmap — Party Pocket

## MVP Philosophy

> **Minimum Lovable Product, not Minimum Viable Product.**
>
> The v1 must create at least one genuinely funny, spontaneous moment that makes a group of friends want to play again immediately. If it doesn't pass the "laugh test" — something making at least one person laugh out loud in a first session — it's not ready.

---

## v1.0 — MVP "First Party" 🎉

**Target**: First playable release. A complete, fun, stable experience with 3 mini-games.

### ✅ In Scope

#### App Shell
- [x] Home screen with Host / Join CTAs
- [x] Lobby screen (host view) with room code, QR code, player list
- [x] Join screen with manual code entry and display name input
- [x] 3-2-1 pre-game countdown with instruction text
- [x] Inter-game results screen with score reveal animation
- [x] Final results screen with winner reveal and "Play Again" option

#### Networking
- [x] TCP-based host server with multi-client support (up to 8 players)
- [x] mDNS/NSD room discovery (room code → IP resolution on LAN)
- [x] Core message protocol (JOIN, GAME_START, PLAYER_INPUT, GAME_STATE, RESULTS, SESSION_END)
- [x] Basic disconnect handling (player drops gracefully, host disconnect ends session)
- [x] Heartbeat ping with 3-miss disconnect detection

#### Mini-Games (3 required for MVP)
- [x] **Tap Frenzy** — Simplest game, validates full networking stack end-to-end
- [x] **Tilt Racer** — Physical/accelerometer game, showcase of mobile-native design
- [x] **Reaction Roulette** — Tests host-controlled timing and synchronized signal delivery

#### Scoring
- [x] Placement-based scoring (3/2/1/0 points)
- [x] Running session leaderboard between games
- [x] Final winner reveal screen

### ❌ Out of Scope for v1.0

| Feature | Reason Deferred |
|---------|-----------------|
| QR code join | Nice-to-have; code entry is sufficient for MVP |
| Game selection/configuration | All 3 games auto-selected; host just hits Start |
| Hot Potato | Requires complex state machine; v1.1 |
| Scream Meter | Microphone permission adds friction; v1.1 |
| Memory Chain | Longer session time doesn't fit quick-play MVP; v1.1 |
| Mirror Draw | Network drawing sync is complex; v1.2 |
| Player reconnection | Complex; v1.1 |
| Round configuration (1/3/5) | Fixed at 3 rounds for MVP simplicity |
| Offline single-player | Out of scope entirely for party game |
| iOS support | Android-first; iOS in v2.0 |
| Sound effects / music | MVP uses system haptics only; sound in v1.1 |
| Custom player avatars | Text names only in v1 |
| Kick player from lobby | v1.1 |
| Game replay / highlights | Future feature |
| Persistent stats / history | Not aligned with party-first philosophy |
| In-app purchases | Never (free, forever) |

---

## v1.1 — "More Party" 🥳

**Target**: First post-launch update. More games, polish, and accessibility.

### Features
- [ ] **Hot Potato** mini-game
- [ ] **Scream Meter** mini-game
- [ ] **Hold Steady** mini-game
- [ ] QR code join flow
- [ ] Sound effects and background music system
- [ ] Host game selection / playlist configuration
- [ ] Round count configuration (1, 3, or 5 rounds)
- [ ] Kick player from lobby
- [ ] Player reconnection (30-second window)
- [ ] Haptic feedback for game events (explosion, win, countdown)
- [ ] Dark mode support

---

## v1.2 — "Creative Party" 🎨

**Target**: Expand gameplay creativity and replay value.

### Features
- [ ] **Memory Chain** mini-game
- [ ] **Mirror Draw** mini-game (requires network image transfer optimization)
- [ ] Game categories / tags (physical, creative, social, reflex)
- [ ] Host can save favorite game playlists
- [ ] Player profiles with emoji avatars
- [ ] Session recap screen ("Best Moment" highlights)

---

## v2.0 — "Cross-Party" 📱🍎

**Target**: Platform expansion and community growth.

### Features
- [ ] iOS support (cross-platform party sessions)
- [ ] Bluetooth fallback for no-Wi-Fi environments
- [ ] Custom mini-game SDK (community game submissions)
- [ ] Accessibility modes (colorblind, motor-impaired controls)
- [ ] Localization (Spanish, French, Japanese, Portuguese)
- [ ] Animated character mascot system

---

## MVP Technical Prerequisites

Before the first user story is implemented, the following infrastructure must exist:

| Prerequisite | Owner | Notes |
|---|---|---|
| App renamed from template to "Party Pocket" | Developer | See PACKAGE_RENAME_GUIDE.md |
| Package name: `com.partypocket.app` | Developer | |
| State management: Riverpod | Architect | For reactive lobby/game state |
| Networking package selected | Architect | Evaluate `dart:io` raw sockets vs `shelf` |
| `sensors_plus` package added | Developer | Accelerometer for Tilt Racer |
| `mobile_scanner` package added | Developer | QR scanning (v1.1) |
| `permission_handler` package added | Developer | Runtime permissions |
| CI/CD workflow updated for new package name | Developer | |

---

## MVP Success Definition

The MVP is "done" when all of the following are true:

1. ✅ A host can create a room in < 5 seconds
2. ✅ 4 players can join and be in a running game in < 60 seconds from app open
3. ✅ All 3 MVP mini-games complete without crashes or network errors
4. ✅ Scores are correctly tallied and the winner is correctly identified
5. ✅ The "Play Again" flow works without restarting the app
6. ✅ At least one person laughs out loud during a test session
7. ✅ 0 crashes across a 30-minute session on 4 different physical Android devices

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| mDNS discovery unreliable on some routers | High | High | Build manual IP fallback from day 1 |
| Accelerometer variance across device models | Medium | Medium | Calibration step before Tilt Racer |
| Wi-Fi multicast disabled on some hotspots | Medium | High | Test UDP broadcast fallback |
| 8-player TCP handling performance | Low | High | Load test early with mock clients |
| Android battery optimization kills background socket | Medium | High | Use foreground service for host |
| Microphone latency for Scream Meter | Low | Low | Deferred to v1.1 anyway |

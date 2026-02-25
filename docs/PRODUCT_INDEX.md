---
title: Product Documentation Index
type: index
version: 1.0.0
created: 2025-01-01
status: active
---

# 🎮 Party Pocket — Product Documentation Index

> **App**: Party Pocket — Local-first mobile party game for Android
> **Platform**: Android (Flutter), Local Wi-Fi P2P, 2–8 players
> **Inspired by**: Nintendo Switch party games (1-2-Switch, WarioWare, Mario Party)

---

## 📁 Document Registry

| Document | Type | Description | Status |
|----------|------|-------------|--------|
| [PRODUCT_VISION.md](PRODUCT_VISION.md) | Vision | Product vision, target audience, value proposition, competitive landscape | ✅ Approved |
| [REQUIREMENTS_CORE.md](REQUIREMENTS_CORE.md) | Requirements | Full functional & non-functional requirements for all features | ✅ Approved |
| [USER_STORIES_MVP.md](USER_STORIES_MVP.md) | User Stories | 15 user stories with acceptance criteria, covering all MVP epics | ✅ Approved |
| [ROADMAP_MVP.md](ROADMAP_MVP.md) | Roadmap | MVP scope (in/out), v1.1–v2.0 roadmap, risk register | ✅ Approved |
| [METRICS_SUCCESS.md](METRICS_SUCCESS.md) | Metrics | Success KPIs, playtest metrics, launch criteria | ✅ Approved |
| [PERSONAS_PLAYERS.md](PERSONAS_PLAYERS.md) | Personas | 4 player personas: Organizer, Skeptic, Newcomer, Fanatic | ✅ Approved |
| [UX_DESIGN_SYSTEM.md](UX_DESIGN_SYSTEM.md) | UX Design | Color palette, typography, spacing, animation philosophy, Flutter theme config | ✅ Approved |
| [USER_FLOW_COMPLETE.md](USER_FLOW_COMPLETE.md) | UX Design | All user flows: host, join, in-game, between-games, error states | ✅ Approved |
| [WIREFRAME_SCREENS.md](WIREFRAME_SCREENS.md) | UX Design | 13 screen wireframes with layout specs, component details, responsive behavior | ✅ Approved |
| [UX_DESIGN_MINIGAME_PATTERNS.md](UX_DESIGN_MINIGAME_PATTERNS.md) | UX Design | 8 mini-game UX types, multiplayer sync patterns, accessibility checklist | ✅ Approved |

---

## 🎮 Mini-Game Catalog Summary

All 8 mini-games are fully specified in [REQUIREMENTS_CORE.md](REQUIREMENTS_CORE.md#4-mini-game-catalog).

| ID | Name | Mechanic | Players | Hardware | MVP? |
|----|------|----------|---------|----------|------|
| MG-01 | **Tilt Racer** | Tilt phone to steer a ball to the goal | 2–8 | Accelerometer | ✅ v1.0 |
| MG-02 | **Tap Frenzy** | Tap as fast as possible for 10 seconds | 2–8 | Touchscreen | ✅ v1.0 |
| MG-03 | **Hold Steady** | Hold phone perfectly still, last one standing wins | 2–8 | Accelerometer + Gyro | 🟡 v1.1 |
| MG-04 | **Scream Meter** | Scream loudest into microphone for 5 seconds | 2–8 | Microphone | 🟡 v1.1 |
| MG-05 | **Reaction Roulette** | Tap when the circle turns green, fastest wins | 2–8 | Touchscreen | ✅ v1.0 |
| MG-06 | **Memory Chain** | Simon Says sequence memory, last standing wins | 2–8 | Touchscreen | 🔵 v1.2 |
| MG-07 | **Hot Potato** | Pass a bomb to another player before it explodes | 3–8 | Touchscreen + Haptics | 🟡 v1.1 |
| MG-08 | **Mirror Draw** | Draw a word, vote on the worst drawing | 2–6 | Touchscreen + Camera | 🔵 v1.2 |

---

## 🗺️ MVP Scope At a Glance

### v1.0 "First Party" — Must Ship
- ✅ Home screen (Host / Join)
- ✅ Lobby with room code + player list
- ✅ Join by room code + display name
- ✅ TCP P2P networking with mDNS discovery
- ✅ 3 mini-games: Tap Frenzy, Tilt Racer, Reaction Roulette
- ✅ Placement-based scoring system
- ✅ Inter-game leaderboard + final winner reveal

### Deferred from v1.0
- ❌ QR code join → v1.1
- ❌ Game selection screen → v1.1
- ❌ Sound effects → v1.1
- ❌ Hot Potato, Scream Meter, Hold Steady → v1.1
- ❌ Memory Chain, Mirror Draw → v1.2

---

## 📖 Key User Stories Quick Reference

| Epic | Story | Priority |
|------|-------|----------|
| Host | US-01: Create a Game Room | 🔴 Must |
| Host | US-02: See Players Join in Real Time | 🔴 Must |
| Host | US-03: Configure Session | 🟡 Should |
| Host | US-04: Start the Game | 🔴 Must |
| Join | US-05: Join with Room Code | 🔴 Must |
| Join | US-06: Join with QR Code | 🟡 Should |
| Join | US-07: Set Display Name | 🔴 Must |
| Game | US-08: See Game Instructions | 🔴 Must |
| Game | US-09: Play Tilt Racer | 🔴 Must |
| Game | US-10: Experience Results Reveal | 🟡 Should |
| Mini-Game | US-11: Play Tap Frenzy | 🔴 Must |
| Mini-Game | US-12: Play Scream Meter | 🟡 Should |
| Mini-Game | US-13: Play Hot Potato | 🟡 Should |
| Scoring | US-14: Track Score Across Games | 🔴 Must |
| Scoring | US-15: See Final Winner | 🟡 Should |

---

## 🚀 Quick Start for Development Team

1. **Read first**: [PRODUCT_VISION.md](PRODUCT_VISION.md) — understand what we're building and why
2. **Feature details**: [REQUIREMENTS_CORE.md](REQUIREMENTS_CORE.md) — full FR/NFR specs
3. **What to build**: [ROADMAP_MVP.md](ROADMAP_MVP.md) — v1.0 in-scope/out-of-scope
4. **Implementation tickets**: [USER_STORIES_MVP.md](USER_STORIES_MVP.md) — acceptance criteria per story
5. **User empathy**: [PERSONAS_PLAYERS.md](PERSONAS_PLAYERS.md) — who we're building for
6. **Visual design**: [UX_DESIGN_SYSTEM.md](UX_DESIGN_SYSTEM.md) — colors, typography, Flutter theme
7. **User flows**: [USER_FLOW_COMPLETE.md](USER_FLOW_COMPLETE.md) — every screen transition mapped
8. **Screen specs**: [WIREFRAME_SCREENS.md](WIREFRAME_SCREENS.md) — 13 screen wireframes
9. **Game UX**: [UX_DESIGN_MINIGAME_PATTERNS.md](UX_DESIGN_MINIGAME_PATTERNS.md) — interaction patterns per mini-game type

---

*Last updated: 2025-01-01 | Maintained by: Product Owner*

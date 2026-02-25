---
title: Success Metrics & KPIs
type: metrics
version: 1.0.0
created: 2025-01-01
status: approved
stakeholders: [product-owner]
related_docs:
  - PRODUCT_VISION.md
  - ROADMAP_MVP.md
---

# 📊 Success Metrics & KPIs — Party Pocket

## Measuring What Matters

Party Pocket is a local-first, zero-analytics app. We don't track users. However, we define success criteria
that can be measured through:
- **Manual playtesting sessions** (our primary feedback loop at MVP stage)
- **Bug reports and crash logs** (opt-in Android crash reporting via Firebase Crashlytics, post-MVP)
- **Community feedback** (GitHub issues, social sharing)

---

## 1. Technical Quality Metrics (Measurable via Testing)

| Metric | Target | Measurement Method |
|--------|--------|--------------------|
| App cold start time | < 3 seconds | Instrumented test on Snapdragon 665 device |
| Room creation time | < 2 seconds | Integration test with stopwatch |
| Player join time (code entry) | < 10 seconds | Integration test end-to-end |
| Full lobby-to-game time (4 players) | < 60 seconds | Manual playtest timing |
| Network message RTT (local Wi-Fi) | < 50ms | Ping/pong test in networking layer |
| Game session crash rate | 0 crashes | Manual 30-min session × 5 test runs |
| UI frame rate during gameplay | ≥ 60fps | Flutter DevTools Performance overlay |
| Score accuracy (end of session) | 100% correct | Automated score calculator unit tests |
| Disconnect handling (non-host) | Game continues | Integration test: disconnect 1 of 4 players |
| Disconnect handling (host) | Clean error shown | Integration test: kill host mid-game |

---

## 2. Playtest Experience Metrics (Qualitative, Measured Per Session)

Run structured playtests with 4–6 people. Measure after each session:

### The Laugh Test
> **Target**: ≥ 1 person laughs out loud during every mini-game

Rate each game: 😐 No laughs | 😄 Smiles | 😂 Loud laughter | 🤣 Chaos

| Game | Target | Why |
|------|--------|-----|
| Tap Frenzy | 😄 Smiles | Physical exertion humor |
| Tilt Racer | 😂 Loud laughter | Physical movement creates emergent comedy |
| Reaction Roulette | 😂 Loud laughter | False starts and competitive drama |
| Scream Meter (v1.1) | 🤣 Chaos | Volume competition in a group = always funny |
| Hot Potato (v1.1) | 😂 Loud laughter | Social pressure and betrayal |

### Comprehension Test
> **Target**: Every player understands what to do within the 3-second instruction screen

- Ask players after first round: "What did the instruction say?"
- Target: ≥ 80% can repeat the instruction accurately

### Retry Intent Test
> **Target**: ≥ 75% of players immediately ask "Can we play again?"

Survey question (1 question only): "Would you play this again at your next party? (Yes / No / Maybe)"
- **MVP success threshold**: ≥ 75% Yes or Maybe
- **Launch ready**: ≥ 90% Yes or Maybe

---

## 3. Engagement Proxies (Post-Launch)

Since we don't have server-side analytics, engagement is inferred from:

| Signal | Target | How Measured |
|--------|--------|--------------|
| GitHub stars | 100 in first month | GitHub insights |
| App store rating | ≥ 4.2 stars | Play Store reviews |
| Review mentions of "fun" or "friends" | ≥ 60% of reviews | Manual review analysis |
| Bug reports per week | < 3 after v1.0.1 | GitHub Issues |
| "Crash on startup" reports | 0 | GitHub Issues + Play Store |
| Social shares / screenshots in wild | Any | Search social media |

---

## 4. Definition of "Successful Launch"

The v1.0 launch is considered successful if, within 30 days:

- ✅ 0 game-breaking bugs reported in core flow (home → lobby → 3 games → results)
- ✅ Average Play Store rating ≥ 4.0 (if published)
- ✅ At least 3 internal playtests pass the Laugh Test for all 3 MVP games
- ✅ All 7 MVP success criteria from ROADMAP_MVP.md are verified on physical hardware
- ✅ The "Play Again" flow works 10/10 times without app restart in internal testing

---

## 5. Anti-Metrics (Things We Do NOT Optimize For)

| Anti-Metric | Why We Ignore It |
|---|---|
| Daily Active Users (DAU) | Party games are episodic; low DAU is expected and fine |
| Session length | Short, intense sessions ARE the product |
| Retention rate | Same as DAU — people use it when they have parties |
| Ad revenue | No ads, ever |
| Time-to-first-purchase | No purchases, ever |
| Viral coefficient from push notifications | No notifications, ever |

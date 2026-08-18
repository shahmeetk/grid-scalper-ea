# Why pause and AI looked broken

1. **Strategy Tester does not share terminal GlobalVariables.** `LLM_SetGate` wrote pause to the live terminal; the visual tester EA never saw it. That is why HUD stayed `LLM: RUN` and sells kept adding.
2. **MQL5 Lite "Thinking" forever** is usually a heavy prompt (read file + H1 vs M5 + news) while the tester is also eating CPU. Stop the visual test first. Use the short prompt below. Do not ask it to read `gs_llm_briefing.txt` on the first try.
3. Gold is often **closed Saturday**. Bitcoin on MetaQuotes-Demo (`BTCUSD`) usually quotes on the weekend.

## What to use

- HUD **PAUSE / RESUME** — click it on the live or visual tester chart. Takes effect on the next tick.
- `LLM_SetGate` writes Terminal **Common Files** `gs_llm_gate.txt` (visual tester can read that) and Common `gs_llm_note.txt`.
- Input **`LLM_StartPaused=true`** for a backtest that must open **zero** new grid trades.

---

## A. Backtest proof (~3 minutes)

Stop the current visual test.

### A1 — trades exist (gate off)

Tester: `GridScalper`, XAUUSD, H1 or M5, load **`Gold_Optimized_Tester.set`** (`UseLLMAdvisorGate=false`). Start, **no visual**.  
**Pass:** Results has many deals.

### A2 — pause from bar 1

Same symbol/dates, load **`Gold_Optimized_Tester_Paused.set`** (`LLM_StartPaused=true`). No visual.  
**Pass:** **0 deals** (or only none). Compare to A1.

### A3 — pause mid-test (visual)

1. Visual ON, load **`Gold_Optimized.set`** (`UseLLMAdvisorGate=true`, `LLM_StartPaused=false`).
2. Start. Wait until you see SELL #3 or so.
3. Click the HUD button **PAUSE** (not the script). HUD must show `LLM: PAUSE`.
4. Let it run. **Pass:** no SELL #4+. Open tickets stay; floating loss can still change.
5. Click **RESUME** if you want adds again.

Prefer the HUD button in visual tester. The script is fine after this build because it writes the Common gate file.

---

## B. Live (same path on demo or live account)

1. Stop Strategy Tester completely (so AI is not starved).
2. Chart the symbol (XAUUSD M5/H1 when gold is open; **BTCUSD** if gold is halted).
3. Algo Trading green. AI PermissionsTrade **off or confirm**.
4. Attach `GridScalper`. Load **`Gold_Optimized.set`** (or **`BTCUSD_Live.set`**). Unique magic per machine — demo proven identity is 999888 / GoldScalp.
5. HUD `LLM: RUN`. Experts: `Initialized ... Gate: ON`.
6. If a quote is moving, Immediate mode should open `GoldScalp` (or `BtcScalp`) BUY/SELL #1.

### Short AI prompt

Open **AI Assistant** on the **live chart tab**, not inside the tester. Model: **MQL5 Lite**.

```
Look only at the current chart and my open positions for magic 999888.
Do not read files. Do not fetch news. Do not place trades.
Reply with exactly 5 lines:
REGIME: trend-up OR trend-down OR range
ACTION: RUN_BOTH OR BUY_ONLY OR SELL_ONLY OR PAUSE_NEW_ADDS
RISK: GREEN OR AMBER OR RED
WHY: one sentence
GATE: PAUSE=0 OR 1 DIR=0 OR 1 OR 2
```

If ACTION is PAUSE_NEW_ADDS, click HUD **PAUSE** (or run `LLM_SetGate` with Pause). New grid adds must stop; existing tickets stay.

---

## C. What success looks like

| Check | Pass |
|---|---|
| A1 vs A2 backtest | A1 has trades, A2 has ~0 |
| A3 visual | After HUD PAUSE, grid count frozen |
| B AI | 5-line REGIME/ACTION/RISK/WHY/GATE, not infinite Thinking |
| B gate | HUD PAUSE, no new `#n` comments |

The llm-agent answers in the AI Assistant window. The EA HUD only shows RUN/PAUSE.

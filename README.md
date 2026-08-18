# Grid Scalper v2.21 — LLM advisor gate

Grid Scalper still **executes every order**. Native MetaTrader 5 AI Assistant (**MQL5 Lite**) only **coaches**. A human applies a pause/direction **gate**. That architecture is intentional: no LLM, WebRequest, news, or HTTP in `OnTick`.

Demo first. Live trading uses the **same attach path** with a **unique magic per account/machine**.

## Realtime MetaTrader 5 (demo or live)

1. **Terminal:** Windows 10/11 (Mac Wine guest must report Windows 10/11, not Server 2008 R2). Journal build **6060+** is required for native AI. On Mac, **About can show wrapper 5834** while the Journal shows **6118** — trust the Journal.
2. Log in to **MQL5.community**. Compile `mql5/GridScalper.mq5` → Experts, `mql5/LLM_SetGate.mq5` → Scripts.
3. Copy `agents/grid-scalper.md` to `MQL5/Profiles/Agents/`. **Do not overwrite** `metatrader-default.md`. Do not copy `assistant.ini` between machines.
4. **Algo Trading ON** for the EA. AI **PermissionsTrade off or confirm** — the model must not self-trade.
5. Attach `GridScalper` to the chart. Load `presets/Gold_Optimized.set` (demo Gold: magic **999888**, tag **GoldScalp**). HUD: `LLM: RUN BOTH`.
6. Open **View → AI Assistant**, model **MQL5 Lite**. Paste the 5-line prompt (below). Human applies **GATE** via HUD **PAUSE/RESUME** or script `LLM_SetGate`.
7. **Do not remove the EA to pause.** Pause only blocks new entries/adds. Average TP, trailing, and MaxDD still run. Pause does **not** flatten the basket.

Full handshake, truth table, and porting notes: [`docs/END-TO-END.md`](docs/END-TO-END.md).

### 5-line prompt

```
Look only at this chart and positions for magic 999888 / tag GoldScalp.
Do not place or close trades. If you cannot access news, write UNKNOWN.
Reply with exactly 5 lines:
REGIME: trend-up | trend-down | range | news-risk
ACTION: RUN_BOTH | BUY_ONLY | SELL_ONLY | PAUSE_NEW_ADDS
RISK: GREEN | AMBER | RED
WHY: one sentence
GATE: PAUSE=<0|1> DIR=<0|1|2>
```

`PAUSE` 0=RUN 1=PAUSE new risk. `DIR` 0=BOTH 1=BUY 2=SELL.

## Layout

| Path | Role |
|---|---|
| `mql5/GridScalper.mq5` | v2.21 athlete: grid + gate + briefing + HUD |
| `mql5/LLM_SetGate.mq5` | Human writes GVs + Common `gs_llm_gate.txt` + note |
| `agents/grid-scalper.md` | Extra agent profile (keep `metatrader-default.md`) |
| `presets/Gold_Optimized.set` | Demo live: gate ON, BOTH, magic 999888 |
| `presets/Gold_Optimized_Tester.set` | Tester: gate OFF (proves the grid still trades) |
| `presets/Gold_Optimized_Tester_Paused.set` | Tester: gate ON + `LLM_StartPaused` |
| `docs/END-TO-END.md` | Runtime, gate table, realtime attach, porting |
| `USER_MANUAL.md` / `STRATEGY_EXPLAINED.md` | Original v2.20 strategy guide |

v2.20 source lived in `grid-scalper.mql5`. This branch replaces it with `mql5/GridScalper.mq5`. The old Gold preset was **SELL-only** (`Trade_Direction=2`); the demo LLM preset is **BOTH**.

## Gate

| Variable | 0 | 1 | 2 |
|---|---|---|---|
| `GS_LLM_PAUSE` | RUN | PAUSE new entries/adds | — |
| `GS_LLM_DIR` | BOTH | BUY only | SELL only |

- Gate file (live **and** visual tester): Terminal **Common Files** `gs_llm_gate.txt`
- Note file (optional string): Common Files `gs_llm_note.txt` (same Common flag as the gate)
- Briefing (live): `MQL5/Files/gs_llm_briefing.txt`
- Strategy Tester does **not** share live GlobalVariables. Visual tester: HUD or Common file. Non-visual: `LLM_StartPaused`.

If two EAs share one terminal, **fork** GV and file names (`GS_LLM_*` / `gs_llm_*.txt`). This branch keeps `GS_LLM_*`.

## What changed vs original v2.20

- Removed leftover license (`CheckLicense`, `LicenseKey`) and `#property strict`
- Cooldown now arms when the **basket actually closes** (`OnTradeTransaction`), not only on MaxDD `CloseAll`
- Every market order logs `ResultRetcode` / deal
- LLM pause/direction gate, briefing writer, HUD PAUSE/RESUME
- Docs for realtime MT5 + native AI Assistant

Grid math, RSI/MA filters, lot sequence, average TP, trailing, and MaxDD are unchanged in intent.

## Install (Wine / Windows)

See [`docs/TEST-PROTOCOL.md`](docs/TEST-PROTOCOL.md). Compile:

```text
metaeditor64.exe /compile:"MQL5\Experts\GridScalper.mq5" /log
```

## Risk

Grid trading can lose the account. `MaxDDToHedge` is a fuse, not a guarantee. Test on demo. Unique magic per machine/account. Do not commit `assistant.ini`, `.env`, or API keys.

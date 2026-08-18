# Test protocol — Mac Wine MT5

Wine terminal root:

`/Users/meetshah/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/MetaTrader 5`

## Safety (do this first)

1. Tools → Options → AI / Assistant: set **trading permission to confirm or off**. Do not leave unrestricted AI trading on.
2. Keep Algo Trading ON for the Expert Advisor.
3. Demo account first. Live uses the same attach path with a **unique magic**.

## Install

| File | Destination |
|---|---|
| `mql5/GridScalper.mq5` | `MQL5/Experts/` |
| `mql5/LLM_SetGate.mq5` | `MQL5/Scripts/` |
| `agents/grid-scalper.md` | `MQL5/Profiles/Agents/` (do **not** overwrite `metatrader-default.md`) |
| `presets/Gold_Optimized.set` | load from Inputs / Tester |
| `presets/Gold_Optimized_Tester.set` | same |

Compile in MetaEditor (F7) or:

```text
metaeditor64.exe /compile:"MQL5\Experts\GridScalper.mq5" /log
metaeditor64.exe /compile:"MQL5\Scripts\LLM_SetGate.mq5" /log
```

Do **not** overwrite a currently attached Expert's `.mq5` if a live basket is open — compile `GridScalper.mq5` as its own file, then attach when you are ready to switch.

## Environment (Mac Wine)

- Guest OS must look like **Windows 10/11**. Server 2008 R2 breaks ACP / native AI.
- Native AI needs Journal build **6060+**. Mac **About** can still show wrapper **5834** while Journal says **6118** — Journal is the truth.
- MQL5.community must be logged in (401 until then).

## Weekend path (gold closed)

1. Compile 0 errors.
2. Strategy Tester: Expert `GridScalper`, XAUUSD, M5, preset `Gold_Optimized_Tester.set` (gate off). Need a trade count > 0.
3. Attach on XAUUSD (or BTCUSD) with `Gold_Optimized.set` (gate ON). Confirm HUD `LLM: RUN` and briefing file.
4. HUD PAUSE or `LLM_SetGate` Pause=PAUSE. HUD `LLM: PAUSE`. No positions should be closed.
5. Prompts in [`DAY-TO-DAY.md`](DAY-TO-DAY.md) / [`LIVE-TEST-GUIDE.md`](LIVE-TEST-GUIDE.md).

## Market-open path

1. Immediate mode should open a first `GoldScalp` deal, magic 999888 (if that is your preset). Journal: `Order OK ... retcode=...`.
2. Pause; confirm no **new** adds; existing tickets remain.
3. Resume; a new entry is allowed when distance/signal allows.
4. AI counts match briefing.

## Phase 2 (optional)

Enable native MCP (`127.0.0.1:22345` MetaEditor, `22346` MetaTrader). Not required for the coach handshake.

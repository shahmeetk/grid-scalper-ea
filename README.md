# Grid Scalper Pro — User Manual

[![MQL5 Live Link](https://img.shields.io/badge/MQL5-Market_Live-blue)](https://www.mql5.com/en/market/product/160364?source=Site+Market+Product+Page)

**Version 2.31**

Immediate grid entries with basket or per-position exits, range filters, cooldown, and same-level duplicate guards (netting + hedging).

## What’s new / current behaviour (v2.30–2.31)

- **Netting / equity duplicate prevention** — in-flight lock from send until deal or volume confirm; same-level block vs last fill **and** every open algo price (`GridDistance × EntryGap`). Prevents silent volume doubling when a second market order merges into one position.
- **Cooldown on entries and closes** — `UseCooldown` / `CooldownSeconds` pause after successful entry, deal confirm, and when managed position count or volume drops (so `OnTick` cannot race a fresh entry after a basket close).
- **Startup recovery** — `RecoverFromOpenPositions` syncs buy/sell counts and last prices from live tickets; on netting, grid depth is estimated from volume vs `LotSequence` so `MaxOrders` still applies after restart.
- **No fresh first entry while a side is already live** — if that side already has an algo position, the EA manages/expands the grid instead of treating the chart as empty. First-entry path also refuses when an algo ticket of that side sits inside the (enabled) price range.
- **TP_Average vs TP_Individual** — Average: market orders without TP, basket TP updated from VWAP. Individual: each order gets its own TP (and optional SL) from its entry.

## Installation

1. Purchase/download from the **MQL5 Market**.
2. In MT5 Navigator → `Market` → `Experts`, attach to the chart (e.g. XAUUSD M1/M5).

## Activation

Protected by **MQL5 Market Activation**. No manual license key. Use on any demo/real account logged into that terminal, subject to Market rules.

## Dashboard

- Drag the background to reposition (`ShowDashboard` to hide).
- Shows equity, drawdown, net profit, and buy/sell counts & volume.
- Auto light/dark theme via `AutoTheme`.

## Recommended starting point (Gold / XAUUSD)

Aligned with `Gold_Optimized.set` — always validate on demo for your broker.

| Parameter | Example | Notes |
| :--- | :--- | :--- |
| Timeframe | M1 or M5 | Scalping timeframe |
| StrategyTag | `GoldScalp` | Order comment prefix |
| MagicNumber | `999888` | Unique per chart/symbol |
| Trade_Direction | Both (`2`) | Or Buy/Sell only if biased |
| LotSequence | `0.01,0.01,0.01,0.02,0.02,0.03,0.04,0.06,0.10` | Covers early steps; extend if MaxOrders is high |
| MaxOrders | `12` | Aggressive; lower on small / netting accounts |
| GridDistance | `400` | Points between grid steps |
| EntryGap | `1.0` | Full step — blocks same-level re-entry |
| AddToDistance / IncreaseDistAfter | `200` / `3` | Wider spacing after order #3 |
| TP_Type | Average (`0`) | Basket VWAP exit |
| TakeProfit | `1000` | Points (basket or individual, per TP_Type) |
| UseStopLoss | `false` | Optional per-ticket SL |
| UseCooldown | `true` | Pause after every entry and close |
| CooldownSeconds | `300` | Seconds |
| MaxDDToHedge | `2000` | Equity DD trigger ($) |
| CloseOnMaxDD | `true` | Close all when MaxDD hit |
| Ranges / time filter | off | Enable when you have a zone or session |

### Netting / equity brokers (important)

On **netting** accounts a second market order at the same level **merges** into one position and **silently doubles volume**. This build guards that by:

- Holding an **in-flight** lock from send until deal/volume confirm (timeout reconciles; does not re-fire aggressively).
- Refusing a new first or grid entry when price is within `GridDistance × EntryGap` of the last fill **or** any open algo position price (`EntryGap` is clamped to `0…1` in code; `1.0` = full step).
- Syncing existing positions at EA start (`RecoverFromOpenPositions`) so pre-start trades are not invisible.
- Estimating netting grid depth from position volume vs `LotSequence` so `MaxOrders` still means something after restart.

Keep **`EntryGap=1.0`**, a sensible **`GridDistance`**, capped **`MaxOrders`**, and **`UseCooldown=true`** on equity/netting brokers. Do **not** run multiple EA instances with the same `MagicNumber` on the same symbol.

## Parameters

Every input below matches the EA (41 inputs in 7 groups). Prefer / example values are starting points for gold — tune on demo.

### [1] Identity & Risk

| Parameter | Preferred / example | Explanation |
| :--- | :--- | :--- |
| **StrategyTag** | `GoldScalper` / `GoldScalp` | Prefix written into each order comment. Always set — helps filter deals in History. |
| **MagicNumber** | `123456` or `999888` (preset) | Unique ID for this EA’s trades. Must be unique per chart/symbol if you run several EAs. |
| **MaxDDToHedge** | `2000` | Equity drawdown in account currency (`Balance − Equity`) that arms protection. Scale with deposit. |
| **CloseOnMaxDD** | `false` (default) / `true` in preset | If true, close all managed positions when MaxDD is hit; if false, only blocks new entries. Turn **on** for live capital protection. |
| **IncludeManualTrade** | `false` | Also manage Magic `0` (manual) positions on this symbol. Turn **on** only if you want the EA to TP/close your manual tickets too. |

### [2] Grid

| Parameter | Preferred / example | Explanation |
| :--- | :--- | :--- |
| **Trade_Direction** | Both / Buy only / Sell only | Allowed side. Use one-sided on strong trends or when hedging is restricted. |
| **LotSequence** | `0.01,0.01,0.01,0.02,…` | Comma-separated lots per grid step (index 0 = first entry). Keep early lots small; length should cover `MaxOrders`. |
| **MaxOrders** | `5` (default) / `12` (preset) | Max grid steps **per side**. Lower on netting/small accounts — each step adds risk (and volume on netting). |
| **GridDistance** | `400`–`500` on XAUUSD | Base spacing between levels, in **points**. Wider = fewer adds. **Netting:** primary same-level shield with EntryGap. |
| **EntryGap** | `1.0` | Fraction of `GridDistance` used as the same-level exclusion zone (`1.0` = full step; code caps above `1.0`). Keep at `1.0` on equity/netting. Use `0.7`–`0.9` only if you need slightly tighter packing and accept more fill risk. |
| **AddToDistance** | `200` | Extra points added to spacing after `IncreaseDistAfter`. Softens deep-grid stacking. |
| **IncreaseDistAfter** | `3` | Order count at which wider spacing starts. Raise if you want uniform spacing longer. |

### [3] Exit

| Parameter | Preferred / example | Explanation |
| :--- | :--- | :--- |
| **TP_Type** | Average (basket) / Individual (scalp) | **Average** = one basket TP from volume-weighted average; **Individual** = each position keeps its own TP from its entry. Switch deliberately — do not mix expectations mid-basket. |
| **TakeProfit** | `1000` basket / `300`–`500` individual | Target distance in **points**. Larger on Average baskets; smaller on Individual. |
| **UseStopLoss** | `false` for many gold grids | Attach a per-position stop on send. Turn **on** when you need a hard per-ticket risk cap. |
| **FixedStopLoss** | `5000` | SL distance in points (only if UseStopLoss). Must clear broker stops/freeze level. |

### [4] Safety

| Parameter | Preferred / example | Explanation |
| :--- | :--- | :--- |
| **UseAutoRisk** | `false` with a fixed `LotSequence` | Clamp lots from equity × RiskPercent and margin room. Turn **on** for tiny accounts that must not send full sequence lots. |
| **RiskPercent** | `0.5` | Max equity % used as margin budget per trade when AutoRisk is on. Keep low; this is a cap, not a target. |
| **UseMarginBuffer** | `false` / `true` on tight accounts | Require free margin ≥ order margin × multiplier. Enable if you see “not enough money” mid-grid. |
| **MarginBufferMultiplier** | `1.5` | Free-margin headroom factor. Higher = safer, fewer deep-grid adds. |
| **UseLowMarginStop** | `false` / `true` live | Block new trades when margin level % is too low. Recommended live if the broker exposes margin level. |
| **LowMarginLevelStop** | `500` | Margin level threshold (%). Broker-dependent. |

### [5] Cooldown & Time

| Parameter | Preferred / example | Explanation |
| :--- | :--- | :--- |
| **UseCooldown** | `true` | Enable pause after **entries and closes**. Leave **on** for live — critical on netting to stop tick races. |
| **CooldownSeconds** | `300` (5 min) | Pause length after an entry or a position-count/volume drop. Shorter (60–120) on demo only; live gold often wants 180–300. |
| **ApplyTimeFilter** | `false` unless you avoid roll/news | Restrict trading to a server-time window. |
| **StartTime** | `08:00` | Window start `HH:MM` (server). |
| **StopTime** | `20:00` | Window end `HH:MM` (server). Supports overnight windows when Start > Stop. |

Cooldown is stamped when: an entry send succeeds, a deal confirms, **or** managed position count/volume drops.

### [6] Ranges

| Parameter | Preferred / example | Explanation |
| :--- | :--- | :--- |
| **UseBuyRange** | `false` until you have a zone | Only allow buys inside the buy band. |
| **BuyStartPrice** / **BuyStopPrice** | e.g. `1900`–`2100` | Lower/upper bounds for buys (order does not matter). |
| **UseSellRange** | `false` by default | Same for sells. |
| **SellStartPrice** / **SellStopPrice** | e.g. `2100`–`1900` | Bounds for sells. |

**First entry / restart:** with open algo positions, the EA recovers grid state and expands/manages — it does not open a brand-new first entry as if the book were empty. The first-entry path also skips if an algo position of that side is already inside the enabled range (`IsWithinRange` passes through when the range filter is off).

### [7] Dashboard

| Parameter | Preferred / example | Explanation |
| :--- | :--- | :--- |
| **DashCorner** | Left upper | Chart corner for the HUD. |
| **DashX** / **DashY** | `10` / `20` | Pixel offsets. Drag the panel live; these are defaults. |
| **DashWidth** / **DashHeight** | `220` / `180` | Panel size. Increase if text clips. |
| **DashColor** | Goldenrod | Accent colour. |
| **AutoTheme** | `true` | Pick light/dark text from chart background. |
| **ShowDashboard** | `true` | Show or hide HUD. Off for clean charts / VPS screenshots. |

## Behaviour notes

- **Same-level duplicates:** in-flight lock + proximity to last fill and every open algo price (`GridDistance × EntryGap`). On netting, volume increase also confirms a fill.
- **Cooldown:** `UseCooldown` toggle; stamped on entry success and on position-count **or** volume drop.
- **TP_Average:** market orders without TP; basket TP updated from VWAP.
- **TP_Individual:** TP (and optional SL) set on each order from its own entry.
- **Hard spread skip:** ticks with symbol spread > 500 points are ignored (not a user input).

## Troubleshooting

| Symptom | What to check |
| :--- | :--- |
| No trades at all | AutoTrading ON; EA allowed to trade; Experts log for init errors. |
| Still no entries | Cooldown active; outside time window; outside buy/sell range; MaxDD breached (`m_dd_breached`); in-flight lock; same-level gap (`EntryGap`); spread > 500. |
| Duplicate / doubled volume (netting) | One EA instance per magic/symbol; keep `EntryGap=1.0` and cooldown on; wait a few seconds after sends for deal confirm. |
| Re-enters after restart | Check Experts log for `Recovered grid state` — counts should match live volume; do not reset magic mid-basket. |
| Basket never closes / weird TP | Confirm `TP_Type`: Average updates one basket TP from VWAP; Individual uses per-ticket TP from entry. |
| Individual exits too tight/wide | Adjust `TakeProfit` in points for that mode — Average and Individual need different distances. |
| Ranges “not working” | `UseBuyRange` / `UseSellRange` must be **true**; bounds use min/max of start/stop so order does not matter. |

## Disclaimer

Trading involves risk of loss. Past results and templates are not guarantees. Test on demo before live.

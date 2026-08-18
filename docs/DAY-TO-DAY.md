# Day-to-day prompts (Grid Scalper + MT5 AI Assistant)

Paste these into the **terminal** AI Assistant unless noted. Ask the assistant to read `MQL5/Files/gs_llm_briefing.txt` first when it exists.

Every answer must start with:

```
REGIME: trend-up | trend-down | range | news-risk
ACTION: RUN_BOTH | BUY_ONLY | SELL_ONLY | PAUSE_NEW_ADDS
RISK: GREEN | AMBER | RED
WHY: <one short paragraph>
GATE: PAUSE=<0|1> DIR=<0|1|2>
```

`GATE` mapping: PAUSE 0=RUN 1=PAUSE; DIR 0=BOTH 1=BUY 2=SELL.

If web access is off, news = `UNKNOWN`. Do not invent events.

---

## 1. Session open

Read `gs_llm_briefing.txt` if present. On XAUUSD, compare H1 and M5. Is this trend-up, trend-down, range, or news-risk? Should Grid Scalper (magic 999888, tag GoldScalp) run BOTH, BUY only, or SELL only? Any high-impact gold/USD news in the next 4 hours? If you cannot access news, say UNKNOWN. End with the required header. Do not place trades.

## 2. Basket review

Only analyze positions with magic 999888 / comment prefix GoldScalp. Report buy count, sell count, lots, floating P/L, drawdown USD and % of MaxDD (2000). Compare those counts to the briefing file. What is the next lot in 0.01,0.01,0.01,0.02,0.02,0.03,0.04,0.06,0.10 vs free margin? Recommend RUN or PAUSE_NEW_ADDS. Do not close positions.

## 3. Spread / session

Current XAUUSD spread vs a 400-point grid distance. Is the spread hostile for scalping? ACTION must be RUN_BOTH or PAUSE_NEW_ADDS. Do not invent a calendar.

## 4. Dual-grid hedge

If both buy and sell GoldScalp baskets are open, report net lots and net P/L. Is one side against the H1 trend? If yes, GATE should pause that side (DIR=1 or 2) rather than closing tickets. If only one side is open, say so and still fill the header.

## 5. Weekend / Friday

If today is not Friday, reply `SKIP: not Friday` plus the header with ACTION=RUN_BOTH unless briefing already says PAUSE. If Friday, should we PAUSE_NEW_ADDS before the weekend close?

## 6. Post-basket (after a close)

Look at the last closed GoldScalp / magic 999888 deals. Was that consistent with RSI/MA dual-zone logic, or an Immediate-mode overtrade? Keep GridDistance 400 or not? Advice only. Do not change inputs yourself.

## 7. MetaEditor (explain only)

Open `GridScalper.mq5`. Explain: (a) first entry Immediate vs Signal, (b) grid expansion, (c) MaxDD fuse, (d) LLM gate. Do not create, patch, or compile files. Do not place trades.

---

After a recommendation, if GATE is not 0/0, run script `LLM_SetGate` on the chart with those PAUSE and DIR values, or click HUD PAUSE/RESUME. The EA must not be stopped.

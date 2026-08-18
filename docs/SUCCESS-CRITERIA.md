# Success criteria — Grid Scalper LLM gate

**PASS** = the EA still executes, the model only coaches, and a human-applied pause/direction gate changes **new risk** without flattening the basket.

Profit vs the original EA is **not** a criterion.

## Must

| ID | Criterion |
|---|---|
| S1 | Compiles with 0 errors (`GridScalper.mq5`, `LLM_SetGate.mq5`) |
| S2 | No `CheckLicense` / `LicenseKey` / `#property strict` |
| S3 | Tester, `Gold_Optimized_Tester.set` (gate off), XAUUSD, has trades |
| S4 | `MQL5/Files/gs_llm_briefing.txt` contains magic + pause |
| S5 | HUD shows `LLM: RUN` or `PAUSE` |
| S6 | Demo Immediate fill, unique magic, Journal retcode success |
| S7 | AI counts match briefing (or 0 if flat) |
| S8 | Prompts include REGIME/ACTION/RISK/GATE |
| S9 | PAUSE=1: HUD PAUSE, no new orders, basket not closed |
| S10 | PAUSE=0 allows new entries again |
| S11 | AI trade confirm/off; no unexpected magic-0 deals |
| S12 | Explain-only prompt does not write files |

## Proven on demo (2026-08-15+, do not regress)

- Magic **999888**, tag **GoldScalp**, briefing file, Common `gs_llm_gate.txt` for live + visual tester.
- Tester does not share live GlobalVariables → HUD PAUSE + `LLM_StartPaused` required.
- Build **6060+** (Journal). Mac About wrapper may still show 5834.
- AI trading permission off/confirm. Human applies GATE.
- Pause/resume cycle: skip grid-add while PAUSE; skips stop on RUN; DIR=SELL blocks buys without closing the buy ladder.
- Note file: Common `gs_llm_note.txt` on **both** write (`LLM_SetGate`) and read (`ReadLlmNote`).

Historical compile logs from the POC session: MetaEditor reported 0 errors / 0 warnings for the then-named `GridScalper_LLM_POC.mq5`. Re-run compile on `GridScalper.mq5` after this rename.

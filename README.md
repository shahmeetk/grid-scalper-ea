# Grid Scalper Pro - Strategy Guide

This Expert Advisor (EA) is a professional Grid Scalping system designed for Gold (XAUUSD). It focuses on "Smart Entry" and "Dynamic Recovery" to consistently profit from market volatility.

## 🚀 Quick Start (Gold/XAUUSD)

1. **Compile the Code**: Open in MetaEditor and press Compile (F7).
2. **Load Preset**: Use `Gold_Optimized.set` in Strategy Tester.
3. **Mode Recommendation**: Use `Immediate` mode for constant action, or `Signal` mode for surgical entries.

---

## 🔧 Parameters Explained

### [1] Identity & Risk

* **StrategyTag**: Your signature. Appears in trade comments (e.g., `GoldScalp B #1`).
* **MaxDDToHedge**: The Safety Fuse. If Floating Loss > $2000, closes everything to save the account.

### [2] Grid Execution

* **StartMode**:
  * `START_IMMEDIATE` (**Recommended**): Ignores RSI/Trend for the *first* trade. Starts working instantly.
  * `START_SIGNAL`: Waits for specific RSI conditions (slower, safer).
* **LotSequence**: The DNA of the strategy. Define your risk steps.
  * *Example*: `0.01, 0.01, 0.02, 0.03...` (Smooth progression).
* **GridDistance**: The "Breathing Room". Distance between orders. 400 points = $4.00 move on Gold.
* **AddToDistance**: Widens the grid as it gets deeper. Useful for surviving big crashes.
* **UseStartPrice**: If enabled, the EA will only start the *first* trade of a basket when the price is at or better than the **TargetStartPrice**.
  * *Buy*: Price must be <= Target.
  * *Sell*: Price must be >= Target.

### [3] Profit & Exit

* **TP_Type**: `AVG` (Basket Close) is best. It closes all trades when the *net* profit target is hit.
* **TakeProfit**: Target in Points.
* **UseTrailing**: Locks in profit.
  * **ProfitToStartTrail**: Once the basket sees $30 profit, trailing kicks in.
* **UseStopLoss**: Enables a fixed Stop Loss (in points) for *every* individual position in the grid. If hit, that specific position closes.

### [4] Entry Filters

* **CooldownSeconds**: "Coffee Break". After a basket closes, the bot waits 5 mins (300s) to avoid buying at the exact top again.

---

## 📈 Understanding Trade Comments & HUD

The EA labels trades clearly to help you track market progression:

* **`GoldScalp BUY #1 (0.01)`**: Initial trade with lot size.
* **`GoldScalp BUY #2 (0.02)`**: Averaging-down trade.
* **`Journal Logs`**: Check the 'Journal' tab for "TP ADJUSTED" messages to see basket management in real-time.
* **`On-Chart HUD`**: The top-left corner shows your active basket profit, total lots, and order counts.

---

## ⚠️ Risk Warning

Grid trading involves risk. While this EA has safety features (`MaxDDToHedge`), always test on Demo first.

* **Recommended Balance**: $5,000+ for 0.01 lots on Gold.
* **Leverage**: 1:500 recommended.

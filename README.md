# Grid Scalper Pro - Strategy Guide

This Expert Advisor (EA) is a professional Grid Scalping system designed for Gold (XAUUSD). It focuses on "Smart Entry" and "Dynamic Recovery" to consistently profit from market volatility.

## 🚀 Quick Start (Gold/XAUUSD)

1. **Compile the Code**: Open in MetaEditor and press Compile (F7).
2. **Load Preset**: Use `Gold_Optimized.set` in Strategy Tester.
3. **Mode Recommendation**: Use `Immediate` mode for constant action, or `Signal` mode for surgical entries.

---

## 🔧 Parameters Explained

### [1] Identity & Risk

| Parameter | Recommended/Example | Description |
| :--- | :--- | :--- |
| **StrategyTag** | "GoldScalper" | The prefix used in trade comments for easy identification. |
| **MagicNumber** | 123456 | A unique ID for the bot to identify its own trades. |
| **MaxDDToHedge** | 2000.0 | Maximum allowed floating loss ($) before protection kicks in. |
| **CloseOnMaxDD** | true | If true, all trades close immediately when MaxDD is reached. |
| **IncludeManualTrade** | false | If true, the EA will also manage trades opened manually (Magic Number 0). |

### [2] Grid Execution

| Parameter | Recommended/Example | Description |
| :--- | :--- | :--- |
| **Trade_Direction** | Both / Buy / Sell | Controls which direction the bot is allowed to trade. |
| **StartMode** | Immediate / Signal | `Immediate` starts a trade instantly; `Signal` waits for RSI/Trend. |
| **LotSequence** | "0.01,0.01,0.02..." | Comma-separated list of lot sizes for each level of the grid. |
| **MaxOrders** | 12 | The maximum number of grid levels allowed per direction. |
| **GridDistance** | 400 | The base distance (in points) between grid orders (400 pts = $4.00 on Gold). |
| **AddToDistance** | 200 | Points added to the distance after a certain number of orders. |
| **IncreaseDistAfter** | 3 | The grid order number after which `AddToDistance` is applied. |

### [3] Profit & Exit (Profit Target & Loss Limit)

| Parameter | Recommended/Example | Description |
| :--- | :--- | :--- |
| **TP_Type** | Average / Individual | `Average` closes the whole basket; `Individual` closes trades one by one. |
| **TakeProfit** | 1000 | **Profit Target** in points. |
| **UseTrailing** | true | Enables the trailing stop logic for the whole basket. |
| **ProfitToStartTrail** | 30.0 | Total basket profit ($) required to activate the Trailing Stop. |
| **TrailStartPoints** | 500 | Distance from price to start the trail (Points). |
| **TrailStepPoints** | 100 | The step size for the trailing stop (Points). |
| **TrailOnlyLast** | true | If true, trailing is only applied to the very last trade in the basket. |
| **UseStopLoss** | false | Enables a **Loss Limit** for every individual trade. |
| **FixedStopLoss** | 5000 | The **Loss Limit** in points from the entry price. |

### [4] Entry Filters

| Parameter | Recommended/Example | Description |
| :--- | :--- | :--- |
| **CooldownSeconds** | 300 | Seconds to wait after a basket closes before starting a new one. |
| **ApplyTimeFilter** | false | Enable/Disable trading only during specific hours. |
| **StartTime** | "08:00" | The server time to start looking for trades. |
| **StopTime** | "20:00" | The server time to stop looking for new trades. |

### [5] Trend & Signal Logic

| Parameter | Recommended/Example | Description |
| :--- | :--- | :--- |
| **UseTrendFilter** | true | Uses an EMA to determine if the trend is Up or Down. |
| **MA_Period** | 50 | The period of the Exponential Moving Average. |
| **RSI_Period** | 14 | The period of the Relative Strength Index. |
| **RSI_Buy_Dip** | 30.0 | Buy Signal: Price is extremely oversold against the trend. |
| **RSI_Buy_Trend** | 45.0 | Buy Signal: Price is slightly oversold during an uptrend. |
| **RSI_Sell_Peak** | 70.0 | Sell Signal: Price is extremely overbought against the trend. |
| **RSI_Sell_Trend** | 55.0 | Sell Signal: Price is slightly overbought during a downtrend. |

### [6] Range Trading Filters

| Parameter | Recommended/Example | Description |
| :--- | :--- | :--- |
| **UseBuyRange** | false | Enable/Disable the price "box" for the Buy direction. |
| **BuyStartPrice** | 1900.0 | The price boundary where Buying/Gridding starts. |
| **BuyStopPrice** | 2100.0 | The price boundary where Buying/Gridding stops. |
| **UseSellRange** | false | Enable/Disable the price "box" for the Sell direction. |
| **SellStartPrice** | 2100.0 | The price boundary where Selling/Gridding starts. |
| **SellStopPrice** | 1900.0 | The price boundary where Selling/Gridding stops. |

---

## 💎 Current Available Features

* ✅ **Dual Directional Grids**: Trade Buy and Sell simultaneously (Hedged) or set a specific bias.
* ✅ **Range Filtering**: Restrict trading to specific price zones to avoid "buying the top" or "selling the bottom".
* ✅ **Profit/Loss Terminology**: Trades close with clear **"Profit"** or **"Loss"** comments in account history.
* ✅ **On-Chart HUD**: Visual dashboard showing real-time **Active Profit**, trade counts, and volume.
* ✅ **Dynamic Spacing**: Grid distances can widen automatically as the basket grows to survive big market runs.
* ✅ **Trend-Aware RSI**: Different logic for opening trades in strong trends vs. ranging markets.
* ✅ **Trailing Safety**: Lock in gains automatically once a basket reaches your profit threshold.
* ✅ **Drawdown Protection**: Emergency "Fuse" that closes all positions if a set dollar loss is hit.
* ✅ **Cooldown Timer**: Prevents the bot from jumping back into a volatile market too quickly after a win.

---

## 📈 Understanding Trade Comments & HUD

The EA labels trades clearly to help you track market progression:

* **`GoldScalp BUY #1 (0.01)`**: Initial trade with lot size.
* **`GoldScalp BUY #2 (0.02)`**: Averaging-down trade.
* **`Journal Logs`**: Check the 'Journal' tab for "Profit Target UPDATED" messages.
* **`On-Chart HUD`**: The top-left corner shows your active basket **Profit**, total lots, and order counts.

---

## ⚠️ Risk Warning

Grid trading involves risk. While this EA has safety features (`MaxDDToHedge`), always test on Demo first.

* **Recommended Balance**: $5,000+ for 0.01 lots on Gold.
* **Leverage**: 1:500 recommended.

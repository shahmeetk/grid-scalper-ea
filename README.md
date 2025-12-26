# Grid Scalper Pro - Strategy Guide

This Expert Advisor (EA) is an advanced Grid Scalping strategy designed for Gold (XAUUSD) and Forex pairs. It uses a combination of RSI for entry timing and Moving Averages (MA) for trend filtering. It manages risk through a dynamic grid system, weighted average take profit, and equity protection.

## Quick Start Configuration (Gold/XAUUSD)

| Parameter | Recommended Value | Description |
| :--- | :--- | :--- |
| **GridDistance** | `500` | Distance in points between grid orders (500 pts = $5 on Gold). |
| **MaxOrders** | `12-15` | Maximum number of layers in the grid. |
| **TakeProfit** | `1000-1500` | Target profit in points. |
| **TradeSizeArrayStr** | `0.01,0.01,0.02...` | Define your Martingale or linear progression here. |
| **StartMode** | `START_IMMEDIATELY` | forces the EA to trade immediately without waiting for RSI/MA. |

---

## Detailed Parameter Explanation

### 1. Strategy Identity

| Parameter | Type | Example | Description |
| :--- | :--- | :--- | :--- |
| **GridName** | `string` | `"Grid_Gold"` | A unique comment for trades to identify this strategy. |
| **MagicNumber** | `long` | `123456` | Unique ID for the EA. Must be different for every chart/EA. |

### 2. Trade Settings

| Parameter | Type | Example | Description |
| :--- | :--- | :--- | :--- |
| **Trade_Direction** | `Drop Down` | `Both Directions` | Allows the EA to trade Buy, Sell, or Both. |
| **TradeSizeArrayStr** | `string` | `"0.01,0.02..."` | Comma-separated list of lot sizes for each grid step. If steps exceed the list, it repeats the last value. |
| **MaxOrders** | `int` | `15` | Hard limit on how many positions can be open per direction. |

### 3. Entry Logic (Crucial)

| Parameter | Type | Example | Description |
| :--- | :--- | :--- | :--- |
| **StartMode** | `Drop Down` | `Signal / Immediate` | **Signal**: Waits for RSI+MA setup. **Immediate**: Opens trade instantly if grid is empty. |
| **ImmediateDir** | `Drop Down` | `Both` | If StartMode is Immediate, which direction to open first. |
| **RSI_Period** | `int` | `14` | Length of RSI indicator. |
| **RSI_BuyLevel** | `double` | `30.0` | **Reversal Buy**: Buy if RSI < 30 (Deep dip). |
| **RSI_SellLevel** | `double` | `70.0` | **Reversal Sell**: Sell if RSI > 70 (Deep rally). |
| **RSI_Trend_Buy** | `double` | `45.0` | **Trend Buy**: Buy if Price > MA AND RSI < 45 (Shallow dip). |
| **RSI_Trend_Sell** | `double` | `55.0` | **Trend Sell**: Sell if Price < MA AND RSI > 55 (Shallow rally). |
| **UseTrendFilter** | `bool` | `true` | Enables the Dual Zone logic above. |
| **CooldownSeconds**| `int` | `300` | Wait time (seconds) after a basket closes before entering again. |

### 4. Grid Management

| Parameter | Type | Example | Description |
| :--- | :--- | :--- | :--- |
| **GridDistance** | `double` | `500` (Points) | The minimum gap between grid orders. |
| **AddToDistance** | `double` | `200` (Points) | Added to `GridDistance` for later orders to widen the grid. |
| **IncreaseDistAfter**| `int` | `5` | After 5 orders, the grid gap becomes `GridDistance + AddToDistance`. |

### 5. Exit & Risk

| Parameter | Type | Example | Description |
| :--- | :--- | :--- | :--- |
| **TP_Type** | `Drop Down` | `Average` | **Average**: Closes all trades at a common price. **Individual**: Each trade has its own TP. |
| **TakeProfit** | `double` | `1000` | Profit target in points. |
| **MaxDDToHedge** | `double` | `2000.0` | Max monetary loss allowed before safety triggers. |
| **CloseOnMaxDD** | `bool` | `true` | If true, CLOSES all trades when MaxDD is reached to save account. |

---

## Troubleshooting "No Trades"

If the EA is not opening trades:

1. **Check `StartMode`**: Set it to `START_IMMEDIATELY` to verify the EA is working.
2. **Check `TimeFilter`**: Ensure `StartTime` and `StopTime` cover the current server time.
3. **Check `TrendFilter`**: If prices are below the 50 EMA, the EA will NOT Buy (in Signal mode). This is a safety feature. Disable `UseTrendFilter` to trade against the trend.

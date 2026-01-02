# 📘 Grid Scalper Pro - User Manual

## 1. Installation Guide

1. **Purchase/Download**: Acquire the EA directly from the **MQL5 Market**.
2. **Open MT5**: Launch your MetaTrader 5 terminal.
3. **Locate EA**: In the **Navigator** panel (Ctrl+N), go to `Market` -> `Experts`. You will find `Grid Scalper Pro` there.
4. **Attach**: Drag and drop the EA onto your desired chart (e.g., XAUUSD M1 or M5).

---

## 2. 🔑 Activation

This Expert Advisor is protected by the **MQL5 Market Activation** system.

* No manual license keys are needed.
* Simply purchase/rent from the Market, and it will automatically activate for your terminal.
* It can be used on any account (Demo or Real) logged into that terminal, subject to MQL5 Market rules.

---

## 3. Using the Pro Dashboard

The dashboard is designed for professional financial monitoring:

* **🖱️ Movable**: **Double-click** the background to select it, then **drag** it to any position on your chart.
* **🎛️ Visibility**: You can show/hide the dashboard via the `ShowDashboard` input parameter.
* **📊 Live Stats**:
  * **Equity Tracking**: Monitor your equity vs balance.
  * **Net Profit**: Real-time floating P/L calculation.
  * **Drawdown %**: See exactly how much your account is at risk.
  * **Buy/Sell Volume**: Track total exposure for each direction.

> **Note**: The dashboard adapts to your chart theme (Light/Dark) automatically!

---

## 4. Recommended Settings (Gold/XAUUSD)

| Parameter | Value | Notes |
| :--- | :--- | :--- |
| **Timeframe** | **M1 or M5** | Shorter timeframes work best for scalping. |
| **Balance** | **$3,000+** | Recommended minimum for 0.01 lots. |
| **GridDistance** | **400** | Distance between orders (400 points = $4.00 price move). |
| **TakeProfit** | **1000** | Profit Target (1000 points = $10.00 price move). |

---

## 5. Troubleshooting

* **"Autotrading Disabled"**: Make sure the "Algo Trading" button in the top toolbar is Green (ON).
* **No Trades Opening**:
    1. Check `StartMode`. If `Signal`, it may be waiting for RSI/Trend conditions.
    2. Check `Times`. Is the market open?
    3. Check `Spread`. Some brokers have high spreads that prevent scalping.

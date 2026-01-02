# 📘 Grid Scalper Pro - User Manual

## 1. Installation Guide

1. **Download**: Save the `grid-scalper.ex5` file to your computer.
2. **Open MT5**: Launch your MetaTrader 5 terminal.
3. **Open Data Folder**: Go to `File` -> `Open Data Folder`.
4. **Install**: Navigate to `MQL5` -> `Experts` and paste the `grid-scalper.ex5` file there.
5. **Refresh**: Right-click on "Expert Advisors" in the Navigator panel (Ctrl+N) and select `Refresh`.

---

## 2. 🔑 Activation (License Key)

When you first drag the EA onto a chart, you will see a settings window. **You MUST enter your License Key here.**

1. **Drag & Drop**: Drag `Grid Scalper Pro` from the Navigator onto a Gold (XAUUSD) chart.
2. **Go to "Inputs" Tab**: Click the `Inputs` tab in the popup window.
3. **Enter Key**:
    * Find the field **`LicenseKey`** (it is the very first option).
    * Value: Enter the key provided to you (e.g., `GSP-100380605`).
    * **Demo Account?**: If you are using a Demo account, enter `GSP-DEMO`.
4. **Click OK**: The EA will verify the key.
    * ✅ **Success**: The **Advanced Pro Dashboard** appears on the chart.
    * ❌ **Error**: You see an alert "LICENSE ERROR". Check your account number or contact support.

---

## 3. Using the Pro Dashboard

The new dashboard is interactive and professional:

* **🖱️ Movable**: You can **click and drag** the dashboard background to any position on your chart.
* **📊 Live Stats**:
  * **Equity Tracking**: Monitor your equity vs balance.
  * **Drawdown %**: See exactly how much your account is at risk.
  * **Spread & RSI**: Keep an eye on market conditions without extra indicators.
* **🔘 Action Buttons**:
  * **CLOSE ALL**: Emergency button to wipe all trades.
  * **CLOSE BUYS / SELLS**: Partial grid exits for manual management.
  * *Note: Confirmation pops up before closing trades.*

> **Note**: This key is locked to your specific Metatrader Account Number. It will not work on other accounts.

---

## 3. Recommended Settings (Gold/XAUUSD)

| Parameter | Value | Notes |
| :--- | :--- | :--- |
| **Timeframe** | **M1 or M5** | Shorter timeframes work best for scalping. |
| **Balance** | **$3,000+** | Recommended minimum for 0.01 lots. |
| **GridDistance** | **400** | Distance between orders (400 points = $4.00 price move). |
| **TakeProfit** | **1000** | Profit Target (1000 points = $10.00 price move). |

---

## 4. Troubleshooting

* **"LICENSE ERROR"**: You forgot to enter the key in the Inputs tab, or you are finding the wrong key. Double-check your Account Number in the top-left of MT5 window.
* **"Autotrading Disabled"**: Make sure the "Algo Trading" button in the top toolbar is Green (ON).
* **No Trades Opening**:
    1. Check `StartMode`. If `Signal`, it may be waiting for RSI.
    2. Check `Times`. Is the market open?
    3. Check `Spread`. Some brokers have high spreads that prevent scalping.

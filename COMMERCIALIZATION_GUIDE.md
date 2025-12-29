# 🚀 Commercialization Guide: Selling "Grid Scalper Pro"

## 1. The "License Key" System (Best for Private Sales)

Since you want to sell privately to multiple users without recompiling the bot every time, we will implement a **License Key System**.

### How it works

1. **The Lock**: We add code to the EA that calculates a "Secret Key" based on the user's Account Number.
2. **The Key**: You give the buyer the `.ex5` file AND their unique Key.
3. **The Check**: When they start the bot, it checks: `Does Key == Secret_Formula(Account_Number)?`
4. **Security**: If they send the file to a friend, it won't work because the friend has a different Account Number (and thus needs a different Key).

### 🛠️ Key Types

1. **Real Money Accounts**:
    * Formula: `GSP-` + AccountNumber
    * Example: Account 500 -> Key `GSP-500`

2. **Demo/Trial Accounts**:
    * **Universal Key**: `GSP-DEMO`
    * **How to use**: Give this key to ANY user who wants to test on a Demo account. It will work on *any* broker's Demo account but *fail* on Real accounts.

### 🛠️ Step 3: Use this Excel Tool

Use Excel (or Google Sheets) to generate keys for your clients instantly:

| A (Client Name) | B (Account Number) | C (License Key Formula) |
| :--- | :--- | :--- |
| John Doe | 500100 | `="GSP-" & B2` |
| Jane Smith | 888222 | `="GSP-" & B3` |

**Action**: When a user pays you:

1. Ask for their MT5 Account Number.
2. Combine it with "GSP-".
3. Send them the EA file + The Key.

---

## 2. Steps to Prepare for Sale

1. **Compile the Final Version**:
    * Open `grid-scalper.mql5` in MetaEditor.
    * **Compile (F7)**.
    * Locate the `grid-scalper.ex5` file (this is the file you sell).
    * *Note*: NEVER sell the `.mq5` (source code) file, or they can steal your strategy.

2. **Create a User Guide PDF**:
    * Convert the `README.md` content into a nice PDF.
    * Add a section on "How to Activate": *"Enter the License Key provided in email into the 'LicenseKey' input field."*

3. **Delivery**:
    * Send a ZIP file containing: `grid-scalper.ex5`, `UserManual.pdf`, and `Gold_Optimized.set`.

---

## 3. Marketing Copy (Copy/Paste this for your Product Page)

**Title**: Grid Scalper Pro - Gold Edition (Hedged & Range Filtered)

**Subtitle**: Advanced Recovery System with Directional Range Filters. Turn Volatility into Profit.

**Product Description**:

**Grid Scalper Pro** is not just another grid bot. It is a professional-grade recovery system designed specifically for the unique volatility of **Gold (XAUUSD)**.

Unlike blind grid systems that blow accounts, Grid Scalper Pro uses a smart **"Dual-Zone Logic"** combined with RSI and Trend Filters to enter only when the probability is in your favor.

### 💎 Key Features

* **⚔️ Dual-Action Hedging**: Profit from both UP and DOWN moves simultaneously with independent Buy/Sell engines.
* **🎯 Range Filters (NEW)**: Define exact "Work Zones". Prevent the bot from buying at the top or selling at the bottom.
* **🛡️ Dynamic Safety**:
  * **Equity Fuse**: Hard drawdown limit protects your balance.
  * **Volatility Spacing**: Grid gaps widen automatically during news spikes.
  * **Smart Trailing**: Locks in basket profits instantly.
* **📊 Professional HUD**: Monitor your Active Profit, Lot Exposure, and Trades directly on the chart.

### ⚙️ How It Works

1. **Smart Entry**: Uses Trend (EMA) + RSI logic to snipe reversals.
2. **Grid Recovery**: If the price moves against you, it averages down using a customized lot sequence.
3. **Basket Exit**: Closes the entire basket (Buy or Sell) at a weighted average "Profit Target".

### 🔧 Parameters

* **Trade_Direction**: Choose `Both` (Hedge), `Buy`, or `Sell`.
* **StartMode**: `Immediate` for constant action, `Signal` for precision.
* **Buy/Sell Ranges**: Set specific price levels (e.g., 2000-2050) to filter trades.

### ⚠️ Recommendations

* **Symbol**: XAUUSD (Gold)
* **Timeframe**: M1 or M5
* **Minimum Balance**: $3,000 (0.01 lots conservative) or $5,000 (Hedged mode).
* **VPS**: Highly Recommended for 24/7 operation.

---

## 4. Strategy for Commercial Success

1. **The "Proof" Signal**:
    * Rent a VPS.
    * Set up Grid Scalper on a **Live Account** (even a small one, $100 cent account).
    * Link it to MQL5 Signals.
    * Run it for 1-2 months.
    * **Why**: Buyers DO NOT trust backtests. They trust live equity curves. A verified signal is the #1 way to get sales.

2. **The Price Point**:
    * **Launch Price**: $49 - $99 (Gain initial users/reviews).
    * **Mature Price**: $149 - $299 (Once you have 5-star reviews + a Signal).
    * **Rentals**: Offer 1-month rental for ~$30 so users can test it easily.

3. **Support**:
    * Reply to comments instantly.
    * Create a Telegram group for users to share settings (e.g., "Range Settings for Today").

4. **Updates**:
    * Release v2.02, v2.03 strictly. "Added Support for NASDAQ", "Improved Dashboard". Frequent updates show the dev is active.

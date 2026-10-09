//+------------------------------------------------------------------+
//|                                           Grid Scalper Pro Plus  |
//|                                  Copyright 2026, Algorithmic Engineer |
//|                             https://www.mql5.com/en/market/product/160364 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Algorithmic Engineer"
#property link      "https://www.mql5.com/en/market/product/160364"
#property version   "2.31"
#property strict

#define EA_VERSION "2.31"

/*
   GRID SCALPER PRO PLUS - VERSION 2.31
   ------------------------------------
   Immediate grid entries. TP_Average = basket exit from VWAP.
   TP_Individual = per-position TP (+ optional FixedStopLoss) from own entry.
   Guards: in-flight lock, same-level proximity (netting+hedging), cooldown,
   startup sync, range-aware first entry.
*/

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

enum ENUM_TP_TYPE {
   TP_AVERAGE,    // Average (Basket Close)
   TP_INDIVIDUAL  // Individual (Scalping)
};

enum ENUM_TRADE_DIR {
   DIR_BOTH,      // Both Directions
   DIR_BUY,       // Only Buy
   DIR_SELL       // Only Sell
};

bool   CheckVolumeValue(double volume, string &description);
bool   IsNewOrderAllowed();
double NewOrderAllowedVolume(string symbol);
void   AdjustToStopLevel(ENUM_POSITION_TYPE type, double entry_price, double &sl, double &tp);
bool   CheckTradeAllowed();
bool   ValidateEnvironment();
double GetLotSize(int index);
double NormalizeLot(double lot);

input group "=== [1] Identity & Risk ==="
input string      StrategyTag                = "GoldScalper";        // Strategy Name (Comment Tag)
input long        MagicNumber                = 123456;               // Unique Magic Number
input double      MaxDDToHedge               = 2000.0;               // Max Drawdown ($) -> Trigger Protection
input bool        CloseOnMaxDD               = false;                // Close All if MaxDD Reached?
input bool        IncludeManualTrade         = false;                // Manage Manual Trades? (Magic 0)

input group "=== [2] Grid ==="
input ENUM_TRADE_DIR Trade_Direction         = DIR_BOTH;             // Allowed Trade Direction
input string      LotSequence                = "0.01,0.01,0.01,0.02,0.02,0.03,0.04,0.06,0.10,0.15,0.25"; // Lot Sequence (Comma Separated)
input int         MaxOrders                  = 5;                    // Max Grid Orders
input double      GridDistance               = 500;                  // Grid Distance (Points)
input double      EntryGap                   = 1.0;                  // Same-Level Gap (x GridDistance, 1.0=full step)
input double      AddToDistance              = 200;                  // Step Increment (Points)
input int         IncreaseDistAfter          = 3;                    // Increase Distance after Order #

input group "=== [3] Exit ==="
input ENUM_TP_TYPE TP_Type                   = TP_AVERAGE;           // Take Profit Logic
input double      TakeProfit                 = 300;                  // Profit Target (Points)
input bool        UseStopLoss                = false;                // Enable Per-Position Stop Loss
input int         FixedStopLoss              = 5000;                 // Stop Loss (Points)

input group "=== [4] Safety ==="
input bool        UseAutoRisk                = false;                // Auto-Scale Lots for Low Equity
input double      RiskPercent                = 0.5;                  // Max risk per trade % of equity
input bool        UseMarginBuffer            = false;                // Enable Free Margin Buffer Check
input double      MarginBufferMultiplier     = 1.5;                  // Required Free Margin Multiplier
input bool        UseLowMarginStop           = false;                // Enable Low Margin Level Stop
input double      LowMarginLevelStop         = 500.0;                // Stop Trading if Margin Level < X%

input group "=== [5] Cooldown & Time ==="
input bool        UseCooldown                = true;                 // Enable Cooldown After Entry/Close
input int         CooldownSeconds            = 300;                  // Cooldown Seconds
input bool        ApplyTimeFilter            = false;                // Enable Time Filter
input string      StartTime                  = "08:00";              // Start Time (Server)
input string      StopTime                   = "20:00";              // Stop Time (Server)

input group "=== [6] Ranges ==="
input bool        UseBuyRange                = false;                // Enable Buy Price Range?
input double      BuyStartPrice              = 1900.0;               // Buy: Start Price (Lower Bound)
input double      BuyStopPrice               = 2100.0;               // Buy: Stop Price (Upper Bound)
input bool        UseSellRange               = false;                // Enable Sell Price Range?
input double      SellStartPrice             = 2100.0;               // Sell: Start Price (Upper Bound)
input double      SellStopPrice              = 1900.0;               // Sell: Stop Price (Lower Bound)

input group "=== [7] Dashboard ==="
input ENUM_BASE_CORNER DashCorner             = CORNER_LEFT_UPPER;    // Dashboard Corner
input int         DashX                      = 10;                   // Dashboard X Offset
input int         DashY                      = 20;                   // Dashboard Y Offset
input int         DashWidth                  = 220;                  // Dashboard Width
input int         DashHeight                 = 180;                  // Dashboard Height
input color       DashColor                  = clrGoldenrod;         // Theme Color
input bool        AutoTheme                  = true;                 // Auto-detect Light/Dark Theme?
input bool        ShowDashboard              = true;                 // Show/Hide Dashboard

CTrade         m_trade;
CSymbolInfo    m_symbol;
CPositionInfo  m_position;
CAccountInfo   m_account;

double         m_lot_array[];
bool           m_dd_breached = false;
datetime       m_last_action_time = 0;
int            g_dash_x = -1;
int            g_dash_y = -1;

double         m_last_buy_price = 0;
double         m_last_sell_price = 0;
int            m_buy_count = 0;
int            m_sell_count = 0;
int            m_prev_my_positions = 0;
double         m_prev_my_volume = 0;

bool           m_order_inflight = false;
ulong          m_inflight_until = 0;
ENUM_POSITION_TYPE m_inflight_type = POSITION_TYPE_BUY;
double         m_inflight_price = 0;
double         m_inflight_vol_snap = 0;
int            m_inflight_extensions = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   if(!m_symbol.Name(Symbol())) {
      Print("CRITICAL: Failed to initialize symbol info.");
      return(INIT_FAILED);
   }
   RefreshRates();

   if(!ParseLotString(LotSequence, m_lot_array)) {
      Print("CRITICAL ERROR: Invalid LotSequence format.");
      return(INIT_PARAMETERS_INCORRECT);
   }

   m_trade.SetExpertMagicNumber(MagicNumber);
   m_trade.SetMarginMode();
   m_trade.SetDeviationInPoints(10);

   RecoverFromOpenPositions();
   m_prev_my_positions = CountMyPositions();
   m_prev_my_volume = MyTotalVolume();

   PrintFormat("Grid Scalper v%s Initialized. Magic: %d  Netting: %s",
               EA_VERSION, MagicNumber, IsNettingMode() ? "yes" : "no");

   if(!ValidateEnvironment()) return(INIT_FAILED);

   UpdateDashboard();
   ChartRedraw();
   return(INIT_SUCCEEDED);
}

bool ValidateEnvironment() {
   if(m_symbol.LotsMin() <= 0) { Print("Error: Symbol Min Lot is 0"); return false; }
   if(SymbolInfoInteger(Symbol(), SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_DISABLED) { Print("Error: Trading Disabled"); return false; }
   return true;
}

void OnDeinit(const int reason)
{
   CleanDashboard();
}

void OnTick()
{
   if(!RefreshRates()) return;

   int max_spread = (int)SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
   if(max_spread > 500) return;

   ReconcileInflight();
   DetectClosedPositions();
   CheckEquityProtection();

   ManageDirection(POSITION_TYPE_BUY);
   ManageDirection(POSITION_TYPE_SELL);

   if(CountMyPositions() == 0 && !m_order_inflight) {
      if(m_buy_count > 0 || m_sell_count > 0) {
         if(!MQLInfoInteger(MQL_TESTER)) Print("Grid Reset: No positions detected.");
         m_buy_count = 0;
         m_sell_count = 0;
         m_last_buy_price = 0;
         m_last_sell_price = 0;
      }
   }

   UpdateDashboard();
}

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD) {
      if(trans.symbol != Symbol()) return;
      if(!HistoryDealSelect(trans.deal)) return;
      if((long)HistoryDealGetInteger(trans.deal, DEAL_MAGIC) != MagicNumber) return;

      ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
      if(entry == DEAL_ENTRY_IN || entry == DEAL_ENTRY_INOUT) {
         ClearInflight();
         StampAction();
         ENUM_DEAL_TYPE dtype = (ENUM_DEAL_TYPE)HistoryDealGetInteger(trans.deal, DEAL_TYPE);
         double dprice = HistoryDealGetDouble(trans.deal, DEAL_PRICE);
         if(dtype == DEAL_TYPE_BUY) {
            m_last_buy_price = dprice;
            if(IsNettingMode()) {
               if(m_buy_count < 1) m_buy_count = 1;
            } else {
               m_buy_count = CountPositions(POSITION_TYPE_BUY);
            }
         } else if(dtype == DEAL_TYPE_SELL) {
            m_last_sell_price = dprice;
            if(IsNettingMode()) {
               if(m_sell_count < 1) m_sell_count = 1;
            } else {
               m_sell_count = CountPositions(POSITION_TYPE_SELL);
            }
         }
         m_prev_my_volume = MyTotalVolume();
         m_prev_my_positions = CountMyPositions();
      }
      if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_OUT_BY || entry == DEAL_ENTRY_INOUT) {
         StampAction();
         SyncGridFromPositions(POSITION_TYPE_BUY);
         SyncGridFromPositions(POSITION_TYPE_SELL);
         m_prev_my_volume = MyTotalVolume();
         m_prev_my_positions = CountMyPositions();
      }
   }

   if(trans.type == TRADE_TRANSACTION_REQUEST) {
      if(result.retcode != TRADE_RETCODE_DONE &&
         result.retcode != TRADE_RETCODE_PLACED &&
         result.retcode != TRADE_RETCODE_DONE_PARTIAL) {
         ClearInflight();
      }
   }
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   string prefix = "GSP_HUD_";
   if(id == CHARTEVENT_OBJECT_DRAG) {
      if(sparam == prefix + "BG") UpdateDashboard();
   }
}

//+------------------------------------------------------------------+
void ManageDirection(ENUM_POSITION_TYPE type)
{
   SyncGridFromPositions(type);
   int count = CountPositions(type);
   int tracked = (type == POSITION_TYPE_BUY) ? m_buy_count : m_sell_count;

   if(count == 0) {
      if(m_dd_breached || !IsTradingTime()) return;
      if(!DirectionAllowed(type)) return;
      if(IsInCooldown()) return;
      if(IsOrderBlocked(type)) return;

      double price = (type == POSITION_TYPE_BUY) ? m_symbol.Ask() : m_symbol.Bid();
      if(!IsWithinRange(type, price)) return;
      if(HasAlgoPositionInRange(type)) return;

      OpenTrade(type, 0);
   }
   else {
      if(tracked == 0) SyncGridFromPositions(type);
      tracked = (type == POSITION_TYPE_BUY) ? m_buy_count : m_sell_count;

      if(!m_dd_breached && tracked < MaxOrders) {
         if(!IsInCooldown() && !IsOrderBlocked(type))
            CheckGridExpansion(type, tracked);
      }

      if(TP_Type == TP_AVERAGE) UpdateAverageTP(type);
   }
}

bool DirectionAllowed(ENUM_POSITION_TYPE type)
{
   if(type == POSITION_TYPE_BUY)  return (Trade_Direction == DIR_BUY  || Trade_Direction == DIR_BOTH);
   if(type == POSITION_TYPE_SELL) return (Trade_Direction == DIR_SELL || Trade_Direction == DIR_BOTH);
   return false;
}

bool IsInCooldown()
{
   if(!UseCooldown || CooldownSeconds <= 0) return false;
   return (TimeCurrent() - m_last_action_time < CooldownSeconds);
}

void StampAction()
{
   m_last_action_time = TimeCurrent();
}

bool IsNettingMode()
{
   ENUM_ACCOUNT_MARGIN_MODE mode = (ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
   return (mode != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
}

double SameLevelGap()
{
   double gap_mult = EntryGap;
   if(gap_mult <= 0.0) gap_mult = 1.0;
   if(gap_mult > 1.0) gap_mult = 1.0;
   return GridDistance * gap_mult * m_symbol.Point();
}

double MyTotalVolume()
{
   double vol = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i) && IsMyPosition())
         vol += m_position.Volume();
   }
   return vol;
}

double MyVolume(ENUM_POSITION_TYPE type)
{
   double vol = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!m_position.SelectByIndex(i) || !IsMyPosition()) continue;
      if(m_position.PositionType() == type) vol += m_position.Volume();
   }
   return vol;
}

int EstimateLevelsFromVolume(double volume)
{
   if(volume <= 0) return 0;
   int n = ArraySize(m_lot_array);
   if(n <= 0) return 1;

   double sum = 0;
   int levels = 0;
   for(int i = 0; i < MaxOrders; i++) {
      double lot = (i < n) ? m_lot_array[i] : m_lot_array[n - 1];
      sum += NormalizeLot(lot);
      levels++;
      if(sum + 1e-8 >= volume) break;
   }
   return MathMax(levels, 1);
}

bool HasPendingOurs()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) != Symbol()) continue;
      if((long)OrderGetInteger(ORDER_MAGIC) != MagicNumber) continue;
      return true;
   }
   return false;
}

bool RecentDealNear(ENUM_POSITION_TYPE type, double price, double gap)
{
   datetime from = TimeCurrent() - 30;
   if(!HistorySelect(from, TimeCurrent() + 1)) return false;

   ENUM_DEAL_TYPE want = (type == POSITION_TYPE_BUY) ? DEAL_TYPE_BUY : DEAL_TYPE_SELL;
   int total = HistoryDealsTotal();
   for(int i = total - 1; i >= 0; i--) {
      ulong deal = HistoryDealGetTicket(i);
      if(deal == 0) continue;
      if(HistoryDealGetString(deal, DEAL_SYMBOL) != Symbol()) continue;
      if((long)HistoryDealGetInteger(deal, DEAL_MAGIC) != MagicNumber) continue;
      ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_IN && entry != DEAL_ENTRY_INOUT) continue;
      if((ENUM_DEAL_TYPE)HistoryDealGetInteger(deal, DEAL_TYPE) != want) continue;
      double dprice = HistoryDealGetDouble(deal, DEAL_PRICE);
      if(MathAbs(dprice - price) <= gap + m_symbol.Point()) return true;
   }
   return false;
}

bool IsNearPrice(double a, double b, double gap)
{
   if(a <= 0 || b <= 0) return false;
   return (MathAbs(a - b) < gap);
}

bool HasPositionNearPrice(ENUM_POSITION_TYPE type, double price, double gap)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!m_position.SelectByIndex(i) || !IsMyPosition()) continue;
      if(m_position.PositionType() != type) continue;
      if(IsNearPrice(m_position.PriceOpen(), price, gap)) return true;
   }
   return false;
}

bool IsSameLevelBlocked(ENUM_POSITION_TYPE type, double price)
{
   double gap = SameLevelGap();
   if(gap <= 0) return false;

   if(m_order_inflight && m_inflight_type == type && IsNearPrice(m_inflight_price, price, gap))
      return true;

   double last = (type == POSITION_TYPE_BUY) ? m_last_buy_price : m_last_sell_price;
   if(IsNearPrice(last, price, gap)) return true;

   if(HasPositionNearPrice(type, price, gap)) return true;
   return false;
}

void ClearInflight()
{
   m_order_inflight = false;
   m_inflight_until = 0;
   m_inflight_price = 0;
   m_inflight_vol_snap = 0;
   m_inflight_extensions = 0;
}

void ArmInflight(ENUM_POSITION_TYPE type, double price)
{
   m_order_inflight = true;
   m_inflight_type = type;
   m_inflight_price = price;
   m_inflight_vol_snap = MyVolume(type);
   m_inflight_extensions = 0;
   m_inflight_until = GetTickCount64() + 5000;
}

void ReconcileInflight()
{
   if(!m_order_inflight) return;

   ENUM_POSITION_TYPE type = m_inflight_type;
   double gap = SameLevelGap();
   bool filled = false;

   if(MyVolume(type) > m_inflight_vol_snap + 1e-8)
      filled = true;
   else if(HasPositionNearPrice(type, m_inflight_price, gap))
      filled = true;
   else if(RecentDealNear(type, m_inflight_price, gap))
      filled = true;

   if(filled) {
      ClearInflight();
      SyncGridFromPositions(type);
      StampAction();
      m_prev_my_volume = MyTotalVolume();
      m_prev_my_positions = CountMyPositions();
      return;
   }

   if(GetTickCount64() <= m_inflight_until) return;

   if(HasPendingOurs() && m_inflight_extensions < 3) {
      m_inflight_extensions++;
      m_inflight_until = GetTickCount64() + 5000;
      return;
   }

   // Ambiguous timeout: hold briefly and re-sync before allowing another send.
   if(m_inflight_extensions < 1) {
      m_inflight_extensions++;
      m_inflight_until = GetTickCount64() + 3000;
      SyncGridFromPositions(POSITION_TYPE_BUY);
      SyncGridFromPositions(POSITION_TYPE_SELL);
      return;
   }

   ClearInflight();
}

bool IsOrderBlocked(ENUM_POSITION_TYPE type)
{
   ReconcileInflight();
   if(m_order_inflight && m_inflight_type == type) return true;

   double price = (type == POSITION_TYPE_BUY) ? m_symbol.Ask() : m_symbol.Bid();
   return IsSameLevelBlocked(type, price);
}

void DetectClosedPositions()
{
   int now = CountMyPositions();
   double vol = MyTotalVolume();
   if(now < m_prev_my_positions || vol + 1e-8 < m_prev_my_volume)
      StampAction();
   m_prev_my_positions = now;
   m_prev_my_volume = vol;
}

int CountMyPositions()
{
   int cnt = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i) && IsMyPosition()) cnt++;
   }
   return cnt;
}

bool HasAlgoPositionInRange(ENUM_POSITION_TYPE type)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!m_position.SelectByIndex(i) || !IsMyPosition()) continue;
      if(m_position.PositionType() != type) continue;
      if(IsWithinRange(type, m_position.PriceOpen()))
         return true;
   }
   return false;
}

void RecoverFromOpenPositions()
{
   SyncGridFromPositions(POSITION_TYPE_BUY);
   SyncGridFromPositions(POSITION_TYPE_SELL);

   if(IsNettingMode()) {
      double buy_vol = MyVolume(POSITION_TYPE_BUY);
      double sell_vol = MyVolume(POSITION_TYPE_SELL);
      if(buy_vol > 0)
         m_buy_count = MathMax(m_buy_count, EstimateLevelsFromVolume(buy_vol));
      if(sell_vol > 0)
         m_sell_count = MathMax(m_sell_count, EstimateLevelsFromVolume(sell_vol));
   }

   if(!MQLInfoInteger(MQL_TESTER) && (m_buy_count > 0 || m_sell_count > 0)) {
      PrintFormat("Recovered grid state: Buy=%d @ %.5f | Sell=%d @ %.5f",
                  m_buy_count, m_last_buy_price, m_sell_count, m_last_sell_price);
   }
}

void SyncGridFromPositions(ENUM_POSITION_TYPE type)
{
   int count = 0;
   double worst = 0;
   bool found = false;

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!m_position.SelectByIndex(i) || !IsMyPosition()) continue;
      if(m_position.PositionType() != type) continue;
      count++;
      double p = m_position.PriceOpen();
      if(!found) { worst = p; found = true; }
      else if(type == POSITION_TYPE_BUY && p < worst) worst = p;
      else if(type == POSITION_TYPE_SELL && p > worst) worst = p;
   }

   bool inflight_here = (m_order_inflight && m_inflight_type == type);

   if(type == POSITION_TYPE_BUY) {
      if(found) {
         if(IsNettingMode()) {
            if(m_buy_count < 1) m_buy_count = 1;
         } else {
            m_buy_count = count;
         }
         // Prefer last fill; only seed from open if unknown.
         if(m_last_buy_price <= 0) m_last_buy_price = worst;
         else if(!IsNettingMode()) m_last_buy_price = worst;
      } else if(!inflight_here) {
         m_buy_count = 0;
         m_last_buy_price = 0;
      }
   } else {
      if(found) {
         if(IsNettingMode()) {
            if(m_sell_count < 1) m_sell_count = 1;
         } else {
            m_sell_count = count;
         }
         if(m_last_sell_price <= 0) m_last_sell_price = worst;
         else if(!IsNettingMode()) m_last_sell_price = worst;
      } else if(!inflight_here) {
         m_sell_count = 0;
         m_last_sell_price = 0;
      }
   }
}

void BuildStops(ENUM_POSITION_TYPE type, double price, double &sl, double &tp)
{
   sl = 0;
   tp = 0;
   double point = m_symbol.Point();

   if(type == POSITION_TYPE_BUY) {
      if(TP_Type == TP_INDIVIDUAL) tp = price + TakeProfit * point;
      if(UseStopLoss) sl = price - FixedStopLoss * point;
   } else {
      if(TP_Type == TP_INDIVIDUAL) tp = price - TakeProfit * point;
      if(UseStopLoss) sl = price + FixedStopLoss * point;
   }

   AdjustToStopLevel(type, price, sl, tp);
   if(sl != 0) sl = NormalizeDouble(sl, m_symbol.Digits());
   if(tp != 0) tp = NormalizeDouble(tp, m_symbol.Digits());
}

void OpenTrade(ENUM_POSITION_TYPE type, int index)
{
   if(!CheckTradeAllowed()) return;
   if(!IsNewOrderAllowed()) return;
   if(IsOrderBlocked(type)) return;

   double lot = NormalizeLot(GetLotSize(index));
   string vol_err = "";
   if(!CheckVolumeValue(lot, vol_err)) {
      Print("Validation Error: Invalid Volume: ", vol_err);
      return;
   }

   double price = (type == POSITION_TYPE_BUY) ? m_symbol.Ask() : m_symbol.Bid();
   if(IsSameLevelBlocked(type, price)) return;

   double sl = 0, tp = 0;
   BuildStops(type, price, sl, tp);

   if(!CheckMoneyForTrade(lot, type)) return;

   ArmInflight(type, price);
   price = (type == POSITION_TYPE_BUY) ? m_symbol.Ask() : m_symbol.Bid();

   double send_sl = UseStopLoss ? sl : 0;
   double send_tp = (TP_Type == TP_INDIVIDUAL) ? tp : 0;

   string typeStr = (type == POSITION_TYPE_BUY) ? "BUY" : "SELL";
   string comment = StringFormat("%s %s #%d (%.2f)", StrategyTag, typeStr, index + 1, lot);

   bool ok = false;
   if(type == POSITION_TYPE_BUY)
      ok = m_trade.Buy(lot, Symbol(), price, send_sl, send_tp, comment);
   else
      ok = m_trade.Sell(lot, Symbol(), price, send_sl, send_tp, comment);

   if(ok) {
      StampAction();
      if(type == POSITION_TYPE_BUY) {
         m_buy_count = MathMax(m_buy_count + 1, index + 1);
         m_last_buy_price = price;
      } else {
         m_sell_count = MathMax(m_sell_count + 1, index + 1);
         m_last_sell_price = price;
      }
      if(MQLInfoInteger(MQL_TESTER)) Sleep(100);
   } else {
      ClearInflight();
   }
}

void CheckGridExpansion(ENUM_POSITION_TYPE type, int current_count)
{
   double worst_price = (type == POSITION_TYPE_BUY) ? m_last_buy_price : m_last_sell_price;
   if(worst_price == 0) return;

   double required_dist = GridDistance;
   if(current_count >= IncreaseDistAfter)
      required_dist += AddToDistance;

   bool trigger = false;
   if(type == POSITION_TYPE_BUY) {
      if(m_symbol.Ask() <= worst_price - required_dist * m_symbol.Point()) trigger = true;
   } else {
      if(m_symbol.Bid() >= worst_price + required_dist * m_symbol.Point()) trigger = true;
   }
   if(!trigger) return;

   double price = (type == POSITION_TYPE_BUY) ? m_symbol.Ask() : m_symbol.Bid();
   if(!IsWithinRange(type, price)) return;
   if(IsSameLevelBlocked(type, price)) return;
   if(!CheckTradeAllowed()) return;

   OpenTrade(type, current_count);
}

void UpdateAverageTP(ENUM_POSITION_TYPE type)
{
   double sum_prod = 0;
   double sum_vol = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i)) {
         if(IsMyPosition() && m_position.PositionType() == type) {
            sum_prod += m_position.PriceOpen() * m_position.Volume();
            sum_vol += m_position.Volume();
         }
      }
   }
   if(sum_vol == 0) return;

   double avg_price = sum_prod / sum_vol;
   double new_tp = (type == POSITION_TYPE_BUY)
                   ? avg_price + TakeProfit * m_symbol.Point()
                   : avg_price - TakeProfit * m_symbol.Point();
   new_tp = NormalizeDouble(new_tp, m_symbol.Digits());

   double freeze_buffer = (double)MathMax(SymbolInfoInteger(Symbol(), SYMBOL_TRADE_FREEZE_LEVEL),
                                          SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL)) + 20.0;
   double freeze = freeze_buffer * m_symbol.Point();
   double current_price = (type == POSITION_TYPE_BUY) ? m_symbol.Bid() : m_symbol.Ask();

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!m_position.SelectByIndex(i)) continue;
      if(!IsMyPosition() || m_position.PositionType() != type) continue;

      if(type == POSITION_TYPE_BUY) {
         if(current_price >= new_tp - m_symbol.Point()) continue;
      } else {
         if(current_price <= new_tp + m_symbol.Point()) continue;
      }

      if(MathAbs(current_price - new_tp) < freeze) continue;

      if(MathAbs(m_position.TakeProfit() - new_tp) > m_symbol.Point() * 2) {
         if(m_trade.PositionModify(m_position.Ticket(), m_position.StopLoss(), new_tp)) {
            static datetime last_tp_print = 0;
            if(TimeCurrent() - last_tp_print > 3600) {
               PrintFormat("Average TP Set: %s #%I64u to %.2f",
                           (type == POSITION_TYPE_BUY ? "BUY" : "SELL"),
                           m_position.Ticket(), new_tp);
               last_tp_print = TimeCurrent();
            }
         }
      }
   }
}

void CheckEquityProtection()
{
   double current_dd = m_account.Balance() - m_account.Equity();
   if(current_dd > MaxDDToHedge) {
      if(!m_dd_breached) PrintFormat("Max Drawdown Reached! Current DD: %.2f", current_dd);
      if(CloseOnMaxDD) {
         Print("Emergency Protection: Closing ALL Positions.");
         CloseAll();
      }
      m_dd_breached = true;
   } else {
      m_dd_breached = false;
   }
}

double NormalizeLot(double lot)
{
   double min_lot = m_symbol.LotsMin();
   double max_lot = m_symbol.LotsMax();
   double step_lot = m_symbol.LotsStep();
   if(step_lot <= 0) return lot;

   double steps = MathRound(lot / step_lot);
   double norm_lot = steps * step_lot;
   if(norm_lot < min_lot) norm_lot = min_lot;
   if(norm_lot > max_lot) norm_lot = max_lot;
   return NormalizeDouble(norm_lot, 2);
}

void AdjustToStopLevel(ENUM_POSITION_TYPE type, double entry_price, double &sl, double &tp)
{
   int stop_level = (int)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
   int freeze_level = (int)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_FREEZE_LEVEL);
   int spread = (int)SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
   double min_dist = (MathMax(stop_level, freeze_level) + spread + 10) * m_symbol.Point();

   if(type == POSITION_TYPE_BUY) {
      if(sl != 0 && (entry_price - sl) < min_dist) sl = entry_price - min_dist;
      if(tp != 0 && (tp - entry_price) < min_dist) tp = entry_price + min_dist;
   } else {
      if(sl != 0 && (sl - entry_price) < min_dist) sl = entry_price + min_dist;
      if(tp != 0 && (entry_price - tp) < min_dist) tp = entry_price - min_dist;
   }
}

bool CheckMoneyForTrade(double lot, ENUM_POSITION_TYPE type)
{
   double margin = 0;
   ENUM_ORDER_TYPE order_type = (type == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   if(!OrderCalcMargin(order_type, _Symbol, lot, m_symbol.Ask(), margin)) return false;

   if(UseMarginBuffer) {
      if(margin * MarginBufferMultiplier > m_account.FreeMargin()) {
         PrintFormat("MARGIN SAFETY: Lot %.2f requires %.2f margin (Safety %.1fx Required), Free: %.2f",
                     lot, margin, MarginBufferMultiplier, m_account.FreeMargin());
         return false;
      }
   }

   if(UseLowMarginStop) {
      if(m_account.MarginLevel() > 0 && m_account.MarginLevel() < LowMarginLevelStop) {
         PrintFormat("CRITICAL: Margin Level Too Low (%.2f%% < %.2f%%). Skipping Trade.",
                     m_account.MarginLevel(), LowMarginLevelStop);
         return false;
      }
   }
   return true;
}

bool CheckTradeAllowed()
{
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) return false;
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) return false;
   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)) return false;
   if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT)) return false;
   return true;
}

bool IsMyPosition()
{
   if(m_position.Symbol() != Symbol()) return false;
   if(m_position.Magic() == MagicNumber) return true;
   if(IncludeManualTrade && m_position.Magic() == 0) return true;
   return false;
}

bool CheckVolumeValue(double volume, string &description)
{
   double min_volume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double max_volume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   double volume_step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);

   if(volume < min_volume) {
      description = StringFormat("Volume %.2f < Min %.2f", volume, min_volume);
      return false;
   }
   if(volume > max_volume) {
      description = StringFormat("Volume %.2f > Max %.2f", volume, max_volume);
      return false;
   }
   if(volume_step > 0) {
      int ratio = (int)MathRound(volume / volume_step);
      if(MathAbs(ratio * volume_step - volume) > 0.0000001) {
         description = "Volume not Step Aligned";
         return false;
      }
   }
   return true;
}

bool IsNewOrderAllowed()
{
   int max_allowed_orders = (int)AccountInfoInteger(ACCOUNT_LIMIT_ORDERS);
   if(max_allowed_orders == 0) return true;
   return (OrdersTotal() < max_allowed_orders);
}

double NewOrderAllowedVolume(string symbol)
{
   double symbol_max_volume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double max_volume_limit = SymbolInfoDouble(symbol, SYMBOL_VOLUME_LIMIT);
   if(max_volume_limit == 0) return symbol_max_volume;

   double opened_volume = 0;
   int total = PositionsTotal();
   for(int i = 0; i < total; i++) {
      if(m_position.SelectByIndex(i) && m_position.Symbol() == symbol)
         opened_volume += m_position.Volume();
   }
   double allowed = max_volume_limit - opened_volume;
   if(allowed < 0) allowed = 0;
   return MathMin(allowed, symbol_max_volume);
}

int CountPositions(ENUM_POSITION_TYPE type)
{
   int cnt = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i) && IsMyPosition() && m_position.PositionType() == type) cnt++;
   }
   return cnt;
}

bool IsWithinRange(ENUM_POSITION_TYPE type, double price)
{
   if(type == POSITION_TYPE_BUY && UseBuyRange) {
      double min_p = MathMin(BuyStartPrice, BuyStopPrice);
      double max_p = MathMax(BuyStartPrice, BuyStopPrice);
      if(price < min_p || price > max_p) return false;
   }
   if(type == POSITION_TYPE_SELL && UseSellRange) {
      double min_p = MathMin(SellStartPrice, SellStopPrice);
      double max_p = MathMax(SellStartPrice, SellStopPrice);
      if(price < min_p || price > max_p) return false;
   }
   return true;
}

void UpdateDashboard()
{
   if(!ShowDashboard) {
      CleanDashboard();
      return;
   }

   string prefix = "GSP_HUD_";
   if(g_dash_x == -1) { g_dash_x = DashX; g_dash_y = DashY; }

   if(ObjectFind(0, prefix + "BG") >= 0) {
      g_dash_x = (int)ObjectGetInteger(0, prefix + "BG", OBJPROP_XDISTANCE);
      g_dash_y = (int)ObjectGetInteger(0, prefix + "BG", OBJPROP_YDISTANCE);
   }

   int x_base = g_dash_x;
   int y_base = g_dash_y;
   int x_label = x_base + 12;
   int y_row = y_base + 45;
   int y_step = 26;

   double pBuy = 0, pSell = 0, volBuy = 0, volSell = 0;
   int cBuy = CountPositions(POSITION_TYPE_BUY);
   int cSell = CountPositions(POSITION_TYPE_SELL);

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i) && IsMyPosition()) {
         double profit = m_position.Profit() + m_position.Swap() + m_position.Commission();
         if(m_position.PositionType() == POSITION_TYPE_BUY) { pBuy += profit; volBuy += m_position.Volume(); }
         else { pSell += profit; volSell += m_position.Volume(); }
      }
   }

   double total_profit = pBuy + pSell;
   double equity = m_account.Equity();
   double balance = m_account.Balance();
   double dd_val = (balance > equity) ? (balance - equity) : 0;
   double dd_pct = (balance > 0) ? (dd_val / balance * 100.0) : 0;

   color bg_color = C'15,15,15';
   color hdr_color = C'30,30,30';
   color text_main = clrWhite;
   color text_dim = clrSilver;

   if(AutoTheme) {
      color chart_bg = (color)ChartGetInteger(0, CHART_COLOR_BACKGROUND);
      if(chart_bg == clrWhite || chart_bg == clrLightGray || chart_bg == clrSilver) {
         bg_color = C'245,245,245';
         hdr_color = C'220,220,220';
         text_main = clrBlack;
         text_dim = clrDarkGray;
      }
   }

   CreateRectLabel(prefix + "BG", x_base, y_base, DashWidth, DashHeight, bg_color, DashColor, 200);
   CreateRectLabel(prefix + "HDR", x_base, y_base, DashWidth, 32, hdr_color, DashColor, 255);

   string tag_upper = StrategyTag;
   StringToUpper(tag_upper);
   CreateLabel(prefix + "Title", StringFormat("%s SCALPER", tag_upper), x_base + 10, y_base + 8, DashColor, 9, true);

   string login_str = (m_account.Login() > 0) ? IntegerToString(m_account.Login()) : IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
   CreateLabel(prefix + "Acc", StringFormat("TERMINAL ID: %s (%s)", login_str, (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_DEMO ? "DEMO" : "LIVE")), x_label, y_row, text_dim, 9);
   y_row += y_step;

   CreateLabel(prefix + "Equity", StringFormat("EQUITY: $%.2f", equity), x_label, y_row, text_main, 9);
   y_row += y_step;

   CreateLabel(prefix + "DD", StringFormat("DRAWDOWN: $%.2f (%0.2f%%)", dd_val, dd_pct), x_label, y_row, (dd_pct > 3 ? clrOrange : text_main), 9);
   y_row += y_step;

   CreateLabel(prefix + "Prof", StringFormat("NET PROFIT: $%.2f", total_profit), x_label, y_row, (total_profit >= 0 ? clrLime : clrRed), 9, true);
   y_row += y_step;

   CreateRectLabel(prefix + "FTR", x_label - 2, y_row - 4, DashWidth - 20, 1, text_dim, text_dim, 100);
   y_row += 12;

   CreateLabel(prefix + "Stats", StringFormat("BUY: %d (%.2fL) | SELL: %d (%.2fL)", cBuy, volBuy, cSell, volSell), x_label, y_row, (AutoTheme && text_main == clrBlack ? clrBlue : clrSkyBlue), 9);
   y_row += y_step;

   if(m_dd_breached) {
      CreateLabel(prefix + "Warn", "CRITICAL PROTECTION ACTIVE", x_base + (DashWidth / 2), y_base + DashHeight - 15, clrRed, 9, true, ANCHOR_LOWER);
   }

   ChartRedraw();
}

void CreateLabel(string name, string text, int x, int y, color c, int size = 9, bool bold = false, ENUM_ANCHOR_POINT anchor = ANCHOR_LEFT_UPPER)
{
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, DashCorner);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
   }
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, c);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetString(0, name, OBJPROP_FONT, bold ? "Verdana Bold" : "Verdana");
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
}

void CreateRectLabel(string name, int x, int y, int w, int h, color bg, color border, int opacity)
{
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, DashCorner);
      ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, (name == "GSP_HUD_BG"));
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
   }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, border);
}

void CleanDashboard()
{
   ObjectsDeleteAll(0, "GSP_HUD_");
   Comment("");
}

double GetLotSize(int index)
{
   double raw_lot = 0.01;
   int array_size = ArraySize(m_lot_array);
   if(array_size > 0) {
      int safe_idx = (index >= array_size) ? array_size - 1 : index;
      raw_lot = m_lot_array[safe_idx];
   }
   if(!UseAutoRisk) return raw_lot;

   double eq = m_account.Equity();
   if(eq <= 0) return m_symbol.LotsMin();

   double margin_1 = 0;
   if(!OrderCalcMargin(ORDER_TYPE_BUY, Symbol(), 1.0, m_symbol.Ask(), margin_1) || margin_1 <= 0)
      return m_symbol.LotsMin();

   double max_margin_allowed = eq * (RiskPercent / 100.0);
   double equity_cap_lot = max_margin_allowed / margin_1;

   double limit_margin_total = 0.0;
   if(UseLowMarginStop) {
      double divisor = LowMarginLevelStop / 100.0;
      if(divisor <= 0) divisor = 1.0;
      limit_margin_total = eq / divisor;
   } else {
      limit_margin_total = eq;
   }
   double cur_margin = m_account.Margin();
   double margin_room = limit_margin_total - cur_margin;
   double predictive_max_lot = (margin_room > 0) ? (margin_room / margin_1) : 0;

   double final_lot = raw_lot;
   final_lot = MathMin(final_lot, equity_cap_lot);
   final_lot = MathMin(final_lot, predictive_max_lot);

   if(final_lot < m_symbol.LotsMin()) final_lot = m_symbol.LotsMin();
   if(final_lot > m_symbol.LotsMax()) final_lot = m_symbol.LotsMax();

   double max_sym_vol = NewOrderAllowedVolume(Symbol());
   if(final_lot > max_sym_vol) final_lot = max_sym_vol;
   return final_lot;
}

bool ParseLotString(string str_in, double &result[])
{
   string sep = ",";
   ushort u_sep = StringGetCharacter(sep, 0);
   string parts[];
   int total = StringSplit(str_in, u_sep, parts);
   if(total <= 0) return false;
   ArrayResize(result, total);
   for(int i = 0; i < total; i++) result[i] = StringToDouble(parts[i]);
   return true;
}

bool RefreshRates() { return m_symbol.RefreshRates(); }

bool IsTradingTime()
{
   if(!ApplyTimeFilter) return true;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   string curr = StringFormat("%02d:%02d", dt.hour, dt.min);
   if(StartTime < StopTime) return (curr >= StartTime && curr <= StopTime);
   return (curr >= StartTime || curr <= StopTime);
}

void CloseAll()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i) && IsMyPosition())
         m_trade.PositionClose(m_position.Ticket());
   }
   StampAction();
   m_prev_my_positions = CountMyPositions();
}
//+------------------------------------------------------------------+

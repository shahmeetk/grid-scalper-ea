//+------------------------------------------------------------------+
//| GridScalper.mq5                                                  |
//| Grid Scalper v2.21 — native MT5 AI Assistant coach gate          |
//| EA places every order. Gate is pause/direction for NEW risk only.|
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Algorithmic Engineer"
#property link      "https://www.mql5.com"
#property version   "2.21"
#property description "Grid Scalper: RSI/MA grid + LLM pause/direction gate. Coach does not trade."

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

#define GV_LLM_PAUSE  "GS_LLM_PAUSE"
#define GV_LLM_DIR    "GS_LLM_DIR"
#define FILE_BRIEFING "gs_llm_briefing.txt"
#define FILE_LLM_NOTE "gs_llm_note.txt"
#define FILE_LLM_GATE "gs_llm_gate.txt"

enum ENUM_TP_TYPE
  {
   TP_AVERAGE,    // Average (Basket Close)
   TP_INDIVIDUAL  // Individual (Scalping)
  };

enum ENUM_TRADE_DIR
  {
   DIR_BOTH, // Both Directions
   DIR_BUY,  // Only Buy
   DIR_SELL  // Only Sell
  };

enum ENUM_START_MODE
  {
   START_SIGNAL,    // Wait for RSI/MA
   START_IMMEDIATE  // Start Immediately
  };

input group "=== [1] Identity & Risk ==="
input string         StrategyTag        = "GoldScalper"; // Strategy Name (Comment Tag)
input long           MagicNumber        = 123456;        // Unique Magic Number
input double         MaxDDToHedge       = 2000.0;        // Max Drawdown ($) -> Trigger Protection
input bool           CloseOnMaxDD       = false;         // Close All if MaxDD Reached?
input bool           IncludeManualTrade = false;         // Manage Manual Trades? (Magic 0)

input group "=== [2] Grid Execution ==="
input ENUM_TRADE_DIR Trade_Direction   = DIR_BOTH;       // Allowed Trade Direction
input ENUM_START_MODE StartMode        = START_IMMEDIATE; // Entry Mode (Signal vs Immediate)
input string         LotSequence       = "0.01,0.01,0.01,0.02,0.02,0.03,0.04,0.06,0.10,0.15,0.25"; // Lot Sequence
input int            MaxOrders         = 12;             // Max Grid Orders (Per Side)
input double         GridDistance      = 400;            // Grid Distance (Points)
input double         AddToDistance     = 200;            // Step Increment (Points)
input int            IncreaseDistAfter = 3;              // Increase Distance after Order #

input group "=== [3] Profit & Exit ==="
input ENUM_TP_TYPE   TP_Type            = TP_AVERAGE;    // Take Profit Logic
input double         TakeProfit         = 1000;          // Profit Target (Points)
input bool           UseTrailing        = false;         // Enable Trailing Stop
input double         ProfitToStartTrail = 30.0;          // Basket Profit to Start Trailing ($)
input double         TrailStartPoints   = 500;           // Trail Start (Points)
input double         TrailStepPoints    = 100;           // Trail Step (Points)
input bool           TrailOnlyLast      = true;          // Trail Only Last Order?
input bool           UseStopLoss        = false;         // Enable Loss Limit?
input int            FixedStopLoss      = 5000;          // Loss Limit (Points)

input group "=== [4] Entry Filters (Optional) ==="
input int            CooldownSeconds    = 300;           // Cooldown after Basket Close (Sec)
input bool           ApplyTimeFilter    = false;         // Enable Time Filter
input string         StartTime          = "08:00";       // Start Time (Server)
input string         StopTime           = "20:00";       // Stop Time (Server)

input group "=== [5] Trend & Signal (If Signal Mode) ==="
input bool           UseTrendFilter     = false;         // Enable Trend Filter (MA)
input int            MA_Period          = 50;            // MA Period
input int            RSI_Period         = 14;            // RSI Period
input double         RSI_Buy_Dip        = 30.0;          // Buy: Reversal Level (Oversold)
input double         RSI_Buy_Trend      = 45.0;          // Buy: Trend Dip Level
input double         RSI_Sell_Peak      = 70.0;          // Sell: Reversal Level (Overbought)
input double         RSI_Sell_Trend     = 55.0;          // Sell: Trend Rally Level

input group "=== [6] Range Trading Filters ==="
input bool           UseBuyRange        = false;         // Enable Buy Price Range?
input double         BuyStartPrice      = 1900.0;        // Buy: Start Price (Lower Bound)
input double         BuyStopPrice       = 2100.0;        // Buy: Stop Price (Upper Bound)
input bool           UseSellRange       = false;         // Enable Sell Price Range?
input double         SellStartPrice     = 2100.0;        // Sell: Start Price (Upper Bound)
input double         SellStopPrice      = 1900.0;        // Sell: Stop Price (Lower Bound)

input group "=== [7] Dashboard & UI ==="
input ENUM_BASE_CORNER DashCorner       = CORNER_LEFT_UPPER; // Dashboard Corner
input int            DashX              = 10;            // Dashboard X Offset
input int            DashY              = 20;            // Dashboard Y Offset
input int            DashWidth          = 220;           // Dashboard Width
input int            DashHeight         = 210;           // Dashboard Height (210 fits LLM row)
input color          DashColor          = clrGoldenrod;  // Theme Color
input bool           AutoTheme          = true;          // Auto-detect Light/Dark Theme?
input bool           ShowDashboard      = true;          // Show/Hide Dashboard

input group "=== [8] LLM Advisor Gate ==="
input bool           UseLLMAdvisorGate  = true;          // Wrap new entries/adds only (exits ignore this)
input bool           LLM_StartPaused    = false;         // Start with new adds blocked (non-visual tester)
input int            LLM_BriefingSeconds = 30;           // Write briefing file (0 = OnInit only)

CTrade        m_trade;
CSymbolInfo   m_symbol;
CPositionInfo m_position;
CAccountInfo  m_account;

double   m_lot_array[];
int      m_rsi_handle = INVALID_HANDLE;
double   m_rsi_buffer[];
bool     m_dd_breached = false;
int      m_ma_handle = INVALID_HANDLE;
double   m_ma_buffer[];
datetime m_last_close_time = 0;
int      g_dash_x = -1;
int      g_dash_y = -1;
int      m_gate_pause = 0;
int      m_gate_dir = 0;

int CountPositions(ENUM_POSITION_TYPE type);
int CountMyPositions();
bool IsMyPosition();
bool LLMAllowsNew(ENUM_POSITION_TYPE type);
void RefreshLlmGate();
void PersistLlmGate();
void ApplyGateClick();
void SendMarketOrder(ENUM_POSITION_TYPE type,double lot,double price,double sl,double tp,const string comment);
void WriteLlmBriefing();
string LlmPauseLabel();
string LlmDirLabel();
string ReadLlmNote();
void EnsureLlmGlobals();
void GetBasketStats(int &cBuy,int &cSell,double &volBuy,double &volSell,double &pBuy,double &pSell);

int OnInit()
  {
   if(!m_symbol.Name(_Symbol))
     {
      Print("Failed to initialize symbol");
      return(INIT_FAILED);
     }
   RefreshRates();

   if(!ParseLotString(LotSequence,m_lot_array))
     {
      Print("CRITICAL ERROR: Invalid LotSequence format.");
      return(INIT_PARAMETERS_INCORRECT);
     }

   m_rsi_handle = iRSI(_Symbol,PERIOD_CURRENT,RSI_Period,PRICE_CLOSE);
   if(m_rsi_handle == INVALID_HANDLE)
     {
      Print("Failed to create RSI indicator handle");
      return(INIT_FAILED);
     }
   ArraySetAsSeries(m_rsi_buffer,true);

   if(UseTrendFilter)
     {
      m_ma_handle = iMA(_Symbol,PERIOD_CURRENT,MA_Period,0,MODE_EMA,PRICE_CLOSE);
      if(m_ma_handle == INVALID_HANDLE)
        {
         Print("Failed to create MA handle");
         return(INIT_FAILED);
        }
      ArraySetAsSeries(m_ma_buffer,true);
     }

   m_trade.SetExpertMagicNumber(MagicNumber);
   m_trade.SetMarginMode();
   m_trade.SetDeviationInPoints(10);

   m_gate_pause = 0;
   m_gate_dir = 0;
   if(UseLLMAdvisorGate)
     {
      EnsureLlmGlobals();
      m_gate_pause = LLM_StartPaused ? 1 : 0;
      RefreshLlmGate();
     }
   if(LLM_BriefingSeconds > 0)
      EventSetTimer(LLM_BriefingSeconds);

   PrintFormat("Grid Scalper v2.21 Initialized. Magic: %d Gate: %s",
               MagicNumber, UseLLMAdvisorGate ? "ON" : "OFF");
   WriteLlmBriefing();
   UpdateDashboard();
   ChartRedraw();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   if(m_rsi_handle != INVALID_HANDLE)
      IndicatorRelease(m_rsi_handle);
   if(m_ma_handle != INVALID_HANDLE)
      IndicatorRelease(m_ma_handle);
   CleanDashboard();
  }

void OnTick()
  {
   if(!RefreshRates())
      return;

   RefreshLlmGate();
   CheckEquityProtection();

   ManageDirection(POSITION_TYPE_BUY);
   ManageDirection(POSITION_TYPE_SELL);

   if(UseTrailing)
      ManageTrailing();
   if(BarsCalculated(m_rsi_handle) > 0)
      CopyBuffer(m_rsi_handle,0,0,1,m_rsi_buffer);
   UpdateDashboard();
  }

void OnTimer()
  {
   WriteLlmBriefing();
  }

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   string prefix = "GSP_HUD_";
   if(id == CHARTEVENT_OBJECT_DRAG && sparam == prefix + "BG")
      UpdateDashboard();
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == prefix + "PAUSEBTN")
     {
      ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
      ApplyGateClick();
     }
  }

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD)
      return;
   if(trans.symbol != _Symbol)
      return;
   if(trans.deal == 0)
      return;
   if(!HistoryDealSelect(trans.deal))
      return;

   long magic = HistoryDealGetInteger(trans.deal,DEAL_MAGIC);
   bool ours = (magic == MagicNumber) || (IncludeManualTrade && magic == 0);
   if(!ours)
      return;

   long entry = HistoryDealGetInteger(trans.deal,DEAL_ENTRY);
   if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT && entry != DEAL_ENTRY_OUT_BY)
      return;

   if(CountMyPositions() == 0)
     {
      m_last_close_time = TimeCurrent();
      PrintFormat("Cooldown armed: basket closed at %s", TimeToString(m_last_close_time,TIME_DATE|TIME_SECONDS));
     }
  }

void ManageDirection(ENUM_POSITION_TYPE type)
  {
   int count = CountPositions(type);

   if(count == 0)
     {
      if(!m_dd_breached && IsTradingTime())
        {
         if(TimeCurrent() - m_last_close_time < CooldownSeconds)
            return;
         if(!LLMAllowsNew(type))
           {
            static datetime last_skip = 0;
            if(TimeCurrent() - last_skip >= 30)
              {
               PrintFormat("LLM gate: skip new %s entry (PAUSE=%s DIR=%s)",
                           (type == POSITION_TYPE_BUY ? "BUY" : "SELL"),
                           LlmPauseLabel(), LlmDirLabel());
               last_skip = TimeCurrent();
              }
            return;
           }

         bool signal = false;
         if(StartMode == START_IMMEDIATE)
           {
            if(type == POSITION_TYPE_BUY && (Trade_Direction == DIR_BUY || Trade_Direction == DIR_BOTH))
               signal = true;
            if(type == POSITION_TYPE_SELL && (Trade_Direction == DIR_SELL || Trade_Direction == DIR_BOTH))
               signal = true;
           }
         else
            signal = CheckEntrySignal(type);

         if(signal)
           {
            if(!IsWithinRange(type,(type == POSITION_TYPE_BUY ? m_symbol.Ask() : m_symbol.Bid())))
               signal = false;
           }

         if(signal)
            OpenFirstTrade(type);
        }
     }
   else
     {
      if(!m_dd_breached && count < MaxOrders)
        {
         if(!LLMAllowsNew(type))
           {
            static datetime last_skip_add = 0;
            if(TimeCurrent() - last_skip_add >= 30)
              {
               PrintFormat("LLM gate: skip grid add %s (PAUSE=%s DIR=%s)",
                           (type == POSITION_TYPE_BUY ? "BUY" : "SELL"),
                           LlmPauseLabel(), LlmDirLabel());
               last_skip_add = TimeCurrent();
              }
           }
         else
            CheckGridExpansion(type,count);
        }

      if(TP_Type == TP_AVERAGE)
         UpdateAverageTP(type);
     }
  }

bool CheckEntrySignal(ENUM_POSITION_TYPE type)
  {
   if(type == POSITION_TYPE_BUY && Trade_Direction == DIR_SELL)
      return false;
   if(type == POSITION_TYPE_SELL && Trade_Direction == DIR_BUY)
      return false;

   if(CopyBuffer(m_rsi_handle,0,0,1,m_rsi_buffer) < 1)
      return false;
   double rsi = m_rsi_buffer[0];

   if(UseTrendFilter)
     {
      if(CopyBuffer(m_ma_handle,0,0,1,m_ma_buffer) < 1)
         return false;
      double ma = m_ma_buffer[0];
      double close_px = iClose(_Symbol,PERIOD_CURRENT,0);

      if(type == POSITION_TYPE_BUY)
        {
         if(close_px > ma)
            return (rsi < RSI_Buy_Trend);
         return (rsi < RSI_Buy_Dip);
        }

      if(type == POSITION_TYPE_SELL)
        {
         if(close_px < ma)
            return (rsi > RSI_Sell_Trend);
         return (rsi > RSI_Sell_Peak);
        }
      return false;
     }

   if(type == POSITION_TYPE_BUY)
      return (rsi < RSI_Buy_Dip);
   if(type == POSITION_TYPE_SELL)
      return (rsi > RSI_Sell_Peak);
   return false;
  }

void OpenFirstTrade(ENUM_POSITION_TYPE type)
  {
   double lot = GetLotSize(0);
   double price = (type == POSITION_TYPE_BUY) ? m_symbol.Ask() : m_symbol.Bid();
   double tp_price = (type == POSITION_TYPE_BUY)
                     ? price + TakeProfit * m_symbol.Point()
                     : price - TakeProfit * m_symbol.Point();
   tp_price = NormalizeDouble(tp_price,m_symbol.Digits());

   double sl_price = 0;
   if(UseStopLoss)
     {
      sl_price = (type == POSITION_TYPE_BUY)
                 ? price - FixedStopLoss * m_symbol.Point()
                 : price + FixedStopLoss * m_symbol.Point();
      sl_price = NormalizeDouble(sl_price,m_symbol.Digits());
     }

   string comment = StringFormat("%s %s #1 (%.2f)", StrategyTag,
                                 (type == POSITION_TYPE_BUY ? "BUY" : "SELL"), lot);
   SendMarketOrder(type,lot,price,sl_price,tp_price,comment);
  }

void CheckGridExpansion(ENUM_POSITION_TYPE type,int current_count)
  {
   double worst_price = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         if(IsMyPosition() && m_position.PositionType() == type)
           {
            if(type == POSITION_TYPE_BUY)
              {
               if(worst_price == 0 || m_position.PriceOpen() < worst_price)
                  worst_price = m_position.PriceOpen();
              }
            else
              {
               if(worst_price == 0 || m_position.PriceOpen() > worst_price)
                  worst_price = m_position.PriceOpen();
              }
           }
        }
     }

   double required_dist = GridDistance;
   if(current_count >= IncreaseDistAfter)
      required_dist += AddToDistance;

   bool trigger = false;
   if(type == POSITION_TYPE_BUY)
     {
      if(m_symbol.Ask() <= worst_price - required_dist * m_symbol.Point())
         trigger = true;
     }
   else
     {
      if(m_symbol.Bid() >= worst_price + required_dist * m_symbol.Point())
         trigger = true;
     }

   if(!trigger)
      return;

   double price = (type == POSITION_TYPE_BUY) ? m_symbol.Ask() : m_symbol.Bid();
   if(!IsWithinRange(type,price))
      return;

   double lot = GetLotSize(current_count);
   double tp = 0;
   if(TP_Type == TP_INDIVIDUAL)
     {
      tp = (type == POSITION_TYPE_BUY)
           ? price + TakeProfit * m_symbol.Point()
           : price - TakeProfit * m_symbol.Point();
     }

   double sl = 0;
   if(UseStopLoss)
     {
      sl = (type == POSITION_TYPE_BUY)
           ? price - FixedStopLoss * m_symbol.Point()
           : price + FixedStopLoss * m_symbol.Point();
      sl = NormalizeDouble(sl,m_symbol.Digits());
     }

   string typeStr = (type == POSITION_TYPE_BUY) ? "BUY" : "SELL";
   string comment = StringFormat("%s %s #%d (%.2f)", StrategyTag, typeStr, current_count + 1, lot);
   SendMarketOrder(type,lot,price,sl,tp,comment);
  }

void UpdateAverageTP(ENUM_POSITION_TYPE type)
  {
   double sum_prod = 0;
   double sum_vol = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         if(IsMyPosition() && m_position.PositionType() == type)
           {
            sum_prod += m_position.PriceOpen() * m_position.Volume();
            sum_vol  += m_position.Volume();
           }
        }
     }

   if(sum_vol == 0)
      return;

   double avg_price = sum_prod / sum_vol;
   double new_tp = (type == POSITION_TYPE_BUY)
                   ? avg_price + TakeProfit * m_symbol.Point()
                   : avg_price - TakeProfit * m_symbol.Point();
   new_tp = NormalizeDouble(new_tp,m_symbol.Digits());

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         if(IsMyPosition() && m_position.PositionType() == type)
           {
            if(MathAbs(m_position.TakeProfit() - new_tp) > m_symbol.Point())
              {
               if(m_trade.PositionModify(m_position.Ticket(),m_position.StopLoss(),new_tp))
                  PrintFormat("Profit Target UPDATED: [%s] Ticket #%I64u set to %.2f",
                              (type == POSITION_TYPE_BUY ? "BUY" : "SELL"),
                              m_position.Ticket(), new_tp);
              }
           }
        }
     }
  }

void ManageTrailing()
  {
   double profit_buy = 0, profit_sell = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i) && IsMyPosition())
        {
         if(m_position.PositionType() == POSITION_TYPE_BUY)
            profit_buy += m_position.Profit() + m_position.Swap() + m_position.Commission();
         if(m_position.PositionType() == POSITION_TYPE_SELL)
            profit_sell += m_position.Profit() + m_position.Swap() + m_position.Commission();
        }
     }

   ulong last_buy_ticket = 0;
   ulong last_sell_ticket = 0;
   if(TrailOnlyLast)
     {
      last_buy_ticket = GetLastTicket(POSITION_TYPE_BUY);
      last_sell_ticket = GetLastTicket(POSITION_TYPE_SELL);
     }

   if(profit_buy >= ProfitToStartTrail)
      ApplyTrail(POSITION_TYPE_BUY,last_buy_ticket);
   if(profit_sell >= ProfitToStartTrail)
      ApplyTrail(POSITION_TYPE_SELL,last_sell_ticket);
  }

void ApplyTrail(ENUM_POSITION_TYPE type,ulong last_ticket)
  {
   double point = m_symbol.Point();
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i) && IsMyPosition() && m_position.PositionType() == type)
        {
         if(TrailOnlyLast && m_position.Ticket() != last_ticket)
            continue;

         double new_sl = 0;
         double price = (type == POSITION_TYPE_BUY) ? m_symbol.Bid() : m_symbol.Ask();

         if(type == POSITION_TYPE_BUY)
           {
            if(price > m_position.PriceOpen() + TrailStartPoints * point)
              {
               double proposed = price - TrailStepPoints * point;
               if(proposed > m_position.PriceOpen() && proposed > m_position.StopLoss())
                  new_sl = proposed;
              }
           }
         else
           {
            if(price < m_position.PriceOpen() - TrailStartPoints * point)
              {
               double proposed = price + TrailStepPoints * point;
               if(proposed < m_position.PriceOpen() && (m_position.StopLoss() == 0 || proposed < m_position.StopLoss()))
                  new_sl = proposed;
              }
           }

         if(new_sl != 0)
           {
            new_sl = NormalizeDouble(new_sl,m_symbol.Digits());
            m_trade.PositionModify(m_position.Ticket(),new_sl,m_position.TakeProfit());
           }
        }
     }
  }

void CheckEquityProtection()
  {
   double current_dd = m_account.Balance() - m_account.Equity();
   if(current_dd > MaxDDToHedge)
     {
      if(!m_dd_breached)
         PrintFormat("Max Drawdown Reached! Current DD: %.2f", current_dd);

      if(CloseOnMaxDD)
        {
         Print("Emergency Protection: Closing ALL Positions.");
         CloseAll();
        }
      m_dd_breached = true;
     }
   else
      m_dd_breached = false;
  }

bool IsMyPosition()
  {
   if(m_position.Symbol() != _Symbol)
      return false;
   if(m_position.Magic() == MagicNumber)
      return true;
   if(IncludeManualTrade && m_position.Magic() == 0)
      return true;
   return false;
  }

int CountPositions(ENUM_POSITION_TYPE type)
  {
   int cnt = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i) && IsMyPosition() && m_position.PositionType() == type)
         cnt++;
     }
   return cnt;
  }

int CountMyPositions()
  {
   int cnt = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i) && IsMyPosition())
         cnt++;
     }
   return cnt;
  }

void GetBasketStats(int &cBuy,int &cSell,double &volBuy,double &volSell,double &pBuy,double &pSell)
  {
   cBuy = 0;
   cSell = 0;
   volBuy = 0;
   volSell = 0;
   pBuy = 0;
   pSell = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_position.SelectByIndex(i) || !IsMyPosition())
         continue;
      double profit = m_position.Profit() + m_position.Swap() + m_position.Commission();
      if(m_position.PositionType() == POSITION_TYPE_BUY)
        {
         cBuy++;
         volBuy += m_position.Volume();
         pBuy += profit;
        }
      else
        {
         cSell++;
         volSell += m_position.Volume();
         pSell += profit;
        }
     }
  }

bool IsWithinRange(ENUM_POSITION_TYPE type,double price)
  {
   if(type == POSITION_TYPE_BUY && UseBuyRange)
     {
      double min_p = MathMin(BuyStartPrice,BuyStopPrice);
      double max_p = MathMax(BuyStartPrice,BuyStopPrice);
      if(price < min_p || price > max_p)
         return false;
     }
   if(type == POSITION_TYPE_SELL && UseSellRange)
     {
      double min_p = MathMin(SellStartPrice,SellStopPrice);
      double max_p = MathMax(SellStartPrice,SellStopPrice);
      if(price < min_p || price > max_p)
         return false;
     }
   return true;
  }

void UpdateDashboard()
  {
   if(!ShowDashboard)
     {
      CleanDashboard();
      return;
     }

   string prefix = "GSP_HUD_";
   if(g_dash_x == -1)
     {
      g_dash_x = DashX;
      g_dash_y = DashY;
     }

   if(ObjectFind(0,prefix+"BG") >= 0)
     {
      g_dash_x = (int)ObjectGetInteger(0,prefix+"BG",OBJPROP_XDISTANCE);
      g_dash_y = (int)ObjectGetInteger(0,prefix+"BG",OBJPROP_YDISTANCE);
     }

   int x_base = g_dash_x;
   int y_base = g_dash_y;
   int x_label = x_base + 12;
   int y_row = y_base + 45;
   int y_step = 26;

   int cBuy,cSell;
   double volBuy,volSell,pBuy,pSell;
   GetBasketStats(cBuy,cSell,volBuy,volSell,pBuy,pSell);

   double total_profit = pBuy + pSell;
   double equity = m_account.Equity();
   double balance = m_account.Balance();
   double dd_val = (balance > equity) ? (balance - equity) : 0;
   double dd_pct = (balance > 0) ? (dd_val / balance * 100.0) : 0;

   color bg_color = C'15,15,15';
   color hdr_color = C'30,30,30';
   color text_main = clrWhite;
   color text_dim = clrSilver;

   if(AutoTheme)
     {
      color chart_bg = (color)ChartGetInteger(0,CHART_COLOR_BACKGROUND);
      if(chart_bg == clrWhite || chart_bg == clrLightGray || chart_bg == clrSilver)
        {
         bg_color = C'245,245,245';
         hdr_color = C'220,220,220';
         text_main = clrBlack;
         text_dim = clrDarkGray;
        }
     }

   CreateRectLabel(prefix+"BG",x_base,y_base,DashWidth,DashHeight,bg_color,DashColor);
   CreateRectLabel(prefix+"HDR",x_base,y_base,DashWidth,32,hdr_color,DashColor);

   string tag_upper = StrategyTag;
   StringToUpper(tag_upper);
   CreateLabel(prefix+"Title",StringFormat("%s SCALPER",tag_upper),x_base+10,y_base+8,DashColor,9,true);

   string login_str = (m_account.Login() > 0) ? IntegerToString(m_account.Login()) : IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
   CreateLabel(prefix+"Acc",StringFormat("TERMINAL ID: %s (%s)",login_str,
               (AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_DEMO ? "DEMO" : "LIVE")),
               x_label,y_row,text_dim,9);
   y_row += y_step;

   CreateLabel(prefix+"Equity",StringFormat("EQUITY: $%.2f",equity),x_label,y_row,text_main,9);
   y_row += y_step;

   CreateLabel(prefix+"DD",StringFormat("DRAWDOWN: $%.2f (%0.2f%%)",dd_val,dd_pct),
               x_label,y_row,(dd_pct > 3 ? clrOrange : text_main),9);
   y_row += y_step;

   CreateLabel(prefix+"Prof",StringFormat("NET PROFIT: $%.2f",total_profit),
               x_label,y_row,(total_profit >= 0 ? clrLime : clrRed),9,true);
   y_row += y_step;

   CreateRectLabel(prefix+"FTR",x_label-2,y_row-4,DashWidth-20,1,text_dim,text_dim);
   y_row += 12;

   CreateLabel(prefix+"Stats",StringFormat("BUY: %d (%.2fL) | SELL: %d (%.2fL)",cBuy,volBuy,cSell,volSell),
               x_label,y_row,(AutoTheme && text_main == clrBlack ? clrBlue : clrSkyBlue),9);
   y_row += y_step;

   color llm_col = (LlmPauseLabel() == "PAUSE") ? clrOrange : DashColor;
   CreateLabel(prefix+"LLM",
               StringFormat("LLM: %s %s", LlmPauseLabel(), LlmDirLabel()),
               x_label,y_row,llm_col,9,true);
   if(UseLLMAdvisorGate)
      CreateButton(prefix+"PAUSEBTN",
                   (m_gate_pause == 1) ? "RESUME" : "PAUSE",
                   x_base + DashWidth - 78, y_row - 2, 66, 20,
                   (m_gate_pause == 1) ? clrOrange : DashColor);
   else
      ObjectDelete(0,prefix+"PAUSEBTN");

   if(m_dd_breached)
      CreateLabel(prefix+"Warn","CRITICAL PROTECTION ACTIVE",
                  x_base+(DashWidth/2),y_base+DashHeight-15,clrRed,9,true,ANCHOR_LOWER);

   ChartRedraw();
  }

void CreateLabel(string name,string text,int x,int y,color c,int size=9,bool bold=false,ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER)
  {
   if(ObjectFind(0,name) < 0)
     {
      ObjectCreate(0,name,OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_CORNER,DashCorner);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_BACK,false);
     }
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_COLOR,c);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);
   ObjectSetString(0,name,OBJPROP_FONT,bold ? "Verdana Bold" : "Verdana");
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,anchor);
  }

void CreateRectLabel(string name,int x,int y,int w,int h,color bg,color border)
  {
   if(ObjectFind(0,name) < 0)
     {
      ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_CORNER,DashCorner);
      ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,(name == "GSP_HUD_BG"));
      ObjectSetInteger(0,name,OBJPROP_BACK,false);
     }
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,name,OBJPROP_COLOR,border);
  }

void CreateButton(string name,string text,int x,int y,int w,int h,color bg)
  {
   if(ObjectFind(0,name) < 0)
     {
      ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_CORNER,DashCorner);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,true);
      ObjectSetInteger(0,name,OBJPROP_ZORDER,10);
     }
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clrBlack);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
   ObjectSetInteger(0,name,OBJPROP_STATE,false);
  }

void CleanDashboard()
  {
   ObjectsDeleteAll(0,"GSP_HUD_");
   Comment("");
  }

double GetLotSize(int index)
  {
   if(index >= ArraySize(m_lot_array))
      return m_lot_array[ArraySize(m_lot_array)-1];
   return m_lot_array[index];
  }

bool ParseLotString(string str_in,double &result[])
  {
   string sep = ",";
   ushort u_sep = StringGetCharacter(sep,0);
   string parts[];
   int total = StringSplit(str_in,u_sep,parts);
   if(total <= 0)
      return false;
   ArrayResize(result,total);
   for(int i = 0; i < total; i++)
      result[i] = StringToDouble(parts[i]);
   return true;
  }

bool RefreshRates()
  {
   return m_symbol.RefreshRates();
  }

bool IsTradingTime()
  {
   if(!ApplyTimeFilter)
      return true;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(),dt);
   string curr = StringFormat("%02d:%02d",dt.hour,dt.min);
   if(StartTime < StopTime)
      return (curr >= StartTime && curr <= StopTime);
   return (curr >= StartTime || curr <= StopTime);
  }

ulong GetLastTicket(ENUM_POSITION_TYPE type)
  {
   ulong ticket = 0;
   long time = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i) && IsMyPosition() && m_position.PositionType() == type)
        {
         if(m_position.Time() > time)
           {
            time = m_position.Time();
            ticket = m_position.Ticket();
           }
        }
     }
   return ticket;
  }

void CloseAll()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i) && IsMyPosition())
         m_trade.PositionClose(m_position.Ticket());
     }
   m_last_close_time = TimeCurrent();
  }

void EnsureLlmGlobals()
  {
   if(!GlobalVariableCheck(GV_LLM_PAUSE))
      GlobalVariableSet(GV_LLM_PAUSE,0);
   if(!GlobalVariableCheck(GV_LLM_DIR))
      GlobalVariableSet(GV_LLM_DIR,0);
  }

void PersistLlmGate()
  {
   GlobalVariableSet(GV_LLM_PAUSE,(double)m_gate_pause);
   GlobalVariableSet(GV_LLM_DIR,(double)m_gate_dir);
   int flags = FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_REWRITE;
   int h = FileOpen(FILE_LLM_GATE,flags);
   if(h == INVALID_HANDLE)
      return;
   FileWriteString(h, StringFormat("PAUSE=%d\nDIR=%d\n", m_gate_pause, m_gate_dir));
   FileClose(h);
  }

void RefreshLlmGate()
  {
   if(!UseLLMAdvisorGate)
     {
      m_gate_pause = 0;
      m_gate_dir = 0;
      return;
     }

   // Live + visual tester: Common gs_llm_gate.txt (tester does not share live GVs).
   // Non-visual tester: ignore file/GVs so leftover pause files cannot contaminate backtests.
   bool in_tester = (bool)MQLInfoInteger(MQL_TESTER);
   bool visual = (bool)MQLInfoInteger(MQL_VISUAL_MODE);
   bool read_file = (!in_tester) || visual;

   if(read_file)
     {
      int h = FileOpen(FILE_LLM_GATE,FILE_READ|FILE_TXT|FILE_ANSI|FILE_COMMON|FILE_SHARE_READ);
      if(h != INVALID_HANDLE)
        {
         while(!FileIsEnding(h))
           {
            string line = FileReadString(h);
            if(StringFind(line,"PAUSE=") == 0)
               m_gate_pause = (int)StringToInteger(StringSubstr(line,6));
            if(StringFind(line,"DIR=") == 0)
               m_gate_dir = (int)StringToInteger(StringSubstr(line,4));
           }
         FileClose(h);
         return;
        }
     }

   if(!in_tester)
     {
      if(GlobalVariableCheck(GV_LLM_PAUSE))
         m_gate_pause = (GlobalVariableGet(GV_LLM_PAUSE) > 0.5) ? 1 : 0;
      if(GlobalVariableCheck(GV_LLM_DIR))
         m_gate_dir = (int)MathRound(GlobalVariableGet(GV_LLM_DIR));
     }
  }

void ApplyGateClick()
  {
   if(!UseLLMAdvisorGate)
      return;
   m_gate_pause = (m_gate_pause == 1) ? 0 : 1;
   PersistLlmGate();
   PrintFormat("LLM HUD toggle: PAUSE=%s DIR=%s",
               LlmPauseLabel(), LlmDirLabel());
   UpdateDashboard();
  }

bool LLMAllowsNew(ENUM_POSITION_TYPE type)
  {
   if(!UseLLMAdvisorGate)
      return true;
   if(m_gate_pause == 1)
      return false;
   if(m_gate_dir == 1 && type == POSITION_TYPE_SELL)
      return false;
   if(m_gate_dir == 2 && type == POSITION_TYPE_BUY)
      return false;
   return true;
  }

string LlmPauseLabel()
  {
   if(!UseLLMAdvisorGate)
      return "OFF";
   return (m_gate_pause == 1) ? "PAUSE" : "RUN";
  }

string LlmDirLabel()
  {
   if(!UseLLMAdvisorGate)
      return "EA";
   if(m_gate_dir == 1)
      return "BUY";
   if(m_gate_dir == 2)
      return "SELL";
   return "BOTH";
  }

string ReadLlmNote()
  {
   int h = FileOpen(FILE_LLM_NOTE,FILE_READ|FILE_TXT|FILE_ANSI|FILE_COMMON|FILE_SHARE_READ);
   if(h == INVALID_HANDLE)
      return "";
   string note = FileReadString(h);
   FileClose(h);
   return note;
  }

void SendMarketOrder(ENUM_POSITION_TYPE type,double lot,double price,double sl,double tp,const string comment)
  {
   bool ok = false;
   if(type == POSITION_TYPE_BUY)
      ok = m_trade.Buy(lot,_Symbol,price,sl,tp,comment);
   else
      ok = m_trade.Sell(lot,_Symbol,price,sl,tp,comment);

   PrintFormat("Order %s %s lot=%.2f price=%.5f retcode=%u deal=%I64u %s",
               ok ? "OK" : "FAIL",
               (type == POSITION_TYPE_BUY ? "BUY" : "SELL"),
               lot, price,
               m_trade.ResultRetcode(),
               m_trade.ResultDeal(),
               comment);
  }

void WriteLlmBriefing()
  {
   double rsi = 0;
   if(CopyBuffer(m_rsi_handle,0,0,1,m_rsi_buffer) >= 1)
      rsi = m_rsi_buffer[0];

   string ma_side = "n/a";
   if(UseTrendFilter && m_ma_handle != INVALID_HANDLE)
     {
      if(CopyBuffer(m_ma_handle,0,0,1,m_ma_buffer) >= 1)
        {
         double close_px = iClose(_Symbol,PERIOD_CURRENT,0);
         ma_side = (close_px > m_ma_buffer[0]) ? "above_ma" : "below_ma";
        }
     }

   int cBuy,cSell;
   double volBuy,volSell,pBuy,pSell;
   GetBasketStats(cBuy,cSell,volBuy,volSell,pBuy,pSell);

   double dd_val = (m_account.Balance() > m_account.Equity()) ? (m_account.Balance() - m_account.Equity()) : 0;
   double dd_pct_of_max = (MaxDDToHedge > 0) ? (dd_val / MaxDDToHedge * 100.0) : 0;
   int spread_pts = (int)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD);
   string note = ReadLlmNote();

   int flags = FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_REWRITE;
   int h = FileOpen(FILE_BRIEFING,flags);
   if(h == INVALID_HANDLE)
      h = FileOpen(FILE_BRIEFING,flags|FILE_COMMON);
   if(h == INVALID_HANDLE)
     {
      Print("Failed to write ", FILE_BRIEFING, " err=", GetLastError(),
            " data_path=", TerminalInfoString(TERMINAL_DATA_PATH));
      return;
     }

   FileWriteString(h, StringFormat("symbol=%s\n", _Symbol));
   FileWriteString(h, StringFormat("time=%s\n", TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS)));
   FileWriteString(h, StringFormat("bid=%.5f ask=%.5f spread_points=%d\n", m_symbol.Bid(), m_symbol.Ask(), spread_pts));
   FileWriteString(h, StringFormat("rsi=%.2f ma_side=%s\n", rsi, ma_side));
   FileWriteString(h, StringFormat("magic=%d tag=%s\n", MagicNumber, StrategyTag));
   FileWriteString(h, StringFormat("buy_count=%d buy_lots=%.2f buy_pl=%.2f\n", cBuy, volBuy, pBuy));
   FileWriteString(h, StringFormat("sell_count=%d sell_lots=%.2f sell_pl=%.2f\n", cSell, volSell, pSell));
   FileWriteString(h, StringFormat("dd_usd=%.2f dd_vs_maxpct=%.1f max_dd=%.2f\n", dd_val, dd_pct_of_max, MaxDDToHedge));
   FileWriteString(h, StringFormat("gate_enabled=%s pause=%s dir=%s\n",
                                   UseLLMAdvisorGate ? "1" : "0", LlmPauseLabel(), LlmDirLabel()));
   FileWriteString(h, StringFormat("balance=%.2f equity=%.2f free_margin=%.2f\n",
                                   m_account.Balance(), m_account.Equity(), m_account.FreeMargin()));
   FileWriteString(h, StringFormat("note=%s\n", note));
   FileClose(h);
  }
//+------------------------------------------------------------------+

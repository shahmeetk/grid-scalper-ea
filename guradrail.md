# The checks a trading robot must pass before publication in the Market - MQL5 Articles
### Why products are checked before they are published in the Market

Before any product is published in the Market, it must undergo compulsory preliminary checks, as a small error in the expert or indicator logic can cause losses on the trading account. That is why we have developed a series of basic checks to ensure the required quality level of the Market products.  

*   [How to quickly catch and fix errors in trading robots](about:/en/articles/2555#how_to_check)
*   [Insufficient funds to perform trade operation](about:/en/articles/2555#not_enough_money)
*   [Invalid volumes in trade operations](about:/en/articles/2555#invalid_lot)
*   [Limiting Number of Pending Orders](about:/en/articles/2555#account_limit_pending_orders)
*   [Limiting Number of Lots by a Specific Symbol](about:/en/articles/2555#symbol_limit_lots)
*   [Setting the TakeProfit and StopLoss levels within the SYMBOL\_TRADE\_STOPS\_LEVEL minimum level](about:/en/articles/2555#invalid_SL_TP_for_position)
*   [Attempt to modify order or position within the SYMBOL\_TRADE\_FREEZE\_LEVEL freeze level](about:/en/articles/2555#modify_in_freeze_level_prohibited)
*   [Errors that occur when working with symbols which have insufficient quote history](about:/en/articles/2555#not_enough_quotes_history)
*   [Array out of Range](about:/en/articles/2555#out_of_range)
*   [Zero Divide](about:/en/articles/2555#zero_divide)
*   [Sending a request to modify the levels without actually changing them](about:/en/articles/2555#no_changes_in_modification_request)
*   [Attempt to import compiled files (even EX4/EX5) and DLL](about:/en/articles/2555#dll_and_libraries_prohibited)
*   [Calling custom indicators with iCustom()](about:/en/articles/2555#attempt_to_use_icustom)
*   [Passing an invalid parameter to the function (runtime error)](about:/en/articles/2555#invalid_parameter_runtime)
*   [Access violation](about:/en/articles/2555#access_violation)
*   [Consumption of the CPU resources and memory](about:/en/articles/2555#excessive_load_memory_cpu)
*   [Articles for reading](about:/en/articles/2555#articles_for_reading)

If any errors are identified by the Market moderators in the process of checking your product, you will have to fix all of them. This article considers the most frequent errors made by developers in their trading robots and technical indicators. We also recommend reading the following articles:

*   [How to Write a Good Description for a Market Product](https://www.mql5.com/en/articles/557)
*   [Tips for an Effective Product Presentation on the Market.](https://www.mql5.com/en/articles/999)

### How to quickly catch and fix errors in trading robots  

The [strategy tester](https://www.metatrader5.com/en/terminal/help/algotrading/testing "https://www.metatrader5.com/en/terminal/help/algotrading/testing") integrated into the platform allows not only to backtest trading systems, but also to identify logical and algorithmic errors made at the development stage of the trading robot. During testing, all messages about trade operations and identified errors are output to the tester [Journal](https://www.metatrader5.com/en/terminal/help/algotrading/visualization#toolbox_journal "https://www.metatrader5.com/en/terminal/help/algotrading/visualization#toolbox_journal"). It is convenient to analyze those messages in a special log [Viewer](https://www.metatrader5.com/en/terminal/help/start_advanced/journal#viewer "https://www.metatrader5.com/en/terminal/help/start_advanced/journal#viewer"), which can be called using a context menu command.  

![](https://c.mql5.com/2/23/tester_lof_viewer.png)  

After testing the EA, open the viewer and enable the "Errors only" mode, as shown in the figure. If your trading robot contains errors, you will see them immediately. If no errors were detected the first time, perform a series of tests with different instruments/timeframes/input parameters and different values of the initial deposit. 99% of the errors can be identified by these simple techniques, and they will be discussed in this article.  

For a detailed study of detected errors use the [Debugging on History Data](https://www.metatrader5.com/en/metaeditor/help/development/debug#history "https://www.metatrader5.com/en/metaeditor/help/development/debug#history") in the MetaEditor. This method allows to use the [visual testing](https://www.metatrader5.com/en/terminal/help/algotrading/visualization "https://www.metatrader5.com/en/terminal/help/algotrading/visualization") mode for not only monitoring the price charts and values of indicators in use, but also track the value of each variable of the program at each tick. Thus, you will be able to debug your trading strategy without having to spend weeks in real time.  

### Insufficient funds to perform trade operation

Before sending every trade order, it is necessary to check if there are enough funds on the account. Lack of funds to support the future open position or order is considered a blunder.  

**Keep in mind** that even placing a [pending order](https://www.metatrader5.com/en/terminal/help/trading/general_concept#pending_order "https://www.metatrader5.com/en/terminal/help/trading/general_concept#pending_order") may require collateral — [margin](https://www.metatrader5.com/en/terminal/help/trading_advanced/margin_forex "https://www.metatrader5.com/en/terminal/help/trading_advanced/margin_forex").

![](https://c.mql5.com/2/23/errors.png)

It is recommended to [test](https://www.metatrader5.com/en/terminal/help/algotrading/testing "https://www.metatrader5.com/en/terminal/help/algotrading/testing") a trading robot with a deliberately small size of the initial deposit, for example, 1 USD or 1 Euro.

If a check shows that there are insufficient funds to perform a trade operation, it is necessary to output an error message to the log instead of calling the OrderSend() function. Sample check:

**MQL5**

```
bool CheckMoneyForTrade(string symb,double lots,ENUM_ORDER_TYPE type)
  {

   MqlTick mqltick;
   SymbolInfoTick(symb,mqltick);
   double price=mqltick.ask;
   if(type==ORDER_TYPE_SELL)
      price=mqltick.bid;

   double margin,free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   
   if(!OrderCalcMargin(type,symb,lots,price,margin))
     {
      
      Print("Error in ",__FUNCTION__," code=",GetLastError());
      return(false);
     }
   
   if(margin>free_margin)
     {
      
      Print("Not enough money for ",EnumToString(type)," ",lots," ",symb," Error code=",GetLastError());
      return(false);
     }

   return(true);
  }

```


**MQL4**  

```
bool CheckMoneyForTrade(string symb, double lots,int type)
  {
   double free_margin=AccountFreeMarginCheck(symb,type, lots);
   
   if(free_margin<0)
     {
      string oper=(type==OP_BUY)? "Buy":"Sell";
      Print("Not enough money for ", oper," ",lots, " ", symb, " Error code=",GetLastError());
      return(false);
     }
   
   return(true);
  }

```


  

### Invalid volumes in trade operations

Before sending trade orders, it is also necessary to check the correctness of the volumes specified in the orders. The number of lots that the EA is about to set in the order, must be checked before calling the OrderSend() function. The minimum and maximum allowed trading volumes for the symbols are specified in the [Specification](https://www.metatrader5.com/en/terminal/help/trading/market_watch#specification "https://www.metatrader5.com/en/terminal/help/trading/market_watch#specification"), as well as the volume step. In MQL5, these values can be obtained from the [ENUM\_SYMBOL\_INFO\_DOUBLE](about:/en/docs/constants/environment_state/marketinfoconstants#enum_symbol_info_double) enumeration with the help of the [SymbolInfoDouble()](https://www.mql5.com/en/docs/marketinformation/symbolinfodouble) function.  


|SYMBOL_VOLUME_MIN |Minimal volume for a deal                    |
|------------------|---------------------------------------------|
|SYMBOL_VOLUME_MAX |Maximal volume for a deal                    |
|SYMBOL_VOLUME_STEP|Minimal volume change step for deal execution|


Example of function for checking the correctness of the volume

```



bool CheckVolumeValue(double volume,string &description)
  {

   double min_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   if(volume<min_volume)
     {
      description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }


   double max_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   if(volume>max_volume)
     {
      description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }


   double volume_step=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);

   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      description=StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                               volume_step,ratio*volume_step);
      return(false);
     }
   description="Correct volume value";
   return(true);
  }

```


### Limiting Number of Pending Orders

There can also be a limit on the number of active pending orders that can be simultaneously placed at an account. Example of the IsNewOrderAllowed() function, which checks if another pending order can be placed. 

```



bool IsNewOrderAllowed()
  {

   int max_allowed_orders=(int)AccountInfoInteger(ACCOUNT_LIMIT_ORDERS);


   if(max_allowed_orders==0) return(true);


   int orders=OrdersTotal();


   return(orders<max_allowed_orders);
  }


```


The function is simple: get the allowed number of orders to the _max\_allowed\_orders_ variable; and if its value is not equal to zero, compare with the [current number of orders](https://www.mql5.com/en/docs/trading/orderstotal). However, this function does not consider another possible restriction - the limitation on the allowed total volume of open positions and pending orders on a specific symbol.

### Limiting Number of Lots by a Specific Symbol  

To get the size of open position by a specific symbol, first of all you need to select a position using the [PositionSelect()](https://www.mql5.com/en/docs/trading/positionselect) function. And only after that you can request the volume of the open position using the [PositionGetDouble()](https://www.mql5.com/en/docs/trading/positiongetdouble), it returns various [properties of the selected position](https://www.mql5.com/en/docs/constants/tradingconstants/positionproperties) that have the double type. Let's write the PostionVolume() function to get the position volume by a given symbol.

```



double PositionVolume(string symbol)
  {

   bool selected=PositionSelect(symbol);

   if(selected)
      
      return(PositionGetDouble(POSITION_VOLUME));
   else
     {
      
      Print(__FUNCTION__," Failed to perform PositionSelect() for symbol ",
            symbol," Error ",GetLastError());
      return(-1);
     }
  }

```


For accounts that support hedging, it is necessary to iterate over all positions on the current instrument.  

Before [making a trade request](https://www.mql5.com/en/docs/trading/ordersend) for placing a pending [order](https://www.mql5.com/en/docs/constants/tradingconstants/orderproperties) by a symbol, you should check the limitation on the total volume of open position and pending orders on one symbol - SYMBOL\_VOLUME\_LIMIT. If there is no limitation, then the volume of a pending order cannot exceed the maximum allowed volume that can be received using the [SymbolInfoDouble()](https://www.mql5.com/en/docs/marketinformation/symbolinfodouble) volume.

```
double max_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_LIMIT);
if(max_volume==0) volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);

```


However, this approach doesn't consider the volume of current pending orders by the specified symbol. Here is an example of a function that calculates this value:

```



double   PendingsVolume(string symbol)
  {
   double volume_on_symbol=0;
   ulong ticket;

   int all_orders=OrdersTotal();


   for(int i=0;i<all_orders;i++)
     {
      
      if(ticket=OrderGetTicket(i))
        {
         
         if(symbol==OrderGetString(ORDER_SYMBOL))
            volume_on_symbol+=OrderGetDouble(ORDER_VOLUME_INITIAL);
        }
     }

   return(volume_on_symbol);
  }
```


With the consideration of the open position and volume in pending orders, the final check will look the following way:

```



double NewOrderAllowedVolume(string symbol)
  {
   double allowed_volume=0;

   double symbol_max_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);

   double max_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_LIMIT);


   double opened_volume=PositionVolume(symbol);
   if(opened_volume>=0)
     {
      
      if(max_volume-opened_volume<=0)
         return(0);

      
      double orders_volume_on_symbol=PendingsVolume(symbol);
      allowed_volume=max_volume-opened_volume-orders_volume_on_symbol;
      if(allowed_volume>symbol_max_volume) allowed_volume=symbol_max_volume;
     }
   return(allowed_volume);
  }

```


### Setting the TakeProfit and StopLoss levels within the SYMBOL\_TRADE\_STOPS\_LEVEL minimum level  

Many experts trade using the TakeProfit and StopLoss orders with levels calculated dynamically at the moment of performing a buy or a sell. The TakeProfit order serves to close the position when the price moves in a favorable direction, while the StopLoss is used for limiting losses when the price moves in an unfavorable direction.  

Therefore, the TakeProfit and StopLoss levels should be compared to the current price for performing the opposite operation:  

*   Buying is done at the Ask price — the TakeProfit and StopLoss levels should be compared to the Bid price.
*   Selling is done at the Bid price — the TakeProfit and StopLoss levels should be compared to the Ask price.


|Buying is done at the Ask price  |Selling is done at the Bid price |
|---------------------------------|---------------------------------|
|TakeProfit >= Bid StopLoss <= Bid|TakeProfit <= Ask StopLoss >= Ask|


![](https://c.mql5.com/2/23/Check_TP_and_SL_en.png)  

  
Financial instrument may have the [SYMBOL\_TRADE\_STOPS\_LEVEL](about:/en/docs/constants/environment_state/marketinfoconstants#enum_symbol_info_integer) parameter set in the symbol settings. It determines the number of points for minimum indentation of the StopLoss and TakeProfit levels from the current closing price of the open position. If the value of this property is zero, then the minimum indentation for SL/TP orders has not been set for buying and selling.  

In general, checking the TakeProfit and StopLoss levels with the minimum distance of [SYMBOL\_TRADE\_STOPS\_LEVEL](about:/en/docs/constants/environment_state/marketinfoconstants#enum_symbol_info_integer) taken into account looks as follows:  

*   **Buying** is done at the Ask price — the TakeProfit and StopLoss levels must be **at the distance of at least SYMBOL\_TRADE\_STOPS\_LEVEL points from the Bid price.**
*   **Selling** is done at the Bid price — the TakeProfit and StopLoss levels must be **at the distance of at least SYMBOL\_TRADE\_STOPS\_LEVEL points from the Ask price.**



* Buying is done at the Ask price : TakeProfit - Bid >= SYMBOL_TRADE_STOPS_LEVEL Bid - StopLoss >= SYMBOL_TRADE_STOPS_LEVEL
  * Selling is done at the Bid price: Ask - TakeProfit >= SYMBOL_TRADE_STOPS_LEVEL StopLoss - Ask >= SYMBOL_TRADE_STOPS_LEVEL


So, we can create a CheckStopLoss\_Takeprofit() check function, which requires the distance from the TakeProfit and StopLoss to the closing price to be at least SYMBOL\_TRADE\_STOPS\_LEVEL points:

```
bool CheckStopLoss_Takeprofit(ENUM_ORDER_TYPE type,double SL,double TP)
  {

   int stops_level=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   if(stops_level!=0)
     {
      PrintFormat("SYMBOL_TRADE_STOPS_LEVEL=%d: StopLoss and TakeProfit must"+
                  " not be nearer than %d points from the closing price",stops_level,stops_level);
     }

   bool SL_check=false,TP_check=false;

   switch(type)
     {
      
      case  ORDER_TYPE_BUY:
        {
         
         SL_check=(Bid-SL>stops_level*_Point);
         if(!SL_check)
            PrintFormat("For order %s StopLoss=%.5f must be less than %.5f"+
                        " (Bid=%.5f - SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                        EnumToString(type),SL,Bid-stops_level*_Point,Bid,stops_level);
         
         TP_check=(TP-Bid>stops_level*_Point);
         if(!TP_check)
            PrintFormat("For order %s TakeProfit=%.5f must be greater than %.5f"+
                        " (Bid=%.5f + SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                        EnumToString(type),TP,Bid+stops_level*_Point,Bid,stops_level);
         
         return(SL_check&&TP_check);
        }
      
      case  ORDER_TYPE_SELL:
        {
         
         SL_check=(SL-Ask>stops_level*_Point);
         if(!SL_check)
            PrintFormat("For order %s StopLoss=%.5f must be greater than %.5f "+
                        " (Ask=%.5f + SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                        EnumToString(type),SL,Ask+stops_level*_Point,Ask,stops_level);
         
         TP_check=(Ask-TP>stops_level*_Point);
         if(!TP_check)
            PrintFormat("For order %s TakeProfit=%.5f must be less than %.5f "+
                        " (Ask=%.5f - SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                        EnumToString(type),TP,Ask-stops_level*_Point,Ask,stops_level);
         
         return(TP_check&&SL_check);
        }
      break;
     }

   return false;
  }

```


The check itself can look like this:

```



void OnStart()
  {

   int oper=(int)(GetTickCount()%2); 
   switch(oper)
     {
      
      case  0:
        {
         
         double price=Ask;
         double SL=NormalizeDouble(Bid+2*_Point,_Digits);
         double TP=NormalizeDouble(Bid-2*_Point,_Digits);
         
         PrintFormat("Buy at %.5f   SL=%.5f   TP=%.5f  Bid=%.5f",price,SL,TP,Bid);
         if(!CheckStopLoss_Takeprofit(ORDER_TYPE_BUY,SL,TP))
            Print("The StopLoss or TakeProfit level is incorrect!");
         
         Buy(price,SL,TP);
        }
      break;
      
      case  1:
        {
         
         double price=Bid;
         double SL=NormalizeDouble(Ask-2*_Point,_Digits);
         double TP=NormalizeDouble(Ask+2*_Point,_Digits);
         
         PrintFormat("Sell at %.5f   SL=%.5f   TP=%.5f  Ask=%.5f",price,SL,TP,Ask);
         if(!CheckStopLoss_Takeprofit(ORDER_TYPE_SELL,SL,TP))
            Print("The StopLoss or TakeProfit level is incorrect!");
         
         Sell(price,SL,TP);
        }
      break;
      
     }
  }

```


The example of the function can be found in the attached scripts _Check\_TP\_and\_SL.mq4_ and _Check\_TP\_and\_SL.mq5_. Example of execution:  

```
MQL5
Check_TP_and_SL (EURUSD,H1) Buy at 1.11433   SL=1.11425   TP=1.11421  Bid=1.11423
Check_TP_and_SL (EURUSD,H1) SYMBOL_TRADE_STOPS_LEVEL=30: StopLoss and TakeProfit must not nearer than 30 points from the closing price
Check_TP_and_SL (EURUSD,H1) For order ORDER_TYPE_BUY StopLoss=1.11425 must be less than 1.11393 (Bid=1.11423 - SYMBOL_TRADE_STOPS_LEVEL=30 points)
Check_TP_and_SL (EURUSD,H1) For order ORDER_TYPE_BUY TakeProfit=1.11421 must be greater than 1.11453 (Bid=1.11423 + SYMBOL_TRADE_STOPS_LEVEL=30 points)
Check_TP_and_SL (EURUSD,H1) The StopLoss or TakeProfit level is incorrect!
Check_TP_and_SL (EURUSD,H1) OrderSend error 4756
Check_TP_and_SL (EURUSD,H1) retcode=10016  deal=0  order=0
MQL4
Check_TP_and_SL EURUSD,H1:  Sell at 1.11430   SL=1.11445   TP=1.11449  Ask=1.11447
Check_TP_and_SL EURUSD,H1:  SYMBOL_TRADE_STOPS_LEVEL=1: StopLoss and TakeProfit must not nearer than 1 points from the closing price
Check_TP_and_SL EURUSD,H1:  For order ORDER_TYPE_SELL StopLoss=1.11445 must be greater than 1.11448  (Ask=1.11447 + SYMBOL_TRADE_STOPS_LEVEL=1 points)
Check_TP_and_SL EURUSD,H1:  For order ORDER_TYPE_SELL TakeProfit=1.11449 must be less than 1.11446  (Ask=1.11447 - SYMBOL_TRADE_STOPS_LEVEL=1 points)
Check_TP_and_SL EURUSD,H1:  The StopLoss or TakeProfit level is incorrect!
Check_TP_and_SL EURUSD,H1:  OrderSend error 130 

```


To simulate the situation with the invalid TakeProfit and StopLoss values, the _Test\_Wrong\_TakeProfit\_LEVEL.mq5_ and _Test\_Wrong\_StopLoss\_LEVEL.mq5_ experts can be found in the article attachments. They can be run only on a demo account. Study these examples in order to see the conditions when a successful buy operation is possible.  

Example of the _Test\_Wrong\_StopLoss\_LEVEL.mq5_ EA execution:

```
Test_Wrong_StopLoss_LEVEL.mq5
Point=0.00001 Digits=5
SYMBOL_TRADE_EXECUTION=SYMBOL_TRADE_EXECUTION_INSTANT
SYMBOL_TRADE_FREEZE_LEVEL=20: order or position modification is not allowed, if there are 20 points to the activation price
SYMBOL_TRADE_STOPS_LEVEL=30: StopLoss and TakeProfit must not nearer than 30 points from the closing price
1. Buy 1.0 EURUSD at 1.11442 SL=1.11404 Bid=1.11430 ( StopLoss-Bid=-26 points ))
CTrade::OrderSend: instant buy 1.00 EURUSD at 1.11442 sl: 1.11404 [invalid stops]
2. Buy 1.0 EURUSD at 1.11442 SL=1.11404 Bid=1.11431 ( StopLoss-Bid=-27 points ))
CTrade::OrderSend: instant buy 1.00 EURUSD at 1.11442 sl: 1.11404 [invalid stops]
3. Buy 1.0 EURUSD at 1.11442 SL=1.11402 Bid=1.11430 ( StopLoss-Bid=-28 points ))
CTrade::OrderSend: instant buy 1.00 EURUSD at 1.11442 sl: 1.11402 [invalid stops]
4. Buy 1.0 EURUSD at 1.11440 SL=1.11399 Bid=1.11428 ( StopLoss-Bid=-29 points ))
CTrade::OrderSend: instant buy 1.00 EURUSD at 1.11440 sl: 1.11399 [invalid stops]
5. Buy 1.0 EURUSD at 1.11439 SL=1.11398 Bid=1.11428 ( StopLoss-Bid=-30 points ))
Buy 1.0 EURUSD done at 1.11439 with StopLoss=41 points (spread=12 + SYMBOL_TRADE_STOPS_LEVEL=30)


```


Example of the _Test\_Wrong\_TakeProfit\_LEVEL.mq5_ EA execution:  

```
Test_Wrong_TakeProfit_LEVEL.mq5
Point=0.00001 Digits=5
SYMBOL_TRADE_EXECUTION=SYMBOL_TRADE_EXECUTION_INSTANT
SYMBOL_TRADE_FREEZE_LEVEL=20: order or position modification is not allowed, if there are 20 points to the activation price
SYMBOL_TRADE_STOPS_LEVEL=30: StopLoss and TakeProfit must not nearer than 30 points from the closing price
1. Buy 1.0 EURUSD at 1.11461 TP=1.11478 Bid=1.11452 (TakeProfit-Bid=26 points)
CTrade::OrderSend: instant buy 1.00 EURUSD at 1.11461 tp: 1.11478 [invalid stops]
2. Buy 1.0 EURUSD at 1.11461 TP=1.11479 Bid=1.11452 (TakeProfit-Bid=27 points)
CTrade::OrderSend: instant buy 1.00 EURUSD at 1.11461 tp: 1.11479 [invalid stops]
3. Buy 1.0 EURUSD at 1.11461 TP=1.11480 Bid=1.11452 (TakeProfit-Bid=28 points)
CTrade::OrderSend: instant buy 1.00 EURUSD at 1.11461 tp: 1.11480 [invalid stops]
4. Buy 1.0 EURUSD at 1.11461 TP=1.11481 Bid=1.11452 (TakeProfit-Bid=29 points)
CTrade::OrderSend: instant buy 1.00 EURUSD at 1.11461 tp: 1.11481 [invalid stops]
5. Buy 1.0 EURUSD at 1.11462 TP=1.11482 Bid=1.11452 (TakeProfit-Bid=30 points)
Buy 1.0 EURUSD done at 1.11462 with TakeProfit=20 points (SYMBOL_TRADE_STOPS_LEVEL=30 - spread=10)

```


Checking the StopLoss and TakeProfit levels in pending orders is much simpler, as these levels must be set based on the order opening price. That is, the checking of levels taking into account the [SYMBOL\_TRADE\_STOPS\_LEVEL](about:/en/docs/constants/environment_state/marketinfoconstants#enum_symbol_info_integer) minimum distance looks as follows: the TakeProfit and StopLoss levels must be **at the distance of at least SYMBOL\_TRADE\_STOPS\_LEVEL points from the order activation price.**



* BuyLimit and BuyStop : TakeProfit - Open >= SYMBOL_TRADE_STOPS_LEVEL Open - StopLoss >= SYMBOL_TRADE_STOPS_LEVEL
  * SellLimit and SellStop: Open - TakeProfit >= SYMBOL_TRADE_STOPS_LEVEL StopLoss - Open >= SYMBOL_TRADE_STOPS_LEVEL


The _Test\_StopLoss\_Level\_in\_PendingOrders.mq5_ EA makes a series of attempts to place the BuyStop and BuyLimt orders until the operation succeeds. With each successful attempt the StopLoss or TakeProfit level is shifted by 1 point in the right direction. Example of this EA execution:  

```
Test_StopLoss_Level_in_PendingOrders.mq5
SYMBOL_TRADE_EXECUTION=SYMBOL_TRADE_EXECUTION_INSTANT
SYMBOL_TRADE_FREEZE_LEVEL=20: order or position modification is not allowed, if there are 20 points to the activation price
SYMBOL_TRADE_STOPS_LEVEL=30: StopLoss and TakeProfit must not nearer than 30 points from the closing price
1. BuyStop 1.0 EURUSD at 1.11019 SL=1.10993 (Open-StopLoss=26 points)
CTrade::OrderSend: buy stop 1.00 EURUSD at 1.11019 sl: 1.10993 [invalid stops]
2. BuyStop 1.0 EURUSD at 1.11019 SL=1.10992 (Open-StopLoss=27 points)
CTrade::OrderSend: buy stop 1.00 EURUSD at 1.11019 sl: 1.10992 [invalid stops]
3. BuyStop 1.0 EURUSD at 1.11020 SL=1.10992 (Open-StopLoss=28 points)
CTrade::OrderSend: buy stop 1.00 EURUSD at 1.11020 sl: 1.10992 [invalid stops]
4. BuyStop 1.0 EURUSD at 1.11021 SL=1.10992 (Open-StopLoss=29 points)
CTrade::OrderSend: buy stop 1.00 EURUSD at 1.11021 sl: 1.10992 [invalid stops]
5. BuyStop 1.0 EURUSD at 1.11021 SL=1.10991 (Open-StopLoss=30 points)
BuyStop 1.0 EURUSD done at 1.11021 with StopLoss=1.10991 (SYMBOL_TRADE_STOPS_LEVEL=30)
 --------- 
1. BuyLimit 1.0 EURUSD at 1.10621 TP=1.10647 (TakeProfit-Open=26 points)
CTrade::OrderSend: buy limit 1.00 EURUSD at 1.10621 tp: 1.10647 [invalid stops]
2. BuyLimit 1.0 EURUSD at 1.10621 TP=1.10648 (TakeProfit-Open=27 points)
CTrade::OrderSend: buy limit 1.00 EURUSD at 1.10621 tp: 1.10648 [invalid stops]
3. BuyLimit 1.0 EURUSD at 1.10621 TP=1.10649 (TakeProfit-Open=28 points)
CTrade::OrderSend: buy limit 1.00 EURUSD at 1.10621 tp: 1.10649 [invalid stops]
4. BuyLimit 1.0 EURUSD at 1.10619 TP=1.10648 (TakeProfit-Open=29 points)
CTrade::OrderSend: buy limit 1.00 EURUSD at 1.10619 tp: 1.10648 [invalid stops]
5. BuyLimit 1.0 EURUSD at 1.10619 TP=1.10649 (TakeProfit-Open=30 points)
BuyLimit 1.0 EURUSD done at 1.10619 with TakeProfit=1.10649 (SYMBOL_TRADE_STOPS_LEVEL=30)


```


Examples of checking the TakeProfit and StopLoss levels in pending orders can be found in the attached source files: _Check\_TP\_and\_SL.mq4_ and _Check\_TP\_and\_SL.mq5_.  

### Attempt to modify order or position within the SYMBOL\_TRADE\_FREEZE\_LEVEL freeze level

The [SYMBOL\_TRADE\_FREEZE\_LEVEL](https://www.mql5.com/en/docs/constants/environment_state/marketinfoconstants) parameter may be set in the symbol specification. It shows the distance of freezing the trade operations for pending orders and open positions in points. For example, if a trade on financial instrument is redirected for processing to an external trading system, then a BuyLimit pending order may be currently too close to the current Ask price. And, if and a request to modify this order is sent at the moment when the opening price is close enough to the Ask price, it may happen so that the order will have been executed and modification will be impossible.

Therefore, the symbol specifications for pending orders and open positions may have a freeze distance specified, within which they cannot be modified. In general, before attempting to send a modification request, it is necessary to perform a check with consideration of the [SYMBOL\_TRADE\_FREEZE\_LEVEL](about:/en/docs/constants/environment_state/marketinfoconstants#enum_symbol_info_integer):



* Type of order/position: Buy Limit order
  * Activation price:  Ask
  * Check : Ask-OpenPrice >= SYMBOL_TRADE_FREEZE_LEVEL
* Type of order/position: Buy Stop order
  * Activation price:  Ask
  * Check : OpenPrice-Ask >= SYMBOL_TRADE_FREEZE_LEVEL
* Type of order/position: Sell Limit order
  * Activation price:  Bid
  * Check : OpenPrice-Bid >= SYMBOL_TRADE_FREEZE_LEVEL
* Type of order/position: Sell Stop order
  * Activation price:  Bid
  * Check : Bid-OpenPrice >= SYMBOL_TRADE_FREEZE_LEVEL
* Type of order/position: Buy position
  * Activation price:  Bid
  * Check : TakeProfit-Bid >= SYMBOL_TRADE_FREEZE_LEVEL Bid-StopLoss >= SYMBOL_TRADE_FREEZE_LEVEL
* Type of order/position: Sell position
  * Activation price:  Ask
  * Check : Ask-TakeProfit >= SYMBOL_TRADE_FREEZE_LEVELStopLoss-Ask >= SYMBOL_TRADE_FREEZE_LEVEL


The complete examples of functions for checking the SYMBOL\_TRADE\_FREEZE\_LEVEL level of orders and positions can be found in the attached _Check\_FreezeLevel.mq5_ and _Check\_FreezeLevel.mq4_ scripts.

```

   switch(type)
     {
      
      case  ORDER_TYPE_BUY_LIMIT:
        {
         
         check=((Ask-price)>freeze_level*_Point);
         if(!check)
            PrintFormat("Order %s #%d cannot be modified: Ask-Open=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points",
                        EnumToString(type),ticket,(int)((Ask-price)/_Point),freeze_level);
         return(check);
        }
      
      case  ORDER_TYPE_SELL_LIMIT:
        {
         
         check=((price-Bid)>freeze_level*_Point);
         if(!check)
            PrintFormat("Order %s #%d cannot be modified: Open-Bid=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points",
                        EnumToString(type),ticket,(int)((price-Bid)/_Point),freeze_level);
         return(check);
        }
      break;
      
      case  ORDER_TYPE_BUY_STOP:
        {
         
         check=((price-Ask)>freeze_level*_Point);
         if(!check)
            PrintFormat("Order %s #%d cannot be modified: Ask-Open=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points",
                        EnumToString(type),ticket,(int)((price-Ask)/_Point),freeze_level);
         return(check);
        }
      
      case  ORDER_TYPE_SELL_STOP:
        {
         
         check=((Bid-price)>freeze_level*_Point);
         if(!check)
            PrintFormat("Order %s #%d cannot be modified: Bid-Open=%d points < SYMBOL_TRADE_FREEZE_LEVEL=%d points",
                        EnumToString(type),ticket,(int)((Bid-price)/_Point),freeze_level);
         return(check);
        }
      break;
     }

```


You can simulate a situation where there is an attempt to modify a pending order within the freeze level. To do that, open a demo account with financial instruments that have non-zero SYMBOL\_TRADE\_FREEZE\_LEVEL level, then attach the _Test\_SYMBOL\_TRADE\_FREEZE\_LEVEL.mq5_ (_Test\_SYMBOL\_TRADE\_FREEZE\_LEVEL.mq4_) EA to the chart and manually place any pending order. The EA will automatically move the order as close to the current price as possible and will start making illegal modification attempts. It will play a sound alert using the PlaySound() function.

### Errors that occur when working with symbols which have insufficient quote history

If an expert or indicator is launched on a chart with insufficient history, then there are two possibilities:

1.  the program checks for availability of the required history in all the required depth. If there are less bars than required, the program requests the missing data and completes its operation before the next tick arrives. This path is the most correct and it helps to avoid a lot of mistakes, such as array out of range or zero divide;
2.  the program does not make any checks and immediately starts its work, as if all the necessary history on all the required symbols and timeframes was available immediately upon request. This approach is fraught with many unpredictable errors.  
    

You can try simulating this situation yourself. To do that, run the tested indicator or EA on the chart, then close the terminal and delete all history and start the terminal again. If there are no errors in the log after such a restart, then try changing the symbols and timeframes on the charts the program is running on. Many indicators give errors when started on weekly or monthly timeframes, which usually have a limited number of bars. Also, during a sudden change of the chart symbol (for example, from EURUSD to CADJPY), an indicator or an expert running on that chart may encounter an error caused by the absence of history required for its calculation.  

### Array out of Range

When working with arrays, the access to their elements is performed by the index number, which cannot be negative and must be less than the array size. The array size can be obtained using the [ArraySize](https://www.mql5.com/en/docs/array/arraysize)() function.  

This error can be encountered while working with a [dynamic array](https://www.mql5.com/en/docs/basis/types/dynamic_array) when its size has not been explicitly defined by the [ArrayResize()](https://www.mql5.com/en/docs/array/arrayresize) function, or when using such an array in functions that independently set the size of the dynamic arrays passed to them. For example, the [CopyTicks](https://www.mql5.com/en/docs/series/copyticks)() function tries to store the requested number of ticks to an array, but if there are less ticks than requested, the size of resulting array will be smaller than expected.

Another quite obvious way to get this error is to attempt to access the data of an indicator buffer while its size has not been initialized yet. As a reminder, the indicator buffers are dynamic arrays, and their sizes are defined by the terminal's execution system only after the chart initialization. Therefore, for instance, an attempt to access the data of such a buffer in the OnInit() function causes an "array out of range" error.  

![](https://c.mql5.com/2/23/Out_of_range_en.png)  

A simple example of an indicator that generates this error can be found in attached Test\_Out\_of\_range.mq5 file.  

  

### Zero Divide

Another critical error is an attempt to divide by zero. In this case, the program execution is terminated immediately, the tester displays the name of the function and line number in the source code where the error occurred in the Journal.  

![](https://c.mql5.com/2/23/zerodivide_en.png)  

As a rule, division by zero occurs due to a situation unforeseen by the programmer. For example, getting a property or evaluating an expression with "bad" data.  

The zero divide can be easily reproduced using a simple TestZeroDivide.mq5 EA, its source code is displayed in the screenshot. Another critical error is the use of incorrect [object pointer](https://www.mql5.com/en/docs/basis/types/object_pointers). The [Debugging on History Data](https://www.metatrader5.com/en/metaeditor/help/development/debug#history "https://www.metatrader5.com/en/metaeditor/help/development/debug#history") is useful for determining the cause of such error.

  

### Sending a request to modify the levels without actually changing them

If the rules of the trading system require the pending orders or open positions to be modified, then before sending a trade request to perform a transaction, it is necessary to make sure that the requested operation would actually change parameters of the order or position. Sending a trade request which does not make any changes is considered an error. The trade server would respond to such action with a TRADE\_RETCODE\_NO\_CHANGES\=10025 [return code](https://www.mql5.com/en/docs/constants/errorswarnings/enum_trade_return_codes) (MQL5) or with an [ERR\_NO\_RESULT=1](https://docs.mql4.com/en/constants/errorswarnings/enum_trade_return_codes "https://docs.mql4.com/en/constants/errorswarnings/enum_trade_return_codes") code (MQL4)  

Example of the check in MQL5 is provided in the _Check\_OrderLevels.mq5_ script:  

```

#include <Trade\Trade.mqh>
CTrade trade;
#include <Trade\Trade.mqh>

#include <Trade\OrderInfo.mqh>
COrderInfo orderinfo;

#include <Trade\PositionInfo.mqh>
CPositionInfo positioninfo;



bool OrderModifyCheck(ulong ticket,double price,double sl,double tp)
  {

   if(orderinfo.Select(ticket))
     {
      
      string symbol=orderinfo.Symbol();
      double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      int digits=(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
      
      bool PriceOpenChanged=(MathAbs(orderinfo.PriceOpen()-price)>point);
      
      bool StopLossChanged=(MathAbs(orderinfo.StopLoss()-sl)>point);
      
      bool TakeProfitChanged=(MathAbs(orderinfo.TakeProfit()-tp)>point);
      
      if(PriceOpenChanged || StopLossChanged || TakeProfitChanged)
         return(true);  
      
      else
      
         PrintFormat("Order #%d already has levels of Open=%.5f SL=%.5f TP=%.5f",
                     ticket,orderinfo.PriceOpen(),orderinfo.StopLoss(),orderinfo.TakeProfit());
     }

   return(false);       
  }



bool PositionModifyCheck(ulong ticket,double sl,double tp)
  {

   if(positioninfo.SelectByTicket(ticket))
     {
      
      string symbol=positioninfo.Symbol();
      double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      
      bool StopLossChanged=(MathAbs(positioninfo.StopLoss()-sl)>point);
      
      bool TakeProfitChanged=(MathAbs(OrderTakeProfit()-tp)>point);
      
      if(StopLossChanged || TakeProfitChanged)
         return(true);  
      
      else
      
         PrintFormat("Order #%d already has levels of Open=%.5f SL=%.5f TP=%.5f",
                     ticket,orderinfo.PriceOpen(),orderinfo.StopLoss(),orderinfo.TakeProfit());
     }

   return(false);       
  }



void OnStart()
  {

   double priceopen,stoploss,takeprofit;

   ulong orderticket,positionticket;


   if(OrderModifyCheck(orderticket,priceopen,stoploss,takeprofit))
     {
      
      trade.OrderModify(orderticket,priceopen,stoploss,takeprofit,
                        orderinfo.TypeTime(),orderinfo.TimeExpiration());
     }


   if(PositionModifyCheck(positionticket,stoploss,takeprofit))
     {
      
      trade.PositionModify(positionticket,stoploss,takeprofit);
     }

  }

```


Example of the check in the MQL4 language can be found in the _Check\_OrderLevels.mq4_ script:  

```
#property strict



bool OrderModifyCheck(int ticket,double price,double sl,double tp)
  {

   if(OrderSelect(ticket,SELECT_BY_TICKET))
     {
      
      string symbol=OrderSymbol();
      double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      
      bool PriceOpenChanged=true;
      int type=OrderType();
      if(!(type==OP_BUY || type==OP_SELL))
        {
         PriceOpenChanged=(MathAbs(OrderOpenPrice()-price)>point);
        }
      
      bool StopLossChanged=(MathAbs(OrderStopLoss()-sl)>point);
      
      bool TakeProfitChanged=(MathAbs(OrderTakeProfit()-tp)>point);
      
      if(PriceOpenChanged || StopLossChanged || TakeProfitChanged)
         return(true);  
      
      else
      
         PrintFormat("Order #%d already has levels of Open=%.5f SL=%.5f TP=%.5f",
                     ticket,OrderOpenPrice(),OrderStopLoss(),OrderTakeProfit());
     }

   return(false);       
  }



void OnStart()
  {

   double priceopen,stoploss,takeprofit;

   int orderticket;


   if(OrderModifyCheck(orderticket,priceopen,stoploss,takeprofit))
     {
      
      OrderModify(orderticket,priceopen,stoploss,takeprofit,OrderExpiration());
     }
  }

```


Recommended articles for reading:  

1.  [How to Make the Detection and Recovery of Errors in an Expert Advisor Code Easier](https://www.mql5.com/en/articles/1473)
2.  [How to Develop a Reliable and Safe Trade Robot in MQL 4](https://www.mql5.com/en/articles/1462)

### Attempt to import compiled files (even EX4/EX5) and DLL

The programs distributed via the Market must have a guaranteed safety for users. Therefore, any attempts to use and DLL or functions from compiled EX4/EX5 files are considered mistakes. These products will not be published in the Market.  

If your program needs to use additional indicators not present in the standard delivery, use [Resources](https://www.mql5.com/en/docs/runtime/resources).  

  

### Calling custom indicators with iCustom()

If the operation of your program requires calling to the data of a custom indicator, then all the necessary indicators should be placed to the [Resources](https://www.mql5.com/en/docs/runtime/resources). Market products are supposed to be ready to work in any unprepared environment, so they should contain all everything they need within their EX4/EX5 files. Recommended related articles:

*   [Use of Resources in MQL5](https://www.mql5.com/en/articles/261)
*   [How to create an indicator of non-standard charts for MetaTrader Market](https://www.mql5.com/en/articles/2297)

### Passing an invalid parameter to the function (runtime error)

This type of errors is relatively rare, many of them have [ready codes](https://www.mql5.com/en/docs/constants/errorswarnings/errorcodes), that are designed to help in finding the cause.



* Constant: ERR_INTERNAL_ERROR
  * Value: 4001
  * Description: Unexpected internal error
* Constant: ERR_WRONG_INTERNAL_PARAMETER
  * Value: 4002
  * Description: Wrong parameter in the inner call of the client terminal function
* Constant: ERR_INVALID_PARAMETER
  * Value: 4003
  * Description: Wrong parameter when calling the system function
* Constant: ERR_NOTIFICATION_WRONG_PARAMETER
  * Value: 4516
  * Description: Invalid parameter for sending a notification — an empty string or NULL has been passed to the SendNotification() function
* Constant: ERR_BUFFERS_WRONG_INDEX
  * Value: 4602
  * Description: Wrong indicator buffer index
* Constant: ERR_INDICATOR_WRONG_PARAMETERS
  * Value: 4808
  * Description: Wrong number of parameters when creating an indicator
* Constant: ERR_INDICATOR_PARAMETERS_MISSING
  * Value: 4809
  * Description: No parameters when creating an indicator
* Constant: ERR_INDICATOR_CUSTOM_NAME
  * Value: 4810
  * Description: The first parameter in the array must be the name of the custom indicator
* Constant: ERR_INDICATOR_PARAMETER_TYPE
  * Value: 4811
  * Description: Invalid parameter type in the array when creating an indicator
* Constant: ERR_NO_STRING_DATE
  * Value: 5030
  * Description: No date in the string
* Constant: ERR_WRONG_STRING_DATE
  * Value: 5031
  * Description: Wrong date in the string
* Constant: ERR_TOO_MANY_FORMATTERS
  * Value: 5038
  * Description: Amount of format specifiers more than the parameters
* Constant: ERR_TOO_MANY_PARAMETERS
  * Value: 5039
  * Description: Amount of parameters more than the format specifiers


The table does not list all the errors that can me encountered during the operation of a program.  

   

### Access violation

This error occurs when trying to address memory, the access to which is denied. In each such case, it is necessary to contact the developers via the Service Desk in your Profile or via the [Contacts](https://www.mql5.com/en/contact) page. A detailed description of the steps to reproduce the error and an attached source code will significantly accelerate the search for the causes of this error and will help to improve the source code compiler.  

![](https://c.mql5.com/2/23/Access_violation.png)  

### Consumption of the CPU resources and memory

When writing a program, use of time-optimal algorithms is essential, as otherwise the operation of other programs running in the terminal might become hindered or even impossible.

**It is important to remember** that the terminal allocates one common thread for working per each symbol in the [Market watch](https://www.metatrader5.com/en/terminal/help/trading/market_watch "https://www.metatrader5.com/en/terminal/help/trading/market_watch"). All the indicators running and charts opened for that symbol are processed in that thread.  

This means that if there are 5 charts opened for EURUSD on different timeframes and there are 15 indicators running on those charts, then all these charts and indicators receive only a single thread for calculating and displaying information on the chart. Therefore, one inefficient resource-consuming indicator running on a chart may slow down the operation of all other indicators or even inhibit rendering of prices on all other charts of the symbol.  

You can easily check the time taken by your algorithm using the [GetMicrosecondCount](https://www.mql5.com/en/docs/common/getmicrosecondcount)() function. It is easy to get the execution time in microseconds by measuring the time between two lines of code. To convert this time into milliseconds (ms), it should be divided by 1000 (1 millisecond contains 1000 microseconds). Usually, the runtime bottleneck of indicators is the [OnCalculate()](about:/en/docs/basis/function/events#oncalculate) handler. As a rule, the first calculation of the indicator is heavily dependent on the [Max bars in chart](https://www.metatrader5.com/en/terminal/help/startworking/settings#max_bars "https://www.metatrader5.com/en/terminal/help/startworking/settings#max_bars") parameter. Set it to "Unlimited" and run your indicator on a symbol with history of over 10 years on the M1 timeframe. If the first start takes too much time (for example, more than 100 ms), then code optimization is required.  

Here is an example of measuring the execution time of the OnCalculate() handler in the [ROC](https://www.mql5.com/en/code/46) indicator, provided in the standard delivery of the terminal with source code. Insertions are highlighted in yellow:  

```



int OnCalculate(const int rates_total,const int prev_calculated,const int begin,const double &price[])
  {

   if(rates_total<ExtRocPeriod)
      return(0);

   ulong start=GetMicrosecondCount();  

   int pos=prev_calculated-1; 
   if(pos<ExtRocPeriod)
      pos=ExtRocPeriod;

   for(int i=pos;i<rates_total && !IsStopped();i++)
     {
      if(price[i]==0.0)
         ExtRocBuffer[i]=0.0;
      else
         ExtRocBuffer[i]=(price[i]-price[i-ExtRocPeriod])/price[i]*100;
     }

   ulong finish=GetMicrosecondCount();  
   PrintFormat("Function %s in %s took %.1f ms",__FUNCTION__,__FILE__,(finish-start)/1000.);

   return(rates_total);
  }

```


The memory in use can be measured with the [MQLInfoInteger(MQL\_MEMORY\_USED)](https://www.mql5.com/en/docs/check/mqlinfointeger) function. And, of course, use the code [Profiler](https://www.metatrader5.com/en/metaeditor/help/development/profiling "https://www.metatrader5.com/en/metaeditor/help/development/profiling") to find the costliest functions in your program. We also recommend reading [The Principles of Economic Calculation of Indicators](https://www.mql5.com/en/articles/109) and [Debugging MQL5 Programs](https://www.mql5.com/en/articles/654) articles.  

The Experts work in their own threads, but all of the above applies to them as well. Writing optimal code in any types of programs is essential, be it expert, indicator, library or script.  

### There cannot be too many checks  

All of the above tips on checking the indicators and experts are recommended not only for publishing products in the Market, but also in common practice, when you write for yourself. This article did not cover all the errors that can be encountered during trading on real accounts. It did not consider the rules for handling the trade errors, which occur during loss of connection to the trading server, requotes, transaction rejections and many others that may disrupt the perfect rules of the trading system. Every robot developer has personal tried ready-made recipes for such cases.  

Newcomers are recommended to read all the articles about error handling, as well as ask questions on the forum and in the article comments. Other more experienced members of the MQL5.community will help you figure out any unclear points. We hope that the information gathered in the article will help you create more reliable trading robots and in a shorter time.  

**Recommended related articles:**

*   [Common Errors in MQL4 Programs and How to Avoid Them](https://www.mql5.com/en/articles/1391)
*   [Debugging MQL5 Programs](https://www.mql5.com/en/articles/654)
//+------------------------------------------------------------------+
//|                                       AIME_TradeExecution.mqh    |
//|                     Complete Trade Execution Module              |
//+------------------------------------------------------------------+
#ifndef ICT_TRADE_EXECUTION_MQH
#define ICT_TRADE_EXECUTION_MQH

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/OrderInfo.mqh>

// Global trade objects
CTrade         g_Trade;
CPositionInfo  g_Position;
COrderInfo     g_Order;

//+------------------------------------------------------------------+
//| Initialize Execution System                                      |
//+------------------------------------------------------------------+
bool InitializeExecutionSystem()
{
   // Configure trade object
   g_Trade.SetExpertMagicNumber(123456);
   g_Trade.SetDeviationInPoints(10);
   g_Trade.SetTypeFilling(ORDER_FILLING_IOC);
   g_Trade.SetAsyncMode(false);
   
   Print("Trade Execution System Initialized");
   return true;
}

//+------------------------------------------------------------------+
//| Execute ICT Trade (FIXES MISSING FUNCTION ERROR)                |
//+------------------------------------------------------------------+
bool ExecuteICTTrade(ENUM_ORDER_TYPE orderType, double volume, 
                     double entryPrice, double stopLoss, 
                     double takeProfit, string comment)
{
   // Validate parameters
   if(volume <= 0 || volume > SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX))
   {
      Print("Invalid volume: ", volume);
      return false;
   }
   
   // Normalize prices
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   entryPrice = NormalizeDouble(entryPrice, digits);
   stopLoss = NormalizeDouble(stopLoss, digits);
   takeProfit = NormalizeDouble(takeProfit, digits);
   
   // Risk validation
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double maxRisk = accountBalance * (MaxRiskPerTrade / 100.0);
   double positionRisk = CalculatePositionRisk(volume, entryPrice, stopLoss);
   
   if(positionRisk > maxRisk)
   {
      Print("Position risk exceeds maximum: ", positionRisk, " > ", maxRisk);
      return false;
   }
   
   // Check daily risk limit
   if(DailyPnL < -MaxDailyLoss)
   {
      Print("Daily loss limit reached");
      return false;
   }
   
   // Execute trade
   bool result = false;
   
   switch(orderType)
   {
      case ORDER_TYPE_BUY:
         result = g_Trade.Buy(volume, _Symbol, 0, stopLoss, takeProfit, comment);
         break;
         
      case ORDER_TYPE_SELL:
         result = g_Trade.Sell(volume, _Symbol, 0, stopLoss, takeProfit, comment);
         break;
         
      case ORDER_TYPE_BUY_LIMIT:
         result = g_Trade.BuyLimit(volume, entryPrice, _Symbol, stopLoss, takeProfit, 
                                   ORDER_TIME_GTC, 0, comment);
         break;
         
      case ORDER_TYPE_SELL_LIMIT:
         result = g_Trade.SellLimit(volume, entryPrice, _Symbol, stopLoss, takeProfit,
                                    ORDER_TIME_GTC, 0, comment);
         break;
         
      case ORDER_TYPE_BUY_STOP:
         result = g_Trade.BuyStop(volume, entryPrice, _Symbol, stopLoss, takeProfit,
                                  ORDER_TIME_GTC, 0, comment);
         break;
         
      case ORDER_TYPE_SELL_STOP:
         result = g_Trade.SellStop(volume, entryPrice, _Symbol, stopLoss, takeProfit,
                                   ORDER_TIME_GTC, 0, comment);
         break;
   }
   
   // Process result
   if(result)
   {
      ulong ticket = g_Trade.ResultOrder();
      double executedPrice = g_Trade.ResultPrice();
      
      // Update tracking
      ActivePositions++;
      TotalTrades++;
      LastTradeTime = TimeCurrent();
      
      // Log trade
      LogTradeExecution(ticket, orderType, volume, executedPrice, stopLoss, takeProfit, comment);
      
      Print("Trade Executed: ", comment, 
            " | Ticket: ", ticket,
            " | Type: ", EnumToString(orderType),
            " | Volume: ", volume,
            " | Entry: ", executedPrice,
            " | SL: ", stopLoss,
            " | TP: ", takeProfit);
      
      return true;
   }
   else
   {
      // Handle error
      int error = GetLastError();
      string errorDesc = g_Trade.ResultRetcodeDescription();
      
      LastError = error;
      ErrorCount++;
      LastErrorTime = TimeCurrent();
      
      Print("Trade Failed: ", comment,
            " | Error: ", error,
            " | Description: ", errorDesc,
            " | Retcode: ", g_Trade.ResultRetcode());
      
      // Check if recovery needed
      if(ErrorCount > 5)
      {
         RecoveryMode = true;
         TradingAllowed = false;
      }
      
      return false;
   }
}

//+------------------------------------------------------------------+
//| Close Position (FIXES MISSING FUNCTION ERROR)                   |
//+------------------------------------------------------------------+
bool ClosePosition(ulong ticket, string reason = "Manual Close")
{
   if(!g_Position.SelectByTicket(ticket))
   {
      Print("Failed to select position: ", ticket);
      return false;
   }
   
   // Get position details
   double volume = g_Position.Volume();
   ENUM_POSITION_TYPE posType = g_Position.PositionType();
   double openPrice = g_Position.PriceOpen();
   double currentProfit = g_Position.Profit();
   
   // Close position
   bool result = g_Trade.PositionClose(ticket);
   
   if(result)
   {
      // Update tracking
      ActivePositions--;
      
      // Update performance metrics
      if(currentProfit > 0)
      {
         WinningTrades++;
         TotalProfit += currentProfit;
         if(currentProfit > LargestWin) LargestWin = currentProfit;
      }
      else
      {
         LosingTrades++;
         TotalLoss += currentProfit;
         if(currentProfit < LargestLoss) LargestLoss = currentProfit;
      }
      
      DailyPnL += currentProfit;
      
      Print("Position Closed: ", ticket,
            " | Reason: ", reason,
            " | Profit: ", currentProfit,
            " | Type: ", EnumToString(posType));
      
      return true;
   }
   else
   {
      Print("Failed to close position: ", ticket,
            " | Error: ", GetLastError(),
            " | Description: ", g_Trade.ResultRetcodeDescription());
      return false;
   }
}

//+------------------------------------------------------------------+
//| Close Partial Position                                          |
//+------------------------------------------------------------------+
bool ClosePartialPosition(ulong ticket, double volumeToClose, string reason = "Partial Close")
{
   if(!g_Position.SelectByTicket(ticket))
   {
      Print("Failed to select position for partial close: ", ticket);
      return false;
   }
   
   double currentVolume = g_Position.Volume();
   
   // Validate volume
   if(volumeToClose >= currentVolume)
   {
      return ClosePosition(ticket, reason + " (Full)");
   }
   
   if(volumeToClose <= 0)
   {
      Print("Invalid partial close volume: ", volumeToClose);
      return false;
   }
   
   // Normalize volume
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   volumeToClose = MathFloor(volumeToClose / lotStep) * lotStep;
   
   // Execute partial close
   bool result = g_Trade.PositionClosePartial(ticket, volumeToClose);
   
   if(result)
   {
      Print("Partial Close: ", ticket,
            " | Volume Closed: ", volumeToClose,
            " | Remaining: ", currentVolume - volumeToClose,
            " | Reason: ", reason);
      return true;
   }
   else
   {
      Print("Partial close failed: ", ticket,
            " | Error: ", GetLastError());
      return false;
   }
}

//+------------------------------------------------------------------+
//| Calculate Position Risk                                         |
//+------------------------------------------------------------------+
double CalculatePositionRisk(double volume, double entryPrice, double stopLoss)
{
   if(stopLoss == 0) return 0;
   
   double pointValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double pointSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   
   double riskPoints = MathAbs(entryPrice - stopLoss);
   double riskAmount = (riskPoints / pointSize) * pointValue * volume;
   
   return riskAmount;
}

//+------------------------------------------------------------------+
//| Modify Position                                                 |
//+------------------------------------------------------------------+
bool ModifyPosition(ulong ticket, double newSL, double newTP)
{
   if(!g_Position.SelectByTicket(ticket))
   {
      Print("Failed to select position for modification: ", ticket);
      return false;
   }
   
   // Normalize prices
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   newSL = NormalizeDouble(newSL, digits);
   newTP = NormalizeDouble(newTP, digits);
   
   // Execute modification
   bool result = g_Trade.PositionModify(ticket, newSL, newTP);
   
   if(result)
   {
      Print("Position Modified: ", ticket,
            " | New SL: ", newSL,
            " | New TP: ", newTP);
      return true;
   }
   else
   {
      Print("Position modification failed: ", ticket,
            " | Error: ", GetLastError());
      return false;
   }
}

//+------------------------------------------------------------------+
//| Manage Active Positions                                         |
//+------------------------------------------------------------------+
void ManageActivePositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(g_Position.SelectByIndex(i))
      {
         if(g_Position.Symbol() != _Symbol) continue;
         
         ulong ticket = g_Position.Ticket();
         double currentProfit = g_Position.Profit();
         double openPrice = g_Position.PriceOpen();
         double currentPrice = g_Position.PriceCurrent();
         double stopLoss = g_Position.StopLoss();
         double takeProfit = g_Position.TakeProfit();
         ENUM_POSITION_TYPE posType = g_Position.PositionType();
         
         // ICT Trailing Stop
         if(UseICTTrailing)
         {
            ApplyICTTrailingStop(ticket, posType, openPrice, currentPrice, stopLoss);
         }
         
         // ICT Partial Profits
         if(UseICTPartials)
         {
            CheckPartialProfits(ticket, posType, openPrice, currentPrice, currentProfit);
         }
         
         // Break Even Management
         if(UseICTBreakEven)
         {
            CheckBreakEven(ticket, posType, openPrice, currentPrice, stopLoss);
         }
         
         // Emergency Exit
         if(UseEmergencyExit)
         {
            CheckEmergencyExit(ticket, currentPrice, openPrice);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Apply ICT Trailing Stop                                         |
//+------------------------------------------------------------------+
void ApplyICTTrailingStop(ulong ticket, ENUM_POSITION_TYPE posType, 
                          double openPrice, double currentPrice, double currentSL)
{
   double atr = GetCachedATR();
   double trailDistance = atr * 1.5;
   double newSL = 0;
   
   if(posType == POSITION_TYPE_BUY)
   {
      double profitDistance = currentPrice - openPrice;
      if(profitDistance > atr * 2.0)
      {
         newSL = currentPrice - trailDistance;
         if(newSL > currentSL && newSL > openPrice)
         {
            ModifyPosition(ticket, newSL, 0);
         }
      }
   }
   else // POSITION_TYPE_SELL
   {
      double profitDistance = openPrice - currentPrice;
      if(profitDistance > atr * 2.0)
      {
         newSL = currentPrice + trailDistance;
         if((currentSL == 0 || newSL < currentSL) && newSL < openPrice)
         {
            ModifyPosition(ticket, newSL, 0);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check Partial Profits                                           |
//+------------------------------------------------------------------+
void CheckPartialProfits(ulong ticket, ENUM_POSITION_TYPE posType,
                         double openPrice, double currentPrice, double currentProfit)
{
   static bool firstPartialTaken[];
   static bool secondPartialTaken[];
   
   // Initialize arrays if needed
   if(ArraySize(firstPartialTaken) <= ticket)
   {
      ArrayResize(firstPartialTaken, ticket + 100);
      ArrayResize(secondPartialTaken, ticket + 100);
   }
   
   double atr = GetCachedATR();
   double profitDistance = 0;
   
   if(posType == POSITION_TYPE_BUY)
      profitDistance = currentPrice - openPrice;
   else
      profitDistance = openPrice - currentPrice;
   
   // First partial at 2 ATR
   if(!firstPartialTaken[ticket] && profitDistance >= atr * 2.0)
   {
      double volume = g_Position.Volume();
      ClosePartialPosition(ticket, volume * 0.5, "ICT Partial 1 (2 ATR)");
      firstPartialTaken[ticket] = true;
   }
   
   // Second partial at 4 ATR
   if(!secondPartialTaken[ticket] && profitDistance >= atr * 4.0)
   {
      double volume = g_Position.Volume();
      ClosePartialPosition(ticket, volume * 0.5, "ICT Partial 2 (4 ATR)");
      secondPartialTaken[ticket] = true;
   }
}

//+------------------------------------------------------------------+
//| Check Break Even                                                |
//+------------------------------------------------------------------+
void CheckBreakEven(ulong ticket, ENUM_POSITION_TYPE posType,
                    double openPrice, double currentPrice, double currentSL)
{
   double atr = GetCachedATR();
   double beThreshold = atr * 1.0;
   double beBuffer = atr * 0.1;
   
   if(posType == POSITION_TYPE_BUY)
   {
      if(currentPrice - openPrice >= beThreshold && currentSL < openPrice)
      {
         ModifyPosition(ticket, openPrice + beBuffer, 0);
      }
   }
   else // POSITION_TYPE_SELL
   {
      if(openPrice - currentPrice >= beThreshold && 
         (currentSL == 0 || currentSL > openPrice))
      {
         ModifyPosition(ticket, openPrice - beBuffer, 0);
      }
   }
}

//+------------------------------------------------------------------+
//| Check Emergency Exit                                            |
//+------------------------------------------------------------------+
void CheckEmergencyExit(ulong ticket, double currentPrice, double openPrice)
{
   double atr = GetCachedATR();
   double emergencyThreshold = EmergencyExitThreshold * atr;
   
   double adverseMove = MathAbs(currentPrice - openPrice);
   
   if(adverseMove > emergencyThreshold)
   {
      ClosePosition(ticket, "EMERGENCY EXIT - Threshold Exceeded");
      
      // Activate recovery mode
      RecoveryMode = true;
      TradingAllowed = false;
      
      Print("EMERGENCY EXIT ACTIVATED - Trading Suspended");
   }
}

//+------------------------------------------------------------------+
//| Log Trade Execution                                             |
//+------------------------------------------------------------------+
void LogTradeExecution(ulong ticket, ENUM_ORDER_TYPE orderType, double volume,
                       double price, double sl, double tp, string comment)
{
   // Create log entry
   string logEntry = StringFormat(
      "%s | TRADE | Ticket: %d | Type: %s | Volume: %.2f | Price: %.5f | SL: %.5f | TP: %.5f | %s",
      TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
      ticket,
      EnumToString(orderType),
      volume, price, sl, tp,
      comment
   );
   
   // Write to file
   int fileHandle = FileOpen("ICT_TradeLog.csv", FILE_WRITE | FILE_READ | FILE_CSV | FILE_ANSI, ",");
   if(fileHandle != INVALID_HANDLE)
   {
      FileSeek(fileHandle, 0, SEEK_END);
      FileWrite(fileHandle, logEntry);
      FileClose(fileHandle);
   }
}

//+------------------------------------------------------------------+
//| Cleanup Execution System                                        |
//+------------------------------------------------------------------+
void CleanupExecutionSystem()
{
   // Close all positions if needed
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(g_Position.SelectByIndex(i))
      {
         if(g_Position.Symbol() == _Symbol)
         {
            ulong ticket = g_Position.Ticket();
            ClosePosition(ticket, "EA Shutdown");
         }
      }
   }
   
   Print("Execution System Cleaned Up");
}

#endif // ICT_TRADE_EXECUTION_MQH

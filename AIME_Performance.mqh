//+------------------------------------------------------------------+
//|                                       AIME_Performance.mqh       |
//|                      Performance Tracking Module                 |
//+------------------------------------------------------------------+
#ifndef AIME_PERFORMANCE_MQH
#define AIME_PERFORMANCE_MQH

//+------------------------------------------------------------------+
//| Update Performance Metrics                                      |
//+------------------------------------------------------------------+
void UpdatePerformanceMetrics()
{
   // Update account metrics
   AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   CurrentRisk = CalculateCurrentPortfolioRisk();
   DailyPnL = CalculateDailyPnL();
   
   // Calculate advanced metrics
   CalculateAdvancedMetrics();
   UpdateRiskManagement();
   
   // Check recovery mode
   if(RecoveryMode && TimeCurrent() - LastErrorTime > 600)
   {
      if(ErrorCount == 0 || TimeCurrent() - LastErrorTime > 1800)
      {
         RecoveryMode = false;
         TradingAllowed = true;
         Print("Recovery Mode Disabled - System Stabilized");
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate Advanced Metrics                                      |
//+------------------------------------------------------------------+
void CalculateAdvancedMetrics()
{
   if(TotalTrades < 10) return;
   
   double winRate = (WinningTrades / TotalTrades) * 100.0;
   double avgWin = (WinningTrades > 0) ? TotalProfit / WinningTrades : 0;
   double avgLoss = (LosingTrades > 0) ? TotalLoss / LosingTrades : 0;
   double profitFactor = (TotalLoss != 0) ? TotalProfit / MathAbs(TotalLoss) : 0;
   double riskRewardRatio = (avgLoss != 0) ? avgWin / MathAbs(avgLoss) : 0;
   
   // Calculate current drawdown
   double currentEquity = AccountBalance + CalculateDailyPnL();
   static double peakEquity = currentEquity;
   
   if(currentEquity > peakEquity)
   {
      peakEquity = currentEquity;
   }
   
   double currentDrawdown = (peakEquity - currentEquity) / peakEquity * 100.0;
   if(currentDrawdown > MaxDrawdown)
   {
      MaxDrawdown = currentDrawdown;
   }
   
   // Log metrics periodically
   static datetime lastMetricsLog = 0;
   if(TimeCurrent() - lastMetricsLog >= 3600) // Every hour
   {
      Print("=== PERFORMANCE METRICS ===");
      Print("Total Trades: ", TotalTrades);
      Print("Win Rate: ", DoubleToString(winRate, 1), "%");
      Print("Profit Factor: ", DoubleToString(profitFactor, 2));
      Print("Risk-Reward Ratio: ", DoubleToString(riskRewardRatio, 2));
      Print("Max Drawdown: ", DoubleToString(MaxDrawdown, 2), "%");
      Print("Current Portfolio Risk: ", DoubleToString(CurrentRisk, 2), "%");
      Print("Daily P&L: ", DoubleToString(DailyPnL, 2));
      Print("==========================");
      
      lastMetricsLog = TimeCurrent();
   }
}

//+------------------------------------------------------------------+
//| Update Risk Management                                          |
//+------------------------------------------------------------------+
void UpdateRiskManagement()
{
   // Check daily loss limit
   if(DailyPnL < -MaxDailyLoss * 0.9)
   {
      TradingAllowed = false;
      Print("Trading Disabled: Daily loss limit approached");
   }
   
   // Reset daily tracking
   static int lastDay = 0;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   if(dt.day != lastDay)
   {
      TradingAllowed = true;
      DailyPnL = 0;
      lastDay = dt.day;
      Print("New Trading Day: Risk limits reset");
   }
   
   // Adaptive risk based on performance
   if(TotalTrades >= 20)
   {
      double winRate = (WinningTrades / TotalTrades) * 100.0;
      
      if(winRate < 40.0)
      {
         Print("Low win rate detected: ", winRate, "% - Risk management tightened");
         // Could adjust MaxRiskPerTrade here if needed
      }
   }
}

//+------------------------------------------------------------------+
//| Process Trade Event                                             |
//+------------------------------------------------------------------+
void ProcessTradeEvent()
{
   // Update position count
   ActivePositions = 0;
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(g_Position.SelectByIndex(i))
      {
         if(g_Position.Symbol() == _Symbol)
         {
            ActivePositions++;
         }
      }
   }
   
   // Update performance metrics
   UpdatePerformanceMetrics();
}

//+------------------------------------------------------------------+
//| Generate Final Report                                           |
//+------------------------------------------------------------------+
void GenerateFinalReport(int reason)
{
   Print("========================================");
   Print("   AIME MASTER EA v4.00 FINAL REPORT   ");
   Print("========================================");
   
   // Deinitialization reason
   string reasonText = "";
   switch(reason)
   {
      case REASON_PROGRAM:     reasonText = "EA stopped by user"; break;
      case REASON_REMOVE:      reasonText = "EA removed from chart"; break;
      case REASON_CHARTCHANGE: reasonText = "Symbol or timeframe changed"; break;
      case REASON_CHARTCLOSE:  reasonText = "Chart closed"; break;
      case REASON_PARAMETERS:  reasonText = "Input parameters changed"; break;
      case REASON_ACCOUNT:     reasonText = "Account changed"; break;
      case REASON_TEMPLATE:    reasonText = "New template applied"; break;
      case REASON_INITFAILED:  reasonText = "Initialization failed"; break;
      case REASON_CLOSE:       reasonText = "Terminal closed"; break;
   }
   
   Print("Shutdown Reason: ", reasonText);
   Print("");
   
   // Performance summary
   Print("Performance Summary:");
   Print("Total Trades Executed: ", TotalTrades);
   Print("Winning Trades: ", WinningTrades);
   Print("Losing Trades: ", LosingTrades);
   
   if(TotalTrades > 0)
   {
      double winRate = (WinningTrades / TotalTrades) * 100.0;
      Print("Win Rate: ", DoubleToString(winRate, 2), "%");
   }
   
   Print("Total Profit: $", DoubleToString(TotalProfit, 2));
   Print("Total Loss: $", DoubleToString(TotalLoss, 2));
   Print("Net P&L: $", DoubleToString(TotalProfit + TotalLoss, 2));
   
   if(TotalLoss != 0)
   {
      double profitFactor = TotalProfit / MathAbs(TotalLoss);
      Print("Profit Factor: ", DoubleToString(profitFactor, 2));
   }
   
   Print("Largest Win: $", DoubleToString(LargestWin, 2));
   Print("Largest Loss: $", DoubleToString(LargestLoss, 2));
   Print("Maximum Drawdown: ", DoubleToString(MaxDrawdown, 2), "%");
   
   Print("Final Account Balance: $", DoubleToString(AccountBalance, 2));
   Print("Final Daily P&L: $", DoubleToString(DailyPnL, 2));
   Print("");
   
   // Pattern statistics
   Print("Pattern Statistics:");
   Print("- Total FVGs Detected: ", FVGCount);
   Print("- Total Order Blocks Detected: ", OrderBlockCount);
   Print("- Total Liquidity Levels: ", LiquidityLevelCount);
   Print("");
   
   // System statistics
   Print("System Statistics:");
   Print("- Total Errors: ", ErrorCount);
   Print("- Recovery Mode Activations: ", (RecoveryMode ? "Active" : "None"));
   Print("");
   
   Print("========================================");
   Print("Thank you for using AIME Master EA v4.00");
   Print("   Advanced Institutional Market Expert  ");
   Print("   Complete ICT Trading Suite            ");
   Print("========================================");
}

#endif // AIME_PERFORMANCE_MQH

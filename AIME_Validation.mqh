//+------------------------------------------------------------------+
//|                                        AIME_Validation.mqh       |
//|                     Validation and Verification Functions        |
//+------------------------------------------------------------------+
#ifndef AIME_VALIDATION_MQH
#define AIME_VALIDATION_MQH

//+------------------------------------------------------------------+
//| Validate Structure Alignment                                    |
//+------------------------------------------------------------------+
bool ValidateStructureAlignment(ENUM_ICT_PATTERN pattern)
{
   // Check if pattern aligns with current market structure
   switch(pattern)
   {
      case FAIR_VALUE_GAP_BULLISH:
      case ORDER_BLOCK_BULLISH:
         return (MarketStructure.currentStructure == BULLISH_BOS || 
                 MarketStructure.currentStructure == BULLISH_CHoCH ||
                 MarketStructure.currentStructure == BULLISH_MSS);
                 
      case FAIR_VALUE_GAP_BEARISH:
      case ORDER_BLOCK_BEARISH:
         return (MarketStructure.currentStructure == BEARISH_BOS || 
                 MarketStructure.currentStructure == BEARISH_CHoCH ||
                 MarketStructure.currentStructure == BEARISH_MSS);
                 
      default:
         return true; // Neutral patterns
   }
}

//+------------------------------------------------------------------+
//| Validate Market Conditions                                      |
//+------------------------------------------------------------------+
void ValidateMarketConditions()
{
   // Basic market validation implementation
   double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double atr = GetCachedATR();
   
   if(spread > atr * 0.5)
   {
      Print("WARNING: High spread detected: ", spread);
   }
}

//+------------------------------------------------------------------+
//| Validate Trading Conditions                                     |
//+------------------------------------------------------------------+
bool ValidateTradingConditions()
{
   return IsOptimalTradingConditions();
}

//+------------------------------------------------------------------+
//| Is Optimal Trading Conditions                                   |
//+------------------------------------------------------------------+
bool IsOptimalTradingConditions()
{
   if(!TradingAllowed) return false;
   if(RecoveryMode) return false;
   if(ActivePositions >= MaxPositions) return false;
   
   ValidateMarketConditions();
   
   // Check portfolio risk
   double portfolioRisk = CalculateCurrentPortfolioRisk();
   if(portfolioRisk > MaxPortfolioHeat) return false;
   
   // Check daily PnL
   double dailyPnL = CalculateDailyPnL();
   if(dailyPnL < -MaxDailyLoss) return false;
   
   // Check day of week
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   if(dt.day_of_week == 0 || dt.day_of_week == 6) return false;
   
   // Check news
   if(AvoidNews && IsHighImpactNewsTime(TimeCurrent())) return false;
   
   // Check spread
   double spread = PerformanceCache.cachedSpread;
   double atr = GetCachedATR();
   if(spread > atr * 0.4) return false;
   
   // Check structure strength
   if(MarketStructure.structureStrength < 4.0) return false;
   
   // Check correlation divergence
   if(UseCorrelationAnalysis)
   {
      double bias = MathAbs(CalculateSmartMoneyIndex());
      if(bias > 0.9)
      {
         Print("Trading blocked due to extreme correlation divergence: ", bias);
         return false;
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Calculate Current Portfolio Risk                                |
//+------------------------------------------------------------------+
double CalculateCurrentPortfolioRisk()
{
   double totalRisk = 0;
   
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(g_Position.SelectByIndex(i))
      {
         if(g_Position.Symbol() != _Symbol) continue;
         
         double openPrice = g_Position.PriceOpen();
         double sl = g_Position.StopLoss();
         double volume = g_Position.Volume();
         
         if(sl > 0)
         {
            double riskPerPosition = MathAbs(openPrice - sl) * volume * 
                                   SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) / 
                                   SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
            totalRisk += riskPerPosition;
         }
      }
   }
   
   return (totalRisk / AccountBalance) * 100.0;
}

//+------------------------------------------------------------------+
//| Calculate Daily PnL                                             |
//+------------------------------------------------------------------+
double CalculateDailyPnL()
{
   double dailyPnL = 0;
   datetime todayStart = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   
   for(int i = 0; i < PositionsTotal(); i++)
   {
      if(g_Position.SelectByIndex(i))
      {
         if(g_Position.Symbol() == _Symbol)
         {
            datetime positionTime = (datetime)g_Position.Time();
            if(positionTime >= todayStart)
            {
               dailyPnL += g_Position.Profit();
            }
         }
      }
   }
   
   return dailyPnL;
}

//+------------------------------------------------------------------+
//| Requires Visual Update                                          |
//+------------------------------------------------------------------+
bool RequiresVisualUpdate()
{
   static datetime lastUpdate = 0;
   datetime currentTime = TimeCurrent();
   
   // Adaptive update frequency
   int updateFrequency = VisualUpdateFrequency;
   
   // Increase frequency during high volatility
   double volatility = GetCachedVolatility();
   if(volatility > 0.08) updateFrequency = (int)(updateFrequency * 0.5);
   
   // Increase frequency during optimal trading times
   if(IsOptimalTradingTime) updateFrequency = (int)(updateFrequency * 0.6);
   
   // Increase frequency when positions are open
   if(ActivePositions > 0) updateFrequency = (int)(updateFrequency * 0.8);
   
   updateFrequency = MathMax(15, MathMin(60, updateFrequency));
   
   if(currentTime - lastUpdate >= updateFrequency)
   {
      lastUpdate = currentTime;
      return true;
   }
   
   return false;
}

#endif // AIME_VALIDATION_MQH

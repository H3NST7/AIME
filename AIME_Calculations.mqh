//+------------------------------------------------------------------+
//|                                      AIME_Calculations.mqh       |
//|                    Core Calculation Utility Functions            |
//+------------------------------------------------------------------+
#ifndef AIME_CALCULATIONS_MQH
#define AIME_CALCULATIONS_MQH

//+------------------------------------------------------------------+
//| Get Cached ATR                                                  |
//+------------------------------------------------------------------+
double GetCachedATR()
{
   // Check cache validity (60 seconds)
   if(TimeCurrent() - PerformanceCache.atrCacheTime < 60 && PerformanceCache.cachedATR > 0)
   {
      return PerformanceCache.cachedATR;
   }
   
   // Calculate fresh ATR
   double atrBuffer[];
   if(CopyBuffer(HandleATR, 0, 0, 1, atrBuffer) > 0)
   {
      PerformanceCache.cachedATR = atrBuffer[0];
      PerformanceCache.atrCacheTime = TimeCurrent();
      return atrBuffer[0];
   }
   
   // Fallback calculation
   if(RatesTotal >= 14)
   {
      double tr = 0;
      for(int i = RatesTotal - 14; i < RatesTotal; i++)
      {
         if(i > 0)
         {
            double high_low = Rates[i].high - Rates[i].low;
            double high_close = MathAbs(Rates[i].high - Rates[i-1].close);
            double low_close = MathAbs(Rates[i].low - Rates[i-1].close);
            
            tr += MathMax(high_low, MathMax(high_close, low_close));
         }
      }
      
      double fallbackATR = tr / 14.0;
      PerformanceCache.cachedATR = fallbackATR;
      PerformanceCache.atrCacheTime = TimeCurrent();
      return fallbackATR;
   }
   
   return 0.001; // Minimum fallback
}

//+------------------------------------------------------------------+
//| Get Cached Volatility                                           |
//+------------------------------------------------------------------+
double GetCachedVolatility()
{
   // Check cache validity (5 minutes)
   if(TimeCurrent() - PerformanceCache.volatilityCacheTime < 300 && PerformanceCache.cachedVolatility > 0)
   {
      return PerformanceCache.cachedVolatility;
   }
   
   // Calculate volatility as standard deviation of returns
   if(RatesTotal >= 20)
   {
      double returns[];
      ArrayResize(returns, 19);
      
      for(int i = 0; i < 19; i++)
      {
         if(Rates[RatesTotal - 20 + i].close != 0)
         {
            returns[i] = (Rates[RatesTotal - 19 + i].close - Rates[RatesTotal - 20 + i].close) / Rates[RatesTotal - 20 + i].close;
         }
      }
      
      // Calculate mean
      double mean = 0;
      for(int i = 0; i < 19; i++)
      {
         mean += returns[i];
      }
      mean /= 19;
      
      // Calculate standard deviation
      double variance = 0;
      for(int i = 0; i < 19; i++)
      {
         variance += MathPow(returns[i] - mean, 2);
      }
      variance /= 19;
      
      double volatility = MathSqrt(variance);
      PerformanceCache.cachedVolatility = volatility;
      PerformanceCache.volatilityCacheTime = TimeCurrent();
      
      return volatility;
   }
   
   return 0.01; // Default volatility
}

//+------------------------------------------------------------------+
//| Calculate Recent Range                                          |
//+------------------------------------------------------------------+
double CalculateRecentRange(int periods)
{
   if(RatesTotal < periods) return 0;
   
   double high = 0;
   double low = DBL_MAX;
   
   for(int i = RatesTotal - periods; i < RatesTotal; i++)
   {
      if(Rates[i].high > high) high = Rates[i].high;
      if(Rates[i].low < low) low = Rates[i].low;
   }
   
   return high - low;
}

//+------------------------------------------------------------------+
//| Calculate Recent Displacement                                   |
//+------------------------------------------------------------------+
double CalculateRecentDisplacement(int periods)
{
   if(RatesTotal < periods + 1) return 0;
   
   double maxDisplacement = 0;
   double atr = GetCachedATR();
   
   for(int i = RatesTotal - periods; i < RatesTotal; i++)
   {
      double candleSize = MathAbs(Rates[i].close - Rates[i].open);
      double displacement = candleSize / atr;
      
      if(displacement > maxDisplacement)
         maxDisplacement = displacement;
   }
   
   return maxDisplacement;
}

//+------------------------------------------------------------------+
//| Calculate Displacement At Index                                 |
//+------------------------------------------------------------------+
double CalculateDisplacementAtIndex(int index, int lookback)
{
   if(index < lookback || index >= RatesTotal) return 0;
   
   double totalMovement = 0;
   double atr = GetCachedATR();
   
   for(int i = index - lookback + 1; i <= index; i++)
   {
      if(i >= 0 && i < RatesTotal)
      {
         totalMovement += MathAbs(Rates[i].close - Rates[i].open);
      }
   }
   
   return totalMovement / atr;
}

//+------------------------------------------------------------------+
//| Calculate Displacement After Index                              |
//+------------------------------------------------------------------+
double CalculateDisplacementAfterIndex(int index, int lookforward)
{
   if(index + lookforward >= RatesTotal) return 0;
   
   double totalMovement = 0;
   double atr = GetCachedATR();
   
   for(int i = index + 1; i <= index + lookforward; i++)
   {
      if(i < RatesTotal)
      {
         totalMovement += MathAbs(Rates[i].close - Rates[i].open);
      }
   }
   
   return totalMovement / atr;
}

//+------------------------------------------------------------------+
//| Calculate Average Volume                                        |
//+------------------------------------------------------------------+
double CalculateAverageVolume(int index, int periods)
{
   if(index < periods || RatesTotal < periods) return 0;
   
   double totalVolume = 0;
   int count = 0;
   
   for(int i = index - periods + 1; i <= index; i++)
   {
      if(i >= 0 && i < RatesTotal && Rates[i].tick_volume > 0)
      {
         totalVolume += Rates[i].tick_volume;
         count++;
      }
   }
   
   return (count > 0) ? totalVolume / count : 0;
}

//+------------------------------------------------------------------+
//| Calculate Optimal Position Size                                 |
//+------------------------------------------------------------------+
double CalculateOptimalPositionSize(double entryPrice, double stopLoss, double confluenceMultiplier)
{
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = accountBalance * (MaxRiskPerTrade / 100.0);
   
   // Apply confluence multiplier
   riskAmount *= confluenceMultiplier;
   
   // Apply volatility adjustment
   double volatility = GetCachedVolatility();
   double avgVolatility = 0.05; // 5% average volatility assumption
   double volatilityAdjustment = 1.0 + ((avgVolatility - volatility) * 2.0); // +/-20% max
   volatilityAdjustment = MathMax(0.8, MathMin(1.2, volatilityAdjustment));
   riskAmount *= volatilityAdjustment;
   
   // Calculate position size
   double riskDistance = MathAbs(entryPrice - stopLoss);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   
   if(riskDistance > 0 && tickValue > 0 && tickSize > 0)
   {
      double positionSize = riskAmount / (riskDistance * tickValue / tickSize);
      
      // Normalize to lot step
      double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      positionSize = MathFloor(positionSize / lotStep) * lotStep;
      
      // Apply limits
      double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      
      positionSize = MathMax(minLot, MathMin(maxLot, positionSize));
      
      return positionSize;
   }
   
   return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
}

//+------------------------------------------------------------------+
//| Is Institutional Level                                          |
//+------------------------------------------------------------------+
bool IsInstitutionalLevel(double price, double atr)
{
   double levels[] = {10.0, 25.0, 50.0, 100.0};
   
   for(int i = 0; i < ArraySize(levels); i++)
   {
      double level = levels[i];
      double remainder = MathMod(price, level);
      
      if(remainder <= atr * 0.3 || remainder >= level - atr * 0.3)
      {
         return true;
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Calculate Confluence Score                                      |
//+------------------------------------------------------------------+
double CalculateConfluenceScore()
{
   double structureScore = CalculateStructureConfluence();
   double patternScore = CalculatePatternConfluence(Rates[RatesTotal-1].close, GetCachedATR());
   double timingScore = CalculateTimingConfluence();
   double liquidityScore = CalculateLiquidityConfluence(Rates[RatesTotal-1].close, GetCachedATR());
   double pdScore = CalculatePremiumDiscountConfluence();
   
   double overallConfluence = (structureScore * 0.25) + (patternScore * 0.30) + 
                             (timingScore * 0.20) + (liquidityScore * 0.15) + (pdScore * 0.10);
   
   return overallConfluence;
}

//+------------------------------------------------------------------+
//| Calculate Structure Confluence                                  |
//+------------------------------------------------------------------+
double CalculateStructureConfluence()
{
   double score = 5.0;
   
   if(MarketStructure.hasMarketStructureShift) score += 4.0;
   else if(MarketStructure.hasBreakOfStructure) score += 3.0;
   else if(MarketStructure.hasChangeOfCharacter) score += 2.0;
   
   if(MarketStructure.isDisplacement)
   {
      if(MarketStructure.displacementSize > 3.0) score += 2.0;
      else if(MarketStructure.displacementSize > 2.0) score += 1.5;
      else if(MarketStructure.displacementSize > 1.5) score += 1.0;
   }
   
   if(MarketStructure.structureConfirmed) score += 1.0;
   
   return MathMax(1.0, MathMin(10.0, score));
}

//+------------------------------------------------------------------+
//| Calculate Pattern Confluence                                    |
//+------------------------------------------------------------------+
double CalculatePatternConfluence(double currentPrice, double atr)
{
   double score = 3.0;
   int patternCount = 0;
   
   for(int i = 0; i < FVGCount; i++)
   {
      if(FairValueGaps[i].isActive && 
         MathAbs(FairValueGaps[i].midPrice - currentPrice) <= atr * 2.0)
      {
         patternCount++;
         if(FairValueGaps[i].isOptimalFVG) score += 2.0;
         else score += FairValueGaps[i].strength * 0.2;
      }
   }
   
   for(int i = 0; i < OrderBlockCount; i++)
   {
      if(OrderBlocks[i].isActive && 
         MathAbs(OrderBlocks[i].price - currentPrice) <= atr * 2.0)
      {
         patternCount++;
         if(OrderBlocks[i].isOptimal) score += 2.0;
         else score += OrderBlocks[i].strength * 0.2;
      }
   }
   
   if(patternCount >= 3) score += 2.0;
   else if(patternCount >= 2) score += 1.0;
   
   return MathMax(1.0, MathMin(10.0, score));
}

//+------------------------------------------------------------------+
//| Calculate Liquidity Confluence                                  |
//+------------------------------------------------------------------+
double CalculateLiquidityConfluence(double currentPrice, double atr)
{
   double score = 4.0;
   
   for(int i = 0; i < LiquidityLevelCount; i++)
   {
      if(LiquidityLevels[i].isRaided && 
         TimeCurrent() - LiquidityLevels[i].raidTime <= 300)
      {
         if(LiquidityLevels[i].displacementAfterRaid > atr * 2.0) score += 3.0;
         else score += 1.5;
      }
   }
   
   for(int i = 0; i < LiquidityLevelCount; i++)
   {
      if(LiquidityLevels[i].isActive && 
         MathAbs(LiquidityLevels[i].price - currentPrice) <= atr * 1.0)
      {
         score += LiquidityLevels[i].strength * 0.1;
      }
   }
   
   return MathMax(1.0, MathMin(10.0, score));
}

#endif // AIME_CALCULATIONS_MQH

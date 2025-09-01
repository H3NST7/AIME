//+------------------------------------------------------------------+
//|                                       AIME_MarketStructure.mqh    |
//|                      Complete Market Structure Analysis          |
//+------------------------------------------------------------------+
#ifndef AIME_MARKET_STRUCTURE_MQH
#define AIME_MARKET_STRUCTURE_MQH

//+------------------------------------------------------------------+
//| Analyze Complete Market Structure                               |
//+------------------------------------------------------------------+
void AnalyzeCompleteMarketStructure()
{
   if(RatesTotal < 50) return;
   
   // Check cache validity
   if(PerformanceCache.structureCacheValid && 
      TimeCurrent() - PerformanceCache.structureCacheTime < 300) // 5 minutes cache
   {
      return; // Use cached analysis
   }
   
   double atr = GetCachedATR();
   if(atr <= 0) return;
   
   // Analyze swing points with enhanced detection
   AnalyzeStructureFromSwings();
   
   // Detect market structure changes
   DetectStructureChanges(atr);
   
   // Classify current structure
   ClassifyCurrentStructure();
   
   // Detect displacements
   if(DetectDisplacements)
   {
      CheckForDisplacement();
   }
   
   // Update cache
   PerformanceCache.structureCacheValid = true;
   PerformanceCache.structureCacheTime = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Analyze Structure From Swings                                   |
//+------------------------------------------------------------------+
void AnalyzeStructureFromSwings()
{
   if(RatesTotal < StructureLookback * 2) return;
   
   double atr = GetCachedATR();
   double volatility = GetCachedVolatility();
   
   // Dynamic lookback based on volatility
   int lookback = (int)(StructureLookback * (1.0 + volatility * 0.5));
   lookback = MathMin(lookback, RatesTotal / 4);
   
   // Find significant swing highs
   for(int i = lookback; i < RatesTotal - lookback; i++)
   {
      bool isSwingHigh = true;
      double currentHigh = Rates[i].high;
      
      // Check significance using ATR
      double minSignificance = atr * 0.25; // 25% of ATR minimum
      
      // Check left side
      for(int j = i - lookback; j < i; j++)
      {
         if(Rates[j].high >= currentHigh - minSignificance)
         {
            isSwingHigh = false;
            break;
         }
      }
      
      // Check right side
      if(isSwingHigh)
      {
         for(int j = i + 1; j <= i + lookback; j++)
         {
            if(Rates[j].high >= currentHigh - minSignificance)
            {
               isSwingHigh = false;
               break;
            }
         }
      }
      
      // Validate with volume if available
      if(isSwingHigh && Rates[i].tick_volume > 0)
      {
         double avgVolume = CalculateAverageVolume(i, 20);
         if(Rates[i].tick_volume < avgVolume * 0.8) // Below average volume
         {
            isSwingHigh = false;
         }
      }
      
      if(isSwingHigh)
      {
         ProcessSwingHigh(currentHigh, Rates[i].time, i);
      }
   }
   
   // Find significant swing lows (similar logic)
   for(int i = lookback; i < RatesTotal - lookback; i++)
   {
      bool isSwingLow = true;
      double currentLow = Rates[i].low;
      
      double minSignificance = atr * 0.25;
      
      // Check left side
      for(int j = i - lookback; j < i; j++)
      {
         if(Rates[j].low <= currentLow + minSignificance)
         {
            isSwingLow = false;
            break;
         }
      }
      
      // Check right side
      if(isSwingLow)
      {
         for(int j = i + 1; j <= i + lookback; j++)
         {
            if(Rates[j].low <= currentLow + minSignificance)
            {
               isSwingLow = false;
               break;
            }
         }
      }
      
      // Validate with volume
      if(isSwingLow && Rates[i].tick_volume > 0)
      {
         double avgVolume = CalculateAverageVolume(i, 20);
         if(Rates[i].tick_volume < avgVolume * 0.8)
         {
            isSwingLow = false;
         }
      }
      
      if(isSwingLow)
      {
         ProcessSwingLow(currentLow, Rates[i].time, i);
      }
   }
}

//+------------------------------------------------------------------+
//| Process Swing High                                              |
//+------------------------------------------------------------------+
void ProcessSwingHigh(double price, datetime time, int index)
{
   double atr = GetCachedATR();
   
   // Determine if this is a higher high or lower high
   if(MarketStructure.lastHigherHigh == 0 || price > MarketStructure.lastHigherHigh + atr * 0.2)
   {
      // Higher High detected
      MarketStructure.lastHigherHigh = price;
      MarketStructure.lastHigherHighTime = time;
      
      // Check for potential BOS
      if(MarketStructure.lastLowerLow > 0 && 
         price > MarketStructure.lastLowerHigh + atr * DisplacementThreshold)
      {
         MarketStructure.hasBreakOfStructure = true;
         MarketStructure.bosLevel = MarketStructure.lastLowerHigh;
      }
   }
   else if(price < MarketStructure.lastHigherHigh - atr * 0.2)
   {
      // Lower High detected
      MarketStructure.lastLowerHigh = price;
      MarketStructure.lastLowerHighTime = time;
      
      // Check for potential CHoCH
      if(MarketStructure.lastHigherHigh > 0 && 
         price < MarketStructure.lastHigherHigh - atr * ChangeOfCharacterThreshold)
      {
         MarketStructure.hasChangeOfCharacter = true;
         MarketStructure.chochLevel = price;
      }
   }
}

//+------------------------------------------------------------------+
//| Process Swing Low                                               |
//+------------------------------------------------------------------+
void ProcessSwingLow(double price, datetime time, int index)
{
   double atr = GetCachedATR();
   
   // Determine if this is a higher low or lower low
   if(MarketStructure.lastLowerLow == 0 || price < MarketStructure.lastLowerLow - atr * 0.2)
   {
      // Lower Low detected
      MarketStructure.lastLowerLow = price;
      MarketStructure.lastLowerLowTime = time;
      
      // Check for potential BOS
      if(MarketStructure.lastHigherHigh > 0 && 
         price < MarketStructure.lastHigherLow - atr * DisplacementThreshold)
      {
         MarketStructure.hasBreakOfStructure = true;
         MarketStructure.bosLevel = MarketStructure.lastHigherLow;
      }
   }
   else if(price > MarketStructure.lastLowerLow + atr * 0.2)
   {
      // Higher Low detected
      MarketStructure.lastHigherLow = price;
      MarketStructure.lastHigherLowTime = time;
      
      // Check for potential CHoCH
      if(MarketStructure.lastLowerLow > 0 && 
         price > MarketStructure.lastLowerLow + atr * ChangeOfCharacterThreshold)
      {
         MarketStructure.hasChangeOfCharacter = true;
         MarketStructure.chochLevel = price;
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Structure Changes                                         |
//+------------------------------------------------------------------+
void DetectStructureChanges(double atr)
{
   ENUM_AIME_STRUCTURE previousStructure = MarketStructure.currentStructure;
   
   // Reset change flags
   MarketStructure.hasBreakOfStructure = false;
   MarketStructure.hasChangeOfCharacter = false;
   MarketStructure.hasMarketStructureShift = false;
   
   // Analyze recent price action for structure changes
   if(RatesTotal < 20) return;
   
   double recentHigh = Rates[RatesTotal-1].high;
   double recentLow = Rates[RatesTotal-1].low;
   
   // Find highest high and lowest low in recent bars
   for(int i = RatesTotal - 20; i < RatesTotal; i++)
   {
      if(Rates[i].high > recentHigh) recentHigh = Rates[i].high;
      if(Rates[i].low < recentLow) recentLow = Rates[i].low;
   }
   
   // Detect BOS (Break of Structure)
   if(MarketStructure.lastHigherLow > 0 && recentLow < MarketStructure.lastHigherLow - atr * DisplacementThreshold)
   {
      MarketStructure.hasBreakOfStructure = true;
      MarketStructure.bosLevel = MarketStructure.lastHigherLow;
      MarketStructure.currentStructure = BEARISH_BOS;
   }
   else if(MarketStructure.lastLowerHigh > 0 && recentHigh > MarketStructure.lastLowerHigh + atr * DisplacementThreshold)
   {
      MarketStructure.hasBreakOfStructure = true;
      MarketStructure.bosLevel = MarketStructure.lastLowerHigh;
      MarketStructure.currentStructure = BULLISH_BOS;
   }
   
   // Detect CHoCH (Change of Character)
   else if(MarketStructure.lastLowerLow > 0 && recentLow > MarketStructure.lastLowerLow + atr * ChangeOfCharacterThreshold)
   {
      MarketStructure.hasChangeOfCharacter = true;
      MarketStructure.chochLevel = recentLow;
      MarketStructure.currentStructure = BULLISH_CHoCH;
   }
   else if(MarketStructure.lastHigherHigh > 0 && recentHigh < MarketStructure.lastHigherHigh - atr * ChangeOfCharacterThreshold)
   {
      MarketStructure.hasChangeOfCharacter = true;
      MarketStructure.chochLevel = recentHigh;
      MarketStructure.currentStructure = BEARISH_CHoCH;
   }
   
   // Detect MSS (Market Structure Shift) - Major reversal
   if(DetectMarketStructureShifts)
   {
      DetectMarketStructureShift(atr);
   }
   
   // Update previous structure
   if(MarketStructure.currentStructure != previousStructure)
   {
      MarketStructure.previousStructure = previousStructure;
      MarketStructure.structureConfirmed = true;
      Print("Structure Change Detected: ", EnumToString(previousStructure), " -> ", EnumToString(MarketStructure.currentStructure));
   }
}

//+------------------------------------------------------------------+
//| Detect Market Structure Shift                                   |
//+------------------------------------------------------------------+
void DetectMarketStructureShift(double atr)
{
   if(RatesTotal < 50) return;
   
   // Look for major structure reversals
   double longTermHigh = 0;
   double longTermLow = DBL_MAX;
   
   // Analyze longer-term structure (50 bars)
   for(int i = RatesTotal - 50; i < RatesTotal; i++)
   {
      if(Rates[i].high > longTermHigh) longTermHigh = Rates[i].high;
      if(Rates[i].low < longTermLow) longTermLow = Rates[i].low;
   }
   
   double currentPrice = Rates[RatesTotal-1].close;
   double priceRange = longTermHigh - longTermLow;
   
   // MSS Detection Logic
   if(priceRange > atr * 5.0) // Significant range
   {
      // Bullish MSS: Price breaks above previous significant high with strong momentum
      if(currentPrice > longTermHigh - atr * 0.5 && 
         MarketStructure.currentStructure == BEARISH_BOS)
      {
         // Confirm with displacement
         double displacement = CalculateRecentDisplacement(10);
         if(displacement > atr * 2.0)
         {
            MarketStructure.hasMarketStructureShift = true;
            MarketStructure.mssLevel = longTermHigh;
            MarketStructure.currentStructure = BULLISH_MSS;
         }
      }
      
      // Bearish MSS: Price breaks below previous significant low with strong momentum
      else if(currentPrice < longTermLow + atr * 0.5 && 
              MarketStructure.currentStructure == BULLISH_BOS)
      {
         double displacement = CalculateRecentDisplacement(10);
         if(displacement > atr * 2.0)
         {
            MarketStructure.hasMarketStructureShift = true;
            MarketStructure.mssLevel = longTermLow;
            MarketStructure.currentStructure = BEARISH_MSS;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Classify Current Structure                                      |
//+------------------------------------------------------------------+
void ClassifyCurrentStructure()
{
   if(MarketStructure.hasMarketStructureShift)
   {
      // MSS already classified in DetectMarketStructureShift
      MarketStructure.structureStrength = 9.0; // Very strong
   }
   else if(MarketStructure.hasBreakOfStructure)
   {
      // BOS classification with strength calculation
      double displacement = MarketStructure.displacementSize;
      if(displacement > 3.0)
         MarketStructure.structureStrength = 8.0; // Strong BOS
      else if(displacement > 2.0)
         MarketStructure.structureStrength = 6.0; // Moderate BOS
      else
         MarketStructure.structureStrength = 4.0; // Weak BOS
   }
   else if(MarketStructure.hasChangeOfCharacter)
   {
      // CHoCH classification
      MarketStructure.structureStrength = 5.0; // Moderate strength
   }
   else
   {
      // Range-bound or other conditions
      double recentRange = CalculateRecentRange(20);
      double atr = GetCachedATR();
      
      if(recentRange < atr * 1.5)
      {
         MarketStructure.currentStructure = RANGE_BOUND;
         MarketStructure.structureStrength = 2.0;
      }
      else
      {
         // Analyze for accumulation/manipulation/distribution
         AnalyzeMarketPhase();
      }
   }
   
   // Detect inducement traps
   DetectInducementTraps();
}

//+------------------------------------------------------------------+
//| Check For Displacement                                          |
//+------------------------------------------------------------------+
void CheckForDisplacement()
{
   if(RatesTotal < 5) return;
   
   double atr = GetCachedATR();
   MarketStructure.isDisplacement = false;
   MarketStructure.displacementSize = 0;
   
   // Method 1: Single Candle Displacement
   for(int i = RatesTotal - 5; i < RatesTotal; i++)
   {
      double candleSize = MathAbs(Rates[i].close - Rates[i].open);
      double candleRange = Rates[i].high - Rates[i].low;
      double bodyRatio = candleSize / candleRange;
      
      if(candleSize > DisplacementThreshold * atr && bodyRatio > 0.7)
      {
         MarketStructure.isDisplacement = true;
         MarketStructure.displacementSize = candleSize / atr;
         break;
      }
   }
   
   // Method 2: Sequential Displacement (2-3 candles)
   if(!MarketStructure.isDisplacement && RatesTotal >= 3)
   {
      // Check last 3 candles for sequential displacement
      double totalMovement = 0;
      bool sameDirection = true;
      
      for(int i = RatesTotal - 3; i < RatesTotal - 1; i++)
      {
         double movement = Rates[i].close - Rates[i].open;
         totalMovement += movement;
         
         // Check direction consistency
         if(i > RatesTotal - 3)
         {
            double prevMovement = Rates[i-1].close - Rates[i-1].open;
            if((movement > 0 && prevMovement < 0) || (movement < 0 && prevMovement > 0))
            {
               sameDirection = false;
               break;
            }
         }
      }
      
      if(sameDirection && MathAbs(totalMovement) > DisplacementThreshold * atr * 1.5)
      {
         MarketStructure.isDisplacement = true;
         MarketStructure.displacementSize = MathAbs(totalMovement) / atr;
      }
   }
   
   // Method 3: Gap Displacement
   if(!MarketStructure.isDisplacement && RatesTotal >= 2)
   {
      double gap = MathAbs(Rates[RatesTotal-1].open - Rates[RatesTotal-2].close);
      if(gap > atr * 0.5)
      {
         MarketStructure.isDisplacement = true;
         MarketStructure.displacementSize = gap / atr;
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Inducement Traps                                         |
//+------------------------------------------------------------------+
void DetectInducementTraps()
{
   if(RatesTotal < 20) return;
   
   double atr = GetCachedATR();
   MarketStructure.isInducementTrap = false;
   
   // Look for false breakouts that reverse quickly
   for(int i = RatesTotal - 10; i < RatesTotal - 2; i++)
   {
      // Check for break above recent high
      double recentHigh = 0;
      for(int j = i - 10; j < i; j++)
      {
         if(Rates[j].high > recentHigh) recentHigh = Rates[j].high;
      }
      
      // False breakout above high
      if(Rates[i].high > recentHigh + atr * 0.1 && 
         Rates[i].close < recentHigh &&
         Rates[i+1].close < recentHigh - atr * 0.2)
      {
         MarketStructure.isInducementTrap = true;
         MarketStructure.inducementLevel = recentHigh;
         break;
      }
      
      // Check for break below recent low
      double recentLow = DBL_MAX;
      for(int j = i - 10; j < i; j++)
      {
         if(Rates[j].low < recentLow) recentLow = Rates[j].low;
      }
      
      // False breakout below low
      if(Rates[i].low < recentLow - atr * 0.1 && 
         Rates[i].close > recentLow &&
         Rates[i+1].close > recentLow + atr * 0.2)
      {
         MarketStructure.isInducementTrap = true;
         MarketStructure.inducementLevel = recentLow;
         break;
      }
   }
}

#endif // AIME_MARKET_STRUCTURE_MQH

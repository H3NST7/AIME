//+------------------------------------------------------------------+
//|                                       AIME_FairValueGaps.mqh     |
//|                      Complete Fair Value Gap Analysis            |
//+------------------------------------------------------------------+
#ifndef AIME_FAIR_VALUE_GAPS_MQH
#define AIME_FAIR_VALUE_GAPS_MQH

//+------------------------------------------------------------------+
//| Detect And Analyze Fair Value Gaps                              |
//+------------------------------------------------------------------+
void DetectAndAnalyzeFairValueGaps()
{
   if(RatesTotal < 10) return;
   
   double atr = GetCachedATR();
   if(atr <= 0) return;
   
   // Clean up old FVGs first
   CleanupOldFVGs();
   
   // Detect new FVGs using multiple methods
   for(int i = 2; i < RatesTotal - 1; i++)
   {
      // Classic 3-candle FVG pattern
      DetectClassicFVG(i, atr);
      
      // Extended 4-5 candle FVG patterns
      if(i >= 4)
         DetectExtendedFVG(i, atr);
      
      // Volume-based FVGs
      DetectVolumeFVG(i, atr);
   }
   
   // Update existing FVGs
   UpdateExistingFVGs();
}

//+------------------------------------------------------------------+
//| Detect Classic 3-Candle FVG                                     |
//+------------------------------------------------------------------+
void DetectClassicFVG(int index, double atr)
{
   if(index < 2 || index >= RatesTotal - 1) return;
   
   // 3-candle FVG pattern
   double candle0High = Rates[index-2].high;
   double candle0Low = Rates[index-2].low;
   double candle2High = Rates[index].high;
   double candle2Low = Rates[index].low;
   
   double fvgTop = 0, fvgBottom = 0;
   ENUM_AIME_PATTERN fvgDirection = FAIR_VALUE_GAP_BULLISH;
   bool validFVG = false;
   
   // Bullish FVG: Gap between candle 0 high and candle 2 low
   if(candle0High < candle2Low)
   {
      double gapSize = candle2Low - candle0High;
      if(gapSize >= atr * 0.1 && gapSize <= atr * 6.0)
      {
         fvgTop = candle2Low;
         fvgBottom = candle0High;
         fvgDirection = FAIR_VALUE_GAP_BULLISH;
         validFVG = true;
      }
   }
   
   // Bearish FVG: Gap between candle 0 low and candle 2 high
   else if(candle0Low > candle2High)
   {
      double gapSize = candle0Low - candle2High;
      if(gapSize >= atr * 0.1 && gapSize <= atr * 6.0)
      {
         fvgTop = candle0Low;
         fvgBottom = candle2High;
         fvgDirection = FAIR_VALUE_GAP_BEARISH;
         validFVG = true;
      }
   }
   
   if(validFVG)
   {
      if(ValidateFVGQuality(index, fvgTop, fvgBottom, fvgDirection, atr))
      {
         CreateNewFVG(fvgTop, fvgBottom, fvgDirection, Rates[index].time, index, atr, false);
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Extended FVG Patterns                                    |
//+------------------------------------------------------------------+
void DetectExtendedFVG(int index, double atr)
{
   // Extended FVG patterns - looking for 4-5 candle formations
   if(index < 4) return;
   
   for(int lookback = 3; lookback <= 4; lookback++)
   {
      if(index < lookback + 1) continue;
      
      double firstCandleHigh = Rates[index - lookback - 1].high;
      double firstCandleLow = Rates[index - lookback - 1].low;
      double lastCandleHigh = Rates[index].high;
      double lastCandleLow = Rates[index].low;
      
      // Check for gaps in extended patterns
      if(firstCandleHigh < lastCandleLow)
      {
         double gapSize = lastCandleLow - firstCandleHigh;
         if(gapSize >= atr * 0.15 && gapSize <= atr * 8.0)
         {
            if(ValidateFVGQuality(index, lastCandleLow, firstCandleHigh, FAIR_VALUE_GAP_BULLISH, atr))
            {
               CreateNewFVG(lastCandleLow, firstCandleHigh, FAIR_VALUE_GAP_BULLISH, Rates[index].time, index, atr, false);
               break;
            }
         }
      }
      else if(firstCandleLow > lastCandleHigh)
      {
         double gapSize = firstCandleLow - lastCandleHigh;
         if(gapSize >= atr * 0.15 && gapSize <= atr * 8.0)
         {
            if(ValidateFVGQuality(index, firstCandleLow, lastCandleHigh, FAIR_VALUE_GAP_BEARISH, atr))
            {
               CreateNewFVG(firstCandleLow, lastCandleHigh, FAIR_VALUE_GAP_BEARISH, Rates[index].time, index, atr, false);
               break;
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Volume-Based FVG                                         |
//+------------------------------------------------------------------+
void DetectVolumeFVG(int index, double atr)
{
   if(index < 2) return;
   
   if(Rates[index].tick_volume == 0) return;
   
   double avgVolume = CalculateAverageVolume(index, 20);
   if(avgVolume == 0) return;
   
   // Check for high volume candles
   if(Rates[index].tick_volume > avgVolume * 3.0 || 
      Rates[index-1].tick_volume > avgVolume * 3.0 || 
      Rates[index-2].tick_volume > avgVolume * 3.0)
   {
      DetectClassicFVG(index, atr);
      
      // Mark as volume FVG if detected
      if(FVGCount > 0)
      {
         FairValueGaps[FVGCount-1].isVolumeFVG = true;
         FairValueGaps[FVGCount-1].strength += 2.0;
         FairValueGaps[FVGCount-1].strength = MathMin(10.0, FairValueGaps[FVGCount-1].strength);
      }
   }
}

//+------------------------------------------------------------------+
//| Validate FVG Quality                                            |
//+------------------------------------------------------------------+
bool ValidateFVGQuality(int index, double top, double bottom, ENUM_AIME_PATTERN direction, double atr)
{
   // Size validation
   double gapSize = top - bottom;
   if(gapSize < atr * 0.1 || gapSize > atr * 6.0) return false;
   
   // Displacement validation
   double displacement = CalculateDisplacementAtIndex(index, 3);
   if(displacement < atr * 1.2) return false;
   
   // Structure alignment validation
   if(!ValidateStructureAlignment(direction)) return false;
   
   // Duplicate check
   if(IsDuplicateFVG(top, bottom, atr)) return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Create New FVG                                                  |
//+------------------------------------------------------------------+
void CreateNewFVG(double top, double bottom, ENUM_AIME_PATTERN direction, datetime time, int candleIndex, double atr, bool isVolumeBased)
{
   if(FVGCount >= ArraySize(FairValueGaps)) return;
   
   SFairValueGap newFVG;
   newFVG.topPrice = top;
   newFVG.bottomPrice = bottom;
   newFVG.midPrice = (top + bottom) / 2.0;
   newFVG.startTime = time;
   newFVG.endTime = TimeCurrent();
   newFVG.direction = direction;
   newFVG.isActive = true;
   newFVG.atrAtFormation = atr;
   newFVG.candleIndex = candleIndex;
   newFVG.isVolumeFVG = isVolumeBased;
   
   // Calculate FVG strength
   newFVG.strength = CalculateFVGStrength(newFVG, atr);
   newFVG.displacement = CalculateDisplacementAtIndex(candleIndex, 3);
   newFVG.isOptimalFVG = (newFVG.strength >= OptimalFVGThreshold);
   newFVG.isInstitutional = IsInstitutionalLevel(newFVG.midPrice, atr);
   
   FairValueGaps[FVGCount] = newFVG;
   FVGCount++;
   
   Print("New FVG Created: ", (direction == FAIR_VALUE_GAP_BULLISH ? "Bullish" : "Bearish"), 
         " | Strength: ", newFVG.strength, " | Size: ", (top-bottom)/atr, " ATR");
}

//+------------------------------------------------------------------+
//| Calculate FVG Strength                                          |
//+------------------------------------------------------------------+
double CalculateFVGStrength(SFairValueGap &fvg, double atr)
{
   double strength = 5.0; // Base strength
   
   // Size component (20% weight)
   double gapSize = fvg.topPrice - fvg.bottomPrice;
   double sizeRatio = gapSize / atr;
   if(sizeRatio > 2.0) strength += 2.0;
   else if(sizeRatio > 1.0) strength += 1.0;
   
   // Displacement component (30% weight)
   if(fvg.displacement > 3.0) strength += 3.0;
   else if(fvg.displacement > 2.0) strength += 2.0;
   
   // Volume component (20% weight)
   if(fvg.isVolumeFVG) strength += 2.0;
   
   // Structure alignment (15% weight)
   if(ValidateStructureAlignment(fvg.direction)) strength += 1.5;
   
   // Killzone timing (30% weight)
   if(IsOptimalKillzoneTime(fvg.startTime)) strength += 3.0;
   
   // Premium/Discount alignment (15% weight)
   if(IsPremiumDiscountAligned(fvg.direction, fvg.midPrice)) strength += 1.5;
   
   // Institutional level bonus (10% weight)
   if(fvg.isInstitutional) strength += 1.0;
   
   return MathMax(1.0, MathMin(10.0, strength));
}

//+------------------------------------------------------------------+
//| Update Existing FVGs                                            |
//+------------------------------------------------------------------+
void UpdateExistingFVGs()
{
   double currentPrice = Rates[RatesTotal-1].close;
   
   for(int i = 0; i < FVGCount; i++)
   {
      if(!FairValueGaps[i].isActive) continue;
      
      // Update fill percentage
      double gapSize = FairValueGaps[i].topPrice - FairValueGaps[i].bottomPrice;
      double fillLevel = 0;
      
      if(FairValueGaps[i].direction == FAIR_VALUE_GAP_BULLISH)
      {
         if(currentPrice > FairValueGaps[i].bottomPrice)
         {
            fillLevel = MathMin(currentPrice, FairValueGaps[i].topPrice);
            FairValueGaps[i].fillPercentage = ((fillLevel - FairValueGaps[i].bottomPrice) / gapSize) * 100.0;
         }
      }
      else // FAIR_VALUE_GAP_BEARISH
      {
         if(currentPrice < FairValueGaps[i].topPrice)
         {
            fillLevel = MathMax(currentPrice, FairValueGaps[i].bottomPrice);
            FairValueGaps[i].fillPercentage = ((FairValueGaps[i].topPrice - fillLevel) / gapSize) * 100.0;
         }
      }
      
      // Mark as filled if percentage > 90%
      if(FairValueGaps[i].fillPercentage >= 90.0)
      {
         FairValueGaps[i].isFilled = true;
      }
      
      // Check for rejection
      if(MathAbs(currentPrice - FairValueGaps[i].midPrice) <= GetCachedATR() * 0.3)
      {
         FairValueGaps[i].rejectionCount++;
      }
      
      // Update end time
      FairValueGaps[i].endTime = TimeCurrent();
   }
}

//+------------------------------------------------------------------+
//| Check Realtime FVG Formation                                    |
//+------------------------------------------------------------------+
void CheckRealtimeFVGFormation()
{
   if(RatesTotal < 3) return;
   
   double atr = GetCachedATR();
   if(atr <= 0) return;
   
   int index = RatesTotal - 1;
   DetectClassicFVG(index, atr);
   
   // Check for FVG inversions
   CheckForFVGInversions();
}

//+------------------------------------------------------------------+
//| Check For FVG Inversions                                        |
//+------------------------------------------------------------------+
void CheckForFVGInversions()
{
   for(int i = 0; i < FVGCount; i++)
   {
      if(!FairValueGaps[i].isActive || FairValueGaps[i].isInversion) continue;
      
      // Check if FVG has been rejected multiple times
      if(FairValueGaps[i].rejectionCount >= 2)
      {
         // Invert the FVG
         FairValueGaps[i].isInversion = true;
         FairValueGaps[i].direction = (FairValueGaps[i].direction == FAIR_VALUE_GAP_BULLISH) ? 
                                      FAIR_VALUE_GAP_BEARISH : FAIR_VALUE_GAP_BULLISH;
         FairValueGaps[i].strength += 1.5;
         FairValueGaps[i].strength = MathMin(10.0, FairValueGaps[i].strength);
         
         Print("FVG Inversion Detected at ", FairValueGaps[i].midPrice);
      }
   }
}

//+------------------------------------------------------------------+
//| Cleanup Old FVGs                                                |
//+------------------------------------------------------------------+
void CleanupOldFVGs()
{
   datetime currentTime = TimeCurrent();
   double atr = GetCachedATR();
   
   for(int i = 0; i < FVGCount; i++)
   {
      if(!FairValueGaps[i].isActive) continue;
      
      // Calculate max age based on FVG quality
      int maxAge = 4 * 3600; // 4 hours default
      if(FairValueGaps[i].isOptimalFVG) maxAge = 8 * 3600; // 8 hours for optimal FVGs
      
      // Remove old FVGs
      if(currentTime - FairValueGaps[i].startTime > maxAge)
      {
         FairValueGaps[i].isActive = false;
         continue;
      }
      
      // Remove weak FVGs that are old
      if(FairValueGaps[i].strength < 3.0 && currentTime - FairValueGaps[i].startTime > 1800)
      {
         FairValueGaps[i].isActive = false;
         continue;
      }
      
      // Remove filled FVGs
      if(FairValueGaps[i].fillPercentage >= 90.0)
      {
         FairValueGaps[i].isActive = false;
         continue;
      }
      
      // Remove FVGs too far from current price
      double currentPrice = Rates[RatesTotal-1].close;
      if(MathAbs(FairValueGaps[i].midPrice - currentPrice) > atr * 10.0)
      {
         FairValueGaps[i].isActive = false;
      }
   }
}

//+------------------------------------------------------------------+
//| Check if FVG is Duplicate                                       |
//+------------------------------------------------------------------+
bool IsDuplicateFVG(double top, double bottom, double atr)
{
   for(int i = 0; i < FVGCount; i++)
   {
      if(FairValueGaps[i].isActive)
      {
         if(MathAbs(FairValueGaps[i].topPrice - top) <= atr * 0.3 &&
            MathAbs(FairValueGaps[i].bottomPrice - bottom) <= atr * 0.3)
         {
            return true;
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Calculate FVG Confluence                                        |
//+------------------------------------------------------------------+
double CalculateFVGConfluence(int fvgIndex)
{
   double confluence = 0.5; // Base for FVG
   
   // FVG quality (40% weight)
   confluence += (FairValueGaps[fvgIndex].strength / 10.0) * 0.40;
   
   // Structure alignment (25% weight)
   if(ValidateStructureAlignment(FairValueGaps[fvgIndex].direction))
   {
      if(MarketStructure.hasBreakOfStructure) confluence += 0.20;
      else if(MarketStructure.hasChangeOfCharacter) confluence += 0.15;
      else confluence += 0.10;
   }
   
   // Premium/Discount alignment (20% weight)
   if(IsPremiumDiscountAligned(FairValueGaps[fvgIndex].direction, FairValueGaps[fvgIndex].midPrice))
      confluence += 0.20;
   
   // Timing quality (10% weight)
   if(IsOptimalTradingTime) confluence += 0.10;
   else if(IsActiveKillzoneTime(TimeCurrent())) confluence += 0.05;
   
   // Special FVG bonuses (5% weight)
   if(FairValueGaps[fvgIndex].isOptimalFVG) confluence += 0.03;
   if(FairValueGaps[fvgIndex].isVolumeFVG) confluence += 0.02;
   
   return MathMin(1.0, confluence);
}

#endif // AIME_FAIR_VALUE_GAPS_MQH

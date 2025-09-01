//+------------------------------------------------------------------+
//|                                     AIME_PremiumDiscount.mqh     |
//|                    Premium/Discount Array Analysis Module        |
//+------------------------------------------------------------------+
#ifndef AIME_PREMIUM_DISCOUNT_MQH
#define AIME_PREMIUM_DISCOUNT_MQH

//+------------------------------------------------------------------+
//| Update Premium Discount Status                                  |
//+------------------------------------------------------------------+
void UpdatePremiumDiscountStatus()
{
   if(RatesTotal < PremiumDiscountLookback) return;
   
   double high = 0;
   double low = DBL_MAX;
   double volumeWeightedPrice = 0;
   double totalVolume = 0;
   
   // Calculate lookback bars based on timeframe
   int lookbackBars = PremiumDiscountLookback;
   if(Period() == PERIOD_H1) lookbackBars = PremiumDiscountLookback;
   else if(Period() == PERIOD_M15) lookbackBars = PremiumDiscountLookback * 4;
   else if(Period() == PERIOD_M5) lookbackBars = PremiumDiscountLookback * 12;
   
   lookbackBars = MathMin(lookbackBars, RatesTotal - 1);
   
   // Find range high and low
   for(int i = RatesTotal - lookbackBars; i < RatesTotal; i++)
   {
      if(Rates[i].high > high) high = Rates[i].high;
      if(Rates[i].low < low) low = Rates[i].low;
      
      // Calculate volume weighted average price
      double barVolume = (double)Rates[i].tick_volume;
      double barPrice = (Rates[i].high + Rates[i].low + Rates[i].close * 2) / 4.0;
      volumeWeightedPrice += barPrice * barVolume;
      totalVolume += barVolume;
   }
   
   RangeHigh = high;
   RangeLow = low;
   
   double currentPrice = Rates[RatesTotal-1].close;
   double range = RangeHigh - RangeLow;
   
   if(range > 0)
   {
      CurrentPremiumDiscount = (currentPrice - RangeLow) / range;
   }
   else
   {
      CurrentPremiumDiscount = 0.5;
   }
   
   // Determine zone status
   IsInPremium = (CurrentPremiumDiscount >= PremiumThreshold);
   IsInDiscount = (CurrentPremiumDiscount <= DiscountThreshold);
   IsInEquilibrium = (!IsInPremium && !IsInDiscount);
   
   // Check equilibrium zone
   if(MathAbs(CurrentPremiumDiscount - 0.5) <= EquilibriumZone)
   {
      IsInEquilibrium = true;
      IsInPremium = false;
      IsInDiscount = false;
   }
}

//+------------------------------------------------------------------+
//| Is Premium Discount Aligned                                     |
//+------------------------------------------------------------------+
bool IsPremiumDiscountAligned(ENUM_ICT_PATTERN pattern, double price)
{
   // Check if pattern aligns with premium/discount zones
   switch(pattern)
   {
      case FAIR_VALUE_GAP_BULLISH:
      case ORDER_BLOCK_BULLISH:
         // Bullish patterns should be in discount or equilibrium
         return (IsInDiscount || IsInEquilibrium);
         
      case FAIR_VALUE_GAP_BEARISH:
      case ORDER_BLOCK_BEARISH:
         // Bearish patterns should be in premium or equilibrium
         return (IsInPremium || IsInEquilibrium);
         
      default:
         return true;
   }
}

//+------------------------------------------------------------------+
//| Is Near OTE Level                                               |
//+------------------------------------------------------------------+
bool IsNearOTELevel(double price)
{
   if(RangeHigh == 0 || RangeLow == 0) return false;
   
   double range = RangeHigh - RangeLow;
   double tolerance = range * OTETolerance;
   
   // Calculate OTE levels
   double ote618 = RangeLow + (range * OTEFib618);
   double ote705 = RangeLow + (range * OTEFib705);
   double ote786 = RangeLow + (range * OTEFib786);
   
   // Check if price is near any OTE level
   if(MathAbs(price - ote618) <= tolerance ||
      MathAbs(price - ote705) <= tolerance ||
      MathAbs(price - ote786) <= tolerance)
   {
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Calculate Premium Discount Confluence                           |
//+------------------------------------------------------------------+
double CalculatePremiumDiscountConfluence()
{
   double score = 5.0;
   
   // Check alignment with market structure
   if(IsInPremium && MarketStructure.currentStructure == BEARISH_BOS) score += 2.0;
   else if(IsInDiscount && MarketStructure.currentStructure == BULLISH_BOS) score += 2.0;
   else if(IsInEquilibrium) score += 1.0;
   
   // Check if near OTE level
   double currentPrice = Rates[RatesTotal-1].close;
   if(IsNearOTELevel(currentPrice)) score += 1.5;
   
   return MathMax(1.0, MathMin(10.0, score));
}

//+------------------------------------------------------------------+
//| Get Premium Discount Zone Description                           |
//+------------------------------------------------------------------+
string GetPremiumDiscountZone()
{
   if(IsInPremium) return "PREMIUM";
   else if(IsInDiscount) return "DISCOUNT";
   else if(IsInEquilibrium) return "EQUILIBRIUM";
   else return "UNDEFINED";
}

//+------------------------------------------------------------------+
//| Calculate Fibonacci Retracement                                 |
//+------------------------------------------------------------------+
double CalculateFibonacciRetracement(int fibLevel)
{
   if(RatesTotal < 20) return 0;
   
   // Find recent swing high and low
   double swingHigh = 0;
   double swingLow = DBL_MAX;
   
   for(int i = RatesTotal - 20; i < RatesTotal; i++)
   {
      if(Rates[i].high > swingHigh) swingHigh = Rates[i].high;
      if(Rates[i].low < swingLow) swingLow = Rates[i].low;
   }
   
   double range = swingHigh - swingLow;
   double fibRatio = 0;
   
   switch(fibLevel)
   {
      case 236: fibRatio = 0.236; break;
      case 382: fibRatio = 0.382; break;
      case 50:  fibRatio = 0.500; break;
      case 618: fibRatio = 0.618; break;
      case 705: fibRatio = 0.705; break;
      case 786: fibRatio = 0.786; break;
      default: return 0;
   }
   
   // Determine trend direction
   bool uptrend = (Rates[RatesTotal-1].close > Rates[RatesTotal-10].close);
   
   if(uptrend)
      return swingHigh - (range * fibRatio); // Retracement from high
   else
      return swingLow + (range * fibRatio);   // Retracement from low
}

#endif // AIME_PREMIUM_DISCOUNT_MQH

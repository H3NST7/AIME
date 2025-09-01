//+------------------------------------------------------------------+
//|                                        AIME_Correlation.mqh      |
//|                   Multi-Asset Correlation Analysis Module        |
//+------------------------------------------------------------------+
#ifndef AIME_CORRELATION_MQH
#define AIME_CORRELATION_MQH

//+------------------------------------------------------------------+
//| Update Correlation Analysis                                     |
//+------------------------------------------------------------------+
void UpdateCorrelationAnalysis()
{
   if(!UseCorrelationAnalysis) return;
   
   // Update every 5 minutes minimum
   if(TimeCurrent() - LastCorrelationUpdate < 300) return;
   
   // Quick update for key correlations every minute
   if(TimeCurrent() - LastCorrelationUpdate >= 60)
   {
      if(AnalyzeDXY) UpdateSingleCorrelation(0, "USDX");
      if(AnalyzeEquities) UpdateSingleCorrelation(3, "SPX500");
   }
   
   // Full correlation update
   for(int i = 0; i < ArraySize(CorrelationSymbols); i++)
   {
      UpdateSingleCorrelation(i, CorrelationSymbols[i]);
   }
   
   // Calculate overall bias
   CalculateOverallCorrelationBias();
   UpdateTradePermissionsFromCorrelation();
   
   LastCorrelationUpdate = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Update Single Correlation                                       |
//+------------------------------------------------------------------+
void UpdateSingleCorrelation(int index, string symbol)
{
   if(index >= ArraySize(CorrelationValues)) return;
   
   MqlRates correlationRates[];
   int correlationBars = CopyRates(symbol, PERIOD_CURRENT, 0, CorrelationPeriod, correlationRates);
   
   if(correlationBars < CorrelationPeriod)
   {
      Print("Warning: Insufficient data for correlation analysis - ", symbol);
      return;
   }
   
   // Calculate correlation with gold
   double correlation = CalculateCorrelationWithGold(correlationRates, correlationBars);
   
   CorrelationValues[index] = correlation;
   CorrelationStrengths[index] = MathAbs(correlation);
   
   // Update cache
   PerformanceCache.correlationCache[index] = correlation;
   PerformanceCache.correlationCacheTime = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Calculate Correlation With Gold                                 |
//+------------------------------------------------------------------+
double CalculateCorrelationWithGold(MqlRates &correlationRates[], int bars)
{
   if(bars < 10 || RatesTotal < 10) return 0.0;
   
   double goldPrices[];
   double correlationPrices[];
   
   int useBars = MathMin(bars, RatesTotal);
   ArrayResize(goldPrices, useBars);
   ArrayResize(correlationPrices, useBars);
   
   // Fill arrays
   for(int i = 0; i < useBars; i++)
   {
      goldPrices[i] = Rates[RatesTotal - useBars + i].close;
      correlationPrices[i] = correlationRates[bars - useBars + i].close;
   }
   
   return CalculatePearsonCorrelation(goldPrices, correlationPrices, useBars);
}

//+------------------------------------------------------------------+
//| Calculate Pearson Correlation                                   |
//+------------------------------------------------------------------+
double CalculatePearsonCorrelation(double &array1[], double &array2[], int size)
{
   if(size < 2) return 0.0;
   
   // Calculate means
   double mean1 = 0, mean2 = 0;
   for(int i = 0; i < size; i++)
   {
      mean1 += array1[i];
      mean2 += array2[i];
   }
   mean1 /= size;
   mean2 /= size;
   
   // Calculate correlation components
   double numerator = 0;
   double sumSq1 = 0, sumSq2 = 0;
   
   for(int i = 0; i < size; i++)
   {
      double diff1 = array1[i] - mean1;
      double diff2 = array2[i] - mean2;
      
      numerator += diff1 * diff2;
      sumSq1 += diff1 * diff1;
      sumSq2 += diff2 * diff2;
   }
   
   double denominator = MathSqrt(sumSq1 * sumSq2);
   
   if(denominator == 0) return 0.0;
   
   return numerator / denominator;
}

//+------------------------------------------------------------------+
//| Calculate Overall Correlation Bias                              |
//+------------------------------------------------------------------+
void CalculateOverallCorrelationBias()
{
   double overallBias = 0.0;
   double totalWeight = 0.0;
   
   // Weights for each correlation symbol
   double weights[] = {0.40, 0.15, 0.10, 0.35, 0.10, 0.08, 0.12, 0.20};
   //                  USDX  US10Y US02Y SPX500 EURUSD GBPUSD USOIL VIX
   
   for(int i = 0; i < ArraySize(CorrelationSymbols); i++)
   {
      if(i >= ArraySize(weights)) break;
      
      double correlation = CorrelationValues[i];
      double weight = weights[i];
      
      // Inverse correlations for USD and VIX
      if(i == 0 || i == 1 || i == 2) // USDX, US10Y, US02Y
      {
         correlation = -correlation;
      }
      
      if(i == 7) // VIX (inverse correlation)
      {
         correlation = -correlation;
      }
      
      overallBias += correlation * weight;
      totalWeight += weight;
   }
   
   if(totalWeight > 0)
   {
      overallBias /= totalWeight;
   }
   
   // Update market structure strength based on correlation
   MarketStructure.structureStrength = MathMax(MarketStructure.structureStrength, 
                                               5.0 + (MathAbs(overallBias) * 3.0));
}

//+------------------------------------------------------------------+
//| Update Trade Permissions From Correlation                       |
//+------------------------------------------------------------------+
void UpdateTradePermissionsFromCorrelation()
{
   double overallBias = CalculateSmartMoneyIndex();
   
   // Log correlation bias
   if(overallBias > 0.6)
   {
      Print("Correlation Bias: Strong Bullish (", overallBias, ") - Longs Only");
   }
   else if(overallBias > 0.3)
   {
      Print("Correlation Bias: Moderate Bullish (", overallBias, ") - Longs Preferred");
   }
   else if(overallBias >= -0.3)
   {
      Print("Correlation Bias: Neutral (", overallBias, ") - Both Directions");
   }
   else if(overallBias >= -0.6)
   {
      Print("Correlation Bias: Moderate Bearish (", overallBias, ") - Shorts Preferred");
   }
   else
   {
      Print("Correlation Bias: Strong Bearish (", overallBias, ") - Shorts Only");
   }
}

//+------------------------------------------------------------------+
//| Calculate Smart Money Index                                     |
//+------------------------------------------------------------------+
double CalculateSmartMoneyIndex()
{
   double dxyBias = 0, spxBias = 0, bondBias = 0;
   
   // Dollar Index bias
   if(AnalyzeDXY && ArraySize(CorrelationValues) > 0)
   {
      dxyBias = -CorrelationValues[0]; // Inverse correlation with gold
   }
   
   // Equity bias
   if(AnalyzeEquities && ArraySize(CorrelationValues) > 3)
   {
      spxBias = CorrelationValues[3]; // SPX500
   }
   
   // Bond bias
   if(AnalyzeBonds && ArraySize(CorrelationValues) > 1)
   {
      bondBias = -CorrelationValues[1]; // US10Y inverse
   }
   
   // Weighted smart money index
   double smartMoneyIndex = (dxyBias * 0.4) + (spxBias * 0.35) + (bondBias * 0.25);
   
   return MathMax(-1.0, MathMin(1.0, smartMoneyIndex));
}

#endif // AIME_CORRELATION_MQH

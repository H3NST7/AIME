//+------------------------------------------------------------------+
//|                                        AIME_PowerOfThree.mqh     |
//|                        Power of Three Analysis Module            |
//+------------------------------------------------------------------+
#ifndef AIME_POWER_OF_THREE_MQH
#define AIME_POWER_OF_THREE_MQH

//+------------------------------------------------------------------+
//| Analyze Power of Three                                          |
//+------------------------------------------------------------------+
void AnalyzePowerOfThree()
{
   datetime currentTime = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(currentTime, dt);
   
   // Determine current market phase based on time and price action
   ENUM_MARKET_PHASE previousPhase = PowerOfThreeAnalysis.currentPhase;
   
   // Morning session analysis (02:00 - 12:00 GMT)
   if(dt.hour >= 2 && dt.hour < 6)
   {
      // London Open - Typically Accumulation
      PowerOfThreeAnalysis.currentPhase = ACCUMULATION_AM;
      AnalyzeAccumulationPhase();
   }
   else if(dt.hour >= 6 && dt.hour < 10)
   {
      // Mid-morning - Typically Manipulation
      PowerOfThreeAnalysis.currentPhase = MANIPULATION_AM;
      AnalyzeManipulationPhase();
   }
   else if(dt.hour >= 10 && dt.hour < 12)
   {
      // Late morning - Typically Distribution
      PowerOfThreeAnalysis.currentPhase = DISTRIBUTION_AM;
      AnalyzeDistributionPhase();
   }
   
   // Afternoon session analysis (12:00 - 22:00 GMT)
   else if(dt.hour >= 12 && dt.hour < 16)
   {
      // Early afternoon - Accumulation for NY session
      PowerOfThreeAnalysis.currentPhase = ACCUMULATION_PM;
      AnalyzeAccumulationPhase();
   }
   else if(dt.hour >= 16 && dt.hour < 20)
   {
      // NY session - Manipulation/Distribution
      if(dt.hour < 18)
         PowerOfThreeAnalysis.currentPhase = MANIPULATION_PM;
      else
         PowerOfThreeAnalysis.currentPhase = DISTRIBUTION_PM;
      
      if(PowerOfThreeAnalysis.currentPhase == MANIPULATION_PM)
         AnalyzeManipulationPhase();
      else
         AnalyzeDistributionPhase();
   }
   else if(dt.hour >= 20 && dt.hour < 22)
   {
      // End of day rebalancing
      PowerOfThreeAnalysis.currentPhase = REBALANCE_EOD;
      AnalyzeRebalancePhase();
   }
   else
   {
      // Inactive periods
      PowerOfThreeAnalysis.currentPhase = MP_INACTIVE;
      PowerOfThreeAnalysis.phaseStrength = 1.0;
   }
   
   // Phase change detection
   if(PowerOfThreeAnalysis.currentPhase != previousPhase)
   {
      PowerOfThreeAnalysis.phaseStartTime = currentTime;
      PowerOfThreeAnalysis.phaseCandles = 0;
      PowerOfThreeAnalysis.phaseProgress = 0.0;
      Print("Power of 3 Phase Change: ", EnumToString(previousPhase), " -> ", EnumToString(PowerOfThreeAnalysis.currentPhase));
   }
   
   // Update phase metrics
   UpdatePhaseMetrics();
}

//+------------------------------------------------------------------+
//| Analyze Accumulation Phase                                      |
//+------------------------------------------------------------------+
void AnalyzeAccumulationPhase()
{
   if(RatesTotal < 20) return;
   
   // Calculate accumulation range
   double high = 0;
   double low = DBL_MAX;
   int lookback = 20; // Accumulation period
   
   for(int i = RatesTotal - lookback; i < RatesTotal; i++)
   {
      if(Rates[i].high > high) high = Rates[i].high;
      if(Rates[i].low < low) low = Rates[i].low;
   }
   
   PowerOfThreeAnalysis.accumulationHigh = high;
   PowerOfThreeAnalysis.accumulationLow = low;
   PowerOfThreeAnalysis.accumulationMid = (high + low) / 2.0;
   
   // Calculate phase strength
   double range = high - low;
   double atr = GetCachedATR();
   double currentPrice = Rates[RatesTotal-1].close;
   
   // Strength based on range compression and position
   if(range < atr * 0.8) // Tight range indicates strong accumulation
   {
      PowerOfThreeAnalysis.phaseStrength = 8.0;
   }
   else if(range < atr * 1.2)
   {
      PowerOfThreeAnalysis.phaseStrength = 6.0;
   }
   else
   {
      PowerOfThreeAnalysis.phaseStrength = 4.0;
   }
   
   // Check for liquidity grabs during accumulation
   CheckForLiquidityGrabInPhase(high, low);
   
   // Set Market Maker model
   MarketStructure.currentStructure = ACCUMULATION;
}

//+------------------------------------------------------------------+
//| Analyze Manipulation Phase                                      |
//+------------------------------------------------------------------+
void AnalyzeManipulationPhase()
{
   if(RatesTotal < 10) return;
   
   double atr = GetCachedATR();
   
   // Look for manipulation patterns (false breaks, stop hunts)
   double recentHigh = 0;
   double recentLow = DBL_MAX;
   
   for(int i = RatesTotal - 10; i < RatesTotal; i++)
   {
      if(Rates[i].high > recentHigh) recentHigh = Rates[i].high;
      if(Rates[i].low < recentLow) recentLow = Rates[i].low;
   }
   
   PowerOfThreeAnalysis.manipulationHigh = recentHigh;
   PowerOfThreeAnalysis.manipulationLow = recentLow;
   PowerOfThreeAnalysis.manipulationLevel = (recentHigh + recentLow) / 2.0;
   
   // Detect manipulation strength
   double displacement = CalculateRecentDisplacement(5);
   if(displacement > atr * 2.0)
   {
      PowerOfThreeAnalysis.phaseStrength = 9.0; // Strong manipulation
   }
   else if(displacement > atr * 1.5)
   {
      PowerOfThreeAnalysis.phaseStrength = 7.0;
   }
   else
   {
      PowerOfThreeAnalysis.phaseStrength = 5.0;
   }
   
   // Check for liquidity grabs
   if(PowerOfThreeAnalysis.accumulationHigh > 0 && recentHigh > PowerOfThreeAnalysis.accumulationHigh)
   {
      PowerOfThreeAnalysis.hasLiquidityGrab = true;
      PowerOfThreeAnalysis.liquidityGrabLevel = PowerOfThreeAnalysis.accumulationHigh;
   }
   else if(PowerOfThreeAnalysis.accumulationLow > 0 && recentLow < PowerOfThreeAnalysis.accumulationLow)
   {
      PowerOfThreeAnalysis.hasLiquidityGrab = true;
      PowerOfThreeAnalysis.liquidityGrabLevel = PowerOfThreeAnalysis.accumulationLow;
   }
   
   MarketStructure.currentStructure = MANIPULATION;
}

//+------------------------------------------------------------------+
//| Analyze Distribution Phase                                      |
//+------------------------------------------------------------------+
void AnalyzeDistributionPhase()
{
   if(RatesTotal < 15) return;
   
   double atr = GetCachedATR();
   
   // Check if distribution has started
   if(!PowerOfThreeAnalysis.distributionStarted)
   {
      // Look for strong directional movement after manipulation
      double displacement = CalculateRecentDisplacement(5);
      if(displacement > atr * 1.5)
      {
         PowerOfThreeAnalysis.distributionStarted = true;
         
         // Set distribution target based on manipulation range
         if(PowerOfThreeAnalysis.manipulationHigh > PowerOfThreeAnalysis.manipulationLow)
         {
            double manipulationRange = PowerOfThreeAnalysis.manipulationHigh - PowerOfThreeAnalysis.manipulationLow;
            
            // Determine direction
            double currentPrice = Rates[RatesTotal-1].close;
            if(currentPrice > PowerOfThreeAnalysis.manipulationLevel)
            {
               // Bullish distribution
               PowerOfThreeAnalysis.distributionTarget = PowerOfThreeAnalysis.manipulationHigh + manipulationRange * 1.618;
            }
            else
            {
               // Bearish distribution
               PowerOfThreeAnalysis.distributionTarget = PowerOfThreeAnalysis.manipulationLow - manipulationRange * 1.618;
            }
         }
      }
   }
   
   // Update distribution metrics
   if(PowerOfThreeAnalysis.distributionStarted)
   {
      double currentPrice = Rates[RatesTotal-1].close;
      
      // Calculate progress toward target
      if(PowerOfThreeAnalysis.distributionTarget > PowerOfThreeAnalysis.manipulationLevel)
      {
         // Bullish distribution
         double totalDistance = PowerOfThreeAnalysis.distributionTarget - PowerOfThreeAnalysis.manipulationLevel;
         double currentDistance = currentPrice - PowerOfThreeAnalysis.manipulationLevel;
         PowerOfThreeAnalysis.phaseProgress = (currentDistance / totalDistance) * 100.0;
      }
      else
      {
         // Bearish distribution
         double totalDistance = PowerOfThreeAnalysis.manipulationLevel - PowerOfThreeAnalysis.distributionTarget;
         double currentDistance = PowerOfThreeAnalysis.manipulationLevel - currentPrice;
         PowerOfThreeAnalysis.phaseProgress = (currentDistance / totalDistance) * 100.0;
      }
      
      PowerOfThreeAnalysis.phaseProgress = MathMax(0, MathMin(100, PowerOfThreeAnalysis.phaseProgress));
      
      // Calculate phase strength based on momentum
      double momentum = CalculateRecentDisplacement(3);
      if(momentum > atr * 2.0)
         PowerOfThreeAnalysis.phaseStrength = 9.0;
      else if(momentum > atr * 1.0)
         PowerOfThreeAnalysis.phaseStrength = 7.0;
      else
         PowerOfThreeAnalysis.phaseStrength = 5.0;
      
      // Track distribution range
      PowerOfThreeAnalysis.distributionHigh = recentHigh;
      PowerOfThreeAnalysis.distributionLow = recentLow;
   }
   
   MarketStructure.currentStructure = DISTRIBUTION;
}

//+------------------------------------------------------------------+
//| Analyze Rebalance Phase                                         |
//+------------------------------------------------------------------+
void AnalyzeRebalancePhase()
{
   // End of day rebalancing typically shows reduced volatility
   double atr = GetCachedATR();
   double recentRange = CalculateRecentRange(10);
   
   if(recentRange < atr * 0.6)
   {
      PowerOfThreeAnalysis.phaseStrength = 3.0; // Low volatility rebalancing
   }
   else
   {
      PowerOfThreeAnalysis.phaseStrength = 6.0; // Active rebalancing
   }
   
   MarketStructure.currentStructure = REBALANCE;
}

//+------------------------------------------------------------------+
//| Update Phase Metrics                                            |
//+------------------------------------------------------------------+
void UpdatePhaseMetrics()
{
   // Update phase duration
   if(PowerOfThreeAnalysis.phaseStartTime > 0)
   {
      datetime currentTime = TimeCurrent();
      int phaseDuration = (int)((currentTime - PowerOfThreeAnalysis.phaseStartTime) / 60); // Minutes
      
      // Estimate phase candles based on timeframe
      switch(Period())
      {
         case PERIOD_M5:  PowerOfThreeAnalysis.phaseCandles = phaseDuration / 5; break;
         case PERIOD_M15: PowerOfThreeAnalysis.phaseCandles = phaseDuration / 15; break;
         case PERIOD_H1:  PowerOfThreeAnalysis.phaseCandles = phaseDuration / 60; break;
         default:         PowerOfThreeAnalysis.phaseCandles = phaseDuration / (PeriodSeconds() / 60); break;
      }
   }
   
   // Check if phase is optimal for trading
   PowerOfThreeAnalysis.isOptimalPhase = (PowerOfThreeAnalysis.phaseStrength >= 6.0 && 
                                          PowerOfThreeAnalysis.currentPhase != MP_INACTIVE);
   
   // Check phase completion
   if(PowerOfThreeAnalysis.currentPhase == DISTRIBUTION_AM || 
      PowerOfThreeAnalysis.currentPhase == DISTRIBUTION_PM)
   {
      PowerOfThreeAnalysis.phaseComplete = (PowerOfThreeAnalysis.phaseProgress >= 80.0);
   }
}

//+------------------------------------------------------------------+
//| Check For Liquidity Grab In Phase                               |
//+------------------------------------------------------------------+
void CheckForLiquidityGrabInPhase(double high, double low)
{
   // Check if price grabbed liquidity during accumulation phase
   for(int i = 0; i < LiquidityLevelCount; i++)
   {
      if(LiquidityLevels[i].isActive)
      {
         double levelPrice = LiquidityLevels[i].price;
         
         // Check if level was within the accumulation range and was hit
         if(levelPrice >= low && levelPrice <= high)
         {
            // Look for evidence of liquidity grab
            for(int j = RatesTotal - 20; j < RatesTotal; j++)
            {
               if(MathAbs(Rates[j].high - levelPrice) <= GetCachedATR() * 0.2 ||
                  MathAbs(Rates[j].low - levelPrice) <= GetCachedATR() * 0.2)
               {
                  PowerOfThreeAnalysis.hasLiquidityGrab = true;
                  PowerOfThreeAnalysis.liquidityGrabLevel = levelPrice;
                  break;
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Analyze Market Phase                                            |
//+------------------------------------------------------------------+
void AnalyzeMarketPhase()
{
   datetime currentTime = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(currentTime, dt);
   
   // This function is called from ClassifyCurrentStructure
   // It determines the market phase when not in clear trend structure
   
   // Check for accumulation characteristics
   double range = CalculateRecentRange(20);
   double atr = GetCachedATR();
   double volatility = GetCachedVolatility();
   
   if(range < atr * 1.5 && volatility < 0.02)
   {
      MarketStructure.currentStructure = ACCUMULATION;
      MarketStructure.structureStrength = 3.0;
   }
   else if(volatility > 0.05)
   {
      // High volatility suggests manipulation or distribution
      double displacement = CalculateRecentDisplacement(5);
      
      if(displacement > atr * 2.0)
      {
         MarketStructure.currentStructure = DISTRIBUTION;
         MarketStructure.structureStrength = 7.0;
      }
      else
      {
         MarketStructure.currentStructure = MANIPULATION;
         MarketStructure.structureStrength = 5.0;
      }
   }
}

#endif // AIME_POWER_OF_THREE_MQH

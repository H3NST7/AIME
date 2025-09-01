//+------------------------------------------------------------------+
//|                                    AIME_Initialization.mqh       |
//|                        System Initialization Module              |
//+------------------------------------------------------------------+
#ifndef AIME_INITIALIZATION_MQH
#define AIME_INITIALIZATION_MQH

//+------------------------------------------------------------------+
//| Initialize Core System                                          |
//+------------------------------------------------------------------+
bool InitializeCore()
{
   Print("Initializing Core System...");
   
   // Initialize global variables
   AccountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   MaxDailyLoss = AccountBalance * (MaxDailyRisk / 100.0);
   CurrentRisk = 0.0;
   DailyPnL = 0.0;
   ActivePositions = 0;
   TradingAllowed = true;
   LastTradeTime = 0;
   
   // Initialize arrays
   ArrayInitialize(CorrelationValues, 0.0);
   ArrayInitialize(CorrelationStrengths, 0.0);
   
   // Initialize structures
   MarketStructure = SMarketStructure();
   PowerOfThreeAnalysis = SPowerOfThree();
   PerformanceCache = SPerformanceCache();
   
   Print("Core System Initialized");
   return true;
}

//+------------------------------------------------------------------+
//| Initialize Indicators                                           |
//+------------------------------------------------------------------+
bool InitializeIndicators()
{
   Print("Initializing Technical Indicators...");
   
   // Initialize ATR (Average True Range)
   HandleATR = iATR(_Symbol, PERIOD_CURRENT, 14);
   if(HandleATR == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create ATR indicator handle");
      return false;
   }
   
   // Initialize RSI (Relative Strength Index)
   HandleRSI = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
   if(HandleRSI == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create RSI indicator handle");
      return false;
   }
   
   // Initialize MACD
   HandleMACD = iMACD(_Symbol, PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE);
   if(HandleMACD == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create MACD indicator handle");
      return false;
   }
   
   // Initialize EMA 20
   HandleEMA20 = iMA(_Symbol, PERIOD_CURRENT, 20, 0, MODE_EMA, PRICE_CLOSE);
   if(HandleEMA20 == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create EMA20 indicator handle");
      return false;
   }
   
   // Initialize EMA 50
   HandleEMA50 = iMA(_Symbol, PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE);
   if(HandleEMA50 == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create EMA50 indicator handle");
      return false;
   }
   
   // Initialize Bollinger Bands
   HandleBB = iBands(_Symbol, PERIOD_CURRENT, 20, 0, 2.0, PRICE_CLOSE);
   if(HandleBB == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create Bollinger Bands indicator handle");
      return false;
   }
   
   // Initialize Stochastic
   HandleStoch = iStochastic(_Symbol, PERIOD_CURRENT, 14, 3, 3, MODE_SMA, STO_LOWHIGH);
   if(HandleStoch == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create Stochastic indicator handle");
      return false;
   }
   
   // Initialize Williams Percent Range
   HandleWPR = iWPR(_Symbol, PERIOD_CURRENT, 14);
   if(HandleWPR == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create WPR indicator handle");
      return false;
   }
   
   // Initialize ADX
   HandleADX = iADX(_Symbol, PERIOD_CURRENT, 14);
   if(HandleADX == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create ADX indicator handle");
      return false;
   }
   
   // Initialize CCI
   HandleCCI = iCCI(_Symbol, PERIOD_CURRENT, 14, PRICE_TYPICAL);
   if(HandleCCI == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create CCI indicator handle");
      return false;
   }
   
   Print("All 10 Technical Indicators Initialized Successfully");
   return true;
}

//+------------------------------------------------------------------+
//| Initialize Analysis Modules                                     |
//+------------------------------------------------------------------+
bool InitializeAnalysisModules()
{
   Print("Initializing Analysis Modules...");
   
   // Initialize FVG array
   for(int i = 0; i < ArraySize(FairValueGaps); i++)
   {
      FairValueGaps[i] = SFairValueGap();
   }
   FVGCount = 0;
   
   // Initialize Order Block array
   for(int i = 0; i < ArraySize(OrderBlocks); i++)
   {
      OrderBlocks[i] = SOrderBlock();
   }
   OrderBlockCount = 0;
   
   // Initialize Liquidity Level array
   for(int i = 0; i < ArraySize(LiquidityLevels); i++)
   {
      LiquidityLevels[i] = SLiquidityLevel();
   }
   LiquidityLevelCount = 0;
   
   // Load historical data
   RatesTotal = CopyRates(_Symbol, PERIOD_CURRENT, 0, 500, Rates);
   if(RatesTotal < 100)
   {
      Print("ERROR: Insufficient historical data loaded: ", RatesTotal);
      return false;
   }
   
   Print("Analysis Modules Initialized");
   Print("Historical Data Loaded: ", RatesTotal, " bars");
   return true;
}

//+------------------------------------------------------------------+
//| Initialize Strategy Modules                                     |
//+------------------------------------------------------------------+
bool InitializeStrategyModules()
{
   Print("Initializing Strategy Modules...");
   
   // Initialize strategy parameters
   CurrentKillzone = KZ_INACTIVE;
   IsOptimalTradingTime = false;
   CurrentPremiumDiscount = 0.5;
   IsInPremium = false;
   IsInDiscount = false;
   IsInEquilibrium = true;
   
   Print("Strategy Modules Initialized");
   return true;
}

//+------------------------------------------------------------------+
//| Initialize Visual System                                        |
//+------------------------------------------------------------------+
bool InitializeVisualSystem()
{
   Print("Initializing Visual System...");
   
   if(ShowICTDashboard)
   {
      CreateICTDashboard();
   }
   
   // Initialize visual object array
   VisualObjectCount = 0;
   LastVisualUpdate = 0;
   
   Print("Visual System Initialized");
   return true;
}

//+------------------------------------------------------------------+
//| Initialize Performance Tracking                                 |
//+------------------------------------------------------------------+
bool InitializePerformanceTracking()
{
   Print("Initializing Performance Tracking...");
   
   // Reset performance variables
   TotalTrades = 0;
   WinningTrades = 0;
   LosingTrades = 0;
   TotalProfit = 0.0;
   TotalLoss = 0.0;
   LargestWin = 0.0;
   LargestLoss = 0.0;
   MaxDrawdown = 0.0;
   
   // Initialize error handling
   LastError = 0;
   ErrorCount = 0;
   RecoveryMode = false;
   LastErrorTime = 0;
   
   Print("Performance Tracking Initialized");
   return true;
}

//+------------------------------------------------------------------+
//| Process Market Data                                             |
//+------------------------------------------------------------------+
bool ProcessMarketData()
{
   return UpdateMarketData();
}

//+------------------------------------------------------------------+
//| Update Market Data                                              |
//+------------------------------------------------------------------+
bool UpdateMarketData()
{
   // Update rates array with new bar detection
   int newRatesTotal = CopyRates(_Symbol, PERIOD_CURRENT, 0, 500, Rates);
   
   if(newRatesTotal <= 0) return false;
   
   // Detect new bar formation
   static datetime lastBarTime = 0;
   bool newBar = false;
   
   if(newRatesTotal > 0 && Rates[newRatesTotal-1].time != lastBarTime)
   {
      newBar = true;
      lastBarTime = Rates[newRatesTotal-1].time;
      RatesTotal = newRatesTotal;
      
      // Trigger new bar analysis
      OnNewBarFormed();
   }
   
   // Update spread cache
   double currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(TimeCurrent() - PerformanceCache.spreadCacheTime >= 1) // Update spread every second
   {
      PerformanceCache.cachedSpread = currentSpread;
      PerformanceCache.spreadCacheTime = TimeCurrent();
   }
   
   // Validate market conditions
   ValidateMarketConditions();
   
   return true;
}

//+------------------------------------------------------------------+
//| On New Bar Formed                                               |
//+------------------------------------------------------------------+
void OnNewBarFormed()
{
   // Trigger pattern detection on new bar
   if(DetectFairValueGaps)
   {
      CheckRealtimeFVGFormation();
   }
   
   if(DetectOrderBlocks)
   {
      CheckRealtimeOrderBlockFormation();
   }
   
   if(DetectLiquidityRaids)
   {
      CheckRealtimeLiquidityRaid();
   }
   
   // Update market structure on new bar
   UpdateRealtimeMarketStructure();
   
   // Update Power of 3 analysis
   AnalyzePowerOfThree();
   
   // Invalidate structure cache
   PerformanceCache.structureCacheValid = false;
}

//+------------------------------------------------------------------+
//| Cleanup Indicators                                              |
//+------------------------------------------------------------------+
void CleanupIndicators()
{
   if(HandleATR != INVALID_HANDLE) IndicatorRelease(HandleATR);
   if(HandleRSI != INVALID_HANDLE) IndicatorRelease(HandleRSI);
   if(HandleMACD != INVALID_HANDLE) IndicatorRelease(HandleMACD);
   if(HandleEMA20 != INVALID_HANDLE) IndicatorRelease(HandleEMA20);
   if(HandleEMA50 != INVALID_HANDLE) IndicatorRelease(HandleEMA50);
   if(HandleBB != INVALID_HANDLE) IndicatorRelease(HandleBB);
   if(HandleStoch != INVALID_HANDLE) IndicatorRelease(HandleStoch);
   if(HandleWPR != INVALID_HANDLE) IndicatorRelease(HandleWPR);
   if(HandleADX != INVALID_HANDLE) IndicatorRelease(HandleADX);
   if(HandleCCI != INVALID_HANDLE) IndicatorRelease(HandleCCI);
   
   Print("All indicator handles released");
}

//+------------------------------------------------------------------+
//| Cleanup Analysis Modules                                        |
//+------------------------------------------------------------------+
void CleanupAnalysisModules()
{
   // Clean up arrays
   OptimizeArrays();
   
   Print("Analysis modules cleaned up");
}

//+------------------------------------------------------------------+
//| Cleanup Visual System                                           |
//+------------------------------------------------------------------+
void CleanupVisualSystem()
{
   // Remove all visual objects
   for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
   {
      string objectName = ObjectName(0, i);
      if(StringFind(objectName, "AIME_", 0) == 0)
      {
         ObjectDelete(0, objectName);
      }
   }
   
   Print("Visual system cleaned up");
}

#endif // AIME_INITIALIZATION_MQH

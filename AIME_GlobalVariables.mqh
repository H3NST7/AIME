//+------------------------------------------------------------------+
//|                                     AIME_GlobalVariables.mqh     |
//|                         Global Variables and Arrays              |
//+------------------------------------------------------------------+
#ifndef AIME_GLOBAL_VARIABLES_MQH
#define AIME_GLOBAL_VARIABLES_MQH

// Core Trading Variables
double               AccountBalance = 0.0;
double               CurrentRisk = 0.0;
double               DailyPnL = 0.0;
double               MaxDailyLoss = 0.0;
int                  ActivePositions = 0;
bool                 TradingAllowed = true;
datetime             LastTradeTime = 0;

// ICT Analysis Arrays (Optimized Sizes)
SFairValueGap        FairValueGaps[50];              
SOrderBlock          OrderBlocks[50];                  
SLiquidityLevel      LiquidityLevels[100];           
SMarketStructure     MarketStructure;
SPowerOfThree        PowerOfThreeAnalysis;
SPerformanceCache    PerformanceCache;

// Multi-Timeframe Market Data
MqlRates             Rates[500];                     
int                  RatesTotal = 0;

// Technical Indicator Handles
int                  HandleATR = INVALID_HANDLE;
int                  HandleRSI = INVALID_HANDLE;
int                  HandleMACD = INVALID_HANDLE;
int                  HandleEMA20 = INVALID_HANDLE;
int                  HandleEMA50 = INVALID_HANDLE;
int                  HandleBB = INVALID_HANDLE;
int                  HandleStoch = INVALID_HANDLE;
int                  HandleWPR = INVALID_HANDLE;
int                  HandleADX = INVALID_HANDLE;
int                  HandleCCI = INVALID_HANDLE;

// Correlation Analysis Variables
string               CorrelationSymbols[] = {"USDX", "US10Y", "US02Y", "SPX500", "EURUSD", "GBPUSD", "USOIL", "VIX"};
double               CorrelationValues[8];
double               CorrelationStrengths[8];
datetime             LastCorrelationUpdate = 0;

// Premium/Discount Analysis
double               CurrentPremiumDiscount = 0.5;
double               RangeHigh = 0.0;
double               RangeLow = 0.0;
bool                 IsInPremium = false;
bool                 IsInDiscount = false;
bool                 IsInEquilibrium = false;

// Killzone Analysis
ENUM_KILLZONE        CurrentKillzone = KZ_INACTIVE;
bool                 IsOptimalTradingTime = false;
datetime             KillzoneStartTime = 0;
datetime             KillzoneEndTime = 0;

// Pattern Detection Counters
int                  FVGCount = 0;
int                  OrderBlockCount = 0;
int                  LiquidityLevelCount = 0;

// Performance Tracking Variables
double               TotalTrades = 0;
double               WinningTrades = 0;
double               LosingTrades = 0;
double               TotalProfit = 0.0;
double               TotalLoss = 0.0;
double               LargestWin = 0.0;
double               LargestLoss = 0.0;
double               MaxDrawdown = 0.0;

// Visual Element Management
string               VisualObjects[200];             
int                  VisualObjectCount = 0;
datetime             LastVisualUpdate = 0;

// Error Handling and Recovery
int                  LastError = 0;
int                  ErrorCount = 0;
bool                 RecoveryMode = false;
datetime             LastErrorTime = 0;

#endif // AIME_GLOBAL_VARIABLES_MQH

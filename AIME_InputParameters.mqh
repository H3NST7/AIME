//+------------------------------------------------------------------+
//|                                    AIME_InputParameters.mqh      |
//|                    Complete Input Parameter System (64 Params)   |
//+------------------------------------------------------------------+
#ifndef AIME_INPUT_PARAMETERS_MQH
#define AIME_INPUT_PARAMETERS_MQH

//--- Core ICT Risk Management Parameters (5)
input group "=== AIME CORE RISK MANAGEMENT ==="
input double      MaxRiskPerTrade = 2.0;                    // Maximum Risk Per Trade (%)
input double      MaxDailyRisk = 3.0;                       // Maximum Daily Risk (%)
input int         MaxPositions = 3;                         // Maximum Concurrent Positions
input bool        UseICTTrailing = true;                    // Use ICT Trailing Stop
input bool        UseICTPartials = true;                    // Use ICT Partial Profits

//--- Market Structure Analysis Parameters (8)
input group "=== AIME MARKET STRUCTURE ANALYSIS ==="
input int         StructureLookback = 20;                   // Structure Analysis Lookback
input double      DisplacementThreshold = 1.5;              // Displacement Threshold (ATR Multiple)
input double      ChangeOfCharacterThreshold = 0.8;         // Change of Character Threshold
input bool        DetectFairValueGaps = true;               // Detect Fair Value Gaps
input bool        DetectOrderBlocks = true;                 // Detect Order Blocks
input bool        DetectLiquidityRaids = true;              // Detect Liquidity Raids
input bool        DetectMarketStructureShifts = true;       // Detect Market Structure Shifts
input bool        DetectDisplacements = true;               // Detect Price Displacements

//--- ICT Timing and Killzone Parameters (10)
input group "=== AIME TIMING & KILLZONES ==="
input bool        UseLondonOpen = true;                     // Use London Open Killzone
input bool        UseLondonClose = true;                    // Use London Close Killzone
input bool        UseNewYorkOpen = true;                    // Use New York Open Killzone
input bool        UseNewYorkClose = false;                  // Use New York Close Killzone
input bool        UseFrankfurtOpen = true;                  // Use Frankfurt Open Killzone
input bool        UseSilverBullet = true;                   // Use Silver Bullet Strategy
input bool        UseMacroTimes = true;                     // Use Macro Times
input string      SilverBulletTimes = "10:00-11:00,14:00-15:00,18:00-19:00"; // Silver Bullet Times (GMT)
input int         MacroTimeBuffer = 2;                      // Macro Time Buffer (Minutes)
input bool        AvoidNews = true;                         // Avoid High Impact News

//--- Premium/Discount Array Parameters (8)
input group "=== AIME PREMIUM/DISCOUNT ARRAYS ==="
input double      PremiumThreshold = 0.7;                   // Premium Threshold (0-1)
input double      DiscountThreshold = 0.3;                  // Discount Threshold (0-1)
input double      EquilibriumZone = 0.1;                    // Equilibrium Zone (+/- from 0.5)
input double      OTEFib618 = 0.618;                        // OTE Fibonacci 61.8%
input double      OTEFib705 = 0.705;                        // OTE Fibonacci 70.5%
input double      OTEFib786 = 0.786;                        // OTE Fibonacci 78.6%
input double      OTETolerance = 0.015;                     // OTE Tolerance (1.5%)
input int         PremiumDiscountLookback = 48;             // Premium/Discount Lookback Hours

//--- Liquidity Analysis Parameters (6)
input group "=== AIME LIQUIDITY ANALYSIS ==="
input int         LiquidityAnalysisPeriod = 100;            // Liquidity Analysis Period
input double      EqualLevelTolerance = 5.0;                // Equal Level Tolerance (Points)
input double      RelativeEqualTolerance = 0.15;            // Relative Equal Tolerance (ATR)
input int         LiquidityTouchesRequired = 2;             // Minimum Touches Required
input double      LiquidityRaidThreshold = 1.0;             // Liquidity Raid Threshold (ATR)
input double      MinLiquidityStrength = 3.0;               // Minimum Liquidity Strength

//--- Market Maker Model Parameters (7)
input group "=== AIME MARKET MAKER MODELS ==="
input bool        UseMarketMakerModels = true;              // Use Market Maker Models
input double      ConsolidationThreshold = 0.5;             // Consolidation Threshold (ATR)
input double      ExpansionThreshold = 2.0;                 // Expansion Threshold (ATR)
input double      RetracementThreshold = 0.382;             // Retracement Threshold (Fib)
input double      ReversalThreshold = 1.618;                // Reversal Threshold (Fib Extension)
input double      ContinuationThreshold = 1.0;              // Continuation Threshold (ATR)
input int         MarketMakerLookback = 50;                 // Market Maker Analysis Lookback

//--- Advanced ICT Concepts Parameters (10)
input group "=== ADVANCED AIME CONCEPTS ==="
input bool        UseUnicornModel = true;                   // Use Unicorn Model Strategy
input bool        UseDragonflyEntry = true;                 // Use Dragonfly Entry Strategy
input bool        Use2022Mentorship = true;                 // Use 2022 Mentorship Model
input double      UnicornConfluenceThreshold = 0.85;        // Unicorn Confluence Threshold
input double      DragonflyConfluenceThreshold = 0.75;      // Dragonfly Confluence Threshold
input double      MentorshipTimeWindow = 5.0;               // 2022 Mentorship Time Window (Min)
input double      OptimalFVGThreshold = 7.0;                // Optimal FVG Strength Threshold
input double      InstitutionalOBThreshold = 6.0;           // Institutional OB Threshold
input double      LiquidityGrabDisplacement = 2.5;          // Liquidity Grab Displacement (ATR)
input bool        UseAdvancedTiming = true;                 // Use Advanced Timing Analysis

//--- Multi-Asset Correlation Parameters (7)
input group "=== MULTI-ASSET CORRELATION ==="
input bool        UseCorrelationAnalysis = true;            // Use Correlation Analysis
input bool        AnalyzeDXY = true;                        // Analyze US Dollar Index
input bool        AnalyzeBonds = true;                      // Analyze US Bonds (10Y, 2Y)
input bool        AnalyzeEquities = true;                   // Analyze S&P 500
input bool        AnalyzeCurrencies = true;                 // Analyze Major Currencies
input bool        AnalyzeCommodities = true;                // Analyze Oil & VIX
input int         CorrelationPeriod = 50;                   // Correlation Calculation Period

//--- Risk Management Model Parameters (8)
input group "=== AIME RISK MANAGEMENT MODEL ==="
input double      ICTRiskMultiplier = 1.0;                  // ICT Risk Multiplier
input double      ConfluenceRiskAdjustment = 0.5;           // Confluence Risk Adjustment
input double      VolatilityRiskAdjustment = 0.3;           // Volatility Risk Adjustment
input double      CorrelationRiskAdjustment = 0.2;          // Correlation Risk Adjustment
input bool        UseEmergencyExit = true;                  // Use Emergency Exit System
input double      EmergencyExitThreshold = 5.0;             // Emergency Exit Threshold (ATR)
input double      MaxPortfolioHeat = 6.0;                   // Maximum Portfolio Heat (%)
input bool        UseICTBreakEven = true;                   // Use ICT Break Even

//--- Visual Display Parameters (12)
input group "=== AIME VISUAL DISPLAY ==="
input bool        ShowICTDashboard = true;                  // Show ICT Dashboard
input bool        ShowMarketStructure = true;               // Show Market Structure
input bool        ShowFairValueGaps = true;                 // Show Fair Value Gaps
input bool        ShowOrderBlocks = true;                   // Show Order Blocks
input bool        ShowLiquidityLevels = true;               // Show Liquidity Levels
input bool        ShowPremiumDiscount = true;               // Show Premium/Discount
input bool        ShowKillzones = true;                     // Show Killzone Highlights
input bool        ShowCorrelations = true;                  // Show Correlation Info
input color       BullishColor = clrLime;                   // Bullish Elements Color
input color       BearishColor = clrRed;                    // Bearish Elements Color
input color       NeutralColor = clrYellow;                 // Neutral Elements Color
input int         VisualUpdateFrequency = 30;               // Visual Update Frequency (Seconds)

#endif // AIME_INPUT_PARAMETERS_MQH

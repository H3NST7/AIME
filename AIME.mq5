//+------------------------------------------------------------------+
//|                                     ICT_Master_EA_v2025.mq5     |
//|                              Code Architect for Isaiah           |
//|                          Advanced ICT Methodology Expert         |
//+------------------------------------------------------------------+
#property copyright   "Code Architect - ICT Master System 2025"
#property link        "Advanced ICT Methodology Implementation"
#property version     "4.00"
#property description "Most Advanced Inner Circle Trader Expert Advisor"
#property description "Institutional-Grade Multi-Asset Correlation Analysis"
#property description "Complete ICT Methodology with All Advanced Concepts"
#property strict

//+------------------------------------------------------------------+
//| MODULAR ARCHITECTURE INCLUDES                                   |
//+------------------------------------------------------------------+

// Core System Modules
#include <ICT_System/Core/ICT_Enumerations.mqh>
#include <ICT_System/Core/ICT_Structures.mqh>
#include <ICT_System/Core/ICT_GlobalVariables.mqh>
#include <ICT_System/Core/ICT_InputParameters.mqh>

// Analysis Modules
#include <ICT_System/Analysis/ICT_MarketStructure.mqh>
#include <ICT_System/Analysis/ICT_FairValueGaps.mqh>
#include <ICT_System/Analysis/ICT_OrderBlocks.mqh>
#include <ICT_System/Analysis/ICT_LiquidityLevels.mqh>
#include <ICT_System/Analysis/ICT_PowerOfThree.mqh>
#include <ICT_System/Analysis/ICT_PremiumDiscount.mqh>
#include <ICT_System/Analysis/ICT_Killzones.mqh>
#include <ICT_System/Analysis/ICT_Correlation.mqh>

// Strategy Modules
#include <ICT_System/Strategies/ICT_UnicornModel.mqh>
#include <ICT_System/Strategies/ICT_DragonflyEntry.mqh>
#include <ICT_System/Strategies/ICT_SilverBullet.mqh>
#include <ICT_System/Strategies/ICT_2022Mentorship.mqh>
#include <ICT_System/Strategies/ICT_MarketMaker.mqh>

// Execution Modules
#include <ICT_System/Execution/ICT_TradeExecution.mqh>
#include <ICT_System/Execution/ICT_RiskManagement.mqh>
#include <ICT_System/Execution/ICT_PositionManagement.mqh>

// Utility Modules
#include <ICT_System/Utils/ICT_Calculations.mqh>
#include <ICT_System/Utils/ICT_Validation.mqh>
#include <ICT_System/Utils/ICT_MemoryManager.mqh>
#include <ICT_System/Utils/ICT_ErrorHandler.mqh>

// Visual Modules
#include <ICT_System/Visual/ICT_Dashboard.mqh>
#include <ICT_System/Visual/ICT_ChartObjects.mqh>

// Performance Modules
#include <ICT_System/Performance/ICT_Metrics.mqh>
#include <ICT_System/Performance/ICT_Reporting.mqh>

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== ICT Master EA v4.00 Modular System Initialization ===");
   
   // Initialize all subsystems
   if(!InitializeCore()) return INIT_FAILED;
   if(!InitializeIndicators()) return INIT_FAILED;
   if(!InitializeAnalysisModules()) return INIT_FAILED;
   if(!InitializeStrategyModules()) return INIT_FAILED;
   if(!InitializeExecutionSystem()) return INIT_FAILED;
   if(!InitializeVisualSystem()) return INIT_FAILED;
   if(!InitializePerformanceTracking()) return INIT_FAILED;
   
   // Set event timer for low-frequency updates
   EventSetTimer(1);
   
   Print("=== ICT Master EA Initialization Complete ===");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Cleanup all subsystems
   CleanupExecutionSystem();
   CleanupAnalysisModules();
   CleanupVisualSystem();
   CleanupIndicators();
   CleanupPerformanceTracking();
   
   EventKillTimer();
   
   // Generate final report
   GenerateFinalReport(reason);
   
   Print("=== ICT Master EA v4.00 Shutdown Complete ===");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // High-frequency processing
   if(!ProcessMarketData()) return;
   if(!ValidateTradingConditions()) return;
   
   // Execute main trading logic
   ExecuteICTTradingLogic();
   
   // Manage existing positions
   ManageActivePositions();
   
   // Update visual elements
   if(RequiresVisualUpdate())
   {
      UpdateVisualElements();
   }
}

//+------------------------------------------------------------------+
//| Timer event function                                             |
//+------------------------------------------------------------------+
void OnTimer()
{
   // Low-frequency updates (every second)
   static datetime lastStructureUpdate = 0;
   static datetime lastCorrelationUpdate = 0;
   
   datetime currentTime = TimeCurrent();
   
   // Structure analysis (every 60 seconds)
   if(currentTime - lastStructureUpdate >= 60)
   {
      AnalyzeCompleteMarketStructure();
      lastStructureUpdate = currentTime;
   }
   
   // Correlation analysis (every 5 minutes)
   if(currentTime - lastCorrelationUpdate >= 300)
   {
      UpdateCorrelationAnalysis();
      lastCorrelationUpdate = currentTime;
   }
   
   // Memory optimization
   OptimizeMemoryUsage();
}

//+------------------------------------------------------------------+
//| Trade event function                                             |
//+------------------------------------------------------------------+
void OnTrade()
{
   // Handle trade events
   ProcessTradeEvent();
   UpdatePerformanceMetrics();
}

//+------------------------------------------------------------------+
//| Chart event function                                             |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long& lparam, 
                   const double& dparam, const string& sparam)
{
   // Handle dashboard interactions
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      ProcessDashboardClick(sparam);
   }
}

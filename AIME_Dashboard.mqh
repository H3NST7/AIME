//+------------------------------------------------------------------+
//|                                         AIME_Dashboard.mqh       |
//|                      Dashboard Visual System Module              |
//+------------------------------------------------------------------+
#ifndef AIME_DASHBOARD_MQH
#define AIME_DASHBOARD_MQH

//+------------------------------------------------------------------+
//| Create ICT Dashboard                                            |
//+------------------------------------------------------------------+
void CreateICTDashboard()
{
   if(!ShowICTDashboard) return;
   
   string panelName = "AIME_Dashboard_Main";
   
   if(ObjectFind(0, panelName) < 0)
   {
      ObjectCreate(0, panelName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, panelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, panelName, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, panelName, OBJPROP_YDISTANCE, 10);
      ObjectSetInteger(0, panelName, OBJPROP_XSIZE, 450);
      ObjectSetInteger(0, panelName, OBJPROP_YSIZE, 700);
      ObjectSetInteger(0, panelName, OBJPROP_BGCOLOR, clrBlack);
      ObjectSetInteger(0, panelName, OBJPROP_BORDER_COLOR, clrWhite);
      ObjectSetInteger(0, panelName, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, panelName, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, panelName, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, panelName, OBJPROP_FILL, true);
   }
   
   CreateDashboardLabel("AIME_Dashboard_Title", "AIME MASTER EA v4.00", 20, 20, 12, clrYellow);
   CreateDashboardLabel("AIME_Structure_Title", "=== MARKET STRUCTURE ===", 20, 50, 10, clrWhite);
   CreateDashboardLabel("AIME_PD_Title", "=== PREMIUM/DISCOUNT ===", 20, 200, 10, clrWhite);
   CreateDashboardLabel("AIME_Killzone_Title", "=== KILLZONE STATUS ===", 20, 300, 10, clrWhite);
   CreateDashboardLabel("AIME_Pattern_Title", "=== PATTERN ANALYSIS ===", 20, 400, 10, clrWhite);
   CreateDashboardLabel("AIME_Performance_Title", "=== PERFORMANCE ===", 20, 550, 10, clrWhite);
   
   UpdateICTDashboard();
}

//+------------------------------------------------------------------+
//| Create Dashboard Label                                          |
//+------------------------------------------------------------------+
void CreateDashboardLabel(string name, string text, int x, int y, int fontSize, color textColor)
{
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   }
   
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
}

//+------------------------------------------------------------------+
//| Update ICT Dashboard                                            |
//+------------------------------------------------------------------+
void UpdateICTDashboard()
{
   if(!ShowICTDashboard) return;
   
   // Market Structure Section
   string structureText = EnumToString(MarketStructure.currentStructure);
   color structureColor = clrWhite;
   
   if(MarketStructure.currentStructure == BULLISH_BOS || MarketStructure.currentStructure == BULLISH_MSS)
      structureColor = BullishColor;
   else if(MarketStructure.currentStructure == BEARISH_BOS || MarketStructure.currentStructure == BEARISH_MSS)
      structureColor = BearishColor;
   
   CreateDashboardLabel("AIME_Structure_Current", "Structure: " + structureText, 20, 75, 9, structureColor);
   CreateDashboardLabel("AIME_Structure_Strength", "Strength: " + DoubleToString(MarketStructure.structureStrength, 1) + "/10", 20, 95, 9, clrWhite);
   CreateDashboardLabel("AIME_Displacement", "Displacement: " + (MarketStructure.isDisplacement ? "YES (" + DoubleToString(MarketStructure.displacementSize, 1) + " ATR)" : "NO"), 20, 115, 9, MarketStructure.isDisplacement ? clrLime : clrGray);
   
   string bosStatus = "🔴"; if(MarketStructure.hasBreakOfStructure) bosStatus = "🟢";
   string chochStatus = "🔴"; if(MarketStructure.hasChangeOfCharacter) chochStatus = "🟡";
   string mssStatus = "🔴"; if(MarketStructure.hasMarketStructureShift) mssStatus = "🟢";
   
   CreateDashboardLabel("AIME_BOS_Status", "BOS: " + bosStatus, 20, 135, 9, clrWhite);
   CreateDashboardLabel("AIME_CHoCH_Status", "CHoCH: " + chochStatus, 120, 135, 9, clrWhite);
   CreateDashboardLabel("AIME_MSS_Status", "MSS: " + mssStatus, 220, 135, 9, clrWhite);
   
   CreateDashboardLabel("AIME_Po3_Phase", "Po3: " + EnumToString(PowerOfThreeAnalysis.currentPhase), 20, 155, 9, PowerOfThreeAnalysis.isOptimalPhase ? clrLime : clrGray);
   CreateDashboardLabel("AIME_Po3_Strength", "Po3 Strength: " + DoubleToString(PowerOfThreeAnalysis.phaseStrength, 1), 20, 175, 9, clrWhite);
   
   // Premium/Discount Section
   double pdValue = CurrentPremiumDiscount * 100;
   string pdStatus = "EQUILIBRIUM";
   color pdColor = NeutralColor;
   
   if(IsInPremium) { pdStatus = "PREMIUM"; pdColor = BearishColor; }
   else if(IsInDiscount) { pdStatus = "DISCOUNT"; pdColor = BullishColor; }
   
   CreateDashboardLabel("AIME_PD_Status", "Status: " + pdStatus, 20, 225, 9, pdColor);
   CreateDashboardLabel("AIME_PD_Value", "Value: " + DoubleToString(pdValue, 1) + "%", 20, 245, 9, clrWhite);
   CreateDashboardLabel("AIME_PD_Range", "Range: " + DoubleToString(RangeHigh, 2) + " - " + DoubleToString(RangeLow, 2), 20, 265, 9, clrWhite);
   
   // Killzone Section
   string killzoneStatus = EnumToString(CurrentKillzone);
   color killzoneColor = IsOptimalTradingTime ? clrLime : clrGray;
   
   CreateDashboardLabel("AIME_Killzone_Current", "Current: " + killzoneStatus, 20, 325, 9, killzoneColor);
   CreateDashboardLabel("AIME_Killzone_Optimal", "Optimal: " + (IsOptimalTradingTime ? "YES" : "NO"), 20, 345, 9, killzoneColor);
   
   CreateDashboardLabel("AIME_Time_Current", "Time (GMT): " + TimeToString(TimeCurrent(), TIME_MINUTES), 20, 365, 9, clrWhite);
   
   // Pattern Analysis Section
   CreateDashboardLabel("AIME_FVG_Count", "Active FVGs: " + IntegerToString(CountActiveFVGs()), 20, 425, 9, clrWhite);
   CreateDashboardLabel("AIME_OB_Count", "Active OBs: " + IntegerToString(CountActiveOrderBlocks()), 20, 445, 9, clrWhite);
   CreateDashboardLabel("AIME_Liquidity_Count", "Liquidity Levels: " + IntegerToString(CountActiveLiquidityLevels()), 20, 465, 9, clrWhite);
   
   int recentRaids = CountRecentLiquidityRaids(300);
   CreateDashboardLabel("AIME_Recent_Raids", "Recent Raids (5m): " + IntegerToString(recentRaids), 20, 485, 9, recentRaids > 0 ? clrYellow : clrGray);
   
   double confluenceScore = MarketStructure.structureStrength;
   color confluenceColor = clrGray;
   if(confluenceScore >= 8.5) confluenceColor = clrLime;
   else if(confluenceScore >= 7.0) confluenceColor = clrYellow;
   else if(confluenceScore >= 5.0) confluenceColor = clrOrange;
   
   CreateDashboardLabel("AIME_Confluence", "Confluence: " + DoubleToString(confluenceScore, 1) + "/10", 20, 505, 9, confluenceColor);
   
   // Performance Section
   CreateDashboardLabel("AIME_Account_Balance", "Balance: $" + DoubleToString(AccountBalance, 2), 20, 575, 9, clrWhite);
   CreateDashboardLabel("AIME_Daily_PnL", "Daily P&L: $" + DoubleToString(DailyPnL, 2), 20, 595, 9, DailyPnL >= 0 ? clrLime : clrRed);
   CreateDashboardLabel("AIME_Active_Positions", "Positions: " + IntegerToString(ActivePositions) + "/" + IntegerToString(MaxPositions), 20, 615, 9, clrWhite);
   CreateDashboardLabel("AIME_Portfolio_Risk", "Portfolio Risk: " + DoubleToString(CurrentRisk, 1) + "%", 20, 635, 9, CurrentRisk < 5.0 ? clrLime : (CurrentRisk < 8.0 ? clrYellow : clrRed));
   
   string tradingStatus = TradingAllowed ? "ENABLED" : "DISABLED";
   color tradingColor = TradingAllowed ? clrLime : clrRed;
   CreateDashboardLabel("AIME_Trading_Status", "Trading: " + tradingStatus, 20, 655, 9, tradingColor);
   
   if(RecoveryMode)
   {
      CreateDashboardLabel("AIME_Recovery_Mode", "⚠️ RECOVERY MODE ACTIVE ⚠️", 20, 675, 9, clrRed);
   }
   else
   {
      ObjectDelete(0, "AIME_Recovery_Mode");
   }
}

//+------------------------------------------------------------------+
//| Process Dashboard Click                                         |
//+------------------------------------------------------------------+
void ProcessDashboardClick(string objectName)
{
   // Handle dashboard interactions
   if(StringFind(objectName, "AIME_Dashboard") >= 0)
   {
      Print("Dashboard clicked: ", objectName);
      // Add interactive features as needed
   }
}

//+------------------------------------------------------------------+
//| Count Active FVGs                                               |
//+------------------------------------------------------------------+
int CountActiveFVGs()
{
   int count = 0;
   for(int i = 0; i < FVGCount; i++)
   {
      if(FairValueGaps[i].isActive) count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Count Active Order Blocks                                       |
//+------------------------------------------------------------------+
int CountActiveOrderBlocks()
{
   int count = 0;
   for(int i = 0; i < OrderBlockCount; i++)
   {
      if(OrderBlocks[i].isActive) count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| Count Active Liquidity Levels                                   |
//+------------------------------------------------------------------+
int CountActiveLiquidityLevels()
{
   int count = 0;
   for(int i = 0; i < LiquidityLevelCount; i++)
   {
      if(LiquidityLevels[i].isActive) count++;
   }
   return count;
}

#endif // AIME_DASHBOARD_MQH

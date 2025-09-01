//+------------------------------------------------------------------+
//|                                      AIME_ChartObjects.mqh       |
//|                       Chart Objects Visual Module                |
//+------------------------------------------------------------------+
#ifndef AIME_CHART_OBJECTS_MQH
#define AIME_CHART_OBJECTS_MQH

//+------------------------------------------------------------------+
//| Update Visual Elements                                          |
//+------------------------------------------------------------------+
void UpdateVisualElements()
{
   UpdateICTDashboard();
   
   if(ShowMarketStructure) UpdateStructureVisuals();
   if(ShowFairValueGaps) UpdateFVGVisuals();
   if(ShowOrderBlocks) UpdateOrderBlockVisuals();
   if(ShowLiquidityLevels) UpdateLiquidityVisuals();
   if(ShowPremiumDiscount) UpdatePremiumDiscountVisuals();
   if(ShowKillzones) CreateKillzoneElements();
}

//+------------------------------------------------------------------+
//| Update Structure Visuals                                        |
//+------------------------------------------------------------------+
void UpdateStructureVisuals()
{
   // BOS Line
   if(MarketStructure.hasBreakOfStructure && MarketStructure.bosLevel > 0)
   {
      string bosLineName = "AIME_BOS_Line";
      if(ObjectFind(0, bosLineName) < 0)
      {
         ObjectCreate(0, bosLineName, OBJ_HLINE, 0, 0, MarketStructure.bosLevel);
         ObjectSetInteger(0, bosLineName, OBJPROP_COLOR, clrLime);
         ObjectSetInteger(0, bosLineName, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSetInteger(0, bosLineName, OBJPROP_WIDTH, 3);
      }
      else
      {
         ObjectSetDouble(0, bosLineName, OBJPROP_PRICE, MarketStructure.bosLevel);
      }
   }
   
   // CHoCH Line
   if(MarketStructure.hasChangeOfCharacter && MarketStructure.chochLevel > 0)
   {
      string chochLineName = "AIME_CHoCH_Line";
      if(ObjectFind(0, chochLineName) < 0)
      {
         ObjectCreate(0, chochLineName, OBJ_HLINE, 0, 0, MarketStructure.chochLevel);
         ObjectSetInteger(0, chochLineName, OBJPROP_COLOR, clrYellow);
         ObjectSetInteger(0, chochLineName, OBJPROP_STYLE, STYLE_DASH);
         ObjectSetInteger(0, chochLineName, OBJPROP_WIDTH, 2);
      }
      else
      {
         ObjectSetDouble(0, chochLineName, OBJPROP_PRICE, MarketStructure.chochLevel);
      }
   }
   
   // MSS Line
   if(MarketStructure.hasMarketStructureShift && MarketStructure.mssLevel > 0)
   {
      string mssLineName = "AIME_MSS_Line";
      if(ObjectFind(0, mssLineName) < 0)
      {
         ObjectCreate(0, mssLineName, OBJ_HLINE, 0, 0, MarketStructure.mssLevel);
         ObjectSetInteger(0, mssLineName, OBJPROP_COLOR, clrMagenta);
         ObjectSetInteger(0, mssLineName, OBJPROP_STYLE, STYLE_DASHDOT);
         ObjectSetInteger(0, mssLineName, OBJPROP_WIDTH, 3);
      }
      else
      {
         ObjectSetDouble(0, mssLineName, OBJPROP_PRICE, MarketStructure.mssLevel);
      }
   }
}

//+------------------------------------------------------------------+
//| Update FVG Visuals                                              |
//+------------------------------------------------------------------+
void UpdateFVGVisuals()
{
   for(int i = 0; i < FVGCount; i++)
   {
      if(!FairValueGaps[i].isActive) continue;
      
      string fvgName = "AIME_FVG_" + IntegerToString(i);
      
      if(ObjectFind(0, fvgName) < 0)
      {
         ObjectCreate(0, fvgName, OBJ_RECTANGLE, 0, 
                     FairValueGaps[i].startTime, FairValueGaps[i].topPrice,
                     FairValueGaps[i].startTime + 3600, FairValueGaps[i].bottomPrice);
         
         color fvgColor = (FairValueGaps[i].direction == FAIR_VALUE_GAP_BULLISH) ? clrAqua : clrMagenta;
         ObjectSetInteger(0, fvgName, OBJPROP_COLOR, fvgColor);
         ObjectSetInteger(0, fvgName, OBJPROP_FILL, true);
         
         int transparency = (int)(255 - (FairValueGaps[i].strength / 10.0 * 200));
         ObjectSetInteger(0, fvgName, OBJPROP_BGCOLOR, fvgColor);
         
         int borderWidth = (int)(FairValueGaps[i].strength / 3.0);
         borderWidth = MathMax(1, MathMin(3, borderWidth));
         ObjectSetInteger(0, fvgName, OBJPROP_WIDTH, borderWidth);
         
         if(FairValueGaps[i].isOptimalFVG)
         {
            ObjectSetInteger(0, fvgName, OBJPROP_WIDTH, 3);
            ObjectSetInteger(0, fvgName, OBJPROP_STYLE, STYLE_SOLID);
         }
      }
      
      ObjectSetInteger(0, fvgName, OBJPROP_TIME, 1, TimeCurrent());
   }
}

//+------------------------------------------------------------------+
//| Update Order Block Visuals                                      |
//+------------------------------------------------------------------+
void UpdateOrderBlockVisuals()
{
   for(int i = 0; i < OrderBlockCount; i++)
   {
      if(!OrderBlocks[i].isActive) continue;
      
      string obName = "AIME_OB_" + IntegerToString(i);
      
      if(ObjectFind(0, obName) < 0)
      {
         ObjectCreate(0, obName, OBJ_RECTANGLE, 0,
                     OrderBlocks[i].time, OrderBlocks[i].high,
                     OrderBlocks[i].time + 3600, OrderBlocks[i].low);
         
         color obColor = OrderBlocks[i].isBullish ? clrGreen : clrMaroon;
         ObjectSetInteger(0, obName, OBJPROP_COLOR, obColor);
         ObjectSetInteger(0, obName, OBJPROP_FILL, true);
         
         int transparency = (int)(255 - (OrderBlocks[i].strength / 10.0 * 180));
         ObjectSetInteger(0, obName, OBJPROP_BGCOLOR, obColor);
         
         if(OrderBlocks[i].isInstitutional)
         {
            ObjectSetInteger(0, obName, OBJPROP_WIDTH, 3);
            ObjectSetInteger(0, obName, OBJPROP_STYLE, STYLE_SOLID);
         }
      }
      
      ObjectSetInteger(0, obName, OBJPROP_TIME, 1, TimeCurrent() + 1800);
   }
}

//+------------------------------------------------------------------+
//| Update Liquidity Visuals                                        |
//+------------------------------------------------------------------+
void UpdateLiquidityVisuals()
{
   for(int i = 0; i < LiquidityLevelCount; i++)
   {
      if(!LiquidityLevels[i].isActive) continue;
      
      string liquidityName = "AIME_Liquidity_" + IntegerToString(i);
      
      if(ObjectFind(0, liquidityName) < 0)
      {
         ObjectCreate(0, liquidityName, OBJ_HLINE, 0, 0, LiquidityLevels[i].price);
         
         color liquidityColor = clrYellow;
         int lineWidth = (int)(LiquidityLevels[i].strength / 2.0);
         lineWidth = MathMax(1, MathMin(3, lineWidth));
         
         switch(LiquidityLevels[i].type)
         {
            case MONTHLY_HIGH:
            case MONTHLY_LOW:
               liquidityColor = clrRed;
               lineWidth = 3;
               break;
               
            case WEEKLY_HIGH:
            case WEEKLY_LOW:
               liquidityColor = clrOrange;
               lineWidth = 2;
               break;
               
            case DAILY_HIGH:
            case DAILY_LOW:
               liquidityColor = clrYellow;
               break;
               
            case EQUAL_HIGHS:
            case EQUAL_LOWS:
               liquidityColor = clrLime;
               break;
               
            default:
               liquidityColor = clrGray;
               break;
         }
         
         if(LiquidityLevels[i].isRaided)
         {
            liquidityColor = clrDarkGray;
            ObjectSetInteger(0, liquidityName, OBJPROP_STYLE, STYLE_DOT);
         }
         
         ObjectSetInteger(0, liquidityName, OBJPROP_COLOR, liquidityColor);
         ObjectSetInteger(0, liquidityName, OBJPROP_WIDTH, lineWidth);
         
         string labelName = liquidityName + "_Label";
         ObjectCreate(0, labelName, OBJ_TEXT, 0, TimeCurrent(), LiquidityLevels[i].price);
         ObjectSetString(0, labelName, OBJPROP_TEXT, 
                        EnumToString(LiquidityLevels[i].type) + " (" + DoubleToString(LiquidityLevels[i].strength, 1) + ")");
         ObjectSetInteger(0, labelName, OBJPROP_COLOR, liquidityColor);
         ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
      }
   }
}

//+------------------------------------------------------------------+
//| Update Premium Discount Visuals                                 |
//+------------------------------------------------------------------+
void UpdatePremiumDiscountVisuals()
{
   if(RangeHigh == 0 || RangeLow == 0) return;
   
   // Range Box
   string pdRangeName = "AIME_PD_Range";
   if(ObjectFind(0, pdRangeName) < 0)
   {
      datetime startTime = TimeCurrent() - 86400;
      ObjectCreate(0, pdRangeName, OBJ_RECTANGLE, 0, startTime, RangeHigh, TimeCurrent(), RangeLow);
      ObjectSetInteger(0, pdRangeName, OBJPROP_FILL, false);
      ObjectSetInteger(0, pdRangeName, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, pdRangeName, OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(0, pdRangeName, OBJPROP_WIDTH, 1);
   }
   else
   {
      ObjectSetDouble(0, pdRangeName, OBJPROP_PRICE, 0, RangeHigh);
      ObjectSetDouble(0, pdRangeName, OBJPROP_PRICE, 1, RangeLow);
      ObjectSetInteger(0, pdRangeName, OBJPROP_TIME, 1, TimeCurrent());
   }
   
   // Premium Level
   double premiumLevel = RangeLow + ((RangeHigh - RangeLow) * PremiumThreshold);
   string premiumLineName = "AIME_Premium_Line";
   if(ObjectFind(0, premiumLineName) < 0)
   {
      ObjectCreate(0, premiumLineName, OBJ_HLINE, 0, 0, premiumLevel);
      ObjectSetInteger(0, premiumLineName, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, premiumLineName, OBJPROP_STYLE, STYLE_DASH);
   }
   else
   {
      ObjectSetDouble(0, premiumLineName, OBJPROP_PRICE, premiumLevel);
   }
   
   // Discount Level
   double discountLevel = RangeLow + ((RangeHigh - RangeLow) * DiscountThreshold);
   string discountLineName = "AIME_Discount_Line";
   if(ObjectFind(0, discountLineName) < 0)
   {
      ObjectCreate(0, discountLineName, OBJ_HLINE, 0, 0, discountLevel);
      ObjectSetInteger(0, discountLineName, OBJPROP_COLOR, clrLime);
      ObjectSetInteger(0, discountLineName, OBJPROP_STYLE, STYLE_DASH);
   }
   else
   {
      ObjectSetDouble(0, discountLineName, OBJPROP_PRICE, discountLevel);
   }
   
   // Equilibrium Level
   double equilibriumLevel = (RangeHigh + RangeLow) / 2.0;
   string equilibriumLineName = "AIME_Equilibrium_Line";
   if(ObjectFind(0, equilibriumLineName) < 0)
   {
      ObjectCreate(0, equilibriumLineName, OBJ_HLINE, 0, 0, equilibriumLevel);
      ObjectSetInteger(0, equilibriumLineName, OBJPROP_COLOR, clrYellow);
      ObjectSetInteger(0, equilibriumLineName, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, equilibriumLineName, OBJPROP_WIDTH, 2);
   }
   else
   {
      ObjectSetDouble(0, equilibriumLineName, OBJPROP_PRICE, equilibriumLevel);
   }
}

//+------------------------------------------------------------------+
//| Create Killzone Elements                                        |
//+------------------------------------------------------------------+
void CreateKillzoneElements()
{
   if(CurrentKillzone == KZ_INACTIVE) return;
   
   string killzoneName = "AIME_Killzone_Highlight";
   
   datetime currentTime = TimeCurrent();
   datetime killzoneStart = currentTime - 1800;
   datetime killzoneEnd = currentTime + 1800;
   
   double currentHigh = Rates[RatesTotal-1].high;
   double currentLow = Rates[RatesTotal-1].low;
   double atr = GetCachedATR();
   
   if(ObjectFind(0, killzoneName) < 0)
   {
      ObjectCreate(0, killzoneName, OBJ_RECTANGLE, 0, 
                  killzoneStart, currentHigh + atr * 0.5,
                  killzoneEnd, currentLow - atr * 0.5);
      
      color killzoneColor = clrNONE;
      switch(CurrentKillzone)
      {
         case LONDON_OPEN:
         case NEW_YORK_OPEN:
            killzoneColor = C'0,50,0';
            break;
         case SILVER_BULLET:
            killzoneColor = C'50,50,0';
            break;
         case MACRO_TIME:
            killzoneColor = C'0,0,50';
            break;
         default:
            killzoneColor = C'30,30,30';
            break;
      }
      
      ObjectSetInteger(0, killzoneName, OBJPROP_BGCOLOR, killzoneColor);
      ObjectSetInteger(0, killzoneName, OBJPROP_FILL, true);
      ObjectSetInteger(0, killzoneName, OBJPROP_BACK, true);
   }
   
   string killzoneLabelName = "AIME_Killzone_Label";
   if(ObjectFind(0, killzoneLabelName) < 0)
   {
      ObjectCreate(0, killzoneLabelName, OBJ_TEXT, 0, currentTime, currentHigh + atr * 0.3);
      ObjectSetString(0, killzoneLabelName, OBJPROP_TEXT, EnumToString(CurrentKillzone));
      ObjectSetInteger(0, killzoneLabelName, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, killzoneLabelName, OBJPROP_FONTSIZE, 10);
      ObjectSetString(0, killzoneLabelName, OBJPROP_FONT, "Arial Bold");
   }
}

//+------------------------------------------------------------------+
//| Cleanup Visual Elements                                         |
//+------------------------------------------------------------------+
void CleanupVisualElements()
{
   datetime currentTime = TimeCurrent();
   
   // Remove old objects
   for(int i = ObjectsTotal(0) - 1; i >= 0; i--)
   {
      string objectName = ObjectName(0, i);
      
      if(StringFind(objectName, "AIME_", 0) == 0)
      {
         datetime objectTime = (datetime)ObjectGetInteger(0, objectName, OBJPROP_TIME);
         if(objectTime > 0 && currentTime - objectTime > 14400) // 4 hours
         {
            ObjectDelete(0, objectName);
         }
      }
   }
   
   // Limit total objects
   if(ObjectsTotal(0) > 200)
   {
      for(int i = ObjectsTotal(0) - 1; i >= 0 && ObjectsTotal(0) > 150; i--)
      {
         string objectName = ObjectName(0, i);
         if(StringFind(objectName, "AIME_", 0) == 0 && 
            StringFind(objectName, "Dashboard", 0) < 0)
         {
            ObjectDelete(0, objectName);
         }
      }
   }
}

#endif // AIME_CHART_OBJECTS_MQH

//+------------------------------------------------------------------+
//|                                    AIME_DragonflyEntry.mqh       |
//|                      Dragonfly Entry Strategy Module             |
//+------------------------------------------------------------------+
#ifndef AIME_DRAGONFLY_ENTRY_MQH
#define AIME_DRAGONFLY_ENTRY_MQH

//+------------------------------------------------------------------+
//| Execute Dragonfly Strategy                                      |
//+------------------------------------------------------------------+
bool ExecuteDragonflyStrategy()
{
   // Dragonfly: Order Block + FVG confluence + PD optimal
   double currentPrice = Rates[RatesTotal-1].close;
   double atr = GetCachedATR();
   
   // Find Order Block + FVG confluence
   for(int i = 0; i < OrderBlockCount; i++)
   {
      if(!OrderBlocks[i].isActive || OrderBlocks[i].strength < 6.0) continue;
      
      // Look for FVG near this Order Block
      for(int j = 0; j < FVGCount; j++)
      {
         if(!FairValueGaps[j].isActive || FairValueGaps[j].strength < 6.0) continue;
         
         // Check proximity (within 1.5 ATR)
         if(MathAbs(OrderBlocks[i].price - FairValueGaps[j].midPrice) <= atr * 1.5)
         {
            // Check directional alignment
            bool aligned = (OrderBlocks[i].isBullish && FairValueGaps[j].direction == FAIR_VALUE_GAP_BULLISH) ||
                          (!OrderBlocks[i].isBullish && FairValueGaps[j].direction == FAIR_VALUE_GAP_BEARISH);
            
            if(aligned)
            {
               // Check Premium/Discount alignment
               bool pdAligned = (OrderBlocks[i].isBullish && IsInDiscount) ||
                               (!OrderBlocks[i].isBullish && IsInPremium);
               
               if(pdAligned)
               {
                  // Calculate Dragonfly confluence
                  double confluence = CalculateDragonflyConfluence(i, j);
                  
                  if(confluence >= DragonflyConfluenceThreshold)
                  {
                     return ExecuteDragonflyTrade(i, j, OrderBlocks[i].isBullish, confluence);
                  }
               }
            }
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Calculate Dragonfly Confluence                                  |
//+------------------------------------------------------------------+
double CalculateDragonflyConfluence(int obIndex, int fvgIndex)
{
   double confluence = 0.6; // Base for Dragonfly
   
   // Order Block quality (30% weight)
   confluence += (OrderBlocks[obIndex].strength / 10.0) * 0.30;
   
   // FVG quality (30% weight)
   confluence += (FairValueGaps[fvgIndex].strength / 10.0) * 0.30;
   
   // Structure alignment (20% weight)
   if(MarketStructure.hasBreakOfStructure) confluence += 0.15;
   else if(MarketStructure.hasChangeOfCharacter) confluence += 0.10;
   else confluence += 0.05;
   
   // Premium/Discount alignment (10% weight)
   confluence += 0.10; // Already validated
   
   // Timing quality (10% weight)
   if(IsOptimalTradingTime) confluence += 0.10;
   else confluence += 0.05;
   
   return MathMin(1.0, confluence);
}

//+------------------------------------------------------------------+
//| Execute Dragonfly Trade                                         |
//+------------------------------------------------------------------+
bool ExecuteDragonflyTrade(int obIndex, int fvgIndex, bool isBullish, double confluence)
{
   double atr = GetCachedATR();
   
   // Entry between OB and FVG levels
   double obPrice = OrderBlocks[obIndex].price;
   double fvgPrice = FairValueGaps[fvgIndex].midPrice;
   double entryPrice = (obPrice + fvgPrice) / 2.0;
   
   // Stop loss beyond the farthest level
   double stopLoss;
   if(isBullish)
   {
      double farthestLow = MathMin(OrderBlocks[obIndex].low, FairValueGaps[fvgIndex].bottomPrice);
      stopLoss = farthestLow - (atr * 0.5);
   }
   else
   {
      double farthestHigh = MathMax(OrderBlocks[obIndex].high, FairValueGaps[fvgIndex].topPrice);
      stopLoss = farthestHigh + (atr * 0.5);
   }
   
   // Take profit based on confluence
   double tpMultiplier = 2.0 + (confluence * 2.0); // 2-4 ATR based on confluence
   double takeProfit = isBullish ?
                       entryPrice + (atr * tpMultiplier) :
                       entryPrice - (atr * tpMultiplier);
   
   // Position sizing with confluence adjustment
   double lotSize = CalculateOptimalPositionSize(entryPrice, stopLoss, confluence * 1.3);
   
   bool success = ExecuteICTTrade(isBullish ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,
                                  lotSize, entryPrice, stopLoss, takeProfit,
                                  "Dragonfly Entry - Conf: " + DoubleToString(confluence, 2));
   
   if(success)
   {
      Print("Dragonfly Trade: ", (isBullish ? "BUY" : "SELL"), 
            " | Confluence: ", confluence, " | Entry: ", entryPrice);
   }
   
   return success;
}

#endif // AIME_DRAGONFLY_ENTRY_MQH

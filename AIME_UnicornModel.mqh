//+------------------------------------------------------------------+
//|                                       AIME_UnicornModel.mqh      |
//|                         Unicorn Model Strategy Module            |
//+------------------------------------------------------------------+
#ifndef AIME_UNICORN_MODEL_MQH
#define AIME_UNICORN_MODEL_MQH

//+------------------------------------------------------------------+
//| Execute Unicorn Model Strategy                                  |
//+------------------------------------------------------------------+
bool ExecuteUnicornModelStrategy()
{
   // Unicorn Model: Liquidity grab + FVG + Displacement + Optimal timing
   double currentPrice = Rates[RatesTotal-1].close;
   double atr = GetCachedATR();
   
   // Check for recent liquidity grab
   bool recentLiquidityGrab = false;
   double liquidityGrabLevel = 0;
   bool grabBullish = false;
   
   for(int i = 0; i < LiquidityLevelCount; i++)
   {
      if(LiquidityLevels[i].isRaided && 
         TimeCurrent() - LiquidityLevels[i].raidTime <= 300 && // Within 5 minutes
         LiquidityLevels[i].displacementAfterRaid >= LiquidityGrabDisplacement * atr)
      {
         recentLiquidityGrab = true;
         liquidityGrabLevel = LiquidityLevels[i].price;
         grabBullish = (currentPrice > liquidityGrabLevel);
         break;
      }
   }
   
   if(!recentLiquidityGrab) return false;
   
   // Look for FVG in opposite direction of liquidity grab
   int validFVGIndex = -1;
   
   for(int i = 0; i < FVGCount; i++)
   {
      if(!FairValueGaps[i].isActive) continue;
      
      // FVG should be opposite to grab direction and high quality
      bool fvgAligned = false;
      if(grabBullish && FairValueGaps[i].direction == FAIR_VALUE_GAP_BEARISH) fvgAligned = true;
      if(!grabBullish && FairValueGaps[i].direction == FAIR_VALUE_GAP_BULLISH) fvgAligned = true;
      
      if(fvgAligned && FairValueGaps[i].strength >= 7.0 &&
         MathAbs(FairValueGaps[i].midPrice - currentPrice) <= atr * 1.5)
      {
         validFVGIndex = i;
         break;
      }
   }
   
   if(validFVGIndex == -1) return false;
   
   // Check for strong displacement
   double displacement = CalculateRecentDisplacement(5);
   if(displacement < atr * 2.0) return false;
   
   // Optimal timing check
   if(!IsOptimalTradingTime) return false;
   
   // Premium/Discount alignment
   bool pdAligned = false;
   if(grabBullish && IsInDiscount) pdAligned = true;
   if(!grabBullish && IsInPremium) pdAligned = true;
   
   if(!pdAligned) return false;
   
   // Calculate confluence score
   double confluence = CalculateUnicornConfluence(validFVGIndex, displacement, atr);
   if(confluence < UnicornConfluenceThreshold) return false;
   
   // Execute Unicorn Model trade
   return ExecuteUnicornTrade(grabBullish, validFVGIndex, liquidityGrabLevel, confluence);
}

//+------------------------------------------------------------------+
//| Calculate Unicorn Confluence                                    |
//+------------------------------------------------------------------+
double CalculateUnicornConfluence(int fvgIndex, double displacement, double atr)
{
   double confluence = 0.7; // Base for Unicorn setup
   
   // FVG quality (25% weight)
   confluence += (FairValueGaps[fvgIndex].strength / 10.0) * 0.25;
   
   // Displacement strength (25% weight)
   double displacementScore = MathMin(1.0, displacement / (atr * 4.0));
   confluence += displacementScore * 0.25;
   
   // Timing quality (20% weight)
   if(CurrentKillzone == SILVER_BULLET) confluence += 0.20;
   else if(IsOptimalTradingTime) confluence += 0.15;
   else confluence += 0.10;
   
   // Structure alignment (15% weight)
   if(MarketStructure.hasMarketStructureShift) confluence += 0.15;
   else if(MarketStructure.hasBreakOfStructure) confluence += 0.12;
   else confluence += 0.08;
   
   // Premium/Discount alignment (10% weight)
   if(IsInPremium || IsInDiscount) confluence += 0.10;
   else confluence += 0.05;
   
   // Liquidity strength bonus (5% weight)
   confluence += 0.05; // Already validated strong liquidity grab
   
   return MathMin(1.0, confluence);
}

//+------------------------------------------------------------------+
//| Execute Unicorn Trade                                           |
//+------------------------------------------------------------------+
bool ExecuteUnicornTrade(bool isBullish, int fvgIndex, double liquidityLevel, double confluence)
{
   double atr = GetCachedATR();
   double currentPrice = Rates[RatesTotal-1].close;
   
   // Entry: At FVG boundaries
   double entryPrice = isBullish ? FairValueGaps[fvgIndex].bottomPrice : FairValueGaps[fvgIndex].topPrice;
   
   // Stop Loss: Beyond liquidity grab level with buffer
   double stopLoss = isBullish ? liquidityLevel - (atr * 0.6) : liquidityLevel + (atr * 0.6);
   
   // Take Profit: Multiple targets based on structure and confluence
   double tp1 = isBullish ? entryPrice + (atr * 3.0) : entryPrice - (atr * 3.0);
   double tp2 = isBullish ? entryPrice + (atr * 6.0) : entryPrice - (atr * 6.0);
   double tp3 = isBullish ? entryPrice + (atr * 10.0) : entryPrice - (atr * 10.0);
   
   // Position sizing with Unicorn bonus
   double lotSize = CalculateOptimalPositionSize(entryPrice, stopLoss, confluence * 1.6); // Max 1.6x multiplier
   
   // Execute the trade
   bool success = ExecuteICTTrade(isBullish ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, 
                                  lotSize, entryPrice, stopLoss, tp1, 
                                  "Unicorn Model - Conf: " + DoubleToString(confluence, 2));
   
   if(success)
   {
      Print("Unicorn Model Trade Executed: ", (isBullish ? "BUY" : "SELL"), 
            " | Entry: ", entryPrice, " | SL: ", stopLoss, " | Confluence: ", confluence);
   }
   
   return success;
}

#endif // AIME_UNICORN_MODEL_MQH

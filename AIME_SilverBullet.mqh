//+------------------------------------------------------------------+
//|                                      AIME_SilverBullet.mqh       |
//|                       Silver Bullet Strategy Module              |
//+------------------------------------------------------------------+
#ifndef AIME_SILVER_BULLET_MQH
#define AIME_SILVER_BULLET_MQH

//+------------------------------------------------------------------+
//| Execute Silver Bullet Strategy                                  |
//+------------------------------------------------------------------+
bool ExecuteSilverBulletStrategy()
{
   // Silver Bullet: Specific killzone timing + Liquidity raids + Displacement
   if(CurrentKillzone != SILVER_BULLET) return false;
   
   double atr = GetCachedATR();
   double currentPrice = Rates[RatesTotal-1].close;
   
   // Look for liquidity raid + displacement combination
   for(int i = 0; i < LiquidityLevelCount; i++)
   {
      if(LiquidityLevels[i].isRaided &&
         TimeCurrent() - LiquidityLevels[i].raidTime <= 120 && // Within 2 minutes
         LiquidityLevels[i].displacementAfterRaid >= atr * 2.0)
      {
         bool isBullish = (currentPrice > LiquidityLevels[i].price);
         
         // Look for entry pattern in displacement direction
         if(FindSilverBulletEntry(isBullish, LiquidityLevels[i].price))
         {
            return ExecuteSilverBulletTrade(isBullish, LiquidityLevels[i].price);
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Find Silver Bullet Entry                                        |
//+------------------------------------------------------------------+
bool FindSilverBulletEntry(bool isBullish, double liquidityLevel)
{
   double currentPrice = Rates[RatesTotal-1].close;
   double atr = GetCachedATR();
   
   // Look for FVG in displacement direction
   for(int i = 0; i < FVGCount; i++)
   {
      if(!FairValueGaps[i].isActive) continue;
      
      bool fvgAligned = (isBullish && FairValueGaps[i].direction == FAIR_VALUE_GAP_BULLISH) ||
                        (!isBullish && FairValueGaps[i].direction == FAIR_VALUE_GAP_BEARISH);
      
      if(fvgAligned && 
         MathAbs(FairValueGaps[i].midPrice - currentPrice) <= atr * 0.8 &&
         FairValueGaps[i].strength >= 5.0)
      {
         return true;
      }
   }
   
   // Look for Order Block in displacement direction
   for(int i = 0; i < OrderBlockCount; i++)
   {
      if(!OrderBlocks[i].isActive) continue;
      
      bool obAligned = (isBullish && OrderBlocks[i].isBullish) ||
                       (!isBullish && !OrderBlocks[i].isBullish);
      
      if(obAligned &&
         MathAbs(OrderBlocks[i].price - currentPrice) <= atr * 0.8 &&
         OrderBlocks[i].strength >= 5.0)
      {
         return true;
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Execute Silver Bullet Trade                                     |
//+------------------------------------------------------------------+
bool ExecuteSilverBulletTrade(bool isBullish, double liquidityLevel)
{
   double atr = GetCachedATR();
   double currentPrice = Rates[RatesTotal-1].close;
   
   // Aggressive entry (market order style)
   double entryPrice = currentPrice;
   
   // Stop loss beyond liquidity level
   double stopLoss = isBullish ?
                     liquidityLevel - (atr * 0.5) :
                     liquidityLevel + (atr * 0.5);
   
   // Multiple targets for Silver Bullet
   double tp1 = isBullish ? entryPrice + (atr * 2.0) : entryPrice - (atr * 2.0);
   
   // Larger position size for Silver Bullet (high probability)
   double lotSize = CalculateOptimalPositionSize(entryPrice, stopLoss, 1.3);
   
   bool success = ExecuteICTTrade(isBullish ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,
                                  lotSize, entryPrice, stopLoss, tp1,
                                  "Silver Bullet");
   
   if(success)
   {
      Print("Silver Bullet Trade: ", (isBullish ? "BUY" : "SELL"), " at ", entryPrice);
   }
   
   return success;
}

#endif // AIME_SILVER_BULLET_MQH

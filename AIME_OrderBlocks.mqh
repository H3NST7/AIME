//+------------------------------------------------------------------+
//|                                          AIME_OrderBlocks.mqh    |
//|                        Complete Order Block Analysis             |
//+------------------------------------------------------------------+
#ifndef AIME_ORDER_BLOCKS_MQH
#define AIME_ORDER_BLOCKS_MQH

//+------------------------------------------------------------------+
//| Detect And Analyze Order Blocks                                 |
//+------------------------------------------------------------------+
void DetectAndAnalyzeOrderBlocks()
{
   if(RatesTotal < 10) return;
   
   double atr = GetCachedATR();
   if(atr <= 0) return;
   
   // Clean up old order blocks
   CleanupOldOrderBlocks();
   
   // Detect new order blocks using multiple methods
   for(int i = 5; i < RatesTotal - 2; i++)
   {
      // Last up/down order block detection
      DetectLastUpDownOrderBlock(i, atr);
      
      // Liquidity linked order blocks
      DetectLiquidityLinkedOrderBlock(i, atr);
      
      // Breaker order blocks
      DetectBreakerOrderBlock(i, atr);
   }
   
   // Update existing order blocks
   UpdateExistingOrderBlocks();
}

//+------------------------------------------------------------------+
//| Detect Last Up/Down Order Block                                 |
//+------------------------------------------------------------------+
void DetectLastUpDownOrderBlock(int index, double atr)
{
   if(index < 5) return;
   
   // Look for displacement candles
   for(int i = index; i >= index - 3; i--)
   {
      double candleSize = MathAbs(Rates[i].close - Rates[i].open);
      if(candleSize < atr * 1.2) continue;
      
      bool isBullishDisplacement = (Rates[i].close > Rates[i].open);
      
      // Look for last opposite candle before displacement
      for(int j = i - 1; j >= i - 5; j--)
      {
         if(j < 0) break;
         
         bool isBullishCandle = (Rates[j].close > Rates[j].open);
         
         // Bullish order block: last down candle before bullish displacement
         if(isBullishDisplacement && !isBullishCandle)
         {
            if(ValidateOrderBlockQuality(j, true, atr))
            {
               CreateNewOrderBlock(j, true, atr, ORDER_BLOCK_BULLISH);
               break;
            }
         }
         // Bearish order block: last up candle before bearish displacement
         else if(!isBullishDisplacement && isBullishCandle)
         {
            if(ValidateOrderBlockQuality(j, false, atr))
            {
               CreateNewOrderBlock(j, false, atr, ORDER_BLOCK_BEARISH);
               break;
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Liquidity Linked Order Block                             |
//+------------------------------------------------------------------+
void DetectLiquidityLinkedOrderBlock(int index, double atr)
{
   // Check if there was a recent liquidity raid
   bool recentLiquidityRaid = false;
   double liquidityLevel = 0;
   
   for(int i = 0; i < LiquidityLevelCount; i++)
   {
      if(LiquidityLevels[i].isRaided && 
         MathAbs(LiquidityLevels[i].raidTime - Rates[index].time) <= 5 * 60) // Within 5 minutes
      {
         recentLiquidityRaid = true;
         liquidityLevel = LiquidityLevels[i].price;
         break;
      }
   }
   
   if(!recentLiquidityRaid) return;
   
   // Look for order blocks near the liquidity level
   for(int i = index - 5; i <= index; i++)
   {
      if(i < 1) continue;
      
      if(MathAbs(Rates[i].close - liquidityLevel) <= atr * 0.5)
      {
         bool isBullish = (Rates[i].close > Rates[i].open);
         
         if(ValidateOrderBlockQuality(i, isBullish, atr))
         {
            ENUM_AIME_PATTERN obType = isBullish ? ORDER_BLOCK_BULLISH : ORDER_BLOCK_BEARISH;
            CreateNewOrderBlock(i, isBullish, atr, obType);
            
            // Mark as liquidity-linked
            if(OrderBlockCount > 0)
            {
               OrderBlocks[OrderBlockCount-1].hasLiquidityGrab = true;
               OrderBlocks[OrderBlockCount-1].liquidityLevel = liquidityLevel;
               OrderBlocks[OrderBlockCount-1].strength += 2.0;
               OrderBlocks[OrderBlockCount-1].strength = MathMin(10.0, OrderBlocks[OrderBlockCount-1].strength);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Breaker Order Block                                      |
//+------------------------------------------------------------------+
void DetectBreakerOrderBlock(int index, double atr)
{
   // Check existing order blocks for breaker conversion
   for(int i = 0; i < OrderBlockCount; i++)
   {
      if(!OrderBlocks[i].isActive || OrderBlocks[i].isBreaker) continue;
      
      double currentPrice = Rates[index].close;
      bool broken = false;
      
      // Check if order block has been broken
      if(OrderBlocks[i].isBullish)
      {
         // Bullish OB broken to downside
         if(currentPrice < OrderBlocks[i].low - atr * 0.2)
         {
            double displacement = CalculateDisplacementAtIndex(index, 3);
            if(displacement > atr * 1.0)
            {
               broken = true;
            }
         }
      }
      else
      {
         // Bearish OB broken to upside
         if(currentPrice > OrderBlocks[i].high + atr * 0.2)
         {
            double displacement = CalculateDisplacementAtIndex(index, 3);
            if(displacement > atr * 1.0)
            {
               broken = true;
            }
         }
      }
      
      if(broken)
      {
         // Increment rejection count
         OrderBlocks[i].rejectionCount++;
         
         // Convert to breaker after first break
         if(OrderBlocks[i].rejectionCount >= 1)
         {
            OrderBlocks[i].isBreaker = true;
            OrderBlocks[i].isBullish = !OrderBlocks[i].isBullish; // Flip direction
            OrderBlocks[i].patternType = ORDER_BLOCK_BREAKER;
            OrderBlocks[i].strength += 1.5;
            OrderBlocks[i].strength = MathMin(10.0, OrderBlocks[i].strength);
            
            Print("Order Block converted to Breaker: ", (OrderBlocks[i].isBullish ? "Bullish" : "Bearish"));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Validate Order Block Quality                                    |
//+------------------------------------------------------------------+
bool ValidateOrderBlockQuality(int index, bool isBullish, double atr)
{
   if(index < 1 || index >= RatesTotal) return false;
   
   // Calculate candle metrics
   double candleBody = MathAbs(Rates[index].close - Rates[index].open);
   double candleRange = Rates[index].high - Rates[index].low;
   
   // Minimum size requirements
   if(candleBody < atr * 0.3) return false;
   if(candleRange < atr * 0.4) return false;
   
   // Body to range ratio
   double bodyRatio = candleBody / candleRange;
   if(bodyRatio < 0.4) return false; // Need significant body
   
   // Check for displacement after this candle
   double displacement = CalculateDisplacementAtIndex(index + 1, 3);
   if(displacement < atr * 1.2) return false;
   
   // Duplicate check
   if(IsDuplicateOrderBlock(Rates[index].high, Rates[index].low, atr)) return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Create New Order Block                                          |
//+------------------------------------------------------------------+
void CreateNewOrderBlock(int index, bool isBullish, double atr, ENUM_AIME_PATTERN patternType)
{
   if(OrderBlockCount >= ArraySize(OrderBlocks)) return;
   
   SOrderBlock newOB;
   newOB.price = isBullish ? Rates[index].close : Rates[index].close;
   newOB.high = Rates[index].high;
   newOB.low = Rates[index].low;
   newOB.open = Rates[index].open;
   newOB.close = Rates[index].close;
   newOB.time = Rates[index].time;
   newOB.isBullish = isBullish;
   newOB.isActive = true;
   newOB.patternType = patternType;
   newOB.atr = atr;
   newOB.candleIndex = index;
   newOB.volume = (uint)Rates[index].tick_volume;
   
   // Calculate displacement after order block
   newOB.displacement = CalculateDisplacementAtIndex(index + 1, 3);
   
   // Calculate order block strength
   newOB.strength = CalculateOrderBlockStrength(newOB, atr);
   newOB.isOptimal = (newOB.strength >= 7.0);
   newOB.isInstitutional = (newOB.strength >= InstitutionalOBThreshold);
   
   OrderBlocks[OrderBlockCount] = newOB;
   OrderBlockCount++;
   
   Print("New Order Block Created: ", (isBullish ? "Bullish" : "Bearish"), 
         " | Strength: ", newOB.strength, " | Price: ", newOB.price);
}

//+------------------------------------------------------------------+
//| Calculate Order Block Strength                                  |
//+------------------------------------------------------------------+
double CalculateOrderBlockStrength(SOrderBlock &ob, double atr)
{
   double strength = 5.0; // Base strength
   
   // Body size component (20% weight)
   double bodySize = MathAbs(ob.close - ob.open);
   double sizeRatio = bodySize / atr;
   if(sizeRatio > 1.5) strength += 2.0;
   else if(sizeRatio > 1.0) strength += 1.0;
   
   // Body to range ratio (15% weight)
   double bodyRatio = bodySize / (ob.high - ob.low);
   if(bodyRatio > 0.8) strength += 2.0;
   else if(bodyRatio > 0.6) strength += 1.0;
   
   // Displacement component (30% weight)
   if(ob.displacement > 3.0) strength += 3.0;
   else if(ob.displacement > 2.0) strength += 2.0;
   
   // Volume component (10% weight)
   if(ob.volume > 0)
   {
      double avgVolume = CalculateAverageVolume(ob.candleIndex, 20);
      if(avgVolume > 0)
      {
         double volumeRatio = ob.volume / avgVolume;
         if(volumeRatio > 2.0) strength += 1.0;
      }
   }
   
   // Structure alignment (20% weight)
   if(ValidateStructureAlignment(ob.isBullish ? ORDER_BLOCK_BULLISH : ORDER_BLOCK_BEARISH))
      strength += 2.0;
   
   // Killzone timing (30% weight)
   if(IsOptimalKillzoneTime(ob.time)) strength += 3.0;
   
   // Premium/Discount alignment (15% weight)
   if(IsPremiumDiscountAligned(ob.isBullish ? ORDER_BLOCK_BULLISH : ORDER_BLOCK_BEARISH, ob.price))
      strength += 1.5;
   
   // Liquidity grab bonus (20% weight)
   if(ob.hasLiquidityGrab) strength += 2.0;
   
   return MathMax(1.0, MathMin(10.0, strength));
}

//+------------------------------------------------------------------+
//| Update Existing Order Blocks                                    |
//+------------------------------------------------------------------+
void UpdateExistingOrderBlocks()
{
   // Order blocks are relatively static, main updates happen in real-time checks
   for(int i = 0; i < OrderBlockCount; i++)
   {
      if(!OrderBlocks[i].isActive) continue;
      
      // Update can be enhanced here if needed
   }
}

//+------------------------------------------------------------------+
//| Check Realtime Order Block Formation                            |
//+------------------------------------------------------------------+
void CheckRealtimeOrderBlockFormation()
{
   if(RatesTotal < 5) return;
   
   double atr = GetCachedATR();
   if(atr <= 0) return;
   
   int index = RatesTotal - 1;
   DetectLastUpDownOrderBlock(index, atr);
   
   // Check for order block mitigation
   CheckForOrderBlockMitigation();
}

//+------------------------------------------------------------------+
//| Check For Order Block Mitigation                                |
//+------------------------------------------------------------------+
void CheckForOrderBlockMitigation()
{
   double currentPrice = Rates[RatesTotal-1].close;
   
   for(int i = 0; i < OrderBlockCount; i++)
   {
      if(!OrderBlocks[i].isActive || OrderBlocks[i].isMitigated) continue;
      
      bool mitigated = false;
      
      // Check if price has entered order block zone
      if(OrderBlocks[i].isBullish)
      {
         if(currentPrice >= OrderBlocks[i].low && currentPrice <= OrderBlocks[i].high)
         {
            mitigated = true;
         }
      }
      else
      {
         if(currentPrice >= OrderBlocks[i].low && currentPrice <= OrderBlocks[i].high)
         {
            mitigated = true;
         }
      }
      
      if(mitigated)
      {
         OrderBlocks[i].rejectionCount++;
         
         // Create refined order block after multiple touches
         if(OrderBlocks[i].rejectionCount >= 2 && !OrderBlocks[i].isRefinement)
         {
            CreateRefinedOrderBlock(i);
         }
         
         // Mark as mitigated after 3 touches
         if(OrderBlocks[i].rejectionCount >= 3)
         {
            OrderBlocks[i].isMitigated = true;
            OrderBlocks[i].patternType = ORDER_BLOCK_MITIGATION;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Create Refined Order Block                                      |
//+------------------------------------------------------------------+
void CreateRefinedOrderBlock(int originalIndex)
{
   if(OrderBlockCount >= ArraySize(OrderBlocks)) return;
   
   // Copy original order block
   SOrderBlock refinedOB = OrderBlocks[originalIndex];
   refinedOB.isRefinement = true;
   refinedOB.rejectionCount = 0;
   refinedOB.strength += 1.0;
   refinedOB.strength = MathMin(10.0, refinedOB.strength);
   
   // Refine the levels based on current price action
   double currentPrice = Rates[RatesTotal-1].close;
   double atr = GetCachedATR();
   
   if(refinedOB.isBullish)
   {
      // Refine bullish order block
      refinedOB.high = MathMin(refinedOB.high, currentPrice + atr * 0.2);
      refinedOB.low = MathMax(refinedOB.low, currentPrice - atr * 0.2);
   }
   else
   {
      // Refine bearish order block
      refinedOB.high = MathMin(refinedOB.high, currentPrice + atr * 0.2);
      refinedOB.low = MathMax(refinedOB.low, currentPrice - atr * 0.2);
   }
   
   // Update price to middle of refined zone
   refinedOB.price = (refinedOB.high + refinedOB.low) / 2.0;
   
   OrderBlocks[OrderBlockCount] = refinedOB;
   OrderBlockCount++;
   
   Print("Refined Order Block Created at ", refinedOB.price);
}

//+------------------------------------------------------------------+
//| Cleanup Old Order Blocks                                        |
//+------------------------------------------------------------------+
void CleanupOldOrderBlocks()
{
   datetime currentTime = TimeCurrent();
   double atr = GetCachedATR();
   
   for(int i = 0; i < OrderBlockCount; i++)
   {
      if(!OrderBlocks[i].isActive) continue;
      
      // Calculate max age based on order block quality
      int maxAge = 6 * 3600; // 6 hours default
      if(OrderBlocks[i].isOptimal) maxAge = 12 * 3600; // 12 hours for optimal OBs
      
      // Remove old order blocks
      if(currentTime - OrderBlocks[i].time > maxAge)
      {
         OrderBlocks[i].isActive = false;
         continue;
      }
      
      // Remove mitigated order blocks after too many rejections
      if(OrderBlocks[i].isMitigated && OrderBlocks[i].rejectionCount >= 3)
      {
         OrderBlocks[i].isActive = false;
         continue;
      }
      
      // Remove weak order blocks that are old
      if(OrderBlocks[i].strength < 3.5 && currentTime - OrderBlocks[i].time > 3600)
      {
         OrderBlocks[i].isActive = false;
         continue;
      }
      
      // Remove order blocks too far from current price
      double currentPrice = Rates[RatesTotal-1].close;
      if(MathAbs(OrderBlocks[i].price - currentPrice) > atr * 15.0)
      {
         OrderBlocks[i].isActive = false;
      }
   }
}

//+------------------------------------------------------------------+
//| Check if Order Block is Duplicate                               |
//+------------------------------------------------------------------+
bool IsDuplicateOrderBlock(double high, double low, double atr)
{
   for(int i = 0; i < OrderBlockCount; i++)
   {
      if(OrderBlocks[i].isActive)
      {
         if(MathAbs(OrderBlocks[i].high - high) <= atr * 0.3 &&
            MathAbs(OrderBlocks[i].low - low) <= atr * 0.3)
         {
            return true;
         }
      }
   }
   
   return false;
}

#endif // AIME_ORDER_BLOCKS_MQH

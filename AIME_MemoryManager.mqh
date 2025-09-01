//+------------------------------------------------------------------+
//|                                      AIME_MemoryManager.mqh      |
//|                        Memory Management Module                  |
//+------------------------------------------------------------------+
#ifndef AIME_MEMORY_MANAGER_MQH
#define AIME_MEMORY_MANAGER_MQH

//+------------------------------------------------------------------+
//| Smart Memory Management                                         |
//+------------------------------------------------------------------+
void SmartMemoryManagement()
{
   OptimizeArrays();
   CleanupOldPatterns();
   CleanupVisualElements();
   
   if(ErrorCount > 5)
   {
      AttemptErrorRecovery();
   }
}

//+------------------------------------------------------------------+
//| Optimize Memory Usage                                           |
//+------------------------------------------------------------------+
void OptimizeMemoryUsage()
{
   // Call smart memory management
   SmartMemoryManagement();
}

//+------------------------------------------------------------------+
//| Optimize Arrays                                                 |
//+------------------------------------------------------------------+
void OptimizeArrays()
{
   // Check FVG array
   int activeFVGs = 0;
   for(int i = 0; i < FVGCount; i++)
   {
      if(FairValueGaps[i].isActive) activeFVGs++;
   }
   
   if(activeFVGs < FVGCount / 2)
   {
      CompactFVGArray();
   }
   
   // Check Order Block array
   int activeOBs = 0;
   for(int i = 0; i < OrderBlockCount; i++)
   {
      if(OrderBlocks[i].isActive) activeOBs++;
   }
   
   if(activeOBs < OrderBlockCount / 2)
   {
      CompactOrderBlockArray();
   }
   
   // Check Liquidity array
   int activeLiquidity = 0;
   for(int i = 0; i < LiquidityLevelCount; i++)
   {
      if(LiquidityLevels[i].isActive) activeLiquidity++;
   }
   
   if(activeLiquidity < LiquidityLevelCount / 2)
   {
      CompactLiquidityArray();
   }
}

//+------------------------------------------------------------------+
//| Compact FVG Array                                               |
//+------------------------------------------------------------------+
void CompactFVGArray()
{
   int writeIndex = 0;
   
   for(int readIndex = 0; readIndex < FVGCount; readIndex++)
   {
      if(FairValueGaps[readIndex].isActive)
      {
         if(writeIndex != readIndex)
         {
            FairValueGaps[writeIndex] = FairValueGaps[readIndex];
         }
         writeIndex++;
      }
   }
   
   // Clear remaining elements
   for(int i = writeIndex; i < FVGCount; i++)
   {
      FairValueGaps[i] = SFairValueGap();
   }
   
   FVGCount = writeIndex;
   Print("FVG Array Compacted: ", FVGCount, " active elements");
}

//+------------------------------------------------------------------+
//| Compact Order Block Array                                       |
//+------------------------------------------------------------------+
void CompactOrderBlockArray()
{
   int writeIndex = 0;
   
   for(int readIndex = 0; readIndex < OrderBlockCount; readIndex++)
   {
      if(OrderBlocks[readIndex].isActive)
      {
         if(writeIndex != readIndex)
         {
            OrderBlocks[writeIndex] = OrderBlocks[readIndex];
         }
         writeIndex++;
      }
   }
   
   // Clear remaining elements
   for(int i = writeIndex; i < OrderBlockCount; i++)
   {
      OrderBlocks[i] = SOrderBlock();
   }
   
   OrderBlockCount = writeIndex;
   Print("Order Block Array Compacted: ", OrderBlockCount, " active elements");
}

//+------------------------------------------------------------------+
//| Compact Liquidity Array                                         |
//+------------------------------------------------------------------+
void CompactLiquidityArray()
{
   int writeIndex = 0;
   
   for(int readIndex = 0; readIndex < LiquidityLevelCount; readIndex++)
   {
      if(LiquidityLevels[readIndex].isActive)
      {
         if(writeIndex != readIndex)
         {
            LiquidityLevels[writeIndex] = LiquidityLevels[readIndex];
         }
         writeIndex++;
      }
   }
   
   // Clear remaining elements
   for(int i = writeIndex; i < LiquidityLevelCount; i++)
   {
      LiquidityLevels[i] = SLiquidityLevel();
   }
   
   LiquidityLevelCount = writeIndex;
   Print("Liquidity Array Compacted: ", LiquidityLevelCount, " active elements");
}

//+------------------------------------------------------------------+
//| Cleanup Old Patterns                                            |
//+------------------------------------------------------------------+
void CleanupOldPatterns()
{
   CleanupOldFVGs();
   CleanupOldOrderBlocks();
   CleanupOldLiquidityLevels();
}

//+------------------------------------------------------------------+
//| Attempt Error Recovery                                          |
//+------------------------------------------------------------------+
void AttemptErrorRecovery()
{
   Print("Attempting Error Recovery...");
   
   // Check if errors are old
   if(TimeCurrent() - LastErrorTime > 1800)
   {
      ErrorCount = 0;
      LastError = 0;
      Print("Error counters reset - old errors");
      return;
   }
   
   // Refresh market data
   if(!UpdateMarketData())
   {
      Print("Market data refresh failed during recovery");
   }
   
   // Recreate indicator handles if needed
   if(HandleATR == INVALID_HANDLE)
   {
      HandleATR = iATR(_Symbol, PERIOD_CURRENT, 14);
      Print("ATR handle recreated during recovery");
   }
   
   // Clear caches
   PerformanceCache.atrCacheTime = 0;
   PerformanceCache.volatilityCacheTime = 0;
   PerformanceCache.correlationCacheTime = 0;
   PerformanceCache.structureCacheValid = false;
   
   // Reduce error count
   ErrorCount = (int)(ErrorCount * 0.7);
   
   Print("Error Recovery Completed - Error Count: ", ErrorCount);
}

#endif // AIME_MEMORY_MANAGER_MQH

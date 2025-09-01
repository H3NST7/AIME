//+------------------------------------------------------------------+
//|                                      AIME_TradingLogic.mqh       |
//|                     Main Trading Logic Coordination              |
//+------------------------------------------------------------------+
#ifndef AIME_TRADING_LOGIC_MQH
#define AIME_TRADING_LOGIC_MQH

//+------------------------------------------------------------------+
//| Execute ICT Trading Logic                                       |
//+------------------------------------------------------------------+
void ExecuteICTTradingLogic()
{
   // Master trading coordinator - executes strategies based on priority
   if(!TradingAllowed || ActivePositions >= MaxPositions) return;
   
   double confluence = MarketStructure.structureStrength;
   
   // Tier 1 Strategies (Highest Priority - Confluence > 85%)
   if(confluence >= 8.5)
   {
      if(UseUnicornModel && ExecuteUnicornModelStrategy()) return;
      if(Use2022Mentorship && Execute2022MentorshipStrategy()) return;
      if(UseSilverBullet && ExecuteSilverBulletStrategy()) return;
   }
   
   // Tier 2 Strategies (High Priority - Confluence > 70%)
   else if(confluence >= 7.0)
   {
      if(UseDragonflyEntry && ExecuteDragonflyStrategy()) return;
      if(ExecutePowerOf3Strategy()) return;
      if(ExecuteEnhancedFVGStrategy()) return;
   }
   
   // Tier 3 Strategies (Standard Priority - Confluence > 50%)
   else if(confluence >= 5.0)
   {
      if(ExecuteOrderBlockStrategy()) return;
      if(ExecuteLiquidityRaidStrategy()) return;
      if(UseMarketMakerModels && ExecuteMarketMakerStrategy()) return;
      if(ExecutePremiumDiscountStrategy()) return;
   }
}

//+------------------------------------------------------------------+
//| Execute Power of 3 Strategy                                     |
//+------------------------------------------------------------------+
bool ExecutePowerOf3Strategy()
{
   // Power of 3: Phase-based trading
   if(!PowerOfThreeAnalysis.isOptimalPhase) return false;
   if(PowerOfThreeAnalysis.phaseStrength < 6.0) return false;
   
   switch(PowerOfThreeAnalysis.currentPhase)
   {
      case MANIPULATION_AM:
      case MANIPULATION_PM:
         return ExecuteManipulationPhaseStrategy();
         
      case DISTRIBUTION_AM:
      case DISTRIBUTION_PM:
         return ExecuteDistributionPhaseStrategy();
         
      default:
         return false; // Only trade manipulation and distribution phases
   }
}

//+------------------------------------------------------------------+
//| Execute Manipulation Phase Strategy                             |
//+------------------------------------------------------------------+
bool ExecuteManipulationPhaseStrategy()
{
   // Trade the manipulation phase - look for liquidity grabs + reversal
   if(!PowerOfThreeAnalysis.hasLiquidityGrab) return false;
   
   double currentPrice = Rates[RatesTotal-1].close;
   double liquidityLevel = PowerOfThreeAnalysis.liquidityGrabLevel;
   double atr = GetCachedATR();
   
   // Determine manipulation direction
   bool manipulationBullish = (currentPrice > liquidityLevel);
   
   // Look for reversal patterns after liquidity grab
   for(int i = 0; i < FVGCount; i++)
   {
      if(!FairValueGaps[i].isActive) continue;
      
      // FVG should be opposite to manipulation direction
      bool fvgOpposite = (manipulationBullish && FairValueGaps[i].direction == FAIR_VALUE_GAP_BEARISH) ||
                         (!manipulationBullish && FairValueGaps[i].direction == FAIR_VALUE_GAP_BULLISH);
      
      if(fvgOpposite && 
         MathAbs(FairValueGaps[i].midPrice - currentPrice) <= atr * 1.0 &&
         FairValueGaps[i].strength >= 5.0)
      {
         return ExecutePowerOf3Trade(!manipulationBullish, i, liquidityLevel);
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Execute Distribution Phase Strategy                             |
//+------------------------------------------------------------------+
bool ExecuteDistributionPhaseStrategy()
{
   // Trade distribution phase - follow the displacement direction
   if(!PowerOfThreeAnalysis.distributionStarted) return false;
   
   double currentPrice = Rates[RatesTotal-1].close;
   double distributionTarget = PowerOfThreeAnalysis.distributionTarget;
   
   // Determine distribution direction
   bool distributionBullish = (distributionTarget > PowerOfThreeAnalysis.manipulationLevel);
   
   // Only trade if we haven't reached 80% of target
   if(PowerOfThreeAnalysis.phaseProgress >= 80.0) return false;
   
   // Look for continuation patterns
   for(int i = 0; i < FVGCount; i++)
   {
      if(!FairValueGaps[i].isActive) continue;
      
      // FVG should align with distribution direction
      bool fvgAligned = (distributionBullish && FairValueGaps[i].direction == FAIR_VALUE_GAP_BULLISH) ||
                        (!distributionBullish && FairValueGaps[i].direction == FAIR_VALUE_GAP_BEARISH);
      
      if(fvgAligned && FairValueGaps[i].strength >= 5.0 &&
         MathAbs(FairValueGaps[i].midPrice - currentPrice) <= GetCachedATR() * 1.0)
      {
         return ExecutePowerOf3Trade(distributionBullish, i, distributionTarget);
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Execute Power of 3 Trade                                        |
//+------------------------------------------------------------------+
bool ExecutePowerOf3Trade(bool isBullish, int fvgIndex, double referenceLevel)
{
   double atr = GetCachedATR();
   
   // Entry at FVG level
   double entryPrice = isBullish ? FairValueGaps[fvgIndex].bottomPrice : FairValueGaps[fvgIndex].topPrice;
   
   // Stop loss based on phase
   double stopLoss;
   if(PowerOfThreeAnalysis.currentPhase == MANIPULATION_AM || PowerOfThreeAnalysis.currentPhase == MANIPULATION_PM)
   {
      // Manipulation phase - SL beyond manipulation level
      stopLoss = isBullish ? referenceLevel - (atr * 0.8) : referenceLevel + (atr * 0.8);
   }
   else
   {
      // Distribution phase - tighter SL
      stopLoss = isBullish ? entryPrice - (atr * 1.0) : entryPrice + (atr * 1.0);
   }
   
   // Take profit toward phase target
   double takeProfit;
   if(PowerOfThreeAnalysis.distributionTarget != 0)
   {
      // Target the distribution level
      takeProfit = referenceLevel;
   }
   else
   {
      takeProfit = isBullish ? entryPrice + (atr * 3.0) : entryPrice - (atr * 3.0);
   }
   
   double lotSize = CalculateOptimalPositionSize(entryPrice, stopLoss, 1.1);
   
   bool success = ExecuteICTTrade(isBullish ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,
                                  lotSize, entryPrice, stopLoss, takeProfit,
                                  "Power of 3 - " + EnumToString(PowerOfThreeAnalysis.currentPhase));
   
   if(success)
   {
      Print("Power of 3 Trade: ", EnumToString(PowerOfThreeAnalysis.currentPhase), 
            " | ", (isBullish ? "BUY" : "SELL"), " at ", entryPrice);
   }
   
   return success;
}

//+------------------------------------------------------------------+
//| Execute Enhanced FVG Strategy                                   |
//+------------------------------------------------------------------+
bool ExecuteEnhancedFVGStrategy()
{
   // Enhanced FVG strategy with multi-factor confluence
   double currentPrice = Rates[RatesTotal-1].close;
   double atr = GetCachedATR();
   
   for(int i = 0; i < FVGCount; i++)
   {
      if(!FairValueGaps[i].isActive) continue;
      if(FairValueGaps[i].strength < 6.0) continue;
      
      // Check proximity to current price
      if(MathAbs(FairValueGaps[i].midPrice - currentPrice) > atr * 1.5) continue;
      
      // Validate structure alignment
      if(!ValidateStructureAlignment(FairValueGaps[i].direction)) continue;
      
      // Check Premium/Discount alignment
      if(!IsPremiumDiscountAligned(FairValueGaps[i].direction, FairValueGaps[i].midPrice)) continue;
      
      // Calculate FVG confluence
      double confluence = CalculateFVGConfluence(i);
      
      if(confluence >= 0.70)
      {
         bool isBullish = (FairValueGaps[i].direction == FAIR_VALUE_GAP_BULLISH);
         return ExecuteEnhancedFVGTrade(i, isBullish, confluence);
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Execute Enhanced FVG Trade                                      |
//+------------------------------------------------------------------+
bool ExecuteEnhancedFVGTrade(int fvgIndex, bool isBullish, double confluence)
{
   double atr = GetCachedATR();
   
   // Entry at FVG boundary
   double entryPrice = isBullish ? FairValueGaps[fvgIndex].bottomPrice : FairValueGaps[fvgIndex].topPrice;
   
   // Stop loss beyond FVG invalidation
   double stopLoss = isBullish ?
                     FairValueGaps[fvgIndex].bottomPrice - (atr * 0.3) :
                     FairValueGaps[fvgIndex].topPrice + (atr * 0.3);
   
   // Take profit based on confluence and FVG strength
   double tpMultiplier = 1.5 + (confluence * 2.5); // 1.5-4.0 ATR
   double takeProfit = isBullish ?
                       entryPrice + (atr * tpMultiplier) :
                       entryPrice - (atr * tpMultiplier);
   
   // Position sizing with confluence adjustment
   double lotSize = CalculateOptimalPositionSize(entryPrice, stopLoss, confluence * 1.2);
   
   bool success = ExecuteICTTrade(isBullish ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,
                                  lotSize, entryPrice, stopLoss, takeProfit,
                                  "Enhanced FVG - Str: " + DoubleToString(FairValueGaps[fvgIndex].strength, 1));
   
   if(success)
   {
      Print("Enhanced FVG Trade: ", (isBullish ? "BUY" : "SELL"), 
            " | Strength: ", FairValueGaps[fvgIndex].strength, 
            " | Confluence: ", confluence);
   }
   
   return success;
}

//+------------------------------------------------------------------+
//| Execute Order Block Strategy                                    |
//+------------------------------------------------------------------+
bool ExecuteOrderBlockStrategy()
{
   // Standard Order Block strategy with structure alignment
   double currentPrice = Rates[RatesTotal-1].close;
   double atr = GetCachedATR();
   
   for(int i = 0; i < OrderBlockCount; i++)
   {
      if(!OrderBlocks[i].isActive) continue;
      if(OrderBlocks[i].strength < 5.0) continue;
      
      // Check if price is approaching the order block
      double distanceToOB = MathAbs(OrderBlocks[i].price - currentPrice);
      if(distanceToOB > atr * 2.0) continue;
      
      // Validate structure alignment
      ENUM_ICT_PATTERN obPattern = OrderBlocks[i].isBullish ? ORDER_BLOCK_BULLISH : ORDER_BLOCK_BEARISH;
      if(!ValidateStructureAlignment(obPattern)) continue;
      
      // Check if we're in a favorable Premium/Discount zone
      if(!IsPremiumDiscountAligned(obPattern, OrderBlocks[i].price)) continue;
      
      return ExecuteOrderBlockTrade(i, OrderBlocks[i].isBullish);
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Execute Order Block Trade                                       |
//+------------------------------------------------------------------+
bool ExecuteOrderBlockTrade(int obIndex, bool isBullish)
{
   double atr = GetCachedATR();
   
   // Entry at order block price
   double entryPrice = OrderBlocks[obIndex].price;
   
   // Stop loss beyond order block boundary
   double stopLoss = isBullish ?
                     OrderBlocks[obIndex].low - (atr * 0.4) :
                     OrderBlocks[obIndex].high + (atr * 0.4);
   
   // Take profit based on order block strength
   double tpMultiplier = 1.5 + (OrderBlocks[obIndex].strength / 10.0 * 2.0); // 1.5-3.5 ATR
   double takeProfit = isBullish ?
                       entryPrice + (atr * tpMultiplier) :
                       entryPrice - (atr * tpMultiplier);
   
   // Position sizing based on order block quality
   double sizeMultiplier = 0.8 + (OrderBlocks[obIndex].strength / 10.0 * 0.4); // 0.8-1.2x
   double lotSize = CalculateOptimalPositionSize(entryPrice, stopLoss, sizeMultiplier);
   
   bool success = ExecuteICTTrade(isBullish ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,
                                  lotSize, entryPrice, stopLoss, takeProfit,
                                  "Order Block - Str: " + DoubleToString(OrderBlocks[obIndex].strength, 1));
   
   if(success)
   {
      Print("Order Block Trade: ", (isBullish ? "BUY" : "SELL"), 
            " | Strength: ", OrderBlocks[obIndex].strength, " | Entry: ", entryPrice);
   }
   
   return success;
}

//+------------------------------------------------------------------+
//| Execute Liquidity Raid Strategy                                 |
//+------------------------------------------------------------------+
bool ExecuteLiquidityRaidStrategy()
{
   // Trade post-liquidity raid displacement
   double atr = GetCachedATR();
   double currentPrice = Rates[RatesTotal-1].close;
   
   for(int i = 0; i < LiquidityLevelCount; i++)
   {
      if(!LiquidityLevels[i].isRaided) continue;
      
      // Must be recent raid (within 5 minutes)
      if(TimeCurrent() - LiquidityLevels[i].raidTime > 300) continue;
      
      // Must have strong displacement after raid
      if(LiquidityLevels[i].displacementAfterRaid < atr * 1.8) continue;
      
      // Determine trade direction (opposite to raid)
      bool isBullish = (currentPrice > LiquidityLevels[i].price);
      
      // Look for entry pattern in displacement direction
      if(FindLiquidityRaidEntry(isBullish, LiquidityLevels[i].price))
      {
         return ExecuteLiquidityRaidTrade(isBullish, i);
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Find Liquidity Raid Entry                                       |
//+------------------------------------------------------------------+
bool FindLiquidityRaidEntry(bool isBullish, double liquidityLevel)
{
   double currentPrice = Rates[RatesTotal-1].close;
   double atr = GetCachedATR();
   
   // Look for FVG or Order Block in displacement direction
   for(int i = 0; i < FVGCount; i++)
   {
      if(!FairValueGaps[i].isActive) continue;
      
      bool fvgAligned = (isBullish && FairValueGaps[i].direction == FAIR_VALUE_GAP_BULLISH) ||
                        (!isBullish && FairValueGaps[i].direction == FAIR_VALUE_GAP_BEARISH);
      
      if(fvgAligned && 
         MathAbs(FairValueGaps[i].midPrice - currentPrice) <= atr * 1.2 &&
         FairValueGaps[i].strength >= 4.0)
      {
         return true;
      }
   }
   
   for(int i = 0; i < OrderBlockCount; i++)
   {
      if(!OrderBlocks[i].isActive) continue;
      
      bool obAligned = (isBullish && OrderBlocks[i].isBullish) ||
                       (!isBullish && !OrderBlocks[i].isBullish);
      
      if(obAligned &&
         MathAbs(OrderBlocks[i].price - currentPrice) <= atr * 1.2 &&
         OrderBlocks[i].strength >= 4.0)
      {
         return true;
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Execute Liquidity Raid Trade                                    |
//+------------------------------------------------------------------+
bool ExecuteLiquidityRaidTrade(bool isBullish, int liquidityIndex)
{
   double atr = GetCachedATR();
   double currentPrice = Rates[RatesTotal-1].close;
   double liquidityLevel = LiquidityLevels[liquidityIndex].price;
   
   // Entry near current price
   double entryPrice = currentPrice;
   
   // Stop loss beyond liquidity level
   double stopLoss = isBullish ?
                     liquidityLevel - (atr * 0.6) :
                     liquidityLevel + (atr * 0.6);
   
   // Take profit based on displacement strength
   double displacement = LiquidityLevels[liquidityIndex].displacementAfterRaid;
   double tpMultiplier = MathMin(4.0, displacement * 0.8); // Max 4 ATR
   double takeProfit = isBullish ?
                       entryPrice + (atr * tpMultiplier) :
                       entryPrice - (atr * tpMultiplier);
   
   // Position sizing based on displacement strength
   double sizeMultiplier = 0.9 + (displacement / (atr * 5.0) * 0.4); // 0.9-1.3x
   sizeMultiplier = MathMin(1.3, sizeMultiplier);
   double lotSize = CalculateOptimalPositionSize(entryPrice, stopLoss, sizeMultiplier);
   
   bool success = ExecuteICTTrade(isBullish ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,
                                  lotSize, entryPrice, stopLoss, takeProfit,
                                  "Liquidity Raid - Disp: " + DoubleToString(displacement, 1));
   
   if(success)
   {
      Print("Liquidity Raid Trade: ", (isBullish ? "BUY" : "SELL"), 
            " | Displacement: ", displacement, " ATR | Entry: ", entryPrice);
   }
   
   return success;
}

//+------------------------------------------------------------------+
//| Execute Market Maker Strategy                                   |
//+------------------------------------------------------------------+
bool ExecuteMarketMakerStrategy()
{
   // Market Maker Model trading
   if(!UseMarketMakerModels) return false;
   
   // Analyze current market maker model
   ENUM_MARKET_MAKER_MODEL currentModel = AnalyzeCurrentMarketMakerModel();
   
   switch(currentModel)
   {
      case EXPANSION_BULLISH:
      case EXPANSION_BEARISH:
         return ExecuteExpansionModelTrade(currentModel);
         
      case RETRACEMENT_BULLISH:
      case RETRACEMENT_BEARISH:
         return ExecuteRetracementModelTrade(currentModel);
         
      case CONTINUATION_BULLISH:
      case CONTINUATION_BEARISH:
         return ExecuteContinuationModelTrade(currentModel);
         
      default:
         return false; // Don't trade consolidation or reversal models
   }
}

//+------------------------------------------------------------------+
//| Analyze Current Market Maker Model                              |
//+------------------------------------------------------------------+
ENUM_MARKET_MAKER_MODEL AnalyzeCurrentMarketMakerModel()
{
   double atr = GetCachedATR();
   
   // Calculate recent range and movement
   double recentRange = CalculateRecentRange(20);
   double recentMovement = CalculateRecentDisplacement(10);
   
   // Consolidation Model
   if(recentRange < ConsolidationThreshold * atr)
   {
      return CONSOLIDATION;
   }
   
   // Expansion Models
   if(recentMovement > ExpansionThreshold * atr)
   {
      bool bullishExpansion = (Rates[RatesTotal-1].close > Rates[RatesTotal-10].close);
      return bullishExpansion ? EXPANSION_BULLISH : EXPANSION_BEARISH;
   }
   
   // Retracement Models
   double fibonacci50 = CalculateFibonacciRetracement(50);
   if(fibonacci50 > 0 && MathAbs(Rates[RatesTotal-1].close - fibonacci50) <= atr * 0.5)
   {
      bool bullishRetracement = (MarketStructure.currentStructure == BULLISH_BOS);
      return bullishRetracement ? RETRACEMENT_BULLISH : RETRACEMENT_BEARISH;
   }
   
   // Continuation Models
   if(MarketStructure.hasBreakOfStructure)
   {
      bool bullishContinuation = (MarketStructure.currentStructure == BULLISH_BOS);
      return bullishContinuation ? CONTINUATION_BULLISH : CONTINUATION_BEARISH;
   }
   
   return CONSOLIDATION; // Default
}

//+------------------------------------------------------------------+
//| Execute Expansion Model Trade                                   |
//+------------------------------------------------------------------+
bool ExecuteExpansionModelTrade(ENUM_MARKET_MAKER_MODEL model)
{
   bool isBullish = (model == EXPANSION_BULLISH);
   double atr = GetCachedATR();
   double currentPrice = Rates[RatesTotal-1].close;
   
   // Look for pullback entry in expansion direction
   double entryPrice = currentPrice;
   
   // Tight stop loss for expansion model
   double stopLoss = isBullish ?
                     currentPrice - (atr * 1.0) :
                     currentPrice + (atr * 1.0);
   
   // Extended take profit for expansion
   double takeProfit = isBullish ?
                       currentPrice + (atr * 4.0) :
                       currentPrice - (atr * 4.0);
   
   double lotSize = CalculateOptimalPositionSize(entryPrice, stopLoss, 1.1);
   
   bool success = ExecuteICTTrade(isBullish ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,
                                  lotSize, entryPrice, stopLoss, takeProfit,
                                  "MM Expansion - " + (isBullish ? "Bull" : "Bear"));
   
   if(success)
   {
      Print("Market Maker Expansion Trade: ", (isBullish ? "BUY" : "SELL"), " at ", entryPrice);
   }
   
   return success;
}

//+------------------------------------------------------------------+
//| Execute Retracement Model Trade                                 |
//+------------------------------------------------------------------+
bool ExecuteRetracementModelTrade(ENUM_MARKET_MAKER_MODEL model)
{
   bool isBullish = (model == RETRACEMENT_BULLISH);
   double atr = GetCachedATR();
   
   // Entry at fibonacci retracement level
   double entryPrice = CalculateFibonacciRetracement(618); // 61.8% retracement
   if(entryPrice == 0) return false;
   
   // Stop loss beyond retracement zone
   double stopLoss = isBullish ?
                     CalculateFibonacciRetracement(786) - (atr * 0.3) : // 78.6% level
                     CalculateFibonacciRetracement(786) + (atr * 0.3);
   
   // Take profit at trend continuation
   double takeProfit = isBullish ?
                       entryPrice + (atr * 3.0) :
                       entryPrice - (atr * 3.0);
   
   double lotSize = CalculateOptimalPositionSize(entryPrice, stopLoss, 1.0);
   
   bool success = ExecuteICTTrade(isBullish ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,
                                  lotSize, entryPrice, stopLoss, takeProfit,
                                  "MM Retracement - " + (isBullish ? "Bull" : "Bear"));
   
   if(success)
   {
      Print("Market Maker Retracement Trade: ", (isBullish ? "BUY" : "SELL"), " at ", entryPrice);
   }
   
   return success;
}

//+------------------------------------------------------------------+
//| Execute Continuation Model Trade                                |
//+------------------------------------------------------------------+
bool ExecuteContinuationModelTrade(ENUM_MARKET_MAKER_MODEL model)
{
   bool isBullish = (model == CONTINUATION_BULLISH);
   double atr = GetCachedATR();
   double currentPrice = Rates[RatesTotal-1].close;
   
   // Entry on structure break continuation
   double entryPrice = currentPrice;
   
   // Stop loss at structure level
   double stopLoss = isBullish ?
                     MarketStructure.bosLevel - (atr * 0.5) :
                     MarketStructure.bosLevel + (atr * 0.5);
   
   // Take profit based on structure target
   double takeProfit = isBullish ?
                       entryPrice + (atr * 3.5) :
                       entryPrice - (atr * 3.5);
   
   double lotSize = CalculateOptimalPositionSize(entryPrice, stopLoss, 1.0);
   
   bool success = ExecuteICTTrade(isBullish ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,
                                  lotSize, entryPrice, stopLoss, takeProfit,
                                  "MM Continuation - " + (isBullish ? "Bull" : "Bear"));
   
   if(success)
   {
      Print("Market Maker Continuation Trade: ", (isBullish ? "BUY" : "SELL"), " at ", entryPrice);
   }
   
   return success;
}

//+------------------------------------------------------------------+
//| Execute Premium Discount Strategy                               |
//+------------------------------------------------------------------+
bool ExecutePremiumDiscountStrategy()
{
   // Premium/Discount zone trading with structure
   if(IsInEquilibrium) return false; // Don't trade in equilibrium
   
   double currentPrice = Rates[RatesTotal-1].close;
   double atr = GetCachedATR();
   
   // Premium zone - look for sells
   if(IsInPremium && (MarketStructure.currentStructure == BEARISH_BOS || 
                      MarketStructure.currentStructure == BEARISH_CHoCH))
   {
      return ExecutePremiumTrade(false);
   }
   
   // Discount zone - look for buys
   if(IsInDiscount && (MarketStructure.currentStructure == BULLISH_BOS || 
                       MarketStructure.currentStructure == BULLISH_CHoCH))
   {
      return ExecuteDiscountTrade(true);
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Execute Premium Trade                                           |
//+------------------------------------------------------------------+
bool ExecutePremiumTrade(bool isBullish)
{
   double atr = GetCachedATR();
   double currentPrice = Rates[RatesTotal-1].close;
   
   // Entry in premium zone
   double entryPrice = currentPrice;
   
   // Stop loss above premium zone
   double stopLoss = RangeHigh + (atr * 0.5);
   
   // Take profit toward equilibrium and discount
   double takeProfit = RangeLow + ((RangeHigh - RangeLow) * DiscountThreshold);
   
   double lotSize = CalculateOptimalPositionSize(entryPrice, stopLoss, 0.9);
   
   bool success = ExecuteICTTrade(ORDER_TYPE_SELL,
                                  lotSize, entryPrice, stopLoss, takeProfit,
                                  "Premium Zone Sell");
   
   if(success)
   {
      Print("Premium Zone Trade: SELL at ", entryPrice, " | PD: ", CurrentPremiumDiscount);
   }
   
   return success;
}

//+------------------------------------------------------------------+
//| Execute Discount Trade                                          |
//+------------------------------------------------------------------+
bool ExecuteDiscountTrade(bool isBullish)
{
   double atr = GetCachedATR();
   double currentPrice = Rates[RatesTotal-1].close;
   
   // Entry in discount zone
   double entryPrice = currentPrice;
   
   // Stop loss below discount zone
   double stopLoss = RangeLow - (atr * 0.5);
   
   // Take profit toward equilibrium and premium
   double takeProfit = RangeLow + ((RangeHigh - RangeLow) * PremiumThreshold);
   
   double lotSize = CalculateOptimalPositionSize(entryPrice, stopLoss, 0.9);
   
   bool success = ExecuteICTTrade(ORDER_TYPE_BUY,
                                  lotSize, entryPrice, stopLoss, takeProfit,
                                  "Discount Zone Buy");
   
   if(success)
   {
      Print("Discount Zone Trade: BUY at ", entryPrice, " | PD: ", CurrentPremiumDiscount);
   }
   
   return success;
}

#endif // AIME_TRADING_LOGIC_MQH

//+------------------------------------------------------------------+
//|                                      AIME_LiquidityLevels.mqh    |
//|                    Complete Liquidity Level Analysis             |
//+------------------------------------------------------------------+
#ifndef AIME_LIQUIDITY_LEVELS_MQH
#define AIME_LIQUIDITY_LEVELS_MQH

//+------------------------------------------------------------------+
//| Detect And Analyze Liquidity Levels                             |
//+------------------------------------------------------------------+
void DetectAndAnalyzeLiquidityLevels()
{
   if(RatesTotal < 50) return;
   
   double atr = GetCachedATR();
   if(atr <= 0) return;
   
   // Clean up old liquidity levels
   CleanupOldLiquidityLevels();
   
   // Detect various types of liquidity
   DetectEqualLevels(atr);
   DetectRelativeEqualLevels(atr);
   DetectSwingLiquidity(atr);
   DetectTerminalLiquidity(atr);
   DetectInstitutionalReferenceLevels(atr);
   
   // Update existing liquidity levels
   UpdateExistingLiquidityLevels();
   
   // Check for liquidity raids
   CheckForLiquidityRaids(atr);
}

//+------------------------------------------------------------------+
//| Detect Equal Levels (Equal Highs/Lows)                          |
//+------------------------------------------------------------------+
void DetectEqualLevels(double atr)
{
   int lookback = LiquidityAnalysisPeriod;
   if(lookback > RatesTotal) lookback = RatesTotal;
   
   // Detect equal highs
   for(int i = 5; i < lookback - 5; i++)
   {
      double currentHigh = Rates[i].high;
      double currentLow = Rates[i].low;
      
      // Look for equal highs
      for(int j = i + 5; j < lookback; j++)
      {
         if(MathAbs(Rates[j].high - currentHigh) <= EqualLevelTolerance * SymbolInfoDouble(_Symbol, SYMBOL_POINT))
         {
            if(ValidateLiquidityLevel(currentHigh, EQUAL_HIGHS, atr))
            {
               CreateNewLiquidityLevel(currentHigh, Rates[i].time, EQUAL_HIGHS, atr);
               break; // Only create one level per detection
            }
         }
      }
      
      // Look for equal lows
      for(int j = i + 5; j < lookback; j++)
      {
         if(MathAbs(Rates[j].low - currentLow) <= EqualLevelTolerance * SymbolInfoDouble(_Symbol, SYMBOL_POINT))
         {
            if(ValidateLiquidityLevel(currentLow, EQUAL_LOWS, atr))
            {
               CreateNewLiquidityLevel(currentLow, Rates[i].time, EQUAL_LOWS, atr);
               break;
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Relative Equal Levels                                    |
//+------------------------------------------------------------------+
void DetectRelativeEqualLevels(double atr)
{
   double tolerance = RelativeEqualTolerance * atr;
   int lookback = LiquidityAnalysisPeriod;
   if(lookback > RatesTotal) lookback = RatesTotal;
   
   for(int i = 10; i < lookback - 10; i++)
   {
      double currentHigh = Rates[i].high;
      double currentLow = Rates[i].low;
      
      // Relative equal highs (not exactly equal but within ATR tolerance)
      for(int j = i + 10; j < lookback; j++)
      {
         double difference = MathAbs(Rates[j].high - currentHigh);
         if(difference > EqualLevelTolerance * SymbolInfoDouble(_Symbol, SYMBOL_POINT) && 
            difference <= tolerance)
         {
            if(ValidateLiquidityLevel(currentHigh, RELATIVE_EQUAL_HIGHS, atr))
            {
               CreateNewLiquidityLevel(currentHigh, Rates[i].time, RELATIVE_EQUAL_HIGHS, atr);
               break;
            }
         }
      }
      
      // Relative equal lows
      for(int j = i + 10; j < lookback; j++)
      {
         double difference = MathAbs(Rates[j].low - currentLow);
         if(difference > EqualLevelTolerance * SymbolInfoDouble(_Symbol, SYMBOL_POINT) && 
            difference <= tolerance)
         {
            if(ValidateLiquidityLevel(currentLow, RELATIVE_EQUAL_LOWS, atr))
            {
               CreateNewLiquidityLevel(currentLow, Rates[i].time, RELATIVE_EQUAL_LOWS, atr);
               break;
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Swing Liquidity                                          |
//+------------------------------------------------------------------+
void DetectSwingLiquidity(double atr)
{
   int swingLookback = 20;
   
   for(int i = swingLookback; i < RatesTotal - swingLookback; i++)
   {
      bool isSwingHigh = true;
      bool isSwingLow = true;
      double currentHigh = Rates[i].high;
      double currentLow = Rates[i].low;
      
      // Check for swing high
      for(int j = i - swingLookback; j <= i + swingLookback; j++)
      {
         if(j != i && Rates[j].high >= currentHigh)
         {
            isSwingHigh = false;
            break;
         }
      }
      
      if(isSwingHigh && ValidateLiquidityLevel(currentHigh, SWING_HIGH, atr))
      {
         CreateNewLiquidityLevel(currentHigh, Rates[i].time, SWING_HIGH, atr);
      }
      
      // Check for swing low
      for(int j = i - swingLookback; j <= i + swingLookback; j++)
      {
         if(j != i && Rates[j].low <= currentLow)
         {
            isSwingLow = false;
            break;
         }
      }
      
      if(isSwingLow && ValidateLiquidityLevel(currentLow, SWING_LOW, atr))
      {
         CreateNewLiquidityLevel(currentLow, Rates[i].time, SWING_LOW, atr);
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Terminal Liquidity (Daily, Weekly, Monthly)              |
//+------------------------------------------------------------------+
void DetectTerminalLiquidity(double atr)
{
   // Daily levels
   MqlRates dailyRates[];
   int dailyCount = CopyRates(_Symbol, PERIOD_D1, 0, 30, dailyRates);
   
   if(dailyCount > 10)
   {
      for(int i = 1; i < dailyCount - 1; i++)
      {
         // Daily highs
         if(ValidateLiquidityLevel(dailyRates[i].high, DAILY_HIGH, atr))
         {
            CreateNewLiquidityLevel(dailyRates[i].high, dailyRates[i].time, DAILY_HIGH, atr);
         }
         
         // Daily lows
         if(ValidateLiquidityLevel(dailyRates[i].low, DAILY_LOW, atr))
         {
            CreateNewLiquidityLevel(dailyRates[i].low, dailyRates[i].time, DAILY_LOW, atr);
         }
      }
   }
   
   // Weekly levels
   MqlRates weeklyRates[];
   int weeklyCount = CopyRates(_Symbol, PERIOD_W1, 0, 12, weeklyRates);
   
   if(weeklyCount > 4)
   {
      for(int i = 1; i < weeklyCount - 1; i++)
      {
         // Weekly highs
         if(ValidateLiquidityLevel(weeklyRates[i].high, WEEKLY_HIGH, atr))
         {
            CreateNewLiquidityLevel(weeklyRates[i].high, weeklyRates[i].time, WEEKLY_HIGH, atr);
         }
         
         // Weekly lows
         if(ValidateLiquidityLevel(weeklyRates[i].low, WEEKLY_LOW, atr))
         {
            CreateNewLiquidityLevel(weeklyRates[i].low, weeklyRates[i].time, WEEKLY_LOW, atr);
         }
      }
   }
   
   // Monthly levels
   MqlRates monthlyRates[];
   int monthlyCount = CopyRates(_Symbol, PERIOD_MN1, 0, 6, monthlyRates);
   
   if(monthlyCount > 2)
   {
      for(int i = 1; i < monthlyCount - 1; i++)
      {
         // Monthly highs
         if(ValidateLiquidityLevel(monthlyRates[i].high, MONTHLY_HIGH, atr))
         {
            CreateNewLiquidityLevel(monthlyRates[i].high, monthlyRates[i].time, MONTHLY_HIGH, atr);
         }
         
         // Monthly lows
         if(ValidateLiquidityLevel(monthlyRates[i].low, MONTHLY_LOW, atr))
         {
            CreateNewLiquidityLevel(monthlyRates[i].low, monthlyRates[i].time, MONTHLY_LOW, atr);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Institutional Reference Levels                           |
//+------------------------------------------------------------------+
void DetectInstitutionalReferenceLevels(double atr)
{
   double currentPrice = Rates[RatesTotal-1].close;
   
   // Psychological levels for XAUUSD
   double levels[] = {50.0, 100.0, 500.0, 1000.0};
   
   for(int i = 0; i < ArraySize(levels); i++)
   {
      double levelSize = levels[i];
      double nearestLevel = MathRound(currentPrice / levelSize) * levelSize;
      
      // Check levels above and below current price
      for(int j = -2; j <= 2; j++)
      {
         double testLevel = nearestLevel + (j * levelSize);
         
         // Only consider levels within reasonable distance
         if(MathAbs(testLevel - currentPrice) <= atr * 10 &&
            ValidateLiquidityLevel(testLevel, INSTITUTIONAL_REFERENCE, atr))
         {
            CreateNewLiquidityLevel(testLevel, TimeCurrent(), INSTITUTIONAL_REFERENCE, atr);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Validate Liquidity Level                                        |
//+------------------------------------------------------------------+
bool ValidateLiquidityLevel(double price, ENUM_LIQUIDITY_TYPE type, double atr)
{
   // Check for duplicates
   for(int i = 0; i < LiquidityLevelCount; i++)
   {
      if(LiquidityLevels[i].isActive && 
         MathAbs(LiquidityLevels[i].price - price) <= atr * 0.3)
      {
         return false; // Level already exists
      }
   }
   
   // Check minimum distance from current price
   double currentPrice = Rates[RatesTotal-1].close;
   double distance = MathAbs(price - currentPrice);
   
   // Too close to current price
   if(distance < atr * 0.5) return false;
   
   // Too far from current price
   if(distance > atr * 20) return false;
   
   // Validate significance
   return ValidateLiquiditySignificance(price, type, atr);
}

//+------------------------------------------------------------------+
//| Validate Liquidity Significance                                 |
//+------------------------------------------------------------------+
bool ValidateLiquiditySignificance(double price, ENUM_LIQUIDITY_TYPE type, double atr)
{
   double currentPrice = Rates[RatesTotal-1].close;
   double recentHigh = 0;
   double recentLow = DBL_MAX;
   
   // Calculate recent range
   for(int i = RatesTotal - 50; i < RatesTotal; i++)
   {
      if(Rates[i].high > recentHigh) recentHigh = Rates[i].high;
      if(Rates[i].low < recentLow) recentLow = Rates[i].low;
   }
   
   double range = recentHigh - recentLow;
   double levelPosition = (price - recentLow) / range;
   
   // Type-specific validation
   switch(type)
   {
      case EQUAL_HIGHS:
      case EQUAL_LOWS:
         return (levelPosition > 0.1 && levelPosition < 0.9);
         
      case SWING_HIGH:
      case SWING_LOW:
         return (range > atr * 2.0); // Need significant range
         
      case DAILY_HIGH:
      case DAILY_LOW:
      case WEEKLY_HIGH:
      case WEEKLY_LOW:
      case MONTHLY_HIGH:
      case MONTHLY_LOW:
         return true; // Terminal levels always significant
         
      case INSTITUTIONAL_REFERENCE:
         return (MathAbs(price - currentPrice) > atr * 2.0);
         
      default:
         return (levelPosition > 0.15 && levelPosition < 0.85);
   }
}

//+------------------------------------------------------------------+
//| Create New Liquidity Level                                      |
//+------------------------------------------------------------------+
void CreateNewLiquidityLevel(double price, datetime time, ENUM_LIQUIDITY_TYPE type, double atr)
{
   if(LiquidityLevelCount >= ArraySize(LiquidityLevels)) return;
   
   SLiquidityLevel newLevel;
   newLevel.price = price;
   newLevel.time = time;
   newLevel.type = type;
   newLevel.isActive = true;
   newLevel.strength = CalculateLiquidityStrength(type, price, atr);
   newLevel.tolerance = CalculateLiquidityTolerance(type, atr);
   newLevel.touchCount = 1;
   
   // Set classification flags
   newLevel.isEqual = (type == EQUAL_HIGHS || type == EQUAL_LOWS);
   newLevel.isRelative = (type == RELATIVE_EQUAL_HIGHS || type == RELATIVE_EQUAL_LOWS);
   newLevel.isIntermediate = (type == INTERMEDIATE_TERM_HIGH || type == INTERMEDIATE_TERM_LOW);
   newLevel.isTerminal = (type == DAILY_HIGH || type == DAILY_LOW || 
                         type == WEEKLY_HIGH || type == WEEKLY_LOW ||
                         type == MONTHLY_HIGH || type == MONTHLY_LOW);
   
   LiquidityLevels[LiquidityLevelCount] = newLevel;
   LiquidityLevelCount++;
   
   Print("New Liquidity Level Created: ", EnumToString(type), " at ", price, " | Strength: ", newLevel.strength);
}

//+------------------------------------------------------------------+
//| Calculate Liquidity Strength                                    |
//+------------------------------------------------------------------+
double CalculateLiquidityStrength(ENUM_LIQUIDITY_TYPE type, double price, double atr)
{
   double baseStrength = 1.0;
   
   // Type-based strength
   switch(type)
   {
      case MONTHLY_HIGH:
      case MONTHLY_LOW:
         baseStrength = 10.0;
         break;
         
      case WEEKLY_HIGH:
      case WEEKLY_LOW:
         baseStrength = 8.5;
         break;
         
      case DAILY_HIGH:
      case DAILY_LOW:
         baseStrength = 7.0;
         break;
         
      case INTERMEDIATE_TERM_HIGH:
      case INTERMEDIATE_TERM_LOW:
         baseStrength = 6.0;
         break;
         
      case EQUAL_HIGHS:
      case EQUAL_LOWS:
         baseStrength = 5.0;
         break;
         
      case SWING_HIGH:
      case SWING_LOW:
         baseStrength = 4.5;
         break;
         
      case INSTITUTIONAL_REFERENCE:
         baseStrength = 4.0;
         break;
         
      case RELATIVE_EQUAL_HIGHS:
      case RELATIVE_EQUAL_LOWS:
         baseStrength = 3.5;
         break;
         
      default:
         baseStrength = 3.0;
         break;
   }
   
   // Additional strength modifiers can be added here
   
   return MathMin(10.0, baseStrength);
}

//+------------------------------------------------------------------+
//| Calculate Liquidity Tolerance                                   |
//+------------------------------------------------------------------+
double CalculateLiquidityTolerance(ENUM_LIQUIDITY_TYPE type, double atr)
{
   switch(type)
   {
      case EQUAL_HIGHS:
      case EQUAL_LOWS:
         return EqualLevelTolerance * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
         
      case RELATIVE_EQUAL_HIGHS:
      case RELATIVE_EQUAL_LOWS:
         return RelativeEqualTolerance * atr;
         
      case INSTITUTIONAL_REFERENCE:
         return atr * 0.5;
         
      default:
         return atr * 0.3;
   }
}

//+------------------------------------------------------------------+
//| Check For Liquidity Raids                                       |
//+------------------------------------------------------------------+
void CheckForLiquidityRaids(double atr)
{
   double currentPrice = Rates[RatesTotal-1].close;
   
   for(int i = 0; i < LiquidityLevelCount; i++)
   {
      if(!LiquidityLevels[i].isActive || LiquidityLevels[i].isRaided) continue;
      
      double levelPrice = LiquidityLevels[i].price;
      double tolerance = LiquidityLevels[i].tolerance;
      
      bool raided = false;
      
      // Check recent bars for raid
      for(int j = RatesTotal - 5; j < RatesTotal; j++)
      {
         // Check for raid above (buyside liquidity)
         if(levelPrice > currentPrice && Rates[j].high >= levelPrice - tolerance)
         {
            // Confirm with displacement after raid
            double displacement = CalculateDisplacementAfterIndex(j, 3);
            if(displacement >= LiquidityRaidThreshold * atr)
            {
               raided = true;
               LiquidityLevels[i].raidTime = Rates[j].time;
               LiquidityLevels[i].raidVolume = (uint)Rates[j].tick_volume;
               LiquidityLevels[i].displacementAfterRaid = displacement;
               break;
            }
         }
         // Check for raid below (sellside liquidity)
         else if(levelPrice < currentPrice && Rates[j].low <= levelPrice + tolerance)
         {
            double displacement = CalculateDisplacementAfterIndex(j, 3);
            if(displacement >= LiquidityRaidThreshold * atr)
            {
               raided = true;
               LiquidityLevels[i].raidTime = Rates[j].time;
               LiquidityLevels[i].raidVolume = (uint)Rates[j].tick_volume;
               LiquidityLevels[i].displacementAfterRaid = displacement;
               break;
            }
         }
      }
      
      if(raided)
      {
         LiquidityLevels[i].isRaided = true;
         CheckRaidStructureImpact(i);
         Print("Liquidity Raid Detected: ", EnumToString(LiquidityLevels[i].type), 
               " at ", levelPrice, " | Displacement: ", LiquidityLevels[i].displacementAfterRaid);
      }
   }
}

//+------------------------------------------------------------------+
//| Check Raid Structure Impact                                     |
//+------------------------------------------------------------------+
void CheckRaidStructureImpact(int liquidityIndex)
{
   double displacement = LiquidityLevels[liquidityIndex].displacementAfterRaid;
   double atr = GetCachedATR();
   
   // Strong displacement indicates BOS
   if(displacement > atr * 2.5)
   {
      LiquidityLevels[liquidityIndex].causedBOS = true;
   }
   
   // Moderate displacement indicates CHoCH
   if(displacement > atr * 1.8)
   {
      LiquidityLevels[liquidityIndex].causedCHoCH = true;
   }
}

//+------------------------------------------------------------------+
//| Update Existing Liquidity Levels                                |
//+------------------------------------------------------------------+
void UpdateExistingLiquidityLevels()
{
   double currentPrice = Rates[RatesTotal-1].close;
   
   for(int i = 0; i < LiquidityLevelCount; i++)
   {
      if(!LiquidityLevels[i].isActive) continue;
      
      double levelPrice = LiquidityLevels[i].price;
      double tolerance = LiquidityLevels[i].tolerance;
      
      // Check if price is touching the level
      if(MathAbs(currentPrice - levelPrice) <= tolerance)
      {
         LiquidityLevels[i].touchCount++;
         
         // Increase strength with more touches
         double touchBonus = LiquidityLevels[i].touchCount * 0.5;
         LiquidityLevels[i].strength = MathMin(10.0, 
            CalculateLiquidityStrength(LiquidityLevels[i].type, levelPrice, GetCachedATR()) + touchBonus);
      }
   }
}

//+------------------------------------------------------------------+
//| Check Realtime Liquidity Raid                                   |
//+------------------------------------------------------------------+
void CheckRealtimeLiquidityRaid()
{
   if(RatesTotal < 2) return;
   
   double atr = GetCachedATR();
   if(atr <= 0) return;
   
   CheckForLiquidityRaids(atr);
   UpdateLiquidityInteractions();
}

//+------------------------------------------------------------------+
//| Update Liquidity Interactions                                   |
//+------------------------------------------------------------------+
void UpdateLiquidityInteractions()
{
   double currentPrice = Rates[RatesTotal-1].close;
   
   for(int i = 0; i < LiquidityLevelCount; i++)
   {
      if(!LiquidityLevels[i].isActive) continue;
      
      double levelPrice = LiquidityLevels[i].price;
      double tolerance = LiquidityLevels[i].tolerance;
      
      // Check if price is interacting with level
      if(MathAbs(currentPrice - levelPrice) <= tolerance)
      {
         LiquidityLevels[i].touchCount++;
         
         // Update strength based on interactions
         double touchBonus = LiquidityLevels[i].touchCount * 0.5;
         LiquidityLevels[i].strength = MathMin(10.0, 
            CalculateLiquidityStrength(LiquidityLevels[i].type, levelPrice, GetCachedATR()) + touchBonus);
         
         // Check for partial raid
         if(!LiquidityLevels[i].isRaided && LiquidityLevels[i].touchCount >= 2)
         {
            LiquidityLevels[i].isPartiallyRaided = true;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Cleanup Old Liquidity Levels                                    |
//+------------------------------------------------------------------+
void CleanupOldLiquidityLevels()
{
   datetime currentTime = TimeCurrent();
   double atr = GetCachedATR();
   
   for(int i = 0; i < LiquidityLevelCount; i++)
   {
      if(!LiquidityLevels[i].isActive) continue;
      
      // Clean up raided levels after some time
      if(LiquidityLevels[i].isRaided && currentTime - LiquidityLevels[i].raidTime > 7200) // 2 hours
      {
         LiquidityLevels[i].isActive = false;
         continue;
      }
      
      // Different max ages for different types
      int maxAge = 24 * 3600; // Default 24 hours
      
      switch(LiquidityLevels[i].type)
      {
         case MONTHLY_HIGH:
         case MONTHLY_LOW:
            maxAge = 30 * 24 * 3600; // 30 days
            break;
            
         case WEEKLY_HIGH:
         case WEEKLY_LOW:
            maxAge = 7 * 24 * 3600; // 7 days
            break;
            
         case DAILY_HIGH:
         case DAILY_LOW:
            maxAge = 3 * 24 * 3600; // 3 days
            break;
            
         default:
            maxAge = 24 * 3600; // 24 hours
            break;
      }
      
      // Remove old levels
      if(currentTime - LiquidityLevels[i].time > maxAge)
      {
         LiquidityLevels[i].isActive = false;
         continue;
      }
      
      // Remove levels too far from price
      double currentPrice = Rates[RatesTotal-1].close;
      if(MathAbs(LiquidityLevels[i].price - currentPrice) > atr * 50.0)
      {
         LiquidityLevels[i].isActive = false;
      }
   }
}

//+------------------------------------------------------------------+
//| Count Recent Liquidity Raids                                    |
//+------------------------------------------------------------------+
int CountRecentLiquidityRaids(int timeframeSeconds)
{
   int count = 0;
   datetime cutoffTime = TimeCurrent() - timeframeSeconds;
   
   for(int i = 0; i < LiquidityLevelCount; i++)
   {
      if(LiquidityLevels[i].isRaided && LiquidityLevels[i].raidTime >= cutoffTime)
      {
         count++;
      }
   }
   return count;
}

#endif // AIME_LIQUIDITY_LEVELS_MQH

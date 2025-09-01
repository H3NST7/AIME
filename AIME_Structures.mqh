//+------------------------------------------------------------------+
//|                                           AIME_Structures.mqh    |
//|                     Complete ICT Data Structure Definitions      |
//+------------------------------------------------------------------+
#ifndef AIME_STRUCTURES_MQH
#define AIME_STRUCTURES_MQH

// Fair Value Gap Structure (19 Properties)
struct SFairValueGap
{
   // Core Properties
   double            topPrice;                    // Top of FVG
   double            bottomPrice;                 // Bottom of FVG
   double            midPrice;                    // Middle of FVG
   datetime          startTime;                   // Formation time
   datetime          endTime;                     // Current time
   ENUM_AIME_PATTERN  direction;                   // FVG direction
   
   // State Properties
   bool              isFilled;                    // Fill status
   double            fillPercentage;              // Fill percentage (0-100)
   bool              isInversion;                 // Inversion status
   bool              isActive;                    // Active status
   
   // Strength Properties
   double            strength;                    // Strength (1-10)
   double            displacement;                // Associated displacement
   double            atrAtFormation;              // ATR at formation
   
   // Advanced Properties
   bool              isVolumeFVG;                 // Volume-based FVG
   bool              isOptimalFVG;                // Optimal FVG criteria
   bool              isInstitutional;             // Institutional significance
   
   // Rejection Properties
   int               rejectionCount;              // Rejection count
   int               candleIndex;                 // Formation candle index
   
   // Constructor
   SFairValueGap() : topPrice(0), bottomPrice(0), midPrice(0), startTime(0), endTime(0),
                     direction(FAIR_VALUE_GAP_BULLISH), isFilled(false), fillPercentage(0),
                     isInversion(false), isActive(true), strength(0), displacement(0),
                     atrAtFormation(0), isVolumeFVG(false), isOptimalFVG(false),
                     isInstitutional(false), rejectionCount(0), candleIndex(0) {}
};

// Order Block Structure (22 Properties)
struct SOrderBlock
{
   // Price Properties
   double            price;                       // Order block price
   double            high;                        // Order block high
   double            low;                         // Order block low
   double            open;                        // Order block open
   double            close;                       // Order block close
   datetime          time;                        // Formation time
   
   // State Properties
   bool              isBullish;                   // Bullish/Bearish
   bool              isBreaker;                   // Breaker status
   bool              isMitigated;                 // Mitigation status
   bool              isActive;                    // Active status
   
   // Pattern Properties
   ENUM_AIME_PATTERN  patternType;                 // Pattern type
   bool              isRefinement;                // Refinement status
   bool              isOptimal;                   // Optimal criteria
   
   // Volume Properties
   uint              volume;                      // Volume at formation
   double            displacement;                // Associated displacement
   double            atr;                         // ATR at formation
   
   // Liquidity Properties
   bool              hasLiquidityGrab;            // Liquidity grab association
   double            liquidityLevel;              // Associated liquidity level
   
   // Institutional Properties
   bool              isInstitutional;             // Institutional significance
   double            strength;                    // Strength (1-10)
   int               rejectionCount;              // Rejection count
   int               candleIndex;                 // Formation candle index
   
   // Constructor
   SOrderBlock() : price(0), high(0), low(0), open(0), close(0), time(0),
                   isBullish(true), isBreaker(false), isMitigated(false), isActive(true),
                   patternType(ORDER_BLOCK_BULLISH), isRefinement(false), isOptimal(false),
                   volume(0), displacement(0), atr(0), hasLiquidityGrab(false),
                   liquidityLevel(0), isInstitutional(false), strength(0),
                   rejectionCount(0), candleIndex(0) {}
};

// Liquidity Level Structure (20 Properties)
struct SLiquidityLevel
{
   // Core Properties
   double            price;                       // Liquidity price
   datetime          time;                        // Formation time
   ENUM_LIQUIDITY_TYPE type;                      // Liquidity type
   double            tolerance;                   // Price tolerance
   
   // State Properties
   bool              isRaided;                    // Raid status
   bool              isPartiallyRaided;           // Partial raid status
   bool              isActive;                    // Active status
   
   // Strength Properties
   double            strength;                    // Strength (1-10)
   int               touchCount;                  // Touch count
   uint              volume;                      // Volume at level
   
   // Classification Properties
   bool              isEqual;                     // Equal level status
   bool              isRelative;                  // Relative equal status
   bool              isIntermediate;              // Intermediate term
   bool              isTerminal;                  // Terminal level
   
   // Raid Properties
   datetime          raidTime;                    // Raid time
   uint              raidVolume;                  // Raid volume
   double            displacementAfterRaid;       // Post-raid displacement
   
   // Structure Properties
   bool              causedBOS;                   // Caused Break of Structure
   bool              causedCHoCH;                 // Caused Change of Character
   int               candleIndex;                 // Formation candle index
   
   // Constructor
   SLiquidityLevel() : price(0), time(0), type(BUYSIDE_LIQUIDITY), tolerance(0),
                       isRaided(false), isPartiallyRaided(false), isActive(true),
                       strength(0), touchCount(0), volume(0), isEqual(false),
                       isRelative(false), isIntermediate(false), isTerminal(false),
                       raidTime(0), raidVolume(0), displacementAfterRaid(0),
                       causedBOS(false), causedCHoCH(false), candleIndex(0) {}
};

// Market Structure Analysis (22 Properties)
struct SMarketStructure
{
   // Swing Properties
   double            lastHigherHigh;              // Last Higher High
   datetime          lastHigherHighTime;          // HH Time
   double            lastLowerHigh;               // Last Lower High
   datetime          lastLowerHighTime;           // LH Time
   double            lastHigherLow;               // Last Higher Low
   datetime          lastHigherLowTime;           // HL Time
   double            lastLowerLow;                // Last Lower Low
   datetime          lastLowerLowTime;            // LL Time
   
   // Structure Properties
   ENUM_AIME_STRUCTURE currentStructure;           // Current structure
   ENUM_AIME_STRUCTURE previousStructure;          // Previous structure
   
   // State Properties
   bool              isDisplacement;              // Displacement detected
   double            displacementSize;            // Displacement size in ATR
   
   // Change Properties
   bool              hasChangeOfCharacter;        // CHoCH detected
   bool              hasBreakOfStructure;         // BOS detected
   bool              hasMarketStructureShift;     // MSS detected
   
   // Level Properties
   double            bosLevel;                    // BOS level
   double            chochLevel;                  // CHoCH level
   double            mssLevel;                    // MSS level
   
   // Validation Properties
   bool              structureConfirmed;          // Structure confirmed
   double            structureStrength;           // Structure strength (1-10)
   
   // Trap Properties
   bool              isInducementTrap;            // Inducement trap
   double            inducementLevel;             // Inducement level
   
   // Constructor
   SMarketStructure() : lastHigherHigh(0), lastHigherHighTime(0), lastLowerHigh(0),
                        lastLowerHighTime(0), lastHigherLow(0), lastHigherLowTime(0),
                        lastLowerLow(0), lastLowerLowTime(0), currentStructure(RANGE_BOUND),
                        previousStructure(RANGE_BOUND), isDisplacement(false),
                        displacementSize(0), hasChangeOfCharacter(false),
                        hasBreakOfStructure(false), hasMarketStructureShift(false),
                        bosLevel(0), chochLevel(0), mssLevel(0), structureConfirmed(false),
                        structureStrength(0), isInducementTrap(false), inducementLevel(0) {}
};

// Power of Three Analysis (19 Properties)
struct SPowerOfThree
{
   // Phase Properties
   ENUM_MARKET_PHASE currentPhase;                // Current phase
   datetime          phaseStartTime;              // Phase start time
   bool              isOptimalPhase;              // Optimal phase timing
   
   // Accumulation Properties
   double            accumulationHigh;            // Accumulation high
   double            accumulationLow;             // Accumulation low
   double            accumulationMid;             // Accumulation midpoint
   
   // Manipulation Properties
   double            manipulationLevel;           // Manipulation level
   double            manipulationHigh;            // Manipulation high
   double            manipulationLow;             // Manipulation low
   
   // Distribution Properties
   bool              distributionStarted;         // Distribution started
   double            distributionTarget;          // Distribution target
   double            distributionHigh;            // Distribution high
   double            distributionLow;             // Distribution low
   
   // Progress Properties
   bool              phaseComplete;               // Phase completion
   double            phaseProgress;               // Phase progress (0-100)
   int               phaseCandles;                // Candles in phase
   
   // Strength Properties
   double            phaseStrength;               // Phase strength (1-10)
   bool              hasLiquidityGrab;            // Liquidity grab in phase
   double            liquidityGrabLevel;          // Liquidity grab level
   
   // Constructor
   SPowerOfThree() : currentPhase(MP_INACTIVE), phaseStartTime(0), isOptimalPhase(false),
                     accumulationHigh(0), accumulationLow(0), accumulationMid(0),
                     manipulationLevel(0), manipulationHigh(0), manipulationLow(0),
                     distributionStarted(false), distributionTarget(0), distributionHigh(0),
                     distributionLow(0), phaseComplete(false), phaseProgress(0),
                     phaseCandles(0), phaseStrength(0), hasLiquidityGrab(false),
                     liquidityGrabLevel(0) {}
};

// Performance Cache Structure (15 Properties)
struct SPerformanceCache
{
   // Indicator Cache (with timestamps)
   double            cachedATR;                   // Cached ATR value
   datetime          atrCacheTime;                // ATR cache timestamp
   double            cachedVolatility;            // Cached volatility
   datetime          volatilityCacheTime;         // Volatility cache timestamp
   double            cachedSpread;                // Cached spread
   datetime          spreadCacheTime;             // Spread cache timestamp
   
   // Market Data Cache
   double            cachedRSI;                   // Cached RSI
   double            cachedMACD;                  // Cached MACD
   double            cachedEMA20;                 // Cached EMA 20
   double            cachedEMA50;                 // Cached EMA 50
   double            cachedBBUpper;               // Cached Bollinger Upper
   double            cachedBBLower;               // Cached Bollinger Lower
   
   // Correlation Cache
   double            correlationCache[8];         // Cached correlations
   datetime          correlationCacheTime;        // Correlation cache time
   
   // Structure Cache
   bool              structureCacheValid;         // Structure cache validity
   datetime          structureCacheTime;          // Structure cache time
   
   // Constructor
   SPerformanceCache() : cachedATR(0), atrCacheTime(0), cachedVolatility(0),
                         volatilityCacheTime(0), cachedSpread(0), spreadCacheTime(0),
                         cachedRSI(0), cachedMACD(0), cachedEMA20(0), cachedEMA50(0),
                         cachedBBUpper(0), cachedBBLower(0), correlationCacheTime(0),
                         structureCacheValid(false), structureCacheTime(0)
   {
      ArrayInitialize(correlationCache, 0.0);
   }
};

#endif // AIME_STRUCTURES_MQH

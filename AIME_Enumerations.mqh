//+------------------------------------------------------------------+
//|                                          ICT_Enumerations.mqh    |
//|                              Complete Enumeration System         |
//+------------------------------------------------------------------+
#ifndef ICT_ENUMERATIONS_MQH
#define ICT_ENUMERATIONS_MQH

// Primary ICT Market Structure Classification (11 States)
enum ENUM_ICT_STRUCTURE
{
   BULLISH_BOS,           // Bullish Break of Structure
   BEARISH_BOS,           // Bearish Break of Structure  
   BULLISH_CHoCH,         // Bullish Change of Character
   BEARISH_CHoCH,         // Bearish Change of Character
   BULLISH_MSS,           // Bullish Market Structure Shift
   BEARISH_MSS,           // Bearish Market Structure Shift
   RANGE_BOUND,           // Range-bound Market
   ACCUMULATION,          // Accumulation Phase
   MANIPULATION,          // Manipulation Phase
   DISTRIBUTION,          // Distribution Phase
   REBALANCE             // Rebalancing Phase
};

// ICT Market Phase Classification (8 Phases)
enum ENUM_MARKET_PHASE
{
   ACCUMULATION_AM,       // Morning Accumulation
   MANIPULATION_AM,       // Morning Manipulation
   DISTRIBUTION_AM,       // Morning Distribution
   ACCUMULATION_PM,       // Afternoon Accumulation
   MANIPULATION_PM,       // Afternoon Manipulation
   DISTRIBUTION_PM,       // Afternoon Distribution
   REBALANCE_EOD,         // End of Day Rebalance
   MP_INACTIVE           // Inactive Period
};

// Comprehensive Liquidity Type Classification (19 Types)
enum ENUM_LIQUIDITY_TYPE
{
   BUYSIDE_LIQUIDITY,           // Buy-side Liquidity
   SELLSIDE_LIQUIDITY,          // Sell-side Liquidity
   EQUAL_HIGHS,                 // Equal Highs
   EQUAL_LOWS,                  // Equal Lows
   RELATIVE_EQUAL_HIGHS,        // Relative Equal Highs
   RELATIVE_EQUAL_LOWS,         // Relative Equal Lows
   INTERMEDIATE_TERM_HIGH,      // Intermediate Term High
   INTERMEDIATE_TERM_LOW,       // Intermediate Term Low
   SHORT_TERM_HIGH,             // Short Term High
   SHORT_TERM_LOW,              // Short Term Low
   SWING_HIGH,                  // Swing High
   SWING_LOW,                   // Swing Low
   DAILY_HIGH,                  // Daily High
   DAILY_LOW,                   // Daily Low
   WEEKLY_HIGH,                 // Weekly High
   WEEKLY_LOW,                  // Weekly Low
   MONTHLY_HIGH,                // Monthly High
   MONTHLY_LOW,                 // Monthly Low
   INSTITUTIONAL_REFERENCE      // Institutional Reference Point
};

// Advanced ICT Pattern Classification (26 Patterns)
enum ENUM_ICT_PATTERN
{
   FAIR_VALUE_GAP_BULLISH,           // Bullish Fair Value Gap
   FAIR_VALUE_GAP_BEARISH,           // Bearish Fair Value Gap
   FAIR_VALUE_GAP_INVERSION,         // Fair Value Gap Inversion
   ORDER_BLOCK_BULLISH,              // Bullish Order Block
   ORDER_BLOCK_BEARISH,              // Bearish Order Block
   ORDER_BLOCK_BREAKER,              // Breaker Order Block
   ORDER_BLOCK_MITIGATION,           // Mitigation Order Block
   UNICORN_MODEL_BULLISH,            // Bullish Unicorn Model
   UNICORN_MODEL_BEARISH,            // Bearish Unicorn Model
   DRAGONFLY_ENTRY_BULLISH,          // Bullish Dragonfly Entry
   DRAGONFLY_ENTRY_BEARISH,          // Bearish Dragonfly Entry
   MENTORSHIP_2022_BULLISH,          // 2022 Mentorship Bullish
   MENTORSHIP_2022_BEARISH,          // 2022 Mentorship Bearish
   SILVER_BULLET_BULLISH,            // Silver Bullet Bullish
   SILVER_BULLET_BEARISH,            // Silver Bullet Bearish
   TURTLE_SOUP_LONG,                 // Turtle Soup Long
   TURTLE_SOUP_SHORT,                // Turtle Soup Short
   MARKET_MAKER_BUY_MODEL,           // Market Maker Buy Model
   MARKET_MAKER_SELL_MODEL,          // Market Maker Sell Model
   VOLUME_IMBALANCE_BULLISH,         // Bullish Volume Imbalance
   VOLUME_IMBALANCE_BEARISH,         // Bearish Volume Imbalance
   INEFFICIENCY_BULLISH,             // Bullish Market Inefficiency
   INEFFICIENCY_BEARISH,             // Bearish Market Inefficiency
   INSTITUTIONAL_ORDER_FLOW_BULL,    // Bullish Institutional Order Flow
   INSTITUTIONAL_ORDER_FLOW_BEAR,    // Bearish Institutional Order Flow
   OPTIMAL_TRADE_ENTRY              // Optimal Trade Entry
};

// ICT Killzone Classification (10 Zones)
enum ENUM_KILLZONE
{
   LONDON_OPEN,          // London Open (02:00-05:00 GMT)
   LONDON_CLOSE,         // London Close (10:00-12:00 GMT)
   NEW_YORK_OPEN,        // New York Open (13:30-16:00 GMT)
   NEW_YORK_CLOSE,       // New York Close (20:00-22:00 GMT)
   ASIAN_RANGE,          // Asian Range (22:00-02:00 GMT)
   FRANKFURT_OPEN,       // Frankfurt Open (07:00-09:00 GMT)
   LUNCH_TIME,           // Lunch Time (12:00-13:30 GMT)
   SILVER_BULLET,        // Silver Bullet Times
   MACRO_TIME,           // Macro Times (Hourly :00-:02)
   KZ_INACTIVE          // Inactive Killzone
};

// Market Maker Model Classification (9 Models)
enum ENUM_MARKET_MAKER_MODEL
{
   CONSOLIDATION,        // Consolidation Model
   EXPANSION_BULLISH,    // Bullish Expansion Model
   EXPANSION_BEARISH,    // Bearish Expansion Model
   RETRACEMENT_BULLISH,  // Bullish Retracement Model
   RETRACEMENT_BEARISH,  // Bearish Retracement Model
   REVERSAL_BULLISH,     // Bullish Reversal Model
   REVERSAL_BEARISH,     // Bearish Reversal Model
   CONTINUATION_BULLISH, // Bullish Continuation Model
   CONTINUATION_BEARISH  // Bearish Continuation Model
};

#endif // ICT_ENUMERATIONS_MQH

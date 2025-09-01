## AIME (Advanced ICT Methodology Expert) is a sophisticated, modular Expert Advisor (EA) designed for MetaTrader 5 (MT5) that automates trading strategies based on the Inner Circle Trader (ICT) methodology. This project aims to provide a comprehensive, institutional-grade solution for market analysis, trade execution, and risk management, integrating advanced concepts such as market structure, fair value gaps, liquidity analysis, and various ICT-specific models.

## Modular Architecture

The EA is built with a highly modular architecture, allowing for easy expansion, maintenance, and customization. The core system is divided into several logical modules, each handling specific aspects of the trading process:

* **Core System Modules**: Handles fundamental enumerations, data structures, global variables, and input parameters.
* **Analysis Modules**: Focuses on advanced market analysis concepts.
* **Strategy Modules**: Implements various ICT trading strategies.
* **Execution Modules**: Manages trade execution, risk, and position management.
* **Utility Modules**: Provides core calculation, validation, memory management, and error handling functionalities.
* **Visual Modules**: Responsible for the graphical dashboard and chart object management.
* **Performance Modules**: Tracks and reports trading performance metrics.

## Key ICT Concepts Implemented

AIME integrates a wide array of advanced ICT concepts to provide a robust and intelligent trading system:

## 1. Market Structure Analysis

This module (`AIME_MarketStructure.mqh`) is crucial for identifying the directional bias of the market. It analyzes swing points, detects significant changes in market behavior, and classifies the current market structure. Key functionalities include:

* **Swing Point Detection**: Identifies significant swing highs and lows using dynamic lookback periods and volume validation.
* **Break of Structure (BOS)**: Detects continuation of the current trend when price breaks above a previous swing high (bullish) or below a previous swing low (bearish).
* **Change of Character (CHoCH)**: Identifies potential trend reversals when price breaks a previous swing point in the opposite direction of the current trend.
* **Market Structure Shift (MSS)**: A more significant reversal signal, indicating a major shift in market dynamics, often confirmed by strong displacement.
* **Displacement Detection**: Identifies strong, impulsive price movements, often associated with institutional activity, using single candle, sequential, and gap-based methods.
* **Inducement Traps**: Detects false breakouts that quickly reverse, designed to trap retail traders.

## 2. Fair Value Gaps (FVG) Analysis

The `AIME_FairValueGaps.mqh` module identifies and analyzes Fair Value Gaps, which are imbalances in price delivery. These gaps often act as magnets for price or areas of potential support/resistance. Features include:

* **Classic 3-Candle FVG Detection**: Identifies standard FVGs based on the three-candle pattern.
* **Extended FVG Patterns**: Detects FVGs formed over 4-5 candles.
* **Volume-Based FVG Detection**: Incorporates volume analysis to identify high-conviction FVGs.
* **FVG Quality Validation**: Assesses the quality of FVGs based on size, displacement, and alignment with market structure.
* **FVG Strength Calculation**: Assigns a strength score to each FVG, considering factors like size, displacement, volume, structure alignment, timing (Killzones), and Premium/Discount alignment.
* **FVG Inversion Detection**: Identifies when an FVG changes its role (e.g., from bullish support to bearish resistance) after multiple rejections.
* **Real-time FVG Monitoring**: Continuously updates the fill percentage and activity status of existing FVGs.

## 3. Liquidity Levels Analysis

This module (`AIME_LiquidityLevels.mqh` - focuses on identifying areas where significant liquidity is resting, often represented by equal highs/lows, swing points, or institutional reference points. These levels are prime targets for institutional algorithms.

## 4. Order Blocks (OB) Analysis

This module (`AIME_OrderBlocks.mqh` - identifies Order Blocks, which are specific candles or groups of candles where large institutional orders were placed, leading to significant price movements. These often serve as strong support or resistance levels.

## 5. Premium/Discount Arrays

This concept (`AIME_PremiumDiscount.mqh` - helps determine whether the current price is trading at a premium (expensive) or discount (cheap) relative to a defined price range. This is crucial for identifying optimal entry and exit points.

## 6. Killzones and Timing

This module (`AIME_Killzones.mqh` - identifies specific time windows during the trading day (Killzones) when institutional activity is typically highest, offering higher probability trading opportunities. It also incorporates Macro Times and Silver Bullet timings.

## 7. Multi-Asset Correlation Analysis

This module (`AIME_Correlation.mqh` -  analyzes the correlation between different assets (e.g., DXY, bonds, equities, major currencies, commodities) to provide a broader market context and identify intermarket relationships.

## 8. Market Maker Models

This module (`AIME_MarketMaker.mqh` - implements various Market Maker Models (e.g., Consolidation, Expansion, Retracement, Reversal, Continuation) to understand the likely intentions of institutional players.

## 9. Advanced ICT Strategies

The EA incorporates several specific ICT trading strategies:

* **Unicorn Model**: (`AIME_UnicornModel.mqh` - *not yet analyzed, but inferred from includes*)
* **Dragonfly Entry**: (`AIME_DragonflyEntry.mqh` - *not yet analyzed, but inferred from includes*)
* **Silver Bullet**: (`AIME_SilverBullet.mqh` - *not yet analyzed, but inferred from includes*)
* **2022 Mentorship Model**: (`AIME_2022Mentorship.mqh`)

## Risk Management

AIME includes a robust risk management system (`AIME_RiskManagement.mqh` - *not yet analyzed, but inferred from includes*) with configurable parameters:

* **Max Risk Per Trade**: Defines the maximum percentage of account balance to risk per trade.
* **Max Daily Risk**: Sets a limit on the total daily risk.
* **Max Concurrent Positions**: Controls the number of open trades.
* **ICT Trailing Stop & Partial Profits**: Implements ICT-specific methods for trade management.
* **Emergency Exit System**: Provides a mechanism for rapid trade closure under extreme market conditions.
* **Confluence-Based Risk Adjustment**: Adjusts risk based on the strength of confluence signals.

## Visualizations and Dashboard

The EA provides comprehensive visual feedback through a customizable dashboard (`AIME_Dashboard.mqh` - *not yet analyzed, but inferred from includes*) and chart objects (`AIME_ChartObjects.mqh` - *not yet analyzed, but inferred from includes*). Users can enable or disable the display of various ICT elements directly on the chart, including:

* Market Structure (BOS, CHoCH, MSS)
* Fair Value Gaps
* Order Blocks
* Liquidity Levels
* Premium/Discount Zones
* Killzone Highlights
* Correlation Information

## Input Parameters

The `AIME_InputParameters.mqh` module provides extensive customization options, categorized for clarity:

* **Core ICT Risk Management**: Parameters for controlling trade and daily risk, position limits, and ICT-specific trade management.
* **Market Structure Analysis**: Settings for lookback periods, displacement thresholds, and enabling/disabling detection of various structure elements.
* **ICT Timing & Killzones**: Configuration for various Killzones (London Open/Close, New York Open/Close, Frankfurt Open), Silver Bullet times, Macro Times, and news avoidance.
* **Premium/Discount Arrays**: Defines thresholds for premium, discount, and equilibrium zones, Fibonacci levels for Optimal Trade Entry (OTE), and lookback periods.
* **Liquidity Analysis**: Parameters for liquidity detection, equal level tolerance, minimum touches, raid thresholds, and strength.
* **Market Maker Models**: Enables/disables market maker model analysis and sets thresholds for consolidation, expansion, retracement, reversal, and continuation phases.
* **Advanced ICT Concepts**: Toggles and thresholds for Unicorn Model, Dragonfly Entry, 2022 Mentorship Model, Optimal FVG, Institutional OB, and Liquidity Grab Displacement.
* **Multi-Asset Correlation**: Enables/disables correlation analysis and allows selection of assets to analyze (DXY, Bonds, Equities, Currencies, Commodities).
* **Risk Management Model**: Fine-tunes risk adjustments based on ICT risk multiplier, confluence, volatility, and correlation.
* **Visual Display**: Controls the visibility of various ICT elements on the chart and defines custom colors for bullish, bearish, and neutral elements.

The EA is developed in **MQL5**, the proprietary programming language for the MetaTrader 5 platform.


## Data Structures

The `AIME_Structures.mqh` module defines several key data structures to efficiently manage and store market analysis data:

* **SFairValueGap**: Stores properties of detected Fair Value Gaps, including price levels, time, direction, fill status, strength, and institutional significance.
* **SOrderBlock**: Stores properties of identified Order Blocks, such as price, high/low, time, type (bullish/bearish, breaker, mitigated), volume, and institutional significance.
* **SLiquidityLevel**: Stores details of liquidity levels, including price, time, type (buy-side/sell-side, equal highs/lows), raid status, strength, and impact on market structure.
* **SMarketStructure**: Contains information about the current and previous market structure, including swing points (HH, HL, LH, LL), detection of BOS, CHoCH, MSS, displacement, and inducement traps.
* **SPowerOfThree**: Tracks the phases of the Power of Three concept (Accumulation, Manipulation, Distribution) with associated price levels and progress.
* **SPerformanceCache**: Caches frequently accessed data like ATR, volatility, spread, RSI, MACD, EMA, Bollinger Bands, and correlation values to optimize performance.

## Global Variables

The `AIME_GlobalVariables.mqh` module declares global variables used across different modules to maintain state and share data. These include:

* **Core Trading Variables**: Account balance, current risk, daily PnL, active positions, trading allowance, and last trade time.
* **ICT Analysis Arrays**: Arrays to store detected Fair Value Gaps, Order Blocks, and Liquidity Levels, along with single instances for Market Structure, Power of Three analysis, and Performance Cache.
* **Multi-Timeframe Market Data**: `MqlRates` array to store historical price data for multi-timeframe analysis.
* **Technical Indicator**: Handles for various built-in MT5 indicators (ATR, RSI, MACD, EMA, Bollinger Bands, Stochastic, WPR, ADX, CCI).
* **Correlation Analysis Variables**: Symbols and values for multi-asset correlation analysis.
* **Premium/Discount Analysis**: Variables to track current premium/discount status and range.
* **Killzone Analysis**: Current Killzone, optimal trading time flag, and Killzone start/end times.
* **Pattern Detection Counters: Counters for detected FVGs, Order Blocks, and Liquidity Levels.
* **Performance Tracking Variables**: Metrics for total trades, winning/losing trades, profit/loss, largest win/loss, and maximum drawdown.
* **Visual Element Management**: Arrays and counters for managing graphical objects on the chart.
* **Error Handling and Recovery**: Variables for tracking errors and managing recovery mode.

## Core Calculation Utilities

The `AIME_Calculations.mqh` module provides essential mathematical and analytical functions:

* **Cached ATR & Volatility**: Efficiently retrieves and caches Average True Range (ATR) and volatility values to avoid redundant calculations.
* **Range and Displacement Calculation**: Calculates recent price ranges and displacement (impulsive moves) over specified periods.
* **Optimal Position Size**: Determines optimal lot size based on account balance, risk per trade, entry price, stop loss, and dynamic adjustments for confluence and volatility.
* **Institutional Level Detection**: Identifies if a price level is an institutional level (e.g., round numbers) based on a defined tolerance.
* **Confluence Score Calculation**: Aggregates scores from various analysis modules (structure, pattern, timing, liquidity, premium/discount) to provide an overall confluence score for trade validation.

//+------------------------------------------------------------------+
//|                                           AIME_Killzones.mqh     |
//|                         Killzone Timing Analysis Module          |
//+------------------------------------------------------------------+
#ifndef AIME_KILLZONES_MQH
#define AIME_KILLZONES_MQH

//+------------------------------------------------------------------+
//| Update Killzone Status                                          |
//+------------------------------------------------------------------+
void UpdateKillzoneStatus()
{
   datetime currentTime = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(currentTime, dt);
   
   ENUM_KILLZONE previousKillzone = CurrentKillzone;
   CurrentKillzone = KZ_INACTIVE;
   IsOptimalTradingTime = false;
   
   int gmtHour = dt.hour;
   int gmtMinute = dt.min;
   
   // Check each killzone
   if(UseLondonOpen && gmtHour >= 2 && gmtHour < 5)
   {
      CurrentKillzone = LONDON_OPEN;
      IsOptimalTradingTime = true;
   }
   else if(UseLondonClose && gmtHour >= 10 && gmtHour < 12)
   {
      CurrentKillzone = LONDON_CLOSE;
      IsOptimalTradingTime = true;
   }
   else if(UseNewYorkOpen && ((gmtHour == 13 && gmtMinute >= 30) || (gmtHour >= 14 && gmtHour < 16)))
   {
      CurrentKillzone = NEW_YORK_OPEN;
      IsOptimalTradingTime = true;
   }
   else if(UseNewYorkClose && gmtHour >= 20 && gmtHour < 22)
   {
      CurrentKillzone = NEW_YORK_CLOSE;
      IsOptimalTradingTime = true;
   }
   else if(UseFrankfurtOpen && gmtHour >= 7 && gmtHour < 9)
   {
      CurrentKillzone = FRANKFURT_OPEN;
      IsOptimalTradingTime = true;
   }
   else if(UseSilverBullet && IsSilverBulletTime(currentTime))
   {
      CurrentKillzone = SILVER_BULLET;
      IsOptimalTradingTime = true;
   }
   else if(UseMacroTimes && IsMacroTime(currentTime))
   {
      CurrentKillzone = MACRO_TIME;
      IsOptimalTradingTime = true;
   }
   else if((gmtHour >= 22) || (gmtHour < 2))
   {
      CurrentKillzone = ASIAN_RANGE;
      IsOptimalTradingTime = false;
   }
   else if(gmtHour == 12 || (gmtHour == 13 && gmtMinute < 30))
   {
      CurrentKillzone = LUNCH_TIME;
      IsOptimalTradingTime = false;
   }
   
   // Log killzone changes
   if(CurrentKillzone != previousKillzone)
   {
      Print("Killzone Change: ", EnumToString(previousKillzone), " -> ", EnumToString(CurrentKillzone));
   }
}

//+------------------------------------------------------------------+
//| Is Silver Bullet Time                                           |
//+------------------------------------------------------------------+
bool IsSilverBulletTime(datetime currentTime)
{
   MqlDateTime dt;
   TimeToStruct(currentTime, dt);
   int gmtHour = dt.hour;
   
   // Standard Silver Bullet times: 10:00-11:00, 14:00-15:00, 18:00-19:00 GMT
   if((gmtHour == 10) || (gmtHour == 14) || (gmtHour == 18))
   {
      return true;
   }
   
   // Check custom Silver Bullet times from input
   string times[];
   int count = StringSplit(SilverBulletTimes, ',', times);
   
   for(int i = 0; i < count; i++)
   {
      string timeRange = times[i];
      StringTrimLeft(timeRange);
      StringTrimRight(timeRange);
      
      // Parse time range (format: "HH:MM-HH:MM")
      string startEnd[];
      if(StringSplit(timeRange, '-', startEnd) == 2)
      {
         int startHour, startMin, endHour, endMin;
         
         // Parse start time
         string startParts[];
         if(StringSplit(startEnd[0], ':', startParts) == 2)
         {
            startHour = (int)StringToInteger(startParts[0]);
            startMin = (int)StringToInteger(startParts[1]);
         }
         
         // Parse end time
         string endParts[];
         if(StringSplit(startEnd[1], ':', endParts) == 2)
         {
            endHour = (int)StringToInteger(endParts[0]);
            endMin = (int)StringToInteger(endParts[1]);
         }
         
         // Check if current time is within range
         int currentMinutes = dt.hour * 60 + dt.min;
         int startMinutes = startHour * 60 + startMin;
         int endMinutes = endHour * 60 + endMin;
         
         if(currentMinutes >= startMinutes && currentMinutes < endMinutes)
         {
            return true;
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Is Macro Time                                                   |
//+------------------------------------------------------------------+
bool IsMacroTime(datetime currentTime)
{
   MqlDateTime dt;
   TimeToStruct(currentTime, dt);
   
   // Macro times are at the top of each hour plus buffer
   if(dt.min <= (2 + MacroTimeBuffer))
   {
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Is Optimal Killzone Time                                        |
//+------------------------------------------------------------------+
bool IsOptimalKillzoneTime(datetime time)
{
   MqlDateTime dt;
   TimeToStruct(time, dt);
   int gmtHour = dt.hour;
   
   // Optimal killzones for high-probability setups
   return (gmtHour >= 2 && gmtHour < 5) ||    // London Open
          (gmtHour >= 10 && gmtHour < 12) ||  // London Close
          (gmtHour >= 13 && gmtHour < 16) ||  // New York Open
          IsSilverBulletTime(time);
}

//+------------------------------------------------------------------+
//| Is Active Killzone Time                                         |
//+------------------------------------------------------------------+
bool IsActiveKillzoneTime(datetime time)
{
   MqlDateTime dt;
   TimeToStruct(time, dt);
   int gmtHour = dt.hour;
   
   // Any active trading session
   return (gmtHour >= 2 && gmtHour < 22); // European + US sessions
}

//+------------------------------------------------------------------+
//| Is High Impact News Time                                        |
//+------------------------------------------------------------------+
bool IsHighImpactNewsTime(datetime time)
{
   if(!AvoidNews) return false;
   
   MqlDateTime dt;
   TimeToStruct(time, dt);
   
   // Check for typical high impact news times
   if(dt.min <= 2) // First 2 minutes of the hour
   {
      // Major news release times (GMT)
      if(dt.hour == 8 || dt.hour == 9 ||      // European news
         dt.hour == 12 ||                      // London fix
         dt.hour == 14 || dt.hour == 15 ||    // US news
         dt.hour == 20)                        // Late US news
      {
         return true;
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Calculate Timing Confluence                                     |
//+------------------------------------------------------------------+
double CalculateTimingConfluence()
{
   double score = 5.0;
   
   // Optimal killzone bonus
   if(IsOptimalKillzoneTime(TimeCurrent())) score += 3.0;
   else if(IsActiveKillzoneTime(TimeCurrent())) score += 1.5;
   
   // Power of Three phase bonus
   if(PowerOfThreeAnalysis.isOptimalPhase) score += 2.0;
   if(PowerOfThreeAnalysis.phaseStrength >= 7.0) score += 1.0;
   
   // Macro time bonus
   if(UseMacroTimes && IsMacroTime(TimeCurrent())) score += 1.5;
   
   return MathMax(1.0, MathMin(10.0, score));
}

#endif // AIME_KILLZONES_MQH

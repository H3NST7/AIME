//+------------------------------------------------------------------+
//|                                      AIME_ErrorHandler.mqh       |
//|                         Error Handling Module                    |
//+------------------------------------------------------------------+
#ifndef AIME_ERROR_HANDLER_MQH
#define AIME_ERROR_HANDLER_MQH

//+------------------------------------------------------------------+
//| Handle Trade Error                                              |
//+------------------------------------------------------------------+
void HandleTradeError(int error, string context)
{
   LastError = error;
   ErrorCount++;
   LastErrorTime = TimeCurrent();
   
   string errorMessage = "";
   
   switch(error)
   {
      case ERR_NO_ERROR:
         return;
         
      case ERR_TRADE_CONTEXT_BUSY:
         errorMessage = "Trade context is busy";
         Sleep(100);
         break;
         
      case ERR_REQUOTE:
         errorMessage = "Requote received";
         break;
         
      case ERR_INVALID_STOPS:
         errorMessage = "Invalid stop levels";
         break;
         
      case ERR_TRADE_NOT_ALLOWED:
         errorMessage = "Trading not allowed";
         TradingAllowed = false;
         break;
         
      case ERR_NOT_ENOUGH_MONEY:
         errorMessage = "Not enough money";
         TradingAllowed = false;
         break;
         
      default:
         errorMessage = "Unknown error: " + IntegerToString(error);
         break;
   }
   
   Print("Trade Error in ", context, ": ", errorMessage, " (", error, ")");
   
   // Check if recovery needed
   if(ErrorCount > 10)
   {
      RecoveryMode = true;
      TradingAllowed = false;
      Print("ERROR: Too many errors - Entering Recovery Mode");
   }
}

//+------------------------------------------------------------------+
//| Log Trade Execution                                             |
//+------------------------------------------------------------------+
void LogTradeExecution(ulong ticket, ENUM_ORDER_TYPE orderType, double volume,
                       double price, double sl, double tp, string comment)
{
   // Create log entry
   string logEntry = StringFormat(
      "%s | TRADE | Ticket: %d | Type: %s | Volume: %.2f | Price: %.5f | SL: %.5f | TP: %.5f | %s",
      TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS),
      ticket,
      EnumToString(orderType),
      volume, price, sl, tp,
      comment
   );
   
   // Write to file
   int fileHandle = FileOpen("AIME_TradeLog.csv", FILE_WRITE | FILE_READ | FILE_CSV | FILE_ANSI, ",");
   if(fileHandle != INVALID_HANDLE)
   {
      FileSeek(fileHandle, 0, SEEK_END);
      FileWrite(fileHandle, logEntry);
      FileClose(fileHandle);
   }
   
   // Also print to journal
   Print(logEntry);
}

#endif // AIME_ERROR_HANDLER_MQH

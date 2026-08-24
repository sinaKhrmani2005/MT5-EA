
//+------------------------------------------------------------------+
//|                 XAU M5 Smart Entry EA                            |
//|                 EMA20 + EMA50 + RSI14 + MACD                    |
//+------------------------------------------------------------------+
#property strict
#property version   "1.00"
#property description "XAU M5 Smart Entry - checks every new M5 candle"

#include <Trade/Trade.mqh>

CTrade trade;

//====================== تنظیمات اصلی ==============================

input double LotSize            = 0.01;

input int    StopLossPoints     = 300;
input int    TakeProfitPoints   = 600;

input int    FastEMA             = 20;
input int    SlowEMA             = 50;

input int    RSIPeriod           = 14;

input int    MACDFast            = 12;
input int    MACDSlow            = 26;
input int    MACDSignal          = 9;

input double RSI_Buy_Level       = 50.0;
input double RSI_Sell_Level      = 50.0;

input ulong  MagicNumber         = 2026082401;

//====================== اندیکاتورها ================================

int hEMA20 = INVALID_HANDLE;
int hEMA50 = INVALID_HANDLE;
int hRSI   = INVALID_HANDLE;
int hMACD  = INVALID_HANDLE;

// آخرین کندل بررسی‌شده
datetime LastBarTime = 0;


//+------------------------------------------------------------------+
//| شروع ربات                                                        |
//+------------------------------------------------------------------+
int OnInit()
{
   // شماره اختصاصی معاملات این ربات
   trade.SetExpertMagicNumber(MagicNumber);

   // حداکثر انحراف قیمت
   trade.SetDeviationInPoints(30);

   // EMA20
   hEMA20 = iMA(
      _Symbol,
      PERIOD_M5,
      FastEMA,
      0,
      MODE_EMA,
      PRICE_CLOSE
   );

   // EMA50
   hEMA50 = iMA(
      _Symbol,
      PERIOD_M5,
      SlowEMA,
      0,
      MODE_EMA,
      PRICE_CLOSE
   );

   // RSI14
   hRSI = iRSI(
      _Symbol,
      PERIOD_M5,
      RSIPeriod,
      PRICE_CLOSE
   );

   // MACD
   hMACD = iMACD(
      _Symbol,
      PERIOD_M5,
      MACDFast,
      MACDSlow,
      MACDSignal,
      PRICE_CLOSE
   );

   // بررسی ساخته‌شدن اندیکاتورها
   if(
      hEMA20 == INVALID_HANDLE ||
      hEMA50 == INVALID_HANDLE ||
      hRSI   == INVALID_HANDLE ||
      hMACD  == INVALID_HANDLE
   )
   {
      Print("ERROR | Indicator handles could not be created");
      return(INIT_FAILED);
   }

   Print("================================================");
   Print("XAU M5 Smart Entry INITIALIZED");
   Print("Symbol: ", _Symbol);
   Print("Timeframe: M5");
   Print("Check: Every NEW candle");
   Print("Lot: ", LotSize);
   Print("SL Points: ", StopLossPoints);
   Print("TP Points: ", TakeProfitPoints);
   Print("Magic Number: ", MagicNumber);
   Print("================================================");

   return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//| توقف ربات                                                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(hEMA20 != INVALID_HANDLE)
      IndicatorRelease(hEMA20);

   if(hEMA50 != INVALID_HANDLE)
      IndicatorRelease(hEMA50);

   if(hRSI != INVALID_HANDLE)
      IndicatorRelease(hRSI);

   if(hMACD != INVALID_HANDLE)
      IndicatorRelease(hMACD);

   Print("XAU M5 Smart Entry STOPPED");
}


//+------------------------------------------------------------------+
//| بررسی کندل جدید                                                  |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime CurrentBarTime = iTime(
      _Symbol,
      PERIOD_M5,
      0
   );

   if(CurrentBarTime <= 0)
      return(false);

   // اگر کندل جدید تشکیل شده
   if(CurrentBarTime != LastBarTime)
   {
      LastBarTime = CurrentBarTime;

      return(true);
   }

   return(false);
}


//+------------------------------------------------------------------+
//| تابع اصلی                                                        |
//+------------------------------------------------------------------+
void OnTick()
{
   // فقط با تشکیل کندل جدید بررسی کن
   if(!IsNewBar())
      return;

   CheckSignal();
}


//+------------------------------------------------------------------+
//| بررسی شرایط معامله                                               |
//+------------------------------------------------------------------+
void CheckSignal()
{
   double EMA20Buffer[3];
   double EMA50Buffer[3];

   double RSIBuffer[3];

   double MACDMainBuffer[3];
   double MACDSignalBuffer[3];

   ArraySetAsSeries(EMA20Buffer,true);
   ArraySetAsSeries(EMA50Buffer,true);

   ArraySetAsSeries(RSIBuffer,true);

   ArraySetAsSeries(MACDMainBuffer,true);
   ArraySetAsSeries(MACDSignalBuffer,true);


   //================ EMA20 =========================================

   if(
      CopyBuffer(
         hEMA20,
         0,
         0,
         3,
         EMA20Buffer
      ) < 3
   )
   {
      Print("NO TRADE | EMA20 data unavailable");
      return;
   }


   //================ EMA50 =========================================

   if(
      CopyBuffer(
         hEMA50,
         0,
         0,
         3,
         EMA50Buffer
      ) < 3
   )
   {
      Print("NO TRADE | EMA50 data unavailable");
      return;
   }


   //================ RSI ===========================================

   if(
      CopyBuffer(
         hRSI,
         0,
         0,
         3,
         RSIBuffer
      ) < 3
   )
   {
      Print("NO TRADE | RSI data unavailable");
      return;
   }


   //================ MACD Main =====================================

   if(
      CopyBuffer(
         hMACD,
         0,
         0,
         3,
         MACDMainBuffer
      ) < 3
   )
   {
      Print("NO TRADE | MACD main data unavailable");
      return;
   }


   //================ MACD Signal ===================================

   if(
      CopyBuffer(
         hMACD,
         1,
         0,
         3,
         MACDSignalBuffer
      ) < 3
   )
   {
      Print("NO TRADE | MACD signal data unavailable");
      return;
   }


   //===============================================================
   // از کندل بسته‌شده قبلی استفاده می‌کنیم
   //===============================================================

   double ClosePrice = iClose(
      _Symbol,
      PERIOD_M5,
      1
   );

   double EMA20 = EMA20Buffer[1];
   double EMA50 = EMA50Buffer[1];

   double RSI = RSIBuffer[1];

   double MACDMain   = MACDMainBuffer[1];
   double MACDSignal = MACDSignalBuffer[1];


   //===============================================================
   // گزارش کامل در Experts
   //===============================================================

   Print(
      "CHECK | ",
      "Close=",
      DoubleToString(ClosePrice,_Digits),

      " | EMA20=",
      DoubleToString(EMA20,_Digits),

      " | EMA50=",
      DoubleToString(EMA50,_Digits),

      " | RSI=",
      DoubleToString(RSI,2),

      " | MACD=",
      DoubleToString(MACDMain,6),

      " | Signal=",
      DoubleToString(MACDSignal,6)
   );


   //===============================================================
   // شرایط BUY
   //===============================================================

   bool BuyCondition =
      (EMA20 > EMA50) &&
      (RSI > RSI_Buy_Level) &&
      (MACDMain > MACDSignal);


   //===============================================================
   // شرایط SELL
   //===============================================================

   bool SellCondition =
      (EMA20 < EMA50) &&
      (RSI < RSI_Sell_Level) &&
      (MACDMain < MACDSignal);


   //===============================================================
   // BUY
   //===============================================================

   if(BuyCondition)
   {
      Print(
         "BUY SIGNAL | EMA bullish + RSI bullish + MACD bullish"
      );

      OpenBuy();

      return;
   }


   //===============================================================
   // SELL
   //===============================================================

   if(SellCondition)
   {
      Print(
         "SELL SIGNAL | EMA bearish + RSI bearish + MACD bearish"
      );

      OpenSell();

      return;
   }


   //===============================================================
   // بدون سیگنال
   //===============================================================

   string Reason = "";

   if(EMA20 > EMA50)
      Reason += "EMA bullish; ";

   else if(EMA20 < EMA50)
      Reason += "EMA bearish; ";

   else
      Reason += "EMA equal; ";


   if(RSI > 50)
      Reason += "RSI above 50; ";

   else
      Reason += "RSI below 50; ";


   if(MACDMain > MACDSignal)
      Reason += "MACD bullish; ";

   else
      Reason += "MACD bearish; ";


   Print(
      "NO BUY/SELL | reason: ",
      Reason
   );
}


//+------------------------------------------------------------------+
//| باز کردن BUY                                                     |
//+------------------------------------------------------------------+
void OpenBuy()
{
   double AskPrice = SymbolInfoDouble(
      _Symbol,
      SYMBOL_ASK
   );

   if(AskPrice <= 0)
   {
      Print("BUY FAILED | Ask price unavailable");
      return;
   }


   // محاسبه SL
   double SL =
      AskPrice -
      (StopLossPoints * _Point);


   // محاسبه TP
   double TP =
      AskPrice +
      (TakeProfitPoints * _Point);


   SL = NormalizeDouble(
      SL,
      _Digits
   );

   TP = NormalizeDouble(
      TP,
      _Digits
   );


   // ارسال BUY
   bool Result = trade.Buy(
      LotSize,
      _Symbol,
      0,
      SL,
      TP,
      "XAU M5 Smart Entry BUY"
   );


   if(Result)
   {
      Print(
         "BUY OPENED | ",
         "Lot=",
         LotSize,

         " | Entry=",
         DoubleToString(
            AskPrice,
            _Digits
         ),

         " | SL=",
         DoubleToString(
            SL,
            _Digits
         ),

         " | TP=",
         DoubleToString(
            TP,
            _Digits
         )
      );
   }
   else
   {
      Print(
         "BUY FAILED | Retcode=",
         trade.ResultRetcode(),

         " | ",
         trade.ResultRetcodeDescription()
      );
   }
}


//+------------------------------------------------------------------+
//| باز کردن SELL                                                    |
//+------------------------------------------------------------------+
void OpenSell()
{
   double BidPrice = SymbolInfoDouble(
      _Symbol,
      SYMBOL_BID
   );

   if(BidPrice <= 0)
   {
      Print("SELL FAILED | Bid price unavailable");
      return;
   }


   // محاسبه SL
   double SL =
      BidPrice +
      (StopLossPoints * _Point);


   // محاسبه TP
   double TP =
      BidPrice -
      (TakeProfitPoints * _Point);


   SL = NormalizeDouble(
      SL,
      _Digits
   );

   TP = NormalizeDouble(
      TP,
      _Digits
   );


   // ارسال SELL
   bool Result = trade.Sell(
      LotSize,
      _Symbol,
      0,
      SL,
      TP,
      "XAU M5 Smart Entry SELL"
   );


   if(Result)
   {
      Print(
         "SELL OPENED | ",
         "Lot=",
         LotSize,

         " | Entry=",
         DoubleToString(
            BidPrice,
            _Digits
         ),

         " | SL=",
         DoubleToString(
            SL,
            _Digits
         ),

         " | TP=",
         DoubleToString(
            TP,
            _Digits
         )
      );
   }
   else
   {
      Print(
         "SELL FAILED | Retcode=",
         trade.ResultRetcode(),

         " | ",
         trade.ResultRetcodeDescription()
      );
   }
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| XAUUSD SIGNAL ONLY                                               |
//| ENTRY -> SLL -> TP                                               |
//| NO AUTOMATIC TRADING                                             |
//+------------------------------------------------------------------+
#property strict
#property version "3.00"

input int EMA_Fast_Period = 20;
input int EMA_Slow_Period = 50;
input int RSI_Period      = 14;

input double RSI_Buy_Min  = 52.0;
input double RSI_Sell_Max = 48.0;

int EMA_Fast_Handle = INVALID_HANDLE;
int EMA_Slow_Handle = INVALID_HANDLE;
int RSI_Handle      = INVALID_HANDLE;

datetime LastBarTime = 0;

int State = 0;
// 0 = waiting for ENTRY
// 1 = BUY active
// 2 = SELL active
// 3 = waiting after SLL

bool EntryShown = false;
bool SLLShown   = false;
bool TPShown    = false;


//+------------------------------------------------------------------+
//| Draw text                                                        |
//+------------------------------------------------------------------+
void DrawSignal(string text, datetime t, double price, string id)
{
   string name = "SIGNAL_ONLY_" + id + "_" + IntegerToString((int)t);

   if(ObjectFind(0,name) >= 0)
      return;

   if(!ObjectCreate(0,name,OBJ_TEXT,0,t,price))
      return;

   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,11);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,false);
}


//+------------------------------------------------------------------+
//| Get indicator values                                             |
//+------------------------------------------------------------------+
bool GetValues(
   int shift,
   double &fast,
   double &slow,
   double &rsi)
{
   double a[1];
   double b[1];
   double c[1];

   if(CopyBuffer(EMA_Fast_Handle,0,shift,1,a) != 1)
      return false;

   if(CopyBuffer(EMA_Slow_Handle,0,shift,1,b) != 1)
      return false;

   if(CopyBuffer(RSI_Handle,0,shift,1,c) != 1)
      return false;

   fast = a[0];
   slow = b[0];
   rsi  = c[0];

   return true;
}


//+------------------------------------------------------------------+
//| Check BUY/SELL entry                                             |
//+------------------------------------------------------------------+
void CheckEntry()
{
   double fast;
   double slow;
   double rsi;

   if(!GetValues(1,fast,slow,rsi))
      return;

   double close1 = iClose(_Symbol,_Period,1);
   double open1  = iOpen(_Symbol,_Period,1);

   bool bullishCandle = close1 > open1;
   bool bearishCandle = close1 < open1;

   bool buy =
      fast > slow &&
      close1 > fast &&
      rsi >= RSI_Buy_Min &&
      bullishCandle;

   bool sell =
      fast < slow &&
      close1 < fast &&
      rsi <= RSI_Sell_Max &&
      bearishCandle;


   if(buy)
   {
      State = 1;
      EntryShown = true;
      SLLShown = false;
      TPShown = false;

      double price =
         iLow(_Symbol,_Period,1) - 30*_Point;

      DrawSignal(
         "BUY ENTRY",
         iTime(_Symbol,_Period,1),
         price,
         "BUY_ENTRY"
      );

      return;
   }


   if(sell)
   {
      State = 2;
      EntryShown = true;
      SLLShown = false;
      TPShown = false;

      double price =
         iHigh(_Symbol,_Period,1) + 30*_Point;

      DrawSignal(
         "SELL ENTRY",
         iTime(_Symbol,_Period,1),
         price,
         "SELL_ENTRY"
      );
   }
}


//+------------------------------------------------------------------+
//| Check active BUY                                                 |
//+------------------------------------------------------------------+
void CheckBuy()
{
   double fast;
   double slow;
   double rsi;

   if(!GetValues(1,fast,slow,rsi))
      return;

   double close1 = iClose(_Symbol,_Period,1);
   double open1  = iOpen(_Symbol,_Period,1);

   bool bearish =
      close1 < open1;

   bool trendBroken =
      close1 < fast;

   bool weakRSI =
      rsi < 50.0;


   // SLL condition
   if(!SLLShown &&
      bearish &&
      trendBroken &&
      weakRSI)
   {
      double price =
         iHigh(_Symbol,_Period,1) + 50*_Point;

      DrawSignal(
         "SLL BAZ",
         iTime(_Symbol,_Period,1),
         price,
         "BUY_SLL"
      );

      SLLShown = true;

      // بعد از SLL دیگر TP همان ورود را نمی‌دهیم
      State = 3;

      return;
   }


   // TP condition
   bool strongMove =
      close1 > fast &&
      fast > slow &&
      rsi >= 60.0 &&
      bullishCandle();

   if(!TPShown && strongMove)
   {
      double price =
         iHigh(_Symbol,_Period,1) + 50*_Point;

      DrawSignal(
         "TP BAZ",
         iTime(_Symbol,_Period,1),
         price,
         "BUY_TP"
      );

      TPShown = true;
      State = 0;
   }
}


//+------------------------------------------------------------------+
//| Check active SELL                                                |
//+------------------------------------------------------------------+
void CheckSell()
{
   double fast;
   double slow;
   double rsi;

   if(!GetValues(1,fast,slow,rsi))
      return;

   double close1 = iClose(_Symbol,_Period,1);
   double open1  = iOpen(_Symbol,_Period,1);

   bool bullish =
      close1 > open1;

   bool trendBroken =
      close1 > fast;

   bool weakRSI =
      rsi > 50.0;


   // SLL condition
   if(!SLLShown &&
      bullish &&
      trendBroken &&
      weakRSI)
   {
      double price =
         iLow(_Symbol,_Period,1) - 50*_Point;

      DrawSignal(
         "SLL BAZ",
         iTime(_Symbol,_Period,1),
         price,
         "SELL_SLL"
      );

      SLLShown = true;

      State = 3;

      return;
   }


   // TP condition
   bool strongMove =
      close1 < fast &&
      fast < slow &&
      rsi <= 40.0 &&
      bearishCandle();

   if(!TPShown && strongMove)
   {
      double price =
         iLow(_Symbol,_Period,1) - 50*_Point;

      DrawSignal(
         "TP BAZ",
         iTime(_Symbol,_Period,1),
         price,
         "SELL_TP"
      );

      TPShown = true;
      State = 0;
   }
}


//+------------------------------------------------------------------+
//| Candle helpers                                                   |
//+------------------------------------------------------------------+
bool bullishCandle()
{
   return iClose(_Symbol,_Period,1) >
          iOpen(_Symbol,_Period,1);
}


bool bearishCandle()
{
   return iClose(_Symbol,_Period,1) <
          iOpen(_Symbol,_Period,1);
}


//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   EMA_Fast_Handle =
      iMA(
         _Symbol,
         _Period,
         EMA_Fast_Period,
         0,
         MODE_EMA,
         PRICE_CLOSE
      );

   EMA_Slow_Handle =
      iMA(
         _Symbol,
         _Period,
         EMA_Slow_Period,
         0,
         MODE_EMA,
         PRICE_CLOSE
      );

   RSI_Handle =
      iRSI(
         _Symbol,
         _Period,
         RSI_Period,
         PRICE_CLOSE
      );


   if(EMA_Fast_Handle == INVALID_HANDLE)
      return INIT_FAILED;

   if(EMA_Slow_Handle == INVALID_HANDLE)
      return INIT_FAILED;

   if(RSI_Handle == INVALID_HANDLE)
      return INIT_FAILED;


   LastBarTime =
      iTime(_Symbol,_Period,0);


   return INIT_SUCCEEDED;
}


//+------------------------------------------------------------------+
//| Deinitialization                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(EMA_Fast_Handle != INVALID_HANDLE)
      IndicatorRelease(EMA_Fast_Handle);

   if(EMA_Slow_Handle != INVALID_HANDLE)
      IndicatorRelease(EMA_Slow_Handle);

   if(RSI_Handle != INVALID_HANDLE)
      IndicatorRelease(RSI_Handle);
}


//+------------------------------------------------------------------+
//| Main                                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   datetime currentBar =
      iTime(_Symbol,_Period,0);

   // فقط یک بار در شروع هر کندل جدید
   if(currentBar == LastBarTime)
      return;

   LastBarTime = currentBar;


   if(State == 0)
   {
      CheckEntry();
   }
   else if(State == 1)
   {
      CheckBuy();
   }
   else if(State == 2)
   {
      CheckSell();
   }
   else if(State == 3)
   {
      // بعد از SLL منتظر ENTRY جدید می‌ماند
      State = 0;
   }
}
//+------------------------------------------------------------------+

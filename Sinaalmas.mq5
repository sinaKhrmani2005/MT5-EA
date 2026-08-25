//+------------------------------------------------------------------+
//| XAUUSD SIGNAL ONLY - BUY / SELL / SLL / TP                     |
//| NO AUTOMATIC TRADING                                             |
//+------------------------------------------------------------------+
#property strict
#property version "4.00"

input int EMA_Fast_Period = 20;
input int EMA_Slow_Period = 50;
input int RSI_Period      = 14;

input double RSI_Buy      = 55.0;
input double RSI_Sell     = 45.0;

input int MinBarsBetweenSignals = 2;

int EMA_Fast_Handle = INVALID_HANDLE;
int EMA_Slow_Handle = INVALID_HANDLE;
int RSI_Handle      = INVALID_HANDLE;
int MACD_Handle     = INVALID_HANDLE;

datetime LastBarTime = 0;
datetime LastSignalTime = 0;

// 0 = انتظار
// 1 = BUY
// -1 = SELL
int CurrentSignal = 0;

bool SLL_Shown = false;
bool TP_Shown  = false;


//+------------------------------------------------------------------+
//| Draw text on chart                                               |
//+------------------------------------------------------------------+
void DrawSignal(string text, datetime time, double price, string id)
{
   string name =
      "SIGNAL_" +
      id +
      "_" +
      IntegerToString((int)time);

   if(ObjectFind(0,name) >= 0)
      return;

   if(!ObjectCreate(
      0,
      name,
      OBJ_TEXT,
      0,
      time,
      price))
   {
      return;
   }

   ObjectSetString(
      0,
      name,
      OBJPROP_TEXT,
      text);

   ObjectSetInteger(
      0,
      name,
      OBJPROP_FONTSIZE,
      11);

   ObjectSetInteger(
      0,
      name,
      OBJPROP_SELECTABLE,
      false);

   ObjectSetInteger(
      0,
      name,
      OBJPROP_HIDDEN,
      false);
}


//+------------------------------------------------------------------+
//| Read indicators                                                  |
//+------------------------------------------------------------------+
bool GetIndicators(
   int shift,
   double &emaFast,
   double &emaSlow,
   double &rsi,
   double &macdMain,
   double &macdSignal)
{
   double a[1];
   double b[1];
   double c[1];
   double d[1];
   double e[1];

   if(CopyBuffer(
      EMA_Fast_Handle,
      0,
      shift,
      1,
      a) != 1)
      return false;

   if(CopyBuffer(
      EMA_Slow_Handle,
      0,
      shift,
      1,
      b) != 1)
      return false;

   if(CopyBuffer(
      RSI_Handle,
      0,
      shift,
      1,
      c) != 1)
      return false;

   if(CopyBuffer(
      MACD_Handle,
      0,
      shift,
      1,
      d) != 1)
      return false;

   if(CopyBuffer(
      MACD_Handle,
      1,
      shift,
      1,
      e) != 1)
      return false;

   emaFast    = a[0];
   emaSlow    = b[0];
   rsi        = c[0];
   macdMain   = d[0];
   macdSignal = e[0];

   return true;
}


//+------------------------------------------------------------------+
//| Check whether enough time passed                                 |
//+------------------------------------------------------------------+
bool CanSignal()
{
   if(LastSignalTime == 0)
      return true;

   int shift =
      iBarShift(
         _Symbol,
         _Period,
         LastSignalTime,
         false);

   if(shift < 0)
      return true;

   return shift >= MinBarsBetweenSignals;
}


//+------------------------------------------------------------------+
//| BUY condition                                                    |
//+------------------------------------------------------------------+
bool BuyCondition()
{
   double fast;
   double slow;
   double rsi;
   double macd;
   double macdSignal;

   if(!GetIndicators(
      1,
      fast,
      slow,
      rsi,
      macd,
      macdSignal))
      return false;

   double closePrice =
      iClose(
         _Symbol,
         _Period,
         1);

   double openPrice =
      iOpen(
         _Symbol,
         _Period,
         1);

   bool candleUp =
      closePrice > openPrice;

   return
      fast > slow &&
      closePrice > fast &&
      rsi >= RSI_Buy &&
      macd > macdSignal &&
      candleUp;
}


//+------------------------------------------------------------------+
//| SELL condition                                                   |
//+------------------------------------------------------------------+
bool SellCondition()
{
   double fast;
   double slow;
   double rsi;
   double macd;
   double macdSignal;

   if(!GetIndicators(
      1,
      fast,
      slow,
      rsi,
      macd,
      macdSignal))
      return false;

   double closePrice =
      iClose(
         _Symbol,
         _Period,
         1);

   double openPrice =
      iOpen(
         _Symbol,
         _Period,
         1);

   bool candleDown =
      closePrice < openPrice;

   return
      fast < slow &&
      closePrice < fast &&
      rsi <= RSI_Sell &&
      macd < macdSignal &&
      candleDown;
}


//+------------------------------------------------------------------+
//| Create BUY entry                                                 |
//+------------------------------------------------------------------+
void CreateBuyEntry()
{
   if(!CanSignal())
      return;

   datetime t =
      iTime(
         _Symbol,
         _Period,
         1);

   double price =
      iLow(
         _Symbol,
         _Period,
         1)
      - 30 * _Point;

   DrawSignal(
      "BUY ENTRY",
      t,
      price,
      "BUY_ENTRY");

   CurrentSignal = 1;

   SLL_Shown = false;
   TP_Shown  = false;

   LastSignalTime = t;
}


//+------------------------------------------------------------------+
//| Create SELL entry                                                |
//+------------------------------------------------------------------+
void CreateSellEntry()
{
   if(!CanSignal())
      return;

   datetime t =
      iTime(
         _Symbol,
         _Period,
         1);

   double price =
      iHigh(
         _Symbol,
         _Period,
         1)
      + 30 * _Point;

   DrawSignal(
      "SELL ENTRY",
      t,
      price,
      "SELL_ENTRY");

   CurrentSignal = -1;

   SLL_Shown = false;
   TP_Shown  = false;

   LastSignalTime = t;
}


//+------------------------------------------------------------------+
//| Manage BUY                                                       |
//+------------------------------------------------------------------+
void ManageBuy()
{
   double fast;
   double slow;
   double rsi;
   double macd;
   double macdSignal;

   if(!GetIndicators(
      1,
      fast,
      slow,
      rsi,
      macd,
      macdSignal))
      return;

   double closePrice =
      iClose(
         _Symbol,
         _Period,
         1);

   double openPrice =
      iOpen(
         _Symbol,
         _Period,
         1);

   bool candleDown =
      closePrice < openPrice;

   // Strong reversal against BUY
   bool reversal =
      closePrice < fast &&
      rsi < 50.0 &&
      macd < macdSignal &&
      candleDown;

   if(!SLL_Shown && reversal)
   {
      DrawSignal(
         "SLL BAZ",
         iTime(_Symbol,_Period,1),
         iHigh(_Symbol,_Period,1) + 50*_Point,
         "BUY_SLL");

      SLL_Shown = true;

      // بعد از SLL، سیگنال قبلی تمام می‌شود
      CurrentSignal = 0;

      return;
   }


   // Strong profitable BUY condition
   bool profitCondition =
      closePrice > fast &&
      fast > slow &&
      rsi >= 60.0 &&
      macd > macdSignal;

   if(!TP_Shown && profitCondition)
   {
      // برای جلوگیری از TP بلافاصله روی اولین ENTRY،
      // فقط وقتی سیگنال از قبل فعال بوده بررسی می‌شود.
      static int buyBars = 0;

      buyBars++;

      if(buyBars >= 2)
      {
         DrawSignal(
            "TP BAZ",
            iTime(_Symbol,_Period,1),
            iHigh(_Symbol,_Period,1) + 50*_Point,
            "BUY_TP");

         TP_Shown = true;
         CurrentSignal = 0;
         buyBars = 0;
      }
   }
}


//+------------------------------------------------------------------+
//| Manage SELL                                                      |
//+------------------------------------------------------------------+
void ManageSell()
{
   double fast;
   double slow;
   double rsi;
   double macd;
   double macdSignal;

   if(!GetIndicators(
      1,
      fast,
      slow,
      rsi,
      macd,
      macdSignal))
      return;

   double closePrice =
      iClose(
         _Symbol,
         _Period,
         1);

   double openPrice =
      iOpen(
         _Symbol,
         _Period,
         1);

   bool candleUp =
      closePrice > openPrice;

   // Strong reversal against SELL
   bool reversal =
      closePrice > fast &&
      rsi > 50.0 &&
      macd > macdSignal &&
      candleUp;

   if(!SLL_Shown && reversal)
   {
      DrawSignal(
         "SLL BAZ",
         iTime(_Symbol,_Period,1),
         iLow(_Symbol,_Period,1) - 50*_Point,
         "SELL_SLL");

      SLL_Shown = true;

      CurrentSignal = 0;

      return;
   }


   // Strong profitable SELL condition
   bool profitCondition =
      closePrice < fast &&
      fast < slow &&
      rsi <= 40.0 &&
      macd < macdSignal;

   if(!TP_Shown && profitCondition)
   {
      static int sellBars = 0;

      sellBars++;

      if(sellBars >= 2)
      {
         DrawSignal(
            "TP BAZ",
            iTime(_Symbol,_Period,1),
            iLow(_Symbol,_Period,1) - 50*_Point,
            "SELL_TP");

         TP_Shown = true;
         CurrentSignal = 0;
         sellBars = 0;
      }
   }
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
         PRICE_CLOSE);

   EMA_Slow_Handle =
      iMA(
         _Symbol,
         _Period,
         EMA_Slow_Period,
         0,
         MODE_EMA,
         PRICE_CLOSE);

   RSI_Handle =
      iRSI(
         _Symbol,
         _Period,
         RSI_Period,
         PRICE_CLOSE);

   MACD_Handle =
      iMACD(
         _Symbol,
         _Period,
         12,
         26,
         9,
         PRICE_CLOSE);


   if(EMA_Fast_Handle == INVALID_HANDLE)
      return INIT_FAILED;

   if(EMA_Slow_Handle == INVALID_HANDLE)
      return INIT_FAILED;

   if(RSI_Handle == INVALID_HANDLE)
      return INIT_FAILED;

   if(MACD_Handle == INVALID_HANDLE)
      return INIT_FAILED;


   LastBarTime =
      iTime(
         _Symbol,
         _Period,
         0);

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

   if(MACD_Handle != INVALID_HANDLE)
      IndicatorRelease(MACD_Handle);
}


//+------------------------------------------------------------------+
//| Main                                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   datetime currentBar =
      iTime(
         _Symbol,
         _Period,
         0);

   // فقط یک بار در هر کندل جدید
   if(currentBar == LastBarTime)
      return;

   LastBarTime = currentBar;


   //==============================================================
   // وقتی هیچ سیگنالی نداریم
   //==============================================================
   if(CurrentSignal == 0)
   {
      bool buy = BuyCondition();
      bool sell = SellCondition();

      if(buy && !sell)
      {
         CreateBuyEntry();
         return;
      }

      if(sell && !buy)
      {
         CreateSellEntry();
         return;
      }
   }


   //==============================================================
   // BUY فعال
   //==============================================================
   if(CurrentSignal == 1)
   {
      // اگر بازار واقعاً SELL شد، اول SLL
      if(SellCondition())
      {
         if(!SLL_Shown)
         {
            DrawSignal(
               "SLL BAZ",
               iTime(_Symbol,_Period,1),
               iHigh(_Symbol,_Period,1) + 50*_Point,
               "BUY_SLL_REVERSAL");

            SLL_Shown = true;
         }

         CurrentSignal = 0;
         return;
      }

      ManageBuy();
      return;
   }


   //==============================================================
   // SELL فعال
   //==============================================================
   if(CurrentSignal == -1)
   {
      // اگر بازار واقعاً BUY شد، اول SLL
      if(BuyCondition())
      {
         if(!SLL_Shown)
         {
            DrawSignal(
               "SLL BAZ",
               iTime(_Symbol,_Period,1),
               iLow(_Symbol,_Period,1) - 50*_Point,
               "SELL_SLL_REVERSAL");

            SLL_Shown = true;
         }

         CurrentSignal = 0;
         return;
      }

      ManageSell();
      return;
   }
}
//+------------------------------------------------------------------+

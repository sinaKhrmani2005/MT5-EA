//+------------------------------------------------------------------+
//| GAINZALGO_STYLE_XAUUSD.mq5                                      |
//| Visual BUY / SELL + TP / SL                                     |
//| NO AUTOMATIC TRADING                                             |
//+------------------------------------------------------------------+
#property strict
#property indicator_chart_window
#property indicator_plots 0
#property version "1.00"

input ENUM_TIMEFRAMES SignalTF = PERIOD_CURRENT;

input int EMA_Fast = 20;
input int EMA_Slow = 50;
input int RSI_Period = 14;

input int MACD_Fast = 12;
input int MACD_Slow = 26;
input int MACD_Signal = 9;

input int ATR_Period = 14;

input double RSI_Buy_Min = 55.0;
input double RSI_Sell_Max = 45.0;

input double TP_ATR_Multiplier = 2.0;
input double SL_ATR_Multiplier = 1.5;

input int MinimumBarsBetweenSignals = 5;
input int MaximumSignalsOnChart = 12;

input bool ShowTPSLLines = true;
input bool ShowDashboard = true;
input bool EnableAlerts = false;


int EMA_Fast_Handle = INVALID_HANDLE;
int EMA_Slow_Handle = INVALID_HANDLE;
int RSI_Handle = INVALID_HANDLE;
int MACD_Handle = INVALID_HANDLE;
int ATR_Handle = INVALID_HANDLE;

datetime LastBarTime = 0;

string Prefix = "GAINZALGO_";


//+------------------------------------------------------------------+
//| Colors                                                           |
//+------------------------------------------------------------------+

color BUY_COLOR  = clrLimeGreen;
color SELL_COLOR = clrRed;
color TEXT_COLOR = clrWhite;
color PANEL_COLOR = clrBlack;
color GOLD_COLOR = clrGold;


//+------------------------------------------------------------------+
//| Timeframe                                                        |
//+------------------------------------------------------------------+

ENUM_TIMEFRAMES GetTimeframe()
{
   if(SignalTF == PERIOD_CURRENT)
      return (ENUM_TIMEFRAMES)_Period;

   return SignalTF;
}


//+------------------------------------------------------------------+
//| Timeframe text                                                   |
//+------------------------------------------------------------------+

string GetTimeframeText()
{
   ENUM_TIMEFRAMES tf = GetTimeframe();

   if(tf == PERIOD_M1)
      return "M1";

   if(tf == PERIOD_M5)
      return "M5";

   if(tf == PERIOD_M15)
      return "M15";

   if(tf == PERIOD_M30)
      return "M30";

   if(tf == PERIOD_H1)
      return "H1";

   if(tf == PERIOD_H4)
      return "H4";

   if(tf == PERIOD_D1)
      return "D1";

   return EnumToString(tf);
}


//+------------------------------------------------------------------+
//| Delete indicator objects                                         |
//+------------------------------------------------------------------+

void DeleteObjects()
{
   int total = ObjectsTotal(0,0,-1);

   for(int i=total-1; i>=0; i--)
   {
      string name = ObjectName(0,i,0,-1);

      if(StringFind(name,Prefix) == 0)
         ObjectDelete(0,name);
   }
}


//+------------------------------------------------------------------+
//| Create dashboard label                                           |
//+------------------------------------------------------------------+

void CreateLabel(
   string name,
   string text,
   int x,
   int y,
   int size,
   color clr)
{
   if(ObjectFind(0,name) < 0)
      ObjectCreate(0,name,OBJ_LABEL,0,0,0);

   ObjectSetInteger(
      0,
      name,
      OBJPROP_CORNER,
      CORNER_LEFT_UPPER);

   ObjectSetInteger(
      0,
      name,
      OBJPROP_XDISTANCE,
      x);

   ObjectSetInteger(
      0,
      name,
      OBJPROP_YDISTANCE,
      y);

   ObjectSetInteger(
      0,
      name,
      OBJPROP_FONTSIZE,
      size);

   ObjectSetInteger(
      0,
      name,
      OBJPROP_COLOR,
      clr);

   ObjectSetString(
      0,
      name,
      OBJPROP_FONT,
      "Arial");

   ObjectSetString(
      0,
      name,
      OBJPROP_TEXT,
      text);

   ObjectSetInteger(
      0,
      name,
      OBJPROP_SELECTABLE,
      false);

   ObjectSetInteger(
      0,
      name,
      OBJPROP_HIDDEN,
      true);
}


//+------------------------------------------------------------------+
//| Dashboard                                                        |
//+------------------------------------------------------------------+

void CreateDashboard()
{
   if(!ShowDashboard)
      return;

   string panel = Prefix+"PANEL";

   if(ObjectFind(0,panel) < 0)
      ObjectCreate(
         0,
         panel,
         OBJ_RECTANGLE_LABEL,
         0,
         0,
         0);

   ObjectSetInteger(
      0,
      panel,
      OBJPROP_CORNER,
      CORNER_LEFT_UPPER);

   ObjectSetInteger(
      0,
      panel,
      OBJPROP_XDISTANCE,
      10);

   ObjectSetInteger(
      0,
      panel,
      OBJPROP_YDISTANCE,
      20);

   ObjectSetInteger(
      0,
      panel,
      OBJPROP_XSIZE,
      255);

   ObjectSetInteger(
      0,
      panel,
      OBJPROP_YSIZE,
      135);

   ObjectSetInteger(
      0,
      panel,
      OBJPROP_BGCOLOR,
      PANEL_COLOR);

   ObjectSetInteger(
      0,
      panel,
      OBJPROP_COLOR,
      clrDimGray);

   ObjectSetInteger(
      0,
      panel,
      OBJPROP_BACK,
      true);

   ObjectSetInteger(
      0,
      panel,
      OBJPROP_SELECTABLE,
      false);

   ObjectSetInteger(
      0,
      panel,
      OBJPROP_HIDDEN,
      true);


   CreateLabel(
      Prefix+"TITLE",
      "GAINZALGO STYLE",
      22,
      28,
      13,
      BUY_COLOR);

   CreateLabel(
      Prefix+"TF",
      "TIMEFRAME: "+GetTimeframeText(),
      22,
      52,
      10,
      TEXT_COLOR);

   CreateLabel(
      Prefix+"TREND",
      "TREND: SCANNING",
      22,
      72,
      10,
      TEXT_COLOR);

   CreateLabel(
      Prefix+"STRENGTH",
      "SIGNAL: WAITING",
      22,
      92,
      10,
      TEXT_COLOR);

   CreateLabel(
      Prefix+"STATUS",
      "STATUS: SCANNING...",
      22,
      112,
      10,
      BUY_COLOR);

   CreateLabel(
      Prefix+"NOTE",
      "SIGNALS ONLY - NO AUTO TRADING",
      22,
      130,
      8,
      GOLD_COLOR);
}


//+------------------------------------------------------------------+
//| Update dashboard                                                 |
//+------------------------------------------------------------------+

void UpdateDashboard(
   string trend,
   string strength,
   string status,
   color clr)
{
   if(!ShowDashboard)
      return;

   CreateDashboard();

   ObjectSetString(
      0,
      Prefix+"TF",
      OBJPROP_TEXT,
      "TIMEFRAME: "+GetTimeframeText());

   ObjectSetString(
      0,
      Prefix+"TREND",
      OBJPROP_TEXT,
      "TREND: "+trend);

   ObjectSetString(
      0,
      Prefix+"STRENGTH",
      OBJPROP_TEXT,
      "SIGNAL: "+strength);

   ObjectSetString(
      0,
      Prefix+"STATUS",
      OBJPROP_TEXT,
      "STATUS: "+status);

   ObjectSetInteger(
      0,
      Prefix+"TREND",
      OBJPROP_COLOR,
      clr);

   ObjectSetInteger(
      0,
      Prefix+"STATUS",
      OBJPROP_COLOR,
      clr);
}


//+------------------------------------------------------------------+
//| Read indicators                                                  |
//+------------------------------------------------------------------+

bool ReadIndicators(
   int shift,
   double &fast,
   double &slow,
   double &rsi,
   double &macdMain,
   double &macdSignal,
   double &atr)
{
   double a[1];
   double b[1];
   double c[1];
   double d[1];
   double e[1];
   double f[1];


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


   if(CopyBuffer(
      ATR_Handle,
      0,
      shift,
      1,
      f) != 1)
      return false;


   fast = a[0];
   slow = b[0];
   rsi = c[0];

   macdMain = d[0];
   macdSignal = e[0];

   atr = f[0];


   if(atr <= 0)
      return false;


   return true;
}


//+------------------------------------------------------------------+
//| BUY condition                                                    |
//+------------------------------------------------------------------+

bool BuySignal(
   int shift,
   double &atr)
{
   double fast;
   double slow;
   double rsi;
   double macd;
   double macdSignal;


   if(!ReadIndicators(
      shift,
      fast,
      slow,
      rsi,
      macd,
      macdSignal,
      atr))
      return false;


   double closePrice =
      iClose(
         _Symbol,
         GetTimeframe(),
         shift);


   double openPrice =
      iOpen(
         _Symbol,
         GetTimeframe(),
         shift);


   bool bullishCandle =
      closePrice > openPrice;


   return
      fast > slow &&
      closePrice > fast &&
      rsi >= RSI_Buy_Min &&
      macd > macdSignal &&
      bullishCandle;
}


//+------------------------------------------------------------------+
//| SELL condition                                                   |
//+------------------------------------------------------------------+

bool SellSignal(
   int shift,
   double &atr)
{
   double fast;
   double slow;
   double rsi;
   double macd;
   double macdSignal;


   if(!ReadIndicators(
      shift,
      fast,
      slow,
      rsi,
      macd,
      macdSignal,
      atr))
      return false;


   double closePrice =
      iClose(
         _Symbol,
         GetTimeframe(),
         shift);


   double openPrice =
      iOpen(
         _Symbol,
         GetTimeframe(),
         shift);


   bool bearishCandle =
      closePrice < openPrice;


   return
      fast < slow &&
      closePrice < fast &&
      rsi <= RSI_Sell_Max &&
      macd < macdSignal &&
      bearishCandle;
}


//+------------------------------------------------------------------+
//| Signal strength                                                  |
//+------------------------------------------------------------------+

int SignalStrength(
   bool buy,
   int shift)
{
   double fast;
   double slow;
   double rsi;
   double macd;
   double macdSignal;
   double atr;


   if(!ReadIndicators(
      shift,
      fast,
      slow,
      rsi,
      macd,
      macdSignal,
      atr))
      return 0;


   int score = 0;


   double closePrice =
      iClose(
         _Symbol,
         GetTimeframe(),
         shift);


   if(buy)
   {
      if(fast > slow)
         score += 25;

      if(closePrice > fast)
         score += 25;

      if(rsi >= RSI_Buy_Min)
         score += 25;

      if(macd > macdSignal)
         score += 25;
   }
   else
   {
      if(fast < slow)
         score += 25;

      if(closePrice < fast)
         score += 25;

      if(rsi <= RSI_Sell_Max)
         score += 25;

      if(macd < macdSignal)
         score += 25;
   }


   return score;
}


//+------------------------------------------------------------------+
//| Draw signal                                                      |
//+------------------------------------------------------------------+

void DrawSignal(
   datetime signalTime,
   double highPrice,
   double lowPrice,
   double closePrice,
   bool buy,
   double atr)
{
   string side;

   if(buy)
      side = "BUY";
   else
      side = "SELL";


   color signalColor;

   if(buy)
      signalColor = BUY_COLOR;
   else
      signalColor = SELL_COLOR;


   double tp;
   double sl;


   if(buy)
   {
      tp =
         closePrice +
         atr * TP_ATR_Multiplier;

      sl =
         closePrice -
         atr * SL_ATR_Multiplier;
   }
   else
   {
      tp =
         closePrice -
         atr * TP_ATR_Multiplier;

      sl =
         closePrice +
         atr * SL_ATR_Multiplier;
   }


   string id =
      Prefix+
      side+
      "_"+
      IntegerToString((int)signalTime);


   //===============================================================
   // BUY / SELL text
   //===============================================================

   string textName =
      id+"_TEXT";


   double textPrice;


   if(buy)
      textPrice =
         lowPrice -
         atr * 0.35;
   else
      textPrice =
         highPrice +
         atr * 0.35;


   if(ObjectCreate(
      0,
      textName,
      OBJ_TEXT,
      0,
      signalTime,
      textPrice))
   {
      ObjectSetString(
         0,
         textName,
         OBJPROP_TEXT,
         side);

      ObjectSetInteger(
         0,
         textName,
         OBJPROP_COLOR,
         signalColor);

      ObjectSetInteger(
         0,
         textName,
         OBJPROP_FONTSIZE,
         14);

      ObjectSetString(
         0,
         textName,
         OBJPROP_FONT,
         "Arial");

      ObjectSetInteger(
         0,
         textName,
         OBJPROP_SELECTABLE,
         false);

      ObjectSetInteger(
         0,
         textName,
         OBJPROP_HIDDEN,
         true);
   }


   //===============================================================
   // Arrow
   //===============================================================

   string arrowName =
      id+"_ARROW";


   double arrowPrice;


   if(buy)
      arrowPrice =
         lowPrice -
         atr * 0.12;
   else
      arrowPrice =
         highPrice +
         atr * 0.12;


   if(ObjectCreate(
      0,
      arrowName,
      OBJ_ARROW,
      0,
      signalTime,
      arrowPrice))
   {
      if(buy)
         ObjectSetInteger(
            0,
            arrowName,
            OBJPROP_ARROWCODE,
            233);
      else
         ObjectSetInteger(
            0,
            arrowName,
            OBJPROP_ARROWCODE,
            234);


      ObjectSetInteger(
         0,
         arrowName,
         OBJPROP_COLOR,
         signalColor);

      ObjectSetInteger(
         0,
         arrowName,
         OBJPROP_WIDTH,
         2);

      ObjectSetInteger(
         0,
         arrowName,
         OBJPROP_SELECTABLE,
         false);

      ObjectSetInteger(
         0,
         arrowName,
         OBJPROP_HIDDEN,
         true);
   }


   //===============================================================
   // TP / SL
   //===============================================================

   if(!ShowTPSLLines)
      return;


   int seconds =
      PeriodSeconds(GetTimeframe());


   if(seconds <= 0)
      seconds = 900;


   datetime endTime =
      signalTime +
      (datetime)(seconds * 4);


   string tpName =
      id+"_TP";


   string slName =
      id+"_SL";


   // TP line
   if(ObjectCreate(
      0,
      tpName,
      OBJ_TREND,
      0,
      signalTime,
      tp,
      endTime,
      tp))
   {
      ObjectSetInteger(
         0,
         tpName,
         OBJPROP_COLOR,
         BUY_COLOR);

      ObjectSetInteger(
         0,
         tpName,
         OBJPROP_STYLE,
         STYLE_DASH);

      ObjectSetInteger(
         0,
         tpName,
         OBJPROP_WIDTH,
         1);

      ObjectSetInteger(
         0,
         tpName,
         OBJPROP_RAY_RIGHT,
         false);

      ObjectSetInteger(
         0,
         tpName,
         OBJPROP_SELECTABLE,
         false);

      ObjectSetInteger(
         0,
         tpName,
         OBJPROP_HIDDEN,
         true);
   }


   // SL line
   if(ObjectCreate(
      0,
      slName,
      OBJ_TREND,
      0,
      signalTime,
      sl,
      endTime,
      sl))
   {
      ObjectSetInteger(
         0,
         slName,
         OBJPROP_COLOR,
         SELL_COLOR);

      ObjectSetInteger(
         0,
         slName,
         OBJPROP_STYLE,
         STYLE_DASH);

      ObjectSetInteger(
         0,
         slName,
         OBJPROP_WIDTH,
         1);

      ObjectSetInteger(
         0,
         slName,
         OBJPROP_RAY_RIGHT,
         false);

      ObjectSetInteger(
         0,
         slName,
         OBJPROP_SELECTABLE,
         false);

      ObjectSetInteger(
         0,
         slName,
         OBJPROP_HIDDEN,
         true);
   }


   // TP / SL text
   string infoName =
      id+"_INFO";


   double infoPrice;


   if(buy)
      infoPrice =
         lowPrice -
         atr * 0.65;
   else
      infoPrice =
         highPrice +
         atr * 0.65;


   if(ObjectCreate(
      0,
      infoName,
      OBJ_TEXT,
      0,
      signalTime,
      infoPrice))
   {
      string infoText =
         "TP: "+
         DoubleToString(tp,_Digits)+
         "\nSL: "+
         DoubleToString(sl,_Digits);


      ObjectSetString(
         0,
         infoName,
         OBJPROP_TEXT,
         infoText);

      ObjectSetInteger(
         0,
         infoName,
         OBJPROP_COLOR,
         GOLD_COLOR);

      ObjectSetInteger(
         0,
         infoName,
         OBJPROP_FONTSIZE,
         9);

      ObjectSetString(
         0,
         infoName,
         OBJPROP_FONT,
         "Arial");

      ObjectSetInteger(
         0,
         infoName,
         OBJPROP_SELECTABLE,
         false);

      ObjectSetInteger(
         0,
         infoName,
         OBJPROP_HIDDEN,
         true);
   }
}


//+------------------------------------------------------------------+
//| Scan chart                                                       |
//+------------------------------------------------------------------+

void ScanChart()
{
   DeleteObjects();


   if(ShowDashboard)
      CreateDashboard();


   int bars =
      Bars(
         _Symbol,
         GetTimeframe());


   if(bars <
      EMA_Slow+
      ATR_Period+
      20)
      return;


   int found = 0;

   int lastSignalShift =
      bars + 100;


   for(
      int shift=1;
      shift<bars-2 &&
      found<MaximumSignalsOnChart;
      shift++)
   {
      double atr = 0.0;


      bool buy =
         BuySignal(
            shift,
            atr);


      bool sell =
         SellSignal(
            shift,
            atr);


      if(!buy && !sell)
         continue;


      if(
         lastSignalShift <
         bars+50 &&
         (lastSignalShift-shift) <
         MinimumBarsBetweenSignals)
      {
         continue;
      }


      datetime signalTime =
         iTime(
            _Symbol,
            GetTimeframe(),
            shift);


      double highPrice =
         iHigh(
            _Symbol,
            GetTimeframe(),
            shift);


      double lowPrice =
         iLow(
            _Symbol,
            GetTimeframe(),
            shift);


      double closePrice =
         iClose(
            _Symbol,
            GetTimeframe(),
            shift);


      DrawSignal(
         signalTime,
         highPrice,
         lowPrice,
         closePrice,
         buy,
         atr);


      found++;

      lastSignalShift =
         shift;


      // Latest closed candle
      if(shift == 1)
      {
         int strength =
            SignalStrength(
               buy,
               1);


         if(buy)
         {
            UpdateDashboard(
               "BULLISH",
               IntegerToString(strength)+"%",
               "BUY SIGNAL",
               BUY_COLOR);
         }
         else
         {
            UpdateDashboard(
               "BEARISH",
               IntegerToString(strength)+"%",
               "SELL SIGNAL",
               SELL_COLOR);
         }


         if(
            EnableAlerts &&
            signalTime != LastBarTime)
         {
            if(buy)
               Alert(
                  _Symbol,
                  " ",
                  GetTimeframeText(),
                  " BUY SIGNAL");
            else
               Alert(
                  _Symbol,
                  " ",
                  GetTimeframeText(),
                  " SELL SIGNAL");
         }
      }
   }


   if(found == 0)
   {
      UpdateDashboard(
         "NEUTRAL",
 

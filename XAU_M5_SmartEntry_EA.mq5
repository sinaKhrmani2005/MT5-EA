//+------------------------------------------------------------------+
//|                 XAU M5 Smart Entry EA                            |
//|                 EMA20 + EMA50 + RSI14 + MACD                    |
//+------------------------------------------------------------------+
#property strict
#property version   "1.00"
#property description "XAU M5 Smart Entry - checks every new candle"

#include <Trade/Trade.mqh>

CTrade trade;

//--- Inputs
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

//--- Indicator handles
int hEMA20 = INVALID_HANDLE;
int hEMA50 = INVALID_HANDLE;
int hRSI   = INVALID_HANDLE;
int hMACD  = INVALID_HANDLE;

//--- Last processed candle
datetime LastBarTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(30);

   hEMA20 = iMA(_Symbol, PERIOD_M5, FastEMA, 0, MODE_EMA, PRICE_CLOSE);
   hEMA50 = iMA(_Symbol, PERIOD_M5, SlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   hRSI   = iRSI(_Symbol, PERIOD_M5, RSIPeriod, PRICE_CLOSE);
   hMACD  = iMACD(_Symbol, PERIOD_M5, MACDFast, MACDSlow, MACDSignal, PRICE_CLOSE);

   if(hEMA20 == INVALID_HANDLE ||
      hEMA50 == INVALID_HANDLE ||
      hRSI   == INVALID_HANDLE ||
      hMACD  == INVALID_HANDLE)
   {
      Print("ERROR | Failed to create indicator handles");
      return(INIT_FAILED);
   }

   Print("==================================================");
   Print("XAU M5 Smart Entry INITIALIZED");
   Print("Symbol: ", _Symbol);
   Print("Timeframe: M5");
   Print("Checking every NEW candle");
   Print("Lot: ", LotSize);
   Print("SL points: ", StopLossPoints);
   Print("TP points: ", TakeProfitPoints);
   Print("==================================================");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
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
//| Check for new candle                                             |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime currentBarTime = iTime(_Symbol, PERIOD_M5, 0);

   if(currentBarTime <= 0)
      return false;

   if(currentBarTime != LastBarTime)
   {
      LastBarTime = currentBarTime;
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Main tick function                                               |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!IsNewBar())
      return;

   CheckSignal();
}

//+------------------------------------------------------------------+
//| Check trading conditions                                         |
//+------------------------------------------------------------------+
void CheckSignal()
{
   double ema20[3];
   double ema50[3];
   double rsi[3];
   double macdMain[3];
   double macdSignal[3];

   ArraySetAsSeries(ema20, true);
   ArraySetAsSeries(ema50, true);
   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(macdMain, true);
   ArraySetAsSeries(macdSignal, true);

   if(CopyBuffer(hEMA20, 0, 0, 3, ema20) < 3)
   {
      Print("NO TRADE | EMA20 data unavailable");
      return;
   }

   if(CopyBuffer(hEMA50, 0, 0, 3, ema50) < 3)
   {
      Print("NO TRADE | EMA50 data unavailable");
      return;
   }

   if(CopyBuffer(hRSI, 0, 0, 3, rsi) < 3)
   {
      Print("NO TRADE | RSI data unavailable");
      return;
   }

   if(CopyBuffer(hMACD, 0, 0, 3, macdMain) < 3)
   {
      Print("NO TRADE | MACD main data unavailable");
      return;
   }

   if(CopyBuffer(hMACD, 1, 0, 3, macdSignal) < 3)
   {
      Print("NO TRADE | MACD signal data unavailable");
      return;
   }

   // Use the CLOSED candle (shift 1)
   double closePrice = iClose(_Symbol, PERIOD_M5, 1);

   double e20 = ema20[1];
   double e50 = ema50[1];
   double r   = rsi[1];
   double m   = macdMain[1];
   double ms  = macdSignal[1];

   Print(
      "CHECK | Close=", DoubleToString(closePrice, _Digits),
      " EMA20=", DoubleToString(e20, _Digits),
      " EMA50=", DoubleToString(e50, _Digits),
      " RSI=", DoubleToString(r, 2),
      " MACD=", DoubleToString(m, 6),
      " Signal=", DoubleToString(ms, 6)
   );

   //--- BUY conditions
   bool buyCondition =
      (e20 > e50) &&
      (r > RSI_Buy_Level) &&
      (m > ms);

   //--- SELL conditions
   bool sellCondition =
      (e20 < e50) &&
      (r < RSI_Sell_Level) &&
      (m < ms);

   if(buyCondition)
   {
      Print("BUY SIGNAL | Conditions confirmed");
      OpenBuy();
      return;
   }

   if(sellCondition)
   {
      Print("SELL SIGNAL | Conditions confirmed");
      OpenSell();
      return;
   }

   //--- No signal
   string reason = "";

   if(e20 > e50)
      reason += "EMA bullish; ";
   else if(e20 < e50)
      reason += "EMA bearish; ";
   else
      reason += "EMA equal; ";

   if(r > 50)
      reason += "RSI above 50; ";
   else
      reason += "RSI below 50; ";

   if(m > ms)
      reason += "MACD bullish; ";
   else
      reason += "MACD bearish; ";

   Print("NO BUY/SELL | reason: ", reason);
}

//+------------------------------------------------------------------+
//| Open BUY                                                         |
//+------------------------------------------------------------------+
void OpenBuy()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   if(ask <= 0)
   {
      Print("BUY ERROR | Ask price unavailable");
      return;
   }

   double sl = ask - StopLossPoints * _Point;
   double tp = ask + TakeProfitPoints * _Point;

   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);

   bool result = trade.Buy(
      LotSize,
      _Symbol,
      0,
      sl,
      tp,
      "XAU M5 Smart Entry BUY"
   );

   if(result)
   {
      Print(
         "BUY OPENED | Lot=", LotSize,
         " Entry=", DoubleToString(ask, _Digits),
         " SL=", DoubleToString(sl, _Digits),
         " TP=", DoubleToString(tp, _Digits)
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
//| Open SELL                                                        |
//+------------------------------------------------------------------+
void OpenSell()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(bid <= 0)
   {
      Print("SELL ERROR | Bid price unavailable");
      return;
   }

   double sl = bid + StopLossPoints * _Point;
   double tp = bid - TakeProfitPoints * _Point;

   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);

   bool result = trade.Sell(
      LotSize,
      _Symbol,
      0,
      sl,
      tp,
      "XAU M5 Smart Entry SELL"
   );

   if(result)
   {
      Print(
         "SELL OPENED | Lot=", LotSize,
         " Entry=", DoubleToString(bid, _Digits),
         " SL=", DoubleToString(sl, _Digits),
         " TP=", DoubleToString(tp, _Digits)
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

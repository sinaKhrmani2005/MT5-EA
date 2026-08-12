#property strict
#property version "1.00"

#include <Trade/Trade.mqh>

CTrade trade;

input double Lots = 0.01;
input int StopLossPoints = 500;
input int TakeProfitPoints = 1000;

input int EMA_Fast = 20;
input int EMA_Slow = 50;
input int RSI_Period = 14;

input int MACD_Fast = 12;
input int MACD_Slow = 26;
input int MACD_Signal = 9;

input double RSI_Buy = 50.0;
input double RSI_Sell = 50.0;

input ulong MagicNumber = 20260812;

int ema20Handle;
int ema50Handle;
int rsiHandle;
int macdHandle;

datetime lastBar = 0;

int OnInit()
{
   ema20Handle = iMA(_Symbol,_Period,EMA_Fast,0,MODE_EMA,PRICE_CLOSE);
   ema50Handle = iMA(_Symbol,_Period,EMA_Slow,0,MODE_EMA,PRICE_CLOSE);
   rsiHandle   = iRSI(_Symbol,_Period,RSI_Period,PRICE_CLOSE);

   macdHandle = iMACD(
      _Symbol,
      _Period,
      MACD_Fast,
      MACD_Slow,
      MACD_Signal,
      PRICE_CLOSE
   );

   if(ema20Handle == INVALID_HANDLE ||
      ema50Handle == INVALID_HANDLE ||
      rsiHandle == INVALID_HANDLE ||
      macdHandle == INVALID_HANDLE)
   {
      Print("Indicator initialization failed.");
      return INIT_FAILED;
   }

   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);

   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(ema20Handle);
   IndicatorRelease(ema50Handle);
   IndicatorRelease(rsiHandle);
   IndicatorRelease(macdHandle);
}

bool NewBar()
{
   datetime currentBar = iTime(_Symbol,_Period,0);

   if(currentBar != lastBar)
   {
      lastBar = currentBar;
      return true;
   }

   return false;
}

bool HasPosition()
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);

      if(ticket==0)
         continue;

      if(PositionGetString(POSITION_SYMBOL)==_Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC)==MagicNumber)
         return true;
   }

   return false;
}

void OnTick()
{
   if(!NewBar())
      return;

   if(HasPosition())
      return;

   double ema20[1];
   double ema50[1];
   double rsi[1];
   double macdMain[1];
   double macdSignal[1];

   if(CopyBuffer(ema20Handle,0,1,1,ema20)!=1)
      return;

   if(CopyBuffer(ema50Handle,0,1,1,ema50)!=1)
      return;

   if(CopyBuffer(rsiHandle,0,1,1,rsi)!=1)
      return;

   if(CopyBuffer(macdHandle,0,1,1,macdMain)!=1)
      return;

   if(CopyBuffer(macdHandle,1,1,1,macdSignal)!=1)
      return;

   bool buy =
      ema20[0] > ema50[0] &&
      rsi[0] > RSI_Buy &&
      macdMain[0] > macdSignal[0];

   bool sell =
      ema20[0] < ema50[0] &&
      rsi[0] < RSI_Sell &&
      macdMain[0] < macdSignal[0];

   double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);

   if(buy)
   {
      double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);

      double sl = ask - StopLossPoints * point;
      double tp = ask + TakeProfitPoints * point;

      sl = NormalizeDouble(sl,digits);
      tp = NormalizeDouble(tp,digits);

      trade.Buy(
         Lots,
         _Symbol,
         0,
         sl,
         tp,
         "EMA RSI MACD BUY"
      );
   }

   if(sell)
   {
      double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);

      double sl = bid + StopLossPoints * point;
      double tp = bid - TakeProfitPoints * point;

      sl = NormalizeDouble(sl,digits);
      tp = NormalizeDouble(tp,digits);

      trade.Sell(
         Lots,
         _Symbol,
         0,
         sl,
         tp,
         "EMA RSI MACD SELL"
      );
   }
}

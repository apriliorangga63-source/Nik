//+------------------------------------------------------------------+
//| Global Variables Header                                           |
//+------------------------------------------------------------------+
#ifndef __GLOBALVARIABLES_MQH__
#define __GLOBALVARIABLES_MQH__

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/OrderInfo.mqh>
#include <Trade/DealInfo.mqh>

//+------------------------------------------------------------------+
//| Enumerations                                                      |
//+------------------------------------------------------------------+
enum ESignal
{
    SIGNAL_NONE,
    SIGNAL_BUY,
    SIGNAL_SELL
};

enum ENewsImpact
{
    NEWS_NO_IMPACT,
    NEWS_MEDIUM_IMPACT,
    NEWS_HIGH_IMPACT
};

enum ENewsType
{
    NEWS_CPI,
    NEWS_NFP,
    NEWS_FOMC,
    NEWS_GDP,
    NEWS_UNEMPLOYMENT,
    NEWS_OTHER
};

//+------------------------------------------------------------------+
//| News Structure                                                    |
//+------------------------------------------------------------------+
struct SNewsData
{
    ENewsType type;
    datetime time;
    double forecast;
    double previous;
    double actual;
    bool isConfirmed;
};

//+------------------------------------------------------------------+
//| Position Structure                                               |
//+------------------------------------------------------------------+
struct SPositionData
{
    ulong ticket;
    string engine;  // "Technical" or "Fundamental"
    double entryPrice;
    double stopLoss;
    double takeProfit;
    datetime openTime;
    int type;  // ORDER_TYPE_BUY or ORDER_TYPE_SELL
};

//+------------------------------------------------------------------+
//| Global Objects                                                    |
//+------------------------------------------------------------------+
CTrade Trade;
CPositionInfo PositionInfo;
COrderInfo OrderInfo;
CDealInfo DealInfo;

//+------------------------------------------------------------------+
//| Global Buffers                                                    |
//+------------------------------------------------------------------+
double ATRBuffer[];
double HighBuffer[];
double LowBuffer[];
double CloseBuffer[];

//+------------------------------------------------------------------+
#endif
//+------------------------------------------------------------------+
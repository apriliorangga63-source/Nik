//+------------------------------------------------------------------+
//| Fundamental Engine - News Based Trading                          |
//+------------------------------------------------------------------+
#ifndef __FUNDAMENTALENGINE_MQH__
#define __FUNDAMENTALENGINE_MQH__

#include "GlobalVariables.mqh"
#include "NewsFilter.mqh"

class CFundamentalEngine
{
private:
    SNewsData currentNews;
    bool isNewsActive;
    datetime lastNewsTime;
    
public:
    CFundamentalEngine();
    ~CFundamentalEngine();
    
    bool Init();
    ESignal GetSignal();
    bool CheckNewsRating(double actual, double forecast, double previous);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CFundamentalEngine::CFundamentalEngine()
{
    isNewsActive = false;
    lastNewsTime = 0;
    
    currentNews.type = NEWS_OTHER;
    currentNews.time = 0;
    currentNews.forecast = 0;
    currentNews.previous = 0;
    currentNews.actual = 0;
    currentNews.isConfirmed = false;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CFundamentalEngine::~CFundamentalEngine()
{
}

//+------------------------------------------------------------------+
//| Initialize                                                        |
//+------------------------------------------------------------------+
bool CFundamentalEngine::Init()
{
    return true;
}

//+------------------------------------------------------------------+
//| Get Signal                                                        |
//+------------------------------------------------------------------+
ESignal CFundamentalEngine::GetSignal()
{
    // Check news data from calendar
    // BUY: Actual > Forecast AND Actual > Previous
    // SELL: Actual < Forecast AND Actual < Previous
    
    if(!isNewsActive)
        return SIGNAL_NONE;
    
    if(currentNews.actual > currentNews.forecast && currentNews.actual > currentNews.previous)
    {
        Print("[FUNDAMENTAL] BUY Signal - ", EnumToString(currentNews.type));
        return SIGNAL_BUY;
    }
    else if(currentNews.actual < currentNews.forecast && currentNews.actual < currentNews.previous)
    {
        Print("[FUNDAMENTAL] SELL Signal - ", EnumToString(currentNews.type));
        return SIGNAL_SELL;
    }
    
    return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| Check News Rating                                                |
//+------------------------------------------------------------------+
bool CFundamentalEngine::CheckNewsRating(double actual, double forecast, double previous)
{
    // Verify significant difference
    double diffForecast = MathAbs(actual - forecast);
    double diffPrevious = MathAbs(actual - previous);
    
    // If difference is less than 5%, skip
    if(diffForecast < forecast * 0.05 && diffPrevious < previous * 0.05)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
#endif
//+------------------------------------------------------------------+
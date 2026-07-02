//+------------------------------------------------------------------+
//| News Filter - Economic Calendar Integration                      |
//+------------------------------------------------------------------+
#ifndef __NEWSFILTER_MQH__
#define __NEWSFILTER_MQH__

#include "GlobalVariables.mqh"

class CNewsFilter
{
private:
    ENewsImpact currentImpact;
    datetime lastNewsTime;
    int highImpactMinutesAfter;
    bool highImpactActive;
    
    ENewsImpact DetermineImpact(ENewsType type);
    
public:
    CNewsFilter();
    ~CNewsFilter();
    
    bool Init();
    ENewsImpact GetCurrentImpact();
    bool IsHighImpactNewsActive();
    bool IsHighImpactNews(ENewsType type);
    bool IsMediumImpactNews(ENewsType type);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CNewsFilter::CNewsFilter()
{
    currentImpact = NEWS_NO_IMPACT;
    lastNewsTime = 0;
    highImpactMinutesAfter = 5;  // 5 minutes after high impact news
    highImpactActive = false;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CNewsFilter::~CNewsFilter()
{
}

//+------------------------------------------------------------------+
//| Initialize                                                        |
//+------------------------------------------------------------------+
bool CNewsFilter::Init()
{
    currentImpact = NEWS_NO_IMPACT;
    lastNewsTime = 0;
    highImpactActive = false;
    return true;
}

//+------------------------------------------------------------------+
//| Get Current Impact                                               |
//+------------------------------------------------------------------+
ENewsImpact CNewsFilter::GetCurrentImpact()
{
    // Check MT5 Economic Calendar for upcoming news
    // This is a simplified version
    
    if(highImpactActive)
    {
        if(TimeCurrent() - lastNewsTime <= highImpactMinutesAfter * 60)
            return NEWS_HIGH_IMPACT;
        else
            highImpactActive = false;
    }
    
    return NEWS_NO_IMPACT;
}

//+------------------------------------------------------------------+
//| Is High Impact News Active                                       |
//+------------------------------------------------------------------+
bool CNewsFilter::IsHighImpactNewsActive()
{
    return highImpactActive && (TimeCurrent() - lastNewsTime <= highImpactMinutesAfter * 60);
}

//+------------------------------------------------------------------+
//| Is High Impact News Type                                         |
//+------------------------------------------------------------------+
bool CNewsFilter::IsHighImpactNews(ENewsType type)
{
    switch(type)
    {
        case NEWS_CPI:
        case NEWS_NFP:
        case NEWS_FOMC:
        case NEWS_GDP:
        case NEWS_UNEMPLOYMENT:
            return true;
        default:
            return false;
    }
}

//+------------------------------------------------------------------+
//| Is Medium Impact News Type                                       |
//+------------------------------------------------------------------+
bool CNewsFilter::IsMediumImpactNews(ENewsType type)
{
    // Medium impact: Retail sales, Producer prices, etc.
    // For now, return anything not high impact
    return !IsHighImpactNews(type);
}

//+------------------------------------------------------------------+
//| Determine Impact                                                 |
//+------------------------------------------------------------------+
ENewsImpact CNewsFilter::DetermineImpact(ENewsType type)
{
    if(IsHighImpactNews(type))
        return NEWS_HIGH_IMPACT;
    else if(IsMediumImpactNews(type))
        return NEWS_MEDIUM_IMPACT;
    
    return NEWS_NO_IMPACT;
}

//+------------------------------------------------------------------+
#endif
//+------------------------------------------------------------------+
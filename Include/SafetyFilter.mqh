//+------------------------------------------------------------------+
//| Safety Filter - Risk Management & Anti-Overtrade                 |
//+------------------------------------------------------------------+
#ifndef __SAFETYFILTER_MQH__
#define __SAFETYFILTER_MQH__

#include "GlobalVariables.mqh"

class CSafetyFilter
{
private:
    int maxSpreadPips;
    int lastEntryCandle;
    double normalSpread;
    bool hasOpenPosition;
    int positionCount;
    
    bool CheckSpread();
    bool CheckDuplicateEntry();
    bool CheckNormalConditions();
    
public:
    CSafetyFilter();
    ~CSafetyFilter();
    
    bool Init(int spreadPips);
    bool CheckPrerequisites();
    bool CheckPositionLimit(double lotSize, double maxLot);
    int GetOpenPositionCount();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CSafetyFilter::CSafetyFilter()
{
    maxSpreadPips = 15;
    lastEntryCandle = 0;
    normalSpread = 0;
    hasOpenPosition = false;
    positionCount = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CSafetyFilter::~CSafetyFilter()
{
}

//+------------------------------------------------------------------+
//| Initialize                                                        |
//+------------------------------------------------------------------+
bool CSafetyFilter::Init(int spreadPips)
{
    maxSpreadPips = spreadPips;
    normalSpread = (double)maxSpreadPips / 2.5;  // 60% of max spread
    return true;
}

//+------------------------------------------------------------------+
//| Check Prerequisites                                              |
//+------------------------------------------------------------------+
bool CSafetyFilter::CheckPrerequisites()
{
    // Check if market conditions are safe for trading
    if(!CheckSpread())
    {
        Print("[SAFETY] Spread too high - Skipping");
        return false;
    }
    
    if(!CheckNormalConditions())
    {
        Print("[SAFETY] Market conditions abnormal - Skipping");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check Position Limit                                             |
//+------------------------------------------------------------------+
bool CSafetyFilter::CheckPositionLimit(double lotSize, double maxLot)
{
    positionCount = GetOpenPositionCount();
    
    // Max 2 positions
    if(positionCount >= 2)
    {
        Print("[SAFETY] Max positions (2) reached");
        return false;
    }
    
    // Calculate current lot
    double currentLot = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionSelectByTicket(i))
        {
            if(PositionGetString(POSITION_SYMBOL) == Symbol())
                currentLot += PositionGetDouble(POSITION_VOLUME);
        }
    }
    
    // Check if adding new lot exceeds max
    if(currentLot + lotSize > maxLot)
    {
        Print("[SAFETY] Total lot limit exceeded");
        return false;
    }
    
    // Prevent duplicate entry per candle
    if(!CheckDuplicateEntry())
    {
        Print("[SAFETY] Duplicate entry prevented");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check Spread                                                     |
//+------------------------------------------------------------------+
bool CSafetyFilter::CheckSpread()
{
    int spread = (int)(Ask - Bid) / Point();
    
    if(spread > maxSpreadPips)
    {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check Duplicate Entry                                            |
//+------------------------------------------------------------------+
bool CSafetyFilter::CheckDuplicateEntry()
{
    int currentCandle = iTime(Symbol(), Period(), 0);
    
    if(lastEntryCandle == currentCandle)
    {
        return false;  // Already entered this candle
    }
    
    lastEntryCandle = currentCandle;
    return true;
}

//+------------------------------------------------------------------+
//| Check Normal Conditions                                          |
//+------------------------------------------------------------------+
bool CSafetyFilter::CheckNormalConditions()
{
    // Check if broker is connected
    if(!SymbolInfoInteger(Symbol(), SYMBOL_EXIST))
        return false;
    
    // Check if symbol is tradable
    if(!SymbolInfoInteger(Symbol(), SYMBOL_TRADE_MODE) || 
       SymbolInfoInteger(Symbol(), SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_DISABLED)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Get Open Position Count                                          |
//+------------------------------------------------------------------+
int CSafetyFilter::GetOpenPositionCount()
{
    int count = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionSelectByTicket(i))
        {
            if(PositionGetString(POSITION_SYMBOL) == Symbol())
                count++;
        }
    }
    return count;
}

//+------------------------------------------------------------------+
#endif
//+------------------------------------------------------------------+
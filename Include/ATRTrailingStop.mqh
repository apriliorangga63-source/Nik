//+------------------------------------------------------------------+
//| ATR Trailing Stop - Technical Stop Management                    |
//+------------------------------------------------------------------+
#ifndef __ATRTRAILINGSTOP_MQH__
#define __ATRTRAILINGSTOP_MQH__

#include "GlobalVariables.mqh"

class CATRTrailingStop
{
private:
    int atrHandle;
    int atrPeriod;
    double atrMultiplier;
    double atrValue;
    
public:
    CATRTrailingStop();
    ~CATRTrailingStop();
    
    bool Init(int period, double multiplier);
    void UpdateTrailingStops(string symbol);
    void UpdateStopForPosition(ulong ticket, double atr);
    double CalculateStopLoss(ENUM_ORDER_TYPE type, double atr);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CATRTrailingStop::CATRTrailingStop()
{
    atrHandle = INVALID_HANDLE;
    atrPeriod = 14;
    atrMultiplier = 1.2;
    atrValue = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CATRTrailingStop::~CATRTrailingStop()
{
    if(atrHandle != INVALID_HANDLE)
        IndicatorRelease(atrHandle);
}

//+------------------------------------------------------------------+
//| Initialize                                                        |
//+------------------------------------------------------------------+
bool CATRTrailingStop::Init(int period, double multiplier)
{
    atrPeriod = period;
    atrMultiplier = multiplier;
    atrHandle = iATR(Symbol(), Period(), atrPeriod);
    
    if(atrHandle == INVALID_HANDLE)
    {
        Print("ERROR: Failed to create ATR for TrailingStop");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Update Trailing Stops for All Positions                         |
//+------------------------------------------------------------------+
void CATRTrailingStop::UpdateTrailingStops(string symbol)
{
    double atrArray[];
    if(CopyBuffer(atrHandle, 0, 0, 1, atrArray) > 0)
        atrValue = atrArray[0];
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionSelectByTicket(i))
        {
            if(PositionGetString(POSITION_SYMBOL) == symbol)
            {
                UpdateStopForPosition(PositionGetTicket(i), atrValue);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Update Stop Loss for Single Position                             |
//+------------------------------------------------------------------+
void CATRTrailingStop::UpdateStopForPosition(ulong ticket, double atr)
{
    if(!PositionSelectByTicket(ticket))
        return;
    
    ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    double currentSL = PositionGetDouble(POSITION_SL);
    double newSL = 0;
    
    if(type == POSITION_TYPE_BUY)
    {
        newSL = Close[0] - (atr * atrMultiplier * Point());
        
        // Only move stop loss higher, never lower
        if(newSL > currentSL)
        {
            CTrade trade;
            trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
        }
    }
    else if(type == POSITION_TYPE_SELL)
    {
        newSL = Close[0] + (atr * atrMultiplier * Point());
        
        // Only move stop loss lower, never higher
        if(newSL < currentSL)
        {
            CTrade trade;
            trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
        }
    }
}

//+------------------------------------------------------------------+
//| Calculate Stop Loss                                              |
//+------------------------------------------------------------------+
double CATRTrailingStop::CalculateStopLoss(ENUM_ORDER_TYPE type, double atr)
{
    double sl = 0;
    
    if(type == ORDER_TYPE_BUY)
        sl = Ask - (atr * atrMultiplier * Point());
    else if(type == ORDER_TYPE_SELL)
        sl = Bid + (atr * atrMultiplier * Point());
    
    return sl;
}

//+------------------------------------------------------------------+
#endif
//+------------------------------------------------------------------+
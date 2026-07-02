//+------------------------------------------------------------------+
//| EA MT5 Professional - Technical & Fundamental Separation Final    |
//| Single File Version - All Components Integrated                   |
//| Author: April Orangga 2026                                        |
//+------------------------------------------------------------------+
#property copyright "April Orangga 2026"
#property version   "1.0"
#property strict

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/OrderInfo.mqh>
#include <Trade/DealInfo.mqh>

//+------------------------------------------------------------------+
//| ENUMERATIONS & STRUCTURES                                        |
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

struct SNewsData
{
    ENewsType type;
    datetime time;
    double forecast;
    double previous;
    double actual;
    bool isConfirmed;
};

struct SPositionData
{
    ulong ticket;
    string engine;
    double entryPrice;
    double stopLoss;
    double takeProfit;
    datetime openTime;
    int type;
};

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+

input string   EA_Name                = "EA MT5 Professional";
input double   LotSize                = 0.02;
input double   MaxPositions           = 0.04;
input int      ATRPeriod              = 14;
input double   ATRMultiplier          = 1.2;
input double   TPMultiplier           = 2.0;
input bool     EnableFundamental      = true;
input bool     EnableTechnical        = true;
input int      MaxSpreadPips          = 15;
input int      NewsCheckIntervalSeconds = 60;
input bool     EnableSpikeFilter      = true;
input bool     EnableTrailingStop     = true;

//+------------------------------------------------------------------+
//| GLOBAL OBJECTS & VARIABLES                                      |
//+------------------------------------------------------------------+

CTrade Trade;
CPositionInfo PositionInfo;

bool isFundamentalActive = false;
bool isTechnicalActive = true;
int lastNewsCheckTime = 0;
int lastEntryCandle = 0;
datetime lastNewsTime = 0;

// Technical Engine Variables
int atrHandle = INVALID_HANDLE;
double atrValue = 0;
double atrAverage = 0;

//+------------------------------------------------------------------+
//| INITIALIZATION                                                    |
//+------------------------------------------------------------------+

int OnInit()
{
    Print("================================================");
    Print("EA MT5 Professional - Initialization Started");
    Print("================================================");
    
    // Create ATR indicator
    atrHandle = iATR(Symbol(), Period(), ATRPeriod);
    if(atrHandle == INVALID_HANDLE)
    {
        Print("ERROR: Failed to create ATR indicator");
        return INIT_FAILED;
    }
    
    Print("All components initialized successfully");
    Print("================================================");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| DEINITIALIZATION                                                 |
//+------------------------------------------------------------------+

void OnDeinit(const int reason)
{
    Print("EA MT5 Professional - Deinitialization");
    
    if(atrHandle != INVALID_HANDLE)
        IndicatorRelease(atrHandle);
    
    CloseAllPositions();
}

//+------------------------------------------------------------------+
//| MAIN TICK FUNCTION                                               |
//+------------------------------------------------------------------+

void OnTick()
{
    static int lastTickTime = 0;
    int currentTime = (int)TimeCurrent();
    
    // Prevent multiple processing per candle
    if(lastTickTime == iTime(Symbol(), Period(), 0))
        return;
    lastTickTime = iTime(Symbol(), Period(), 0);
    
    // Safety checks
    if(!CheckPrerequisites())
        return;
    
    // Update ATR values
    UpdateATRValues();
    
    // Check for high impact news every 60 seconds
    if(currentTime - lastNewsCheckTime >= NewsCheckIntervalSeconds)
    {
        lastNewsCheckTime = currentTime;
        CheckNewsImpact();
    }
    
    // Determine active engine
    DetermineActiveEngine();
    
    // Execute active engine
    if(isFundamentalActive && EnableFundamental)
    {
        ExecuteFundamentalEngine();
    }
    else if(isTechnicalActive && EnableTechnical)
    {
        ExecuteTechnicalEngine();
    }
    
    // Update trailing stops
    if(EnableTrailingStop)
    {
        UpdateTrailingStops();
    }
}

//+------------------------------------------------------------------+
//| SAFETY CHECKS                                                    |
//+------------------------------------------------------------------+

bool CheckPrerequisites()
{
    // Check spread
    int spread = (int)(Ask - Bid) / Point();
    if(spread > MaxSpreadPips)
    {
        return false;
    }
    
    // Check if symbol is tradable
    if(!SymbolInfoInteger(Symbol(), SYMBOL_EXIST))
        return false;
    
    if(SymbolInfoInteger(Symbol(), SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_DISABLED)
        return false;
    
    return true;
}

bool CheckPositionLimit(double lotSize, double maxLot)
{
    int posCount = GetOpenPositionCount();
    
    // Max 2 positions
    if(posCount >= 2)
    {
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
        return false;
    }
    
    // Prevent duplicate entry per candle
    int currentCandle = iTime(Symbol(), Period(), 0);
    if(lastEntryCandle == currentCandle)
    {
        return false;
    }
    
    lastEntryCandle = currentCandle;
    return true;
}

int GetOpenPositionCount()
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
//| ATR FUNCTIONS                                                    |
//+------------------------------------------------------------------+

void UpdateATRValues()
{
    double atrArray[];
    if(CopyBuffer(atrHandle, 0, 0, 1, atrArray) > 0)
        atrValue = atrArray[0];
    
    // Calculate 20-candle ATR average
    double atrSum = 0;
    for(int i = 0; i < 20; i++)
    {
        if(CopyBuffer(atrHandle, 0, i, 1, atrArray) > 0)
            atrSum += atrArray[0];
    }
    atrAverage = atrSum / 20;
}

double GetATR()
{
    return atrValue;
}

//+------------------------------------------------------------------+
//| NEWS MANAGEMENT                                                  |
//+------------------------------------------------------------------+

void CheckNewsImpact()
{
    // Simplified news check - In production, integrate with MT5 Economic Calendar
    // For now, check if we're near major news times
}

void DetermineActiveEngine()
{
    if(IsHighImpactNewsActive())
    {
        isFundamentalActive = true;
        isTechnicalActive = false;
    }
    else
    {
        isFundamentalActive = false;
        isTechnicalActive = true;
    }
}

bool IsHighImpactNewsActive()
{
    // Check if we're within 5 minutes of high impact news
    if(lastNewsTime > 0 && TimeCurrent() - lastNewsTime <= 300)
    {
        return true;
    }
    return false;
}

bool IsHighImpactNews(ENewsType type)
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
//| SPIKE FILTER CHECKS                                              |
//+------------------------------------------------------------------+

bool IsSpike()
{
    // Rule 1: Skip if candle range > 2.5 × ATR and body < 25% range
    if(CheckSpikeRule1())
        return true;
    
    // Rule 2: Skip 1-2 candles after news
    if(CheckSpikeRule2())
        return true;
    
    // Rule 3: Skip if ATR > 3 × ATR average
    if(CheckSpikeRule3())
        return true;
    
    // Rule 5: Entry only if after spike continues 1 candle in direction
    if(!CheckSpikeRule5())
        return true;
    
    return false;
}

bool CheckSpikeRule1()
{
    double range = High[0] - Low[0];
    double body = MathAbs(Close[0] - Open[0]);
    
    if(range > 2.5 * atrValue && body < range * 0.25)
        return true;
    
    return false;
}

bool CheckSpikeRule2()
{
    // Skip 1-2 candles after news
    if(lastNewsTime > 0 && TimeCurrent() - lastNewsTime <= 120)
    {
        return true;
    }
    return false;
}

bool CheckSpikeRule3()
{
    if(atrValue > 3 * atrAverage)
        return true;
    
    return false;
}

bool CheckSpikeRule5()
{
    // Entry only if after spike: price continues 1+ candle in direction
    if(Close[0] > Open[0] && Close[1] > Open[1])  // Two bullish
        return true;
    
    if(Close[0] < Open[0] && Close[1] < Open[1])  // Two bearish
        return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| TECHNICAL ENGINE                                                 |
//+------------------------------------------------------------------+

void ExecuteTechnicalEngine()
{
    ESignal signal = GetTechnicalSignal();
    
    if(signal == SIGNAL_NONE)
        return;
    
    if(CheckPositionLimit(LotSize, MaxPositions))
    {
        if(signal == SIGNAL_BUY)
        {
            OpenBuyPosition(LotSize, "Technical");
        }
        else if(signal == SIGNAL_SELL)
        {
            OpenSellPosition(LotSize, "Technical");
        }
    }
}

ESignal GetTechnicalSignal()
{
    // Smart Money Concept Logic
    if(CheckLiquiditySweep() && CheckBreakOfStructure() && CheckOrderBlock())
    {
        if(Close[0] > Close[1])
            return SIGNAL_BUY;
        else
            return SIGNAL_SELL;
    }
    
    return SIGNAL_NONE;
}

bool CheckLiquiditySweep()
{
    // Check if price breaks recent high/low
    double recentHigh = High[1];
    double recentLow = Low[1];
    
    if(Close[0] > recentHigh || Close[0] < recentLow)
        return true;
    
    return false;
}

bool CheckBreakOfStructure()
{
    // Check if price closes beyond 2-candle range
    double highOfTwo = MathMax(High[1], High[2]);
    double lowOfTwo = MathMin(Low[1], Low[2]);
    
    if(Close[0] > highOfTwo || Close[0] < lowOfTwo)
        return true;
    
    return false;
}

bool CheckOrderBlock()
{
    // Detect price rejection zones
    double range1 = High[2] - Low[2];
    double range2 = High[1] - Low[1];
    
    if(range1 > range2 * 1.5)
        return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| FUNDAMENTAL ENGINE                                               |
//+------------------------------------------------------------------+

void ExecuteFundamentalEngine()
{
    // Skip spike signals
    if(EnableSpikeFilter && IsSpike())
    {
        Print("[SPIKE FILTER] Spike detected - Skipping entry");
        return;
    }
    
    ESignal signal = GetFundamentalSignal();
    
    if(signal == SIGNAL_NONE)
        return;
    
    if(CheckPositionLimit(LotSize, MaxPositions))
    {
        if(signal == SIGNAL_BUY)
        {
            OpenBuyPosition(LotSize, "Fundamental");
        }
        else if(signal == SIGNAL_SELL)
        {
            OpenSellPosition(LotSize, "Fundamental");
        }
    }
}

ESignal GetFundamentalSignal()
{
    // This would be populated with actual news data from MT5 Economic Calendar
    // For now, returning SIGNAL_NONE
    // In production: Check Actual vs Forecast vs Previous
    
    return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| POSITION MANAGEMENT                                              |
//+------------------------------------------------------------------+

void OpenBuyPosition(double lot, string engine)
{
    double sl = Ask - (atrValue * ATRMultiplier * Point());
    double tp = Ask + (atrValue * ATRMultiplier * TPMultiplier * Point());
    
    if(Trade.Buy(lot, Symbol(), Ask, sl, tp, "BUY " + engine))
    {
        Print("[BUY] ", engine, " - Lot: ", lot, " SL: ", sl, " TP: ", tp);
    }
    else
    {
        Print("[ERROR] Buy order failed: ", GetLastError());
    }
}

void OpenSellPosition(double lot, string engine)
{
    double sl = Bid + (atrValue * ATRMultiplier * Point());
    double tp = Bid - (atrValue * ATRMultiplier * TPMultiplier * Point());
    
    if(Trade.Sell(lot, Symbol(), Bid, sl, tp, "SELL " + engine))
    {
        Print("[SELL] ", engine, " - Lot: ", lot, " SL: ", sl, " TP: ", tp);
    }
    else
    {
        Print("[ERROR] Sell order failed: ", GetLastError());
    }
}

void UpdateTrailingStops()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionSelectByTicket(i))
        {
            if(PositionGetString(POSITION_SYMBOL) == Symbol())
            {
                UpdateStopForPosition(PositionGetTicket(i));
            }
        }
    }
}

void UpdateStopForPosition(ulong ticket)
{
    if(!PositionSelectByTicket(ticket))
        return;
    
    ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    double currentSL = PositionGetDouble(POSITION_SL);
    double newSL = 0;
    
    if(type == POSITION_TYPE_BUY)
    {
        newSL = Close[0] - (atrValue * ATRMultiplier * Point());
        
        if(newSL > currentSL)
        {
            Trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
        }
    }
    else if(type == POSITION_TYPE_SELL)
    {
        newSL = Close[0] + (atrValue * ATRMultiplier * Point());
        
        if(newSL < currentSL)
        {
            Trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
        }
    }
}

void CloseAllPositions()
{
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionSelectByTicket(i))
        {
            if(PositionGetString(POSITION_SYMBOL) == Symbol())
            {
                Trade.Close(PositionGetTicket(i));
            }
        }
    }
}

//+------------------------------------------------------------------+
//| END                                                              |
//+------------------------------------------------------------------+

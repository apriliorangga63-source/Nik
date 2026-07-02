//+------------------------------------------------------------------+
//| Spike Filter - Anti-Spike Protection                             |
//+------------------------------------------------------------------+
#ifndef __SPIKEFILTER_MQH__
#define __SPIKEFILTER_MQH__

#include "GlobalVariables.mqh"

class CSpikeFilter
{
private:
    int atrHandle;
    int atrPeriod;
    double atrValue;
    double atrAverage;
    datetime lastNewsTime;
    int newsSkipCandles;
    
    bool IsExtremeCandleRange();
    bool IsSmallBodyCandle();
    bool IsExtremeATR();
    
public:
    CSpikeFilter();
    ~CSpikeFilter();
    
    bool Init(int period);
    bool IsSpike();
    bool CheckRule1();
    bool CheckRule2();
    bool CheckRule3();
    bool CheckRule4();
    bool CheckRule5();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CSpikeFilter::CSpikeFilter()
{
    atrHandle = INVALID_HANDLE;
    atrPeriod = 14;
    atrValue = 0;
    atrAverage = 0;
    lastNewsTime = 0;
    newsSkipCandles = 2;  // Skip 1-2 candles after news
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CSpikeFilter::~CSpikeFilter()
{
    if(atrHandle != INVALID_HANDLE)
        IndicatorRelease(atrHandle);
}

//+------------------------------------------------------------------+
//| Initialize                                                        |
//+------------------------------------------------------------------+
bool CSpikeFilter::Init(int period)
{
    atrPeriod = period;
    atrHandle = iATR(Symbol(), Period(), atrPeriod);
    
    if(atrHandle == INVALID_HANDLE)
    {
        Print("ERROR: Failed to create ATR for SpikeFilter");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Is Spike - Main Check                                            |
//+------------------------------------------------------------------+
bool CSpikeFilter::IsSpike()
{
    // Rule 1: Skip if candle range > 2.5 × ATR and body < 25% candle range
    if(CheckRule1())
        return true;
    
    // Rule 2: Skip 1-2 candles after news
    if(CheckRule2())
        return true;
    
    // Rule 3: Skip if ATR > 3 × ATR average (20 candle)
    if(CheckRule3())
        return true;
    
    // Rule 5: Entry only if after spike price continues minimum 1 candle in direction
    if(!CheckRule5())
        return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Check Rule 1                                                     |
//+------------------------------------------------------------------+
bool CSpikeFilter::CheckRule1()
{
    double range = High[0] - Low[0];
    double body = MathAbs(Close[0] - Open[0]);
    double atrBuffer[];
    
    if(CopyBuffer(atrHandle, 0, 0, 1, atrBuffer) > 0)
    {
        atrValue = atrBuffer[0];
        
        if(range > 2.5 * atrValue && body < range * 0.25)
            return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check Rule 2 - Skip After News                                  |
//+------------------------------------------------------------------+
bool CSpikeFilter::CheckRule2()
{
    // Skip 1-2 candles after news
    // Returns true if still in news avoidance period
    return false;  // Implement with news timestamp
}

//+------------------------------------------------------------------+
//| Check Rule 3 - Extreme ATR                                       |
//+------------------------------------------------------------------+
bool CSpikeFilter::CheckRule3()
{
    double atrArray[];
    double atrSum = 0;
    
    // Get ATR average of last 20 candles
    for(int i = 0; i < 20; i++)
    {
        if(CopyBuffer(atrHandle, 0, i, 1, atrArray) > 0)
            atrSum += atrArray[0];
    }
    
    atrAverage = atrSum / 20;
    
    if(CopyBuffer(atrHandle, 0, 0, 1, atrArray) > 0)
    {
        atrValue = atrArray[0];
        if(atrValue > 3 * atrAverage)
            return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check Rule 4 - Spread Filter                                     |
//+------------------------------------------------------------------+
bool CSpikeFilter::CheckRule4()
{
    // Implemented in SafetyFilter
    return false;
}

//+------------------------------------------------------------------+
//| Check Rule 5 - Candle Direction Confirmation                    |
//+------------------------------------------------------------------+
bool CSpikeFilter::CheckRule5()
{
    // Entry only if after spike price continues 1 candle in direction
    if(Close[0] > Open[0] && Close[1] > Open[1])  // Two bullish candles
        return true;
    
    if(Close[0] < Open[0] && Close[1] < Open[1])  // Two bearish candles
        return true;
    
    return false;
}

//+------------------------------------------------------------------+
#endif
//+------------------------------------------------------------------+
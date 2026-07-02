//+------------------------------------------------------------------+
//| EA MT5 Professional - Technical & Fundamental Separation Final    |
//| Main Entry Point                                                   |
//+------------------------------------------------------------------+
#property copyright "April Orangga 2026"
#property version   "1.0"
#property strict

#include "Include/GlobalVariables.mqh"
#include "Include/SessionManager.mqh"
#include "Include/TechnicalEngine.mqh"
#include "Include/FundamentalEngine.mqh"
#include "Include/NewsFilter.mqh"
#include "Include/SpikeFilter.mqh"
#include "Include/SafetyFilter.mqh"
#include "Include/ATRTrailingStop.mqh"

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
input string   EA_Name            = "EA MT5 Professional";
input double   LotSize            = 0.02;
input double   MaxPositions       = 0.04;
input int      ATRPeriod          = 14;
input double   ATRMultiplier      = 1.2;
input double   TPMultiplier       = 2.0;
input bool     EnableFundamental  = true;
input bool     EnableTechnical    = true;
input int      MaxSpreadPips      = 15;
input int      NewsCheckIntervalSeconds = 60;
input bool     EnableSpikeFilter  = true;
input bool     EnableTrailingStop = true;

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
CSessionManager sessionManager;
CTechnicalEngine technicalEngine;
CFundamentalEngine fundamentalEngine;
CNewsFilter newsFilter;
CSpikeFilter spikeFilter;
CSafetyFilter safetyFilter;
CATRTrailingStop atrTrailingStop;

bool isFundamentalActive = false;
bool isTechnicalActive = false;
int lastNewsCheckTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("=", StringFill('=', 50));
    Print("EA MT5 Professional - Initialization Started");
    Print("=", StringFill('=', 50));
    
    // Initialize components
    if(!sessionManager.Init())
    {
        Print("ERROR: SessionManager initialization failed");
        return INIT_FAILED;
    }
    
    if(!technicalEngine.Init(ATRPeriod, Symbol(), Period()))
    {
        Print("ERROR: TechnicalEngine initialization failed");
        return INIT_FAILED;
    }
    
    if(!fundamentalEngine.Init())
    {
        Print("ERROR: FundamentalEngine initialization failed");
        return INIT_FAILED;
    }
    
    if(!newsFilter.Init())
    {
        Print("ERROR: NewsFilter initialization failed");
        return INIT_FAILED;
    }
    
    if(!spikeFilter.Init(ATRPeriod))
    {
        Print("ERROR: SpikeFilter initialization failed");
        return INIT_FAILED;
    }
    
    if(!safetyFilter.Init(MaxSpreadPips))
    {
        Print("ERROR: SafetyFilter initialization failed");
        return INIT_FAILED;
    }
    
    if(!atrTrailingStop.Init(ATRPeriod, ATRMultiplier))
    {
        Print("ERROR: ATRTrailingStop initialization failed");
        return INIT_FAILED;
    }
    
    Print("All components initialized successfully");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("EA MT5 Professional - Deinitialization");
    CloseAllPositions();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
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
    if(!safetyFilter.CheckPrerequisites())
        return;
    
    // Check for high impact news every 60 seconds
    if(currentTime - lastNewsCheckTime >= NewsCheckIntervalSeconds)
    {
        lastNewsCheckTime = currentTime;
        CheckNewsImpact();
    }
    
    // Session Manager: Determine active engine
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
        atrTrailingStop.UpdateTrailingStops(Symbol());
    }
}

//+------------------------------------------------------------------+
//| Check News Impact                                                |
//+------------------------------------------------------------------+
void CheckNewsImpact()
{
    ENewsImpact impact = newsFilter.GetCurrentImpact();
    
    if(impact == NEWS_HIGH_IMPACT)
    {
        isFundamentalActive = true;
        isTechnicalActive = false;
        Print("[NEWS] HIGH IMPACT NEWS detected - Fundamental Engine ON");
    }
    else if(impact == NEWS_MEDIUM_IMPACT)
    {
        isFundamentalActive = false;
        isTechnicalActive = true;
        Print("[NEWS] MEDIUM IMPACT NEWS - Technical with 1-min confirmation");
    }
    else
    {
        isFundamentalActive = false;
        isTechnicalActive = true;
    }
}

//+------------------------------------------------------------------+
//| Determine Active Engine                                          |
//+------------------------------------------------------------------+
void DetermineActiveEngine()
{
    if(newsFilter.IsHighImpactNewsActive())
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

//+------------------------------------------------------------------+
//| Execute Fundamental Engine                                       |
//+------------------------------------------------------------------+
void ExecuteFundamentalEngine()
{
    // Skip spike signals
    if(spikeFilter.IsSpike())
    {
        Print("[SPIKE FILTER] Spike detected - Skipping entry");
        return;
    }
    
    // Get fundamental signal
    ESignal signal = fundamentalEngine.GetSignal();
    
    if(signal == SIGNAL_NONE)
        return;
    
    // Verify position limits
    if(safetyFilter.CheckPositionLimit(LotSize, MaxPositions))
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

//+------------------------------------------------------------------+
//| Execute Technical Engine                                         |
//+------------------------------------------------------------------+
void ExecuteTechnicalEngine()
{
    ESignal signal = technicalEngine.GetSignal();
    
    if(signal == SIGNAL_NONE)
        return;
    
    // Verify position limits
    if(safetyFilter.CheckPositionLimit(LotSize, MaxPositions))
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

//+------------------------------------------------------------------+
//| Open Buy Position                                                |
//+------------------------------------------------------------------+
void OpenBuyPosition(double lot, string engine)
{
    double sl = Ask - (technicalEngine.GetATR() * ATRMultiplier * Point());
    double tp = Ask + (technicalEngine.GetATR() * ATRMultiplier * TPMultiplier * Point());
    
    CTrade trade;
    if(trade.Buy(lot, Symbol(), Ask, sl, tp, "BUY " + engine))
    {
        Print("[BUY] " + engine + " - Lot: ", lot, " SL: ", sl, " TP: ", tp);
    }
    else
    {
        Print("[ERROR] Buy order failed: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Open Sell Position                                               |
//+------------------------------------------------------------------+
void OpenSellPosition(double lot, string engine)
{
    double sl = Bid + (technicalEngine.GetATR() * ATRMultiplier * Point());
    double tp = Bid - (technicalEngine.GetATR() * ATRMultiplier * TPMultiplier * Point());
    
    CTrade trade;
    if(trade.Sell(lot, Symbol(), Bid, sl, tp, "SELL " + engine))
    {
        Print("[SELL] " + engine + " - Lot: ", lot, " SL: ", sl, " TP: ", tp);
    }
    else
    {
        Print("[ERROR] Sell order failed: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Close All Positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
    CTrade trade;
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionSelectByTicket(trade.ResultOrder()))
        {
            if(PositionGetString(POSITION_SYMBOL) == Symbol())
            {
                trade.Close(PositionGetTicket(i));
            }
        }
    }
}

//+------------------------------------------------------------------+
//| String Fill Function                                             |
//+------------------------------------------------------------------+
string StringFill(string character, int count)
{
    string result = "";
    for(int i = 0; i < count; i++)
        result += character;
    return result;
}
//+------------------------------------------------------------------+
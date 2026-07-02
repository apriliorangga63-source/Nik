//+------------------------------------------------------------------+
//| Session Manager - Control Technical/Fundamental Separation       |
//+------------------------------------------------------------------+
#ifndef __SESSIONMANAGER_MQH__
#define __SESSIONMANAGER_MQH__

#include "GlobalVariables.mqh"

class CSessionManager
{
private:
    bool fundamentalMode;
    bool technicalMode;
    datetime lastModeSwitch;
    int modeCheckInterval;
    
public:
    CSessionManager();
    ~CSessionManager();
    
    bool Init();
    void SwitchToFundamental();
    void SwitchToTechnical();
    bool IsFundamentalMode() const;
    bool IsTechnicalMode() const;
    void Update();
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CSessionManager::CSessionManager()
{
    fundamentalMode = false;
    technicalMode = true;
    lastModeSwitch = 0;
    modeCheckInterval = 60;  // Check every 60 seconds
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CSessionManager::~CSessionManager()
{
}

//+------------------------------------------------------------------+
//| Initialization                                                    |
//+------------------------------------------------------------------+
bool CSessionManager::Init()
{
    technicalMode = true;
    fundamentalMode = false;
    lastModeSwitch = TimeCurrent();
    return true;
}

//+------------------------------------------------------------------+
//| Switch to Fundamental Mode                                       |
//+------------------------------------------------------------------+
void CSessionManager::SwitchToFundamental()
{
    if(!fundamentalMode)
    {
        fundamentalMode = true;
        technicalMode = false;
        lastModeSwitch = TimeCurrent();
        Print("[SESSION] Mode switched to FUNDAMENTAL");
    }
}

//+------------------------------------------------------------------+
//| Switch to Technical Mode                                         |
//+------------------------------------------------------------------+
void CSessionManager::SwitchToTechnical()
{
    if(!technicalMode)
    {
        technicalMode = true;
        fundamentalMode = false;
        lastModeSwitch = TimeCurrent();
        Print("[SESSION] Mode switched to TECHNICAL");
    }
}

//+------------------------------------------------------------------+
//| Is Fundamental Mode                                              |
//+------------------------------------------------------------------+
bool CSessionManager::IsFundamentalMode() const
{
    return fundamentalMode;
}

//+------------------------------------------------------------------+
//| Is Technical Mode                                                |
//+------------------------------------------------------------------+
bool CSessionManager::IsTechnicalMode() const
{
    return technicalMode;
}

//+------------------------------------------------------------------+
//| Update Mode                                                       |
//+------------------------------------------------------------------+
void CSessionManager::Update()
{
    // Mode persistence logic
    if(fundamentalMode)
    {
        if(TimeCurrent() - lastModeSwitch > 300)  // 5 minutes max fundamental mode
        {
            SwitchToTechnical();
        }
    }
}

//+------------------------------------------------------------------+
#endif
//+------------------------------------------------------------------+
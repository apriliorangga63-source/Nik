# EA MT5 Professional - Technical & Fundamental Separation Final

## GENERAL RULES

✅ **DO NOT CHANGE:**
- Technical Engine (Smart Money Concept, SMC)
- Smart Money Concept (SMC)
- Liquidity Sweep
- Break of Structure (BOS)
- Trendline System
- Volume Profile
- ATR Trailing Stop (Technical)

✅ **ADD ONLY:**
- Fundamental Engine
- Medium News Confirmation
- Spike Filter

✅ **MUST SUPPORT:**
- All MT5 Brokers (HFM, Exness, DooPrime, Markets4you, etc.)
- 3/4/5 digit brokers
- Compilation without errors

---

## SESSION MANAGER RULES

### HIGH IMPACT NEWS ACTIVE:
```
→ FUNDAMENTAL ENGINE ON
→ TECHNICAL ENGINE OFF
```

### NO HIGH IMPACT NEWS:
```
→ TECHNICAL ENGINE ON
→ FUNDAMENTAL ENGINE OFF
```

---

## HIGH IMPACT NEWS (FUNDAMENTAL ONLY)

**Valid News Types (MT5 Economic Calendar):**
- CPI (Consumer Price Index)
- NFP (Non-Farm Payroll)
- FOMC (Interest Rate Decisions)
- GDP (High Impact Only)
- Unemployment Rate

---

## FUNDAMENTAL LOGIC

### BUY Signal:
```
Actual > Forecast  AND
Actual > Previous
```

### SELL Signal:
```
Actual < Forecast  AND
Actual < Previous
```

### NO TRADE:
```
No significant difference
```

---

## FUNDAMENTAL ENTRY RULES

### Position Sizing:
- **Entry 1:** 0.02 lot
- **Entry 2:** 0.02 lot
- **TOTAL MAX:** 0.04 lot (never more than 2 positions)

### Stop Loss:
```
SL = ATR × 1.2
```

### Take Profit:
```
TP = SL × 2 (Risk:Reward = 1:2)
```

---

## SPIKE FILTER (FUNDAMENTAL ONLY)

### Rule 1: Extreme Candle Range
```
Skip if:
  Candle Range > 2.5 × ATR  AND
  Body < 25% of Candle Range
```

### Rule 2: Post-News Avoidance
```
Skip 1-2 candles after news release
```

### Rule 3: Extreme ATR
```
Skip if:
  ATR (current) > 3 × ATR Average (20 candles)
```

### Rule 4: Spread Protection
```
Skip if:
  Spread > Normal Spread × 2.5
```

### Rule 5: Direction Confirmation
```
Entry only if after spike:
  Price continues 1+ candle in direction
```

---

## MEDIUM NEWS CONFIRMATION (TECHNICAL SUPPORT)

**Rule:** Medium impact news does NOT open fundamental trades.

**But in 1-minute window after medium news:**

Technical entry valid only if:
✓ Volume above average
✓ Candle direction matches news bias (clear bullish/bearish)
✓ Spread normal
✓ No extreme spike

**If no confirmation in 1 minute:**
→ Technical continues normal without news filter

---

## TECHNICAL ENGINE (LOCKED)

**Always active when no high impact news:**
- Smart Money Concept (SMC)
- Liquidity Sweep Detection
- Break of Structure (BOS)
- Trendline H4 & H1
- Order Block
- Volume Profile
- ATR Trailing Stop (Technical)

---

## SAFETY FILTERS

✓ Max spread filter
✓ No duplicate entry per candle
✓ No dual engine active simultaneously
✓ No martingale
✓ No grid trading
✓ No averaging (except controlled Entry 2)
✓ Anti-overtrade system
✓ Max 2 open positions
✓ Max 0.04 total lot

---

## FINAL BEHAVIOR

### HIGH IMPACT NEWS SCENARIO:
```
Fundamental ON  ✓
Technical OFF   ✓
Spike Filter ON ✓
Max 2 Positions
Max 0.04 Lot
```

### MEDIUM NEWS SCENARIO:
```
Technical ON (default)
1-minute confirmation window
If valid → Entry
If not valid → Normal technical
```

### NO NEWS SCENARIO:
```
Technical ON FULL (no restrictions)
```

---

## FINAL OBJECTIVES

✓ Stable across all MT5 brokers
✓ No order spam
✓ No overtrading
✓ No simultaneous dual engine
✓ Compatible: HFM, Exness, DooPrime, Markets4you, etc.
✓ Ready for live trading

---

## COMPILATION REQUIREMENTS

✓ Compile without errors
✓ All includes properly linked
✓ No undefined references
✓ Ready for production

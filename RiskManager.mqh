//+------------------------------------------------------------------+
//|                                              RiskManager.mqh     |
//|                                     Copyright 2026, AIK Project  |
//|                                      Project: AIK Trade Manager  |
//+------------------------------------------------------------------+
#property copyright "Ali ihsan KARA"
#property strict

#include "Defines.mqh"

class CRiskManager
{
public:
   CRiskManager() {}
   ~CRiskManager() {}

   // --- Lot Normalizasyon (Broker kurallarına göre dinamik yuvarlama) ---
   double NormalizeLot(string symbol, double lot)
   {
      double step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
      double min  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      double max  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
      
      if(step <= 0) step = 0.01;
      if(min <= 0)  min = 0.01;
      if(max <= 0)  max = 100.0;
      
      double l = MathRound(lot / step) * step;
      
      if(l < min) l = min;
      if(l > max) l = max;
      
      int digits = 0;
      if(step < 1.0) digits = 1;
      if(step < 0.1) digits = 2;
      if(step < 0.01) digits = 3;
      if(step < 0.001) digits = 4;
      if(step < 0.0001) digits = 5;
      
      return NormalizeDouble(l, digits);
   }

   // --- Ana Lot Hesaplama Fonksiyonu ---
   double CalculateLot(string symbol, double entryPrice, double slPrice, ENUM_RISK_MODE mode, double riskValue, double &outRiskMoney)
   {
      double distSL = MathAbs(entryPrice - slPrice);
      if(distSL == 0) {
         outRiskMoney = 0;
         return 0; // Sıfıra bölünme hatasını engelle
      }

      double balance  = AccountInfoDouble(ACCOUNT_BALANCE); 
      double tickVal  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      
      if(tickSize <= 0) tickSize = SymbolInfoDouble(symbol, SYMBOL_POINT);
      
      if(tickVal <= 0) {
         SymbolInfoDouble(symbol, SYMBOL_BID); 
         tickVal = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
         if(tickVal <= 0) return 0;
      }

      double rawLot = 0;
      double riskAmount = 0;

      switch(mode)
      {
         case RISK_PERCENT:
            riskAmount = balance * (riskValue / 100.0);
            rawLot = riskAmount / ((distSL / tickSize) * tickVal);
            break;
            
         case RISK_MONEY:
            riskAmount = riskValue;
            rawLot = riskAmount / ((distSL / tickSize) * tickVal);
            break;
            
         case RISK_LOT:
            rawLot = riskValue;
            riskAmount = rawLot * ((distSL / tickSize) * tickVal);
            break;
      }
      
      outRiskMoney = riskAmount;
      return NormalizeLot(symbol, rawLot);
   }
   
   // --- Kâr (Reward) Hesaplama ---
   double CalculateReward(string symbol, double entryPrice, double tpPrice, double lot)
   {
      double tickVal  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      if(tickSize <= 0) tickSize = SymbolInfoDouble(symbol, SYMBOL_POINT);
      if(tickVal <= 0) return 0;
      
      double distTP = MathAbs(entryPrice - tpPrice);
      return lot * ((distTP / tickSize) * tickVal);
   }
};
//+------------------------------------------------------------------+
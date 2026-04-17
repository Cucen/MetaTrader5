//+------------------------------------------------------------------+
//|                                                 TradeEngine.mqh  |
//|                                     Copyright 2026, AIK Project  |
//|                                      Project: AIK Trade Manager  |
//+------------------------------------------------------------------+
#property copyright "Ali ihsan KARA"
#property strict

#include <Trade\Trade.mqh>
#include "Defines.mqh"

class CTradeEngine
{
private:
   CTrade         m_trade;        // Standart kütüphane nesnesi
   int            m_magic;        // Magic Number
   int            m_slippage;     // Sapma (Deviation)
   
public:
   CTradeEngine() { }
   ~CTradeEngine() { }

   void Init(int magic, int slippage)
   {
      m_magic = magic;
      m_slippage = slippage;
      m_trade.SetExpertMagicNumber(m_magic);
      m_trade.SetDeviationInPoints(m_slippage);
      m_trade.SetTypeFilling(ORDER_FILLING_IOC); 
      m_trade.SetAsyncMode(false); 
   }

   bool CloseTicket(ulong ticket)
   {
      if(m_trade.PositionClose(ticket)) {
         Print("AIK_Engine: Pozisyon Kapatıldı. Ticket: ", ticket);
         return true;
      }
      Print("AIK_Engine: Kapatma Hatası! Kod: ", m_trade.ResultRetcode());
      return false;
   }
   
   bool ClosePartialPct(ulong ticket, double volumePct)
   {
      if(!PositionSelectByTicket(ticket)) return false;
      double totalVol = PositionGetDouble(POSITION_VOLUME);
      double closeVol = totalVol * (volumePct / 100.0);
      return ClosePartialLot(ticket, closeVol);
   }
   
   bool ClosePartialLot(ulong ticket, double lotAmount)
   {
      if(!PositionSelectByTicket(ticket)) return false;
      
      double totalVol = PositionGetDouble(POSITION_VOLUME);
      string symbol   = PositionGetString(POSITION_SYMBOL);
      double step     = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
      double min      = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      
      double closeVol = MathFloor(lotAmount / step) * step;
      
      if(closeVol < min) {
         Print("AIK_Engine: Kısmi kapanış miktarı çok düşük (" + DoubleToString(closeVol, 3) + "). İptal.");
         return false;
      }
      
      if((totalVol - closeVol) < min) closeVol = totalVol;
      
      if(m_trade.PositionClosePartial(ticket, closeVol)) {
         Print("AIK_Engine: Kısmi Kapanış Başarılı. Ticket: ", ticket, " Closed: ", closeVol);
         return true;
      }
      
      Print("AIK_Engine: Kısmi Kapatma Hatası! Kod: ", m_trade.ResultRetcode());
      return false;
   }

   bool DeleteTicket(ulong ticket)
   {
      if(m_trade.OrderDelete(ticket)) {
         Print("AIK_Engine: Emir Silindi. Ticket: ", ticket);
         return true;
      }
      Print("AIK_Engine: Silme Hatası! Kod: ", m_trade.ResultRetcode());
      return false;
   }

   void CloseAll(string symbol)
   {
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0 && PositionGetInteger(POSITION_MAGIC) == m_magic && PositionGetString(POSITION_SYMBOL) == symbol) {
            m_trade.PositionClose(ticket);
         }
      }
      for(int i = OrdersTotal() - 1; i >= 0; i--) {
         ulong ticket = OrderGetTicket(i);
         if(ticket > 0 && OrderGetInteger(ORDER_MAGIC) == m_magic && OrderGetString(ORDER_SYMBOL) == symbol) {
            m_trade.OrderDelete(ticket);
         }
      }
   }

   bool ModifyPosition(ulong ticket, double sl, double tp)
   {
      if(m_trade.PositionModify(ticket, sl, tp)) return true;
      return false;
   }

   // --- Yeni İşlem Açma (GÜVENLİK FİLTRESİ EKLENDİ) ---
   ulong OpenOrder(int type, double lot, string symbol, double price, double sl, double tp)
   {
      // LOT GÜVENLİK KONTROLÜ
      double minVol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      double maxVol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
      if(minVol <= 0) minVol = 0.01;
      
      if(lot < minVol) {
         Print("AIK_Engine: İPTAL! Hesaplanan lot (", DoubleToString(lot, 3), "), minimum hacimden (", DoubleToString(minVol, 3), ") küçük veya hatalı.");
         return 0; // İşlemi durdur
      }
      if(maxVol > 0 && lot > maxVol) {
         Print("AIK_Engine: İPTAL! Hesaplanan lot (", DoubleToString(lot, 3), "), maksimum hacmi (", DoubleToString(maxVol, 3), ") aşıyor.");
         return 0; // İşlemi durdur
      }

      bool res = false;
      switch(type) {
         case 1: res = m_trade.Buy(lot, symbol, 0, sl, tp); break;         
         case 2: res = m_trade.Sell(lot, symbol, 0, sl, tp); break;        
         case 3: res = m_trade.BuyLimit(lot, price, symbol, sl, tp); break;
         case 4: res = m_trade.SellLimit(lot, price, symbol, sl, tp); break;
         case 5: res = m_trade.BuyStop(lot, price, symbol, sl, tp); break;
         case 6: res = m_trade.SellStop(lot, price, symbol, sl, tp); break;
      }

      if(res && (m_trade.ResultRetcode() == TRADE_RETCODE_DONE || m_trade.ResultRetcode() == TRADE_RETCODE_PLACED)) {
         ulong ticket = m_trade.ResultOrder();
         Print("AIK_Engine: İşlem Başarılı. Ticket: ", ticket, " Lot: ", DoubleToString(lot, 3));
         return ticket;
      }
      
      Print("AIK_Engine: İşlem Hatası! Kod: ", m_trade.ResultRetcode(), " Açıklama: ", m_trade.ResultRetcodeDescription(), " Gönderilen Lot: ", DoubleToString(lot, 3));
      return 0;
   }
};
//+------------------------------------------------------------------+
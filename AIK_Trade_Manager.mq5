//+------------------------------------------------------------------+
//|                             AIK_Trade_Manager.mq5                |
//|                             Copyright 2026, PROJE 1 (AIK)        |
//|                             Project: AIK Trade Manager           |
//| Version: 31.0 (PERFORMANCE UPDATE: Timer & Event Optimization)   |
//+------------------------------------------------------------------+
#property copyright "Ali ihsan KARA"
#property link      "https://www.mql5.com"
#property version   "31.0" 
#property description "AIK Trade Manager - Ultimate Edition"
#property strict

// --- MODÜLER BAĞLANTILAR ---
#include <AIK_TradeManager\Defines.mqh> 
#include <AIK_TradeManager\TradeEngine.mqh>
#include <AIK_TradeManager\RiskManager.mqh>
#include <AIK_TradeManager\Utilities.mqh>
#include <AIK_TradeManager\PanelUI.mqh>
#include <AIK_TradeManager\SetupManager.mqh>
#include <Trade\Trade.mqh> 

// ======================================================================================
// 2. GİRİŞ PARAMETRELERİ
// ======================================================================================

input group "=== PANEL VE TASARIM AYARLARI ==="
input bool             InpStrictTrend    = true;            // Trend Filtresi (Strict Mode)
input bool             InpEnableTerminal = true;            // Dahili Terminali Göster
input int              InpToolTimeOffset = 5;               // Tool Sağ Ofset (Bar Sayısı)
input bool             InpEnableToolDrag = true;            // Tool'u SL/TP alanından sürükle

input group "=== SD ŞABLONLARI (SPL & EXT) ==="
input ENUM_SPL_MODE    InpSplMode        = SPL_AGGRESSIVE;  // SPL Çalışma Modu
input int              InpAggressiveSLOffset = 0;           // Aggressive Mod SL Offset (Puan)
input string           InpSdPattern_SPL   = "3.5, 2.5, 2.0"; // SPL Modu: Max, Mid, Low (Sıralı)
input string           InpSdPattern_EXT   = "2.0, 3.0, 4.0"; // EXT Modu: 1. Hedef, 2. Hedef...

input group "=== BAŞLANGIÇ AYARLARI ==="
input ENUM_RISK_MODE InpDefaultMode     = RISK_PERCENT;  // Varsayılan Risk Modu
input double         InpDefaultValue    = 1.0;            // Başlangıç Değeri (%, Para veya Lot)
input int            InpStartDistPx     = 100;            // Çizgilerin Fiyata Uzaklığı (Pixel)

input group "=== RİSK YÖNETİMİ AYARLARI ==="
input double         InpDefRiskPct      = 1.0;            // Varsayılan Risk (%)
input double         InpStepRiskPct     = 0.25;           // Risk Artış/Azalış Adımı (%)
input double         InpDefRiskMoney    = 100.0;          // Varsayılan Risk (Para)
input double         InpStepRiskMoney   = 50.0;           // Risk Artış/Azalış Adımı (Para)
input double         InpDefRiskLot      = 1.0;            // Varsayılan Risk (Sabit Lot)
input double         InpStepRiskLot     = 1.0;            // Risk Artış/Azalış Adımı (Lot)

input group "=== ÇOKLU TP (PARÇALI KAPANIŞ) ==="
input double         InpDefTP2Pct       = 50.0;           // TP2 Kapanış Miktarı (%)
input double         InpDefTP3Pct       = 50.0;           // TP3 Kapanış Miktarı (%)
input double         InpDefTP4Pct       = 50.0;           // TP4 Kapanış Miktarı (%)

input group "=== DİNAMİK IŞINLAR (GUIDE RAYS) ==="
input bool           InpUseGuideRays    = true;             // Dinamik Işınları Göster
input color          InpGuideColor      = clrOrange;        // Işın Rengi
input ENUM_LINE_STYLE InpGuideStyle     = STYLE_DOT;        // Işın Stili
input int            InpGuideWidth      = 1;                // Işın Kalınlığı

input group "=== KLAVYE KISAYOLLARI ==="
input string         KeyBuyMkt  = "S";                     // Alış (Market) Tuşu
input string         KeySellMkt = "A";                     // Satış (Market) Tuşu
input string         KeyBuyLmt  = "X";                     // Alış (Limit) Tuşu
input string         KeySellLmt = "Q";                     // Satış (Limit) Tuşu 
input string         KeyBuyStp  = "W";                     // Alış (Stop) Tuşu
input string         KeySellStp = "Z";                     // Satış (Stop) Tuşu 
input string         KeyExecute = "Enter";                 // EMRİ GÖNDER (Execute)
input string         KeyCancel  = "Esc";                   // İPTAL ET (Cancel)
input string         KeyClose   = "C";                     // POZİSYONLARI KAPAT (Close)
input string         KeyTP2     = "2";                     // TP2 Aktif/Pasif
input string         KeyTP3     = "3";                     // TP3 Aktif/Pasif
input string         KeyTP4     = "4";                     // TP4 Aktif/Pasif
input string         KeyBE      = "B";                     // Break-Even (BE) Çizgisi

input group "=== İŞLEM MOTORU AYARLARI ==="
input bool           InpVisualLevels    = true;             // Görsel Fiyat Tetiklemesi (Makası Yoksay)
input bool           InpEnableBE        = false;            // Varsayılan Olarak BE Açık Olsun
input bool           InpCoverSpread     = true;             // BE Yaparken Spread'i Koru
input int            InpMagicNum        = 666;              // Magic Number (Kimlik No)
input int            InpSlippage        = 10;               // Slippage (Maksimum Sapma Puanı)

input group "=== RENK VE GÖRSEL AYARLAR ==="
input bool           InpShowChartExec   = true;             // Grafik Üzerinde "EXEC" Butonu Göster
input color          InpColorEntry      = clrGray;          // Giriş Çizgisi Rengi
input color          InpColorSL         = clrRed;           // Stop Loss Rengi
input color          InpColorTP         = clrGreen;         // Take Profit Rengi
input color          InpColorBE         = clrGold;          // Break-Even Çizgi Rengi
input color          InpColorFillLoss   = C'255,220,220';   // Zarar Bölgesi Dolgusu
input color          InpColorFillWin    = C'220,255,220';   // Kar Bölgesi Dolgusu
input color          InpColorGhostWin   = 13172680;         // Ghost Modu (Kazanç) Rengi
input color          InpColorGhostLoss  = 13353215;         // Ghost Modu (Kayıp) Rengi
input int            InpLineWidth       = 1;                // Çizgi Kalınlığı
input int            InpMagnetSens      = 40;               // Mıknatıs Hassasiyeti (Pixel)

// ======================================================================================
// 3. GLOBAL NESNELER
// ======================================================================================

CTradeEngine    Engine; 
CRiskManager    RiskManager;
CPanelUI        Panel;
CSetupManager   Setup;
CTrade          ExtTrade; 

ulong  glbTickCounter = 0;
int    lastTrendDir = 0;
bool   isTrendSyncActive = true; 
bool   isMouseOverPanel = false;
bool   isSplitMode = true;       

string gvSync = ""; 
string gvSplit = ""; 
string gvMin  = "";
string gvIndiHeartbeat = ""; 
string gvIndiState = ""; 
string gvCmdTrigger = ""; 
string gvPanelActive = ""; 

ENUM_RISK_MODE CurrentRiskMode;

long codeBuyM, codeSellM, codeBuyL, codeSellL, codeBuyS, codeSellS;
long codeExecute, codeCancel, codeClose, codeTP2, codeTP3, codeTP4, codeBE;

// ======================================================================================
// 4. YARDIMCI FONKSİYONLAR
// ======================================================================================

void RemoveGUI() {
   Panel.Destroy();
}

int CountTrades() {
   int total = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) { if(PositionGetTicket(i)>0 && PositionGetInteger(POSITION_MAGIC)==InpMagicNum && PositionGetString(POSITION_SYMBOL)==_Symbol) total++; }
   for(int i = OrdersTotal() - 1; i >= 0; i--) { if(OrderGetTicket(i)>0 && OrderGetInteger(ORDER_MAGIC)==InpMagicNum && OrderGetString(ORDER_SYMBOL)==_Symbol) total++; }
   return total;
}

void GetIndicatorLevels(double &outTP, double &outSL) {
   outTP = 0; outSL = 0;
   if(!isTrendSyncActive) return;
   
   if(!GlobalVariableCheck(gvIndiHeartbeat)) return;
   
   double pwr = 0.0; 
   if(GlobalVariableCheck(gvIndiState)) pwr = GlobalVariableGet(gvIndiState);
   
   if(pwr < 0.5) return; 

   if(ObjectFind(0, NAME_Indi_Ray_TP) >= 0) outTP = ObjectGetDouble(0, NAME_Indi_Ray_TP, OBJPROP_PRICE);
   if(ObjectFind(0, NAME_Indi_Ray_SL) >= 0) outSL = ObjectGetDouble(0, NAME_Indi_Ray_SL, OBJPROP_PRICE);
}

void CreateTriggerLinesWithLots(ulong ticket, double lot2, double lot3, double lot4) {
   if(Setup.IsBE && ObjectFind(0, NAME_LineBE) >= 0) {
      double bePrice = ObjectGetDouble(0, NAME_LineBE, OBJPROP_PRICE);
      string tName = "BE_Trigger_" + (string)ticket;
      ObjectCreate(0, tName, OBJ_HLINE, 0, 0, bePrice); 
      ObjectSetInteger(0, tName, OBJPROP_COLOR, InpColorBE);
      ObjectSetInteger(0, tName, OBJPROP_STYLE, STYLE_DASH); 
      ObjectSetString(0, tName, OBJPROP_TEXT, "BE #"+(string)ticket);
      ObjectSetString(0, tName, OBJPROP_TOOLTIP, IntegerToString(glbTickCounter));
   }
   
   if(Setup.IsTP2 && lot2 > 0) {
      double p = Setup.m_tpPrice2; 
      string tName = "AIK_Trig_TP2_" + (string)ticket;
      ObjectCreate(0, tName, OBJ_HLINE, 0, 0, p); 
      ObjectSetDouble(0, tName, OBJPROP_PRICE, p); 
      ObjectSetInteger(0, tName, OBJPROP_COLOR, InpColorTP);
      ObjectSetInteger(0, tName, OBJPROP_STYLE, STYLE_DASHDOT); 
      ObjectSetString(0, tName, OBJPROP_TEXT, "TP2 #"+(string)ticket + " VOL=" + DoubleToString(lot2, 2));
      ObjectSetString(0, tName, OBJPROP_TOOLTIP, IntegerToString(glbTickCounter));
   }
   
   if(Setup.IsTP3 && lot3 > 0) {
      double p = Setup.m_tpPrice3; 
      string tName = "AIK_Trig_TP3_" + (string)ticket;
      ObjectCreate(0, tName, OBJ_HLINE, 0, 0, p); 
      ObjectSetDouble(0, tName, OBJPROP_PRICE, p); 
      ObjectSetInteger(0, tName, OBJPROP_COLOR, InpColorTP);
      ObjectSetInteger(0, tName, OBJPROP_STYLE, STYLE_DASHDOT); 
      ObjectSetString(0, tName, OBJPROP_TEXT, "TP3 #"+(string)ticket + " VOL=" + DoubleToString(lot3, 2));
      ObjectSetString(0, tName, OBJPROP_TOOLTIP, IntegerToString(glbTickCounter));
   }
   
   if(Setup.IsTP4 && lot4 > 0) {
      double p = Setup.m_tpPrice4; 
      string tName = "AIK_Trig_TP4_" + (string)ticket;
      ObjectCreate(0, tName, OBJ_HLINE, 0, 0, p); 
      ObjectSetDouble(0, tName, OBJPROP_PRICE, p); 
      ObjectSetInteger(0, tName, OBJPROP_COLOR, InpColorTP);
      ObjectSetInteger(0, tName, OBJPROP_STYLE, STYLE_DASHDOT); 
      ObjectSetString(0, tName, OBJPROP_TEXT, "TP4 #"+(string)ticket + " VOL=" + DoubleToString(lot4, 2));
      ObjectSetString(0, tName, OBJPROP_TOOLTIP, IntegerToString(glbTickCounter));
   }
}

// ======================================================================================
// 5. GUI YÖNETİMİ
// ======================================================================================

void UpdateButtons() {
   string text = ""; color bg = clrBtnGray;
   switch(CurrentRiskMode) {
      case RISK_PERCENT: text = "R%"; bg = clrBtnRisk; break;
      case RISK_MONEY:   text = "R$"; bg = clrBtnActive; break;
      case RISK_LOT:     text = "RL"; bg = clrBtnExec;   break;
   }
   ObjectSetString(0, NAME_BtnRiskMode, OBJPROP_TEXT, text); ObjectSetInteger(0, NAME_BtnRiskMode, OBJPROP_BGCOLOR, bg);

   ObjectSetInteger(0, NAME_BtnTP2, OBJPROP_BGCOLOR, Setup.IsTP2 ? clrBtnActive : clrBtnGray); ObjectSetInteger(0, NAME_BtnTP2, OBJPROP_STATE, false);
   CUtilities::SetVisible(NAME_EditTP2, true); 
   ObjectSetInteger(0, NAME_EditTP2, OBJPROP_READONLY, !Setup.IsTP2);
   ObjectSetInteger(0, NAME_EditTP2, OBJPROP_BGCOLOR, Setup.IsTP2 ? clrInputBG : clrBtnGray);
   
   ObjectSetInteger(0, NAME_BtnTP3, OBJPROP_BGCOLOR, Setup.IsTP3 ? clrBtnActive : clrBtnGray); ObjectSetInteger(0, NAME_BtnTP3, OBJPROP_STATE, false);
   CUtilities::SetVisible(NAME_EditTP3, true); 
   ObjectSetInteger(0, NAME_EditTP3, OBJPROP_READONLY, !Setup.IsTP3); 
   ObjectSetInteger(0, NAME_EditTP3, OBJPROP_BGCOLOR, Setup.IsTP3 ? clrInputBG : clrBtnGray);
   
   ObjectSetInteger(0, NAME_BtnTP4, OBJPROP_BGCOLOR, Setup.IsTP4 ? clrBtnActive : clrBtnGray); ObjectSetInteger(0, NAME_BtnTP4, OBJPROP_STATE, false);
   CUtilities::SetVisible(NAME_EditTP4, true); 
   ObjectSetInteger(0, NAME_EditTP4, OBJPROP_READONLY, !Setup.IsTP4); 
   ObjectSetInteger(0, NAME_EditTP4, OBJPROP_BGCOLOR, Setup.IsTP4 ? clrInputBG : clrBtnGray);
   
   ObjectSetInteger(0, NAME_BtnBE, OBJPROP_BGCOLOR, Setup.IsBE ? clrBtnActive : clrBtnGray); ObjectSetInteger(0, NAME_BtnBE, OBJPROP_STATE, false);
   
   Panel.UpdateModeButton(isSplitMode);
   Setup.SetSplitMode(isSplitMode);
   
   if(Setup.IsLinesActive) {
      ObjectSetInteger(0, NAME_BtnCancel, OBJPROP_BGCOLOR, clrBtnCancelActive); 
      
      if(Setup.IsModificationMode) {
         ObjectSetString(0, NAME_BtnExecute, OBJPROP_TEXT, "MODIFY"); 
         ObjectSetInteger(0, NAME_BtnExecute, OBJPROP_BGCOLOR, clrBtnActive); 
         if(ObjectFind(0, NAME_BtnMiniExec) >= 0) ObjectSetString(0, NAME_BtnMiniExec, OBJPROP_TEXT, "MOD");
      } else {
         ObjectSetString(0, NAME_BtnExecute, OBJPROP_TEXT, "EXECUTE"); 
         ObjectSetInteger(0, NAME_BtnExecute, OBJPROP_BGCOLOR, clrBtnExec); 
         if(ObjectFind(0, NAME_BtnMiniExec) >= 0) ObjectSetString(0, NAME_BtnMiniExec, OBJPROP_TEXT, "EXEC");
      }
      
      if(ObjectFind(0, NAME_BtnMiniExec) >= 0) ObjectSetInteger(0, NAME_BtnMiniExec, OBJPROP_BGCOLOR, Setup.IsModificationMode ? clrBtnActive : clrBtnExec);
   } else {
      ObjectSetInteger(0, NAME_BtnCancel, OBJPROP_BGCOLOR, clrBtnGray); 
      ObjectSetInteger(0, NAME_BtnExecute, OBJPROP_BGCOLOR, clrBtnGray);
      ObjectSetString(0, NAME_BtnExecute, OBJPROP_TEXT, "EXECUTE");
      if(ObjectFind(0, NAME_BtnMiniExec) >= 0) { ObjectSetInteger(0, NAME_BtnMiniExec, OBJPROP_BGCOLOR, clrBtnGray); ObjectSetString(0, NAME_BtnMiniExec, OBJPROP_TEXT, "EXEC"); }
   }
   
   if(ObjectFind(0, NAME_BtnSync) >= 0) {
      color syncCol = clrBtnSyncOff; 
      string syncTxt = "SYNC";
      
      if(isTrendSyncActive) { 
         if(GlobalVariableCheck(gvIndiHeartbeat)) {
            double pwr = 0.0; 
            if(GlobalVariableCheck(gvIndiState)) pwr = GlobalVariableGet(gvIndiState);
            
            if(pwr > 0.5) {
               syncCol = clrBtnSyncOn; 
               syncTxt = "SYNC";
            } else {
               syncCol = C'255,140,0'; 
               syncTxt = "AIK OFF";
            }
         } else {
            syncCol = clrOrangeRed; 
            syncTxt = "NO SIG";
         }
      }
      
      ObjectSetInteger(0, NAME_BtnSync, OBJPROP_BGCOLOR, syncCol);
      ObjectSetString(0, NAME_BtnSync, OBJPROP_TEXT, syncTxt);
   }
   
   color closeClr = (CountTrades() > 0) ? clrBtnClose : clrBtnGray;
   if(ObjectFind(0, NAME_BtnClose) >= 0) ObjectSetInteger(0, NAME_BtnClose, OBJPROP_BGCOLOR, closeClr);
   if(ObjectFind(0, NAME_BtnMiniClose) >= 0) ObjectSetInteger(0, NAME_BtnMiniClose, OBJPROP_BGCOLOR, closeClr);
   
   ChartRedraw();
}

// ======================================================================================
// 6. OPERASYONLAR
// ======================================================================================

void ExecuteOrder() {
   if(!Setup.IsLinesActive) return;
   
   if(Setup.IsModificationMode) {
      Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct);
      double newSL = ObjectGetDouble(0, NAME_LineSL, OBJPROP_PRICE);
      double newTP = ObjectGetDouble(0, NAME_LineTP1, OBJPROP_PRICE);
      double newEntry = ObjectGetDouble(0, NAME_LineEntry, OBJPROP_PRICE); 
      
      if(InpVisualLevels && Setup.RecalledTicket > 0) {
         double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
         bool isSellMod = false;
         if(PositionSelectByTicket(Setup.RecalledTicket)) {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) isSellMod = true;
         } else if(OrderSelect(Setup.RecalledTicket)) {
            long t = OrderGetInteger(ORDER_TYPE);
            if(t == ORDER_TYPE_SELL || t == ORDER_TYPE_SELL_LIMIT || t == ORDER_TYPE_SELL_STOP || t == ORDER_TYPE_SELL_STOP_LIMIT) isSellMod = true;
         }
         if(isSellMod) {
            if(newSL > 0) newSL += spread;
            if(newTP > 0) newTP += spread;
         }
      }
      
      if(Setup.RecalledTicket > 0) {
         if(OrderSelect(Setup.RecalledTicket)) {
            ExtTrade.SetExpertMagicNumber(InpMagicNum);
            ExtTrade.OrderModify(Setup.RecalledTicket, newEntry, newSL, newTP, ORDER_TIME_GTC, 0);
         }
         else if(PositionSelectByTicket(Setup.RecalledTicket)) {
            Engine.ModifyPosition(Setup.RecalledTicket, newSL, newTP);
         }
         
         double curVol = 0;
         if(PositionSelectByTicket(Setup.RecalledTicket)) curVol = PositionGetDouble(POSITION_VOLUME);
         else if(OrderSelect(Setup.RecalledTicket)) curVol = OrderGetDouble(ORDER_VOLUME_INITIAL);
         
         if(curVol > 0) {
            double l2 = Setup.Lot_TP2; double l3 = Setup.Lot_TP3; double l4 = Setup.Lot_TP4;
            for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) {
               string name = ObjectName(0, i);
               if(StringFind(name, "_" + (string)Setup.RecalledTicket) > 0) ObjectDelete(0, name);
            }
            CreateTriggerLinesWithLots(Setup.RecalledTicket, l2, l3, l4);
         }
         Setup.RemoveSetup(); 
         UpdateButtons();
      }
      return; 
   }

   Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); 
   double entry = ObjectGetDouble(0, NAME_LineEntry, OBJPROP_PRICE);
   double sl    = ObjectGetDouble(0, NAME_LineSL, OBJPROP_PRICE);
   double tp1   = ObjectGetDouble(0, NAME_LineTP1, OBJPROP_PRICE);
   double userRisk = StringToDouble(ObjectGetString(0, NAME_EditRiskVal, OBJPROP_TEXT));
   double riskMoneyReal = 0;
   double totalLot = RiskManager.CalculateLot(_Symbol, entry, sl, CurrentRiskMode, userRisk, riskMoneyReal);
   
   int finalOrderType = Setup.ActiveOrderType; 
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double slippagePoints = InpSlippage * point; 
   
   bool isBuySetup  = (Setup.ActiveOrderType == 1 || Setup.ActiveOrderType == 3 || Setup.ActiveOrderType == 5);
   bool isSellSetup = (Setup.ActiveOrderType == 2 || Setup.ActiveOrderType == 4 || Setup.ActiveOrderType == 6);
   
   if(isBuySetup) {
      if (entry > ask + slippagePoints) finalOrderType = 5; 
      else if (entry < ask - slippagePoints) finalOrderType = 3; 
      else finalOrderType = 1; 
   } 
   else if(isSellSetup) {
      if (entry < bid - slippagePoints) finalOrderType = 6; 
      else if (entry > bid + slippagePoints) finalOrderType = 4; 
      else finalOrderType = 2; 
   }
   
   double final_sl = sl;
   double final_tp = tp1;
   
   if(InpVisualLevels && isSellSetup) {
      double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
      if(final_sl > 0) final_sl += spread;
      if(final_tp > 0) final_tp += spread;
   }
   
   double l2 = Setup.Lot_TP2; double l3 = Setup.Lot_TP3; double l4 = Setup.Lot_TP4;
   ulong ticket = Engine.OpenOrder(finalOrderType, totalLot, _Symbol, entry, final_sl, final_tp);
   if(ticket > 0) CreateTriggerLinesWithLots(ticket, l2, l3, l4);
   Setup.RemoveSetup();
   UpdateButtons();
}

void ManageOpenTrades() {
   if(PositionsTotal() == 0) return;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i); 
      if(PositionGetInteger(POSITION_MAGIC) != InpMagicNum) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      string beLine = "BE_Trigger_" + (string)ticket;
      if(ObjectFind(0, beLine) >= 0) {
         double bePrice = ObjectGetDouble(0, beLine, OBJPROP_PRICE);
         
         double currentPrice = InpVisualLevels ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : ((PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK));
         bool triggered = (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) ? (currentPrice >= bePrice) : (currentPrice <= bePrice);
         
         if(triggered) {
            double newSL = PositionGetDouble(POSITION_PRICE_OPEN);
            double spread = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD)*_Point;
            
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) {
               if(InpCoverSpread) newSL += spread; 
            } else {
               if(InpVisualLevels) newSL += spread; 
               if(InpCoverSpread) newSL -= spread;  
            }
            
            double curSL = PositionGetDouble(POSITION_SL);
            bool mod = (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) ? (curSL < newSL || curSL==0) : (curSL > newSL || curSL==0);
            if(mod) { if(Engine.ModifyPosition(ticket, newSL, PositionGetDouble(POSITION_TP))) ObjectDelete(0, beLine); }
         }
      }
      CheckPartialTriggerSmart(ticket, "AIK_Trig_TP2_");
      CheckPartialTriggerSmart(ticket, "AIK_Trig_TP3_");
      CheckPartialTriggerSmart(ticket, "AIK_Trig_TP4_");
   }
}

void CheckPartialTriggerSmart(ulong ticket, string prefix) {
   string lineName = prefix + (string)ticket;
   if(ObjectFind(0, lineName) >= 0) {
      double triggerPrice = ObjectGetDouble(0, lineName, OBJPROP_PRICE);
      
      double currentPrice = InpVisualLevels ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : ((PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK));
      bool hit = (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) ? (currentPrice >= triggerPrice) : (currentPrice <= triggerPrice);
      
      if(hit) {
         string text = ObjectGetString(0, lineName, OBJPROP_TEXT);
         int idx = StringFind(text, "VOL=");
         if(idx >= 0) {
            string sLot = StringSubstr(text, idx + 4); 
            double closeLot = StringToDouble(sLot);
            if(closeLot > 0) { if(Engine.ClosePartialLot(ticket, closeLot)) { ObjectDelete(0, lineName); PlaySound("Ok.wav"); } }
         }
      }
   }
}

void CleanupOrphanedLines() {
   for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) {
      string name = ObjectName(0, i);
      if(StringFind(name, "BE_Trigger_") == 0 || StringFind(name, "AIK_Trig_") == 0) {
         string strBirth = ObjectGetString(0, name, OBJPROP_TOOLTIP); 
         if(glbTickCounter - (ulong)StringToInteger(strBirth) < 5) continue; 
         int lastUnderscore = StringFindReverse(name, "_");
         if(lastUnderscore > 0) {
            ulong ticket = (ulong)StringToInteger(StringSubstr(name, lastUnderscore + 1)); 
            if(!PositionSelectByTicket(ticket)) { if(!OrderSelect(ticket)) ObjectDelete(0, name); }
         }
      }
   }
}

int StringFindReverse(string text, string match) {
   for(int i = StringLen(text) - 1; i >= 0; i--) {
      if(StringSubstr(text, i, 1) == match) return i;
   }
   return -1;
}

void Handle_Button_Click(string sparam) {
   if(sparam == Setup.GetExecBtnName()) { ExecuteOrder(); return; }
   if(StringFind(sparam, "AIK_TM_Lbl_") >= 0) return;
   
   if(sparam == "AIK_TM_Btn_Mode_ExtSpl") { isSplitMode = !isSplitMode; UpdateButtons(); return; }
   
   if(StringFind(sparam, "AIK_Trm_Pos_Bg_") >= 0) {
      ulong ticket = (ulong)StringToInteger(StringSubstr(sparam, 15));
      if(PositionSelectByTicket(ticket)) {
         long type = PositionGetInteger(POSITION_TYPE);
         double entry = PositionGetDouble(POSITION_PRICE_OPEN);
         double sl = PositionGetDouble(POSITION_SL);
         double tp = PositionGetDouble(POSITION_TP);
         int setupType = (type == POSITION_TYPE_BUY) ? 1 : 2;
         Setup.RecallSetup(ticket, setupType, entry, sl, tp, false);
         UpdateButtons();
      }
      return; 
   }
   
   if(StringFind(sparam, "AIK_Trm_Ord_Bg_") >= 0) {
      ulong ticket = (ulong)StringToInteger(StringSubstr(sparam, 15)); 
      if(OrderSelect(ticket)) {
         long type = OrderGetInteger(ORDER_TYPE);
         double entry = OrderGetDouble(ORDER_PRICE_OPEN);
         double sl = OrderGetDouble(ORDER_SL);
         double tp = OrderGetDouble(ORDER_TP);
         int setupType = 0;
         if(type == ORDER_TYPE_BUY_LIMIT || type == ORDER_TYPE_BUY_STOP || type == ORDER_TYPE_BUY_STOP_LIMIT) setupType = 1;
         else if(type == ORDER_TYPE_SELL_LIMIT || type == ORDER_TYPE_SELL_STOP || type == ORDER_TYPE_SELL_STOP_LIMIT) setupType = 2;
         if(setupType > 0) { Setup.RecallSetup(ticket, setupType, entry, sl, tp, true); UpdateButtons(); }
      }
      return;
   }
   
   if(sparam == NAME_BtnMinMax) { Panel.ToggleMinimize(); Panel.UpdatePosition(isTrendSyncActive, lastTrendDir, InpEnableTerminal, InpMagicNum); return; }
   if(sparam == NAME_BtnTerminalToggle && InpEnableTerminal) { Panel.IsTerminalOpen = !Panel.IsTerminalOpen; Panel.UpdatePosition(isTrendSyncActive, lastTrendDir, InpEnableTerminal, InpMagicNum); if(Panel.IsTerminalOpen) Panel.UpdateTerminal(InpMagicNum); ChartRedraw(); return; }
   if(sparam == NAME_BtnSync) { isTrendSyncActive = !isTrendSyncActive; Panel.UpdatePosition(isTrendSyncActive, lastTrendDir, InpEnableTerminal, InpMagicNum); ChartRedraw(); return; }
   
   double iTP = 0, iSL = 0;
   if(isTrendSyncActive) GetIndicatorLevels(iTP, iSL);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   if(sparam == NAME_BtnMiniBuy || sparam == NAME_BtnBuyM) Setup.CreateSetup(1, isTrendSyncActive, lastTrendDir, ask, bid, iTP, iSL);
   else if(sparam == NAME_BtnMiniSell || sparam == NAME_BtnSellM) Setup.CreateSetup(2, isTrendSyncActive, lastTrendDir, ask, bid, iTP, iSL);
   else if(sparam == NAME_BtnBuyL) Setup.CreateSetup(3, isTrendSyncActive, lastTrendDir, ask, bid, iTP, iSL);
   else if(sparam == NAME_BtnSellL) Setup.CreateSetup(4, isTrendSyncActive, lastTrendDir, ask, bid, iTP, iSL);
   else if(sparam == NAME_BtnBuyS) Setup.CreateSetup(5, isTrendSyncActive, lastTrendDir, ask, bid, iTP, iSL);
   else if(sparam == NAME_BtnSellS) Setup.CreateSetup(6, isTrendSyncActive, lastTrendDir, ask, bid, iTP, iSL);
   else if(sparam == NAME_BtnTrendMkt) { 
      if(lastTrendDir == 1) Setup.CreateSetup(2, isTrendSyncActive, lastTrendDir, ask, bid, iTP, iSL); 
      else if(lastTrendDir == -1) Setup.CreateSetup(1, isTrendSyncActive, lastTrendDir, ask, bid, iTP, iSL); 
   }
   else if(sparam == NAME_BtnMiniExec || sparam == NAME_BtnExecute) ExecuteOrder();
   else if(sparam == NAME_BtnMiniClose || sparam == NAME_BtnClose) Engine.CloseAll(_Symbol);
   else if(sparam == NAME_BtnCancel) { Setup.RemoveSetup(); UpdateButtons(); }
   else if(sparam == NAME_BtnPin) { Panel.IsPinned = !Panel.IsPinned; Panel.UpdatePinButton(); }
   else if(sparam == NAME_BtnRiskMode) {
      if(CurrentRiskMode == RISK_PERCENT) { CurrentRiskMode = RISK_MONEY; ObjectSetString(0, NAME_EditRiskVal, OBJPROP_TEXT, DoubleToString(InpDefRiskMoney, 2)); }
      else if(CurrentRiskMode == RISK_MONEY) { CurrentRiskMode = RISK_LOT; ObjectSetString(0, NAME_EditRiskVal, OBJPROP_TEXT, DoubleToString(InpDefRiskLot, 2)); }
      else { CurrentRiskMode = RISK_PERCENT; ObjectSetString(0, NAME_EditRiskVal, OBJPROP_TEXT, DoubleToString(InpDefRiskPct, 2)); }
      Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct);
   }
   else if(sparam == NAME_BtnRiskPlus || sparam == NAME_BtnRiskMinus) {
      double val = StringToDouble(ObjectGetString(0, NAME_EditRiskVal, OBJPROP_TEXT)); double step = 0; int d=2;
      if(CurrentRiskMode == RISK_PERCENT) { step = InpStepRiskPct; } else if(CurrentRiskMode == RISK_MONEY) { step = InpStepRiskMoney; } else { step = InpStepRiskLot; }
      if(sparam == NAME_BtnRiskMinus) step = -step; double newVal = val + step; if(newVal < 0) newVal = 0;
      ObjectSetString(0, NAME_EditRiskVal, OBJPROP_TEXT, DoubleToString(newVal, d)); 
      Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct);
   }
   else if(sparam == NAME_BtnBE) { Setup.IsBE = !Setup.IsBE; if(Setup.IsLinesActive) { if(Setup.IsBE) { double e = ObjectGetDouble(0, NAME_LineEntry, OBJPROP_PRICE); double t = ObjectGetDouble(0, NAME_LineTP1, OBJPROP_PRICE); ObjectCreate(0, NAME_LineBE, OBJ_HLINE, 0, 0, (e+t)/2.0); ObjectSetInteger(0, NAME_LineBE, OBJPROP_COLOR, InpColorBE); } else ObjectDelete(0, NAME_LineBE); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); } }
   else if(sparam == NAME_BtnTP2) { Setup.IsTP2 = !Setup.IsTP2; if(Setup.IsTP2) ObjectSetString(0, NAME_EditTP2, OBJPROP_TEXT, DoubleToString(InpDefTP2Pct, 0)); Setup.RefreshTPs(); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); UpdateButtons(); }
   else if(sparam == NAME_BtnTP3) { Setup.IsTP3 = !Setup.IsTP3; if(Setup.IsTP3) ObjectSetString(0, NAME_EditTP3, OBJPROP_TEXT, DoubleToString(InpDefTP3Pct, 0)); Setup.RefreshTPs(); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); UpdateButtons(); }
   else if(sparam == NAME_BtnTP4) { Setup.IsTP4 = !Setup.IsTP4; if(Setup.IsTP4) ObjectSetString(0, NAME_EditTP4, OBJPROP_TEXT, DoubleToString(InpDefTP4Pct, 0)); Setup.RefreshTPs(); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); UpdateButtons(); }
   
   if(StringFind(sparam, "AIK_Trm_") == 0) {
      if(StringFind(sparam, "_Pos_Btn_") > 0) { 
         ulong t = (ulong)StringToInteger(StringSubstr(sparam, 16)); 
         string btnText = ObjectGetString(0, sparam, OBJPROP_TEXT);
         
         if(btnText == "MOD") { 
             string vName = "AIK_Trm_Pos_Vol_" + (string)t;
             string pName = "AIK_Trm_Pos_Prf_" + (string)t;
             bool isVolPending = (ObjectGetInteger(0, vName, OBJPROP_COLOR) == clrOrange);
             bool isPLPending = (ObjectGetInteger(0, pName, OBJPROP_COLOR) == clrOrange);
             
             if(PositionSelectByTicket(t)) {
                 double currentVol = PositionGetDouble(POSITION_VOLUME);
                 double currentProfit = PositionGetDouble(POSITION_PROFIT);
                 double closeAmount = 0;
                 
                 if(isVolPending) {
                     double typedVol = StringToDouble(ObjectGetString(0, vName, OBJPROP_TEXT));
                     closeAmount = currentVol - typedVol; 
                     if(typedVol >= currentVol) closeAmount = 0; 
                 } else if(isPLPending) {
                     double typedPL = StringToDouble(ObjectGetString(0, pName, OBJPROP_TEXT));
                     double absCurrent = MathAbs(currentProfit);
                     double absTarget = MathAbs(typedPL);
                     if(absCurrent > 0 && absTarget > 0 && absTarget < absCurrent) closeAmount = currentVol * (absTarget / absCurrent);
                 }
                 
                 if(closeAmount > 0 && closeAmount <= currentVol) {
                     if(Engine.ClosePartialLot(t, closeAmount)) {
                         PlaySound("Ok.wav");
                         if(Setup.IsLinesActive && Setup.RecalledTicket == t) Setup.RecallSetup(t, Setup.ActiveOrderType, Setup.m_entryPrice, Setup.m_slPrice, Setup.m_tpPrice, false);
                     } else PlaySound("Timeout.wav");
                 } else PlaySound("Error.wav");
             }
             ObjectSetInteger(0, vName, OBJPROP_COLOR, clrInputTxt); ObjectSetInteger(0, pName, OBJPROP_COLOR, (PositionGetDouble(POSITION_PROFIT)>=0)?clrGreen:clrRed);
             if(Panel.IsTerminalOpen) { Panel.UpdateTerminal(InpMagicNum); ChartRedraw(); }
         } 
         else {
             Engine.CloseTicket(t); if(Panel.IsTerminalOpen) { Sleep(50); Panel.UpdateTerminal(InpMagicNum); ChartRedraw(); } 
         }
      } 
      else if(StringFind(sparam, "_Ord_Btn_") > 0) { ulong t = (ulong)StringToInteger(StringSubstr(sparam, 16)); Engine.DeleteTicket(t); if(Panel.IsTerminalOpen) { Sleep(50); Panel.UpdateTerminal(InpMagicNum); ChartRedraw(); } } 
      return;
   }
   
   Setup.WakeUp(); UpdateButtons(); ObjectSetInteger(0, sparam, OBJPROP_STATE, false); ChartRedraw();
}

void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& request, const MqlTradeResult& result) {
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD || trans.type == TRADE_TRANSACTION_HISTORY_ADD || trans.type == TRADE_TRANSACTION_POSITION) {
      if(InpEnableTerminal && Panel.IsTerminalOpen) { Panel.UpdateTerminal(InpMagicNum); Panel.UpdatePosition(isTrendSyncActive, lastTrendDir, InpEnableTerminal, InpMagicNum); ChartRedraw(); }
      UpdateButtons(); 
   }
}

// --- YENİ: PERFORMANS İÇİN TIMER EKLENDİ ---
void OnTimer() {
   CleanupOrphanedLines();
   // Terminal sadece açıksa güncelle
   if(InpEnableTerminal && Panel.IsTerminalOpen) Panel.UpdateTerminal(InpMagicNum);
   // Butonları sadece gerektiğinde güncelle (trade varsa)
   UpdateButtons();
}

void OnTick() {
   glbTickCounter++; 
   
   if(glbTickCounter % 100 == 0) GlobalVariableSet(gvPanelActive, 1);
   
   // glbTickCounter==1: Sadece ilk tick'te GUI'yi yeniden oluştur
   // NOT: Bu artık sadece bir kez çalışır ve normal tick'lerde GUI'yi yıkıp yeniden yaratmaz
   if(glbTickCounter == 1) { 
      Panel.Destroy();
      Panel.CreateGUI(InpDefaultValue, KeyBuyLmt, KeyBuyStp, KeyBuyMkt, KeySellMkt, KeySellLmt, KeySellStp, KeyCancel, KeyExecute, KeyClose, KeyTP2, KeyTP3, KeyTP4, KeyBE, InpEnableTerminal);
      Panel.UpdatePosition(isTrendSyncActive, lastTrendDir, InpEnableTerminal, InpMagicNum); 
      UpdateButtons();
   }

   bool needRedraw = false;

   if(isTrendSyncActive) {
      if(GlobalVariableCheck(gvIndiHeartbeat)) {
         int tr = (int)GlobalVariableGet(gvIndiHeartbeat);
         double pwr = 0.0; 
         if(GlobalVariableCheck(gvIndiState)) pwr = GlobalVariableGet(gvIndiState);
         if(pwr < 0.5) tr = 0; 

         if(tr != lastTrendDir) { 
            lastTrendDir = tr; 
            Panel.UpdatePosition(isTrendSyncActive, lastTrendDir, InpEnableTerminal, InpMagicNum); 
            needRedraw = true;
         }
         
         if(ObjectFind(0, NAME_BtnTrendMkt) >= 0) {
            if(pwr < 0.5) { ObjectSetString(0, NAME_BtnTrendMkt, OBJPROP_TEXT, "OFF"); ObjectSetInteger(0, NAME_BtnTrendMkt, OBJPROP_BGCOLOR, clrBtnGray); } 
            else {
               if(lastTrendDir == 1) { ObjectSetString(0, NAME_BtnTrendMkt, OBJPROP_TEXT, "SELL"); ObjectSetInteger(0, NAME_BtnTrendMkt, OBJPROP_BGCOLOR, clrBtnSellMkt); } 
               else if(lastTrendDir == -1) { ObjectSetString(0, NAME_BtnTrendMkt, OBJPROP_TEXT, "BUY"); ObjectSetInteger(0, NAME_BtnTrendMkt, OBJPROP_BGCOLOR, clrBtnBuyMkt); } 
               else { ObjectSetString(0, NAME_BtnTrendMkt, OBJPROP_TEXT, "WAIT"); ObjectSetInteger(0, NAME_BtnTrendMkt, OBJPROP_BGCOLOR, clrBtnGray); }
            }
         }
      } else {
         if(lastTrendDir != 0) { lastTrendDir = 0; Panel.UpdatePosition(isTrendSyncActive, lastTrendDir, InpEnableTerminal, InpMagicNum); needRedraw = true; }
         if(ObjectFind(0, NAME_BtnTrendMkt) >= 0) { ObjectSetString(0, NAME_BtnTrendMkt, OBJPROP_TEXT, "---"); ObjectSetInteger(0, NAME_BtnTrendMkt, OBJPROP_BGCOLOR, clrBtnGray); }
      }
      
      if(GlobalVariableCheck(gvCmdTrigger)) {
         int trigDir = (int)GlobalVariableGet(gvCmdTrigger);
         double iTP=0, iSL=0; GetIndicatorLevels(iTP, iSL);
         datetime iTime = 0; if(ObjectFind(0, "AIK_EndLine") >= 0) iTime = (datetime)ObjectGetInteger(0, "AIK_EndLine", OBJPROP_TIME);
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK); double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         if(trigDir == 1) Setup.CreateSetup(2, true, trigDir, ask, bid, iTP, iSL, iTime);
         else if(trigDir == -1) Setup.CreateSetup(1, true, trigDir, ask, bid, iTP, iSL, iTime);
         GlobalVariableDel(gvCmdTrigger);
         needRedraw = true;
      }
   }
   
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK); double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   Setup.OnTickLogic(ask, bid);
   
   // SADECE ÇİZGİLER AKTİFSE HESAPLAMA YAP (Performans)
   if(Setup.IsLinesActive) {
      Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct);
      needRedraw = true;
   }
   
   ManageOpenTrades(); 
   
   // ChartRedraw sadece gerektiğinde
   if(needRedraw) ChartRedraw();
}

int OnInit() {
   Engine.Init(InpMagicNum, InpSlippage); 
   
   // SABİT ATAMALAR SADECE BİR KEZ YAPILIR (Performans)
   Setup.Init(InpColorEntry, InpColorSL, InpColorTP, InpColorBE, InpColorFillLoss, InpColorFillWin, InpStartDistPx, InpLineWidth, InpMagnetSens, InpShowChartExec, InpColorGhostWin, InpColorGhostLoss, InpToolTimeOffset, InpUseGuideRays, InpGuideColor, InpGuideStyle, InpGuideWidth); 
   Setup.SetPatterns(InpSdPattern_SPL, InpSdPattern_EXT);
   Setup.SetEnableToolDrag(InpEnableToolDrag);
   Setup.SetAggressiveSettings(InpSplMode, InpAggressiveSLOffset);
   
   CurrentRiskMode = InpDefaultMode; glbTickCounter = 0;
   
   gvSync = "AIK_State_Sync_" + (string)ChartID(); 
   gvSplit = "AIK_State_Split_" + (string)ChartID(); 
   gvMin  = "AIK_State_Min_" + (string)ChartID();
   gvIndiHeartbeat = "AIK_Trend_" + (string)ChartID(); gvIndiState = "AIK_MainState_" + (string)ChartID();  
   gvCmdTrigger = "AIK_Cmd_Trig_" + (string)ChartID();
   gvPanelActive = "AIK_PANEL_ACTIVE_" + (string)ChartID(); GlobalVariableSet(gvPanelActive, 1);
   
   if(GlobalVariableCheck(gvSync)) isTrendSyncActive = (bool)GlobalVariableGet(gvSync); else isTrendSyncActive = true; 
   if(GlobalVariableCheck(gvSplit)) isSplitMode = (bool)GlobalVariableGet(gvSplit); else isSplitMode = true; 
   if(GlobalVariableCheck(gvMin)) Panel.IsMinimized = (bool)GlobalVariableGet(gvMin); else Panel.IsMinimized = false;
   
   codeBuyM = CUtilities::GetKeyCode(KeyBuyMkt); codeSellM = CUtilities::GetKeyCode(KeySellMkt); codeBuyL = CUtilities::GetKeyCode(KeyBuyLmt); codeSellL = CUtilities::GetKeyCode(KeySellLmt); 
   codeBuyS = CUtilities::GetKeyCode(KeyBuyStp); codeSellS = CUtilities::GetKeyCode(KeySellStp); codeTP2 = CUtilities::GetKeyCode(KeyTP2); codeTP3 = CUtilities::GetKeyCode(KeyTP3); codeTP4 = CUtilities::GetKeyCode(KeyTP4); codeBE = CUtilities::GetKeyCode(KeyBE); 
   codeExecute= CUtilities::GetKeyCode(KeyExecute); codeCancel= CUtilities::GetKeyCode(KeyCancel); codeClose = CUtilities::GetKeyCode(KeyClose); 
   if(KeyExecute == "Enter") codeExecute = 13; if(KeyCancel == "Esc") codeCancel = 27;
   
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true); ChartSetInteger(0, CHART_SHOW_OBJECT_DESCR, true);
   Panel.Destroy(); 
   Panel.CreateGUI(InpDefaultValue, KeyBuyLmt, KeyBuyStp, KeyBuyMkt, KeySellMkt, KeySellLmt, KeySellStp, KeyCancel, KeyExecute, KeyClose, KeyTP2, KeyTP3, KeyTP4, KeyBE, InpEnableTerminal);
   Panel.UpdatePosition(isTrendSyncActive, lastTrendDir, InpEnableTerminal, InpMagicNum);
   UpdateButtons();
   
   // PERFORMANS İÇİN TIMER BAŞLATILDI (1 Saniye)
   EventSetMillisecondTimer(1000);
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) { 
   EventKillTimer(); // Timer'ı kapat
   GlobalVariableSet(gvSync, isTrendSyncActive); 
   GlobalVariableSet(gvSplit, isSplitMode); 
   GlobalVariableSet(gvMin, Panel.IsMinimized);
   if(GlobalVariableCheck(gvPanelActive)) GlobalVariableDel(gvPanelActive);
   ChartSetInteger(0, CHART_DRAG_TRADE_LEVELS, true); ChartSetInteger(0, CHART_MOUSE_SCROLL, true);
   
   // Setup tool objelerini temizle
   Setup.RemoveSetup(); 
   
   // Panel GUI'yi temizle (tüm AIK_ objelerini siler)
   Panel.Destroy(); 
   
   // Kalan tüm AIK_ prefix'li objeleri zorla sil (güvenlik net)
   for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) {
      string name = ObjectName(0, i);
      if(StringFind(name, "AIK_") == 0) {
         ObjectDelete(0, name);
      }
   }
   
   // DockPanel GV kayıtlarını temizle
   int totalGV = GlobalVariablesTotal();
   for(int i = totalGV - 1; i >= 0; i--) {
      string gvName = GlobalVariableName(i);
      if(StringFind(gvName, "AIK_DOCK_REG_") == 0) GlobalVariableDel(gvName);
   }
   
   ChartRedraw(); 
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
   if(id == CHARTEVENT_CLICK) {
      int x = (int)lparam; int y = (int)dparam;
      if(!Setup.IsToolClicked(x, y)) Setup.Sleep();
   }
   
   if(id == CHARTEVENT_CHART_CHANGE) { 
      Panel.UpdatePosition(isTrendSyncActive, lastTrendDir, InpEnableTerminal, InpMagicNum); 
      if(Panel.IsTerminalOpen) Panel.UpdateTerminal(InpMagicNum); 
      if(Setup.IsLinesActive) { Setup.OnTickLogic(); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); }
      ChartRedraw(); 
   }
   
   if(id == CHARTEVENT_MOUSE_MOVE) {
      int mx = (int)lparam; int my = (int)dparam; int mb = (int)sparam; 
      
      bool isOver = (mx >= Panel.X && mx <= (Panel.X + Panel.W) && my >= Panel.Y && my <= (Panel.Y + Panel.H));
      if(isOver != isMouseOverPanel) { isMouseOverPanel = isOver; }
      
      if(!Panel.IsPinned) Panel.HandleDrag(mx, my, mb, isTrendSyncActive, lastTrendDir, InpEnableTerminal, InpMagicNum);
      if(Setup.IsLinesActive) Setup.HandleDrag(mx, my, mb, RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); 
      
      static bool lastLockState = false;
      bool currentLockState = isMouseOverPanel || Panel.IsDragging || Setup.IsDragging();
      
      if(currentLockState) {
         ChartSetInteger(0, CHART_MOUSE_SCROLL, false);
         ChartSetInteger(0, CHART_DRAG_TRADE_LEVELS, false);
         lastLockState = true;
      } 
      else if(lastLockState) {
         ChartSetInteger(0, CHART_MOUSE_SCROLL, true);
         ChartSetInteger(0, CHART_DRAG_TRADE_LEVELS, true);
         lastLockState = false;
      }
   }
   
   if(id == CHARTEVENT_OBJECT_CLICK) { 
      Handle_Button_Click(sparam); 
   }
   
   if(id == CHARTEVENT_OBJECT_ENDEDIT) {
      if(StringFind(sparam, "AIK_Trm_Pos_Vol_") >= 0 || StringFind(sparam, "AIK_Trm_Pos_Prf_") >= 0) {
         
         string valStr = ObjectGetString(0, sparam, OBJPROP_TEXT);
         StringReplace(valStr, ",", "."); 
         
         if(StringFind(valStr, ".") < 0) {
            double numericVal = StringToDouble(valStr);
            if(numericVal >= 10) numericVal = numericVal / 100.0; 
            else if(numericVal >= 1) numericVal = numericVal / 100.0; 
            ObjectSetString(0, sparam, OBJPROP_TEXT, DoubleToString(numericVal, 2));
         } else {
            double numericVal = StringToDouble(valStr);
            ObjectSetString(0, sparam, OBJPROP_TEXT, DoubleToString(numericVal, 2));
         }

         ObjectSetInteger(0, sparam, OBJPROP_COLOR, clrOrange);
         if(InpEnableTerminal && Panel.IsTerminalOpen) { Panel.UpdateTerminal(InpMagicNum); ChartRedraw(); }
      }
      else if(sparam == NAME_EditRiskVal || sparam == NAME_EditTP2 || sparam == NAME_EditTP3 || sparam == NAME_EditTP4) {
         Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); 
         UpdateButtons(); 
         ChartRedraw();
      }
   }
   
   if(id == CHARTEVENT_OBJECT_DRAG) { 
      if(StringFind(sparam, "AIK_Line_") >= 0) Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); 
   }
   
   if(id == CHARTEVENT_KEYDOWN) {
      long key = lparam;
      if(key == codeCancel) {
         for(int i=ObjectsTotal(0,-1,-1)-1; i>=0; i--) {
            string n = ObjectName(0,i);
            if(StringFind(n, "AIK_Trm_Pos_") >= 0) {
               if(ObjectGetInteger(0, n, OBJPROP_TYPE) == OBJ_EDIT && ObjectGetInteger(0, n, OBJPROP_COLOR) == clrOrange) {
                  ObjectSetInteger(0, n, OBJPROP_COLOR, clrInputTxt); 
                  ObjectSetInteger(0, n, OBJPROP_BGCOLOR, clrInputBG);
               }
            }
         }
         if(Panel.IsTerminalOpen) Panel.UpdateTerminal(InpMagicNum); ChartRedraw();
      }
      
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK); double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double iTP=0, iSL=0; if(isTrendSyncActive) GetIndicatorLevels(iTP, iSL);
      if(key == codeBuyM) Setup.CreateSetup(1, isTrendSyncActive, lastTrendDir, ask, bid, iTP, iSL);
      else if(key == codeSellM) Setup.CreateSetup(2, isTrendSyncActive, lastTrendDir, ask, bid, iTP, iSL);
      else if(key == codeBuyL) Setup.CreateSetup(3, isTrendSyncActive, lastTrendDir, ask, bid, iTP, iSL);
      else if(key == codeSellL) Setup.CreateSetup(4, isTrendSyncActive, lastTrendDir, ask, bid, iTP, iSL);
      else if(key == codeBuyS) Setup.CreateSetup(5, isTrendSyncActive, lastTrendDir, ask, bid, iTP, iSL);
      else if(key == codeSellS) Setup.CreateSetup(6, isTrendSyncActive, lastTrendDir, ask, bid, iTP, iSL);
      else if(key == codeExecute) ExecuteOrder(); 
      else if(key == codeCancel) { Setup.RemoveSetup(); UpdateButtons(); }
      else if(key == codeClose) Engine.CloseAll(_Symbol);
      else if(key == codeTP2) { Setup.IsTP2 = !Setup.IsTP2; if(Setup.IsTP2) ObjectSetString(0, NAME_EditTP2, OBJPROP_TEXT, DoubleToString(InpDefTP2Pct, 0)); Setup.RefreshTPs(); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); UpdateButtons(); }
      else if(key == codeTP3) { Setup.IsTP3 = !Setup.IsTP3; if(Setup.IsTP3) ObjectSetString(0, NAME_EditTP3, OBJPROP_TEXT, DoubleToString(InpDefTP3Pct, 0)); Setup.RefreshTPs(); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); UpdateButtons(); }
      else if(key == codeTP4) { Setup.IsTP4 = !Setup.IsTP4; if(Setup.IsTP4) ObjectSetString(0, NAME_EditTP4, OBJPROP_TEXT, DoubleToString(InpDefTP4Pct, 0)); Setup.RefreshTPs(); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); UpdateButtons(); }
      else if(key == codeBE) { Setup.IsBE = !Setup.IsBE; if(Setup.IsLinesActive) { if(Setup.IsBE) { double e = ObjectGetDouble(0, NAME_LineEntry, OBJPROP_PRICE); double t = ObjectGetDouble(0, NAME_LineTP1, OBJPROP_PRICE); ObjectCreate(0, NAME_LineBE, OBJ_HLINE, 0, 0, (e+t)/2.0); ObjectSetInteger(0, NAME_LineBE, OBJPROP_COLOR, InpColorBE); } else ObjectDelete(0, NAME_LineBE); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); } }
      ChartRedraw();
      UpdateButtons();
   }
}
//+-------------------------------------------------------------------------------------------+
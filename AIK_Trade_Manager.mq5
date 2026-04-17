diff --git a/AIK_Trade_Manager.mq5 b/AIK_Trade_Manager.mq5
index 516ce408af9af5d02761cdae6ef9e81b86d43be3..05eaabe6a73ea2e5cb05b8349ea2a52fcc8c5f69 100644
--- a/AIK_Trade_Manager.mq5
+++ b/AIK_Trade_Manager.mq5
@@ -25,50 +25,51 @@
 
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
+input double         InpMaxLeverage    = 0.0;            // Maksimum Kaldıraç Limiti (0=Kapalı, 10 => 1:10)
 
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
@@ -271,104 +272,104 @@ void UpdateButtons() {
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
-      Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct);
+      Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct, InpMaxLeverage);
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
 
-   Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); 
+   Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct, InpMaxLeverage); 
    double entry = ObjectGetDouble(0, NAME_LineEntry, OBJPROP_PRICE);
    double sl    = ObjectGetDouble(0, NAME_LineSL, OBJPROP_PRICE);
    double tp1   = ObjectGetDouble(0, NAME_LineTP1, OBJPROP_PRICE);
    double userRisk = StringToDouble(ObjectGetString(0, NAME_EditRiskVal, OBJPROP_TEXT));
    double riskMoneyReal = 0;
-   double totalLot = RiskManager.CalculateLot(_Symbol, entry, sl, CurrentRiskMode, userRisk, riskMoneyReal);
+   double totalLot = RiskManager.CalculateLot(_Symbol, entry, sl, CurrentRiskMode, userRisk, InpMaxLeverage, riskMoneyReal);
    
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
@@ -501,63 +502,63 @@ void Handle_Button_Click(string sparam) {
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
-      Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct);
+      Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct, InpMaxLeverage);
    }
    else if(sparam == NAME_BtnRiskPlus || sparam == NAME_BtnRiskMinus) {
       double val = StringToDouble(ObjectGetString(0, NAME_EditRiskVal, OBJPROP_TEXT)); double step = 0; int d=2;
       if(CurrentRiskMode == RISK_PERCENT) { step = InpStepRiskPct; } else if(CurrentRiskMode == RISK_MONEY) { step = InpStepRiskMoney; } else { step = InpStepRiskLot; }
       if(sparam == NAME_BtnRiskMinus) step = -step; double newVal = val + step; if(newVal < 0) newVal = 0;
       ObjectSetString(0, NAME_EditRiskVal, OBJPROP_TEXT, DoubleToString(newVal, d)); 
-      Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct);
+      Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct, InpMaxLeverage);
    }
-   else if(sparam == NAME_BtnBE) { Setup.IsBE = !Setup.IsBE; if(Setup.IsLinesActive) { if(Setup.IsBE) { double e = ObjectGetDouble(0, NAME_LineEntry, OBJPROP_PRICE); double t = ObjectGetDouble(0, NAME_LineTP1, OBJPROP_PRICE); ObjectCreate(0, NAME_LineBE, OBJ_HLINE, 0, 0, (e+t)/2.0); ObjectSetInteger(0, NAME_LineBE, OBJPROP_COLOR, InpColorBE); } else ObjectDelete(0, NAME_LineBE); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); } }
-   else if(sparam == NAME_BtnTP2) { Setup.IsTP2 = !Setup.IsTP2; if(Setup.IsTP2) ObjectSetString(0, NAME_EditTP2, OBJPROP_TEXT, DoubleToString(InpDefTP2Pct, 0)); Setup.RefreshTPs(); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); UpdateButtons(); }
-   else if(sparam == NAME_BtnTP3) { Setup.IsTP3 = !Setup.IsTP3; if(Setup.IsTP3) ObjectSetString(0, NAME_EditTP3, OBJPROP_TEXT, DoubleToString(InpDefTP3Pct, 0)); Setup.RefreshTPs(); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); UpdateButtons(); }
-   else if(sparam == NAME_BtnTP4) { Setup.IsTP4 = !Setup.IsTP4; if(Setup.IsTP4) ObjectSetString(0, NAME_EditTP4, OBJPROP_TEXT, DoubleToString(InpDefTP4Pct, 0)); Setup.RefreshTPs(); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); UpdateButtons(); }
+   else if(sparam == NAME_BtnBE) { Setup.IsBE = !Setup.IsBE; if(Setup.IsLinesActive) { if(Setup.IsBE) { double e = ObjectGetDouble(0, NAME_LineEntry, OBJPROP_PRICE); double t = ObjectGetDouble(0, NAME_LineTP1, OBJPROP_PRICE); ObjectCreate(0, NAME_LineBE, OBJ_HLINE, 0, 0, (e+t)/2.0); ObjectSetInteger(0, NAME_LineBE, OBJPROP_COLOR, InpColorBE); } else ObjectDelete(0, NAME_LineBE); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct, InpMaxLeverage); } }
+   else if(sparam == NAME_BtnTP2) { Setup.IsTP2 = !Setup.IsTP2; if(Setup.IsTP2) ObjectSetString(0, NAME_EditTP2, OBJPROP_TEXT, DoubleToString(InpDefTP2Pct, 0)); Setup.RefreshTPs(); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct, InpMaxLeverage); UpdateButtons(); }
+   else if(sparam == NAME_BtnTP3) { Setup.IsTP3 = !Setup.IsTP3; if(Setup.IsTP3) ObjectSetString(0, NAME_EditTP3, OBJPROP_TEXT, DoubleToString(InpDefTP3Pct, 0)); Setup.RefreshTPs(); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct, InpMaxLeverage); UpdateButtons(); }
+   else if(sparam == NAME_BtnTP4) { Setup.IsTP4 = !Setup.IsTP4; if(Setup.IsTP4) ObjectSetString(0, NAME_EditTP4, OBJPROP_TEXT, DoubleToString(InpDefTP4Pct, 0)); Setup.RefreshTPs(); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct, InpMaxLeverage); UpdateButtons(); }
    
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
@@ -638,51 +639,51 @@ void OnTick() {
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
-      Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct);
+      Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct, InpMaxLeverage);
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
@@ -728,122 +729,122 @@ void OnDeinit(const int reason) {
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
-      if(Setup.IsLinesActive) { Setup.OnTickLogic(); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); }
+      if(Setup.IsLinesActive) { Setup.OnTickLogic(); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct, InpMaxLeverage); }
       ChartRedraw(); 
    }
    
    if(id == CHARTEVENT_MOUSE_MOVE) {
       int mx = (int)lparam; int my = (int)dparam; int mb = (int)sparam; 
       
       bool isOver = (mx >= Panel.X && mx <= (Panel.X + Panel.W) && my >= Panel.Y && my <= (Panel.Y + Panel.H));
       if(isOver != isMouseOverPanel) { isMouseOverPanel = isOver; }
       
       if(!Panel.IsPinned) Panel.HandleDrag(mx, my, mb, isTrendSyncActive, lastTrendDir, InpEnableTerminal, InpMagicNum);
-      if(Setup.IsLinesActive) Setup.HandleDrag(mx, my, mb, RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); 
+      if(Setup.IsLinesActive) Setup.HandleDrag(mx, my, mb, RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct, InpMaxLeverage); 
       
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
-         Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); 
+         Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct, InpMaxLeverage); 
          UpdateButtons(); 
          ChartRedraw();
       }
    }
    
    if(id == CHARTEVENT_OBJECT_DRAG) { 
-      if(StringFind(sparam, "AIK_Line_") >= 0) Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); 
+      if(StringFind(sparam, "AIK_Line_") >= 0) Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct, InpMaxLeverage); 
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
-      else if(key == codeTP2) { Setup.IsTP2 = !Setup.IsTP2; if(Setup.IsTP2) ObjectSetString(0, NAME_EditTP2, OBJPROP_TEXT, DoubleToString(InpDefTP2Pct, 0)); Setup.RefreshTPs(); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); UpdateButtons(); }
-      else if(key == codeTP3) { Setup.IsTP3 = !Setup.IsTP3; if(Setup.IsTP3) ObjectSetString(0, NAME_EditTP3, OBJPROP_TEXT, DoubleToString(InpDefTP3Pct, 0)); Setup.RefreshTPs(); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); UpdateButtons(); }
-      else if(key == codeTP4) { Setup.IsTP4 = !Setup.IsTP4; if(Setup.IsTP4) ObjectSetString(0, NAME_EditTP4, OBJPROP_TEXT, DoubleToString(InpDefTP4Pct, 0)); Setup.RefreshTPs(); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); UpdateButtons(); }
-      else if(key == codeBE) { Setup.IsBE = !Setup.IsBE; if(Setup.IsLinesActive) { if(Setup.IsBE) { double e = ObjectGetDouble(0, NAME_LineEntry, OBJPROP_PRICE); double t = ObjectGetDouble(0, NAME_LineTP1, OBJPROP_PRICE); ObjectCreate(0, NAME_LineBE, OBJ_HLINE, 0, 0, (e+t)/2.0); ObjectSetInteger(0, NAME_LineBE, OBJPROP_COLOR, InpColorBE); } else ObjectDelete(0, NAME_LineBE); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct); } }
+      else if(key == codeTP2) { Setup.IsTP2 = !Setup.IsTP2; if(Setup.IsTP2) ObjectSetString(0, NAME_EditTP2, OBJPROP_TEXT, DoubleToString(InpDefTP2Pct, 0)); Setup.RefreshTPs(); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct, InpMaxLeverage); UpdateButtons(); }
+      else if(key == codeTP3) { Setup.IsTP3 = !Setup.IsTP3; if(Setup.IsTP3) ObjectSetString(0, NAME_EditTP3, OBJPROP_TEXT, DoubleToString(InpDefTP3Pct, 0)); Setup.RefreshTPs(); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct, InpMaxLeverage); UpdateButtons(); }
+      else if(key == codeTP4) { Setup.IsTP4 = !Setup.IsTP4; if(Setup.IsTP4) ObjectSetString(0, NAME_EditTP4, OBJPROP_TEXT, DoubleToString(InpDefTP4Pct, 0)); Setup.RefreshTPs(); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct, InpMaxLeverage); UpdateButtons(); }
+      else if(key == codeBE) { Setup.IsBE = !Setup.IsBE; if(Setup.IsLinesActive) { if(Setup.IsBE) { double e = ObjectGetDouble(0, NAME_LineEntry, OBJPROP_PRICE); double t = ObjectGetDouble(0, NAME_LineTP1, OBJPROP_PRICE); ObjectCreate(0, NAME_LineBE, OBJ_HLINE, 0, 0, (e+t)/2.0); ObjectSetInteger(0, NAME_LineBE, OBJPROP_COLOR, InpColorBE); } else ObjectDelete(0, NAME_LineBE); Setup.UpdateCalculations(RiskManager, CurrentRiskMode, InpDefTP2Pct, InpDefTP3Pct, InpDefTP4Pct, InpMaxLeverage); } }
       ChartRedraw();
       UpdateButtons();
    }
 }
 //+-------------------------------------------------------------------------------------------+
\ No newline at end of file

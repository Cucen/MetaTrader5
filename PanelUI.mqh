//+------------------------------------------------------------------+
//|                                                      PanelUI.mqh |
//|                                     Copyright 2026, AIK Project  |
//|                                      Project: AIK Trade Manager  |
//| Version: 30.3 (FINAL: Z-Order Fix + Terminal Edit Visibility)    |
//+------------------------------------------------------------------+
#property strict

#include "Defines.mqh"
#include "Utilities.mqh"

// --- DOCKPANEL ENTEGRASYON SABİTİ ---
#define GV_REG_PREFIX "AIK_DOCK_REG_" 

//+------------------------------------------------------------------+
//| SetPropIfChanged (Anti-Flicker Helper)                           |
//+------------------------------------------------------------------+
void SetPropIfChanged(const string name,
                      const ENUM_OBJECT_PROPERTY_INTEGER prop,
                      const long newVal)
{
   if(ObjectFind(0, name) < 0) return;
   if(ObjectGetInteger(0, name, prop) == newVal) return;
   ObjectSetInteger(0, name, prop, newVal);
}

class CPanelUI
{
private:
   int FindLastIndex(string text, string match) {
      for(int i = StringLen(text) - 1; i >= 0; i--) {
         if(StringSubstr(text, i, 1) == match) return i;
      }
      return -1;
   }

   void RegisterToDock(string objName) {
      string gvKey = GV_REG_PREFIX + objName;
      if(!GlobalVariableCheck(gvKey)) GlobalVariableSet(gvKey, 1.0);
   }

   void UnregisterFromDock(string objName) {
      string gvKey = GV_REG_PREFIX + objName;
      if(GlobalVariableCheck(gvKey)) GlobalVariableDel(gvKey);
   }

public:
   int      X, Y, W, H;            
   bool     IsMinimized;           
   bool     IsPinned;              
   bool     IsTerminalOpen;        
   bool     IsDragging;            
   int      DragOffsetX, DragOffsetY;
   
   string   m_btnModeName;
   
   CPanelUI() {
      X = 20; Y = 50; W = 300; H = 320;
      IsMinimized = false; IsPinned = false; IsTerminalOpen = false; IsDragging = false;
      m_btnModeName = "AIK_TM_Btn_Mode_ExtSpl"; 
   }

   void Destroy() {
      // DockPanel kayıtlarını temizle
      UnregisterFromDock(NAME_ObjPanel); UnregisterFromDock(NAME_ObjTitleBar); UnregisterFromDock(NAME_ObjMasterShield);
      UnregisterFromDock(NAME_BtnDrag); UnregisterFromDock(NAME_BtnMinMax); UnregisterFromDock(NAME_BtnPin);
      UnregisterFromDock(NAME_BtnRiskMode); UnregisterFromDock(NAME_EditRiskVal); 
      UnregisterFromDock(NAME_BtnRiskPlus); UnregisterFromDock(NAME_BtnRiskMinus);
      UnregisterFromDock(NAME_BtnSync); UnregisterFromDock(NAME_BtnTrendMkt);
      UnregisterFromDock(m_btnModeName); 
      
      UnregisterFromDock(NAME_BtnMiniBuy); UnregisterFromDock(NAME_BtnMiniSell); 
      UnregisterFromDock(NAME_BtnMiniExec); UnregisterFromDock(NAME_BtnMiniClose);
      UnregisterFromDock(NAME_BtnBuyM); UnregisterFromDock(NAME_BtnSellM); 
      UnregisterFromDock(NAME_BtnBuyL); UnregisterFromDock(NAME_BtnSellL);
      UnregisterFromDock(NAME_BtnBuyS); UnregisterFromDock(NAME_BtnSellS);
      UnregisterFromDock(NAME_BtnTP1); UnregisterFromDock(NAME_BtnTP2); UnregisterFromDock(NAME_BtnTP3); UnregisterFromDock(NAME_BtnTP4);
      UnregisterFromDock(NAME_EditTP1); UnregisterFromDock(NAME_EditTP2); UnregisterFromDock(NAME_EditTP3); UnregisterFromDock(NAME_EditTP4);
      UnregisterFromDock(NAME_BtnBE);
      UnregisterFromDock(NAME_BtnCancel); UnregisterFromDock(NAME_BtnExecute); UnregisterFromDock(NAME_BtnClose);
      UnregisterFromDock(NAME_BtnTerminalToggle); UnregisterFromDock(NAME_ObjTerminalBG);
      
      // Tüm panel objelerini direkt sil (AIK_TM_ ve AIK_Trm_ prefix'li)
      for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) {
         string name = ObjectName(0, i);
         if(StringFind(name, "AIK_TM_") == 0 || StringFind(name, "AIK_Trm_") == 0) {
            UnregisterFromDock(name);
            ObjectDelete(0, name);
         }
      }
      ChartRedraw();
   }

   void HideAllControls() {
      CUtilities::SetVisible(NAME_BtnRiskMode, false); CUtilities::SetVisible(NAME_EditRiskVal, false);
      CUtilities::SetVisible(NAME_BtnRiskPlus, false); CUtilities::SetVisible(NAME_BtnRiskMinus, false);
      CUtilities::SetVisible(NAME_BtnPin, false); CUtilities::SetVisible(NAME_BtnMinMax, false);
      CUtilities::SetVisible(NAME_BtnSync, false); CUtilities::SetVisible(NAME_BtnTrendMkt, false);
      CUtilities::SetVisible(m_btnModeName, false);
      CUtilities::SetVisible(NAME_BtnMiniBuy, false); CUtilities::SetVisible(NAME_BtnMiniSell, false);
      CUtilities::SetVisible(NAME_BtnMiniExec, false); CUtilities::SetVisible(NAME_BtnMiniClose, false);
      CUtilities::SetVisible(NAME_BtnBuyM, false); CUtilities::SetVisible(NAME_BtnSellM, false);
      CUtilities::SetVisible(NAME_BtnBuyL, false); CUtilities::SetVisible(NAME_BtnSellL, false);
      CUtilities::SetVisible(NAME_BtnBuyS, false); CUtilities::SetVisible(NAME_BtnSellS, false);
      CUtilities::SetVisible(NAME_BtnTP1, false); CUtilities::SetVisible(NAME_BtnTP2, false);
      CUtilities::SetVisible(NAME_BtnTP3, false); CUtilities::SetVisible(NAME_BtnTP4, false);
      CUtilities::SetVisible(NAME_EditTP1, false); CUtilities::SetVisible(NAME_EditTP2, false);
      CUtilities::SetVisible(NAME_EditTP3, false); CUtilities::SetVisible(NAME_EditTP4, false);
      CUtilities::SetVisible(NAME_BtnBE, false);
      CUtilities::SetVisible(NAME_BtnCancel, false); CUtilities::SetVisible(NAME_BtnExecute, false); CUtilities::SetVisible(NAME_BtnClose, false);
      
      CUtilities::SetVisible(NAME_BtnTerminalToggle, false); 
      CUtilities::SetVisible(NAME_ObjTerminalBG, false);
      
      for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) {
         string name = ObjectName(0, i);
         if(StringFind(name, "AIK_Trm_") >= 0) CUtilities::SetVisible(name, false);
      }
   }

   void CreateBtn(string name, string text, int x, int y, int w, int h, color bg, int zOrder) {
      if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
      RegisterToDock(name);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, w); ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER); ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg); ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8); ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
      ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_RAISED); ObjectSetString(0, name, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, name, OBJPROP_ZORDER, zOrder);
   }

   void CreateBgBox(string name, int x, int y, int w, int h, color bg, int zOrder) {
      if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
      RegisterToDock(name);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, w); ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg); ObjectSetInteger(0, name, OBJPROP_COLOR, bg);
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, bg); ObjectSetInteger(0, name, OBJPROP_STATE, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false); ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER); ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, zOrder);
   }

   void CreateEdit(string name, string text, int x, int y, int w, int h, int zOrder) {
      if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0);
      RegisterToDock(name);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x); ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, w); ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER); ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrInputBG); ObjectSetInteger(0, name, OBJPROP_COLOR, clrInputTxt);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8); ObjectSetInteger(0, name, OBJPROP_ALIGN, ALIGN_CENTER);
      ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS); ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_SUNKEN);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, zOrder);
   }
   
   ENUM_GUI_STATE GetState(bool _syncActive) {
      if(!IsMinimized && !_syncActive) return GUI_FULL_MOD;
      if(!IsMinimized && _syncActive)  return GUI_SYNC_MOD;
      if(IsMinimized && !_syncActive)  return GUI_FULL_MOD_MINIMAL;
      return GUI_SYNC_MOD_MINIMAL;
   }

   void CreateGUI(double defaultVal, string kLmt, string kStp, string kMktL, string kMktS, string kLmtS, string kStpS, string kCan, string kExe, string kCls, string kTP2, string kTP3, string kTP4, string kBE, bool enableTerminal) 
   {
      // KATMAN SIRALARI GÜNCELLENDİ (Buttons > 200)
      CreateBgBox(NAME_ObjMasterShield, X, Y, W, H, clrPanelBG, GUI_Z_BASE); 
      CreateBgBox(NAME_ObjPanel, X, Y, W, H, clrPanelBG, GUI_Z_BASE+100); 
      CreateBgBox(NAME_ObjTitleBar, X, Y, W, HDR_H, clrHeaderBG, GUI_Z_BASE+101);
      
      CreateBtn(NAME_BtnDrag, "#", X, Y, 20, 24, clrHeaderBG, GUI_Z_BASE+102); 
      CreateBtn(NAME_BtnRiskMode, "R%", 0, 0, 24, 24, clrBtnRisk, GUI_Z_BASE+200); 
      CreateBtn(NAME_BtnRiskMinus, "-", 0, 0, 18, 24, clrBtnGray, GUI_Z_BASE+200);
      CreateEdit(NAME_EditRiskVal, DoubleToString(defaultVal, 2), 0, 0, 40, 24, GUI_Z_BASE+200); 
      CreateBtn(NAME_BtnRiskPlus, "+", 0, 0, 18, 24, clrBtnGray, GUI_Z_BASE+200);

      CreateBtn(NAME_BtnSync, "SYNC", 0, 0, 50, 24, clrBtnGreen, GUI_Z_BASE+200);
      CreateBtn(m_btnModeName, "EXT", 0, 0, 28, 24, clrGray, GUI_Z_BASE+200);
      
      CreateBtn(NAME_BtnTrendMkt, "BUY", 0, 0, 50, 24, clrBtnBuyMkt, GUI_Z_BASE+200);
      CreateBtn(NAME_BtnMiniSell, "SELL", 0, 0, 28, 24, clrBtnSellMkt, GUI_Z_BASE+200);
      CreateBtn(NAME_BtnMiniBuy, "BUY", 0, 0, 28, 24, clrBtnBuyMkt, GUI_Z_BASE+200);
      CreateBtn(NAME_BtnMiniExec, "EXEC", 0, 0, 28, 24, clrBtnGray, GUI_Z_BASE+200);
      CreateBtn(NAME_BtnMiniClose, "CLS", 0, 0, 28, 24, clrBtnClose, GUI_Z_BASE+200); 
      CreateBtn(NAME_BtnPin, "\x25CB", 0, 0, 20, 24, clrBtnGray, GUI_Z_BASE+200);
      CreateBtn(NAME_BtnMinMax, "_", 0, 0, 20, 24, clrBtnGray, GUI_Z_BASE+200);

      CreateBtn(NAME_BtnSellL, CUtilities::AddKeyText("SELL Lmt", kLmtS), 0, 0, 135, 25, clrBtnSellLmt, GUI_Z_BASE+200);
      CreateBtn(NAME_BtnBuyS, CUtilities::AddKeyText("BUY Stp", kStp), 0, 0, 135, 25, clrBtnBuyStp, GUI_Z_BASE+200); 
      CreateBtn(NAME_BtnSellM, CUtilities::AddKeyText("SELL", kMktS), 0, 0, 135, 55, clrBtnSellMkt, GUI_Z_BASE+200); 
      CreateBtn(NAME_BtnBuyM, CUtilities::AddKeyText("BUY", kMktL), 0, 0, 135, 55, clrBtnBuyMkt, GUI_Z_BASE+200);
      CreateBtn(NAME_BtnSellS, CUtilities::AddKeyText("SELL Stp", kStpS), 0, 0, 135, 25, clrBtnSellStp, GUI_Z_BASE+200); 
      CreateBtn(NAME_BtnBuyL, CUtilities::AddKeyText("BUY Lmt", kLmt), 0, 0, 135, 25, clrBtnBuyLmt, GUI_Z_BASE+200);
      
      CreateBtn(NAME_BtnCancel, CUtilities::AddKeyText("Cancel", kCan), 0, 0, 280, 25, clrBtnGray, GUI_Z_BASE+200);
      CreateBtn(NAME_BtnTP1, "TP1", 0, 0, 54, 25, clrBtnActive, GUI_Z_BASE+200);
      CreateBtn(NAME_BtnTP2, CUtilities::AddKeyText("TP2", kTP2), 0, 0, 54, 25, clrBtnGray, GUI_Z_BASE+200);
      CreateBtn(NAME_BtnTP3, CUtilities::AddKeyText("TP3", kTP3), 0, 0, 54, 25, clrBtnGray, GUI_Z_BASE+200);
      CreateBtn(NAME_BtnTP4, CUtilities::AddKeyText("TP4", kTP4), 0, 0, 54, 25, clrBtnGray, GUI_Z_BASE+200);
      CreateBtn(NAME_BtnBE, CUtilities::AddKeyText("BE", kBE), 0, 0, 54, 25, clrBtnGray, GUI_Z_BASE+200);
      
      CreateEdit(NAME_EditTP1, "100", 0, 0, 54, 20, GUI_Z_BASE+200); ObjectSetInteger(0, NAME_EditTP1, OBJPROP_READONLY, true); ObjectSetInteger(0, NAME_EditTP1, OBJPROP_BGCOLOR, clrBtnGray); 
      CreateEdit(NAME_EditTP2, "0", 0, 0, 54, 20, GUI_Z_BASE+200);
      CreateEdit(NAME_EditTP3, "0", 0, 0, 54, 20, GUI_Z_BASE+200);
      CreateEdit(NAME_EditTP4, "0", 0, 0, 54, 20, GUI_Z_BASE+200);
      
      CreateBtn(NAME_BtnExecute, CUtilities::AddKeyText("EXECUTE", kExe), 0, 0, 135, 55, clrBtnGray, GUI_Z_BASE+500); 
      CreateBtn(NAME_BtnClose, CUtilities::AddKeyText("CLOSE", kCls), 0, 0, 135, 55, clrBtnClose, GUI_Z_BASE+500); 
      
      if(enableTerminal) {
         CreateBtn(NAME_BtnTerminalToggle, "v", X, Y + H, W, 15, clrHeaderBG, GUI_Z_BASE+510); 
      }
      UpdatePinButton();
   }
   
   void UpdateModeButton(bool isSplit) {
      if(ObjectFind(0, m_btnModeName) >= 0) {
         ObjectSetString(0, m_btnModeName, OBJPROP_TEXT, isSplit ? "SPL" : "EXT");
         ObjectSetInteger(0, m_btnModeName, OBJPROP_BGCOLOR, isSplit ? clrOrange : clrGray);
      }
   }

   void UpdatePosition(bool _syncActive, int _trendDir, bool _enableTerminal, int magicNum) {

      SetPropIfChanged(NAME_ObjMasterShield, OBJPROP_XDISTANCE, X);
      SetPropIfChanged(NAME_ObjMasterShield, OBJPROP_YDISTANCE, Y);
      SetPropIfChanged(NAME_ObjPanel,        OBJPROP_XDISTANCE, X);
      SetPropIfChanged(NAME_ObjPanel,        OBJPROP_YDISTANCE, Y);
      SetPropIfChanged(NAME_ObjTitleBar,     OBJPROP_XDISTANCE, X);
      SetPropIfChanged(NAME_ObjTitleBar,     OBJPROP_YDISTANCE, Y);
      SetPropIfChanged(NAME_BtnDrag,         OBJPROP_XDISTANCE, X + 2);
      SetPropIfChanged(NAME_BtnDrag,         OBJPROP_YDISTANCE, Y + 3);
      
      if(IsDragging) {
         HideAllControls(); 
         return; 
      }

      int ry = Y+3; 
      int xRisk=X+25, wRisk=24, gap=2, wMinus=18, wEdit=40, wPlus=18, xMinus=xRisk+wRisk+gap, xEdit=xMinus+wMinus+gap, xPlus=xEdit+wEdit+gap;
      
      CUtilities::SetVisible(NAME_BtnRiskMode, true);
      SetPropIfChanged(NAME_BtnRiskMode, OBJPROP_XDISTANCE, xRisk); SetPropIfChanged(NAME_BtnRiskMode, OBJPROP_YDISTANCE, ry);
      CUtilities::SetVisible(NAME_BtnRiskMinus, true);
      SetPropIfChanged(NAME_BtnRiskMinus, OBJPROP_XDISTANCE, xMinus); SetPropIfChanged(NAME_BtnRiskMinus, OBJPROP_YDISTANCE, ry);
      CUtilities::SetVisible(NAME_EditRiskVal, true);
      SetPropIfChanged(NAME_EditRiskVal, OBJPROP_XDISTANCE, xEdit); SetPropIfChanged(NAME_EditRiskVal, OBJPROP_YDISTANCE, ry);
      CUtilities::SetVisible(NAME_BtnRiskPlus, true);
      SetPropIfChanged(NAME_BtnRiskPlus, OBJPROP_XDISTANCE, xPlus); SetPropIfChanged(NAME_BtnRiskPlus, OBJPROP_YDISTANCE, ry);
      
      CUtilities::SetVisible(NAME_BtnPin, true);
      SetPropIfChanged(NAME_BtnPin, OBJPROP_XDISTANCE, X + W - 45); SetPropIfChanged(NAME_BtnPin, OBJPROP_YDISTANCE, ry);
      CUtilities::SetVisible(NAME_BtnMinMax, true);
      SetPropIfChanged(NAME_BtnMinMax, OBJPROP_XDISTANCE, X + W - 22); SetPropIfChanged(NAME_BtnMinMax, OBJPROP_YDISTANCE, ry);
      
      ENUM_GUI_STATE state = GetState(_syncActive);
      
      CUtilities::SetVisible(NAME_BtnSync, false); CUtilities::SetVisible(m_btnModeName, false);
      CUtilities::SetVisible(NAME_BtnTrendMkt, false); 
      CUtilities::SetVisible(NAME_BtnMiniBuy, false); CUtilities::SetVisible(NAME_BtnMiniSell, false); 
      CUtilities::SetVisible(NAME_BtnMiniExec, false); CUtilities::SetVisible(NAME_BtnMiniClose, false);
      CUtilities::SetVisible(NAME_BtnBuyM, false); CUtilities::SetVisible(NAME_BtnSellM, false); 
      CUtilities::SetVisible(NAME_BtnBuyL, false); CUtilities::SetVisible(NAME_BtnSellL, false); 
      CUtilities::SetVisible(NAME_BtnBuyS, false); CUtilities::SetVisible(NAME_BtnSellS, false);
      CUtilities::SetVisible(NAME_BtnTP1, false); CUtilities::SetVisible(NAME_EditTP1, false); 
      CUtilities::SetVisible(NAME_BtnTP2, false); CUtilities::SetVisible(NAME_EditTP2, false); 
      CUtilities::SetVisible(NAME_BtnTP3, false); CUtilities::SetVisible(NAME_EditTP3, false); 
      CUtilities::SetVisible(NAME_BtnTP4, false); CUtilities::SetVisible(NAME_EditTP4, false); 
      CUtilities::SetVisible(NAME_BtnBE, false); 
      CUtilities::SetVisible(NAME_BtnCancel, false); CUtilities::SetVisible(NAME_BtnExecute, false); CUtilities::SetVisible(NAME_BtnClose, false);
      
      int safeW = W - (2 * PAD_SIDE); int startX = X + PAD_SIDE; int currentY = Y + HDR_H + GAP_V; 
      int btnW = 0, miniGap = 2, minStartX = X + 135, minEndX = X + W - 45, minAvailW = minEndX - minStartX;

      switch(state) {
         case GUI_SYNC_MOD_MINIMAL: {
            CUtilities::SetVisible(NAME_BtnTrendMkt, true); CUtilities::SetVisible(NAME_BtnMiniExec, true); CUtilities::SetVisible(NAME_BtnMiniClose, true);
            btnW = (minAvailW - (2*miniGap)) / 3;
            SetPropIfChanged(NAME_BtnTrendMkt,  OBJPROP_XDISTANCE, minStartX);                           SetPropIfChanged(NAME_BtnTrendMkt,  OBJPROP_YDISTANCE, ry); SetPropIfChanged(NAME_BtnTrendMkt,  OBJPROP_XSIZE, btnW);
            SetPropIfChanged(NAME_BtnMiniClose, OBJPROP_XDISTANCE, minStartX + btnW + miniGap);          SetPropIfChanged(NAME_BtnMiniClose, OBJPROP_YDISTANCE, ry); SetPropIfChanged(NAME_BtnMiniClose, OBJPROP_XSIZE, btnW); ObjectSetString(0, NAME_BtnMiniClose, OBJPROP_TEXT, "CLS"); 
            SetPropIfChanged(NAME_BtnMiniExec,  OBJPROP_XDISTANCE, minStartX + (btnW*2) + (miniGap*2)); SetPropIfChanged(NAME_BtnMiniExec,  OBJPROP_YDISTANCE, ry); SetPropIfChanged(NAME_BtnMiniExec,  OBJPROP_XSIZE, btnW); 
            H = HDR_H; 
         } break;
         case GUI_FULL_MOD_MINIMAL: {
            CUtilities::SetVisible(NAME_BtnMiniBuy, true); CUtilities::SetVisible(NAME_BtnMiniSell, true); CUtilities::SetVisible(NAME_BtnMiniExec, true); CUtilities::SetVisible(NAME_BtnMiniClose, true);
            btnW = (minAvailW - (3*miniGap)) / 4;
            SetPropIfChanged(NAME_BtnMiniSell,  OBJPROP_XDISTANCE, minStartX);                           SetPropIfChanged(NAME_BtnMiniSell,  OBJPROP_YDISTANCE, ry); SetPropIfChanged(NAME_BtnMiniSell,  OBJPROP_XSIZE, btnW);
            SetPropIfChanged(NAME_BtnMiniBuy,   OBJPROP_XDISTANCE, minStartX + btnW + miniGap);          SetPropIfChanged(NAME_BtnMiniBuy,   OBJPROP_YDISTANCE, ry); SetPropIfChanged(NAME_BtnMiniBuy,   OBJPROP_XSIZE, btnW);
            SetPropIfChanged(NAME_BtnMiniClose, OBJPROP_XDISTANCE, minStartX + (btnW*2) + (miniGap*2)); SetPropIfChanged(NAME_BtnMiniClose, OBJPROP_YDISTANCE, ry); SetPropIfChanged(NAME_BtnMiniClose, OBJPROP_XSIZE, btnW);
            SetPropIfChanged(NAME_BtnMiniExec,  OBJPROP_XDISTANCE, minStartX + (btnW*3) + (miniGap*3)); SetPropIfChanged(NAME_BtnMiniExec,  OBJPROP_YDISTANCE, ry); SetPropIfChanged(NAME_BtnMiniExec,  OBJPROP_XSIZE, btnW);
            H = HDR_H;
         } break;
         case GUI_SYNC_MOD:
         case GUI_FULL_MOD: {
            CUtilities::SetVisible(NAME_BtnSync, true); CUtilities::SetVisible(m_btnModeName, true);
            
            int wSync = 50; int wMode = 28; int gapBtn = 2;
            int xStartBtn = X + 135;
            
            SetPropIfChanged(NAME_BtnSync, OBJPROP_XDISTANCE, xStartBtn); 
            SetPropIfChanged(NAME_BtnSync, OBJPROP_YDISTANCE, ry); 
            
            if(state == GUI_SYNC_MOD) {
               wSync = (W - 135 - 50 - wMode - gapBtn); 
               if(wSync < 40) wSync = 40;
            } 
            SetPropIfChanged(NAME_BtnSync, OBJPROP_XSIZE, wSync);
            
            SetPropIfChanged(m_btnModeName, OBJPROP_XDISTANCE, xStartBtn + wSync + gapBtn); 
            SetPropIfChanged(m_btnModeName, OBJPROP_YDISTANCE, ry);
            SetPropIfChanged(m_btnModeName, OBJPROP_XSIZE, wMode);

            if(state == GUI_SYNC_MOD) {
               int hRowSmall = 55; int hRowBig = (hRowSmall * 2) + GAP_V; 
               int wHalf = (safeW - GAP_H) / 2; int wLeft = wHalf; int wRight = wHalf;
               bool showBuy = true, showSell = true;
               if(_trendDir == 1) { showBuy = false; showSell = true; } else if(_trendDir == -1) { showBuy = true; showSell = false; }
               if(showSell) {
                  CUtilities::SetVisible(NAME_BtnSellS, true); CUtilities::SetVisible(NAME_BtnSellL, true); CUtilities::SetVisible(NAME_BtnSellM, true);
                  SetPropIfChanged(NAME_BtnSellL, OBJPROP_XDISTANCE, startX);               SetPropIfChanged(NAME_BtnSellL, OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_BtnSellL, OBJPROP_XSIZE, wLeft); SetPropIfChanged(NAME_BtnSellL, OBJPROP_YSIZE, hRowSmall);
                  SetPropIfChanged(NAME_BtnSellS, OBJPROP_XDISTANCE, startX);               SetPropIfChanged(NAME_BtnSellS, OBJPROP_YDISTANCE, currentY + hRowSmall + GAP_V); SetPropIfChanged(NAME_BtnSellS, OBJPROP_XSIZE, wLeft); SetPropIfChanged(NAME_BtnSellS, OBJPROP_YSIZE, hRowSmall);
                  SetPropIfChanged(NAME_BtnSellM, OBJPROP_XDISTANCE, startX + wLeft + GAP_H); SetPropIfChanged(NAME_BtnSellM, OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_BtnSellM, OBJPROP_XSIZE, wRight); SetPropIfChanged(NAME_BtnSellM, OBJPROP_YSIZE, hRowBig);
               }
               if(showBuy) {
                  CUtilities::SetVisible(NAME_BtnBuyS, true); CUtilities::SetVisible(NAME_BtnBuyL, true); CUtilities::SetVisible(NAME_BtnBuyM, true);
                  SetPropIfChanged(NAME_BtnBuyS, OBJPROP_XDISTANCE, startX);               SetPropIfChanged(NAME_BtnBuyS, OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_BtnBuyS, OBJPROP_XSIZE, wLeft); SetPropIfChanged(NAME_BtnBuyS, OBJPROP_YSIZE, hRowSmall);
                  SetPropIfChanged(NAME_BtnBuyL, OBJPROP_XDISTANCE, startX);               SetPropIfChanged(NAME_BtnBuyL, OBJPROP_YDISTANCE, currentY + hRowSmall + GAP_V); SetPropIfChanged(NAME_BtnBuyL, OBJPROP_XSIZE, wLeft); SetPropIfChanged(NAME_BtnBuyL, OBJPROP_YSIZE, hRowSmall);
                  SetPropIfChanged(NAME_BtnBuyM, OBJPROP_XDISTANCE, startX + wLeft + GAP_H); SetPropIfChanged(NAME_BtnBuyM, OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_BtnBuyM, OBJPROP_XSIZE, wRight); SetPropIfChanged(NAME_BtnBuyM, OBJPROP_YSIZE, hRowBig);
               }
               currentY += hRowBig + GAP_V + GAP_V; 
               CUtilities::SetVisible(NAME_BtnCancel, true); SetPropIfChanged(NAME_BtnCancel, OBJPROP_XDISTANCE, startX); SetPropIfChanged(NAME_BtnCancel, OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_BtnCancel, OBJPROP_XSIZE, safeW); SetPropIfChanged(NAME_BtnCancel, OBJPROP_YSIZE, 35);
               currentY += 35 + GAP_V;
               CUtilities::SetVisible(NAME_BtnExecute, true); CUtilities::SetVisible(NAME_BtnClose, true); int hExec = 70; 
               SetPropIfChanged(NAME_BtnClose,   OBJPROP_XDISTANCE, startX);               SetPropIfChanged(NAME_BtnClose,   OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_BtnClose,   OBJPROP_XSIZE, wHalf); SetPropIfChanged(NAME_BtnClose,   OBJPROP_YSIZE, hExec);
               SetPropIfChanged(NAME_BtnExecute, OBJPROP_XDISTANCE, startX + wHalf + GAP_H); SetPropIfChanged(NAME_BtnExecute, OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_BtnExecute, OBJPROP_XSIZE, wHalf); SetPropIfChanged(NAME_BtnExecute, OBJPROP_YSIZE, hExec);
               currentY += hExec + GAP_V;
            } else {
               // FULL MOD
               int colW = (safeW - GAP_H) / 2; int hStd = 30; int hBig = (hStd * 2) + GAP_V;
               
               CUtilities::SetVisible(NAME_BtnSellL, true); CUtilities::SetVisible(NAME_BtnSellM, true); CUtilities::SetVisible(NAME_BtnSellS, true);
               CUtilities::SetVisible(NAME_BtnBuyS, true); CUtilities::SetVisible(NAME_BtnBuyM, true); CUtilities::SetVisible(NAME_BtnBuyL, true);
               
               SetPropIfChanged(NAME_BtnSellL, OBJPROP_XDISTANCE, startX);           SetPropIfChanged(NAME_BtnSellL, OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_BtnSellL, OBJPROP_XSIZE, colW); SetPropIfChanged(NAME_BtnSellL, OBJPROP_YSIZE, hStd);
               SetPropIfChanged(NAME_BtnBuyS,  OBJPROP_XDISTANCE, startX+colW+GAP_H); SetPropIfChanged(NAME_BtnBuyS,  OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_BtnBuyS,  OBJPROP_XSIZE, colW); SetPropIfChanged(NAME_BtnBuyS,  OBJPROP_YSIZE, hStd);
               currentY += hStd + GAP_V;
               SetPropIfChanged(NAME_BtnSellM, OBJPROP_XDISTANCE, startX);           SetPropIfChanged(NAME_BtnSellM, OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_BtnSellM, OBJPROP_XSIZE, colW); SetPropIfChanged(NAME_BtnSellM, OBJPROP_YSIZE, hBig);
               SetPropIfChanged(NAME_BtnBuyM,  OBJPROP_XDISTANCE, startX+colW+GAP_H); SetPropIfChanged(NAME_BtnBuyM,  OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_BtnBuyM,  OBJPROP_XSIZE, colW); SetPropIfChanged(NAME_BtnBuyM,  OBJPROP_YSIZE, hBig);
               currentY += hBig + GAP_V;
               SetPropIfChanged(NAME_BtnSellS, OBJPROP_XDISTANCE, startX);           SetPropIfChanged(NAME_BtnSellS, OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_BtnSellS, OBJPROP_XSIZE, colW); SetPropIfChanged(NAME_BtnSellS, OBJPROP_YSIZE, hStd);
               SetPropIfChanged(NAME_BtnBuyL,  OBJPROP_XDISTANCE, startX+colW+GAP_H); SetPropIfChanged(NAME_BtnBuyL,  OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_BtnBuyL,  OBJPROP_XSIZE, colW); SetPropIfChanged(NAME_BtnBuyL,  OBJPROP_YSIZE, hStd);
               currentY += hStd + GAP_V + GAP_V;
               
               CUtilities::SetVisible(NAME_BtnCancel, true); SetPropIfChanged(NAME_BtnCancel, OBJPROP_XDISTANCE, startX); SetPropIfChanged(NAME_BtnCancel, OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_BtnCancel, OBJPROP_XSIZE, safeW); SetPropIfChanged(NAME_BtnCancel, OBJPROP_YSIZE, 30);
               currentY += 30 + GAP_V;
               
               int tpCount = 5; int tpW = (safeW - ((tpCount-1)*GAP_H)) / tpCount;
               CUtilities::SetVisible(NAME_BtnTP1, true); CUtilities::SetVisible(NAME_BtnTP2, true); CUtilities::SetVisible(NAME_BtnTP3, true); CUtilities::SetVisible(NAME_BtnTP4, true); CUtilities::SetVisible(NAME_BtnBE, true);
               
               SetPropIfChanged(NAME_BtnTP1, OBJPROP_XDISTANCE, startX);                 SetPropIfChanged(NAME_BtnTP1, OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_BtnTP1, OBJPROP_XSIZE, tpW);
               SetPropIfChanged(NAME_BtnTP2, OBJPROP_XDISTANCE, startX+(tpW+GAP_H));   SetPropIfChanged(NAME_BtnTP2, OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_BtnTP2, OBJPROP_XSIZE, tpW);
               SetPropIfChanged(NAME_BtnTP3, OBJPROP_XDISTANCE, startX+(tpW+GAP_H)*2); SetPropIfChanged(NAME_BtnTP3, OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_BtnTP3, OBJPROP_XSIZE, tpW);
               SetPropIfChanged(NAME_BtnTP4, OBJPROP_XDISTANCE, startX+(tpW+GAP_H)*3); SetPropIfChanged(NAME_BtnTP4, OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_BtnTP4, OBJPROP_XSIZE, tpW);
               SetPropIfChanged(NAME_BtnBE,  OBJPROP_XDISTANCE, startX+(tpW+GAP_H)*4); SetPropIfChanged(NAME_BtnBE,  OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_BtnBE,  OBJPROP_XSIZE, tpW);
               currentY += 26;
               
               CUtilities::SetVisible(NAME_EditTP1, true); CUtilities::SetVisible(NAME_EditTP2, true); CUtilities::SetVisible(NAME_EditTP3, true); CUtilities::SetVisible(NAME_EditTP4, true);
               SetPropIfChanged(NAME_EditTP1, OBJPROP_XDISTANCE, startX);                 SetPropIfChanged(NAME_EditTP1, OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_EditTP1, OBJPROP_XSIZE, tpW);
               SetPropIfChanged(NAME_EditTP2, OBJPROP_XDISTANCE, startX+(tpW+GAP_H));   SetPropIfChanged(NAME_EditTP2, OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_EditTP2, OBJPROP_XSIZE, tpW);
               SetPropIfChanged(NAME_EditTP3, OBJPROP_XDISTANCE, startX+(tpW+GAP_H)*2); SetPropIfChanged(NAME_EditTP3, OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_EditTP3, OBJPROP_XSIZE, tpW);
               SetPropIfChanged(NAME_EditTP4, OBJPROP_XDISTANCE, startX+(tpW+GAP_H)*3); SetPropIfChanged(NAME_EditTP4, OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_EditTP4, OBJPROP_XSIZE, tpW);
               currentY += 20 + GAP_V;
               
               CUtilities::SetVisible(NAME_BtnExecute, true); CUtilities::SetVisible(NAME_BtnClose, true); int hExec = 55; int wHalf = (safeW - GAP_H) / 2; 
               SetPropIfChanged(NAME_BtnClose,   OBJPROP_XDISTANCE, startX);               SetPropIfChanged(NAME_BtnClose,   OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_BtnClose,   OBJPROP_XSIZE, wHalf); SetPropIfChanged(NAME_BtnClose,   OBJPROP_YSIZE, hExec);
               SetPropIfChanged(NAME_BtnExecute, OBJPROP_XDISTANCE, startX+wHalf+GAP_H); SetPropIfChanged(NAME_BtnExecute, OBJPROP_YDISTANCE, currentY); SetPropIfChanged(NAME_BtnExecute, OBJPROP_XSIZE, wHalf); SetPropIfChanged(NAME_BtnExecute, OBJPROP_YSIZE, hExec);
               currentY += hExec + GAP_V;
            }
            H = currentY - Y;
         } break;
      }
      SetPropIfChanged(NAME_ObjPanel,         OBJPROP_YSIZE, H);
      SetPropIfChanged(NAME_ObjMasterShield, OBJPROP_XSIZE, W);
      SetPropIfChanged(NAME_ObjMasterShield, OBJPROP_YSIZE, H);
      
      if(_enableTerminal) { 
         CUtilities::SetVisible(NAME_BtnTerminalToggle, true); 
         SetPropIfChanged(NAME_BtnTerminalToggle, OBJPROP_XDISTANCE, X); 
         SetPropIfChanged(NAME_BtnTerminalToggle, OBJPROP_YDISTANCE, Y + H); 
         SetPropIfChanged(NAME_BtnTerminalToggle, OBJPROP_XSIZE, W); 
         UpdateTerminal(magicNum); 
      } else {
         CUtilities::SetVisible(NAME_BtnTerminalToggle, false);
      }
   }

   void UpdateTerminal(int magicNum) {
      if(IsDragging) return;

      if(!IsTerminalOpen) { 
         CUtilities::SetVisible(NAME_ObjTerminalBG, false); 
         for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) {
            string name = ObjectName(0, i);
            if(StringFind(name, "AIK_Trm_") >= 0) CUtilities::SetVisible(name, false);
         }
         ObjectSetString(0, NAME_BtnTerminalToggle, OBJPROP_TEXT, "v"); 
         return; 
      }
      
      ObjectSetString(0, NAME_BtnTerminalToggle, OBJPROP_TEXT, "^"); 

      for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) {
         string objName = ObjectName(0, i);
         if(StringFind(objName, "AIK_Trm_") < 0) continue; 
         if(StringFind(objName, "_Hdr_") >= 0 || objName == NAME_ObjTerminalBG) continue;

         int lastUnderscore = FindLastIndex(objName, "_");
         if(lastUnderscore > 0) {
            ulong ticket = (ulong)StringToInteger(StringSubstr(objName, lastUnderscore + 1));
            bool isAlive = false;
            if(StringFind(objName, "_Pos_") >= 0) isAlive = PositionSelectByTicket(ticket);
            else if(StringFind(objName, "_Ord_") >= 0) isAlive = OrderSelect(ticket);
            
            if(!isAlive) {
               UnregisterFromDock(objName);
               ObjectDelete(0, objName);
            }
         }
      }

      int totalPos = 0, totalOrd = 0;
      for(int i = PositionsTotal() - 1; i >= 0; i--) { if(PositionGetTicket(i)>0 && PositionGetInteger(POSITION_MAGIC)==magicNum && PositionGetString(POSITION_SYMBOL)==_Symbol) totalPos++; }
      for(int i = OrdersTotal() - 1; i >= 0; i--) { if(OrderGetTicket(i)>0 && OrderGetInteger(ORDER_MAGIC)==magicNum && OrderGetString(ORDER_SYMBOL)==_Symbol) totalOrd++; }
      
      int totalRows = totalPos + totalOrd; int rowH = 25; int hdrH = 20; int terminalH = (totalRows > 0) ? (totalRows * 27) + 35 : 40; int termY = Y + H + 15;
      
      int zTrm = GUI_Z_BASE+502; 
      CUtilities::SetVisible(NAME_ObjTerminalBG, true); 
      CreateBgBox(NAME_ObjTerminalBG, X, termY, W, terminalH, clrTerminalBG, zTrm); 
      
      int startY = termY + 5; int startX = X + 5;
      string hdrBg = "AIK_Trm_Hdr_BG"; CreateBgBox(hdrBg, X, startY, W, hdrH, clrTrmHdrBG, GUI_Z_BASE+503);
      
      int wBadge=25, wAct=25, wAvail=W-10-wBadge-wAct-10, wSym=80, wVol=55, wPrf=wAvail-wSym-wVol;
      int xBadge=startX, xSym=xBadge+wBadge+2, xVol=xSym+wSym, xPrf=xVol+wVol, xAct=X+W-30;
      
      int zRow = GUI_Z_BASE+505;
      CreateBtn("AIK_Trm_H_1", "ORD", xBadge, startY, wBadge, hdrH, clrBtnRisk, zRow); CreateBtn("AIK_Trm_H_2", "SYMBOL", xSym, startY, wSym, hdrH, clrTrmHdrBG, zRow);
      CreateBtn("AIK_Trm_H_3", "VOL", xVol, startY, wVol, hdrH, clrTrmHdrBG, zRow); CreateBtn("AIK_Trm_H_4", "P/L", xPrf, startY, wPrf, hdrH, clrTrmHdrBG, zRow);
      CreateBtn("AIK_Trm_H_5", "CLS", xAct, startY, wAct, hdrH, clrBtnClose, zRow);
      startY += 22; int currentRow = 0;
      
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i); if(PositionGetInteger(POSITION_MAGIC) != magicNum) continue; if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
         long type = PositionGetInteger(POSITION_TYPE); double vol = PositionGetDouble(POSITION_VOLUME); double profit = PositionGetDouble(POSITION_PROFIT); string symbol = PositionGetString(POSITION_SYMBOL); string sTick = (string)ticket;
         int y = startY + (currentRow * 27); color bgZebra = (currentRow % 2 == 0) ? clrTrmRow1 : clrTrmRow2;
         
         CreateBtn("AIK_Trm_Pos_Bg_" + sTick, (type==POSITION_TYPE_BUY)?"B":"S", xBadge, y, wBadge, 20, (type==POSITION_TYPE_BUY)?clrBtnBuyMkt:clrBtnSellMkt, zRow);
         CreateBtn("AIK_Trm_Pos_Sym_" + sTick, symbol, xSym, y, wSym, 20, clrTerminalBG, zRow); ObjectSetInteger(0, "AIK_Trm_Pos_Sym_" + sTick, OBJPROP_BGCOLOR, bgZebra);
         
         string vName = "AIK_Trm_Pos_Vol_" + sTick;
         if(ObjectFind(0, vName) < 0) CreateEdit(vName, DoubleToString(vol, 2), xVol, y, wVol, 20, zRow);
         else {
             if(ObjectGetInteger(0, vName, OBJPROP_COLOR) != clrOrange) { 
                 ObjectSetString(0, vName, OBJPROP_TEXT, DoubleToString(vol, 2));
                 ObjectSetInteger(0, vName, OBJPROP_COLOR, clrInputTxt);
             }
         }
         ObjectSetInteger(0, vName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
         SetPropIfChanged(vName, OBJPROP_XDISTANCE, xVol); SetPropIfChanged(vName, OBJPROP_YDISTANCE, y); ObjectSetInteger(0, vName, OBJPROP_BGCOLOR, clrInputBG);
         
         string pName = "AIK_Trm_Pos_Prf_" + sTick;
         if(ObjectFind(0, pName) < 0) CreateEdit(pName, DoubleToString(profit, 2), xPrf, y, wPrf, 20, zRow);
         else {
             if(ObjectGetInteger(0, pName, OBJPROP_COLOR) != clrOrange) { 
                 ObjectSetString(0, pName, OBJPROP_TEXT, DoubleToString(profit, 2));
                 ObjectSetInteger(0, pName, OBJPROP_COLOR, (profit>=0)?clrGreen:clrRed);
             }
         }
         ObjectSetInteger(0, pName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
         SetPropIfChanged(pName, OBJPROP_XDISTANCE, xPrf); SetPropIfChanged(pName, OBJPROP_YDISTANCE, y); ObjectSetInteger(0, pName, OBJPROP_BGCOLOR, clrInputBG);
         
         bool isPendingVol = (ObjectGetInteger(0, vName, OBJPROP_COLOR) == clrOrange);
         bool isPendingPL = (ObjectGetInteger(0, pName, OBJPROP_COLOR) == clrOrange);
         string btnName = "AIK_Trm_Pos_Btn_" + sTick;
         
         if(isPendingVol || isPendingPL) {
             CreateBtn(btnName, "MOD", xAct, y, wAct, 20, clrBtnActive, zRow); // YEŞİL RENK YAPILDI
             ObjectSetInteger(0, btnName, OBJPROP_COLOR, clrWhite);
         } else {
             CreateBtn(btnName, "x", xAct, y, wAct, 20, clrBtnClose, zRow);
         }
         currentRow++;
      }
      for(int i = OrdersTotal() - 1; i >= 0; i--) {
         ulong ticket = OrderGetTicket(i); if(OrderGetInteger(ORDER_MAGIC) != magicNum) continue; if(OrderGetString(ORDER_SYMBOL) != _Symbol) continue;
         long type = OrderGetInteger(ORDER_TYPE); double vol = OrderGetDouble(ORDER_VOLUME_INITIAL); double openPrice = OrderGetDouble(ORDER_PRICE_OPEN); string symbol = OrderGetString(ORDER_SYMBOL); string sTick = (string)ticket;
         int y = startY + (currentRow * 27); color bgZebra = (currentRow % 2 == 0) ? clrTrmRow1 : clrTrmRow2; string tStr = "P"; if(type==ORDER_TYPE_BUY_LIMIT||type==ORDER_TYPE_SELL_LIMIT) tStr="L"; if(type==ORDER_TYPE_BUY_STOP||type==ORDER_TYPE_SELL_STOP) tStr="S";
         
         CreateBtn("AIK_Trm_Ord_Bg_" + sTick, tStr, xBadge, y, wBadge, 20, clrBtnRisk, zRow);
         CreateBtn("AIK_Trm_Ord_Sym_" + sTick, symbol, xSym, y, wSym, 20, clrTerminalBG, zRow); ObjectSetInteger(0, "AIK_Trm_Ord_Sym_" + sTick, OBJPROP_BGCOLOR, bgZebra);
         CreateBtn("AIK_Trm_Ord_Vol_" + sTick, DoubleToString(vol, 2), xVol, y, wVol, 20, clrTerminalBG, zRow); ObjectSetInteger(0, "AIK_Trm_Ord_Vol_" + sTick, OBJPROP_BGCOLOR, bgZebra);
         CreateBtn("AIK_Trm_Ord_Prf_" + sTick, "@ " + DoubleToString(openPrice, _Digits), xPrf, y, wPrf, 20, clrTerminalBG, zRow); ObjectSetInteger(0, "AIK_Trm_Ord_Prf_" + sTick, OBJPROP_BGCOLOR, bgZebra); ObjectSetInteger(0, "AIK_Trm_Ord_Prf_" + sTick, OBJPROP_COLOR, clrBtnGray);
         CreateBtn("AIK_Trm_Ord_Btn_" + sTick, "x", xAct, y, wAct, 20, clrBtnClose, zRow); currentRow++;
      }
   }
   
   void UpdatePinButton() {
      if(IsPinned) { ObjectSetInteger(0, NAME_BtnPin, OBJPROP_BGCOLOR, clrBtnPinActive); ObjectSetString(0, NAME_BtnPin, OBJPROP_TEXT, "\x25CF"); }
      else { ObjectSetInteger(0, NAME_BtnPin, OBJPROP_BGCOLOR, clrBtnGray); ObjectSetString(0, NAME_BtnPin, OBJPROP_TEXT, "\x25CB"); } ChartRedraw();
   }
   
   void ToggleMinimize() { IsMinimized = !IsMinimized; ChartRedraw(); }

   void HandleDrag(int x, int y, int b, bool _syncActive, int _trendDir, bool _enableTerminal, int magicNum) {
      if(!IsDragging && b == 1) { 
         long btnX = ObjectGetInteger(0, NAME_BtnDrag, OBJPROP_XDISTANCE); long btnY = ObjectGetInteger(0, NAME_BtnDrag, OBJPROP_YDISTANCE);
         long btnW = ObjectGetInteger(0, NAME_BtnDrag, OBJPROP_XSIZE); long btnH = ObjectGetInteger(0, NAME_BtnDrag, OBJPROP_YSIZE);
         if(x >= btnX && x <= (btnX + btnW) && y >= btnY && y <= (btnY + btnH)) {
            IsDragging = true;
            DragOffsetX = x - X; DragOffsetY = y - Y;
         }
      } else if(IsDragging) { 
         if(b == 1) { 
            X = x - DragOffsetX; Y = y - DragOffsetY; if(X < 0) X = 0; if(Y < 0) Y = 0; 
            UpdatePosition(_syncActive, _trendDir, _enableTerminal, magicNum); 
            ChartRedraw(); 
         } else {
            IsDragging = false; 
            UpdatePosition(_syncActive, _trendDir, _enableTerminal, magicNum); 
            if(IsTerminalOpen) UpdateTerminal(magicNum); 
            ChartRedraw();
         }
      }
   }
};
//+-----------------------------------------------------------------------+
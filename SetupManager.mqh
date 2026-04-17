//+------------------------------------------------------------------+
//|                                                 SetupManager.mqh |
//|                                     Copyright 2026, AIK Project  |
//|                                      Project: AIK Trade Manager  |
//| Version: 31.0 (PERFORMANCE UPDATE: Removed Redraw Loops)         |
//+------------------------------------------------------------------+
#property strict

#include "Defines.mqh"
#include "Utilities.mqh"
#include "RiskManager.mqh"

enum ENUM_INTERACTION_MODE {
   MODE_NONE, MODE_MOVE_ALL, MODE_MODIFY_ENTRY, MODE_MODIFY_SL,
   MODE_MODIFY_TP, MODE_MODIFY_TP2, MODE_MODIFY_TP3, MODE_MODIFY_TP4,
   MODE_RESIZE_TIME, MODE_DRAG_TOOL_AREA
};

struct STPTarget {
   int id; 
   double dist;
   double lot;
};

class CSetupManager
{
private:
   color m_clrEntry, m_clrSL, m_clrTP, m_clrBE;
   color m_clrFillLoss, m_clrFillWin, m_clrGhostWin, m_clrGhostLoss;
   
   bool m_useGuideRays;
   color m_guideRayColor;
   ENUM_LINE_STYLE m_guideRayStyle;
   int m_guideRayWidth;
   string m_nameGuideRay;
   
   int m_startDistPx, m_lineWidth, m_magnetSens, m_barOffset; 
   
   bool m_isDragging;        
   bool m_isPreDragging;     
   ENUM_INTERACTION_MODE m_dragMode;
   
   bool m_isTrackingPrice, m_isSync, m_showExecBtn, m_isPendingOrder, m_isSplitMode; 
   bool m_isLiveSim; 
   bool m_isPermanentSelected, m_isMouseHovering, m_lastVisibilityState; 
   
   bool m_isHistorySetup; 
   datetime m_historyRefTime; 
   
   bool m_isSetupConfirmed; 
   
   bool m_isTP2Locked, m_isTP3Locked, m_isTP4Locked;
   bool m_manualTP2, m_manualTP3, m_manualTP4; 
   double m_valTP2Pct, m_valTP3Pct, m_valTP4Pct; 
   
   // SYNC OFF modu için sabit mesafe takibi
   double m_fixedSlDist;   // Entry'den SL'ye sabit mesafe
   double m_fixedTpDist;   // Entry'den TP'ye sabit mesafe
   bool   m_fixedSlAbove;  // SL entry'nin üstünde mi
   bool   m_fixedTpAbove;  // TP entry'nin üstünde mi
   bool   m_isSyncMode;    // Aktif setup'ın sync modu
   
   string m_pattSPL; 
   string m_pattEXT; 
   
   ENUM_SPL_MODE m_splMode;
   int m_aggressiveOffset;
   
   uint m_lastActionTick; 

   double m_lastCurrentPrice, m_simulatedExitPrice; 
   double m_recalledVolume; 
   
   datetime m_startTime, m_endTime;
   
   int m_dragRefX, m_dragRefY; double m_dragRefPrice; datetime m_dragRefTime; uint m_lastClickTick; 

   string m_nameZoneLoss, m_nameZoneWin, m_nameHandleEntry, m_nameHandleSL, m_nameHandleTP, m_nameHandleTime;
   string m_nameHandleTP2, m_nameHandleTP3, m_nameHandleTP4, m_nameLineGhost, m_nameGhostFill; 
   string m_lblEntry, m_lblSL, m_lblTP1, m_lblTP2, m_lblTP3, m_lblTP4, m_btnExecChart; 
   string m_btnAddTP, m_btnRemTP2, m_btnRemTP3, m_btnRemTP4; 
   string m_lineEntry, m_lineSL, m_lineTP1, m_lineBE, m_lineTP2, m_lineTP3, m_lineTP4;
   string m_hoveredHandle; const int SZ_BASE; const int SZ_HOVER;

   bool CheckClick(string n, int x, int y) { 
      if(ObjectFind(0,n)<0) return false; 
      long lx=ObjectGetInteger(0,n,OBJPROP_XDISTANCE);
      long ly=ObjectGetInteger(0,n,OBJPROP_YDISTANCE);
      long lw=ObjectGetInteger(0,n,OBJPROP_XSIZE);
      long lh=ObjectGetInteger(0,n,OBJPROP_YSIZE); 
      return (x>=lx && x<=lx+lw && y>=ly && y<=ly+lh); 
   }

   bool CheckZoneClick(string n, int x, int y) { 
      double p; datetime t; int s; 
      if(ChartXYToTimePrice(0,x,y,s,t,p)) { 
         if(ObjectFind(0,n)<0) return false;
         double p1=ObjectGetDouble(0,n,OBJPROP_PRICE,0);
         double p2=ObjectGetDouble(0,n,OBJPROP_PRICE,1); 
         if(t>=m_startTime && t<=m_endTime && p>=MathMin(p1,p2) && p<=MathMax(p1,p2)) return true; 
      } 
      return false; 
   }

   void ApplyMagnet(double &price, int x, int y) { 
      if(m_magnetSens<=0) return; 
      int b=iBarShift(_Symbol,0,m_dragRefTime); if(b<0) return; 
      double h=iHigh(_Symbol,0,b), l=iLow(_Symbol,0,b), o=iOpen(_Symbol,0,b), c=iClose(_Symbol,0,b); 
      int yH,yL,yO,yC,dm; 
      ChartTimePriceToXY(0,0,(datetime)m_dragRefTime,h,dm,yH); 
      ChartTimePriceToXY(0,0,(datetime)m_dragRefTime,l,dm,yL); 
      ChartTimePriceToXY(0,0,(datetime)m_dragRefTime,o,dm,yO); 
      ChartTimePriceToXY(0,0,(datetime)m_dragRefTime,c,dm,yC); 
      int dH=MathAbs(y-yH), dL=MathAbs(y-yL), dO=MathAbs(y-yO), dC=MathAbs(y-yC); 
      int minD=m_magnetSens; 
      if(dH<=minD){minD=dH;price=h;} 
      if(dL<=minD){minD=dL;price=l;} 
      if(dO<=minD){minD=dO;price=o;} 
      if(dC<=minD){minD=dC;price=c;} 
   }

   double GetPriceBySDValue(double sdVal) {
      for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) {
         string name = ObjectName(0, i);
         if(StringFind(name, "AIK_Draw_SD_T_") >= 0) {
            string text = ObjectGetString(0, name, OBJPROP_TEXT); 
            double val = 0; int start = StringFind(text, ":");
            if(start > 0) val = StringToDouble(StringSubstr(text, start + 1)); else val = StringToDouble(text);
            if(MathAbs(val - sdVal) < 0.01) return ObjectGetDouble(0, name, OBJPROP_PRICE);
         }
      }
      return 0;
   }

   double GetAggressiveSLPrice(bool isBuy) {
       string targetMatch = isBuy ? "AIK_Draw_IC_Sup" : "AIK_Draw_IC_Res";
       string avoid = "FVG"; 
       datetime bestTime = 0;
       for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--) {
           string n = ObjectName(0, i);
           if(StringFind(n, targetMatch) < 0) continue;
           if(StringFind(n, avoid) >= 0) continue;
           datetime t = (datetime)ObjectGetInteger(0, n, OBJPROP_TIME);
           if(t > bestTime) bestTime = t;
       }
       if(bestTime > 0) {
           int b = iBarShift(_Symbol, 0, bestTime);
           if(b >= 0) {
               double p = 0;
               if(isBuy) p = iLow(_Symbol, 0, b) - (m_aggressiveOffset * _Point);
               else p = iHigh(_Symbol, 0, b) + (m_aggressiveOffset * _Point);
               return p;
           }
       }
       return 0;
   }

   double GetNextSDLevelPrice(double currentPrice, string pattern, bool isBuy) {
       string parts[]; int count = StringSplit(pattern, ',', parts);
       if(count <= 0) return 0;
       double sdValues[]; ArrayResize(sdValues, count);
       for(int i=0; i<count; i++) sdValues[i] = StringToDouble(parts[i]);
       ArraySort(sdValues); 
       for(int i=0; i<count; i++) {
           double p = GetPriceBySDValue(sdValues[i]); 
           if(p == 0) continue; 
           if(isBuy) { if(p > currentPrice + (_Point * 10)) return p; } 
           else { if(p < currentPrice - (_Point * 10)) return p; }
       }
       return 0; 
   }
   
   double ParseSD(string pattern, int indexFromMax) {
       string parts[]; int count = StringSplit(pattern, ',', parts);
       if(count <= 0) return 0;
       double sdValues[]; ArrayResize(sdValues, count);
       for(int i=0; i<count; i++) sdValues[i] = StringToDouble(parts[i]);
       ArraySort(sdValues); ArrayReverse(sdValues); 
       if(indexFromMax >= 0 && indexFromMax < count) return GetPriceBySDValue(sdValues[indexFromMax]);
       return 0;
   }

   void DrawGhostLine() { 
      if(TimeCurrent()<m_startTime) { ObjectDelete(0, m_nameLineGhost); ObjectDelete(0, m_nameGhostFill); m_simulatedExitPrice=0; return; } 
      datetime tStart=m_startTime; bool act=false; 
      int cStart=iBarShift(_Symbol,0,m_startTime), cEnd=iBarShift(_Symbol,0,TimeCurrent()); 
      if(cStart<0)cStart=0; if(cEnd<0)cEnd=0; 
      for(int i=cStart; i>=cEnd; i--) { 
         double l=iLow(_Symbol,0,i), h=iHigh(_Symbol,0,i); if(l<=m_entryPrice && h>=m_entryPrice) { act=true; tStart=iTime(_Symbol,0,i); break; } 
      } 
      if(!act) { ObjectDelete(0, m_nameLineGhost); ObjectDelete(0, m_nameGhostFill); m_simulatedExitPrice=0; return; } 
      datetime tEnd=m_endTime, tNow=TimeCurrent(), tLimit=(tNow>tEnd)?tEnd:tNow; 
      int sBar=iBarShift(_Symbol,0,tStart), eBar=iBarShift(_Symbol,0,tLimit); 
      if(sBar<0||eBar<0) return; 
      bool isBuy=(ActiveOrderType==1||ActiveOrderType==3||ActiveOrderType==5); 
      double hPrice=0; datetime hTime=0; bool isHit=false; double fT=m_tpPrice; 
      if(IsTP2) fT=isBuy?MathMax(fT,m_tpPrice2):MathMin(fT,m_tpPrice2); 
      if(IsTP3) fT=isBuy?MathMax(fT,m_tpPrice3):MathMin(fT,m_tpPrice3); 
      if(IsTP4) fT=isBuy?MathMax(fT,m_tpPrice4):MathMin(fT,m_tpPrice4); 
      for(int i=sBar; i>=eBar; i--) { 
         double l=iLow(_Symbol,0,i), h=iHigh(_Symbol,0,i); datetime t=iTime(_Symbol,0,i); 
         if(isBuy) { if(l<=m_slPrice) { isHit=true; hPrice=m_slPrice; hTime=t; break; } if(h>=fT) { isHit=true; hPrice=fT; hTime=t; break; } } 
         else { if(h>=m_slPrice) { isHit=true; hPrice=m_slPrice; hTime=t; break; } if(l<=fT) { isHit=true; hPrice=fT; hTime=t; break; } } 
      } 
      
      // Hit olduysa exit fiyatı dondur - PnL hesaplaması bu fiyata göre yapılır
      double fP = 0;
      datetime fTi = 0;
      if(isHit) {
         fP = hPrice; fTi = hTime;
         // GhostLine bitişini frozen yapıyoruz
         m_simulatedExitPrice = fP;
      } else {
         fP = (TimeCurrent() > tEnd) ? iClose(_Symbol,0,eBar) : m_lastCurrentPrice;
         fTi = (TimeCurrent() > tEnd) ? tEnd : tNow;
         m_simulatedExitPrice = fP; // Canlı takip
      }
      
      if(fTi <= tStart) { ObjectDelete(0, m_nameLineGhost); ObjectDelete(0, m_nameGhostFill); return; }
      
      if(ObjectFind(0,m_nameLineGhost)<0) ObjectCreate(0,m_nameLineGhost,OBJ_TREND,0,0,0); 
      ObjectSetInteger(0,m_nameLineGhost,OBJPROP_TIME,0,tStart); ObjectSetDouble(0,m_nameLineGhost,OBJPROP_PRICE,0,m_entryPrice); 
      ObjectSetInteger(0,m_nameLineGhost,OBJPROP_TIME,1,fTi); ObjectSetDouble(0,m_nameLineGhost,OBJPROP_PRICE,1,fP); 
      ObjectSetInteger(0,m_nameLineGhost,OBJPROP_COLOR,clrGray); ObjectSetInteger(0,m_nameLineGhost,OBJPROP_STYLE,STYLE_DOT); 
      ObjectSetInteger(0,m_nameLineGhost,OBJPROP_WIDTH,1); ObjectSetInteger(0,m_nameLineGhost,OBJPROP_RAY_RIGHT,false); 
      if(ObjectFind(0,m_nameGhostFill)<0) ObjectCreate(0,m_nameGhostFill,OBJ_RECTANGLE,0,0,0); 
      ObjectSetInteger(0,m_nameGhostFill,OBJPROP_TIME,0,tStart); ObjectSetDouble(0,m_nameGhostFill,OBJPROP_PRICE,0,m_entryPrice); 
      ObjectSetInteger(0,m_nameGhostFill,OBJPROP_TIME,1,fTi); ObjectSetDouble(0,m_nameGhostFill,OBJPROP_PRICE,1,fP); 
      bool iP=(isBuy?(fP>m_entryPrice):(fP<m_entryPrice)); 
      ObjectSetInteger(0,m_nameGhostFill,OBJPROP_COLOR,iP?m_clrGhostWin:m_clrGhostLoss); 
      ObjectSetInteger(0,m_nameGhostFill,OBJPROP_FILL,true); ObjectSetInteger(0,m_nameGhostFill,OBJPROP_BACK,true); 
   }

   void UpdateGuideRays() {
       if(!m_useGuideRays) { ObjectDelete(0, m_nameGuideRay); return; }
       double rayPrice = 0; bool show = false;
       if(m_hoveredHandle == m_nameHandleEntry) { rayPrice = m_entryPrice; show = true; }
       else if(m_hoveredHandle == m_nameHandleSL) { rayPrice = m_slPrice; show = true; }
       else if(m_hoveredHandle == m_nameHandleTP) { rayPrice = m_tpPrice; show = true; }
       else if(IsTP2 && m_hoveredHandle == m_nameHandleTP2) { rayPrice = m_tpPrice2; show = true; }
       else if(IsTP3 && m_hoveredHandle == m_nameHandleTP3) { rayPrice = m_tpPrice3; show = true; }
       else if(IsTP4 && m_hoveredHandle == m_nameHandleTP4) { rayPrice = m_tpPrice4; show = true; }

       if(m_isDragging) {
           if(m_dragMode == MODE_MODIFY_ENTRY || m_dragMode == MODE_MOVE_ALL || m_dragMode == MODE_DRAG_TOOL_AREA) { rayPrice = m_entryPrice; show = true; }
           else if(m_dragMode == MODE_MODIFY_SL) { rayPrice = m_slPrice; show = true; }
           else if(m_dragMode == MODE_MODIFY_TP) { rayPrice = m_tpPrice; show = true; }
           else if(m_dragMode == MODE_MODIFY_TP2) { rayPrice = m_tpPrice2; show = true; }
           else if(m_dragMode == MODE_MODIFY_TP3) { rayPrice = m_tpPrice3; show = true; }
           else if(m_dragMode == MODE_MODIFY_TP4) { rayPrice = m_tpPrice4; show = true; }
       }
       if(show) {
           if(ObjectFind(0, m_nameGuideRay) < 0) ObjectCreate(0, m_nameGuideRay, OBJ_TREND, 0, 0, 0);
           ObjectSetInteger(0, m_nameGuideRay, OBJPROP_TIME, 0, m_startTime); ObjectSetDouble(0, m_nameGuideRay, OBJPROP_PRICE, 0, rayPrice);
           ObjectSetInteger(0, m_nameGuideRay, OBJPROP_TIME, 1, m_endTime); ObjectSetDouble(0, m_nameGuideRay, OBJPROP_PRICE, 1, rayPrice);
           ObjectSetInteger(0, m_nameGuideRay, OBJPROP_RAY_LEFT, true); ObjectSetInteger(0, m_nameGuideRay, OBJPROP_RAY_RIGHT, false); 
           ObjectSetInteger(0, m_nameGuideRay, OBJPROP_COLOR, m_guideRayColor); ObjectSetInteger(0, m_nameGuideRay, OBJPROP_STYLE, m_guideRayStyle);
           ObjectSetInteger(0, m_nameGuideRay, OBJPROP_WIDTH, m_guideRayWidth); ObjectSetInteger(0, m_nameGuideRay, OBJPROP_SELECTABLE, false); ObjectSetInteger(0, m_nameGuideRay, OBJPROP_BACK, false);
       } else { ObjectDelete(0, m_nameGuideRay); }
   }

   void CreateToolBtn(string name, string text, color bg) { 
       if(ObjectFind(0, name)<0) ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0); 
       ObjectSetInteger(0, name, OBJPROP_XSIZE, 20); ObjectSetInteger(0, name, OBJPROP_YSIZE, 20); 
       ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg); ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite); 
       ObjectSetString(0, name, OBJPROP_TEXT, text); ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 11); 
       ObjectSetString(0, name, OBJPROP_FONT, "Calibri"); ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT); 
       ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER); ObjectSetInteger(0, name, OBJPROP_ZORDER, GUI_Z_BASE+40); 
   }

   void DrawToolButtons(bool isVisible) { 
      ObjectSetInteger(0, m_btnAddTP, OBJPROP_XDISTANCE, -5000); ObjectSetInteger(0, m_btnRemTP2, OBJPROP_XDISTANCE, -5000); 
      ObjectSetInteger(0, m_btnRemTP3, OBJPROP_XDISTANCE, -5000); ObjectSetInteger(0, m_btnRemTP4, OBJPROP_XDISTANCE, -5000); 
      if(!isVisible) return; 
      int sizeBtn = 20; int half = sizeBtn/2; int offsetSlotA = 5; int offsetSlotB = 30; 
      if(!IsTP4) { 
         double lastTP = IsTP3 ? m_tpPrice3 : (IsTP2 ? m_tpPrice2 : m_tpPrice);
         CreateToolBtn(m_btnAddTP, "+", clrBtnActive); int x,y; 
         if(ChartTimePriceToXY(0,0,m_endTime,lastTP,x,y)) { 
             bool hov = (m_btnAddTP == m_hoveredHandle);
             ObjectSetInteger(0, m_btnAddTP, OBJPROP_BGCOLOR, hov ? clrLime : clrBtnActive);
             ObjectSetInteger(0, m_btnAddTP, OBJPROP_XDISTANCE, x + offsetSlotB); 
             ObjectSetInteger(0, m_btnAddTP, OBJPROP_YDISTANCE, y - half); 
         } 
      } 
      if(IsTP2){ CreateToolBtn(m_btnRemTP2,"x",clrRed); int x,y; if(ChartTimePriceToXY(0,0,m_endTime,m_tpPrice2,x,y)){ bool hov=(m_btnRemTP2==m_hoveredHandle); ObjectSetInteger(0,m_btnRemTP2,OBJPROP_BGCOLOR,hov?clrOrangeRed:clrRed); ObjectSetInteger(0,m_btnRemTP2,OBJPROP_XDISTANCE,x+offsetSlotA);ObjectSetInteger(0,m_btnRemTP2,OBJPROP_YDISTANCE,y-half);} } 
      if(IsTP3){ CreateToolBtn(m_btnRemTP3,"x",clrRed); int x,y; if(ChartTimePriceToXY(0,0,m_endTime,m_tpPrice3,x,y)){ bool hov=(m_btnRemTP3==m_hoveredHandle); ObjectSetInteger(0,m_btnRemTP3,OBJPROP_BGCOLOR,hov?clrOrangeRed:clrRed); ObjectSetInteger(0,m_btnRemTP3,OBJPROP_XDISTANCE,x+offsetSlotA);ObjectSetInteger(0,m_btnRemTP3,OBJPROP_YDISTANCE,y-half);} } 
      if(IsTP4){ CreateToolBtn(m_btnRemTP4,"x",clrRed); int x,y; if(ChartTimePriceToXY(0,0,m_endTime,m_tpPrice4,x,y)){ bool hov=(m_btnRemTP4==m_hoveredHandle); ObjectSetInteger(0,m_btnRemTP4,OBJPROP_BGCOLOR,hov?clrOrangeRed:clrRed); ObjectSetInteger(0,m_btnRemTP4,OBJPROP_XDISTANCE,x+offsetSlotA);ObjectSetInteger(0,m_btnRemTP4,OBJPROP_YDISTANCE,y-half);} } 
   }

   void UpdateSmartLabel(string name, double price, string text, int type) { 
       if(ObjectFind(0, name)<0) return; 
       bool vis = (m_isPermanentSelected || m_isMouseHovering || m_isDragging);
       if(!vis) { ObjectSetInteger(0, name, OBJPROP_XDISTANCE, -5000); if(type==0 && m_showExecBtn) ObjectSetInteger(0, m_btnExecChart, OBJPROP_XDISTANCE, -5000); return; } 
       
       datetime tC=m_startTime+(m_endTime-m_startTime)/2; int x,y; 
       if(!ChartTimePriceToXY(0,0,tC,price,x,y)) { ObjectSetInteger(0, name, OBJPROP_XDISTANCE, -5000); if(type==0 && m_showExecBtn) ObjectSetInteger(0, m_btnExecChart, OBJPROP_XDISTANCE, -5000); return; } 
       
       int h=22; int w=StringLen(text)*6+4; int bW=40; int gap=1; int tW=w; 
       if(type==0 && m_showExecBtn) tW+=(bW+gap); 
       int xs,xe,ys; ChartTimePriceToXY(0,0,m_startTime,price,xs,ys); ChartTimePriceToXY(0,0,m_endTime,price,xe,ys); int tTool=MathAbs(xe-xs); bool cr=(tTool<(tW+10)); 
       int yF=y; int off=15; 
       if(cr){ if(type==2){ if(m_tpPrice>m_entryPrice) yF=y-h-off; else yF=y+off; } else if(type==1){ if(m_slPrice<m_entryPrice) yF=y+off; else yF=y-h-off; } else if(type==0){ if(m_slPrice<m_entryPrice) yF=y+off; else yF=y-h-off; } } else { yF=y-(h/2); if(type==1||type==2) yF=y-h+5; } 
       int cBW=0; int cG=0; if(type==0 && m_showExecBtn) { cBW=40; cG=1; } 
       int totW=w+cG+cBW; int sX=x-(totW/2); 
       ObjectSetInteger(0, name, OBJPROP_XDISTANCE, sX); ObjectSetInteger(0, name, OBJPROP_YDISTANCE, yF); 
       ObjectSetString(0, name, OBJPROP_TEXT, text); ObjectSetInteger(0, name, OBJPROP_XSIZE, w); ObjectSetInteger(0, name, OBJPROP_YSIZE, h); 
       
       if(type==0 && m_showExecBtn) { 
           if(ObjectFind(0, m_btnExecChart)>=0) { 
               bool hov=(m_btnExecChart==m_hoveredHandle); int gr=hov?4:0; int lR=sX+w; 
               ObjectSetInteger(0, m_btnExecChart, OBJPROP_XDISTANCE, lR+cG-gr); ObjectSetInteger(0, m_btnExecChart, OBJPROP_YDISTANCE, yF-gr); 
               ObjectSetInteger(0, m_btnExecChart, OBJPROP_XSIZE, bW+(gr*2)); ObjectSetInteger(0, m_btnExecChart, OBJPROP_YSIZE, h+(gr*2)); 
               ObjectSetInteger(0, m_btnExecChart, OBJPROP_FONTSIZE, 8+(hov?2:0)); 
               if(m_hoveredHandle == m_btnExecChart) ObjectSetInteger(0, m_btnExecChart, OBJPROP_BGCOLOR, IsModificationMode ? clrLime : C'30,144,255');
           } 
       } 
   }

   void CreateLabel(string name, color bg) { if(ObjectFind(0, name)<0) { ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0); } ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg); ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite); ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10); ObjectSetString(0, name, OBJPROP_FONT, "Calibri"); ObjectSetInteger(0, name, OBJPROP_ZORDER, GUI_Z_BASE+25); ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER); ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, bg); }

   void UpdateSingleHandle(string name, datetime t, double p, int bx, int by, int ax, int ay) { 
       int x, y; 
       bool vis = (m_isPermanentSelected || m_isMouseHovering || m_isDragging);
       if(ChartTimePriceToXY(0, 0, t, p, x, y)) { 
           if(!vis) { ObjectSetInteger(0, name, OBJPROP_XDISTANCE, -5000); return; } 
           bool isHover = (name == m_hoveredHandle); 
           int size = isHover ? SZ_HOVER : SZ_BASE; int grow = isHover ? (SZ_HOVER - SZ_BASE)/2 : 0; 
           ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x + bx - grow); ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y + by - grow); 
           ObjectSetInteger(0, name, OBJPROP_XSIZE, size); ObjectSetInteger(0, name, OBJPROP_YSIZE, size); 
       } else ObjectSetInteger(0, name, OBJPROP_XDISTANCE, -5000); 
   }

   void UpdateHandles() { UpdateSingleHandle(m_nameHandleEntry, m_startTime, m_entryPrice, -6, -6, 0, -6); UpdateSingleHandle(m_nameHandleSL, m_startTime, m_slPrice, -6, -6, 0, -6); UpdateSingleHandle(m_nameHandleTP, m_startTime, m_tpPrice, -6, -6, 0, -6); UpdateSingleHandle(m_nameHandleTime, m_endTime, m_entryPrice, 0, -6, 0, -6); if(IsTP2) UpdateSingleHandle(m_nameHandleTP2, m_startTime, m_tpPrice2, -6, -6, 0, -6); else ObjectSetInteger(0, m_nameHandleTP2, OBJPROP_XDISTANCE, -5000); if(IsTP3) UpdateSingleHandle(m_nameHandleTP3, m_startTime, m_tpPrice3, -6, -6, 0, -6); else ObjectSetInteger(0, m_nameHandleTP3, OBJPROP_XDISTANCE, -5000); if(IsTP4) UpdateSingleHandle(m_nameHandleTP4, m_startTime, m_tpPrice4, -6, -6, 0, -6); else ObjectSetInteger(0, m_nameHandleTP4, OBJPROP_XDISTANCE, -5000); }

   void CreateHandle(string name, color clr) { if(ObjectFind(0, name)<0) { ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0); } ObjectSetInteger(0, name, OBJPROP_XSIZE, SZ_BASE); ObjectSetInteger(0, name, OBJPROP_YSIZE, SZ_BASE); ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clr); ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrWhite); ObjectSetString(0, name, OBJPROP_TEXT, ""); ObjectSetInteger(0, name, OBJPROP_ZORDER, GUI_Z_BASE+30); ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER); ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrWhite); }

   void DrawFiniteLine(string name, double price, color clr, bool isRay = false) { if(ObjectFind(0, name)<0) ObjectCreate(0, name, OBJ_TREND, 0, 0, 0); ObjectSetInteger(0, name, OBJPROP_TIME, 0, m_startTime); ObjectSetDouble(0, name, OBJPROP_PRICE, 0, price); ObjectSetInteger(0, name, OBJPROP_TIME, 1, m_endTime); ObjectSetDouble(0, name, OBJPROP_PRICE, 1, price); ObjectSetInteger(0, name, OBJPROP_COLOR, clr); ObjectSetInteger(0, name, OBJPROP_WIDTH, m_lineWidth); ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, isRay); ObjectSetInteger(0, name, OBJPROP_RAY_LEFT, isRay); }

   void DrawZone(string name, double p1, double p2, color fillClr) { if(ObjectFind(0, name)<0) ObjectCreate(0, name, OBJ_RECTANGLE, 0, 0, 0); ObjectSetInteger(0, name, OBJPROP_TIME, 0, m_startTime); ObjectSetDouble(0, name, OBJPROP_PRICE, 0, p1); ObjectSetInteger(0, name, OBJPROP_TIME, 1, m_endTime); ObjectSetDouble(0, name, OBJPROP_PRICE, 1, p2); ObjectSetInteger(0, name, OBJPROP_COLOR, fillClr); ObjectSetInteger(0, name, OBJPROP_FILL, true); ObjectSetInteger(0, name, OBJPROP_BACK, true); ObjectSetInteger(0, name, OBJPROP_WIDTH, 0); }

   void UpdateLabelCentered(string name, double price, string text, string zoneName, bool isEntry = false, bool isLocked = false) {
      if(ObjectFind(0, name) < 0) return;
      bool vis = (m_isPermanentSelected || m_isMouseHovering || m_isDragging);
      if(!vis) { ObjectSetInteger(0, name, OBJPROP_XDISTANCE, -5000); return; }
      datetime tCenter = m_startTime + (m_endTime - m_startTime) / 2; int x=0, y=0;
      if(ChartTimePriceToXY(0, 0, tCenter, price, x, y)) {
          int width = StringLen(text) * 6 + 4; int height = 22; 
          ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x - (width / 2)); 
          ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y - (height / 2));
          ObjectSetString(0, name, OBJPROP_TEXT, text);
          color bg = m_clrTP; if(isLocked) bg = clrDarkOrange; 
          ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg); ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, bg);
          ObjectSetInteger(0, name, OBJPROP_XSIZE, width); ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
      } else ObjectSetInteger(0, name, OBJPROP_XDISTANCE, -5000);
   }
   
   bool CheckToolAreaHover(int x, int y) {
      if(CheckZoneClick(m_nameZoneLoss, x, y) || CheckZoneClick(m_nameZoneWin, x, y)) return true;
      return false;
   }

   string ScanForHover(int x, int y) {
       if(CheckClick(m_btnAddTP, x, y)) return m_btnAddTP;
       if(CheckClick(m_btnRemTP2, x, y)) return m_btnRemTP2;
       if(CheckClick(m_btnRemTP3, x, y)) return m_btnRemTP3;
       if(CheckClick(m_btnRemTP4, x, y)) return m_btnRemTP4;
       if(CheckClick(m_btnExecChart, x, y)) return m_btnExecChart;
       if(CheckClick(m_nameHandleEntry, x, y)) return m_nameHandleEntry;
       if(CheckClick(m_nameHandleSL, x, y)) return m_nameHandleSL;
       if(CheckClick(m_nameHandleTP, x, y)) return m_nameHandleTP;
       if(CheckClick(m_nameHandleTime, x, y)) return m_nameHandleTime;
       if(IsTP2 && CheckClick(m_nameHandleTP2, x, y)) return m_nameHandleTP2;
       if(IsTP3 && CheckClick(m_nameHandleTP3, x, y)) return m_nameHandleTP3;
       if(IsTP4 && CheckClick(m_nameHandleTP4, x, y)) return m_nameHandleTP4;
       if(CheckClick(m_lblEntry, x, y)) return m_lblEntry;
       if(CheckToolAreaHover(x, y)) return "AREA";
       return "";
   }

   void CheckHover(int x, int y) {
      if(!IsLinesActive) { m_isMouseHovering = false; return; }
      string prevHover = m_hoveredHandle;
      m_hoveredHandle = ScanForHover(x, y); 
      bool isHovering = (StringLen(m_hoveredHandle) > 0);
      m_isMouseHovering = isHovering;
      if(m_hoveredHandle != prevHover || m_isMouseHovering != m_lastVisibilityState) { 
          m_lastVisibilityState = m_isMouseHovering; 
          DrawAll(); // ChartRedraw() KALDIRILDI (Performans)
      }
   }

public:
   int ActiveOrderType; bool IsLinesActive; bool IsTP2, IsTP3, IsTP4, IsBE;
   bool IsModificationMode; ulong RecalledTicket;
   bool m_enableToolDrag;

   double m_entryPrice, m_slPrice, m_tpPrice, m_tpPrice2, m_tpPrice3, m_tpPrice4;
   double Lot_TP1, Lot_TP2, Lot_TP3, Lot_TP4; 

   CSetupManager() : SZ_BASE(12), SZ_HOVER(18) {
      m_nameZoneLoss = NAME_RectZoneLoss; m_nameZoneWin = NAME_RectZoneWin; 
      m_nameHandleEntry = "AIK_TM_Handle_Entry"; m_nameHandleSL = "AIK_TM_Handle_SL"; m_nameHandleTP = "AIK_TM_Handle_TP";
      m_nameHandleTP2 = "AIK_TM_Handle_TP2"; m_nameHandleTP3 = "AIK_TM_Handle_TP3"; m_nameHandleTP4 = "AIK_TM_Handle_TP4";
      m_nameHandleTime = "AIK_TM_Handle_Time"; m_nameLineGhost = "AIK_TM_Line_Ghost"; m_nameGhostFill = "AIK_TM_Ghost_Fill"; 
      m_lblEntry = NAME_LblEntry; m_lblSL = NAME_LblSL; m_lblTP1 = NAME_LblTP1; 
      m_lblTP2 = NAME_LblTP2; m_lblTP3 = NAME_LblTP3; m_lblTP4 = NAME_LblTP4;
      m_btnExecChart = "AIK_TM_Btn_ChartExec"; m_btnAddTP = "AIK_TM_Btn_AddTP";
      m_btnRemTP2 = "AIK_TM_Btn_RemTP2"; m_btnRemTP3 = "AIK_TM_Btn_RemTP3"; m_btnRemTP4 = "AIK_TM_Btn_RemTP4";
      m_lineEntry = NAME_LineEntry; m_lineSL = NAME_LineSL; m_lineTP1 = NAME_LineTP1; 
      m_lineBE = NAME_LineBE; m_lineTP2 = NAME_LineTP2; m_lineTP3 = NAME_LineTP3; m_lineTP4 = NAME_LineTP4;
      m_nameGuideRay = "AIK_TM_Guide_Ray";
      IsLinesActive=false; m_enableToolDrag=true; m_isPermanentSelected=true; m_lastVisibilityState=true;
      m_isTrackingPrice=false; m_isLiveSim=false; m_isSync=false;
      m_splMode = SPL_AGGRESSIVE; m_aggressiveOffset = 0; 
      m_fixedSlDist = 0; m_fixedTpDist = 0; m_fixedSlAbove = false; m_fixedTpAbove = false; m_isSyncMode = false;
   }

   bool IsDragging() { return m_isDragging; }
   string GetExecBtnName() { return m_btnExecChart; }
   void SetSplitMode(bool enable) { m_isSplitMode = enable; }
   void SetSyncMode(bool enable) { m_isSync = enable; }
   void SetEnableToolDrag(bool enable) { m_enableToolDrag = enable; }
   void SetAggressiveSettings(ENUM_SPL_MODE mode, int offset) { m_splMode = mode; m_aggressiveOffset = offset; }
   void WakeUp() { if(IsLinesActive) { m_isPermanentSelected = true; DrawAll(); ChartRedraw(); } }
   void Sleep() { if(IsLinesActive) { m_isPermanentSelected = false; DrawAll(); ChartRedraw(); } }
   
   void SetPatterns(string spl, string ext) { m_pattSPL = spl; m_pattEXT = ext; }

   bool IsToolClicked(int x, int y) {
      if(!IsLinesActive) return false;
      if(ScanForHover(x, y) != "") return true;
      return false;
   }

   void Init(color cEntry, color cSL, color cTP, color cBE, color cFillLoss, color cFillWin, int distPx, int lineWidth, int magnetSens, bool showExec, color cGhostWin, color cGhostLoss, int barOffset, bool useRay, color rayCol, ENUM_LINE_STYLE rayStl, int rayWid) {
      m_clrEntry=cEntry; m_clrSL=cSL; m_clrTP=cTP; m_clrBE=cBE; m_clrFillLoss=cFillLoss; m_clrFillWin=cFillWin;
      m_startDistPx=distPx; m_lineWidth=lineWidth; m_magnetSens=magnetSens; m_showExecBtn=showExec; m_clrGhostWin=cGhostWin; m_clrGhostLoss=cGhostLoss;
      m_barOffset = barOffset; m_useGuideRays = useRay; m_guideRayColor = rayCol; m_guideRayStyle = rayStl; m_guideRayWidth = rayWid;
   }

   void CreateSetup(int type, bool isSync, int trendDir, double ask, double bid, double refTP, double refSL, datetime refTime = 0) {
      if(isSync && trendDir != 0) {
         if(trendDir == 1 && (type==1||type==3||type==5)) { Print("AIK: Trend Filtresi: Alis Engellendi"); return; }
         if(trendDir == -1 && (type==2||type==4||type==6)) { Print("AIK: Trend Filtresi: Satis Engellendi"); return; }
      }
      RemoveSetup(); ActiveOrderType=type; IsLinesActive=true; m_isSync=isSync; m_isSyncMode=isSync; m_isPermanentSelected=true; 
      
      m_isLiveSim = false; m_isSetupConfirmed = false; m_isTrackingPrice = false;

      if(refTime > 0 && refTP > 0 && refSL > 0) {
         double maxP = MathMax(refTP, refSL); double minP = MathMin(refTP, refSL);
         bool hasBreach = false; int startBar = iBarShift(_Symbol, PERIOD_CURRENT, refTime); int endBar = 0; 
         for(int i = startBar; i >= endBar; i--) { double h = iHigh(_Symbol, PERIOD_CURRENT, i); double l = iLow(_Symbol, PERIOD_CURRENT, i); if(h > maxP + _Point || l < minP - _Point) { hasBreach = true; break; } }
         double currentPrice = (type % 2 != 0) ? ask : bid; bool isOutside = (currentPrice > maxP || currentPrice < minP);
         if(hasBreach || isOutside) { m_isHistorySetup = true; m_historyRefTime = refTime; m_isLiveSim = true; m_startTime = refTime; } 
         else { m_isHistorySetup = false; m_isLiveSim = false; m_startTime = TimeCurrent() + (PeriodSeconds() * m_barOffset); }
      } else {
         // SYNC ON: barOffset ile başlat (entry fiyat takibinde tool ötelenebilir)
         // SYNC OFF: barOffset YOK, tool ilk atıldığı anda sabit kalır
         if(isSync) m_startTime = TimeCurrent() + (PeriodSeconds() * m_barOffset);
         else        m_startTime = TimeCurrent();
      }
      m_endTime = m_startTime + (PeriodSeconds() * 30); m_isTP2Locked=false; m_isTP3Locked=false; m_isTP4Locked=false;
      
      double baseRefPrice = (type%2!=0) ? ask : bid; 
      double distVal = 100 * _Point; 
      if(m_startDistPx > 0) { 
         int x, y; if(ChartTimePriceToXY(0, 0, TimeCurrent(), baseRefPrice, x, y)) { 
            double tp; datetime dt; int ds; 
            if(ChartXYToTimePrice(0, x, y + m_startDistPx, ds, dt, tp)) { double calculatedDist = MathAbs(baseRefPrice - tp); if(calculatedDist > 10 * _Point) distVal = calculatedDist; }
         } 
      }
      bool isBuy=(type==1||type==3||type==5);
      bool isMarketOrder = (type == 1 || type == 2);

      if(isSync && refTP > 0 && refSL > 0) {
          if(m_isHistorySetup) { 
             m_tpPrice = refTP; m_slPrice = refSL; m_entryPrice = (refTP + refSL) / 2.0; m_isTrackingPrice = false; 
          } 
          else {
             m_tpPrice = refTP; m_slPrice = refSL;
             if(isMarketOrder) { 
                if(type==1) m_entryPrice = ask; else m_entryPrice = bid; 
                // SYNC modda market emirlerde entry fiyatı takip eder
                m_isTrackingPrice = true; 
             } 
             else { 
                if(type==3) m_entryPrice = ask - distVal; else if(type==4) m_entryPrice = bid + distVal; 
                else if(type==5) m_entryPrice = ask + distVal; else if(type==6) m_entryPrice = bid - distVal; 
                m_isTrackingPrice = false; 
             }
             
             if(m_splMode == SPL_AGGRESSIVE) {
                 double aggSL = GetAggressiveSLPrice(isBuy);
                 if(aggSL > 0) m_slPrice = aggSL;
             }
          }
          if(m_isSplitMode) { double maxSD = ParseSD(m_pattSPL, 0); if(maxSD > 0) m_tpPrice = maxSD; } 
      } 
      else {
          // SYNC KAPALI: SL ve TP sabit, Entry (market emriyse) fiyatı takip eder
          // Önce entry'yi belirle
          if(type==1) m_entryPrice=ask; 
          else if(type==2) m_entryPrice=bid; 
          else if(type==3) m_entryPrice=ask-distVal; 
          else if(type==4) m_entryPrice=bid+distVal; 
          else if(type==5) m_entryPrice=ask+distVal; 
          else if(type==6) m_entryPrice=bid-distVal; 
          
          // SL/TP entry'den uzaklık cinsinden belirlenir - sabit kalacak
          m_slPrice = isBuy ? (m_entryPrice - distVal) : (m_entryPrice + distVal);
          if(m_isSplitMode) { 
             double risk = MathAbs(m_entryPrice - m_slPrice); 
             m_tpPrice = isBuy ? (m_entryPrice + (risk * 4.0)) : (m_entryPrice - (risk * 4.0)); 
          } else { 
             double risk = MathAbs(m_entryPrice - m_slPrice); 
             m_tpPrice = isBuy ? (m_entryPrice + risk) : (m_entryPrice - risk); 
          }
          
          // Market emriyse entry fiyatı takip eder, SL/TP SABİT KALIR
          if(isMarketOrder) m_isTrackingPrice = true; 
          else m_isTrackingPrice = false;
          
          // SL ve TP için başlangıç uzaklıklarını kaydet
          m_fixedSlDist = MathAbs(m_entryPrice - m_slPrice);
          m_fixedTpDist = MathAbs(m_entryPrice - m_tpPrice);
          m_fixedSlAbove = (m_slPrice > m_entryPrice); // SL entry'nin üstünde mi?
          m_fixedTpAbove = (m_tpPrice > m_entryPrice); // TP entry'nin üstünde mi?
      }
      double rDist=m_tpPrice-m_entryPrice; m_tpPrice2=m_entryPrice+(rDist*2.0); m_tpPrice3=m_entryPrice+(rDist*3.0); m_tpPrice4=m_entryPrice+(rDist*4.0);
      DrawAll(); ChartRedraw();
   }
   
   void RecallSetup(ulong ticket, int type, double entry, double sl, double tp, bool isPending) {
      RemoveSetup(); ActiveOrderType=type; IsLinesActive=true; m_isSync=false; IsModificationMode=true; RecalledTicket=ticket; m_isPendingOrder=isPending; m_isPermanentSelected=true; 
      m_isTrackingPrice=false; m_isLiveSim=false; m_lastCurrentPrice=0; m_simulatedExitPrice=0; 
      m_isSyncMode=false; m_fixedSlDist=0; m_fixedTpDist=0; m_fixedSlAbove=false; m_fixedTpAbove=false;
      m_entryPrice=entry; m_slPrice=sl; m_tpPrice=tp;
      m_manualTP2=false; m_manualTP3=false; m_manualTP4=false; m_isTP2Locked=false; m_isTP3Locked=false; m_isTP4Locked=false; m_recalledVolume = 0;
      if(isPending) { if(OrderSelect(ticket)) m_recalledVolume = OrderGetDouble(ORDER_VOLUME_INITIAL); } else { if(PositionSelectByTicket(ticket)) m_recalledVolume = PositionGetDouble(POSITION_VOLUME); }
      IsTP2=false; IsTP3=false; IsTP4=false;
      string prefix2 = "AIK_Trig_TP2_" + (string)ticket; string prefix3 = "AIK_Trig_TP3_" + (string)ticket; string prefix4 = "AIK_Trig_TP4_" + (string)ticket;
      double rDist = (m_tpPrice - m_entryPrice);
      if(ObjectFind(0, prefix2) >= 0) { IsTP2 = true; m_tpPrice2 = ObjectGetDouble(0, prefix2, OBJPROP_PRICE); } else { m_tpPrice2 = m_entryPrice + (rDist * 1.5); }
      if(ObjectFind(0, prefix3) >= 0) { IsTP3 = true; m_tpPrice3 = ObjectGetDouble(0, prefix3, OBJPROP_PRICE); } else { m_tpPrice3 = m_entryPrice + (rDist * 2.0); }
      if(ObjectFind(0, prefix4) >= 0) { IsTP4 = true; m_tpPrice4 = ObjectGetDouble(0, prefix4, OBJPROP_PRICE); } else { m_tpPrice4 = m_entryPrice + (rDist * 2.5); }
      if(m_slPrice==0) m_slPrice=m_entryPrice-(100*_Point); if(m_tpPrice==0) m_tpPrice=m_entryPrice+(100*_Point); 
      m_startTime = TimeCurrent() + (PeriodSeconds() * 2); m_endTime=m_startTime+(PeriodSeconds()*30); m_isSetupConfirmed = true; DrawAll(); ChartRedraw();
   }

   void RemoveSetup() {
      ObjectDelete(0,m_lineEntry); ObjectDelete(0,m_lineSL); ObjectDelete(0,m_lineBE); ObjectDelete(0,m_lineTP1); ObjectDelete(0,m_lineTP2); ObjectDelete(0,m_lineTP3); ObjectDelete(0,m_lineTP4);
      ObjectDelete(0,m_lblEntry); ObjectDelete(0,m_lblSL); ObjectDelete(0,m_lblTP1); ObjectDelete(0,m_lblTP2); ObjectDelete(0,m_lblTP3); ObjectDelete(0,m_lblTP4);
      ObjectDelete(0,m_nameZoneLoss); ObjectDelete(0,m_nameZoneWin); ObjectDelete(0,m_nameHandleEntry); ObjectDelete(0,m_nameHandleSL); ObjectDelete(0,m_nameHandleTP); ObjectDelete(0,m_nameHandleTime);
      ObjectDelete(0,m_nameHandleTP2); ObjectDelete(0,m_nameHandleTP3); ObjectDelete(0,m_nameHandleTP4); ObjectDelete(0,m_nameLineGhost); ObjectDelete(0,m_nameGhostFill); ObjectDelete(0,m_btnExecChart); 
      ObjectDelete(0,m_btnAddTP); ObjectDelete(0,m_btnRemTP2); ObjectDelete(0,m_btnRemTP3); ObjectDelete(0,m_btnRemTP4); ObjectDelete(0,m_nameGuideRay);
      IsLinesActive=false; ActiveOrderType=0; m_isTrackingPrice=false; m_isLiveSim=false; IsModificationMode=false; RecalledTicket=0; m_isPendingOrder=false; m_lastCurrentPrice=0; m_simulatedExitPrice=0; m_hoveredHandle=""; m_isPermanentSelected=false;
      IsTP2=false; IsTP3=false; IsTP4=false; m_isTP2Locked=false; m_isTP3Locked=false; m_isTP4Locked=false; m_isDragging=false; m_isPreDragging=false; m_dragMode=MODE_NONE; 
      m_fixedSlDist=0; m_fixedTpDist=0; m_fixedSlAbove=false; m_fixedTpAbove=false; m_isSyncMode=false; m_isSetupConfirmed=false;
      ChartRedraw();
   }

   void RefreshTPs() { WakeUp(); }

   void UpdateCalculations(CRiskManager &riskManager, ENUM_RISK_MODE riskMode, double defPct2, double defPct3, double defPct4) {
      if(!IsLinesActive) return;
      m_entryPrice = NormalizeDouble(m_entryPrice, _Digits); m_slPrice = NormalizeDouble(m_slPrice, _Digits); m_tpPrice = NormalizeDouble(m_tpPrice, _Digits);
      double userRiskValue = StringToDouble(ObjectGetString(0, NAME_EditRiskVal, OBJPROP_TEXT));
      double riskMoneyReal = 0;
      double totalLot = 0; if(IsModificationMode && m_recalledVolume > 0) totalLot = m_recalledVolume; else { totalLot = riskManager.CalculateLot(_Symbol, m_entryPrice, m_slPrice, riskMode, userRiskValue, riskMoneyReal); totalLot = riskManager.NormalizeLot(_Symbol, totalLot); }
      
      STPTarget targets[4]; int activeCount = 0;
      targets[activeCount].id = 1; targets[activeCount].dist = MathAbs(m_tpPrice - m_entryPrice); activeCount++;
      if(IsTP2) { targets[activeCount].id = 2; targets[activeCount].dist = MathAbs(m_tpPrice2 - m_entryPrice); activeCount++; }
      if(IsTP3) { targets[activeCount].id = 3; targets[activeCount].dist = MathAbs(m_tpPrice3 - m_entryPrice); activeCount++; }
      if(IsTP4) { targets[activeCount].id = 4; targets[activeCount].dist = MathAbs(m_tpPrice4 - m_entryPrice); activeCount++; }
      
      // SORT TARGETS BY DISTANCE (Ascending: Closest first)
      for(int i=0; i<activeCount-1; i++) { for(int j=i+1; j<activeCount; j++) { if(targets[j].dist < targets[i].dist) { STPTarget temp = targets[i]; targets[i] = targets[j]; targets[j] = temp; } } }

      if(m_isSplitMode) {
          // --- FIXED CASCADE LOGIC (50% of Remaining) ---
          double currentRem = totalLot;
          
          for(int i=0; i<activeCount; i++) {
              if(i == activeCount - 1) {
                  targets[i].lot = riskManager.NormalizeLot(_Symbol, currentRem);
              } else {
                  double val = riskManager.NormalizeLot(_Symbol, currentRem * 0.5);
                  double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
                  if(val < minLot) {
                     if(currentRem >= minLot) val = minLot; else val = currentRem; 
                  }
                  currentRem -= val;
                  targets[i].lot = val;
              }
          }
      } else { 
          double share = riskManager.NormalizeLot(_Symbol, totalLot / activeCount); for(int i=0; i<activeCount; i++) targets[i].lot = share;
          double used = 0; for(int i=0; i<activeCount; i++) used += targets[i].lot; double diff = riskManager.NormalizeLot(_Symbol, totalLot - used); if(diff != 0) targets[activeCount-1].lot += diff; 
      }
      
      Lot_TP1=0; Lot_TP2=0; Lot_TP3=0; Lot_TP4=0;
      for(int i=0; i<activeCount; i++) {
         if(targets[i].id == 1) Lot_TP1 = targets[i].lot;
         else if(targets[i].id == 2) Lot_TP2 = targets[i].lot;
         else if(targets[i].id == 3) Lot_TP3 = targets[i].lot;
         else if(targets[i].id == 4) Lot_TP4 = targets[i].lot;
      }
      
      UpdateLabels(riskManager, totalLot, riskMoneyReal, Lot_TP1, Lot_TP2, Lot_TP3, Lot_TP4); DrawAll(); // ChartRedraw() KALDIRILDI (Performans)
   }

   double CalculateProfitSafe(ENUM_ORDER_TYPE type, double volume, double openPrice, double closePrice) {
      if(volume <= 0) return 0; double profit = 0; if(OrderCalcProfit(type, _Symbol, volume, openPrice, closePrice, profit)) return profit;
      double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE); double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      if(tickSize > 0 && tickVal > 0) { double points = MathAbs(openPrice - closePrice); double ticks = points / tickSize; profit = ticks * tickVal * volume; if(type == ORDER_TYPE_BUY && closePrice < openPrice) profit = -profit; if(type == ORDER_TYPE_SELL && closePrice > openPrice) profit = -profit; return profit; } return 0;
   }

   void UpdateLabels(CRiskManager &risk, double tL, double rM, double l1, double l2, double l3, double l4) {
      double dSL = MathAbs(m_entryPrice - m_slPrice);
      double pips = (dSL / _Point) / ((_Digits==3||_Digits==5)?10.0:1.0);
      ENUM_ORDER_TYPE ot = (ActiveOrderType % 2 != 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      double slRiskVal = CalculateProfitSafe(ot, tL, m_entryPrice, m_slPrice);
      
      bool isSecure = false;
      if(ot == ORDER_TYPE_BUY && m_slPrice > m_entryPrice) isSecure = true;
      if(ot == ORDER_TYPE_SELL && m_slPrice < m_entryPrice) isSecure = true;
      string labelPrefix = isSecure ? "Secure" : "Stop";
      
      string slText = StringFormat("%s: %s (%.1f) %+.0f %s", labelPrefix, DoubleToString(m_slPrice, _Digits), pips, slRiskVal, AccountInfoString(ACCOUNT_CURRENCY));
      UpdateSmartLabel(m_lblSL, m_slPrice, slText, 1);
      
      if(ObjectFind(0, m_lblSL) >= 0) {
          ObjectSetInteger(0, m_lblSL, OBJPROP_BGCOLOR, isSecure ? clrLimeGreen : m_clrSL);
          ObjectSetInteger(0, m_lblSL, OBJPROP_BORDER_COLOR, isSecure ? clrLimeGreen : m_clrSL);
      }

      double rwTP1 = CalculateProfitSafe(ot, l1, m_entryPrice, m_tpPrice);
      string tpText = StringFormat("TP1 (Close: %.2f) %+.0f %s", l1, rwTP1, AccountInfoString(ACCOUNT_CURRENCY));
      UpdateSmartLabel(m_lblTP1, m_tpPrice, tpText, 2);
      if(IsTP2) { double rw2 = CalculateProfitSafe(ot, l2, m_entryPrice, m_tpPrice2); string t2 = StringFormat("TP2 (Close: %.2f) %+.0f %s", l2, rw2, AccountInfoString(ACCOUNT_CURRENCY)); UpdateLabelCentered(m_lblTP2, m_tpPrice2, t2, m_nameZoneWin, false, m_isTP2Locked); } else ObjectDelete(0, m_lblTP2);
      if(IsTP3) { double rw3 = CalculateProfitSafe(ot, l3, m_entryPrice, m_tpPrice3); string t3 = StringFormat("TP3 (Close: %.2f) %+.0f %s", l3, rw3, AccountInfoString(ACCOUNT_CURRENCY)); UpdateLabelCentered(m_lblTP3, m_tpPrice3, t3, m_nameZoneWin, false, m_isTP3Locked); } else ObjectDelete(0, m_lblTP3);
      if(IsTP4) { double rw4 = CalculateProfitSafe(ot, l4, m_entryPrice, m_tpPrice4); string t4 = StringFormat("TP4 (Close: %.2f) %+.0f %s", l4, rw4, AccountInfoString(ACCOUNT_CURRENCY)); UpdateLabelCentered(m_lblTP4, m_tpPrice4, t4, m_nameZoneWin, false, m_isTP4Locked); } else ObjectDelete(0, m_lblTP4);
      
      string pnlText = "";
      if(IsModificationMode) pnlText = " [MODIFY]";
      else {
          bool showPnL = false; double exitPrice = 0;
          if(m_isLiveSim && m_simulatedExitPrice > 0) { 
             // LiveSim (History veya Limit/Stop emir) modunda: GhostLine'ın son noktasını kullan
             showPnL = true; 
             exitPrice = m_simulatedExitPrice; 
          }
          else if(m_isSetupConfirmed && !m_isTrackingPrice) { 
             // Kullanıcı Entry etiketine tıklayarak sabitledi: canlı fiyatla PnL hesapla
             exitPrice = (ActiveOrderType % 2 != 0) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK); 
             showPnL = true; 
          }
          // m_isTrackingPrice == true ise PnL gösterme
          
          if(showPnL && exitPrice > 0) {
             double pnlVal = CalculateProfitSafe(ot, tL, m_entryPrice, exitPrice); 
             pnlText = StringFormat(" | PnL: %+.2f", pnlVal); 
          }
      }
      double rr = (dSL > 0) ? MathAbs(m_entryPrice - m_tpPrice) / dSL : 0;
      string eText = StringFormat("Lot: %.2f | RR: %.2f%s", tL, rr, pnlText);
      UpdateSmartLabel(m_lblEntry, m_entryPrice, eText, 0);
      if(IsBE && ObjectFind(0, m_lineBE) >= 0) { double beP = (m_entryPrice + m_tpPrice) / 2.0; ObjectSetDouble(0, m_lineBE, OBJPROP_PRICE, 0, beP); ObjectSetDouble(0, m_lineBE, OBJPROP_PRICE, 1, beP); ObjectSetInteger(0, m_lineBE, OBJPROP_TIME, 0, m_startTime); ObjectSetInteger(0, m_lineBE, OBJPROP_TIME, 1, m_endTime); }
   }

   void OnTickLogic() { UpdateHandles(); } 
   void OnTickLogic(double ask, double bid) {
      if(!IsLinesActive) return;
      double newPrice = (ActiveOrderType % 2 != 0) ? bid : ask;
      if(MathAbs(m_lastCurrentPrice - newPrice) < _Point && !m_isDragging) return;
      m_lastCurrentPrice = newPrice;
      bool isMarket = (ActiveOrderType == 1 || ActiveOrderType == 2);
      if(m_isTrackingPrice && !m_isDragging && isMarket) {
          m_entryPrice = (ActiveOrderType == 1) ? ask : bid;
          
          if(m_isSyncMode) {
             // SYNC ON: Entry hareket eder, startTime güncellenir, SL/TP sabit kalır
             if(m_isSplitMode && IsTP2) { 
                double risk = MathAbs(m_entryPrice - m_slPrice);
                bool isBuy = (ActiveOrderType == 1);
                if(isBuy) m_tpPrice2 = m_entryPrice + risk; else m_tpPrice2 = m_entryPrice - risk;
             }
             long duration = m_endTime - m_startTime; 
             m_startTime = TimeCurrent() + (PeriodSeconds() * m_barOffset); 
             m_endTime = m_startTime + (datetime)duration;
          }
          // SYNC OFF: Sadece m_entryPrice güncellendi, m_startTime/m_endTime/m_slPrice/m_tpPrice SABİT
          // Tool grafikte yerinde durur, sadece entry çizgisi fiyatla hareket eder
          
          DrawAll();
      } else { 
         if(!IsModificationMode) {
            DrawGhostLine();
         } else { 
            ObjectDelete(0, m_nameLineGhost); ObjectDelete(0, m_nameGhostFill); 
         } 
      }
      UpdateHandles();
   }

   void DrawAll() {
      if(!IsLinesActive) return;
      bool vis = (m_isPermanentSelected || m_isMouseHovering || m_isDragging);
      double maxTP = m_tpPrice;
      if(IsTP2) { if(ActiveOrderType%2!=0) maxTP = MathMax(maxTP, m_tpPrice2); else maxTP = MathMin(maxTP, m_tpPrice2); }
      if(IsTP3) { if(ActiveOrderType%2!=0) maxTP = MathMax(maxTP, m_tpPrice3); else maxTP = MathMin(maxTP, m_tpPrice3); }
      if(IsTP4) { if(ActiveOrderType%2!=0) maxTP = MathMax(maxTP, m_tpPrice4); else maxTP = MathMin(maxTP, m_tpPrice4); }
      DrawZone(m_nameZoneLoss, m_entryPrice, m_slPrice, m_clrFillLoss); DrawZone(m_nameZoneWin, m_entryPrice, maxTP, m_clrFillWin); 
      DrawFiniteLine(m_lineEntry, m_entryPrice, m_clrEntry); DrawFiniteLine(m_lineSL, m_slPrice, m_clrSL, false); DrawFiniteLine(m_lineTP1, m_tpPrice, m_clrTP, false);
      if(IsBE) DrawFiniteLine(m_lineBE, (m_entryPrice+m_tpPrice)/2.0, m_clrBE);
      if(IsTP2) { DrawFiniteLine(m_lineTP2, m_tpPrice2, m_clrTP, false); if(ObjectFind(0, m_lblTP2)<0) CreateLabel(m_lblTP2, m_clrTP); CreateHandle(m_nameHandleTP2, m_clrTP); } else { ObjectDelete(0, m_lineTP2); ObjectDelete(0, m_lblTP2); ObjectDelete(0, m_nameHandleTP2); }
      if(IsTP3) { DrawFiniteLine(m_lineTP3, m_tpPrice3, m_clrTP, false); if(ObjectFind(0, m_lblTP3)<0) CreateLabel(m_lblTP3, m_clrTP); CreateHandle(m_nameHandleTP3, m_clrTP); } else { ObjectDelete(0, m_lineTP3); ObjectDelete(0, m_lblTP3); ObjectDelete(0, m_nameHandleTP3); }
      if(IsTP4) { DrawFiniteLine(m_lineTP4, m_tpPrice4, m_clrTP, false); if(ObjectFind(0, m_lblTP4)<0) CreateLabel(m_lblTP4, m_clrTP); CreateHandle(m_nameHandleTP4, m_clrTP); } else { ObjectDelete(0, m_lineTP4); ObjectDelete(0, m_lblTP4); ObjectDelete(0, m_nameHandleTP4); }
      if(ObjectFind(0, m_lblEntry)<0) CreateLabel(m_lblEntry, m_clrEntry);
      if(m_showExecBtn) { if(ObjectFind(0, m_btnExecChart)<0) CreateLabel(m_btnExecChart, clrRoyalBlue); if(IsModificationMode) { ObjectSetString(0, m_btnExecChart, OBJPROP_TEXT, "MOD"); ObjectSetInteger(0, m_btnExecChart, OBJPROP_BGCOLOR, clrLimeGreen); } else { ObjectSetString(0, m_btnExecChart, OBJPROP_TEXT, "EXEC"); ObjectSetInteger(0, m_btnExecChart, OBJPROP_BGCOLOR, clrRoyalBlue); } if(m_hoveredHandle == m_btnExecChart) { ObjectSetInteger(0, m_btnExecChart, OBJPROP_BGCOLOR, IsModificationMode ? clrLime : C'30,144,255'); } if(!vis) ObjectSetInteger(0, m_btnExecChart, OBJPROP_XDISTANCE, -5000); } else ObjectDelete(0, m_btnExecChart);
      if(ObjectFind(0, m_lblSL)<0) CreateLabel(m_lblSL, m_clrSL); if(ObjectFind(0, m_lblTP1)<0) CreateLabel(m_lblTP1, m_clrTP);
      CreateHandle(m_nameHandleEntry, m_clrEntry); CreateHandle(m_nameHandleSL, m_clrSL); CreateHandle(m_nameHandleTP, m_clrTP); CreateHandle(m_nameHandleTime, m_clrEntry); 
      UpdateHandles(); DrawToolButtons(vis); UpdateGuideRays(); 
      if(!vis) { ObjectSetInteger(0, m_lblEntry, OBJPROP_XDISTANCE, -5000); ObjectSetInteger(0, m_lblSL, OBJPROP_XDISTANCE, -5000); ObjectSetInteger(0, m_lblTP1, OBJPROP_XDISTANCE, -5000); if(IsTP2) ObjectSetInteger(0, m_lblTP2, OBJPROP_XDISTANCE, -5000); if(IsTP3) ObjectSetInteger(0, m_lblTP3, OBJPROP_XDISTANCE, -5000); if(IsTP4) ObjectSetInteger(0, m_lblTP4, OBJPROP_XDISTANCE, -5000); if(m_showExecBtn) ObjectSetInteger(0, m_btnExecChart, OBJPROP_XDISTANCE, -5000); }
   }

   void HandleDrag(int x, int y, int b, CRiskManager &risk, ENUM_RISK_MODE mode, double defPct2, double defPct3, double defPct4) {
      if(!m_isDragging) CheckHover(x, y);
      if(b==1 && !m_isDragging) {
          if(!m_isPreDragging) { m_isPreDragging = true; m_dragRefX = x; m_dragRefY = y; }
          string h = ScanForHover(x, y);
          if(h == "") { if(GetTickCount() - m_lastActionTick > 1000) Sleep(); return; } 
          WakeUp(); m_isPermanentSelected = true;
          
          if(h == m_btnAddTP) { 
             bool isBuy = (ActiveOrderType==1 || ActiveOrderType==3 || ActiveOrderType==5);
             double riskVal = MathAbs(m_entryPrice - m_slPrice);
             double totalDist = MathAbs(m_tpPrice - m_entryPrice);

             if(m_isSplitMode) {
                if(m_isSync) {
                   if(!IsTP2) { IsTP2=true; m_tpPrice2 = isBuy ? (m_entryPrice + riskVal) : (m_entryPrice - riskVal); } 
                   else if(!IsTP3) { IsTP3=true; double p = ParseSD(m_pattSPL, 1); if(p>0) m_tpPrice3=p; else m_tpPrice3=(m_tpPrice+m_tpPrice2)/2.0; }
                   else if(!IsTP4) { IsTP4=true; double p = ParseSD(m_pattSPL, 2); if(p>0) m_tpPrice4=p; else m_tpPrice4=(m_tpPrice2+m_tpPrice3)/2.0; } 
                } else {
                   if(!IsTP2) { IsTP2=true; m_tpPrice2 = (m_entryPrice + m_tpPrice)/2.0; } 
                   else if(!IsTP3) { IsTP3=true; m_tpPrice3 = isBuy ? (m_entryPrice + (totalDist * 0.25)) : (m_entryPrice - (totalDist * 0.25)); } 
                   else if(!IsTP4) { IsTP4=true; m_tpPrice4 = isBuy ? (m_entryPrice + (totalDist * 0.75)) : (m_entryPrice - (totalDist * 0.75)); } 
                }
             } else {
                if(!IsTP2) { IsTP2=true; if(m_isSync) { double p = GetNextSDLevelPrice(m_tpPrice, m_pattEXT, isBuy); if(p>0) m_tpPrice2=p; else m_tpPrice2 = isBuy ? m_tpPrice+riskVal : m_tpPrice-riskVal; } else { m_tpPrice2 = isBuy ? m_tpPrice+riskVal : m_tpPrice-riskVal; } }
                else if(!IsTP3) { IsTP3=true; if(m_isSync) { double p = GetNextSDLevelPrice(m_tpPrice2, m_pattEXT, isBuy); if(p>0) m_tpPrice3=p; else m_tpPrice3 = isBuy ? m_tpPrice2+riskVal : m_tpPrice2-riskVal; } else { m_tpPrice3 = isBuy ? m_tpPrice2+riskVal : m_tpPrice2-riskVal; } }
                else if(!IsTP4) { IsTP4=true; if(m_isSync) { double p = GetNextSDLevelPrice(m_tpPrice3, m_pattEXT, isBuy); if(p>0) m_tpPrice4=p; else m_tpPrice4 = isBuy ? m_tpPrice3+riskVal : m_tpPrice3-riskVal; } else { m_tpPrice4 = isBuy ? m_tpPrice3+riskVal : m_tpPrice3-riskVal; } } 
             }
             UpdateCalculations(risk, mode, defPct2, defPct3, defPct4); ChartRedraw(); return; 
          }
          if(h == m_btnRemTP2 || h == m_btnRemTP3 || h == m_btnRemTP4 || h == m_lblTP2 || h == m_lblTP3 || h == m_lblTP4) {
             if(h==m_btnRemTP2) IsTP2=false; else if(h==m_btnRemTP3) IsTP3=false; else if(h==m_btnRemTP4) IsTP4=false;
             else if(h==m_lblTP2) { m_isTP2Locked=!m_isTP2Locked; } else if(h==m_lblTP3) { m_isTP3Locked=!m_isTP3Locked; } else if(h==m_lblTP4) { m_isTP4Locked=!m_isTP4Locked; }
             UpdateCalculations(risk, mode, defPct2, defPct3, defPct4); ChartRedraw(); return;
          }
          if(h == m_lblEntry && (GetTickCount() - m_lastActionTick > 500)) {
             m_lastActionTick = GetTickCount();
             
             if(m_isHistorySetup) {
                 // History setup: LiveSim toggle
                 m_isLiveSim = !m_isLiveSim;
                 m_isTrackingPrice = false;
                 m_isSetupConfirmed = true; 
             }
             else {
                 bool isMarket = (ActiveOrderType == 1 || ActiveOrderType == 2);
                 if(isMarket) {
                     if(m_isTrackingPrice) {
                         // Tracking açık -> Sabitle (fiyatı dondur, PnL başlasın)
                         m_isTrackingPrice = false;
                         m_isSetupConfirmed = true; 
                         long duration = m_endTime - m_startTime;
                         m_startTime = TimeCurrent(); 
                         m_endTime = m_startTime + (datetime)duration;
                         if(ActiveOrderType == 1) m_entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK); 
                         else m_entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                     } else {
                         // Sabitlenmiş -> Tracking'e geri dön
                         m_isTrackingPrice = true;
                         m_isSetupConfirmed = false;
                         m_simulatedExitPrice = 0; // PnL'yi sıfırla
                         long duration = m_endTime - m_startTime;
                         m_startTime = TimeCurrent() + (PeriodSeconds() * m_barOffset);
                         m_endTime = m_startTime + (datetime)duration;
                         // GhostLine'ı temizle
                         ObjectDelete(0, m_nameLineGhost);
                         ObjectDelete(0, m_nameGhostFill);
                     }
                 } else {
                     // Limit/Stop emirlerde: LiveSim toggle
                     m_isLiveSim = !m_isLiveSim;
                     if(!m_isLiveSim) m_simulatedExitPrice = 0;
                 }
             }
             DrawAll(); ChartRedraw(); return;
          }

          if(h == m_nameHandleEntry) m_dragMode = MODE_MODIFY_ENTRY;
          else if(h == m_nameHandleSL) m_dragMode = MODE_MODIFY_SL;
          else if(h == m_nameHandleTP) m_dragMode = MODE_MODIFY_TP;
          else if(h == m_nameHandleTP2) m_dragMode = MODE_MODIFY_TP2;
          else if(h == m_nameHandleTP3) m_dragMode = MODE_MODIFY_TP3;
          else if(h == m_nameHandleTP4) m_dragMode = MODE_MODIFY_TP4;
          else if(h == m_nameHandleTime) m_dragMode = MODE_RESIZE_TIME;
          else if(m_enableToolDrag && h == "AREA") {
             m_dragMode = MODE_DRAG_TOOL_AREA;
             if(m_isTrackingPrice) { m_isTrackingPrice = false; } 
          }
          else if(h == "AREA") m_dragMode = MODE_MOVE_ALL;
          
          if(m_dragMode != MODE_NONE) { 
             m_isDragging = true; m_isPreDragging = false; 
             int s; ChartXYToTimePrice(0, x, y, s, m_dragRefTime, m_dragRefPrice); 
          }
      }
      else if(m_isPreDragging && b == 1) {
          if(MathSqrt(MathPow(x-m_dragRefX,2)+MathPow(y-m_dragRefY,2)) > 10) { 
             m_isPreDragging = false; m_isDragging = true; 
             if(m_dragMode == MODE_DRAG_TOOL_AREA || m_dragMode == MODE_MOVE_ALL) {
                if(m_isTrackingPrice) { m_isTrackingPrice = false; }
             }
          }
      }
      
      if(m_isDragging) {
          if(b==1) {
             double cP; datetime cT; int s; ChartXYToTimePrice(0, x, y, s, cT, cP);
             if(m_dragMode != MODE_RESIZE_TIME && m_dragMode != MODE_DRAG_TOOL_AREA) ApplyMagnet(cP, x, y);
             double dP = cP - m_dragRefPrice; long dT = cT - m_dragRefTime;
             switch(m_dragMode) {
                case MODE_DRAG_TOOL_AREA:
                case MODE_MOVE_ALL:
                   m_entryPrice+=dP; m_slPrice+=dP; m_tpPrice+=dP; if(IsTP2)m_tpPrice2+=dP; if(IsTP3)m_tpPrice3+=dP; if(IsTP4)m_tpPrice4+=dP;
                   m_startTime+=(datetime)dT; m_endTime+=(datetime)dT; break;
                case MODE_MODIFY_ENTRY: m_entryPrice+=dP; m_startTime+=(datetime)dT; break;
                case MODE_MODIFY_SL: {
                   double n = m_slPrice + dP;
                   if(!IsModificationMode) { 
                      bool isBuy = (ActiveOrderType == 1 || ActiveOrderType == 3 || ActiveOrderType == 5);
                      if(isBuy) { if(n >= m_entryPrice) n = m_entryPrice - _Point; }
                      else { if(n <= m_entryPrice) n = m_entryPrice + _Point; }
                   }
                   m_slPrice = n;
                } break;
                case MODE_MODIFY_TP: m_tpPrice+=dP; break;
                case MODE_MODIFY_TP2: m_tpPrice2+=dP; break;
                case MODE_MODIFY_TP3: m_tpPrice3+=dP; break;
                case MODE_MODIFY_TP4: m_tpPrice4+=dP; break;
                case MODE_RESIZE_TIME: m_endTime+=(datetime)dT; break;
             }
             m_dragRefPrice = cP; m_dragRefTime = cT; DrawGhostLine(); UpdateCalculations(risk, mode, defPct2, defPct3, defPct4); ChartRedraw();
          } else { 
             m_isDragging = false; m_dragMode = MODE_NONE; m_isPreDragging = false; 
             // Sürükleme bitti: SYNC OFF modda yeni pozisyona göre sabit mesafeleri güncelle
             if(!m_isSyncMode) {
                m_fixedSlDist = MathAbs(m_entryPrice - m_slPrice);
                m_fixedTpDist = MathAbs(m_entryPrice - m_tpPrice);
                m_fixedSlAbove = (m_slPrice > m_entryPrice);
                m_fixedTpAbove = (m_tpPrice > m_entryPrice);
             }
             DrawAll(); ChartRedraw(); 
          }
      }
   }
};
//+------------------------------------------------------------------+
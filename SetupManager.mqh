diff --git a/SetupManager.mqh b/SetupManager.mqh
index 88913690e0f95b877fc5feccf37df6a68d4be3b5..13468021de43604857b508199d57c1d0702c8057 100644
--- a/SetupManager.mqh
+++ b/SetupManager.mqh
@@ -541,56 +541,56 @@ public:
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
 
-   void UpdateCalculations(CRiskManager &riskManager, ENUM_RISK_MODE riskMode, double defPct2, double defPct3, double defPct4) {
+   void UpdateCalculations(CRiskManager &riskManager, ENUM_RISK_MODE riskMode, double defPct2, double defPct3, double defPct4, double maxLeverage) {
       if(!IsLinesActive) return;
       m_entryPrice = NormalizeDouble(m_entryPrice, _Digits); m_slPrice = NormalizeDouble(m_slPrice, _Digits); m_tpPrice = NormalizeDouble(m_tpPrice, _Digits);
       double userRiskValue = StringToDouble(ObjectGetString(0, NAME_EditRiskVal, OBJPROP_TEXT));
       double riskMoneyReal = 0;
-      double totalLot = 0; if(IsModificationMode && m_recalledVolume > 0) totalLot = m_recalledVolume; else { totalLot = riskManager.CalculateLot(_Symbol, m_entryPrice, m_slPrice, riskMode, userRiskValue, riskMoneyReal); totalLot = riskManager.NormalizeLot(_Symbol, totalLot); }
+      double totalLot = 0; if(IsModificationMode && m_recalledVolume > 0) totalLot = m_recalledVolume; else { totalLot = riskManager.CalculateLot(_Symbol, m_entryPrice, m_slPrice, riskMode, userRiskValue, maxLeverage, riskMoneyReal); }
       
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
@@ -705,84 +705,84 @@ public:
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
 
-   void HandleDrag(int x, int y, int b, CRiskManager &risk, ENUM_RISK_MODE mode, double defPct2, double defPct3, double defPct4) {
+   void HandleDrag(int x, int y, int b, CRiskManager &risk, ENUM_RISK_MODE mode, double defPct2, double defPct3, double defPct4, double maxLeverage) {
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
-             UpdateCalculations(risk, mode, defPct2, defPct3, defPct4); ChartRedraw(); return; 
+             UpdateCalculations(risk, mode, defPct2, defPct3, defPct4, maxLeverage); ChartRedraw(); return; 
           }
           if(h == m_btnRemTP2 || h == m_btnRemTP3 || h == m_btnRemTP4 || h == m_lblTP2 || h == m_lblTP3 || h == m_lblTP4) {
              if(h==m_btnRemTP2) IsTP2=false; else if(h==m_btnRemTP3) IsTP3=false; else if(h==m_btnRemTP4) IsTP4=false;
              else if(h==m_lblTP2) { m_isTP2Locked=!m_isTP2Locked; } else if(h==m_lblTP3) { m_isTP3Locked=!m_isTP3Locked; } else if(h==m_lblTP4) { m_isTP4Locked=!m_isTP4Locked; }
-             UpdateCalculations(risk, mode, defPct2, defPct3, defPct4); ChartRedraw(); return;
+             UpdateCalculations(risk, mode, defPct2, defPct3, defPct4, maxLeverage); ChartRedraw(); return;
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
@@ -835,41 +835,41 @@ public:
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
-             m_dragRefPrice = cP; m_dragRefTime = cT; DrawGhostLine(); UpdateCalculations(risk, mode, defPct2, defPct3, defPct4); ChartRedraw();
+             m_dragRefPrice = cP; m_dragRefTime = cT; DrawGhostLine(); UpdateCalculations(risk, mode, defPct2, defPct3, defPct4, maxLeverage); ChartRedraw();
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
-//+------------------------------------------------------------------+
\ No newline at end of file
+//+------------------------------------------------------------------+

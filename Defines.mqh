//+------------------------------------------------------------------+
//|                                                      Defines.mqh |
//|                                     Copyright 2026, AIK Project  |
//|                                      Project: AIK Trade Manager  |
//| Version: 1.1 (UX FIX: Enum Names Changed to Cons/Aggressive)     |
//+------------------------------------------------------------------+
#property copyright "Ali ihsan KARA"
#property strict

// ======================================================================================
// 1. VERİ YAPILARI VE ENUM TANIMLARI
// ======================================================================================
enum ENUM_RISK_MODE { RISK_PERCENT, RISK_MONEY, RISK_LOT };
enum ENUM_LINE_EXTENT { LINE_FULL, LINE_RIGHT, LINE_LEFT };
enum ENUM_GUI_STATE {
   GUI_FULL_MOD, GUI_SYNC_MOD, GUI_FULL_MOD_MINIMAL, GUI_SYNC_MOD_MINIMAL
};
enum ENUM_DRAW_STYLE { STYLE_LINES_ONLY, STYLE_TV_BOXES };

// --- GÜNCELLENEN: SPL ÇALIŞMA MODU ---
enum ENUM_SPL_MODE {
   SPL_CONSERVATIVE, // Conservative Mod (İndikatör Ray seviyelerini kullanır)
   SPL_AGGRESSIVE    // Aggressive Mod (IC objelerinin mum tepesi/dibini kullanır)
};

// ======================================================================================
// 2. SABİT DEĞERLER VE BOYUTLAR
// ======================================================================================
const int GUI_Z_BASE = 50000; 
const int HDR_H = 30; 
const int GAP_V = 3; 
const int GAP_H = 3; 
const int PAD_SIDE = 5;

// ======================================================================================
// 3. RENK TANIMLARI (Colors)
// ======================================================================================
const color clrPanelBG       = C'35,35,35'; 
const color clrTerminalBG    = C'28,28,28'; 
const color clrHeaderBG      = C'25,25,25';
const color clrInputBG       = C'245,245,245'; 
const color clrInputTxt      = C'0,0,0';
const color clrBtnBuyMkt     = C'34,139,34'; 
const color clrBtnBuyLmt     = C'46,139,87'; 
const color clrBtnBuyStp     = C'60,179,113';
const color clrBtnSellMkt    = C'220,20,60'; 
const color clrBtnSellLmt    = C'205,92,92'; 
const color clrBtnSellStp    = C'178,34,34';
const color clrBtnExec       = C'65,105,225'; 
const color clrBtnClose      = C'178,34,34';
const color clrBtnSyncOn     = C'34,139,34'; 
const color clrBtnSyncOff    = C'105,105,105';
const color clrBtnRisk       = C'255,140,0'; 
const color clrBtnGray       = C'80,80,80';
const color clrBtnPinActive  = C'220,20,60'; 
const color clrBtnActive     = C'50,205,50';
const color clrBtnCancelActive = C'255,190,0'; 
const color clrBtnGreen      = C'34,139,34';
const color clrTrmHdrBG      = C'55,55,55'; 
const color clrTrmRow1       = C'28,28,28'; 
const color clrTrmRow2       = C'38,38,38';

// ======================================================================================
// 4. OBJE İSİMLERİ (Object Names)
// ======================================================================================
const string NAME_ObjPanel          = "AIK_TM_Panel"; 
const string NAME_ObjTitleBar       = "AIK_TM_TitleBar";
const string NAME_BtnMinMax         = "AIK_TM_Btn_MinMax"; 
const string NAME_BtnDrag           = "AIK_TM_Btn_Drag"; 
const string NAME_BtnPin            = "AIK_TM_Btn_Pin";
const string NAME_BtnRiskMode       = "AIK_TM_Btn_RiskMode"; 
const string NAME_EditRiskVal       = "AIK_TM_Edit_RiskVal";
const string NAME_BtnRiskPlus       = "AIK_TM_Btn_RiskPlus"; 
const string NAME_BtnRiskMinus      = "AIK_TM_Btn_RiskMinus";
const string NAME_BtnSync           = "AIK_TM_Btn_Sync_EA"; 
const string NAME_BtnBE             = "AIK_TM_Btn_BE"; 
const string NAME_BtnTrendMkt       = "AIK_TM_Btn_TrendMkt";
const string NAME_BtnMiniBuy        = "AIK_TM_Btn_MiniBuy"; 
const string NAME_BtnMiniSell       = "AIK_TM_Btn_MiniSell";
const string NAME_BtnMiniExec       = "AIK_TM_Btn_MiniExec"; 
const string NAME_BtnMiniClose      = "AIK_TM_Btn_MiniClose";
const string NAME_BtnBuyM           = "AIK_TM_Btn_BuyM"; 
const string NAME_BtnSellM          = "AIK_TM_Btn_SellM";
const string NAME_BtnBuyL           = "AIK_TM_Btn_BuyL"; 
const string NAME_BtnSellL          = "AIK_TM_Btn_SellL";
const string NAME_BtnBuyS           = "AIK_TM_Btn_BuyS"; 
const string NAME_BtnSellS          = "AIK_TM_Btn_SellS";
const string NAME_BtnTP1            = "AIK_TM_Btn_TP1"; 
const string NAME_EditTP1           = "AIK_TM_Edit_TP1";
const string NAME_BtnTP2            = "AIK_TM_Btn_TP2"; 
const string NAME_EditTP2           = "AIK_TM_Edit_TP2";
const string NAME_BtnTP3            = "AIK_TM_Btn_TP3"; 
const string NAME_EditTP3           = "AIK_TM_Edit_TP3";
const string NAME_BtnTP4            = "AIK_TM_Btn_TP4"; 
const string NAME_EditTP4           = "AIK_TM_Edit_TP4";
const string NAME_BtnExecute        = "AIK_TM_Btn_Execute"; 
const string NAME_BtnCancel         = "AIK_TM_Btn_Cancel"; 
const string NAME_BtnClose          = "AIK_TM_Btn_Close";
const string NAME_LineEntry         = "AIK_TM_Line_Entry"; 
const string NAME_LineSL            = "AIK_TM_Line_SL";
const string NAME_LineBE            = "AIK_TM_Line_BE"; 
const string NAME_LineTP1           = "AIK_TM_Line_TP1";
const string NAME_LineTP2           = "AIK_TM_Line_TP2"; 
const string NAME_LineTP3           = "AIK_TM_Line_TP3"; 
const string NAME_LineTP4           = "AIK_TM_Line_TP4";
const string NAME_LblEntry          = "AIK_TM_Lbl_Entry"; 
const string NAME_LblSL             = "AIK_TM_Lbl_SL";
const string NAME_LblTP1            = "AIK_TM_Lbl_TP1"; 
const string NAME_LblTP2            = "AIK_TM_Lbl_TP2"; 
const string NAME_LblTP3            = "AIK_TM_Lbl_TP3"; 
const string NAME_LblTP4            = "AIK_TM_Lbl_TP4";
const string NAME_RectZoneLoss      = "AIK_TM_Rect_Loss"; 
const string NAME_RectZoneWin       = "AIK_TM_Rect_Win";
const string NAME_Indi_Ray_TP       = "AIK_Tool_Ray1"; // İndikatörden okunan isimler (DEĞİŞMEZ)
const string NAME_Indi_Ray_SL       = "AIK_Tool_Ray2"; // İndikatörden okunan isimler (DEĞİŞMEZ)
const string NAME_BtnTerminalToggle = "AIK_TM_Btn_Terminal_Toggle"; 
const string NAME_ObjTerminalBG     = "AIK_TM_Terminal_BG"; 
const string NAME_ObjMasterShield   = "AIK_TM_Master_Shield";
//+------------------------------------------------------------------+
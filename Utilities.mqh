//+------------------------------------------------------------------+
//|                                                Utilities.mqh     |
//|                                     Copyright 2026, AIK Project  |
//|                                      Project: AIK Trade Manager  |
//+------------------------------------------------------------------+
#property copyright "Ali ihsan KARA"
#property strict

class CUtilities
{
public:
   // --- Tuş Kodunu Karaktere Çevir ---
   static long GetKeyCode(string key) 
   { 
      string upper = key; 
      StringToUpper(upper); 
      if(StringLen(upper) > 0) return StringGetCharacter(upper, 0); 
      return 0; 
   }

   // --- Buton Metnine Tuş Bilgisi Ekle ---
   static string AddKeyText(string text, string key) 
   { 
      if(StringLen(key) > 0) return text + " [" + key + "]"; 
      return text; 
   }
   
   // --- Nesne Görünürlüğünü Ayarla (GÜNCELLENDİ: EKRAN DIŞINA FIRLATMA) ---
   static void SetVisible(string name, bool vis) 
   {
      if(ObjectFind(0, name) < 0) return;
      
      // Görünürlük Zamanlaması
      ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, vis ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
      
      // EĞER GİZLENECEKSE, EKRANIN DIŞINA ( -1000, -1000 ) KOORDİNATINA AT
      // Bu, sol üst köşedeki (0,0) karartı sorununu çözer.
      if(!vis) {
         ObjectSetInteger(0, name, OBJPROP_XDISTANCE, -1000);
         ObjectSetInteger(0, name, OBJPROP_YDISTANCE, -1000);
      }
   }
};
//+------------------------------------------------------------------+
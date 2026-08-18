//+------------------------------------------------------------------+
//| LLM_SetGate.mq5                                                  |
//| Human applies GS_LLM_PAUSE / GS_LLM_DIR for GridScalper.         |
//| Does not place or close trades. Run on the same chart as the EA. |
//+------------------------------------------------------------------+
#property copyright "Grid Scalper"
#property version   "1.01"
#property script_show_inputs
#property description "Set LLM pause/direction gate. Does not place or close trades."

#define GV_LLM_PAUSE "GS_LLM_PAUSE"
#define GV_LLM_DIR   "GS_LLM_DIR"
#define FILE_LLM_NOTE "gs_llm_note.txt"
#define FILE_LLM_GATE "gs_llm_gate.txt"

enum ENUM_LLM_PAUSE
  {
   LLM_RUN = 0,   // RUN (allow new entries/adds)
   LLM_PAUSE = 1  // PAUSE new entries/adds
  };

enum ENUM_LLM_DIR
  {
   LLM_DIR_BOTH = 0, // BOTH
   LLM_DIR_BUY  = 1, // BUY only
   LLM_DIR_SELL = 2  // SELL only
  };

input ENUM_LLM_PAUSE InpPause = LLM_RUN;
input ENUM_LLM_DIR   InpDir   = LLM_DIR_BOTH;
input string         InpNote  = ""; // Optional note for briefing (Common Files)

void OnStart()
  {
   GlobalVariableSet(GV_LLM_PAUSE, (double)InpPause);
   GlobalVariableSet(GV_LLM_DIR, (double)InpDir);

   int flags = FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON|FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_REWRITE;
   int hg = FileOpen(FILE_LLM_GATE, flags);
   if(hg != INVALID_HANDLE)
     {
      FileWriteString(hg, StringFormat("PAUSE=%d\nDIR=%d\n", (int)InpPause, (int)InpDir));
      FileClose(hg);
     }

   int h = FileOpen(FILE_LLM_NOTE, flags);
   if(h != INVALID_HANDLE)
     {
      FileWriteString(h, InpNote);
      FileClose(h);
     }

   string pause_s = (InpPause == LLM_PAUSE) ? "PAUSE" : "RUN";
   string dir_s = "BOTH";
   if(InpDir == LLM_DIR_BUY)
      dir_s = "BUY";
   if(InpDir == LLM_DIR_SELL)
      dir_s = "SELL";

   PrintFormat("LLM gate set: PAUSE=%s DIR=%s note=%s", pause_s, dir_s, InpNote);
   Comment(StringFormat("LLM gate: %s  DIR: %s", pause_s, dir_s));
  }
//+------------------------------------------------------------------+

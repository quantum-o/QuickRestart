#include <sourcemod>
#include <sdktools>
#include <nextmap>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Quick Restart",
	author = "quantum.",
	description = "Sunucuya hızlı bir restart atmayı sağlar",
	version = "1.00",
	url = "https://steamcommunity.com/id/quascave"
};

int Sure;
Handle GeriSay;
ConVar g_EklentiTagi;
ConVar g_MaxSure;

public void OnPluginStart()
{
	RegAdminCmd("sm_hizlires", QuickRes, ADMFLAG_ROOT, "Sunucuya hızlı bir restart atmayı sağlar");
	RegAdminCmd("sm_quickres", QuickRes, ADMFLAG_ROOT, "Sunucuya hızlı bir restart atmayı sağlar");
	RegAdminCmd("sm_hizlires0", QuickRes0, ADMFLAG_ROOT, "Sunucuya hızlı resi iptal eder");
	RegAdminCmd("sm_hizliresiptal", QuickRes0, ADMFLAG_ROOT, "Sunucuya hızlı resi iptal eder");
	RegAdminCmd("sm_quickresiptal", QuickRes0, ADMFLAG_ROOT, "Sunucuya hızlı resi iptal eder");
	
	g_EklentiTagi = CreateConVar("quickres_eklenti_tagi", "SM", "Bütün eklentilerin reklamlarını buradan değiştirebilirsiniz. ([ ] gibi işaretler koymayınız)");
	g_MaxSure = CreateConVar("quickres_max_sure", "30", "Max Verilebilecek HizliRes Süresi");
}

public void OnMapStart()
{
	AutoExecConfig(true, "QuickRestart", "quantum");
}

public Action QuickRes0(int client, int args)
{
	Sure = 0;
	if (GeriSay != INVALID_HANDLE)
	{
		CloseHandle(GeriSay);
		GeriSay = INVALID_HANDLE;
	}
	char EklentiTagi[64];
	GetConVarString(g_EklentiTagi, EklentiTagi, sizeof(EklentiTagi));
	PrintToChatAll(" [%s] \x10%N \x0Etarafından hızlı restart işlemi iptal edildi", EklentiTagi, client);
}

public Action QuickRes(int client, int args)
{
	char EklentiTagi[64];
	GetConVarString(g_EklentiTagi, EklentiTagi, sizeof(EklentiTagi));
	if(args)
	{
		char arg1[64];
		GetCmdArg(1, arg1, sizeof(arg1));
		if(StringToInt(arg1) <= 0)
		{
			PrintToChat(client, " [%s] \x10%N \x0Ehızlı restart süresi 0'dan büyük olmalıdır!", EklentiTagi, client);
		}
		else
		{
			if(StringToInt(arg1) < GetConVarInt(g_MaxSure))
			{
				Sure = StringToInt(arg1, 10);
				GeriSay = CreateTimer(1.0, QuickTimer, _, TIMER_REPEAT);
			}
			else
			{
				PrintToChat(client, " [%s] \x10%N \x0Esüre aşımı yaptınız maksimum süre: \x01%d", EklentiTagi, client, GetConVarInt(g_MaxSure));
			}
		}
	}
	else
	{
		Sure = 5;
		GeriSay = CreateTimer(1.0, QuickTimer, _, TIMER_REPEAT);
	}
}

public Action QuickTimer(Handle timer)
{
	if(Sure > 0)
	{
		char msg[256];
		Format(msg, sizeof(msg), "Sunucuya %d saniye sonra restart geliyor\nHey Sen hiç bir yere kımıldama çünkü otomatik yeniden bağlanıcaksın", Sure);
		SendPanelToAll(msg);
		Sure--;	
		return Plugin_Continue;
	}
	else
	{
		char buffer[PLATFORM_MAX_PATH];
		GetCurrentMap(buffer, sizeof(buffer));
		SetNextMap(buffer);
		
		PrintToServer("Hizli res atiliyor !");
		int flags = GetConVarFlags(FindConVar("mp_maxrounds"));
		flags &= ~FCVAR_NOTIFY;
		SetConVarFlags(FindConVar("mp_maxrounds"), flags);
		SetConVarInt(FindConVar("mp_maxrounds"), 0, true, false);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				ForcePlayerSuicide(i);
			}	
		}
		CreateTimer(13.0, MapDegis, _, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}
}

public Action MapDegis(Handle Timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			ClientCommand(i, "retry");
		}
	}
	/*char map[256];
	GetCurrentMap(map, sizeof(map));
	ForceChangeLevel(map, "QuickRestart");*/
	ServerCommand("_restart");
}

void SendPanelToAll(char[] message)
{
	char title[100];
	Format(title, 64, "Console:");
	
	ReplaceString(message, 192, "\\n", "\n");
	
	Panel panel = new Panel();
	SetPanelTitle(panel, title);
	DrawPanelItem(panel, "", ITEMDRAW_SPACER);
	DrawPanelText(panel, message);
	DrawPanelItem(panel, "", ITEMDRAW_SPACER);
	DrawPanelItem(panel, "Close", ITEMDRAW_CONTROL);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			SendPanelToClient(panel, i, Handler_DoNothing, 10);
		}
	}
	delete panel;
}

public int Handler_DoNothing(Menu menu, MenuAction action, int param1, int param2)
{
	/* Do nothing */
}

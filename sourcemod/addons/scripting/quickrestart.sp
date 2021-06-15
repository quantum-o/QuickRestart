#include <sourcemod>
#include <sdktools>
#include <nextmap>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Quick Restart", 
	author = "quantum.", 
	description = "Quickly restarts your server without dropping your players", 
	version = "1.00", 
	url = "https://steamcommunity.com/id/quascave"
};

int restime = 0;
Handle countdown = null;
ConVar g_Maxtime = null;

public void OnPluginStart()
{
	RegAdminCmd("sm_hizlires", QuickRes, ADMFLAG_ROOT, "QuickRes main cmd");
	RegAdminCmd("sm_quickres", QuickRes, ADMFLAG_ROOT, "QuickRes main cmd");
	RegAdminCmd("sm_quickres0", QuickRes0, ADMFLAG_ROOT, "QuickRes cancel cmd");
	RegAdminCmd("sm_hizliresiptal", QuickRes0, ADMFLAG_ROOT, "QuickRes cancel cmd");
	
	g_Maxtime = CreateConVar("quickres_max_time", "30", "Maximum quickres time");
}

public void OnMapStart()
{
	AutoExecConfig(true, "QuickRestart");
}

public Action QuickRes0(int client, int args)
{
	restime = 0;
	if (countdown != INVALID_HANDLE)
	{
		CloseHandle(countdown);
		countdown = INVALID_HANDLE;
	}
	PrintToChatAll("[SM] \x0EQuick restart cancelled by \x10%N", client);
}

public Action QuickRes(int client, int args)
{
	if (!args)
	{
		ReplyToCommand(client, "[SM] Usage: !quickres <time>");
		return;
	}
	
	char arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	if (StringToInt(arg1) <= 0) {
		ReplyToCommand(client, "[SM] \x0EQuick restart time must be bigger than zero");
		return;
	}
	if (StringToInt(arg1) > g_Maxtime.IntValue)
	{
		ReplyToCommand(client, "[SM] \x0EQuick restart maximum time is %d", g_Maxtime.IntValue);
		return;
	}
	restime = StringToInt(arg1);
	countdown = CreateTimer(1.0, QuickTimer, _, TIMER_REPEAT);
	
}

public Action QuickTimer(Handle timer)
{
	if (restime > 0)
	{
		char msg[256];
		Format(msg, sizeof(msg), "Server will restart in %d seconds\nDont disappear you will automaticly reconnect", restime);
		SendPanelToAll(msg);
		restime--;
		return Plugin_Continue;
	}
	char buffer[PLATFORM_MAX_PATH];
	GetCurrentMap(buffer, sizeof(buffer));
	SetNextMap(buffer);
	
	int flags = GetConVarFlags(FindConVar("mp_maxrounds"));
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(FindConVar("mp_maxrounds"), flags);
	SetConVarInt(FindConVar("mp_maxrounds"), 0, true);
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && !IsFakeClient(i))
	{
		ForcePlayerSuicide(i);
	}
	CreateTimer(13.0, ChangeMap, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Stop;
}

public Action ChangeMap(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && !IsFakeClient(i))
		ClientCommand(i, "retry");
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
	
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && !IsFakeClient(i))
		SendPanelToClient(panel, i, Handler_DoNothing, 10);
	delete panel;
}

public int Handler_DoNothing(Menu menu, MenuAction action, int param1, int param2) { /* Do nothing */ }

#pragma semicolon 1
#include <sourcemod>
#include <fragstocks>
#include <geometry>
#include <lastrequest>
#undef REQUIRE_PLUGIN
#include <lastrequest>
#include <myjailbreak>
#include <warden>
#define REQUIRE_PLUGIN

public Plugin myinfo = 
{
	name = "PlayerSouls", 
	author = "FrAgOrDiE", 
	description = "", 
	version = "1.0", 
	url = "galaxyjb.it"
};

int colorl[][] =
{  
	{ 255, 102, 102, 255 }, { 255, 140, 102, 255 }, 
	{ 255, 179, 102, 255 }, { 255, 217, 102, 255 }, { 255, 255, 102, 255 }, 
	{ 217, 255, 102, 255 }, { 179, 255, 102, 255 }, { 140, 255, 102, 255 }, 
	{ 102, 255, 102, 255 }, { 102, 255, 140, 255 }, { 102, 255, 179, 255 }, 
	{ 102, 255, 217, 255 }, { 102, 255, 255, 255 }, { 102, 217, 255, 255 }, 
	{ 102, 179, 255, 255 }, { 102, 140, 255, 255 }, { 102, 102, 255, 255 }, 
	{ 140, 102, 255, 255 }, { 179, 102, 255, 255 }, { 217, 102, 255, 255 }, 
	{ 255, 102, 255, 255 }, { 255, 102, 217, 255 }, { 255, 102, 179, 255 }, 
	{ 255, 102, 140, 255 }, { 255, 102, 102, 255 }
};

int g_oldButtons[MAXPLAYERS + 1];
int iRespTime[MAXPLAYERS + 1];
int g_iBeamSprite;
int g_iHaloSprite;
int iTargetOfClient[MAXPLAYERS + 1];
int iWarden = -1;

float fClientPos[MAXPLAYERS + 1][3];

bool bSoul[MAXPLAYERS + 1];
bool bPressingButtons[MAXPLAYERS + 1];
bool bFoundTarget[MAXPLAYERS + 1];
bool bTimerActive[MAXPLAYERS + 1];
bool bTimerSecActive[MAXPLAYERS + 1];
bool bLRAvailable;
bool bHosties;
bool bMyJB;
bool bWarden;

StringMap colors;
StringMap targets;

Handle hTimer[MAXPLAYERS + 1];
Handle hSecTimer[MAXPLAYERS + 1];

ConVar cv_iInteractionTime;
ConVar cv_iSoulsTeam;
ConVar cv_bSQL;
ConVar cv_sDBconf;
ConVar cv_bDisableAttack;
ConVar cv_bWardenOnly;

GlobalForward frw_OnSoulInteraction;

Database db;

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	CreateTimer(0.1, Timer_SpawnSouls, _, TIMER_REPEAT);
	CreateTimer(0.5, Timer_SpawnSoulsSounds, _, TIMER_REPEAT);
	colors = new StringMap();
	targets = new StringMap();
	LoadTranslations("souls.phrases");
	
	cv_iInteractionTime = CreateConVar("sm_souls_interact_time", "6", "Time required to steal/respawn a soul");
	cv_iSoulsTeam = CreateConVar("sm_souls_teams", "3", "For which teams should souls be spawned (1 = only Ts, 2 = only CTs, 3 = BOTH)", _, true, 1.0, true, 3.0); //I guess only works for csgo
	cv_bSQL = CreateConVar("sm_souls_enable_sql", "0", "Enable support for SQL", _, true, 0.0, true, 1.0);
	cv_sDBconf = CreateConVar("sm_souls_db_confname", "souls", "SQL database entry in configs/databases.cfg");
	cv_bDisableAttack = CreateConVar("sm_souls_disable_attack", "1", "Disallow attacking while interacting with a soul", _, true, 0.0, true, 1.0);
	cv_bWardenOnly = CreateConVar("sm_souls_warden_only", "0", "Only the warden's soul will be spawned", _, true, 0.0, true, 1.0);
	
	HookConVarChange(cv_bSQL, CvarChange);
	
	AutoExecConfig();
	
	if (cv_bSQL.BoolValue)
	{
		char sConf[64];
		cv_sDBconf.GetString(sConf, sizeof(sConf));
		Database.Connect(CB_connect, sConf);
	}
}

public void CvarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == cv_bSQL && !StringToInt(oldValue) && StringToInt(newValue) == 1 && cv_bSQL.BoolValue)
	{
		char sConf[64];
		cv_sDBconf.GetString(sConf, sizeof(sConf));
		Database.Connect(CB_connect, sConf);
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("souls");
	CreateNative("Souls_GetClientStolenSouls", Native_GetClientStolenSouls);
	CreateNative("Souls_GetClientRespawnedClients", Native_GetClientRespawnedClients);
	CreateNative("Souls_ToggleSoul", Native_ToggleSoul);
	frw_OnSoulInteraction = CreateGlobalForward("Souls_OnSoulInteraction", ET_Ignore, Param_Cell, Param_Cell);
	return APLRes_Success;
}

public int Native_GetClientStolenSouls(Handle plugin, int params)
{
	if (!cv_bSQL.BoolValue)
		return ThrowNativeError(SP_ERROR_NATIVE, "SQL support is not enabled, set \"sm_souls_enable_sql\" to 1");
	int souls;
	char error[2048], sSteam64[32];
	SQL_LockDatabase(db);
	DBStatement st = SQL_PrepareQuery(db, "SELECT `souls_stolen` FROM `users` WHERE `steam64` = ?", error, sizeof(error));
	if (st == INVALID_HANDLE)
	{
		SQL_UnlockDatabase(db);
		return ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	GetNativeString(1, sSteam64, sizeof(sSteam64));
	st.BindString(0, sSteam64, false);
	if (st == INVALID_HANDLE)
	{
		SQL_UnlockDatabase(db);
		return ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	SQL_Execute(st);
	if (SQL_FetchRow(st))
	{
		souls = SQL_FetchInt(st, 0);
		SQL_UnlockDatabase(db);
		return souls;
	}
	SQL_UnlockDatabase(db);
	return souls;
}

public int Native_GetClientRespawnedClients(Handle plugin, int params)
{
	if (!cv_bSQL.BoolValue)
		return ThrowNativeError(SP_ERROR_NATIVE, "SQL support is not enabled, set \"sm_souls_enable_sql\" to 1");
	int respawns;
	char error[2048], sSteam64[32];
	SQL_LockDatabase(db);
	DBStatement st = SQL_PrepareQuery(db, "SELECT `respawned_clients` FROM `users` WHERE `steam64` = ?", error, sizeof(error));
	if (st == INVALID_HANDLE)
	{
		SQL_UnlockDatabase(db);
		return ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	GetNativeString(1, sSteam64, sizeof(sSteam64));
	st.BindString(0, sSteam64, false);
	if (st == INVALID_HANDLE)
	{
		SQL_UnlockDatabase(db);
		return ThrowNativeError(SP_ERROR_NATIVE, error);
	}
	SQL_Execute(st);
	if (SQL_FetchRow(st))
	{
		respawns = SQL_FetchInt(st, 0);
		SQL_UnlockDatabase(db);
		return respawns;
	}
	SQL_UnlockDatabase(db);
	return respawns;
}

public int Native_ToggleSoul(Handle plugin, int params)
{
	bSoul[GetNativeCell(1)] = GetNativeCell(2);
	return 0;
}

public void CB_connect(Database database, const char[] error, any data)
{
	if (database == null)
		SetFailState(error);
	LogMessage("Database connection established");
	db = database;
	db.Query(CB_Simple, "CREATE TABLE IF NOT EXISTS `users` ( `id` INT NOT NULL AUTO_INCREMENT , `steam64` VARCHAR(32) NOT NULL , `nick` VARCHAR(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL , `souls_stolen` INT NOT NULL DEFAULT '0' , `respawned_clients` INT NOT NULL DEFAULT '0' , PRIMARY KEY (`steam64`), INDEX (`id`))");
}

public void CB_Simple(Database database, DBResultSet results, const char[] error, any data)
{
	if (database == null)
		SetFailState(error);
}

public void OnAllPluginsLoaded()
{
	bHosties = LibraryExists("lastrequest");
	bMyJB = LibraryExists("myjailbreak");
	bWarden = LibraryExists("warden");
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "lastrequest"))
		bHosties = false;
	else if (StrEqual(name, "myjailbreak"))
		bMyJB = false;
	else if (StrEqual(name, "warden"))
		bWarden = false;
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "lastrequest"))
		bHosties = true;
	else if (StrEqual(name, "myjailbreak"))
		bMyJB = true;
	else if (StrEqual(name, "warden"))
		bWarden = true;
}

public void OnMapStart()
{
	g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
	PrecacheSound("galaxy/orb/CT_revive/revive_1.wav");
	PrecacheSound("galaxy/orb/CT_revive/revive_2.wav");
	PrecacheSound("galaxy/orb/orb/energy_bg4.wav");
	PrecacheSound("galaxy/orb/orb/orb_spawn.wav");
	PrecacheSound("galaxy/orb/T_steal/steal_1.wav");
	PrecacheSound("galaxy/orb/T_steal/steal_2.wav");
	PrecacheSound("galaxy/orb/T_steal/steal_3.wav");
	PrecacheSound("galaxy/orb/start.wav");
	PrecacheSound("galaxy/orb/end.wav");
	PrecacheSound("galaxy/orb/lr_despawn/desp_1.wav");
	PrecacheSound("galaxy/orb/lr_despawn/desp_2.wav");
	PrecacheSound("galaxy/orb/lr_despawn/desp_3.wav");
	PrecacheSound("galaxy/orb/lr_despawn/desp_4.wav");
}

public void Event_RoundStart(Event event, char[] name, bool dontBroadcast)
{
	if (getPlayerCount(2) != 1)
		bLRAvailable = false;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (bHosties && bLRAvailable || bMyJB && MyJailbreak_IsEventDayRunning())return;
	int userid = event.GetInt("userid");
	if (bWarden && cv_bWardenOnly.BoolValue && iWarden == GetClientOfUserId(userid))return;
	if (GetClientTeam(GetClientOfUserId(userid)) == 3 || GetClientTeam(GetClientOfUserId(userid)) == 2)
	{
		GetEntPropVector(GetEntPropEnt(GetClientOfUserId(userid), Prop_Send, "m_hRagdoll"), Prop_Send, "m_vecOrigin", fClientPos[GetClientOfUserId(userid)]);
		fClientPos[GetClientOfUserId(userid)][2] += 30;
		CreateTimer(1.5, Timer_Ragdoll, userid, TIMER_FLAG_NO_MAPCHANGE);
	}	
}

public Action Timer_SpawnSouls(Handle timer)
{
	if (bHosties && bLRAvailable || bMyJB && MyJailbreak_IsEventDayRunning())return Plugin_Continue;
	int color[4];
	float fTempPos[3];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidEntity(i))continue;
		if (IsValidClient(i) && !IsPlayerAlive(i) && (GetClientTeam(i) == 3 && (cv_iSoulsTeam.IntValue == 2 || cv_iSoulsTeam.IntValue == 3) || GetClientTeam(i) == 2 && (cv_iSoulsTeam.IntValue == 1 || cv_iSoulsTeam.IntValue == 3)) && bSoul[i])
		{
			if (bWarden && cv_bWardenOnly.BoolValue && iWarden == i)continue;
			float buffer[12][3];
			Geo_NewIcosahedron(fClientPos[i], 25.0, buffer);
			char sClient[6];
			IntToString(i, sClient, sizeof(sClient));
			colors.GetArray(sClient, color, sizeof(color));
			Link(buffer, 0.2, 0.7, color, true);
			Geo_NewIcosahedron(fClientPos[i], 10.0, buffer);
			color =  { 255, 0, 0, 255 };
			Link(buffer, 0.1, 0.5, color);
			fTempPos[0] = fClientPos[i][0];
			fTempPos[1] = fClientPos[i][1];
			fTempPos[2] = fClientPos[i][2] + 16.0;
		}
		else bSoul[i] = false;
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i, false))continue;
		int target;
		char sClient[6];
		IntToString(i, sClient, sizeof(sClient));
		if (targets.GetValue(sClient, target) && bPressingButtons[i])
		{
			TE_SetupBeamRingPoint(fClientPos[i], float(iRespTime[i] + 1) * 10.0, float(iRespTime[i] + 1) * 10.0 + 0.1, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.1, 0.6, 0.6, color, 0, 0);
			TE_SendToAll();
		}
	}
	return Plugin_Continue;
}

public Action Timer_SpawnSoulsSounds(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsPlayerAlive(i) && (GetClientTeam(i) == 3 || GetClientTeam(i) == 2) && bSoul[i])
		{
			if (!IsValidEntity(i))continue;
			EmitAmbientSound("galaxy/orb/orb/energy_bg4.wav", fClientPos[i]);
		}
	}
}

public Action Timer_Ragdoll(Handle timer, any userid)
{
	if (bHosties && bLRAvailable)return Plugin_Stop;
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client) && !IsPlayerAlive(client) && client)
	{
		char sClient[6];
		IntToString(client, sClient, sizeof(sClient));
		colors.SetArray(sClient, colorl[GetRandomInt(0, sizeof(colorl) - 1)], sizeof(colorl[]));
		bSoul[client] = true;
		EmitAmbientSound("galaxy/orb/orb/orb_spawn.wav", fClientPos[client]);
	}
	return Plugin_Stop;
}

public Action OnPlayerRunCmd(int client, int & buttons, int & impulse, float vel[3], float angles[3], int & weapon, int & subtype, int & cmdnum, int & tickcount, int & seed, int mouse[2])
{
	float fPos[3];
	GetClientAbsOrigin(client, fPos);
	fPos[2] += 30;
	if (bPressingButtons[client] && bFoundTarget[client] && buttons & IN_ATTACK && cv_bDisableAttack.BoolValue)
		buttons &= ~IN_ATTACK;
	if (buttons & IN_USE == IN_USE && g_oldButtons[client] & IN_USE != IN_USE && buttons & IN_DUCK)
	{
		if (GetClientTeam(client) == 3 || GetClientTeam(client) == 2)
		{
			OnPressButtons(client, GetClientTeam(client), fPos);
		}
	}
	if (!(buttons & IN_DUCK && buttons & IN_USE))
	{
		if (bPressingButtons[client] && bFoundTarget[client])
		{
			if (bTimerActive[client])
			{
				KillTimer(hTimer[client]);
				bTimerActive[client] = false;
			}
			if (bTimerSecActive[client])
			{
				KillTimer(hSecTimer[client]);
				bTimerSecActive[client] = false;
			}
			EmitAmbientSound("galaxy/orb/end.wav", fPos, client);
			char sClient[6];
			IntToString(client, sClient, sizeof(sClient));
			targets.SetValue(sClient, 0);
			if (GetClientTeam(client) != GetClientTeam(GetClientOfUserId(iTargetOfClient[client])))
			{
				PrintHintText(client, "<font color='#fa6e37'>%t", "no longer stealing", GetClientOfUserId(iTargetOfClient[client]));
			}
			else if (GetClientTeam(client) == GetClientTeam(GetClientOfUserId(iTargetOfClient[client])))
			{
				PrintHintText(client, "<font color='#fa6e37'>%t", "no longer respawning", GetClientOfUserId(iTargetOfClient[client]));
			}
		}
		bPressingButtons[client] = false;
		bFoundTarget[client] = false;
	}
	g_oldButtons[client] = buttons;
	return Plugin_Continue;
}

public Action Timer_Hint(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	int target = GetClientOfUserId(pack.ReadCell());
	int team = pack.ReadCell();
	float fPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
	
	if (!iRespTime[client])
	{
		if (team == GetClientTeam(target))
		{
			PrintHintText(client, "<font color='#fa6e37'>%t", "you respawned", target);
			PrintHintText(target, "<font color='#fa6e37'>%t", "you have been respawned", client);
			if (cv_bSQL)
			{
				char sQuery[4028], sSteam64[32];
				GetClientAuthId(client, AuthId_SteamID64, sSteam64, sizeof(sSteam64));
				db.Format(sQuery, sizeof(sQuery), "INSERT INTO `users` (`steam64`, `nick`, `respawned_clients`) VALUES ('%s', '%N', '1') ON DUPLICATE KEY UPDATE `respawned_clients` = `respawned_clients` + '1'", sSteam64, client);
				db.Query(CB_Simple, sQuery);
			}
		}
		else if (team != GetClientTeam(target))
		{
			PrintHintText(client, "<font color='#fa6e37'>%t", "soul stolen", target);
			PrintHintText(target, "<font color='#fa6e37'>%t", "soul has been stolen", client);
			if (cv_bSQL)
			{
				char sQuery[4028], sSteam64[32];
				GetClientAuthId(client, AuthId_SteamID64, sSteam64, sizeof(sSteam64));
				db.Format(sQuery, sizeof(sQuery), "INSERT INTO `users` (`steam64`, `nick`, `souls_stolen`) VALUES ('%s', '%N', '1') ON DUPLICATE KEY UPDATE `souls_stolen` = `souls_stolen` + '1'", sSteam64, client);
				db.Query(CB_Simple, sQuery);
			}
		}
	}
	if (GetVectorDistance(fPos, fClientPos[target]) >= 50.0)
	{
		if (GetClientTeam(client) != GetClientTeam(target))
		{
			PrintHintText(client, "<font color='#fa6e37'>%t", "no longer stealing", GetClientOfUserId(iTargetOfClient[client]));
			PrintHintText(GetClientOfUserId(iTargetOfClient[client]), "<font color='#fa6e37'>%t", "no longer stealing passive", client);
		}
		else if (GetClientTeam(client) == GetClientTeam(target))
		{
			PrintHintText(client, "<font color='#fa6e37'>%t", "no longer respawning", GetClientOfUserId(iTargetOfClient[client]));
			PrintHintText(GetClientOfUserId(iTargetOfClient[client]), "<font color='#fa6e37'>%t", "no longer respawning passive", client);
		}
		EmitAmbientSound("galaxy/orb/end.wav", fPos, client);
		char sClient[6];
		IntToString(client, sClient, sizeof(sClient));
		targets.SetValue(sClient, 0);
		bFoundTarget[client] = false;
		pack.Close();
		KillTimerSafe(hTimer[client]);
		bTimerSecActive[client] = false;
		return Plugin_Stop;
	}
	if (!bPressingButtons[client] || !bFoundTarget[client])
	{
		pack.Close();
		bTimerSecActive[client] = false;
		return Plugin_Stop;
	}
	if (team == GetClientTeam(target))
	{
		PrintHintText(client, "<font color='#ffc39e'>%t", "respawning", target, iRespTime[client]);
		PrintHintText(target, "<font color='#ffc39e'>%t", "respawning passive", client, iRespTime[client]);
		iRespTime[client]--;
	}
	else if (team != GetClientTeam(target))
	{
		PrintHintText(client, "<font color='#ffc39e'>%t", "stealing", target, iRespTime[client]);
		PrintHintText(target, "<font color='#ffc39e'>%t", "stealing passive", client, iRespTime[client]);
		iRespTime[client]--;
	}
	return Plugin_Continue;
}

public Action Timer_Respawn(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	int target = GetClientOfUserId(pack.ReadCell());
	int team = pack.ReadCell();
	bTimerActive[client] = false;
	bFoundTarget[client] = false;
	float fPos[3];
	GetClientAbsOrigin(client, fPos);
	fPos[2] += 30;
	EmitAmbientSound("galaxy/orb/end.wav", fPos, client);
	char sClient[6];
	IntToString(client, sClient, sizeof(sClient));
	targets.SetValue(sClient, 0);
	if (IsValidClient(target) && !IsPlayerAlive(target))
	{
		if (team == GetClientTeam(target))
		{
			CS_RespawnPlayer(target);
			TeleportEntity(target, fClientPos[target]);
			if (GetPlayerWeaponSlot(target, CS_SLOT_KNIFE) == -1)
				GivePlayerItem(target, "weapon_knife");
			int r = GetRandomInt(0, 1);
			EmitAmbientSound(r ? "galaxy/orb/CT_revive/revive_1.wav" : "galaxy/orb/CT_revive/revive_2.wav", fPos, client);
		}
		else if (team != GetClientTeam(target))
		{
			bSoul[target] = false;
			int r = GetRandomInt(1, 3);
			char sSound[PLATFORM_MAX_PATH];
			Format(sSound, sizeof(sSound), "galaxy/orb/T_steal/steal_%i.wav", r);
			EmitAmbientSound(sSound, fPos, client);
		}
	}
	pack.Close();
}

void OnPressButtons(int client, int team, float fPos[3])
{
	bPressingButtons[client] = true;
	float fMinDist = 999999999.0;
	int nearest = -1;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || IsPlayerAlive(i) || GetClientTeam(i) != 3 && GetClientTeam(i) != 2 || !bSoul[i])continue;
		float distance = GetVectorDistance(fPos, fClientPos[i]);
		if (distance < fMinDist)
		{
			fMinDist = distance;
			nearest = i;
		}
	}
	if (fMinDist < 50.0)
	{
		iTargetOfClient[client] = GetClientUserId(nearest);
		EmitAmbientSound("galaxy/orb/start.wav", fPos, client);
		DataPack pack[2];
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsValidClient(i, false))continue;
			int target;
			char sClient[6];
			IntToString(i, sClient, sizeof(sClient));
			if (targets.GetValue(sClient, target) && target == nearest)
			{
				PrintHintText(client, "<font color='#ffc39e'>Qualcuno sta già interagendo con l'anima di %N (<font color='#fa6e37'>%N<font color='#ffc39e'>)", target, i);
				return;
			}
		}
		Call_StartForward(frw_OnSoulInteraction);
		Call_PushCell(client);
		Call_PushCell(nearest);
		Call_Finish();
		char sClient[6];
		IntToString(client, sClient, sizeof(sClient));
		targets.SetValue(sClient, nearest);
		pack[0] = new DataPack();
		pack[1] = new DataPack();
		pack[0].WriteCell(GetClientUserId(client));
		pack[1].WriteCell(GetClientUserId(client));
		pack[0].WriteCell(GetClientUserId(nearest));
		pack[1].WriteCell(GetClientUserId(nearest));
		pack[0].WriteCell(team);
		pack[1].WriteCell(team);
		bFoundTarget[client] = true;
		hTimer[client] = CreateTimer(float(cv_iInteractionTime.IntValue), Timer_Respawn, pack[0], TIMER_FLAG_NO_MAPCHANGE);
		bTimerActive[client] = true;
		bTimerSecActive[client] = true;
		iRespTime[client] = cv_iInteractionTime.IntValue;
		if (!cv_iInteractionTime.IntValue)
		{
			pack[1].Close();
			PrintHintText(client, "<font color='#fa6e37'>%t", "you respawned", nearest);
			PrintHintText(nearest, "<font color='#fa6e37'>%t", "you have been respawned", client);
			if (cv_bSQL)
			{
				char sQuery[4028], sSteam64[32];
				GetClientAuthId(client, AuthId_SteamID64, sSteam64, sizeof(sSteam64));
				db.Format(sQuery, sizeof(sQuery), "INSERT INTO `users` (`steam64`, `nick`, `respawned_clients`) VALUES ('%s', '%N', '1') ON DUPLICATE KEY UPDATE `respawned_clients` = `respawned_clients` + '1'", sSteam64, client);
				db.Query(CB_Simple, sQuery);
			}
			return;
		}	
		hSecTimer[client] = CreateTimer(1.0, Timer_Hint, pack[1], TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
		TriggerTimer(hSecTimer[client]);
	}
}

public void OnAvailableLR()
{
	bLRAvailable = true;
	char sSound[PLATFORM_MAX_PATH];
	Format(sSound, sizeof(sSound), "galaxy/orb/lr_despawn/desp_%i.wav", GetRandomInt(1, 4));
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsPlayerAlive(i) && (GetClientTeam(i) == 3 || GetClientTeam(i) == 2) && bSoul[i])
		{
			EmitAmbientSound(sSound, fClientPos[i]);
		}
		if (IsValidClient(i))
			bSoul[i] = false;
	}
}

public void warden_OnWardenCreated(int client)
{
	iWarden = client;
}

void Link(float buffer[12][3], float time, float width, int color[4], bool stella = false)
{
	TE_SetupBeamPoints(buffer[0], buffer[3], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[0], buffer[5], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[0], buffer[6], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[0], buffer[8], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[0], buffer[11], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[1], buffer[9], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[1], buffer[5], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[1], buffer[6], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[1], buffer[10], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[1], buffer[2], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[2], buffer[7], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[2], buffer[4], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[2], buffer[10], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[2], buffer[9], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[3], buffer[7], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[3], buffer[11], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[3], buffer[8], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[3], buffer[4], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[4], buffer[8], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[4], buffer[7], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[4], buffer[9], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[5], buffer[8], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[5], buffer[6], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[5], buffer[9], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[6], buffer[10], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[6], buffer[11], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[7], buffer[11], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[7], buffer[10], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[7], buffer[4], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[8], buffer[9], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[10], buffer[11], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	
	if (!stella)return;
	
	TE_SetupBeamPoints(buffer[0], buffer[2], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[3], buffer[1], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[4], buffer[6], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[5], buffer[7], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[8], buffer[10], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
	TE_SetupBeamPoints(buffer[9], buffer[11], g_iBeamSprite, g_iHaloSprite, 0, 10, time, width, width, 1, 0.0, color, 5);
	TE_SendToAll();
} 
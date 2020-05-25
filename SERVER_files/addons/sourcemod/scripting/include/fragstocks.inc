#include <sdktools>
#include <cstrike>

/**
* Check if for a valid client
*
*
* @param client				Client Index
* @param AllowBots				Allow Bots?
* @param AllowDead				Allow Dead players?
* @noreturn
*/
stock bool IsValidClient(int client, bool AllowDead = true, bool AllowBots = false)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !AllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!AllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}

/**
* Checks if user flags (Root is always true)
*
*
* @param client			Client Index
* @param flags				Flags to check, enter comma to separate flags.
* @return					True if client has the flags, false otherwise.
*/
stock bool CheckAdminFlag(int client, const char[] flags)
{
	int iCount = 0;
	char sflagNeed[22][8], sflagFormat[64];
	bool bEntitled = false;
	
	Format(sflagFormat, sizeof(sflagFormat), flags);
	ReplaceString(sflagFormat, sizeof(sflagFormat), " ", "");
	iCount = ExplodeString(sflagFormat, ",", sflagNeed, sizeof(sflagNeed), sizeof(sflagNeed[]));
	
	for (int i = 0; i < iCount; i++)
	{
		if ((GetUserFlagBits(client) & ReadFlagString(sflagNeed[i]) == ReadFlagString(sflagNeed[i])) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
		{
			bEntitled = true;
			break;
		}
	}
	
	return bEntitled;
}

stock int GetClientAimTargetPos(int client, float pos[3]) 
{
	if (!client) 
		return -1;
	
	float vAngles[3]; float vOrigin[3];
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilterAllEntities, client);
	
	TR_GetEndPosition(pos, trace);
	pos[2] += 5.0;
	
	int entity = TR_GetEntityIndex(trace);
	
	CloseHandle(trace);
	
	return entity;
}

stock bool TraceFilterAllEntities(int entity, int contentsMask, any client)
{
	if (entity == client)
		return false;
	if (entity > MaxClients)
		return false;
	if(!IsClientInGame(entity))
		return false;
	if(!IsPlayerAlive(entity))
		return false;
	
	return true;
}

stock int getAliveTs()
{
	int Ts = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			Ts++;
		}
	}
	return Ts;
}

stock int getAliveCTs()
{
	int CTs = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
		{
			CTs++;
		}
	}
	return CTs;
}

stock int getPlayerCount(int team = -1)
{
	int players = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (team != -1 && GetClientTeam(i) == team)
				players++;
			else if (team == -1)
				players++;
		}
	}
	return players;
}

/**
* Strip All Weapons & the knife slot twice for taser
*
*
* @param client				Client Index
* @noreturn
*/
stock void StripAllPlayerWeapons(int client)
{
	int weapon;
	int index;
	
	while((weapon = GetNextWeapon(client, index)) != -1)
	{
		CS_DropWeapon(client, weapon, false, true);
		RemoveEdict(weapon);
	}
}

//Adaption for smlib
stock int GetNextWeapon(int client, int &weaponIndex) 
{ 
    static int weaponsOffset = -1; 
    if (weaponsOffset == -1) 
        weaponsOffset = FindDataMapInfo(client, "m_hMyWeapons"); 
     
    int offset = weaponsOffset + (weaponIndex * 4); 
     
    int weapon; 
    while (weaponIndex < 48)  
    { 
        weaponIndex++; 
         
        weapon = GetEntDataEnt2(client, offset); 
         
        if (IsValidEdict(weapon))  
            return weapon; 
         
        offset += 4; 
    } 
     
    return -1; 
}

/**
* Set ammo account for a weapon
*
* @param client			Client Index
* @param weapon			Weapon Index
* @param clip				Ammo ammount in the clip
* @param ammo				Total ammo ammount
* @noreturn
*/
stock void SetPlayerAmmo(int client, int weapon, int clip = -1, int ammo = -1)
{
	if (weapon == INVALID_ENT_REFERENCE)
		return;

	if (clip != -1)
	{
		SetEntProp(weapon, Prop_Send , "m_iClip1", clip);
	}

	if (ammo != -1)
	{
		SetEntProp(weapon, Prop_Send , "m_iPrimaryReserveAmmoCount", ammo);
		SetEntProp(weapon, Prop_Send , "m_iSecondaryReserveAmmoCount", ammo);
	}
}

stock void PrintToStaff(char[] message, any ...)
{
	char sBuffer[512];
	VFormat(sBuffer, sizeof(sBuffer), message, 2);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && CheckCommandAccess(i, "sm_chat", ADMFLAG_CHAT))
		{
			PrintToChat(i, sBuffer);
		}
	}
}

stock void PrintToStaff2(int client, char[] message)
{
	char sBuffer[512];
	Format(sBuffer, sizeof(sBuffer), message);
	int target;
	char sName[MAX_NAME_LENGTH];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsValidClient(i) && CheckCommandAccess(i, "sm_chat", ADMFLAG_CHAT) && i != client)
		{
			GetClientName(i, sName, sizeof(sName));
			target = FindTarget(client, sName);
			PrintToChat(i, sBuffer);
		}
	}
}

stock void ShowOverlayToAll(const char[] overlaypath)
{
	for (int x = 1; x <= MaxClients; x++)
	{
		if (IsClientInGame(x) && !IsFakeClient(x))
		{
			ShowOverlayToClient(x, overlaypath);
		}
	}
}

stock void ShowOverlayToClient(int client, const char[] overlaypath)
{
	ClientCommand(client, "r_screenoverlay \"%s\"", overlaypath);
}

stock int getNearestClient(int client)
{
	int nearest = -1;
	float vPos[3];
	float vTempPos[3];
	float fMinDistance = 9999999.0;
	
	GetClientAbsOrigin(client, vPos);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			if (i == client)
				continue;
			GetClientAbsOrigin(i, vTempPos);
			float distance = GetVectorDistance(vPos, vTempPos);
			if (distance < fMinDistance)
			{
				nearest = i;
				fMinDistance = distance;
			}
		}
	}
	return nearest;
}

/*
 * Converts a string entirely to lowercase characters
 * @param arg		Text to convert to lowercase
 */
stock void StrToLower(char[] arg)
{
	for (int i = 0; i < strlen(arg); i++)
	{
		arg[i] = CharToLower(arg[i]);
	}
}

stock void PushMenuString(Menu hndl, const char[] id, const char[] data)
{
	AddMenuItem(hndl, id, data, ITEMDRAW_IGNORE);
}

stock bool GetMenuString(Menu hndl, const char[] id, char[] Buffer, int size)
{
	int ItemCount = GetMenuItemCount(hndl);
	char info[64]; char data[64];
	
	for (int i = 0; i < ItemCount; i++)
	{
		GetMenuItem(hndl, i, info, sizeof(info), _, data, sizeof(data));
		
		if (StrEqual(info, id))
		{
			strcopy(Buffer, size, data);
			return true;
		}
	}
	
	return false;
}

stock void KillTimerSafe(Handle& timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}
}

stock void NewSquare(float center[3], float buffer[4][3], float ampitude)
{
	buffer[0][2] = center[2];
	buffer[1][2] = center[2];
	buffer[2][2] = center[2];
	buffer[3][2] = center[2];
	
	//A
	buffer[0][0] = center[0] - ampitude;
	buffer[0][1] = center[1] + ampitude;
	
	//B
	buffer[1][0] = center[0] - ampitude;
	buffer[1][1] = center[1] - ampitude;
	
	//C
	buffer[2][0] = center[0] + ampitude;
	buffer[2][1] = center[1] - ampitude;
	
	//D
	buffer[3][0] = center[0] + ampitude;
	buffer[3][1] = center[1] + ampitude;
}

stock void Ottaedro(float center[3], float buffer[6][3], float ampitude)
{
	buffer[0][0] = center[0];
	buffer[0][1] = center[1];
	buffer[0][2] = center[2] + ampitude;
	buffer[1][0] = center[0] - ampitude / 2;
	buffer[1][1] = center[1] + ampitude / 2;
	buffer[1][2] = center[2];
	buffer[2][0] = center[0] - ampitude / 2;
	buffer[2][1] = center[1] - ampitude / 2;
	buffer[2][2] = center[2];
	buffer[3][0] = center[0] + ampitude / 2;
	buffer[3][1] = center[1] - ampitude / 2;
	buffer[3][2] = center[2];
	buffer[4][0] = center[0] + ampitude / 2;
	buffer[4][1] = center[1] + ampitude / 2;
	buffer[4][2] = center[2];
	buffer[5][0] = center[0];
	buffer[5][1] = center[1];
	buffer[5][2] = center[2] - ampitude;
}
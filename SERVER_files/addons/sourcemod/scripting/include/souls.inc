#if defined _souls_included
#endinput
#endif
#define _souls_included

public SharedPlugin __pl_souls = 
{
	name = "souls",
	file = "galaxy-souls.smx",
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_souls_SetNTVOptional()
{
	MarkNativeAsOptional("Souls_GetClientStolenSouls");
	MarkNativeAsOptional("Souls_GetClientRespawnedClients");
}
#endif

/** 
 * Returns client's stolen souls (sql).
 *
 * @param        Client Steam64ID.
 */
native int Souls_GetClientStolenSouls(char[] sSteam64);

/** 
 * Returns client's respawns (sql).
 *
 * @param        Client Steam64ID.
 */
native int Souls_GetClientRespawnedClients(char[] sSteam64);


/**
 * Called when a client interact (respawn or steal) with a soul.
 *
 * @param client		Client Index.
 *
 * @noreturn
 */
forward void Souls_OnSoulInteraction(int client)
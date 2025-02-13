#include <sourcemod>
#include <sdktools>

ConVar g_hAFKTime;				  // ConVar for AFK time
ConVar g_hDisplayAFKMessage;	  // ConVar for displaying AFK message notification
ConVar g_hDisplayTextEntities;	  // ConVar for displaying text entities

float  g_fLastAction[MAXPLAYERS + 1];
bool   g_bIsAFK[MAXPLAYERS + 1];
int	   g_iAFKTextEntity[MAXPLAYERS + 1];
int	   g_iAFKTimerEntity[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name		= "[TF2] AFK Manager",
	author		= "roxrosykid",
	description = "Notifies others if player went AFK and renders AFK message above players' head.",
	version		= "1.0.3",
	url			= "https://github.com/roxrosykid"
};

public void OnPluginStart()
{
	// Create the ConVar for AFK time
	g_hAFKTime			   = CreateConVar("sm_afk_time", "300.0", "Time in seconds before a player is considered AFK", FCVAR_NONE, true, 0.0);

	// Create the ConVar for displaying AFK message notification
	g_hDisplayAFKMessage   = CreateConVar("sm_afk_message", "1", "Display AFK message notification (1 = Yes, 0 = No)", FCVAR_NONE, true, 0.0, true, 1.0);

	// Create the ConVar for displaying text entities
	g_hDisplayTextEntities = CreateConVar("sm_afk_text", "1", "Display text entities above AFK players (1 = Yes, 0 = No)", FCVAR_NONE, true, 0.0, true, 1.0);

	// Hook the ConVar change
	g_hDisplayTextEntities.AddChangeHook(OnDisplayTextEntitiesChanged);

	CreateTimer(1.0, Timer_CheckAFK, _, TIMER_REPEAT);

	float fTime = GetEngineTime();
	for (int i = 0; i <= MaxClients; i++)
	{
		g_fLastAction[i] = fTime;
	}

	DeleteEntitiesWithTargetname("afk_entity");
}

public void OnClientPutInServer(int client)
{
	g_fLastAction[client]	  = GetEngineTime();
	g_bIsAFK[client]		  = false;
	g_iAFKTextEntity[client]  = -1;
	g_iAFKTimerEntity[client] = -1;
}

public Action Timer_CheckAFK(Handle timer)
{
	float currentTime = GetEngineTime();
	float afkTime	  = g_hAFKTime.FloatValue;	  // Get the AFK time from the ConVar

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			float timeSinceLastAction = currentTime - g_fLastAction[i];

			if (timeSinceLastAction >= afkTime && !g_bIsAFK[i])
			{
				g_bIsAFK[i] = true;
				if (g_hDisplayAFKMessage.BoolValue)
				{
					PrintToChatAll("%N is now AFK.", i);
				}
				if (g_hDisplayTextEntities.BoolValue && GetClientTeam(i) > 1)
				{
					CreateAFKEntity(i, timeSinceLastAction);
				}
			}
			else if (timeSinceLastAction < afkTime && g_bIsAFK[i])
			{
				g_bIsAFK[i] = false;
				if (g_hDisplayAFKMessage.BoolValue)
				{
					PrintToChatAll("%N is no longer AFK.", i);
				}
				if (g_hDisplayTextEntities.BoolValue)
				{
					RemoveAFKEntity(i);
				}
			}
			else if (g_bIsAFK[i] && g_hDisplayTextEntities.BoolValue)
			{
				UpdateAFKEntity(i, timeSinceLastAction);
			}

			// Check if player is in spectator team and remove AFK entities if so
			if (GetClientTeam(i) == 1 && g_bIsAFK[i] && g_hDisplayTextEntities.BoolValue)
			{
				RemoveAFKEntity(i);
			}
		}
	}

	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		if (buttons != 0 || vel[0] != 0.0 || vel[1] != 0.0 || vel[2] != 0.0 || mouse[0] != 0 || mouse[1] != 0)
		{
			g_fLastAction[client] = GetEngineTime();
		}
	}

	return Plugin_Continue;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (client && IsClientInGame(client) && !IsFakeClient(client))
	{
		g_fLastAction[client] = GetEngineTime();
		if (g_bIsAFK[client])
		{
			g_bIsAFK[client] = false;
			if (g_hDisplayAFKMessage.BoolValue)
			{
				PrintToChatAll("%N is no longer AFK.", client);
			}
			if (g_hDisplayTextEntities.BoolValue)
			{
				RemoveAFKEntity(client);
			}
		}
	}

	return Plugin_Continue;
}

void CreateAFKEntity(int client, float timeSinceLastAction)
{
	float origin[3];
	GetClientAbsOrigin(client, origin);
	origin[2] += 6.0;	 // Adjust height above player's head

	// Create AFK timer entity
	g_iAFKTimerEntity[client] = CreateEntityByName("point_worldtext");
	if (g_iAFKTimerEntity[client] != -1)
	{
		char buffer[64];
		FormatTimeString(timeSinceLastAction, buffer, sizeof(buffer));
		DispatchKeyValue(g_iAFKTimerEntity[client], "message", buffer);
		DispatchKeyValue(g_iAFKTimerEntity[client], "color", "255 255 255");
		DispatchKeyValue(g_iAFKTimerEntity[client], "font", "8");
		DispatchKeyValue(g_iAFKTimerEntity[client], "textsize", "6");
		DispatchKeyValue(g_iAFKTimerEntity[client], "orientation", "1");
		DispatchKeyValue(g_iAFKTimerEntity[client], "targetname", "afk_entity");	// Set targetname

		TeleportEntity(g_iAFKTimerEntity[client], origin, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(g_iAFKTimerEntity[client]);
		ActivateEntity(g_iAFKTimerEntity[client]);

		// Attach the entity to the player
		SetVariantString("!activator");
		AcceptEntityInput(g_iAFKTimerEntity[client], "SetParent", client);
		SetVariantString("head");
		AcceptEntityInput(g_iAFKTimerEntity[client], "SetParentAttachmentMaintainOffset");
	}

	// Create AFK text entity
	g_iAFKTextEntity[client] = CreateEntityByName("point_worldtext");
	if (g_iAFKTextEntity[client] != -1)
	{
		DispatchKeyValue(g_iAFKTextEntity[client], "message", "AFK");
		DispatchKeyValue(g_iAFKTextEntity[client], "color", "255 100 100");
		DispatchKeyValue(g_iAFKTextEntity[client], "font", "8");
		DispatchKeyValue(g_iAFKTextEntity[client], "textsize", "8");
		DispatchKeyValue(g_iAFKTextEntity[client], "orientation", "1");
		DispatchKeyValue(g_iAFKTextEntity[client], "targetname", "afk_entity");	   // Set targetname

		origin[2] += 6.0;	 // Adjust height for the timer text
		TeleportEntity(g_iAFKTextEntity[client], origin, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(g_iAFKTextEntity[client]);
		ActivateEntity(g_iAFKTextEntity[client]);

		// Attach the entity to the player
		SetVariantString("!activator");
		AcceptEntityInput(g_iAFKTextEntity[client], "SetParent", client);
		SetVariantString("head");
		AcceptEntityInput(g_iAFKTextEntity[client], "SetParentAttachmentMaintainOffset");
	}
}

void UpdateAFKEntity(int client, float timeSinceLastAction)
{
	if (g_iAFKTimerEntity[client] != -1)
	{
		char buffer[64];
		FormatTimeString(timeSinceLastAction, buffer, sizeof(buffer));
		DispatchKeyValue(g_iAFKTimerEntity[client], "message", buffer);
	}
}

void RemoveAFKEntity(int client)
{
	if (g_iAFKTextEntity[client] != -1)
	{
		RemoveEntity(g_iAFKTextEntity[client]);
		g_iAFKTextEntity[client] = -1;
	}
	if (g_iAFKTimerEntity[client] != -1)
	{
		RemoveEntity(g_iAFKTimerEntity[client]);
		g_iAFKTimerEntity[client] = -1;
	}
}

void DeleteEntitiesWithTargetname(const char[] targetname)
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "point_worldtext")) != -1)
	{
		char entTargetname[64];
		GetEntPropString(entity, Prop_Data, "m_iName", entTargetname, sizeof(entTargetname));
		if (StrEqual(entTargetname, targetname))
		{
			RemoveEntity(entity);
		}
	}
}

void FormatTimeString(float time, char[] buffer, int maxlength)
{
	int hours	= RoundToFloor(time / 3600.0);
	int minutes = RoundToFloor((time - (hours * 3600.0)) / 60.0);
	int seconds = RoundToFloor(time - (hours * 3600.0) - (minutes * 60.0));

	if (hours > 0)
	{
		Format(buffer, maxlength, "%dh %dm %ds", hours, minutes, seconds);
	}
	else if (minutes > 0)
	{
		Format(buffer, maxlength, "%dm %ds", minutes, seconds);
	}
	else
	{
		Format(buffer, maxlength, "%ds", seconds);
	}
}

public void OnDisplayTextEntitiesChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 0)
	{
		// Remove all AFK text entities
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && g_bIsAFK[i])
			{
				RemoveAFKEntity(i);
			}
		}
	}
}
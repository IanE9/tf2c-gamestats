/*
 * tf2c-gamestats
 * Copyright (C) 2021  Ian
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include <sourcemod>
#include <sdktools>
#include <tf2c-gamestats>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "TF2C GameStats",
	author = "Ian",
	description = "API for interacting with GameStats in Team Fortress 2 Classic.",
	version = "1.0.0",
	url = "https://github.com/IanE9/tf2c-gamestats"
};

int g_Offset_m_aPlayerStats;
int g_Offset_m_aPlayerStats_Stride;
int g_Offset_statsCurrentLife;
int g_Offset_statsCurrentRound;
int g_Offset_statsAccumulated;
Address g_Address_CTF_GameStats;

Address GetClientStatAddress(int client, TF2_StatScope scope, TF2_StatType stat) {
	int scopeOffset;
	switch (scope) {
		case TF2StatScope_CurrentLife:
			scopeOffset = g_Offset_statsCurrentLife;
		case TF2StatScope_CurrentRound:
			scopeOffset = g_Offset_statsCurrentRound;
		case TF2StatScope_Accumulated:
			scopeOffset = g_Offset_statsAccumulated;
	}
	return g_Address_CTF_GameStats
		 + view_as<Address>(g_Offset_m_aPlayerStats)
		 + view_as<Address>(client * g_Offset_m_aPlayerStats_Stride)
		 + view_as<Address>(scopeOffset)
		 + view_as<Address>(view_as<int>(stat) * 4);
}

any Native_GetClientGameStat(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	if (client < 0 || client > MaxClients) {
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d) specified", client);
	}

	TF2_StatScope statScope = GetNativeCell(2);
	if (statScope < TF2StatScope_CurrentLife || statScope > TF2StatScope_Accumulated) {
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid stat scope (%d) specified", statScope);
	}

	TF2_StatType statType = GetNativeCell(3);
	if (statType < TF2Stat_First || statType > TF2Stat_Last) {
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid stat type (%d) specified", statType);
	}

	Address statAddr = GetClientStatAddress(client, statScope, statType);
	return LoadFromAddress(statAddr, NumberType_Int32);
}

public void OnPluginStart() {
	GameData gameconf = LoadGameConfigFile("tf2c-gamestats");
	if (!gameconf) {
		SetFailState("GameData \"tf2c-gamestats.txt\" failed to load.");
	}

	if ((g_Offset_m_aPlayerStats = gameconf.GetOffset("m_aPlayerStats")) == -1) {
		SetFailState("Failed to get offset of \"m_aPlayerStats\".");
	} else if ((g_Offset_m_aPlayerStats_Stride = gameconf.GetOffset("m_aPlayerStats_Stride")) == -1) {
		SetFailState("Failed to get offset of \"m_aPlayerStats_Stride\".");
	} else if ((g_Offset_statsCurrentLife = gameconf.GetOffset("statsCurrentLife")) == -1) {
		SetFailState("Failed to get offset of \"statsCurrentLife\".");
	} else if ((g_Offset_statsCurrentRound = gameconf.GetOffset("statsCurrentRound")) == -1) {
		SetFailState("Failed to get offset of \"statsCurrentRound\".");
	} else if ((g_Offset_statsAccumulated = gameconf.GetOffset("statsAccumulated")) == -1) {
		SetFailState("Failed to get offset of \"statsAccumulated\".");
	} else if ((g_Address_CTF_GameStats = gameconf.GetAddress("CTF_GameStats")) == Address_Null) {
		SetFailState("Failed to get address of \"CTF_GameStats\".");
	}

	delete gameconf;
}

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int max)
{
	CreateNative("TF2_GetClientGameStat", Native_GetClientGameStat);

	RegPluginLibrary("tf2c-gamestats");
	return APLRes_Success;
}
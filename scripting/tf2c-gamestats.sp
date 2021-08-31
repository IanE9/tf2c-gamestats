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
#include <dhooks>
#include <tf2c-gamestats>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "TF2C GameStats",
	author = "Ian",
	description = "API for interacting with GameStats in Team Fortress 2 Classic.",
	version = "1.3.0",
	url = "https://github.com/IanE9/tf2c-gamestats"
};

int g_Offset_m_aPlayerStats;
int g_Offset_m_aPlayerStats_Stride;
int g_Offset_statsCurrentLife;
int g_Offset_statsCurrentRound;
int g_Offset_statsAccumulated;
int g_Offset_iStatsChangedBits;
Address g_Address_CTF_GameStats;
DynamicDetour g_Detour_CTFGameRules_CalcPlayerScore;
GlobalForward g_Forward_OnCalcClientScore;

int GetStatScopeOffset(TF2_StatScope scope) {
	switch (scope) {
		case TF2StatScope_CurrentLife:  return g_Offset_statsCurrentLife;
		case TF2StatScope_CurrentRound: return g_Offset_statsCurrentRound;
		case TF2StatScope_Accumulated:  return g_Offset_statsAccumulated;
		default:                        return 0; // Should never happen!!
	}
}

Address GetClientStatAddress(int client, TF2_StatScope scope, TF2_StatType stat) {
	int scopeOffset = GetStatScopeOffset(scope);
	return g_Address_CTF_GameStats
		 + view_as<Address>(g_Offset_m_aPlayerStats)
		 + view_as<Address>(client * g_Offset_m_aPlayerStats_Stride)
		 + view_as<Address>(scopeOffset)
		 + view_as<Address>(view_as<int>(stat) * 4);
}

Address GetClientStatsChangedBitsAddress(int client) {
	return g_Address_CTF_GameStats
		 + view_as<Address>(g_Offset_m_aPlayerStats)
		 + view_as<Address>(client * g_Offset_m_aPlayerStats_Stride)
		 + view_as<Address>(g_Offset_iStatsChangedBits);
}

bool ShouldSendStat(TF2_StatType statType) {
	switch(statType) {
		case TF2Stat_ShotsHit:   return false;
		case TF2Stat_ShotsFired: return false;
		case TF2Stat_Suicides:   return false;
		case TF2Stat_EnvDeaths:  return false;
		default:                 return true;
	}
}

void SetClientStatChangedBit(int client, TF2_StatType statType) {
	Address statsChangedBitsAddr = GetClientStatsChangedBitsAddress(client);
	int statsChangedBits = LoadFromAddress(statsChangedBitsAddr, NumberType_Int32);
	int statBit = 1 << (view_as<int>(statType) - 1);
	statsChangedBits |= statBit;
	StoreToAddress(statsChangedBitsAddr, statsChangedBits, NumberType_Int32);
}

void Native_VerifyStatClient(int client) {
	if (client < 1 || client > MaxClients) {
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d) specified", client);
	}
}

void Native_VerifyStatScope(TF2_StatScope statScope) {
	if (statScope < TF2StatScope_First || statScope > TF2StatScope_Last) {
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid stat scope (%d) specified", statScope);
	}
}

void Native_VerifyStatType(TF2_StatType statType) {
	if (statType < TF2Stat_First || statType > TF2Stat_Last) {
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid stat type (%d) specified", statType);
	}
}

any Native_GetClientGameStat(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	Native_VerifyStatClient(client);

	TF2_StatScope statScope = GetNativeCell(2);
	Native_VerifyStatScope(statScope);

	TF2_StatType statType = GetNativeCell(3);
	Native_VerifyStatType(statType);

	Address statAddr = GetClientStatAddress(client, statScope, statType);
	return LoadFromAddress(statAddr, NumberType_Int32);
}

any Native_SetClientGameStat(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	Native_VerifyStatClient(client);

	TF2_StatScope statScope = GetNativeCell(2);
	Native_VerifyStatScope(statScope);

	TF2_StatType statType = GetNativeCell(3);
	Native_VerifyStatType(statType);

	int value = GetNativeCell(4);

	Address statAddr = GetClientStatAddress(client, statScope, statType);
	StoreToAddress(statAddr, value, NumberType_Int32);

	if (ShouldSendStat(statType)) {
		SetClientStatChangedBit(client, statType);
	}
}

any Native_AdjustClientGameStat(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	Native_VerifyStatClient(client);

	TF2_StatScope statScope = GetNativeCell(2);
	Native_VerifyStatScope(statScope);

	TF2_StatType statType = GetNativeCell(3);
	Native_VerifyStatType(statType);

	int delta = GetNativeCell(4);
	if (delta != 0) {
		Address statAddr = GetClientStatAddress(client, statScope, statType);
		int statValue = LoadFromAddress(statAddr, NumberType_Int32);
		statValue += delta;
		StoreToAddress(statAddr, statValue, NumberType_Int32);

		if (ShouldSendStat(statType)) {
			SetClientStatChangedBit(client, statType);
		}
	}
}

any Native_AdjustClientGameStatAll(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	Native_VerifyStatClient(client);

	TF2_StatType statType = GetNativeCell(2);
	Native_VerifyStatType(statType);

	int delta = GetNativeCell(3);
	if (delta != 0) {
		for (TF2_StatScope statScope = TF2StatScope_First; statScope <= TF2StatScope_Last; ++statScope) {
			Address statAddr = GetClientStatAddress(client, statScope, statType);
			int statValue = LoadFromAddress(statAddr, NumberType_Int32);
			statValue += delta;
			StoreToAddress(statAddr, statValue, NumberType_Int32);
		}

		if (ShouldSendStat(statType)) {
			SetClientStatChangedBit(client, statType);
		}
	}
}

bool FindRoundStatsClientAndScope(int& client, TF2_StatScope& scope, Address roundStatsAddr) {
	// Ensure that the address is within a valid range.
	Address m_aPlayerStats_Begin = g_Address_CTF_GameStats + view_as<Address>(g_Offset_m_aPlayerStats);
	if (roundStatsAddr < m_aPlayerStats_Begin) {
		return false;
	}
	if (roundStatsAddr >= m_aPlayerStats_Begin + view_as<Address>(g_Offset_m_aPlayerStats_Stride * MaxClients)) {
		return false;
	}

	int roundStatsAbsOffset = view_as<int>(roundStatsAddr) - view_as<int>(m_aPlayerStats_Begin);
	client = roundStatsAbsOffset / g_Offset_m_aPlayerStats_Stride;

	int scopeOffset = roundStatsAbsOffset - (client * g_Offset_m_aPlayerStats_Stride);

	// TF2StatScope_Accumulated is used overwhelmingly frequently, so this loop is reversed for optimization.
	for (TF2_StatScope checkScope = TF2StatScope_Last; checkScope >= TF2StatScope_First; --checkScope) {
		if (GetStatScopeOffset(checkScope) == scopeOffset) {
			scope = checkScope;
			return true;
		}
	}

	// Unknown scope, uh oh!
	return false;
}

MRESReturn Detour_CTFGameRules_CalcPlayerScore(DHookReturn hReturn, DHookParam hParams)
{
	int client;
	TF2_StatScope scope;
	if (g_Forward_OnCalcClientScore.FunctionCount > 0 && FindRoundStatsClientAndScope(client, scope, hParams.Get(1))) {
		int score = hReturn.Value;
		Call_StartForward(g_Forward_OnCalcClientScore);
		Call_PushCell(client);
		Call_PushCell(scope);
		Call_PushCellRef(score);
		Call_Finish();
		if (score < 0) {
			// m_iTotalScore is 12 bits and unsigned, pretty dumb!
			score = 0;
		}
		hReturn.Value = score;
		return MRES_Override;
	} else {
		return MRES_Ignored;
	}
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
	} else if ((g_Offset_iStatsChangedBits = gameconf.GetOffset("iStatsChangedBits")) == -1) {
		SetFailState("Failed to get offset of \"iStatsChangedBits\".");
	} else if ((g_Address_CTF_GameStats = gameconf.GetAddress("CTF_GameStats")) == Address_Null) {
		SetFailState("Failed to get address of \"CTF_GameStats\".");
	} else if ((g_Detour_CTFGameRules_CalcPlayerScore = DynamicDetour.FromConf(gameconf, "CTFGameRules::CalcPlayerScore")) == null) {
		SetFailState("Failed to create detour for \"CTFGameRules::CalcPlayerScore\".");
	} else if (!g_Detour_CTFGameRules_CalcPlayerScore.Enable(Hook_Post, Detour_CTFGameRules_CalcPlayerScore)) {
		SetFailState("Failed to enable detour for \"CTFGameRules::CalcPlayerScore\".");
	}

	delete gameconf;
}

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int max)
{
	CreateNative("TF2_GetClientGameStat", Native_GetClientGameStat);
	CreateNative("TF2_SetClientGameStat", Native_SetClientGameStat);
	CreateNative("TF2_AdjustClientGameStat", Native_AdjustClientGameStat);
	CreateNative("TF2_AdjustClientGameStatAll", Native_AdjustClientGameStatAll);

	g_Forward_OnCalcClientScore = new GlobalForward("TF2_OnCalcClientScore", ET_Ignore, Param_Cell, Param_Cell, Param_CellByRef);

	RegPluginLibrary("tf2c-gamestats");
	return APLRes_Success;
}
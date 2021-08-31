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
#include <tf2c-gamestats>

#pragma semicolon 1
#pragma newdecls required

int g_ClientLifeTeamKills[MAXPLAYERS];
int g_ClientRoundTeamKills[MAXPLAYERS];
int g_ClientAccumulatedTeamKills[MAXPLAYERS];

public Plugin myinfo = {
	name = "TF2C GameStats Test",
	author = "Ian",
	description = "Test for TF2C-GameStats.",
	version = "1.0.0",
	url = "https://github.com/IanE9/tf2c-gamestats"
};

public void OnPluginStart() {
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("teamplay_round_start", Event_RoundStart);
}

public void OnClientPutInServer(int client) {
	g_ClientLifeTeamKills[client] = 0;
	g_ClientRoundTeamKills[client] = 0;
	g_ClientAccumulatedTeamKills[client] = 0;
}

public void TF2_OnCalcClientScore(int client, TF2_StatScope scope, int& score) {
	int tkPenalty;
	switch (scope) {
		case TF2StatScope_CurrentLife:
			tkPenalty = g_ClientLifeTeamKills[client];
		case TF2StatScope_CurrentRound:
			tkPenalty = g_ClientRoundTeamKills[client];
		case TF2StatScope_Accumulated:
			tkPenalty = g_ClientAccumulatedTeamKills[client];
	}
	score -= tkPenalty;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_ClientLifeTeamKills[client] = 0;
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int victim = GetClientOfUserId(event.GetInt("userid"));
	PrintToChat(victim, "You healed %d that life", TF2_GetClientGameStat(victim, TF2StatScope_CurrentLife, TF2Stat_Healing));
	g_ClientLifeTeamKills[victim] = 0;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (attacker >= 1 && attacker <= MaxClients) {
		if (GetClientTeam(victim) == GetClientTeam(attacker)) {
			++g_ClientLifeTeamKills[attacker];
			++g_ClientRoundTeamKills[attacker];
			++g_ClientAccumulatedTeamKills[attacker];

			// Prevent the attacker from being awarded a kill
			TF2_AdjustClientGameStatAll(attacker, TF2Stat_Kills, -1);
		}
	}
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	for (int i = 1; i <= MaxClients; ++i) {
		g_ClientRoundTeamKills[i] = 0;
	}
}
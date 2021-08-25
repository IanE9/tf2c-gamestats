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

public Plugin myinfo = {
	name = "TF2C GameStats Test",
	author = "Ian",
	description = "Test for TF2C-GameStats.",
	version = "1.0.0",
	url = "https://github.com/IanE9/tf2c-gamestats"
};

public void OnPluginStart() {
	HookEvent("player_death", Event_PlayerDeath);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int victim = GetClientOfUserId(event.GetInt("userid"));
	PrintToChat(victim, "You healed %d that life", TF2_GetClientGameStat(victim, TF2StatScope_CurrentLife, TF2Stat_Healing));
}
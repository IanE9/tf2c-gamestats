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

#if defined _tf2c_gamestats_included
	#endinput
#endif
#define _tf2c_gamestats_included

enum TF2_StatType {
	TF2Stat_ShotsHit           = 1,
	TF2Stat_ShotsFired         = 2,
	TF2Stat_Kills              = 3,
	TF2Stat_Deaths             = 4,
	TF2Stat_Damage             = 5,
	TF2Stat_Captures           = 6,
	TF2Stat_Defenses           = 7,
	TF2Stat_Dominations        = 8,
	TF2Stat_Revenges           = 9,
	TF2Stat_PointsScored       = 10,
	TF2Stat_BuildingsDestroyed = 11,
	TF2Stat_Headshots          = 12,
	TF2Stat_PlayTime           = 13,
	TF2Stat_Healing            = 14,
	TF2Stat_Invulns            = 15,
	TF2Stat_KillAssists        = 16,
	TF2Stat_Backstabs          = 17,
	TF2Stat_HealthLeached      = 18,
	TF2Stat_BuildingsBuilt     = 19,
	TF2Stat_MaxSentryKills     = 20,
	TF2Stat_Teleports          = 21,
	TF2Stat_Suicides           = 22,
	TF2Stat_EnvDeaths          = 23,
	TF2Stat_BonusPoints        = 24,

	TF2Stat_First = TF2Stat_ShotsHit,
	TF2Stat_Last = TF2Stat_BonusPoints,
};

enum TF2_StatScope {
	TF2StatScope_CurrentLife  = 0,
	TF2StatScope_CurrentRound = 1,
	TF2StatScope_Accumulated  = 2,

	TF2StatScope_First = TF2StatScope_CurrentLife,
	TF2StatScope_Last = TF2StatScope_Accumulated,
};

/**
 * Retrieves the value of a client's stat within a scope.
 *
 * @param client    Index of the client.
 * @param scope     Scope to retrieve the stat under.
 * @param stat      Stat to retrieve the value of.
 * @return          Value of the stat.
 * @error           Invalid client index, scope, or stat will result in an error.
 */
native int TF2_GetClientGameStat(int client, TF2_StatScope scope, TF2_StatType stat);

/**
 * Sets the value of a client's stat within a scope.
 *
 * @param client    Index of the client.
 * @param scope     Scope to set the stat under.
 * @param stat      Stat to set the value of.
 * @param value     Value to assign the stats.
 * @noreturn
 * @error           Invalid client index, scope, or stat will result in an error.
 */
native void TF2_SetClientGameStat(int client, TF2_StatScope scope, TF2_StatType stat, int value);

/**
 * Adjusts the value of a client's stat within a scope.
 *
 * @param client    Index of the client.
 * @param scope     Scope to adjust the stat under.
 * @param stat      Stat to adjust the value of.
 * @param delta     Adjustment to apply to the stat value.
 * @noreturn
 * @error           Invalid client index, scope, or stat will result in an error.
 */
native void TF2_AdjustClientGameStat(int client, TF2_StatScope scope, TF2_StatType stat, int delta);

/**
 * Adjusts the value of a client's stat within all scopes.
 *
 * @param client    Index of the client.
 * @param stat      Stat to adjust the value of.
 * @param delta     Adjustment to apply to the stat value.
 * @noreturn
 * @error           Invalid client index or stat will result in an error.
 */
native void TF2_AdjustClientGameStatAll(int client, TF2_StatType stat, int delta);

/**
 * Called when a client's score is being calculated.
 *
 * @param client    Index of the client.
 * @param scope     Scope for which the score is being calculated.
 * @param score     Client's calculated score.
 * @noreturn
 */
forward void TF2_OnCalcClientScore(int client, TF2_StatScope scope, int& score);

public SharedPlugin __pl_tf2c_gamestats =
{
	name = "tf2c-gamestats",
	file = "tf2c-gamestats.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_tf2c_gamestats_SetNTVOptional()
{
	MarkNativeAsOptional("TF2_GetClientGameStat");
	MarkNativeAsOptional("TF2_SetClientGameStat");
	MarkNativeAsOptional("TF2_AdjustClientGameStat");
	MarkNativeAsOptional("TF2_AdjustClientGameStatAll");
}
#endif
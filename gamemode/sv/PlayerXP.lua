/*
	Handle XP, and stuff
*/

util.AddNetworkString("rake_GiveXP")

dbInternal = dbInternal or {}

function dbInternal:Initialize()
	return self
end

function dbInternal:CheckTableAndAdd(player)
	/* add player_xp table if it doesn't exist, then add the player to the table */
	sql.Begin()
	sql.Query("CREATE TABLE IF NOT EXISTS players_xp (steamid64 VARCHAR(255), xp INTEGER, level INTEGER)")
	sql.Query("IF NOT EXISTS (SELECT steamid64 FROM players_xp WHERE steamid64 = '" .. sql.SQLStr(player:SteamID64()) .. "') INSERT INTO players_xp (steamid64, xp, level) VALUES ('" .. player:SteamID64() .. "', 0, 0)")
	sql.Commit()
end

// modify the player XP
function dbInternal:ModifyPlayerXP(player, amount)
	sql.Begin()
	sql.Query("UPDATE players_xp SET xp = xp + " .. amount .. " WHERE steamid64 = '" .. sql.SQLStr(player:SteamID64()) .. "'")
	sql.Commit()
end

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

	local p_xp = sql.QueryValue("SELECT xp FROM players_xp WHERE steamid64 = '" .. sql.SQLStr(player:SteamID64()) .. "'")
	sql.Commit()

	player:SetNWInt("XP", tonumber(p_xp))
end

// modify the player XP
function dbInternal:ModifyPlayerXP(player, amount)
	sql.Begin()
	sql.Query("UPDATE players_xp SET xp = " .. player:GetNWInt("XP") + amount .. " WHERE steamid64 = '" .. sql.SQLStr(player:SteamID64()) .. "'")
	sql.Commit()
	print("[XP] " .. player:Nick() .. " has gained " .. amount .. " XP!")
	player:SetNWInt("XP", player:GetNWInt("XP") + amount)
	print("[XP] " .. player:Nick() .. " has " .. player:GetNWInt("XP") .. " XP!")
end

// update the player XP
function dbInternal:UpdateXP(player)
	sql.Begin()
	sql.Query("UPDATE players_xp SET xp = " .. player:GetNWInt("XP") .. " WHERE steamid64 = '" .. sql.SQLStr(player:SteamID64()) .. "'")
	sql.Commit()
end

function dbInternal:QueryXP(player)
	sql.Begin()
	local result = sql.QueryValue("SELECT xp FROM players_xp WHERE steamid64 = '" .. sql.SQLStr(player:SteamID64()) .. "'")

	sql.Commit()

	return tonumber(result) or result
end

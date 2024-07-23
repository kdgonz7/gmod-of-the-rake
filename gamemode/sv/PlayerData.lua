/*
	Handle XP, and stuff
*/

-- TODO use SQL instead of files, we'll do this tomorrow
-- TODO we can use custom SQL code, i know how to use it.

util.AddNetworkString("rake_GiveXP")

dbInternal = dbInternal or {}

-- init function
function dbInternal:Initialize()
	return self
end

-- loads the player's data from their file, or creates it if it doesn't exist :)
-- this function is used in LoadFromFile
-- it also sets the player's XP, class, and inventory
function dbInternal:LoadPlayerData(ply)
	if ! ply then return end								--- we reallylyyyyy wanna make sure this is a player
	if ! ply:IsPlayer() then return end			--- again, we really wanna make sure this is a player

	sql.Begin()
	sql.Query("CREATE TABLE IF NOT EXISTS rake_players (id varchar(255), xp bigint, class varchar(255), inventory varchar(255))")

	-- load the player's data from the file
	--! NOTE: this is the old way local data = file.Read("rake/rakePlayer_" .. ply:SteamID64() .. ".txt")

	local data = sql.Query("SELECT * FROM rake_players where id = '" .. ply:SteamID64() .. "'")

	if data then
		-- if the file exists, we want to load it
		-- note that the data is encoded in JSON, 
		-- so we need to decode it
		--! OLD WAY AGAIN local p = util.JSONToTable(data)

		local p = {
			["XP"] = tonumber(data[1]["xp"]),
			["Class"] = data[1]["class"],
			["Inventory"] = data[1]["inventory"]
		}

		-- set the player's XP, class, and inventory
		-- i really want to make the entire inventory the master holder, 
		-- but life doesn't always work that way
		ply:SetNWInt("XP", p["XP"])
		ply:SetNWString("WeaponClass", p["Class"])
		ply:SetNWString("Inventory", p["Inventory"])
	else
		-- if the file doesn't exist, we want to create it
		-- we'll set the defaults, because this player is not 
		-- in the files yet
		-- TODO: use SQL instead of files
		-- TODO: also centralize the data 
		-- TODO: so we can load and change 
		-- TODO: the system easily
		local def_xp = 0
		local def_class = "assault"
		local def_inventory = util.TableToJSON({["Classes"] = {["assault"] = true}})

		-- set the player's XP, class, and inventory
		ply:SetNWInt("XP", def_xp)
		ply:SetNWString("WeaponClass", def_class)
		ply:SetNWString("Inventory", def_inventory)

		--! old way here ( file.Write("rake/rakePlayer_" .. ply:SteamID64() .. ".txt", util.TableToJSON({["XP"] = def_xp, ["Class"] = def_class, ["Inventory"] = def_inventory}))
		-- IF NOT EXISTS (SELECT * FROM rake_players WHERE id = 'id') THEN INSERT into rake_players VALUES ('id', xp, 'class', 'inventory')
		sql.Query("INSERT INTO rake_players VALUES ('" .. ply:SteamID64() .. "', " .. def_xp .. ", '" .. def_class .. "', '" .. def_inventory .. "') IF NOT EXISTS (SELECT * FROM rake_players WHERE id = '" .. ply:SteamID64() .. "')")
		sql.Commit()
	end
end


-- modify the player XP
-- this sets the networked integer XP and also the PData
function dbInternal:ModifyPlayerXP(player, amount)
	player:SetNWInt("XP", player:GetNWInt("XP") + amount)
end

-- modifies the player class (changing it to the newClass)
-- checks if it exists in the Player Inventory (see below)
function dbInternal:ModifyPlayerClass(player, newClass)
	if ! dbInternal:PlayerHasWeaponClass(player, newClass) then return end
	player:SetNWString("WeaponClass", newClass)
end

-- returns the inventory string of the player
-- and converts it to a table
function dbInternal:DecodeInventory(ply)
	return util.JSONToTable(ply:GetNWString("Inventory"))
end

-- Adds the item to the player inventory, returning if it doesn't exist.
function dbInternal:AddToPlayerInventory(ply, item)
	if ! ply or ! item then return end

	-- decode the inventory, so we can see certain objects
	local inventory = dbInternal:DecodeInventory(ply)

	if inventory["Classes"][item] then
		return
	end

	-- add to inventory
	inventory["Classes"][item] = true

	-- encode it back (TODO: find a more efficient way of doing this)
	ply:SetNWString("Inventory", util.TableToJSON(inventory))
end

-- returns true if the player has the class
function dbInternal:PlayerHasWeaponClass(pl, class)
	-- decode the inventory and see if the class exists
	local inventory = dbInternal:DecodeInventory(pl)
	return inventory["Classes"][class]
end

-- iterates through all the players
-- and saves each of their data to a file
--! this function should be used liberally, 
--! as it is very slow, but hell, that's how 
--! a saving system works
function dbInternal:SaveToFile()
	-- create the rake player data directory
	-- if it doesn't exist
	if ! file.IsDir("rake", "DATA") then
		file.CreateDir("rake")
	end

	-- iterate through all the players and saves their data
	-- one day i wanna make everything into the inventory table
	-- instead of seperate XP, class, and inventory variables
	-- but i don't want to do that right now
	for k, v in pairs(player.GetAll()) do
		self:SavePlayer(v)
	end
end

-- saves the player's data to a persistent file.
-- note: this is used in SaveToFile
function dbInternal:SavePlayer(ply)
	if ! ply then return end

	-- begin SQL operations
	sql.Begin()

	-- get the player's XP, class, and inventory
	local p_xp = ply:GetNWInt("XP")
	local p_class = ply:GetNWString("WeaponClass")

	-- we're setting the data
	-- developers housekeeping note: please keep
	-- the "Inventory" default with the "Assault"
	-- class intact
	local data = {
		["XP"] = p_xp,
		["Class"] = p_class,
		["Inventory"] = ply:GetNWString("Inventory", util.TableToJSON({["Classes"] = {["assault"] = true}}))
	}

	-- save it by their steam id
	--! old way here ( file.Write("rake/rakePlayer_" .. ply:SteamID64() .. ".txt", data)

	-- INSERT into rake_players VALUES ('id', xp, 'class', 'inventory') WHERE id = steam id
	-- we use the ID as an identification point
	sql.Query("UPDATE rake_players SET xp = " .. p_xp .. ", class = '" .. p_class .. "', inventory = '" .. data["Inventory"] .. "' WHERE id = '" .. ply:SteamID64() .. "'")
	sql.Commit()
end

--! this function should never be used
--! because it's very inefficient, especially
--! when called in large amounts. thanks.
function dbInternal:LoadFromFile()
	for k, v in pairs(player.GetAll()) do
		local data = file.Read("rake/rakePlayer_" .. v:SteamID64() .. ".txt")
		if data then
			local p = util.JSONToTable(data)
			v:SetNWInt("XP", p["XP"])
			v:SetNWString("WeaponClass", p["Class"])
			v:SetNWString("Inventory", p["Inventory"])
		end
	end
end

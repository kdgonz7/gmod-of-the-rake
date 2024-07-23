/*
	Handle XP, and stuff
*/

util.AddNetworkString("rake_GiveXP")

dbInternal = dbInternal or {}

function dbInternal:Initialize()
	return self
end

-- loads the player's data from their file, or creates it if it doesn't exist :)
-- this function is used in LoadFromFile
-- it also sets the player's XP, class, and inventory
function dbInternal:LoadPlayerData(ply)
	if ! ply then return end								--- we reallylyyyyy wanna make sure this is a player
	if ! ply:IsPlayer() then return end			--- again, we really wanna make sure this is a player

	-- load the player's data from the file
	local data = file.Read("rake/rakePlayer_" .. ply:SteamID64() .. ".txt")

	if data then
		-- if the file exists, we want to load it
		-- note that the data is encoded in JSON, 
		-- so we need to decode it
		local p = util.JSONToTable(data)

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

		file.Write("rake/rakePlayer_" .. ply:SteamID64() .. ".txt", util.TableToJSON({["XP"] = def_xp, ["Class"] = def_class, ["Inventory"] = def_inventory}))
	end
end


-- modify the player XP
-- this sets the networked integer XP and also the PData
function dbInternal:ModifyPlayerXP(player, amount)
	player:SetNWInt("XP", player:GetNWInt("XP") + amount)
	player:SetPData("XP", player:GetNWInt("XP"))
end

-- modifies the player class (changing it to the newClass)
-- checks if it exists in the Player Inventory (see below)
function dbInternal:ModifyPlayerClass(player, newClass)
	if ! dbInternal:PlayerHasWeaponClass(player, newClass) then return end
	player:SetNWString("WeaponClass", newClass)
	player:SetPData("Class", newClass)
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
	-- get the player's XP, class, and inventory
	local p_xp = v:GetNWInt("XP")
	local p_class = v:GetNWString("WeaponClass")

	-- we're setting the data
	-- developers housekeeping note: please keep
	-- the "Inventory" default with the "Assault"
	-- class intact
	local data = util.TableToJSON({
		["XP"] = p_xp,
		["Class"] = p_class,
		["Inventory"] = v:GetNWString("Inventory", util.TableToJSON({["Classes"] = {["assault"] = true}}))
	})

	-- save it by their steam id
	file.Write("rake/rakePlayer_" .. v:SteamID64() .. ".txt", data)
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

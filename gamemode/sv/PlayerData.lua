/*
	Handle XP, and stuff
*/

util.AddNetworkString("rake_GiveXP")

dbInternal = dbInternal or {}

function dbInternal:Initialize()
	return self
end

function dbInternal:CheckTableAndAdd(player)
	local pd = player:GetPData("XP", 0)

	local pc = player:GetPData("Class", "assault")

	local default = util.TableToJSON({
		["Classes"] = {["assault"] = true},
	})

	local inventory = player:GetPData("Inventory", default)

	player:SetNWString("WeaponClass", pc)
	player:SetNWInt("XP", pd)

	player:SetNWString("Inventory", inventory)
end

// modify the player XP
function dbInternal:ModifyPlayerXP(player, amount)
	player:SetNWInt("XP", player:GetNWInt("XP") + amount)
	player:SetPData("XP", player:GetNWInt("XP"))
end

function dbInternal:ModifyPlayerClass(player, newClass)
	if ! dbInternal:PlayerHasWeaponClass(player, newClass) then return end
	player:SetNWString("WeaponClass", newClass)
	player:SetPData("Class", newClass)
end

function dbInternal:QueryXP(player)
	return player:GetNWInt("XP")
end

function dbInternal:DecodeInventory(ply)
	return util.JSONToTable(ply:GetNWString("Inventory"))
end

function dbInternal:AddToPlayerInventory(player, item)
	local inventory = dbInternal:DecodeInventory(player)

	if inventory["Classes"][item] then
		return
	end

	inventory["Classes"][item] = true

	player:SetNWString("Inventory", util.TableToJSON(inventory))
end

function dbInternal:PlayerHasWeaponClass(pl, class)
	local inventory = dbInternal:DecodeInventory(pl)

	return inventory["Classes"][class]
end

function dbInternal:SaveToFile()
	if ! file.IsDir("rake", "DATA") then
		file.CreateDir("rake")
	end
	for k, v in pairs(player.GetAll()) do
		local p_xp = v:GetNWInt("XP")
		local p_class = v:GetNWString("WeaponClass")

		local data = util.TableToJSON({
			["XP"] = p_xp,
			["Class"] = p_class,
			["Inventory"] = v:GetNWString("Inventory", util.TableToJSON({["Classes"] = {["assault"] = true}}))
		})

		file.Write("rake/rakePlayer_" .. v:SteamID64() .. ".txt", data)
	end
end

/* note: you should probably NEVER use this */
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

function dbInternal:LoadPlayerData(ply)
	dbInternal:CheckTableAndAdd(ply)

	local data = file.Read("rake/rakePlayer_" .. ply:SteamID64() .. ".txt")

	print("Loaded Data" .. ply:SteamID64())
	if data then
		local p = util.JSONToTable(data)
		print("inventory: " .. p["Inventory"])
		ply:SetNWInt("XP", p["XP"])
		ply:SetNWString("WeaponClass", p["Class"])
		ply:SetNWString("Inventory", p["Inventory"])
	else
		ply:SetNWInt("XP", 0)
		ply:SetNWString("WeaponClass", "assault")
		ply:SetNWString("Inventory", util.TableToJSON({["Classes"] = {["assault"] = true}}))
	end
end

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
		["Classes"] = {},
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

	inventory["Classes"][#inventory["Classes"] + 1] = item

	player:SetNWString("Inventory", util.TableToJSON(inventory))
end

function dbInternal:PlayerHasWeaponClass(pl, class)
	local inventory = dbInternal:DecodeInventory(pl)

	for i = 1, #inventory["Classes"] do
		if inventory["Classes"][i] == class then
			return true
		end
	end

	return false
end

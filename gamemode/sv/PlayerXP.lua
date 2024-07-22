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

	local inventory = player:GetPData("Inventory", "")

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
	player:SetNWString("WeaponClass", newClass)
	player:SetPData("Class", newClass)
end

function dbInternal:QueryXP(player)
	return player:GetNWInt("XP")
end

function dbInternal:DecodeInventory(player)
	return util.JSONToTable(player:GetNWString("Inventory"))
end

function dbInternal:AddToPlayerInventory(player, item)

end

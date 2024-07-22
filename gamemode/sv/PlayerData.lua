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
		["Classes"] = {"assault"},
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

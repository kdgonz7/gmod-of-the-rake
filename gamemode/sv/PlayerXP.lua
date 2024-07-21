/*
	Handle XP, and stuff
*/

util.AddNetworkString("rake_GiveXP")

dbInternal = dbInternal or {}

function dbInternal:Initialize()
	return self
end

function dbInternal:CheckTableAndAdd(player)
	local pd = player:GetPData("XP", -1)

	if pd == -1 then
		player:SetPData("XP", 0)

		pd = 0
	end

	local pc = player:GetPData("Class", "assault")

	player:SetNWString("WeaponClass", pc)
	player:SetNWInt("XP", pd)
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

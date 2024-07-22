util.AddNetworkString("rake_BuyClass")

net.Receive("rake_BuyClass", function(len, ply)
	if roundManage:GetRoundStatus() != IN_LOBBY then return end
	if not ply:Alive() then return end

	local className = sql.SQLStr(net.ReadString(), true)

	local myXP = tonumber(ply:GetNWInt("XP"))

	local requested_class =	string.lower(className)

	if dataBase:PlayerHasWeaponClass(ply, requested_class) then
		dataBase:ModifyPlayerClass(ply, requested_class)
		print("[Rake] Changed Class to " .. requested_class)
		return
	end

	if requested_class == nil then
		print("[Rake] no class specified!")
		return
	end

	if (requested_class == "list") then
		print("A list of available classes to choose from: ")
		for class, req in pairs(roundManage.XPRequirements) do
			print(class .. ": " .. req .. " XP")
		end
		return
	end

	local req_class_requirement = roundManage.XPRequirements[requested_class]

	if myXP < req_class_requirement then
		print("[Rake] you don't have enough XP!")
		return
	end

	dataBase:ModifyPlayerXP(ply, -req_class_requirement)
	dataBase:ModifyPlayerClass(ply, requested_class)
	dataBase:AddToPlayerInventory(ply, requested_class)

	print("[Rake] changed class to " .. requested_class)
	print("[Rake] successfully bought")
	print("[Rake] new XP: " .. ply:GetNWInt("XP"))
end)
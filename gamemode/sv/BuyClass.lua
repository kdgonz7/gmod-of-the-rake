concommand.Add("rake_ChangeClass", function(ply, cmd, args, str)
	if roundManage:GetRoundStatus() != IN_LOBBY then return end
	if ! args[1] then return end

	local myXP = ply:GetNWInt("XP")

	local requested_class =	string.lower(args[1])
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

	ply:SetNWInt("XP", myXP - req_class_requirement)
	ply:SetNWString("WeaponClass", requested_class)

	print("[Rake] changed class to " .. requested_class)
end)

concommand.Add("rake_MyXP", function(ply, cmd, args, str)
	local myXP = ply:GetNWInt("XP")

	print("[Rake] your XP: " .. myXP)
end)

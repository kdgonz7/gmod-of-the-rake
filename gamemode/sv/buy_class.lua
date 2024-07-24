util.AddNetworkString("rake_BuyClass")

-- simple code to buy a class
net.Receive("rake_BuyClass", function(len, ply)
	if roundManage:GetRoundStatus() != IN_LOBBY then return end	-- checks
	if not ply:Alive() then return end													-- checks

	-- make sure even i didn't make a mistake
	local className = sql.SQLStr(net.ReadString(), true)	-- the classname
	local myXP = tonumber(ply:GetNWInt("XP"))							-- the player's XP
	local requested_class =	string.lower(className)				-- the class they're requesting

	if dataBase:PlayerHasWeaponClass(ply, requested_class) then	-- if they already have that class
		dataBase:ModifyPlayerClass(ply, requested_class)					-- change their class
		print("[Rake] Changed Class to " .. requested_class)			-- tell them it changed
		return																										-- return
	end

	-- idk why it'd be nil but 
	-- make sure we have a valid class
	if requested_class == nil then
		print("[Rake] no class specified!")
		return
	end

	-- list classes if it's called as rake_BuyClass list
	if (requested_class == "list") then
		print("A list of available classes to choose from: ")
		for class, req in pairs(roundManage.XPRequirements) do
			print(class .. ": " .. req .. " XP")
		end
		return
	end

	-- make sure they have enough XP
	local req_class_requirement = roundManage.XPRequirements[requested_class]

	if myXP < req_class_requirement then
		print("[Rake] you don't have enough XP!")
		return
	end

	-- buy the class
	dataBase:ModifyPlayerXP(ply, -req_class_requirement)
	dataBase:ModifyPlayerClass(ply, requested_class)
	dataBase:AddToPlayerInventory(ply, requested_class)

	print("[Rake] changed class to " .. requested_class)
	print("[Rake] successfully bought")
	print("[Rake] new XP: " .. ply:GetNWInt("XP"))
end)
-- call to StartRound()
concommand.Add("rake_StartGame", function(ply, cmd, args, str)
	if not ply:IsSuperAdmin() then return end
	if roundManage:GetRoundStatus() ~= IN_LOBBY then
		print("match is already in progress. please use rake_EndMatch to end the match")
		return
	end

	roundManage:StartRound()
end)

-- call to EndRound()
concommand.Add("rake_EndMatch", function(ply, cmd, args, str)
	if not ply:IsSuperAdmin() or not adminManager:PlayerIsAdmin(ply:SteamID64()) then return end
	roundManage:EndRound(REASON_ROUNDCOMPLETE)
end)

-- buys back a player that's dead
concommand.Add("rake_BuyBack", function(ply, cmd, args, str)
	local steamid = args[1]

	if not steamid then return end

	local gply = player.GetBySteamID64(steamid)

	local xp = tonumber(ply:GetPData("XP", 0))

	print("[Rake] XP: " .. xp)

	if xp < 100 then
		print("[Rake] you don't have enough XP!")
		return
	end

	if not ply then return end

	-- todo: make this a net reciever
	if not gply:Alive() then
		dataBase:ModifyPlayerXP(ply, -100)
		gply:Spawn()
		gply:Give("mg_m1911")
		gply:SelectWeapon("mg_m1911")
		gply:GiveAmmo(550, "Pistol", true)
	end
end)

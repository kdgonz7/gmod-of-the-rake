roundManage = roundManager:Initialize()
adminManager = adminManager:Initialize()

for i = 1, #admins do
	adminManager:AddAdmin(tostring(admins[i]))
end

hook.Add("InitPostEntity", "RakeGetnodes", function()
	if not AiNodes then
		print("prep ainodes")
		AiNodes = ainGetAllNodePositions()
	end

	if not navAreas then
		navAreas = navmesh.GetAllNavAreas()

		if not navAreas
		then
			Derma_Message("This map does NOT have a navmesh! THE RAKE will not work properly.", "[ERROR]", "OK")
		end
	end
end)

concommand.Add("rake_StartGame", function(ply, cmd, args, str)
	if not ply:IsSuperAdmin() then return end
	if roundManage:GetRoundStatus() ~= IN_LOBBY then
		print("match is already in progress. please use rake_EndMatch to end the match")
		return
	end

	roundManage:StartRound()
end)

concommand.Add("rake_EndMatch", function(ply, cmd, args, str)
	if not ply:IsSuperAdmin() or not adminManager:PlayerIsAdmin(ply:SteamID64()) then return end
	roundManage:EndRound(REASON_ROUNDCOMPLETE)
end)

hook.Add("OnNPCKilled", "RakeNPCKilled", function(npc, attacker, inflictor)
	if npc == roundManage.RakeEntity then
		npc:BecomeRagdoll()
		for _, pl in pairs(player.GetAll()) do
			pl:Lock()
		end

		roundManage.LastRakeKiller = attacker
		roundManage:EndRound(REASON_WINNER)
	end
end)

hook.Add("PlayerSetModel", "RakePlayerModel", function(ply) ply:SetModel("models/player/combine_soldier.mdl") end)

hook.Add("PlayerShouldTakeDamage", "RakePlayerShouldTakeDamage", function(ply, attacker)
	if (attacker:IsPlayer()) then
		return false
	end

	return true
end)

hook.Add("Initialize", "RakeDRGBaseSettings", function()
	RunConsoleCommand("drgbase_ai_radius", 797)
	RunConsoleCommand("drgbase_ai_patrol", 1)
	RunConsoleCommand("drgbase_ai_sight", 1)
	RunConsoleCommand("drgbase_ai_hearing", 1)
	RunConsoleCommand("mgbase_sv_customization", 1)
	RunConsoleCommand("fpsfog_active", 0)

	roundManage:ModifyStatus(IN_LOBBY)
end)

hook.Add("PlayerInitialSpawn", "AdminCheckAndEtc", function(ply)
	ply:SetNWString("WeaponClass", "assault")	// assault gives a M4A1, and a Renetti
	ply:SetNWInt("XP", 10)

	if adminManager:PlayerIsAdmin(ply:SteamID64()) then
		PrintMessage(HUD_PRINTCENTER, "Admin has joined!")
	end
end)

hook.Add("PlayerSpawn", "RakeSpawnPlayer", function(ply)
	if not IsValid(ply) then return end
	if not roundManager:FindPlayer(ply) then roundManager:AddPlayerObjectToCache(ply) end

	ply:RemoveAllAmmo()
	ply:StripWeapons()

	if roundManage:GetRoundStatus() == IN_LOBBY then
		// We'll give them a pistol to fight their friends :)
		ply:Give("mg_m1911")
		ply:GiveAmmo(550, "Pistol", true)
		ply:GodEnable()
		ply:SelectWeapon("mg_m1911")
	end
end)

hook.Add("PlayerDeathThink", "RakeNoRespawn", function(ply)
	if roundManage:GetRoundStatus() == IN_LOBBY then
		// if we're in the lobby, respawn, otherwise we'll handle that
		// separately.
		return nil
	else
		return 0
	end
end)

hook.Add("PlayerDeath", "RakeRespawn", function(ply, inflictor, attacker)
	if roundManage:GetRoundStatus() == IN_LOBBY then
		// if we're in the lobby, respawn, otherwise we'll handle that
		// separately.
		return nil
	elseif roundManage:GetRoundStatus() == IN_MATCH then
		roundManage:RegisterDead(ply)

		if roundManage:NoPlayersLeft() then roundManage:EndRound(REASON_DEATHS) end

		ply:Spectate(5)

		if not game.SinglePlayer() then
			ply:SpectateEntity(roundManage.Players[math.floor(math.random(1, #roundManage.Players))])
		else
			ply:SpectateEntity(roundManage.RakeEntity)
		end

		PrintMessage(HUD_PRINTCENTER, ply:Nick() .. " has been found! The rake awaits for its next victim")
		inflictor.WAttacking = true

		timer.Simple(10, function()
			inflictor.WAttacking = false
		end)
		return 0
	end
end)

/*
	only allow one type of each weapon to be picked up
*/
hook.Add("PlayerCanPickupWeapon", "RakeAmmoCheck", function (ply, wep)
	local plyWeapons = ply:GetWeapons()

	for _, v in ipairs(plyWeapons) do
		if (v:GetPrimaryAmmoType() == wep:GetPrimaryAmmoType()) then
			ply:DropWeapon(v, nil, Vector(0, 5, 1))
		end
	end

	return true
end)

hook.Add("PlayerSwitchWeapon", "RakeSpeedChange", function (ply, old, new)
	if not ply:Alive() then return end
	if roundManage["WalkSpeeds"][new:GetPrimaryAmmoType()] == nil then return end

	ply:SetWalkSpeed(roundManage["WalkSpeeds"][new:GetPrimaryAmmoType()][1])
	ply:SetRunSpeed (roundManage["WalkSpeeds"][new:GetPrimaryAmmoType()][2])
end)

util.AddNetworkString("startgamehud")

hook.Add("ShowSpare1", "RakeStartGameHUD", function(ply)
	if not ply:IsSuperAdmin() or not adminManager:PlayerIsAdmin(ply:SteamID64()) then return end

		net.Start("startgamehud")
		net.Send(ply)
end)

concommand.Add("drop", function(ply, cmd, args, str)
	ply:DropWeapon(ply:GetActiveWeapon(), nil, Vector(0, 5, 1))
end)

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

	if not gply:Alive() then
		dataBase:ModifyPlayerXP(ply, -100)
		gply:Spawn()
		gply:Give("mg_m1911")
		gply:SelectWeapon("mg_m1911")
		gply:GiveAmmo(550, "Pistol", true)
	end
end)

local color_red = Color( 255, 0, 0 )

hook.Add("PlayerNoClip", "NoNoClip", function(ply, des) return false end)

print("loaded player hooks")
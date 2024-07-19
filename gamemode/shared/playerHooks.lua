roundManage = roundManager:Initialize()
adminManager = adminManager:Initialize()

for i = 1, #admins do
	adminManager:AddAdmin(tostring(admins[i]))
end

concommand.Add("rake_StartGame", function(ply, cmd, args, str)
	if not ply:IsSuperAdmin() then return end
	if roundManage:GetRoundStatus() ~= IN_LOBBY then
		print("match is already in progress. please use rake_EndMatch to end the match")
		return
	end

	roundManage:StartRound()

	local weaponList = weapons.GetList()

	for i = 1, #weaponList do
		local weapon = weaponList[i]
		if string.StartsWith(weapon.ClassName, "mg_") then
			roundManage:AddWeaponToSpawnQueue(weapon.ClassName)
			print(weapon.Primary.Ammo)
			roundManage:AddAmmoToSpawnQueue(weapon.Primary.Ammo)
		end
	end

	PrintTable(game.GetAmmoTypes())
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

hook.Add("Initialize", "RakeDRGBaseSettings", function()
	RunConsoleCommand("drgbase_ai_radius", 797)
	RunConsoleCommand("drgbase_ai_patrol", 1)
	RunConsoleCommand("drgbase_ai_sight", 1)
	RunConsoleCommand("drgbase_ai_hearing", 1)
	RunConsoleCommand("mgbase_sv_customization", 0)
	RunConsoleCommand("fpsfog_active", 0)

	roundManage:ModifyStatus(IN_LOBBY)
end)

hook.Add("PlayerInitialSpawn", "AdminCheckAndEtc", function(ply)
	print("Steam id: " .. ply:SteamID64())
	if adminManager:PlayerIsAdmin(ply:SteamID64()) then
		PrintMessage(HUD_PRINTCENTER, "Admin has joined!")
	end
end)

hook.Add("PlayerSpawn", "RakeSpawnPlayer", function(ply)
	if not IsValid(ply) then return end
	if not roundManager:FindPlayer(ply) then roundManager:AddPlayerObjectToCache(ply) end

	ply.WeaponClass = "Assault"	// assault gives a M4A1, and a Renetti

	ply:RemoveAllAmmo()

	if roundManage:GetRoundStatus() == IN_LOBBY then
		// We'll give them a pistol to fight their friends :)
		ply:Give("mg_m1911")
		ply:GiveAmmo(550, "Pistol", true)
		ply:GodEnable()
	else
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
		roundManage:RemovePlayerFromCache(ply)
		if roundManage:NoPlayersLeft() then roundManage:EndRound(REASON_DEATHS) end

		ply:Spectate(5)

		if not game.SinglePlayer() then
			ply:SpectateEntity(roundManage.Players[math.floor(math.random(1, #roundManage.Players))])
		else
			ply:SpectateEntity(roundManage.RakeEntity)
		end
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

hook.Add("PlayerNoClip", "NoNoClip", function(ply, des) return false end)

print("loaded player hooks")
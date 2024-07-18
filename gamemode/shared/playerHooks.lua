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
end)

hook.Add("PlayerSetModel", "RakePlayerModel", function(ply) ply:SetModel("models/player/combine_soldier.mdl") end)
hook.Add("Initialize", "RakeDRGBaseSettings", function()
	RunConsoleCommand("drgbase_ai_radius", 797)
	RunConsoleCommand("drgbase_ai_patrol", 1)
	RunConsoleCommand("drgbase_ai_sight", 0)
	RunConsoleCommand("drgbase_ai_hearing", 1)
end)

hook.Add("PlayerInitialSpawn", "AdminCheckAndEtc", function(ply)
	print("Steam id: " .. ply:SteamID64())
	if adminManager:PlayerIsAdmin(ply:SteamID64()) then
		PrintMessage(HUD_PRINTCENTER, "Admin has joined!")
		print("admin has joined")
	end
end)

hook.Add("PlayerSpawn", "RakeSpawnPlayer", function(ply)
	if not IsValid(ply) then return end
	if not roundManager:FindPlayer(ply) then roundManager:AddPlayerObjectToCache(ply) end
	ply:RemoveAllAmmo()
	if roundManage:GetRoundStatus() == IN_LOBBY then
		// We'll give them a pistol to fight their friends :)
		ply:Give("weapon_pistol")
		ply:GiveAmmo(550, "Pistol", true)
		ply:GodEnable()
	else
		// This is most likely called when we're in the match 
		// and somebody joins, we'll handle this
	end

	if ply:IsSuperAdmin() then // connect the start game hud to player
		print("super admin")
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

hook.Add("PlayerNoClip", "NoNoClip", function(ply, des) return false end)
print("loaded player hooks")
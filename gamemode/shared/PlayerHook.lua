util.AddNetworkString("startgamehud")

-- little globals :)
roundManage = roundManager:Initialize()
adminManager = adminManager:Initialize()
dataBase = dataBase or dbInternal:Initialize()

-- TODO: this code needs to be redone soon
-- TODO: i have a placement test so i'm not 
-- TODO: going to do this right now
for i = 1, #admins do
	adminManager:AddAdmin(tostring(admins[i]))
end

-- after everything is spawned, it's time to get the
-- ainodes and navmesh
hook.Add("InitPostEntity", "RakeGetnodes", function()
	if not AiNodes then
		-- this function was designed by somebody i don't know
		-- yet i revamped it for a more readable and clean result
		AiNodes = ainGetAllNodePositions()
	end

	if not navAreas then
		-- navmesh.GetAllNavAreas() returns a table of navareas
		navAreas = navmesh.GetAllNavAreas()

		if not navAreas
		then
			Derma_Message("This map does NOT have a navmesh! THE RAKE will not work properly.", "[ERROR]", "OK")
		end
	end
end)

-- if the rake is killed then we can end the round
hook.Add("OnNPCKilled", "RakeNPCKilled", function(npc, attacker, inflictor)
	if npc == roundManage.RakeEntity then -- if we killed the rake
		for _, pl in pairs(roundManage.Players) do	-- we can lock down the alive players
			pl:Lock()
		end

		roundManage.LastRakeKiller = attacker				-- set the last killer to the player that killed it
		roundManage:EndRound(REASON_WINNER)					-- end the round
	end
end)

/* player focused hooks */

hook.Add("PlayerSetModel", "RakePlayerModel", function(ply) ply:SetModel("models/player/combine_soldier.mdl") end)
hook.Add("PlayerShouldTakeDamage", "RakePlayerShouldTakeDamage", function(ply, attacker)
	-- no team killing is allowed, also no dying to things that are player-related
	return not attacker:IsPlayer()
end)

-- base settings
-- these change the 
-- *Modern Warfare Base
-- *DRGBase
-- *and FPSFog
hook.Add("Initialize", "RakeDRGBaseSettings", function()
	RunConsoleCommand("drgbase_ai_radius", 797)
	RunConsoleCommand("drgbase_ai_patrol", 1)
	RunConsoleCommand("drgbase_ai_sight", 1)
	RunConsoleCommand("drgbase_ai_hearing", 1)
	RunConsoleCommand("mgbase_sv_customization", 1)
	RunConsoleCommand("fpsfog_active", 0)

	-- we start in the lobby
	roundManage:ModifyStatus(IN_LOBBY)

	--NOTE: remove this function if it causes problems lol
	timer.Create("Cleanup_Props", 60, 0, function()
		for _, ent in pairs(ents.FindByClass("prop_physics")) do
			if not ent:CreatedByMap() then
				ent:Remove()
			end
		end
	end)
end)

-- another initial spawn hook for admin checking
hook.Add("PlayerInitialSpawn", "AdminCheckAndEtc", function(ply)
	-- give the admins a nice welcome
	-- they deserve it for being trusted enough lol
	if adminManager:PlayerIsAdmin(ply:SteamID64()) then
		PrintMessage(HUD_PRINTCENTER, "Admin has joined!")
	end

	-- we will load the player data initially
	if dataBase then
		dataBase:LoadPlayerData(ply)
	end
end)

--! SO: this function is a exponentially wild one.
--! we need to do a lot of stuff here, one thing 
--! being ensuring players that spawn during games 
--! are added to the cache. That may need to be handled in
--! PlayerInitialSpawn instead of Spawn, so that'll be in v0.0.4 :)
hook.Add("PlayerSpawn", "RakeSpawnPlayer", function(ply)
	if not IsValid(ply) then return end
	if not roundManager:FindPlayer(ply) then roundManager:AddPlayerObjectToCache(ply) end

	-- we start the game HUD with a bunch of
	-- goodies and UI to change their weapon class
	net.Start("startgamehud")
	net.Send(ply)

	-- we strip all the player's weapons
	ply:RemoveAllAmmo()
	ply:StripWeapons()

	-- if we're in the lobby, give them a little pistol and
	-- make sure they can't get killed.
	-- that edge case is already handled though
	if roundManage:GetRoundStatus() == IN_LOBBY then
		-- We'll give them a pistol to fight their friends :) 
		-- even though they can't kill anyone.
		ply:Give("mg_m1911")
		ply:GiveAmmo(550, "Pistol", true)
		ply:GodEnable()
		ply:SelectWeapon("mg_m1911")
		ply:DrawViewModel(true)
	end

	-- spawning during a match is handled by roundManager:StartRound()
end)

-- don't respawn during matches,
-- watch the people do their job instead
hook.Add("PlayerDeathThink", "RakeNoRespawn", function(ply)
	if roundManage:GetRoundStatus() == IN_LOBBY then
		-- if we're in the lobby, respawn, otherwise we'll handle that
		-- separately.
		return nil
	else
		return 0
	end
end)

-- note: this function is unreliable, just wait until a round is done
hook.Add("ShutDown", "RakeShutDownManageData", function()
	dataBase:SaveToFile()
end)

-- on death, we can spectate certain people depending on round status
-- or we can just respawn
hook.Add("PlayerDeath", "RakeRespawn", function(ply, inflictor, attacker)
	if roundManage:GetRoundStatus() == IN_LOBBY then
		-- if we're in the lobby, respawn, otherwise we'll handle that
		-- separately.
		return nil
	elseif roundManage:GetRoundStatus() == IN_MATCH then
		PrintMessage(HUD_PRINTCENTER, ply:Nick() .. " has been found! The rake awaits for its next victim")

		-- make sure we know the player's dead by adding
		-- them to a separate array
		roundManage:RegisterDead(ply)

		-- if we have no players left, end the match
		if roundManage:NoPlayersLeft() then roundManage:EndRound(REASON_DEATHS) end

		-- set spectate mode to chase
		ply:Spectate(5)

		-- if we're in multiplayer, spectate a random player
		-- otherwise we can just spectate the rake
		if not game.SinglePlayer() then
			ply:SpectateEntity(roundManage.Players[math.floor(math.random(1, #roundManage.Players))])
		else
			ply:SpectateEntity(roundManage.RakeEntity)
		end

		--! i forgot what this does
		--! but i remembered, this just
		--! gives players a break from the rake after
		--! it kills someone
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
	-- local plyWeapons = ply:GetWeapons()

	-- for _, v in ipairs(plyWeapons) do
	-- 	if (v:GetPrimaryAmmoType() == wep:GetPrimaryAmmoType()) then
	-- 		ply:DropWeapon(v, nil, Vector(0, 5, 1))
	-- 	end
	-- end

	return true
end)

-- change the speed of the player depending on their weapon (defined in roundManager)
hook.Add("PlayerSwitchWeapon", "RakeSpeedChange", function (ply, old, new)
	if not ply:Alive() then return end
	if roundManage["WalkSpeeds"][new:GetPrimaryAmmoType()] == nil then return end

	ply:SetWalkSpeed(roundManage["WalkSpeeds"][new:GetPrimaryAmmoType()][1])
	ply:SetRunSpeed (roundManage["WalkSpeeds"][new:GetPrimaryAmmoType()][2])
end)

-- menu bind :)
hook.Add("ShowSpare1", "RakeStartGameHUD", function(ply)
	if not ply:IsSuperAdmin() or not adminManager:PlayerIsAdmin(ply:SteamID64()) then return end

		net.Start("startgamehud")
		net.Send(ply)
end)

hook.Add("PlayerNoClip", "NoNoClip", function(ply, des) return false end)

print("loaded player hooks")

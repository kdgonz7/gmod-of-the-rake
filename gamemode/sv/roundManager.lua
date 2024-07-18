/*
Handle the management of rounds
*/

/* Round statuses enum */
IN_LOBBY = 0
IN_MATCH = 1

/* reasons enum */
REASON_DEATHS = 0

roundManager = roundManager or {
	InRound = false,
	TimeLeft = 0,
	Players = {},
	RoundStartTime = 5,
	RakeEntity = nil,
	EnemyTimer = nil,

	RoundStartCallback = function() end,
	RoundEndCallback = function() end
}

function roundManager:Initialize()
	return self
end

function roundManager:FindPlayer(player)
	for k, v in pairs(roundManager.Players) do
		if v == player then
			return true
		end
	end
	return false
end

//- Add and remove players from the cache
function roundManager:AddPlayerObjectToCache(player)
	if !IsValid(player) then return end
	roundManager.Players[#roundManager.Players + 1] = player
end

function roundManager:RemovePlayerFromCache(player)
	if !IsValid(player) then return end
	for k, v in pairs(roundManager.Players) do
		if v == player then
			table.remove(roundManager.Players, k)
		end
	end
end

/* Rounds */

/* If we are in a round, return IN_MATCH else IN_LOBBY */
function roundManager:GetRoundStatus()
	if InRound then return IN_MATCH else return IN_LOBBY end
end

function roundManager:ModifyStatus(status)
	if status == IN_LOBBY then
		InRound = false
		self:RoundEndCallback()

		PrintMessage(HUD_PRINTCENTER, "Round Commensing...")
	elseif status == IN_MATCH then
		InRound = true
		self:RoundStartCallback()
		PrintMessage(HUD_PRINTCENTER, "Round Beginning...")
	end
end

function roundManager:NoPlayersLeft()
	return #self.Players == 0
end

// start the round, reset the players and get them ready with weaponry.
function roundManager:StartRound()
	if self:GetRoundStatus() == IN_MATCH then return end

	RunConsoleCommand("gmod_admin_cleanup")

	InRound = true

	self:ModifyStatus(IN_MATCH)

	PrintMessage(HUD_PRINTCENTER, "Round starting in 5 seconds...")

	for _, v in pairs(player.GetAll()) do
		v:StripWeapons()
		v:StripAmmo()

		v:Spawn()
		v:Lock()


		timer.Simple(5, function()
			v:UnLock()

			local navAreas = navmesh.GetAllNavAreas()
			local randomSpawn = math.floor(math.random(1, #navAreas + 1))

			local rake = ents.Create("drg_sf2_rake_byleenux55")

			rake:SetPos(navAreas[randomSpawn]:GetRandomPoint())
			rake:Spawn()

			self.RakeEntity = rake

			self:ModifyStatus(IN_MATCH)
		end)


			print("starting EnemyTimer")
			self.EnemyTimer = timer.Create("CreateSoldierEnemies", 10, -1, function()
				local navAreas = navmesh.GetAllNavAreas()
				local randomSpawn = math.floor(math.random(1, #navAreas + 1))

				local soldier = ents.Create("npc_combine_s")

				soldier:SetPos(navAreas[randomSpawn]:GetRandomPoint())
				soldier:Give("weapon_shotgun")
				soldier:Spawn()
			end)
	end

	self:RoundStartCallback()
end

function roundManager:EndRound(reason)
	// Cleanup the current round

	// check the reason the game ended
	if reason == REASON_DEATHS then
		PrintMessage(HUD_PRINTCENTER, "Too many players have died. Ending in 5 seconds.")
	else
		PrintMessage(HUD_PRINTCENTER, "Report in team. Round over.")
	end

	timer.Simple(5, function()
		self:ModifyStatus(IN_LOBBY)

		for _, v in pairs(player.GetAll()) do
			v:Spawn()

			if reason == REASON_DEATHS then
				v:UnSpectate()
			end
		end

		self.RakeEntity:Remove()
		self.RakeEntity = nil
		timer.Remove("CreateSoldierEnemies")

		// Run a final cleanup
		RunConsoleCommand("gmod_admin_cleanup")
	end)
end

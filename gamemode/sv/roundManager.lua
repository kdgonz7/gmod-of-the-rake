/*
Handle the management of rounds
*/

/* Round statuses enum */
IN_LOBBY = 0
IN_MATCH = 1

/* reasons enum */
REASON_DEATHS = 0


/*
	roundManager class
*/
roundManager = roundManager or {
	InRound = false,
	TimeLeft = 0,
	Players = {},
	RoundStartTime = 5,

	RakeEntity = nil,

	WeaponSpawnList = {},
	AmmoSpawnList = {},

	AmmoCache = {},

	WeaponsInMap = 0,
	WeaponSpawnRoof = 10,

	RoundStartCallback = function() end,
	RoundEndCallback = function() end
}

function roundManager:Initialize()
	return self
end

/*
	Players
*/

function roundManager:FindPlayer(player)
	for k, v in pairs(roundManager.Players) do
		if v == player then
			return true
		end
	end
	return false
end

function roundManager:NoPlayersLeft()
	return #self.Players == 0
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

/*
	Weapon Handling
*/

/* Add a weapon to the end of the spawn queue */
function roundManager:AddWeaponToSpawnQueue(weapon)
	self.WeaponSpawnList[#self.WeaponSpawnList + 1] = weapon
end

function roundManager:AddAmmoToSpawnQueue(weapon)
	self.AmmoSpawnList[#self.AmmoSpawnList + 1] = weapon
end

function roundManager:SelectRandomWeapon()

	if #self.WeaponSpawnList == 0 then
		return nil
	end

	local index = math.random(1, #self.WeaponSpawnList)
	local weapon = self.WeaponSpawnList[index]

	return weapon
end

function roundManager:SelectRandomAmmo()
	if #self.AmmoSpawnList == 0 then
		return nil
	end

	local index = math.random(1, #self.AmmoSpawnList)
	local ammo = self.AmmoSpawnList[index]

	return ammo
end

/* 
	Rounds
*/

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

// start the round, reset the players and get them ready with weaponry.
function roundManager:StartRound()
	if self:GetRoundStatus() == IN_MATCH then return end

	RunConsoleCommand("fpsfog_active", 1)
	RunConsoleCommand("fpsfog_color_r", 30)
	RunConsoleCommand("fpsfog_color_g", 30)
	RunConsoleCommand("fpsfog_color_b", 30)
	RunConsoleCommand("fpsfog_distance", 300)
	RunConsoleCommand("fpsfog_thickness", 50	)

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
			timer.Create("CreateSoldierEnemies", 10, -1, function()
				local navAreas = navmesh.GetAllNavAreas()
				local randomSpawn = math.floor(math.random(1, #navAreas + 1))

				local soldier = ents.Create("npc_combine_s")

				soldier:SetPos(navAreas[randomSpawn]:GetRandomPoint())
				soldier:Give("weapon_shotgun")
				soldier:Spawn()
			end)

			timer.Create("RandomWeaponSpawns", 10, -1, function()
				if (#self.AmmoCache >= self.WeaponSpawnRoof) then
					for _, x in pairs(self.AmmoCache) do
						if IsValid(x) then
							x:Remove()
						end
					end
				end

				if self.WeaponsInMap >= self.WeaponSpawnRoof then return end

				local navAreas = navmesh.GetAllNavAreas()
				local randomSpawn = math.floor(math.random(1, #navAreas + 1))

				local ra = self:SelectRandomWeapon()

				if !ra then return end

				local weapon = ents.Create(ra)

				weapon:SetPos(navAreas[randomSpawn]:GetRandomPoint())
				weapon:Spawn()

				print(self:SelectRandomAmmo())

				local ammo = ents.Create("sent_xdest_loot")

				local randomSpawn2 = math.floor(math.random(1, #navAreas + 1))


				ammo:SetPos(navAreas[randomSpawn2]:GetRandomPoint())
				ammo:Spawn()

				self.AmmoCache[#self.AmmoCache + 1] = ammo

				self.AmmoCache = {}

				self.WeaponsInMap = self.WeaponsInMap + 1
			end)
	end

	self:RoundStartCallback()
end

function roundManager:EndRound(reason)
	// Cleanup the current round

	RunConsoleCommand("fpsfog_active", 0)
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

		timer.Remove("RandomWeaponSpawns")
		self.WeaponsInMap = 0
		// Run a final cleanup
		RunConsoleCommand("gmod_admin_cleanup")
	end)
end

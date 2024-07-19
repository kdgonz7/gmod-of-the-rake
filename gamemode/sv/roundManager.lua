/*
Handle the management of rounds
*/

/* Round statuses enum */
IN_LOBBY = 0
IN_MATCH = 1

/* reasons enum */
REASON_DEATHS = 0
REASON_WINNER = 1

/*
	Helper functions
*/

/*
	roundManager class
*/
roundManager = roundManager or {
	InRound = false,
	TimeLeft = 0,

	Players = {},
	DeadPlayers = {},

	RoundStartTime = 5,

	RakeEntity = nil,
	RakeBadPositions = {},

	WeaponSpawnList = {},
	AmmoSpawnList = {},

	AmmoCache = {},

	LastRakeKiller = nil,

	GameState = CreateConVar("rake_GameState", "lobby", FCVAR_REPLICATED, "The state of the game. lobby, match, etc."),
	EnemySpawnFrequency = CreateConVar("rake_EnemySpawnFrequency", 5, FCVAR_REPLICATED, "Frequency of enemy spawns."),

	ArmorEnabled = CreateConVar("rake_ArmorEnabled", 1, FCVAR_REPLICATED, "Enable or disable armor. 1 = enabled, 0 = disabled."),
	FogEnabled = CreateConVar("rake_FogEnabled", 1, FCVAR_REPLICATED, "Enable or disable fog. 1 = enabled, 0 = disabled."),
	Difficulty = CreateConVar("rake_Difficulty", 1, FCVAR_REPLICATED, "Difficulty. 0 = easy, 1 = normal, 2 = hard"),
	UseForTracking = CreateConVar("rake_UseForTracking", "ainodes", FCVAR_REPLICATED, "Which method should be used to spawn rake? navmesh or ainodes. note: navmesh is more likely to get rake stuck initially"),

	WeaponClasses = {
		["Assault"] = {
			{"mg_acharlie", "AR2", 210},
			{ "mg_m9", "Pistol", 50}
		}
	},

	WeaponsInMap = 0,
	WeaponSpawnRoof = 10,

	RoundStartCallback = function() end,
	RoundEndCallback = function() end
}

AiNodes = AiNodes or nil
navAreas = navAreas or nil

function roundManager:Initialize()
	return self
end

function roundManager:IsAKnownBadPosition(position)
	for k, v in pairs(self.RakeBadPositions) do
		if v == position then
			return true
		end
	end
	return false
end

function roundManager:AddBadPosition(position)
	if self:IsAKnownBadPosition(position) then return end
	self.RakeBadPositions[#self.RakeBadPositions + 1] = position
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


function GetRandomPointInMap(typ)
	if typ == "navmesh" then
		return navAreas[math.random(1, #navAreas)]:GetRandomPoint()
	elseif typ == "ainodes" then
		return AiNodes[math.random(1, #AiNodes)]
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

function roundManager:SelectRandomPlayer()
	if #self.Players == 0 then
		return nil
	end

	local index = math.random(1, #self.Players)

	return self.Players[index]
end

function roundManager:ClearDeadPlayers()
	self.DeadPlayers = {}
end

function roundManager:RemoveDeadPlayer(player)
	for k, v in pairs(self.DeadPlayers) do
		if v == player then
			table.remove(self.DeadPlayers, k)
		end
	end
end

// remove player from alive array and add to dead
function roundManager:RegisterDead(player)
	for k, v in pairs(self.Players) do
		if v == player then
			table.remove(self.Players, k)
			break
		end
	end

	self.DeadPlayers[#self.DeadPlayers + 1] = player
end

function roundManager:ResetAllPlayers()
	for k, v in pairs(self.Players) do
		v:UnLock()
		v:Spawn()
	end

	for k, v in pairs(self.DeadPlayers) do
		v:UnSpectate()
		v:Spawn()

		table.remove(self.DeadPlayers, k)
	end
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

		self.GameState:SetString("lobby")
	elseif status == IN_MATCH then
		InRound = true
		self:RoundStartCallback()
		PrintMessage(HUD_PRINTCENTER, "Round Beginning...")

		self.GameState:SetString("match")
	end
end

function FindClosestNode(toPosition)
	if ! AiNodes then return end

	local closest = nil

	for _, v in pairs(AiNodes) do
		local distance = v:DistToSqr(toPosition)

		if !closest or distance < closest:DistToSqr(toPosition) then
			closest = v
		end
	end

	return closest
end

// start the round, reset the players and get them ready with weaponry.
function roundManager:StartRound()
	if self:GetRoundStatus() == IN_MATCH then return end

	if self.FogEnabled:GetBool() then
		RunConsoleCommand("fpsfog_active", self.Difficulty:GetInt())
		RunConsoleCommand("fpsfog_color_r", 30)
		RunConsoleCommand("fpsfog_color_g", 30)
		RunConsoleCommand("fpsfog_color_b", 30)
		RunConsoleCommand("fpsfog_distance", 1000 / self.Difficulty:GetInt())
		RunConsoleCommand("fpsfog_thickness", 50 * self.Difficulty:GetInt())
	else
		RunConsoleCommand("fpsfog_active", 0)
	end

	RunConsoleCommand("gmod_admin_cleanup")

	self:ModifyStatus(IN_MATCH)

	PrintMessage(HUD_PRINTCENTER, "Round starting in 5 seconds...")

	for _, v in pairs(self.Players) do
		v:StripWeapons()
		v:StripAmmo()

		v:Spawn()

		for _, x in ipairs(self.WeaponClasses[v.WeaponClass]) do
			v:Give(x[1])
			v:GiveAmmo(x[3], x[2])
		end

		if self.ArmorEnabled:GetBool() then
			v:SetArmor(100)
		end

		timer.Simple(5, function()
			local rake = ents.Create("drg_sf2_therake")

			local randSpawn = GetRandomPointInMap(self.UseForTracking:GetString())

			rake.RunSpeed = 500 * self.Difficulty:GetInt()
			rake.SpawnHealth = 10000 * self.Difficulty:GetInt()

			rake:SetPos(randSpawn)
			rake:SetPos(rake:GetPos() + Vector(0, 0, 100))

			rake:Spawn()

			self.RakeEntity = rake

			self:ModifyStatus(IN_MATCH)
		end)

		timer.Create("FindSomeoneToKill", 22, -1, function()
				if ! self.RakeEntity then return end

				local p = self:SelectRandomPlayer()

				if ! p then return end

				if p:Alive() then /* spawn right on top of em */
					local around = FindClosestNode(p:GetPos())

					self.RakeEntity:SetPos(around)
					self.RakeEntity:SetNW2Entity("DrGBaseEnemy", p)
				end
			end)

			timer.Create("SpawnSupplies", 20, -1, function()
				local ammo = ents.Create("sent_xdest_loot")

				local randomSpawn2 = GetRandomPointInMap(self.UseForTracking:GetString())

				ammo:SetPos(randomSpawn2)
				ammo:Spawn()

				self.AmmoCache[#self.AmmoCache + 1] = ammo

				if #self.AmmoCache > 10 then
					for _, z in ipairs(self.AmmoCache) do
						z:Remove()
					end

					PrintMessage(HUD_PRINTCENTER, "Clearing out loot...")
				else
					PrintMessage(HUD_PRINTCENTER, "Loot has spawned!")
				end
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
	elseif reason == REASON_WINNER then
		PrintMessage(HUD_PRINTCENTER, self.LastRakeKiller:Nick() .. ": Report! Creature Down!")
	else
		PrintMessage(HUD_PRINTCENTER, "Report in team. Round over.")
	end

	timer.Simple(5, function()
		self:ModifyStatus(IN_LOBBY)

		self:ResetAllPlayers()

		if self.RakeEntity:IsValid() then
			self.RakeEntity:Remove()
			self.RakeEntity = nil
		end

		timer.Remove("FindSomeoneToKill")
		timer.Remove("SpawnSupplies")

		self.WeaponsInMap = 0
		self.AmmoCache = {}

		// Run a final cleanup
		RunConsoleCommand("gmod_admin_cleanup")
	end)
end

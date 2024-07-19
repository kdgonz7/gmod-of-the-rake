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
	FindBestIndex(l, f)
			Finds the first index in l that is nil.
			If no index is nil, it will remove the first element.
			Will return 0 if all elements in l are nil.

	Best case; O(1)
	Worst case; O(n)
*/
function FindBestIndex(list, floor)
	local goodIndex = 0;

	local i = 0

	while i <= floor do
		if list[i] == nil then
				goodIndex = i
				break
		end

		if i == floor then
				list[1]:Remove()
				table.remove(list, 1)
				i = 0
		end

		i = i + 1
	end

	return goodIndex
end

/*
	roundManager class
*/
roundManager = roundManager or {
	InRound = false,
	TimeLeft = 0,
	Players = {},
	RoundStartTime = 5,

	RakeEntity = nil,
	RakeBadPositions = {},

	WeaponSpawnList = {},
	AmmoSpawnList = {},

	AmmoCache = {},

	LastRakeKiller = nil,

	GameState = CreateConVar("rake_GameState", "lobby", FCVAR_REPLICATED, "The state of the game. lobby, match, etc."),
	FogEnabled = CreateConVar("rake_FogEnabled", 1, FCVAR_REPLICATED, "Enable or disable fog. 1 = enabled, 0 = disabled."),
	EnemySpawnFrequency = CreateConVar("rake_EnemySpawnFrequency", 5, FCVAR_REPLICATED, "Frequency of enemy spawns."),
	ArmorEnabled = CreateConVar("rake_ArmorEnabled", 1, FCVAR_REPLICATED, "Enable or disable armor. 1 = enabled, 0 = disabled."),

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

		self.GameState:SetString("lobby")
	elseif status == IN_MATCH then
		InRound = true
		self:RoundStartCallback()
		PrintMessage(HUD_PRINTCENTER, "Round Beginning...")

		self.GameState:SetString("match")
	end
end

// start the round, reset the players and get them ready with weaponry.
function roundManager:StartRound()
	if self:GetRoundStatus() == IN_MATCH then return end

	if self.FogEnabled:GetBool() then
		RunConsoleCommand("fpsfog_active", 1)
		RunConsoleCommand("fpsfog_color_r", 30)
		RunConsoleCommand("fpsfog_color_g", 30)
		RunConsoleCommand("fpsfog_color_b", 30)
		RunConsoleCommand("fpsfog_distance", 1000)
		RunConsoleCommand("fpsfog_thickness", 50	)
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
			local navAreas = navmesh.GetAllNavAreas()
			local randomSpawn = math.floor(math.random(1, #navAreas))

			local rake = ents.Create("drg_sf2_therake")

			rake:SetPos(navAreas[randomSpawn]:GetRandomPoint())
			rake:SetPos(rake:GetPos() + Vector(0, 0, 100))
			rake.OnStuck = function(self)
				local navArea = navmesh.GetAllNavAreas()
				local randomSpaw = math.floor(math.random(1, #navAreas))

				local badpositions = rake.BadPositions or {}

				local point = navArea[randomSpaw]:GetRandomPoint()
				-- local second_iterator = 1
				for _, x in pairs(badpositions) do
					if x == point then
						self:OnStuck()
						return
					end
				end

				rake:SetPos(point)
				rake:SetPos(rake:GetPos() + Vector(0, 0, 100))

				self.loco:ClearStuck()

			end
			rake:Spawn()

			self.RakeEntity = rake

			self:ModifyStatus(IN_MATCH)
		end)
			timer.Create("RandomWeaponSpawns", 10, -1, function()

				local ammo = ents.Create("sent_xdest_loot")

				local navAreas = navmesh.GetAllNavAreas()
				local randomSpawn2 = math.floor(math.random(1, #navAreas))

				ammo:SetPos(navAreas[randomSpawn2]:GetRandomPoint())
				ammo:Spawn()

				local ind = FindBestIndex(self.AmmoCache, 10)
				self.AmmoCache[ind] = ammo

				self.AmmoCache = {}
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

		for _, v in pairs(self.Players) do
			v:UnLock()
			v:StripWeapons()
			v:RemoveAllAmmo()
			v:Spawn()


			if reason == REASON_DEATHS or v:GetObserverTarget() ~= nil then
				v:UnSpectate()
			end
		end

		if self.RakeEntity:IsValid() then
			self.RakeEntity:Remove()
			self.RakeEntity = nil
		end

		timer.Remove("RandomWeaponSpawns")

		self.WeaponsInMap = 0
		self.AmmoCache = {}

		// Run a final cleanup
		RunConsoleCommand("gmod_admin_cleanup")
	end)
end

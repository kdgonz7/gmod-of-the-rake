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

	WalkSpeeds = {
		[0] = { 250, 350 }, -- Melee
		[1] = { 160, 265 }, /* [Ammo ID] = { walk speed, run speed } */	-- AR2
		[3] = { 200, 300 }, -- Pistol
		[4] = { 130, 265 },	-- SMG
	},

	LastRakeKiller = nil,

	GameState = CreateConVar("rake_GameState", "lobby", FCVAR_REPLICATED, "The state of the game. lobby, match, etc."),
	EnemySpawnFrequency = CreateConVar("rake_EnemySpawnFrequency", 5, FCVAR_REPLICATED, "Frequency of enemy spawns."),

	ArmorEnabled = CreateConVar("rake_ArmorEnabled", 1, FCVAR_REPLICATED, "Enable or disable armor. 1 = enabled, 0 = disabled."),
	FogEnabled = CreateConVar("rake_FogEnabled", 1, FCVAR_REPLICATED, "Enable or disable fog. 1 = enabled, 0 = disabled."),
	Difficulty = CreateConVar("rake_Difficulty", 1, FCVAR_REPLICATED, "Difficulty. 0 = easy, 1 = normal, 2 = hard"),
	UseForTracking = CreateConVar("rake_UseForTracking", "ainodes", FCVAR_REPLICATED, "Which method should be used to spawn rake? navmesh or ainodes. note: navmesh is more likely to get rake stuck initially"),

	WeaponClasses = {
		["assault"] = {
			{"mg_acharlie", "AR2", 210},
			{ "mg_m9", "Pistol", 50},
			{"rake_createviewtrap", nil, nil},
		},
		["assassin"] = {
			{"mg_sm_t9standard", "SMG1", 210},
			{"mg_makarov", "Pistol", 50},
			{"weapon_slam", "slam", 10},
			{"rake_createviewtrap", nil, nil},
		},
	},

	XPRequirements = {
		["assault"] = 0,
		["assassin"] = 60,
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
	for k, v in pairs(self.Players) do
		if v == player then
			return true
		end
	end
	return false
end

function roundManager:NoPlayersLeft()
	return #self.Players == 0
end

--- Add and remove players from the cache
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

-- remove player from alive array and add to dead
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

		v:PrintMessage(HUD_PRINTTALK, "+5 XP for staying alive")
		dataBase:ModifyPlayerXP(v, 5)
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

function FindClosestNode(toPosition, depth)
	if ! AiNodes then return end

	depth = depth or 1

	local distances = {}

	for _, v in pairs(AiNodes) do
			local distance = v:DistToSqr(toPosition)
			table.insert(distances, { node = v, distance = distance })
	end

	local function partition(arr, low, high)
			local pivot = arr[high].distance
			local i = low
			for j = low, high - 1 do
					if arr[j].distance < pivot then
							arr[i], arr[j] = arr[j], arr[i]
							i = i + 1
					end
			end
			arr[i], arr[high] = arr[high], arr[i]
			return i
	end

	local function quickselect(arr, low, high, k)
			if low <= high then
					local pi = partition(arr, low, high)
					if pi == k then
							return arr[pi]
					elseif pi < k then
							return quickselect(arr, pi + 1, high, k)
					else
							return quickselect(arr, low, pi - 1, k)
					end
			end
	end

	local result = quickselect(distances, 1, #distances, depth)
	return result and result.node or nil
end

-- start the round, reset the players and get them ready with weaponry.
function roundManager:StartRound()
	/* initial startup */

	if self:GetRoundStatus() == IN_MATCH then return end -- don't start if we're already in a round

	-- in case it's enabled, we'll disable it
	RunConsoleCommand("ai_disabled", 0)

	/* if fog is enabled, turn it on */
	if self.FogEnabled:GetBool() then
		RunConsoleCommand("fpsfog_active", self.Difficulty:GetInt())
		RunConsoleCommand("fpsfog_color_r", 30)
		RunConsoleCommand("fpsfog_color_g", 30)
		RunConsoleCommand("fpsfog_color_b", 30)
		RunConsoleCommand("fpsfog_distance", 1000 / self.Difficulty:GetInt())
		RunConsoleCommand("fpsfog_thickness", 50 * self.Difficulty:GetInt())
	else
		RunConsoleCommand("fpsfog_active", 0) -- keep it off
	end

	-- clean up the map
	RunConsoleCommand("gmod_admin_cleanup")

	self:ModifyStatus(IN_MATCH) -- set the game state to match

	-- let the players know the round is starting
	PrintMessage(HUD_PRINTCENTER, "Round starting in 5 seconds...")

	for _, v in pairs(self.Players) do
		-- reset the player
		v:StripWeapons()
		v:StripAmmo()
		v:Spawn() -- spawn em

		local wc = v:GetNWString("WeaponClass") -- get the player's weapon class (WeaponClass)

		for _, x in pairs(self.WeaponClasses[wc]) do
			if ! v:Give(x[1]) then
				print( "failed to give weapon " .. x[1] .. " to " .. v:Nick() )
			end

			print("Giving " .. x[1])

			if x[2] then
				v:GiveAmmo(x[3], x[2])
			end

			v:DrawViewModel( true ) -- for some reason the viewmodels disappear, i don't know why and don't know if this fixes it
		end

		v:SelectWeapon(self.WeaponClasses[wc][1][1]) -- select the first weapon

		if self.ArmorEnabled:GetBool() then	-- if armor is enabled (why wouldn't it be, you psychos???)
			v:SetArmor(100)
		end
	end
	/* note: this future code is primarily a repetitive sequence of timers and events that happen during the match */
		timer.Simple(5, function()
			-- spawn the rake
			local rake = ents.Create("drg_sf2_therake")

			local randSpawn = GetRandomPointInMap(self.UseForTracking:GetString())

			rake.RunSpeed = 500 * self.Difficulty:GetInt()
			rake.SpawnHealth = 10000 * self.Difficulty:GetInt()

			--!	This function may be removed in the future
			rake.OnStuck = function()
				local att2 = GetRandomPointInMap(self.UseForTracking:GetString())

				rake:SetPos(att2)
				rake:SetPos(rake:GetPos() + Vector(0, 0, 100))
			end

			-- set the spawn position to a random point
			rake:SetPos(randSpawn)
			rake:SetPos(rake:GetPos() + Vector(0, 0, 100))

			-- spawn
			rake:Spawn()
			self.RakeEntity = rake
		end)

		-- keep the game moving by spawning the rake near a random player,
		-- so they are not in the dark the entire time
		timer.Create("FindSomeoneToKill", 60, -1, function()
				if ! self.RakeEntity then return end

				-- select a random player
				local p = self:SelectRandomPlayer()

				-- the function should not fail,
				-- but if it does we'll return, this failed
				if ! p then return end

				-- if they're alive
				if p:Alive() then /* spawn right on top of em */
					local around = FindClosestNode(p:GetPos(), 4)

					self.RakeEntity:SetPos(around)

					-- in case this stupid nextbot does
					-- not see the player initially, then 
					-- we'll just shove it in it's face (pause)
					self.RakeEntity:SetNW2Entity("DrGBaseEnemy", p)

					-- print a message to let them know, this doesn't work
					-- for some odd reason and i might remove it :)
					PrintMessage(HUD_PRINTCENTER, "The Rake is on the loose!")
				end
			end)

			-- again, another timer that spawns loot
			timer.Create("SpawnSupplies", 20, -1, function()
				-- we finally aren't using sent_xdest_loot anymore, thanks!
				local ammo = ents.Create("rake_supplycrate")

				-- if we fail to create the entity
				if ! ammo then return end

				-- we select a random part of the map.
				local randomSpawn2 = GetRandomPointInMap(self.UseForTracking:GetString())

				-- spawn it there
				ammo:SetPos(randomSpawn2)
				ammo:Spawn()

				self.AmmoCache[#self.AmmoCache + 1] = ammo

				-- we don't want to continually spawn a thousand crates, so we'll just remove them lol
				if #self.AmmoCache > 10 then
					-- look through the ammo cache
					for _, z in ipairs(self.AmmoCache) do
						if z:IsValid() then
							z:Remove() -- remove it
						end
					end

					-- we'll let them know the loot is disappearing
					-- "WHY IS THERE NO LOOT" - player 3, at 1hp
					PrintMessage(HUD_PRINTCENTER, "Clearing out loot...")

					self.AmmoCache = {}
				else
					-- otherwise we just print a message
					-- saying the loot has dropped.
					PrintMessage(HUD_PRINTCENTER, "Loot has spawned!")
				end
			end)

			-- okay, i'm gonna stop commenting on these timers
			timer.Create("RakeBuyStationSpawn", 30, 1, function()
				-- if there's no rake, we don't need to do anything.
				-- idk why this is here, but it's here and works so i'm not changing it.
				if ! self.RakeEntity then return end

				-- print a message
				PrintMessage(HUD_PRINTCENTER, "Buy Station Has Spawned!")

				-- so we find a node that's the closest to the map origin
				-- TODO: change this, i don't know if this works under every case
				local randomSpawn = FindClosestNode(Vector(0, 0, 0), 3)
				if ! randomSpawn then return end

				-- create the buy station entity
				local buyStation = ents.Create("rake_buystation")

				-- set it's position
				buyStation:SetPos(randomSpawn)
				buyStation:SetPos(buyStation:GetPos() + Vector(0, 0, -3))
				buyStation:Spawn()

				-- in 60 seconds, we can remove it and let them know they screwed up
				timer.Simple(60, function()
					if buyStation:IsValid() then
						buyStation:Remove()
					end

					PrintMessage(HUD_PRINTCENTER, "Buy Station Has Been Removed!")
				end)
			end)

	-- i have no clue why i implemented this, as it was never used, so I might remove this. :)
	self:RoundStartCallback()
end

/*
	This function ends a round and cleans up the game state
*/
function roundManager:EndRound(reason)
	reasons = reasons or REASON_OTHER

	-- Cleanup the current round
	if self:GetRoundStatus() == IN_LOBBY then return end

	RunConsoleCommand("fpsfog_active", 0)		-- disable the fog
	RunConsoleCommand("ai_disabled", 1)			-- should've did this a long ass time ago, so the rake doesn't kill you

	-- check the reason the game ended
	-- this is 90% self explanatory, enjoy the condition tree :)
	if reason == REASON_DEATHS then
		PrintMessage(HUD_PRINTCENTER, "Too many players have died. Ending in 5 seconds.")
	elseif reason == REASON_WINNER then
		PrintMessage(HUD_PRINTCENTER, self.LastRakeKiller:Nick() .. ": Report! Creature Down!")
	else
		PrintMessage(HUD_PRINTCENTER, "Report in team. Round over.")
	end

	-- 5 second timer, which ends the round after.
	-- TODO: add a countdown or something
	timer.Simple(5, function()
		-- we are now in lobby
		self:ModifyStatus(IN_LOBBY)		-- set the status to IN_LOBBY
		self:ResetAllPlayers()				-- clear out all players (AKA respawn them)
		dataBase:SaveToFile()					-- save all the player data

		-- remove the rake entity
		if self.RakeEntity ~= nil then
			self.RakeEntity:Remove()
			self.RakeEntity = nil
		end

		-- memory: free all the currently running timers
		timer.Remove("FindSomeoneToKill")
		timer.Remove("SpawnSupplies")
		timer.Remove("RakeBuyStationSpawn")

		self.WeaponsInMap = 0

		-- clear out the ammo cache
		-- NOTE: this should've been done a while ago, because idk if garbage collection
		-- is a thing in source
		for i = 1, #self.AmmoCache do
			local z = self.AmmoCache[i]

			if z:IsValid() then
				z:Remove()
			end
		end

		self.AmmoCache = {}	-- okay now we freshen up the cache

		-- Run a final cleanup
		RunConsoleCommand("gmod_admin_cleanup")
	end)
end

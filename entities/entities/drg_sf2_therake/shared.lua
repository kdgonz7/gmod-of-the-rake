if not DrGBase then -- return if DrGBase isn't installed
	Derma_Message("Please install DRGBase for THE RAKE to work!", "DRGBase not found!", "OK")
	return
end

ENT.Base = "drgbase_nextbot" -- DO NOT TOUCH (obviously)
	-- Misc --
ENT.PrintName = "Rake (2)"
ENT.Category = "THE RAKE (Modified)"
ENT.Models = {"models/painkiller_76/sf2/rake/new/rakev2.mdl"}
ENT.ModelScale = 1.2
ENT.CollisionBounds = Vector(10, 10, 50)
ENT.EntitiesToNoCollide = {"prop_physics"}
-- Sounds --
ENT.OnDamageSounds = {"slender/newrake/intro2.mp3"}
ENT.OnIdleSounds = {"slender/newrake/idle1.mp3", "slender/newrake/idle2.mp3", "slender/newrake/idle3.mp3", "slender/newrake/idle4.mp3", "slender/newrake/idle5.mp3"}
-- Stats --
ENT.SpawnHealth = 10000
ENT.HealthRegen = 0
-- AI --
ENT.RangeAttackRange = 50
ENT.MeleeAttackRange = 50
ENT.ReachEnemyRange = 50
ENT.AvoidEnemyRange = 0
-- Relationships --
ENT.Factions = {"FACTION_RAKE"}
-- Movements/animations --
ENT.RunAnimRate = 1
ENT.WalkAnimRate = -1
ENT.Acceleration = 500
ENT.Deceleration = 5000
ENT.WalkSpeed = 300
ENT.RunSpeed = 500
ENT.WalkAnimation = "run"
ENT.IdleAnimation = "newidle2"
ENT.RunAnimation = "run"
-- Detection --
ENT.EyeBone = "ValveBiped.Bip01_Head"
ENT.EyeOffset = Vector(7.5, 0, 5)
-- Possession --
ENT.PossessionCrosshair = true
ENT.PossessionEnabled = true
ENT.PossessionMovement = POSSESSION_MOVE_1DIR
ENT.PossessionViews = {
	{
		offset = Vector(0, 30, 0),
		distance = 100
	},
	{
		offset = Vector(20, 0, 0),
		distance = 0,
		eyepos = true
	}
}

ENT.PossessionBinds = {
	[IN_ATTACK] = {
		{
			coroutine = true,
			onkeydown = function(self)
				local terma = math.random(2)
				if terma == 1 then
					self:Termaattack1()
					self:PlaySequenceAndMove("br2_attack", 1, self.FaceEnemy)
				end

				if terma == 2 then
					self:Termaattack1()
					self:PlaySequenceAndMove("melee", 1, self.FaceEnemy)
					self:Termaattack1()
					self:PlaySequenceAndMove("melee", 1, self.FaceEnemy)
				end
			end
		}
	},
	[IN_JUMP] = {
		{
			coroutine = true,
			onkeydown = function(self) self:Jump(960) end
		}
	}
}

local threshold = 300
local damage_taken = 0

function ENT:Termaattack1()
	self:Attack({
		damage = 50,
		range = 100,
		delay = 0.3,
		radius = 350,
		force = Vector(100, 100, 100),
		type = DMG_SLASH,
		viewpunch = Angle(20, math.random(-10, 10), 0),
	}, function(self, hit)
		if #hit > 0 then
			self:EmitSound("Zombie.AttackHit")
		else
			self:EmitSound("Zombie.AttackMiss")
		end
	end)
end

if SERVER then
	running = running or false
	-- Init/Think --
	function ENT:CustomInitialize()
		self:SetDefaultRelationship(D_HT)
	end

	-- AI --
	function ENT:CustomThink()
		if self.WAttacking and self:GetNW2Entity("DrGBaseEnemy") then
			self:SetNW2Entity("DrGBaseEnemy", nil)
		end

		for k, ball in pairs(ents.FindInSphere(self:LocalToWorld(Vector(0, 0, 75)), 50)) do
			if IsValid(ball) then
				if ball:GetClass() == "prop_door_rotating" then ball:Fire("open") end
				if ball:GetClass() == "func_door_rotating" then ball:Fire("open") end
				if ball:GetClass() == "func_door" then ball:Fire("open") end
			end
		end
		-- if running then
		-- 	self:MoveToPos(self:RandomPos(1500))
		-- end
	end

	function ENT:OnMeleeAttack(enemy)
		local terma = math.random(2)
		if terma == 1 then
			self:Termaattack1()
			self:PlaySequenceAndMove("br2_attack", 1, self.FaceEnemy)
		end

		if terma == 2 then
			self:Termaattack1()
			self:PlaySequenceAndMove("melee", 1, self.FaceEnemy)
			self:Termaattack1()
			self:PlaySequenceAndMove("melee", 1, self.FaceEnemy)
		end
	end


	function ENT:OnNewEnemy(enemy)
		self:PlaySequence("br2_roar")
		self:EmitSound("slender/newrake/intro1.mp3", 100)
	end

	function ENT:OnReachedPatrol()
		self:PlaySequenceAndMove("idle_angry")
	end

	function ENT:OnIdle()
		self:AddPatrolPos(self:RandomPos(1500))
	end

	-- hide (run away, to a random area) when shot --
	function ENT:OnTakeDamage(dmg)
		damage_taken = damage_taken + dmg:GetDamage()

		if damage_taken >= threshold then
			local att2 = GetRandomPointInMap(roundManage.UseForTracking:GetString())
			local rake = self
			rake:SetPos(att2)
			rake:SetPos(rake:GetPos() + Vector(0, 0, 100))

			local p = dmg:GetAttacker()

			if IsValid(p) then
				p:PrintMessage(HUD_PRINTTALK, "+10 XP for deterring the rake")
				dataBase:ModifyPlayerXP(p, 10)
			end

			local myEnt = self:GetNW2Entity("DrGBaseEnemy")

			-- check if the entity is valid
			-- TODO clean this up
			if IsValid(myEnt) then
			if p ~= myEnt and p:Alive() and myEnt:Alive() then
					p:PrintMessage(HUD_PRINTTALK, "+15 XP for saving " .. self:GetNW2Entity("DrGBaseEnemy"):Name())
					myEnt:PrintMessage(HUD_PRINTTALK, "you were saved by " .. p:Name())
				end
			end

			damage_taken = 0

			self:SetNW2Entity("DrGBaseEnemy", nil)
		end
	end
end

-- DO NOT TOUCH --
AddCSLuaFile()
DrGBase.AddNextbot(ENT)
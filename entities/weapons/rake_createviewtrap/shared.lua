// Create a view trap for the rake
AddCSLuaFile()

SWEP.PrintName = "Create Rake View Trap"
SWEP.Author = "Kai D."
SWEP.Category = "The Rake Tools"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Purpose = "Spawn rake traps"

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo		= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo		= "none"

SWEP.DrawAmmo = false

SWEP.Weight			= 0
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.Slot			= 0
SWEP.SlotPos			= 5
SWEP.DrawAmmo			= false
SWEP.DrawCrosshair		= true
SWEP.canSpawn = true

function SWEP:Initialize()
	self:SetHoldType("normal")
end

function SWEP:Deploy()
	if CLIENT then
			self:CreatePreviewEntity()
	end
	return true
end

function SWEP:Holster()
	if CLIENT then
			self:RemovePreviewEntity()
	end
	return true
end

function SWEP:CreatePreviewEntity()
	if not IsValid(self.PreviewEntity) then
			self.PreviewEntity = ClientsideModel("models/combine_turrets/floor_turret.mdl")
			self.PreviewEntity:SetNoDraw(true)
			self.PreviewEntity:SetRenderMode(RENDERMODE_TRANSCOLOR)
			self.PreviewEntity:SetColor(Color(0, 255, 0, 150)) // Semi-transparent green
	end
end

function SWEP:RemovePreviewEntity()
	if IsValid(self.PreviewEntity) then
			self.PreviewEntity:Remove()
			self.PreviewEntity = nil
	end
end

function SWEP:ShouldDrawViewModel()
	return false
end

function SWEP:PrimaryAttack()
	if SERVER then
		local owner = self:GetOwner()
		local tr = owner:GetEyeTrace()
		if tr.Hit and tr.HitPos:Distance(owner:GetPos()) <= 100 and self.canSpawn then
			local ent = ents.Create("rake_viewtrap")

			local ey = owner:EyeAngles()
			ey.pitch = 0

			ent:SetPos(tr.HitPos)
			ent:SetAngles(ey)
			ent:Spawn()

			self.canSpawn = false
		end
	end
end

function SWEP:SecondaryAttack()
	if SERVER then
		local owner = self:GetOwner()
		local tr = owner:GetEyeTrace()

		if tr.Hit and tr.Entity:GetClass() == "rake_viewtrap" then
			self.canSpawn = true
			tr.Entity:Remove()
		end
	end
end

function SWEP:Think()
	if CLIENT and IsValid(self.PreviewEntity) then
			local owner = self:GetOwner()
			local tr = owner:GetEyeTrace()
			if tr.Hit and tr.HitPos:Distance(owner:GetPos()) <= 100 then
					self.PreviewEntity:SetPos(tr.HitPos)
					self.PreviewEntity:SetAngles(owner:GetAngles())
					self.PreviewEntity:SetNoDraw(false)
			else
					self.PreviewEntity:SetNoDraw(true)
			end
	end
end

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

SWEP.Weight			= 1
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.Slot			= 1
SWEP.SlotPos			= 2
SWEP.DrawAmmo			= false
SWEP.DrawCrosshair		= true

function SWEP:Initialize()
	self:SetHoldType("fists")
end

function SWEP:Deploy()
	return true
end

function SWEP:ShouldDrawViewModel()
	return false
end

function SWEP:PrimaryAttack()
	if SERVER then
		local owner = self:GetOwner()
		local tr = owner:GetEyeTrace()
		if tr.Hit and tr.HitPos:Distance(owner:GetPos()) <= 100 then
			local ent = ents.Create("rake_viewtrap")

			ent:SetPos(tr.HitPos)
			ent:Spawn()

			self:Remove()
		end
	end
end

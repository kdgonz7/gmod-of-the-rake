-- Traps the rake, allows you to see where it is if it is in this entities line of sight.
ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Rake View Trap"
ENT.Author = "Kai D."
ENT.Category = "The Rake Tools"
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_BOTH

AddCSLuaFile()

ENT.Model = "models/combine_turrets/floor_turret.mdl"
ENT.NoClimbing = true

if SERVER then
	Rake = nil
end

function ENT:Initialize()
	self:SetModel(self.Model)
	self:PhysicsInit(SOLID_NONE)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
end

function ENT:Think()
	local forward = self:GetForward()
	local tr = util.QuickTrace(self:GetPos() + Vector(0, 0, 30), forward * 10000, self)
	local hitEntity = tr.Entity

	if tr.Hit and hitEntity:GetClass() == "drg_sf2_therake" then
		Rake = hitEntity
		if SERVER then
			PrintMessage(HUD_PRINTCENTER, "ALERT: An anomaly has been detected.")
			if !self then return end
			self:Remove()
		end
	end
end

hook.Add("PreDrawHalos", "RakeViewTrapPreDrawHalos", function()
	if Rake == nil then return end

	halo.Add({Rake}, Color(255, 0, 0), 5, 5, 2, true, true)

	timer.Simple(15, function()
		Rake = nil

		if SERVER then
			PrintMessage(HUD_PRINTCENTER, "ALERT: We've lost sight of the anomaly.")
		end
	end)
end)

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Rake View Trap Preview"
ENT.Author = "Kai D."
ENT.Information = "A preview of the Rake View Trap"
ENT.Category = "The Rake Tools"

ENT.Editable = false
ENT.Spawnable = false
ENT.AdminOnly = false

function ENT:Initialize()
	self:SetModel("models/combine_turrets/floor_turret.mdl")
	self:DrawShadow(false)
	self:SetSolid(SOLID_NONE)
	self:SetRenderMode(RENDERMODE_TRANSCOLOR)
	self:SetColor(Color(0, 255, 0, 150)) -- Semi-transparent green
end

function ENT:Think()
	self:SetPos(self:GetPos()) -- Ensure position is updated
	self:NextThink(CurTime())
	return true
end

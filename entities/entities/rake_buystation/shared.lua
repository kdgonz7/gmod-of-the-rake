ENT.Type = 'anim'
ENT.Base = 'base_anim'

ENT.PrintName = 'Rake View Trap'
ENT.Author = 'Kai D.'
ENT.Category = 'The Rake Tools'
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_BOTH

AddCSLuaFile()

ENT.Model = 'models/props_phx/empty_barrel.mdl'

J = nil

function ENT:Initialize()
	self:SetModel(self.Model)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	if SERVER then
	self:PhysicsInit(SOLID_NONE)
	end
	self:SetSolid(SOLID_VPHYSICS)
if SERVER then
	self:SetUseType(SIMPLE_USE)
end
J = self
end

function ENT:Use(activator, caller)
	activator:ConCommand('rake_buy')
end

hook.Add( 'PreDrawHalos', 'PHalo', function()
	halo.Add( { J }, Color( 0 , 0, 255 ), 5, 5, 2, true, true)
end )

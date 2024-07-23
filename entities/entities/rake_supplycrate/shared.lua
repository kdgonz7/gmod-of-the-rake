-- a simple supply crate entity

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Rake Supply Crate"
ENT.Author = "Kai D."
ENT.Category = "The Rake Tools"
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_BOTH

AddCSLuaFile()

ENT.Model = "models/Items/ammocrate_ar2.mdl"

local loot_pool = {
	"item_healthkit",
	"item_battery",
	"item_box_buckshot",
	"item_ammo_ar2",
	"item_ammo_smg1",
	"item_ammo_357",
	"item_healthvial",
	"armorplate_pickup"
}

local weapon_prefix = "mg_"

function filter(tbl, func)
	local newtbl = {}

	for k, v in pairs(tbl) do
		if func(v) then
			table.insert(newtbl, v.ClassName)
		end
	end

	return newtbl
end

local wpn_pool = filter(weapons.GetList(), function (wpn) return string.StartWith(wpn.ClassName, weapon_prefix) end)

function ENT:Initialize()
	self:SetModel(self.Model)
	self:PhysicsInit(SOLID_NONE)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	if SERVER then
		self:SetUseType( SIMPLE_USE )
	end
end

function ENT:Use(activator, caller)
	self:Remove()

	if SERVER then
		for i = 1, 5 do
			local ent = ents.Create( table.Random(loot_pool) )
			ent:SetPos(self:GetPos() + Vector(math.Rand(-10, 10), math.Rand(-10, 10), 0))
			ent:SetVelocity(Vector(math.Rand(-100, 100), math.Rand(-100, 100), math.Rand(-100, 100)))
			ent:Spawn()
		end

		if math.random(1, 2) == 1 then
			print("spawn weapon")
			local ent = ents.Create( wpn_pool[math.random(1, #wpn_pool)] )
			ent:SetPos(self:GetPos() + Vector(math.Rand(-10, 10), math.Rand(-10, 10), 0))
			ent:SetVelocity(Vector(math.Rand(-100, 100), math.Rand(-100, 100), math.Rand(-100, 100)))
			ent:Spawn()
		end

		activator:PrintMessage(HUD_PRINTTALK, "+5 XP")
		dataBase:ModifyPlayerXP(activator, 5)
	end
end

hook.Add("PreDrawHalos", "RakeSupplyHalo", function()
	halo.Add(ents.FindByClass("rake_supply*"), color_white, 0, 0, 1, true, false)
end)
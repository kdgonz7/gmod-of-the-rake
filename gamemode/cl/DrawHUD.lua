local img_health = Material("materials/health.png")
local img_armor = Material("materials/shield.png")

local a = false

function HUD()
	local cl = LocalPlayer()
	if ! cl then return end
	if ! cl:Alive() then return end

	-- draw.RoundedBox(10, 50, ScrH() - 300, 250, 250, Color(39, 39, 39, 255))
	draw.RoundedBox(9, 80 - 2, ScrH() - 70 - 2, 300 + 4, 30 + 4, Color(87, 87, 87))
	draw.RoundedBox(9, 80, ScrH() - 70, 300 * (cl:Health() / cl:GetMaxHealth()), 30, Color(255, 255, 255)) -- health

	surface.SetMaterial(img_health)
	surface.SetDrawColor(255, 255, 255, 255)
	surface.DrawTexturedRect(10, ScrH() - 80, 50, 50)

	draw.RoundedBox(9, ScrW() - 370 - 2, ScrH() - 70 - 2, 300 + 4, 30 + 4, Color(87, 87, 87))
	draw.RoundedBox(9, ScrW() - 370, ScrH() - 70, 300 * (cl:Armor() / cl:GetMaxArmor()), 30, Color(255, 255, 255)) -- health


	surface.SetMaterial(img_health)
	surface.SetDrawColor(255, 255, 255, 255)
	surface.DrawTexturedRect(10, ScrH() - 80, 50, 50)

	surface.SetMaterial(img_armor)
	surface.SetDrawColor(255, 255, 255, 255)
	surface.DrawTexturedRect(ScrW() - 60, ScrH() - 80, 50, 50)

	-- Ammo
	if ! cl:GetActiveWeapon():IsValid() then return end
	draw.SimpleText(cl:GetActiveWeapon():Clip1(), "HudDefault", 80, ScrH() - 310, Color(255, 255, 255, 255), 0, 0)
	draw.SimpleText(cl:GetAmmoCount(cl:GetActiveWeapon():GetPrimaryAmmoType()), "HudHintTextLarge", 80, ScrH() - 290, Color(255, 255, 255, 255), 0, 0)

	if a then
		draw.SimpleText("F3 - Open Menu", "HudHintTextLarge", ScrW() * 0.5, ScrH() * 0.9, Color(255, 255, 255, 255), 0, 0)
	end
	-- how to open menu text
	timer.Simple(30, function()
		
		a = false
	end)
end

function HideHUD(name)
	for _,v in pairs({"CHudHealth","CHudBattery","CHudAmmo","CHudSecondaryAmmo"}) do
		if v == name then
			return false
		end
	end
	return true
end

hook.Add("HUDShouldDraw", "RakeHideHud", HideHUD)
hook.Add("HUDPaint", "RakeHUD", HUD)

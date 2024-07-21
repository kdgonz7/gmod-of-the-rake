/*
Handle XP hooks
*/

dataBase = dataBase or dbInternal:Initialize()

hook.Add("PlayerInitialSpawn", "RakePlayerXPCheck", function(play)
	dataBase:CheckTableAndAdd(play)
end)

-- hook.Add("EntityTakeDamage", "RakeGiveXP", function(ent, dmg)
-- 	if (ent:GetClass() == "drg_sf2_therake") then
-- 		local attacker = dmg:GetAttacker()

-- 		/* if the attacker is a player, nice work! */
-- 		if (attacker:IsPlayer()) then
-- 			dataBase:ModifyPlayerXP(attacker, 1)
-- 		end

-- 		return true
-- 	end
-- end)

/*
	Handle XP hooks
*/

util.AddNetworkString("rake_GiveXP")

hook.Add("PlayerInitialSpawn", "RakePlayerXPCheck", function(play)
	dataBase:LoadPlayerData(play)
end)

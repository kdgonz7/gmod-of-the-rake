AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include "shared.lua"

// function GM:SpawnMenuCreated() return false end


for _, v in pairs(file.Find("gamemodes/rake/gamemode/sv/*.lua", "GAME")) do
	include("sv/" .. v)
end

for _, v in pairs(file.Find("gamemodes/rake/gamemode/shared/*.lua", "GAME")) do
	AddCSLuaFile("shared/" .. v)
	include("shared/" .. v)
end

for _, v in pairs(file.Find("gamemodes/rake/gamemode/cl/*.lua", "GAME")) do
	AddCSLuaFile("cl/" .. v)
end

function GM:Initialize()

end

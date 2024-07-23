AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include "shared.lua"

for _, v in pairs(file.Find("gamemodes/rake/gamemode/sv/*.lua", "GAME")) do
	print("[Rake Loader] Serverside file loaded: " .. v)
	include("sv/" .. v)
end

for _, v in pairs(file.Find("gamemodes/rake/gamemode/shared/*.lua", "GAME")) do
	AddCSLuaFile("shared/" .. v)
	include("shared/" .. v)

	print("[Rake Loader] Shared file loaded: " .. v)
end

for _, v in pairs(file.Find("gamemodes/rake/gamemode/cl/*.lua", "GAME")) do
	AddCSLuaFile("cl/" .. v)

	print("[Rake Loader] Clientside file loaded: " .. v)
end

-- this is the only function you HAVE to define
function GM:Initialize() end

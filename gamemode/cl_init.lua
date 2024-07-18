include "shared.lua"

for _, v in pairs(file.Find("gamemodes/rake/gamemode/cl/*.lua", "GAME")) do
	include("cl/" .. v)
end

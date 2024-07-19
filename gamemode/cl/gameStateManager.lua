local gameState = CreateClientConVar("rake_GameState", "lobby", FCVAR_NONE, "The state of the game. lobby, match, etc.")

function GetGameState()
	return gameState:GetString()
end

print(GetGameState())

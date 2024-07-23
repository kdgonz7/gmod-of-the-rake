-- ability to drop weapons
concommand.Add("drop", function(ply, cmd, args, str)
	ply:DropWeapon(ply:GetActiveWeapon(), nil, Vector(0, 5, 1))
end)

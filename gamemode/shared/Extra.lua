-- ability to drop weapons
concommand.Add("drop", function(ply, cmd, args, str)
	if ! ply then return end
	if ! ply:GetActiveWeapon() then return end

	ply:DropWeapon(ply:GetActiveWeapon(), nil, Vector(0, 5, 1))
end)

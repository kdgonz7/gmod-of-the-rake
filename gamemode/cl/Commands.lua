concommand.Add("rake_MyXP", function(ply, cmd, args, str)
	local myXP = ply:GetNWInt("XP")

	print("[Rake] your XP: " .. myXP)
end)



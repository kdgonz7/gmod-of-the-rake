concommand.Add("rake_BuyClass", function(ply, cmd, args, str)
	if ! args[1] then return end
	net.Start("rake_BuyClass")
	net.WriteString(args[1])
	net.SendToServer()
end)

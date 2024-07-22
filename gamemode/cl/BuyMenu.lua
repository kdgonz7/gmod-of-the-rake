concommand.Add("rake_buy", function(ply, cmd, args, str)
	local Dialog = vgui.Create("DFrame")

	Dialog:SetSize(ScrW() * 0.5, ScrH() * 0.5)
	Dialog:Center()
	Dialog:MakePopup()
	Dialog:SetTitle("Rake Buy Menu")
	Dialog:ShowCloseButton(true)
	Dialog:SetDraggable(true)

	Dialog.Paint = function(self, w, h)
		draw.RoundedBox(5, 0, 0, w, h, Color(40, 40, 40, 250))
	end

	local panel2 = vgui.Create( "DPanel", Dialog )
	// half of window
	panel2:SetSize(Dialog:GetWide() * 0.5, Dialog:GetTall() )

	panel2.Paint = function(self, w, h)
		draw.RoundedBox(5, 0, 0, w, h, Color(89, 89, 89))
	end

	local panel3 = vgui.Create( "DPanel", Dialog )
	// half of window
	panel3.Paint = function(self, w, h)
		draw.RoundedBox(5, 0, 0, w, h, Color(89, 89, 89))
	end


	DrawMultilineText(panel2, "Your current class is '" .. ply:GetNWString("WeaponClass") .. "'\n\nTo the right is the list of classes you can buy,\nas well as classes you own.", "MainUIFont", 50, 50, Color(255, 255, 255))


	local DeadPlayers = vgui.Create( "DListView", Dialog )

	DeadPlayers:SetPos(Dialog:GetWide() * 0.5, Dialog:GetTall() * 0.11)
	DeadPlayers:SetSize(panel2:GetWide(), panel2:GetTall() * 0.4)

	DeadPlayers:SetMultiSelect(false)
	DeadPlayers:AddColumn("Name")

	for k, v in pairs(player.GetAll()) do
		if not v:Alive() then
			DeadPlayers:AddLine(v:Name(), v:SteamID64())
		end
	end

	DeadPlayers.OnRowSelected = function(self, id, line)
		ply:ConCommand("rake_BuyBack " .. line:GetValue(2))
		Dialog:Close()
	end
end)
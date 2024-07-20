net.Receive("startgamehud", function(len)
	if GetConVar("rake_GameState"):GetString() == "match" then return end
		if not frame then
			local frame = vgui.Create("DFrame")
			local w = ScrW() * 0.5
			local h = ScrH() * 0.5

			frame:SetSize(w, h)
			frame:SetTitle("The Rake by Kai D.")

			frame:SetVisible(true)
			frame:SetDraggable(false)
			frame:ShowCloseButton(true)
			frame:SetDeleteOnClose(true)

			frame:Center()
			frame:MakePopup()

			local startLabel = vgui.Create( "DLabel", frame )
			startLabel:SetPos( 210, 100 )
			startLabel:SetSize( 150, 30 )
			startLabel:SetText( "Click start to start the game" )

			local Panel = vgui.Create( "DPanel", frame )
			Panel:SetPos( 10, 100 )
			Panel:SetSize( 150, 150 )

			local Button = vgui.Create( "DButton", frame )
			Button:SetPos( 210, 150 )
			Button:SetSize( 150, 30 )
			Button:SetText( "Start Game" )
			Button.DoClick = function()
				RunConsoleCommand("rake_StartGame")
				frame:Close()
			end


	end
end)
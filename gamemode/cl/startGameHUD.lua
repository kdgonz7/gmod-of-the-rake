hook.Add("Initialize", "RakeAddFonts", function()
	surface.CreateFont("MainUIFont", {
		font = "Arial",
		extended = false,
		size = 21,
		weight = 550,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	})
end)

net.Receive("startgamehud", function(len)
	if GetConVar("rake_GameState"):GetString() == "match" then return end
		if not frame then
			local frame = vgui.Create("DFrame")
			local width = ScrW() * 0.8
			local height = ScrH() * 0.8


			frame:SetSize(width, height)
			frame:SetTitle("The Rake by Kai D.")

			frame:SetVisible(true)
			frame:SetDraggable(false)
			frame:ShowCloseButton(true)
			frame:SetDeleteOnClose(true)

			frame.Paint = function(self, w, h)
				draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40, 200))
			end

			frame:Center()
			frame:MakePopup()

			local panel2 = vgui.Create( "DPanel", frame )
			panel2:Dock( FILL)
			panel2:DockMargin(0, 0, 0, 0)
			panel2.Paint = function(self, w, h)
				draw.RoundedBox(5, 0, 0, w, h, Color(68, 68, 68, 0))
			end

			local ext = vgui.Create( "DPanel", frame )
			ext:Dock( LEFT)
			ext:DockMargin(0, 0, 0, 0)
			ext.Paint = function(self, w, h)
				draw.RoundedBox(5, 0, 0, w, h, Color(77, 77, 77))
			end

			DrawMultilineText(frame, "Welcome to the rake. A gamemode about\nsurvival and killing an anomaly\nknown as the rake.\n\nTo survive you must have teamwork,\nand a determination to survive.\n\nHow to play: Press `Start Game`. You start off with the Assault class, but can upgrade as your XP improves.\nTo open this menu again, press F3.\nThis window is only visible in the lobby.", "MainUIFont", 100, 50, Color(255, 255, 255))

			local Button = vgui.Create( "DButton", frame )
			Button:SetPos( 100, 300 )
			Button:SetSize( 200, 90 )
			Button:SetText( "Start Game" )
			Button:SetFont	( "MainUIFont" )
			Button.DoClick = function()
				RunConsoleCommand("rake_StartGame")
				frame:Close()
			end
			Button.Paint = function(self, w, h)
				draw.RoundedBox(10, 0, 0, w, h, Color(77, 77, 77))
			end
			Button:SetTextColor(Color(255, 255, 255))

		else
			frame:Close()
		end
end)

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

local function DrawMultilineText(text, font, x, y, color, align)
	surface.SetFont(font)

	local w, h = surface.GetTextSize(text)
	local y = y - h

	draw.DrawText(text, font, x, y, color, align)
end

net.Receive("startgamehud", function(len)
	if GetConVar("rake_GameState"):GetString() == "match" then return end
		if not frame then
			local frame = vgui.Create("DFrame")
			local width = ScrW() * 0.5
			local height = ScrH() * 0.5


			frame:SetSize(width, height)
			frame:SetTitle("The Rake by Kai D.")

			frame:SetVisible(true)
			frame:SetDraggable(false)
			frame:ShowCloseButton(true)
			frame:SetDeleteOnClose(true)

			frame.Paint = function(self, w, h)
				draw.RoundedBox(5, 0, 0, w, h, Color(68, 68, 68))
			end

			frame:Center()
			frame:MakePopup()

			local panel2 = vgui.Create( "DPanel", frame )
			panel2:Dock( FILL)
			panel2:DockMargin(0, 0, 0, 0)
			panel2.Paint = function(self, w, h)
				draw.RoundedBox(5, 0, 0, w, h, Color(68, 68, 68, 0))
			end

			DrawMultilineText("Welcome to the rake.", "MainUIFont", 10, 10, Color(255, 255, 255), 1)

			local startLabel = vgui.Create( "DLabel", frame )
			startLabel:SetText( "Click start to start the game" )
			startLabel:SetFont("MainUIFont")
			startLabel:SetPos(200, 100)
			startLabel:SetSize(500, 50)

			local Button = vgui.Create( "DButton", frame )
			Button:SetPos( 210, 150 )
			Button:SetText( "Start Game" )
			Button:Center()
			Button.DoClick = function()
				RunConsoleCommand("rake_StartGame")
				frame:Close()
			end
		else
			frame:Close()
		end
end)

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
	local ply = LocalPlayer()
		if not frame then
			local frame = vgui.Create("DFrame")
			local width = ScrW() * 0.8
			local height = ScrH() * 0.8

			local scrw = ScrW()
			local scrh = ScrH()


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

			DrawMultilineText(frame, "Welcome to the rake. A gamemode about\nsurvival and killing an anomaly\nknown as the rake.\n\nTo survive you must have teamwork,\nand a determination to survive.\n\nHow to play: Press `Start Game`. You start off with the Assault class, but can upgrade as your XP improves.\nTo open this menu again, press F3.", "MainUIFont", 100, 50, Color(255, 255, 255))

			local Button = vgui.Create( "DButton", frame )
			Button:SetPos( 100, 300 )
			Button:SetSize( scrw * 200 / 1920, scrh * 100 / 1080 )

			if ply:IsSuperAdmin() then
					if (GetConVar("rake_GameState"):GetString() == "lobby") then
						Button:SetText( "Start Game" )
					else
						Button:SetText( "End Current Game" )
					end

					Button:SetFont	( "MainUIFont" )
					Button.DoClick = function()
						if (GetConVar("rake_GameState"):GetString() == "lobby") then
							RunConsoleCommand("rake_StartGame")
						else
							RunConsoleCommand("rake_EndMatch")
						end

						frame:Close()
					end
					Button.Paint = function(self, w, h)
						draw.RoundedBox(10, 0, 0, w, h, Color(77, 77, 77))
					end
					Button:SetTextColor(Color(255, 255, 255))
			end

			local ClassPanelLabel = vgui.Create( "DLabel", frame )
			ClassPanelLabel:SetPos( frame:GetWide() * 0.75, frame:GetTall() * 0.02  )
			ClassPanelLabel:SetSize( scrw * 420 / 1920, scrh * 15 / 1080 )
			ClassPanelLabel:SetFont("MainUIFont")
			ClassPanelLabel:SetTextColor(Color(255, 255, 255))
			ClassPanelLabel:SetText("Owned Classes")

			local XPLabel = vgui.Create( "DLabel", frame )
			XPLabel:SetPos( frame:GetWide() * 0.77, frame:GetTall() -30  )
			XPLabel:SetSize( scrw * 420 / 1920, scrh * 15 / 1080 )
			XPLabel:SetFont("MainUIFont")
			XPLabel:SetTextColor(Color(255, 255, 255))
			XPLabel:SetText("XP: " .. ply:GetNWInt("XP"))

			local ClassPanel = vgui.Create( "DPanel", frame )
			ClassPanel:SetPos( frame:GetWide() * 0.65, frame:GetTall() * 0.05  )
			ClassPanel:SetSize( scrw * 420 / 1920, scrw * ( frame:GetTall() * 0.9 ) / 1080 )

			ClassPanel.Paint = function(self, w, h)
				draw.RoundedBox(6, 0, 0, w, h, Color(0, 0, 0, 240))
			end

			local grid = vgui.Create( "DGrid", ClassPanel )

			local inv = util.JSONToTable( ply:GetNWString("Inventory") )

			for k, v in pairs(inv["Classes"]) do
				local item = vgui.Create( "DButton", ClassPanel )

				item:SetText( k )

				item:SetSize( scrw * 150 / 1920, scrh * 100 / 1080 )

				item:SetFont	( "MainUIFont" )
				item:SetTextColor(Color(190, 190, 190))

				item.DoClick = function()
					net.Start("rake_BuyClass")
					net.WriteString(k)
					net.SendToServer()

					notification.AddLegacy("Changed class to " .. k, NOTIFY_GENERIC, 5)
				end

				item.Paint = function(self, w, h)
					draw.RoundedBox(20, 0, 0, w, h, Color(77, 77, 77))
				end

				grid:AddItem( item )
			end

			grid:SetPos( 5, 5 )
			grid:SetCols( 3 )
			grid:SetColWide( scrw * 150 / 1920 )
			grid:SetRowHeight( scrh * 100 / 1080 )

			grid:AddItem(  )
		else
			frame:Close()
		end
end)

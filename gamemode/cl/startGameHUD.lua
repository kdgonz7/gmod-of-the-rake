hook.Add("InitPostEntity", "StartGameHUD", function()
	local frame = vgui.Create("DFrame")
	frame:SetSize(1000, 750)
	frame:Center()
	frame:MakePopup()
	frame:SetVisible(true)
	local helloText = vgui.Create("DLabel", frame)
	helloText:SetPos(10, 55)
	helloText:SetSize(100, 500)
	helloText:SetWrap(true)
	helloText:SetText("Hello, " .. LocalPlayer():Nick() .. ", this is the RAKE! To start the game, you can type rake_StartGame in the console (as a superadmin), otherwise there should be a button if you don't close this panel out.")

	if LocalPlayer():IsSuperAdmin() then
		local startButton = vgui.Create("DButton", frame)
		startButton:SetPos(10, 40)
		startButton:SetSize(200, 45)
		startButton:SetText("Start Current Game")
		startButton.DoClick = function()
			RunConsoleCommand("rake_StartGame")
			frame:SetDeleteOnClose(true)
			frame:Close()
		end
	end
end)
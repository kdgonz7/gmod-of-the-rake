function DrawMultilineText(parent, text, font, x, y, color)
	text = string.Explode("\n", text)

	local offset = 0

	for _, v in ipairs(text) do
		local l = vgui.Create("DLabel", parent)

		l:SetFont(font)
		l:SetPos(x, y + offset)
		l:SetColor(color)
		l:SetText(v)
		l:SetWidth(1000)
		l:SizeToContents()  -- Adjust the size to fit the text


		offset = offset + l:GetTall()
	end
end

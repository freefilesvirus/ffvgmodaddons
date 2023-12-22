local prop = {}
prop.MenuLabel = "Make Invisible"
prop.Order = 1337

prop.Filter = function(self, ent)
	self.MenuLabel = "Make Invisible"
	self.MenuIcon = "materials/qvblink.png"
	if string.Split(tostring(ent:GetColor()), " ")[4] == "0" then
		self.MenuLabel = "Make Visible"
		self.MenuIcon = "materials/qveye.png"
	end
	return true
end

prop.Action = function(self, ent)
	self:MsgStart()
		net.WriteEntity(ent)
	self:MsgEnd()
end

prop.Receive = function(self, length, ply)
	local ent = net.ReadEntity()
	local color = string.Split(tostring(ent:GetColor()), " ")

	if color[4] == "0" then
		ent:SetColor(Color(color[1], color[2], color[3], 255))
	else
		ent:SetColor(Color(color[1], color[2], color[3], 0))
	end
	ent:SetRenderMode(RENDERMODE_TRANSCOLOR)
end

properties.Add("quickvisibility", prop)
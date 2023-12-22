AddCSLuaFile("skelify.lua")
include("skelify.lua")

local prop = {}
prop.MenuLabel = "Skelificate"
prop.Order = 9001

prop.Filter = function(self, ent)
	return qualify_skelify(ent, false)
end

prop.Action = function(self, ent)
	self:MsgStart()
		net.WriteEntity(ent)
	self:MsgEnd()
end

prop.Receive = function(self, length, ply)
	local ent = net.ReadEntity()
	skelify(ent, ply)
end

properties.Add("skelifier", prop)
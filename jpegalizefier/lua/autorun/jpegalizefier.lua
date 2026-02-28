require("jpegalizefier")

local jpegalizefy={}
jpegalizefy.MenuLabel="jpegalizefy"
jpegalizefy.MenuIcon="icon16/image.png"
jpegalizefy.Order=4343

jpegalizefy.Filter=function(self,ent)
	self.MenuLabel=jpegalizefier.GetJPEGalizefied(ent) and "unjpegalizefy" or "jpegalizefy"
	return IsValid(ent:GetNWEntity("jpegEntity")) or isfunction(ent.Draw) or isfunction(ent.DrawModel)
end

jpegalizefy.Action=function(self,ent)
	self:MsgStart()
	net.WriteEntity(ent)
	self:MsgEnd()
end

jpegalizefy.Receive=function(self,length,ply)
	local ent=net.ReadEntity()

	jpegalizefier.SetJPEGalizefied(ent,!jpegalizefier.GetJPEGalizefied(ent))
end

properties.Add("jpegalizefier",jpegalizefy)

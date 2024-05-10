AddCSLuaFile()

DEFINE_BASECLASS("popc_base")

ENT.Base = "popc_base"
ENT.Spawnable = true
ENT.Category = "Pop Cones"
ENT.PrintName = "Lamp"

ENT.usesConduit = true

ENT.light = nil

function ENT:setupParts()
	self:addPart("models/props_wasteland/prison_lamp001c.mdl",Vector(0,0,-6),Angle(0,0,180)):SetSkin(1)

	self.light = ents.Create("gmod_light")
	self.light:SetParent(self)
	self.light:SetLocalPos(Vector(0,0,24))
	self.light:SetColor(Color(255,255,255,255))
	self.light:SetOn(false)
end

function ENT:Think()
	BaseClass.Think(self)

	if CLIENT then return end

	local skin = self:GetPopped() and 0 or 1
	self.parts[1][1]:SetSkin(skin)

	local power = self:power()
	self.light:SetOn(self:GetPopped())
	self.light:SetBrightness(math.log(power)+1)
	self.light:SetLightSize(96+(96*power))
end

function ENT:OnEntityCopyTableFinish(data)
	BaseClass.OnEntityCopyTableFinish(self,data)

	data.light = nil
end

function ENT:extraRemove() if IsValid(self.light) then self.light:Remove() end end
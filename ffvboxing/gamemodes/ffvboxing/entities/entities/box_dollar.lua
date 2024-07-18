AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.changed = false
ENT.mat = Material("ffvboxing/dollar.png","noclamp smooth")

ENT.startTime = 0

ENT.velocity = Vector()

function ENT:Initialize()
	self:SetModel("models/hunter/plates/plate025x05.mdl")
	self:DrawShadow(false)

	self.startTime = CurTime()
end

function ENT:Think()
	if CLIENT then
		if ((not self.changed) and (not (self:GetNWString("image")==""))) then
			self.changed = true
			self.mat = Material("ffvboxing/"..self:GetNWString("image")..".png","noclamp smooth")
		end
		return
	end

	if ((((CurTime()-self.startTime)*-64)+255)<0) then self:Remove() end

	self:SetPos(self:GetPos()+self.velocity)
	self.velocity = (self.velocity*.99)
	self.velocity = (self.velocity-Vector(0,0,.06))

	self:NextThink(CurTime())
	return true
end

ENT.mat = Material("ffvboxing/dollar.png")
function ENT:Draw()
	local newang = Angle(0,EyeAngles().y-90,90)
	self:SetAngles(newang+Angle(90,0,0))
	cam.Start3D2D(self:GetPos(),newang,.1)
		surface.SetMaterial(self.mat)
		surface.SetDrawColor(255,255,255,math.Clamp(((CurTime()-self.startTime)*-128)+400,0,255))
		surface.DrawTexturedRect(-75,-32,150,64)
	cam.End3D2D()
end
AddCSLuaFile()

ENT.Base="base_anim"
ENT.Spawnable=false

ENT.PrintName="bot viewer"

local presets={
	{"models/props_c17/tv_monitor01.mdl",Vector(6,-9.2,5.9),Angle(0,90,90),15,10,.05},
	{"models/props_lab/monitor01a.mdl",Vector(11.7,-10,12),Angle(0,90,85.6),20,17,.1},
	{"models/props_lab/monitor01b.mdl",Vector(6.4,-5.83,5.3),Angle(0,90,90),12,12,.2,.8},
	{"models/props_phx/rt_screen.mdl",Vector(6,-28.5,36),Angle(0,90,90),57,34,0},
	{"models/props_combine/combine_intmonitor003.mdl",Vector(24,-17,49),Angle(0,90,90),34,46,.25}
}
ENT.preset=0
ENT.presetxy={}

function ENT:Initialize()
	if CLIENT or self.preset==0 then return end

	self:SetModel(presets[self.preset][1])
	self:PhysicsInit(SOLID_VPHYSICS)

	self:SetUseType(SIMPLE_USE)
end

function ENT:PostEntityPaste()
	self:Spawn()
	self:SetNWInt("preset",self.preset)
end

function ENT:Use(ply)
	local phys=self:GetPhysicsObject()
	if IsValid(phys) and phys:IsMotionEnabled() then ply:PickupObject(self) end
end

local error=Material("models/props_combine/combine_interface_disp")

local view=Material("a")
local overlay=Material("materials/probots/overlaysquare.png")

function ENT:Draw()
	self:DrawModel()

	local preset={}
	if self.preset==0 then
		if self:GetNWInt("preset")>0 then
			self.preset=self:GetNWInt("preset")
			preset=presets[self.preset]

			local dif=preset[5]/preset[4]
			local squish=preset[6]
			self.presetxy={squish/dif,(1-dif)/2+squish,1-(squish/dif),1-squish-((1-dif)/2)}
		else return end
	end
	local preset=presets[self.preset]

	local valid=false
	local target=self:GetNWEntity("target")
	if target~=nil and IsValid(target)then
		valid=true
		target:updateRt()
		view:SetTexture("$basetexture",target.rt)
	end

	local ang=self:GetAngles()
	ang:RotateAroundAxis(self:GetUp(),90)
	ang:RotateAroundAxis(self:GetRight(),-90)
	cam.Start3D2D(self:LocalToWorld(preset[2]),self:LocalToWorldAngles(preset[3]),preset[7] or 1)
	if valid then
		surface.SetDrawColor(255,255,255,255)
		for _,v in pairs({view,overlay}) do
			surface.SetMaterial(v)
			surface.DrawTexturedRectUV(0,0,preset[4],preset[5],unpack(self.presetxy))
		end
	else
		surface.SetDrawColor(255,255,255,255)
		surface.SetMaterial(error)
		surface.DrawTexturedRect(0,0,unpack(preset,4,5))
	end
	cam.End3D2D()
end
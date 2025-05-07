AddCSLuaFile()

ENT.Base="base_anim"
ENT.Spawnable=false

ENT.PrintName="bot viewer"

function ENT:Initialize()
	if CLIENT then return end

	self:SetModel("models/props_c17/tv_monitor01.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)

	self:SetUseType(SIMPLE_USE)
end

function ENT:Use(ply)
	ply:PickupObject(self)
end

local error=Material("models/props_combine/combine_interface_disp")

local view=Material("a")
local overlay=Material("materials/ffvrobots/overlaysquare.png")

function ENT:Draw()
	self:DrawModel()

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
	cam.Start3D2D(self:GetPos()+(self:GetForward()*5)+(self:GetRight()*9.9)+(self:GetUp()*6.5),ang,2)
	if valid then
		surface.SetDrawColor(255,255,255,255)
		for _,v in pairs({view,overlay}) do
			surface.SetMaterial(v)
			surface.DrawTexturedRectUV(0,0,8,6,.1,.1,.9,.9)
		end
	else
		surface.SetDrawColor(255,255,255,255)
		surface.SetMaterial(error)
		surface.DrawTexturedRect(0,0,8,6)
	end
	cam.End3D2D()
end
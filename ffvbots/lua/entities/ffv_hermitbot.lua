AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "ffv_basebot"
ENT.PrintName = "Hermit Bot"
ENT.Spawnable = false

ENT.peek = 0

function ENT:tickThink()
	local phys = self:GetPhysicsObject()

	local bucket = self.parts[1]
	bucket:SetLocalPos(Vector(bucket:GetLocalPos().x-((bucket:GetLocalPos().x-(-6-(self.peek*2)))/6),0,8))
	bucket:SetLocalAngles(Angle(180,90,bucket:GetLocalAngles().z-(math.AngleDifference(bucket:GetLocalAngles().z,(self.peek*20))/6)))
end

function ENT:Initialize()
	if CLIENT then return end
	self:SetModel("models/props_wasteland/light_spotlight01_lamp.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)

	self:addPart("models/props_junk/MetalBucket02a.mdl",Vector(-6,0,8),Angle(180,90,0))
	self:addPart("models/props_vehicles/carparts_wheel01a.mdl",Vector(-16,0,-1),Angle(0,0,0),.3)
	self:addPart("models/props_c17/playground_teetertoter_stan.mdl",Vector(-5.5,0,-4),Angle(0,0,0),.7)

	self:makeLight(self)
end

-- list.Set("NPC","ffv_hermitbot",{
-- 	Name = "Hermit Bot",
-- 	Class = "ffv_hermitbot",
-- 	Category = "Robots"
-- })

if CLIENT then language.Add("ffv_hermitbot","Saw Bot") end
if SERVER then duplicator.RegisterEntityClass("ffv_hermitbot",function(ply,data) return end,nil) end
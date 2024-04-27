AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "ffv_basebot"
ENT.PrintName = "Skater Bot"
ENT.Spawnable = false

function ENT:tickThink()
	--adjust wheel pole
	local trace = util.TraceLine({
		start=self:GetPos(),
		endpos=self:GetPos()+(-self:GetUp()*120),
		filter=self
	})
	local pole = self.parts[1]
	pole:SetLocalPos(Vector(0,0,(-trace.Fraction*120)+24))

	--float
	if trace.Hit then
		local trace = util.TraceLine({start=self:GetPos(),endpos=self:GetPos()-Vector(0,0,999),filter=self})
		local pos = trace.HitPos+Vector(0,0,24)
		self:GetPhysicsObject():AddVelocity((self:GetPos()-pos)/4)
	end
end

function ENT:Initialize()
	if CLIENT then return end
	self:SetModel("models/props_borealis/bluebarrel001.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	--parts
	local pole = self:addPart("models/props_c17/signpole001.mdl",Vector(0,0,0),Angle(0,0,0))
	self:addPart("models/props_vehicles/tire001c_car.mdl",Vector(0,0,-10),Angle(0,90,0)):SetParent(pole)

	local lamp = self:addPart("models/props_wasteland/light_spotlight01_lamp.mdl",Vector(20,0,10),Angle(0,0,0))
	self:makeLight(lamp)
end

-- list.Set("NPC","ffv_skaterbot",{
-- 	Name = "Skater Bot",
-- 	Class = "ffv_skaterbot",
-- 	Category = "Robots"
-- })

if CLIENT then language.Add("ffv_skaterbot","Skater Bot") end
if SERVER then duplicator.RegisterEntityClass("ffv_skaterbot",function(ply,data) return end,nil) end
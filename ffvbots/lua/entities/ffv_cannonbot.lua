AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "ffv_basebot"
ENT.PrintName = "Cannon Bot"
ENT.Spawnable = false

ENT.lookVar = Vector(0,0,0)
ENT.lookVarSize = 1
ENT.lookTarget = nil

--0 is look around
--1 is shoot
ENT.state = 0

function ENT:delayedThink()
	--look
	self.lookVar:Random(-self.lookVarSize,self.lookVarSize)
end

function ENT:tickThink()
	local phys = self:GetPhysicsObject()

	--friction
	if self.grounded then
		phys:SetMaterial("gmod_ice")
		phys:SetVelocity(phys:GetVelocity()*.9)
		phys:SetAngleVelocity(phys:GetAngleVelocity()*.9)
	else
		phys:SetMaterial("metal")
	end

	--lamp look
	self.lookTarget = self.target
	local lamp = self.parts[9]
	local lookPos = self:GetPos()+(self:GetForward()*100)+(self:GetUp()*30)
	if ((IsValid(self.lookTarget) and lineOfSight(self,self.lookTarget)) and self.grounded) then
		self.lookVarSize = 4
		if self.lookTarget:IsPlayer() then
			lookPos = self.lookTarget:GetShootPos()-Vector(0,0,20)
		elseif (self.lookTarget:IsNPC() or self.lookTarget:IsNextBot()) then
			lookPos = self.lookTarget:WorldSpaceCenter()
		elseif self.lookTarget.isffvrobot then
			lookPos = self.lookTarget.parts[#self.lookTarget.parts]:GetPos()
		else
			lookPos = self.lookTarget:GetPos()
		end
	else
		self.lookVarSize = 20
	end
	if (not self.grounded) then
		lookPos = self:GetPos()+(self:GetUp()*100)
	end
	lookPos = lookPos+((self.lookVar/100)*(self:GetPos():Distance(lookPos)))
	local angoal = (lamp:GetPos()-lookPos):Angle()
	angoal = Angle(-angoal.x,angoal.y,angoal.z)+Angle(0,180,0)
	lamp:SetAngles(Angle(
		lamp:GetAngles().x-(math.AngleDifference(lamp:GetAngles().x,angoal.x)/6),
		lamp:GetAngles().y-(math.AngleDifference(lamp:GetAngles().y,angoal.y)/6),
		self:GetAngles().z
	))
	--body look
	if (IsValid(self.lookTarget) and (not self.goalPos)) then
		local look = math.NormalizeAngle(getRotated(self:GetPos()-self.lookTarget:GetPos(),-self:GetAngles()):Angle().y-180)
		phys:AddAngleVelocity(Vector(0,0,math.Clamp(look,-8,8)))
	end

	--weel
	if self.grounded then
		local wheelR = self.parts[1]
		local wheelL = self.parts[2]
		local vel = phys:GetVelocity()
		vel:Rotate(-self:GetAngles())
		wheelL:SetLocalAngles(wheelL:GetLocalAngles()-Angle(vel.x/30,0,0))
		wheelR:SetLocalAngles(wheelR:GetLocalAngles()+Angle(vel.x/30,0,0))
		local angVel = phys:GetAngleVelocity()
		wheelL:SetLocalAngles(wheelL:GetLocalAngles()+Angle(angVel.z/40,0,0))
		wheelR:SetLocalAngles(wheelR:GetLocalAngles()+Angle(angVel.z/40,0,0))
	end
end

function ENT:Initialize()
	if CLIENT then return end
	self:SetModel("models/props_c17/furnitureStove001a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	--parts
	self:addPart("models/props_wasteland/wheel01.mdl",Vector(0,34,9),Angle(0,0,0))
	self:addPart("models/props_wasteland/wheel01.mdl",Vector(0,-34,9),Angle(0,180,0))
	local sheild = self:addPart("models/props_phx/construct/windows/window_curve90x1.mdl",Vector(14,-14,20.5),Angle(0,135,0),.4)
	self:addPart("models/props_lab/filecabinet02.mdl",Vector(-1,14,27),Angle(90,0,0),.8)
	local cannon = self:addPart("models/Mechanics/gears/gear12x12_small.mdl",Vector(-1,25,30),Angle(0,0,90))
	self:addPart("models/props_c17/canister01a.mdl",Vector(-1,14,50),Angle(180,0,0)):SetParent(cannon)
	self:addPart("models/props_trainstation/trashcan_indoor001b.mdl",Vector(-1,14,80),Angle(),.7):SetParent(cannon)
	self:addPart("models/props_vehicles/tire001a_tractor.mdl",Vector(-1,14,90),Angle(90,0,0),.4):SetParent(cannon)
	
	local lamp = self:addPart("models/props_wasteland/light_spotlight01_lamp.mdl",Vector(0,-14,26),Angle(0,0,0))
	sheild:SetParent(lamp)
	self:makeLight(lamp)
end

-- list.Set("NPC","ffv_cannonbot",{
-- 	Name = "Cannon Bot",
-- 	Class = "ffv_cannonbot",
-- 	Category = "Robots"
-- })

if CLIENT then language.Add("ffv_cannonbot","Cannon Bot") end
if SERVER then duplicator.RegisterEntityClass("ffv_cannonbot",function(ply,data) return end,nil) end
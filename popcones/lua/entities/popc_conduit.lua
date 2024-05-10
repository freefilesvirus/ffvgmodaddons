AddCSLuaFile()

DEFINE_BASECLASS("popc_base")

ENT.Base = "popc_base"
ENT.Spawnable = true
ENT.Category = "Pop Cones"
ENT.PrintName = "Conduit"

ENT.thinkDelay = .2

ENT.target = nil
ENT.rope = nil

ENT.connected = false

ENT.loopSound = nil

ENT.lastPower = 1

function ENT:setupParts()
	self:addPart("models/props_c17/GasPipes006a.mdl",Vector(0,-4.5,10),Angle(0,90,0),1,false)

	self.loopSound = CreateSound(self,"ambient/energy/electric_loop.wav")
	self.loopSound:Play()
	self.loopSound:ChangeVolume(0)
end

local sparkSounds = {
	Sound("weapons/stunstick/spark1.wav"),
	Sound("weapons/stunstick/spark2.wav"),
	Sound("weapons/stunstick/spark3.wav")
}
function ENT:Think()
	BaseClass.Think(self)

	if CLIENT then return end

	if IsValid(self.rope) then self.rope:SetKeyValue("Slack",tostring(math.random(-20,20))) end
	if (self.connected and ((not IsValid(self.target)) or (not self.target:GetPopped()) or (not self:GetPopped()))) then self:detach()
	elseif self.connected then
		--if the power gets changed like in wiremod or whatever fix what its powering to the right power
		if (self.lastPower~=self:GetPower()) then
			self.target.conduitPower = self.target.conduitPower+self:GetPower()-self.lastPower
		end

		self.lastPower = self:GetPower()
	end

	if (not self:GetPopped()) then return end
	if (self.target==nil) then
		for k,v in pairs(ents.FindInSphere(self:GetPos(),80)) do
			if (v.ispopcone and v.usesConduit and v:GetPopped()) then
				--attach
				self.target = v
				self.connected = true

				v.conduitPower = v.conduitPower+self:GetPower()

				self:EmitSound(sparkSounds[math.random(3)])
				self.loopSound:ChangeVolume(1)
				self:spark()

				if IsValid(self.rope) then self.rope:Remove() end
				self.rope = constraint.CreateKeyframeRope(Vector(0,0,0),4,"cable/blue_elec",self,self,Vector(0,-9,36),0,v,Vector(0,0,16),0)

				self.lastPower = self:GetPower()
				return
			end
		end
	elseif (self:GetPos():DistToSqr(self.target:GetPos())>16384) then
		self:detach()
	end
end

function ENT:extraPop(popping)
	if (self.connected and IsValid(self.target) and (not popping)) then self:detach() end
end

function ENT:detach()
	if IsValid(self.target) then
		self.target.conduitPower = self.target.conduitPower-self:GetPower()
	end

	self.target = nil
	self.connected = false

	self:EmitSound(sparkSounds[math.random(3)])
	self.loopSound:ChangeVolume(0)
	self:spark()

	if IsValid(self.rope) then self.rope:Remove() end
end

function ENT:spark()
	local effectdata = EffectData()
	local pos = Vector(0,-9,36)
	pos:Rotate(self:GetAngles())
	effectdata:SetOrigin(self:GetPos()+pos)
	util.Effect("StunstickImpact",effectdata)
end

function ENT:extraRemove()
	if (self.target~=nil) then self:detach() end
	self.loopSound:Stop()
end

function ENT:OnEntityCopyTableFinish(data)
	BaseClass.OnEntityCopyTableFinish(self,data)

	data.target = nil
	data.rope = nil
end

AddCSLuaFile()

DEFINE_BASECLASS("popc_base")

ENT.Base = "popc_base"
ENT.Spawnable = true
ENT.Category = "Pop Cones"
ENT.PrintName = "Laser"

ENT.thinkDelay = .1

ENT.connections = {}

ENT.hitLast = false

function ENT:setupParts()
	self:addPart("models/props_trainstation/trainstation_post001.mdl",Vector(0,0,-15),Angle(0,0,0),.6,false)

	if (WireLib~=nil) then
		WireLib.CreateOutputs(self,{"Popped"})
		WireLib.CreateInputs(self,{"Popped"})
	end
end

local sparkSounds = {
	Sound("weapons/stunstick/spark1.wav"),
	Sound("weapons/stunstick/spark2.wav"),
	Sound("weapons/stunstick/spark3.wav")
}
local damageSounds = {
	Sound("player/pl_burnpain1.wav"),
	Sound("player/pl_burnpain2.wav"),
	Sound("player/pl_burnpain3.wav"),
}
function ENT:Think()
	BaseClass.Think(self)

	if CLIENT then return end
	if (not self:GetPopped()) then return end

	local newConnection = false
	--look for new lasers
	for k,v in pairs(ents.FindInSphere(self:GetPos(),128)) do
		if ((v~=self) and (v:GetClass()=="popc_laser") and (v:GetPopped())) then
			if (not (entInConnections(self,v) or entInConnections(v,self))) then
				--add to connections
				local rope = constraint.CreateKeyframeRope(Vector(0,0,0),12,"cable/redlaser",self,self,Vector(0,0,18),0,v,Vector(0,0,18),0)
				rope:SetKeyValue("Slack","-200")
				table.insert(self.connections,{v,rope})

				v:spark()

				newConnection = true
			end
		end
	end
	if newConnection then
		self:EmitSound(sparkSounds[math.random(3)])
		self:spark()
	end

	--fix lasers
	local toRemove = {}
	for k,v in pairs(self.connections) do
		local cone = v[1]
		if ((not IsValid(cone)) or (not cone:GetPopped()) or (self:GetPos():DistToSqr(cone:GetPos())>36864)) then
			if IsValid(v[2]) then v[2]:Remove() end
			if IsValid(v[1]) then v[1]:spark() end
			table.remove(self.connections,k)

			self:EmitSound(sparkSounds[math.random(3)])
			self:spark()
		end
	end

	--do damage
	for k,v in pairs(self.connections) do
		local pos1 = Vector(0,0,18)
		pos1:Rotate(self:GetAngles())
		pos1 = pos1+self:GetPos()

		local cone = v[1]
		if (not IsValid(cone)) then return end
		local pos2 = Vector(0,0,18)
		pos2:Rotate(cone:GetAngles())
		pos2 = pos2+cone:GetPos()

		if (not self.hitLast) then
			local trace = util.TraceHull({
				start=pos1,
				endpos=pos2,
				filter=function(ent)
					if ent.ispopcone then return false end

					local d = DamageInfo()
					d:SetDamage(2)
					d:SetAttacker(self)
					d:SetDamageType(DMG_DISSOLVE)

					ent:TakeDamageInfo(d)

					ent:SetVelocity((ent:GetPos()+pos1+((pos2-pos1)/2)):GetNormalized()*48)
					if (ent:IsNPC() or ent:IsNextBot() or ent:IsPlayer()) then
						ent:EmitSound(damageSounds[math.random(3)])
					end

					self.hitLast = true

					return false
				end,
				mins=Vector(-2,-2,-2),
				maxs=Vector(2,2,2)
			})
		else self.hitLast = false end
	end
end

function ENT:spark()
	local effectdata = EffectData()
	local pos = Vector(0,0,18)
	pos:Rotate(self:GetAngles())
	effectdata:SetOrigin(self:GetPos()+pos)
	util.Effect("StunstickImpact",effectdata)
end

function ENT:extraPop(popping)
	if popping then return end
	for k,v in pairs(self.connections) do
		if IsValid(v[2]) then v[2]:Remove() end
		if IsValid(v[1]) then v[1]:spark() end
	end
	self:spark()
	self.connections = {}
end

function ENT:extraRemove()
	for k,v in pairs(self.connections) do
		if IsValid(v[2]) then v[2]:Remove() end
	end
end

function entInConnections(ent,entIn)
	for k,v in pairs(entIn.connections) do
		if (v[1]==ent) then return true end
	end
	return false
end

function ENT:OnEntityCopyTableFinish(data)
	BaseClass.OnEntityCopyTableFinish(self,data)

	data.connections = nil
end

if SERVER then return end
language.Add("popc_laser","Laser")
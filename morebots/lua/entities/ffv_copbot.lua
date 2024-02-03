AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "ffv_basebot"
ENT.PrintName = "Cop Bot"
ENT.Spawnable = false

ENT.lookVar = Vector(0,0,0)
ENT.lookVarSize = 1
ENT.lookTarget = nil

ENT.groundVec = Vector(0,0,1)

ENT.eyeGoal = .2
ENT.eyePos = .2

ENT.lastFired = 0
ENT.fireRate = 1.2
ENT.gunRotGoal = .8
ENT.gunRot = .8

ENT.speed = 3
ENT.turnSpeed = 30

ENT.jumping = false

--0 is patrol
--1 is escort
--2 is attack
--3 is glare
ENT.state = 0

function ENT:delayedThink()
	--look
	self.lookVar:Random(-self.lookVarSize,self.lookVarSize)

	--remove goalpos if too high up
	if (self.goalPos and ((self:GetPos()-self.goalPos).z<-100)) then self.goalPos = nil end

	--jump if fallen
	if (((not self.grounded) and (not self.jumping)) and randomChance(4)) then
		self.jumping = true
		self:GetPhysicsObject():AddVelocity(Vector(0,0,200))
	end

	--look for target
	local candidates = {}
	local rank = {}
	local hostile = false
	for k,v in ipairs(ents.GetAll()) do
		if (v:IsPlayer() or (v:IsNPC() or v.isffvrobot)) then
			if (lineOfSight(self,v) and (v:GetPos():DistToSqr(self:GetPos())<360000)) then
				table.insert(candidates,v)
				local interest = self:lookTargetInterest(v)
				table.insert(rank,interest)
				if (interest==99) then hostile = true end
			end
		end
	end
	if (((not IsValid(self.target)) and randomChance(2)) or (hostile and (self.state~=2))) then self.target = candidates[weightedRandom(rank)] end

	local oldState = self.state
	if IsValid(self.target) then
		--escort player
		if self.target:IsPlayer() then self.state = 1 end
		if self.target:IsNPC() then
			--escort friendly npc
			if (self.target:Classify()<=3) then self.state = 1
			--attack mean npc
			else self.state = 2 end
		end
		--attack theiving hoardbot
		if ((self.target:GetClass()=="ffv_hoardbot") and IsValid(self.target.rope)) then self.state = 2 end
		--escort robot
		if (self.target.isffvrobot and ((not (self.target:GetClass()=="ffv_hoardbot")) and (not self.target:GetClass()=="ffv_copbot"))) then self.state = 1 end
		--glare at other
		if (((not self.target:IsPlayer()) and (not self.target:IsNPC())) and ((not self.target.isffvrobot) or (self.target:GetClass()=="ffv_hoardbot"))) then
			if (self.state~=2) then self.state = 3 end
		end
	--patrol if no target
	else self.state = 0 end
	if (self.state~=oldState) then self.goalPos = nil end

	--statestuff
	if (self.state==0) then
		--patrol
		self.speed = 3
		self.turnSpeed = 30
		self.eyeGoal = .2
		self.gunRotGoal = .8

		if (not self.goalPos) then
			if randomChance(6) then
				local trace = util.TraceLine({
					start=self:GetPos(),
					endpos=self:GetPos()+Vector(math.random(-300,300),math.random(-300,300),0),
					filter=self})
				self.goalPos = trace.HitPos
			end
		end
	elseif (self.state==1) then
		--escort
		if (self:GetPos():DistToSqr(self.target:GetPos())>160000) then self.speed = 12
		else self.speed = 3 end
		self.turnSpeed = 30
		self.eyeGoal = .2
		self.gunRotGoal = .4

		if (not self.goalPos) then
			if (randomChance(8) or (self:GetPos():DistToSqr(self.target:GetPos())>160000)) then
				local trace = util.TraceLine({
					start=self.target:GetPos(),
					endpos=self.target:GetPos()+Vector(math.random(-300,300),math.random(-300,300),0),
					filter={self,self.target}})
				self.goalPos = trace.HitPos
			end
		end

		--too far
		if ((self:GetPos():DistToSqr(self.target:GetPos())>640000) or ((self:GetPos()-self.target:GetPos()).z<-100)) then
			self.target = nil
		end
	elseif (self.state==2) then
		--attack
		--abandon if target isnt hostile somehow
		--also, what a line!
		if (((self.target:IsNPC() and (self.target:Classify()<=3)) or self.target:IsPlayer()) or (self.target.isffvrobot and (not self.target:GetClass()=="ffv_hoardbot"))) then
			self.state = 0
			self.target = nil
			return
		end

		self.speed = 12
		self.turnSpeed = 60
		self.eyeGoal = .4
		self.gunRotGoal = 0

		if (self:GetPos():DistToSqr(self.target:GetPos())>90000) then
			self.goalPos = self.target:GetPos()-((self.target:GetPos()-self:GetPos()):GetNormalized()*100)
		end
		if self.goalPos then
			self.gunRotGoal = .4
			self.eyeGoal = .2

			if (self:GetPos():DistToSqr(self.target:GetPos())<40000) then self.goalPos = nil end
		end

		--abandon hoardbot
		if ((self.target:GetClass()=="ffv_hoardbot") and (not IsValid(self.target.rope))) then self.target = nil return end
		--too far
		if ((self:GetPos():DistToSqr(self.target:GetPos())>160000) or ((self:GetPos()-self.target:GetPos()).z<-100)) then self.target = nil return end
	elseif (self.state==3) then
		--glare
		self.speed = 3
		self.turnSpeed = 30
		self.eyeGoal = .4
		self.gunRotGoal = .8

		self.goalPos = nil
		if randomChance(6) then
			self.target = nil
		end
	end
end

function ENT:tickThink()
	--friction things
	local phys = self:GetPhysicsObject()
	if self.grounded then
		phys:SetMaterial("gmod_ice")
		phys:SetVelocity(phys:GetVelocity()*.9)
		phys:SetAngleVelocity(phys:GetAngleVelocity()*.9)
	else
		phys:SetMaterial("metal")
	end

	--eyelid move
	self.eyePos = math.Approach(self.eyePos,self.eyeGoal,(self.eyePos-self.eyeGoal)/8)
	local eyelid = self.parts[#self.parts-1]
	val = math.Clamp(self.eyePos,.1,1)
	eyelid:SetLocalAngles(Angle(math.log10(val)*90,0,90))
	local forward = (math.log(val,2)*2)+11
	local height = (-math.pow(val,2)*11)+15
	eyelid:SetLocalPos(Vector(forward,0,height))
	--gun shoot recoil
	local gun = self.parts[3]
	local fraction = math.Clamp((CurTime()-self.lastFired)*2,0,1)
	gun:SetLocalPos(Vector(math.ease.OutBack(fraction)*8,-20,10))
	--gun rot
	self.gunRot = math.Approach(self.gunRot,self.gunRotGoal,(self.gunRot-self.gunRotGoal)/8)
	gun:SetLocalAngles(Angle(((self.gunRot+1)*90)+((math.ease.InOutBack(fraction)-1)*20),0,0))

	--lamp look
	self.lookTarget = self.target
	local lamp = self.parts[#self.parts-2]
	local lookPos = self:GetPos()+(self:GetForward()*100)+(self:GetUp()*30)
	if (IsValid(self.lookTarget) and lineOfSight(self,self.lookTarget)) then
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
	lookPos = lookPos+((self.lookVar/100)*(self:GetPos():Distance(lookPos)))
	local angoal = (lamp:GetPos()-lookPos):Angle()
	angoal = Angle(-angoal.x,angoal.y,angoal.z)+Angle(0,180,0)
	lamp:SetAngles(Angle(
		lamp:GetAngles().x-(math.AngleDifference(lamp:GetAngles().x,angoal.x)/6),
		lamp:GetAngles().y-(math.AngleDifference(lamp:GetAngles().y,angoal.y)/6),
		self:GetAngles().z
	))

	if (cvars.Number("ai_disabled")==0) then
		--body look
		if (IsValid(self.lookTarget) and (not self.goalPos)) then
			local look = math.NormalizeAngle(getRotated(self:GetPos()-self.lookTarget:GetPos(),-self:GetAngles()):Angle().y-180)
			phys:AddAngleVelocity(Vector(0,0,math.Clamp(look,-8,8)))
		end
		--fire gun
		if ((IsValid(self.target) and ((self.state==2) and (not self.goalPos))) and ((CurTime()>(self.lastFired+self.fireRate)) and lineOfSight(self,self.target,-.8))) then
			--good to fire
			self:EmitSound("weapons/shotgun/shotgun_fire7.wav")
			self.lastFired = CurTime()

			local firepos = self.parts[3]:GetPos()+(self:GetForward()*24)
			self:FireBullets({
				Attacker=self,
				Damage=4,
				Num=6,
				Spread=Vector(6,6,0),
				Src=firepos,
				Dir=self.target:WorldSpaceCenter()-firepos
			})
		end
	end

	--speeeeen
	if self.grounded then
		local wheelR = self.parts[1]
		local wheelL = self.parts[2]
		local vel = phys:GetVelocity()
		vel:Rotate(-self:GetAngles())
		wheelL:SetLocalAngles(wheelL:GetLocalAngles()+Angle(0,0,vel.x/30))
		wheelR:SetLocalAngles(wheelR:GetLocalAngles()+Angle(0,0,vel.x/15))
		local angVel = phys:GetAngleVelocity()
		wheelL:SetLocalAngles(wheelL:GetLocalAngles()-Angle(0,0,angVel.z/40))
		wheelR:SetLocalAngles(wheelR:GetLocalAngles()+Angle(0,0,angVel.z/20))
	end

	--correct rot when jumping
	if (self.jumping and (not self.grounded)) then
		local phys = self:GetPhysicsObject()
		phys:AddAngleVelocity(Vector(math.Clamp(-self:GetAngles().z,-10,10),math.Clamp(-self:GetAngles().x,-10,10),0))
	end
	if self.grounded then self.jumping = false end
end

function ENT:OnTakeDamage(dmg)
	if (self.state~=2) then
		self.target = dmg:GetAttacker()
		self.state = 4
	end
end

function ENT:Use(ply)
	if ply:IsPlayer() then self.target = ply end
end

function ENT:PhysicsCollide(data,phys)
	local ent = data.HitEntity
	if (((not ent:IsWorld()) and (self.state~=2)) and (data.TheirOldVelocity:Length()>100)) then self.target = ent end

	self.jumping = false
end

function ENT:movement(pos)
	if (not self.grounded) then return end

	--curb
	local phys = self:GetPhysicsObject()
	local curbAllowance = 6
	local min,max = self:GetCollisionBounds()
	local tr = {
		start=self:GetPos()+getRotated(Vector(max.x+6,0,-max.z+curbAllowance),self:GetAngles()),
		endpos=self:GetPos()+getRotated(Vector(max.x+6,0,-max.z),self:GetAngles()),
		filter=self}
	local trace = util.TraceLine(tr)
	if ((tr.endpos.z-trace.HitPos.z)<-1) then
		phys:AddAngleVelocity(Vector(0,-self.turnSpeed,0))
		phys:AddVelocity((self:GetUp()*16)-(self:GetForward()*2))
	elseif (not trace.Hit) then phys:AddAngleVelocity(Vector(0,5,0)) end

	--look at goal
	local look = math.NormalizeAngle(getRotated(pos-self:GetPos(),-self:GetAngles()):Angle().y)
	local lookMod = math.abs(math.Clamp(math.abs(look/32),1,3)-3)
	phys:AddAngleVelocity(Vector(0,0,math.Clamp(look,-8,8)))

	--forward
	local x,z = self:GetAngles().x,self:GetAngles().z
	local rampMod = (((math.abs(z)>math.abs(x)) and z) or x)
	rampMod = (((rampMod<0) and math.abs(rampMod/10)) or 0)
	phys:AddVelocity(self:GetForward()*((self.speed*lookMod)+rampMod))

	if ((tr.endpos:DistToSqr(self.goalPos)<4000) or (self:GetPos():DistToSqr(self.goalPos)<4000)) then self.goalPos = nil end
end

function ENT:Initialize()
	if CLIENT then return end
	self:SetModel("models/props_lab/reciever_cart.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:GetPhysicsObject():SetMass(20)
	--parts
	self:addPart("models/props_vehicles/tire001c_car.mdl",Vector(0,-26,-24),Angle(0,90,0))
	self:addPart("models/props_vehicles/tire001b_truck.mdl",Vector(0,28,-14),Angle(0,90,0))
	local gun = self:addPart("models/props_c17/canister01a.mdl",Vector(0,0,0),Angle(90,0,0))
	self:addPart("models/props_c17/lampShade001a.mdl",Vector(26,0,0),Angle(270,0,0)):SetParent(gun)
	self:addPart("models/props_c17/pulleywheels_small01.mdl",Vector(-35,0,0),Angle(0,0,0)):SetParent(gun)
	self:addPart("models/props_junk/metal_paintcan001a.mdl",Vector(14,0,0),Angle(90,0,0),1.1):SetParent(gun)
	self:addPart("models/props_trainstation/traincar_rack001.mdl",Vector(-11,0,7),Angle(270,90,0),.28):SetParent(gun)
	gun:SetLocalPos(Vector(0,-20,10))
	local lamp = self:addPart("models/props_wasteland/light_spotlight01_lamp.mdl",Vector(16,4.4,40),Angle(0,0,0))
	local eyelid = self:addPart("models/props_debris/metal_panel02a.mdl",Vector(0,0,0),Angle(0,0,0),.4)
	eyelid:SetParent(lamp)
	self:makeLight(lamp)
end

function ENT:lookTargetInterest(ent)
	if ((ent:GetClass()=="ffv_hoardbot") and IsValid(ent.rope)) then return 99 end
	if ((ent:IsPlayer() and (cvars.Number("ai_ignoreplayers")==0)) or ent.isffvrobot) then return 1 end
	if ent:IsNPC() then
		if (ent:Classify()<=3) then return 1
		else return 99 end
	end
	return 0
end

list.Set("NPC","ffv_copbot",{
	Name = "Cop Bot",
	Class = "ffv_copbot",
	Category = "Robots"
})

if CLIENT then language.Add("ffv_copbot","Cop Bot") end
if SERVER then duplicator.RegisterEntityClass("ffv_copbot",function(ply,data) return end,nil) end
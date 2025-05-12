AddCSLuaFile()

ENT.Base = "pbot_base"
ENT.PrintName = "cop bot"
ENT.Spawnable = false

ENT.goalDistance=4000

ENT.maxHealth = 80
ENT.willFight = true
ENT.friendly = true

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

ENT.speed = 1
ENT.turnSpeed = 1

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
	if (((not self.grounded) and (not self.jumping)) and math.random(4)==1) then
		self.jumping = true
		self:GetPhysicsObject():AddVelocity(Vector(0,0,200))
	end

	--look for target
	local candidates = {}
	local rank = {}
	local hostile = false
	for k,v in ipairs(ents.GetAll()) do
		if ((v:IsPlayer() or v:IsNPC() or v.isProbot) and (not (v==self))) then
			if (self:lineOfSight(v)>0 and (v:GetPos():DistToSqr(self:GetPos())<360000)) then
				table.insert(candidates,v)
				local interest = self:lookTargetInterest(v)
				table.insert(rank,interest)
				if (interest==99) then hostile = true end
			end
		end
	end
	if (self.state~=2) then self.target = candidates[self.weightedRandom(rank)] end

	local oldState = self.state
	if IsValid(self.target) then
		--be nice to nice or mean to mean
		if self:getFriendly(self.target) then self.state = 1 
		else self.state = 2 end
		--attack theiving hoardbot
		if ((self.target:GetClass()=="pbot_hoardbot") and IsValid(self.target.rope)) then self.state = 2 end
		--glare at other
		if (((not self.target:IsPlayer()) and (not self.target:IsNPC())) and ((not self.target.isProbot) or (self.target:GetClass()=="pbot_hoardbot"))) then
			if (self.state~=2) then self.state = 3 end
		end
	--patrol if no target
	else self.state = 0 end
	if (self.state~=oldState) then self.goalPos = nil end

	--statestuff
	if (self.state==0) then
		--patrol
		self.speed = .8
		self.turnSpeed = 1
		self.eyeGoal = .2
		self.gunRotGoal = .8

		if (not self.goalPos) then
			if math.random(6)==1 then
				local trace = util.TraceLine({
					start=self:GetPos(),
					endpos=self:GetPos()+Vector(math.random(-300,300),math.random(-300,300),0),
					filter=self})
				self.goalPos = trace.HitPos
			end
		end
	elseif (self.state==1) then
		--escort
		if (self:GetPos():DistToSqr(self.target:GetPos())>160000) then self.speed = 2
		else self.speed = .8 end
		self.turnSpeed = 1
		self.eyeGoal = .2
		self.gunRotGoal = .4

		if (not self.goalPos) then
			if (math.random(8)==1 or (self:GetPos():DistToSqr(self.target:GetPos())>160000)) then
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
		if (((self.target:IsNPC() and self:getFriendly(self.target)) or (self.target.isProbot and (not self.target:GetClass()=="pbot_hoardbot")))) then
			self.state = 0
			self.target = nil
			return
		end

		self.speed = 2
		self.turnSpeed = 2
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
		if ((self.target:GetClass()=="pbot_hoardbot") and (not IsValid(self.target.rope))) then self.target = nil return end
		--too far
		if ((self:GetPos():DistToSqr(self.target:GetPos())>160000) or ((self:GetPos()-self.target:GetPos()).z<-100)) then self.target = nil return end
	elseif (self.state==3) then
		--glare
		self.speed = .8
		self.turnSpeed = 1
		self.eyeGoal = .4
		self.gunRotGoal = .8

		self.goalPos = nil
		if math.random(6)==1 then
			self.target = nil
		end
	end
end

function ENT:tickThink()
	local phys = self:GetPhysicsObject()

	--eyelid move
	self.eyePos = math.Approach(self.eyePos,self.eyeGoal,(self.eyePos-self.eyeGoal)/8)
	local eyelid = self.parts[#self.parts-2]
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
	local lamp = self.parts[#self.parts-1]
	local lookPos = self:GetPos()+(self:GetForward()*100)+(self:GetUp()*30)
	if (IsValid(self.lookTarget) and self:lineOfSight(self.lookTarget)>0) then
		self.lookVarSize = 4
		if self.lookTarget:IsPlayer() then
			lookPos = self.lookTarget:GetShootPos()-Vector(0,0,20)
		elseif (self.lookTarget:IsNPC() or self.lookTarget:IsNextBot()) then
			lookPos = self.lookTarget:WorldSpaceCenter()
		elseif self.lookTarget.isProbot then
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
		0--self:GetAngles().z
	))

	if (cvars.Number("ai_disabled")==0) then
		--body look
		if (IsValid(self.lookTarget) and (not self.goalPos)) then
			local lookPos=self:GetPos()-self.lookTarget:GetPos()
			lookPos:Rotate(-self:GetAngles())
			local look = math.NormalizeAngle(lookPos:Angle().y-180)
			phys:AddAngleVelocity(Vector(0,0,math.Clamp(look,-8,8)))
		end
		--fire gun
		if ((IsValid(self.target) and ((self.state==2) and (not self.goalPos))) and ((CurTime()>(self.lastFired+self.fireRate)) and self:lineOfSight(self.target)>.8)) then
			--good to fire
			self:EmitSound("weapons/shotgun/shotgun_fire7.wav")
			self.lastFired = CurTime()

			local firepos = self.parts[3]:GetPos()+(self:GetForward()*24)
			self:FireBullets({
				Attacker=self,
				Damage=10,
				Num=8,
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
		self.state=(self:getFriendly(dmg:GetAttacker()) and 3 or 2)
	end

	self.BaseClass.OnTakeDamage(self,dmg)
end

function ENT:Use(ply)
	if ply:IsPlayer() then self.target = ply end
end

function ENT:PhysicsCollide(data,phys)
	local ent = data.HitEntity
	if (((not ent:IsWorld()) and (self.state~=2)) and (data.TheirOldVelocity:Length()>100)) then self.target = ent end

	self.jumping = false
end

function ENT:pop()
	for k=3,7 do self.parts[k]:SetModelScale(.09) end
	local fakeGun=self.parts[3]
	local gun=ents.Create("ffv_copgun")
	gun:SetPos(fakeGun:GetPos())
	gun:SetAngles(fakeGun:GetAngles())
	gun:Spawn()

	self.BaseClass.pop(self)
end

function ENT:Initialize()
	if SERVER then
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
		local eyelid = self:addPart("models/props_debris/metal_panel02a.mdl",Vector(0,0,0),Angle(0,0,0),.4)
		local lamp = self:addPart("models/props_wasteland/light_spotlight01_lamp.mdl",Vector(16,4.4,40),Angle(0,0,0))
		eyelid:SetParent(lamp)
		self:makeLight(lamp)
	end

	self.BaseClass.Initialize(self)
end

function ENT:lookTargetInterest(ent)
	if ((ent:GetClass()=="pbot_hoardbot") and IsValid(ent.rope)) then return 99 end
	if (ent:IsPlayer() and (not (ent:Alive() and (cvars.Number("ai_ignoreplayers")==0)))) then return 0 end
	if (ent:IsNPC() or ent:IsPlayer() or ent.isProbot) then
		if (self:getFriendly(ent)) then return 1
		else return 99 end
	end
	return 0
end

list.Set("NPC","pbot_copbot",{
	Name=ENT.PrintName,
	Class="pbot_copbot",
	Category="probots"
})
if CLIENT then language.Add("pbot_copbot",ENT.PrintName) end
AddCSLuaFile()

ENT.Base = "ffv_basebot"
ENT.PrintName = "skater bot"
ENT.Spawnable = false

ENT.lastGroundTrace=nil

ENT.leanGoal=Vector(0,0,0)

ENT.height=112
ENT.duck=false

ENT.jumping=false

ENT.lampGoal=0
ENT.lampVary=0

ENT.speed=2

ENT.toRetreat=Vector(0,0,0)

--0 idle
--1 go interest
--2 run to player to drop
--3 run away
ENT.state=0

ENT.willFight=true
ENT.friendly=false

function ENT:fixPole()
	local trace=util.TraceLine({
		start=self:GetPos(),
		endpos=self:GetPos()+(-self:GetUp()*120),
		filter=self
	})
	self.parts[1]:SetLocalPos(Vector(0,0,24-(trace.Fraction*120)))

	return trace
end

function ENT:setGrounded()
	self.lastGroundTrace=self:fixPole()
	self.grounded=self.lastGroundTrace.Hit

	local angles=self:GetAngles()
	local badLean=-Vector(angles.z,angles.x,0)
	if (badLean:LengthSqr()>2500) then self.grounded=false end

	if self.grounded then self.jumping=false end
end

function ENT:tickThink()
	local phys=self:GetPhysicsObject()
	--wheel

	local vel=phys:GetVelocity()
	vel:Rotate(-self:GetForward():Angle())
	self.parts[2]:SetAngles(self.parts[2]:GetAngles()+Angle(0,0,vel.x/20))

	--float
	phys:EnableGravity(not self.grounded)
	if self.grounded then
		local goal=(self.lastGroundTrace.HitPos.z-self:GetPos().z+self.height)
		if (math.abs(goal)<12) then
			goal=-phys:GetVelocity().z
		end
		phys:SetVelocity((phys:GetVelocity()*Vector(.96,.96,1))+Vector(0,0,math.Clamp(goal,-8,8)))

		--fix lean
		local angles=self:GetAngles()
		self.parts[4]:SetLocalAngles(Angle(0,(angles.z*2)+90,0))
		local badLean=-Vector(angles.z*2,angles.x,angles.z*3)
		phys:SetAngleVelocity(phys:GetAngleVelocity()*.9)
		if (badLean:LengthSqr()>100) then
			phys:AddAngleVelocity((badLean:GetNormalized()*6)-(badLean/48))

			local dir=Vector(angles.x*2,-angles.z/6,0)
			dir:Rotate(Angle(0,angles.y,0))
			phys:AddVelocity(dir/4)
		end
	end

	--crouch
	self.height=math.Clamp(self.height-(self.duck and .8 or -.4),64,112)

	if (not self.goalPos) then
		--look at whatever
		if self.target then self:lookAt(self.target) end
	end
	self.parts[15]:SetLocalAngles(LerpAngle(.1,self.parts[15]:GetLocalAngles(),Angle(self.lampGoal+self.lampVary,0,0)))

	--jump
	if self.jumping then
		local angles=self:GetAngles()
		local badLean=-Vector(angles.z*2,angles.x,angles.z*3)
		phys:SetAngleVelocity(phys:GetAngleVelocity()*.9)
		if (badLean:LengthSqr()>100) then phys:AddAngleVelocity(badLean:GetNormalized()*12) end
	end
end

function ENT:delayedThink()
	self:fixRelationships()

	--crouch
	local trace=util.TraceLine({
		start=self:GetPos(),
		endpos=(self:GetPos()+Vector(0,0,72)),
		filter=self
	})
	self.duck=trace.Hit
	if ((not self.duck) and self.goalPos) then
		local trace=util.TraceHull({
			start=self:GetPos(),
			endpos=(self:GetPos()-(((self:GetPos()-self.goalPos)*Vector(1,1,0)):GetNormalized()*312)),
			mins=self:OBBMins(),
			maxs=self:OBBMaxs(),
			filter=self
		})
		self.duck=trace.Hit
	end

	--jump
	if (not self.grounded) then
		local trace=util.TraceLine({
			start=self:GetPos(),
			endpos=(self:GetPos()-Vector(0,0,20)),
			filter=self
		})
		if trace.Hit then
			self.jumping=true
			self:GetPhysicsObject():AddVelocity(Vector(0,0,400))
		end
	end

	self.lampVary=math.Rand(-4,4)

	if self.target then
		if (self:GetPos():DistToSqr(self.target:GetPos())>1000000) then self.target=nil end
	end

	if (self.state==0) then
		self.speed=.8

		local hint=nil
		for k,v in pairs({1,8,16,4}) do
			if (not hint) then hint=sound.GetLoudestSoundHint(v,self:GetPos()) end
		end
		if hint then
			self.goalPos=hint.origin
			self.state=1

			return
		end

		--look around
		if randomChance(2) then
			local trace=util.TraceLine({
				start=self:GetPos(),
				endpos=(self:GetPos()+(self:GetForward()*Vector(400,400,0))),
				filter=self
			})
			if (trace.Fraction>.8) then
				self.goalPos=trace.HitPos
				return
			end
		end
		if (not self.goalPos) then
			--check in 6 directions for the clearest direction
			local poss={}
			local fractions={}
			local dir=Vector(60,0,0)
			for k=1,6 do
				dir:Rotate(Angle(0,20,0))

				local trace=util.TraceLine({
					start=self:GetPos(),
					endpos=(self:GetPos()+dir),
					filter=self
				})
				table.insert(poss,trace.HitPos)
				table.insert(fractions,trace.Fraction)
			end
			self.goalPos=poss[weightedRandom(fractions)]
		end
	elseif (self.state==1) then
		self.speed=1

		if (not self.goalPos) then
			self.state=0

			return
		elseif (((self:GetPos()*Vector(1,1,0)):DistToSqr(self.goalPos*Vector(1,1,0))<60000) and lineOfSight(self,self.goalPos)) then self.goalPos=nil end
	elseif (self.state==2) then
		self.speed=2

		if (not self.target) then
			self.state=0
			return
		end

		self.goalPos=self.target:GetPos()
		local dist=self:GetPos():DistToSqr(self.target:GetPos())
		if (dist<20000) then
			self.state=3
			self.target=nil

			local trace=util.TraceLine({
				start=self:GetPos(),
				endpos=(self:GetPos()+(self:GetForward()*Vector(400,400,0))),
				filter=self
			})
			self.goalPos=((trace.Fraction>.8) and trace.HitPos or self.toRetreat)
			self:grenade(2)

			return
		end

		--abort
		if (lineOfSight(self.target,self,-.94) and (dist>80000)) then
			self.state=0
		end
	elseif (self.state==3) then
		self.speed=3

		if (not self.goalPos) then
			self.state=0
		end
	elseif (self.state==4) then --agro
		self.speed=3

		if (not self.target) then
			self.state=0
			return
		end

		self.goalPos=self.target:GetPos()
		local dist=self:GetPos():DistToSqr(self.target:GetPos())
		if (dist<20000) then
			self.state=3
			self.target=nil

			local trace=util.TraceLine({
				start=self:GetPos(),
				endpos=(self:GetPos()+(self:GetForward()*Vector(400,400,0))),
				filter=self
			})
			self.goalPos=((trace.Fraction>.8) and trace.HitPos or self.toRetreat)
			self:grenade(2)

			return
		end
	end

	if (self.state<2) then
		local targets=self:enemiesInLOS()
		if istable(targets) then
			self.target=targets[1][weightedRandom(targets[2])]
			self.state=2
			self.toRetreat=self:GetPos()
		end
	end
end

function ENT:enemiesInLOS()
	local enemies={}
	local interests={}
	for k,v in ipairs(ents.FindInSphere(self:GetPos(),1600)) do
		if ((v:IsPlayer() or v:IsNPC() or v:IsNextBot() or v.isffvrobot) and lineOfSight(self,v:GetPos()) and (not self:getFriendly(v))) then
			local interest=self:getInterest(v)
			if (interest>0) then
				table.insert(enemies,v)
				table.insert(interests,interest)
			end
		end
	end

	if (#enemies==0) then return nil end
	return {enemies,interests}
end

function ENT:prePop()
	for k=1,math.random(4) do
		self:grenade(4+math.Rand(0,2))
	end
end

function ENT:getInterest(ent)
	if lineOfSight(ent,self,-.3) then return 0 end
	if ent:IsPlayer() then return 4 end
	return 1
end

function ENT:movement(pos)
	if ((not self.grounded) or self.jumping) then return end
	local phys=self:GetPhysicsObject()

	local lookMod=self:lookAt((pos*Vector(1,1,0))+Vector(0,0,self:GetPos().z))

	--forward
	if (self:GetAngles().x<20) then phys:AddAngleVelocity(Vector(0,math.Clamp((20-self:GetAngles().x)*3,0,30*self.speed*(math.Clamp(lookMod,.8,1)-.8)),0)) end

	--reached goal
	if ((self:GetPos()*Vector(1,1,0)):DistToSqr(self.goalPos*Vector(1,1,0))<600) then
		self.goalPos=nil
		self.lampGoal=0
	end
end

function ENT:lookAt(pos)
	if isentity(pos) then pos=((pos:IsPlayer() or pos:IsNPC()) and pos:GetShootPos() or pos:GetPos()) end

	self.lampGoal=-(self:GetPos()-pos):Angle().x

	local look=math.NormalizeAngle(getRotated(pos-self:GetPos(),-self:GetAngles()):Angle().y)
	local lookMod=-math.Clamp((math.abs(look)-120)/120,-1,0)
	local notLookMod=math.abs(lookMod-1)
	if (lookMod<.9) then self:GetPhysicsObject():AddAngleVelocity(Vector(-math.Clamp(look,-2,2)*4*math.Clamp(notLookMod,.2,.4),-notLookMod*4,look/8)) end

	return lookMod
end

function ENT:grenade(time)
	local grenadeProp = ents.Create("npc_grenade_frag")
	grenadeProp:SetPos(self.parts[14]:GetPos())
	grenadeProp:Spawn()
	grenadeProp:Input("SetTimer",nil,nil,time)
end

function ENT:extraInit()
	self:SetNWBool("friendly",false)
	self:fixRelationships()

	self:SetModel("models/props_borealis/bluebarrel001.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	--parts
	local pole = self:addPart("models/props_c17/signpole001.mdl",Vector(0,0,0),Angle(0,0,0))
	self:addPart("models/props_vehicles/tire001c_car.mdl",Vector(0,0,-10),Angle(0,90,0)):SetParent(pole)

	self:addPart("models/props_c17/pulleywheels_small01.mdl",Vector(0,0,-30),Angle(90,0,0))
	local fin=self:addPart("models/props_interiors/refrigeratorDoor02a.mdl",Vector(-10,0,10),Angle(0,90,0))
	self:addPart("models/props_c17/metalladder002b.mdl",Vector(14,0,20),Angle(0,0,180),.7)
	self:addPart("models/props_wasteland/controlroom_filecabinet001a.mdl",Vector(2,0,12),Angle(0,180,0))
	local pipe=self:addPart("models/props_c17/GasPipes006a.mdl",Vector(-5,-15,6),Angle(0,0,180))
	constraint.CreateKeyframeRope(Vector(0,0,0),2,"cable/cable2",nil,fin,Vector(0,15,-8),0,pipe,Vector(-6,0,25),0,{["Slack"]=160})
	self:addPart("models/props_junk/CinderBlock01a.mdl",Vector(-10,0,10),Angle(0,90,0))
	self:addPart("models/props_junk/propane_tank001a.mdl",Vector(0,-14,3),Angle(0,0,180))

	for k=0,2 do self:addPart("models/props_wasteland/panel_leverHandle001a.mdl",Vector(0,0,-10),Angle((30*(k-1))+3,0,0),1.7):SetParent(pole) end
	self:addPart("models/props_junk/PopCan01a.mdl",Vector(0,0,-10),Angle(0,0,90),1.4):SetParent(pole)

	self:addPart("models/props_junk/garbage_coffeemug001a.mdl",Vector(16,0,0),Angle(0,-90,180),1.6)

	local lamp = self:addPart("models/props_wasteland/light_spotlight01_lamp.mdl",Vector(20,0,10),Angle(0,0,0))
	self:makeLight(lamp)
end

function ENT:extraTakeDamage(info)
	local attacker=info:GetAttacker()
	if ((attacker~=nil) and (self.state<3)) then
		self.target=attacker
		self.goalPos=attacker:GetPos()
		self.state=4
	end
end

list.Set("NPC","ffv_skaterbot",{
	Name=ENT.PrintName,
	Class="ffv_skaterbot",
	Category="robots"
})
if CLIENT then language.Add("ffv_skaterbot",ENT.PrintName) end
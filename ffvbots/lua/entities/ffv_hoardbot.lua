AddCSLuaFile()

ENT.Base = "ffv_basebot"
ENT.PrintName = "Hoarding Bot"
ENT.Spawnable = false

ENT.state = 0

ENT.touchingGround = true

ENT.rope = nil
ENT.realMass = 0
ENT.lookTarget = nil
ENT.lookVar = Vector(0,0,0)
ENT.lookVarSize = 1

ENT.neck = 1
ENT.neckSpeed = 6

ENT.backing = false
ENT.ignorePathing = false
ENT.turnSpeed = 10
ENT.speed = 7

function ENT:preThink() if (not IsValid(self.lookTarget)) then self.lookTarget = false end end
function ENT:delayedThink()
	--look around
	self.lookVar:Random(-self.lookVarSize,self.lookVarSize)

	--state stuff
	local wanderRange = 300
	local protectRange = 90000 --300 hu
	local cautiousRange = 1000000 --1000 hu
	local hoardmarker = ents.FindByClass("ffv_hoardmarker")[1]
	if (self.state==0) then
		--wander around near hoard

		self.backing = false
		self.speed = 5
		self.turnSpeed = 10
		self.ignorePathing = false
		self.neck = 1

		self.lookTarget = hoardmarker
		if ((not self.goalPos) and randomChance(8)) then
			self.goalPos = hoardmarker:GetPos()+Vector(
				math.random(-wanderRange,wanderRange),
				math.random(-wanderRange,wanderRange),0)
			local trace = util.TraceLine({
				start = self:GetPos(),
				endpos = self.goalPos,
				filter = self
			})
			self.goalPos = trace.HitPos
		end
		--look for players
		local closePlayers = {}
		for k,v in ipairs(ents.GetAll()) do
			if self:qualifyAttack(v) then
				local dist = hoardmarker:GetPos():DistToSqr(v:GetPos())
				if (dist<protectRange) then table.insert(closePlayers,v) end
			end
		end
		if (#closePlayers>0) then
			--attack
			self.target = closePlayers[math.random(#closePlayers)]
			self.state = 1
			self.goalPos = false
		end
		--go and find more props
		if ((#closePlayers==0) and randomChance(6)) then
			self.state = 2
			self.target = nil
		end
	elseif (self.state==1) then
		--ram into target

		if (not self.target) then self.state = 3 return end

		self.turnSpeed = 20
		self.lookTarget = self.target

		local vec = Vector(-40,0,0)
		vec:Rotate(self:GetAngles())
		local trace = util.TraceLine({
			start = self:GetPos(),
			endpos = self:GetPos()+vec,
			filter = self
		})
		if (((self:GetPos():DistToSqr(self.target:GetPos())<20000) and (not self.goalPos)) and (not trace.Hit)) then
			self.speed = 4
			self.backing = true
			self.neck = 1
		else
			self.speed = 40
			self.backing = false
			self.ignorePathing = true
			self.neck = .2
			self.goalPos = self.target:GetPos()+((self:GetPos()-self.target:GetPos()):GetNormalized()*-20)
		end
		--abandon attack
		local dist = hoardmarker:GetPos():DistToSqr(self.target:GetPos())
		if (self.target:IsPlayer() and (self.target:Health()<1)) then self.state = 3 end
		if (dist>cautiousRange) then self.state = 3 end
		if ((dist>protectRange) and randomChance(4)) then self.state = 3 end
		if (self.state==3) then self.goalPos = hoardmarker:GetPos() end
	elseif (self.state==2) then
		--find props

		self.speed = 10

		if (not self.target) then self.lookTarget = nil
		else self.lookTarget = self.target end

		if (not self.goalPos) then
			--look for nearby qualifying props
			local potentialTargets = {}
			for k,v in ipairs(ents.GetAll()) do
				if self:qualifyTarget(v) then table.insert(potentialTargets,v) end
			end
			if (#potentialTargets>0) then
				self.target = potentialTargets[math.random(#potentialTargets)]
				self.goalPos = self.target:GetPos()
			end
		end

		--wander for props
		if (not self.goalPos) then
			self.goalPos = self:GetPos()+Vector(
				math.random(-wanderRange,wanderRange),
				math.random(-wanderRange,wanderRange),0)
		end
		local trace = util.TraceLine({
			start = self:GetPos(),
			endpos = self.goalPos,
			filter = self
		})
		self.goalPos = trace.HitPos

		--if a player is in hoard and line of sight, gitim!
		local closePlayers = {}
		for k,v in ipairs(ents.GetAll()) do
			if self:qualifyAttack(v) then
				local dist = hoardmarker:GetPos():DistToSqr(v:GetPos())
				if (dist<protectRange) then table.insert(closePlayers,v) end
			end
		end
		if (#closePlayers>0) then
			self.target = closePlayers[math.random(#closePlayers)]
			self.state = 1
			self.goalPos = false
		end

		--chance to abort and check home
		if randomChance(30) then self.state = 3 end
	elseif (self.state==3) then
		--run home

		self.speed = 30
		self.turnSpeed = 30
		self.goalPos = hoardmarker:GetPos()

		--if a player is in hoard and line of sight, gitim!
		local closePlayers = {}
		for k,v in ipairs(ents.GetAll()) do
			if self:qualifyAttack(v) then
				local dist = hoardmarker:GetPos():DistToSqr(v:GetPos())
				if (dist<protectRange) then table.insert(closePlayers,v) end
			end
		end
		if (#closePlayers>0) then
			self.target = closePlayers[math.random(#closePlayers)]
			self.state = 1
			self.goalPos = false
		end
	end
end

function ENT:tickThink()
	local phys = self:GetPhysicsObject()
	--detect on ground
	local min,max = self:WorldSpaceAABB()
	local trace = util.TraceLine({
		start = self:GetPos(),
		endpos = min-Vector(0,0,1),
		filter = self
	})
	self.touchingGround = trace.Hit

	--flip over if not grounded
	if ((not self.grounded) and self.touchingGround) then
		local vec = self:GetAngles()
		if (math.abs(vec.x)>10) then
			phys:AddAngleVelocity(Vector(0,math.AngleDifference(-vec.x,0)/3,0))
		end
		if (math.abs(vec.z)>10) then
			phys:AddAngleVelocity(Vector(math.AngleDifference(-vec.z,0)/3,0,0))
		end
		phys:AddVelocity(Vector(0,0,4))
	end

	--adjust neck
	local lamp = self.parts[6]
	local neckGoal = ((self.neck*40)-12)
	local neckDif = lamp:GetLocalPos().x-neckGoal
	lamp:SetLocalPos(Vector(math.Approach(lamp:GetLocalPos().x,neckGoal,neckDif/self.neckSpeed),0,10))

	--lamp look
	local lookPos = self:GetPos()+(self:GetForward()*100)
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
		self.lookVarSize = 30
	end
	lookPos = lookPos+((self.lookVar/100)*(self:GetPos():Distance(lookPos)))
	local angoal = (lamp:GetPos()-lookPos):Angle()
	angoal = Angle(-angoal.x,angoal.y,angoal.z)+Angle(0,180,0)
	lamp:SetAngles(Angle(
		lamp:GetAngles().x-(math.AngleDifference(lamp:GetAngles().x,angoal.x)/2),
		lamp:GetAngles().y-(math.AngleDifference(lamp:GetAngles().y,angoal.y)/2),
		lamp:GetAngles().z-(math.AngleDifference(lamp:GetAngles().z,angoal.z)/2)
	))

	--backing
	if self.backing then
		phys:AddVelocity(-self:GetForward()*self.speed)
	end

	--friction
	if self.touchingGround then phys:SetVelocity(phys:GetVelocity()*.9) end
	if self.touchingGround then phys:SetAngleVelocity(phys:GetAngleVelocity()*.9) end

	--spin da wheel
	if (self.grounded or self.touchingGround) then
		local wheelL = self.parts[3]
		local wheelR = self.parts[4]
		local vel = self:GetPhysicsObject():GetVelocity()
		vel:Rotate(-self:GetAngles())
		wheelL:SetLocalAngles(wheelL:GetLocalAngles()+Angle(0,0,vel.x/30))
		wheelR:SetLocalAngles(wheelR:GetLocalAngles()+Angle(0,0,vel.x/30))
		local angVel = self:GetPhysicsObject():GetAngleVelocity()
		wheelL:SetLocalAngles(wheelL:GetLocalAngles()-Angle(0,0,angVel.z/40))
		wheelR:SetLocalAngles(wheelR:GetLocalAngles()+Angle(0,0,angVel.z/40))
	end
end

function ENT:movement(pos)
	local phys = self:GetPhysicsObject()
	if self.goalPos then
		if (self:GetPos():DistToSqr(self.goalPos)<5000) then
			--reached goalpos
			self.goalPos = false
			if ((self.state==2) and (self.target and (self:GetPos():DistToSqr(self.target:GetPos())<14400))) then
				--rope target
				self.rope = constraint.Rope(
					self,self.target,
					0,0,
					Vector(25,0,45),
					Vector(0,0,0),
					120,0,0,3,
					"cable/rope",
					false,
					Color(255,255,255,255))
				self:EmitSound("npc/turret_floor/click1.wav")
				self.realMass = self.target:GetPhysicsObject():GetMass()
				self.target:GetPhysicsObject():SetMass(10)
				self.state = 3
			elseif (self.state==3) then
				--get home
				if (IsValid(self.rope)) then self.rope:Remove() self:EmitSound("npc/turret_floor/click1.wav") end
				if (IsValid(self.target)) then self.target:GetPhysicsObject():SetMass(self.realMass) end
				self.target = nil
				self.state = 0
			end
		else
			--face goal
			local angDif = math.AngleDifference((pos-self:GetPos()):Angle().y,self:GetAngles().y)
			phys:AddAngleVelocity(Vector(0,0,math.Clamp(angDif*4,-self.turnSpeed,self.turnSpeed)))
			--move forward if facing straight enough
			local speedMod = 1
			if (not self.grounded) then speedMod = 0 end
			if (not self.touchingGround) then speedMod = 0 end
			local alignment = math.abs(math.Clamp(math.abs(angDif)-90,-90,0))/90
			phys:AddVelocity(self:GetForward()*self.speed*alignment*speedMod)
		end
	elseif self.lookTarget then
		--face look target
		local angDif = math.AngleDifference((self.lookTarget:GetPos()-self:GetPos()):Angle().y,self:GetAngles().y)
		phys:AddAngleVelocity(Vector(0,0,math.Clamp(angDif*4,-self.turnSpeed,self.turnSpeed)))
	end

	--advanced curb technology
	local vec = Vector(30,0,-1)
	vec:Rotate(self:GetAngles())
	local trace = util.TraceLine({
		start = self:GetPos(),
		endpos = self:GetPos()+vec,
		filter = self
	})
	if (self.goalPos and trace.Hit) then
		phys:AddAngleVelocity(Vector(0,-40,0))
	end
end

function ENT:extraInit()
	self:SetModel("models/props_lab/kennel_physics.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:GetPhysicsObject():SetMaterial("gmod_ice")

	--add parts
	self:addPart("models/props_c17/FurnitureShelf001b.mdl",Vector(0,7.8,0),Angle(0,90,0))
	self:addPart("models/props_c17/FurnitureShelf001b.mdl",Vector(0,-7.8,0),Angle(0,90,0))
	self:addPart("models/props_c17/pulleywheels_large01.mdl",Vector(0,27,21),Angle(0,90,0))
	self:addPart("models/props_c17/pulleywheels_large01.mdl",Vector(0,-27,21),Angle(0,90,0))
	self:addPart("models/props_junk/propane_tank001a.mdl",Vector(10,0,45),Angle(20,90,90))
	local lamp = self:addPart("models/props_wasteland/light_spotlight01_lamp.mdl",Vector(-12,0,10),Angle(0,0,0))
	self:makeLight(lamp)

	--check for hoardmarker
	if (#ents.FindByClass("ffv_hoardmarker")==0) then
		local marker = ents.Create("ffv_hoardmarker")
		marker:SetPos(self:GetPos()-Vector(0,0,32))
		marker:Spawn()
	else
		self.state = 3
	end

	self:SetCustomCollisionCheck(true)
end

function ENT:extraTakeDamage(info)
	if ((self.state==1) and randomChance(6)) then
		self.state = 3
		self.target = nil
	elseif (self.state==2) then
		if randomChance(2) then
			self.state = 3
			self.target = nil
		end
	elseif (self.state==3) then
		if (IsValid(self.rope) and randomChance(3)) then
			self.rope:Remove() self:EmitSound("npc/turret_floor/click1.wav")
		end
	end
end

function ENT:extraRemove()
	if (#ents.FindByClass("ffv_hoardbot")==0) then
		hoardmarker = ents.FindByClass("ffv_hoardmarker")[1]
		if IsValid(hoardmarker) then hoardmarker:Remove() end
	end
end

function ENT:addPart(model,pos,ang)
	local part = ents.Create("prop_dynamic")
	part:SetModel(model)
	pos:Rotate(self:GetAngles())
	part:SetPos(self:GetPos()+pos)
	part:SetAngles(self:GetAngles()+ang)
	part:SetParent(self)
	table.insert(self.parts,part)

	return part
end

function ENT:qualifyTarget(ent)
	local hoardmarker = ents.FindByClass("ffv_hoardmarker")[1]
	if (ent:GetPos():DistToSqr(hoardmarker:GetPos())<90000) then return false end
	if (ent:GetPos():DistToSqr(self:GetPos())>1000000) then return false end
	if (not (ent:GetClass()=="prop_physics")) then return false end
	if (not ent:GetPhysicsObject():IsMotionEnabled()) then return false end
	--if (ent:GetPhysicsObject():GetMass()>300) then return false end
	return true
end

function ENT:qualifyAttack(ent)
	if (ent:GetClass()=="ffv_hoardbot") then return false end
	if (ent:GetClass()=="ffv_copbot") then return false end
	if (ent:IsPlayer() and (cvars.Number("ai_ignoreplayers")==0)) then return true end
	if ent.isffvrobot then return true end
	return false
end

hook.Add("ShouldCollide","hoardbotHoardCollision",function(ent1,ent2)
	if ((ent1:GetClass()=="ffv_hoardbot") and (ent2:GetClass()=="prop_physics")) then
		local hoardmarker = ents.FindByClass("ffv_hoardmarker")[1]
		return (not (ent2:GetPos():DistToSqr(hoardmarker:GetPos())<40000))
	end
end)

list.Set("NPC","ffv_hoardbot",{
	Name = "Hoarding Bot",
	Class = "ffv_hoardbot",
	Category = "Robots"
})

if CLIENT then language.Add("ffv_hoardbot","Hoarding Bot") end
if SERVER then duplicator.RegisterEntityClass("ffv_hoardbot",function(ply,data) return end,nil) end
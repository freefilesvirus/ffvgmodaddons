AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "ffv_basebot"
ENT.PrintName = "Janitor Bot"
ENT.Spawnable = false

ENT.plugAng = Angle(90,0,0)
ENT.plugPos = Vector(30,23,50)
ENT.plugLocal = true
ENT.plugSpeed = 8

ENT.hitBone = 0
ENT.welded = false
ENT.startElectrify = 0

ENT.jumping = false

--0 is look for body
--1 is go to body
--2 is dissolve body
ENT.state = 0

function ENT:delayedThink()
	--jump if fallen
	if (((not self.grounded) and (not self.jumping)) and randomChance(4)) then
		self.jumping = true
		self:GetPhysicsObject():AddVelocity(Vector(0,0,220))
	end

	--state stuff
	if (self.state==0) then
		--look for body
		self.plugLocal = true
		self.plugPos = Vector(30,23,50)
		self.plugAng = Angle(90,0,0)
		self.plugSpeed = 8

		--look for closest ragdoll
		local ragdoll = nil
		local distance = 360000
		for k,v in ipairs(ents.GetAll()) do
			local dist = v:GetPos():DistToSqr(self:GetPos())
			if (((v:GetClass()=="prop_ragdoll") and (not v.electrifying)) and (lineOfSight(self,v:GetPos()+Vector(0,0,20)) and (dist<360000))) then
				if (dist<distance) then
					ragdoll = v
					distance = dist
				end
			end
		end
		if ragdoll then
			self.target = ragdoll
			self.goalPos = ragdoll:GetPos()-((ragdoll:GetPos()-self:GetPos()):GetNormalized()*40)
			self.state = 1
		elseif (not self.goalPos) then
			--move somewhere
			if randomChance(6) then
				local trace = util.TraceLine({
					start=self:GetPos(),
					endpos=self:GetPos()+Vector(math.random(-300,300),math.random(-300,300),0),
					filter={self,self.parts[13]}})
				if trace.Hit then self.goalPos = trace.HitPos-((trace.HitPos-self:GetPos()):GetNormalized()*40)
				else self.goalPos = trace.HitPos end
			end
		end
	elseif (self.state==1) then
		--go to body
		self.plugLocal = true
		self.plugPos = Vector(30,23,50)
		self.plugAng = Angle(90,0,0)
		self.plugSpeed = 8

		if (not self.target) then
			self.state = 0
			self.goalPos = nil
			return
		end

		if ((self:GetPos()+getRotated(Vector(18,23,65),self:GetAngles())):DistToSqr(self.target:GetPos())<10000) then
			--prep for electrocution
			local trace = util.TraceLine({
				start=self:GetPos(),
				endpos=self.target:WorldSpaceCenter(),
				filter={self,self.parts[13]}
			})
			self.goalPos = nil
			self.plugLocal = false
			self.plugPos = trace.HitPos
			self.plugAng = ((self:GetPos()+getRotated(Vector(18,23,65),self:GetAngles()))-trace.HitPos):Angle()
			self.plugSpeed = 24
			self.welded = false
			self.hitBone = trace.PhysicsBone
			self.startElectrify = CurTime()
			self.state = 2
		else self.goalPos = self.target:GetPos()-((self.target:GetPos()-self:GetPos()):GetNormalized()*40) end
	elseif (self.state==2) then
		--dissolve body
		if (not self.target) then
			self.state = 0
			self.goalPos = nil
			return
		end
		if (CurTime()>(self.startElectrify+2)) then
			self.sounds[#self.sounds]:Stop()
			self.parts[13]:EmitSound("ambient/levels/labs/electric_explosion1.wav")
			self.state = 0
			self.target.electrifying = true
			MakeDissolver(self.target,self.target:GetPos(),self,0)
		end
	end
end

function ENT:tickThink()
	--friction
	local phys = self:GetPhysicsObject()
	if self.grounded then
		phys:SetMaterial("gmod_ice")
		phys:SetVelocity(phys:GetVelocity()*.9)
		phys:SetAngleVelocity(phys:GetAngleVelocity()*.9)
	else
		phys:SetMaterial("metal")
	end

	--lamp look
	local lamp = self.parts[14]
	local targetLook = 20
	if self.target then
		targetLook = (self.target:WorldSpaceCenter()-lamp:GetPos()):Angle().x
	end
	lamp:SetLocalAngles(Angle(lamp:GetLocalAngles().x-(math.AngleDifference(lamp:GetLocalAngles().x,targetLook)/8),0,90))

	--plug
	local plug = self.parts[13]
	if (not IsValid(plug)) then self:Remove() return end
	--plug pos
	local pos = self.plugPos
	if self.plugLocal then pos = getRotated(pos,self:GetAngles())+self:GetPos() end
	local plugphys = plug:GetPhysicsObject()
	plugphys:AddVelocity((plug:GetPos()-pos)*-self.plugSpeed)
	--plug rot
	local ang = self.plugAng
	plugphys:SetAngles(plug:GetAngles()+(Angle(
		math.AngleDifference(ang.x,plug:GetAngles().x),
		math.AngleDifference(ang.y,plug:GetAngles().y),
		math.AngleDifference(ang.z,plug:GetAngles().z))/2))
	--fix stuck plug
	if (((not plug:IsPlayerHolding()) and (not self:IsPlayerHolding())) and (plug:GetPos():DistToSqr(pos)>10000)) then plug:SetPos(pos) end
	--weld plug to body
	if ((not self.welded) and ((self.state==2) and (plug:GetPos():DistToSqr(pos)<30))) then
		plug:EmitSound("physics/flesh/flesh_squishy_impact_hard"..math.random(4)..".wav")
		table.insert(self.sounds,CreateSound(self.parts[13],"ambient/energy/electric_loop.wav"))
		self.sounds[#self.sounds]:Play()

		plug:SetPos(pos)
		constraint.Weld(plug,self.target,0,self.hitBone,0,true,false)
		self.welded = true
	end

	--lookit those wheels go!
	if self.grounded then
		local wheelL1 = self.parts[1]
		local wheelL2 = self.parts[2]
		local wheelR1 = self.parts[3]
		local wheelR2 = self.parts[4]
		local vel = phys:GetVelocity()
		vel:Rotate(-self:GetAngles())
		wheelL1:SetLocalAngles(wheelL1:GetLocalAngles()-Angle(0,0,vel.x/15))
		wheelL2:SetLocalAngles(wheelL2:GetLocalAngles()-Angle(0,0,vel.x/15))
		wheelR1:SetLocalAngles(wheelR1:GetLocalAngles()+Angle(0,0,vel.x/15))
		wheelR2:SetLocalAngles(wheelR2:GetLocalAngles()+Angle(0,0,vel.x/15))
		local angVel = phys:GetAngleVelocity()
		wheelL1:SetLocalAngles(wheelL1:GetLocalAngles()-Angle(0,0,angVel.z/20))
		wheelL2:SetLocalAngles(wheelL2:GetLocalAngles()-Angle(0,0,angVel.z/20))
		wheelR1:SetLocalAngles(wheelR1:GetLocalAngles()-Angle(0,0,angVel.z/20))
		wheelR2:SetLocalAngles(wheelR2:GetLocalAngles()-Angle(0,0,angVel.z/20))
	end

	--correct rot when jumping
	if (self.jumping and (not self.grounded)) then
		local phys = self:GetPhysicsObject()
		phys:AddAngleVelocity(Vector(math.Clamp(-self:GetAngles().z,-10,10),math.Clamp(-self:GetAngles().x,-10,10),0))
	end
	if self.grounded then self.jumping = false end
end

function ENT:movement(pos)
	if (not self.grounded) then return end
	local phys = self:GetPhysicsObject()

	local curbAllowance = 6
	local min,max = self:GetCollisionBounds()
	local tr = {
		start=self:GetPos()+getRotated(Vector(max.x+6,0,-max.z+curbAllowance),self:GetAngles()),
		endpos=self:GetPos()+getRotated(Vector(max.x+6,0,-max.z),self:GetAngles()),
		filter=self}
	local trace = util.TraceLine(tr)

	--look at goal
	local look = math.NormalizeAngle(getRotated(pos-self:GetPos(),-self:GetAngles()):Angle().y)
	local lookMod = math.abs(math.Clamp(math.abs(look/8),1,3)-3)
	phys:AddAngleVelocity(Vector(0,0,math.Clamp(look,-8,8)))

	--forward
	local x,z = self:GetAngles().x,self:GetAngles().z
	local rampMod = (((math.abs(z)>math.abs(x)) and z) or x)
	rampMod = (((rampMod<0) and math.abs(rampMod/10)) or 0)
	phys:AddVelocity(self:GetForward()*((2*lookMod)+rampMod))

	if ((tr.endpos:DistToSqr(self.goalPos)<600) or (self:GetPos():DistToSqr(self.goalPos)<600)) then self.goalPos = nil end
end

function ENT:PhysicsCollide(data,phys)
	self.jumping = false
end

function ENT:Initialize()
	if CLIENT then return end
	self:SetModel("models/props_wasteland/kitchen_stove002a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	--parts
	self:addPart("models/props_vehicles/apc_tire001.mdl",Vector(-14,-23,9),Angle(0,-90,0),.3)
	self:addPart("models/props_vehicles/apc_tire001.mdl",Vector(10,-23,9),Angle(0,-90,0),.3)
	self:addPart("models/props_vehicles/apc_tire001.mdl",Vector(-14,23,9),Angle(0,90,0),.3)
	self:addPart("models/props_vehicles/apc_tire001.mdl",Vector(10,23,9),Angle(0,90,0),.3)
	self:addPart("models/props_interiors/refrigeratorDoor01a.mdl",Vector(-2,-18,30),Angle(0,-90,0))
	self:addPart("models/props_interiors/refrigeratorDoor01a.mdl",Vector(-2,18,30),Angle(0,90,0))
	self:addPart("models/props_interiors/refrigeratorDoor01a.mdl",Vector(-19,0,30),Angle(0,180,0))
	self:addPart("models/props_trainstation/TrackSign03.mdl",Vector(-14,0,70),Angle(0,0,0))
	self:addPart("models/props_junk/metal_paintcan001a.mdl",Vector(-10,23,65),Angle(0,0,-90))
	self:addPart("models/props_borealis/door_wheel001a.mdl",Vector(-10,32,65),Angle(0,90,0))
	self:addPart("models/props_junk/propane_tank001a.mdl",Vector(0,23,65),Angle(90,0,0))
	self:addPart("models/props_wasteland/kitchen_counter001c.mdl",Vector(-2,0,11),Angle(0,0,180),.5)

	--plug
	local plug = ents.Create("ffv_corpseplug")
	plug:SetPos(self:GetPos()+getRotated(Vector(20,23,50),self:GetAngles()))
	plug:SetAngles(self:GetAngles()+Angle(90,0,0))
	plug:Spawn()
	table.insert(self.parts,plug)

	constraint.Rope(self,plug,0,0,Vector(18,23,65),Vector(10,0,0),100,0,0,3,"cable/cable2",false,Color(255,255,255))

	local lamp = self:addPart("models/props_wasteland/light_spotlight01_lamp.mdl",Vector(16,-18,76),Angle(20,0,90))
	self:makeLight(lamp)
end

function MakeDissolver( ent, position, attacker, dissolveType )
	--borrowed... from gmod wiki
    local Dissolver = ents.Create( "env_entity_dissolver" )
    timer.Simple(5, function()
        if IsValid(Dissolver) then
            Dissolver:Remove() -- backup edict save on error
        end
    end)

    Dissolver.Target = "dissolve"..ent:EntIndex()
    Dissolver:SetKeyValue( "dissolvetype", dissolveType )
    Dissolver:SetKeyValue( "magnitude", 0 )
    Dissolver:SetPos( position )
    Dissolver:SetPhysicsAttacker( attacker )
    Dissolver:Spawn()

    ent:SetName( Dissolver.Target )

    Dissolver:Fire( "Dissolve", Dissolver.Target, 0 )
    Dissolver:Fire( "Kill", "", 0.1 )

    return Dissolver
end

list.Set("NPC","ffv_corpsebot",{
	Name = "Janitor Bot",
	Class = "ffv_corpsebot",
	Category = "Robots"
})

if CLIENT then language.Add("ffv_corpsebot","Janitor Bot") end
if SERVER then duplicator.RegisterEntityClass("ffv_corpsebot",function(ply,data) return end,nil) end
AddCSLuaFile()
AddCSLuaFile("wiki_astar.lua")
include("wiki_astar.lua")

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.Spawnable = true

ENT.parts = {}
ENT.sounds = {}
ENT.lastThink = 0
ENT.target = nil

ENT.lookVar = Vector(0,0,0)
ENT.lookVarSize = 1

ENT.forward = 1
ENT.goalAngle = false
ENT.goalPos = false
ENT.moveSpeed = 6.5

ENT.grounded = false

function ENT:Think()
	if CLIENT then return end
	if (IsValid(self.target) and (not self:qualifyLook(self.target))) then self.target = nil end
	if ((CurTime()-self.lastThink)>1) then
		--ticks every second
		local size = self.lookVarSize
		if randomChance(2) then self.lookVar:Random(-size,size) end
		--checks if fell over
		self.grounded = math.abs(self:GetAngles().z)<40
		--no one looking shenanigans
		local looking = false
		for k,v in ipairs(player.GetAll()) do
			local dif = (v:GetShootPos()-self:GetPos()):GetNormalized()
			dif:Rotate(-v:EyeAngles())
			if (v:Visible(self) and (dif.x+1<1)) then looking = true end
		end
		if (not looking) then
			--get up when no ones looking
			if (not self.grounded) then
				self:SetAngles(Angle(0,0,0))
			end
			--fratricide
			if (IsValid(self.target) and ((self.target:GetClass()=="ffv_watchbot") and randomChance(2000))) then
				local barrel = ents.Create("prop_physics")
				barrel:SetModel("models/props_c17/oildrum001.mdl")
				barrel:Spawn()
				barrel:SetPos(self.target:GetPos())
				barrel:SetAngles(self.target:GetAngles())
				self.target:Remove()
				self.target = barrel
				--screenshot
				self:EmitSound("npc/scanner/scanner_photo1.wav")
				local light = self.parts[6]
				light:Input("TurnOff",nil,nil,true)
				timer.Simple(0.2,function()
					if (not IsValid(light)) then return end
					light:Input("TurnOn",nil,nil,true)
				end)
			end
		end
		--target stuff
		if IsValid(self.target) then
			--chance go to target
			if randomChance(3) then self.goalPos = self.target:GetPos() end
			--chance face target
			if ((IsValid(self.target) and randomChance(6)) and ((not self.goalAngle) and (not self.goalPos))) then
				local targetAngle = (self.target:GetPos()-self:GetPos()):Angle()
				local angDif = math.AngleDifference(self:GetAngles().y,targetAngle.y)
				if (not(((angDif>-10)and(angDif<10))or((angDif>170)or(angDif<-170)))) then
					--target is not within 20 degrees of either directly in front of or behind him
					self.goalAngle = targetAngle.y
				end
			end
			--chance to switch target to what targets looking at
			if (self.target:IsPlayer() or self.target:IsNPC()) then
				local trace = util.TraceLine({
					start=self.target:GetShootPos(),
					endpos=self.target:GetShootPos()+self.target:GetAimVector()*9999,
					filter=self.target
				})
				local changeChance = 1
				--far higher chance to look at the thing if its being shot at
				if (IsValid(self.target:GetActiveWeapon()) and ((CurTime()-self.target:GetActiveWeapon():LastShootTime())<.5)) then changeChance = 24 end
				if (IsValid(trace.Entity) and (self:qualifyLook(trace.Entity)) and (weightedRandom({self:getInterest(self.target)*2,changeChance})==2)) then
					self.target = trace.Entity
				end
			end
			--chance get bored
			if (weightedRandom({self:getInterest(self.target)*6,1})==2) then
				--chance to instantly look for something else
				if randomChance(4) then
					local candidates = {}
					local chances = {}
					local pos = self:GetPos()
					for k,v in ipairs(ents.GetAll()) do
						if ((self:Visible(v) and (pos:DistToSqr(v:GetPos())<422500)) and self:qualifyLook(v)) then
							table.insert(candidates,v)
							table.insert(chances,self:getInterest(v))
						end
					end
					self.target = candidates[weightedRandom(chances)]
				else
					self.target = nil
				end
			end

			if (self.target==nil) then return end
			--looks to see if target is still visible
			if (not self.parts[5]:Visible(self.target)) then
				--either go searching for a new target or look for old one
				if (weightedRandom({self:getInterest(self.target),6})==2) then
					--go find target
					self.goalPos = self.target:GetPos()
				else
					self.target = nil
				end
			end
		else
			--ramble the land
			if (randomChance(3) and (not self.goalPos)) then
				local trace = util.TraceLine({
					start=self:GetPos(),
					endpos=self:GetPos()+Vector(math.random(-300,300),math.random(-300,300),0),
					filter=self
				})
				self.goalPos = trace.HitPos
			end
			--look for something interesting
			if randomChance(10) then
				local candidates = {}
				local chances = {}
				local pos = self:GetPos()
				for k,v in ipairs(ents.GetAll()) do
					if ((self:Visible(v) and (pos:DistToSqr(v:GetPos())<422500)) and self:qualifyLook(v)) then
						table.insert(candidates,v)
						table.insert(chances,self:getInterest(v))
					end
				end
				self.target = candidates[weightedRandom(chances)]
			end
		end

		self.lastThink = CurTime()
	end

	--ticks every frame
	if (not IsValid(self.target)) then self.target = nil end
	--look stuff
	local latGear = self.parts[3]
	local longGear = self.parts[4]
	local targetPos
	if IsValid(self.target) then
		self.lookVarSize = 1
		if self.target:IsPlayer() then
			targetPos = self.target:GetShootPos()-Vector(0,0,20)
		elseif (self.target:IsNPC() or self.target:IsNextBot()) then
			targetPos = self.target:WorldSpaceCenter()
		elseif (self.target:GetClass()=="ffv_watchbot") then
			targetPos = self.target.parts[3]:GetPos()
		else
			targetPos = self.target:GetPos()
		end
	else
		self.lookVarSize = 30
		local vec = Vector(100*self.forward,0,0)
		vec:Rotate(self:GetAngles())
		targetPos = latGear:GetPos()+vec
	end
	if (not self.grounded) then
		self.lookVarSize = 0
		local vec = Vector(0,0,100)
		vec:Rotate(self:GetAngles())
		targetPos = latGear:GetPos()+vec
	end

	targetPos = targetPos+((self.lookVar/100)*(self:GetPos():Distance(targetPos)))
	local angoal = (targetPos-(latGear:GetPos())):Angle()
	local latDif = math.AngleDifference(latGear:GetAngles().y,angoal.y)
	local latSound = self.sounds[1]
	local longDif = math.AngleDifference(longGear:GetAngles().x,angoal.x)
	local longSound = self.sounds[2]
	if self.grounded then
		local preMove = latGear:GetLocalAngles()
		latGear:SetLocalAngles(latGear:GetLocalAngles()-Angle(0,latDif/8,0))
		latSound:ChangeVolume(math.Clamp(math.abs((preMove-latGear:GetLocalAngles()).y),0,1))
	end
	local preMove = longGear:GetLocalAngles()
	longGear:SetLocalAngles(longGear:GetLocalAngles()-Angle(longDif/8,0,0))
	longSound:ChangeVolume(math.Clamp(math.abs((preMove-longGear:GetLocalAngles()).x),0,1))

	--abort here if disable ai thinking is on
	if (cvars.Number("ai_disabled")==1) then
		self.target = nil
		self:NextThink(CurTime())
		return true
	end

	--wheel stuff
	if self.grounded then
		local wheelL = self.parts[1]
		local wheelR = self.parts[2]
		local vel = self:GetPhysicsObject():GetVelocity()
		vel:Rotate(-self:GetAngles())
		wheelL:SetLocalAngles(wheelL:GetLocalAngles()+Angle(0,0,vel.x/20))
		wheelR:SetLocalAngles(wheelR:GetLocalAngles()+Angle(0,0,vel.x/20))
		local angVel = self:GetPhysicsObject():GetAngleVelocity()
		wheelL:SetLocalAngles(wheelL:GetLocalAngles()-Angle(0,0,angVel.z/40))
		wheelR:SetLocalAngles(wheelR:GetLocalAngles()+Angle(0,0,angVel.z/40))
	end

	--movement stuff
	if self.goalPos then
		if (self:GetPos():DistToSqr(self.goalPos)<10000) then
			self.goalPos = false
			--chance to screenshot
			if randomChance(20) then
				self:EmitSound("npc/scanner/scanner_photo1.wav")
				local light = self.parts[6]
				light:Input("TurnOff",nil,nil,true)
				timer.Simple(0.2,function()
					if (not IsValid(light)) then return end
					light:Input("TurnOn",nil,nil,true)
				end)
			end
		else
			local nextPos = self.goalPos
			--see if theres pathfinding to do
			local path = AstarVector(self:GetPos(),self.goalPos)
			if istable(path) then
				nextPos = path[#path-1]:GetCenter()
			end
			--face target area before moving
			local targetAngle = (nextPos-self:GetPos()):Angle()
			local angDif = math.AngleDifference(self:GetAngles().y,targetAngle.y)
			if (math.AngleDifference(angDif+90,0)>0) then self.forward = 1 else self.forward = -1 end
			if (not(((angDif>-10)and(angDif<10))or((angDif>170)or(angDif<-170)))) then
				--not facing the right way
				self.goalAngle = targetAngle.y
			end
			if (not self.goalAngle) then
				--move when not turning
				local phys = self:GetPhysicsObject()
				if ((phys:GetVelocity()*Vector(1,1,0)):Length()<(self.moveSpeed*10)) then
					phys:AddVelocity(((nextPos-self:GetPos()):GetNormalized()*self.moveSpeed)*Vector(1,1,0))
					phys:AddAngleVelocity(Vector(0,self.moveSpeed*-6*self.forward),0)
				end
			end
		end
	end
	--angle stuff
	if self.goalAngle then
		if (math.abs(math.AngleDifference(self.goalAngle,self:GetAngles().y))>90) then
			--flip the goal angle 180 degrees cause he doesnt have a defined front or back
			local a = Angle(self.goalAngle+180,0,0)
			a:Normalize()
			self.goalAngle = a.x
			self.forward = self.forward*-1
		end
		local angDif = math.AngleDifference(self.goalAngle,self:GetAngles().y)
		self:GetPhysicsObject():SetAngleVelocity(Vector(0,0,-math.Clamp(angDif,-20,20)))
		--within 10 degrees of the target angle
		if ((math.abs(angDif))<2) then self.goalAngle = false end
	end

	self:NextThink(CurTime())
	return true
end

function ENT:Initialize()
	if CLIENT then return end
	self:SetModel("models/props_c17/oildrum001.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	--add parts
	self:addPart("models/props_c17/pulleywheels_small01.mdl",Vector(0,19,6),Angle(0,90,0))
	self:addPart("models/props_c17/pulleywheels_small01.mdl",Vector(0,-19,6),Angle(0,90,0))
	local latGear = self:addPart("models/Mechanics/gears2/gear_12t1.mdl",Vector(0,0,48),Angle(0,0,0))
	local longGear = self:addPart("models/Mechanics/gears2/gear_12t1.mdl",Vector(0,12,58),Angle(0,0,90))
	longGear:SetParent(latGear)
	local lamp = self:addPart("models/props_wasteland/light_spotlight01_lamp.mdl",Vector(10,0,56),Angle(0,0,0))
	lamp:SetParent(longGear)
	local light = ents.Create("env_projectedtexture")
	light:Spawn()
	light:SetParent(lamp)
	light:SetKeyValue("enableshadows",1)
	light:SetKeyValue("lightfov",40)
	light:SetKeyValue("lightcolor",Format("255 255 255 255",10000))
	light:Input("SpotlightTexture",nil,nil,"effects/flashlight001")
	light:SetLocalPos(Vector(4,0,0))
	light:SetLocalAngles(Angle(0,0,0))
	table.insert(self.parts,light)
	for k=1,2 do
		local sound = CreateSound(self,"ratchetloop.wav")
		sound:PlayEx(0,100)
		table.insert(self.sounds,sound)
	end
	local sound = CreateSound(self,"vehicles/diesel_loop2.wav")
	sound:PlayEx(.6,180)
	table.insert(self.sounds,sound)
end

function ENT:OnRemove()
	for k,v in pairs(self.parts) do v:Remove() end
	for k,v in pairs(self.sounds) do v:Stop() end
end

function ENT:OnTakeDamage(info)
	if (weightedRandom({self:getInterest(info:GetAttacker())+2,1})==1) then
		self.target = info:GetAttacker()
	end
	return 0
end
function ENT:PhysicsCollide(data,phys)
	if (data.HitEntity==game.GetWorld()) then return end
	if (weightedRandom({self:getInterest(data.HitEntity)+2,1})==1) then
		self.target = data.HitEntity
	end
end
function ENT:Use(activator)
	self.target = activator
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

function ENT:getInterest(ent)
	if ent:IsPlayer() then return 6 end
	if (ent:GetClass()=="ffv_watchbot") then return 5 end
	if ent:IsNPC() then return 3 end
	if ent:IsRagdoll() then return 3 end
	if ent:IsVehicle() then return 2 end
	return 1
end

function ENT:qualifyLook(ent)
	if ent:IsWeapon() then return false end
	if (ent==self) then return end
	if (ent:GetClass()=="prop_physics") then return true end
	if (ent:GetClass()=="ffv_watchbot") then return true end
	if ent:IsPlayer() then
		if (cvars.Number("ai_ignoreplayers")==1) then return false end
		return true
	end
	if ent:IsRagdoll() then return true end
	if ent:IsVehicle() then return true end
	if ent:IsNPC() then return true end
	if ent:IsNextBot() then return true end
	--nepotism
	if string.StartsWith(ent:GetClass(),"ffv_") then return true end
	return false
end

function randomChance(chance)
	if (math.random(chance)==1) then return true end
	return false
end

function weightedRandom(chances)
	--table format: {chance,chance,chance}
	--example {5,1} has a 5/6 chance of returning 1 and 1/6 chance of returning 2
	local drawTable = {}
	for k,v in pairs(chances) do
		for i=1,v do
			table.insert(drawTable,k)
		end
	end
	return drawTable[math.random(#drawTable)]
end

list.Set("NPC","ffv_watchbot",{
	Name = "Observation Bot",
	Class = "ffv_watchbot",
	Category = "Robots"
})
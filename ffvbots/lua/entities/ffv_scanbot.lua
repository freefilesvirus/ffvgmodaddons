--COOL IDEA BY seabazian ON STEAM!!!
--profile is private but i promised to link profiles that give idea i make into robot
--https://steamcommunity.com/profiles/76561199072326561

AddCSLuaFile()
ENT.Base = "ffv_basebot"
ENT.PrintName = "scan bot"
ENT.Spawnable = false

ENT.lookVar = Vector(0,0,0)
ENT.lookTarget = nil

ENT.jumping = false

ENT.hologram = nil
ENT.showHologram = false

ENT.slideVar = 0

ENT.scanning=false
ENT.clearScan=0
ENT.lastScanned=nil
ENT.startHologram=0

local scanSounds = {
	Sound("buttons/combine_button1.wav"),
	Sound("buttons/combine_button2.wav"),
	Sound("buttons/combine_button3.wav"),
	Sound("buttons/combine_button5.wav"),
	Sound("buttons/combine_button7.wav"),
	Sound("buttons/combine_button_locked.wav")
}

function ENT:OnEntityCopyTableFinish(data)
	self.BaseClass.OnEntityCopyTableFinish(self,data)
	data.hologram=nil
end

function ENT:extraInit()
	if CLIENT then return end
	self:SetModel("models/props_c17/furnitureStove001a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:addPart("models/props_lab/reciever01b.mdl",Vector(8,-16,23),Angle(0,0,0))
	self:addPart("models/props_wasteland/prison_lamp001c.mdl",Vector(8,-16,26),Angle(0,0,180)):SetSkin(1)
	self:addPart("models/props_wasteland/prison_lamp001c.mdl",Vector(-8,-16,42),Angle(270,0,0)):SetSkin(1)
	self:addPart("models/props_c17/computer01_keyboard.mdl",Vector(10,11,20),Angle(0,0,0))
	self:addPart("models/props_lab/tpplug.mdl",Vector(-11.5,-16,17),Angle(270,0,0))
	self:addPart("models/props_c17/GasPipes006a.mdl",Vector(-10,-16,17),Angle(0,180,0))
	self:addPart("models/props_c17/GasPipes006a.mdl",Vector(-7,4,27),Angle(0,270,0))
	self:addPart("models/props_c17/GasPipes006a.mdl",Vector(-11,-1,14),Angle(0,270,0))
	self:addPart("models/props_c17/GasPipes006a.mdl",Vector(-15,0,20),Angle(0,270,0))
	self:addPart("models/props_trainstation/payphone001a.mdl",Vector(-13,11,20),Angle(0,0,0))
	self:addPart("models/props_lab/lockerdoorleft.mdl",Vector(-6,11.5,22),Angle(0,0,0))
	self:addPart("models/items/car_battery01.mdl",Vector(-11,18,47),Angle(0,180,90))
	self:addPart("models/items/car_battery01.mdl",Vector(-11,18,30),Angle(0,180,90))

	self:addPart("models/props_c17/pulleywheels_small01.mdl",Vector(11,29,-13),Angle(0,90,0),.8)
	self:addPart("models/props_c17/pulleywheels_small01.mdl",Vector(-14,29,-13),Angle(0,90,0),.8)
	self:addPart("models/props_c17/pulleywheels_small01.mdl",Vector(11,-29,-13),Angle(0,270,0),.8)
	self:addPart("models/props_c17/pulleywheels_small01.mdl",Vector(-14,-29,-13),Angle(0,270,0),.8)

	local wheel = self:addPart("models/props_vehicles/apc_tire001.mdl",Vector(0,29,6),Angle(0,90,0),.4)
	local slide = self:addPart("models/props_junk/propane_tank001a.mdl",Vector(0,38,6),Angle(0,270,0))
	self:addPart("models/props_trainstation/trainstation_ornament002.mdl",Vector(0,31,6),Angle(0,0,270))
	slide:SetParent(wheel)

	self.hologram = ents.Create("ffv_scanprop")
	self.hologram:SetParent(self)
	self.hologram:SetLocalPos(Vector(8,-16,38))
	self.hologram:SetLocalAngles(Angle(0,0,45))
	self.hologram:Spawn()
	self.hologram:SetNoDraw(true)

	local lamp = self:addPart("models/props_wasteland/light_spotlight01_lamp.mdl",Vector(0,42,34.5),Angle(270,90,0))
	lamp:SetParent(slide)
	self:makeLight(lamp)
end

function ENT:delayedThink()
	--jump if fallen
	if (((not self.grounded) and (not self.jumping)) and randomChance(4)) then
		self.jumping = true
		self:GetPhysicsObject():AddVelocity(Vector(0,0,200))
	end

	--bot can have little a variability. as a flair
	self.slideVar = math.Rand(-.02,.02)
	self.lookVar:Random(-6,6)

	--self:EmitSound(scanSounds[math.random(#scanSounds)])

	--target stuff
	if IsValid(self.target) then
		if self.scanning then
			if self:GetPos():DistToSqr(self.target:GetPos())>16000 then
				self.scanning=false
				return
			end

			local scanTime=CurTime()-self.clearScan
			if scanTime>.5 then self:EmitSound(scanSounds[math.random(#scanSounds)]) end
			if scanTime>3 then
				self.lastScanned=self.target
				self.showHologram=true
				self.scanning=false

				self.startHologram=CurTime()
				self.hologram:setModel(self.target:GetModel())
			end

			return
		end

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
		self.scanning=false

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

	--wheels that move n whatnot
	if self.grounded then
		for k=14,17 do
			--scuffed code
			local dir = 1
			if (k>15) then dir = -1 end
			local vel = getRotated(self:GetPhysicsObject():GetVelocity(),-self:GetAngles())
			local angVel = self:GetPhysicsObject():GetAngleVelocity()
			self.parts[k]:SetLocalAngles(self.parts[k]:GetLocalAngles()+Angle(0,0,vel.x/20*dir)-Angle(0,0,angVel.z/40))
		end
	end

	--look at things
	local wheel = self.parts[18]
	local slide = self.parts[19]
	local slideAmount = (self.scanning and 1 or 0)+self.slideVar
	slide:SetLocalPos(Vector(9,0,slide:GetLocalPos().z-(slide:GetLocalPos().z+6-(slideAmount*22))/24))

	--self.lookTarget = self:GetPos()+getRotated(Vector(100,0,math.sin(CurTime()*12)*12),self:GetAngles())
	if self.target then self.lookTarget = self.target:WorldSpaceCenter()
	else self.lookTarget = nil end
	local lookPos = self.lookTarget or (self:GetPos()+getRotated(Vector(100,0,0),self:GetAngles()))
	lookPos = lookPos+self.lookVar
	local lookDif = getRotated(self:GetPos()-lookPos,-self:GetAngles()):Angle()
	wheel:SetLocalAngles(Angle(0,90,wheel:GetLocalAngles().z-(math.AngleDifference(wheel:GetLocalAngles().z,90-lookDif.x)/6)))
	--debugoverlay.Sphere(lookPos,2,.1)

	if self.showHologram then
		if self.hologram:GetNoDraw() then
			self:EmitSound("common/wpn_moveselect.wav")
			self.parts[2]:SetSkin(0)
			self.parts[3]:SetSkin(0)
			self.hologram:SetNoDraw(false)
		end
		--hologram hover; classic
		self.hologram:SetLocalAngles(Angle(0,(CurTime()*20)%360,0))
		self.hologram:SetLocalPos(Vector(8,-16,42+(math.sin(CurTime()/2)*2)))
	else
		if (not self.hologram:GetNoDraw()) then
			self:EmitSound("common/wpn_hudoff.wav")
			self.parts[2]:SetSkin(1)
			self.parts[3]:SetSkin(1)
			self.hologram:SetNoDraw(true)
		end
	end

	if self.scanning then
		local badLook=math.NormalizeAngle(205+(self:GetAngles()-(self:GetPos()-self.target:GetPos()):Angle())[2])
		if math.abs(badLook)>2 then self:GetPhysicsObject():AddAngleVelocity(Vector(0,0,math.Clamp(-badLook,-4,4))) end
	end

	--correct rot when jumping
	if (self.jumping and (not self.grounded)) then
		local phys = self:GetPhysicsObject()
		phys:AddAngleVelocity(Vector(math.Clamp(-self:GetAngles().z,-8,8),math.Clamp(-self:GetAngles().x,-8,8),0))
	end
	if self.grounded then self.jumping = false end
end

function ENT:PhysicsCollide(data,phys)
	local ent = data.HitEntity
	if (((not ent:IsWorld()) and (self.state~=2)) and (data.TheirOldVelocity:Length()>100)) then
		self.target = ent
		self.goalPos=nil
	end

	self.jumping = false
end

function ENT:movement(pos)
	if self.goalPos and self:GetPos():DistToSqr(self.goalPos)<8000 then self.goalPos = nil end
	if (self.BaseClass.movement(self,pos) or self.goalPos==nil) and not self.scanning then
		if IsValid(self.target) and not (self.showHologram and self.target==self.lastScanned) then
			self.scanning=true
			self.clearScan=CurTime()
		elseif self.showHologram and math.Rand(0,1)>.9 and (CurTime()-self.startHologram)>10 then self.showHologram=false end
	end
end

function ENT:qualifyLook(ent)
	if ent==self.hologram then return false end
	if ent:IsWeapon() then return false end
	if (ent==self) then return false end
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

function ENT:getInterest(ent)
	if ent==self.lastScanned then return 1 end
	if ent:IsPlayer() then return 6 end
	if (string.StartsWith(ent:GetClass(),"ffv_") and string.EndsWith(ent:GetClass(),"bot")) then return 5 end
	if (ent:GetClass()=="ffv_hoardmarker") then return 5 end
	if ent:IsNPC() then return 3 end
	if ent:IsRagdoll() then return 3 end
	if ent:IsVehicle() then return 2 end
	return 1
end

function ENT:prePop()
	local emitter1 = self.parts[2]
	local emitter2 = self.parts[3]
	if (emitter1:GetSkin()==0) then
		emitter1:SetSkin(1)
		emitter2:SetSkin(1)
		self:EmitSound("weapons/stunstick/spark"..math.random(3)..".wav")

		local effectdata = EffectData()
		effectdata:SetOrigin(emitter1:GetPos()-getRotated(Vector(0,0,4),emitter1:GetAngles()))
		effectdata:SetNormal(-emitter1:GetUp())
		util.Effect("ManhackSparks",effectdata)
		effectdata:SetOrigin(emitter2:GetPos()-getRotated(Vector(0,0,4),emitter2:GetAngles()))
		effectdata:SetNormal(-emitter2:GetUp())
		util.Effect("ManhackSparks",effectdata)
	end
end

list.Set("NPC","ffv_scanbot",{
	Name=ENT.PrintName,
	Class="ffv_scanbot",
	Category="robots"
})
if CLIENT then language.Add("ffv_scanbot",ENT.PrintName) end
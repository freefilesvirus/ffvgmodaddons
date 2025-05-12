AddCSLuaFile()

ENT.Base = "pbot_base"
ENT.PrintName = "observation bot"
ENT.Spawnable = false

ENT.lookVar = Vector(0,0,0)
ENT.lookVarSize = 1

ENT.forward = 1
ENT.goalAngle = false
ENT.moveSpeed = 6.5

local pictureChance=CreateConVar("pbot_takepicturechance_onein",20)

function ENT:fixGroundedFriction() end

function ENT:delayedThink()
	local size = self.lookVarSize
	if math.random(2)==1 then self.lookVar:Random(-size,size) end
	--checks if fell over
	self.grounded = math.abs(self:GetAngles().z)<40
	--no one looking shenanigans
	local looking = false
	for k,v in ipairs(player.GetAll()) do
		if self.lineOfSight(v,self)>0 then looking = true end
	end
	if (not looking) then
		--get up when no ones looking
		if (not self.grounded) then
			self:SetAngles(Angle(0,0,0))
		end
		--fratricide
		if (IsValid(self.target) and ((self.target:GetClass()=="pbot_watchbot") and math.random(2000)==1)) then
			local barrel = ents.Create("prop_physics")
			barrel:SetModel("models/props_c17/oildrum001.mdl")
			barrel:Spawn()
			barrel:SetPos(self.target:GetPos())
			barrel:SetAngles(self.target:GetAngles())
			self.target:Remove()
			self.target = barrel
			--screenshot
			self:screenshot()
		end
	end
	--target stuff
	if IsValid(self.target) then
		--chance go to target
		if math.random(3)==1 then self.goalPos = self.target:GetPos() end
		--chance face target
		if ((IsValid(self.target) and math.random(6)==1) and ((not self.goalAngle) and (not self.goalPos))) then
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
			if (IsValid(trace.Entity) and (self:qualifyLook(trace.Entity)) and (self.weightedRandom({self:getInterest(self.target)*2,changeChance})==2)) then
				self.target = trace.Entity
			end
		end
		--chance get bored
		if (self.weightedRandom({self:getInterest(self.target)*6,1})==2) then
			--chance to instantly look for something else
			if math.random(4)==1 then
				local candidates = {}
				local chances = {}
				local pos = self:GetPos()
				for k,v in ipairs(ents.GetAll()) do
					if ((self:Visible(v) and (pos:DistToSqr(v:GetPos())<422500)) and self:qualifyLook(v)) then
						table.insert(candidates,v)
						table.insert(chances,self:getInterest(v))
					end
				end
				self.target = candidates[self.weightedRandom(chances)]
			else
				self.target = nil
			end
		end

		if (self.target==nil) then return end
		--looks to see if target is still visible
		if (not self.parts[5]:Visible(self.target)) then
			--either go searching for a new target or look for old one
			if (self.weightedRandom({self:getInterest(self.target),6})==2) then
				--go find target
				self.goalPos = self.target:GetPos()
			else
				self.target = nil
			end
		end
	else
		--ramble the land
		if (math.random(3)==1 and (not self.goalPos)) then
			local trace = util.TraceLine({
				start=self:GetPos(),
				endpos=self:GetPos()+Vector(math.random(-300,300),math.random(-300,300),0),
				filter=self
			})
			self.goalPos = trace.HitPos
		end
		--look for something interesting
		if math.random(10)==1 then
			local candidates = {}
			local chances = {}
			local pos = self:GetPos()
			for k,v in ipairs(ents.GetAll()) do
				if ((self:Visible(v) and (pos:DistToSqr(v:GetPos())<422500)) and self:qualifyLook(v)) then
					table.insert(candidates,v)
					table.insert(chances,self:getInterest(v))
				end
			end
			self.target = candidates[self.weightedRandom(chances)]
		end
	end
end

function ENT:tickThink()
	if ((not IsValid(self.target)) or (not self:qualifyLook(self.target))) then self.target = nil end
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
		elseif self.target.isProbot then
			targetPos = self.target.parts[#self.target.parts]:GetPos()
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
		targetPos = latGear:GetPos()+(self:GetUp()*100)
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
end

function ENT:movement(pos)
	if (not self.goalPos) then return end
	if (self:GetPos():DistToSqr(self.goalPos)<10000) then
		self.goalPos = false
		--chance to screenshot
		local num=math.Clamp(pictureChance:GetInt(),0,math.huge)
		pictureChance:SetInt(num)
		if math.random(num)==1 then self:screenshot() end
	else
		--face target area before moving
		local targetAngle = (pos-self:GetPos()):Angle()
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
				phys:AddVelocity(((pos-self:GetPos()):GetNormalized()*self.moveSpeed)*Vector(1,1,0))
				phys:AddAngleVelocity(Vector(0,self.moveSpeed*-6*self.forward),0)
			end
		end
	end
end

function ENT:Initialize()
	if SERVER then
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
		self:makeLight(lamp)
		--sounds
		for k=1,2 do
			local sound = CreateSound(self,"probots/ratchetloop.wav")
			sound:PlayEx(0,100)
			table.insert(self.sounds,sound)
		end
	end

	self.BaseClass.Initialize(self)
end

function ENT:OnTakeDamage(info)
	if (self.weightedRandom({self:getInterest(info:GetAttacker())+2,1})==1) then
		self.target = info:GetAttacker()
	end

	self.BaseClass.OnTakeDamage(self,info)
end
function ENT:PhysicsCollide(data,phys)
	if (data.HitEntity==game.GetWorld()) then return end
	if (self.weightedRandom({self:getInterest(data.HitEntity)+2,1})==1) then
		self.target = data.HitEntity
	end
end
function ENT:Use(activator)
	self.target = activator
end

function ENT:getInterest(ent)
	if ent:IsPlayer() then return 6 end
	if ent.isProbot then return 5 end
	if (ent:GetClass()=="pbot_hoardmarker") then return 5 end
	if ent:IsNPC() then return 3 end
	if ent:IsRagdoll() then return 3 end
	if ent:IsVehicle() then return 2 end
	return 1
end

function ENT:qualifyLook(ent)
	if ent:IsWeapon() then return false end
	if (ent==self) then return false end
	if (ent:GetClass()=="prop_physics") then return true end
	if ent.isProbot then return true end
	if ent:IsPlayer() then
		if (cvars.Number("ai_ignoreplayers")==1) then return false end
		return true
	end
	if ent:IsRagdoll() then return true end
	if ent:IsVehicle() then return true end
	if ent:IsNPC() then return true end
	if ent:IsNextBot() then return true end
	return false
end

function ENT:screenshot()
	self:EmitSound("npc/scanner/scanner_photo1.wav")
	local light = self.parts[6]

	--create the name
	local filename = os.time()
	local mapname = string.Right(game.GetMap(),#game.GetMap()-#string.Split(game.GetMap(),"_")[1]-1)
	if math.random(2)==1 then filename = filename.."."..mapname end
	if self.target then
		local name = "thing"
		if (self.target:GetClass()=="pbot_watchbot") then name="franklin" end
		if (self.target:GetClass()=="pbot_hoardbot") then name=(math.Rand(0,1)>.5 and "calvin" or "thief") end
		if (self.target:GetClass()=="pbot_copbot") then name="johnny" end
		if string.StartsWith(self.target:GetClass(),"pbot_corpse") then name=(math.Rand(0,1)>.5 and "kramer" or "hunk") end
		if (self.target:GetClass()=="pbot_sawbot") then name=(math.Rand(0,1)>.5 and "spinley" or "asshole") end
		if (self.target:GetClass()=="pbot_skaterbot") then name=(math.Rand(0,1)>.5 and "owen" or "asshole") end
		if string.StartsWith(self.target:GetClass(),"pbot_scan") then name="jack" end

		if self.target:IsPlayer() then
			if math.random(4)==1 then name = "friend"
			else name = self.target:GetName() end
		end
		if (self.target:GetClass()=="prop_physics") then
			name = self.target:GetModel()
			name = string.Split(name,"/")
			name = name[#name]
			name = string.Split(name,"0")[1]
			name = string.Split(name,".")[1]
		end
		if (name=="thing") then
			name = self.target:GetClass()
			name = string.Split(name,"_")
			name = name[#name]
		end
		if math.random(2)==1 then filename = filename.."."..name end
	end
	--get players
	local plys = {}
	for k,v in ipairs(player.GetAll()) do
		if (v:GetInfoNum("pbot_savepictures",0)==1) then table.insert(plys,v) end
	end
	--tell client to save
	net.Start("watchbotPicture")
		net.WriteEntity(self)
		net.WriteString(filename)
	net.Send(plys)

	light:Input("TurnOff",nil,nil,true)
	self.parts[#self.parts-1]:SetSkin(1)
	timer.Simple(0.2,function()
		if (not IsValid(light)) then return end
	self.parts[#self.parts-1]:SetSkin(0)
		light:Input("TurnOn",nil,nil,true)
	end)
end

net.Receive("watchbotPicture",function()
	local bot=net.ReadEntity()
	local filename = net.ReadString()

	bot:updateRt()
	timer.Simple(.1,function() --give it time to updatert
		local view=Material("a")
		view:SetTexture("$basetexture",bot.rt)
		cam.Start2D()
			surface.SetDrawColor(255,255,255,255)
			surface.SetMaterial(view)
			surface.DrawTexturedRect(0,0,300,300)
			surface.SetMaterial(Material("materials/probots/overlaysquare.png"))
			surface.DrawTexturedRect(0,0,300,300)
			local texture = render.Capture({
				x=60,
				y=60,
				w=180,
				h=180,
				format="jpeg",	--PNG doesn't render/export correctly and wastes space for most users.
				--quality=96	--GMod's default is 90, values of 96 and above are high quality.
			})
			if (not file.Exists("data/observationbot","GAME")) then file.CreateDir("observationbot") end
			file.Write("observationbot/"..filename..".jpg",texture)
		cam.End2D()
	end)
end)

CreateClientConVar("pbot_savepictures","1",true,true)

list.Set("NPC","pbot_watchbot",{
	Name=ENT.PrintName,
	Class="pbot_watchbot",
	Category="probots"
})
if CLIENT then language.Add("pbot_watchbot",ENT.PrintName) end
if SERVER then util.AddNetworkString("watchbotPicture") end

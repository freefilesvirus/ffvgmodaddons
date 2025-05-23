AddCSLuaFile()

ENT.Base = "pbot_base"
ENT.PrintName = "saw bot"
ENT.Spawnable = false

ENT.willFight = true
ENT.friendly = false

ENT.sawGoal = 60
ENT.sawSpeed = 4
ENT.sawTurnSpeed = 0
ENT.sawGrounded = false
ENT.upright = nil

ENT.lookSpeed = 24
ENT.lookGoal = 0

ENT.jumping = false

ENT.state = 0
--0, look around and turn to target
--1, saw down and forward

function ENT:delayedThink()
	if (self.target and (self:getInterest(self.target)==0)) then
		self.target = nil
		return
	end

	--state? state?? STAAAAAAAAAAAAAAAAAAATE
	if (self.state==0) then
		if math.random(2)==1 then self.lookGoal = math.NormalizeAngle(self.lookGoal+math.random(-12,12)) end
		if math.random(3)==1 then
			local dir = 1
			if math.random(2)==1 then dir = -1 end
			self.lookGoal = math.NormalizeAngle(self.lookGoal+((45+math.random(0,90))*dir))
		end
		if (not self.target) then
			--look for guy to KILL!
			local candidates = {}
			local chances = {}
			for k,v in ipairs(ents.FindInSphere(self:GetPos(),1600)) do
				if (self:lineOfSight(v)>.2 and ((v:IsPlayer() or (v:IsNPC() or v:IsNextBot() or v.isProbot)) and (not self:getFriendly(v)))) then
					if (self:getInterest(v)>0) then
						table.insert(candidates,v)
						table.insert(chances,self:getInterest(v))
					end
				end
			end
			if (#candidates>0) then self.target = candidates[self.weightedRandom(chances)] end
		else
			local trace = util.TraceLine({
				start=self:GetPos(),
				endpos=self.target:WorldSpaceCenter()+((self.target:WorldSpaceCenter()-self:GetPos())*99),
				filter=self
			})
			if (not (trace.Entity==self.target)) then
				self.target = nil
				return
			end

			if (math.abs((self:GetPos()-self.target:GetPos()):Angle().y-self:GetAngles().y-180)<2) then self.state=1 end
		end
	elseif (self.state==1) then
		if self:lineOfSight(self.target)<.2 then self.state = 0 end
	end

	--i get knocked down. but i get up again
	if (((not self.grounded) and (not self.jumping)) and math.random(4)==1) then
		self.jumping = true
		self:GetPhysicsObject():AddVelocity(Vector(0,0,180))
	end
	if (self.jumping and (not self.grounded)) then
		local phys = self:GetPhysicsObject()
		phys:AddAngleVelocity(Vector(math.Clamp(-self:GetAngles().z,-10,10),math.Clamp(-self:GetAngles().x,-10,10),0))
	end
	if self.grounded then self.jumping = false end
end


function ENT:fixGroundedFriction()
	local phys = self:GetPhysicsObject()
	if not IsValid(phys) then return end

	if self.grounded then
		phys:SetMaterial("gmod_ice")
		phys:SetVelocity(phys:GetVelocity()*.92)
		phys:SetAngleVelocity(phys:GetAngleVelocity()*.1)
	else
		phys:SetMaterial("metal")
	end
end

function ENT:tickThink()
	local phys = self:GetPhysicsObject()

	--states
	if (self.state==0) then
		self.lookSpeed = self.target and 6 or 24
		self.sawGoal = 60
		self.sawSpeed = 8
		self.sawTurnSpeed = (self.sawTurnSpeed-.1)

		if self.target then self.lookGoal = ((self:GetPos()-self.target:GetPos()):Angle().y-self:GetAngles().y+180) end
		if (self.target and self.grounded) then
			phys:AddAngleVelocity(Vector(0,0,math.Clamp(math.AngleDifference((self:GetPos()-self.target:GetPos()):Angle().y-self:GetAngles().y,180)*6,-100,100)))
		end
	elseif (self.state==1) then
		self.lookSpeed = 6
		self.sawGoal = 60
		self.sawSpeed = 2
		self.sawTurnSpeed = (self.sawTurnSpeed+.1)

		self.lookGoal = 0

		local trace = util.TraceLine({
			start=self:GetPos(),
			endpos=self:GetPos()+(self:GetForward()*70)+Vector(0,0,10),
			filter=self
		})
		if (self.grounded and ((self.sawTurnSpeed>14) and (not trace.Hit))) then self.sawGoal = 95 end
		if (self.sawGrounded and trace.Hit) then
			self:hit(trace.Entity,trace.HitPos,trace.HitNormal,true)
		end

		if (IsValid(self.target) and (self.sawGrounded and (not trace.Hit))) then
			phys:AddVelocity(self:GetForward()*self.sawTurnSpeed*1.8)
			phys:AddAngleVelocity(Vector(0,0,math.Clamp(math.AngleDifference((self:GetPos()-self.target:GetPos()):Angle().y-self:GetAngles().y,180)*1.4,-100,100)))

			local effectdata = EffectData()
			effectdata:SetOrigin(self:LocalToWorld(Vector(36,2,-26)))
			effectdata:SetNormal(self:GetUp()-(self:GetForward()/2))
			util.Effect("MetalSpark",effectdata)
		end
	end

	--staws
	local saw = self.parts[2]
	saw:SetLocalAngles(Angle(saw:GetLocalAngles().x-((saw:GetLocalAngles().x-self.sawGoal)/self.sawSpeed),0,0))
	if (saw:GetLocalAngles().x<94) then
		if self.sawGrounded then
			self.sawGrounded = false
			if IsValid(self.upright) then
				self.upright:Remove()
				self.upright = nil
			end
		end
	else
		if (not self.sawGrounded) then
			self.sawGrounded = true
			self:EmitSound("physics/metal/sawblade_stick"..math.random(3)..".wav")

			if IsValid(self.upright) then
				self.upright:Remove()
				self.upright = nil
			end
			self.upright = constraint.Keepupright(self,self:GetAngles(),0,999)
		end
	end
	local sawblade = self.parts[3]
	self.sawTurnSpeed = math.Clamp(self.sawTurnSpeed,0,20)
	sawblade:SetLocalAngles(sawblade:GetLocalAngles()+Angle(self.sawTurnSpeed,0,0))
	local vol = self.sawTurnSpeed/20
	self.sounds[1]:ChangeVolume(self.sawGrounded and 0 or vol)
	self.sounds[2]:ChangeVolume(self.sawGrounded and vol or 0)

	--stlooks
	local neck = self.parts[4]
	neck:SetLocalAngles(neck:GetLocalAngles()-Angle(0,math.AngleDifference(neck:GetLocalAngles().y,self.lookGoal)/self.lookSpeed,0))

	--stjumping
	if (self.jumping and (not self.grounded)) then
		local phys = self:GetPhysicsObject()
		phys:AddAngleVelocity(Vector(math.Clamp(-self:GetAngles().z,-10,10),math.Clamp(-self:GetAngles().x,-10,10),0))
	end
	if self.grounded then self.jumping = false end

	--no funny spinny wheel :(
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/props_c17/FurnitureWashingmachine001a.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		--self:GetPhysicsObject():Wake()
		--parts
		local wheel = self:addPart("models/props_vehicles/apc_tire001.mdl",Vector(13,0,-10),Angle(-90,0,0),.3)					--1, hook swivel
		local hookSwivel = self:addPart("models/Combine_Helicopter/helicopter_bomb01.mdl",Vector(20,0,-10),Angle(0,0,0),.09)	--2, the part to move the hook
		hookSwivel:SetParent(wheel)
		self:addPart("models/props_junk/sawblade001a.mdl",Vector(52,2,-14),Angle(0,0,90)):SetParent(hookSwivel)					--3, saw
		local headSwivel = self:addPart("models/props_vehicles/tire001c_car.mdl",Vector(0,0,18),Angle(90,0,0),.6)				--4, head swivel
		--self:addPart("models/props_phx/construct/glass/glass_plate1x2.mdl",Vector(12,-5.7,22),Angle(90,0,0),.25)
		self:addPart("models/props_junk/meathook001a.mdl",Vector(38,0,-13),Angle(0,-90,90)):SetParent(hookSwivel)
		self:addPart("models/props_junk/metal_paintcan001a.mdl",Vector(52,0,-14),Angle(0,0,90)):SetParent(hookSwivel)
		for k=-1,4 do
			local ang = Angle(k*-17,0,0)
			local pos = Vector(0,0,7)
			pos:Rotate(ang)
			self:addPart("models/props_wasteland/panel_leverHandle001a.mdl",Vector(52,0,-14)+pos,ang,1.3):SetParent(hookSwivel)
		end

		self:addPart("models/props_c17/utilitypole02b.mdl",Vector(12,12,-4),Angle(0,0,0),.1)
		local rope = constraint.CreateKeyframeRope(Vector(),2,"cable/cable2",nil,self,Vector(12,20,42),0,hookSwivel,Vector(32,7,-4),0,{["Slack"]=100})

		--could be cool but makes the robot look a bit cluttered
		-- local plug = ents.Create("prop_physics")
		-- plug:SetModel("models/props_lab/tpplug.mdl")
		-- plug:SetPos(self:GetPos()+getRotated(Vector(-26,-8,-18),self:GetAngles()))
		-- plug:SetAngles(self:GetAngles()+Angle(0,0,0))
		-- plug:Spawn()
		-- plug:GetPhysicsObject():EnableMotion(false)
		-- self:GetPhysicsObject():EnableMotion(false)
		-- table.insert(self.parts,plug)
		-- constraint.Rope(self,plug,0,0,Vector(-14,-8,-18),Vector(10,0,0),100,0,0,3,"cable/cable2",false,Color(255,255,255))

		hookSwivel:SetLocalAngles(Angle(60,0,0))
		local lamp = self:addPart("models/props_wasteland/light_spotlight01_lamp.mdl",Vector(0,0,26),Angle(0,0,0))
		lamp:SetParent(headSwivel)
		self:makeLight(lamp)

		local spinSound = CreateSound(self,"probots/sawdry.wav")
		local dragSound = CreateSound(self,"probots/sawbzrzhzt.wav")
		spinSound:PlayEx(0,100)
		dragSound:PlayEx(0,100)
		table.insert(self.sounds,spinSound)
		table.insert(self.sounds,dragSound)
	end

	self.BaseClass.Initialize(self)
end

function ENT:PhysicsCollide(data,phys)
	if ((self.state==1) and ((data.OurOldVelocity*Vector(1,1,0)):Length()>300)) then
		self:hit(data.HitEntity,data.HitPos,data.HitNormal,false)
	end
end

function ENT:OnTakeDamage(dmg)
	if (self.state==0) then
		self.lookGoal = ((self:GetPos()-dmg:GetAttacker():GetPos()):Angle().y-self:GetAngles().y+180)
	end

	self.BaseClass.OnTakeDamage(self,dmg)
end

function ENT:Use(ply)
	if (ply:IsPlayer() and (self.state==0)) then self.target = ply end
end

function ENT:getInterest(ent)
	if self:getFriendly(ent) then return 0 end
	if ent:IsPlayer() then
		if (ent:Alive() and (cvars.Number("ai_ignoreplayers")==0)) then return 6
		else return 0 end
	end
	return 1
end

function ENT:hit(ent,pos,normal,tracehit)
	if ((not tracehit) and (ent==game:GetWorld())) then return end
	if IsValid(self.upright) then
		self.upright:Remove()
		self.upright = nil
	end

	local phys = self:GetPhysicsObject()
	phys:SetVelocity((phys:GetVelocity()*-.6)+Vector(0,0,200))
	phys:AddAngleVelocity(Vector(0,80,0))

	if tracehit then ent:TakeDamage(phys:GetVelocity():Length()/9,self,self) end
	if (ent:IsPlayer() or ((ent:IsNPC() or ent:IsRagdoll()) or ent:IsNextBot())) then
		self:EmitSound("npc/manhack/grind_flesh"..math.random(3)..".wav")

		local effectdata = EffectData()
		effectdata:SetOrigin(pos)
		util.Effect("BloodImpact",effectdata)
		util.Decal("Blood",self:GetPos(),self:GetPos()+(self:GetForward()*999),self)

		--if the target dies immediately look for a new one
		if self.target and (self.target:Health()<1) then
			local candidates = {}
			local chances = {}
			for k,v in ipairs(ents.FindInSphere(self:GetPos(),1600)) do
				if (self:lineOfSight(v)>-.2 and ((v:IsPlayer() or v:IsNPC() or v:IsNextBot() or v.isProbot) and (not self:getFriendly(v)))) then
					local interest=self:getInterest(v)
					if (interest>0) then
						table.insert(candidates,v)
						table.insert(chances,interest)
					end
				end
			end
			if (#candidates>0) then self.target = candidates[self.weightedRandom(chances)] end
			self.state = 0
		end
	else
		self.state = 0
		self.target = nil

		self:EmitSound("physics/metal/sawblade_stick"..math.random(3)..".wav")

		local effectdata = EffectData()
		effectdata:SetOrigin(pos)
		effectdata:SetNormal(normal)
		util.Effect("MetalSpark",effectdata)
		--util.Decal("ManhackCut",self:GetPos(),self:GetPos()+(self:GetForward()*999),self) its sideways >:[
	end
end

list.Set("NPC","pbot_sawbot",{
	Name=ENT.PrintName,
	Class="pbot_sawbot",
	Category="probots"
})
if CLIENT then language.Add("pbot_sawbot",ENT.PrintName) end
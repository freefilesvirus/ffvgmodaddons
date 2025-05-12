--designed by dohju121 https://steamcommunity.com/profiles/76561198985441804

AddCSLuaFile()

ENT.Base="pbot_base"
ENT.PrintName="fish bot"
ENT.Spawnable=false

ENT.goalDistance=10000

list.Set("NPC","pbot_fishbot",{
	Name=ENT.PrintName,
	Class="pbot_fishbot",
	Category="probots"
})
if CLIENT then language.Add("pbot_fishbot",ENT.PrintName) end

ENT.waggle=0
ENT.waggleGoal=0
ENT.waggleStart=0

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/props_lab/filecabinet02.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)

		self:addPart("models/props_trainstation/tracksign09.mdl",Vector(-6.6,10,19),Angle(0,-90,-135))
		self:addPart("models/props_interiors/refrigeratordoor02a.mdl",Vector(3,-.75,0),Angle(-100,0,0))
		local tire=self:addPart("models/props_vehicles/tire001c_car.mdl",Vector(-16,0,0),Angle(90,0,0))
		self:addPart("models/props_junk/metalgascan.mdl",Vector(-40,0,-8),Angle(0,90,50)):SetParent(tire)
		self:addPart("models/props_junk/metalgascan.mdl",Vector(-40,0,8),Angle(0,-90,-120)):SetParent(tire)
		self:addPart("models/props_wasteland/light_spotlight01_lamp.mdl",Vector(14,-.5,-1.5),Angle(-0.000020,0.043932,0.000137))

		self:makeLight(self.parts[#self.parts])
	end

	self.BaseClass.Initialize(self)
end

ENT.onGround=false
ENT.stuckOnGround=0

function ENT:delayedThink()
	if self.waggle==0 then self.waggleStart=CurTime() end

	if not self.grounded and self.onGround then
		self.waggleGoal=0

		self.stuckOnGround=self.stuckOnGround+1
		if math.Rand(3,5)<self.stuckOnGround then
			self.stuckOnGround=0

			self:flop()
		end
	else
		self.stuckOnGround=0

		if not self.goalPos then
			if not self.target then
				local choices={}
				local interests={3}
				for _,v in ipairs(ents.FindInCone(self:GetPos(),self:GetForward(),1200,.5)) do
					if self:interest(v)>0 then
						table.insert(choices,v)
						table.insert(interests,self:interest(v))
					end
				end

				if #choices>0 then
					local pick=self.weightedRandom(interests)
					if pick>1 then self.target=choices[pick-1] end
				end

				if not self.target then self:pickSwimDir() end
			else
				if not self.posInWater(self.target:GetPos()) then
					self.target=nil

					return
				end

				if math.random(4)==1 then
					self.target=nil
					self:pickSwimDir()
				elseif self:GetPos():DistToSqr(self.target:GetPos())>(self.goalDistance+3000) then self.goalPos=self.target:GetPos() end
			end
		elseif not self.posInWater(self.goalPos) then self.goalPos=nil end
	end
end

function ENT:tickThink()
	local phys=self:GetPhysicsObject()
	if not IsValid(phys) then return end

	self.waggle=Lerp(.06,self.waggle,self.waggleGoal)
	self.parts[3]:SetLocalAngles(Angle(90,math.sin((CurTime()-self.waggleStart)*12)*self.waggle*24,0))

	if self.grounded and not self.goalPos then
		if self.target then self:look(isfunction(self.target.EyePos) and self.target:EyePos() or self.target:GetPos())
		else self.waggleGoal=0 end

		phys:AddAngleVelocity(Vector(-self:GetAngles()[3]/10,-self:GetAngles()[1]/10,0))
	end
end

function ENT:pickSwimDir()
	local pos=Vector(math.Rand(150,300),0,math.Rand(-80,80))
	pos:Rotate(Angle(0,math.Rand(-180,180),0))
	pos=pos+self:GetPos()

	local dir=pos:GetNormalized()

	if not self.posInWater(pos) then
		pos[3]=self:GetPos()[3]

		dir[3]=0
		dir:Normalize()
	end

	local tr=util.TraceLine({start=self:GetPos(),endpos=pos,filter=self})
	if tr.Hit then pos=tr.HitPos-dir*32+tr.HitNormal*32 end

	self.goalPos=pos
end

function ENT:Use(ply)
	self.target=ply
	if self.goalPos then self.goalPos=nil end
end

function ENT:interest(ent)
	if ent==self or table.HasValue(self.parts,ent) then return 0 end
	for _,v in pairs({"gmod_hands","physgun_beam","predicted_viewmodel","prop_dynamic"}) do
		if ent:GetClass()==v then return 0 end
	end
	for _,v in pairs({"env","func","path","lua","point","info","beam","spotlight","light"}) do
		if string.StartsWith(ent:GetClass(),v) then return 0 end
	end

	if ent:IsPlayer() then return 6 end
	if ent:GetClass()=="pbot_fishbot" then return 1 end
	if ent.isProbot or ent:IsNPC() then return 4 end

	return 1
end

function ENT:movement(pos)
	local phys=self:GetPhysicsObject()
	if not IsValid(phys) then return end
	if not isvector(pos) then return end

	phys:AddVelocity(Vector(0,0,-5))

	self.BaseClass.movement(pos)
end

function ENT:setGrounded()
	self.onGround=util.TraceLine({start=self:GetPos(),endpos=self:GetPos()-Vector(0,0,20),filter=self}).Hit
	self.grounded=(not self:IsPlayerHolding()) and self.posInWater(self:GetPos())
end

function ENT.posInWater(pos) return bit.band(util.PointContents(pos),CONTENTS_WATER)==CONTENTS_WATER end

function ENT:fixGroundedFriction()
	local phys=self:GetPhysicsObject()
	if not IsValid(phys) then return end

	phys:EnableGravity(not self.grounded)
	if self.grounded then
		phys:AddVelocity(Vector(0,0,-3.33))
		phys:SetVelocity(phys:GetVelocity()*.95)
		phys:SetAngleVelocity(phys:GetAngleVelocity()*.9)

		if self:GetUp():Dot(Vector(0,0,-1))>-.4 then phys:AddAngleVelocity(Vector(0,20,0)) end
	end
end

function ENT:OnTakeDamage(dmg)
	if not self.grounded then self:flop()
	else self:pickSwimDir() end

	self.BaseClass.OnTakeDamage(self,dmg)
end

function ENT:movement(pos)
	local phys=self:GetPhysicsObject()
	if not IsValid(phys) then return end

	local lookMod=math.max(-math.abs(self:look(pos)[2])+110,0)
	self.waggleGoal=lookMod/110+.1

	local tr=util.TraceLine({start=self:GetPos(),endpos=self:GetPos()+self:GetForward()*64,filter=self})
	if tr.Hit then phys:AddVelocity(tr.HitNormal*8)
	else phys:AddVelocity((self:GetForward()*lookMod/24)+Vector(0,0,math.Clamp(pos[3]-self:GetPos()[3],-2,2))) end

	if self:GetPos():DistToSqr(pos)<self.goalDistance then self.goalPos=nil end
end

function ENT:look(pos)
	local phys=self:GetPhysicsObject()
	if not IsValid(phys) then return end

	local dif=pos-self:GetPos()
	dif:Rotate(-self:GetAngles())
	dif=dif:Angle()
	dif:Normalize()

	phys:AddAngleVelocity(Vector(0,dif[1]/20,dif[2]/10))

	self.waggleGoal=math.Clamp(dif[2],-20,20)/60

	return dif
end

function ENT:setPath() end

function ENT:flop()
	if self.grounded or not self.onGround then return end

	local phys=self:GetPhysicsObject()
	if IsValid(phys) then
		phys:AddVelocity(Vector(0,0,300))
		local vec=Vector()
		vec:Random(-120,120)
		phys:AddAngleVelocity(vec)

		self.waggleGoal=1
	end
end
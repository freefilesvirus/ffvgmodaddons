require("scales")

AddCSLuaFile()
ENT.Base="base_anim"
ENT.Type="anim"

ENT.open=false

ENT.x=0
ENT.y=0
ENT.width=8

ENT.sound=-1

ENT.moving=0
ENT.speed=1
ENT.vel=0
ENT.closed=Vector(0,0,0)
ENT.hullTick=0

ENT.moveSound=nil
ENT.stopSound=nil

function sign(x)
	return ((x==0) and 0 or ((x>0) and 1 or -1))
end

function ENT:Initialize()
	if (self.closed==Vector(0,0,0)) then self.closed=self:GetPos() end

	if CLIENT then return end

	local size=math.min(math.ceil(self.y/64),8)
	self:SetModel("models/hunter/plates/plate"..size.."x"..size..".mdl")

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	local min,max=self:GetModelBounds()
	scales.Scale(self,Vector(self.y+8,self.x+8,self.width)/(max-min))

	local phys=self:GetPhysicsObject()
	if IsValid(phys) then phys:EnableMotion(false) end

	if (WireLib~=nil) then
		WireLib.CreateInputs(self,{"open","speed"})
		WireLib.CreateOutputs(self,{"open","moving"})
	end
end

function ENT:OnDuplicated(data) self:Initialize() end

function ENT:TriggerInput(name,val)
	if (name=="open") then self:setOpen(val>0)
	elseif (name=="speed") then self.speed=val end
end

function ENT:setOpen(open)
	self.open=open

	self.moving=sign((self.open and (self.closed.z+self.y) or self.closed.z)-self:GetPos().z)
	self.vel=0
	if ((self.sound==-1) and (self.moveSound~=nil)) then
		self.sound=self:StartLoopingSound(self.moveSound)

		timer.Simple(.1,function()
			if (self.moving==0) then
				self:StopLoopingSound(self.sound)
				self.sound=-1
			end
		end)
	end

	if (WireLib~=nil) then
		WireLib.TriggerOutput(self,"open",self.open and 1 or 0)
		WireLib.TriggerOutput(self,"moving",self.moving)
	end
end

function ENT:Think()
	if CLIENT then return end

	if (self.moving~=0) then
		local goal=(self.open and (self.closed.z+self.y) or self.closed.z)
		
		self.vel=math.min(self.vel+.02,4)
		self:SetPos(self:GetPos()+Vector(0,0,self.vel*self.moving*math.max(.1,self.speed)))

		if (sign(goal-self:GetPos().z)~=self.moving) then
			self:SetNWFloat("slam",CurTime())

			self.moving=0
			self:SetPos(Vector(self:GetPos().x,self:GetPos().y,goal))

			if (self.sound>=0) then
				self:StopLoopingSound(self.sound)
				self.sound=-1
			end
			if (self.stopSound~=nil) then self:EmitSound(self.stopSound) end

			if (WireLib~=nil) then WireLib.TriggerOutput(self,"moving",self.moving) end
		end

		if (self.moving==-1) then
			if (self.hullTick>5) then
				local mins,maxs=self:GetRotatedAABB(self:OBBMins(),self:OBBMaxs())
				local pos=self:GetPos()
				local tr=util.TraceHull({
					start=pos,
					endpos=pos,
					maxs=maxs,
					mins=mins,
					ignoreworld=true,
					filter=self
				})
				if tr.Hit then tr.Entity:TakeDamage(999) end

				self.hullTick=0
			else self.hullTick=(self.hullTick+1) end
		end

		self:NextThink(CurTime())
		return true
	end
end

function ENT:OnRemove()
	if (self.sound>=0) then self:StopLoopingSound(self.sound) end
end

function ENT:Draw()
	local since=(CurTime()-self:GetNWFloat("slam"))

	local v=Vector(0,0,math.sin(since*48)*math.abs(math.min(.8,since)-.8)*1)
	v:Rotate(self:GetAngles())
	self:SetPos(Vector(self.closed.x,self.closed.y,self:GetPos().z)+v)
	self:DrawModel()
end

if SERVER then
	numpad.Register("ffvgate_toggle",function(ply,ent)
		if !(IsValid(ent)) then return end

		ent:setOpen(!(ent.open))
	end)
end

hook.Add("PhysgunPickup","ffvgate_nophys",function(ply,ent)
	if (ent:GetClass()=="ffv_gate") then return false end
end)
hook.Add("CanPlayerUnfreeze","ffvgate_nounfreeze",function(ply,ent,phys)
	if (ent:GetClass()=="ffv_gate") then return false end
end)
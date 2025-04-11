require("scales")

AddCSLuaFile()
ENT.Base="base_anim"
ENT.Type="anim"

ENT.isOpen=false

ENT.x=0
ENT.y=0
ENT.width=8

ENT.shake=true

ENT.sound=-1

ENT.moving=false
ENT.speed=1
ENT.vel=0
ENT.closed=Vector(0,0,0)
ENT.open=Vector(0,0,0)
ENT.dir=Vector(0,0,0)

ENT.moveSound=nil
ENT.stopSound=nil

local function sign(x)
	return ((x==0) and 0 or ((x>0) and 1 or -1))
end

function ENT:Initialize()
	if CLIENT then return end

	self:SetModel("models/hunter/blocks/cube4x4x4.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:GetPhysicsObject():EnableMotion(false)

	local min,max=self:GetModelBounds()
	scales.Scale(self,Vector(self.x+2,self.width,self.y+2)/(max-min))

	if (WireLib~=nil) then
		WireLib.CreateInputs(self,{"open","speed"})
		WireLib.CreateOutputs(self,{"open","moving"})
	end
end

function ENT:setOpen(open)
	if (self.isOpen==open) then return end
	self.isOpen=open

	local goal=(self.isOpen and self.open or self.closed)

	self.moving=true
	self.vel=0
	if ((self.sound==-1) and (self.moveSound~=nil)) then self.sound=self:StartLoopingSound(self.moveSound) end

	if (WireLib~=nil) then
		WireLib.TriggerOutput(self,"open",self.isOpen and 1 or 0)
		WireLib.TriggerOutput(self,"moving",1)
	end
end

function ENT:Think()
	if CLIENT then return end

	if self.moving then
		local goal=(self.isOpen and self.open or self.closed)

		self.vel=math.min(self.vel+.01,1)
		local moving=(self.isOpen and 1 or -1)
		local to=self:GetPos()
		for xyz=1,3 do
			to[xyz]=(to[xyz]+(self.dir[xyz]*self.vel*self.speed*4*moving))
		end
		self:SetPos(to)

		if ((self:GetPos()-goal):GetNormalized():Dot(self.dir*moving)>0) then
			self:SetNWFloat("slam",CurTime())
			self.moving=false

			if (self.sound~=-1) then
				self:StopLoopingSound(self.sound)
				self.sound=-1
			end
			if (self.stopSound~=nil) then self:EmitSound(self.stopSound) end

			self:SetPos(goal)

			if (WireLib~=nil) then WireLib.TriggerOutput(self,"moving",0) end
		end

		if !(self.isOpen) then
			local mins,maxs=self:GetRotatedAABB(self:OBBMins()+Vector(1,1,1),self:OBBMaxs()-Vector(1,1,1))
			local tr=util.TraceHull({
				start=self:GetPos(),
				endpos=self:GetPos()+(self.dir*math.max(self.speed,1)*2),
				maxs=maxs,
				mins=mins,
				ignoreworld=true,
				filter=self
			})
			if tr.Hit then tr.Entity:TakeDamage(999) end
		end

		self:NextThink(CurTime())
		return true
	end
end

function ENT:OnRemove() if (self.sound>=0) then self:StopLoopingSound(self.sound) end end

function ENT:Draw()
	local since=(CurTime()-self:GetNWFloat("slam"))

	local v=Vector(0,math.sin(since*48)*math.abs(math.min(.8,since)-.8),0)
	v:Rotate(self:GetAngles())
	self:SetPos(self:GetPos()+v)

	self:DrawModel()
end

if SERVER then
	numpad.Register("ffvgate_toggle",function(ply,ent)
		if !(IsValid(ent)) then return end

		ent:setOpen(!(ent.isOpen))
	end)
end

hook.Add("PhysgunPickup","ffvgate_nophys",function(ply,ent)
	if (ent:GetClass()=="ffv_gate") then return false end
end)
hook.Add("CanPlayerUnfreeze","ffvgate_nounfreeze",function(ply,ent,phys)
	if (ent:GetClass()=="ffv_gate") then return false end
end)

--wiremood
function ENT:TriggerInput(name,val)
	if (name=="open") then self:setOpen(val>0)
	elseif (name=="speed") then self.speed=val end
end

function ENT:PreEntityCopy()
	if (WireLib~=nil) then
		duplicator.ClearEntityModifier(self,"WireDupeInfo")
		local info=WireLib.BuildDupeInfo(self)
		if info then duplicator.StoreEntityModifier(self,"WireDupeInfo",info) end
	end
end
local function EntityLookup(CreatedEntities)
	return function(id,default)
		if (id==nil) then return default end
		if (id==0) then return game.GetWorld() end
		local ent = CreatedEntities[id]
		if IsValid(ent) then return ent else return default end
	end
end
function ENT:PostEntityPaste(ply,ent,createdEnts)
	if ((WireLib~=nil) and ent.EntityMods and ent.EntityMods.WireDupeInfo) then WireLib.ApplyDupeInfo(ply,ent,ent.EntityMods.WireDupeInfo,EntityLookup(createdEnts)) end
end
--weeirmode
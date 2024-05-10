AddCSLuaFile()

ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.Spawnable = false
ENT.Category = "Pop Cones"

ENT.ispopcone = true

ENT.waitingPop = true
ENT.popTime = 0

ENT.thinkDelay = .4

ENT.conduitPower = 0

ENT.parts = {}

function ENT:Initialize()
	if CLIENT then return end
	
	if (self.popTime==0) then self.popTime = CurTime()+.2 end

	self:SetModel("models/props_junk/TrafficCone001a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)

	self:SetUseType(SIMPLE_USE)

	if (WireLib~=nil) then
		WireLib.CreateOutputs(self,{"Popped","Power"})
		WireLib.CreateInputs(self,{"Popped","Power"})
	end

	self:SetPower(1)

	self:setupParts()
	if self:GetPopped() then
		for k,v in pairs(self.parts) do
			if v[2] then
				v[1]:SetLocalPos(v[1]:GetLocalPos()+Vector(0,0,24))
			end
		end

		self:NextThink(CurTime())
		return true
	end
end

function ENT:SetupDataTables()
	self:NetworkVar("Bool",0,"Popped")
	self:NetworkVar("Float",0,"Power")

	if CLIENT then return end

	self:SetPower(1)
end

local popSound = Sound("physics/cardboard/cardboard_box_impact_bullet4.wav")
function ENT:Think()
	if CLIENT then
		local height = self:GetPopped() and 1 or .2
		local mat = Matrix()
		mat:Scale(Vector(1,1,height))
		mat:Translate(Vector(0,0,(height-1)*76))
		self:EnableMatrix("RenderMultiply",mat)
	else
		--wire stuff
		if (WireLib~=nil) then
			WireLib.TriggerOutput(self,"Popped",self:GetPopped() and 1 or 0)
			WireLib.TriggerOutput(self,"Power",self:GetPower())
		end

		self:SetPower(math.Clamp(self:GetPower(),1,999))

		--pop stuff
		if (self.waitingPop and (CurTime()>self.popTime)) then
			local popping = (not self:GetPopped())
			self.lastPop = CurTime()

			self:EmitSound(popSound)

			local phys = self:GetPhysicsObject()
			phys:AddVelocity(Vector(0,0,200))
			local rot = Vector(0,0,0)
			rot:Random(-30,30)
			phys:AddAngleVelocity(rot)

			for k,v in pairs(self.parts) do
				if v[2] then
					local mult = popping and 1 or -1
					v[1]:SetLocalPos(v[1]:GetLocalPos()+Vector(0,0,24*mult))
				end
			end

			if (popping and self:IsPlayerHolding() and (self.plyHolding~=nil)) then
				self.plyHolding:DropObject()
			end
			self.held = false

			self.waitingPop = false
			self:SetPopped(popping)
			self:extraPop(popping)
		end
	end

	self:NextThink(CurTime()+self.thinkDelay)
	return true
end

--more wire stuff
function ENT:TriggerInput(name,val)
	if (name=="Popped") then
		if (self:GetPopped() and (val<=0) or (val>0)) then self.waitingPop = true end
	elseif (name=="Power") then
		self:SetPower(val)
	end
end

function ENT:OnRemove()
	if CLIENT then return end

	for k,v in pairs(self.parts) do
		if IsValid(v) then v[1]:Remove() end
	end
end

ENT.held = false
ENT.plyHolding = nil
function ENT:Use(ply)
	if (self:GetPopped() or (not self:GetPhysicsObject():IsMotionEnabled())) then
		self.waitingPop = true

		self:NextThink(CurTime())
		return true
	elseif (ply:IsPlayer()) then
		ply:PickupObject(self)

		self.held = true
		self.plyHolding = ply
	end
end

function ENT:PhysicsCollide(data,collider)
	if (self.held and (not self:IsPlayerHolding())) then
		self.popTime = CurTime()+.2
		self.waitingPop = true
	end
end

local damagetoggle
ENT.lastPop = 0
function ENT:OnTakeDamage(data)
	if (damagetoggle==nil) then damagetoggle = GetConVar("popc_damagetoggle") end
	if ((not damagetoggle:GetBool()) or ((CurTime()-self.lastPop)<.4)) then return end

	self.waitingPop = true
	
	self:NextThink(CurTime())
	return true
end

--fix duplication stuff
function ENT:OnEntityCopyTableFinish(data) data.parts = nil end
function ENT:PreEntityCopy() constraint.ForgetConstraints(self) end

function ENT:power()
	return self:GetPower()+self.conduitPower
end

function ENT:addPart(model,pos,rot,scale,popAffected)
	if (pos==nil) then pos = Vector(0,0,0) end
	if (rot==nil) then rot = Angle(0,0,0) end
	if (scale==nil) then scale = 1 end
	if (popAffected==nil) then popAffected = true end

	local part = ents.Create("prop_dynamic")
	part:SetModel(model)
	part:SetModelScale(scale)
	part:SetParent(self)
	part:SetLocalPos(pos)
	part:SetLocalAngles(rot)

	table.insert(self.parts,{part,popAffected})
	return part
end

--override this
function ENT:extraRemove() end
function ENT:extraPop(popping) end

-- end of actual entity stuff --

CreateConVar("popc_damagetoggle",1)

properties.Add("togglepopcone",{
	MenuLabel="Pop",
	Order=10,
	MenuIcon="icon16/popcone.png",
	Filter=function(self,ent,ply)
		if (not ent.ispopcone) then return false end

		self.MenuLabel = ent:GetPopped() and "Flatten" or "Pop"
		return true
	end,
	Action=function(self,ent)
		self:MsgStart()
		net.WriteEntity(ent)
		self:MsgEnd()
	end,
	Receive=function(self,length,ply)
		local ent = net.ReadEntity()
		ent.waitingPop = true

		ent:NextThink(CurTime())
		return true
	end
})

if SERVER then return end
list.Set("ContentCategoryIcons","Pop Cones","icon16/popcone.png")
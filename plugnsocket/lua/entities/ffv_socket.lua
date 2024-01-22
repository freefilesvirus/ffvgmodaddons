AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Spawnable = true
ENT.PrintName = "Socket"
ENT.Category = "Plugs & Sockets"
ENT.Instructions = "Goes with plug"

ENT.plug = nil
ENT.unplugged = 0
ENT.attachConstraints = {}
ENT.plugWeld = nil

function ENT:Initialize()
	if CLIENT then return end
	self:SetModel("models/props_lab/tpplugholder_single.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:GetPhysicsObject():Wake()

	self:SetUseType(SIMPLE_USE)

	if (WireLib~=nil) then
		WireLib.CreateOutputs(self,{"Attached"})
		WireLib.CreateInputs(self,{"Unplug"})
	end
end

function ENT:TriggerInput(name,val)
	if (((name=="Unplug") and (val>0)) and (IsValid(self.plugWeld) and IsValid(self.plug))) then self:detach(self.plug) end
end

function ENT:Touch(ent)
	if (((not IsValid(self.plugWeld)) and (not IsValid(ent.socketWeld))) and (ent:GetClass()=="ffv_plug")) then
		self:attach(ent)
	end
end

function ENT:Use()
	if IsValid(self.plugWeld) then
		self:detach(self.plug)
	end
end

function ENT:Think()
	if CLIENT then return end
	if ((not IsValid(self.plugWeld)) and (#self.attachConstraints>0)) then
		for k, v in pairs(self.attachConstraints) do
			if (IsValid(v) and v:IsConstraint()) then v:Remove() end
		end
		self.attachConstraints = {}
	end

	if (WireLib~=nil) then WireLib.TriggerOutput(self,"Attached",(IsValid(self.plugWeld) and 1) or 0) end
end

function ENT:attach(ent)
	if ((CurTime()-self.unplugged)<.4) then return end

	self.plug = ent
	ent.socket = self
	if ent:IsPlayerHolding() then ent.ply:DropObject() end

	--get relative pos of stuff to plug
	local plugWelds = constraint.FindConstraints(ent,"Weld")
	local attachedInfo = {}
	for k, v in pairs(plugWelds) do
		if ((v.Ent1==ent) or (v.Ent2==ent)) then
			local info = {
				v.Ent2,
				v.Bone2
			}
			v.Ent2:SetParent(ent)
			table.insert(attachedInfo,info)
		end
	end
	--move the plug
	ent:SetAngles(self:GetAngles())
	local offset = Vector(6,13,10)
	offset:Rotate(self:GetAngles())
	ent:SetPos(self:GetPos()+offset)

	--welds
	for k, v in pairs(attachedInfo) do
		local ent2 = v[1]
		ent2:SetParent(nil)
		--weld it to stuff welded to self
		for k1, v1 in pairs(constraint.FindConstraints(self,"Weld")) do
			if ((v1.Ent1==self) or (v1.Ent2==self)) then
				table.insert(self.attachConstraints,constraint.Weld(v1.Ent2,ent2,0,v[2],-8,true,false))
			end
		end
		table.insert(self.attachConstraints,constraint.Weld(self,ent2,0,v[2],-8,true,false))
	end
	self.plugWeld = constraint.Weld(self,ent,0,0,-8,true,false)
	ent.socketWeld = self.plugWeld

	self:EmitSound("npc/turret_floor/click1.wav")

	if (WireLib~=nil) then
		WireLib.TriggerOutput(self,"Attached",1)
		WireLib.TriggerOutput(ent,"Attached",1)
	end
end

function ENT:detach(ent)
	self.unplugged = CurTime()
	self.plug = nil

	self.plugWeld:Remove()
	ent.socketWeld = nil
	for k, v in pairs(self.attachConstraints) do
		if (IsValid(v) and v:IsConstraint()) then v:Remove() end
	end
	self.attachConstraints = {}

	self:EmitSound("buttons/blip1.wav")

	if (WireLib~=nil) then
		WireLib.TriggerOutput(self,"Attached",0)
		WireLib.TriggerOutput(ent,"Attached",0)
	end
end

function ENT:PostEntityPaste(ply,ent,ents)
	--reset vars
	self.plug = nil
	self.unplugged = 0
	self.attachConstraints = {}
	self.plugWeld = nil

	--destroy socket related welds
	timer.Simple(.01,function()
		--timer here is probably not good but constraints arent created yet when postentitypaste is called
		if (not IsValid(self)) then return end

		for k,v in pairs(constraint.FindConstraints(self,"Weld")) do
			if ((v.Ent1==self) or (v.Ent2==self)) then
				for k1,v1 in pairs(constraint.FindConstraints(v.Ent2,"Weld")) do
					if (((v1.Ent1==v.Ent2) or (v1.Ent2==v.Ent2)) and (v1.forcelimit==-8)) then v1.Constraint:Remove() end
				end
				if (v.forcelimit==-8) then v.Constraint:Remove() end
			end
		end

		--look for nearby plugs
		for k,v in pairs(ents) do
			if ((v:GetClass()=="ffv_plug") and (self:GetPos():DistToSqr(v:GetPos())<310)) then
				--another probably-not-good-solution timer
				timer.Simple(.01,function() if IsValid(v) then self:attach(v) end end)
			end
		end
	end)
end
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Spawnable = true
ENT.PrintName = "Socket"
--ENT.Category = "Sockets & Plugs"
ENT.Category = "ffvjunk"
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
end

function ENT:attach(ent)
	if ((CurTime()-self.unplugged)<.2) then return end

	self.plug = ent

	--get relative pos of stuff to plug
	local plugWelds = constraint.FindConstraints(ent,"Weld")
	local attachedInfo = {}
	for k, v in pairs(plugWelds) do
		local info = {
			v.Ent2,
			v.Bone2
		}
		v.Ent2:SetParent(ent)
		table.insert(attachedInfo,info)
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
			table.insert(self.attachConstraints,constraint.Weld(v1.Ent2,ent2,0,v[2],0,true,false))
		end
		table.insert(self.attachConstraints,constraint.Weld(self,ent2,0,v[2],0,true,false))
	end
	self.plugWeld = constraint.Weld(self,ent,0,0,0,true,false)
	ent.socketWeld = self.plugWeld

	self:EmitSound("npc/turret_floor/click1.wav")
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
end
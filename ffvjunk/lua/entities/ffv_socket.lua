AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Spawnable = true
ENT.PrintName = "Socket"
--ENT.Category = "Sockets & Plugs"
ENT.Category = "ffvjunk"
ENT.Instructions = "Goes with plug"


ENT.plugged = false
ENT.plug = nil
ENT.attachConstraints = {}

function ENT:Initialize()
	if CLIENT then return end
	self:SetModel("models/props_lab/tpplugholder_single.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:GetPhysicsObject():Wake()
end

function ENT:Touch(ent)
	if ((ent:GetClass() == "ffv_plug") and (not self.plugged) and (not ent.plugged)) then
		self:attach(ent)
	end
end

function ENT:Use()
	if (self.plugged == true) and IsValid(self.plug) then
		self:detach(self.plug)
	end
end

function ENT:attach(ent)
	self.plugged = true
	self.plug = ent
	ent.plugged = true

	local oldPos = self:GetPos()
	local oldAngles = self:GetAngles()
	self:SetParent(ent)
	self:SetLocalPos(Vector(-6,-13,-10))
	self:SetLocalAngles(Angle(0,0,0))
	self:SetParent(nil)

	self:GetPhysicsObject():EnableMotion(false)

	ent:SetParent(self)
	local weld = constraint.Weld(ent,self,0,0,0,true,false)
	table.insert(self.attachConstraints, weld)

	for k, v in pairs(constraint.FindConstraints(ent, "Weld")) do
		local ent1 = v["Ent2"]

		-- ent1:SetPos(ent1:GetPos()-newPos)
		-- ent1:SetAngles(ent1:GetAngles()+oldAngles)
		-- ent1:GetPhysicsObject():EnableMotion(false)

		local weld = constraint.Weld(ent1,self,v["Bone2"],0,0,true,false)
		table.insert(self.attachConstraints, weld)
	end

	-- self:SetPos(oldPos)
	-- self:SetAngles(oldAngles)

	self:EmitSound("npc/turret_floor/click1.wav")
end

function ENT:detach(ent)
	timer.Simple(.4, function()
		self.plugged = false
	end)
	self.plug = nil
	ent.plugged = false

	ent:SetParent(nil)

	for k, v in pairs(self.attachConstraints) do
		if not isbool(v) then v:Remove() end
	end
	self.attachConstraints = {}

	self:EmitSound("buttons/blip1.wav")
end

function ENT:good_constraint(con)
	if isbool(con) then return false end
	local ent = con["Ent2"]
	if ent == nil then return false end
	if ent == self then return false end
	if ent == self.plug then return false end
	return true
end
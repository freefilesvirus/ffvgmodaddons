AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "ffv_shredderpart"

function ENT:Initialize()
	self:SetModel("models/props_lab/blastdoor001c.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:GetPhysicsObject():Wake()
end

function ENT:StartTouch(ent)
	if self:GetNWEntity("shredder"):IsValid() then
		self:GetNWEntity("shredder"):shred(ent)
	end
end
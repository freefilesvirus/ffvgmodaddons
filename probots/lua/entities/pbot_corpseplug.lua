AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.Spawnable = false

function ENT:Initialize()
	if CLIENT then return end
	self:SetModel("models/props_lab/tpplug.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:GetPhysicsObject():Wake()
end

function ENT:PostEntityPaste(ply,ent,data) self:Remove() end
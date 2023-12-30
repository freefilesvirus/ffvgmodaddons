AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Spawnable = true
ENT.PrintName = "Plug"
--ENT.Category = "Sockets & Plugs"
ENT.Category = "ffvjunk"
ENT.Instructions = "Goes with socket"

ENT.plugged = false
ENT.socketWeld = nil

function ENT:Initialize()
	if CLIENT then return end
	self:SetModel("models/props_lab/tpplug.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:GetPhysicsObject():Wake()
	self:GetPhysicsObject():SetMass(0)
end
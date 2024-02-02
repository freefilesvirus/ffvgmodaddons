AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Bot Viewer"
ENT.Spawnable = false

ENT.target = nil

function ENT:Initialize()
	if CLIENT then return end

	self:SetModel("models/props_lab/reciever01b.mdl")
	self:SetUseType(CONTINUOUS_USE)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:GetPhysicsObject():Wake()
end

function ENT:Use(ply)
	if (not ply:IsPlayer()) then return end
	drive.PlayerStartDriving(ply,self.target.parts[#self.target.parts],"drive_ffvrobot")
end
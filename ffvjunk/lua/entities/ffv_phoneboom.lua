AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.Spawnable = false

ENT.spawner = nil

function ENT:Initialize()
	if CLIENT then return end

	self:SetModel("models/props_trainstation/payphone_reciever001a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)

	self:EmitSound("vo/npc/male01/docfreeman01.wav")
end

function ENT:PhysicsCollide(data)
	if (data.HitEntity==self.spawner) then return end

	self.spawner.removing = true
	self.spawner:Remove()
	self:Remove()
end
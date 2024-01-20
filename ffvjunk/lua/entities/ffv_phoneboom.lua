AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.Spawnable = false

ENT.spawner = nil

function ENT:Initialize()
	if CLIENT then return end
	self:SetModel("models/props_trainstation/payphone_reciever001a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
end

function ENT:PhysicsCollide(data)
	if (data.HitEntity==self.spawner) then return end
	self.spawner.removing = true
	self.spawner:Remove()
	util.BlastDamage(self,self,self:GetPos(),200,160)
	local effect = EffectData()
	effect:SetOrigin(self:GetPos())
	util.Effect("Explosion",effect)
	self:Remove()
end

if SERVER then return end
killicon.Add("ffv_phoneboom","HUD/killicons/default",Color(255,80,0))
language.Add("ffv_phoneboom","Unknown Number")
AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.Spawnable = true
ENT.Category = "Other"
ENT.PrintName = "Saw Ammo"

function ENT:Initialize()
	if CLIENT then return end
	self:SetModel("models/props_junk/sawblade001a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:GetPhysicsObject():Wake()
	self:SetModelScale(.5)
	self:Activate()

	self.ply = nil
end

function ENT:Use(ply)
	if (not ply:IsPlayer()) then return end
	local wep = ply:GetActiveWeapon()
	if (not (wep:GetClass()=="ffv_hhsaw")) then return end
	if wep.saw then return end
	if wep:get_saw() then self:Remove() end
end

function ENT:PhysicsCollide(data,phys)
	local speed = data.OurOldAngularVelocity:Length()
	local ent = data.HitEntity

	if (not IsValid(ent)) then return end
	if (speed<800) then return end

	ent:TakeDamage(speed/15,self.ply)
	if ((ent:IsNPC() or ent:IsRagdoll()) or ent:IsPlayer()) then
		local effect = EffectData()
		effect:SetOrigin(data.HitPos)
		self:EmitSound("npc/manhack/grind_flesh"..math.random(3)..".wav")
		util.Effect("BloodImpact",effect)
		util.Decal("Blood",data.HitPos+data.HitNormal,data.HitPos-data.HitNormal)

		local phys = self:GetPhysicsObject()
		phys:SetAngleVelocity(Vector(0,0,0))
		phys:SetVelocity(phys:GetVelocity()/2)
	end
end

hook.Add("Initialize","hhsawInit",function()
	if SERVER then return end
	language.Add("ffv_hhsawent","Saw")
	killicon.Add("ffv_hhsawent","HUD/killicons/default",Color(255,80,0,255))
	killicon.Add("ffv_hhsaw","HUD/killicons/default",Color(255,80,0,255))
end)
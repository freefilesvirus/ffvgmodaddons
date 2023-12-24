AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_gmodentity"

function ENT:Initialize()
	if CLIENT then return end
	self:SetModel("models/props_junk/harpoon002a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:GetPhysicsObject():Wake()
end

function ENT:PhysicsCollide(colData, collider)
	local ent = colData.HitEntity
	if (not (ent == game.GetWorld())) then return end
	if ((colData.Speed > 1000) and ((self:GetAngles():Forward() - colData.HitNormal):Length() < 1)) then
		--this is so it makes the hole in the wall with the right sound n stuff
		local bullet = {}
		bullet.Damage = 0
		bullet.Src = self:GetPos()
		bullet.Dir = self:GetAngles():Forward()
		self:FireBullets(bullet)

		self:GetPhysicsObject():EnableMotion(false)
	end
end

function ENT:Use(ply)
	self:Remove()
	if (ply:GetAmmoCount("javelin") > 0) then ply:GiveAmmo(1, "javelin", true) end
	ply:Give("ffv_javelinswep")
end
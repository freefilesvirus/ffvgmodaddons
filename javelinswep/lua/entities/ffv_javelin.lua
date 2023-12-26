AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.awaitingWeld = false
ENT.object = nil
ENT.objectFrozen = false
ENT.objectBone = 0

ENT.hitPos = Vector(0,0,0)
ENT.hitAngle = Angle(0,0,0)

function ENT:Initialize()
	if CLIENT then return end
	self:SetModel("models/props_junk/harpoon002a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:GetPhysicsObject():Wake()
end

function ENT:PhysicsCollide(colData, collider)
	if CLIENT then return end
	local ent = colData.HitEntity
	local speed = colData.OurOldVelocity:Length()
	if (not (ent == game.GetWorld())) then
		if (speed > 2000) then ent:TakeDamage(speed/20,self:GetNWEntity("thrower"),self) end
		if (ent:IsNPC() or ent:IsPlayer()) then return end
	end
	if (colData.TheirSurfaceProps == 76) then return end

	if ((speed > 1000) and ((self:GetAngles():Forward() - colData.HitNormal):Length() < 1)) then
		--this was the best way i could think of to get the hole be the right material and sound
		local bullet = {}
		bullet.Damage = 0
		bullet.Src = self:GetPos()
		bullet.Dir = self:GetAngles():Forward()
		self:FireBullets(bullet)
		-- self:GetPhysicsObject():EnableMotion(false)
		-- if IsValid(ent:GetPhysicsObject()) then
		-- 	self.objectFrozen = ent:GetPhysicsObject():IsMotionEnabled()
		-- 	ent:GetPhysicsObject():EnableMotion(false)
		-- end

		self.awaitingWeld = true
		self.object = ent
		self.hitAngle = self:GetAngles()

		local trace = util.QuickTrace(self:GetPos(),self:GetAngles():Forward()*999,self)
		local gap = self.hitPos-trace.HitPos
		self.hitPos = self:GetPos() + (self.hitAngle:Forward()*((trace.HitPos-self:GetPos()):Length()-40))
		self.objectBone = trace.PhysicsBone
		self:NextThink(CurTime())
	end
end

function ENT:Think()
	if CLIENT then return end
	if self.awaitingWeld then
		self:SetAngles(self.hitAngle)
		self:SetPos(self.hitPos)
		--self:SetPos(self.hitPos+(self:GetAngles():Forward()*10))

		local weldPart = game.GetWorld()
		if IsValid(self.object) then
			weldPart = self.object
			-- weldPart:GetPhysicsObject():EnableMotion(self.objectFrozen)
			-- self:GetPhysicsObject():EnableMotion(true)

		elseif (not (self.object == game.GetWorld())) then
			--it hit an object but its gone by the time we get to here
			weldPart = nil
			-- self:GetPhysicsObject():EnableMotion(true)
		end
		constraint.Weld(self,weldPart,0,self.objectBone,GetConVar("jav_weldforcelimit"):GetInt(),true,false)
		self.awaitingWeld = false
	end
end

function ENT:Use(ply)
	if (self:GetPhysicsObject():GetVelocity():Length() > 1000) then return end
	self:Remove()
	if (ply:GetAmmoCount("javelin") > 0) then ply:GiveAmmo(1, "javelin", true) end
	ply:Give("ffv_javelinswep")
end
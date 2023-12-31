AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.awaitingWeld = false
ENT.object = nil
ENT.objectFrozen = false
ENT.objectBone = 0

ENT.hitPos = Vector(0,0,0)
ENT.hitAngle = Angle(0,0,0)

ENT.hitNpc = false
ENT.numRagdolls = 0
ENT.preHitVel = Vector(0,0,0)
ENT.ragdoll = nil

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
		self.numRagdolls = #ents.FindByClass("prop_ragdoll")
		if (speed > 2000) then ent:TakeDamage(speed/20,self:GetNWEntity("thrower"),self) end

		if (ent:IsPlayer() or ent:IsNPC()) then
			self.hitNpc = true
			self.preHitVel = colData.OurOldVelocity
			self:NextThink(CurTime())
			return
		end
	end
	if (colData.TheirSurfaceProps == 76) then return end
	if (IsValid(self.ragdoll) and (ent == self.ragdoll)) then return end

	if ((speed > 1000) and ((self:GetAngles():Forward() - colData.HitNormal):Length() < 1)) then
		local bullet = {}
		bullet.Damage = 0
		bullet.Src = self:GetPos()
		bullet.Dir = self:GetAngles():Forward()
		if IsValid(self.ragdoll) then bullet.IgnoreEntity = self.ragdoll end
		self:FireBullets(bullet)

		self.awaitingWeld = true
		self.object = ent
		self.hitAngle = self:GetAngles()

		local filter = {self}
		if IsValid(self.ragdoll) then table.insert(filter,self.ragdoll) end
		local trace = util.QuickTrace(self:GetPos(),self:GetAngles():Forward()*999,filter)
		self.hitPos = self:GetPos() + (self.hitAngle:Forward()*((trace.HitPos-self:GetPos()):Length()-40))
		self.objectBone = trace.PhysicsBone
		self:NextThink(CurTime())
	end
end

function ENT:Think()
	if CLIENT then return end
	if self.hitNpc then
		--pierce npc
		if (#ents.FindByClass("prop_ragdoll")>self.numRagdolls) then
			--hit npc died, unless an unrelated ragdoll spawned in the 1 game tick between the collision and now
			local trace = util.QuickTrace(self:GetPos(),self:GetAngles():Forward()*999,self)
			local ent = trace.Entity
			if (not (ent == ents.FindByClass("prop_ragdoll")[#ents.FindByClass("prop_ragdoll")])) then
				self.hitNpc = false
				return
			end

			--move the javelin into the enemy, or if a wall is close enough move it into the wall and weld it to the world
			local trace2 = util.QuickTrace(self:GetPos(),self:GetAngles():Forward()*999,{self,ent})
			if ((trace.HitPos-self:GetPos()):Length()>(trace2.HitPos-self:GetPos()):Length()-40) then
				--hit wall behind ragdoll
				local bullet = {}
				bullet.Damage = 0
				bullet.Src = self:GetPos()
				bullet.Dir = self:GetAngles():Forward()
				if IsValid(self.ragdoll) then bullet.IgnoreEntity = ent end
				self:FireBullets(bullet)

				self:SetPos(self:GetPos() + (self:GetAngles():Forward()*((trace2.HitPos-self:GetPos()):Length()-40)))

				constraint.Weld(self,trace2.Entity,0,trace2.PhysicsBone,GetConVar("jav_weldforcelimit"):GetInt(),true,false)
			else
				self:SetPos(self:GetPos() + (self:GetAngles():Forward()*((trace.HitPos-self:GetPos()):Length())))

				ent:GetPhysicsObject():SetVelocity(ent:GetPhysicsObject():GetVelocity() + (self.preHitVel/2))
				self:GetPhysicsObject():SetVelocity(self.preHitVel/2)
			end

			--ent:SetParent(self)
			constraint.Weld(self,ent,0,trace.PhysicsBone,GetConVar("jav_weldforcelimit"):GetInt(),true,false)
			self.ragdoll = ent
		end
		self.hitNpc = false
		return
	end

	if self.awaitingWeld then
		self:SetAngles(self.hitAngle)
		self:SetPos(self.hitPos)
		if IsValid(self.ragdoll) then
			self.ragdoll:SetPos(self.hitPos-self:GetPos()+self.ragdoll:GetPos())
		end

		local weldPart = game.GetWorld()
		if IsValid(self.object) then
			weldPart = self.object

		elseif (not (self.object == game.GetWorld())) then
			--it hit an object but its gone by the time we get to here
			weldPart = nil
		else
			self:GetPhysicsObject():EnableMotion(false)
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
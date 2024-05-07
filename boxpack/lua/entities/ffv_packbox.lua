AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.Spawnable = false

ENT.contraption = {}

ENT.hasNpc = false
ENT.lastBump = 0

function ENT:Initialize()
	if CLIENT then return end
	self:SetUseType(SIMPLE_USE)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:GetPhysicsObject():Wake()

	self:PrecacheGibs()

	self.lastBump = CurTime()
end

function ENT:Think()
	if CLIENT then return end

	local time = CurTime()-self.lastBump
	if (self.hasNpc and (time>1) and randomChance(math.floor(10-time))) then
		self.lastBump = CurTime()
		local size = 800
		self:GetPhysicsObject():AddAngleVelocity(Vector(math.random(size)-(size/2),math.random(size)-(size/2),math.random(size)-(size/2)))
		self:EmitSound("physics/wood/wood_box_footstep"..math.random(1,4)..".wav")
	end
end

function ENT:Use(ply)
	if (not ply:IsPlayer()) then return end
	ply:PickupObject(self)
end

function ENT:OnTakeDamage(dmg)
	local ply = dmg:GetAttacker()
	if (not ply:IsPlayer()) then return end

	--gibs
	local numents = #ents.GetAll()
	self:GetPhysicsObject():AddVelocity(dmg:GetDamageForce()/24)
	self:GibBreakServer(Vector())
	local allents = ents.GetAll()
	for k=1,#allents-numents do
		allents[numents+k]:SetCollisionGroup(COLLISION_GROUP_WORLD)
	end

	--dupe
	local min,max = self:WorldSpaceAABB()
	duplicator.SetLocalPos(Vector(self:GetPos().x,self:GetPos().y,min.z))
	local ents,cons = duplicator.Paste(ply,self.contraption.Entities,self.contraption.Constraints)
	duplicator.SetLocalPos(vector_origin)

	local vel = self:GetPhysicsObject():GetVelocity()
	for v in pairs(ents) do
		local ent = ents[v]:GetPhysicsObject()
		if IsValid(ent) then
			ent:Wake()
			ent:SetVelocity(vel)
		end
	end

	--undo
	undo.Create("Unpack")
		for v in pairs(ents) do undo.AddEntity(ents[v]) end
		for v in pairs(cons) do undo.AddEntity(cons[v]) end
		if IsValid(gib) then undo.AddEntity(gib) end
		undo.SetPlayer(ply)
	undo.Finish()
	self:Remove()
end

function randomChance(chance)
	--its just a 1 in blank chance, cause im lazy and is quicker than typing out (math.random(2)==1)
	return (math.random(chance)==1)
end
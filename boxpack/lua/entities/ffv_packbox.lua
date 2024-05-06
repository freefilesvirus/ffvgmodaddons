AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.Spawnable = false

ENT.contraption = {}

function ENT:Initialize()
	if CLIENT then return end
	self:PhysicsInit(SOLID_VPHYSICS)
	self:GetPhysicsObject():Wake()
	self:PrecacheGibs()
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
	self:GibBreakServer(dmg:GetDamageForce()/8)
	local allents = ents.GetAll()
	for k=1,#allents-numents do
		allents[numents+k]:SetCollisionGroup(COLLISION_GROUP_WORLD)
	end

	--dupe
	duplicator.SetLocalPos(self:GetPos())
	local ents,cons = duplicator.Paste(ply,self.contraption.Entities,self.contraption.Constraints)
	self:Remove()
	duplicator.SetLocalPos(vector_origin)

	for v in pairs(ents) do
		local ent = ents[v]
		if IsValid(ent:GetPhysicsObject()) then ent:GetPhysicsObject():Wake() end
	end

	--undo
	undo.Create("Unpack")
		for v in pairs(ents) do undo.AddEntity(ents[v]) end
		for v in pairs(cons) do undo.AddEntity(cons[v]) end
		if IsValid(gib) then undo.AddEntity(gib) end
		undo.SetPlayer(ply)
	undo.Finish()
end
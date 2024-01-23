AddCSLuaFile()
ENT.Base = "base_gmodentity"
ENT.Type = "anim"

ENT.PrintName = "Hook"
ENT.Spawnable = false

ENT.weldedEnts = {}
ENT.waitingWelds = {}

ENT.ply = nil

function ENT:Initialize()
	if CLIENT then return end
	self:SetModel("models/props_junk/meathook001a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
end

local rope = Material("cable/rope")
function ENT:Draw()
	self:DrawModel()
	if IsValid(self.ply) then
		local vec = Vector(0,3,21)
		vec:Rotate(self:GetAngles())
		render.SetMaterial(rope)
		render.DrawBeam(self.ply:GetBonePosition(self.ply:LookupBone("ValveBiped.Bip01_R_Hand")),self:GetPos()+vec,2,1,10,Color(255,255,255,255))
	end
end

function ENT:PhysicsCollide(data,phys)
	if (data.HitEntity==game.GetWorld()) then return end
	if data.HitEntity:IsPlayer() then return end
	if (data.HitEntity:IsNPC() or data.HitEntity:IsNextBot()) then return end
	if data.HitEntity:IsVehicle() then return end
	if (data.HitEntity:GetClass()=="ffv_rafthookent") then return end
	for k,v in pairs(self.weldedEnts) do
		if (v==data.HitEntity) then return end
	end

	table.insert(self.weldedEnts,data.HitEntity)
	table.insert(self.waitingWelds,data.HitEntity)
end

function ENT:Think()
	for k,v in pairs(self.waitingWelds) do
		table.remove(self.waitingWelds,k)
		if IsValid(v) then
			v:SetParent(self)
		end
	end

	self:NextThink(CurTime())
end

function ENT:OnRemove()
	for k,v in pairs(self.weldedEnts) do
		if IsValid(v) then
			v:SetParent(nil)

			local min,max = v:WorldSpaceAABB()
			v:SetPos(v:GetPos()+Vector(0,0,self:GetPos().z-min.z,0,9999))
		end
	end
end
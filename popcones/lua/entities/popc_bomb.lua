AddCSLuaFile()

DEFINE_BASECLASS("popc_base")

ENT.Base = "popc_base"
ENT.Spawnable = true
ENT.Category = "Pop Cones"
ENT.PrintName = "Bomb"

ENT.waitingPop = false

ENT.usesConduit = true

function ENT:setupParts()
	local pivot = self:addPart("models/Combine_Helicopter/helicopter_bomb01.mdl",Vector(0,0,-4),Angle(0,0,0),.1)
	local bomb = self:addPart("models/dynamite/dynamite.mdl",Vector(0,0,-10),Angle(0,90,0))
	self:addPart("models/dav0r/tnt/tnt.mdl",Vector(-8,6,-10),Angle(0,20,90),1,false)

	bomb:SetParent(pivot)
	local ang = Angle(0,0,0)
	ang:Random(-30,30)
	pivot:SetLocalAngles(ang)
	bomb:SetParent(self)
	table.remove(self.parts,1)
	pivot:Remove()
end

function ENT:extraPop()
	timer.Simple(.5,function()
		if (not IsValid(self)) then return end
		
		local power = self:power()
		util.BlastDamage(self,self,self:GetPos(),96+(32*power),60+(30*power))

		local effectdata = EffectData()
		effectdata:SetOrigin(self:GetPos())
		util.Effect("Explosion",effectdata)

		self:Remove()
	end)
end

if SERVER then return end
language.Add("popc_bomb","Bomb")
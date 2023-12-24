AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

SWEP.Weight = 999
SWEP.AutoSwitchTo = true
SWEP.AutoSwitchFrom = false

SWEP.grenadeProp = nil
SWEP.time = 3

function SWEP:Holster() return false end
function SWEP:CanBePickedUpByNPCs() return true end

function SWEP:Equip()
	local ply = self:GetOwner()

	ply:SelectWeapon(self)

	self.grenadeProp = ents.Create("npc_grenade_frag")
	self.grenadeProp:SetPos(ply:GetPos())
	self.grenadeProp:Spawn()
	self.grenadeProp:Input("SetTimer", nil, nil, self.time)
	self.grenadeProp:FollowBone(ply, ply:LookupBone("ValveBiped.Bip01_R_Hand"))
	self.grenadeProp:SetLocalPos(Vector(3,-2,-.2))
	self.grenadeProp:SetLocalAngles(Angle(-20,0,180))
	self.grenadeProp:PhysicsDestroy()

	timer.Simple(self.time, function()
		if (not IsValid(ply)) or (not IsValid(self)) then return end
		if ply:GetActiveWeapon() == self then ply:SetHealth(1) end
		if IsValid(self) then self:Remove() end
	end)
end
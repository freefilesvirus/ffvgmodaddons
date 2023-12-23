AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

SWEP.Weight = 999
SWEP.AutoSwitchTo = true
SWEP.AutoSwitchFrom = false

SWEP.grenadeProp = nil

function SWEP:Holster() return false end
function SWEP:CanPrimaryAttack() return false end
function SWEP:CanSecondaryAttack() return false end
function SWEP:CanBePickedUpByNPCs() return true end

function SWEP:Equip()
	local ply = self:GetOwner()

	ply:SelectWeapon(self)
	util.AddNetworkString("grenadeProp")
	--self:SetHoldType(self.HoldType)

	self.grenadeProp = ents.Create("npc_grenade_frag")
	self.grenadeProp:SetPos(ply:GetPos())
	self.grenadeProp:Spawn()
	self.grenadeProp:Input("SetTimer", nil, nil, 3)
	self.grenadeProp:FollowBone(ply, ply:LookupBone("ValveBiped.Bip01_R_Hand"))
	self.grenadeProp:SetLocalPos(Vector(3,-2,-.2))
	self.grenadeProp:SetLocalAngles(Angle(-20,0,180))
	self.grenadeProp:PhysicsDestroy()

	if ply:IsPlayer(ply) then
		net.Start("grenadeProp")
			net.WriteEntity(self.grenadeProp)
		net.Send(ply)
	end

	timer.Simple(3, function()
		if ply:GetActiveWeapon() == self then ply:SetHealth(1) end
		self:Remove()
	end)
end
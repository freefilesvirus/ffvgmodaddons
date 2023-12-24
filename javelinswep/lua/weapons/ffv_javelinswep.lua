SWEP.Category = "Other"
SWEP.PrintName = "Javelin"
SWEP.Spawnable = true
SWEP.DrawAmmo = true
SWEP.Slot = 1

SWEP.ViewModel = ""
SWEP.WorldModel = ""

SWEP.Author = "freefilesvirus"

SWEP.Primary.DefaultClip = 1
SWEP.Primary.ClipSize = -1
SWEP.Primary.Ammo = "javelin"
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Ammo = ""

SWEP.javelin = nil

function SWEP:SecondaryAttack() return end

function SWEP:Initialize()
	self:SetHoldType("grenade")
end

function SWEP:Holster()
	if CLIENT then return end
	if IsValid(self.javelin) then self.javelin:Remove() end
	return true
end

function SWEP:Deploy()
	if CLIENT then return end
	if IsValid(self.javelin) then self.javelin:Remove() end
	local ply = self:GetOwner()
	self.javelin = ents.Create("prop_physics")
	self.javelin:SetModel("models/props_junk/harpoon002a.mdl")
	self.javelin:SetPos(ply:GetPos())
	self.javelin:FollowBone(ply, ply:LookupBone("ValveBiped.Bip01_R_Hand"))
	self.javelin:SetLocalPos(Vector(3,20,0))
	self.javelin:SetLocalAngles(Angle(180,90,0))
end

function SWEP:PrimaryAttack()
	self:ShootEffects()
	self:TakePrimaryAmmo(1)
	if CLIENT then return end
	local ply = self:GetOwner()

	local javelin = ents.Create("ffv_javelin")
	javelin:Spawn()
	javelin:SetNWEntity("thrower", ply)
	javelin:SetPos(ply:GetShootPos())
	javelin:SetAngles(ply:EyeAngles() + Angle(5,0,0))
	javelin:GetPhysicsObject():SetVelocity(ply:GetAimVector() * 2000)

	javelin:SetCustomCollisionCheck(true)
	timer.Simple(.1, function()
		javelin:SetCustomCollisionCheck(false)
	end)

	if (self:Ammo1() < 1) then
		if IsValid(self.javelin) then self.javelin:Remove() end
		ply:StripWeapon("ffv_javelinswep")
	end
end

hook.Add("ShouldCollide", "javelinSkipThrownPly", function(ent1, ent2)
	if ((ent1:GetModel() == "models/props_junk/harpoon002a.mdl") and ent2:IsPlayer()) then
		if (not IsValid(ent1:GetNWEntity("thrower"))) then return true end
		if (ent1:GetNWEntity("thrower") == ent2) then return false end
	elseif ((ent2:GetModel() == "models/props_junk/harpoon002a.mdl") and ent1:IsPlayer()) then
		if (not IsValid(ent2:GetNWEntity("thrower"))) then return true end
		if (ent2:GetNWEntity("thrower") == ent1) then return false end
	end
end)

hook.Add("Initialize", "javelinAmmo", function()
	game.AddAmmoType({name = "javelin"})
	if SERVER then return end
	language.Add("javelin_ammo", "Javelins")
	language.Add("ffv_javelin", "Javelin")
end)
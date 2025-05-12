SWEP.PrintName="Cop Gun"
SWEP.Slot=3
SWEP.Base="base_sck"
SWEP.DrawAmmo=false
SWEP.Primary.DefaultClip=-1
SWEP.Primary.ClipSize=-1
SWEP.Secondary.DefaultClip=-1
SWEP.Secondary.ClipSize=-1

SWEP.WElements = {
	["shade"] = { type = "Model", model = "models/props_c17/lampShade001a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "base", pos = Vector(0, 0, 26), angle = Angle(180, 0, 0), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["base"] = { type = "Model", model = "models/props_c17/canister01a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(0.791, 0.518, -6.753), angle = Angle(80, -3.507, 180), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["wheel"] = { type = "Model", model = "models/props_c17/pulleywheels_small01.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "base", pos = Vector(0, 0, -35), angle = Angle(90, 0, 0), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["paint"] = { type = "Model", model = "models/props_junk/metal_paintcan001a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "base", pos = Vector(0, 0, 14), angle = Angle(0, 0, 0), size = Vector(1.1, 1.1, 1.1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["rack"] = { type = "Model", model = "models/props_trainstation/traincar_rack001.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "base", pos = Vector(-7, 0, -11), angle = Angle(180, 0, 90), size = Vector(0.28, 0.28, 0.28), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}
SWEP.VElements = {
	["base"] = { type = "Model", model = "models/props_c17/canister01a.mdl", bone = "base", rel = "", pos = Vector(-0.519, 0.518, -1.558), angle = Angle(0, -90, 0), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["rack"] = { type = "Model", model = "models/props_trainstation/traincar_rack001.mdl", bone = "ValveBiped.Bip01_Spine4", rel = "base", pos = Vector(-7, 0, -11), angle = Angle(180, 0, 90), size = Vector(0.28, 0.28, 0.28), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["paint"] = { type = "Model", model = "models/props_junk/metal_paintcan001a.mdl", bone = "ValveBiped.Bip01_Spine4", rel = "base", pos = Vector(0, 0, 14), angle = Angle(0, 0, 0), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["shade"] = { type = "Model", model = "models/props_c17/lampShade001a.mdl", bone = "ValveBiped.Bip01_Spine4", rel = "base", pos = Vector(0, 0, 26), angle = Angle(180, 0, 0), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}
SWEP.HoldType = "rpg"
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_rpg.mdl"
SWEP.WorldModel = "models/props_c17/canister01a.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = false
SWEP.ViewModelBoneMods = {}

SWEP.parts={}
function SWEP:Initialize()
	self.BaseClass.Initialize(self)

	if CLIENT then return end

	local i=0
	for k,e in pairs(self.WElements) do
		if (i>0) then
			local part = ents.Create("prop_dynamic")
			part:SetParent(self)
			part:SetModel(e.model)
			if (k~="base") then 
				part:SetLocalPos(e.pos)
				part:SetLocalAngles(e.angle)
			else
				part:SetLocalPos(Vector(0,0,0))
				part:SetLocalAngles(Angle(0,0,0))
			end
			part:SetModelScale(e.size.x)
			table.insert(self.parts,part)
		end
		i=(i+1)
	end
end

function SWEP:Equip()
	for k,v in pairs(self.parts) do v:Remove() end
	self.parts={}
end

SWEP.lastFired=0
function SWEP:PrimaryAttack()
	if (not self:CanPrimaryAttack()) then return end

	self.lastFired=CurTime()
	self:ShootBullet(10,12,.1)

	self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self:GetOwner():SetAnimation(PLAYER_ATTACK1)
	self:EmitSound("weapons/shotgun/shotgun_fire7.wav")
end

function SWEP:CanPrimaryAttack()
	if ((CurTime()-self.lastFired)>1) then return true end
	self:EmitSound("weapons/pistol/pistol_empty.wav")
	return false
end

function SWEP:CanSecondaryAttack() return false end
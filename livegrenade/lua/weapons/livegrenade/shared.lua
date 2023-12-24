SWEP.Author = "freefilesvirus"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Base = "weapon_base"

SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/w_grenade.mdl"

SWEP.Primary.Ammo = "none"
SWEP.Secondary.Ammo = "none"

function SWEP:PrimaryAttack() return false end
function SWEP:SecondaryAttack() return false end
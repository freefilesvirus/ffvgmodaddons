SWEP.PrintName = "Money Gun"
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_pistol.mdl"
SWEP.WorldModel = ""

SWEP.Instructions = "Finally, a use for all that gambling money"

SWEP.empty = Sound("weapons/pistol/pistol_empty.wav")
SWEP.fire = Sound("physics/cardboard/cardboard_box_impact_bullet4.wav")

function SWEP:Initialize() self:SetHoldType("normal") end

function SWEP:SecondaryAttack() self:makeDollar("10dollar",10) end
function SWEP:PrimaryAttack() self:makeDollar("dollar",1) end

function SWEP:makeDollar(image,cost)
	if CLIENT then return end

	local ply = self:GetOwner()

	if (ply:GetNWInt("money")<cost) then
		ply:EmitSound(self.empty)
		return
	end
	ply:EmitSound(self.fire)
	addMoney(ply,-cost)

	local dollar = ents.Create("box_dollar")
	dollar:SetNWString("image",image)
	dollar:Spawn()
	dollar.velocity = ((ply:GetAimVector()*2)+Vector(0,0,1)+(ply:GetVelocity()/60))
	dollar:SetPos(ply:GetShootPos()-ply:GetAimVector())
end
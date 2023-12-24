SWEP.Category = "ffvjunk"
SWEP.Spawnable = true
SWEP.PrintName = "Undo Gun"
SWEP.DrawAmmo = false
SWEP.Slot = 1

SWEP.ViewModel = "models/weapons/c_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.UseHands = true

SWEP.Author = "freefilesvirus"
SWEP.Instructions = "Shoot a guy then undo the damage"

SWEP.cooldown = false
SWEP.shootsound = Sound("weapons/pistol/pistol_fire2.wav")

function SWEP:PrimaryAttack()
	if self.cooldown then return end

	self:EmitSound(self.shootsound)

	local ply = self:GetOwner()
	local bullet = {}
	local dmg = math.random(4,8)
	bullet.Damage = dmg
	bullet.Attacker = ply
	bullet.Dir = ply:GetAimVector()
	bullet.Src = ply:GetShootPos()
	self:FireBullets(bullet)

	--the actual undo stuff
	if ply:IsPlayer() then
		local trace = ply:GetEyeTrace()
		if (IsValid(trace.Entity) and SERVER) then
			local ent = trace.Entity

			undo.Create("Damage")
				undo.AddFunction(function()
					if (not IsValid(ent)) then return end
					ent:SetHealth(ent:Health() + dmg)
				end)
				undo.SetPlayer(ply)
			undo.Finish()
		end
		ply:ViewPunch(Angle(-1,0,0))
	end
	self:ShootEffects()

	self.cooldown = true
	timer.Simple(.1, function() self.cooldown = false end)
end

function SWEP:SecondaryAttack()
	return
end
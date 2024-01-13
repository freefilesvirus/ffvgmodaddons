SWEP.Category = "fsfv"
SWEP.Spawnable = true
SWEP.PrintName = "Boarehn"
SWEP.Slot = 2
SWEP.Base = "base_sck"

SWEP.Primary.ClipSize = -1
SWEP.Primary.Automatic = true
SWEP.Secondary.Ammo = ""

SWEP.shooting = false
SWEP.lastFire = 0
SWEP.numFires = 0
SWEP.endAmmo = 0
SWEP.overcharged = false
SWEP.overchargeVal = 40

SWEP.sound = {
	fire = Sound("buttons/blip1.wav"),
	overcharge = Sound("ambient/energy/zap1.wav"),
	empty = Sound("buttons/button11.wav"),
	recharged = Sound("buttons/button17.wav")
}

function SWEP:SecondaryAttack() end
function SWEP:Reload() end
function SWEP:extraHolster() self.shooting = false end
function SWEP:extraInit() self:SetClip1(0) end
function SWEP:extraVM()
	local clip = self:Clip1()
	self.VElements.wheel.angle = Angle(0,0,clip*3)
	self.VElements.wheel.pos = Vector(-7+(clip/(self.overchargeVal/2)),0.15,0.15)
end
function SWEP:extraWM()
	local clip = self:Clip1()
	self.WElements.wheel.angle = Angle(0,0,clip*3)
	self.WElements.wheel.pos = Vector(-9+(clip/(self.overchargeVal/2)),0.15,0.15)
end

function SWEP:PrimaryAttack()
	if CLIENT then return end
	--gun stuff
	local time = math.Clamp(.4-(self.numFires/8),.06,.4)
	if self.overcharged then
		self:EmitSound(self.sound.empty)
	else
		self:SetClip1(self:Clip1()+1)
		if (self:Clip1()>(self.overchargeVal-2)) then
			--overcharge
			self.overcharged = true
			self:SetClip1(self.overchargeVal)
			CreateSound(self,self.sound.overcharge):PlayEx(1,100)
		else
			--fires
			CreateSound(self,self.sound.fire):PlayEx(1,100+math.Clamp(self.numFires,0,70))
			self:ShootEffects()
			--maybe replace this with some sort of laser? like the pomson or something

		end
	end

	if self.overcharged then
		self:SetNextPrimaryFire(CurTime()+1)
		return
	end
	self.shooting = true
	self.lastFire = CurTime()
	self.numFires = self.numFires+1
	self:SetNextPrimaryFire(CurTime()+time)
	timer.Create("stopShooting"..self:EntIndex(),time+.1,1,function()
		if (not self:IsValid()) then return end
		--ply stops firing
		self.shooting = false
		self.lastFire = CurTime()
		self.endAmmo = self:Clip1()
		self.numFires = 0
		self:GetOwner():ChatPrint("a")
	end)
end

function SWEP:Think()
	if CLIENT then return end
	if self.shooting then return end
	--whatever-eths of a second since last fire
	local ticks = (CurTime()-self.lastFire)*20
	if ((self:Clip1()<1) and self.overcharged) then
		--the gun is fully charged
		CreateSound(self,self.sound.recharged):PlayEx(1,100)
		self.overcharged = false
	end

	local wait = 1
	if self.overcharged then wait = .6 end
	self:SetClip1(math.Clamp(5+self.endAmmo-math.Round(ticks*wait),0,self.endAmmo))
end

--sck stuff
--weapon
SWEP.HoldType = "smg"
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_smg1.mdl"
SWEP.WorldModel = "models/weapons/w_smg1.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = false
SWEP.ViewModelBoneMods = {
    ["ValveBiped.base"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
}
--ironsights
SWEP.IronSightsPos = Vector(0, 0, 0)
SWEP.IronSightsAng = Vector(0, -10, 0)
--vm
SWEP.VElements = {
    ["pole"] = { type = "Model", model = "models/props_c17/signpole001.mdl", bone = "ValveBiped.base", rel = "base", pos = Vector(-1.961, 0.15, 0.15), angle = Angle(90, 0, 0), size = Vector(0.3, 0.3, 0.059), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
    ["trigger"] = { type = "Model", model = "models/props_c17/canister01a.mdl", bone = "ValveBiped.base", rel = "base", pos = Vector(4.5, 0, -4), angle = Angle(180, 90, 0), size = Vector(0.15, 0.15, 0.15), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
    ["wheel"] = { type = "Model", model = "models/props_c17/pulleywheels_large01.mdl", bone = "ValveBiped.base", rel = "base", pos = Vector(-7, 0.15, 0.15), angle = Angle(0, 0, 0), size = Vector(0.1, 0.1, 0.1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
    ["base"] = { type = "Model", model = "models/props_wasteland/laundry_washer003.mdl", bone = "ValveBiped.base", rel = "", pos = Vector(0, -0.801, 1), angle = Angle(90, -90, 0), size = Vector(0.079, 0.079, 0.079), color = Color(255, 255, 255, 255), surpresslightning = true, material = "", skin = 0, bodygroup = {} },
    ["hold"] = { type = "Model", model = "models/props_trainstation/trainstation_post001.mdl", bone = "ValveBiped.base", rel = "base", pos = Vector(-3.024, 0, 0), angle = Angle(0, 0, 180), size = Vector(0.28, 0.28, 0.1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
    ["shoot"] = { type = "Model", model = "models/props_wasteland/prison_lamp001c.mdl", bone = "ValveBiped.base", rel = "base", pos = Vector(4, 0, 0), angle = Angle(90, 0, 0), size = Vector(0.3, 0.3, 0.3), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}
--wm
SWEP.WElements = {
    ["trigger"] = { type = "Model", model = "models/props_c17/canister01a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "base", pos = Vector(5.135, 0, -4), angle = Angle(180, 90, 0), size = Vector(0.15, 0.15, 0.15), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
    ["hold"] = { type = "Model", model = "models/props_trainstation/trainstation_post001.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "base", pos = Vector(-5.058, 0, 0), angle = Angle(0, 0, 180), size = Vector(0.28, 0.28, 0.1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
    ["pole"] = { type = "Model", model = "models/props_c17/signpole001.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "base", pos = Vector(-4, 0.15, 0.15), angle = Angle(90, 0, 0), size = Vector(0.3, 0.3, 0.059), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
    ["wheel"] = { type = "Model", model = "models/props_c17/pulleywheels_large01.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "base", pos = Vector(-10, 0.15, 0.15), angle = Angle(0, 0, 0), size = Vector(0.1, 0.1, 0.1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
    ["shoot"] = { type = "Model", model = "models/props_wasteland/prison_lamp001c.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "base", pos = Vector(7, 0, 0), angle = Angle(90, 0, 0), size = Vector(0.3, 0.3, 0.3), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
    ["base"] = { type = "Model", model = "models/props_wasteland/laundry_washer003.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(8.376, 1.253, -5.455), angle = Angle(-7.889, 0, 180), size = Vector(0.119, 0.079, 0.079), color = Color(255, 255, 255, 255), surpresslightning = true, material = "", skin = 0, bodygroup = {} }
}
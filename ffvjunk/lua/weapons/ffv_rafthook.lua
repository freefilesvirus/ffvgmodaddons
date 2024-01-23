SWEP.Category = "ffvjunk"
SWEP.Spawnable = true
SWEP.PrintName = "Hook"
SWEP.Slot = 4
SWEP.Base = "base_sck"

SWEP.DrawAmmo = false
SWEP.Primary.Automatic = true

SWEP.hook = nil
SWEP.charge = 0

SWEP.shooting = false
SWEP.startFire = 0
SWEP.lastFire = 0
SWEP.cancelFire = false

function SWEP:Reload() end

function SWEP:ShootEffects() self:GetOwner():SetAnimation(PLAYER_ATTACK1) end
function SWEP:extraHolster()
	self.shooting = false
	if CLIENT then return end

	self:killHook()
end

function SWEP:Think()
	if CLIENT then
		local vmGoal = 0
		if self.shooting then vmGoal = 1 end
		self.IronSightsAng = Vector(math.Approach(self.IronSightsAng.x,vmGoal*3,(self.IronSightsAng.x-(vmGoal*3))/12),0,0)
		self.IronSightsPos = Vector(0,math.Approach(self.IronSightsPos.y,-vmGoal*2,(self.IronSightsPos.y-(-vmGoal*2))/12),0)
		return
	end

	if IsValid(self.hook) then
		if (self:GetOwner():GetPos():DistToSqr(self.hook:GetPos())<3000) then self:killHook() end
	end
end

function SWEP:PrimaryAttack()
	if CLIENT then return end
	
	if (not self.shooting) then
		self.startFire = CurTime()
		net.Start("ffvHookShooting")
		net.WriteBool(true)
		net.Send(self:GetOwner())
	end
	self.shooting = true
	self.lastFire = CurTime()

	if IsValid(self.hook) then
		local ply = self:GetOwner()
		local trace = util.TraceLine({
			start=ply:GetPos(),
			endpos=ply:GetPos()-Vector(0,0,36),
			filter=ply
		})
		self.hook:GetPhysicsObject():AddVelocity((trace.HitPos-self.hook:GetPos()):GetNormalized()*7)
	end

	timer.Create("stopShooting"..self:EntIndex(),.1,1,function()
		if (not self:IsValid()) then return end
		--ply stops firing
		self.shooting = false
		self.lastFire = CurTime()
		net.Start("ffvHookShooting")
		net.WriteBool(false)
		net.Send(self:GetOwner())

		if ((not self.cancelFire) and (not IsValid(self.hook))) then
			--throw hook
			self.VElements.hook.size = Vector(.01,.01,.01)
			self.WElements.hook.size = Vector(.01,.01,.01)
			local ply = self:GetOwner()
			local hook = ents.Create("ffv_rafthookent")
			local trace = util.TraceLine({
				start=ply:GetShootPos(),
				endpos=ply:GetShootPos()+(ply:GetAimVector()*80),
				filter=ply
			})
			hook:SetPos(trace.HitPos-(ply:GetAimVector()*20))
			hook:SetAngles(Angle(0,ply:EyeAngles().y-90,-ply:EyeAngles().x+90))
			hook:Spawn()
			hook:GetPhysicsObject():AddVelocity(ply:GetAimVector()*700*self.charge)
			hook.ply = ply

			self.hook = hook
			net.Start("ffvHookEnt")
			net.WriteEntity(hook)
			net.Send(self:GetOwner())
		end

		self.charge = 0
		net.Start("ffvHookCharge")
		net.WriteFloat(self.charge)
		net.Send(self:GetOwner())
		self.cancelFire = false
	end)

	if self.cancelFire then return end

	self.charge = math.Clamp((CurTime()-self.startFire),0,1)
	net.Start("ffvHookCharge")
	net.WriteFloat(self.charge)
	net.Send(self:GetOwner())
end

function SWEP:SecondaryAttack()
	if CLIENT then return end

	if self.shooting then
		self.cancelFire = true
		net.Start("ffvHookShooting")
		net.WriteBool(false)
		net.Send(self:GetOwner())

		self.charge = 0
		net.Start("ffvHookCharge")
		net.WriteFloat(self.charge)
		net.Send(self:GetOwner())
		return
	end

	if IsValid(self.hook) then self:killHook() end
end

function SWEP:killHook()
	self.VElements.hook.size = Vector(.699,.699,.699)
	self.WElements.hook.size = Vector(1,1,1)

	if IsValid(self.hook) then
		self.hook:Remove()
		self.hook = nil
		net.Start("ffvHookEnt")
		net.WriteEntity(nil)
		net.Send(self:GetOwner())

		if self.shooting then self.cancelFire = true end
		self.charge = 0
		net.Start("ffvHookCharge")
		net.WriteFloat(self.charge)
		net.Send(self:GetOwner())
	end
end

--sck
--weapon
SWEP.HoldType = "melee"
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_smg1.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = false
SWEP.ViewModelBoneMods = {
    ["ValveBiped.Bip01_L_Clavicle"] = { scale = Vector(1, 1, 1), pos = Vector(-15.631, 0, 30), angle = Angle(0, 0, 0) },
    ["ValveBiped.base"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, -10, 0), angle = Angle(0, 0, 0) }
}
--ironsights
SWEP.IronSightsPos = Vector(0, 0, 0)
SWEP.IronSightsAng = Vector(0, 0, 0)
--vm
SWEP.VElements = {
    ["hook"] = { type = "Model", model = "models/props_junk/meathook001a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(6.177, 2.976, 2.282), angle = Angle(0, 50, 12), size = Vector(0.699, 0.699, 0.699), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}
--wm
SWEP.WElements = {
    ["hook"] = { type = "Model", model = "models/props_junk/meathook001a.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(2, 4, 4), angle = Angle(10, 0, 0), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

--hud stuff
if SERVER then
	util.AddNetworkString("ffvHookCharge")
	util.AddNetworkString("ffvHookShooting")
	util.AddNetworkString("ffvHookEnt")
	return
end

net.Receive("ffvHookCharge",function()
	local ply = LocalPlayer()
	local wep = ply:GetActiveWeapon()
	if (not IsValid(wep)) then return end
	if (not (wep:GetClass()=="ffv_rafthook")) then return end
	wep.charge = net.ReadFloat()
end)

net.Receive("ffvHookShooting",function()
	local ply = LocalPlayer()
	local wep = ply:GetActiveWeapon()
	if (not IsValid(wep)) then return end
	if (not (wep:GetClass()=="ffv_rafthook")) then return end
	wep.shooting = net.ReadBool()
end)

net.Receive("ffvHookEnt",function()
	local ply = LocalPlayer()
	local wep = ply:GetActiveWeapon()
	if (not IsValid(wep)) then return end
	if (not (wep:GetClass()=="ffv_rafthook")) then return end
	local hook = net.ReadEntity()
	wep.hook = hook
	hook.ply = ply
	if IsValid(hook) then
		wep.VElements.hook.size = Vector(.01,.01,.01)
		wep.WElements.hook.size = Vector(.01,.01,.01)
	else
		wep.VElements.hook.size = Vector(.699,.699,.699)
		wep.WElements.hook.size = Vector(1,1,1)
	end
end)

hook.Add("PostDrawHUD","ffvHookHUD",function()
	local ply = LocalPlayer()
	local wep = ply:GetActiveWeapon()
	if (not IsValid(wep)) then return end
	if (not (wep:GetClass()=="ffv_rafthook")) then return end
	local charge = wep.charge

	local rad = 25
	local extraRad = 8
	surface.DrawCircle(ScrW()/2,ScrH()/2,rad,255,255,255)

	if ((charge>0) and (not IsValid(wep.hook))) then
		for k=0,extraRad*2 do
			local center = Vector( ScrW() / 2, ScrH() / 2, 0 )
			local scale = Vector( rad+((extraRad-k)/2), rad+((extraRad-k)/2), 0 )
			local segmentdist = 180 / ( 2 * math.pi * math.max( scale.x, scale.y ) / 2 )
			surface.SetDrawColor( 255, 255, 255, 255 )
			for a = 0, (360*charge) - segmentdist, segmentdist do
				a=-(a-90)
				surface.DrawLine( center.x + math.cos( math.rad( a ) ) * scale.x, center.y - math.sin( math.rad( a ) ) * scale.y, center.x + math.cos( math.rad( a + segmentdist ) ) * scale.x, center.y - math.sin( math.rad( a + segmentdist ) ) * scale.y )
			end
		end
	end
end)
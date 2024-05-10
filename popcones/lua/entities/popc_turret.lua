AddCSLuaFile()

DEFINE_BASECLASS("popc_base")

ENT.Base = "popc_base"
ENT.Spawnable = true
ENT.Category = "Pop Cones"
ENT.PrintName = "Turret"

ENT.usesConduit = true

ENT.thinkDelay = 0

ENT.target = nil

ENT.lastShoot = 0
ENT.shootDelay = .4

function ENT:setupParts()
	local gear = self:addPart("models/Mechanics/gears/gear12x12_small.mdl",Vector(0,0,-8),Angle(0,0,90),.6)
	self:addPart("models/weapons/w_irifle.mdl",Vector(-10,0,-8),Angle(0,0,0),1,false):SetParent(gear)
end

local shootSound = Sound("weapons/ar2/fire1.wav")
function ENT:Think()
	BaseClass.Think(self)
	
	if CLIENT then return end

	if (not self:GetPopped()) then
		self.parts[1][1]:SetLocalAngles(Angle(-40,self.parts[1][1]:GetLocalAngles().y,90))
		return
	else
		self.parts[1][1]:SetLocalAngles(Angle(0,self.parts[1][1]:GetLocalAngles().y,90))
	end

	local power = self:power()
	if IsValid(self.target) then
		--vector math... those 3 lines took half an hour
		local ang = self:GetPos()-self.target:WorldSpaceCenter()+Vector(0,0,20)
		ang:Rotate(-self:GetAngles())
		ang = ang:Angle()

		self.parts[1][1]:SetLocalAngles(Angle(ang.x,ang.y,90))

		if ((CurTime()-self.lastShoot)>(self.shootDelay/power)) then
			--shoot
			self.lastShoot = CurTime()

			self:EmitSound(shootSound)
			local spread = .004*power
			self.parts[2][1]:FireBullets({
				Attacker=self,
				Damage=6,
				Force=2,
				TracerName="AR2Tracer",
				Dir=-self.parts[2][1]:GetForward(),
				Src=self.parts[2][1]:GetPos(),
				Spread=Vector(spread,spread,0)
			})

			if (util.TraceLine({start=self:GetPos(),endpos=self.target:WorldSpaceCenter(),filter=self}).Entity~=self.target) then 
				self.target = nil
				return
			end
		end
	else
		self.target = nil
		for k,v in pairs(ents.FindInSphere(self:GetPos(),640+(64*power))) do
			if ((v:IsNPC() and (v:Classify()>3)) or v:IsNextBot()) then
				if (util.TraceLine({start=self:GetPos(),endpos=v:WorldSpaceCenter(),filter=self}).Entity==v) then 
					self.target = v
					return
				end
			end
		end
	end
end

function ENT:extraPop() self.lastShoot = CurTime() end
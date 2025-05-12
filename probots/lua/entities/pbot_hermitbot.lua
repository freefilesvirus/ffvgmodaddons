--behavior suggested by TankDestroyer https://steamcommunity.com/profiles/76561198323813529

AddCSLuaFile()

ENT.Base="pbot_base"
ENT.PrintName="hermit bot"
ENT.Spawnable=false

ENT.speed=.4
ENT.turnSpeed=1

ENT.maxHealth=20

ENT.peek=0

ENT.stolenWeapon=nil
ENT.stolenWeaponClass=""

ENT.onGround=false
ENT.stuckOnGround=0

function ENT:tickThink()
	local phys=self:GetPhysicsObject()
	if not IsValid(phys) then return end

	local bucket=self.parts[1]
	bucket:SetLocalPos(Vector(bucket:GetLocalPos().x-((bucket:GetLocalPos().x-(-6-(self.peek*2)))/6),0,8))
	bucket:SetLocalAngles(Angle(180,90,bucket:GetLocalAngles().z-(math.AngleDifference(bucket:GetLocalAngles().z,(self.peek*20))/6)))

	if self.grounded then
		local vel=phys:GetVelocity()
		vel:Rotate(-self:GetAngles())
		self.parts[2]:SetLocalAngles(Angle(self.parts[2]:GetLocalAngles()[1]+(vel[1]/20),0,0))

		if self:GetAngles()[3]>-20 then
			phys:AddAngleVelocity(Vector(-25,0,0))
			phys:AddVelocity(Vector(0,0,10))
		end
	end
end

function ENT:Use()
	self.peek=self.peek==0 and 1 or 0
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/props_wasteland/light_spotlight01_lamp.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)

		self:addPart("models/props_junk/MetalBucket02a.mdl",Vector(-6,0,8),Angle(180,90,0))
		self:addPart("models/props_vehicles/carparts_wheel01a.mdl",Vector(-16,0,-1),Angle(0,0,0),.3)
		self:addPart("models/props_c17/playground_teetertoter_stan.mdl",Vector(-5.5,0,-4),Angle(0,0,0),.7)

		table.insert(self.parts,self) --weird with body being the lamp

		self:makeLight(self)
	end

	self.BaseClass.Initialize(self)
end

function ENT:setGrounded()
	self.onGround=util.TraceLine({start=self:GetPos(),endpos=self:GetPos()-Vector(0,0,20),filter=self}).Hit

	self.BaseClass.setGrounded(self)
end

function ENT:delayedThink()
	local phys=self:GetPhysicsObject()
	if not IsValid(phys) then return end

	if self.stolenWeapon then
		self.speed=1
		self.turnSpeed=1.4

		self.peek=1
	else
		self.speed=.4
		self.turnSpeed=1

		self.peek=self.target and 1 or 0
	end

	if self.grounded then
		self.stuckOnGround=0

		if self.target then
			if self.lineOfSight(self.target,self)>.4 then
				local pos=self:GetPos()+(self:GetPos()-self.target:GetPos()):GetNormalized()*200
				local tr=util.TraceLine({start=self:GetPos(),endpos=pos,filter=self})
				self.goalPos=tr.Hit and tr.HitPos or pos

				self.target=nil

				self.peek=0
			else
				self.goalPos=self.target:GetPos()

				if self:GetPos():DistToSqr(self.target:GetPos())<1200 then
					local wep=self.target:GetActiveWeapon()
					if IsValid(wep) then
						self.stolenWeaponClass=wep:GetClass()
						if self.stolenWeaponClass=="weapon_frag" then
							self.stolenWeapon=ents.Create("npc_grenade_frag")
							self.stolenWeapon:SetParent(self)
							self.stolenWeapon:SetLocalPos(Vector(12,0,0))
							self.stolenWeapon:SetLocalAngles(Angle(-30,90,0))
							self.stolenWeapon:Spawn()

							self.stolenWeapon:Fire("SetTimer",2)
						else
							self.stolenWeapon=self:addPart(wep:GetModel(),Vector(12,0,0),Angle(-30,90,0))
							table.remove(self.parts,#self.parts)
						end

						wep:Remove()

						local farthestDist=0
						local farthest=nil
						for _,v in pairs(navmesh.Find(self:GetPos(),2400,6,6)) do
							local dist=self:GetPos():DistToSqr(v:GetCenter())
							if dist>farthestDist then
								farthestDist=dist
								farthest=v
							end
						end

						if farthest then self.goalPos=farthest:GetCenter() end
					end
					self.target=nil
				end
			end
		elseif not self.stolenWeapon then
			local choices={}
			local interests={}
			for _,v in ipairs(ents.FindInSphere(self:GetPos(),1200)) do
				local interest=self:interest(v)
				if interest>0 then
					table.insert(choices,v)
					table.insert(interests,interest)
				end
			end

			if #choices>0 then
				local pick=self.weightedRandom(interests)

				self.target=choices[pick]
				self.goalPos=self.target:GetPos()
			elseif not self.goalPos and math.random(4)==1 then
				local pos=Vector(100,0,0)
				pos:Rotate(Angle(0,math.Rand(-180,180),0))
				pos=pos+self:GetPos()
				local tr=util.TraceLine({start=self:GetPos(),endpos=pos,filter=self})
				self.goalPos=tr.Hit and tr.HitPos or pos
			end
		elseif not self.goalPos then self:dropWeapon() end
	else
		if self.onGround then
			self.stuckOnGround=self.stuckOnGround+1
			if math.Rand(2,4)<self.stuckOnGround then
				self.stuckOnGround=0

				phys:AddVelocity(Vector(0,0,40))
				phys:AddAngleVelocity(Vector(self:GetAngles()[3]*-8,0,0))

				if util.TraceLine({start=self:GetPos(),endpos=self:LocalToWorld(Vector(16,0,0)),filter=self}).Hit then phys:AddAngleVelocity(Vector(0,0,2000)) end
			end
		end
	end
end

function ENT:interest(ent)
	if not isfunction(ent.GetActiveWeapon) then return 0 end
	if self.lineOfSight(ent,self)<.4 then return 1 end
	return 0
end

function ENT:dropWeapon()
	print(self.stolenWeaponClass)
	if self.stolenWeapon and self.stolenWeaponClass~="weapon_frag" then
		local wep=ents.Create(self.stolenWeaponClass)
		wep:SetPos(self:LocalToWorld(Vector(12,0,0)))
		wep:SetAngles(self:LocalToWorldAngles(Angle(-30,90,0)))
		wep:Spawn()

		self.stolenWeapon:Remove()
		self.stolenWeapon=nil
	end
end

function ENT:OnTakeDamage(dmg)
	self:dropWeapon()

	self.BaseClass.OnTakeDamage(self,dmg)
end

function ENT:pop()
	table.remove(self.parts,#self.parts-1)

	self.BaseClass.pop(self)
end

list.Set("NPC","pbot_hermitbot",{
	Name=ENT.PrintName,
	Class="pbot_hermitbot",
	Category="probots"
})
if CLIENT then language.Add("pbot_hermitbot",ENT.PrintName) end
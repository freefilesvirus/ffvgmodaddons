AddCSLuaFile()

ENT.Base="base_anim"
ENT.Type="anim"

if CLIENT then
	language.Add("ffv_lightningrod","lightning")
end

function ENT:Initialize()
	if CLIENT then return end
	
	self:SetModel("models/props_trainstation/trainstation_ornament002.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	
	if WireLib then
		WireLib.CreateInputs(self,{"call","shoot"})
	end
end

function ENT:TriggerInput(name,val)
	if val>0 then
		if name=="call" then
			self:summon()
		elseif name=="shoot" then
			self:summon(true)
		end
	end
end

function ENT:summon(flip)
	local trace=util.QuickTrace(self:GetPos(),self:GetUp()*9999,self)
	
	local from=flip and self:LocalToWorld(Vector(0,0,30)) or trace.HitPos
	local to=flip and trace.HitPos or self:LocalToWorld(Vector(0,0,30))
	
	local effect=EffectData()
	effect:SetStart(from)
	effect:SetOrigin(to)
	util.Effect("ffvlightningbolt",effect,true,true)
	
	if trace.HitNonWorld and trace.Hit then
		local damage=DamageInfo()
		damage:SetAttacker(self)
		damage:SetDamage(trace.Entity:Health())
		damage:SetDamageType(DMG_DISSOLVE)
		damage:SetDamageForce(self:GetUp()*99)
		
		trace.Entity:TakeDamageInfo(damage)
	end
	
	util.BlastDamage(self,self,to,200,80)
	
	local phys=self:GetPhysicsObject()
	if phys then
		phys:AddVelocity(self:GetUp()*-600)
	end
end
TOOL.Category="Fun"
TOOL.Name="smite"

if CLIENT then
	TOOL.Information = {{name="left"}}
	language.Add("tool.ffvsmite.name","smite")
	language.Add("tool.ffvsmite.desc","take a wild guess")
	language.Add("tool.ffvsmite.left","smite")
end

function TOOL:LeftClick(trace)
	if SERVER then
		local effect=EffectData()
		effect:SetStart(util.QuickTrace(trace.HitPos,(trace.HitNormal+Vector(0,0,2)):GetNormalized()*9999,trace.Entity).HitPos)
		effect:SetOrigin(trace.HitPos)
		util.Effect("ffvlightningbolt",effect,true,true)
		
		if trace.HitNonWorld and trace.Hit then
			local damage=DamageInfo()
			damage:SetAttacker(self:GetOwner())
			damage:SetDamage(trace.Entity:Health())
			damage:SetDamageType(DMG_DISSOLVE)
			damage:SetDamageForce(Vector(0,0,-99))
			
			trace.Entity:TakeDamageInfo(damage)
		end
		
		util.BlastDamage(self:GetOwner(),self:GetOwner(),trace.HitPos,200,80)
	end
end
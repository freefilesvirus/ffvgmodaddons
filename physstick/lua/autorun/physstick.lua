if CLIENT then
	CreateClientConVar("physstick_enabled",1,true,true)

	return
end

function physstick(ply,ent)
	if (ply:GetInfoNum("physstick_enabled",1)==0) then return end

	local filter={ent}
	local toStick={}
	local k=0
	local lastHit=true

	local from=(ent:GetPos()+Vector(0,0,2))
	local mins,maxs=ent:GetRotatedAABB(ent:OBBMins(),ent:OBBMaxs())
	while ((k<99) and lastHit) do
		local tr=util.TraceHull({start=from,endpos=from,mins=mins,maxs=maxs,ignoreworld=true,filter=filter},ent)
		if tr.Hit then
			table.insert(filter,tr.Entity)

			local tr2=util.TraceLine({start=tr.Entity:GetPos(),endpos=Vector(tr.Entity:GetPos()[1],tr.Entity:GetPos()[2],(ent:GetPos()+mins)[3]),
				ignoreworld=true,filter={ent},whitelist=true})
			local phys=tr.Entity:GetPhysicsObject()
			if (IsValid(phys) and phys:IsMotionEnabled() and (tr.Entity:GetPos()[3]>(ent:GetPos()+mins)[3]) and tr2.Hit) then
				table.insert(toStick,tr.Entity)
			end
		else lastHit=false end
		k=(k+1)
	end

	if (#toStick==0) then return end

	local welds={}
	for k,v in pairs(toStick) do
		table.insert(welds,constraint.Weld(ent,v,0,0))
	end
	checkHeld(ent,welds)
end

function checkHeld(ent,welds) --hook for start pickup but not for stop pickup?
	timer.Simple(.2,function()
		if !(IsValid(ent)) then return end

		if ent:IsPlayerHolding() then checkHeld(ent,welds)
		else
			for k,v in pairs(welds) do
				if IsValid(v) then v:Remove() end
			end
		end
	end)
end

hook.Add("OnPhysgunPickup","ffv_physstick_phys",physstick)
hook.Add("OnPlayerPhysicsPickup","ffv_physstick_ply",physstick)
hook.Add("GravGunOnPickedUp","ffv_physstick_grav",physstick)
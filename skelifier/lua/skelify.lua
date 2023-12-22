function skelify(ent, ply)
	if not (math.random(200) < 200) then
		ent:EmitSound("ambient/creatures/town_child_scream1.wav")
	end

	local newModel = GetConVar("skelifier_ragdoll"):GetString()
	--test if cvar is good or not
	local testRag = ents.Create("prop_ragdoll")
	testRag:SetModel(newModel)
	if not qualify_skelify(testRag, true) then
		newModel = "models/player/skeleton.mdl"

		util.AddNetworkString("skelifier_badcvar")
		net.Start("skelifier_badcvar")
		net.Send(ply)
	end

	--if its a ragdoll
	if not ent:IsRagdoll() then
		local ragdolls = ents.FindByClass("prop_ragdoll")
		ent:TakeDamage(ent:Health()-1)
		ent:TakeDamage(1, ply)
		if #ragdolls == #ents.FindByClass("prop_ragdoll") then return false end
		ragdolls = ents.FindByClass("prop_ragdoll")
		ent = ragdolls[#ragdolls]
	end
	ent:SetModel(newModel)

	local ragdoll = ents.Create("prop_ragdoll")
	ragdoll:SetModel(newModel)
	ragdoll:Spawn()
	ragdoll:SetPos(ent:GetPos())

	for i=1,ent:GetBoneCount() do
		local originBone = ent:GetBoneName(i)
		local newBone = ragdoll:LookupBone(originBone)
		if newBone then
			local phys = ragdoll:GetPhysicsObjectNum(ragdoll:TranslateBoneToPhysBone(newBone))
			local pos = ent:GetPhysicsObjectNum(ent:TranslateBoneToPhysBone(i)):GetPos()
			local ang = ent:GetPhysicsObjectNum(ent:TranslateBoneToPhysBone(i)):GetAngles()
			local vel = ent:GetPhysicsObjectNum(ent:TranslateBoneToPhysBone(i)):GetVelocity()

			if ent:IsPlayer() then vel = Vector(0,0,0) end

			phys:EnableMotion(true)
			phys:SetPos(pos)
			phys:SetAngles(ang)
			phys:SetVelocity(vel)
		end
	end

	undo.Create("Skelification")
		undo.AddEntity(ragdoll)
		undo.SetPlayer(ply)
	undo.Finish()

	ent:Remove()
end

function qualify_skelify(ent, override)
	if not IsValid(ent) then return false end
	if not ((ent:IsNPC() or ent:IsPlayer() or ent:IsRagdoll())) then return false end
	if not ent:LookupBone("ValveBiped.Bip01_Spine") then return false end
	if ((ent:IsRagdoll() and (string.lower(ent:GetModel()) == string.lower(GetConVar("skelifier_ragdoll"):GetString()))) and (not override)) then return false end
	return true
end

net.Receive("skelifier_badcvar", function()
	GetConVar("skelifier_ragdoll"):SetString("models/player/skeleton.mdl")
end)
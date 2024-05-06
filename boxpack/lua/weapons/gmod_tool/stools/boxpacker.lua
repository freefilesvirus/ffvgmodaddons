TOOL.Category = "Construction"
TOOL.Name = "Box Packer"

TOOL.ClientConVar["model"] = "models/props_junk/wood_crate001a.mdl"

if CLIENT then
	TOOL.Information = {{name="left",stage=0}}
	language.Add("tool.boxpacker.name","Box Packer")
	language.Add("tool.boxpacker.desc","Crams a contraption into a relatively small box")
	language.Add("tool.boxpacker.left","Pack")
end

function TOOL:LeftClick(trace)
	if CLIENT then return (not trace.HitWorld) end
	if (trace.HitWorld or trace.Entity:IsPlayer()) then return false end
	local ent = trace.Entity

	--find lowest point
	local cents = {}
	local cons = {}
	duplicator.GetAllConstrainedEntitiesAndConstraints(ent,cents,cons)
	local lowest = ent:WorldSpaceCenter().z
	for v in pairs(cents) do
		local vent = cents[v]
		local min,max = vent:WorldSpaceAABB()
		if (min.z<lowest) then lowest = min.z end
	end

	--make box
	local box = ents.Create("ffv_packbox")
	box.hasNpc = ent:IsNPC()
	--make sure box isnt submerged in ground
	box:SetModel(self:GetClientInfo("model"))
	local min,max = box:GetModelBounds()
	local tr = util.TraceLine({
		start=trace.HitPos,
		endpos=trace.HitPos-Vector(0,0,math.abs(min.z*2)),
		filter=ent
	})
	box:SetPos(tr.Hit and (tr.HitPos+Vector(0,0,math.abs(min.z))) or trace.HitPos)

	duplicator.SetLocalPos(Vector(box:GetPos().x,box:GetPos().y,lowest))
	box.contraption = duplicator.Copy(ent)
	duplicator.SetLocalPos(vector_origin)
	--clean up
	for v in pairs(cents) do cents[v]:Remove() end

	--undo
	undo.Create("Pack")
		undo.AddEntity(box)
		undo.SetPlayer(self:GetOwner())
	undo.Finish()

	--spawn box
	box:Spawn()
	if IsValid(ent:GetPhysicsObject()) then box:GetPhysicsObject():SetVelocity(ent:GetPhysicsObject():GetVelocity()) end

	return true
end

function TOOL.BuildCPanel(cpanel)
	cpanel:AddControl("Header",{Description="#tool.boxpacker.desc"})
	cpanel:AddControl("PropSelect",{ConVar="boxpacker_model",Height=0,Models=list.Get("boxModels")})
end
list.Set("boxModels","models/props_junk/wood_crate001a.mdl",{})
list.Set("boxModels","models/props_junk/wood_crate002a.mdl",{})
list.Set("boxModels","models/props_junk/cardboard_box001a.mdl",{})
list.Set("boxModels","models/props_junk/cardboard_box002a.mdl",{}) --is this just the one above with a different color?
list.Set("boxModels","models/props_junk/cardboard_box003a.mdl",{})
list.Set("boxModels","models/props_junk/cardboard_box004a.mdl",{})
--any breakable propd work here...
list.Set("boxModels","models/props_junk/watermelon01.mdl",{})
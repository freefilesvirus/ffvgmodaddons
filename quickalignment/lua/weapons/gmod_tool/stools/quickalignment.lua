TOOL.Category = "Construction"
TOOL.Name = "Quick Alignment"

TOOL.ClientConVar["alignx"] = 1
TOOL.ClientConVar["aligny"] = 1
TOOL.ClientConVar["alignz"] = 1
TOOL.ClientConVar["objectcenter"] = 1

if CLIENT then
	TOOL.Information = {
		{name = "left", stage = 0},
		{name = "left_1", stage = 1},
		{name = "reload", stage = 1}
	}

	language.Add("tool.quickalignment.name", "Quick Alignment")
	language.Add("tool.quickalignment.desc", "Aligns objects")
	language.Add("tool.quickalignment.left", "Select an object to be aligned")
	language.Add("tool.quickalignment.left_1", "Select an object to align to")
	language.Add("tool.quickalignment.reload", "Cancel alignment")
	
	language.Add("tool.quickalignment.help", "Align an objects position with another object")
end

function TOOL:LeftClick(trace)
	local ent = trace.Entity
	if (not self:qualify_ent(ent)) then return false end

	--being exposed to so much of garrys code has me putting parentheses around everything...
	if (self:GetStage() == 0) then
		self:SetStage(1)
		self:SetObject(0, ent, ent:GetPos(), ent:GetPhysicsObject(), 0, trace.HitNormal)
		return true
	else
		self:SetStage(0)
		if CLIENT then return true end
		local oldEnt = self:GetEnt(0)
		oldEnt:GetPhysicsObject():EnableMotion(false)
		oldEnt:SetPos(self:get_aligned_pos(ent))
		return true
	end
end

function TOOL:Think()
	--this is for having the ghost to show alignment
	if (self:GetStage() == 1) then
		local ply = self:GetOwner()
		local trace = ply:GetEyeTrace()
		local ent = self:GetEnt(0)
		if (not (trace.Hit and self:qualify_ent(trace.Entity))) then 
			self:ReleaseGhostEntity()
			return
		end

		--client didnt have ent if this was in singleplayer. hope this line of code doesnt lead to any unforeseen consequences
		if (game.SinglePlayer() and CLIENT) then return end
		self:MakeGhostEntity(ent:GetModel(), self:get_aligned_pos(trace.Entity), ent:GetAngles())
	else
		self:ReleaseGhostEntity()
	end
end

function TOOL:get_aligned_pos(alignent)
	local newPos = self:GetEnt(0):GetPos()
	local alignPos
	if self:GetClientBool("objectcenter") then
		alignPos = alignent:WorldSpaceCenter() + (newPos - self:GetEnt(0):WorldSpaceCenter())
	else
		alignPos = alignent:GetPos()
	end

	if self:GetClientBool("alignx") then
		newPos = Vector(alignPos.x,newPos.y,newPos.z)
	end
	if self:GetClientBool("aligny") then
		newPos = Vector(newPos.x,alignPos.y,newPos.z)
	end
	if self:GetClientBool("alignz") then
		newPos = Vector(newPos.x,newPos.y,alignPos.z)
	end
	return newPos
end

function TOOL:qualify_ent(ent)
	if (not IsValid(ent)) then return false end
	if ent:IsPlayer() then return false end
	if ent:IsRagdoll() then return false end
	if ((self:GetStage() == 1) and (ent == self:GetEnt(0))) then return false end
	if CLIENT then return true end
	if (not IsValid(ent:GetPhysicsObject())) then return false end
	return true
end

function TOOL.BuildCPanel(cpanel)
	cpanel:AddControl("Header", {Description = "#tool.quickalignment.help"})

	cpanel:AddControl("CheckBox", {Label = "Align X", Command = "quickalignment_alignx"})
	cpanel:AddControl("CheckBox", {Label = "Align Y", Command = "quickalignment_aligny"})
	cpanel:AddControl("CheckBox", {Label = "Align Z", Command = "quickalignment_alignz"})

	cpanel:AddControl("Header", {Description = "Object center or model origin"})
	cpanel:AddControl("CheckBox", {Label = "Object center", Command = "quickalignment_objectcenter"})
end
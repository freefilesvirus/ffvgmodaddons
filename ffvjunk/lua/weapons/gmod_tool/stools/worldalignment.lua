TOOL.Category = "ffvjunk"
TOOL.Name = "World Alignment"

TOOL.ClientConVar["x"] = 1
TOOL.ClientConVar["y"] = 1
TOOL.ClientConVar["z"] = 1

TOOL.worldPoints = {}

if CLIENT then
	TOOL.Information = {
		{name="left",stage=0},
		{name="left_1",stage=1},
		{name="right",stage=1},
		{name="reload",stage=1}
	}
	language.Add("tool.worldalignment.name","World Alignment")
	language.Add("tool.worldalignment.desc","Aligns an object between points in the world")
	language.Add("tool.worldalignment.left","Select an object to be aligned")
	language.Add("tool.worldalignment.left_1","Add a world point")
	language.Add("tool.worldalignment.right","Confirm object position")
	language.Add("tool.worldalignment.reload","Cancel alignment")
	language.Add("tool.worldalignment.help","Averages multiple points in the world that the selected object is moved to")
end

function TOOL:Reload()
	self:SetStage(0)
	self.worldPoints = {}
end

function TOOL:LeftClick(trace)
	local ent = trace.Entity
	if (not self:qualify_ent(ent)) then return false end

	if (self:GetStage() == 0) then
		self:SetStage(1)
		self:SetObject(0, ent, ent:GetPos(), ent:GetPhysicsObject(), 0, trace.HitNormal)
		return true
	else
		table.insert(self.worldPoints,trace.HitPos)
		return true
	end
end

function TOOL:RightClick()
	if (self:GetStage() == 1) then
		if CLIENT then return true end
		local oldEnt = self:GetEnt(0)
		local oldPos = oldEnt:GetPos()
		--undo
		undo.Create("Alignment")
			undo.AddFunction(function()
				--PrintTable(oldEnt)
				if IsValid(oldEnt) then oldEnt:SetPos(oldPos) end
			end)
			undo.SetPlayer(self:GetOwner())
		undo.Finish()

		--align
		oldEnt:GetPhysicsObject():EnableMotion(false)
		oldEnt:SetPos(self:get_aligned_pos())

		self:SetStage(0)
		self.worldPoints = {}

		return true
	end
end

function TOOL:get_aligned_pos()
	local newPos = self:GetEnt(0):GetPos()
	local alignedPos = Vector(0,0,0)
	if (#self.worldPoints>0) then
		for k, v in pairs(self.worldPoints) do
			alignedPos = alignedPos + v
		end
		alignedPos = alignedPos / #self.worldPoints
		
		if self:GetClientBool("x") then
			newPos = Vector(alignedPos.x,newPos.y,newPos.z)
		end
		if self:GetClientBool("y") then
			newPos = Vector(newPos.x,alignedPos.y,newPos.z)
		end
		if self:GetClientBool("z") then
			newPos = Vector(newPos.x,newPos.y,alignedPos.z)
		end
	end

	return newPos
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


function TOOL:qualify_ent(ent)
	if (self:GetStage() == 1) then return true end
	if (ent == game.GetWorld()) then return false end
	if ent:IsPlayer() then return false end
	if ent:IsRagdoll() then return false end
	if CLIENT then return true end
	if (not IsValid(ent:GetPhysicsObject())) then return false end
	return true
end

function TOOL.BuildCPanel(cpanel)
	cpanel:AddControl("Header", {Description = "#tool.worldalignment.help"})
	cpanel:AddControl("CheckBox", {Label = "Align X", Command = "worldalignment_x"})
	cpanel:AddControl("CheckBox", {Label = "Align Y", Command = "worldalignment_y"})
	cpanel:AddControl("CheckBox", {Label = "Align Z", Command = "worldalignment_z"})
end
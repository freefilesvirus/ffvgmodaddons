TOOL.Category = "ffvjunk"
TOOL.Name = "Robot Mover"

if CLIENT then
	TOOL.Information = {
		{name="left"},
		{name="right"}
	}
	language.Add("tool.robomover.name","Robot Mover")
	language.Add("tool.robomover.desc","Force a robot to move somewhere")
	language.Add("tool.robomover.left","Select the robot")
	language.Add("tool.robomover.right","Select the place")
end

function TOOL:LeftClick(trace)
	local ent = trace.Entity
	if (not string.EndsWith(ent:GetClass(),"bot")) then return false end
	if SERVER then
		self:SetObject(0,ent,ent:GetPos(),ent:GetPhysicsObject(),0,trace.HitNormal)
	end
	return true
end

function TOOL:RightClick(trace)
	local ent = trace.Entity
	if SERVER then
		self:GetEnt(0).goalPos = trace.HitPos
	end
	return true
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

function TOOL:qualify_ent(ent)
	if (ent == self:GetEnt(0)) then return false end
	if (ent == game.GetWorld()) then return false end
	if ent:IsPlayer() then return true end
	return true
end
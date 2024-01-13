TOOL.Category = "ffvjunk"
TOOL.Name = "Robot Targeter"

if CLIENT then
	TOOL.Information = {
		{name="left"},
		{name="right"},
		{name="reload"}
	}
	language.Add("tool.robotarget.name","Robot Targeter")
	language.Add("tool.robotarget.desc","Force a robot to target something")
	language.Add("tool.robotarget.left","Select the robot")
	language.Add("tool.robotarget.right","Select the target")
	language.Add("tool.robotarget.reload","Target yourself")
end

function TOOL:LeftClick(trace)
	local ent = trace.Entity
	if (not string.EndsWith(ent:GetClass(),"bot")) then return false end
	if SERVER then
		self:SetObject(0,ent,ent:GetPos(),ent:GetPhysicsObject(),0,trace.HitNormal)
	end
	return true
end

function TOOL:Reload()
	if (not IsValid(self:GetEnt(0))) then return false end
	if SERVER then
		self:GetEnt(0).target = self:GetOwner()
	end
	return true
end

function TOOL:RightClick(trace)
	local ent = trace.Entity
	if (not IsValid(self:GetEnt(0))) then return false end
	if (not self:qualify_ent(ent)) then return false end
	if SERVER then
		self:GetEnt(0).target = ent
		self:GetEnt(0):SetNWEntity("target",ent)
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
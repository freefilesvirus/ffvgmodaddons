TOOL.Category = "Render"
TOOL.Name = "bot viewer"

if CLIENT then
	TOOL.Information = {
		{name="start",icon="gui/lmb.png",stage=0},
		{name="create",icon="gui/lmb.png",stage=1},
		{name="update",icon="gui/rmb.png",stage=1},
	}
	language.Add("tool.botviewer.name","bot viewer")
	language.Add("tool.botviewer.desc","create a monitor linked to a robots eye")
	language.Add("tool.botviewer.start","select a robot")
	language.Add("tool.botviewer.create","create a monitor")
	language.Add("tool.botviewer.update","update a monitor")
end

function TOOL:LeftClick(trace)
	if (self:GetStage()==0) then
		local ent = trace.Entity
		if ent.isffvrobot then
			if CLIENT then return true end

			self:SetStage(1)
			self:SetObject(0,ent,ent:GetPos(),ent:GetPhysicsObject(),0,trace.HitNormal)
			return true
		else return false end
	else
		if CLIENT then return true end

		local botviewer = ents.Create("ffv_bottv")
		botviewer:SetPos(trace.HitPos+(trace.HitNormal*10))
		botviewer:SetAngles(Angle(0,self:GetOwner():EyeAngles().y+180,0))
		botviewer:Spawn()
		botviewer:SetNWEntity("target",self:GetEnt(0))

		undo.Create("bot viewer")
		undo.AddEntity(botviewer)
		undo.SetPlayer(self:GetOwner())
		undo.Finish()

		self:SetStage(0)
		return true
	end
end

function TOOL:RightClick(trace)
	if self:GetStage()==1 and trace.Entity:GetClass()=="ffv_bottv" then
		if SERVER then
			trace.Entity:SetNWEntity("target",self:GetEnt(0))
			self:SetStage(0)
		end
		return true
	end
end

function TOOL:Think()
	if (self:GetStage()==1) then
		local trace = self:GetOwner():GetEyeTrace()
		self:MakeGhostEntity("models/props_c17/tv_monitor01.mdl",trace.HitPos+(trace.HitNormal*10),Angle(0,self:GetOwner():EyeAngles().y+180,0))
	else self:ReleaseGhostEntity() end
end

function TOOL.BuildCPanel(cpanel)
	cpanel:AddControl("Header", {Description = "#tool.botviewer.desc"})
end
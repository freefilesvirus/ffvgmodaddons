TOOL.Category = "Render"
TOOL.Name = "Bot Viewer"

if CLIENT then
	TOOL.Information = {
		{name="left",stage=0},
		{name="left_1",stage=1},
		{name="reload",stage=1}
	}
	language.Add("tool.botviewer.name","Bot Viewer")
	language.Add("tool.botviewer.desc","Spawn a remote bot viewer")
	language.Add("tool.botviewer.left","Select a robot")
	language.Add("tool.botviewer.left_1","Spawn the bot viewer")
	language.Add("tool.botviewer.reload","Cancel")
	language.Add("tool.botviewer.help","Spawn a remote bot viewer that can be activated with the use key")
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
		local botviewer = ents.Create("ffv_botviewer")
		botviewer:SetPos(trace.HitPos+Vector(0,0,3.5))
		botviewer:SetAngles(Angle(0,self:GetOwner():EyeAngles().y+180,0))
		botviewer:Spawn()
		botviewer.target = self:GetEnt(0)

		self:SetStage(0)
		return true
	end
end

function TOOL:Think()
	if (self:GetStage()==1) then
		local trace = self:GetOwner():GetEyeTrace()
		self:MakeGhostEntity("models/props_lab/reciever01b.mdl",trace.HitPos+Vector(0,0,3.5),Angle(0,self:GetOwner():EyeAngles().y+180,0))
	else self:ReleaseGhostEntity() end
end

function TOOL.BuildCPanel(cpanel)
	cpanel:AddControl("Header", {Description = "#tool.botviewer.help"})
end
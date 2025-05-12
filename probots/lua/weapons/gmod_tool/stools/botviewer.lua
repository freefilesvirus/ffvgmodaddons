TOOL.Category = "Render"
TOOL.Name = "probot viewer"

local presets={
	{"models/props_c17/tv_monitor01.mdl",Vector(10,0,0),Angle(90,0,0)},
	{"models/props_lab/monitor01a.mdl",Vector(12,0,0),Angle(90,0,0)},
	{"models/props_lab/monitor01b.mdl",Vector(7,0,0),Angle(90,0,0)},
	{"models/props_phx/rt_screen.mdl",Vector(0,0,-18),Angle(0,0,0)},
	{"models/props_combine/combine_intmonitor003.mdl",Vector(0,0,0),Angle(0,0,0)}
}

if CLIENT then
	TOOL.Information = {
		{name="start",icon="gui/lmb.png",stage=0},
		{name="create",icon="gui/lmb.png",stage=1},
		{name="update",icon="gui/rmb.png",stage=1},
	}
	language.Add("tool.botviewer.name","probot viewer")
	language.Add("tool.botviewer.desc","create a monitor linked to a probots eye")
	language.Add("tool.botviewer.start","select a robot")
	language.Add("tool.botviewer.create","create a monitor")
	language.Add("tool.botviewer.update","update a monitor")

	TOOL.ClientConVar["screen"]=1
	TOOL.ClientConVar["freeze"]=1
end

function TOOL:LeftClick(trace)
	if (self:GetStage()==0) then
		local ent=trace.Entity
		if ent.isProbot then
			if CLIENT then return true end

			self:SetStage(1)
			self:SetObject(0,ent,ent:GetPos(),ent:GetPhysicsObject(),0,trace.HitNormal)
			return true
		else return false end
	else
		if CLIENT then return true end

		local m,p,a=self:presetModelPosAng(trace)

		local botviewer=ents.Create("pbot_tv")
		botviewer:SetPos(p)
		botviewer:SetAngles(a)
		botviewer.preset=math.Clamp(self:GetClientNumber("screen"),1,#presets)
		botviewer:SetNWInt("preset",botviewer.preset)
		botviewer:SetNWEntity("target",self:GetEnt(0))
		botviewer:Spawn()

		local phys=botviewer:GetPhysicsObject()
		if IsValid(phys) then
			if self:GetClientBool("freeze") then phys:EnableMotion(false)
			else phys:Wake() end
		end

		undo.Create("probot viewer")
		undo.AddEntity(botviewer)
		undo.SetPlayer(self:GetOwner())
		undo.Finish()

		self:SetStage(0)
		return true
	end
end

function TOOL:RightClick(trace)
	if self:GetStage()==1 and trace.Entity:GetClass()=="pbot_tv" then
		if SERVER then
			trace.Entity:SetNWEntity("target",self:GetEnt(0))
			self:SetStage(0)
		end
		return true
	end
end

function TOOL:Think()
	if (self:GetStage()==1) then self:MakeGhostEntity(self:presetModelPosAng(self:GetOwner():GetEyeTrace()))
	else self:ReleaseGhostEntity() end
end

function TOOL:presetModelPosAng(trace)
	local preset=presets[math.Clamp(self:GetClientNumber("screen"),1,#presets)]
	local pos=Vector()
	pos:Set(preset[2])
	pos:Rotate(trace.HitNormal:Angle())

	return preset[1],trace.HitPos+pos,trace.HitNormal:Angle()+preset[3]
end

function TOOL.BuildCPanel(cpanel)
	cpanel:AddControl("Header",{Description="#tool.botviewer.desc"})

	local screens={}
	for k,v in pairs(presets) do screens[v[1]]={botviewer_screen=k} end
	cpanel:PropSelect("model","",screens)

	cpanel:CheckBox("spawn frozen","botviewer_freeze")
end
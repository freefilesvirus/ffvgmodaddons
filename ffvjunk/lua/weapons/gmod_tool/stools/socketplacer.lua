print("todo fix socketplacer stool")
-- --TOOL.Category = "Construction"
-- TOOL.Category = "ffvjunk"
-- TOOL.Name = "Socket Placer"

-- if CLIENT then
-- 	TOOL.Information = {
-- 		{name="left",stage=0},
-- 		{name="left_1",stage=1},
-- 		{name="reload"}
-- 	}
-- 	language.Add("tool.socketplacer.name","Socket Placer")
-- 	language.Add("tool.socketplacer.desc","Quickly attach sockets or plugs")
-- 	language.Add("tool.socketplacer.left","Place socket")
-- 	language.Add("tool.socketplacer.left_1","Place plug")
-- 	language.Add("tool.socketplacer.reload","Switch attachment")
-- end

-- function TOOL.BuildCPanel(cpanel)
-- 	cpanel:AddControl("Header", {Description = "#tool.socketplacer.desc"})
-- end

-- function TOOL:Deploy()
-- 	self:MakeGhostEntity("models/props_lab/tpplugholder_single.mdl",Vector(0,0,0),Angle(0,0,0))
-- end

-- function TOOL:Reload()
-- 	if (self:GetStage()==0) then
-- 		self:SetStage(1)
-- 	else
-- 		self:SetStage(0)
-- 	end
-- end

-- function TOOL:Think()
-- 	if (game.SinglePlayer() and CLIENT) then return end
-- 	local trace = self:GetOwner():GetEyeTrace()

-- 	local model = "models/props_lab/tpplugholder_single.mdl"
-- 	if (self:GetStage()==1) then model = "models/props_lab/tpplug.mdl" end
-- 	local offset, rotOffset = self:get_offsets(trace)
-- 	offset:Rotate(trace.HitNormal:Angle())
-- 	self:MakeGhostEntity(model,trace.HitPos+offset,trace.HitNormal:Angle()+rotOffset)
-- end

-- function TOOL:LeftClick(trace)
-- 	if CLIENT then return end
-- 	local ent
-- 	local name
-- 	if (self:GetStage()==0) then
-- 		ent = ents.Create("ffv_socket")
-- 		name = "Socket"
-- 	else
-- 		ent = ents.Create("ffv_plug")
-- 		name = "Plug"
-- 	end

-- 	local offset, rotOffset = self:get_offsets(trace)
-- 	ent:SetPos(trace.HitPos+offset)
-- 	ent:SetAngles(trace.HitNormal:Angle()+rotOffset)
-- 	constraint.Weld(ent,trace.Entity,0,trace.PhysicsBone,0,true,true)
-- 	undo.Create(name)
-- 		undo.AddEntity(ent)
-- 		undo.SetPlayer(self:GetOwner())
-- 	undo.Finish()
-- 	return true
-- end

-- function TOOL:get_offsets(trace)
-- 	local offset = Vector(-2,-13,-9)
-- 	local rotOffset = Angle(0,0,0)
-- 	if (self:GetStage()==1) then
-- 		model = "models/props_lab/tpplug.mdl"
-- 		offset = Vector(8,0,0)
-- 		rotOffset = Angle(180,0,0)
-- 	end
-- 	offset:Rotate(trace.HitNormal:Angle())

-- 	return offset, rotOffset
-- end
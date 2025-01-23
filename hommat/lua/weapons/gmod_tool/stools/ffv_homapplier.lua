TOOL.Category="Render"
TOOL.Name="#tool.ffv_homapplier.name"

if CLIENT then
	TOOL.Information={
		{name="left"},
		{name="right"}
	}

	language.Add("tool.ffv_homapplier.name","hall of mirrorizer")
	language.Add("tool.ffv_homapplier.desc","apply the hall of mirrors glitch effect")
	language.Add("tool.ffv_homapplier.left","apply")
	language.Add("tool.ffv_homapplier.right","clear")
end

function TOOL:LeftClick(trace)
	local good=(IsValid(trace.Entity) and (trace.Entity~=game.GetWorld()) and (not trace.Entity:GetNWBool("ffv_homed")))
	
	trace.Entity:SetNWBool("ffv_homed",true)

	self:networkUpdatedTable()
	return good
end

function TOOL:RightClick(trace)
	local good=(IsValid(trace.Entity) and trace.Entity:GetNWBool("ffv_homed"))
	
	trace.Entity:SetNWBool("ffv_homed",false)

	self:networkUpdatedTable()
	return good
end

function TOOL:networkUpdatedTable()
	if CLIENT then return end
	
	local relevant={}
	for _,e in ents.Iterator() do
		if (e:GetNWBool("ffv_homed") and IsValid(e)) then table.insert(relevant,e) end
	end

	net.Start("ffvHOMTable")
		net.WriteTable(relevant)
	net.Broadcast()
end
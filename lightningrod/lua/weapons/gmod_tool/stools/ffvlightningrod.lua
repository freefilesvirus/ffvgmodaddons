TOOL.Category="Construction"
TOOL.Name="#tool.ffvlightningrod.name"

if CLIENT then
	TOOL.Information={
		{name="left"}
	}
	
	language.Add("tool.ffvlightningrod.name","lightning rod")
	language.Add("tool.ffvlightningrod.desc","creates lightning rods")
	language.Add("tool.ffvlightningrod.left","place or update lightning rod")
	
	TOOL.ClientConVar["out"]="51"
	TOOL.ClientConVar["in"]="52"
else
	function makeRod(ply,pos,ang,outkey,inkey)
		local rod=ents.Create("ffv_lightningrod")
		rod:SetPos(pos)
		rod:SetAngles(ang)
		rod.outkey=outkey
		numpad.OnDown(ply,outkey,"ffvlightningrod_shoot",rod)
		rod.inkey=inkey
		numpad.OnDown(ply,inkey,"ffvlightningrod_call",rod)
		
		rod:Spawn()
		
		return rod
	end
	duplicator.RegisterEntityClass("ffv_lightningrod",makeRod,"Pos","Ang","outkey","inkey")
	
	numpad.Register("ffvlightningrod_shoot",function(ply,rod)
		if IsValid(rod) then
			rod:summon(true)
		end
	end)
	numpad.Register("ffvlightningrod_call",function(ply,rod)
		if IsValid(rod) then
			rod:summon()
		end
	end)
end

function TOOL:Think()
	if game.SinglePlayer() and CLIENT then return end

	local trace=self:GetOwner():GetEyeTrace()
	if trace and trace.Entity:GetClass()!="ffv_lightningrod" then
		self:MakeGhostEntity("models/props_trainstation/trainstation_ornament002.mdl",trace.HitPos,trace.HitNormal:Angle()+Angle(90,0,0))
	else
		self:ReleaseGhostEntity()
	end
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end

	local updating=trace.Entity:GetClass()=="ffv_lightningrod"
	local pos=updating and trace.Entity:GetPos() or trace.HitPos
	local ang=updating and trace.Entity:GetAngles() or trace.HitNormal:Angle()+Angle(90,0,0)
	local rod=makeRod(self:GetOwner(),pos,ang,self:GetClientNumber("out"),self:GetClientNumber("in"))

	if updating then
		undo.ReplaceEntity(trace.Entity,rod)
		cleanup.ReplaceEntity(trace.Entity,rod)
		trace.Entity:Remove()
	else
		if trace.Entity!=game.GetWorld() then
			constraint.Weld(rod,trace.Entity,0,0)
		else
			local phys=rod:GetPhysicsObject()
			if phys then
				phys:EnableMotion(false)
			end
		end
	
		undo.Create("lightning rod")
		undo.AddEntity(rod)
		undo.SetPlayer(self:GetOwner())
		undo.Finish()
	end
	
	return true
end

function TOOL.BuildCPanel(cpanel)
	cpanel:AddControl("header",{description="#tool.ffvlightningrod.desc"})
	cpanel:KeyBinder("call lightning","ffvlightningrod_in")
	cpanel:KeyBinder("shoot lightning","ffvlightningrod_out")
end
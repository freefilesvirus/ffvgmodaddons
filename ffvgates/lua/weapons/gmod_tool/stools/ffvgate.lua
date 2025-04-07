TOOL.Category="Construction"
TOOL.Name="#tool.ffvgate.name"

if CLIENT then
	TOOL.Information={
		{name="bottom",icon="gui/lmb.png",stage=0},
		{name="auto",icon="gui/rmb.png",stage=0},
		{name="top",icon="gui/lmb.png",stage=1},
		{name="side",icon="gui/lmb.png",stage=2},
		{name="confirm",icon="gui/lmb.png",stage=3},
		{name="reset",icon="gui/r.png",op=1}
	}

	language.Add("tool.ffvgate.name","gate")
	language.Add("tool.ffvgate.desc","builds gates shaped to doorways")
	language.Add("tool.ffvgate.bottom","place the bottom")
	language.Add("tool.ffvgate.auto","auto place")
	language.Add("tool.ffvgate.top","place the top")
	language.Add("tool.ffvgate.side","place a side")
	language.Add("tool.ffvgate.confirm","confirm shape")
	language.Add("tool.ffvgate.reset","reset")

	TOOL.ClientConVar["movesound"]="doors/garage_move1.wav"
	TOOL.ClientConVar["stopsound"]="doors/heavy_metal_stop1.wav"
	TOOL.ClientConVar["mat"]="phoenix_storms/dome"
	TOOL.ClientConVar["speed"]=1
	TOOL.ClientConVar["width"]=8
	TOOL.ClientConVar["toggle"]=1
	TOOL.ClientConVar["key"]="51"

	net.Receive("ffvgate_fail",function(len,ply)
		notification.AddLegacy(net.ReadString(),NOTIFY_ERROR,2)
		surface.PlaySound("buttons/button10.wav")
	end)

	bottom=Vector(0,0,0)
	top=Vector(0,0,0)
	side1=Vector(0,0,0)
	side2=Vector(0,0,0)
	normal=Vector(1,0,0)
	x=0
	y=0
	net.Receive("ffvgate_info",function(len,ply)
		local type=net.ReadInt(3)
		if (type==0) then
			bottom=net.ReadVector()
		elseif (type==1) then
			top=net.ReadVector()
		elseif (type==2) then
			side1=net.ReadVector()
			side2=net.ReadVector()
			normal=net.ReadNormal()

			x=(side1-side2):Length()
			y=(top-bottom):Length()
		end
	end)
else
	util.AddNetworkString("ffvgate_fail")
	util.AddNetworkString("ffvgate_info")
end

function TOOL:RightClick(trace)
	if (self:GetStage()>0) then return end

	if !(self:LeftClick(trace)) then
		self:Deploy()
		return
	end

	local tr=util.TraceLine({
		start=trace.HitPos,
		endpos=trace.HitPos+Vector(0,0,999),
		collisiongroup=COLLISION_GROUP_WORLD
	})
	if !(self:LeftClick(tr,1)) then
		self:Deploy()
		return
	end
	
	local aimVec=self:GetOwner():GetAimVector()
	local tr2=util.TraceLine({
		start=trace.HitPos+Vector(0,0,1),
		endpos=trace.HitPos+Vector(0,0,1)+(Vector(aimVec.x,aimVec.y,0):Angle():Right()*999),
		collisiongroup=COLLISION_GROUP_WORLD
	})
	if !(self:LeftClick(tr2,2)) then
		self:Deploy()
		return
	end

	return true
end

function TOOL:LeftClick(trace,stage)
	if (stage==nil) then stage=self:GetStage() end
	if !(trace.Hit) then return false end

	if ((stage<2) and (math.abs(trace.HitNormal.z)<.5)) then
		if SERVER then
			net.Start("ffvgate_fail")
			net.WriteString(((stage==0) and "bottom" or "top").." cant be on a wall!")
			net.Send(self:GetOwner())
		end

		return false
	end

	if (stage==0) then
		self:SetObject(0,Entity(0),trace.HitPos,0,0,trace.HitNormal)
		if SERVER then
			net.Start("ffvgate_info")
			net.WriteInt(0,3)
			net.WriteVector(trace.HitPos)
			net.Send(self:GetOwner())
		end

		self:SetOperation(1)
		self:SetStage(1)
	elseif (stage==1) then
		if (trace.HitPos.z<=self:GetPos(0).z) then --fail if top isnt higher than bottom
			if SERVER then
				net.Start("ffvgate_fail")
				net.WriteString("top needs to be higher than the bottom!")
				net.Send(self:GetOwner())
			end

			return false
		end

		local bottom=self:GetPos(0)
		self:SetObject(1,Entity(0),Vector(bottom.x,bottom.y,trace.HitPos.z),0,0,trace.HitNormal)
		if SERVER then
			net.Start("ffvgate_info")
			net.WriteInt(1,3)
			net.WriteVector(Vector(bottom.x,bottom.y,trace.HitPos.z))
			net.Send(self:GetOwner())
		end

		self:SetStage(2)
	elseif (stage==2) then
		if ((trace.HitNormal==self:GetNormal(0)) or (trace.HitNormal==self:GetNormal(1))) then
			if SERVER then
				net.Start("ffvgate_fail")
				net.WriteString("has to be a different wall!")
				net.Send(self:GetOwner())
			end

			return false
		end

		local tr=util.TraceLine({
			start=trace.HitPos,
			endpos=(trace.HitPos+(trace.HitNormal*9999)),
			collisiongroup=COLLISION_GROUP_WORLD
		})
		if !(tr.Hit) then --no opposing wall
			if SERVER then
				net.Start("ffvgate_fail")
				net.WriteString("cant find opposing side!")
				net.Send(self:GetOwner())
			end

			return false
		else
			local s1=self:squishVector(trace.HitPos,self:GetPos(0),trace.HitNormal)
			local s2=self:squishVector(tr.HitPos,self:GetPos(0),trace.HitNormal)
			s1.z=((self:GetPos(1).z+self:GetPos(0).z)/2)
			s2.z=((self:GetPos(1).z+self:GetPos(0).z)/2)
			self:SetObject(2,Entity(0),s1,0,0,trace.HitNormal)
			self:SetObject(3,Entity(0),s2,0,0,tr.HitNormal)

			local bottom=((s1+s2)/2)
			bottom.z=self:GetPos(0).z
			self:SetObject(0,Entity(0),bottom,0,0,self:GetNormal(0))
			self:SetObject(1,Entity(0),Vector(bottom.x,bottom.y,self:GetPos(1).z),0,0,self:GetNormal(1))

			if SERVER then
				net.Start("ffvgate_info")
				net.WriteInt(0,3)
				net.WriteVector(bottom)
				net.Send(self:GetOwner())
				net.Start("ffvgate_info")
				net.WriteInt(1,3)
				net.WriteVector(self:GetPos(1))
				net.Send(self:GetOwner())
				net.Start("ffvgate_info")
				net.WriteInt(2,3)
				net.WriteVector(s1)
				net.WriteVector(s2)
				net.WriteNormal(self:GetNormal(2))
				net.Send(self:GetOwner())
			end
		end

		self:SetStage(3)
	elseif (stage==3) then
		if SERVER then
			local gate=ents.Create("ffv_gate")
			gate:SetPos((self:GetPos(0)+self:GetPos(1))/2)
			gate:SetMaterial(self:GetClientInfo("mat"))
			gate:SetAngles(self:GetNormal(2):Angle()+Angle(90,90,0))
			gate.x=math.abs((self:GetPos(2)-self:GetPos(3)):Length())
			gate.y=math.abs((self:GetPos(0)-self:GetPos(1)):Length())
			gate.width=self:GetClientNumber("width")
			gate.speed=self:GetClientNumber("speed")

			local moveSound=self:GetClientInfo("movesound")
			if (moveSound~="") then gate.moveSound=Sound(moveSound) end
			local stopSound=self:GetClientInfo("stopsound")
			if (stopSound~="") then gate.stopSound=Sound(stopSound) end

			gate:Spawn()

			numpad.OnDown(self:GetOwner(),self:GetClientNumber("key"),"ffvgate_toggle",gate)
			if !(self:GetClientBool("toggle")) then numpad.OnUp(self:GetOwner(),self:GetClientNumber("key"),"ffvgate_toggle",gate) end

			undo.Create("gate")
			undo.AddEntity(gate)
			undo.SetPlayer(self:GetOwner())
			undo.Finish()
		end

		self:Deploy()
	end

	return true
end

function TOOL:squishVector(from,to,normal)
	return Vector((normal.x==0) and to.x or from.x,(normal.y==0) and to.y or from.y,(normal.z==0) and to.z or from.z)
end

function TOOL:Deploy()
	self:ClearObjects()
	self:SetOperation(0)
	self:SetStage(0)
end

hook.Add("PostDrawTranslucentRenderables","ffvgate_preview",function()
	local weapon=LocalPlayer():GetActiveWeapon()
	if !(IsValid(weapon) and (weapon:GetClass()=="gmod_tool") and (weapon:GetMode()=="ffvgate")) then return end

	local stage=weapon:GetStage()
	if (stage==2) then render.DrawLine(bottom,top)
	elseif (stage==3) then
		local maxs=(Vector(x,GetConVar("ffvgate_width"):GetFloat(),y)/2)
		maxs:Rotate(normal:Angle())
		render.DrawWireframeBox((bottom+top)/2,Angle(0,0,0),-maxs,maxs)
	end
end)

function TOOL.BuildCPanel(cpanel)
	cpanel:Help("#tool.ffvgate.desc")

	cpanel:KeyBinder("button","ffvgate_key")
	cpanel:CheckBox("toggle","ffvgate_toggle")

	cpanel:NumSlider("speed","ffvgate_speed",.1,200)

	cpanel:NumSlider("width","ffvgate_width",1,256)

	cpanel:MatSelect("ffvgate_mat",{
		"phoenix_storms/dome",
		"models/props_interiors/metalfence007a",
		"phoenix_storms/stripes",
		"models/props_wasteland/wood_fence01a_skin2",
		"models/props_debris/metalwall001a",
		"phoenix_storms/metalbox",
		"phoenix_storms/metalset_1-2",
		"models/props_pipes/Pipesystem01a_skin3",
	},true,.25,.25)

	local movesound=cpanel:ComboBoxMulti("moving sound",list.Get("ffvgateMoveSounds"))
	local stopsound=cpanel:ComboBoxMulti("slam sound",list.Get("ffvgateStopSounds"))
end

list.Set("ffvgateMoveSounds","garage door",{ffvgate_movesound="doors/garage_move1.wav"})
list.Set("ffvgateMoveSounds","squeaky gate",{ffvgate_movesound="doors/gate_move1.wav"})
list.Set("ffvgateMoveSounds","shaky",{ffvgate_movesound="doors/door_metal_thin_move1.wav"})
list.Set("ffvgateMoveSounds","heavy metal",{ffvgate_movesound="doors/heavy_metal_move1.wav"})
list.Set("ffvgateMoveSounds","pnuematic",{ffvgate_movesound="doors/doormove3.wav"})
list.Set("ffvgateMoveSounds","door",{ffvgate_movesound="doors/default_move.wav"})
list.Set("ffvgateMoveSounds","none",{ffvgate_movesound=""})

list.Set("ffvgateStopSounds","garage door",{ffvgate_stopsound="doors/garage_stop1.wav"})
list.Set("ffvgateStopSounds","heavy metal",{ffvgate_stopsound="doors/heavy_metal_stop1.wav"})
list.Set("ffvgateStopSounds","plastic",{ffvgate_stopsound="doors/door1_stop.wav"})
list.Set("ffvgateStopSounds","latch 1",{ffvgate_stopsound="doors/default_stop.wav"})
list.Set("ffvgateStopSounds","latch 2",{ffvgate_stopsound="doors/door_latch1.wav"})
list.Set("ffvgateStopSounds","shaky",{ffvgate_stopsound="doors/door_metal_thin_close2.wav"})
list.Set("ffvgateStopSounds","clatter",{ffvgate_stopsound="doors/metal_stop1.wav"})
list.Set("ffvgateStopSounds","none",{ffvgate_stopsound=""})
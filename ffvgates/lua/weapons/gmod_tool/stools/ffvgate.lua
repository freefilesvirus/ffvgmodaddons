TOOL.Category="Construction"
TOOL.Name="#tool.ffvgate.name"

if CLIENT then
	TOOL.Information={
		{name="pos1",icon="gui/lmb.png",stage=0},
		{name="pos2",icon="gui/lmb.png",stage=1},
		{name="confirm",icon="gui/lmb.png",stage=2},
		{name="reset",icon="gui/r.png",op=1}
	}

	language.Add("tool.ffvgate.name","gate")
	language.Add("tool.ffvgate.desc","builds gates shaped to doorways")
	language.Add("tool.ffvgate.pos1","set axis 1")
	language.Add("tool.ffvgate.pos2","set axis 2")
	language.Add("tool.ffvgate.confirm","confirm shape")
	language.Add("tool.ffvgate.reset","reset")

	TOOL.ClientConVar["shake"]=1
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

	a1p1=Vector(0,0,0)
	a1p2=Vector(0,0,0)
	a2p1=Vector(0,0,0)
	a2p2=Vector(0,0,0)
	pos=Vector(0,0,0)
	angle=Angle(0,0,0)
	x=0
	y=0
	net.Receive("ffvgate_info",function(len,ply)
		local type=net.ReadInt(3)
		if (type==0) then
			a1p1=net.ReadVector()
			a1p2=net.ReadVector()
		elseif (type==1) then
			a2p1=net.ReadVector()
			a2p2=net.ReadVector()
			x=(a2p1-a2p2):Length()
			y=(a1p1-a1p2):Length()
			pos=((a2p1+a2p2)/2)
			angle=net.ReadAngle()
		end
	end)

	hook.Add("PostDrawTranslucentRenderables","ffvgate_preview",function()
		local weapon=LocalPlayer():GetActiveWeapon()
		if !(IsValid(weapon) and (weapon:GetClass()=="gmod_tool") and (weapon:GetMode()=="ffvgate")) then return end

		local stage=weapon:GetStage()
		if (stage==1) then render.DrawLine(a1p1,a1p2)
		elseif (stage==2) then
			local maxs=(Vector(x,GetConVar("ffvgate_width"):GetFloat(),y)/2)
			render.DrawWireframeBox(pos,angle,-maxs,maxs)
		end
	end)
else
	util.AddNetworkString("ffvgate_fail")
	util.AddNetworkString("ffvgate_info")

	function makeGate(ply,pos,ang,mat,key,x,y,width,speed,shake,moveSound,stopSound,toggle,isOpen,open,closed,dir)
		local gate=ents.Create("ffv_gate")
		gate:SetPos(pos)
		gate:SetAngles(ang)
		gate:SetMaterial(mat)
		gate.mat=mat
		gate.x=x
		gate.y=y
		gate.width=width
		gate.speed=speed
		gate.shake=shake

		gate.ply=ply

		if (moveSound~="") then gate.moveSound=Sound(moveSound) end
		if (stopSound~="") then gate.stopSound=Sound(stopSound) end


		if (isOpen==nil) then
			isOpen=false
			closed=pos
			open=(pos+(ang:Up()*(y-4)))
			dir=(open-closed):GetNormalized()
		end
		gate.isOpen=isOpen
		gate.closed=closed
		gate.open=open
		gate.dir=dir

		gate:Spawn()

		gate.key=key
		gate.toggle=toggle
		numpad.OnDown(ply,key,"ffvgate_toggle",gate)
		if !(toggle) then numpad.OnUp(ply,key,"ffvgate_toggle",gate) end

		return gate
	end
	duplicator.RegisterEntityClass("ffv_gate",makeGate,"Pos","Ang","mat","key","x","y","width","speed","shake","moveSound","stopSound","toggle",
		"isOpen","open","closed","dir")
end

local maxSize=CreateConVar("ffvgate_max_size",9999)

function TOOL:LeftClick(trace)
	local stage=self:GetStage()

	if (stage==0) then
		if trace.HitSky then
			

			return false
		end

		local tr=util.TraceLine({
			start=trace.HitPos,
			endpos=(trace.HitPos+(trace.HitNormal*maxSize:GetFloat())),
		})

		if (!(tr.Hit) or tr.HitSky) then
			self:fail("cant find opposing side!")
			return false
		end

		if SERVER then
			net.Start("ffvgate_info")
	 		net.WriteInt(0,3)
	 		net.WriteVector(tr.HitPos)
	 		net.WriteVector(trace.HitPos)
			net.Send(self:GetOwner())

			for k,t in pairs({trace,tr}) do self:SetObject(k-1,Entity(0),t.HitPos,0,0,t.HitNormal) end
		end
	elseif (stage==1) then
		if (math.abs(self:GetNormal(0):Dot(trace.HitNormal))==1) then
			self:fail("axes need to be perpendicular!")
			return false
		end

		local traces={}
		local midPos=((self:GetPos(0)+self:GetPos(1))/2)
		for k=-1,1,2 do
			local tr=util.TraceLine({start=midPos,endpos=midPos+(trace.HitNormal*maxSize:GetFloat()*k)})
			if (!(tr.Hit) or tr.HitSky) then
				self:fail("cant find opposing side!")
				return false
			end

			table.insert(traces,tr)
		end

		if SERVER then
			net.Start("ffvgate_info")
	 		net.WriteInt(1,3)

	 		for k,t in pairs(traces) do
	 			net.WriteVector(t.HitPos)
	 			self:SetObject(k+1,Entity(0),t.HitPos,0,0,t.HitNormal)
	 		end
	 		net.WriteAngle(self:GetNormal(2):AngleEx(self:GetNormal(0)))
			net.Send(self:GetOwner())
		end
	elseif ((stage==2) and SERVER) then
		local gate=makeGate(self:GetOwner(),(self:GetPos(2)+self:GetPos(3))/2,self:GetNormal(2):AngleEx(self:GetNormal(0)), --ply pos ang
			self:GetClientInfo("mat"),self:GetClientNumber("key"),math.abs((self:GetPos(2)-self:GetPos(3)):Length()), --mat key x
			math.abs((self:GetPos(0)-self:GetPos(1)):Length()),self:GetClientNumber("width"),self:GetClientNumber("speed"), --y width speed
			self:GetClientNumber("shake"),self:GetClientInfo("movesound"),self:GetClientInfo("stopsound"),self:GetClientBool("toggle")) --the names are right there

		undo.Create("gate")
		undo.AddEntity(gate)
		undo.SetPlayer(self:GetOwner())
		undo.Finish()
	end

	if (stage==0) then self:SetOperation(1) end
	if (stage<2) then self:SetStage(stage+1)
	else
		self:SetStage(0)
		self:SetOperation(0)
	end

	return true
end

function TOOL:fail(reason)
	net.Start("ffvgate_fail")
	net.WriteString(reason)
	net.Send(self:GetOwner())
end

function TOOL:Deploy()
	self:ClearObjects()
	self:SetOperation(0)
	self:SetStage(0)
end

function TOOL.BuildCPanel(cpanel)
	cpanel:Help("#tool.ffvgate.desc")

	cpanel:KeyBinder("button","ffvgate_key")
	cpanel:CheckBox("toggle","ffvgate_toggle")

	cpanel:CheckBox("shake","ffvgate_shake")

	cpanel:NumSlider("speed","ffvgate_speed",.1,50)

	cpanel:NumSlider("width","ffvgate_width",1,256)

	cpanel:MatSelect("ffvgate_mat",{ --pheonix storms i love ya
		"phoenix_storms/dome",
		"models/props_interiors/metalfence007a",
		"phoenix_storms/stripes",
		"models/props_wasteland/wood_fence01a_skin2",
		"models/props_debris/metalwall001a",
		"phoenix_storms/metalbox",
		"phoenix_storms/metalset_1-2",
		"models/props_pipes/Pipesystem01a_skin3",
		"phoenix_storms/mat/mat_phx_carbonfiber",
		"phoenix_storms/pack2/metalbox2",
		"phoenix_storms/pack2/train_floor",
		"phoenix_storms/trains/track_plateside",
		"phoenix_storms/cube",
		"phoenix_storms/futuristictrackramp_1-2",
		"phoenix_storms/glass",
		"phoenix_storms/side",
		"phoenix_storms/wood_dome"
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
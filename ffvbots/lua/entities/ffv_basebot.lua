AddCSLuaFile()

ENT.Base = "base_ai"
ENT.Spawnable = false

ENT.parts = {}
ENT.sounds = {}
ENT.lastThink = 0
ENT.target = nil
ENT.goalPos = nil
ENT.grounded = false
ENT.path = nil

ENT.maxHealth = 80
ENT.isffvrobot = true
ENT.willFight = false
ENT.friendly = true

ENT.light=nil
ENT.rt=nil

function ENT:OnEntityCopyTableFinish(data)
	data.parts={}
	data.sounds={}
end

function ENT:Draw()
	local toDraw={self}
	table.Add(toDraw,self.parts)
	for k,v in pairs(toDraw) do v:DrawModel() end
end

function ENT:Initialize()
	if CLIENT then
		if not game.SinglePlayer() then
			net.Start("ffvbot_clientparts")
			net.WriteEntity(self)
			net.SendToServer()
		end

		return
	end

	self:SetHealth(self.maxHealth)
	self:SetHullType( HULL_MEDIUM )
	self:SetHullSizeNormal()
	self:SetActivity(ACT_COVER)

	local sound = CreateSound(self,"vehicles/diesel_loop2.wav")
	sound:PlayEx(.6,180)
	table.insert(self.sounds,sound)

	self:extraInit()

	self.light=self.parts[#self.parts]

	if game.SinglePlayer() then self:sendClientParts() end
end

function ENT:sendClientParts()
	net.Start("ffvbot_clientparts")
	net.WriteEntity(self)
	net.WriteInt(#self.parts,12)
	for k,v in pairs(self.parts) do net.WriteEntity(v) end
	net.Broadcast()
end

ENT.dead=false
function ENT:OnTakeDamage(dmg)
	self:EmitSound("weapons/stunstick/spark"..math.random(3)..".wav")
	self:SetHealth(self:Health()-dmg:GetDamage())
	if ((self:Health()<1) and (not self.dead)) then
		self.dead=true
		
		local attacker=dmg:GetAttacker()
		if (not IsValid(attacker)) then return end
		local inflictor=dmg:GetInflictor()
		if (not IsValid(inflictor)) then inflictor=attacker end

		self:pop()
		gamemode.Call("SendDeathNotice",attacker:IsPlayer() and attacker or ("#"..attacker:GetClass()),
			(inflictor:IsPlayer() or (inflictor:IsNPC() and IsValid(inflictor:GetActiveWeapon()))) and inflictor:GetActiveWeapon():GetClass() or inflictor:GetClass(),
			self.PrintName,((attacker:IsNPC() and (attacker:Classify()<=3)) and 2 or 0))
		return
	end
	self:extraTakeDamage(dmg)

	--light
	if (not randomChance(3)) then return end
	local light = self.parts[#self.parts]
	local lamp = light:GetParent()
	lamp:SetSkin(1)
	light:SetKeyValue("lightcolor",Format("0 0 0 0",10000))
	timer.Simple(.2,function()
		if (not IsValid(self)) then return end
		lamp:SetSkin(0)
		light:SetKeyValue("lightcolor",Format("255 255 255 255",10000))
	end)
	--spark
	if (not randomChance(6)) then return end
	local effectdata = EffectData()
	effectdata:SetOrigin(lamp:GetPos()+getRotated(Vector(0,0,-0),lamp:GetAngles()))
	effectdata:SetNormal(lamp:GetUp()-(lamp:GetForward()/2))
	util.Effect("ManhackSparks",effectdata)
end

function ENT:Think()
	if CLIENT then return end

	if (not IsValid(self.target)) then self.target = nil end
	if (IsValid(self.target) and ((cvars.Number("ai_ignoreplayers")==1) and self.target:IsPlayer())) then self.target = nil end

	self:setGrounded()
	if ((CurTime()-self.lastThink)>1) then
		self:delayedThink()
		self.lastThink = CurTime()
		--calculate path
		if self.goalPos then self.path = AstarVector(self:GetPos(),self.goalPos) end
	end
	self:tickThink()

	--movement
	local nextPos = self:GetPos()
	if (navmesh.IsLoaded() and (self.goalPos and (cvars.Number("ai_disabled")==0))) then
		nextPos = self.goalPos
		if istable(self.path) then
			nextPos = self.path[#self.path-1]:GetCenter()
		end
		self:movement(nextPos)
	end

	self:NextThink(CurTime())
	return true
end

function ENT:OnRemove()
	if CLIENT then return end
	for k,v in pairs(self.parts) do if IsValid(v) then v:Remove() end end
	for k,v in pairs(self.sounds) do if v:IsPlaying() then v:Stop() end end
	for k,v in ipairs(player.GetAll()) do
		if (v:GetViewEntity()==self.parts[#self.parts]) then
			v:SetViewEntity(v)
			v:SetFOV(0)
		end
	end
	self:extraRemove()
end

function ENT:setGrounded()
	local min,max = self:GetCollisionBounds()
	min = min+Vector(2,2,1)
	max = max-Vector(2,2,0)
	local angles = self:GetAngles()
	min:Rotate(angles)
	local points = {
		self:GetPos()+min,
		self:GetPos()+min+getRotated(max*Vector(2,0,0),angles),
		self:GetPos()+min+getRotated(max*Vector(0,2,0),angles),
		self:GetPos()+min+getRotated(max*Vector(2,2,0),angles),
		self:GetPos()+min+getRotated(max*Vector(1,1,0),angles)
	}
	local hits = 0
	for k,v in pairs(points) do
		-- debugoverlay.Sphere(v,1,.03,Color(255,0,0),true)
		-- debugoverlay.Sphere(v-(self:GetUp()*2),1,.03,Color(0,0,255),true)
		if (util.TraceLine({start=v,endpos=v-(self:GetUp()*8),filter=self}).Hit) then hits = hits+1 end
	end
	self.grounded = true
	if (hits<3) then self.grounded = false end
	if self:IsPlayerHolding() then self.grounded = false end
	local x,z = math.abs(angles.x),math.abs(angles.z)
	if ((((z>x) and z) or x)>50) then self.grounded = false end
	if (not self:GetPhysicsObject():IsMotionEnabled()) then self.grounded = false end
end

function ENT:addPart(model,pos,ang,scale)
	if (scale==nil) then scale = 1 end
	local part = ents.Create("prop_dynamic")
	part:SetModel(model)
	pos:Rotate(self:GetAngles())
	part:SetPos(self:GetPos()+pos)
	part:SetAngles(self:GetAngles()+ang)
	part:SetModelScale(scale)
	part:SetParent(self)
	table.insert(self.parts,part)

	return part
end

function ENT:makeLight(lamp,offset)
	if (not offset) then offset = Vector(4,0,4) end

	local light = ents.Create("env_projectedtexture")
	light:Spawn()
	light:SetParent(lamp)
	light:SetKeyValue("enableshadows",1)
	light:SetKeyValue("lightfov",70)
	light:SetKeyValue("lightcolor",Format("255 255 255 255",10000))
	light:Input("SpotlightTexture",nil,nil,"effects/flashlight001")
	light:SetLocalPos(offset)
	light:SetLocalAngles(Angle(0,0,0))
	light.bot = self
	table.insert(self.parts,light)
	
	return light
end

function ENT:deathNotice(attacker,inflictor)
	net.Start("DeathNoticeEvent")
		if isstring(attacker) then
			net.WriteUInt(1,2)
			net.WriteString(attacker)
		else
			net.WriteUInt(2,2)
			net.WriteEntity(attacker)
		end
		net.WriteString(inflictor)
		net.WriteUInt(1,2)
		net.WriteString(self.PrintName)
		net.WriteUInt(((not self.willFight) or self.friendly) and 1 or 0,8)
	net.Broadcast()
end

ENT.popped=false
function ENT:pop()
	if self.popped then return end
	self.popped=true
	
	self:prePop()
	local makeUndo = false
	local undoPly = nil
	local newParts = {}
	for k,v in pairs(undo.GetTable()) do
		for k1,v1 in pairs(v) do
			if (v1["Entities"][1]==self) then
				makeUndo = true
				undoPly = v1["Owner"]
			end
		end
	end
	if makeUndo then
		undo.Create(self.PrintName)
		undo.SetPlayer(undoPly)
	end

	table.insert(self.parts,self)
	for k,v in pairs(self.parts) do
		local nogo = false
		if (v:GetClass()=="env_projectedtexture") then nogo = true end
		if ((not nogo) and (v:GetModelScale()<.1)) then nogo = true end
		if (not nogo) then
			local part = ents.Create("prop_physics")
			part:SetModel(v:GetModel())
			part:SetModelScale(v:GetModelScale())
			part:SetPos(v:GetPos())
			part:SetAngles(v:GetAngles())
			part:SetSkin(v:GetSkin())
			part:Spawn()
			part:GetPhysicsObject():SetVelocity(self:GetPhysicsObject():GetVelocity())
			part:GetPhysicsObject():SetAngleVelocity(self:GetPhysicsObject():GetAngleVelocity())
			part:Activate()
			if (v:GetModel()=="models/props_wasteland/light_spotlight01_lamp.mdl") then
				local light = self:makeLight(part)
				table.remove(self.parts)
				--maybe would be better to use a new entity instead of timers? idk
				--i wrote that comment a while ago; new entity? what?
				local initDelay = math.Rand(1,6)
				timer.Simple(initDelay,function()
					if ((not IsValid(light)) or (not IsValid(part))) then return end
					part:EmitSound("items/flashlight1.wav")
					part:EmitSound("weapons/stunstick/spark"..math.random(3)..".wav")
					part:SetSkin(1)
					light:SetKeyValue("lightcolor",Format("0 0 0 0",0))
				end)
				timer.Simple(initDelay+.3,function()
					if ((not IsValid(light)) or (not IsValid(part))) then return end
					part:SetSkin(0)
					light:SetKeyValue("lightcolor",Format("255 255 255 255",10000))
				end)
				timer.Simple(initDelay+math.Rand(.8,3),function()
					if ((not IsValid(light)) or (not IsValid(part))) then return end
					part:EmitSound("items/flashlight1.wav")
					part:EmitSound("weapons/stunstick/spark"..math.random(3)..".wav")
					part:SetSkin(1)
					light:Remove()

					local effectdata = EffectData()
					effectdata:SetOrigin(part:GetPos()+getRotated(Vector(0,0,-0),part:GetAngles()))
					effectdata:SetNormal(part:GetUp()-(part:GetForward()/2))
					util.Effect("ManhackSparks",effectdata)
				end)
			end
			undo.AddEntity(part)

			for k,v in pairs(newParts) do
				constraint.NoCollide(part,v,0,0)
			end
			table.insert(newParts,part)
		end
	end

	if makeUndo then undo.Finish() end
	self:OnRemove()
end

function ENT:fixRelationships()
	if (not self.willFight) then return end

	for k,v in ipairs(ents.GetAll()) do
		if v:IsNPC() then
			if self:getFriendly(v) then
				v:AddEntityRelationship(self,D_LI,5)
			else
				v:AddEntityRelationship(self,D_HT,5)
				v:SetEnemy(self)
			end
		end
	end
end

function ENT:getFriendly(ent)
	if (not (ent:IsPlayer() or ent:IsNPC())) then return false end
	if ent.isffvrobot then
		return (self.friendly==ent.friendly)
	end
	if self.friendly then return (ent:IsPlayer() or (ent:Classify()<=3))
	else return (not (ent:IsPlayer() or (ent:Classify()<=3))) end
end

--override these
function ENT:extraInit() end
function ENT:extraTakeDamage(dmg) end
function ENT:preThink() end
function ENT:delayedThink() end
function ENT:tickThink() end
function ENT:extraRemove() end
function ENT:prePop() end
--also ENT:setGrounded() can be changed if needed to calculate differently

------------------------------------------------------------
--default stuff that i can copy over
function ENT:extraInit()
	if CLIENT then return end
	self:SetModel("models/props_lab/filecabinet02.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	local lamp = self:addPart("models/props_wasteland/light_spotlight01_lamp.mdl",Vector(0,0,20),Angle(0,0,0))
	self:makeLight(lamp)
end

function ENT:tickThink()
	local phys = self:GetPhysicsObject()
	if self.grounded then
		phys:SetMaterial("gmod_ice")
		phys:SetVelocity(phys:GetVelocity()*.9)
		phys:SetAngleVelocity(phys:GetAngleVelocity()*.9)
	else
		phys:SetMaterial("metal")
	end
end

function ENT:movement(pos)
	if (not self.grounded) then return end
	-- debugoverlay.Sphere(pos,1,.03,Color(0,0,0),true)
	-- debugoverlay.Sphere(self.goalPos,1,.03,Color(255,0,0),true)

	--curb
	local phys = self:GetPhysicsObject()
	local curbAllowance = 6
	local min,max = self:GetCollisionBounds()
	local tr = {
		start=self:GetPos()+getRotated(Vector(max.x+6,0,-max.z+curbAllowance),self:GetAngles()),
		endpos=self:GetPos()+getRotated(Vector(max.x+6,0,-max.z),self:GetAngles()),
		filter=self}
	local trace = util.TraceLine(tr)
	-- debugoverlay.Sphere(trace.StartPos,1,.03,Color(255,0,0),true)
	-- debugoverlay.Sphere(trace.HitPos,1,.03,Color(0,0,255),true)
	if ((tr.endpos.z-trace.HitPos.z)<-1) then
		phys:AddAngleVelocity(Vector(0,-60,0))
		phys:AddVelocity((self:GetUp()*16)-(self:GetForward()*2))
	elseif (not trace.Hit) then phys:AddAngleVelocity(Vector(0,5,0)) end

	--look at goal
	local look = math.NormalizeAngle(getRotated(pos-self:GetPos(),-self:GetAngles()):Angle().y)
	local lookMod = math.abs(math.Clamp(math.abs(look/8),1,3)-3)
	phys:AddAngleVelocity(Vector(0,0,math.Clamp(look,-8,8)))

	--forward
	local x,z = self:GetAngles().x,self:GetAngles().z
	local rampMod = (((math.abs(z)>math.abs(x)) and z) or x)
	rampMod = (((rampMod<0) and math.abs(rampMod/10)) or 0)
	phys:AddVelocity(self:GetForward()*((2*lookMod)+rampMod))

	if (IsValid(self.goalPos) and (tr.endpos:DistToSqr(self.goalPos)<600 or self:GetPos():DistToSqr(self.goalPos)<600)) then
		self.goalPos = nil
		return true
	end
	return false
end
------------------------------------------------------------

--useful functions
function lineOfSight(ent,pos,accuracy)
	--1 is gauranteed, -1 is have to look at it perfectly
	if ((not isvector(pos)) and (not IsValid(pos))) then return false end
	if (not isvector(pos)) then
		pos = (pos:WorldSpaceCenter() or pos:GetPos())
	end
	if (accuracy==nil) then accuracy = 0 end
	local dif = (ent:GetPos()-pos):GetNormalized()
	if (ent:IsPlayer() or ent:IsNPC()) then
		dif:Rotate(-ent:EyeAngles())
	else
		dif:Rotate(-ent:GetAngles())
	end
	return ((dif.x<accuracy) and (not util.TraceLine({start=ent:GetPos(),endpos=pos}).HitWorld))
end

function randomChance(chance)
	--its just a 1 in blank chance, cause im lazy and is quicker than typing out (math.random(2)==1)
	if (math.random(chance)==1) then return true end
	return false
end

function weightedRandom(chances)
	--table format: {chance,chance,chance}
	--example {5,1} has a 5/6 chance of returning 1 and 1/6 chance of returning 2
	
	local totalChances=0
	for k,v in pairs(chances) do totalChances=(totalChances+v) end
	
	local decision=math.Rand(1,totalChances)
	local tested=0
	for k,v in pairs(chances) do
		if ((tested+v)>=decision) then return k end

		tested=(tested+v)
	end

	return #chances
end

function getRotated(vec,ang)
	local newVec = vec + Vector(0,0,0)
	newVec:Rotate(ang)
	return newVec
end

--pathfinding code taken from gmod wiki
function Astar( start, goal )
	if ( !IsValid( start ) || !IsValid( goal ) ) then return false end
	if ( start == goal ) then return true end

	start:ClearSearchLists()

	start:AddToOpenList()

	local cameFrom = {}

	start:SetCostSoFar( 0 )

	start:SetTotalCost( heuristic_cost_estimate( start, goal ) )
	start:UpdateOnOpenList()

	while ( !start:IsOpenListEmpty() ) do
		local current = start:PopOpenList() -- Remove the area with lowest cost in the open list and return it
		if ( current == goal ) then
			return reconstruct_path( cameFrom, current )
		end

		current:AddToClosedList()

		for k, neighbor in pairs( current:GetAdjacentAreas() ) do
			local newCostSoFar = current:GetCostSoFar() + heuristic_cost_estimate( current, neighbor )

			if ( neighbor:IsUnderwater() ) then -- Add your own area filters or whatever here
				continue
			end
			
			if ( ( neighbor:IsOpen() || neighbor:IsClosed() ) && neighbor:GetCostSoFar() <= newCostSoFar ) then
				continue
			else
				neighbor:SetCostSoFar( newCostSoFar );
				neighbor:SetTotalCost( newCostSoFar + heuristic_cost_estimate( neighbor, goal ) )

				if ( neighbor:IsClosed() ) then
				
					neighbor:RemoveFromClosedList()
				end

				if ( neighbor:IsOpen() ) then
					-- This area is already on the open list, update its position in the list to keep costs sorted
					neighbor:UpdateOnOpenList()
				else
					neighbor:AddToOpenList()
				end

				cameFrom[ neighbor:GetID() ] = current:GetID()
			end
		end
	end

	return false
end

function heuristic_cost_estimate( start, goal )
	-- Perhaps play with some calculations on which corner is closest/farthest or whatever
	return start:GetCenter():Distance( goal:GetCenter() )
end

-- using CNavAreas as table keys doesn't work, we use IDs
function reconstruct_path( cameFrom, current )
	local total_path = { current }

	current = current:GetID()
	while ( cameFrom[ current ] ) do
		current = cameFrom[ current ]
		table.insert( total_path, navmesh.GetNavAreaByID( current ) )
	end
	return total_path
end

function AstarVector( start, goal )
	local startArea = navmesh.GetNearestNavArea( start )
	local goalArea = navmesh.GetNearestNavArea( goal )
	return Astar( startArea, goalArea )
end

--watch stuff
drive.Register("drive_ffvrobot",
{
	StartMove = function( self, mv, cmd )
		if ( mv:KeyReleased( IN_USE ) ) then self:Stop() end
	end,
	Init = function(self) self.Player:SetFOV(150) end,
	SetupControls = function() end,
	Move = function() end,
	FinishMove = function() end,
	CalcView = function() end,
	Stop = function( self )
		self.StopDriving = true
		self.Player:SetFOV(0)
	end
})

properties.Add( "watchffvrobot", {
	MenuLabel = "Watch",
	Order = 1101,
	MenuIcon = "materials/ffvrobots/robotwatch.png",

	Filter = function( self, ent, ply )

		if (not ent.isffvrobot) then return false end

		return true

	end,

	Action = function( self, ent )

		self:MsgStart()
			net.WriteEntity( ent )
		self:MsgEnd()

	end,

	Receive = function( self, length, ply )

		local ent = net.ReadEntity()
		if ( !properties.CanBeTargeted( ent, ply ) ) then return end
		if ( !self:Filter( ent, ply ) ) then return end
		if (not (ent.parts[#ent.parts]:GetClass()=="env_projectedtexture")) then return end

		drive.PlayerStartDriving( ply, ent.parts[#ent.parts], "drive_ffvrobot" )
		net.Start("markbotlight")
		net.WriteEntity(ent.parts[#ent.parts])
		net.Broadcast()

	end

} )
if SERVER then
	util.AddNetworkString("markbotlight")
	util.AddNetworkString("ffvbot_clientparts")

	net.Receive("ffvbot_clientparts",function() net.ReadEntity():sendClientParts() end)
else
	net.Receive("ffvbot_clientparts",function()
		local bot=net.ReadEntity()
		if not IsValid(bot) then return end

		local numParts=net.ReadInt(12)
		if numParts>0 then
			for k=1,numParts do table.insert(bot.parts,net.ReadEntity()) end
		end

		bot.light=bot.parts[#bot.parts]
		bot.rt=GetRenderTarget("ffvbotrt_"..bot:EntIndex(),300,300)
	end)

	ENT.waitingUpdate=false
	function ENT:updateRt() self.waitingUpdate=true end

	hook.Add("PreRender","ffvbot_rt",function()
		for _,v in ipairs(ents.FindByClass("ffv_*")) do
			if v.isffvrobot and v.waitingUpdate then
				render.PushRenderTarget(v.rt)
				cam.Start2D()
				render.RenderView({origin=v.light:GetPos(),angles=v.light:GetAngles(),x=0,y=0,h=300,w=300,fov=150,drawviewmodel=false,drawviewer=true})
				cam.End2D()
				render.PopRenderTarget()
			end
		end
	end)
end
net.Receive("markbotlight",function()
	net.ReadEntity().isbotlight = true
end)

local robotWatchMat = Material("materials/ffvrobots/overlay.png")
hook.Add("PostDrawHUD","ffvrobotWatch",function()
	local ply = LocalPlayer()
	local viewEnt = ply:GetViewEntity()
	if (not (viewEnt:GetClass()=="class C_EnvProjectedTexture")) then return end
	if (not (viewEnt.isbotlight)) then return end
	cam.Start2D()
		surface.SetDrawColor(255,255,255,255)
		surface.SetMaterial(robotWatchMat)
		surface.DrawTexturedRect(0,0,ScrW(),ScrH())
	cam.End2D()
end)

--pop
properties.Add( "popffvrobot", {
	MenuLabel = "Pop",
	Order = 1103,
	MenuIcon = "materials/ffvrobots/robotwatch.png",

	Filter = function( self, ent, ply )

		if (not ent.isffvrobot) then return false end

		return true

	end,

	Action = function( self, ent )

		self:MsgStart()
			net.WriteEntity( ent )
		self:MsgEnd()

	end,

	Receive = function( self, length, ply )
		local bot=net.ReadEntity()
		bot:deathNotice("","")
		bot:pop()
	end

} )

--friendly/hostile
properties.Add("friendlyffvrobot",{
	MenuLabel="Make Hostile",
	Order=1102,
	MenuIcon="materials/ffvrobots/robotwatch.png",

	Filter=function(self,ent,ply)
		if (not ent.isffvrobot) then return false end
		if (not ent.willFight) then return false end
		local friendly = ent:GetNWBool("friendly",true)
		if friendly then self.MenuLabel = "Make Hostile"
		else self.MenuLabel = "Make Friendly" end
		return true
	end,
	Action=function(self,ent)
		self:MsgStart()
		net.WriteEntity(ent)
		self:MsgEnd()
	end,
	Receive=function()
		local ent = net.ReadEntity()
		ent.friendly = (not ent.friendly)
		ent:SetNWBool("friendly",ent.friendly)
		ent:fixRelationships()
	end
})
AddCSLuaFile()

ENT.Base="base_anim"
ENT.Type="anim"

ENT.parts={}
ENT.sounds={}
ENT.lastThink=0

ENT.target=nil

ENT.oldGoalPos=nil
ENT.goalPos=nil
ENT.goalDistance=1000
ENT.lastDistFromPath=math.huge
ENT.path=nil

ENT.speed=1
ENT.turnSpeed=1
ENT.grounded=false

ENT.maxHealth=80
ENT.isProbot=true
ENT.willFight=false
ENT.friendly=true

ENT.rt=nil

function ENT:Initialize()
	if CLIENT then
		if not game.SinglePlayer() then
			net.Start("pbot_clientparts")
			net.WriteEntity(self)
			net.SendToServer()
		end
		return
	end

	self:SetUseType(SIMPLE_USE)

	self:AddFlags(FL_OBJECT)
	self:fixRelationships()

	self:SetNWBool("friendly",self.friendly)

	self:SetHealth(self.maxHealth)

	local sound=CreateSound(self,"vehicles/diesel_loop2.wav")
	sound:PlayEx(.6,180)
	table.insert(self.sounds,sound)

	if game.SinglePlayer() then self:sendClientParts() end
end

function ENT:Think()
	if CLIENT or cvars.Number("ai_disabled")==1 then return end

	if not IsValid(self.target) or (cvars.Number("ai_ignoreplayers")==1 and self.target:IsPlayer()) then self.target=nil end

	self:setGrounded()
	self:fixGroundedFriction()

	if (CurTime()-self.lastThink)>1 then
		self:delayedThink()
		self.lastThink=CurTime()

		if self.goalPos then
			local newDist=self:GetPos():Distance(self:nextMovePos())
			local distDif=self.lastDistFromPath-newDist
			self.lastDistFromPath=newDist

			if self.goalPos~=self.oldGoalPos or (not istable(self.path) and self.path~=true) or distDif<-200 then self:setPath() end
			self.oldGoalPos=self.goalPos
		end
	end
	self:tickThink()

	if navmesh.IsLoaded() and self.goalPos and self.grounded then self:movement(self:nextMovePos()) end

	self:NextThink(CurTime())
	return true
end

function ENT:OnTakeDamage(dmg)
	if self:Health()<1 or dmg:GetDamage()<1 then return end

	self:EmitSound("weapons/stunstick/spark"..math.random(3)..".wav")

	local light=self.parts[#self.parts]
	local lamp=self.parts[#self.parts-1]
	if IsValid(light) and IsValid(lamp) then
		local effectdata=EffectData()
		effectdata:SetOrigin(lamp:GetPos())
		effectdata:SetNormal(lamp:GetUp()-(lamp:GetForward()/2))
		util.Effect("ManhackSparks",effectdata)

		lamp:SetSkin(1)
		light:SetKeyValue("lightcolor",Format("0 0 0 0",10000))

		timer.Simple(.2,function()
			if not (IsValid(light) and IsValid(lamp)) then return end

			lamp:SetSkin(0)
			light:SetKeyValue("lightcolor",Format("255 255 255 255",10000))
		end)
	end

	self:SetHealth(self:Health()-dmg:GetDamage())
	if self:Health()<1 then
		self:pop()

		local attacker=dmg:GetAttacker()
		if not attacker:IsPlayer() then attacker="#"..attacker:GetClass() end
		if not IsValid(attacker) then return end

		local inflictor=dmg:GetInflictor()
		if not IsValid(inflictor) then
			if isfunction(attacker.GetActiveWeapon) then inflictor=attacker:GetActiveWeapon()
			else inflictor=attacker end
		end

		local flags=0
		if not self.willFight or self.friendly then flags=flags+1 end
		if (attacker:IsNPC() or attacker.isProbot) and attacker:Classify()<=3 then flags=flags+2 end

		gamemode.Call("SendDeathNotice",attacker,inflictor:GetClass(),"#"..self:GetClass(),flags)
	end
end

function ENT:OnRemove()
	if CLIENT then return end

	for _,v in pairs(self.parts) do
		if IsValid(v) then v:Remove() end
	end
	for _,v in pairs(self.sounds) do
		if v:IsPlaying() then v:Stop() end
	end
end

function ENT:Draw()
	local toDraw={self}
	table.Add(toDraw,self.parts)
	for k,v in pairs(toDraw) do v:DrawModel() end
end

function ENT:OnEntityCopyTableFinish(data)
	data.parts={}
	data.sounds={}
end

function ENT:Classify()
	if not self.willFight then return 7	end
	if self.friendly then return 2 end
	return 9
end

function ENT:EyeAngles() return self.parts[#self.parts]:GetAngles() end
function ENT:EyePos() return self.parts[#self.parts]:GetPos() end

function ENT:movement(pos)
	local phys=self:GetPhysicsObject()
	if not IsValid(phys) then return end
	if not isvector(pos) then return end

	local min,max=self:GetCollisionBounds()
	local from1=Vector(max[1],0,min[3])
	local from2=Vector(max[1],0,max[3])
	for _,v in pairs({from1,from2}) do v:Set(self:LocalToWorld(v)) end

	local tr1=util.TraceLine({start=from1,endpos=from1+self:GetForward()*6+self:GetUp()*6,filter=self})
	local tr2=util.TraceLine({start=from2,endpos=from2+self:GetForward()*12,filter=self})
	if tr1.Hit and not tr2.Hit then
		phys:AddAngleVelocity(Vector(0,-180,0))
		phys:AddVelocity((self:GetUp()*24)-(self:GetForward()*100))
	else phys:AddAngleVelocity(Vector(0,5,0)) end

	local look=math.NormalizeAngle((self:GetPos()-pos):Angle().y-self:GetAngles().y-180)
	phys:AddAngleVelocity(Vector(0,0,math.Clamp(look,-12,12)*self.turnSpeed))

	local x,y,z=self:GetAngles():Unpack()
	local rampMod=math.abs(z)>math.abs(x) and z or x
	rampMod=rampMod<0 and math.abs(rampMod/10) or 0
	phys:AddVelocity(self:GetForward()*self.speed*(rampMod+math.Clamp(-math.abs(look)+60,-20,90)/4))

	if self:GetPos():DistToSqr(pos)<self.goalDistance then
		if istable(self.path) and #self.path>0 then table.remove(self.path,#self.path)
		elseif self.goalPos then self.goalPos=nil end

		self.lastDistFromPath=math.huge
		return true
	end
end

function ENT:addPart(model,pos,ang,scale)
	local part=ents.Create("prop_dynamic")
	part:SetModel(model)
	part:SetParent(self)

	part:SetLocalPos(pos)
	part:SetLocalAngles(ang)
	if scale~=nil then part:SetModelScale(scale) end

	table.insert(self.parts,part)
	return part
end

function ENT:makeLight(lamp,offset)
	if not offset then offset=Vector(4,0,4) end

	local light=ents.Create("env_projectedtexture")
	light:Spawn()
	light:SetParent(lamp)
	light:SetLocalPos(offset)
	light:SetLocalAngles(Angle(0,0,0))

	light:SetKeyValue("enableshadows",1)
	light:SetKeyValue("lightfov",70)
	light:SetKeyValue("lightcolor","255 255 255 255")
	light:Input("SpotlightTexture",nil,nil,"effects/flashlight001")

	table.insert(self.parts,light)
	return light
end

function ENT:sendClientParts()
	net.Start("pbot_clientparts")
	net.WriteEntity(self)
	net.WriteInt(#self.parts,12)
	for k,v in pairs(self.parts) do net.WriteEntity(v) end
	net.Broadcast()
end

function ENT:pop()
	local undoTable=nil
	for _,v in pairs(undo.GetTable()) do
		for _,u in pairs(v) do
			for _,e in pairs(u.Entities) do
				if e==self then
					undoTable=u
					break
				end
			end
			if undoTable then break end
		end
		if undoTable then break end
	end

	local phys=self:GetPhysicsObject()

	local parts={}
	table.insert(self.parts,self)
	for _,v in pairs(self.parts) do
		if v:GetClass()~="env_projectedtexture" and v:GetModelScale()>.1 then
			local part=ents.Create("prop_physics")
			part:SetModel(v:GetModel())
			part:SetSkin(v:GetSkin())
			part:SetModelScale(v:GetModelScale())

			part:SetPos(v:GetPos())
			part:SetAngles(v:GetAngles())

			part:Spawn()
			part:Activate()

			local newPhys=part:GetPhysicsObject()
			if IsValid(phys) and IsValid(newPhys) then
				newPhys:SetVelocity(phys:GetVelocity())
				newPhys:SetAngleVelocity(phys:GetAngleVelocity())
				newPhys:Wake()
			end

			for _,p in pairs(parts) do constraint.NoCollide(part,p,0,0) end

			table.insert(parts,part)
		end
	end

	if undoTable then undoTable.Entities=parts end

	self:Remove()
end

function ENT:setGrounded()
	local phys=self:GetPhysicsObject()
	if self:IsPlayerHolding() or (IsValid(phys) and not phys:IsMotionEnabled()) or self:GetAngles():Up():Dot(Vector(0,0,1))<.5 then
		self.grounded=false
		return
	end

	local min,max=self:GetCollisionBounds()
	min=min+Vector(2,2,1)
	max=max-Vector(2,2,0)

	local hits=0
	for k=1,5 do
		local from=Vector(0,0,min[3])
		if k>1 then
			for i=1,2 do from[i]=((k%2)==i)==(k>3) and min[i] or max[i] end
		end
		from:Rotate(self:GetAngles())
		from=from+self:GetPos()

		if util.TraceLine({start=from,endpos=from+(self:GetUp()*-8),filter=self}).Hit then
			hits=hits+1
			if hits>=3 then break end
		end
	end
	self.grounded=hits>=3
end

function ENT:fixGroundedFriction(phys)
	local phys=self:GetPhysicsObject()
	if not IsValid(phys) then return end

	if self.grounded then
		phys:SetMaterial("gmod_ice")
		phys:SetVelocity(phys:GetVelocity()*.9)
		phys:SetAngleVelocity(phys:GetAngleVelocity()*.9)
	else
		phys:SetMaterial("metal")
		return
	end
end

function ENT:nextMovePos()
	if istable(self.path) and #self.path>1 then return self.path[#self.path-1]:GetCenter()
	else return self.goalPos end
end

function ENT:fixRelationships(ent)
	if not self.willFight then return end

	if isentity(ent) then ent={ent}
	elseif ent==nil then ent=ents.GetAll() end

	for _,v in pairs(ent) do
		if v:IsNPC() then v:AddEntityRelationship(self,self:getFriendly(v) and D_LI or D_HT,5) end
	end
end

function ENT:getFriendly(ent)
	if ent:IsNPC() then return self.friendly==(ent:Classify()<=3) end
	if ent.isProbot then return self.friendly==ent.friendly end

	return self.friendly
end

function ENT:delayedThink() end
function ENT:tickThink() end

function ENT.lineOfSight(ent,pos)
	if not IsValid(ent) then return -1 end

	if isentity(pos) then pos=pos:GetPos() end
	if not isvector(pos) then return -1 end

	local tr=util.TraceLine({start=ent:GetPos(),endpos=pos,filter=game.GetWorld(),whitelist=true})
	if tr.Hit then return -1 end
	return (pos-ent:GetPos()):GetNormalized():Dot((isfunction(ent.EyeAngles) and ent:EyeAngles() or ent:GetAngles()):Forward()) or -1
end

function ENT.weightedRandom(chances)
	--table format: {chance,chance,chance}
	--example {5,1} has a 5/6 chance of returning 1 and 1/6 chance of returning 2
	
	local total=0
	for _,v in pairs(chances) do total=total+v end

	local pick=math.Rand(0,total)
	local tested=0
	for k,v in pairs(chances) do
		if pick<=v+tested then return k end

		tested=tested+v
	end

	return #chances
end

if SERVER then
	util.AddNetworkString("pbot_clientparts")

	net.Receive("pbot_clientparts",function() net.ReadEntity():sendClientParts() end)

	hook.Add("OnEntityCreated","pbot_fixnewrel",function(ent)
		if ent:IsNPC() then
			for _,v in ipairs(ents.FindByClass("pbot_*")) do
				if v.isProbot and v.willFight then v:fixRelationships(ent) end
			end
		end
	end)
else
	net.Receive("pbot_clientparts",function()
		local bot=net.ReadEntity()
		if not IsValid(bot) then return end

		local numParts=net.ReadInt(12)
		if numParts>0 then
			for k=1,numParts do table.insert(bot.parts,net.ReadEntity()) end
		end

		bot.light=bot.parts[#bot.parts]
		bot.rt=GetRenderTarget("pbotrt_"..bot:EntIndex(),300,300)
	end)

	ENT.waitingUpdate=false
	function ENT:updateRt() self.waitingUpdate=true end

	hook.Add("PreRender","pbot_rt",function()
		for _,v in ipairs(ents.FindByClass("pbot_*")) do
			if v.isProbot and v.waitingUpdate then
				render.PushRenderTarget(v.rt)
				cam.Start2D()
				render.RenderView({origin=v.light:GetPos(),angles=v.light:GetAngles(),x=0,y=0,h=300,w=300,fov=150,drawviewmodel=false,drawviewer=true})
				cam.End2D()
				render.PopRenderTarget()
			end
		end
	end)
end

properties.Add("probotFriendlyToggle",{
	MenuLabel="make hostile",
	Order=1102,
	MenuIcon="materials/probots/robotwatch.png",
	Filter=function(self,ent,ply)
		if not (ent.isProbot and ent.willFight) then return false end

		self.MenuLabel="make "..(ent:GetNWBool("friendly") and "hostile" or "friendly")

		return true
	end,
	Action=function(self,ent)
		self:MsgStart()
		net.WriteEntity(ent)
		self:MsgEnd()
	end,
	Receive=function()
		local bot=net.ReadEntity()
		bot.friendly=not bot.friendly
		bot:SetNWBool("friendly",bot.friendly)
		bot:fixRelationships()
	end
})

--pathfinding code taken from gmod wiki. nothing by me down here ----------------
local function heuristic_cost_estimate( start, goal )
	-- Perhaps play with some calculations on which corner is closest/farthest or whatever
	return start:GetCenter():Distance( goal:GetCenter() )
end

-- using CNavAreas as table keys doesn't work, we use IDs
local function reconstruct_path( cameFrom, current )
	local total_path = { current }

	current = current:GetID()
	while ( cameFrom[ current ] ) do
		current = cameFrom[ current ]
		table.insert( total_path, navmesh.GetNavAreaByID( current ) )
	end
	return total_path
end

local function Astar( start, goal )
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

local function AstarVector( start, goal )
	local startArea = navmesh.GetNearestNavArea( start )
	local goalArea = navmesh.GetNearestNavArea( goal )
	return Astar( startArea, goalArea )
end

--except this i did this
function ENT:setPath()
	if self.goalPos then
		self.path=AstarVector(self:GetPos(),self.goalPos)
		self.lastDistFromPath=math.huge
	end
end
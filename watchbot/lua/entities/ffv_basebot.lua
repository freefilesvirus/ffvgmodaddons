AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.Spawnable = false

ENT.parts = {}
ENT.sounds = {}
ENT.lastThink = 0
ENT.target = nil
ENT.goalPos = nil
ENT.grounded = false
ENT.path = nil

function ENT:Think()
	if CLIENT then return end
	if (not IsValid(self.target)) then self.target = nil end
	self:preThink()
	if ((CurTime()-self.lastThink)>1) then
		self:delayedThink()
		self.lastThink = CurTime()
		--calculate path
		if self.goalPos then self.path = AstarVector(self:GetPos(),self.goalPos) end
	end
	self:tickThink()

	--movement
	local nextpos = nil
	if (self.goalPos and (cvars.Number("ai_disabled")==0)) then
		nextPos = self.goalPos
		if istable(self.path) then
			nextPos = self.path[#self.path-1]:GetCenter()
		end
	end
	self:movement(nextPos)

	self:NextThink(CurTime())
	return true
end

function ENT:OnRemove()
	if CLIENT then return end
	for k,v in pairs(self.parts) do v:Remove() end
	for k,v in pairs(self.sounds) do v:Stop() end
	for k,v in ipairs(player.GetAll()) do
		if (v:GetViewEntity()==self.parts[#self.parts]) then
			v:SetViewEntity(v)
			v:SetFOV(0)
		end
	end
	self:extraRemove()
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

function ENT:makeLight(lamp)
	local light = ents.Create("env_projectedtexture")
	light:Spawn()
	light:SetParent(lamp)
	light:SetKeyValue("enableshadows",1)
	light:SetKeyValue("lightfov",70)
	light:SetKeyValue("lightcolor",Format("255 255 255 255",10000))
	light:Input("SpotlightTexture",nil,nil,"effects/flashlight001")
	light:SetLocalPos(Vector(4,0,4))
	light:SetLocalAngles(Angle(0,0,0))
	light.bot = self
	table.insert(self.parts,light)
	return light
end

--override these
function ENT:preThink() end
function ENT:delayedThink() end
function ENT:tickThink() end
function ENT:movement(pos) end
function ENT:extraRemove() end

--useful functions
function lineOfSight(ent,pos,accuracy)
	--1 is gauranteed, -1 is have to look at it perfectly
	if (not isvector(pos)) then pos = pos:GetPos() end
	if (accuracy==nil) then accuracy = 0 end
	local dif = (ent:GetPos()-pos):GetNormalized()
	if (ent:IsPlayer() or ent:IsNPC()) then
		dif:Rotate(-ent:EyeAngles())
	else
		dif:Rotate(-ent:GetAngles())
	end
	return dif.x<accuracy
end

function randomChance(chance)
	--its just a 1 in blank chance, cause im lazy and is quicker than typing out (math.random(2)==1)
	if (math.random(chance)==1) then return true end
	return false
end

function weightedRandom(chances)
	--table format: {chance,chance,chance}
	--example {5,1} has a 5/6 chance of returning 1 and 1/6 chance of returning 2
	local drawTable = {}
	for k,v in pairs(chances) do
		for i=1,v do
			table.insert(drawTable,k)
		end
	end
	return drawTable[math.random(#drawTable)]
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
	Order = 1100,
	MenuIcon = "materials/ffvrobots/robotwatch.png",

	Filter = function( self, ent, ply )

		if (not (string.StartsWith(ent:GetClass(),"ffv_") and string.EndsWith(ent:GetClass(),"bot"))) then return false end

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

	end

} )

local robotWatchMat = Material("materials/ffvrobots/overlay.png")
hook.Add("PostDrawHUD","ffvrobotWatch",function()
	local ply = LocalPlayer()
	local viewEnt = ply:GetViewEntity()
	if (not (viewEnt:GetClass()=="class C_EnvProjectedTexture")) then return end
	if (not (viewEnt:GetParent():GetModel()=="models/props_wasteland/light_spotlight01_lamp.mdl")) then return end
	cam.Start2D()
		surface.SetDrawColor(255,255,255,255)
		surface.SetMaterial(robotWatchMat)
		surface.DrawTexturedRect(0,0,ScrW(),ScrH())
	cam.End2D()
end)
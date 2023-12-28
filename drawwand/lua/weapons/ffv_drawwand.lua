AddCSLuaFile("ffv_dwsfuncs.lua")
include("ffv_dwsfuncs.lua")

SWEP.Category = "Other"
SWEP.PrintName = "Drawing Wand"
SWEP.Spawnable = true
SWEP.DrawAmmo = false
SWEP.Slot = 4
SWEP.Author = "freefilesvirus"

SWEP.Primary.Ammo = ""
SWEP.Secondary.Ammo = ""
SWEP.Secondary.Automatic = true

SWEP.errorSound = Sound("buttons/button10.wav")

SWEP.lines = {}
SWEP.drawing = false
SWEP.plyDrawPos = Vector(0,0,0)
SWEP.linecolor = Color(255,255,255)
--0 is no spells or lines
--1 is a circle has been drawn
--2 is a spell has been loaded into the wand
--loop between 2 and 1 until the wand is fired
SWEP.state = 0
SWEP.spellPoints = {}
SWEP.lineTurns = {}
SWEP.lineDir = Vector(0,0,0)
SWEP.lastPos = Vector(0,0,0)

SWEP.loadedSpells = {}

function SWEP:wand_network(state,vector,color)
	if (vector == nil) then vector = Vector(0,0,0) end
	if (color == nil) then color = Color(255,255,255) end

	net.Start("wandLine")
	net.WriteEntity(self)
	net.WriteInt(state,4)
	net.WriteVector(vector)
	net.WriteColor(color)
	net.Broadcast()
end

function SWEP:clear_lines()
	if CLIENT then return end
	self.lines = {}
	self:wand_network(1)
end

function SWEP:PrimaryAttack()
	if CLIENT then return end
	--if state 1 clear lines, go state 0
	--if state 2 fire spells
	--if state 3 clear lines, go state 2
	if (self.state == 0) then
		self:EmitSound("weapons/pistol/pistol_empty.wav")
	elseif (self.state == 1) then
		self:EmitSound("weapons/shotgun/shotgun_empty.wav")
		self:clear_lines()
		if (#self.loadedSpells > 0) then self.state = 2 return end
		self.state = 0
	elseif (self.state == 2) then
		local ply = self:GetOwner()
		local trace = ply:GetEyeTrace()
		for k, v in pairs(self.loadedSpells) do
			if v.targetEntity then
				if IsValid(trace.Entity) then
					v.action(trace.Entity,self)
				else
					self:EmitSound("weapons/pistol/pistol_empty.wav")
					return
				end
			else
				v.action(trace.HitPos,self)
			end
		end
		self:ShootEffects()
		self.loadedSpells = {}
		self.state = 0
	end
end

function SWEP:SecondaryAttack()
	if CLIENT then return end
	local ply = self:GetOwner()
	if (not self.drawing) then
		table.insert(self.lines,{})
		self.lineTurns = {}

		--add line table
		self:wand_network(2)
	end
	local curLine = self.lines[#self.lines]

	local drawPos = ply:EyePos()+(ply:EyeAngles():Forward()*64)
	if ((not self.drawing) or ((curLine[#curLine]-drawPos):Length() > GetConVar("dw_resolution"):GetFloat())) then
		table.insert(curLine,drawPos)

		--add vector
		self:wand_network(0,drawPos)

		--detect turns
		if (self.drawing) then
			local lineDir = (self.lastPos-drawPos):GetNormalized()
			if ((self.lineDir-lineDir):Length() > 1) then
				--turn
				table.insert(self.lineTurns,drawPos)
			end
			self.lineDir = lineDir
		else
			table.insert(self.lineTurns,drawPos)
			self.lineDir = Vector(0,0,0)
		end
		self.lastPos = drawPos
	end

	--self:SetNextSecondaryFire(CurTime()+.001)
	self.drawing = true
	timer.Create(ply:SteamID64().."drawend",.11,1,function()
		--player has finished drawing. it seems like there should be a hook for when the player finishes firing an automatic weapon but i couldnt find it
		if (not IsValid(self)) then return end
		self.drawing = false

		table.insert(self.lineTurns,drawPos)

		if ((self.state == 0) or (self.state == 2)) then
			--the first line should be the circle
			local averagedPos = Vector(0,0,0)
			for k, v in pairs(curLine) do
				averagedPos = averagedPos + v
			end
			averagedPos = averagedPos / #curLine
			local x = 0
			local y = 0

			for k, v in pairs(curLine) do
				--flattens all the points
				local newPos = v-averagedPos
				--this rotation value was the best i could figure out. it works fine if you look left or right but if you tilt your camera up or down it starts to go wonky, but only on one side? vector math SUX!
				local rot = ((ply:GetShootPos()-averagedPos)*Vector(-1,1,0)):Angle()
				newPos:Rotate(rot)
				newPos = newPos*Vector(0,1,1)
				
				if (newPos.y>x) then x = newPos.y end
				if (newPos.z>y) then y = newPos.z end
			end
			--normalize
			local mult = (x+y)/1
			x = x/mult
			y = y/mult
			local leniency = GetConVar("dw_leniency"):GetFloat()
			if ((x<leniency) and (y<leniency)) then
				--even enough
				if (((curLine[1]-curLine[#curLine]):Length()<6) and (#self.lineTurns<3)) then
					--closed, also no sharp turns
					--change color
					self:wand_network(3,Vector(0,0,0),Color(255,255,0))
					self.state = 1
					self.plyDrawPos = ply:GetPos()

					--find the main 16 points
					self.spellPoints = {}
					local rotateAxis = Angle(90,0,0)
					for i=1,16 do
						--it starts straight down then goes clockwise around
						local pos = (rotateAxis:Forward()*(mult/2))
						pos:Rotate(-((ply:GetShootPos()-averagedPos)*Vector(-1,1,0)):Angle())
						table.insert(self.spellPoints,pos+averagedPos)
						rotateAxis:RotateAroundAxis(Vector(1,0,0),360/16)
					end
					table.insert(self.spellPoints,averagedPos)
					return
				end
			end
			--not circle enough, fail
			self:EmitSound(self.errorSound)
			self:clear_lines()
			return
		elseif (self.state == 1) then
			--spell detection
			local pointTable = {}
			--go through each turn and find the closest one of the 16 major points
			for k, v in pairs(self.lineTurns) do
				local dist = 999999
				local closest = 0
				for k1, v1 in pairs(self.spellPoints) do
					local length = (v-v1):Length()
					if length < dist then
						dist = length
						closest = k1
					end
				end
				table.insert(pointTable,closest)
			end
			local spell = dw_find_spell(pointTable)
			if (spell == nil) then
				--no spell found
				self:EmitSound(self.errorSound)
				if (#self.loadedSpells > 0) then self.state = 2 else self.state = 0 end
			else
				--yes spell found
				if istable(spell.sound) then
					self:EmitSound(spell.sound[math.random(#spell.sound)])
				else
					self:EmitSound(spell.sound)
				end
				self.state = 2
				if ((not table.HasValue(self.loadedSpells,spell)) or spell.canStack) then
					table.insert(self.loadedSpells,spell)
				end
			end
			self:clear_lines()
		end
	end)
end

function SWEP:Think()
	local ply = self:GetOwner()
	--stop player from moving after drawing the base
	if ((self.state == 1) and ((ply:GetPos()-self.plyDrawPos):Length()>10)) then
		self:EmitSound(self.errorSound)
		if (#self.loadedSpells > 0) then self.state = 2 else self.state = 0 end
		self:clear_lines()
	end
end

net.Receive("wandLine", function()
	--write ent, the weapon
	--write int, state (0 is add vector, 1 is clear table, 2 is add line table, 3 is change color)
	--write vector, the one to add
	--write color, the one to change to
	local weapon = net.ReadEntity()
	local state = net.ReadInt(4)
	if (state == 0) then
		table.insert(weapon.lines[#weapon.lines],net.ReadVector())
	elseif (state == 1) then
		weapon.lines = {}
		weapon.linecolor = Color(255,255,255)
	elseif (state == 2) then
		table.insert(weapon.lines,{})
	elseif (state == 3) then
		net.ReadVector()
		weapon.linecolor = net.ReadColor()
	end
end)

hook.Add("PostDrawOpaqueRenderables","visualizeWandLines",function()
	cam.Start3D()
		for k, v in ipairs(ents.FindByClass("ffv_drawwand")) do
			--each weapon
			for k1, v1 in pairs(v.lines) do
				--each line in the weapon
				local lastPos = nil
				for k2, v2 in pairs(v1) do
					--each position in the line of the weapon. these nested for do loops dont feel great but idk what would be better
					if (not (lastPos == nil)) then
						render.DrawLine(v2,lastPos,v.linecolor,true)
					end
					lastPos = v2
				end
			end
		end
	cam.End3D()
end)

hook.Add("Initialize","wandNWString",function()
	if CLIENT then return end
	util.AddNetworkString("wandLine")
	CreateConVar("dw_leniency", .6)
	CreateConVar("dw_resolution", .2)
end)

--swep construction kit stuff
--weapon
SWEP.HoldType = "pistol"
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true
SWEP.ViewModelBoneMods = {
	["ValveBiped.clip"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
}
--viewmodels
SWEP.VElements = {
	["wandglow"] = { type = "Sprite", sprite = "sprites/animglow02", bone = "ValveBiped.square", rel = "wandtip", pos = Vector(0, 0, 2.596), size = { x = 10, y = 10 }, color = Color(255, 0, 0, 0), nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["wandbase"] = { type = "Model", model = "models/props_trainstation/trainstation_column001.mdl", bone = "ValveBiped.square", rel = "", pos = Vector(0, 0.03, 5.438), angle = Angle(0, 0, 0), size = Vector(0.108, 0.108, 0.019), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["wandtip"] = { type = "Model", model = "models/props_trainstation/trainstation_ornament002.mdl", bone = "ValveBiped.square", rel = "wandbase", pos = Vector(0, 0, 5.125), angle = Angle(0, 0, 0), size = Vector(0.1, 0.1, 0.1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}
--world models
SWEP.WElements = {
	["wandglow"] = { type = "Sprite", sprite = "sprites/animglow02", bone = "ValveBiped.Bip01_R_Hand", rel = "wandtip", pos = Vector(0, 0, 2.596), size = { x = 10, y = 10 }, color = Color(255, 0, 0, 0), nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["wandbase"] = { type = "Model", model = "models/props_trainstation/trainstation_column001.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(10.291, 2.098, -4), angle = Angle(-95, 0, 0), size = Vector(0.108, 0.108, 0.019), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
	["wandtip"] = { type = "Model", model = "models/props_trainstation/trainstation_ornament002.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "wandbase", pos = Vector(0, 0, 4.85), angle = Angle(0, 0, 0), size = Vector(0.1, 0.1, 0.1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
}

/********************************************************
	SWEP Construction Kit base code
		Created by Clavus
	Available for public use, thread at:
	   facepunch.com/threads/1032378
	   
	   
	DESCRIPTION:
		This script is meant for experienced scripters 
		that KNOW WHAT THEY ARE DOING. Don't come to me 
		with basic Lua questions.
		
		Just copy into your SWEP or SWEP base of choice
		and merge with your own code.
		
		The SWEP.VElements, SWEP.WElements and
		SWEP.ViewModelBoneMods tables are all optional
		and only have to be visible to the client.
********************************************************/

function SWEP:Initialize()

	// other initialize code goes here

	if CLIENT then
	
		// Create a new table for every weapon instance
		self.VElements = table.FullCopy( self.VElements )
		self.WElements = table.FullCopy( self.WElements )
		self.ViewModelBoneMods = table.FullCopy( self.ViewModelBoneMods )

		self:CreateModels(self.VElements) // create viewmodels
		self:CreateModels(self.WElements) // create worldmodels
		
		// init view model bone build function
		if IsValid(self.Owner) then
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) then
				self:ResetBonePositions(vm)
				
				// Init viewmodel visibility
				if (self.ShowViewModel == nil or self.ShowViewModel) then
					vm:SetColor(Color(255,255,255,255))
				else
					// we set the alpha to 1 instead of 0 because else ViewModelDrawn stops being called
					vm:SetColor(Color(255,255,255,1))
					// ^ stopped working in GMod 13 because you have to do Entity:SetRenderMode(1) for translucency to kick in
					// however for some reason the view model resets to render mode 0 every frame so we just apply a debug material to prevent it from drawing
					vm:SetMaterial("Debug/hsv")			
				end
			end
		end
		
	end

end

function SWEP:Holster()
	
	if CLIENT and IsValid(self.Owner) then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			self:ResetBonePositions(vm)
		end
	end
	
	return true
end

function SWEP:OnRemove()
	self:Holster()
end

if CLIENT then

	SWEP.vRenderOrder = nil
	function SWEP:ViewModelDrawn()
		
		local vm = self.Owner:GetViewModel()
		if !IsValid(vm) then return end
		
		if (!self.VElements) then return end
		
		self:UpdateBonePositions(vm)

		if (!self.vRenderOrder) then
			
			// we build a render order because sprites need to be drawn after models
			self.vRenderOrder = {}

			for k, v in pairs( self.VElements ) do
				if (v.type == "Model") then
					table.insert(self.vRenderOrder, 1, k)
				elseif (v.type == "Sprite" or v.type == "Quad") then
					table.insert(self.vRenderOrder, k)
				end
			end
			
		end

		for k, name in ipairs( self.vRenderOrder ) do
		
			local v = self.VElements[name]
			if (!v) then self.vRenderOrder = nil break end
			if (v.hide) then continue end
			
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			
			if (!v.bone) then continue end
			
			local pos, ang = self:GetBoneOrientation( self.VElements, v, vm )
			
			if (!pos) then continue end
			
			if (v.type == "Model" and IsValid(model)) then

				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				//model:SetModelScale(v.size)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix( "RenderMultiply", matrix )
				
				if (v.material == "") then
					model:SetMaterial("")
				elseif (model:GetMaterial() != v.material) then
					model:SetMaterial( v.material )
				end
				
				if (v.skin and v.skin != model:GetSkin()) then
					model:SetSkin(v.skin)
				end
				
				if (v.bodygroup) then
					for k, v in pairs( v.bodygroup ) do
						if (model:GetBodygroup(k) != v) then
							model:SetBodygroup(k, v)
						end
					end
				end
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(true)
				end
				
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(false)
				end
				
			elseif (v.type == "Sprite" and sprite) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
				
			elseif (v.type == "Quad" and v.draw_func) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func( self )
				cam.End3D2D()

			end
			
		end
		
	end

	SWEP.wRenderOrder = nil
	function SWEP:DrawWorldModel()
		
		if (self.ShowWorldModel == nil or self.ShowWorldModel) then
			self:DrawModel()
		end
		
		if (!self.WElements) then return end
		
		if (!self.wRenderOrder) then

			self.wRenderOrder = {}

			for k, v in pairs( self.WElements ) do
				if (v.type == "Model") then
					table.insert(self.wRenderOrder, 1, k)
				elseif (v.type == "Sprite" or v.type == "Quad") then
					table.insert(self.wRenderOrder, k)
				end
			end

		end
		
		if (IsValid(self.Owner)) then
			bone_ent = self.Owner
		else
			// when the weapon is dropped
			bone_ent = self
		end
		
		for k, name in pairs( self.wRenderOrder ) do
		
			local v = self.WElements[name]
			if (!v) then self.wRenderOrder = nil break end
			if (v.hide) then continue end
			
			local pos, ang
			
			if (v.bone) then
				pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent )
			else
				pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand" )
			end
			
			if (!pos) then continue end
			
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			
			if (v.type == "Model" and IsValid(model)) then

				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				//model:SetModelScale(v.size)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix( "RenderMultiply", matrix )
				
				if (v.material == "") then
					model:SetMaterial("")
				elseif (model:GetMaterial() != v.material) then
					model:SetMaterial( v.material )
				end
				
				if (v.skin and v.skin != model:GetSkin()) then
					model:SetSkin(v.skin)
				end
				
				if (v.bodygroup) then
					for k, v in pairs( v.bodygroup ) do
						if (model:GetBodygroup(k) != v) then
							model:SetBodygroup(k, v)
						end
					end
				end
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(true)
				end
				
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(false)
				end
				
			elseif (v.type == "Sprite" and sprite) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
				
			elseif (v.type == "Quad" and v.draw_func) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func( self )
				cam.End3D2D()

			end
			
		end
		
	end

	function SWEP:GetBoneOrientation( basetab, tab, ent, bone_override )
		
		local bone, pos, ang
		if (tab.rel and tab.rel != "") then
			
			local v = basetab[tab.rel]
			
			if (!v) then return end
			
			// Technically, if there exists an element with the same name as a bone
			// you can get in an infinite loop. Let's just hope nobody's that stupid.
			pos, ang = self:GetBoneOrientation( basetab, v, ent )
			
			if (!pos) then return end
			
			pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
		else
		
			bone = ent:LookupBone(bone_override or tab.bone)

			if (!bone) then return end
			
			pos, ang = Vector(0,0,0), Angle(0,0,0)
			local m = ent:GetBoneMatrix(bone)
			if (m) then
				pos, ang = m:GetTranslation(), m:GetAngles()
			end
			
			if (IsValid(self.Owner) and self.Owner:IsPlayer() and 
				ent == self.Owner:GetViewModel() and self.ViewModelFlip) then
				ang.r = -ang.r // Fixes mirrored models
			end
		
		end
		
		return pos, ang
	end

	function SWEP:CreateModels( tab )

		if (!tab) then return end

		// Create the clientside models here because Garry says we can't do it in the render hook
		for k, v in pairs( tab ) do
			if (v.type == "Model" and v.model and v.model != "" and (!IsValid(v.modelEnt) or v.createdModel != v.model) and 
					string.find(v.model, ".mdl") and file.Exists (v.model, "GAME") ) then
				
				v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)
				if (IsValid(v.modelEnt)) then
					v.modelEnt:SetPos(self:GetPos())
					v.modelEnt:SetAngles(self:GetAngles())
					v.modelEnt:SetParent(self)
					v.modelEnt:SetNoDraw(true)
					v.createdModel = v.model
				else
					v.modelEnt = nil
				end
				
			elseif (v.type == "Sprite" and v.sprite and v.sprite != "" and (!v.spriteMaterial or v.createdSprite != v.sprite) 
				and file.Exists ("materials/"..v.sprite..".vmt", "GAME")) then
				
				local name = v.sprite.."-"
				local params = { ["$basetexture"] = v.sprite }
				// make sure we create a unique name based on the selected options
				local tocheck = { "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }
				for i, j in pairs( tocheck ) do
					if (v[j]) then
						params["$"..j] = 1
						name = name.."1"
					else
						name = name.."0"
					end
				end

				v.createdSprite = v.sprite
				v.spriteMaterial = CreateMaterial(name,"UnlitGeneric",params)
				
			end
		end
		
	end
	
	local allbones
	local hasGarryFixedBoneScalingYet = false

	function SWEP:UpdateBonePositions(vm)
		
		if self.ViewModelBoneMods then
			
			if (!vm:GetBoneCount()) then return end
			
			// !! WORKAROUND !! //
			// We need to check all model names :/
			local loopthrough = self.ViewModelBoneMods
			if (!hasGarryFixedBoneScalingYet) then
				allbones = {}
				for i=0, vm:GetBoneCount() do
					local bonename = vm:GetBoneName(i)
					if (self.ViewModelBoneMods[bonename]) then 
						allbones[bonename] = self.ViewModelBoneMods[bonename]
					else
						allbones[bonename] = { 
							scale = Vector(1,1,1),
							pos = Vector(0,0,0),
							angle = Angle(0,0,0)
						}
					end
				end
				
				loopthrough = allbones
			end
			// !! ----------- !! //
			
			for k, v in pairs( loopthrough ) do
				local bone = vm:LookupBone(k)
				if (!bone) then continue end
				
				// !! WORKAROUND !! //
				local s = Vector(v.scale.x,v.scale.y,v.scale.z)
				local p = Vector(v.pos.x,v.pos.y,v.pos.z)
				local ms = Vector(1,1,1)
				if (!hasGarryFixedBoneScalingYet) then
					local cur = vm:GetBoneParent(bone)
					while(cur >= 0) do
						local pscale = loopthrough[vm:GetBoneName(cur)].scale
						ms = ms * pscale
						cur = vm:GetBoneParent(cur)
					end
				end
				
				s = s * ms
				// !! ----------- !! //
				
				if vm:GetManipulateBoneScale(bone) != s then
					vm:ManipulateBoneScale( bone, s )
				end
				if vm:GetManipulateBoneAngles(bone) != v.angle then
					vm:ManipulateBoneAngles( bone, v.angle )
				end
				if vm:GetManipulateBonePosition(bone) != p then
					vm:ManipulateBonePosition( bone, p )
				end
			end
		else
			self:ResetBonePositions(vm)
		end
		   
	end
	 
	function SWEP:ResetBonePositions(vm)
		
		if (!vm:GetBoneCount()) then return end
		for i=0, vm:GetBoneCount() do
			vm:ManipulateBoneScale( i, Vector(1, 1, 1) )
			vm:ManipulateBoneAngles( i, Angle(0, 0, 0) )
			vm:ManipulateBonePosition( i, Vector(0, 0, 0) )
		end
		
	end

	/**************************
		Global utility code
	**************************/

	// Fully copies the table, meaning all tables inside this table are copied too and so on (normal table.Copy copies only their reference).
	// Does not copy entities of course, only copies their reference.
	// WARNING: do not use on tables that contain themselves somewhere down the line or you'll get an infinite loop
	function table.FullCopy( tab )

		if (!tab) then return nil end
		
		local res = {}
		for k, v in pairs( tab ) do
			if (type(v) == "table") then
				res[k] = table.FullCopy(v) // recursion ho!
			elseif (type(v) == "Vector") then
				res[k] = Vector(v.x, v.y, v.z)
			elseif (type(v) == "Angle") then
				res[k] = Angle(v.p, v.y, v.r)
			else
				res[k] = v
			end
		end
		
		return res
		
	end
	
end


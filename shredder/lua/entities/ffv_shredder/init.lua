AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.sounds = {}
ENT.parts = {}
ENT.dumpster = nil
ENT.cs = nil

function ENT:Initialize()
	self:SetModel("models/props_lab/blastdoor001c.mdl")
	self:SetAngles(Angle(90,0,0))
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:GetPhysicsObject():Wake()

	self.cs = ents.Create("phys_constraintsystem")

	--the big dumpster stuff is thrown into
	self.dumpster = self:add_part("models/props_junk/TrashDumpster02.mdl", Vector(54,16,85), Angle(20,90,0), 200)
	self:loop_sound("vehicles/airboat/fan_motor_idle_loop1.wav")
	--the fireplace for the pipe
	self:add_part("models/props_c17/FurnitureFireplace001a.mdl", Vector(90,-60,50), Angle(180,270,0), 0)
	--the bit at the end of the pipe so you dont see the backface culled face
	self:add_part("models/props_trainstation/trainstation_ornament002.mdl", Vector(97.15,-73,12.7), Angle(0,0,90), 0):SetModelScale(.5)
	--the oven
	self:add_part("models/props_c17/furnitureStove001a.mdl", Vector(30,40,24), Angle(0,90,0), 0)
	--fence
	self:add_part("models/props_c17/fence01a.mdl", Vector(60,0,52), Angle(0,0,0), 0)
	--the lockers
	self:add_part("models/props_c17/Lockers001a.mdl", Vector(70,40,40), Angle(0,0,0), 0)
	self:add_part("models/props_c17/Lockers001a.mdl", Vector(70,-10,40), Angle(0,0,0), 0)
	--the canister that looks like support
	self:add_part("models/props_c17/canister01a.mdl", Vector(10,-40,33), Angle(0,90,0), 0)

	--spinny gears. they were barrels at first thats why the variable name says barrels
	local barrel1 = ents.Create("prop_physics")
	barrel1:SetModel("models/Mechanics/gears2/gear_12t1.mdl")
	barrel1:SetParent(self.dumpster)
	barrel1:SetPos(self.dumpster:GetPos() + Vector(26,80,0))
	barrel1:SetAngles(Angle(0,0,70))
	table.insert(self.parts, barrel1)
	self:SetNWEntity("barrel1", barrel1)
	for i=1,7 do
		local gear = ents.Create("prop_physics")
		gear:SetModel("models/Mechanics/gears2/gear_12t1.mdl")
		gear:SetParent(barrel1)
		gear:SetPos(barrel1:GetPos())
		gear:SetAngles(barrel1:GetAngles())
		gear:SetLocalPos(Vector(0,0,21.5*i))
		if not ((i % 2) == 0) then
			gear:SetLocalAngles(Angle(0,15,0))
		end
		table.insert(self.parts, gear)
	end
	local barrel2 = ents.Create("prop_physics")
	barrel2:SetModel("models/Mechanics/gears2/gear_12t1.mdl")
	barrel2:SetParent(self.dumpster)
	barrel2:SetPos(self.dumpster:GetPos() + Vector(-26,80,0))
	barrel2:SetAngles(Angle(0,0,70))
	table.insert(self.parts, barrel2)
	self:SetNWEntity("barrel2", barrel2)
	for i=1,7 do
		local gear = ents.Create("prop_physics")
		gear:SetModel("models/Mechanics/gears2/gear_12t1.mdl")
		gear:SetParent(barrel2)
		gear:SetPos(barrel2:GetPos())
		gear:SetAngles(barrel2:GetAngles())
		gear:SetLocalPos(Vector(0,0,21.5*i))
		if not ((i % 2) == 0) then
			gear:SetLocalAngles(Angle(0,15,0))
		end
		table.insert(self.parts, gear)
	end
	timer.Create("barrelspin"..tostring(CurTime()), .01, 0, function()
		if not (IsValid(barrel1) and IsValid(barrel2)) then timer.Remove("barrelspin") return end
		barrel1:SetLocalAngles(barrel1:GetLocalAngles() - Angle(.5,0,0))
		barrel2:SetLocalAngles(barrel2:GetLocalAngles() + Angle(.5,0,0))
	end)

	--the bit that detects stuff being thrown into the grinder
	local part = ents.Create("ffv_shreddercollision")
	part:SetModel("models/props_lab/blastdoor001c.mdl")
	part:SetPos(self:GetPos() + Vector(0,30,120))
	part:SetAngles(Angle(110,90,90))
	part:PhysicsInit(SOLID_VPHYSICS)
	part:SetMoveType(MOVETYPE_VPHYSICS)
	part:SetSolid(SOLID_VPHYSICS)
	part:GetPhysicsObject():Wake()
	part:GetPhysicsObject():SetMass(0)
	part:SetNoDraw(true)
	table.insert(self.parts, part)
	SetPhysConstraintSystem(self.cs)
	constraint.Weld(part,self,0,0,0,true,true)
	constraint.NoCollide(part,self.dumpster,0,0)
	part:SetNWEntity("shredder", self)
end

function ENT:loop_sound(sound)
	table.insert(self.sounds, self:StartLoopingSound(sound))
end

function ENT:add_part(model, pos, angle, mass)
	if self.cs == nil then
		self.cs = ents.Create("phys_constraintsystem")
	end

	local part = ents.Create("ffv_shredderpart")
	part:SetModel(model)
	part:SetPos(self:GetPos() + pos)
	part:SetAngles(angle)
	part:PhysicsInit(SOLID_VPHYSICS)
	part:SetMoveType(MOVETYPE_VPHYSICS)
	part:SetSolid(SOLID_VPHYSICS)
	part:GetPhysicsObject():Wake()
	part:GetPhysicsObject():SetMass(mass)
	SetPhysConstraintSystem(self.cs)
	constraint.Weld(part,self,0,0,0,true,true)
	for k, v in pairs(self.parts) do
		SetPhysConstraintSystem(self.cs)
		constraint.NoCollide(part,v,0,0)
	end
	table.insert(self.parts, part)

	return part
end

function move_to_value(value, goal, dist)
	return math.Clamp(goal, value-dist, value+dist)
end

function ENT:shred(ent)
	for k, v in pairs(self.parts) do
		if (ent == v) then return end
	end
	if (not ent:IsNPC()) and (not ent:IsNextBot()) then ent:TakeDamage(ent:Health()) end
	if ent:IsPlayer() then return end

	local min, max = ent:GetModelBounds()
	--whoof what a line
	local sizeVec = Vector(max.x + math.abs(min.x), max.y + math.abs(min.y), max.z + math.abs(min.z))
	sizeVec:Rotate(ent:GetAngles() - self.dumpster:GetAngles())
	local size = math.ceil(math.abs(sizeVec.z))

	ent:SetParent(self.dumpster)
	ent:SetSolid(SOLID_NONE)
	local sound = self:StartLoopingSound("physics/metal/canister_scrape_rough_loop1.wav")
	local i = 0
	timer.Create("shred"..tostring(CurTime()..tostring(#self.dumpster:GetChildren())), 0.01, 0, function()
		if not IsValid(ent) then self:StopLoopingSound(sound) return end
		ent:SetLocalPos(ent:GetLocalPos() - Vector(0,0,1))
		--prop funneling so huge things go in the dumpster
		if (not ent:IsNPC()) and (not ent:IsNextBot()) then
			local localAngles = ent:GetLocalAngles()
			ent:SetLocalAngles(Angle(
				move_to_value(localAngles.x,math.Round((localAngles.x/90))*90,.06),
				localAngles.y,
				move_to_value(localAngles.z,math.Round((localAngles.z/90))*90,.06)))
		end

		--sparks every 8th tick
		if (i % 8) == 0 then
			local sparkVec = Vector(-90,20,50)
			sparkVec:Rotate(self:GetAngles())

			local effectdata = EffectData()
			effectdata:SetOrigin(self:GetPos() + sparkVec)
			util.Effect("ManhackSparks", effectdata)
		end

		i = i + 1
		if i > size*1.1 then
			--find and delete ragdoll if it exists
			local ragdolls = #ents.FindByClass("prop_ragdoll")
			if ent:IsNPC() then ent:TakeDamage(ent:Health()) end
			if ragdolls < #ents.FindByClass("prop_ragdoll") then ents.FindByClass("prop_ragdoll")[ragdolls+1]:Remove() end

			ent:Remove()
			self:StopLoopingSound(sound)
		end
	end)
end

function ENT:OnRemove()
	for k, v in pairs(self.sounds) do
		self:StopLoopingSound(v)
	end
	for k, v in pairs(self.parts) do
		if IsValid(v) then v:Remove() end
	end
end

function ENT:Think()
	for k, v in pairs(self.parts) do
		if not IsValid(v) then self:Remove() end
	end
end

function ENT:OnEntityCopyTableFinish(data)
	data["parts"] = nil
	data["sounds"] = nil
	data["dumpster"] = nil
	data["cs"] = nil
end
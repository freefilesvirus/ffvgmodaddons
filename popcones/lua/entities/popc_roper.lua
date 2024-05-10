AddCSLuaFile()

DEFINE_BASECLASS("popc_base")

ENT.Base = "popc_base"
ENT.Spawnable = true
ENT.Category = "Pop Cones"
ENT.PrintName = "Roper"

ENT.ropes = {}

function ENT:setupParts()
	self:addPart("models/props_c17/utilitypole03a.mdl",Vector(0,0,-15),Angle(0,0,0),.1,false)
	self:addPart("models/props_vehicles/apc_tire001.mdl",Vector(0,0,-9),Angle(-90,0,0),.06)

	if (WireLib~=nil) then
		WireLib.CreateOutputs(self,{"Popped"})
		WireLib.CreateInputs(self,{"Popped"})
	end
end

local ropeSound = Sound("npc/turret_floor/click1.wav")
function ENT:extraPop(popping)
	if popping then
		local madeRope = false
		for k,v in pairs(ents.FindInSphere(self:GetPos(),128)) do
			if (not (v:IsPlayer() or v:IsNPC() or v:IsNextBot() or (v==self) or (not IsValid(v:GetPhysicsObject())))) then
				--make rope
				local offset = Vector(0,(math.random(2)==1) and 7.5 or -7.5,(math.random(2)==1) and 23 or 27.5)
				local r1,r2 = constraint.Rope(self,v,0,0,offset,Vector(0,0,0),128,0,0,2,"cable/rope")
				table.insert(self.ropes,{r1,r2})

				madeRope = true
			end
		end
		if madeRope then self:EmitSound(ropeSound) end
	else
		if (#self.ropes>0) then self:EmitSound(ropeSound) end
		for k,v in pairs(self.ropes) do
			if IsValid(v[1]) then
				v[1]:Remove()
				v[2]:Remove()
			end
		end
	end
end

function ENT:OnEntityCopyTableFinish(data)
	BaseClass.OnEntityCopyTableFinish(self,data)

	data.ropes = {}
end

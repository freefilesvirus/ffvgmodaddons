AddCSLuaFile()
ENT.Base = "base_gmodentity"
ENT.Type = "anim"

ENT.Spawnable = true
ENT.PrintName = "Magic Dumpster"
--ENT.Category = "Other"
ENT.Category = "ffvjunk"
ENT.Instructions = "Flip upside down and shake"

ENT.spawnWait = false
ENT.spawnedJunk = {}

junkprops = {
	"models/props_c17/doll01.mdl",
	"models/props_junk/Shoe001a.mdl",
	"models/props_junk/garbage_glassbottle002a.mdl",
	"models/props_junk/PopCan01a.mdl",
	"models/props_junk/garbage_takeoutcarton001a.mdl",
	"models/props_lab/jar01a.mdl",
	"models/props_junk/garbage_milkcarton001a.mdl",
	"models/props_junk/garbage_milkcarton002a.mdl",
	"models/props_junk/garbage_plasticbottle001a.mdl",
	"models/props_c17/TrapPropeller_Engine.mdl",
	"models/props_junk/watermelon01.mdl",
	"models/props_junk/glassjug01.mdl",
	"models/props_lab/frame002a.mdl",
	"models/props_junk/plasticbucket001a.mdl",
	"models/props_c17/tools_wrench01a.mdl",
	"models/props_junk/Shovel01a.mdl",
	"models/props_junk/garbage_coffeemug001a.mdl",
	"models/props_junk/garbage_newspaper001a.mdl",
	"models/props_canal/mattpipe.mdl",
	"models/props_c17/metalPot002a.mdl",
	"models/props_c17/metalPot001a.mdl",
	"models/Gibs/HGIBS.mdl",
	"models/Gibs/HGIBS_rib.mdl",
	"models/Gibs/HGIBS_scapula.mdl",
	"models/Gibs/HGIBS_spine.mdl",
	"models/props_junk/gascan001a.mdl",
	"models/props_lab/tpplug.mdl",
	"models/props_lab/tpplugholder_single.mdl",
	"models/props_lab/cactus.mdl",
	"models/props_trainstation/payphone_reciever001a.mdl",
	"models/props_lab/kennel_physics.mdl",
	"models/props_c17/lampShade001a.mdl",
	"models/props_combine/breenglobe.mdl",
	"models/Combine_Helicopter/helicopter_bomb01.mdl",
	"models/props_vehicles/tire001b_truck.mdl",
	"models/props_vehicles/tire001c_car.mdl",
	"models/props_vehicles/apc_tire001.mdl",
	"models/props_vehicles/tire001a_tractor.mdl",
	"models/props_wasteland/wheel01.mdl",
	"models/props_junk/cardboard_box001b.mdl",
	"models/props_junk/cardboard_box002b.mdl",
	"models/props_junk/cardboard_box003b.mdl",
	"models/props_junk/CinderBlock01a.mdl",
	"models/props_junk/meathook001a.mdl",
	"models/props_interiors/pot01a.mdl",
	"models/props_c17/chair02a.mdl",
	"models/maxofs2d/companion_doll.mdl",
	"models/props_trainstation/TrackSign02.mdl",
	"models/props_junk/PropaneCanister001a.mdl"
}

function ENT:Initialize()
	if CLIENT then return end
	self:SetModel("models/props_junk/TrashDumpster02.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:GetPhysicsObject():Wake()
	self:GetPhysicsObject():SetMass(1200)
end

function ENT:Think()
	if CLIENT then return end
	local angles = self:GetAngles()
	angles:Normalize()
	if (math.abs(angles.z) > 150) and (math.abs(angles.x) < 30) then
		--pointing down
		if self:GetVelocity().z < -400 then
			--being shaken
			if not self.spawnWait then
				for i=1,math.random(1,3) do
					local junk = ents.Create("prop_physics")
					junk:SetModel(junkprops[math.random(1,#junkprops)])
					junk:SetPos(self:GetPos() - Vector(math.random(-32,32),math.random(-64,64),64))
					junk:PhysicsInit(SOLID_VPHYSICS)
					junk:SetMoveType(MOVETYPE_VPHYSICS)
					junk:SetSolid(SOLID_VPHYSICS)
					junk:GetPhysicsObject():Wake()
					junk:GetPhysicsObject():SetVelocity(self:GetVelocity()/2)

					table.insert(self.spawnedJunk, junk)
				end

				self.spawnWait = true
				timer.Simple(.01, function()
					self.spawnWait = false
				end)
			end
		end
	end
end

function ENT:OnRemove()
	self:clear_junk()
end

function ENT:clear_junk()
	for k, v in pairs(self.spawnedJunk) do
		if IsValid(v) then v:Remove() end
	end
	self.spawnedJunk = {}
end

local prop = {}
prop.MenuLabel = "Clean Junk"
prop.Order = 9001
prop.Filter = function(self, ent)
	if not isentity(ent) then return false end
	if (ent:GetClass() == "ffv_junkdumpster") then return true end
	return false
end
prop.Action = function(self, ent)
	self:MsgStart()
		net.WriteEntity(ent)
	self:MsgEnd()
end
prop.Receive = function(self, length, ply)
	net.ReadEntity():clear_junk()
end
properties.Add("cleandumpsterjunk", prop)
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Phone"
ENT.Spawnable = true
ENT.Category = "ffvjunk"

ENT.sound = nil
ENT.soundTick = 0
ENT.fakePhone = nil
ENT.removing = false

function ENT:Initialize()
	if CLIENT then return end

	self:SetModel("models/props_trainstation/payphone001a.mdl")
	self:PhysicsInitStatic(SOLID_VPHYSICS)

	self.fakePhone = ents.Create("prop_dynamic")
	self.fakePhone:SetModel("models/props_trainstation/payphone_reciever001a.mdl")
	self.fakePhone:Spawn()
	self.fakePhone:SetParent(self)
	self.fakePhone:SetLocalPos(Vector(0,0,0))
	self.fakePhone:SetLocalAngles(Angle(0,0,0))

	self.sound = CreateSound(self,"ambient/alarms/train_crossing_bell_loop1.wav")
	self.sound:PlayEx(1,200)
	self.soundTick = CurTime()
end

function ENT:OnRemove()
	if CLIENT then return end

	if (not self.removing) then self:EmitSound("ambient/creatures/town_child_scream1.wav") end
	if (not (self.sound==nil)) then self.sound:Stop() end
end

function ENT:Use()
	if CLIENT then return end
	if (not IsValid(self.fakePhone)) then return end

	self.sound:Stop()
	self.sound = nil
	local phone = ents.Create("ffv_phoneboom")
	phone:SetPos(self.fakePhone:GetPos())
	phone:SetAngles(self.fakePhone:GetAngles())
	phone:Spawn()
	phone:GetPhysicsObject():Wake()
	self.fakePhone:Remove()
	phone.spawner = self
end

function ENT:Think()
	if CLIENT then return end
	if (self.sound==nil) then return end

	if ((CurTime()-self.soundTick)>2) then
		if self.sound:IsPlaying() then
			self.sound:Stop()
			self.soundTick = CurTime()-.4
		else
			self.sound:PlayEx(1,200)
			self.soundTick = CurTime()
		end
	end

	self:NextThink(CurTime())
	return true
end

--this is so evil
if CLIENT then return end
hook.Add("PhysgunPickup","noPhysPhone",function(ply,ent)
	if (ent:GetClass()=="ffv_phonestand") then return false end
end)
hook.Add("CanUndo","noUndoPhone",function(ply,undo)
	if (undo.Entities[1]:GetClass()=="ffv_phonestand") then return false end
end)
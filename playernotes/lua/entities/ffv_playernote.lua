AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.message = "something went wrong"
ENT.steamid = 0
ENT.name = "unknown user"
ENT.date = os.time()

function ENT:Initialize()
	if CLIENT then return end
	self:SetModel("models/extras/info_speech.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_CUSTOM)
	self:SetSolid(SOLID_VPHYSICS)

	self:GetPhysicsObject():Wake()
	self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
	self:SetTrigger(true)

	self:SetUseType(SIMPLE_USE)

	self:SetNWString("message",self.message)
	--self:SetNWColor("vanity",self.steamid=="76561198169249882")

	self:GetPhysicsObject():EnableCollisions(false)
	self:SetCustomCollisionCheck(true)

	self:SetNWInt("r",255)
	self:SetNWInt("g",255)
	self:SetNWInt("b",255)
	for k,v in pairs(pnColorTable) do
		if (v[2]==self.steamid) then
			self:SetNWInt("r",v[1].r)
			self:SetNWInt("g",v[1].g)
			self:SetNWInt("b",v[1].b)
			return
		end
	end
end

function ENT:Use(ply)
	if (not ply:IsPlayer()) then return end
	net.Start("ffvreadplayernote")
		net.WriteString(self.message)
		net.WriteString(self.steamid)
		net.WriteString(self.name)
		net.WriteString(self.date)
	net.Send(ply)
end

hook.Add("PostDrawOpaqueRenderables","ffvplayernotetext",function()
	for k,v in ipairs(ents.FindByClass("ffv_playernote")) do
		if (v:GetPos():DistToSqr(EyePos())<12000) then
			cam.Start3D2D(v:GetPos()+Vector(0,0,16),Angle(0,EyeAngles().y-90,90),0.2)
				surface.SetFont("Default")
				local w,h = surface.GetTextSize(v:GetNWString("message"))
				draw.RoundedBox(8,-w/2,-h/2,w,h,Color(0,0,0,128))
				--local color = Color(255,255,255,255)
				--if v:GetNWBool("vanity") then color = Color(255,234,124,255) end
				draw.SimpleText(v:GetNWString("message"),"Default",0,0,Color(v:GetNWInt("r"),v:GetNWInt("g"),v:GetNWInt("b"),255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			cam.End3D2D()
		end
	end
end)

--partial fix to the stopping train and elevator. doesnt always work
hook.Add("ShouldCollide","ffvplayernotecollision",function(ent1,ent2)
	if CLIENT then return end

	if ((ent1:GetClass()=="ffv_playernote") or (ent2:GetClass()=="ffv_playernote")) then
		if string.StartsWith(ent1:GetClass(),"func") then ent2:Remove() end
		if string.StartsWith(ent2:GetClass(),"func") then ent1:Remove() end
	end
end)

if SERVER then duplicator.RegisterEntityClass("ffv_playernote",function(ply,data) return end,nil) end


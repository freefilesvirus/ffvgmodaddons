AddCSLuaFile()
ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.Spawnable = false

ENT.model=""
ENT.size=2

function ENT:Draw()
	if self.model~=self:GetModel() then return end

	local mat = Matrix()
	mat:Scale(Vector(self.size,self.size,self.size))
	self:EnableMatrix("RenderMultiply",mat)
	render.MaterialOverride(Material("models/props_combine/stasisshield_sheet"))
	self:DrawModel()
	render.MaterialOverride()

	mat:Scale(Vector(1.01,1.01,1.01))
	self:EnableMatrix("RenderMultiply",mat)
	render.MaterialOverride(Material("models/props_combine/portalball001_sheet"))
	self:DrawModel()
	render.MaterialOverride()

	local dlight = DynamicLight(self:EntIndex())
	if dlight then
		dlight.pos = self:WorldSpaceCenter()
		dlight.r = 100
		dlight.g = 255
		dlight.b = 255
		dlight.brightness = 2
		dlight.decay = 1000
		dlight.size = 80
		dlight.dietime = CurTime() + 1
	end
end

function ENT:Initialize()
	self:DrawShadow(false)
	self:SetRenderMode(RENDERMODE_TRANSCOLOR)

	if SERVER then self:SetModel(self:GetModel()) end
end

function ENT:setModel(model)
	self:SetModel(model)

	net.Start("pbot_holo")
	net.WriteEntity(self)
	net.WriteString(model)
	net.WriteFloat(8/self:GetModelBounds():Length())
	net.Broadcast()
end

if SERVER then util.AddNetworkString("pbot_holo")
else
	net.Receive("pbot_holo",function()
		local bot=net.ReadEntity()
		bot.model=net.ReadString()
		bot.size=net.ReadFloat()
	end)
end
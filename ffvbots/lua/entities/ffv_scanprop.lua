AddCSLuaFile()
ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.Spawnable = false

function ENT:Draw()
	local mat = Matrix()
	local size = 8/self:GetNWFloat("size")
	mat:Scale(Vector(size,size,size))
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
	if CLIENT then return end
	self:SetModel("models/props_c17/doll01.mdl")
	self:SetRenderMode(RENDERMODE_TRANSCOLOR)

	self:SetNWFloat("size",self:GetModelBounds():Length())
end
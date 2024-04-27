AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.Spawnable = false

function ENT:Initialize()
	if CLIENT then return end
	self:SetModel("models/props_trainstation/trainstation_post001.mdl")
	--there should only be one of these
	if (#ents.FindByClass("ffv_hoardmarker")>1) then ents.FindByClass("ffv_hoardmarker")[1]:Remove() end
end
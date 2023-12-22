AddCSLuaFile("skelify.lua")
include("skelify.lua")

TOOL.Category = "Punishment"
TOOL.Name = "Skelifier"
TOOL.Command = nil
TOOL.ConfigName = "skelifier"
TOOL.Information = {"left"}

TOOL.ClientConVar["ragdoll"] = "models/player/skeleton.mdl"

if CLIENT then
	language.Add("tool.skelifier.name", "Skelifier")
	language.Add("tool.skelifier.desc", "Skelificates NPCs")
	language.Add("tool.skelifier.left", "Skelify")
end

function TOOL.BuildCPanel(cpanel)
	cpanel:AddControl("Header", {Description = "#tool.skelifier.desc"})
	cpanel:AddControl("textbox", {label = "Ragdoll Override", command = "skelifier_ragdoll"})
end

function TOOL:LeftClick(tr)
	local ent = tr.Entity
	local ply = self:GetOwner()
	if not qualify_skelify(ent, false) then return false end
	if CLIENT then return true end

	skelify(ent, ply)
	return true
end
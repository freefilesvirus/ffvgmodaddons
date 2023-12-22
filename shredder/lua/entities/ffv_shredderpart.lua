AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

function ENT:OnEntityCopyTableFinish(data)
	for k, v in pairs(data) do
		data[k] = nil
	end
end
include("shared.lua")

SWEP.PrintName = "Live Grenade"
SWEP.Slot = 4
SWEP.SlotPos = 0
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

local grenadeProp = nil
local drewVm = true

net.Receive("grenadeProp", function()
	grenadeProp = net.ReadEntity()
end)

function SWEP:DrawWorldModel(flags)
	if IsValid(grenadeProp) then
		grenadeProp:SetNoDraw(false)
		return false
	else
		self:DrawModel(flags)
	end
end

function SWEP:ViewModelDrawn() grenadeProp:SetNoDraw(true) end
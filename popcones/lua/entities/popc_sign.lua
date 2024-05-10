AddCSLuaFile()

DEFINE_BASECLASS("popc_base")

ENT.Base = "popc_base"
ENT.Spawnable = true
ENT.Category = "Pop Cones"
ENT.PrintName = "Sign"

ENT.Editable = true

function ENT:setupParts()
	self:addPart("models/props_wasteland/prison_lamp001c.mdl",Vector(0,0,-6),Angle(0,0,180)):SetSkin(1)
	self:addPart("models/props_lab/reciever01b.mdl",Vector(0,0,-9))
end

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("String",0,"Text",{KeyName="Text",Edit={type="String",order=3}})

	if CLIENT then return end

	if (math.random(200)==1) then self:SetText("set my message in the context menu, idiot")
	else self:SetText("set my message in the context menu") end
end

function ENT:Think()
	BaseClass.Think(self)
	
	if CLIENT then return end

	self.parts[1][1]:SetSkin(self:GetPopped() and 0 or 1)
end

hook.Add("PostDrawOpaqueRenderables","popc_sign_text",function()
	for k,v in ipairs(ents.FindByClass("popc_sign")) do
		if v:GetPopped() then 
			local pos = Vector(0,0,40)
			pos:Rotate(v:GetAngles())
			pos = pos+v:GetPos()
			local ang = v:GetAngles()
			ang:RotateAroundAxis(v:GetUp(),90)
			ang:RotateAroundAxis(v:GetRight(),-90)

			cam.Start3D2D(pos,ang,.8)
				local text = v:GetText()
				surface.SetFont("DefaultFixedDropShadow")

				draw.SimpleText(text,"DefaultFixedDropShadow",-select(1,surface.GetTextSize(text))/2,0,color_white)
			cam.End3D2D()
		end
	end
end)
include("shared.lua")

function ENT:Draw()
	self:DrawModel()
	
	local barrel1 = self:GetNWEntity("barrel1")
	local barrel2 = self:GetNWEntity("barrel2")
	if IsValid(barrel1) and IsValid(barrel2) then
		local mat = Matrix()
		mat:Scale(Vector(2,2,3.6))
		barrel1:EnableMatrix("RenderMultiply", mat)
		for k, v in pairs(barrel1:GetChildren()) do
			v:EnableMatrix("RenderMultiply", mat)
		end
		barrel2:EnableMatrix("RenderMultiply", mat)
		for k, v in pairs(barrel2:GetChildren()) do
			v:EnableMatrix("RenderMultiply", mat)
		end
	end
end
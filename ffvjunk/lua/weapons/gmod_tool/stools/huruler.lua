TOOL.Category = "ffvjunk"
TOOL.Name = "HU Ruler"

TOOL.ClientConVar["limitx"] = 0
TOOL.ClientConVar["limity"] = 0
TOOL.ClientConVar["limitz"] = 0

if CLIENT then
	TOOL.Information = {{name = "left"}}

	language.Add("tool.huruler.name", "HU Ruler")
	language.Add("tool.huruler.desc", "Measures in hammer units")
	language.Add("tool.huruler.left", "Select the starting point")
	
	language.Add("tool.huruler.help", "Measures the distance between two points in hammer units")
end

function TOOL.BuildCPanel(cpanel)
	cpanel:AddControl("Header", {Description = "#tool.huruler.help"})

	cpanel:AddControl("CheckBox", {Label = "Lock X axis", Command = "huruler_limitx"})
	cpanel:AddControl("CheckBox", {Label = "Lock Y axis", Command = "huruler_limity"})
	cpanel:AddControl("CheckBox", {Label = "Lock Z axis", Command = "huruler_limitz"})
end

function TOOL:LeftClick(trace)
	self:GetOwner():SetNWVector("rulerpos",trace.HitPos)
	return true
end

function TOOL:Think()
	--this is really bad! if youre looking through my code to see how you should do stuff dont do this! i couldnt read the convar in the rendering hook for some reason and i dont know why so i did this. this is why it is in the junk collection addon
	local ply = self:GetOwner()
	ply:SetNWBool("hurx",self:GetClientBool("limitx"))
	ply:SetNWBool("hury",self:GetClientBool("limity"))
	ply:SetNWBool("hurz",self:GetClientBool("limitz"))
end

hook.Add("PostDrawOpaqueRenderables", "hurulertext", function()
	local ply = LocalPlayer()
	local wep = ply:GetActiveWeapon()
	if (not IsValid(wep)) then return end
	if (not (wep:GetClass() == "gmod_tool")) then return end
	if (not (wep:GetMode() == "huruler")) then return end

	local trace = ply:GetEyeTrace()
	local startpos = ply:GetNWVector("rulerpos")
	local pos = startpos
	if (not ply:GetNWBool("hurx")) then
		pos = Vector(trace.HitPos.x,pos.y,pos.z)
	end
	if (not ply:GetNWBool("hury")) then
		pos = Vector(pos.x,trace.HitPos.y,pos.z)
	end
	if (not ply:GetNWBool("hurz")) then
		pos = Vector(pos.x,pos.y,trace.HitPos.z)
	end

	render.DrawLine(startpos, pos)
	cam.Start2D()
		local length = math.floor((startpos-pos):Length()*100)/100
		local text = tostring(length) .. " hu"
		surface.SetFont("Default")
		local tw, th = surface.GetTextSize(text)
		local pad = 5

		surface.SetDrawColor(0,0,0,255)
		surface.DrawRect((ScrW()/2)-(pad/2),(ScrH()/2)-(pad/2),tw+pad,th+pad)
		draw.SimpleText(text,"Default",ScrW()/2,ScrH()/2,color_white)
	cam.End2D()
end)
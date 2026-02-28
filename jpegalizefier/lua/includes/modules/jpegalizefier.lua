AddCSLuaFile()

local IsValid=IsValid
local ents=ents
local isfunction=isfunction

module("jpegalizefier")

local totalJpegalizefied=0

function GetJPEGalizefied(ent)
	return IsValid(ent) and IsValid(ent:GetNWEntity("jpegEntity"))
end

function SetJPEGalizefied(ent,enabled)
	if enabled==GetJPEGalizefied(ent) then
		return
	end

	if enabled then
		-- make new guy
		local newEnt=ents.Create("ent_jpegalizefied")
		newEnt:SetPos(ent:GetPos())
		newEnt:SetParent(ent)
		newEnt:Spawn()
		
		ent:SetNoDraw(true)

		newEnt:SetNWEntity("jpegTarget",ent)
		newEnt:SetNWInt("jpegIndex",totalJpegalizefied)
		totalJpegalizefied=totalJpegalizefied+1

		ent:SetNWEntity("jpegEntity",newEnt)
	else
		-- kill old guy
		ent:GetNWEntity("jpegEntity"):Remove()
		ent:SetNWEntity("jpegEntity",null)
		ent:SetNoDraw(false)
	
		return
	end
end
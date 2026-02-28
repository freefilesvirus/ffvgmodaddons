AddCSLuaFile()

ENT.Type="anim"
ENT.Base="base_gmodentity"

if SERVER then
	return
end

local scale=100

local jpegWidthConvar=CreateClientConVar("jpeg_width","384",true,false,"how many pixels horizontally the image has",100)
local jpegCaptureDurationConvar=CreateClientConVar("jpeg_capture","0.1",true,false,"how often in seconds the jpeg refreshes",0.01)

local saveFolder="jpegalizefier"
local saveFile="jpegalizefied"

ENT.jpegWaitingForMaterial=true

ENT.jpegMaterial=null
ENT.maskMaterial=null

-- nwent jpegTarget
-- nwint jpegIndex

local function GetScreenRenderBounds(target)
	local mins,maxs=target:GetRenderBounds()
	local screenLeft=ScrW()
	local screenTop=ScrH()
	local screenRight=0
	local screenBottom=0
	local corners={
		Vector(mins.x,mins.y,mins.z),
		Vector(mins.x,mins.y,maxs.z),
		Vector(mins.x,maxs.y,mins.z),
		Vector(mins.x,maxs.y,maxs.z),
		Vector(maxs.x,mins.y,mins.z),
		Vector(maxs.x,mins.y,maxs.z),
		Vector(maxs.x,maxs.y,mins.z),
		Vector(maxs.x,maxs.y,maxs.z),
	}
	cam.Start3D() -- wow after an hour of NO PROGRESS this is the fix???
	for _,corner in pairs(corners) do
		local screenCorner=target:LocalToWorld(corner):ToScreen()
		
		screenLeft=math.min(screenLeft,screenCorner.x)
		screenTop=math.min(screenTop,screenCorner.y)
		screenRight=math.max(screenRight,screenCorner.x)
		screenBottom=math.max(screenBottom,screenCorner.y)
	end
	cam.End3D()
	screenLeft=math.max(0,screenLeft)
	screenTop=math.max(0,screenTop)
	screenRight=math.min(ScrW(),screenRight)
	screenBottom=math.min(ScrH(),screenBottom)

	local rect={
		x=screenLeft,
		y=screenTop,
		w=screenRight-screenLeft,
		h=screenBottom-screenTop,
	}
	return rect
end

local function GetBiggestBound(target)
	local mins,maxs=target:GetRenderBounds()
	local biggestBound=0
	for i=1,3 do
		biggestBound=math.max(math.abs(mins[i]),maxs[i],biggestBound)
	end
	biggestBound=biggestBound*2

	return biggestBound
end

function ENT:Initialize()
	self:DestroyShadow()
end

function ENT:Think()
	self:CreateJPEGMaterial()

	self:SetNextClientThink(CurTime()+jpegCaptureDurationConvar:GetFloat())
	return true
end

function ENT:Draw(flags)
	local target=self:GetNWEntity("jpegTarget")
	if !IsValid(target) then
		return
	end

	self:SetRenderBounds(target:GetRenderBounds())
	self:SetRenderOrigin(target:GetRenderOrigin())

	if self.jpegMaterial==null then
		return
	end
	
	render.SetStencilEnable( true )
	render.ClearStencil()
	render.SetStencilTestMask( 255 )
	render.SetStencilWriteMask( 255 )
	render.SetStencilPassOperation( STENCILOPERATION_KEEP )
	render.SetStencilZFailOperation( STENCILOPERATION_KEEP )
	render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_NEVER )
	render.SetStencilReferenceValue( 9 )
	render.SetStencilFailOperation( STENCILOPERATION_REPLACE )
	-- draw for stencil
	if isfunction(target.Draw) then
		target:Draw()
	else
		target:DrawModel()
	end
	render.SetStencilFailOperation( STENCILOPERATION_KEEP )
	render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )
	surface.SetDrawColor(Color(255,255,255,255))

	cam.Start2D()
	
	local screenBounds=GetScreenRenderBounds(target)

	surface.SetDrawColor(Color(255,255,255,255))
	surface.SetMaterial(self.jpegMaterial)
	surface.DrawTexturedRect(screenBounds.x,screenBounds.y,screenBounds.w,screenBounds.h)
	
	render.SetStencilEnable( false )

	cam.End2D()
end

function ENT:CreateJPEGMaterial()
	local target=self:GetNWEntity("jpegTarget")
	if !IsValid(target) then
		--error("jpeg missing target!")

		return
	end
	self.jpegLastCapture=CurTime()

	local screenJpegRatio=ScrW()/jpegWidthConvar:GetInt()
	local jpegHeight=ScrH()/screenJpegRatio

	-- figure out screen mins maxs
	local screenBounds=GetScreenRenderBounds(target)
	local entX=math.floor(screenBounds.x/screenJpegRatio)
	local entY=math.floor(screenBounds.y/screenJpegRatio)
	local entW=math.floor(screenBounds.w/screenJpegRatio)
	local entH=math.floor(screenBounds.h/screenJpegRatio)
	if entW==0 or entH==0 then
		return
	end

	local customRT=GetRenderTarget("jpegalizefierRT",jpegWidthConvar:GetInt(),jpegHeight)
	render.PushRenderTarget(customRT)

	local biggestBound=GetBiggestBound(target)
	local mins,maxs=target:GetRenderBounds()
	local renderCenter=target:LocalToWorld((mins+maxs)/2)

	local viewSetup=render.GetViewSetup()
	local dir=renderCenter-viewSetup.origin
	dir:Normalize()

	cam.Start3D()

	-- draw stuff
	render.Clear(0,0,0,0,true)
	if isfunction(target.Draw) then
		target:Draw()
	else
		target:DrawModel()
	end

	-- screenshot
	local jpegData=render.Capture({
		format="jpeg",
		x=entX,
		y=entY,
		w=entW,
		h=entH,
		quality=0,
	})

	cam.End3D()
	render.PopRenderTarget()

	-- save to file so the data can be read
	file.CreateDir(saveFolder)
	-- naming the file .png even though it isnt a png lets gmod reload the image in the Material() call where it doesnt for a jpeg
	local jpegPath=saveFolder.."/"..saveFile.."."..self:GetNWInt("jpegIndex")..".png"
	file.Write(jpegPath,jpegData)
	timer.Simple(.01,function()
		if file.Exists("data/"..jpegPath,"GAME") then
			self.jpegMaterial=Material("data/"..jpegPath)
			--file.Delete(jpegPath)
		end
	end)
end

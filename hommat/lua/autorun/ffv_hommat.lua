if SERVER then
	util.AddNetworkString("ffvHOMTable")

	return
end

local texture=GetRenderTarget(
	"ffvGlitchTexture",
	ScrW(),ScrH()
)

local relevant={}
local anythingRelevant=false

local function checkForRelevant()
	relevant={}

	for _,e in ents.Iterator() do
		if (e:GetNWBool("ffv_homed") and IsValid(e)) then table.insert(relevant,e) end
	end

	anythingRelevant=(#relevant>0)
end

net.Receive("ffvHOMTable",function()
	local newRelevant=net.ReadTable()

	if ((not anythingRelevant) and (#newRelevant>0)) then
		render.PushRenderTarget(texture) --pushing it works here but not in the renderscene hook?
		render.RenderView({})
		render.PopRenderTarget()
	end

	relevant=newRelevant
	anythingRelevant=(#relevant>0)
end)

hook.Add("InitPostEntity","ffvHOMSpawn",function() checkForRelevant() end)

hook.Add("EntityRemoved","ffvHOMValidate",function(ent,fullUpdate)
	if fullUpdate then return end

	if table.HasValue(relevant,ent) then
		table.RemoveByValue(relevant,ent)
		anythingRelevant=(#relevant>0)
	end
end)

hook.Add("RenderScene","ffvHOMRender",function()
	if (not anythingRelevant) then return end

	render.RenderView({})
	render.CopyRenderTargetToTexture(texture)
end)

hook.Add("PostDrawOpaqueRenderables","ffvHOMDraw",function()
	if (not anythingRelevant) then return end

	render.ClearStencil()
	render.SetStencilWriteMask( 255 )
	render.SetStencilTestMask( 255 )
	render.SetStencilPassOperation( STENCILOPERATION_KEEP )
	render.SetStencilZFailOperation( STENCILOPERATION_KEEP )

	render.SetStencilEnable( true )

	render.SetStencilReferenceValue( 1 )
	render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_ALWAYS )
	render.SetStencilPassOperation( STENCILOPERATION_REPLACE )

	for _,e in pairs(relevant) do
		if (IsValid(e) and (halo.RenderedEntity()~=e)) then e:DrawModel() end
	end

	render.SetStencilFailOperation( STENCILOPERATION_KEEP )
	render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )
	render.ClearBuffersObeyStencil( 0, 0, 0, 255, true )

	render.DrawTextureToScreen(texture)

	render.SetStencilEnable(false)
end)
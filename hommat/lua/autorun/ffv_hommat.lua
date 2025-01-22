if SERVER then
	util.AddNetworkString("ffvHOMTable")

	return
end

local ffvHOMRelevant={}

hook.Add("InitPostEntity","ffvHOMSpawn",function(ply)
	if SERVER then return end

	for _,e in ents.Iterator() do
		if e:GetNWBool("ffv_homed") then table.insert(ffvHOMRelevant,e) end
	end
end)

net.Receive("ffvHOMTable",function() ffvHOMRelevant=net.ReadTable() end)

local texture=GetRenderTarget(
	"ffvGlitchTexture",
	ScrW(),ScrH()
)

hook.Add("RenderScene","ffvGlitchRender",function()
	render.RenderView({})
	render.CopyRenderTargetToTexture(texture)
end)

hook.Add("PostDrawOpaqueRenderables","ffvGlitchDraw",function()
	if (#ffvHOMRelevant==0) then return end

	render.ClearStencil()
	render.SetStencilWriteMask( 255 )
	render.SetStencilTestMask( 255 )
	render.SetStencilPassOperation( STENCILOPERATION_KEEP )
	render.SetStencilZFailOperation( STENCILOPERATION_KEEP )

	render.SetStencilEnable( true )

	render.SetStencilReferenceValue( 1 )
	render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_ALWAYS )
	render.SetStencilPassOperation( STENCILOPERATION_REPLACE )

	for _,e in pairs(ffvHOMRelevant) do
		if (IsValid(e) and (halo.RenderedEntity()~=e)) then e:DrawModel() end
	end

	render.SetStencilFailOperation( STENCILOPERATION_KEEP )
	render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )
	render.ClearBuffersObeyStencil( 0, 0, 0, 255, true )

	render.DrawTextureToScreen(texture)

	render.SetStencilEnable(false)
end)
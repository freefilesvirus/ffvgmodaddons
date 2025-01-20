list.Add("OverrideMaterials","!ffvHallOfMirrors")
if SERVER then return end

local texture=GetRenderTarget(
	"ffvGlitchTexture",
	ScrW(),ScrH()
)
CreateMaterial(
	"ffvHallOfMirrors",
	"UnlitGeneric",
	{["$basetexture"]="ffvGlitchTexture"}
)

hook.Add("RenderScene","ffvGlitchRender",function()
	render.RenderView()
	render.CopyRenderTargetToTexture(texture)
end)

hook.Add("PostDrawOpaqueRenderables","ffvGlitchDraw",function()
	local relevant={}
	for _,e in ents.Iterator() do
		local isRelevant=(e:GetMaterial()=="!ffvHallOfMirrors")
		local k=1
		while ((not isRelevant) and (k<=#e:GetMaterials())) do
			if (e:GetSubMaterial(k)=="!ffvHallOfMirrors") then isRelevant=true end
			k=(k+1)
		end
		if isRelevant then table.insert(relevant,e) end
	end
	if (#relevant==0) then return end

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
		if (halo.RenderedEntity()~=e) then e:DrawModel() end
	end

	render.SetStencilFailOperation( STENCILOPERATION_KEEP )
	render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )
	render.ClearBuffersObeyStencil( 0, 0, 0, 255, true )

	render.DrawTextureToScreen(texture)

	render.SetStencilEnable(false)
end)
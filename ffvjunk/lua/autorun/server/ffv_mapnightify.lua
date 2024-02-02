local night = false

function nightify()
	for k,v in ipairs(ents.GetAll()) do print(v:GetClass()) end
	night = true

	local sun = ents.FindByClass("env_sun")[1]
	if IsValid(sun) then sun:Remove() end

	local tonemap = ents.FindByClass("env_tonemap_controller")[1]
	if IsValid(tonemap) then tonemap:Remove() end

	local lightenv = ents.FindByClass("light_environment")[1]
	if IsValid(lightenv) then lightenv:Fire("TurnOff") end

	local skypaint = ents.FindByClass("env_skypaint")[1]
	if IsValid(skypaint) then
		skypaint:SetKeyValue("topcolor","0 0 0")
		skypaint:SetKeyValue("bottomcolor","0 0 0")
	end
	local fog = ents.FindByClass("env_fog_controller")[1]
	if IsValid(fog) then
		fog:Input("SetColor",nil,nil,"0 0 0")
		fog:Input("SetColorSecondary",nil,nil,"0 0 0")
		fog:SetKeyValue("SetStartDist","10")
		fog:Input("TurnOff")
	end


	RunConsoleCommand("sv_skyname","sky_borealis01")
end

concommand.Add("mapnightify",function() nightify() end)

-- hook.Add("PostCleanupMap","cleanupNightify",function()
-- 	print(night)
-- 	if night then nightify() end
-- end)
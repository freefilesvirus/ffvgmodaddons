include("cl_menu.lua")
include("shared.lua")

net.Receive("tryLoadFile",function()
	if file.Exists("ffvboxmodelcolor.json","DATA") then
		local data = util.JSONToTable(file.Read("ffvboxmodelcolor.json"))
		local color = Color(data.color.r,data.color.g,data.color.b)
		local model = data.model

		print(color)
		print(model)

		net.Start("setPlayermodel")
			net.WriteString(model)
		net.SendToServer()
		net.Start("setPlayercolor")
			net.WriteVector(color:ToVector())
		net.SendToServer()
	end
end)

function makeLabel(screenHeight,text)
	local label = vgui.Create("DLabel")
	label:SetFont("Trebuchet24")
	label:SetContentAlignment(5)
	label:SetText(text)
	label:SizeToContents()
	label:SetPos(1,ScrH()/screenHeight)
	label:SetBright(1)
	label:CenterHorizontal()
	return label
end

local gameText
net.Receive("gameText",function()
	local time = net.ReadInt(8)
	local text = net.ReadString()

	if IsValid(gameText) then gameText:Remove() end
	gameText = makeLabel(8,text)

	timer.Create("gameText"..LocalPlayer():EntIndex(),time,1,function() gameText:Remove() end)
end)

local timerObject
local timerWait
local timerStart
net.Receive("gameTimer",function()
	local time = net.ReadInt(8)

	if IsValid(timerObject) then timerObject:Remove() end
	timerObject = makeLabel(12,time)
	timerStart = CurTime()
	timerWait = time
end)
hook.Add("Think","ffvboxFixTimer",function()
	if IsValid(timerObject) then
		local timeDif = (timerWait-math.floor(CurTime()-timerStart))
		timerObject:SetText(timeDif)
		if (timeDif==0) then timerObject:Remove() end
	end
end)
if SERVER then
	local numNotes = -1

	util.AddNetworkString("ffvreadplayernote")
	util.AddNetworkString("ffvbuildplayernote")

	net.Receive("ffvbuildplayernote",function()
		local note = ents.Create("ffv_playernote")
		note.message = net.ReadString()
		note.steamid = net.ReadString()
		note.name = net.ReadString()
		note.date =  tonumber(net.ReadString())
		note:Spawn()
		note:SetPos(net.ReadVector())
		note:SetAngles(net.ReadAngle())
	end)

	function spawnPlayerNotes(refresh)
		http.Post("https://wthanpy.pythonanywhere.com/",
			{getnotes="yes",
			map=game.GetMap()},
			function(body)
				body = string.Replace(body,"\\","")

				if (refresh and (numNotes==#string.Split(body,"\n"))) then return end
				numNotes = #string.Split(body,"\n")

				for k,v in ipairs(ents.FindByClass("ffv_playernote")) do
					v:Remove()
				end

				for k,v in pairs(string.Split(body,"\n")) do
					if (k==#string.Split(body,"\n")) then return end
					
					local dict = {}
					for key, value in string.gmatch(v,'"([^"]+)":%s*"([^"]+)"') do
						dict[key] = value
					end

					local note = ents.Create("ffv_playernote")
					note.message = dict.message
					note.steamid = dict.steamid
					note.name = dict.name
					note.date = tonumber(dict.time)
					note:Spawn()
					note:SetPos(util.StringToType(dict.pos,"Vector"))
					note:SetAngles(util.StringToType(dict.ang,"Angle"))
				end
			end,
			function()
				print("something went wrong with spawning player notes")
			end)
	end
	spawnPlayerNotes()
	concommand.Add("pn_refresh",spawnPlayerNotes)
	hook.Add("PostCleanupMap","ffvcleanuprespawnnotes",spawnPlayerNotes)

	timer.Create("ffvcheckfornewnotes",2,0,function() spawnPlayerNotes(true) end)

	concommand.Add("pn_clear",function()
		for k,v in ipairs(ents.FindByClass("ffv_playernote")) do
			v:Remove()
		end
	end)

	hook.Add("PhysgunPickup","ffvnophysgunnotes",function(ply,ent)
		if (ent:GetClass()=="ffv_playernote") then return false end
	end)

	return
end

--build gui
local buildnoteframe = nil
local buildmessage = nil
function buildGui()
	buildnoteframe = vgui.Create("DFrame")
	buildnoteframe:SetSize(400,80)
	buildnoteframe:Center()
	buildnoteframe:SetTitle("Player Notes")
	buildnoteframe:SetDraggable(true)
	buildnoteframe:ShowCloseButton(true)
	buildnoteframe:MakePopup()
	buildnoteframe:SetDeleteOnClose(false)
	buildnoteframe:Close()

	buildmessage = vgui.Create("DTextEntry",buildnoteframe)
	buildmessage:Dock(TOP)
	buildmessage:SetPlaceholderText("Put your message here")
	function buildmessage:OnEnter()
		if (#self:GetValue()>128) then self:SetText(string.sub(self:GetValue(),1,128)) end
	end

	local buildbutton = vgui.Create("DButton",buildnoteframe)
	buildbutton:Dock(BOTTOM)
	buildbutton:SetText("Send your message to the world!")
	function buildbutton:DoClick()
		buildnoteframe:Close()

		--hello all reading this. if you wouldntve realized this code is vulnerable, dont read the rest of the comment so i dont give ya any ideas. im aware that this is incredibly easy to exploit and i dont know how to fix it without either being really intrusive or forcing people to sign in through steam, but thatd be a lot of hassle for something thats meant to be easy to use. i ask please dont ruin the fun for everyone else by abusing it
		local str = string.sub(buildmessage:GetValue(),1,128)
		str = string.Replace(str,"\"","'")
		http.Post("https://wthanpy.pythonanywhere.com/",
			{message=str,
			name=LocalPlayer():Nick(),
			steamid=tostring(LocalPlayer():SteamID64()),
			time=tostring(os.time()),
			pos=tostring(LocalPlayer():GetPos()+Vector(0,0,32)),
			ang=tostring(Angle(0,LocalPlayer():EyeAngles().y,0)),
			map=game.GetMap()},
			function(body)
				if (string.StartsWith(body,"bad")) then
					LocalPlayer():ChatPrint("Something went wrong! No note made.")
					print(body)
				end
			end,
			function()
				LocalPlayer():ChatPrint("Something went wrong! No note made.")
			end)

		net.Start("ffvbuildplayernote")
			net.WriteString(string.sub(buildmessage:GetValue(),1,128))
			net.WriteString(LocalPlayer():SteamID64())
			net.WriteString(LocalPlayer():Nick())
			net.WriteString(tostring(os.time()))
			net.WriteVector(LocalPlayer():GetPos()+Vector(0,0,32))
			net.WriteAngle(Angle(0,LocalPlayer():EyeAngles().y,0))
		net.SendToServer()
	end
end

list.Set("DesktopWindows","ffvsplayernotes",{
	title="Player Notes",
	icon="playernotes/playernote.png",
	init=function()
		if (not buildnoteframe) then buildGui() end
		buildnoteframe:SetVisible(true)
		buildmessage:SetText("")
	end
})

--read gui
function readGui(message,steamid,name,time)
	local readnoteframe = vgui.Create("DFrame")
	readnoteframe:SetSize(400,200)
	readnoteframe:Center()
	readnoteframe:SetTitle("Player Notes")
	readnoteframe:SetDraggable(true)
	readnoteframe:ShowCloseButton(true)
	readnoteframe:MakePopup()

	local readmessage = vgui.Create("DLabel",readnoteframe)
	readmessage:Dock(TOP)
	readmessage:SetWrap(true)
	readmessage:SetAutoStretchVertical(true)
	readmessage:SetText(message or "something went wrong")

	local readavatar = vgui.Create("AvatarImage",readnoteframe)
	readavatar:SetPos(5,163)
	readavatar:SetSize(32,32)
	readavatar:SetSteamID(steamid or "0",32)

	local readname = vgui.Create("DLabel",readnoteframe)
	readname:SetPos(45,161)
	readname:SetSize(200,32)
	readname:SetAutoStretchVertical(true)
	readname:SetText((name.."\n"..os.date("%x, %X",time)) or ("unknown user\n"..os.date("%x, %X")))

	local readbutton = vgui.Create("DButton",readnoteframe)
	readbutton:SetPos(306,163)
	readbutton:SetSize(90,32)
	readbutton:SetText("Visit Profile")
	function readbutton:DoClick()
		gui.OpenURL("https://steamcommunity.com/profiles/"..steamid)
	end

	readnoteframe:SetVisible(true)
end

net.Receive("ffvreadplayernote",function()
	local message = net.ReadString()
	local steamid = net.ReadString()
	local name = net.ReadString()
	local time = net.ReadString()

	readGui(message,steamid,name,time)
end)
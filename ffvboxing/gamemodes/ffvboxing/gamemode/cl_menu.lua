local menu = nil

function createMenu(startVisible)
	if (startVisible==nil) then startVisible = false end

	menu = vgui.Create("DFrame")
	menu:SetSize(640,460)
	menu:SetTitle("Menu")
	menu:Center()
	menu:MakePopup()
	menu:SetDeleteOnClose(false)
	menu:SetVisible(startVisible)

	local playermodel = vgui.Create("DPanel",menu)
	playermodel:SetSize(308)
	playermodel:DockPadding(4,4,4,4)
	playermodel:Dock(RIGHT)
	local pmcolor = vgui.Create("DColorMixer",playermodel)
	pmcolor:SetAlphaBar(false)
	pmcolor:SetPalette(false)
	pmcolor:SetColor(Color(62,88,106))
	pmcolor:Dock(TOP)
	function pmcolor:ValueChanged(col)
		net.Start("setPlayercolor")
			net.WriteVector(pmcolor:GetVector())
		net.SendToServer()

		--mmmmm probably not good with how much this happens
		file.Write("ffvboxmodelcolor.json",util.TableToJSON({color=pmcolor:GetColor(),model=LocalPlayer():GetModel()}))
	end
	local modelholder = vgui.Create("DIconLayout",playermodel)
	modelholder:DockMargin(0,4,0,0)
	modelholder:SetSpaceX(0)
	modelholder:SetSpaceY(2)
	modelholder:Dock(FILL)
	local models = {{"models/player/Group01/female_0",6},{"models/player/Group01/male_0",9}}
	for k=1,2 do
		for k1=1,models[k][2] do
			local button = vgui.Create("SpawnIcon",modelholder)
			button:SetModel(models[k][1]..k1..".mdl")
			button:SetSize(60,60)
			button.DoClick = function()
				net.Start("setPlayermodel")
					net.WriteString(button:GetModelName())
				net.SendToServer()

				file.Write("ffvboxmodelcolor.json",util.TableToJSON({color=pmcolor:GetColor(),model=button:GetModelName()}))
			end
		end
	end

	local leaderboard = vgui.Create("DPanel",menu)
	leaderboard:DockMargin(0,4,4,0)
	leaderboard:DockPadding(4,4,4,4)
	leaderboard:SetSize(1,155)
	leaderboard:Dock(BOTTOM)
	local llabel = vgui.Create("DLabel",leaderboard)
	llabel:SetTextColor(Color(0,0,0))
	llabel:SetText("Most Money")
	llabel:Dock(TOP)
	local lscroll = vgui.Create("DScrollPanel",leaderboard)
	lscroll:Dock(FILL)
	function menu:fixLeaderboard()
		lscroll:Clear()

		local order = {}
		for k,v in ipairs(player.GetAll()) do table.insert(order,{nameKD(v),v:GetNWInt("money")}) end
		table.sort(order,function(a,b) return a[2]>b[2] end)
		for k,v in pairs(order) do
			local label = vgui.Create("DLabel",lscroll)
			label:SetTextColor(Color(0,0,0))
			label:SetText(k.."- "..v[1].."; $"..v[2])
			label:Dock(TOP)
		end
	end
	menu:fixLeaderboard()

	local history = vgui.Create("DPanel",menu)
	history:DockMargin(0,0,4,0)
	history:DockPadding(4,4,4,4)
	history:SetSize(1,155)
	history:Dock(BOTTOM)
	local hlabel = vgui.Create("DLabel",history)
	hlabel:SetTextColor(Color(0,0,0))
	hlabel:SetText("Round History")
	hlabel:Dock(TOP)
	local hscroll = vgui.Create("DScrollPanel",history)
	hscroll:Dock(FILL)
	function menu:addHistory(winner,loser)
		local htab = vgui.Create("DPanel",hscroll)
		htab:SetZPos(-#hscroll:GetCanvas():GetChildren())
		htab:SetSize(1,76)
		htab:Dock(TOP)

		local wavatar = vgui.Create("AvatarImage",htab)
		wavatar:SetSize(32,32)
		wavatar:SetPos(4,4)
		wavatar:SetPlayer(winner)
		local wlabel = vgui.Create("DLabel",htab)
		wlabel:SetSize(200,32)
		wlabel:SetPos(40,4)
		wlabel:SetText(nameKD(winner).." won")
		wlabel:SetTextColor(Color(0,0,0))

		local lavatar = vgui.Create("AvatarImage",htab)
		lavatar:SetSize(32,32)
		lavatar:SetPos(4,40)
		lavatar:SetPlayer(loser)
		local llabel = vgui.Create("DLabel",htab)
		llabel:SetSize(200,32)
		llabel:SetPos(40,40)
		llabel:SetText(nameKD(loser).." lost")
		llabel:SetTextColor(Color(0,0,0))
	end

	local betting = vgui.Create("DPanel",menu)
	betting:DockMargin(0,0,4,4)
	betting:DockPadding(4,0,4,0)
	betting:Dock(FILL)
	local money = vgui.Create("DLabel",betting)
	money:SetTextColor(Color(0,0,0))
	money:Dock(TOP)
	function menu:updateMoney()
		money:SetText("$"..(IsValid(LocalPlayer()) and LocalPlayer():GetNWInt("money") or 20))
	end
	menu:updateMoney()
	local nextround = vgui.Create("DPanel",betting)
	nextround:Dock(FILL)
	local blabel = vgui.Create("DLabel",nextround)
	blabel:Dock(TOP)
	blabel:SetTextColor(Color(0,0,0))
	blabel:SetText("Next round:")
	local bvs = vgui.Create("DLabel",nextround)
	bvs:Dock(TOP)
	bvs:SetTextColor(Color(0,0,0))
	blabel = vgui.Create("DLabel",nextround)
	blabel:SetPos(0,40)
	blabel:SetTextColor(Color(0,0,0))
	blabel:SetText("$")
	blabel = vgui.Create("DLabel",nextround)
	blabel:SetPos(77,40)
	blabel:SetTextColor(Color(0,0,0))
	blabel:SetText("on")
	local bet = vgui.Create("DTextEntry",nextround)
	bet:SetPos(9,40)
	bet:SetNumeric(true)
	bet:SetText(0)
	function bet:OnLoseFocus() bet:OnValueChange() end
	function bet:OnValueChange()
		if (bet:GetValue()=="") then bet:SetText(0) end
		bet:SetText(math.Clamp(bet:GetInt(),0,(IsValid(LocalPlayer()) and LocalPlayer():GetNWInt("money") or 20)))
	end
	local betchoice = vgui.Create("DComboBox",nextround)
	betchoice:SetSortItems(false)
	betchoice:SetSize(218,20)
	betchoice:SetPos(92,40)
	local placebet = vgui.Create("DButton",nextround)
	placebet:SetSize(310,20)
	placebet:SetPos(0,64)
	placebet:SetText("Place bet")
	placebet.DoClick = function()
		if (bet:GetInt()<1) then return end
		nextround:SetVisible(false)
		LocalPlayer():ChatPrint("$"..bet:GetInt().." bet placed on "..betchoice:GetSelected())
		net.Start("placeBet")
			net.WriteInt(bet:GetInt(),32)
			net.WriteInt(betchoice:GetSelectedID(),3)
		net.SendToServer()
	end
	nextround:SetVisible(false)
	function menu:openBets(ply1,ply2)
		nextround:SetVisible(true)
		bvs:SetText(nameKD(ply1).." vs "..nameKD(ply2))
		bet:SetText(0)
		betchoice:Clear()
		if ((ply1==LocalPlayer()) or (ply2==LocalPlayer())) then
			betchoice:AddChoice(nameKD(LocalPlayer())) --no betting against yourself! >:(
		else
			betchoice:AddChoice(nameKD(ply1))
			betchoice:AddChoice(nameKD(ply2))
		end
		betchoice:ChooseOptionID(1)
	end

	--admin section
	if (not LocalPlayer():IsAdmin()) then return end
	local size = 76
	menu:SetSize(640,464+size)
	local admin = vgui.Create("DPanel",menu)
	admin:SetZPos(-1)
	admin:DockMargin(0,4,0,0)
	admin:DockPadding(4,4,4,4)
	admin:SetSize(1,size)
	admin:Dock(BOTTOM)

	local wlabel = vgui.Create("DLabel",admin)
	wlabel:SetTextColor(Color(0,0,0))
	wlabel:SetText("Weapon")
	wlabel:SetPos(322,4)
	local wentry = vgui.Create("DTextEntry",admin)
	wentry:SetPos(322,52)
	wentry:SetSize(280,20)
	wentry:SetPlaceholderText("Other weapon")
	wentry.OnLoseFocus = function() wentry:OnValueChange() end
	function wentry:OnValueChange()
		if (wentry:GetValue()=="") then return end
		LocalPlayer():ConCommand("box_weapon "..wentry:GetValue())
	end
	local wchoice = vgui.Create("DComboBox",admin)
	wchoice:SetSortItems(false)
	wchoice:SetPos(322,28)
	wchoice:SetSize(304,20)
	local baseweapons = {"weapon_fists","weapon_crowbar","weapon_pistol","weapon_357","weapon_smg1","weapon_ar2","weapon_shotgun","weapon_rpg","weapon_crossbow","weapon_frag"}
	for k,v in pairs(baseweapons) do
		wchoice:AddChoice(v)
	end
	wchoice:ChooseOptionID(1)
	function wchoice:OnSelect(i,text)
		LocalPlayer():ConCommand("box_weapon "..text)
		wentry:SetText(text)
	end
	local wexpand = vgui.Create("DButton",admin)
	wexpand:SetPos(606,52)
	wexpand:SetSize(20,20)
	wexpand:SetText("...")
	local wexpandframe = vgui.Create("DFrame")
	wexpandframe:SetSize(273,300)
	wexpandframe:SetTitle("All Weapons")
	wexpandframe:SetDeleteOnClose(false)
	local pwetty = vgui.Create("DPanel",wexpandframe)
	pwetty:DockMargin(4,4,4,4)
	pwetty:Dock(FILL)
	local wexpandscroll = vgui.Create("DScrollPanel",pwetty)
	wexpandscroll:Dock(FILL)
	local allweapons = {}
	for k,v in pairs(baseweapons) do if (not (v=="weapon_fists")) then table.insert(allweapons,{ClassName=v}) end end
	table.Add(allweapons,weapons.GetList())
	for k,v in pairs(allweapons) do
		local wepinfo = vgui.Create("DPanel",wexpandscroll)
		wepinfo:SetSize(1,24)
		wepinfo:DockMargin(4,4,4,4)
		wepinfo:Dock(TOP)
		local button = vgui.Create("DButton",wepinfo)
		button:SetPos(4,2)
		button:SetSize(205,20)
		button:SetText(v.ClassName)
		button.DoClick = function()
			wentry:SetText(v.ClassName)
			wentry:OnValueChange()
		end
		local check = vgui.Create("DCheckBox",wepinfo)
		check:SetChecked(table.HasValue(baseweapons,v.ClassName))
		check:SetPos(213,4)
		function check:OnChange(state)
			if state then wchoice:AddChoice(v.ClassName)
			else
				for k=1,math.huge do
					if (wchoice:GetOptionText(k)==v.ClassName) then
						wchoice:RemoveChoice(k)
						return
					elseif (wchoice:GetOptionText(k)==nil) then return end
				end
			end
		end
	end
	wexpandframe:Close()
	wexpand.DoClick = function() wexpandframe:SetVisible(true) end
	function menu:OnClose() wexpandframe:Close() end

	for k,v in pairs({{"Round Time","box_roundtime","60"},{"Downtime","box_downtime","10"},{"Health","box_health","100"}}) do
		local label = vgui.Create("DLabel",admin)
		label:SetTextColor(Color(0,0,0))
		label:SetText(v[1])
		label:SetPos(4,(24*(k-1))+4)
		local entry = vgui.Create("DTextEntry",admin)
		entry:SetPlaceholderText(v[3])
		entry:SetNumeric(true)
		entry:SetSize(254,20)
		entry:SetPos(64,(24*(k-1))+4)
		entry.OnLoseFocus = function() entry:OnValueChange() end
		function entry:OnValueChange()
			if (entry:GetInt()==nil) then return end
			LocalPlayer():ConCommand(v[2].." "..entry:GetValue())
		end
	end
end

function openMenu()
	if (menu==nil) then createMenu(true)
	else
		menu:fixLeaderboard()
		menu:SetVisible(true)
	end
end

hook.Add("PlayerBindPress", "openMenuKeybind", function(ply,bind)
	if (not IsValid(LocalPlayer())) then return end
	if (bind=="+menu") then openMenu() end
end)

net.Receive("updateMoney",function(len)
	if (not IsValid(LocalPlayer())) then return end
	LocalPlayer():SetNWInt("money",net.ReadInt(32))
	if (menu==null) then createMenu() end
	menu:updateMoney()
end)

net.Receive("nextPlayersPicked",function(len)
	if (not IsValid(LocalPlayer())) then return end
	if (menu==null) then createMenu() end
	menu:openBets(net.ReadPlayer(),net.ReadPlayer())
end)

net.Receive("roundWon",function()
	if (not IsValid(LocalPlayer())) then return end
	if (menu==null) then createMenu() end
	menu:addHistory(net.ReadPlayer(),net.ReadPlayer())
end)
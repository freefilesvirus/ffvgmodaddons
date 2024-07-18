include("shared.lua")

util.AddNetworkString("nextPlayersPicked")

nextPlayers = {}
currentPlayers = {}

roundWaiting = true

function pickRandom(plys)
	table.sort(plys,function(a,b) return a:GetNWInt("roundsSincePicked")<b:GetNWInt("roundsSincePicked") end)

	local totalChance = 0
	for k,v in ipairs(plys) do
		totalChance = (totalChance+v:GetNWInt("roundsSincePicked"))
	end

	local triedChances = 0
	local rand = math.Rand(0,1)
	for k,v in ipairs(plys) do
		if (((v:GetNWInt("roundsSincePicked")/totalChance)+triedChances)>=rand) then return v end
		
		triedChances = (triedChances+(v:GetNWInt("roundsSincePicked")/totalChance))
	end
end

function decideNextPlayers()
	if (#player.GetAll()<2) then return end
	
	nextPlayers = {}
	local plys = player.GetAll()
	table.insert(nextPlayers,pickRandom(plys))
	table.RemoveByValue(plys,nextPlayers[1])
	table.insert(nextPlayers,pickRandom(plys))

	net.Start("nextPlayersPicked")
		net.WritePlayer(nextPlayers[1])
		net.WritePlayer(nextPlayers[2])
	net.Broadcast()
end

local roundtimeConVar
local healthConVar
local weaponConVar = CreateConVar("box_weapon","weapon_fists")
function startRound()
	if (#player.GetAll()<2) then
		roundWaiting = true
		return
	end
	if (#nextPlayers~=2) then
		decideNextPlayers()
		startDowntime()
		return
	end
	if !(IsValid(nextPlayers[1]) and IsValid(nextPlayers[2])) then
		gameText("Queued player left! Reshuffling",3)
		refundBets()
		decideNextPlayers()
		startDowntime()
		return
	end

	currentPlayers = nextPlayers
	decideNextPlayers()

	thisRoundBets = nextRoundBets
	nextRoundBets = {}

	for k,v in ipairs(player.GetAll()) do v:SetNWInt("roundsSincePicked",v:GetNWInt("roundsSincePicked")+1) end

	if (healthConVar==nil) then healthConVar = GetConVar("box_health") end
	for k,v in pairs(currentPlayers) do
		v:Spawn()
		v:StripWeapons()
		v:Give(weaponConVar:GetString())
		if (#v:GetWeapons()>0) then v:GiveAmmo(999,v:GetWeapons()[1]:GetPrimaryAmmoType()) end
		v:SetHealth(healthConVar:GetInt())
		v:SetNWInt("roundsSincePicked",1)
	end

	currentPlayers[1]:SetPos(Vector(0,160,80))
	currentPlayers[1]:SetEyeAngles(Angle(0,-90,0))
	currentPlayers[2]:SetPos(Vector(0,-160,80))
	currentPlayers[2]:SetEyeAngles(Angle(0,90,0))


	if (roundtimeConVar==nil) then roundtimeConVar = GetConVar("box_roundtime") end
	gameTimer(roundtimeConVar:GetInt())
	timer.Create("ffvboxRoundTimer",roundtimeConVar:GetInt(),1,function()
		gameText("Stalemate! Bets refunded",3)
		refundBets()
		endRound()
	end)
end

local downtimeConVar
function startDowntime()
	if roundWaiting then
		roundWaiting = false
		decideNextPlayers()
	end

	if (downtimeConVar==nil) then downtimeConVar = GetConVar("box_downtime") end
	timer.Create("ffvboxDowntime",downtimeConVar:GetInt(),1,function() startRound() end)
	gameTimer(downtimeConVar:GetInt())
end

function endRound()
	timer.Remove("ffvboxRoundTimer")
	gameTimer(0)

	local plys = currentPlayers
	currentPlayers = {}

	timer.Simple(3,function()
		for k,v in pairs(plys) do if (IsValid(v) and v.important) then v:Kill() end end
		startDowntime()
	end)
end

hook.Add("PlayerDeath","ffvboxEndRound",function(ply)
	if (ply.important and (#currentPlayers>1)) then
		table.RemoveByValue(currentPlayers,ply)
		local winner = currentPlayers[1]
		gameText(nameKD(winner).." won!",3)

		ply:SetNWInt("deaths",ply:GetNWInt("deaths")+1)
		winner:SetNWInt("kills",winner:GetNWInt("kills")+1)

		addMoney(winner,20)
		payoutBets(winner)

		net.Start("roundWon")
			net.WritePlayer(winner)
			net.WritePlayer(ply)
		net.Broadcast()

		endRound()
	end

	ply.important = false

	timer.Simple(3,function() if (not ply:Alive()) then ply:Spawn() end end)
end)